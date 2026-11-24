import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/services/course_map_cache_service.dart';
import 'package:golf_diary_app/services/course_map_pack_store.dart';
import 'package:golf_diary_app/services/course_map_pack_store_io.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/hole_map_image.dart';
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

  /// Reads of these paths wait until the completer finishes.
  final Map<String, Completer<void>> gates = {};

  @override
  Future<Uint8List?> read(String path) async {
    reads.add(path);
    final gate = gates[path];
    if (gate != null) await gate.future;
    return objects[path];
  }

  Iterable<String> get packReads =>
      reads.where((r) => r != 'course_maps/index.json');
}

Uint8List _json(Object value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

/// Villamor pack objects; [versioned] uses `course_maps/{id}/v{n}/`, else the
/// legacy unversioned layout.
Map<String, Uint8List> _villamorBucket({
  int version = 1,
  bool versioned = false,
}) {
  final base = versioned
      ? 'course_maps/ph-crse-villamor/v$version'
      : 'course_maps/ph-crse-villamor';
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
        {'courseId': 'ph-crse-villamor', 'version': version},
      ],
    }),
    '$base/manifest.json': _json({
      'schema': 1,
      'courseId': 'ph-crse-villamor',
      'version': version,
      'holes': holes,
    }),
    '$base/hole_1.png': _png,
    '$base/hole_2.png': _png,
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
      await service.debugSettle();
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

  group('versioned persistent packs', () {
    late MemoryCourseMapPackStore store;

    Future<CourseMapResolveResult> resolve(int hole) => service.resolveHoleMap(
          courseName: course,
          holeNumber: hole,
          coords: holeCoordinates(course, hole)!,
          allowDownload: true,
        );

    /// A fresh app open: session state cleared, stored packs kept.
    _FakeSource reopen(Map<String, Uint8List> bucket) {
      service.debugReset();
      final source = _FakeSource(bucket);
      service
        ..store = store
        ..source = source;
      return source;
    }

    setUp(() => store = MemoryCourseMapPackStore());

    test('reads course_maps/{id}/v{n}/ before the legacy layout', () async {
      final source = reopen(_villamorBucket(versioned: true));
      final result = await resolve(1);
      await service.debugSettle();
      expect(result.kind, CourseMapResolveKind.satellite);
      expect(result.frame!.packDirectory, 'course_maps/ph-crse-villamor/v1');
      expect(source.packReads, [
        'course_maps/ph-crse-villamor/v1/manifest.json',
        'course_maps/ph-crse-villamor/v1/hole_1.png',
        'course_maps/ph-crse-villamor/v1/hole_2.png',
      ]);
    });

    test('legacy pack is fetched once from the unversioned path', () async {
      final source = reopen(_villamorBucket());
      await resolve(1);
      await service.debugSettle();
      expect(source.packReads, [
        'course_maps/ph-crse-villamor/v1/manifest.json',
        'course_maps/ph-crse-villamor/manifest.json',
        'course_maps/ph-crse-villamor/hole_1.png',
        'course_maps/ph-crse-villamor/hole_2.png',
      ]);
    });

    test('returns the current hole before the rest of the pack arrives',
        () async {
      final source = reopen(_villamorBucket(versioned: true));
      final hole2 = Completer<void>();
      source.gates['course_maps/ph-crse-villamor/v1/hole_2.png'] = hole2;

      final result = await resolve(1);
      expect(result.kind, CourseMapResolveKind.satellite);
      expect(store.files.keys, isNot(contains('ph-crse-villamor/v1/hole_2.png')));

      hole2.complete();
      await service.debugSettle();
      expect(store.files.keys, contains('ph-crse-villamor/v1/hole_2.png'));
    });

    test('a reopened app serves the stored pack without downloading it',
        () async {
      reopen(_villamorBucket(versioned: true));
      await resolve(1);
      await service.debugSettle();

      final source = reopen(_villamorBucket(versioned: true));
      expect((await resolve(1)).kind, CourseMapResolveKind.satellite);
      expect((await resolve(2)).kind, CourseMapResolveKind.satellite);
      await service.debugSettle();
      expect(source.packReads, isEmpty);
      expect(source.reads, ['course_maps/index.json']);
    });

    test('opens offline from the stored pack', () async {
      reopen(_villamorBucket(versioned: true));
      await resolve(1);
      await service.debugSettle();

      reopen({});
      expect(await service.hasPackForCourse(course), isTrue);
      final result = await resolve(2);
      expect(result.kind, CourseMapResolveKind.satellite);
      expect(service.cachedImageBytes(result.frame!), _png);
    });

    test('a new index version is downloaded, switched to, and v1 pruned',
        () async {
      reopen(_villamorBucket(versioned: true));
      await resolve(1);
      await service.debugSettle();

      final source = reopen(_villamorBucket(version: 2, versioned: true));
      final stale = await resolve(1);
      expect(stale.frame!.packDirectory, endsWith('/v1'));
      await service.debugSettle();
      expect(source.packReads, [
        'course_maps/ph-crse-villamor/v2/manifest.json',
        'course_maps/ph-crse-villamor/v2/hole_1.png',
        'course_maps/ph-crse-villamor/v2/hole_2.png',
      ]);
      expect((await resolve(2)).frame!.packDirectory, endsWith('/v2'));
      expect(
        store.files.keys.where((k) => k.contains('/v1/')),
        isEmpty,
      );
      expect(await store.latestVersion('ph-crse-villamor'), 2);
    });

    test('an incomplete new version does not replace the stored one',
        () async {
      reopen(_villamorBucket(versioned: true));
      await resolve(1);
      await service.debugSettle();

      final bucket = _villamorBucket(version: 2, versioned: true)
        ..remove('course_maps/ph-crse-villamor/v2/hole_2.png');
      reopen(bucket);
      await resolve(1);
      await service.debugSettle();
      expect(await store.latestVersion('ph-crse-villamor'), 1);
      expect((await resolve(2)).frame!.packDirectory, endsWith('/v1'));
    });

    test('repeat resolves return the same bytes instance', () async {
      reopen(_villamorBucket(versioned: true));
      final first = await resolve(1);
      final again = await resolve(1);
      expect(
        identical(
          service.cachedImageBytes(first.frame!),
          service.cachedImageBytes(again.frame!),
        ),
        isTrue,
      );
    });
  });

  group('DiskCourseMapPackStore', () {
    late Directory root;
    late DiskCourseMapPackStore disk;

    setUp(() {
      root = Directory.systemTemp.createTempSync('course_maps_test');
      disk = DiskCourseMapPackStore(root: () async => root);
    });

    tearDown(() => root.deleteSync(recursive: true));

    Uint8List manifest(int version) => _json({
          'schema': 1,
          'courseId': 'ph-crse-villamor',
          'version': version,
          'holes': const [],
        });

    test('stores files under {courseId}/v{n}/ and prunes old versions',
        () async {
      await disk.write('ph-crse-villamor', 1, 'manifest.json', manifest(1));
      await disk.write('ph-crse-villamor', 1, 'hole_1.png', _png);
      await disk.write('ph-crse-villamor', 2, 'hole_1.png', _png);
      expect(await disk.latestVersion('ph-crse-villamor'), 1);

      await disk.write('ph-crse-villamor', 2, 'manifest.json', manifest(2));
      expect(await disk.latestVersion('ph-crse-villamor'), 2);
      expect(
        File(p.join(root.path, 'ph-crse-villamor', 'v2', 'hole_1.png'))
            .existsSync(),
        isTrue,
      );

      await disk.prune('ph-crse-villamor', 2);
      expect(await disk.read('ph-crse-villamor', 1, 'hole_1.png'), isNull);
      expect(await disk.read('ph-crse-villamor', 2, 'hole_1.png'), _png);
    });

    test('reads a pre-versioning cache as its manifest version', () async {
      final legacy = Directory(p.join(root.path, 'ph-crse-villamor'))
        ..createSync();
      File(p.join(legacy.path, 'manifest.json'))
          .writeAsBytesSync(manifest(1));
      File(p.join(legacy.path, 'hole_1.png')).writeAsBytesSync(_png);

      expect(await disk.latestVersion('ph-crse-villamor'), 1);
      expect(await disk.read('ph-crse-villamor', 1, 'hole_1.png'), _png);
      expect(await disk.read('ph-crse-villamor', 2, 'hole_1.png'), isNull);

      await disk.write('ph-crse-villamor', 2, 'manifest.json', manifest(2));
      await disk.prune('ph-crse-villamor', 2);
      expect(File(p.join(legacy.path, 'hole_1.png')).existsSync(), isFalse);
      expect(await disk.latestVersion('ph-crse-villamor'), 2);
    });
  });

  group('holeMapDecodeWidth', () {
    test('decodes at display size, rounded up to 128 px', () {
      expect(holeMapDecodeWidth(200, 2, 1280), 512);
      expect(holeMapDecodeWidth(256, 2, 1280), 512);
    });

    test('keeps full size when the display is as wide as the source', () {
      expect(holeMapDecodeWidth(400, 3, 720), isNull);
      expect(holeMapDecodeWidth(0, 3, 720), isNull);
      expect(holeMapDecodeWidth(double.infinity, 3, 720), isNull);
    });
  });
}
