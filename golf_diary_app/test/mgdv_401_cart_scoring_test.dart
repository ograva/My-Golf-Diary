import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/scorecard_preferences.dart';
import 'package:golf_diary_app/screens/scorecard_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/pin_distance.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv401.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_mgdv401.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  test('catalogTeeToGreenYards returns yards for Club Intramuros hole 1', () {
    final yards =
        catalogTeeToGreenYards('Club Intramuros Golf Course', 1);
    expect(yards, isNotNull);
    expect(yards, greaterThan(50));
  });

  test('incrementStrokes creates row and adds stroke', () async {
    await useFreshDatabase();
    addTearDown(restoreDatabase);
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(
      courseName: 'Club Intramuros Golf Course',
      par: 3,
    );
    await db.incrementStrokes(
      roundId: roundId,
      courseName: 'Club Intramuros Golf Course',
      holeNumber: 1,
    );
    final row = await db.getHoleScore(roundId, 1);
    expect(row, isNotNull);
    expect(row!.strokes, 1);
    expect(row.finalScore, 1);
  });

  testWidgets('cart scoring +1 updates stroke count', (tester) async {
    await tester.runAsync(() async {
      await useFreshDatabase();
      final db = LocalDatabaseService.instance;
      await db.saveGolferProfile(
        (await db.getGolferProfile())
            .copyWith(scorecardViewMode: ScorecardViewMode.cart),
      );
      final roundId = await db.startNewRound(
        courseName: 'Club Intramuros Golf Course',
        par: 3,
      );
      expect(roundId, isNotEmpty);
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: const ScorecardScreen(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('scorecard-cart-stroke-plus')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-cart-stroke-count')), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scorecard-cart-stroke-plus')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
  });

  test('scorecard view mode persists in golfer_profile', () async {
    await useFreshDatabase();
    addTearDown(restoreDatabase);
    final db = LocalDatabaseService.instance;
    await db.saveGolferProfile(
      (await db.getGolferProfile())
          .copyWith(scorecardViewMode: ScorecardViewMode.cart),
    );
    final profile = await db.getGolferProfile();
    expect(profile.scorecardViewMode, ScorecardViewMode.cart);
  });
}