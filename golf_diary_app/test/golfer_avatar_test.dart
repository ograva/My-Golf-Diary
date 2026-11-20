import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_avatar.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/screens/golfer_profile_settings_screen.dart';
import 'package:golf_diary_app/services/account_auth_controller.dart';
import 'package:golf_diary_app/services/account_session.dart';
import 'package:golf_diary_app/services/golfer_profile_store.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/widgets/account_avatar_app_bar_menu.dart';
import 'package:golf_diary_app/widgets/golfer_avatar_circle.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const _googleSession = AccountSession(
  uid: 'uid',
  email: 'riley@example.com',
  displayName: 'Riley Cruz',
  photoUrl: 'https://example.com/riley.png',
  isAnonymous: false,
  isEmailVerified: true,
  primaryProviderId: 'google.com',
);

const _emailSession = AccountSession(
  uid: 'uid',
  email: 'riley@example.com',
  displayName: 'Riley Cruz',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: true,
  primaryProviderId: 'password',
);

void main() {
  group('defaultGolferAvatar', () {
    const cases = {
      (GolferGender.female, GolferSkillTier.beginner):
          GolferAvatar.femaleBeginner,
      (GolferGender.male, GolferSkillTier.beginner): GolferAvatar.maleBeginner,
      (GolferGender.female, GolferSkillTier.amateur):
          GolferAvatar.femaleAmateur,
      (GolferGender.male, GolferSkillTier.amateur): GolferAvatar.maleAmateur,
      (GolferGender.female, GolferSkillTier.seasonedPro):
          GolferAvatar.femaleSeasoned,
      (GolferGender.male, GolferSkillTier.seasonedPro):
          GolferAvatar.maleSeasoned,
      (GolferGender.male, 'pro'): GolferAvatar.maleSeasoned,
      (GolferGender.female, 'Seasoned'): GolferAvatar.femaleSeasoned,
    };
    cases.forEach((input, expected) {
      test('${input.$1} × ${input.$2} → ${expected.id}', () {
        expect(
          defaultGolferAvatar(gender: input.$1, skillTier: input.$2),
          expected,
        );
      });
    });

    test('non-binary, prefer-not-to-say, or missing data → none', () {
      expect(
        defaultGolferAvatar(
          gender: GolferGender.nonBinary,
          skillTier: GolferSkillTier.amateur,
        ),
        isNull,
      );
      expect(
        defaultGolferAvatar(
          gender: GolferGender.preferNotToSay,
          skillTier: GolferSkillTier.beginner,
        ),
        isNull,
      );
      expect(
        defaultGolferAvatar(gender: GolferGender.female, skillTier: ''),
        isNull,
      );
      expect(
        defaultGolferAvatar(gender: '', skillTier: GolferSkillTier.amateur),
        isNull,
      );
    });
  });

  group('resolveGolferAvatar', () {
    test('explicit alternate choice wins over gender × tier', () {
      const profile = GolferProfile(
        gender: GolferGender.female,
        skillTier: GolferSkillTier.amateur,
        avatarChoice: 'female_amateur_alt',
      );
      expect(resolveGolferAvatar(profile), GolferAvatar.femaleAmateurAlt);
    });

    test('non-binary golfer can still pick any avatar', () {
      const profile = GolferProfile(
        gender: GolferGender.nonBinary,
        skillTier: GolferSkillTier.beginner,
        avatarChoice: 'male_seasoned',
      );
      expect(resolveGolferAvatar(profile), GolferAvatar.maleSeasoned);
    });

    test('unknown stored choice falls back to default', () {
      const profile = GolferProfile(
        gender: GolferGender.male,
        skillTier: GolferSkillTier.amateur,
        avatarChoice: 'retired_id',
      );
      expect(resolveGolferAvatar(profile), GolferAvatar.maleAmateur);
    });

    test('picker lists amateur alternate right after the default', () {
      final order = golferAvatarPickerOrder(
        gender: GolferGender.male,
        skillTier: GolferSkillTier.amateur,
      );
      expect(order.take(2),
          [GolferAvatar.maleAmateur, GolferAvatar.maleAmateurAlt]);
      expect(order.toSet(), GolferAvatar.values.toSet());
    });

    test('every avatar asset path is under assets/avatars', () {
      for (final avatar in GolferAvatar.values) {
        expect(avatar.assetPath, 'assets/avatars/${avatar.id}.png');
      }
    });
  });

  group('resolveGolferAvatarSource precedence', () {
    const amateur = GolferProfile(
      gender: GolferGender.female,
      skillTier: GolferSkillTier.amateur,
    );

    test('Google photo beats illustrated avatar', () {
      expect(
        resolveGolferAvatarSource(session: _googleSession, profile: amateur),
        GolferAvatarSource.accountPhoto,
      );
    });

    test('illustrated avatar beats initials', () {
      expect(
        resolveGolferAvatarSource(session: _emailSession, profile: amateur),
        GolferAvatarSource.illustrated,
      );
    });

    test('signed out with avatar shows illustrated avatar', () {
      expect(
        resolveGolferAvatarSource(
          session: const AccountSession.signedOut(),
          profile: amateur,
        ),
        GolferAvatarSource.illustrated,
      );
    });

    test('no avatar → initials signed in, generic icon signed out', () {
      expect(
        resolveGolferAvatarSource(
          session: _emailSession,
          profile: const GolferProfile(),
        ),
        GolferAvatarSource.initials,
      );
      expect(
        resolveGolferAvatarSource(
          session: const AccountSession.signedOut(),
          profile: const GolferProfile(),
        ),
        GolferAvatarSource.genericIcon,
      );
    });
  });

  group('header avatar', () {
    tearDown(() => AccountAuthController.debugSetInstance(null));

    Future<void> pumpHeader(
      WidgetTester tester, {
      required GolferProfile profile,
      AccountSession? session,
    }) async {
      AccountAuthController.debugSetInstance(AccountAuthController());
      if (session != null) {
        AccountAuthController.instance.debugSetSession(session);
      }
      final store = GolferProfileStore()..profile = profile;
      await tester.pumpWidget(
        MaterialApp(
          home: GolferProfileScope(
            store: store,
            child: Scaffold(
              appBar: AppBar(actions: const [AccountAvatarAppBarMenu()]),
            ),
          ),
        ),
      );
    }

    testWidgets('shows tier avatar from profile when signed out',
        (tester) async {
      await pumpHeader(
        tester,
        profile: const GolferProfile(
          gender: GolferGender.male,
          skillTier: GolferSkillTier.seasonedPro,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account-avatar-button')),
          matching: find.byKey(const ValueKey('golfer-avatar-male_seasoned')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows chosen alternate avatar', (tester) async {
      await pumpHeader(
        tester,
        session: _emailSession,
        profile: const GolferProfile(
          gender: GolferGender.female,
          skillTier: GolferSkillTier.amateur,
          avatarChoice: 'female_amateur_alt',
        ),
      );
      expect(
        find.byKey(const ValueKey('golfer-avatar-female_amateur_alt')),
        findsOneWidget,
      );
    });

    testWidgets('no profile keeps generic icon signed out', (tester) async {
      await pumpHeader(tester, profile: const GolferProfile());
      expect(
        find.byKey(const ValueKey('golfer-avatar-generic')),
        findsOneWidget,
      );
    });
  });

  group('settings avatar picker', () {
    bool isSelected(WidgetTester tester, String key) {
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Semantics),
            )
            .first,
      );
      return semantics.properties.selected ?? false;
    }

    testWidgets('defaults to Auto and selects an alternate', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GolferProfileSettingsScreen(
            initialProfile: GolferProfile(
              gender: GolferGender.female,
              skillTier: GolferSkillTier.amateur,
            ),
          ),
        ),
      );
      final alt =
          find.byKey(const ValueKey('profile-avatar-female_amateur_alt'));
      await tester.scrollUntilVisible(
        alt,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(isSelected(tester, 'profile-avatar-auto'), isTrue);
      expect(isSelected(tester, 'profile-avatar-female_amateur_alt'), isFalse);

      await tester.tap(alt);
      await tester.pump();
      expect(isSelected(tester, 'profile-avatar-auto'), isFalse);
      expect(isSelected(tester, 'profile-avatar-female_amateur_alt'), isTrue);
    });
  });

  group('persistence', () {
    const fileName = 'golf_diary_avatar.db';

    setUp(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName(fileName);
      await deleteDatabase(join(await getDatabasesPath(), fileName));
    });

    tearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });

    test('avatar choice round-trips through SQLite', () async {
      await LocalDatabaseService.instance.saveGolferProfile(
        const GolferProfile(
          gender: GolferGender.male,
          skillTier: GolferSkillTier.amateur,
          avatarChoice: 'male_amateur_alt',
        ),
      );
      final profile = await LocalDatabaseService.instance.getGolferProfile();
      expect(profile.avatarChoice, 'male_amateur_alt');
      expect(resolveGolferAvatar(profile), GolferAvatar.maleAmateurAlt);
    });

    test('v15 database upgrades with empty avatar choice', () async {
      final path = join(await getDatabasesPath(), fileName);
      final raw = await openDatabase(
        path,
        version: 15,
        onCreate: (db, version) async {
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
              yardage_display_mode TEXT NOT NULL DEFAULT 'follow_skill_tier',
              onboarding_completed INTEGER NOT NULL DEFAULT 0,
              bag_nickname TEXT NOT NULL DEFAULT '',
              scorecard_view_mode TEXT NOT NULL DEFAULT 'classic',
              scorecard_cart_high_contrast INTEGER NOT NULL DEFAULT 0,
              is_synced INTEGER NOT NULL DEFAULT 0,
              updated_at_ms INTEGER NOT NULL DEFAULT 0,
              deleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.insert('golfer_profile', {
            'id': GolferProfile.rowId,
            'gender': GolferGender.female,
            'skill_tier': GolferSkillTier.seasonedPro,
          });
        },
      );
      await raw.close();

      final profile = await LocalDatabaseService.instance.getGolferProfile();
      expect(profile.avatarChoice, '');
      expect(resolveGolferAvatar(profile), GolferAvatar.femaleSeasoned);
    });
  });
}
