import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'local_database_service.dart';

/// Pushes locally dirty rows to Firestore under users/{userId}/...
class CloudSyncService {
  CloudSyncService({
    required this.userId,
    LocalDatabaseService? database,
  }) : _db = database ?? LocalDatabaseService.instance;

  final String userId;
  final LocalDatabaseService _db;

  static const _tables = ['clubs', 'shots', 'round_scores', 'range_drills'];

  bool get isAvailable => Firebase.apps.isNotEmpty;

  Future<int> syncAll() async {
    if (!isAvailable) return 0;

    var pushed = 0;
    for (final table in _tables) {
      pushed += await _syncTable(table);
    }
    return pushed;
  }

  Future<int> _syncTable(String table) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('users').doc(userId).collection(table);
    final rows = await _db.getUnsynced(table);

    for (final row in rows) {
      final id = row['id'] as String;
      await collection.doc(id).set(row, SetOptions(merge: true));
      await _db.markSynced(table, id);
    }
    return rows.length;
  }
}

Future<bool> initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return true;
  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    return false;
  }
}
