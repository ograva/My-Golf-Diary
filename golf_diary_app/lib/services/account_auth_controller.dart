import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import 'account_link_conflict.dart';
import 'account_session.dart';
import 'auth_session_binder.dart';
import 'cloud_sync_service.dart';
import 'local_database_service.dart';
import 'remote_diary_state.dart';
import 'sync_identity.dart';

/// User closed the Google account picker without choosing an account.
const String kSignInCancelled = '__sign_in_cancelled__';

/// Anonymous link failed because that Google or email account already exists.
const String kAccountLinkConflict = '__account_link_conflict__';

bool isSignInCancelled(String? message) => message == kSignInCancelled;

bool isAccountLinkConflict(String? message) => message == kAccountLinkConflict;

/// Web [GoogleSignIn.signIn] ends the account popup with an access token and
/// no ID token. The plugin then calls the People API for a synthetic profile.
/// That call throws, or Firebase rejects the token-less credential, and the
/// sheet shows "Google sign-in failed." Web sign-in uses
/// [FirebaseAuth.signInWithPopup], which receives Google's ID token.
bool googleSignInPluginReturnsIdToken({required bool isWeb}) => !isWeb;

/// Popup outcomes that are not a failed Google account.
String? googlePopupFailure(String code) {
  switch (code) {
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
      return kSignInCancelled;
    case 'popup-blocked':
      return 'The browser blocked the Google sign-in window. Allow pop-ups and try again.';
    default:
      return null;
  }
}

