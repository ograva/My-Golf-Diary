import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_on_course.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_on_course.db'));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Future<void> pumpCourse(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildGolfTheme(), home: const FairwayTrackerScreen()));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      final error = tester.takeException();
      if (error != null) fail('$error');
      if (find.text('Driver').evaluate().isNotEmpty) return;
    }
    fail('On Course did not load the bag');
  }

  Future<void> finishAction(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
  }

  testWidgets('a catalog course sets hole par and a custom name stays par 4',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCourse(tester);
    ChoiceChip parChip(String label) =>
        tester.widget(find.widgetWithText(ChoiceChip, label));
    expect(parChip('Par 4').selected, isTrue);

    await tester.enterText(
        find.widgetWithText(TextField, 'Course name'), 'Intramuros');
    await tester.pump();
    await tester.tap(find.text('Club Intramuros Golf Course'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Course name'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Course name'))
            .controller
            ?.text,
        'Club Intramuros Golf Course');
    expect(parChip('Par 3').selected, isTrue);
    expect(find.text('18 holes · par 66'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Course name'), 'Camp Aguinaldo');
    await tester.pump();
    await tester.tap(find.text('Camp Aguinaldo Golf Club'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    expect(find.text('18 holes · par 68'), findsOneWidget);

    await finishAction(tester, find.text('Finish Hole'));
    expect(find.text('Hole 2'), findsOneWidget);
    expect(parChip('Par 3').selected, isTrue);

    await tester.enterText(
        find.widgetWithText(TextField, 'Course name'), 'My Backyard');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();

    expect(parChip('Par 4').selected, isTrue);
    expect(find.text('18 holes · par 66'), findsNothing);
  });

  testWidgets('leaving On Course resumes the hole Finish Hole created',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCourse(tester);
    expect(find.text('Hole 1'), findsOneWidget);
    final next =
        tester.widget<IconButton>(find.byKey(const Key('on-course-hole-next')));
    expect(next.onPressed, isNull);

    await finishAction(tester, find.text('Finish Hole'));
    expect(find.text('Hole 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpCourse(tester);
    expect(find.text('Hole 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('on-course-hole-previous')));
    await tester.pump();
    expect(find.text('Hole 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('on-course-hole-next')));
    await tester.pump();
    expect(find.text('Hole 2'), findsOneWidget);
  });

  testWidgets('a recorded shot can change lie or be deleted', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCourse(tester);
    await tester.tap(find.text('Simulator'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Distance travelled (yds)'), '150');
    await finishAction(
        tester, find.widgetWithText(ElevatedButton, 'Record shot'));

    expect(find.textContaining('Stroke 1'), findsOneWidget);
    await tester.tap(find.textContaining('Stroke 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rough').last);
    await tester.pump();
    await tester.tap(find.byKey(const Key('on-course-shot-save')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('rough'), findsOneWidget);

    await tester.tap(find.textContaining('rough'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('on-course-shot-delete')));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Stroke 1'), findsNothing);
    expect(find.textContaining('rough'), findsNothing);
  });
}
