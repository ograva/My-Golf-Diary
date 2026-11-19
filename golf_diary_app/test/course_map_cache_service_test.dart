import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/services/course_map_cache_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/oncourse_map_pane.dart';
import 'package:golf_diary_app/widgets/oncourse_satellite_hole_map.dart';

// 1×1 transparent PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class _FakeSource implements CourseMapPackSource {
  _FakeSource(this.objects);

  final Map<String, Uint8List> objects;
  final List<String> reads = [];

  @override
  Future<Uint8List?> read(String path) async {
    reads.add(path);
    return objects[path];
  }
}

Uint8List _json(Object value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

Map<String, Uint8List> _villamorBucket() {
  final holes = [
    for (var n = 1; n <= 2; n++)
      {
        'holeNumber': n,
        'imagePath': 'hole_$n.png',
        'widthPx': 720,
        'heightPx': 1280,
        'bbox': {
          'swLat': 14.50,
          'swLon': 121.00,
          'neLat': 14.51,
          'neLon': 121.01,
        },
      },
  ];
  return {
    'course_maps/index.json': _json({
      'schema': 1,
      'courses': [
        {'courseId': 'ph-crse-villamor', 'version': 1},
      ],
    }),
    'course_maps/ph-crse-villamor/manifest.json': _json({
      'schema': 1,
      'courseId': 'ph-crse-villamor',
      'version': 1,
      'holes': holes,
    }),
    'course_maps/ph-crse-villamor/hole_1.png': _png,
    'course_maps/ph-crse-villamor/hole_2.png': _png,
  };
}

void main() {
  final service = CourseMapCacheService.instance;
  const course = 'Villamor Golf Club';

  tearDown(service.debugReset);

  group('courseMapPackId', () {
    test('maps every surveyed course to its established ph-crse id', () {
      for (final name in surveyedCourseNames) {
        expect(kCourseMapPackIds, contains(name), reason: name);
        expect(courseMapPackId(name), startsWith('ph-crse-'));
      }
      expect(kCourseMapPackIds, hasLength(17));
      expect(kCourseMapPackIds.values.toSet(), hasLength(17));
    });

    test('table keys are canonical catalog names', () {
      for (final name in kCourseMapPackIds.keys) {
        expect(canonicalCourseName(name), name);
      }
    });

    test('uses the venue id, not the bare name slug', () {
      expect(courseMapPackId('Villamor Golf Club'), 'ph-crse-villamor');
      expect(
        courseMapPackId('Hallow Ridge Filipinas Golf (KC Filipinas)'),
        'ph-crse-hallow-ridge',
      );
    });

    test('falls back to ph-crse-<slug> for unlisted names', () {
      expect(courseMapPackId('New Course & Club'), 'ph-crse-new-course-club');
    });
  });

  group('memory cache (web)', () {
    late _FakeSource source;

    setUp(() {
      source = _FakeSource(_villamorBucket());
      service
        ..debugUseMemoryCache = true
        ..source = source;
    });

    test('hasPackForCourse reads the remote index once per session', () async {
      expect(await service.hasPackForCourse(course), isTrue);
      expect(await service.hasPackForCourse('Cebu Country Club'), isFalse);
      expect(
        source.reads.where((r) => r == 'course_maps/index.json'),
        hasLength(1),
      );
    });

    test('downloads the pack from ph-crse path and serves holes from memory',
        () async {
      final coords = holeCoordinates(course, 1)!;
      final first = await service.resolveHoleMap(
        courseName: course,
        holeNumber: 1,
        coords: coords,
      );
      expect(first.kind, CourseMapResolveKind.downloading);

      final downloaded = await service.resolveHoleMap(
        courseName: course,
        holeNumber: 1,
        coords: coords,
        allowDownload: true,
      );
      expect(downloaded.kind, CourseMapResolveKind.satellite);
      expect(downloaded.frame!.imageFile, isNull);
      expect(downloaded.frame!.entry.imagePath, 'hole_1.png');
      expect(service.cachedImageBytes(downloaded.frame!), _png);
      expect(
        source.reads,
        containsAll([
          'course_maps/ph-crse-villamor/manifest.json',
          'course_maps/ph-crse-villamor/hole_1.png',
          'course_maps/ph-crse-villamor/hole_2.png',
        ]),
      );

      final readsBefore = source.reads.length;
      final hole2 = await service.resolveHoleMap(
        courseName: course,
        holeNumber: 2,
        coords: holeCoordinates(course, 2)!,
      );
      expect(hole2.kind, CourseMapResolveKind.satellite);
      expect(service.cachedImageBytes(hole2.frame!), _png);
      expect(source.reads.length, readsBefore);
    });

    test('concurrent downloads share one fetch', () async {
      final coords = holeCoordinates(course, 1)!;
      await Future.wait([
        for (var i = 0; i < 3; i++)
          service.resolveHoleMap(
            courseName: course,
            holeNumber: 1,
            coords: coords,
            allowDownload: true,
          ),
      ]);
      expect(
        source.reads
            .where((r) => r == 'course_maps/ph-crse-villamor/manifest.json'),
        hasLength(1),
      );
    });

    test('missing pack falls back to vector', () async {
      source.objects.remove('course_maps/ph-crse-villamor/manifest.json');
      final result = await service.resolveHoleMap(
        courseName: course,
        holeNumber: 1,
        coords: holeCoordinates(course, 1)!,
        allowDownload: true,
      );
      expect(result.kind, CourseMapResolveKind.vector);
    });

    test('offline index means no pack', () async {
      source.objects.clear();
      expect(await service.hasPackForCourse(course), isFalse);
    });

    testWidgets('map pane downloads and paints the cached image',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGolfTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: OncourseMapPane(
                courseName: course,
                holeNumber: 1,
                coords: holeCoordinates(course, 1)!,
                shots: const [],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump();

      expect(find.byType(OncourseSatelliteHoleMap), findsOneWidget);
      expect(
        find.byKey(const ValueKey('oncourse-hole-map-image')),
        findsOneWidget,
      );
    });
  });
}
