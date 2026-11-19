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
    LocalDatabaseService.debugSetFileName('golf_diary_crse032.db');
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Future<void> waitForBag(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.text('Driver').evaluate().isNotEmpty) return;
    }
    fail('On Course did not load the bag');
  }

  testWidgets('mapped course shows aim wedge; unmapped and simulator hide it',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var fixIndex = 0;
    final fixes = [
      Position(
        latitude: 14.508,
        longitude: 121.0,
        timestamp: DateTime.utc(2026),
        accuracy: 1,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      Position(
        latitude: 14.5095,
        longitude: 121.0,
        timestamp: DateTime.utc(2026),
        accuracy: 1,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: FairwayTrackerScreen(
        positionForShot: () async => fixes[fixIndex++],
      ),
    ));
    await waitForBag(tester);

    expect(find.byKey(const ValueKey('oncourse-aim-summary')), findsNothing);

    const course = 'Villamor Golf Club';
    await submitCourseName(tester, course);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byKey(const ValueKey('oncourse-aim-summary'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('oncourse-aim-summary')), findsOneWidget);
    expect(find.text('Record shot at ball'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('oncourse-aim-summary')));
    await settleSheet(tester);
    expect(find.byKey(const ValueKey('oncourse-aim-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('oncourse-aim-left')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('oncourse-aim-right')));
    await settleSheet(tester);
    expect(find.byKey(const ValueKey('oncourse-aim-sheet')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('oncourse-aim-summary')),
            matching: find.text('R ▶')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('oncourse-record-shot-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const ValueKey('oncourse-record-shot-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await expandShotList(tester);
    expect(find.byKey(const ValueKey('oncourse-shot-row-2')), findsOneWidget);
    expect(find.textContaining('Aim right'), findsWidgets);
    expect(find.textContaining('yds'), findsWidgets);

    await selectSimulator(tester);
    expect(find.byKey(const ValueKey('oncourse-aim-summary')), findsNothing);

    await selectFairway(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('oncourse-aim-summary')), findsOneWidget);

    await submitCourseName(tester, 'My Backyard');
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byKey(const ValueKey('oncourse-aim-summary'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('oncourse-aim-summary')), findsNothing);
  });

  test('recordFairwayHit stores aim on mapped outdoor shots', () async {
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(courseName: 'Villamor Golf Club');
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: 'driver',
      lieType: 'tee',
      currentLat: holeCoordinates('Villamor Golf Club', 1)!.teeLat,
      currentLon: holeCoordinates('Villamor Golf Club', 1)!.teeLon,
      aimDirection: 'right',
    );
    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots.single.aimDirection, 'right');
  });
}
