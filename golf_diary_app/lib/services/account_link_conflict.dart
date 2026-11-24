import 'account_session.dart';
import 'remote_diary_state.dart';

/// What the golfer picked on the anonymous-link conflict dialog.
enum AccountLinkChoice { uploadFirst, downloadAndSync, replaceLocal, cancel }

/// Firebase user fields needed to decide if the UI should show an account.
class AuthUserSnapshot {
  const AuthUserSnapshot({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.isEmailVerified,
    this.providerIds = const [],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isEmailVerified;
  final List<String> providerIds;
}

/// Maps a Firebase user onto the session the avatar and settings read.
///
/// Email/password link can leave [AuthUserSnapshot.isAnonymous] true and
/// [AuthUserSnapshot.providerIds] empty until reload. An email on that user
/// is still the account they just signed into.
AccountSession sessionFromAuthSnapshot(AuthUserSnapshot? user) {
  if (user == null || user.uid.isEmpty) {
    return const AccountSession.signedOut();
  }
  final providers = user.providerIds
      .where((id) => id.isNotEmpty && id != 'firebase')
      .toList();
  final hasGoogle = providers.contains('google.com');
  final hasPassword = providers.contains('password');
  final hasEmail = (user.email ?? '').trim().isNotEmpty;
  final anonymous = user.isAnonymous && !hasGoogle && !hasPassword && !hasEmail;
  final provider = anonymous
      ? 'anonymous'
      : hasGoogle
          ? 'google.com'
          : (hasPassword || hasEmail)
              ? 'password'
              : (providers.isNotEmpty ? providers.first : 'password');
  return AccountSession(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoUrl,
    isAnonymous: anonymous,
    isEmailVerified: user.isEmailVerified || hasGoogle,
    primaryProviderId: provider,
  );
}

/// Copy and actions for the link-conflict dialog.
class ConflictPrompt {
  const ConflictPrompt({
    required this.remote,
    required this.localDataExists,
    this.signInError,
  });

  final RemoteDiaryState remote;
  final bool localDataExists;
  final String? signInError;

  /// Auth user exists is not enough. Only a live remote diary may say so.
  bool get claimAccountHasEntries =>
      signInError == null && remote == RemoteDiaryState.hasEntries;

  bool get needsDialog =>
      signInError == null && (localDataExists || claimAccountHasEntries);

  /// Third choice when this device has rows and the account is empty or unclear.
  /// Also offered when the account has entries so neither copy is dropped silently.
  bool get offerUpload => localDataExists;

  bool get offerReplace => claimAccountHasEntries && localDataExists;

  String get title => claimAccountHasEntries
      ? 'Account already has entries'
      : 'Save this device\'s diary';

  String get body => claimAccountHasEntries
      ? 'That account already has diary entries in the cloud. '
          'Download and sync keeps rows that exist only on this device. '
          'Replace this device only if you want the cloud copy instead.'
      : 'This account does not have diary entries yet, or the cloud copy '
          'could not be checked. What is on this device is still here. '
          'Upload it to the account first, then download and sync.';
}
