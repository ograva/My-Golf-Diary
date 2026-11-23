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
  });
}