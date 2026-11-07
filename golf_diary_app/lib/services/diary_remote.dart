import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'sync_constants.dart';

/// Cloud copy of one SQLite table, scoped to a signed-in user.
abstract class DiaryRemote {
  Future<void> setDocument(String userId, String table, String id, Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> listDocuments(String userId, String table);
}

class FirestoreDiaryRemote implements DiaryRemote {
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: kFirestoreDatabaseId,
      );

  CollectionReference<Map<String, dynamic>> _collection(String userId, String table) {
    return _firestore.collection('users').doc(userId).collection(table);
  }

  @override
  Future<void> setDocument(String userId, String table, String id, Map<String, dynamic> data) {
    return _collection(userId, table).doc(id).set(data, SetOptions(merge: true));
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments(String userId, String table) async {
    final snapshot = await _collection(userId, table).get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }
}

/// In-memory stand-in used by unit tests.
class MemoryDiaryRemote implements DiaryRemote {
  final Map<String, Map<String, dynamic>> docs = {};
  Object? failOnSet;

  String _key(String userId, String table, String id) => '$userId/$table/$id';

  @override
  Future<void> setDocument(String userId, String table, String id, Map<String, dynamic> data) async {
    if (failOnSet != null) throw failOnSet!;
    docs[_key(userId, table, id)] = {...data, 'id': id};
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments(String userId, String table) async {
    final prefix = '$userId/$table/';
    return docs.entries.where((entry) => entry.key.startsWith(prefix)).map((entry) => Map<String, dynamic>.from(entry.value)).toList();
  }
}
