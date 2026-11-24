import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/services/cloud_sync_service.dart';
import 'package:golf_diary_app/services/diary_remote.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final db = LocalDatabaseService.instance;
  const deviceA = 'golf_diary_round_sync_a.db';
  const deviceB = 'golf_diary_round_sync_b.db';

  Future<void> useDevice(String file) async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(file);
  }

  setUp(() async {
    for (final file in [deviceA, deviceB]) {
      await deleteDatabase(join(await getDatabasesPath(), file));
    }
    await useDevice(deviceA);
  });

  tearDown(() async {
    await useDevice('golf_diary.db');
  });

  Future<String> playedRound() async {
    final roundId = await db.startNewRound(courseName: 'Local Course');
    for (var hole = 1; hole <= 3; hole++) {
      await db.incrementStrokes(
        roundId: roundId,
        courseName: 'Local Course',
        holeNumber: hole,
      );
    }
    return roundId;
  }

  test('finish stamps every hole row so the finish syncs', () async {
    final roundId = await playedRound();
    await db.completeRound(roundId);
    final rows = await db.getUnsynced('round_scores');
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row['round_finished_at_ms'], isNotNull);
    }

    await db.saveManualHoleScore(
      roundId: roundId,
      courseName: 'Local Course',
      holeNumber: 4,
      par: 4,
      strokes: 5,
      penalties: 0,
      holeComplete: true,
    );
    final hole4 = (await db.getUnsynced('round_scores'))
        .firstWhere((row) => row['hole_number'] == 4);
    expect(hole4['round_finished_at_ms'], isNotNull);
  });

  test('a finished round arrives finished and a delete removes it everywhere',
      () async {
    final remote = MemoryDiaryRemote();
    final roundId = await playedRound();
    await db.completeRound(roundId);
    await CloudSyncService(userId: 'uid', database: db, remote: remote)
        .syncAll();

    await useDevice(deviceB);
    await CloudSyncService(userId: 'uid', database: db, remote: remote)
        .downloadAndSync();
    expect((await db.listRecentRounds()).map((r) => r.roundId), [roundId]);
    expect(await db.isRoundCompleted(roundId), isTrue);

    await useDevice(deviceA);
    await db.deleteRound(roundId);
    expect(await db.listRecentRounds(), isEmpty);
    await CloudSyncService(userId: 'uid', database: db, remote: remote)
        .syncAll();
    expect(await db.getUnsynced('round_scores'), isEmpty);

    await useDevice(deviceB);
    await CloudSyncService(userId: 'uid', database: db, remote: remote)
        .downloadAndSync();
    expect(await db.listRecentRounds(), isEmpty);
    expect(await db.getScoresForRound(roundId), isEmpty);
  });

  test('an empty account does not apply round tombstones', () async {
    final remote = MemoryDiaryRemote();
    final roundId = await playedRound();
    await remote.setDocument('uid', 'round_scores', '${roundId}_h1', {
      'id': '${roundId}_h1',
      'round_id': roundId,
      'updatedAtMs': 9000000000000,
      'deleted': true,
    });

    await CloudSyncService(userId: 'uid', database: db, remote: remote)
        .pullAll(applyTombstones: false);
    expect((await db.listRecentRounds()).map((r) => r.roundId), [roundId]);
  });

  test('flight and caddy links mark a round for the stronger warning',
      () async {
    final roundId = await playedRound();
    expect(await db.roundHasFlight(roundId), isFalse);
    await db.linkRoundToFlight(roundId, 'flight_abc');
    expect(await db.roundHasFlight(roundId), isTrue);
  });
}
