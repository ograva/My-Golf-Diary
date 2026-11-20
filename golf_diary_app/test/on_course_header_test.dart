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
    testWidgets('$tier: book icon sits left of the avatar; menu has no Diary',
        (tester) async {
      await pumpOnCourse(tester, tier: tier);

      expect(key('oncourse-diary-edge-swipe'), findsNothing);
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(key('diary-entry-on-course'), findsOneWidget);
      expect(key('on-course-invite-caddy'), findsNothing);
      expect(menuButton, findsOneWidget);

      final menu = tester.getRect(menuButton);
      final diary = tester.getRect(key('diary-entry-on-course'));
      final avatar =
          tester.getRect(find.byKey(const Key('account-avatar-button')));
      expect(menu.left, lessThan(24));
      expect(menu.right, lessThan(tester.getRect(find.text('On Course')).left));
      expect(diary.center.dx, greaterThan(390 / 2));
      expect(diary.right, lessThanOrEqualTo(avatar.left + 1));
      expect(diary.width, greaterThanOrEqualTo(48));
      expect(diary.height, greaterThanOrEqualTo(48));
      expect(avatar.left, greaterThan(390 / 2));

      await tester.tap(menuButton);
      await settle(tester);
      expect(find.text('Diary'), findsNothing);
      expect(find.text('Swing diary'), findsNothing);
      expect(key('diary-entry-on-course'), findsOneWidget);
      expect(key('on-course-invite-caddy'), findsOneWidget);
      expect(find.text('Invite caddy'), findsOneWidget);
    });
  }

  testWidgets('header book icon opens the diary sheet', (tester) async {
    await pumpOnCourse(tester);
    await tester.tap(key('diary-entry-on-course'));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsOneWidget);
    await closeDiary(tester);
    expect(find.byType(SwingDiarySheet), findsNothing);
  });

  testWidgets('a right-edge swipe does not open the diary', (tester) async {
    await pumpOnCourse(tester);
    await tester.dragFrom(const Offset(388, 420), const Offset(-160, 0));
    await settle(tester);
    expect(find.byType(SwingDiarySheet), findsNothing);
  });
}