/// Firebase Auth + Google sign-in; passwords never touch SQLite.
class AccountAuthController extends ChangeNotifier {
  AccountAuthController({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _authOverride = auth,
        _googleOverride = googleSignIn;

  static AccountAuthController? _override;
  static AccountAuthController get instance =>
      _override ??= AccountAuthController();

  @visibleForTesting
  static void debugSetInstance(AccountAuthController? controller) {
    _override = controller;
  }

  final FirebaseAuth? _authOverride;
  final GoogleSignIn? _googleOverride;
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _sub;
  final AuthSessionBinder _binder = AuthSessionBinder();

  AuthCredential? _pendingCredential;
  String? _pendingEmail;
  String? _pendingPassword;
  bool _conflictAdopted = false;
  RemoteDiaryState? _remoteState;

  AccountSession _session = const AccountSession.signedOut();

  AccountSession get session => _session;

  @visibleForTesting
  void debugSetSession(AccountSession session) {
    if (session.isSignedOut) {
      _binder.adopt(null);
    } else {
      _binder.adopt(
        AuthUserSnapshot(
          uid: session.uid!,
          email: session.email,
          displayName: session.displayName,
          photoUrl: session.photoUrl,
          isAnonymous: session.isAnonymous,
          isEmailVerified: session.isEmailVerified,
          providerIds: [
            if (session.primaryProviderId != null) session.primaryProviderId!,
          ],
        ),
      );
    }
    _session = session;
    notifyListeners();
  }

  FirebaseAuth? get _firebaseAuth {
    if (_authOverride != null) return _authOverride;
    if (!SyncIdentity.canSync) return null;
    return _auth ??= FirebaseAuth.instance;
  }

  GoogleSignIn get _google {
    return _googleSignIn ??= _googleOverride ?? _platformGoogleSignIn();
  }

  GoogleSignIn _platformGoogleSignIn() {
    if (kIsWeb) {
      final clientId = DefaultFirebaseOptions.googleWebClientId;
      if (clientId.isEmpty) {
        return GoogleSignIn();
      }
      return GoogleSignIn(clientId: clientId);
    }
    return GoogleSignIn();
  }

  void startListening() {
    final auth = _firebaseAuth;
    if (auth == null) return;
    _sub?.cancel();
    final current = _snapshot(auth.currentUser);
    if (current != null) {
      _binder.adopt(current);
      _session = _binder.session;
    }
    _sub = auth.authStateChanges().listen(_onAuthState);
    notifyListeners();
  }

  void _ensureListening() {
    if (_sub != null) return;
    startListening();
  }

  void _onAuthState(User? user) {
    final auth = _firebaseAuth;
    _session = _binder.apply(
      event: _snapshot(user),
      current: _snapshot(auth?.currentUser),
      whenSettled: (epoch) {
        Future<void>.delayed(_binder.settleDelay, () {
          if (!_binder.settle(epoch, _snapshot(_firebaseAuth?.currentUser))) {
            return;
          }
          _session = _binder.session;
          notifyListeners();
        });
      },
    );
    notifyListeners();
  }

  void disposeController() {
    _sub?.cancel();
    _sub = null;
  }

  AuthUserSnapshot? _snapshot(User? user) {
    if (user == null) return null;
    return AuthUserSnapshot(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
      providerIds: [
        for (final info in user.providerData) info.providerId,
      ],
    );
  }

  Future<void> _adoptSignedInUser(User? user) async {
    User? current = user;
    if (current != null) {
      try {
        await current.reload();
      } catch (_) {}
      current = _firebaseAuth?.currentUser ?? current;
    }
    _binder.adopt(_snapshot(current));
    _session = _binder.session;
    notifyListeners();
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth != null) {
      await auth.signOut();
    }
    try {
      await _google.signOut();
    } catch (e, stack) {
      debugPrint('Google sign-out failed: $e\n$stack');
    }
    _clearPending();
    _conflictAdopted = false;
    _binder.adopt(null);
    _session = _binder.session;
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    if (!await ensureFirebaseForSignIn()) {
      return 'Firebase is not available yet. Check your connection, wait a moment, and try again.';
    }
    final auth = _firebaseAuth;
    if (auth == null) {
      return 'Firebase is not configured on this device.';
    }
    _ensureListening();
    if (!googleSignInPluginReturnsIdToken(isWeb: kIsWeb)) {
      return _signInWithGooglePopup(auth);
    }
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return kSignInCancelled;
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return 'Google did not return a sign-in token. Try again.';
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );
      final current = auth.currentUser;
      if (current != null && current.isAnonymous) {
        try {
          await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (_isLinkConflict(e)) {
            _rememberCredential(credential);
            return kAccountLinkConflict;
          }
          return _messageForAuthError(e);
        }
      } else {
        await auth.signInWithCredential(credential);
      }
      _clearPending();
      await _adoptSignedInUser(auth.currentUser);
      return null;
    } on FirebaseAuthException catch (e) {
      if (_isLinkConflict(e)) {
        return kAccountLinkConflict;
      }
      return _messageForAuthError(e);
    } catch (e, stack) {
      debugPrint('signInWithGoogle failed: $e\n$stack');
      if (kDebugMode) {
        return 'Google sign-in failed: $e';
      }
      return 'Google sign-in failed. Try again.';
    }
  }

  /// Web Google sign-in. The popup credential includes the ID token Firebase needs.
  Future<String?> _signInWithGooglePopup(FirebaseAuth auth) async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters(<dynamic, dynamic>{'prompt': 'select_account'});
    try {
      final current = auth.currentUser;
      final UserCredential signedIn;
      if (current != null && current.isAnonymous) {
        signedIn = await current.linkWithPopup(provider);
      } else {
        signedIn = await auth.signInWithPopup(provider);
      }
      _clearPending();
      await _adoptSignedInUser(signedIn.user ?? auth.currentUser);
      return null;
    } on FirebaseAuthException catch (e) {
      final popup = googlePopupFailure(e.code);
      if (popup != null) return popup;
      if (_isLinkConflict(e)) {
        final pending = e.credential;
        if (pending != null) _rememberCredential(pending);
        return kAccountLinkConflict;
      }
      return _messageForAuthError(e);
    } catch (e, stack) {
      debugPrint('signInWithGoogle failed: $e\n$stack');
      if (kDebugMode) {
        return 'Google sign-in failed: $e';
      }
      return 'Google sign-in failed. Try again.';
    }
  }

  /// Signs into the existing account, then describes what the dialog should say.
  ///
  /// An existing Auth user is not treated as a diary. Empty and unreadable
  /// accounts stay unsigned as "already has entries".
  Future<ConflictPrompt> loadLinkConflictPrompt() async {
    final local = await LocalDatabaseService.instance.hasLocalSyncRows();
    final auth = _firebaseAuth;
    if (auth == null) {
      _remoteState = RemoteDiaryState.unclear;
      return ConflictPrompt(
        remote: RemoteDiaryState.unclear,
        localDataExists: local,
      );
    }
    try {
      if (_pendingCredential != null) {
        await auth.signInWithCredential(_pendingCredential!);
      } else if (_pendingEmail != null && _pendingPassword != null) {
        await auth.signInWithEmailAndPassword(
          email: _pendingEmail!,
          password: _pendingPassword!,
        );
      } else if (auth.currentUser == null || auth.currentUser!.isAnonymous) {
        _remoteState = RemoteDiaryState.unclear;
        return ConflictPrompt(
          remote: RemoteDiaryState.unclear,
          localDataExists: local,
          signInError: 'Sign-in did not finish. Try again.',
        );
      }
    } on FirebaseAuthException catch (e) {
      _remoteState = RemoteDiaryState.unclear;
      return ConflictPrompt(
        remote: RemoteDiaryState.unclear,
        localDataExists: local,
        signInError: _messageForAuthError(e),
      );
    }
    await _adoptSignedInUser(auth.currentUser);
    _conflictAdopted = session.isDurableAccount;
    _clearPending();
    final uid = session.uid;
    var remote = RemoteDiaryState.unclear;
    if (uid != null && session.isDurableAccount) {
      remote = await CloudSyncService(userId: uid).inspectRemote();
    }
    _remoteState = remote;
    return ConflictPrompt(remote: remote, localDataExists: local);
  }

  /// Pushes this device, then pulls. Does not delete local-only rows.
  Future<String?> resolveLinkConflictUploadFirst() async {
    final uid = session.uid;
    if (uid == null || !session.isDurableAccount) {
      return 'Sign in to the account before uploading this device.';
    }
    try {
      await CloudSyncService(userId: uid).uploadLocalThenDownload();
    } catch (_) {
      return 'Upload did not finish. Your diary is still on this device.';
    }
    _conflictAdopted = false;
    await _adoptSignedInUser(_firebaseAuth?.currentUser);
    return null;
  }

  /// Pulls then pushes when the account has live rows.
  ///
  /// An empty or unreadable account is pushed instead, and tombstones are not
  /// applied, so download cannot wipe this device.
  Future<String?> resolveLinkConflictDownload() async {
    final uid = session.uid;
    if (uid == null || !session.isDurableAccount) {
      return 'Sign-in did not finish. Your diary is still on this device.';
    }
    try {
      await CloudSyncService(userId: uid).downloadAndSync();
    } catch (_) {
      return 'Download did not finish. Your diary is still on this device.';
    }
    _conflictAdopted = false;
    await _adoptSignedInUser(_firebaseAuth?.currentUser);
    return null;
  }

  /// Removes local-only rows after the account's live diary has been pulled.
  Future<String?> resolveLinkConflictReplaceLocal() async {
    final uid = session.uid;
    if (uid == null || !session.isDurableAccount) {
      return 'Sign-in did not finish. Your diary is still on this device.';
    }
    if (_remoteState != RemoteDiaryState.hasEntries) {
      return 'This account has no diary entries to download. Local data was kept.';
    }
    try {
      final result =
          await CloudSyncService(userId: uid).replaceLocalWithRemote();
      if (result.refused) {
        return 'This account has no diary entries to download. Local data was kept.';
      }
    } catch (_) {
      return 'Replace did not finish. Your diary is still on this device.';
    }
    _conflictAdopted = false;
    await _adoptSignedInUser(_firebaseAuth?.currentUser);
    return null;
  }

  /// Drops the account adopted for the conflict dialog and returns to anonymous.
  ///
  /// SQLite is not touched.
  Future<void> cancelLinkConflict() async {
    _clearPending();
    if (!_conflictAdopted) return;
    _conflictAdopted = false;
    final auth = _firebaseAuth;
    try {
      if (auth != null) await auth.signOut();
    } catch (_) {}
    try {
      await _google.signOut();
    } catch (_) {}
    try {
      if (auth != null) await auth.signInAnonymously();
    } catch (_) {}
    await _adoptSignedInUser(auth?.currentUser);
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    if (!await ensureFirebaseForSignIn()) {
      return 'Firebase is not available yet. Check your connection, wait a moment, and try again.';
    }
    final auth = _firebaseAuth;
    if (auth == null) {
      return 'Firebase is not configured on this device.';
    }
    _ensureListening();
    final trimmed = email.trim();
    try {
      final credential = EmailAuthProvider.credential(
        email: trimmed,
        password: password,
      );
      final current = auth.currentUser;
      if (createAccount) {
        if (current != null && current.isAnonymous) {
          try {
            final linked = await current.linkWithCredential(credential);
            await linked.user?.sendEmailVerification();
          } on FirebaseAuthException catch (e) {
            if (_isLinkConflict(e)) {
              _rememberEmail(trimmed, password);
              return kAccountLinkConflict;
            }
            return _messageForAuthError(e);
          }
        } else {
          final created = await auth.createUserWithEmailAndPassword(
            email: trimmed,
            password: password,
          );
          await created.user?.sendEmailVerification();
        }
      } else {
        if (current != null && current.isAnonymous) {
          try {
            await current.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (_isLinkConflict(e)) {
              _rememberEmail(trimmed, password);
              return kAccountLinkConflict;
            }
            return _messageForAuthError(e);
          }
        } else {
          await auth.signInWithEmailAndPassword(
            email: trimmed,
            password: password,
          );
        }
      }
      _clearPending();
      await _adoptSignedInUser(auth.currentUser);
      return null;
    } on FirebaseAuthException catch (e) {
      if (_isLinkConflict(e)) {
        _rememberEmail(trimmed, password);
        return kAccountLinkConflict;
      }
      return _messageForAuthError(e);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    final auth = _firebaseAuth;
    if (auth == null) return 'Firebase is not configured.';
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageForAuthError(e);
    }
  }

  Future<String?> sendEmailVerification() async {
    final auth = _firebaseAuth;
    if (auth == null) return 'Firebase is not configured.';
    final user = auth.currentUser;
    if (user == null) return 'Sign in first.';
    try {
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageForAuthError(e);
    }
  }

  Future<String?> reloadUser() async {
    final auth = _firebaseAuth;
    if (auth == null) return null;
    await _adoptSignedInUser(auth.currentUser);
    return null;
  }

  void _rememberEmail(String email, String password) {
    _pendingEmail = email;
    _pendingPassword = password;
    _pendingCredential = null;
  }

  void _rememberCredential(AuthCredential credential) {
    _pendingCredential = credential;
    _pendingEmail = null;
    _pendingPassword = null;
  }

  void _clearPending() {
    _pendingCredential = null;
    _pendingEmail = null;
    _pendingPassword = null;
  }

  bool _isLinkConflict(FirebaseAuthException e) =>
      e.code == 'email-already-in-use' || e.code == 'credential-already-in-use';

  static String? _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password. Try again or reset it.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'email-already-in-use':
        return 'That email already has an account. Sign in instead.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      default:
        return e.message ?? 'Sign-in failed (${e.code}).';
    }
  }
}
