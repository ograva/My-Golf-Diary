import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/pin_distance.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

import 'support/on_course_test_helpers.dart';

class _FakePinDistance implements PinDistanceClient {
  _FakePinDistance(this.fix);

  final PinFix fix;
  int live = 0;

  @override
  Future<PinFix?> current() async => fix;

  @override
  Stream<PinFix> watch() {
    late StreamController<PinFix> controller;
    controller = StreamController<PinFix>(
      onListen: () {
        live++;
        controller.add(fix);
      },
      onCancel: () => live--,
    );
    return controller.stream;
  }
}

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_fairway.db');
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Future<void> waitForBag(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      final error = tester.takeException();
      if (error != null) fail('$error');
      if (find.text('Driver').evaluate().isNotEmpty) return;
    }
    fail('On Course did not load the bag');
  }

  testWidgets('Simulator mode asks for yards and rejects a blank distance',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        theme: buildGolfTheme(), home: const FairwayTrackerScreen()));
    await waitForBag(tester);

    expect(find.text('Record shot at ball'), findsOneWidget);
    expect(find.text('Distance travelled (yds)'), findsNothing);

    await selectSimulator(tester);

    expect(find.text('Record stroke'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('oncourse-sim-yards-field')), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Record stroke'));
    await tester.pump();
    expect(find.text('Enter a distance greater than 0'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('oncourse-sim-yards-field')), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Record stroke'));
    await tester.pump();
    expect(find.text('Enter a distance greater than 0'), findsOneWidget);

    await selectFairway(tester);
    await tester.pump();
    expect(find.text('Record shot at ball'), findsOneWidget);
    expect(find.text('Distance travelled (yds)'), findsNothing);
  });

  testWidgets('mapped course shows yards to the pin and simulator hides them',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const course = 'Villamor Golf Club';
    final hole = holeCoordinates(course, 1)!;
    final client =
        _FakePinDistance(PinFix(latitude: hole.teeLat, longitude: hole.teeLon));
    final yards = yardsToHole(hole, fromLat: hole.teeLat, fromLon: hole.teeLon);

    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: FairwayTrackerScreen(pinDistance: client),
    ));
    await waitForBag(tester);
    expect(
        find.byKey(const ValueKey('on-course-distance-to-hole')), findsNothing);

    await submitCourseName(tester, course);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find
          .byKey(const ValueKey('on-course-distance-to-hole'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('on-course-distance-to-hole')),
        findsOneWidget);
    expect(find.text('$yards yds to pin'), findsOneWidget);
    expect(client.live, 1);

    await selectSimulator(tester);
    expect(
        find.byKey(const ValueKey('on-course-distance-to-hole')), findsNothing);
    expect(client.live, 0);

    await selectFairway(tester);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find.text('$yards yds to pin').evaluate().isNotEmpty) break;
    }
    expect(find.text('$yards yds to pin'), findsOneWidget);

    await submitCourseName(tester, 'My Backyard');
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find
          .byKey(const ValueKey('on-course-distance-to-hole'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }
    expect(
        find.byKey(const ValueKey('on-course-distance-to-hole')), findsNothing);
    expect(find.textContaining('yds to pin'), findsNothing);
    expect(find.byKey(const ValueKey('on-course-map-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('oncourse-hud-tabular')), findsOneWidget);
  });

  testWidgets('unknown course shows tabular HUD without pin or map toggle',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        theme: buildGolfTheme(), home: const FairwayTrackerScreen()));
    await waitForBag(tester);

    expect(find.byKey(const ValueKey('oncourse-hud-tabular')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('on-course-distance-to-hole')), findsNothing);
    expect(find.byKey(const ValueKey('on-course-map-toggle')), findsNothing);
  });

  testWidgets('Sherwood mapped hole gains toggle and unmapped hole hides it',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const course = 'Sherwood Hills Golf Club';
    final mappedHole = holeCoordinates(course, 1)!;
    final client = _FakePinDistance(
        PinFix(latitude: mappedHole.teeLat, longitude: mappedHole.teeLon));

    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: FairwayTrackerScreen(pinDistance: client),
    ));
    await waitForBag(tester);

    await submitCourseName(tester, course);
    for (var i = 0; i < 24; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find
          .byKey(const ValueKey('on-course-map-toggle'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('on-course-map-toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('on-course-distance-to-hole')),
        findsOneWidget);

    for (var hole = 1; hole < 3; hole++) {
      await tester.tap(find.text('Finish Hole'));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        if (find.text('Hole ${hole + 1}').evaluate().isNotEmpty) {
          break;
        }
      }
    }

    expect(find.text('Hole 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('on-course-map-toggle')), findsNothing);
    expect(
        find.byKey(const ValueKey('on-course-distance-to-hole')), findsNothing);
    expect(find.byKey(const ValueKey('oncourse-hud-tabular')), findsOneWidget);
  });

  testWidgets('simulator record saves yards note and shot row key',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
        theme: buildGolfTheme(), home: const FairwayTrackerScreen()));
    await waitForBag(tester);

    await selectSimulator(tester);

    await tester.enterText(
        find.byKey(const ValueKey('oncourse-sim-yards-field')), '142');
    await tester.tap(find.byKey(const ValueKey('oncourse-sim-notes-chip')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('oncourse-sim-stroke-note-field')),
        'Chunked it right');

    await tester.tap(find.widgetWithText(FilledButton, 'Record stroke'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    expect(find.byKey(const ValueKey('oncourse-sim-stroke-note-field')),
        findsNothing);
    expect(find.byKey(const ValueKey('oncourse-shot-row-1')), findsNothing);
    await expandShotList(tester);
    expect(find.byKey(const ValueKey('oncourse-shot-row-1')), findsOneWidget);
    expect(find.textContaining('142 yds travelled'), findsOneWidget);
    expect(find.textContaining('Chunked it right'), findsOneWidget);
    expect(find.byIcon(Icons.notes_outlined), findsOneWidget);
  });

  testWidgets('map pane without pack shows vector fallback and snackbar once',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const course = 'Villamor Golf Club';
    final mappedHole = holeCoordinates(course, 1)!;
    final client = _FakePinDistance(
        PinFix(latitude: mappedHole.teeLat, longitude: mappedHole.teeLon));

    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: FairwayTrackerScreen(pinDistance: client),
    ));
    await waitForBag(tester);

    await submitCourseName(tester, course);
    for (var i = 0; i < 24; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find
          .byKey(const ValueKey('on-course-map-toggle'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    await tester.tap(find.text('Map'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find
          .byKey(const ValueKey('oncourse-map-vector'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const ValueKey('oncourse-map-vector')), findsOneWidget);
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .text('Showing the hole line without the course photo.')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(
      find.text('Showing the hole line without the course photo.'),
      findsOneWidget,
    );
  });
}
