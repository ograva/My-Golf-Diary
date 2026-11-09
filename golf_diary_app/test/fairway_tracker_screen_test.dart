import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/pin_distance.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

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

    expect(find.text('Record Shot at Ball'), findsOneWidget);
    expect(find.text('Distance travelled (yds)'), findsNothing);

    await tester.tap(find.text('Simulator'));
    await tester.pump();

    expect(find.text('Record shot'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Distance travelled (yds)'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Record shot'));
    await tester.pump();
    expect(find.text('Enter a distance greater than 0'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Distance travelled (yds)'), '0');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Record shot'));
    await tester.pump();
    expect(find.text('Enter a distance greater than 0'), findsOneWidget);

    await tester.tap(find.text('Course'));
    await tester.pump();
    expect(find.text('Record Shot at Ball'), findsOneWidget);
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

    await tester.enterText(
        find.widgetWithText(TextField, 'Course name'), course);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
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

    await tester.tap(find.text('Simulator'));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('on-course-distance-to-hole')), findsNothing);
    expect(client.live, 0);

    await tester.tap(find.text('Course'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find.text('$yards yds to pin').evaluate().isNotEmpty) break;
    }
    expect(find.text('$yards yds to pin'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Course name'), 'My Backyard');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
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
  });
}
