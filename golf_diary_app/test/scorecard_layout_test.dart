import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/scoring_format.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/screens/scorecard_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'support/on_course_test_helpers.dart';

void main() {
  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_scorecard_layout.db');
    await deleteDatabase(join(
      await getDatabasesPath(),
      'golf_diary_scorecard_layout.db',
    ));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  Future<void> pumpScorecard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: const ScorecardScreen(),
      ),
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
  }

  testWidgets('course name opens the shared dialog and shows the format',
      (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(() async {
      await LocalDatabaseService.instance.startNewRound(courseName: 'Local Course');
    });

    await pumpScorecard(tester);

    expect(find.byKey(const ValueKey('scorecard-course-summary')), findsOneWidget);
    expect(find.text('Gross'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-attest-btn')), findsNothing);
    expect(find.byKey(const ValueKey('scorecard-view-mode-toggle')), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scorecard-course-summary')));
    await settleSheet(tester);
    expect(find.text('Course'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-format-toggle')), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.ensureVisible(find.text('Molave'));
    await tester.tap(find.text('Molave'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('scorecard-double-eagle-6')));
    await tester.pump();
    await saveCourseDialog(tester);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Molave · double eagle 6'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-format-toggle')), findsNothing);

    await tester.tap(find.byKey(const Key('shell-header-overflow-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scorecard-flight-btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-invite-caddy')), findsOneWidget);
  });

  testWidgets('attest appears only after every hole is played', (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(() async {
      final db = LocalDatabaseService.instance;
      final roundId = await db.startNewRound(courseName: 'Local Course');
      for (var hole = 1; hole <= 18; hole++) {
        await db.incrementStrokes(
          roundId: roundId,
          courseName: 'Local Course',
          holeNumber: hole,
        );
      }
    });

    await pumpScorecard(tester);

    expect(find.byKey(const ValueKey('scorecard-attest-badge')), findsOneWidget);
    expect(find.text('Not attested'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-attest-btn')), findsOneWidget);
    expect(find.text('Gross'), findsWidgets);
  });

  testWidgets('On Course confirm writes the format onto the active round',
      (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: const FairwayTrackerScreen(),
    ));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Driver').evaluate().isNotEmpty) break;
    }

    await tester.tap(find.byKey(const ValueKey('oncourse-course-summary')));
    await settleSheet(tester);
    expect(find.text('Course'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-format-toggle')), findsOneWidget);
    await tester.tap(find.text('System 36'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('scorecard-course-rating')),
      '71.2',
    );
    await tester.enterText(find.byKey(const ValueKey('scorecard-slope')), '128');
    await saveCourseDialog(tester);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    final db = LocalDatabaseService.instance;
    final roundId = await db.getActiveRoundId();
    final settings = await db.getRoundFormat(roundId!);
    expect(settings.format, ScoringFormat.system36);
    expect(settings.courseRating, closeTo(71.2, 0.001));
    expect(settings.slopeRating, 128);
    expect(find.byKey(const ValueKey('oncourse-course-sheet')), findsNothing);
  });
}
