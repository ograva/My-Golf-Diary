import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/account_profile_screen.dart';
import 'package:golf_diary_app/services/account_auth_controller.dart';
import 'package:golf_diary_app/services/account_link_conflict.dart';
import 'package:golf_diary_app/services/account_session.dart';
import 'package:golf_diary_app/services/auth_session_binder.dart';
import 'package:golf_diary_app/services/remote_diary_state.dart';
import 'package:golf_diary_app/widgets/account_avatar_app_bar_menu.dart';
import 'package:golf_diary_app/widgets/account_login_sheet.dart';

const _emailSession = AccountSession(
  uid: 'reuben',
  email: 'reuben@example.com',
  displayName: 'Reuben',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: false,
  primaryProviderId: 'password',
);

AuthUserSnapshot _emailUser(
    {bool isAnonymous = false, List<String>? providers}) {
  return AuthUserSnapshot(
    uid: 'reuben',
    email: 'reuben@example.com',
    displayName: 'Reuben',
    isAnonymous: isAnonymous,
    isEmailVerified: false,
    providerIds: providers ?? const ['password'],
  );
}

void main() {
  tearDown(() {
    AccountAuthController.debugSetInstance(null);
  });

  test('stale anonymous flag still shows the email account', () {
    final session = sessionFromAuthSnapshot(
      _emailUser(isAnonymous: true, providers: const []),
    );
    expect(session.isDurableAccount, isTrue);
    expect(session.isAnonymous, isFalse);
    expect(session.isEmailPasswordAccount, isTrue);
    expect(session.email, 'reuben@example.com');
    expect(session.providerLabel, 'Email');
  });

  test('a null auth event does not clear a session that just signed in', () {
    final binder = AuthSessionBinder();
    binder.adopt(_emailUser(isAnonymous: true, providers: const []));
    expect(binder.session.isDurableAccount, isTrue);

    int? settled;
    final held = binder.apply(
      event: null,
      current: null,
      whenSettled: (epoch) => settled = epoch,
    );
    expect(held.isDurableAccount, isTrue);
    expect(held.email, 'reuben@example.com');

    expect(binder.settle(settled!, _emailUser()), isTrue);
    expect(binder.session.isDurableAccount, isTrue);
    expect(binder.session.email, 'reuben@example.com');
  });

  test('a newer sign-in wins over a late null settle', () {
    final binder = AuthSessionBinder();
    binder.adopt(_emailUser());
    int? settled;
    binder.apply(
        event: null, current: null, whenSettled: (epoch) => settled = epoch);
    binder.adopt(_emailUser());
    expect(binder.settle(settled!, null), isFalse);
    expect(binder.session.email, 'reuben@example.com');
  });

  test(
      'unclear remote with local data offers upload and does not claim entries',
      () {
    const prompt = ConflictPrompt(
      remote: RemoteDiaryState.unclear,
      localDataExists: true,
    );
    expect(prompt.claimAccountHasEntries, isFalse);
    expect(prompt.offerUpload, isTrue);
    expect(prompt.offerReplace, isFalse);
    expect(prompt.body, isNot(contains('already has')));
  });

  test('live remote entries can offer replace', () {
    const prompt = ConflictPrompt(
      remote: RemoteDiaryState.hasEntries,
      localDataExists: true,
    );
    expect(prompt.claimAccountHasEntries, isTrue);
    expect(prompt.offerUpload, isTrue);
    expect(prompt.offerReplace, isTrue);
    expect(prompt.body, contains('already has diary entries'));
  });

  testWidgets('successful email sign-in stays on that account in the UI',
      (tester) async {
    final auth = _ScriptedAuth(conflict: false);
    AccountAuthController.debugSetInstance(auth);
    await _pumpShell(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-login-submit')));
    await tester.pumpAndSettle();

    expect(auth.session.isDurableAccount, isTrue);
    expect(auth.session.email, 'reuben@example.com');
    expect(find.byKey(const Key('account-login-submit')), findsNothing);

    await tester.tap(find.byKey(const Key('account-avatar-button')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-menu-profile')));
    await tester.pumpAndSettle();
    expect(find.text('reuben@example.com'), findsOneWidget);
    expect(find.text('Provider: Email'), findsOneWidget);
    expect(find.byType(AccountProfileScreen), findsOneWidget);
  });

  testWidgets(
      'empty account offers upload and download without a false diary claim',
      (tester) async {
    final auth = _ScriptedAuth(
      conflict: true,
      prompt: const ConflictPrompt(
        remote: RemoteDiaryState.empty,
        localDataExists: true,
      ),
    );
    AccountAuthController.debugSetInstance(auth);
    await _pumpShell(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Save this device\'s diary'), findsOneWidget);
    expect(find.textContaining('does not have diary entries'), findsOneWidget);
    expect(find.textContaining('already has'), findsNothing);
    expect(
        find.byKey(const Key('account-conflict-upload-first')), findsOneWidget);
    expect(find.byKey(const Key('account-conflict-download-sync')),
        findsOneWidget);
    expect(
        find.byKey(const Key('account-conflict-replace-local')), findsNothing);

    await tester.tap(find.byKey(const Key('account-conflict-download-sync')));
    await tester.pumpAndSettle();

    expect(auth.downloads, 1);
    expect(auth.session.isDurableAccount, isTrue);
    expect(auth.session.email, 'reuben@example.com');
    expect(
        find.byKey(const Key('account-conflict-download-sync')), findsNothing);
  });

  testWidgets('upload choice keeps the signed-in account', (tester) async {
    final auth = _ScriptedAuth(
      conflict: true,
      prompt: const ConflictPrompt(
        remote: RemoteDiaryState.unclear,
        localDataExists: true,
      ),
    );
    AccountAuthController.debugSetInstance(auth);
    await _pumpShell(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-login-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account-conflict-upload-first')));
    await tester.pumpAndSettle();

    expect(auth.uploads, 1);
    expect(auth.session.email, 'reuben@example.com');
    expect(auth.session.isDurableAccount, isTrue);
  });

  testWidgets('cancel leaves the previous signed-out session', (tester) async {
    final auth = _ScriptedAuth(
      conflict: true,
      prompt: const ConflictPrompt(
        remote: RemoteDiaryState.empty,
        localDataExists: true,
      ),
    );
    AccountAuthController.debugSetInstance(auth);
    await _pumpShell(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-conflict-cancel')));
    await tester.pumpAndSettle();

    expect(auth.cancels, 1);
    expect(auth.downloads, 0);
    expect(auth.session.isSignedOut, isTrue);
    expect(find.byKey(const Key('account-login-submit')), findsOneWidget);
  });

  testWidgets('replace asks again and keeps local data when declined',
      (tester) async {
    final auth = _ScriptedAuth(
      conflict: true,
      prompt: const ConflictPrompt(
        remote: RemoteDiaryState.hasEntries,
        localDataExists: true,
      ),
    );
    AccountAuthController.debugSetInstance(auth);
    await _pumpShell(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-login-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('already has diary entries'), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-conflict-replace-local')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-conflict-replace-confirm')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('account-conflict-replace-cancel')));
    await tester.pumpAndSettle();

    expect(auth.replaces, 0);
    expect(auth.session.isDurableAccount, isTrue);
  });

  testWidgets('confirmed replace runs and stays signed in', (tester) async {
    final auth = _ScriptedAuth(
      conflict: true,
      prompt: const ConflictPrompt(
        remote: RemoteDiaryState.hasEntries,
        localDataExists: true,
      ),
    );
    AccountAuthController.debugSetInstance(auth);
    await _pumpShell(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-conflict-replace-local')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-conflict-replace-confirm')));
    await tester.pumpAndSettle();

    expect(auth.replaces, 1);
    expect(auth.session.email, 'reuben@example.com');
  });
}

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: const [AccountAvatarAppBarMenu()],
        ),
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAccountLoginSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

class _ScriptedAuth extends AccountAuthController {
  _ScriptedAuth({
    required this.conflict,
    this.prompt = const ConflictPrompt(
      remote: RemoteDiaryState.empty,
      localDataExists: false,
    ),
  });

  final bool conflict;
  final ConflictPrompt prompt;
  int uploads = 0;
  int downloads = 0;
  int replaces = 0;
  int cancels = 0;

  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    if (!conflict) debugSetSession(_emailSession);
    return conflict ? kAccountLinkConflict : null;
  }

  @override
  Future<ConflictPrompt> loadLinkConflictPrompt() async {
    debugSetSession(_emailSession);
    return prompt;
  }

  @override
  Future<String?> resolveLinkConflictUploadFirst() async {
    uploads += 1;
    debugSetSession(_emailSession);
    return null;
  }

  @override
  Future<String?> resolveLinkConflictDownload() async {
    downloads += 1;
    debugSetSession(_emailSession);
    return null;
  }

  @override
  Future<String?> resolveLinkConflictReplaceLocal() async {
    replaces += 1;
    debugSetSession(_emailSession);
    return null;
  }

  @override
  Future<void> cancelLinkConflict() async {
    cancels += 1;
    debugSetSession(const AccountSession.signedOut());
  }
}
