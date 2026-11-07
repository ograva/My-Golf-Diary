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
    final updated = (await db.getAllClubs()).firstWhere((club) => club.id == id);
    expect(updated.name, 'Lob wedge');
    expect(updated.brand, 'Cleveland');
    expect(updated.model, 'RTX');
    expect(updated.category, 'wedge');

    await db.deleteClub(id);
    expect((await db.getAllClubs()).any((club) => club.id == id), isFalse);
  });

  test('range drills are newest first and the yardage trend stays chronological', () async {
    final club = (await db.getAllClubs()).firstWhere((item) => item.id == '7iron');
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

    final driver = (await db.getAllClubs()).firstWhere((item) => item.id == 'driver');
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

  test('simulator fairway hit stores typed yards and leaves the previous shot', () async {
    final roundId = await db.startNewRound(courseName: 'Sim');
    final driver = (await db.getAllClubs()).firstWhere((club) => club.id == 'driver');

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
    expect((await db.getAllClubs()).firstWhere((club) => club.id == 'driver').avgDistance, driver.avgDistance);
  });

  test('GPS fairway hit still closes the previous shot and leaves the new one pending', () async {
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

  test('startNewRound creates a different round while another is still active', () async {
    final first = await db.ensureActiveRound(courseName: 'Morning');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = await db.startNewRound(courseName: 'Afternoon');

    expect(second, isNot(first));
    expect(await db.getActiveRoundId(), second);
    final earlier = await db.getScoresForRound(first);
    expect(earlier.single.courseName, 'Morning');
    expect((await db.getScoresForRound(second)).single.courseName, 'Afternoon');
  });

  test('finish hole advances the resume hole and deleting a shot renumbers', () async {
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
    await db.updateShotDetails(shotId: first.id, clubId: 'driver', lieType: 'rough');
    expect((await db.getShotsForHole(roundId, 2)).first.lieType, 'rough');

    await db.deleteShot(first);
    final left = await db.getShotsForHole(roundId, 2);
    expect(left, hasLength(1));
    expect(left.single.strokeNumber, 1);
    expect((await db.getHoleScore(roundId, 2))!.strokes, 1);
  });
}
