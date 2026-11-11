import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_wrapup.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_wrapup.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  void clearSnackBars(WidgetTester tester) {
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();
  }

  Finder labeled(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
  }

  testWidgets('session note survives club changes and compiles into the log', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));

    Future<void> pumpRange() async {
      await tester.pumpWidget(
          MaterialApp(theme: buildGolfTheme(), home: const RangeDrillScreen()));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }

    await pumpRange();

    final evaluate = find.byKey(const ValueKey('range-save-evaluate-session-btn'));
    await tester.ensureVisible(evaluate);
    await tester.tap(evaluate);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text(kEmptyRangeSessionMessage), findsOneWidget);
    clearSnackBars(tester);
    await tester.pump();

    await tester.enterText(labeled('Avg (Yds)'), '220');
    final save = find.text('Save Drill Session');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    clearSnackBars(tester);
    await tester.pump();

    final note = find.byKey(const ValueKey('range-session-note-field'));
    await tester.ensureVisible(note);
    await tester.enterText(note, 'Smooth session');
    await tester.tap(find.widgetWithText(ChoiceChip, '7 Iron'));
    await tester.pump();
    expect(
      tester.widget<TextField>(note).controller!.text,
      'Smooth session',
    );

    await tester.enterText(labeled('Avg (Yds)'), '150');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    clearSnackBars(tester);
    await tester.pump();

    expect(find.textContaining('Driver'), findsWidgets);
    expect(find.textContaining('7 Iron'), findsWidgets);

    await tester.ensureVisible(evaluate);
    await tester.tap(evaluate);
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    await tester.pump();

    final sessions = await tester.runAsync(() => LocalDatabaseService.instance.listRangeSessions());
    expect(sessions, hasLength(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    final bar = tester.widget<SnackBar>(find.byType(SnackBar, skipOffstage: false));
    expect((bar.content as Text).data, contains('stored for later'));
    expect(tester.widget<TextField>(note).controller!.text, isEmpty);
    final card = find.byWidgetPredicate((widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('range-compiled-session-'));
    expect(card, findsOneWidget);
    expect(find.textContaining('Smooth session'), findsWidgets);
    expect(find.textContaining('Compiled session'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '3 Wood'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('range-log-this-club')));
    await tester.pump();
    expect(card, findsNothing);

    await tester.tap(find.byKey(const Key('range-log-all')));
    await tester.pump();
    expect(card, findsOneWidget);

    await pumpRange();
    expect(card, findsOneWidget);
  });
}
