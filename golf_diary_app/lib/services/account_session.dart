/// Read-only view of the signed-in Firebase account (not local golfer profile).
class AccountSession {
  const AccountSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymous,
    required this.isEmailVerified,
    required this.primaryProviderId,
  });

  const AccountSession.signedOut()
      : uid = null,
        email = null,
        displayName = null,
        photoUrl = null,
        isAnonymous = false,
        isEmailVerified = false,
        primaryProviderId = null;

  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isEmailVerified;
  final String? primaryProviderId;

  bool get isSignedOut => uid == null;

  /// Durable Google or email/password account (not anonymous).
  bool get isDurableAccount => uid != null && !isAnonymous;

  bool get isGoogleAccount => primaryProviderId == 'google.com';

  bool get isEmailPasswordAccount => primaryProviderId == 'password';

  /// Cloud push requires a durable account; email must be verified unless Google.
  bool get canPushToCloud {
    if (!isDurableAccount) return false;
    if (primaryProviderId == 'google.com') return true;
    if (primaryProviderId == 'password') return isEmailVerified;
    return isEmailVerified;
  }

  String get providerLabel {
    if (isSignedOut || isAnonymous) return 'Not signed in';
    if (primaryProviderId == 'google.com') return 'Google';
    if (primaryProviderId == 'password') return 'Email';
    return 'Account';
  }

  String get initials {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, 1).toUpperCase();
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}