import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/services/account_auth_controller.dart';
import 'package:golf_diary_app/services/account_session.dart';
import 'package:golf_diary_app/widgets/account_avatar_app_bar_menu.dart';

void main() {
  tearDown(() {
    AccountAuthController.debugSetInstance(null);
  });

  Future<void> pumpMenu(WidgetTester tester, {AccountSession? session}) async {
    AccountAuthController.debugSetInstance(AccountAuthController());
    if (session != null) {
      AccountAuthController.instance.debugSetSession(session);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [AccountAvatarAppBarMenu()],
          ),
        ),
      ),
    );
  }

  testWidgets('signed out avatar opens four menu entries', (tester) async {
    await pumpMenu(tester);
    expect(find.byKey(const Key('account-avatar-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-avatar-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-menu-login')), findsOneWidget);
    expect(find.byKey(const Key('account-menu-sync')), findsOneWidget);
    expect(find.byKey(const Key('account-menu-profile')), findsOneWidget);
    expect(find.byKey(const Key('account-menu-settings')), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('signed in menu shows Sign out label', (tester) async {
    await pumpMenu(
      tester,
      session: const AccountSession(
        uid: 'uid',
        email: 'riley@example.com',
        displayName: 'Riley',
        photoUrl: null,
        isAnonymous: false,
        isEmailVerified: true,
        primaryProviderId: 'password',
      ),
    );
    await tester.tap(find.byKey(const Key('account-avatar-button')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('sync while signed out shows snackbar', (tester) async {
    await pumpMenu(tester);
    await tester.tap(find.byKey(const Key('account-avatar-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-menu-sync')));
    await tester.pump();
    final requiresSignIn =
        find.text('Sign in to save your diary to the cloud.');
    final noFirebase =
        find.text('Firebase not configured — local data is saved on device');
    expect(
      requiresSignIn.evaluate().isNotEmpty || noFirebase.evaluate().isNotEmpty,
      isTrue,
    );
  });
}
