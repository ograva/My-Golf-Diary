import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/models/course_map_manifest.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/on_course/hole_map_geo.dart';
import 'package:golf_diary_app/services/course_map_cache_service.dart';
import 'package:golf_diary_app/services/pin_distance.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/hole_map_marker_painter.dart';
import 'package:golf_diary_app/widgets/oncourse_satellite_hole_map.dart';
import 'package:golf_diary_app/widgets/oncourse_vector_hole_map.dart';

void main() {
  tearDown(() {
    CourseMapCacheService.instance.debugHoleFrame = null;
    CourseMapCacheService.instance.debugHasPack = null;
  });

  test('boundsForHole pads tee and green', () {
    const coords = HoleCoordinates(
      teeLat: 14.0,
      teeLon: 121.0,
      greenLat: 14.001,
      greenLon: 121.002,
    );
    final bounds = boundsForHole(coords);
    expect(bounds.swLat, lessThan(coords.teeLat));
    expect(bounds.neLat, greaterThan(coords.greenLat));
  });

  testWidgets('satellite map shows attribution and marker layer',
      (tester) async {
    const course = 'Villamor Golf Club';
    final coords = holeCoordinates(course, 1)!;
    final bounds = boundsForHole(coords);
    CourseMapCacheService.instance.debugHoleFrame = HoleMapFrame(
      entry: HoleMapManifestEntry(
        holeNumber: 1,
        imagePath: 'hole_1.webp',
        swLat: bounds.swLat,
        swLon: bounds.swLon,
        neLat: bounds.neLat,
        neLon: bounds.neLon,
        widthPx: 640,
        heightPx: 640,
      ),
      packDirectory: '/tmp',
      imageFile: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: OncourseSatelliteHoleMap(
            frame: CourseMapCacheService.instance.debugHoleFrame!,
            coords: coords,
            shots: const [],
            player: PinFix(latitude: coords.teeLat, longitude: coords.teeLon),
          ),
        ),
      ),
    );

    expect(find.text('Google'), findsOneWidget);
    expect(find.byType(OncourseSatelliteHoleMap), findsOneWidget);
  });

  testWidgets('vector map repaints when shot list grows', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const course = 'Villamor Golf Club';
    final coords = holeCoordinates(course, 1)!;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: _VectorHarness(coords: coords),
      ),
    );

    var painter = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('oncourse-map-vector')),
    );
    final before = (painter.painter as HoleMapMarkerPainter).shots.length;

    await tester.tap(find.text('Add shot'));
    await tester.pump();

    painter = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('oncourse-map-vector')),
    );
    final after = (painter.painter as HoleMapMarkerPainter).shots.length;
    expect(after, greaterThan(before));
  });
}

class _VectorHarness extends StatefulWidget {
  const _VectorHarness({required this.coords});
  final HoleCoordinates coords;

  @override
  State<_VectorHarness> createState() => _VectorHarnessState();
}

class _VectorHarnessState extends State<_VectorHarness> {
  final List<ShotRecord> _shots = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: OncourseVectorHoleMap(
              coords: widget.coords,
              shots: _shots,
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _shots.add(
                ShotRecord(
                  id: 's${_shots.length}',
                  roundId: 'r1',
                  holeNumber: 1,
                  strokeNumber: _shots.length + 1,
                  clubId: 'c1',
                  lieType: 'fairway',
                  startLat: widget.coords.teeLat,
                  startLon: widget.coords.teeLon,
                  endLat: widget.coords.teeLat + 0.0001,
                  endLon: widget.coords.teeLon + 0.0001,
                  timestamp: 1,
                ),
              );
            }),
            child: const Text('Add shot'),
          ),
        ],
      ),
    );
  }
}
