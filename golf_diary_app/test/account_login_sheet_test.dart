import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/widgets/account_login_sheet.dart';

void main() {
  testWidgets('login sheet exposes Google and email keys', (tester) async {
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
    expect(find.byKey(const Key('account-login-google')), findsOneWidget);
    expect(find.byKey(const Key('account-login-email')), findsOneWidget);
    expect(find.byKey(const Key('account-login-password')), findsOneWidget);
    expect(find.byKey(const Key('account-login-submit')), findsOneWidget);
    await tester.tap(find.text('New here? Create account'));
    await tester.pump();
    expect(find.text('Create account'), findsWidgets);
  });
}
