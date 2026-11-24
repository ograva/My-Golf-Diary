import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/scorecard_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'support/on_course_test_helpers.dart';

void main() {
  const file = 'golf_diary_scorecard_controls.db';
  final db = LocalDatabaseService.instance;

  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(file);
    await deleteDatabase(join(await getDatabasesPath(), file));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settleSheet(tester);
  }

  Future<void> pumpScorecard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: buildGolfTheme(), home: const ScorecardScreen()),
    );
    await settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<String> roundWithHoles(int played) async {
    final roundId = await db.startNewRound(courseName: 'Local Course');
    for (var hole = 1; hole <= played; hole++) {
      await db.incrementStrokes(
        roundId: roundId,
        courseName: 'Local Course',
        holeNumber: hole,
      );
    }
    return roundId;
  }

  testWidgets('blank holes confirm before finishing; cancel keeps it open',
      (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    late String roundId;
    await tester.runAsync(() async => roundId = await roundWithHoles(2));
    await pumpScorecard(tester);

    expect(find.text('In progress'), findsOneWidget);
    await tapKey(tester, 'scorecard-finish-round');
    expect(find.text('16 holes blank, finish anyway?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(await tester.runAsync(() => db.isRoundCompleted(roundId)), isFalse);

    await tapKey(tester, 'scorecard-finish-round');
    await tapKey(tester, 'scorecard-finish-confirm');
    expect(find.byKey(const ValueKey('scorecard-attest-name')), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tapKey(tester, 'scorecard-attest-skip');

    expect(await tester.runAsync(() => db.isRoundCompleted(roundId)), isTrue);
    expect(find.byKey(const ValueKey('scorecard-finish-round')), findsNothing);
    expect(find.text('Not attested'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-attest-btn')), findsOneWidget);
    expect(find.text('Finished · read-only'), findsOneWidget);
  });

  testWidgets(
      'a full card finishes straight to attest, then stays read-only until unlocked',
      (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    late String roundId;
    await tester.runAsync(() async => roundId = await roundWithHoles(18));
    await pumpScorecard(tester);

    await tapKey(tester, 'scorecard-finish-round');
    expect(
        find.byKey(const ValueKey('scorecard-finish-confirm')), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('scorecard-attest-name')), 'Pat');
    await tapKey(tester, 'scorecard-attest-save');
    expect(find.text('Attested by Pat · self'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-attest-btn')), findsNothing);

    await tapKey(tester, 'scorecard-hole-tile-3');
    expect(find.byKey(const ValueKey('scorecard-read-only-snack')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-attest-edit-confirm')),
        findsNothing);

    await tester.tap(find.byKey(const Key('shell-header-overflow-btn')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('scorecard-edit-finished-round')));
    await settle(tester);
    expect(find.text('Finished · editing'), findsOneWidget);

    await tapKey(tester, 'scorecard-hole-tile-3');
    await tapKey(tester, 'scorecard-attest-edit-confirm');
    final settings = await tester.runAsync(() => db.getRoundFormat(roundId));
    expect(settings!.isAttested, isFalse);
    expect(settings.editedAfterAttestCount, 1);
    expect(await tester.runAsync(() => db.isRoundCompleted(roundId)), isTrue);
  });

  testWidgets(
      'delete confirms, warns on attested rounds, then selects the next',
      (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    late String older;
    late String newer;
    await tester.runAsync(() async {
      older = await roundWithHoles(1);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      newer = await roundWithHoles(18);
      await db.completeRound(newer);
      await db.attestRound(roundId: newer, name: 'Pat', role: 'marker');
    });
    await pumpScorecard(tester);
    expect(find.byKey(ValueKey('scorecard-round-chip-$newer')), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('scorecard-round-chip-$newer')));
    await settle(tester);
    await tapKey(tester, 'scorecard-delete-round');
    expect(find.text('Delete round?'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('scorecard-delete-warning')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.byKey(ValueKey('scorecard-round-chip-$newer')), findsOneWidget);

    await tapKey(tester, 'scorecard-delete-round');
    await tapKey(tester, 'scorecard-delete-confirm');
    expect(find.byKey(ValueKey('scorecard-round-chip-$newer')), findsNothing);
    expect(find.text('In progress'), findsOneWidget);
    final remaining = await tester.runAsync(() => db.listRecentRounds());
    expect(remaining!.map((r) => r.roundId), [older]);

    await tapKey(tester, 'scorecard-delete-round');
    expect(
        find.byKey(const ValueKey('scorecard-delete-warning')), findsNothing);
    await tapKey(tester, 'scorecard-delete-confirm');
    expect(find.byKey(const ValueKey('scorecard-empty-state')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-delete-round')), findsNothing);
  });
}
