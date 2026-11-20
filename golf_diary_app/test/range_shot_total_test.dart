import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

void main() {
  test('shot total cycles 10 then 3 then 5 then 10', () {
    expect(kRangeShotTotals, [10, 3, 5]);
    expect(nextRangeShotTotal(10), 3);
    expect(nextRangeShotTotal(3), 5);
    expect(nextRangeShotTotal(5), 10);
    expect(nextRangeShotTotal(7), 10);
  });

  var databaseSerial = 0;

  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    databaseSerial += 1;
    LocalDatabaseService.debugSetFileName(
      'golf_diary_shot_total_$databaseSerial.db',
    );
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  Future<void> pumpRange(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildGolfTheme(), home: const RangeDrillScreen()),
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.byType(ChoiceChip).evaluate().isNotEmpty) return;
    }
    fail('Range club chips did not load');
  }

  Future<void> releaseScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await LocalDatabaseService.debugClose();
    });
  }

  Finder totalControl() => find.byKey(const ValueKey('range-shot-total'));

  ElevatedButton hitShotButton(WidgetTester tester) {
    return tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Hit Shot'),
    );
  }

  void usePhoneWidth(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('range total-shots tap cycles 10, 3, 5, and back to 10',
      (tester) async {
    usePhoneWidth(tester);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));

    await pumpRange(tester);

    expect(find.text('Balls hit: 0 / 10'), findsOneWidget);
    expect(totalControl(), findsOneWidget);

    await tester.ensureVisible(totalControl());
    await tester.tap(totalControl());
    await tester.pump();
    expect(find.text('Balls hit: 0 / 3'), findsOneWidget);

    await tester.tap(totalControl());
    await tester.pump();
    expect(find.text('Balls hit: 0 / 5'), findsOneWidget);

    await tester.tap(totalControl());
    await tester.pump();
    expect(find.text('Balls hit: 0 / 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await releaseScreen(tester);
  });

  testWidgets('hit shot stays capped at the selected total', (tester) async {
    usePhoneWidth(tester);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));

    await pumpRange(tester);
    await tester.ensureVisible(totalControl());
    await tester.tap(totalControl());
    await tester.pump();

    final hit = find.widgetWithText(ElevatedButton, 'Hit Shot');
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(hit);
      await tester.tap(hit);
      await tester.pump();
    }
    expect(find.text('Balls hit: 3 / 3'), findsOneWidget);
    expect(hitShotButton(tester).onPressed, isNull);

    await tester.tap(totalControl());
    await tester.pump();
    expect(find.text('Balls hit: 3 / 5'), findsOneWidget);
    expect(hitShotButton(tester).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await releaseScreen(tester);
  });

  testWidgets('logging uses the selected total when no balls were counted',
      (tester) async {
    usePhoneWidth(tester);
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));

    await pumpRange(tester);
    await tester.ensureVisible(totalControl());
    await tester.tap(totalControl());
    await tester.tap(totalControl());
    await tester.pump();
    expect(find.text('Balls hit: 0 / 5'), findsOneWidget);

    final save = find.text('Save Drill Session');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    expect(find.textContaining('Saved drill'), findsOneWidget);

    final drills = await tester.runAsync(
        () => LocalDatabaseService.instance.listRangeDrills());
    expect(drills, isNotNull);
    expect(drills!.single.drill.shotCount, 5);

    final hit = find.widgetWithText(ElevatedButton, 'Hit Shot');
    await tester.ensureVisible(hit);
    await tester.tap(hit);
    await tester.tap(hit);
    await tester.pump();
    expect(find.text('Balls hit: 2 / 5'), findsOneWidget);

    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();

    final afterHits = await tester.runAsync(
        () => LocalDatabaseService.instance.listRangeDrills());
    expect(afterHits!.first.drill.shotCount, 2);
    expect(tester.takeException(), isNull);
    await releaseScreen(tester);
  });
}
