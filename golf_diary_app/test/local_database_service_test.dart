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
}
