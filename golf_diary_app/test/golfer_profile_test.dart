import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/services/diary_model.dart';
import 'package:golf_diary_app/services/golfer_profile_service.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('lead-in prompts prefer the body and skip dismissed ones', () {
    const fresh = GolferProfile();
    final clubs = [
      Club(id: 'driver', name: 'Driver', category: 'wood'),
    ];
    final prompts = leadInPrompts(
      fresh,
      clubsMissingSpecs: clubsMissingEquipmentSpecs(clubs),
    );
    expect(prompts.map((prompt) => prompt.id).toList(), ['physical', 'swing']);

    final afterBody = leadInPrompts(
      fresh.copyWith(
        physicalConstraints: 'heels',
        dismissedPrompts: const ['swing'],
      ),
      clubsMissingSpecs: true,
    );
    expect(afterBody.map((prompt) => prompt.id).toList(), ['training', 'equipment']);
  });

  test('distillation keeps a filled pillar when the model returns a blank', () {
    const current = GolferProfile(
      swingAnchors: '3:1 tempo',
      physicalConstraints: 'heels',
    );
    final merged = mergeDistilledBaseline(
      current: current,
      distilledThroughMs: 50,
      rawJson: '''
{"equipmentNotes":"Sword Katana","swingAnchors":"","physicalConstraints":"heels and thoracic spine","trainingEnvironment":"","changedSummary":"Added the driver"}
''',
    );
    expect(merged.profile.equipmentNotes, 'Sword Katana');
    expect(merged.profile.swingAnchors, '3:1 tempo');
    expect(merged.profile.physicalConstraints, 'heels and thoracic spine');
    expect(merged.profile.distilledThroughMs, 50);
    expect(merged.changed, isTrue);
    expect(merged.summary, 'Added the driver');
  });

  test('resolveYardageUiDensity honors mode and skill tier', () {
    const beginner = GolferProfile(
      skillTier: GolferSkillTier.beginner,
      yardageDisplayMode: YardageDisplayMode.followSkillTier,
    );
    expect(resolveYardageUiDensity(beginner), YardageUiDensity.simple);

    const amateur = GolferProfile(
      skillTier: GolferSkillTier.amateur,
      yardageDisplayMode: YardageDisplayMode.followSkillTier,
    );
    expect(
      resolveYardageUiDensity(amateur),
      YardageUiDensity.simpleWithExpandHints,
    );

    const proFull = GolferProfile(
      skillTier: GolferSkillTier.seasonedPro,
      yardageDisplayMode: YardageDisplayMode.followSkillTier,
    );
    expect(resolveYardageUiDensity(proFull), YardageUiDensity.full);

    const overrideSimple = GolferProfile(
      skillTier: GolferSkillTier.seasonedPro,
      yardageDisplayMode: YardageDisplayMode.simple,
    );
    expect(resolveYardageUiDensity(overrideSimple), YardageUiDensity.simple);
  });

  test('skill tier and yardage mode persist across getGolferProfile', () async {
    final name = 'golf_diary_profile_v10.db';
    final path = join(await getDatabasesPath(), name);
    await deleteDatabase(path);
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(name);
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });

    const saved = GolferProfile(
      skillTier: GolferSkillTier.amateur,
      yardageDisplayMode: YardageDisplayMode.full,
      age: 40,
      yearsPlaying: 12,
      onboardingCompleted: 1,
    );
    await LocalDatabaseService.instance.saveGolferProfile(saved);
    final loaded = await LocalDatabaseService.instance.getGolferProfile();
    expect(loaded.skillTier, GolferSkillTier.amateur);
    expect(loaded.yardageDisplayMode, YardageDisplayMode.full);
    expect(loaded.age, 40);
  });

  test('version 9 database gains yardage_display_mode at version 10', () async {
    final name = 'golf_diary_profile_v10_upgrade.db';
    final path = join(await getDatabasesPath(), name);
    await deleteDatabase(path);
    final seeded = await openDatabase(path, version: 9, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE golfer_profile (
          id TEXT PRIMARY KEY,
          equipment_notes TEXT NOT NULL DEFAULT '',
          swing_anchors TEXT NOT NULL DEFAULT '',
          physical_constraints TEXT NOT NULL DEFAULT '',
          training_environment TEXT NOT NULL DEFAULT '',
          dismissed_prompts_json TEXT NOT NULL DEFAULT '[]',
          distilled_through_ms INTEGER NOT NULL DEFAULT 0,
          age INTEGER,
          years_playing INTEGER,
          gender TEXT NOT NULL DEFAULT '',
          skill_tier TEXT NOT NULL DEFAULT '',
          onboarding_completed INTEGER NOT NULL DEFAULT 0,
          bag_nickname TEXT NOT NULL DEFAULT '',
          is_synced INTEGER NOT NULL DEFAULT 0,
          updated_at_ms INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
    });
    await seeded.insert('golfer_profile', {
      'id': GolferProfile.rowId,
      'skill_tier': GolferSkillTier.beginner,
      'deleted': 0,
    });
    await seeded.close();

    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(name);
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });

    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.skillTier, GolferSkillTier.beginner);
    expect(profile.yardageDisplayMode, YardageDisplayMode.followSkillTier);
  });

  test('version 8 database gains onboarding columns at version 9', () async {
    final name = 'golf_diary_profile_v9.db';
    final path = join(await getDatabasesPath(), name);
    await deleteDatabase(path);
    final seeded = await openDatabase(path, version: 8, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE golfer_profile (
          id TEXT PRIMARY KEY,
          equipment_notes TEXT NOT NULL DEFAULT '',
          swing_anchors TEXT NOT NULL DEFAULT '',
          physical_constraints TEXT NOT NULL DEFAULT '',
          training_environment TEXT NOT NULL DEFAULT '',
          dismissed_prompts_json TEXT NOT NULL DEFAULT '[]',
          distilled_through_ms INTEGER NOT NULL DEFAULT 0,
          is_synced INTEGER NOT NULL DEFAULT 0,
          updated_at_ms INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
    });
    await seeded.insert('golfer_profile', {
      'id': GolferProfile.rowId,
      'equipment_notes': 'old shaft',
      'deleted': 0,
    });
    await seeded.close();

    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(name);
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });

    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.equipmentNotes, 'old shaft');
    expect(profile.onboardingCompleted, 0);
    expect(profile.age, isNull);
  });

  test('a version 7 database gains golfer_profile and ignores model text', () async {
    final name = 'golf_diary_profile_upgrade.db';
    final path = join(await getDatabasesPath(), name);
    await deleteDatabase(path);
    final seeded = await openDatabase(path, version: 7, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE range_sessions (
          id TEXT PRIMARY KEY,
          venue_name TEXT,
          session_note TEXT,
          compiled_summary_json TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          updated_at_ms INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE range_drills (
          id TEXT PRIMARY KEY,
          club_id TEXT,
          shot_count INTEGER,
          min_yards REAL,
          max_yards REAL,
          avg_yards REAL,
          tempo_notes TEXT,
          venue_name TEXT,
          timestamp INTEGER NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          updated_at_ms INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0,
          session_id TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE clubs (
          id TEXT PRIMARY KEY,
          name TEXT,
          category TEXT,
          brand TEXT,
          model TEXT,
          swing_notes TEXT,
          updated_at_ms INTEGER NOT NULL DEFAULT 0,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE swing_diary_messages (
          id TEXT PRIMARY KEY,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE golf_rounds (
          round_id TEXT PRIMARY KEY,
          course_name TEXT NOT NULL,
          started_at_ms INTEGER NOT NULL,
          deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
    });
    await seeded.insert('range_sessions', {
      'id': 's1',
      'venue_name': 'Villamor',
      'session_note': 'Mats were harsh',
      'compiled_summary_json': '[]',
      'timestamp': 20,
      'deleted': 0,
    });
    await seeded.insert('range_drills', {
      'id': 'd1',
      'tempo_notes': 'Paused at the top',
      'timestamp': 10,
      'deleted': 0,
    });
    await seeded.insert('swing_diary_messages', {
      'id': 'm1',
      'role': 'model',
      'content': 'MODEL GUESS',
      'timestamp': 30,
      'deleted': 0,
    });
    await seeded.insert('swing_diary_messages', {
      'id': 'u1',
      'role': 'user',
      'content': 'Summarize today',
      'timestamp': 31,
      'deleted': 0,
    });
    await seeded.insert('swing_diary_messages', {
      'id': 'u2',
      'role': 'user',
      'content': 'My heel hurt',
      'timestamp': 32,
      'deleted': 0,
    });
    await seeded.insert('golf_rounds', {
      'round_id': 'r1',
      'course_name': 'Club Intramuros',
      'started_at_ms': 1,
      'deleted': 0,
    });
    await seeded.close();

    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(name);
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });

    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.swingAnchors, isEmpty);
    final venues = await LocalDatabaseService.instance.frequentVenueNames();
    expect(venues, containsAll(['Villamor', 'Club Intramuros']));

    final notes = await GolferProfileService(
      model: _SilentModel(),
      database: LocalDatabaseService.instance,
    ).collectUndistilledNotes(profile);
    expect(notes.text, contains('Mats were harsh'));
    expect(notes.text, contains('Paused at the top'));
    expect(notes.text, contains('My heel hurt'));
    expect(notes.text, isNot(contains('MODEL GUESS')));
    expect(notes.text, isNot(contains('Summarize today')));
    expect(notes.newestMs, 32);
  });
}

class _SilentModel implements DiaryModel {
  @override
  bool get available => false;

  @override
  String get location => 'global';

  @override
  String get modelName => 'fake';

  @override
  Stream<String> generate(String prompt, {String? systemInstruction, DiaryCancel? cancel}) async* {}

  @override
  Future<String?> generateJson({
    required String prompt,
    required String systemInstruction,
    Schema? responseSchema,
    DiaryCancel? cancel,
  }) async =>
      null;
}
