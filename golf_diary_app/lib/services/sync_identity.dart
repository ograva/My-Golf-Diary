import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Anonymous Firebase user that owns `users/{uid}/...`.
class SyncIdentity {
  static bool get canSync => Firebase.apps.isNotEmpty;

  static String? get currentUserId =>
      canSync ? FirebaseAuth.instance.currentUser?.uid : null;

  static Future<String?> ensureSignedIn() async {
    if (!canSync) return null;
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return existing.uid;
    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user?.uid;
  }
}
