import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/practice_drill_sheet.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final db = LocalDatabaseService.instance;

  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_drills.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_drills.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  testWidgets('practice drill sheet can be used, cleared, and removed',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await useFreshDatabase();
      expect(
          (await db.getAllClubs()).map((club) => club.id), contains('driver'));
      expect((await db.listPracticeDrills()).length, greaterThan(0));
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.pumpWidget(
        MaterialApp(theme: buildGolfTheme(), home: const RangeDrillScreen()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text('Driver'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('range-header-drills-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    final chip =
        find.byKey(ValueKey(practiceDrillChipKey('Full Swing & Tempo')));

    expect(find.byKey(const ValueKey('range-drills-sheet')), findsOneWidget);
    await tester.tap(
        find.byKey(const ValueKey('range-drill-title-rng-drl-tempo-3to1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('range-drills-sheet')), findsNothing);
    final notes = tester
        .widgetList<TextField>(find.byType(TextField))
        .singleWhere(
            (field) => field.controller?.text == '3:1 Tour Tempo Rhythm');
    expect(notes.controller?.text, '3:1 Tour Tempo Rhythm');

    await tester.tap(find.byKey(const ValueKey('range-header-drills-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();

    final tempo =
        find.byKey(const ValueKey('range-drill-row-rng-drl-tempo-3to1'));
    await tester.ensureVisible(tempo);
    await tester.tap(tempo);
    await tester.pump();
    expect(find.textContaining('Select a mid-iron'), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const ValueKey('range-drill-use-btn')));
    await tester.tap(find.byKey(const ValueKey('range-drill-use-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('3:1 Tour Tempo Rhythm'), findsNWidgets(2));

    await tester.enterText(find.widgetWithText(TextField, 'Avg (Yds)'), '150');
    await tester.tap(find.text('Save Drill Session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final saved = await tester.runAsync(() => db.listRangeDrills());
    expect(saved!.first.drill.drillId, 'rng-drl-tempo-3to1');

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Text && widget.data == '3:1 Tour Tempo Rhythm'),
        findsNothing);
    expect(find.text('3:1 Tour Tempo Rhythm'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Avg (Yds)'), '140');
    await tester.tap(find.text('Save Drill Session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final cleared = await tester.runAsync(() => db.listRangeDrills());
    expect(cleared!.first.drill.drillId, isNull);

    await tester.tap(find.byKey(const ValueKey('range-header-drills-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    final tempoChip =
        find.byKey(ValueKey(practiceDrillChipKey('Full Swing & Tempo')));
    await tester.ensureVisible(tempoChip);
    await tester.tap(tempoChip);
    await tester.pump();
    final tempoRow =
        find.byKey(const ValueKey('range-drill-row-rng-drl-tempo-3to1'));
    await tester.ensureVisible(tempoRow);
    await tester.tap(tempoRow);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('range-drill-delete-btn')));
    await tester.pump();
    expect(find.text('Remove this drill?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.byKey(const ValueKey('range-drill-row-rng-drl-tempo-3to1')),
        findsNothing);

    await tester.runAsync(() async {
      for (final drill in await db.listPracticeDrills()) {
        await db.deletePracticeDrill(drill.id);
      }
    });
    Navigator.of(
            tester.element(find.byKey(const ValueKey('range-drills-sheet'))))
        .pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('range-header-drills-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text('No drills in this list. Add one.'), findsOneWidget);
  });
}
