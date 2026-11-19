import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Persistence paths covered here; UI keys verified in golfer_profile_settings_screen.dart.
void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_settings.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_settings.db'));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  test('changing skill tier and yardage mode persists in SQLite', () async {
    await LocalDatabaseService.instance.saveGolferProfile(
      const GolferProfile(
        age: 25,
        yearsPlaying: 3,
        skillTier: GolferSkillTier.beginner,
        yardageDisplayMode: YardageDisplayMode.followSkillTier,
        onboardingCompleted: 1,
      ),
    );

    await LocalDatabaseService.instance.saveGolferProfile(
      const GolferProfile(
        age: 25,
        yearsPlaying: 3,
        skillTier: GolferSkillTier.amateur,
        yardageDisplayMode: YardageDisplayMode.full,
        onboardingCompleted: 1,
      ),
    );

    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.skillTier, GolferSkillTier.amateur);
    expect(profile.yardageDisplayMode, YardageDisplayMode.full);
    expect(
      resolveYardageUiDensity(profile),
      YardageUiDensity.full,
    );
  });

  test('reset onboarding clears onboarding_completed only', () async {
    await LocalDatabaseService.instance.saveGolferProfile(
      const GolferProfile(
        age: 30,
        yearsPlaying: 5,
        skillTier: GolferSkillTier.amateur,
        onboardingCompleted: 1,
      ),
    );

    final current = await LocalDatabaseService.instance.getGolferProfile();
    await LocalDatabaseService.instance.saveGolferProfile(
      current.copyWith(onboardingCompleted: 0),
    );

    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.onboardingCompleted, 0);
    expect(profile.hasCompletedOnboarding, isFalse);
    expect(profile.skillTier, GolferSkillTier.amateur);
    expect(profile.age, 30);
  });
}
