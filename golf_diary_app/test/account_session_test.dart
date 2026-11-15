import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/services/account_session.dart';

void main() {
  test('signed-out session cannot push', () {
    const session = AccountSession.signedOut();
    expect(session.isDurableAccount, isFalse);
    expect(session.canPushToCloud, isFalse);
  });

  test('Google session can push without email verification flag', () {
    const session = AccountSession(
      uid: 'u1',
      email: 'r@example.com',
      displayName: 'Rory Reed',
      photoUrl: null,
      isAnonymous: false,
      isEmailVerified: false,
      primaryProviderId: 'google.com',
    );
    expect(session.canPushToCloud, isTrue);
    expect(session.initials, 'RR');
  });

  test('unverified email cannot push', () {
    const session = AccountSession(
      uid: 'u1',
      email: 'r@example.com',
      displayName: null,
      photoUrl: null,
      isAnonymous: false,
      isEmailVerified: false,
      primaryProviderId: 'password',
    );
    expect(session.canPushToCloud, isFalse);
    expect(session.initials, 'R');
  });
}