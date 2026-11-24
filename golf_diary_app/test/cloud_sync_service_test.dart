import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/cloud_sync_service.dart';
import 'package:golf_diary_app/services/diary_remote.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/remote_diary_state.dart';
import 'package:golf_diary_app/services/sync_merge.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final db = LocalDatabaseService.instance;

  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_sync.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_sync.db'));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  test('newer remote wins and an older remote stays local', () {
    expect(
      decideMerge(
          localExists: false, localUpdatedAtMs: 0, remoteUpdatedAtMs: 5),
      MergeAction.applyRemote,
    );
    expect(
      decideMerge(
          localExists: true, localUpdatedAtMs: 10, remoteUpdatedAtMs: 11),
      MergeAction.applyRemote,
    );
    expect(
      decideMerge(
          localExists: true, localUpdatedAtMs: 11, remoteUpdatedAtMs: 11),
      MergeAction.keepLocal,
    );
  });

  test('sync uploads dirty rows and leaves a failed write dirty', () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);

    final first = await sync.syncAll();
    expect(first.failed, 0);
    expect(first.pushed, greaterThan(0));
    expect(remote.docs.containsKey('uid/clubs/driver'), isTrue);
    expect(await db.getUnsynced('clubs'), isEmpty);

    await db.updateClubSwingNotes('driver', 'Pause at the top');
    remote.failOnSet = StateError('offline');
    final second = await sync.syncAll();
    expect(second.failed, 1);
    expect(second.pushed, 0);
    expect((await db.getUnsynced('clubs')).single['id'], 'driver');
  });

  test('pull applies a newer club and a tombstone removes it', () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    await sync.syncAll();

    await remote.setDocument('uid', 'clubs', 'driver', {
      'id': 'driver',
      'name': 'Driver X',
      'category': 'wood',
      'brand': '',
      'model': '',
      'min_distance': 0,
      'max_distance': 0,
      'avg_distance': 240,
      'swing_notes': '',
      'updatedAtMs': 9000000000000,
      'deleted': false,
    });
    expect(await sync.pullAll(), greaterThan(0));
    final pulled =
        (await db.getAllClubs()).firstWhere((club) => club.id == 'driver');
    expect(pulled.name, 'Driver X');
    expect(pulled.avgDistance, 240);

    await remote.setDocument('uid', 'clubs', 'driver', {
      'id': 'driver',
      'updatedAtMs': 9000000000001,
      'deleted': true,
    });
    await sync.pullAll();
    expect(
        (await db.getAllClubs()).any((club) => club.id == 'driver'), isFalse);
  });

  test('deleting a club pushes a tombstone and then drops the local row',
      () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    await db.insertClub(Club(id: 'gap', name: 'Gap', category: 'wedge'));
    await db.deleteClub('gap');
    expect((await db.getAllClubs()).any((club) => club.id == 'gap'), isFalse);

    await sync.syncAll();
    expect(remote.docs['uid/clubs/gap']?['deleted'], isTrue);
    final leftover = await db.getUnsynced('clubs');
    expect(leftover.any((row) => row['id'] == 'gap'), isFalse);
  });

  test('a newer tombstone pull deletes the local row', () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    await _insertShot(db, 'shot-local');
    await remote.setDocument('uid', 'shots', 'shot-local', {
      'id': 'shot-local',
      'updatedAtMs': 9000000000000,
      'deleted': true,
    });

    await sync.pullAll();

    expect(await db.hasLiveRow('shots', 'shot-local'), isFalse);
  });

  test('empty account is not treated as having entries', () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    expect(await sync.inspectRemote(), RemoteDiaryState.empty);

    await remote.setDocument('uid', 'shots', 'gone', {
      'id': 'gone',
      'updatedAtMs': 5,
      'deleted': true,
    });
    expect(await sync.inspectRemote(), RemoteDiaryState.empty);

    await remote.setDocument('uid', 'shots', 'kept', _shotDoc('kept'));
    expect(await sync.inspectRemote(), RemoteDiaryState.hasEntries);
  });

  test('download on an empty account keeps local shots and uploads them',
      () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    await _insertShot(db, 'shot-local');
    await remote.setDocument('uid', 'shots', 'shot-local', {
      'id': 'shot-local',
      'updatedAtMs': 9000000000000,
      'deleted': true,
    });

    final result = await sync.downloadAndSync();

    expect(result.failed, 0);
    expect(await db.hasLiveRow('shots', 'shot-local'), isTrue);
    expect(remote.docs['uid/shots/shot-local']?['deleted'], isFalse);
  });

  test('replace refuses to wipe local data when the account has no live rows',
      () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    await _insertShot(db, 'shot-local');
    await remote.setDocument('uid', 'shots', 'shot-local', {
      'id': 'shot-local',
      'updatedAtMs': 9000000000000,
      'deleted': true,
    });

    final result = await sync.replaceLocalWithRemote();

    expect(result.refused, isTrue);
    expect(result.removed, 0);
    expect(await db.hasLiveRow('shots', 'shot-local'), isTrue);
    expect(await db.hasLiveRow('clubs', 'driver'), isTrue);
  });

  test('replace removes local-only rows only when the remote diary is real',
      () async {
    final remote = MemoryDiaryRemote();
    final sync = CloudSyncService(userId: 'uid', database: db, remote: remote);
    await _insertShot(db, 'shot-local');
    await remote.setDocument(
        'uid', 'shots', 'shot-cloud', _shotDoc('shot-cloud'));

    final result = await sync.replaceLocalWithRemote();

    expect(result.refused, isFalse);
    expect(await db.hasLiveRow('shots', 'shot-local'), isFalse);
    expect(await db.hasLiveRow('shots', 'shot-cloud'), isTrue);
  });
}

Future<void> _insertShot(LocalDatabaseService db, String id) async {
  final database = await db.database;
  await database.insert('shots', {
    'id': id,
    'round_id': 'round-1',
    'hole_number': 1,
    'stroke_number': 1,
    'club_id': 'driver',
    'lie_type': 'tee',
    'start_lat': 0,
    'start_lon': 0,
    'timestamp': 10,
    'updated_at_ms': 10,
    'deleted': 0,
    'is_synced': 0,
  });
}

Map<String, dynamic> _shotDoc(String id) {
  return {
    'id': id,
    'round_id': 'round-1',
    'hole_number': 1,
    'stroke_number': 1,
    'club_id': 'driver',
    'lie_type': 'tee',
    'start_lat': 0,
    'start_lon': 0,
    'timestamp': 10,
    'updatedAtMs': 20,
    'deleted': false,
  };
}
