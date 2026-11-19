import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/screens/clubs_screen.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  Finder yardageLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
  }

  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv203.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_mgdv203.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  testWidgets('beginner bag shows usual hero and Shortest labels in details',
      (tester) async {
    final db = LocalDatabaseService.instance;
    await tester.runAsync(() async {
      await useFreshDatabase();
      await db.saveGolferProfile(
        const GolferProfile(
          skillTier: GolferSkillTier.beginner,
          yardageDisplayMode: YardageDisplayMode.followSkillTier,
          onboardingCompleted: 1,
        ),
      );
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: const ClubsScreen(),
      ),
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle();

    expect(find.text('Min'), findsNothing);
    expect(find.byKey(const ValueKey('bag-hero-yards-driver')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('bag-details-btn-driver')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bag-details-btn-driver')));
    await tester.pumpAndSettle();

    expect(find.text('Shortest'), findsOneWidget);
    expect(find.text('Usual'), findsWidgets);
    expect(find.text('Best'), findsOneWidget);
  });

  testWidgets('full yardage mode shows Min Avg Max on bag row', (tester) async {
    final db = LocalDatabaseService.instance;
    await tester.runAsync(() async {
      await useFreshDatabase();
      await db.saveGolferProfile(
        const GolferProfile(
          skillTier: GolferSkillTier.seasonedPro,
          yardageDisplayMode: YardageDisplayMode.full,
          onboardingCompleted: 1,
        ),
      );
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: const ClubsScreen(),
      ),
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle();

    expect(find.text('Min'), findsAtLeastNWidgets(1));
    expect(find.text('Avg'), findsAtLeastNWidgets(1));
    expect(find.text('Max'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('bag-details-btn-driver')), findsNothing);
  });

  testWidgets('range simple mode hides min max until More numbers',
      (tester) async {
    final db = LocalDatabaseService.instance;
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await useFreshDatabase();
      await db.saveGolferProfile(
        const GolferProfile(
          skillTier: GolferSkillTier.beginner,
          yardageDisplayMode: YardageDisplayMode.simple,
          onboardingCompleted: 1,
        ),
      );
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: const RangeDrillScreen(),
      ),
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle();

    expect(find.text('Range'), findsOneWidget);
    expect(find.text('Range Drill Instructor'), findsNothing);
    expect(yardageLabel('Min (yds)'), findsNothing);
    expect(
        find.byKey(const ValueKey('range-usual-yards-field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('range-yardage-mode-expand')));
    await tester.pumpAndSettle();

    expect(yardageLabel('Shortest (yds)'), findsOneWidget);
    expect(yardageLabel('Best (yds)'), findsOneWidget);
  });

  testWidgets('simple range save with usual only updates club average',
      (tester) async {
    final db = LocalDatabaseService.instance;
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await useFreshDatabase();
      await db.saveGolferProfile(
        const GolferProfile(
          skillTier: GolferSkillTier.beginner,
          yardageDisplayMode: YardageDisplayMode.simple,
          onboardingCompleted: 1,
        ),
      );
    });
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: const RangeDrillScreen(),
      ),
    );
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('range-usual-yards-field')), '200');
    final save = find.text('Save Drill Session');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump();

    final clubs = await tester.runAsync(db.getAllClubs);
    expect(clubs, isNotNull);
    final driver = clubs!.firstWhere((c) => c.id == 'driver');
    expect(driver.avgDistance, 210);
  });
}
