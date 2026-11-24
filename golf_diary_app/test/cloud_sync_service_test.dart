import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/diary_context_note.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/cloud_sync_service.dart';
import 'package:golf_diary_app/services/diary_remote.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/remote_diary_state.dart';
import 'package:golf_diary_app/services/swing_diary_service.dart';
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

  group('swing diary sync', () {
    test('a second browser downloads the thread, replies, notes, and sessions',
        () async {
      final remote = MemoryDiaryRemote();
      final diary = SwingDiaryService(database: db);
      await diary.setOptedIn(true);
      await diary.appendContextNote(
        content: 'Range: 7i felt flushed',
        source: DiaryContextSource.diary,
        now: DateTime(2026, 11, 20, 9),
      );
      final exchange = await diary.ask(
        prompt: 'prompt',
        reply: 'Keep the tempo.',
        userText: 'How was my 7 iron?',
        now: DateTime(2026, 11, 20, 10),
      );
      await db.compileRangeSession(sessionNote: 'Windy bay');
      final first = await CloudSyncService(
        userId: 'uid',
        database: db,
        remote: remote,
      ).uploadLocalThenDownload();
      expect(first.failed, 0);
      expect(
          remote.docs.keys
              .where((k) => k.startsWith('uid/swing_diary_messages/')),
          hasLength(3));

      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary_sync_b.db');
      await deleteDatabase(
          join(await getDatabasesPath(), 'golf_diary_sync_b.db'));
      final browserB = SwingDiaryService(database: db);
      expect(await browserB.isOptedIn(), isFalse);

      final pulled = await CloudSyncService(
        userId: 'uid',
        database: db,
        remote: remote,
      ).downloadAndSync();

      expect(pulled.failed, 0);
      final messages = await browserB.listMessages();
      expect(
          messages.map((m) => m.content),
          containsAll([
            'Range: 7i felt flushed',
            'How was my 7 iron?',
            'Keep the tempo.'
          ]));
      final evaluations = await browserB.listEvaluations();
      expect(evaluations.single.id, exchange.evaluationId);
      expect((await browserB.listContextNotes()).single.content,
          'Range: 7i felt flushed');
      expect((await db.listRangeSessions()).single.sessionNote, 'Windy bay');
      expect(await browserB.isOptedIn(), isTrue);
      expect(await db.getUnsynced('swing_diary_messages'), isEmpty);
    });

    test('an empty account uploads diary rows and ignores their tombstones',
        () async {
      final remote = MemoryDiaryRemote();
      final diary = SwingDiaryService(database: db);
      final exchange = await diary.ask(
        prompt: 'prompt',
        reply: 'Reply',
        userText: 'Question',
        now: DateTime(2026, 11, 21, 8),
      );
      await remote
          .setDocument('uid', 'range_evaluations', exchange.evaluationId, {
        'id': exchange.evaluationId,
        'updatedAtMs': 9000000000000,
        'deleted': true,
      });

      final result = await CloudSyncService(
        userId: 'uid',
        database: db,
        remote: remote,
      ).downloadAndSync();

      expect(result.failed, 0);
      expect(await db.hasLiveRow('range_evaluations', exchange.evaluationId),
          isTrue);
      expect(
          remote.docs['uid/range_evaluations/${exchange.evaluationId}']
              ?['deleted'],
          isFalse);
      expect((await diary.listMessages()), hasLength(2));
    });

    test('a newer tombstone on a live account removes the diary message',
        () async {
      final remote = MemoryDiaryRemote();
      final sync =
          CloudSyncService(userId: 'uid', database: db, remote: remote);
      final diary = SwingDiaryService(database: db);
      final exchange = await diary.ask(
        prompt: 'prompt',
        reply: 'Reply',
        userText: 'Question',
        now: DateTime(2026, 11, 22, 8),
      );
      await sync.syncAll();
      await remote
          .setDocument('uid', 'swing_diary_messages', exchange.reply.id, {
        'id': exchange.reply.id,
        'updatedAtMs': 9000000000000,
        'deleted': true,
      });

      await sync.downloadAndSync();

      expect(await db.hasLiveRow('swing_diary_messages', exchange.reply.id),
          isFalse);
      expect((await diary.listMessages()).single.content, 'Question');
    });

    test('an older remote diary row does not overwrite a local edit', () async {
      final remote = MemoryDiaryRemote();
      final sync =
          CloudSyncService(userId: 'uid', database: db, remote: remote);
      final diary = SwingDiaryService(database: db);
      final exchange = await diary.ask(
        prompt: 'prompt',
        reply: 'Local reply',
        userText: 'Question',
        now: DateTime(2026, 11, 22, 8),
      );
      await remote
          .setDocument('uid', 'swing_diary_messages', exchange.reply.id, {
        'id': exchange.reply.id,
        'role': 'model',
        'content': 'Stale reply',
        'timestamp': 1,
        'updatedAtMs': 1,
        'deleted': false,
      });

      await sync.downloadAndSync();

      expect((await diary.listMessages()).last.content, 'Local reply');
      expect(
          remote.docs['uid/swing_diary_messages/${exchange.reply.id}']
              ?['content'],
          'Local reply');
    });
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
