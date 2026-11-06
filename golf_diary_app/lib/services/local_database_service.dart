import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/golf_models.dart';
import '../models/round_summary.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('golf_diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clubs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        min_distance REAL DEFAULT 0.0,
        max_distance REAL DEFAULT 0.0,
        avg_distance REAL DEFAULT 0.0,
        swing_notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shots (
        id TEXT PRIMARY KEY,
        round_id TEXT NOT NULL,
        hole_number INTEGER NOT NULL,
        stroke_number INTEGER NOT NULL,
        club_id TEXT NOT NULL,
        lie_type TEXT NOT NULL,
        start_lat REAL NOT NULL,
        start_lon REAL NOT NULL,
        end_lat REAL,
        end_lon REAL,
        distance_yards REAL DEFAULT 0.0,
        notes TEXT,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE round_scores (
        id TEXT PRIMARY KEY,
        round_id TEXT NOT NULL,
        course_name TEXT NOT NULL,
        hole_number INTEGER NOT NULL,
        par INTEGER NOT NULL,
        strokes INTEGER NOT NULL DEFAULT 0,
        penalties INTEGER NOT NULL DEFAULT 0,
        mulligans INTEGER NOT NULL DEFAULT 0,
        conceded INTEGER NOT NULL DEFAULT 0,
        final_score INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE range_drills (
        id TEXT PRIMARY KEY,
        club_id TEXT NOT NULL,
        shot_count INTEGER NOT NULL,
        min_yards REAL NOT NULL,
        max_yards REAL NOT NULL,
        avg_yards REAL NOT NULL,
        tempo_notes TEXT,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    final starterBag = [
      Club(id: 'driver', name: 'Driver', category: 'wood', avgDistance: 220),
      Club(id: '3wood', name: '3 Wood', category: 'wood', avgDistance: 200),
      Club(id: '5wood', name: '5 Wood', category: 'wood', avgDistance: 185),
      Club(id: '3hybrid', name: '3 Hybrid', category: 'hybrid', avgDistance: 175),
      Club(id: '7iron', name: '7 Iron', category: 'iron', avgDistance: 145),
      Club(id: '9iron', name: '9 Iron', category: 'iron', avgDistance: 125),
      Club(id: 'pw', name: 'Pitching Wedge', category: 'wedge', avgDistance: 110),
      Club(id: 'putter', name: 'Putter', category: 'putter', avgDistance: 0),
    ];

    for (final club in starterBag) {
      await db.insert('clubs', club.toMap());
    }
  }

  Future<List<Club>> getAllClubs() async {
    final db = await database;
    final result = await db.query('clubs', orderBy: 'avg_distance DESC');
    return result.map(Club.fromMap).toList();
  }

  Future<List<Club>> getClubsByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'clubs',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'avg_distance DESC',
    );
    return result.map(Club.fromMap).toList();
  }

  Future<void> updateClubSwingNotes(String clubId, String notes) async {
    final db = await database;
    await db.update(
      'clubs',
      {'swing_notes': notes, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  Future<void> saveRangeDrill(RangeDrillLog log) async {
    final db = await database;
    await db.insert('range_drills', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    final clubData = await db.query('clubs', where: 'id = ?', whereArgs: [log.clubId]);
    if (clubData.isNotEmpty) {
      final club = Club.fromMap(clubData.first);
      final newMin = club.minDistance == 0
          ? log.minYards
          : (club.minDistance < log.minYards ? club.minDistance : log.minYards);
      final newMax = club.maxDistance > log.maxYards ? club.maxDistance : log.maxYards;
      final newAvg = club.avgDistance == 0 ? log.avgYards : ((club.avgDistance + log.avgYards) / 2);

      await db.update(
        'clubs',
        {
          'min_distance': newMin,
          'max_distance': newMax,
          'avg_distance': newAvg,
          'swing_notes': log.tempoNotes.isNotEmpty ? log.tempoNotes : club.swingNotes,
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [log.clubId],
      );
    }
  }

  Future<String?> getActiveRoundId() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT round_id, MAX(hole_number) as max_hole
      FROM round_scores
      GROUP BY round_id
      ORDER BY round_id DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    final roundId = rows.first['round_id'] as String;
    final hole18 = await getHoleScore(roundId, 18);
    if (hole18 != null && hole18.finalScore > 0) {
      return null;
    }
    return roundId;
  }

  Future<List<RoundScore>> getScoresForRound(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      where: 'round_id = ?',
      whereArgs: [roundId],
      orderBy: 'hole_number ASC',
    );
    return rows.map(RoundScore.fromMap).toList();
  }

  Future<List<RoundSummary>> listRecentRounds({int limit = 10}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT round_id, course_name, COUNT(*) as holes_recorded
      FROM round_scores
      GROUP BY round_id
      ORDER BY round_id DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((row) {
      final roundId = row['round_id'] as String;
      final ms = _roundIdToMs(roundId);
      return RoundSummary(
        roundId: roundId,
        courseName: row['course_name'] as String,
        holesRecorded: row['holes_recorded'] as int,
        startedAtMs: ms,
      );
    }).toList();
  }

  int _roundIdToMs(String roundId) {
    final suffix = roundId.startsWith('round_') ? roundId.substring(6) : roundId;
    return int.tryParse(suffix) ?? 0;
  }

  Future<RoundTotals?> computeRoundTotals(String roundId) async {
    final holes = await getScoresForRound(roundId);
    if (holes.isEmpty) return null;

    var frontScore = 0;
    var backScore = 0;
    var frontPar = 0;
    var backPar = 0;
    var penalties = 0;
    var mulligans = 0;

    for (final hole in holes) {
      if (!isHolePlayed(hole)) continue;
      final score = effectiveHoleScore(hole);
      penalties += hole.penalties;
      mulligans += hole.mulligans;
      if (hole.holeNumber <= 9) {
        frontScore += score;
        frontPar += hole.par;
      } else {
        backScore += score;
        backPar += hole.par;
      }
    }

    return RoundTotals(
      roundId: roundId,
      courseName: holes.first.courseName,
      frontNineScore: frontScore,
      backNineScore: backScore,
      totalScore: frontScore + backScore,
      frontNinePar: frontPar,
      backNinePar: backPar,
      totalPar: frontPar + backPar,
      penaltiesTotal: penalties,
      mulligansTotal: mulligans,
    );
  }

  Future<String> ensureActiveRound({required String courseName}) async {
    final active = await getActiveRoundId();
    if (active != null) return active;

    final roundId = 'round_${DateTime.now().millisecondsSinceEpoch}';
    final db = await database;
    await db.insert(
      'round_scores',
      RoundScore(
        id: '${roundId}_h1',
        roundId: roundId,
        courseName: courseName,
        holeNumber: 1,
        par: 4,
      ).toMap(),
    );
    return roundId;
  }

  Future<RoundScore?> getHoleScore(String roundId, int holeNumber) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      where: 'round_id = ? AND hole_number = ?',
      whereArgs: [roundId, holeNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RoundScore.fromMap(rows.first);
  }

  Future<void> upsertHoleScore(RoundScore score) async {
    final db = await database;
    await db.insert(
      'round_scores',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRoundCourseName(String roundId, String courseName) async {
    final db = await database;
    final name = courseName.trim().isEmpty ? 'Local Course' : courseName.trim();
    await db.update(
      'round_scores',
      {'course_name': name, 'is_synced': 0},
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  Future<String> getCourseNameForRound(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      columns: ['course_name'],
      where: 'round_id = ?',
      whereArgs: [roundId],
      limit: 1,
    );
    if (rows.isEmpty) return 'Local Course';
    return rows.first['course_name'] as String;
  }

  /// Persists par/strokes/penalties from the scorecard editor (no GPS shots required).
  Future<void> saveManualHoleScore({
    required String roundId,
    required String courseName,
    required int holeNumber,
    required int par,
    required int strokes,
    required int penalties,
    required bool holeComplete,
    bool conceded = false,
    int mulligans = 0,
  }) async {
    final existing = await getHoleScore(roundId, holeNumber);
    final strokeCount = conceded ? par * 2 : strokes.clamp(0, 99);
    final penCount = penalties.clamp(0, 99);
    final gross = computeFinalScore(strokes: strokeCount, penalties: penCount);
    final finalScore = holeComplete || conceded ? gross : 0;

    final score = RoundScore(
      id: existing?.id ?? '${roundId}_h$holeNumber',
      roundId: roundId,
      courseName: existing?.courseName ?? courseName,
      holeNumber: holeNumber,
      par: par,
      strokes: strokeCount,
      penalties: penCount,
      mulligans: mulligans,
      conceded: conceded ? 1 : 0,
      finalScore: finalScore,
      isSynced: 0,
    );
    await upsertHoleScore(score);
  }

  Future<List<ShotRecord>> getShotsForHole(String roundId, int holeNumber) async {
    final db = await database;
    final rows = await db.query(
      'shots',
      where: 'round_id = ? AND hole_number = ?',
      whereArgs: [roundId, holeNumber],
      orderBy: 'stroke_number ASC',
    );
    return rows.map(ShotRecord.fromMap).toList();
  }

  Future<void> syncStrokeCountFromShots(String roundId, int holeNumber) async {
    final shots = await getShotsForHole(roundId, holeNumber);
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;

    final strokes = shots.length;
    final updated = hole.copyWith(
      strokes: strokes,
      finalScore: computeFinalScore(strokes: strokes, penalties: hole.penalties),
      isSynced: 0,
    );
    await upsertHoleScore(updated);
  }

  Future<void> incrementPenalties(String roundId, int holeNumber, int delta) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    final penalties = (hole.penalties + delta).clamp(0, 99);
    final updated = hole.copyWith(
      penalties: penalties,
      finalScore: computeFinalScore(strokes: hole.strokes, penalties: penalties),
      isSynced: 0,
    );
    await upsertHoleScore(updated);
  }

  Future<void> incrementMulligans(String roundId, int holeNumber) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    await upsertHoleScore(hole.copyWith(mulligans: hole.mulligans + 1, isSynced: 0));
  }

  Future<void> concedeHole(String roundId, int holeNumber) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    final maxConceded = hole.par * 2;
    final updated = hole.copyWith(
      conceded: 1,
      strokes: maxConceded,
      finalScore: computeFinalScore(strokes: maxConceded, penalties: hole.penalties),
      isSynced: 0,
    );
    await upsertHoleScore(updated);
  }

  Future<void> finishHole({
    required String roundId,
    required int holeNumber,
    required int nextPar,
  }) async {
    await syncStrokeCountFromShots(roundId, holeNumber);
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole != null && hole.conceded == 0) {
      final score = computeFinalScore(strokes: hole.strokes, penalties: hole.penalties);
      await upsertHoleScore(hole.copyWith(finalScore: score, isSynced: 0));
    }
    if (holeNumber >= 18) return;

    if (hole == null) return;

    final nextHole = RoundScore(
      id: '${roundId}_h${holeNumber + 1}',
      roundId: roundId,
      courseName: hole.courseName,
      holeNumber: holeNumber + 1,
      par: nextPar,
    );
    await upsertHoleScore(nextHole);
  }

  Future<int> getRoundTotal(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      where: 'round_id = ? AND final_score > 0',
      whereArgs: [roundId],
    );
    var total = 0;
    for (final row in rows) {
      total += row['final_score'] as int? ?? 0;
    }
    final active = await db.query(
      'round_scores',
      where: 'round_id = ?',
      whereArgs: [roundId],
      orderBy: 'hole_number DESC',
      limit: 1,
    );
    if (active.isNotEmpty) {
      final current = RoundScore.fromMap(active.first);
      if (current.finalScore == 0 && current.strokes > 0) {
        total += computeFinalScore(strokes: current.strokes, penalties: current.penalties);
      }
    }
    return total;
  }

  Future<void> recordFairwayHit({
    required String roundId,
    required int holeNumber,
    required String clubId,
    required String lieType,
    required double currentLat,
    required double currentLon,
  }) async {
    final db = await database;

    final prevShotMaps = await db.query(
      'shots',
      where: 'round_id = ? AND hole_number = ?',
      whereArgs: [roundId, holeNumber],
      orderBy: 'stroke_number DESC',
      limit: 1,
    );

    var strokeNumber = 1;

    if (prevShotMaps.isNotEmpty) {
      final prevShot = ShotRecord.fromMap(prevShotMaps.first);
      strokeNumber = prevShot.strokeNumber + 1;

      final distanceMeters = Geolocator.distanceBetween(
        prevShot.startLat,
        prevShot.startLon,
        currentLat,
        currentLon,
      );
      final distanceYards = distanceMeters * 1.09361;

      await db.update(
        'shots',
        {
          'end_lat': currentLat,
          'end_lon': currentLon,
          'distance_yards': distanceYards.roundToDouble(),
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [prevShot.id],
      );
    }

    final newShot = ShotRecord(
      id: 'shot_${DateTime.now().millisecondsSinceEpoch}',
      roundId: roundId,
      holeNumber: holeNumber,
      strokeNumber: strokeNumber,
      clubId: clubId,
      lieType: lieType,
      startLat: currentLat,
      startLon: currentLon,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert('shots', newShot.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await syncStrokeCountFromShots(roundId, holeNumber);
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
