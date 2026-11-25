import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/models/course_map_manifest.dart';
import 'package:golf_diary_app/on_course/fwy_aim.dart';
import 'package:golf_diary_app/on_course/hole_projection.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/hole_map_pack_source.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/pin_distance.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'support/on_course_test_helpers.dart';

const kNavBarHeight = 80.0;
const kCourse = 'Villamor Golf Club';

/// Villamor hole 1 from the published v1 pack (CRSE-041).
final _villamorH1 = HoleMapManifestEntry.fromJson(jsonDecode('''
{"holeNumber":1,"par":4,"lengthYds":350,"imagePath":"hole_1.png",
 "widthPx":720,"heightPx":1280,
 "frame":{"centerLat":14.5263114,"centerLon":121.0228992,
          "bearingDeg":329.115,"metersPerPixel":0.30892},
 "corners":{"topLeft":{"lat":14.5273239,"lon":121.0210697},
            "bottomRight":{"lat":14.5252988,"lon":121.0247287}},
 "bbox":{"swLat":14.5242721,"swLon":121.0210697,
         "neLat":14.5283507,"neLon":121.0247287},
 "coverage":"osm","generated":[],
 "markers":[{"id":"ph-crse-villamor-h1-target","kind":"target",
             "lat":14.52668,"lon":121.022631,"reason":"238 yds carry"}]}
''') as Map<String, dynamic>);

// 1×1 transparent PNG.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

class _FakePackSource implements HoleMapPackSource {
  @override
  Future<HoleMapPack?> loadHole(String courseName, int holeNumber) async {
    if (holeNumber != 1 || canonicalCourseName(courseName) != kCourse) {
      return null;
    }
    return HoleMapPack(entry: _villamorH1, imageBytes: _png);
  }
}

class _FixedPin implements PinDistanceClient {
  _FixedPin(this.fix);

  final PinFix fix;

  @override
  Future<PinFix?> current() async => fix;

