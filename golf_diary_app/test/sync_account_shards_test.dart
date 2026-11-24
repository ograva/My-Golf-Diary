import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/account_profile_screen.dart';
import 'package:golf_diary_app/screens/account_sync_settings_screen.dart';
import 'package:golf_diary_app/services/account_auth_controller.dart';
import 'package:golf_diary_app/services/account_link_conflict.dart';
import 'package:golf_diary_app/services/account_session.dart';
import 'package:golf_diary_app/services/remote_diary_state.dart';
import 'package:golf_diary_app/services/cloud_sync_service.dart';
import 'package:golf_diary_app/services/diary_remote.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/sync_constants.dart';
import 'package:golf_diary_app/widgets/account_login_sheet.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_sync_shards.db');
    await deleteDatabase(
      join(await getDatabasesPath(), 'golf_diary_sync_shards.db'),
    );
    AccountAuthController.debugSetInstance(AccountAuthController());
  });

  tearDown(() async {
    AccountAuthController.debugSetInstance(null);
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  group('SYNC-001', () {
    test('injected remote is available and a bare service is not', () {
      final withRemote = CloudSyncService(
        userId: 'uid',
        remote: MemoryDiaryRemote(),
      );
      expect(withRemote.isAvailable, isTrue);

      final bare = CloudSyncService(userId: 'uid');
      expect(Firebase.apps, isEmpty);
      expect(bare.isAvailable, isFalse);
    });

    test('unavailable syncFull does not throw', () async {
      final bare = CloudSyncService(userId: 'uid');
      expect(bare.isAvailable, isFalse);
      final result = await bare.syncFull();
      expect(result.pushed, 0);
      expect(result.failed, 0);
      expect(result.pulled, 0);
    });
  });

  group('SYNC-002', () {
    testWidgets('settings Sync now explains local-only when Firebase is down',
        (tester) async {
      await _pumpSettings(tester);
      await tester.tap(find.byKey(const Key('account-settings-sync-now')));
      await tester.pump();
      expect(
        find.text('Firebase not configured — local data is saved on device'),
        findsOneWidget,
      );
    });
  });

  group('SYNC-003', () {
    test('diary database id is my-golf-diary', () {
      expect(kFirestoreDatabaseId, 'my-golf-diary');
    });

    test('anonymous session cannot push', () {
      const session = AccountSession(
        uid: 'anon',
        email: null,
        displayName: null,
        photoUrl: null,
        isAnonymous: true,
        isEmailVerified: false,
        primaryProviderId: 'anonymous',
      );
      expect(session.isDurableAccount, isFalse);
      expect(session.canPushToCloud, isFalse);
      expect(session.providerLabel, 'Not signed in');
    });
  });

  group('SYNC-006', () {
    testWidgets('forgot password asks for an email before calling Firebase',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAccountLoginSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password'));
      await tester.pump();
      expect(find.text('Enter your email first.'), findsOneWidget);
    });
  });

  group('SYNC-007', () {
    test('core tables stay in the sync set', () {
      expect(
        kSyncTables,
        containsAll(['clubs', 'shots', 'round_scores', 'range_drills']),
      );
    });

    test('profile and later diary tables are not in kSyncTables yet', () {
      expect(kSyncTables, isNot(contains('golfer_profile')));
      expect(kSyncTables, isNot(contains('golf_rounds')));
      expect(kSyncTables, isNot(contains('practice_drills')));
      expect(kSyncTables, isNot(contains('range_sessions')));
      expect(kSyncTables, isNot(contains('swing_diary_messages')));
      expect(kSyncTables, isNot(contains('range_evaluations')));
    });
  });

  group('SYNC-008', () {
    test('link conflict marker is recognized and other errors are not', () {
      expect(isAccountLinkConflict('__account_link_conflict__'), isTrue);
      expect(isAccountLinkConflict(null), isFalse);
      expect(
        isAccountLinkConflict('Wrong password. Try again or reset it.'),
        isFalse,
      );
    });

    test('upload before a durable sign-in does not run', () async {
      final message =
          await AccountAuthController.instance.resolveLinkConflictUploadFirst();
      expect(
        message,
        'Sign in to the account before uploading this device.',
      );
    });

    test('an empty account is not described as already having entries', () {
      const prompt = ConflictPrompt(
        remote: RemoteDiaryState.empty,
        localDataExists: true,
      );
      expect(prompt.claimAccountHasEntries, isFalse);
      expect(prompt.offerUpload, isTrue);
      expect(prompt.needsDialog, isTrue);
      expect(prompt.title, isNot(contains('already has')));
      expect(prompt.body, isNot(contains('already has')));
    });
  });

  group('SYNC-009', () {
    testWidgets('signed-out profile says the diary stays on this device',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AccountProfileScreen()),
      );
      expect(
        find.text(
          'Your diary is saved on this device only until you sign in.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byKey(const Key('account-profile-sign-out')), findsNothing);
    });

    testWidgets('signed-in profile shows provider and sign-out confirm',
        (tester) async {
      AccountAuthController.instance.debugSetSession(
        const AccountSession(
          uid: 'uid',
          email: 'riley@example.com',
          displayName: 'Riley Quinn',
          photoUrl: null,
          isAnonymous: false,
          isEmailVerified: true,
          primaryProviderId: 'google.com',
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(home: AccountProfileScreen()),
      );
      expect(find.text('Riley Quinn'), findsOneWidget);
      expect(find.text('riley@example.com'), findsOneWidget);
      expect(find.text('Provider: Google'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-profile-sign-out')), findsOneWidget);
      expect(
        find.text('Your diary stays on this device. Sign in again to sync.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        AccountAuthController.instance.session.isDurableAccount,
        isTrue,
      );
    });
  });

  group('SYNC-010', () {
    testWidgets('settings lists cloud status and the local skill profile',
        (tester) async {
      await _pumpSettings(tester);
      expect(find.text('Firebase: Not configured'), findsOneWidget);
      expect(find.text('Signed in: Not signed in'), findsOneWidget);
      expect(find.text('Last successful pull: Never'), findsOneWidget);
      expect(find.textContaining('Rows waiting to upload:'), findsOneWidget);
      expect(
          find.byKey(const Key('account-settings-sync-now')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-golfer-profile-entry')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Skill tier, avatar, and coaching baseline stay in SQLite and are not part of cloud account profile.',
        ),
        findsOneWidget,
      );
      expect(find.text('Change password'), findsNothing);
      expect(find.text('Send verification email'), findsNothing);
    });

    testWidgets('unverified email can send a verification email',
        (tester) async {
      AccountAuthController.instance.debugSetSession(
        const AccountSession(
          uid: 'uid',
          email: 'blake@example.com',
          displayName: 'Blake',
          photoUrl: null,
          isAnonymous: false,
          isEmailVerified: false,
          primaryProviderId: 'password',
        ),
      );
      await _pumpSettings(tester);
      expect(find.text('Signed in: blake@example.com'), findsOneWidget);
      expect(find.text('Send verification email'), findsOneWidget);
    });

    testWidgets('Google account does not show a password action',
        (tester) async {
      AccountAuthController.instance.debugSetSession(
        const AccountSession(
          uid: 'uid',
          email: 'rory@example.com',
          displayName: 'Rory',
          photoUrl: null,
          isAnonymous: false,
          isEmailVerified: true,
          primaryProviderId: 'google.com',
        ),
      );
      await _pumpSettings(tester);
      expect(find.text('Signed in: rory@example.com'), findsOneWidget);
      expect(find.text('Send verification email'), findsNothing);
      expect(find.text('Change password'), findsNothing);
    });
  });
}

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MaterialApp(home: AccountSyncSettingsScreen()),
  );
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (find
        .byKey(const Key('account-settings-sync-now'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
  }
  fail('Settings did not leave the loading spinner');
}
