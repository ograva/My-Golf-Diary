import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final db = LocalDatabaseService.instance;

  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_holed.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_holed.db'));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  Future<void> strokes(String roundId, int hole, int count) async {
    for (var i = 0; i < count; i++) {
      await db.recordFairwayHit(
        roundId: roundId,
        holeNumber: hole,
        clubId: '7iron',
        lieType: 'fairway',
        currentLat: 0,
        currentLon: 0,
        distanceYards: 100,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  test('Finish Hole logs a holed putt: strokes + penalties + 1', () async {
    final roundId = await db.startNewRound(courseName: 'Holed', par: 4);
    await strokes(roundId, 1, 3);
    await db.incrementPenalties(roundId, 1, 1);

    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);

    final hole = (await db.getHoleScore(roundId, 1))!;
    expect(hole.strokes, 4);
    expect(hole.penalties, 1);
    expect(hole.finalScore, 5);
    expect(hole.isSynced, 0);

    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots, hasLength(4));
    final holed = shots.last;
    expect(holed.isHoled, isTrue);
    expect(holed.strokeNumber, 4);
    expect(holed.clubId, 'putter');
    expect(holed.lieType, 'green');
    expect(holed.isSynced, 0);

    expect(await db.getRoundTotal(roundId), 5);
  });

  test('Finish Hole with no recorded strokes scores 1', () async {
    final roundId = await db.startNewRound(courseName: 'Ace', par: 3);
    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);

    final hole = (await db.getHoleScore(roundId, 1))!;
    expect(hole.strokes, 1);
    expect(hole.finalScore, 1);
    expect((await db.getShotsForHole(roundId, 1)).single.isHoled, isTrue);
  });

  test('picking up at double par adds no holing stroke', () async {
    final roundId = await db.startNewRound(courseName: 'Pickup', par: 3);
    await strokes(roundId, 1, 5);
    await db.incrementPenalties(roundId, 1, 1);

    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);

    final hole = (await db.getHoleScore(roundId, 1))!;
    expect(hole.strokes, 5);
    expect(hole.finalScore, 6);
    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots.any((s) => s.isHoled), isFalse);
  });

  test('one short of double par still adds the holing stroke', () async {
    final roundId = await db.startNewRound(courseName: 'Close', par: 3);
    await strokes(roundId, 1, 5);

    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);

    expect((await db.getHoleScore(roundId, 1))!.finalScore, 6);
  });

  test('finishing the same hole again does not add a second holed stroke',
      () async {
    final roundId = await db.startNewRound(courseName: 'Twice', par: 4);
    await strokes(roundId, 1, 2);

    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);
    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);

    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots.where((s) => s.isHoled), hasLength(1));
    expect((await db.getHoleScore(roundId, 1))!.finalScore, 3);
  });

  test('deleting the holed stroke drops it from the score', () async {
    final roundId = await db.startNewRound(courseName: 'Undo', par: 4);
    await strokes(roundId, 1, 2);
    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);

    final holed = (await db.getShotsForHole(roundId, 1)).last;
    await db.deleteShot(holed);

    expect((await db.getHoleScore(roundId, 1))!.strokes, 2);
  });

  test('Finish Round on the last hole saves the holed stroke', () async {
    final roundId = await db.startNewRound(
      courseName: 'Philippine Army Golf Club (Kagitingan)',
      par: 4,
    );
    await strokes(roundId, 1, 4);
    await db.finishHole(
        roundId: roundId, holeNumber: 1, nextPar: 4, holeCount: 1);

    expect(await db.isRoundCompleted(roundId), isTrue);
    expect((await db.getHoleScore(roundId, 1))!.finalScore, 5);
    expect(await db.getRoundTotal(roundId), 5);
  });

  test('Concede then Finish: concede alone is 2 x par, Finish adds no putt',
      () async {
    final roundId = await db.startNewRound(courseName: 'Concede', par: 4);
    await strokes(roundId, 1, 3);
    await db.incrementPenalties(roundId, 1, 1);

    await db.concedeHole(roundId, 1);
    final conceded = (await db.getHoleScore(roundId, 1))!;
    expect(conceded.strokes, 8);
    expect(conceded.finalScore, 9);

    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);
    final finished = (await db.getHoleScore(roundId, 1))!;
    expect(finished.conceded, 1);
    expect(finished.strokes, 3);
    expect(finished.finalScore, 4);
    expect((await db.getShotsForHole(roundId, 1)).any((s) => s.isHoled),
        isFalse);
  });

  test('ShotRecord.isHoled reads the holed note', () {
    ShotRecord shot(String notes) => ShotRecord(
          id: 's',
          roundId: 'r',
          holeNumber: 1,
          strokeNumber: 1,
          clubId: 'putter',
          lieType: 'green',
          startLat: 0,
          startLon: 0,
          notes: notes,
          timestamp: 0,
        );
    expect(shot(kHoledShotNote).isHoled, isTrue);
    expect(shot('').isHoled, isFalse);
  });
}
