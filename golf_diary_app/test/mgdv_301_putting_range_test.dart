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
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv3.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_mgdv3.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  testWidgets('putting drill shows putter and hides driver in club strip',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await useFreshDatabase();
      expect((await db.getAllClubs()).map((c) => c.id), contains('driver'));
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.pumpWidget(
        MaterialApp(theme: buildGolfTheme(), home: const RangeDrillScreen()));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text('Driver'), findsWidgets);
    expect(find.text('Putter'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('range-header-drills-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    final puttingChip = find.byKey(ValueKey(practiceDrillChipKey('Putting')));
    await tester.ensureVisible(puttingChip);
    await tester.tap(puttingChip);
    await tester.pump();

    final row = find
        .byKey(const ValueKey('range-drill-row-rng-drl-putt-gate-startline'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('range-drill-use-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('range-putting-yardage-hint')),
        findsOneWidget);
    expect(find.text('Putter'), findsWidgets);
    expect(find.text('Driver'), findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('range-usual-yards-field')), '1');
    await tester.tap(find.text('Save Drill Session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final saved = await tester.runAsync(() => db.listRangeDrills());
    expect(saved!.first.drill.clubId, 'putter');
    expect(saved.first.drill.drillId, 'rng-drl-putt-gate-startline');
  });
}
