import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/services/account_auth_controller.dart';

void main() {
  group('Google sign-in helpers', () {
    test('isSignInCancelled distinguishes user dismiss', () {
      expect(isSignInCancelled(kSignInCancelled), isTrue);
      expect(isSignInCancelled(null), isFalse);
      expect(isSignInCancelled('Google sign-in failed. Try again.'), isFalse);
    });

    test('isAccountLinkConflict unchanged', () {
      expect(isAccountLinkConflict('__account_link_conflict__'), isTrue);
    });

    test('web Google sign-in cannot use the plugin access token', () {
      expect(googleSignInPluginReturnsIdToken(isWeb: true), isFalse);
      expect(googleSignInPluginReturnsIdToken(isWeb: false), isTrue);
    });

    test('closing the Google popup is a cancel, not a failure', () {
      expect(googlePopupFailure('popup-closed-by-user'), kSignInCancelled);
      expect(googlePopupFailure('cancelled-popup-request'), kSignInCancelled);
      expect(
        googlePopupFailure('popup-blocked'),
        contains('Allow pop-ups'),
      );
      expect(googlePopupFailure('invalid-credential'), isNull);
    });
  });
}
