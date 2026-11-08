import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final db = LocalDatabaseService.instance;

  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_unit.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_unit.db'));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  test('insertClub stores brand and model and deleteClub removes it', () async {
    const id = 'club_test_60';
    await db.insertClub(Club(
      id: id,
      name: '60°',
      category: 'wedge',
      brand: 'Vokey',
      model: 'SM10',
    ));

    final loaded = (await db.getAllClubs()).firstWhere((club) => club.id == id);
    expect(loaded.brand, 'Vokey');
    expect(loaded.model, 'SM10');
    expect(loaded.category, 'wedge');

    await db.updateClubIdentity(loaded.copyWith(
      name: 'Lob wedge',
      category: 'wedge',
      brand: 'Cleveland',
      model: 'RTX',
    ));
    final updated =
        (await db.getAllClubs()).firstWhere((club) => club.id == id);
    expect(updated.name, 'Lob wedge');
    expect(updated.brand, 'Cleveland');
    expect(updated.model, 'RTX');
    expect(updated.category, 'wedge');

    await db.deleteClub(id);
    expect((await db.getAllClubs()).any((club) => club.id == id), isFalse);
  });

  test(
      'getClubsByCategory and getAllClubs sort clubs intuitively regardless of distance',
      () async {
    await db.insertClub(
        Club(id: '5iron', name: '5 Iron', category: 'iron', avgDistance: 0));
    await db.insertClub(
        Club(id: '2iron', name: '2 Iron', category: 'iron', avgDistance: 0));
    await db.insertClub(
        Club(id: '8iron', name: '8 Iron', category: 'iron', avgDistance: 200));
    await db.insertClub(Club(
        id: 'sw', name: 'Sand Wedge', category: 'wedge', avgDistance: 120));
    await db.insertClub(
        Club(id: 'gw', name: 'Gap Wedge', category: 'wedge', avgDistance: 0));
    await db.insertClub(Club(
        id: '4hybrid', name: '4 Hybrid', category: 'hybrid', avgDistance: 190));

    final irons = await db.getClubsByCategory('iron');
    expect(
      irons.map((c) => c.name).toList(),
      ['2 Iron', '5 Iron', '7 Iron', '8 Iron', '9 Iron'],
    );

    final wedges = await db.getClubsByCategory('wedge');
    expect(
      wedges.map((c) => c.name).toList(),
      ['Pitching Wedge', 'Gap Wedge', 'Sand Wedge'],
    );

    final woods = await db.getClubsByCategory('wood');
    expect(
      woods.map((c) => c.name).toList(),
      ['Driver', '3 Wood', '5 Wood'],
    );

    final hybrids = await db.getClubsByCategory('hybrid');
    expect(
      hybrids.map((c) => c.name).toList(),
      ['3 Hybrid', '4 Hybrid'],
    );

    final all = await db.getAllClubs();
    expect(all.first.name, 'Driver');
    expect(all.last.name, 'Putter');
    expect(
      all.map((c) => c.name).toList(),
      [
        'Driver',
        '3 Wood',
        '5 Wood',
        '3 Hybrid',
        '4 Hybrid',
        '2 Iron',
        '5 Iron',
        '7 Iron',
        '8 Iron',
        '9 Iron',
        'Pitching Wedge',
        'Gap Wedge',
        'Sand Wedge',
        'Putter',
      ],
    );
  });

  test(
      'range drills are newest first and the yardage trend stays chronological',
      () async {
    final club =
        (await db.getAllClubs()).firstWhere((item) => item.id == '7iron');
    await db.saveRangeDrill(RangeDrillLog(
      id: 'drill_old',
      clubId: club.id,
      shotCount: 10,
      minYards: 130,
      maxYards: 150,
      avgYards: 140,
      venueName: 'Topgolf',
      timestamp: 1000,
    ));
    await db.saveRangeDrill(RangeDrillLog(
      id: 'drill_new',
      clubId: club.id,
      shotCount: 8,
      minYards: 140,
      maxYards: 160,
      avgYards: 150,
      venueName: 'Home sim',
      timestamp: 2000,
    ));

    final log = await db.listRangeDrills();
    expect(log.first.drill.id, 'drill_new');
    expect(log.first.drill.venueName, 'Home sim');
    expect(log.first.clubName, '7 Iron');
    expect(log.last.drill.venueName, 'Topgolf');
    expect(await db.getClubYardageTrend(club.id), [140, 150]);

    final driver =
        (await db.getAllClubs()).firstWhere((item) => item.id == 'driver');
    await db.saveRangeDrill(RangeDrillLog(
      id: 'drill_driver',
      clubId: driver.id,
      shotCount: 10,
      minYards: 200,
      maxYards: 240,
      avgYards: 220,
      timestamp: 3000,
    ));

    final ironOnly = await db.listRangeDrills(clubId: club.id);
    expect(ironOnly.map((entry) => entry.drill.id), ['drill_new', 'drill_old']);
    expect(await db.listRangeDrills(clubId: 'missing'), isEmpty);
  });

  test('updateCourseName rewrites every hole in the round', () async {
    final roundId = await db.startNewRound(courseName: 'Local Course');
    await db.saveManualHoleScore(
      roundId: roundId,
      courseName: 'Local Course',
      holeNumber: 2,
      par: 5,
      strokes: 6,
      penalties: 0,
      holeComplete: true,
    );

    await db.updateCourseName(roundId, 'Pebble Beach');

    final holes = await db.getScoresForRound(roundId);
    expect(holes, hasLength(2));
    expect(holes.every((hole) => hole.courseName == 'Pebble Beach'), isTrue);
  });

  test('simulator fairway hit stores typed yards and leaves the previous shot',
      () async {
    final roundId = await db.startNewRound(courseName: 'Sim');
    final driver =
        (await db.getAllClubs()).firstWhere((club) => club.id == 'driver');

    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: driver.id,
      lieType: 'tee',
      currentLat: 1,
      currentLon: 2,
      distanceYards: 247.2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: '7iron',
      lieType: 'fairway',
      currentLat: 9,
      currentLon: 9,
      distanceYards: 150.8,
    );

    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots, hasLength(2));
    expect(shots.first.distanceYards, 247);
    expect(shots.first.startLat, 0);
    expect(shots.first.startLon, 0);
    expect(shots.first.strokeNumber, 1);
    expect(shots.last.distanceYards, 151);
    expect(shots.last.startLat, 0);
    expect(shots.last.strokeNumber, 2);
    expect((await db.getHoleScore(roundId, 1))!.strokes, 2);
    expect(
        (await db.getAllClubs())
            .firstWhere((club) => club.id == 'driver')
            .avgDistance,
        driver.avgDistance);
  });

  test(
      'GPS fairway hit still closes the previous shot and leaves the new one pending',
      () async {
    final roundId = await db.startNewRound(courseName: 'Outdoor');
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: 'driver',
      lieType: 'tee',
      currentLat: 37.0,
      currentLon: -122.0,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 1,
      clubId: '7iron',
      lieType: 'fairway',
      currentLat: 37.002,
      currentLon: -122.0,
    );

    final shots = await db.getShotsForHole(roundId, 1);
    expect(shots.first.distanceYards, greaterThan(0));
    expect(shots.first.endLat, 37.002);
    expect(shots.last.distanceYards, 0);
    expect(shots.last.startLat, 37.002);
  });

  test('startNewRound creates a different round while another is still active',
      () async {
    final first = await db.ensureActiveRound(courseName: 'Morning');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = await db.startNewRound(courseName: 'Afternoon');

    expect(second, isNot(first));
    expect(await db.getActiveRoundId(), second);
    final earlier = await db.getScoresForRound(first);
    expect(earlier.single.courseName, 'Morning');
    expect((await db.getScoresForRound(second)).single.courseName, 'Afternoon');
  });

  test('finish hole advances the resume hole and deleting a shot renumbers',
      () async {
    final roundId = await db.startNewRound(courseName: 'Resume');
    expect(await db.currentHoleNumber(roundId), 1);
    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);
    expect(await db.currentHoleNumber(roundId), 2);

    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 2,
      clubId: 'driver',
      lieType: 'tee',
      currentLat: 0,
      currentLon: 0,
      distanceYards: 200,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 2,
      clubId: '7iron',
      lieType: 'tee',
      currentLat: 0,
      currentLon: 0,
      distanceYards: 140,
    );
    final first = (await db.getShotsForHole(roundId, 2)).first;
    await db.updateShotDetails(
        shotId: first.id, clubId: 'driver', lieType: 'rough');
    expect((await db.getShotsForHole(roundId, 2)).first.lieType, 'rough');

    await db.deleteShot(first);
    final left = await db.getShotsForHole(roundId, 2);
    expect(left, hasLength(1));
    expect(left.single.strokeNumber, 1);
    expect((await db.getHoleScore(roundId, 2))!.strokes, 1);
  });

  test('completeRound saves in-progress play and clears active round',
      () async {
    final roundId = await db.startNewRound(courseName: 'Save Me');
    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);
    await db.recordFairwayHit(
      roundId: roundId,
      holeNumber: 2,
      clubId: 'driver',
      lieType: 'tee',
      currentLat: 0,
      currentLon: 0,
      distanceYards: 210,
    );
    expect(await db.roundHasMeaningfulPlay(roundId), isTrue);
    await db.completeRound(roundId);
    expect(await db.getActiveRoundId(), isNull);
    expect(await db.isRoundCompleted(roundId), isTrue);
    expect(
        (await db.listRecentRounds()).any((r) => r.roundId == roundId), isTrue);
    final hole2 = await db.getHoleScore(roundId, 2);
    expect(hole2!.finalScore, greaterThan(0));
  });

  test('applyCoursePar sets unplayed holes from the card and keeps played pars',
      () async {
    final roundId = await db.startNewRound(
        courseName: 'Club Intramuros Golf Course', par: 3);
    expect((await db.getHoleScore(roundId, 1))!.par, 3);

    await db.saveManualHoleScore(
      roundId: roundId,
      courseName: 'Club Intramuros Golf Course',
      holeNumber: 2,
      par: 5,
      strokes: 4,
      penalties: 0,
      holeComplete: true,
    );

    await db.applyCoursePar(roundId, 'Wack Wack Golf & Country Club — East');
    expect((await db.getHoleScore(roundId, 1))!.par, 4);
    expect((await db.getHoleScore(roundId, 1))!.courseName,
        'Wack Wack Golf & Country Club — East');
    expect((await db.getHoleScore(roundId, 2))!.par, 5);

    await db.applyCoursePar(roundId, 'Club Intramuros Golf Course');
    expect((await db.getHoleScore(roundId, 1))!.par, 3);
    expect((await db.getHoleScore(roundId, 2))!.par, 5);

    await db.applyCoursePar(roundId, 'My Backyard');
    expect((await db.getHoleScore(roundId, 1))!.par, 4);
    expect((await db.getHoleScore(roundId, 2))!.par, 5);
    expect((await db.listRecentRounds()).first.courseName, 'My Backyard');
  });

  test('finishHole on a 9-hole card completes at hole 9', () async {
    final roundId = await db.startNewRound(
      courseName: 'Philippine Army Golf Club (Kagitingan)',
      par: 4,
    );
    await db.finishHole(
        roundId: roundId, holeNumber: 1, nextPar: 3, holeCount: 9);
    expect(await db.isRoundCompleted(roundId), isFalse);
    expect((await db.getHoleScore(roundId, 2))!.par, 3);

    await db.finishHole(
        roundId: roundId, holeNumber: 9, nextPar: 4, holeCount: 9);
    expect(await db.isRoundCompleted(roundId), isTrue);
    expect(await db.getHoleScore(roundId, 10), isNull);
  });

  test('discardRound removes round from recent list', () async {
    final roundId = await db.startNewRound(courseName: 'Trash');
    await db.finishHole(roundId: roundId, holeNumber: 1, nextPar: 4);
    await db.discardRound(roundId);
    expect(await db.getActiveRoundId(), isNull);
    expect((await db.listRecentRounds()).any((r) => r.roundId == roundId),
        isFalse);
  });
}
