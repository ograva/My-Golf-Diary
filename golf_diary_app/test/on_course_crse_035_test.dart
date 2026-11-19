import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

import 'support/on_course_test_helpers.dart';

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_crse035.db');
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Future<void> pumpOnCourse(WidgetTester tester,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: buildGolfTheme(), home: const FairwayTrackerScreen()));
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Driver').evaluate().isNotEmpty) return;
    }
    fail('On Course did not load the bag');
  }

  Future<void> waitForDb(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
  }

  Finder key(String value) => find.byKey(ValueKey(value));

  testWidgets('Simulator core loop fits 390x844 without scrolling',
      (tester) async {
    await pumpOnCourse(tester);
    await selectSimulator(tester);

    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0);

    final dockTop = tester.getRect(key('oncourse-record-shot-btn')).top;
    expect(tester.getRect(key('oncourse-record-shot-btn')).bottom,
        lessThanOrEqualTo(844));
    for (final id in [
      'oncourse-course-summary',
      'on-course-hole-label',
      'oncourse-par-summary',
      'oncourse-mode-simulator',
      'oncourse-club-summary',
      'oncourse-lie-summary',
      'oncourse-sim-yards-field',
      'oncourse-sim-carry-chip',
      'oncourse-sim-to-hole-chip',
      'oncourse-sim-notes-chip',
      'oncourse-penalty-step-up',
      'oncourse-mulligan-step-up',
    ]) {
      final rect = tester.getRect(key(id));
      expect(rect.bottom, lessThanOrEqualTo(dockTop), reason: id);
      expect(rect.top, greaterThanOrEqualTo(0), reason: id);
      expect(rect.right, lessThanOrEqualTo(390), reason: id);
    }

    final record = tester.getRect(key('oncourse-record-shot-btn'));
    final concede = tester.getRect(key('oncourse-concede-btn'));
    final finish = tester.getRect(key('oncourse-finish-hole-btn'));
    expect(concede.top, greaterThan(record.bottom));
    expect(concede.top - record.bottom, lessThanOrEqualTo(12));
    expect(finish.top, concede.top);
    expect(finish.bottom, lessThanOrEqualTo(844));

    final holeRow = tester.getRect(key('on-course-hole-label'));
    final par = tester.getRect(key('oncourse-par-summary'));
    final stats = tester.getRect(key('oncourse-hole-stats-row'));
    expect((par.center.dy - holeRow.center.dy).abs(), lessThan(4));
    expect(stats.top, greaterThanOrEqualTo(holeRow.bottom - 1));
    expect(stats.bottom,
        lessThanOrEqualTo(tester.getRect(key('oncourse-club-summary')).top));

    final summary = tester.getRect(key('oncourse-course-summary'));
    final toggle = tester.getRect(key('oncourse-mode-toggle'));
    expect(find.byType(SegmentedButton<bool>), findsOneWidget);
    expect((toggle.center.dy - summary.center.dy).abs(), lessThan(4));
    expect(toggle.left, greaterThan(summary.right));
    expect(toggle.right, greaterThan(390 - 20));
    expect(find.text('FWY'), findsOneWidget);
    expect(find.text('SIM'), findsOneWidget);
    expect(find.bySemanticsLabel('Fairway'), findsOneWidget);
    expect(find.bySemanticsLabel('Simulator'), findsOneWidget);

    expect(key('oncourse-sim-carry-field'), findsNothing);
    expect(key('oncourse-sim-distance-to-hole-field'), findsNothing);
    expect(key('oncourse-sim-stroke-note-field'), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('optional chips reveal fields and hide clears them',
      (tester) async {
    await pumpOnCourse(tester);
    await selectSimulator(tester);

    await tester.tap(key('oncourse-sim-carry-chip'));
    await tester.pump();
    await tester.enterText(key('oncourse-sim-carry-field'), '130');
    await tester.tap(key('oncourse-sim-to-hole-chip'));
    await tester.pump();
    expect(key('oncourse-sim-distance-to-hole-field'), findsOneWidget);

    await tester.tap(key('oncourse-sim-carry-hide-btn'));
    await tester.pump();
    expect(key('oncourse-sim-carry-field'), findsNothing);
    expect(tester.widget<FilterChip>(key('oncourse-sim-carry-chip')).selected,
        isFalse);

    await tester.tap(key('oncourse-sim-carry-chip'));
    await tester.pump();
    expect(
        tester
            .widget<TextField>(key('oncourse-sim-carry-field'))
            .controller!
            .text,
        isEmpty);

    await tester.tap(key('oncourse-sim-to-hole-hide-btn'));
    await tester.pump();
    expect(key('oncourse-sim-distance-to-hole-field'), findsNothing);
    expect(tester.widget<FilterChip>(key('oncourse-sim-to-hole-chip')).selected,
        isFalse);
  });

  testWidgets('club sheet lists recent clubs and closes on one tap',
      (tester) async {
    await pumpOnCourse(tester);
    await selectSimulator(tester);
    await tester.enterText(key('oncourse-sim-yards-field'), '210');
    await tester.tap(key('oncourse-record-shot-btn'));
    await waitForDb(tester);

    await tester.tap(key('oncourse-club-summary'));
    await settleSheet(tester);
    expect(key('oncourse-club-sheet'), findsOneWidget);
    expect(key('oncourse-club-recent-driver'), findsOneWidget);

    final allChips = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>)
            .value
            .startsWith('oncourse-club-sheet-chip-') &&
        (w.key as ValueKey<String>).value != 'oncourse-club-sheet-chip-driver');
    final target = tester.widget<ChoiceChip>(allChips.first);
    final targetName = (target.label as Text).data!;
    await tester.tap(allChips.first);
    await settleSheet(tester);

    expect(key('oncourse-club-sheet'), findsNothing);
    expect(
        find.descendant(
            of: key('oncourse-club-summary'), matching: find.text(targetName)),
        findsOneWidget);

    await tester.tap(key('oncourse-lie-summary'));
    await settleSheet(tester);
    expect(key('oncourse-lie-sheet'), findsOneWidget);
    await tester.tap(key('oncourse-lie-chip-rough'));
    await settleSheet(tester);
    expect(key('oncourse-lie-sheet'), findsNothing);
    expect(
        find.descendant(
            of: key('oncourse-lie-summary'), matching: find.text('Rough')),
        findsOneWidget);
  });

  testWidgets('penalty and mulligan steppers count up and down',
      (tester) async {
    await pumpOnCourse(tester);
    String count(String id) => tester.widget<Text>(key(id)).data!;

    expect(count('oncourse-penalty-count'), '0');
    expect(
        tester.widget<IconButton>(key('oncourse-penalty-step-down')).onPressed,
        isNull);

    await tester.tap(key('oncourse-penalty-step-up'));
    await waitForDb(tester);
    await tester.tap(key('oncourse-penalty-step-up'));
    await waitForDb(tester);
    expect(count('oncourse-penalty-count'), '2');
    await tester.tap(key('oncourse-penalty-step-down'));
    await waitForDb(tester);
    expect(count('oncourse-penalty-count'), '1');

    await tester.tap(key('oncourse-mulligan-step-up'));
    await waitForDb(tester);
    expect(count('oncourse-mulligan-count'), '1');
    await tester.tap(key('oncourse-mulligan-step-down'));
    await waitForDb(tester);
    expect(count('oncourse-mulligan-count'), '0');
  });

  testWidgets('hole label opens the hole sheet and jumps holes',
      (tester) async {
    await pumpOnCourse(tester, size: const Size(390, 1000));
    await tester.tap(key('oncourse-finish-hole-btn'));
    await waitForDb(tester);
    expect(find.text('Hole 2'), findsOneWidget);

    await tester.tap(key('on-course-hole-label'));
    await settleSheet(tester);
    expect(key('oncourse-hole-sheet'), findsOneWidget);
    await tester.tap(key('oncourse-hole-sheet-chip-1'));
    await settleSheet(tester);
    await waitForDb(tester);
    expect(key('oncourse-hole-sheet'), findsNothing);
    expect(find.text('Hole 1'), findsOneWidget);
  });
}
