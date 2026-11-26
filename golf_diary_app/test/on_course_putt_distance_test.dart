import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

import 'support/on_course_test_helpers.dart';

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_putt_distance.db');
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
  }

  testWidgets('Green lie shows the paced-yards picker and saves it on the shot',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const course = 'Villamor Golf Club';
    final green = holeCoordinates(course, 1)!;
    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: FairwayTrackerScreen(
        positionForShot: () async => Position(
          latitude: green.greenLat,
          longitude: green.greenLon,
          timestamp: DateTime.utc(2026),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      ),
    ));
    for (var i = 0; i < 30; i++) {
      await settle(tester);
      if (find.text('Driver').evaluate().isNotEmpty) break;
    }
    await submitCourseName(tester, course);
    await tester.pump(const Duration(milliseconds: 200));

    final picker = find.byKey(const ValueKey('oncourse-putt-distance-picker'));
    expect(picker, findsNothing);

    await tester.tap(find.byKey(const ValueKey('oncourse-lie-summary')));
    await settleSheet(tester);
    await tester.tap(find.byKey(const ValueKey('oncourse-lie-chip-green')));
    await settleSheet(tester);
    expect(picker, findsOneWidget);
    expect(find.byKey(const ValueKey('oncourse-putt-distance-chip-20')),
        findsOneWidget);
    expect(find.text('20+'), findsOneWidget);

    final custom =
        find.byKey(const ValueKey('oncourse-putt-distance-custom-chip'));
    await tester.ensureVisible(custom);
    await tester.pump();
    await tester.tap(custom);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
        find.byKey(const ValueKey('oncourse-putt-distance-custom-field')), '4');
    await tester.tap(
        find.byKey(const ValueKey('oncourse-putt-distance-custom-save')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4 yds'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('oncourse-record-shot-btn')));
    await settle(tester);

    final db = LocalDatabaseService.instance;
    final rows = await tester.runAsync(() async {
      final database = await db.database;
      return database.query('shots', where: 'deleted = 0');
    });
    expect(rows!.single['lie_type'], 'green');
    expect(rows.single['putt_distance_yards'], 4.0);
  });

  test('Finish Hole stores the paced distance on the holed putt', () async {
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(courseName: 'Local Course');
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: 'driver',
      lieType: 'green',
      currentLat: 0,
      currentLon: 0,
      puttDistanceYards: 10,
    );
    await db.finishHole(
      roundId: roundId,
      holeNumber: 1,
      nextPar: 4,
      puttDistanceYards: 2,
    );
    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots.map((s) => s.puttDistanceYards), [10, 2]);
    expect(shots.last.isHoled, isTrue);
  });

  test('putt distance is ignored off the green', () async {
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(courseName: 'Local Course');
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: 'driver',
      lieType: 'fairway',
      currentLat: 14,
      currentLon: 121,
      puttDistanceYards: 10,
    );
    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots.single.puttDistanceYards, isNull);
  });
}