  @override
  Stream<PinFix> watch() => Stream<PinFix>.value(fix);
}

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_crse036.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_crse036.db'));
  });

  tearDown(() async {
    HoleMapPackSource.instance = const CachedHoleMapPackSource();
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Finder key(String value) => find.byKey(ValueKey(value));

  Future<void> settleDb(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
  }

  Future<void> pumpOnCourse(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    PinDistanceClient? pinDistance,
    String? course,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tee = holeCoordinates(kCourse, 1)!;
    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: Scaffold(
        body: FairwayTrackerScreen(
          pinDistance: pinDistance,
          positionForShot: () async => null,
        ),
        bottomNavigationBar: const SizedBox(height: kNavBarHeight),
      ),
    ));
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Driver').evaluate().isNotEmpty) break;
    }
    expect(find.text('Driver'), findsWidgets, reason: 'bag loaded');
    if (course != null) {
      await submitCourseName(tester, course);
      await settleDb(tester);
    }
    expect(tee, isNotNull);
  }

  group('projection', () {
    test('pack frame maps its own image corners', () {
      final frame = _villamorH1.frame!;
      final projection = HoleProjection(
        centerLat: frame.centerLat,
        centerLon: frame.centerLon,
        bearingDeg: frame.bearingDeg,
      );
      final halfW = 360 * frame.metersPerPixel;
      final halfH = 640 * frame.metersPerPixel;
      final topLeft = projection.toLocal(14.5273239, 121.0210697);
      final bottomRight = projection.toLocal(14.5252988, 121.0247287);
      expect(topLeft.dx, closeTo(-halfW, 2));
      expect(topLeft.dy, closeTo(halfH, 2));
      expect(bottomRight.dx, closeTo(halfW, 2));
      expect(bottomRight.dy, closeTo(-halfH, 2));

      final tee = holeCoordinates(kCourse, 1)!;
      final teeLocal = projection.toLocal(tee.teeLat, tee.teeLon);
      final greenLocal = projection.toLocal(tee.greenLat, tee.greenLon);
      expect(greenLocal.dy, greaterThan(teeLocal.dy + 250));
      expect((greenLocal.dx - teeLocal.dx).abs(), lessThan(20));

      final back = projection.toLatLon(teeLocal);
      expect(back.lat, closeTo(tee.teeLat, 1e-7));
      expect(back.lon, closeTo(tee.teeLon, 1e-7));
    });

    test('viewport inverse and tee-bottom fit', () {
      final viewport = HoleViewport.fit(
        tee: Offset.zero,
        green: const Offset(0, 300),
        free: const Rect.fromLTWH(12, 136, 300, 400),
      );
      final tee = viewport.toScreen(Offset.zero);
      final green = viewport.toScreen(const Offset(0, 300));
      expect(tee.dy, greaterThan(green.dy));
      expect(green.dy, greaterThanOrEqualTo(136));
      expect(tee.dy, lessThanOrEqualTo(536));
      final round = viewport.toLocal(viewport.toScreen(const Offset(12, 34)));
      expect(round.dx, closeTo(12, 1e-9));
      expect(round.dy, closeTo(34, 1e-9));
    });

    test('ring snapping and derived aim side', () {
      final snapped = snapToRing(
          ball: Offset.zero, tap: const Offset(-10, 10), radius: 100);
      expect(snapped.distance, closeTo(100, 1e-9));
      expect(
          deriveAimDirection(
              ball: Offset.zero, green: const Offset(0, 300), target: snapped),
          'left');
      expect(
          deriveAimDirection(
              ball: Offset.zero,
              green: const Offset(0, 300),
              target: const Offset(40, 100)),
          'right');
      expect(
          deriveAimDirection(
              ball: Offset.zero,
              green: const Offset(0, 300),
              target: const Offset(1, 100)),
          'center');
      expect(StandinHole.forPar(3).lengthYards, 165);
      expect(StandinHole.forPar(5).lengthYards, 510);
    });

    test('carry mark is a 30 degree arc facing the aim', () {
      const sweep = kCarryArcDegrees * math.pi / 180;
      final up =
          carryArcAngles(ball: Offset.zero, focus: const Offset(0, -100));
      expect(up.sweep, closeTo(sweep, 1e-9));
      expect(up.start, closeTo(-math.pi / 2 - sweep / 2, 1e-9));

      final right =
          carryArcAngles(ball: Offset.zero, focus: const Offset(100, 0));
      expect(right.start, closeTo(-sweep / 2, 1e-9));

      final missing = carryArcAngles(ball: Offset.zero, focus: Offset.zero);
      expect(missing.sweep, closeTo(sweep, 1e-9));
      expect(missing.start, closeTo(-math.pi / 2 - sweep / 2, 1e-9));
    });

    test('no aim faces the hole, or the nearest marker toward it', () {
      const ball = Offset.zero;
      const hole = Offset(0, 400);
      const toward = Offset(10, 180);
      const farther = Offset(-8, 260);
      const behind = Offset(0, -40);
      const sideways = Offset(200, 20);
      final markers = [farther, behind, sideways, toward];

      expect(
        carryArcFocus(
          ball: ball,
          hole: hole,
          holeIsAimTarget: true,
          markers: markers,
        ),
        hole,
      );
      expect(
        carryArcFocus(
          ball: ball,
          hole: hole,
          holeIsAimTarget: false,
          markers: markers,
        ),
        toward,
      );
      expect(
        carryArcFocus(
          ball: ball,
          hole: hole,
          holeIsAimTarget: false,
          markers: const [behind, sideways],
        ),
        hole,
      );
      const tapped = Offset(-40, 90);
      expect(
        carryArcFocus(
          ball: ball,
          hole: hole,
          holeIsAimTarget: false,
          golferAim: tapped,
          markers: markers,
        ),
        tapped,
      );
    });
  });

  testWidgets('FWY 390x844: full-bleed map, top rows, right rail, Record only',
      (tester) async {
    final tee = holeCoordinates(kCourse, 1)!;
    await pumpOnCourse(tester,
        course: kCourse,
        pinDistance:
            _FixedPin(PinFix(latitude: tee.teeLat, longitude: tee.teeLon)));
    const body = 844 - kNavBarHeight;
    const appBar = 56.0;

    final map = tester.getRect(key('oncourse-map-background'));
    expect(map.width, 390);
    expect(map.bottom, closeTo(body, 1));
    expect(map.top, appBar);
    expect(map.height, body - appBar);

    for (final id in [
      'oncourse-course-summary',
      'oncourse-mode-toggle',
      'oncourse-course-meta',
      'oncourse-gps-badge',
      'on-course-hole-label',
      'oncourse-par-summary',
      'on-course-distance-to-hole',
    ]) {
      expect(tester.getRect(key(id)).bottom, lessThan(56 + 136), reason: id);
    }
    final summary = tester.getRect(key('oncourse-course-summary'));
    final toggle = tester.getRect(key('oncourse-mode-toggle'));
    expect((summary.center.dy - toggle.center.dy).abs(), lessThan(4));
    expect(tester.getRect(key('oncourse-course-meta')).top,
        greaterThanOrEqualTo(summary.bottom - 1));

    final rail = tester.getRect(key('oncourse-side-rail'));
    expect(rail.right, closeTo(390 - 20, 0.5));
    expect(rail.top,
        greaterThan(tester.getRect(key('on-course-hole-label')).bottom));
    for (final id in [
      'oncourse-club-summary',
      'oncourse-lie-summary',
      'oncourse-aim-summary',
    ]) {
      final tile = tester.getRect(key(id));
      expect(tile.width, 56, reason: id);
      expect(tile.height, 56, reason: id);
    }

    final record = tester.getRect(key('oncourse-record-shot-btn'));
    expect(record.bottom, lessThanOrEqualTo(body));
    expect(record.width, greaterThan(300));
    expect(rail.bottom, lessThan(record.top));
    expect(tester.getRect(key('oncourse-shots-peek')).bottom,
        lessThanOrEqualTo(record.top));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(key('oncourse-concede-btn'), findsNothing);
    expect(key('oncourse-finish-hole-btn'), findsNothing);
    expect(key('on-course-map-toggle'), findsNothing);
    expect(key('oncourse-sim-yards-field'), findsNothing);
    expect(key('oncourse-diary-edge-swipe'), findsNothing);
    expect(key('diary-entry-on-course'), findsOneWidget);
  });

  testWidgets('FWY 360x640: rail fits between the top rows and the dock',
      (tester) async {
    await pumpOnCourse(tester, size: const Size(360, 640), course: kCourse);
    const body = 640 - kNavBarHeight;
    final rail = tester.getRect(key('oncourse-side-rail'));
    final record = tester.getRect(key('oncourse-record-shot-btn'));
    expect(rail.top,
        greaterThan(tester.getRect(key('on-course-hole-label')).bottom));
    expect(
        rail.bottom, lessThan(tester.getRect(key('oncourse-shots-peek')).top));
    expect(record.bottom, lessThanOrEqualTo(body));
    expect(tester.getRect(key('oncourse-club-summary')).height,
        greaterThanOrEqualTo(36));
    expect(tester.takeException(), isNull);
  });

  testWidgets('side toggle moves the rail left and the choice persists',
      (tester) async {
    await pumpOnCourse(tester, course: kCourse);
    await tester.tap(key('oncourse-rail-side-toggle'));
    await settleDb(tester);
    expect(tester.getRect(key('oncourse-side-rail')).left, closeTo(20, 0.5));

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpOnCourse(tester);
    expect(tester.getRect(key('oncourse-side-rail')).left, closeTo(20, 0.5));
    await tester.tap(key('oncourse-rail-side-toggle'));
    await settleDb(tester);
    expect(tester.getRect(key('oncourse-side-rail')).right,
        closeTo(390 - 20, 0.5));
  });

  testWidgets('pack hole: image, OSM attribution, marker; no Line only badge',
      (tester) async {
    HoleMapPackSource.instance = _FakePackSource();
    await pumpOnCourse(tester, course: kCourse);
    expect(key('oncourse-map-pack-image'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors (ODbL)'), findsOneWidget);
    expect(
        key('oncourse-map-marker-ph-crse-villamor-h1-target'), findsOneWidget);
    expect(key('oncourse-map-line-only-badge'), findsNothing);

    final marker =
        tester.getRect(key('oncourse-map-marker-ph-crse-villamor-h1-target'));
    final rail = tester.getRect(key('oncourse-side-rail'));
    expect(marker.right, lessThan(rail.left));
    expect(marker.top, greaterThan(56 + 136));
  });

  testWidgets('unmapped course shows the generated stand-in hole',
      (tester) async {
    await pumpOnCourse(tester, course: 'My Backyard');
    expect(key('oncourse-standin-badge'), findsOneWidget);
    expect(find.text("Sample hole · not this course's shape"), findsOneWidget);
    expect(find.text('≈ 380 yds'), findsOneWidget);
    expect(key('oncourse-aim-summary'), findsOneWidget);
    expect(key('oncourse-map-line-only-badge'), findsNothing);
  });

  testWidgets('Pen popover counts; double par prompts but never auto-finishes',
      (tester) async {
    await pumpOnCourse(tester);
    await tester.tap(key('oncourse-par-summary'));
    await settleSheet(tester);
    await tester.tap(key('oncourse-par-chip-3'));
    await settleSheet(tester);
    await settleDb(tester);

    await tester.tap(key('oncourse-rail-penalty'));
    await settleSheet(tester);
    expect(key('oncourse-penalty-popover'), findsOneWidget);
    expect(
        tester.widget<IconButton>(key('oncourse-penalty-step-down')).onPressed,
        isNull);
    for (var i = 0; i < 6; i++) {
      await tester.tap(key('oncourse-penalty-step-up'));
      await settleDb(tester);
    }
    expect(tester.widget<Text>(key('oncourse-penalty-count')).data, '6');
    await tester.tapAt(const Offset(40, 250));
    await settleSheet(tester);
    expect(key('oncourse-penalty-popover'), findsNothing);
    expect(tester.widget<Text>(key('oncourse-rail-penalty-count')).data, '6');

    expect(key('oncourse-double-par-banner'), findsOneWidget);
    expect(find.text('Double par (6). Finish hole?'), findsOneWidget);
    await tester.tap(key('oncourse-double-par-keep'));
    await tester.pump();
    expect(key('oncourse-double-par-banner'), findsNothing);
    expect(key('oncourse-double-par-finish-chip'), findsOneWidget);
    expect(find.text('Hole 1'), findsOneWidget);

    await tester.tap(key('oncourse-double-par-finish-chip'));
    await settleDb(tester);
    expect(find.text('Hole 2'), findsOneWidget);
    expect(key('oncourse-double-par-finish-chip'), findsNothing);
  });

  testWidgets('Mul popover counts up and down', (tester) async {
    await pumpOnCourse(tester);
    await tester.tap(key('oncourse-rail-mulligan'));
    await settleSheet(tester);
    await tester.tap(key('oncourse-mulligan-step-up'));
    await settleDb(tester);
    await tester.tap(key('oncourse-mulligan-step-up'));
    await settleDb(tester);
    await tester.tap(key('oncourse-mulligan-step-down'));
    await settleDb(tester);
    expect(tester.widget<Text>(key('oncourse-mulligan-count')).data, '1');
    expect(tester.widget<Text>(key('oncourse-rail-mulligan-count')).data, '1');
  });

  testWidgets('Concede and Finish live in the overflow (two taps)',
      (tester) async {
    await pumpOnCourse(tester);
    await tester.tap(find.byKey(const Key('shell-header-overflow-btn')));
    await settleSheet(tester);
    expect(key('oncourse-overflow-concede'), findsOneWidget);
    expect(key('oncourse-overflow-finish'), findsOneWidget);
    expect(find.text('Finish Hole'), findsOneWidget);
    await tester.tap(key('oncourse-overflow-finish'));
    await settleSheet(tester);
    await settleDb(tester);
    expect(find.text('Hole 2'), findsOneWidget);

    await tapOverflowItem(tester, 'oncourse-overflow-concede');
    await settleDb(tester);
    expect(find.text('Hole 2'), findsOneWidget);

    await tester.tap(key('on-course-hole-label'));
    await settleSheet(tester);
    expect(key('oncourse-hole-sheet-concede'), findsOneWidget);
    await tester.tap(key('oncourse-hole-sheet-finish'));
    await settleSheet(tester);
    await settleDb(tester);
    expect(find.text('Hole 3'), findsOneWidget);
  });

  testWidgets('Manual GPS: tap places the pin; Record gates on a move',
      (tester) async {
    await pumpOnCourse(tester, course: kCourse);
    await tester.tap(key('oncourse-gps-badge'));
    await settleSheet(tester);
    await tester.tap(key('oncourse-gps-manual'));
    await settleSheet(tester);
    await settleDb(tester);
    expect(
        find.descendant(
            of: key('oncourse-gps-badge'), matching: find.text('Manual')),
        findsOneWidget);

    FilledButton record() =>
        tester.widget<FilledButton>(key('oncourse-record-shot-btn'));
    expect(record().onPressed, isNull);
    expect(key('oncourse-manual-hint'), findsOneWidget);

    await tester.tapAt(const Offset(160, 520));
    await tester.pump();
    expect(key('oncourse-manual-pin'), findsOneWidget);
    expect(record().onPressed, isNotNull);
    expect(key('on-course-distance-to-hole'), findsOneWidget);

    await tester.tap(key('oncourse-record-shot-btn'));
    await settleDb(tester);
    expect(find.text('Shots this hole (1) ⌃'), findsOneWidget);
    expect(record().onPressed, isNull, reason: 'pin is stale after Record');

    final pin = tester.getCenter(key('oncourse-manual-pin'));
    await tester.tapAt(pin);
    await tester.pump();
    expect(record().onPressed, isNotNull, reason: 'same spot confirmed');

    await tester.tapAt(const Offset(160, 380));
    await tester.pump();
    await tester.tap(key('oncourse-record-shot-btn'));
    await settleDb(tester);
    expect(find.text('Shots this hole (2) ⌃'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpOnCourse(tester);
    expect(
        find.descendant(
            of: key('oncourse-gps-badge'), matching: find.text('Manual')),
        findsOneWidget);
  });

  testWidgets('SIM keeps its layout: no map, rail, or double-par prompt',
      (tester) async {
    await pumpOnCourse(tester, course: kCourse);
    await selectSimulator(tester);
    expect(key('oncourse-map-background'), findsNothing);
    expect(key('oncourse-side-rail'), findsNothing);
    expect(key('oncourse-concede-btn'), findsOneWidget);
    expect(key('oncourse-finish-hole-btn'), findsOneWidget);
    expect(key('oncourse-penalty-step-up'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell-header-overflow-btn')));
    await settleSheet(tester);
    expect(key('oncourse-overflow-finish'), findsNothing);
  });
}
