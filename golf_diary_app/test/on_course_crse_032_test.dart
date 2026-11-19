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

  testWidgets('Aim mode snaps a tap to the ring and saves the derived side',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const course = 'Villamor Golf Club';
    final tee = holeCoordinates(course, 1)!;
    Position fixAt(double lat, double lon) => Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.utc(2026),
          accuracy: 1,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: FairwayTrackerScreen(
        positionForShot: () async => fixAt(tee.teeLat, tee.teeLon),
      ),
    ));
    await waitForBag(tester);
    await submitCourseName(tester, course);
    await tester.pump(const Duration(milliseconds: 200));

    final aim = find.byKey(const ValueKey('oncourse-aim-summary'));
    expect(aim, findsOneWidget);
    expect(find.descendant(of: aim, matching: find.text('Pin')), findsOneWidget);

    await tester.tap(aim);
    await tester.pump();
    expect(find.byKey(const ValueKey('oncourse-aim-mode-banner')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('oncourse-aim-target')), findsNothing);

    await tester.tapAt(const Offset(60, 330));
    await tester.pump();
    expect(find.byKey(const ValueKey('oncourse-aim-target')), findsOneWidget);
    expect(
        find.descendant(of: aim, matching: find.text('Custom')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('oncourse-record-shot-btn')));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('oncourse-aim-target')), findsNothing);
    expect(find.byKey(const ValueKey('oncourse-aim-mode-banner')), findsNothing);
    expect(find.descendant(of: aim, matching: find.text('Pin')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('oncourse-shots-peek')));
    await settleSheet(tester);
    expect(find.byKey(const ValueKey('oncourse-shot-row-1')), findsOneWidget);
    expect(find.textContaining('Aim left'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const ValueKey('oncourse-shot-row-1'))))
        .pop();
    await settleSheet(tester);

    await selectSimulator(tester);
    expect(aim, findsNothing);
    await selectFairway(tester);
    await tester.pump();
    expect(aim, findsOneWidget);
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
