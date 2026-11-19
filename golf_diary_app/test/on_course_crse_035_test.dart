import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

import 'support/on_course_test_helpers.dart';

const kNavBarHeight = 80.0;

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
    // Mirrors HomeShell: the bottom NavigationBar takes 80dp under the screen.
    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: Scaffold(
        body: const FairwayTrackerScreen(),
        bottomNavigationBar: const SizedBox(height: kNavBarHeight),
      ),
    ));
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
  const fold = 844 - kNavBarHeight;

  testWidgets('Simulator core loop fits 390x844 without scrolling',
      (tester) async {
    await pumpOnCourse(tester);
    await selectSimulator(tester);

    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0);

    for (final id in [
      'oncourse-course-summary',
      'oncourse-mode-simulator',
      'on-course-hole-label',
      'oncourse-par-summary',
      'oncourse-hole-stats-row',
      'oncourse-club-summary',
      'oncourse-lie-summary',
      'oncourse-sim-yards-field',
      'oncourse-sim-carry-chip',
      'oncourse-sim-to-hole-chip',
      'oncourse-sim-notes-chip',
      'oncourse-penalty-step-up',
      'oncourse-mulligan-step-up',
      'oncourse-record-shot-btn',
      'oncourse-concede-btn',
      'oncourse-finish-hole-btn',
    ]) {
      final rect = tester.getRect(key(id));
      expect(rect.top, greaterThanOrEqualTo(0), reason: id);
      expect(rect.bottom, lessThanOrEqualTo(fold), reason: id);
      expect(rect.right, lessThanOrEqualTo(390), reason: id);
    }

    final record = tester.getRect(key('oncourse-record-shot-btn'));
    final concede = tester.getRect(key('oncourse-concede-btn'));
    final finish = tester.getRect(key('oncourse-finish-hole-btn'));
    expect(concede.top, greaterThan(record.bottom));
    expect(concede.top - record.bottom, lessThanOrEqualTo(12));
    expect(finish.top, concede.top);

    final club = tester.getRect(key('oncourse-club-summary'));
    final lie = tester.getRect(key('oncourse-lie-summary'));
    expect((club.center.dy - lie.center.dy).abs(), lessThan(1));
    expect(club.height, greaterThanOrEqualTo(56));
    expect(lie.height, greaterThanOrEqualTo(56));
    expect(club.left, lessThan(32));
    expect(lie.right, greaterThan(390 - 32));
    expect(club.width, greaterThan(140));
    expect(lie.width, greaterThan(140));

    final penaltyUp = tester.getRect(key('oncourse-penalty-step-up'));
    final mulliganUp = tester.getRect(key('oncourse-mulligan-step-up'));
    expect(mulliganUp.top, greaterThanOrEqualTo(penaltyUp.bottom));
    expect(penaltyUp.right, greaterThan(390 - 40));
    expect(mulliganUp.right, greaterThan(390 - 40));
    expect(tester.getRect(find.text('Penalty')).left, lessThan(40));
    expect(tester.getRect(find.text('Mulligan')).left, lessThan(40));

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

  testWidgets('stroke log follows Concede | Finish Hole below the fold',
      (tester) async {
    await pumpOnCourse(tester);
    await selectSimulator(tester);
    await tester.enterText(key('oncourse-sim-yards-field'), '150');
    await tester.tap(key('oncourse-record-shot-btn'));
    await waitForDb(tester);

    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0);
    expect(tester.getRect(key('oncourse-record-shot-btn')).bottom,
        lessThanOrEqualTo(fold));
    expect(tester.getRect(key('oncourse-finish-hole-btn')).bottom,
        lessThanOrEqualTo(fold));

    await expandShotList(tester);
    final finish = tester.getRect(key('oncourse-finish-hole-btn'));
    final log = tester.getRect(key('oncourse-shots-list-expander'));
    expect(log.top, greaterThanOrEqualTo(finish.bottom));
    expect(log.top - finish.bottom, lessThanOrEqualTo(16));
    expect(key('oncourse-shot-row-1'), findsOneWidget);
  });

  testWidgets('course meta sits on its own line under the course name',
      (tester) async {
    await pumpOnCourse(tester);

    await submitCourseName(tester, 'Club Intramuros Golf Course');
    await waitForDb(tester);

    final summary = tester.getRect(key('oncourse-course-summary'));
    final meta = tester.getRect(key('oncourse-course-meta'));
    final toggle = tester.getRect(key('oncourse-mode-toggle'));
    expect(find.text('18 holes · Par 66'), findsOneWidget);
    expect(meta.top, greaterThanOrEqualTo(summary.bottom - 1));
    expect(meta.left, lessThan(summary.left + 8));
    expect(
        find.descendant(
            of: key('oncourse-course-summary'),
            matching: find.text('18 holes · Par 66')),
        findsNothing);
    expect((toggle.center.dy - summary.center.dy).abs(), lessThan(4));
    expect(toggle.bottom, lessThanOrEqualTo(meta.top + 1));
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
    await selectSimulator(tester);
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
    await selectSimulator(tester);
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
