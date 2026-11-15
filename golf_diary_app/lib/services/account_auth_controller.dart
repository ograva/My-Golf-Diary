import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'account_session.dart';
import 'sync_identity.dart';

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

  AccountSession _session = const AccountSession.signedOut();

  AccountSession get session => _session;

  @visibleForTesting
  void debugSetSession(AccountSession session) {
    _session = session;
    notifyListeners();
  }

  FirebaseAuth? get _firebaseAuth {
    if (_authOverride != null) return _authOverride;
    if (!SyncIdentity.canSync) return null;
    return _auth ??= FirebaseAuth.instance;
  }

  GoogleSignIn get _google {
    return _googleSignIn ??= _googleOverride ?? GoogleSignIn();
  }

  void startListening() {
    final auth = _firebaseAuth;
    if (auth == null) return;
    _sub?.cancel();
    _session = _fromUser(auth.currentUser);
    _sub = auth.authStateChanges().listen((user) {
      _session = _fromUser(user);
      notifyListeners();
    });
  }

  void disposeController() {
    _sub?.cancel();
    _sub = null;
  }

  AccountSession _fromUser(User? user) {
    if (user == null) return const AccountSession.signedOut();
    final provider = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : (user.isAnonymous ? 'anonymous' : 'password');
    return AccountSession(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
      primaryProviderId: user.isAnonymous ? 'anonymous' : provider,
    );
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth != null) {
      await auth.signOut();
    }
    await _google.signOut();
    _session = const AccountSession.signedOut();
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      return 'Firebase is not configured on this device.';
    }
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final current = auth.currentUser;
      if (current != null && current.isAnonymous) {
        try {
          await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            return _ConflictMarker.linkFailed;
          }
          return _messageForAuthError(e);
        }
      } else {
        await auth.signInWithCredential(credential);
      }
      _session = _fromUser(auth.currentUser);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _messageForAuthError(e);
    } catch (_) {
      return 'Google sign-in failed. Try again.';
    }
  }

  Future<String?> resolveLinkConflictUploadFirst() async {
    return 'Full upload-then-download conflict flow is not available yet.';
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
    required bool createAccount,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      return 'Firebase is not configured on this device.';
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final current = auth.currentUser;
      if (createAccount) {
        if (current != null && current.isAnonymous) {
          try {
            final linked = await current.linkWithCredential(credential);
            await linked.user?.sendEmailVerification();
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use' ||
                e.code == 'credential-already-in-use') {
              return _ConflictMarker.linkFailed;
            }
            return _messageForAuthError(e);
          }
        } else {
          final created = await auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          await created.user?.sendEmailVerification();
        }
      } else {
        if (current != null && current.isAnonymous) {
          try {
            await current.linkWithCredential(credential);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'email-already-in-use' ||
                e.code == 'credential-already-in-use') {
              return _ConflictMarker.linkFailed;
            }
            return _messageForAuthError(e);
          }
        } else {
          await auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        }
      }
      _session = _fromUser(auth.currentUser);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
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
    await auth.currentUser?.reload();
    _session = _fromUser(auth.currentUser);
    notifyListeners();
    return null;
  }

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

/// Returned to the login sheet to open the conflict dialog.
class _ConflictMarker {
  static const linkFailed = '__account_link_conflict__';
}

bool isAccountLinkConflict(String? message) =>
    message == _ConflictMarker.linkFailed;