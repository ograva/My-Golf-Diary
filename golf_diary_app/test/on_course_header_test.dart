import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/services/diary_model.dart';
import 'package:golf_diary_app/services/golfer_profile_store.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/swing_diary_sheet.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class _QuietDiaryModel implements DiaryModel {
  @override
  bool get available => true;

  @override
  String get modelName => 'test-model';

  @override
  String get location => 'global';

  @override
  Stream<String> generate(String prompt,
          {String? systemInstruction, DiaryCancel? cancel}) =>
      const Stream.empty();

  @override
  Future<String?> generateJson({
    required String prompt,
    required String systemInstruction,
    Schema? responseSchema,
    DiaryCancel? cancel,
  }) async =>
      null;
}

void main() {
  const dbName = 'golf_diary_on_course_header.db';

  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(dbName);
    await deleteDatabase(join(await getDatabasesPath(), dbName));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Finder key(String value) => find.byKey(ValueKey(value));
  final menuButton = find.byKey(const Key('shell-header-overflow-btn'));

  Future<void> pumpOnCourse(WidgetTester tester, {String? tier}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = GolferProfileStore()
      ..profile = GolferProfile(skillTier: tier ?? GolferSkillTier.amateur);
    await tester.pumpWidget(MaterialApp(
      theme: buildGolfTheme(),
      home: GolferProfileScope(
        store: store,
        child: FairwayTrackerScreen(diary: _QuietDiaryModel()),
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> closeDiary(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(SwingDiarySheet))).pop();
    await settle(tester);
  }

  for (final tier in [
    GolferSkillTier.beginner,
    GolferSkillTier.amateur,
    GolferSkillTier.seasonedPro,
  ]) {
    testWidgets('$tier: settings menu sits left with Diary and Invite caddy',
        (tester) async {
      await pumpOnCourse(tester, tier: tier);

      expect(find.byIcon(Icons.auto_stories_outlined), findsNothing);
      expect(key('on-course-invite-caddy'), findsNothing);
      expect(menuButton, findsOneWidget);
      final menu = tester.getRect(menuButton);
      expect(menu.right, lessThan(tester.getRect(find.text('On Course')).left));
      expect(menu.left, lessThan(24));
      expect(
          tester.getRect(find.byKey(const Key('account-avatar-button'))).left,
          greaterThan(390 / 2));

      await tester.tap(menuButton);
      await settle(tester);
      expect(key('diary-entry-on-course'), findsOneWidget);
      expect(find.text('Diary'), findsOneWidget);
      expect(key('on-course-invite-caddy'), findsOneWidget);
      expect(find.text('Invite caddy'), findsOneWidget);
    });
  }

  testWidgets('Diary menu item opens the diary sheet', (tester) async {
    await pumpOnCourse(tester);
    await tester.tap(menuButton);
    await settle(tester);
    await tester.tap(key('diary-entry-on-course'));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsOneWidget);
    await closeDiary(tester);
  });

  testWidgets('swiping in from the right edge opens the diary', (tester) async {
    await pumpOnCourse(tester);
    expect(key('oncourse-diary-edge-swipe'), findsOneWidget);

    await tester.dragFrom(const Offset(388, 420), const Offset(-160, 0));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsOneWidget);
    await closeDiary(tester);
    expect(find.byType(SwingDiarySheet), findsNothing);
  });

  testWidgets('swipes away from the edge and vertical edge drags do not',
      (tester) async {
    await pumpOnCourse(tester);

    await tester.dragFrom(const Offset(250, 420), const Offset(-160, 0));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsNothing);

    await tester.dragFrom(const Offset(388, 500), const Offset(0, -200));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsNothing);

    await tester.dragFrom(const Offset(388, 420), const Offset(40, 0));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsNothing);
  });

  testWidgets('edge strip lets taps reach controls under it', (tester) async {
    await pumpOnCourse(tester);
    await tester.tap(key('oncourse-mode-simulator'));
    await tester.pump();
    final plus = tester.getRect(key('oncourse-mulligan-step-up'));
    final strip = tester.getRect(key('oncourse-diary-edge-swipe'));
    await tester.tapAt(Offset(plus.right - 2, plus.center.dy));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(tester.widget<Text>(key('oncourse-mulligan-count')).data, '1');
    expect(find.byType(SwingDiarySheet), findsNothing);
    expect(strip.width, lessThanOrEqualTo(16));
  });
}
