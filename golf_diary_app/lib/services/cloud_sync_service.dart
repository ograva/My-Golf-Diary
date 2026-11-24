import 'package:firebase_core/firebase_core.dart';

import '../app_check_config.dart';
import '../firebase_options.dart';
import 'diary_remote.dart';
import 'local_database_service.dart';
import 'remote_diary_state.dart';
import 'sync_constants.dart';
import 'sync_identity.dart';
import 'sync_merge.dart';

class SyncResult {
  const SyncResult({this.pushed = 0, this.failed = 0, this.pulled = 0});

  final int pushed;
  final int failed;
  final int pulled;
}

/// Outcome of replacing this device with the account diary.
class ReplaceResult {
  const ReplaceResult({
    required this.refused,
    this.removed = 0,
    this.pulled = 0,
  });

  /// True when the remote copy is empty or unreadable, so local rows stay.
  final bool refused;
  final int removed;
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

  /// Live remote rows, ignoring tombstones. Unreadable clouds are [RemoteDiaryState.unclear].
  Future<RemoteDiaryState> inspectRemote() async {
    try {
      final listed = await _listAll();
      if (listed == null) return RemoteDiaryState.unclear;
      if (listed.liveCount == 0) return RemoteDiaryState.empty;
      return RemoteDiaryState.hasEntries;
    } catch (_) {
      return RemoteDiaryState.unclear;
    }
  }

  /// Pushes this device, then pulls. An empty or unreadable account does not
  /// apply tombstones, so a new account cannot delete local rows.
  Future<SyncResult> uploadLocalThenDownload() async {
    final state = await inspectRemote();
    final pushed = await syncAll();
    if (state != RemoteDiaryState.hasEntries) {
      final pulled = await pullAll(applyTombstones: false);
      return SyncResult(
        pushed: pushed.pushed,
        failed: pushed.failed,
        pulled: pulled,
      );
    }
    final pulled = await pullAll();
    final rest = await syncAll();
    return SyncResult(
      pushed: pushed.pushed + rest.pushed,
      failed: pushed.failed + rest.failed,
      pulled: pulled,
    );
  }

  /// Download-and-sync. Local rows are removed only by an explicit replace
  /// of a remote diary that has live entries.
  ///
  /// When the account has no live rows, this pushes first and ignores
  /// tombstones. Pull-first used to delete local ids whose `updated_at_ms`
  /// was still 0, including the seeded bag, whenever a newer tombstone existed.
  Future<SyncResult> downloadAndSync() async {
    final state = await inspectRemote();
    if (state != RemoteDiaryState.hasEntries) {
      final pushed = await syncAll();
      final pulled = await pullAll(applyTombstones: false);
      return SyncResult(
        pushed: pushed.pushed,
        failed: pushed.failed,
        pulled: pulled,
      );
    }
    final pulled = await pullAll();
    final pushed = await syncAll();
    return SyncResult(
      pushed: pushed.pushed,
      failed: pushed.failed,
      pulled: pulled,
    );
  }

  /// Pulls a live remote diary, then deletes local rows that are not in it.
  ///
  /// Refuses when the remote copy has no live rows or could not be read.
  Future<ReplaceResult> replaceLocalWithRemote() async {
    final listed = await _listAll();
    if (listed == null || listed.liveCount == 0) {
      return const ReplaceResult(refused: true);
    }
    final pulled = await pullAll();
    final removed = await _db.deleteLocalRowsMissingFrom(listed.liveIds);
    return ReplaceResult(refused: false, removed: removed, pulled: pulled);
  }

  Future<int> pullAll({bool applyTombstones = true}) async {
    if (!isAvailable) return 0;
    var applied = 0;
    for (final table in kSyncTables) {
      final remoteRows = await _store.listDocuments(userId, table);
      for (final remote in remoteRows) {
        if (!applyTombstones && readDeleted(remote)) continue;
        if (await _db.applyRemoteRow(table, remote)) applied += 1;
      }
    }
    await _db.setLastPulledAt(DateTime.now().millisecondsSinceEpoch);
    return applied;
  }

  Future<_RemoteListing?> _listAll() async {
    if (!isAvailable) return null;
    final liveIds = <String, Set<String>>{};
    var liveCount = 0;
    for (final table in kSyncTables) {
      final rows = await _store.listDocuments(userId, table);
      final ids = <String>{};
      for (final row in rows) {
        if (readDeleted(row)) continue;
        final id = row['id'] as String?;
        if (id == null || id.isEmpty) continue;
        ids.add(id);
        liveCount += 1;
      }
      liveIds[table] = ids;
    }
    return _RemoteListing(liveIds: liveIds, liveCount: liveCount);
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

class _RemoteListing {
  const _RemoteListing({required this.liveIds, required this.liveCount});

  final Map<String, Set<String>> liveIds;
  final int liveCount;
}

/// How long a Firebase startup step may wait before the app continues local-only.
const Duration kOptionalFirebaseStartupLimit = Duration(seconds: 8);

/// Ensures Firebase is initialized before sign-in UI (PWA may still be starting cloud).
Future<bool> ensureFirebaseForSignIn() async {
  if (Firebase.apps.isNotEmpty) return true;
  return initializeFirebase();
}

Future<bool> initializeFirebase() async {
  final alreadyRunning = Firebase.apps.isNotEmpty;
  try {
    if (!alreadyRunning) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(kOptionalFirebaseStartupLimit);
    }
  } catch (_) {
    return false;
  }

  // App Check loads reCAPTCHA; anonymous sign-in waits on Auth. Either can
  // hang when the radio is up but nothing is reachable. A persisted user is
  // still readable once [Firebase.initializeApp] has returned.
  try {
    await activateWebAppCheck().timeout(kOptionalFirebaseStartupLimit);
  } catch (_) {}

  try {
    await SyncIdentity.ensureSignedIn().timeout(kOptionalFirebaseStartupLimit);
  } catch (_) {}

  return Firebase.apps.isNotEmpty;
}
