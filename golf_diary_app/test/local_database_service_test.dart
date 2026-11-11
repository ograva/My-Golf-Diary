import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/practice_drill_seed.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/swing_diary_prompt.dart';
import 'package:golf_diary_app/services/swing_diary_service.dart';
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

  test('a new database seeds practice drills and can hide or add one',
      () async {
    final seeded = await db.listPracticeDrills();
    expect(seeded.length, kPracticeDrillSeed.length);
    expect(seeded.every((drill) => !drill.isCustom), isTrue);
    expect(seeded.map((drill) => drill.id), contains('rng-drl-tempo-3to1'));
    for (var i = 1; i < seeded.length; i++) {
      final category = seeded[i - 1]
          .category
          .toLowerCase()
          .compareTo(seeded[i].category.toLowerCase());
      expect(category, lessThanOrEqualTo(0));
      if (category == 0) {
        expect(
          seeded[i - 1]
              .title
              .toLowerCase()
              .compareTo(seeded[i].title.toLowerCase()),
          lessThanOrEqualTo(0),
        );
      }
    }

    expect(
      () => db.insertPracticeDrill(
        title: '   ',
        category: 'Custom',
        shortDescription: '',
        steps: const ['Swing'],
      ),
      throwsArgumentError,
    );

    final created = await db.insertPracticeDrill(
      title: ' Gate drill ',
      category: ' Custom ',
      shortDescription: 'A narrow gate',
      steps: const [' Place two tees ', ''],
    );
    expect(created.isCustom, isTrue);
    expect(created.title, 'Gate drill');
    expect(created.category, 'Custom');
    expect(created.steps, ['Place two tees']);

    await db.deletePracticeDrill('rng-drl-tempo-3to1');
    await db.deletePracticeDrill(created.id);
    await LocalDatabaseService.debugClose();

    final reopened = await db.listPracticeDrills();
    expect(reopened.any((drill) => drill.id == 'rng-drl-tempo-3to1'), isFalse);
    expect(reopened.any((drill) => drill.id == created.id), isFalse);
    expect(reopened.length, kPracticeDrillSeed.length - 1);
  });

  test(
      'upgrading a version 4 database seeds drills without reviving a tombstone',
      () async {
    final path = join(await getDatabasesPath(), 'golf_diary_unit.db');
    final raw = await openDatabase(
      path,
      version: 4,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE range_drills (
            id TEXT PRIMARY KEY,
            club_id TEXT NOT NULL,
            shot_count INTEGER NOT NULL,
            min_yards REAL NOT NULL,
            max_yards REAL NOT NULL,
            avg_yards REAL NOT NULL,
            tempo_notes TEXT,
            venue_name TEXT,
            timestamp INTEGER NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    await raw.close();

    final seeded = await db.listPracticeDrills();
    expect(seeded.length, kPracticeDrillSeed.length);
    expect(seeded.every((drill) => !drill.isCustom), isTrue);

    await db.deletePracticeDrill('rng-drl-feet-together');
    await LocalDatabaseService.debugClose();
    final reopened = await db.listPracticeDrills();
    expect(
        reopened.any((drill) => drill.id == 'rng-drl-feet-together'), isFalse);
    expect(reopened.length, kPracticeDrillSeed.length - 1);
  });

  Future<RangeDrillLog> saveBlock({
    required String id,
    required String clubId,
    String tempo = '',
    String? drillId,
    double avg = 150,
  }) {
    return Future(() async {
      final log = RangeDrillLog(
        id: id,
        clubId: clubId,
        shotCount: 10,
        minYards: avg - 5,
        maxYards: avg + 5,
        avgYards: avg,
        tempoNotes: tempo,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        drillId: drillId,
      );
      await db.saveRangeDrill(log);
      return log;
    });
  }

  test('compile links two clubs and leaves a note-only session', () async {
    await saveBlock(id: 'block_driver', clubId: 'driver', tempo: 'Smooth', avg: 220, drillId: 'rng-drl-tempo-3to1');
    await saveBlock(id: 'block_iron', clubId: '7iron', tempo: 'Hold', avg: 150);
    await db.updateClubIdentity((await db.getAllClubs()).firstWhere((club) => club.id == 'driver').copyWith(
          name: 'Driver still',
          category: 'wood',
        ));

    final session = await db.compileRangeSession(sessionNote: 'Felt easy', venueName: 'Topgolf');
    expect(session.blocks.map((block) => block.clubId), ['driver', '7iron']);
    expect(session.blocks.first.clubName, 'Driver still');
    expect(session.blocks.first.drillTitle, '3:1 Tour Tempo Rhythm');
    expect(session.blocks.first.drillSteps, isNotEmpty);
    expect(session.sessionNote, 'Felt easy');

    await db.updateClubIdentity((await db.getAllClubs()).firstWhere((club) => club.id == 'driver').copyWith(
          name: 'Renamed driver',
          category: 'wood',
        ));
    final stored = await db.listRangeSessions();
    expect(stored.single.blocks.first.clubName, 'Driver still');
    expect((await db.listRangeDrills()).every((row) => row.drill.sessionId == session.id), isTrue);

    await expectLater(
      db.compileRangeSession(sessionNote: '', blockIds: ['block_driver', 'block_iron']),
      throwsArgumentError,
    );
    expect((await db.listRangeDrills()).every((row) => row.drill.sessionId == session.id), isTrue);

    final noteOnly = await db.compileRangeSession(sessionNote: 'Just a thought');
    expect(noteOnly.blocks, isEmpty);
    expect((await db.listRangeSessions()).length, 2);
  });

  test('a blank visit is rejected', () async {
    await expectLater(db.compileRangeSession(sessionNote: '   '), throwsArgumentError);
    expect(await db.listRangeSessions(), isEmpty);
  });

  test('upgrading a version 5 database adds session links', () async {
    final path = join(await getDatabasesPath(), 'golf_diary_unit.db');
    final raw = await openDatabase(
      path,
      version: 5,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE clubs (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            min_distance REAL NOT NULL DEFAULT 0,
            max_distance REAL NOT NULL DEFAULT 0,
            avg_distance REAL NOT NULL DEFAULT 0,
            swing_notes TEXT,
            is_synced INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.insert('clubs', {
          'id': 'driver',
          'name': 'Driver',
          'category': 'wood',
          'min_distance': 0,
          'max_distance': 0,
          'avg_distance': 220,
          'swing_notes': '',
          'is_synced': 0,
          'updated_at_ms': 0,
          'deleted': 0,
        });
        await database.execute('''
          CREATE TABLE range_drills (
            id TEXT PRIMARY KEY,
            club_id TEXT NOT NULL,
            shot_count INTEGER NOT NULL,
            min_yards REAL NOT NULL,
            max_yards REAL NOT NULL,
            avg_yards REAL NOT NULL,
            tempo_notes TEXT,
            venue_name TEXT,
            drill_id TEXT,
            timestamp INTEGER NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.insert('range_drills', {
          'id': 'legacy_block',
          'club_id': 'driver',
          'shot_count': 10,
          'min_yards': 200,
          'max_yards': 240,
          'avg_yards': 220,
          'tempo_notes': 'Old cue',
          'venue_name': 'Range',
          'drill_id': null,
          'timestamp': 1700000000000,
          'is_synced': 0,
          'updated_at_ms': 0,
          'deleted': 0,
        });
        await database.execute('''
          CREATE TABLE practice_drills (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            short_description TEXT NOT NULL,
            steps_json TEXT NOT NULL,
            recommended_clubs TEXT,
            is_custom INTEGER NOT NULL DEFAULT 0,
            is_synced INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    await raw.close();

    final session = await db.compileRangeSession(sessionNote: 'After upgrade');
    expect(session.blocks.single.clubName, 'Driver');
    expect(session.blocks.single.tempoNotes, 'Old cue');
    expect((await db.listRangeDrills()).single.drill.sessionId, session.id);
  });

  test('diary history under the ceiling is raw and over it stores one brief', () async {
    final now = DateTime.now();
    await db.saveRangeDrill(RangeDrillLog(
      id: 'ancient',
      clubId: 'driver',
      shotCount: 10,
      minYards: 130,
      maxYards: 150,
      avgYards: 140,
      tempoNotes: 'ANCIENT CUE ${'x' * 2000}',
      timestamp: DateTime(2020, 1, 2).millisecondsSinceEpoch,
      drillId: 'rng-drl-tempo-3to1',
    ));
    await db.saveRangeDrill(RangeDrillLog(
      id: 'today_block',
      clubId: 'driver',
      shotCount: 10,
      minYards: 150,
      maxYards: 170,
      avgYards: 160,
      tempoNotes: 'TODAY CUE',
      timestamp: now.millisecondsSinceEpoch,
      drillId: 'rng-drl-tempo-3to1',
    ));
    final store = SwingDiaryService();
    final under = await store.preparePrompt(tokenCeiling: kDiaryTokenCeiling, now: now);
    expect(under.summary, isNull);
    expect(under.prompt, contains('ANCIENT CUE'));
    expect(under.prompt, contains('TODAY CUE'));
    expect(under.prompt, contains('140'));
    expect(under.prompt, contains('160'));
    expect(under.prompt, contains('3:1 Tour Tempo Rhythm'));
    expect(await store.listEvaluations(), isEmpty);

    final over = await store.preparePrompt(tokenCeiling: 80, now: now);
    expect(over.prompt, isNot(contains('ANCIENT CUE')));
    expect(over.prompt, contains('TODAY CUE'));
    expect(over.prompt, contains('Folded earlier practice'));
    final briefs = (await store.listEvaluations()).where((row) => row.kind == 'periodic_summary');
    expect(briefs, hasLength(1));

    final named = await store.preparePrompt(
      tokenCeiling: 80,
      now: now,
      question: 'What about 2020-01-02?',
    );
    expect(named.prompt, contains('ANCIENT CUE'));
    expect(named.prompt, contains('TODAY CUE'));
    expect(named.prompt, contains('Folded earlier practice'));
  });
}
