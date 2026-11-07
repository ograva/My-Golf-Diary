import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/cloud_sync_service.dart';
import 'package:golf_diary_app/services/diary_remote.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
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
      decideMerge(localExists: false, localUpdatedAtMs: 0, remoteUpdatedAtMs: 5),
      MergeAction.applyRemote,
    );
    expect(
      decideMerge(localExists: true, localUpdatedAtMs: 10, remoteUpdatedAtMs: 11),
      MergeAction.applyRemote,
    );
    expect(
      decideMerge(localExists: true, localUpdatedAtMs: 11, remoteUpdatedAtMs: 11),
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
    final pulled = (await db.getAllClubs()).firstWhere((club) => club.id == 'driver');
    expect(pulled.name, 'Driver X');
    expect(pulled.avgDistance, 240);

    await remote.setDocument('uid', 'clubs', 'driver', {
      'id': 'driver',
      'updatedAtMs': 9000000000001,
      'deleted': true,
    });
    await sync.pullAll();
    expect((await db.getAllClubs()).any((club) => club.id == 'driver'), isFalse);
  });

  test('deleting a club pushes a tombstone and then drops the local row', () async {
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
}
