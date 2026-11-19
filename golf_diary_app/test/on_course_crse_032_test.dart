import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

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

    expect(find.byKey(const ValueKey('oncourse-aim-left')), findsNothing);

    const course = 'Villamor Golf Club';
    await tester.enterText(
      find.widgetWithText(TextField, 'Course name'),
      course,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byKey(const ValueKey('oncourse-aim-center'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('oncourse-aim-left')), findsOneWidget);
    expect(find.text('Record shot at ball'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('oncourse-aim-right')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('oncourse-record-shot-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const ValueKey('oncourse-record-shot-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('oncourse-shot-row-2')), findsOneWidget);
    expect(find.textContaining('yds'), findsWidgets);

    await tester.tap(find.text('Simulator'));
    await tester.pump();
    expect(find.byKey(const ValueKey('oncourse-aim-left')), findsNothing);

    await tester.tap(find.text('Course'));
    await tester.pump();
    expect(find.byKey(const ValueKey('oncourse-aim-center')), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Course name'),
      'My Backyard',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byKey(const ValueKey('oncourse-aim-left'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('oncourse-aim-left')), findsNothing);
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