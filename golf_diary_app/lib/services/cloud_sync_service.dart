import 'package:firebase_core/firebase_core.dart';

import '../app_check_config.dart';
import '../firebase_options.dart';
import 'diary_remote.dart';
import 'local_database_service.dart';
import 'sync_constants.dart';
import 'sync_identity.dart';
import 'sync_merge.dart';

class SyncResult {
  const SyncResult({this.pushed = 0, this.failed = 0, this.pulled = 0});

  final int pushed;
  final int failed;
  final int pulled;
}

/// Pulls newer Firestore rows, then pushes dirty local rows.
class CloudSyncService {
  CloudSyncService({
    required this.userId,
    LocalDatabaseService? database,
    DiaryRemote? remote,
  })  : _db = database ?? LocalDatabaseService.instance,
        _remote = remote;

  final String userId;
  final LocalDatabaseService _db;
  final DiaryRemote? _remote;

  bool get isAvailable => _remote != null || Firebase.apps.isNotEmpty;

  DiaryRemote get _store => _remote ?? FirestoreDiaryRemote();

  Future<SyncResult> syncFull() async {
    if (!isAvailable) return const SyncResult();
    final pulled = await pullAll();
    final push = await syncAll();
    return SyncResult(pushed: push.pushed, failed: push.failed, pulled: pulled);
  }

  Future<int> pullAll() async {
    if (!isAvailable) return 0;
    var applied = 0;
    for (final table in kSyncTables) {
      final remoteRows = await _store.listDocuments(userId, table);
      for (final remote in remoteRows) {
        if (await _db.applyRemoteRow(table, remote)) applied += 1;
      }
    }
    await _db.setLastPulledAt(DateTime.now().millisecondsSinceEpoch);
    return applied;
  }

  Future<SyncResult> syncAll() async {
    if (!isAvailable) return const SyncResult();
    var pushed = 0;
    var failed = 0;
    for (final table in kSyncTables) {
      final outcome = await _syncTable(table);
      pushed += outcome.pushed;
      failed += outcome.failed;
    }
    return SyncResult(pushed: pushed, failed: failed);
  }

  Future<SyncResult> _syncTable(String table) async {
    final rows = await _db.prepareUnsyncedForPush(table);
    var pushed = 0;
    var failed = 0;
    for (final row in rows) {
      final id = row['id'] as String;
      final updatedAt = readUpdatedAtMs(row);
      final payload = <String, dynamic>{
        ...row,
        'updated_at_ms': updatedAt,
        'updatedAtMs': updatedAt,
        'deleted': readDeleted(row),
      };
      try {
        await _store.setDocument(userId, table, id, payload);
        await _db.finishPush(table, id, row);
        pushed += 1;
      } catch (_) {
        failed += 1;
      }
    }
    return SyncResult(pushed: pushed, failed: failed);
  }
}

Future<bool> initializeFirebase() async {
  final alreadyRunning = Firebase.apps.isNotEmpty;
  try {
    if (!alreadyRunning) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    await activateWebAppCheck();
    if (!alreadyRunning) {
      await SyncIdentity.ensureSignedIn();
    }
    return true;
  } catch (_) {
    return false;
  }
}
