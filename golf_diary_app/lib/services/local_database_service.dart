import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/ph_golf_catalog.dart';
import '../data/practice_drill_seed.dart';
import '../models/golf_models.dart';
import '../models/practice_drill.dart';
import '../models/round_summary.dart';
import 'sync_merge.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;
  static String _fileName = 'golf_diary.db';

  LocalDatabaseService._init();

  /// Points the singleton at a throwaway file. Call [close] first if a database is open.
  @visibleForTesting
  static void debugSetFileName(String fileName) {
    _fileName = fileName;
  }

  @visibleForTesting
  static Future<void> debugClose() async {
    final db = _database;
    _database = null;
    await db?.close();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _fileName);

    return openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE clubs ADD COLUMN brand TEXT');
      await db.execute('ALTER TABLE clubs ADD COLUMN model TEXT');
      await db.execute('ALTER TABLE range_drills ADD COLUMN venue_name TEXT');
    }
    if (oldVersion < 3) {
      for (final table in ['clubs', 'shots', 'round_scores', 'range_drills']) {
        await db.execute(
            'ALTER TABLE $table ADD COLUMN updated_at_ms INTEGER NOT NULL DEFAULT 0');
        await db.execute(
            'ALTER TABLE $table ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0');
      }
      await _createSyncState(db);
    }
    if (oldVersion < 4) {
      await _createGolfRoundsTable(db);
      await _backfillGolfRounds(db);
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE range_drills ADD COLUMN drill_id TEXT');
      await _createPracticeDrillsTable(db);
      await _seedPracticeDrills(db);
    }
  }

  Future<void> _createSyncState(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        last_pulled_at_ms INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.insert(
      'sync_state',
      {'id': 1, 'last_pulled_at_ms': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> _dirty(Map<String, Object?> fields) => {
        ...fields,
        'is_synced': 0,
        'updated_at_ms': _nowMs(),
      };

  Map<String, Object?> _newRow(Map<String, Object?> fields) => {
        ...fields,
        'deleted': fields['deleted'] ?? 0,
        'is_synced': 0,
        'updated_at_ms': _nowMs(),
      };

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clubs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        min_distance REAL DEFAULT 0.0,
        max_distance REAL DEFAULT 0.0,
        avg_distance REAL DEFAULT 0.0,
        swing_notes TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
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
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
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
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
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
        venue_name TEXT,
        drill_id TEXT,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _createSyncState(db);
    await _createGolfRoundsTable(db);
    await _createPracticeDrillsTable(db);
    await _seedPracticeDrills(db);

    final starterBag = [
      Club(id: 'driver', name: 'Driver', category: 'wood', avgDistance: 220),
      Club(id: '3wood', name: '3 Wood', category: 'wood', avgDistance: 200),
      Club(id: '5wood', name: '5 Wood', category: 'wood', avgDistance: 185),
      Club(
          id: '3hybrid',
          name: '3 Hybrid',
          category: 'hybrid',
          avgDistance: 175),
      Club(id: '7iron', name: '7 Iron', category: 'iron', avgDistance: 145),
      Club(id: '9iron', name: '9 Iron', category: 'iron', avgDistance: 125),
      Club(
          id: 'pw',
          name: 'Pitching Wedge',
          category: 'wedge',
          avgDistance: 110),
      Club(id: 'putter', name: 'Putter', category: 'putter', avgDistance: 0),
    ];

    for (final club in starterBag) {
      await db
          .insert('clubs', {...club.toMap(), 'updated_at_ms': 0, 'deleted': 0});
    }
  }

  Future<List<Club>> getAllClubs() async {
    final db = await database;
    final result = await db.query('clubs', where: 'deleted = 0');
    return sortClubs(result.map(Club.fromMap));
  }

  Future<List<Club>> getClubsByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'clubs',
      where: 'category = ? AND deleted = 0',
      whereArgs: [category],
    );
    return sortClubs(result.map(Club.fromMap));
  }

  Future<void> insertClub(Club club) async {
    final db = await database;
    await db.insert('clubs', _newRow(club.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates the club's name, brand, model, and category. Distances and swing notes stay put.
  Future<void> updateClubIdentity(Club club) async {
    final db = await database;
    await db.update(
      'clubs',
      _dirty({
        'name': club.name,
        'category': club.category,
        'brand': club.brand,
        'model': club.model,
      }),
      where: 'id = ?',
      whereArgs: [club.id],
    );
  }

  Future<void> deleteClub(String clubId) async {
    final db = await database;
    await db.update('clubs', _dirty({'deleted': 1}),
        where: 'id = ?', whereArgs: [clubId]);
  }

  Future<void> updateClubSwingNotes(String clubId, String notes) async {
    final db = await database;
    await db.update(
      'clubs',
      _dirty({'swing_notes': notes}),
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  Future<void> saveRangeDrill(RangeDrillLog log) async {
    final db = await database;
    await db.insert('range_drills', _newRow(log.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);

    final clubData =
        await db.query('clubs', where: 'id = ?', whereArgs: [log.clubId]);
    if (clubData.isNotEmpty) {
      final club = Club.fromMap(clubData.first);
      final newMin = club.minDistance == 0
          ? log.minYards
          : (club.minDistance < log.minYards ? club.minDistance : log.minYards);
      final newMax =
          club.maxDistance > log.maxYards ? club.maxDistance : log.maxYards;
      final newAvg = club.avgDistance == 0
          ? log.avgYards
          : ((club.avgDistance + log.avgYards) / 2);

      await db.update(
        'clubs',
        _dirty({
          'min_distance': newMin,
          'max_distance': newMax,
          'avg_distance': newAvg,
          'swing_notes':
              log.tempoNotes.isNotEmpty ? log.tempoNotes : club.swingNotes,
        }),
        where: 'id = ?',
        whereArgs: [log.clubId],
      );
    }
  }

  /// Newest session first. [clubId] limits the log to one club.
  Future<List<RangeDrillSummary>> listRangeDrills({String? clubId}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT range_drills.*, clubs.name AS club_name
      FROM range_drills
      LEFT JOIN clubs ON clubs.id = range_drills.club_id
      WHERE range_drills.deleted = 0
      ${clubId == null ? '' : 'AND range_drills.club_id = ?'}
      ORDER BY range_drills.timestamp DESC
    ''', clubId == null ? null : [clubId]);
    return rows.map((row) {
      final name = row['club_name'] as String?;
      return RangeDrillSummary(
        drill: RangeDrillLog.fromMap(row),
        clubName: (name == null || name.isEmpty) ? 'Removed club' : name,
      );
    }).toList();
  }

  /// Average yards for [clubId], oldest session first.
  Future<List<double>> getClubYardageTrend(String clubId) async {
    final db = await database;
    final rows = await db.query(
      'range_drills',
      columns: ['avg_yards'],
      where: 'club_id = ? AND deleted = 0',
      whereArgs: [clubId],
      orderBy: 'timestamp ASC',
    );
    return rows.map((row) => (row['avg_yards'] as num).toDouble()).toList();
  }

  Future<List<PracticeDrill>> listPracticeDrills() async {
    final db = await database;
    final rows = await db.query(
      'practice_drills',
      where: 'deleted = 0',
      orderBy: 'category COLLATE NOCASE, title COLLATE NOCASE',
    );
    return rows.map(PracticeDrill.fromMap).toList();
  }

  /// Inserts a custom drill. An empty title is rejected.
  Future<PracticeDrill> insertPracticeDrill({
    required String title,
    required String category,
    required String shortDescription,
    required List<String> steps,
    String recommendedClubs = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'A drill title is required');
    }
    final id = 'drill_${_nowMs()}';
    final row = _newRow({
      'id': id,
      'title': trimmedTitle,
      'category': category.trim().isEmpty ? 'Custom' : category.trim(),
      'short_description': shortDescription.trim(),
      'steps_json': jsonEncode([for (final step in steps) step.trim()]
          .where((step) => step.isNotEmpty)
          .toList()),
      'recommended_clubs': recommendedClubs.trim(),
      'is_custom': 1,
    });
    final db = await database;
    await db.insert('practice_drills', row);
    return PracticeDrill.fromMap(row);
  }

  /// Hides a seeded or custom drill. A later seed does not revive it.
  Future<void> deletePracticeDrill(String id) async {
    final db = await database;
    await db.update(
      'practice_drills',
      _dirty({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getActiveRoundId() async {
    final db = await database;
    final rows = await db.query(
      'golf_rounds',
      columns: ['round_id'],
      where: 'deleted = 0 AND completed_at_ms IS NULL',
      orderBy: 'started_at_ms DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return rows.first['round_id'] as String;
    }
    return null;
  }

  /// True when the round has GPS shots or any hole marked as played on the card.
  Future<bool> roundHasMeaningfulPlay(String roundId) async {
    final db = await database;
    final shotCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM shots WHERE round_id = ? AND deleted = 0',
        [roundId],
      ),
    );
    if ((shotCount ?? 0) > 0) return true;
    final holes = await getScoresForRound(roundId);
    return holes.any(isHolePlayed);
  }

  /// Finalizes open holes and marks the round saved for scorecard history.
  Future<void> completeRound(String roundId) async {
    final holes = await getScoresForRound(roundId);
    for (final hole in holes) {
      if (!isHolePlayed(hole) || hole.finalScore > 0) continue;
      final score =
          computeFinalScore(strokes: hole.strokes, penalties: hole.penalties);
      await upsertHoleScore(hole.copyWith(finalScore: score, isSynced: 0));
    }
    final db = await database;
    final now = _nowMs();
    final meta = await db.query(
      'golf_rounds',
      where: 'round_id = ?',
      whereArgs: [roundId],
      limit: 1,
    );
    if (meta.isEmpty) {
      final courseName = holes.isNotEmpty
          ? holes.first.courseName
          : await getCourseNameForRound(roundId);
      await _registerGolfRound(
        db,
        roundId: roundId,
        courseName: courseName,
        startedAtMs: _roundIdToMs(roundId) > 0 ? _roundIdToMs(roundId) : now,
      );
    }
    await db.update(
      'golf_rounds',
      _dirty({'completed_at_ms': now}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  /// Removes an in-progress round the golfer chose not to keep.
  Future<void> discardRound(String roundId) async {
    final db = await database;
    final now = _nowMs();
    await db.update(
      'golf_rounds',
      _dirty({'deleted': 1}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
    await db.update(
      'round_scores',
      _dirty({'deleted': 1}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
    await db.update(
      'shots',
      _dirty({'deleted': 1}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  Future<bool> isRoundCompleted(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'golf_rounds',
      columns: ['completed_at_ms'],
      where: 'round_id = ? AND deleted = 0',
      whereArgs: [roundId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['completed_at_ms'] != null;
  }

  Future<List<RoundScore>> getScoresForRound(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      where: 'round_id = ? AND deleted = 0',
      whereArgs: [roundId],
      orderBy: 'hole_number ASC',
    );
    return rows.map(RoundScore.fromMap).toList();
  }

  Future<List<RoundSummary>> listRecentRounds({int limit = 10}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT g.round_id, g.course_name, g.started_at_ms, g.completed_at_ms,
             COUNT(rs.id) as holes_recorded
      FROM golf_rounds g
      LEFT JOIN round_scores rs ON rs.round_id = g.round_id AND rs.deleted = 0
      WHERE g.deleted = 0
      GROUP BY g.round_id
      ORDER BY g.started_at_ms DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((row) {
      final roundId = row['round_id'] as String;
      return RoundSummary(
        roundId: roundId,
        courseName: row['course_name'] as String,
        holesRecorded: row['holes_recorded'] as int,
        startedAtMs: row['started_at_ms'] as int,
        completedAtMs: row['completed_at_ms'] as int?,
      );
    }).toList();
  }

  int _roundIdToMs(String roundId) {
    final suffix =
        roundId.startsWith('round_') ? roundId.substring(6) : roundId;
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
    return startNewRound(courseName: courseName);
  }

  /// Always inserts a new round, even when another round is still in progress.
  /// [par] is hole 1. Callers pass a catalog card par when the course is known.
  Future<String> startNewRound(
      {required String courseName, int par = 4}) async {
    final startedAtMs = DateTime.now().millisecondsSinceEpoch;
    final roundId = 'round_$startedAtMs';
    final db = await database;
    await db.insert(
      'round_scores',
      _newRow(RoundScore(
        id: '${roundId}_h1',
        roundId: roundId,
        courseName: courseName,
        holeNumber: 1,
        par: par,
      ).toMap()),
    );
    await _registerGolfRound(
      db,
      roundId: roundId,
      courseName: courseName,
      startedAtMs: startedAtMs,
    );
    return roundId;
  }

  Future<void> updateCourseName(String roundId, String courseName) async {
    await _renameRound(roundId, courseName);
  }

  /// Renames the round, then sets par on holes that have not been played.
  /// A published card supplies each hole. Any other name returns unplayed holes to par 4.
  /// Played holes keep the par already stored.
  Future<void> applyCoursePar(String roundId, String courseName) async {
    await updateCourseName(roundId, courseName);
    final holes = await getScoresForRound(roundId);
    final db = await database;
    for (final hole in holes) {
      if (isHolePlayed(hole)) continue;
      final par = PhGolfCatalog.parForHole(courseName, hole.holeNumber) ?? 4;
      if (hole.par == par) continue;
      await db.update(
        'round_scores',
        _dirty({'par': par}),
        where: 'id = ?',
        whereArgs: [hole.id],
      );
    }
  }

  Future<List<String>> distinctCourseNames({int limit = 8}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT course_name
      FROM golf_rounds
      WHERE deleted = 0 AND TRIM(course_name) != ''
      GROUP BY course_name
      ORDER BY MAX(started_at_ms) DESC
      LIMIT ?
    ''', [limit]);
    return [for (final row in rows) row['course_name'] as String];
  }

  Future<List<String>> distinctVenueNames({int limit = 8}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT venue_name
      FROM range_drills
      WHERE deleted = 0 AND venue_name IS NOT NULL AND TRIM(venue_name) != ''
      GROUP BY venue_name
      ORDER BY MAX(timestamp) DESC
      LIMIT ?
    ''', [limit]);
    return [for (final row in rows) row['venue_name'] as String];
  }

  Future<RoundScore?> getHoleScore(String roundId, int holeNumber) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      where: 'round_id = ? AND hole_number = ? AND deleted = 0',
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
      _newRow(score.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRoundCourseName(String roundId, String courseName) async {
    final name = courseName.trim().isEmpty ? 'Local Course' : courseName.trim();
    await _renameRound(roundId, name);
  }

  Future<void> _renameRound(String roundId, String courseName) async {
    final db = await database;
    await db.update(
      'round_scores',
      _dirty({'course_name': courseName}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
    await db.update(
      'golf_rounds',
      _dirty({'course_name': courseName}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  Future<String> getCourseNameForRound(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'round_scores',
      columns: ['course_name'],
      where: 'round_id = ? AND deleted = 0',
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

  /// Highest hole row on the round. Finish Hole creates that row, so On Course resumes there.
  Future<int> currentHoleNumber(String roundId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT MAX(hole_number) AS hole FROM round_scores WHERE round_id = ?',
      [roundId],
    );
    return (rows.first['hole'] as int?) ?? 1;
  }

  Future<void> updateShotDetails({
    required String shotId,
    required String clubId,
    required String lieType,
  }) async {
    final db = await database;
    await db.update(
      'shots',
      {'club_id': clubId, 'lie_type': lieType, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [shotId],
    );
  }

  /// Removes a shot and renumbers the strokes left on that hole.
  Future<void> deleteShot(ShotRecord shot) async {
    final db = await database;
    await db.delete('shots', where: 'id = ?', whereArgs: [shot.id]);
    final remaining = await getShotsForHole(shot.roundId, shot.holeNumber);
    for (var i = 0; i < remaining.length; i++) {
      final stroke = i + 1;
      if (remaining[i].strokeNumber == stroke) continue;
      await db.update(
        'shots',
        {'stroke_number': stroke, 'is_synced': 0},
        where: 'id = ?',
        whereArgs: [remaining[i].id],
      );
    }
    await syncStrokeCountFromShots(shot.roundId, shot.holeNumber);
  }

  Future<List<ShotRecord>> getShotsForHole(
      String roundId, int holeNumber) async {
    final db = await database;
    final rows = await db.query(
      'shots',
      where: 'round_id = ? AND hole_number = ? AND deleted = 0',
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
      finalScore:
          computeFinalScore(strokes: strokes, penalties: hole.penalties),
      isSynced: 0,
    );
    await upsertHoleScore(updated);
  }

  Future<void> incrementPenalties(
      String roundId, int holeNumber, int delta) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    final penalties = (hole.penalties + delta).clamp(0, 99);
    final updated = hole.copyWith(
      penalties: penalties,
      finalScore:
          computeFinalScore(strokes: hole.strokes, penalties: penalties),
      isSynced: 0,
    );
    await upsertHoleScore(updated);
  }

  Future<void> incrementMulligans(String roundId, int holeNumber) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    await upsertHoleScore(
        hole.copyWith(mulligans: hole.mulligans + 1, isSynced: 0));
  }

  Future<void> concedeHole(String roundId, int holeNumber) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    final maxConceded = hole.par * 2;
    final updated = hole.copyWith(
      conceded: 1,
      strokes: maxConceded,
      finalScore:
          computeFinalScore(strokes: maxConceded, penalties: hole.penalties),
      isSynced: 0,
    );
    await upsertHoleScore(updated);
  }

  Future<void> finishHole({
    required String roundId,
    required int holeNumber,
    required int nextPar,
    int holeCount = 18,
  }) async {
    await syncStrokeCountFromShots(roundId, holeNumber);
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole != null && hole.conceded == 0) {
      final score =
          computeFinalScore(strokes: hole.strokes, penalties: hole.penalties);
      await upsertHoleScore(hole.copyWith(finalScore: score, isSynced: 0));
    }
    if (holeNumber >= holeCount) {
      await completeRound(roundId);
      return;
    }

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
      where: 'round_id = ? AND final_score > 0 AND deleted = 0',
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
        total += computeFinalScore(
            strokes: current.strokes, penalties: current.penalties);
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
    double? distanceYards,
  }) async {
    final db = await database;
    final simulator = distanceYards != null;

    final prevShotMaps = await db.query(
      'shots',
      where: 'round_id = ? AND hole_number = ? AND deleted = 0',
      whereArgs: [roundId, holeNumber],
      orderBy: 'stroke_number DESC',
      limit: 1,
    );

    var strokeNumber = 1;

    if (prevShotMaps.isNotEmpty) {
      final prevShot = ShotRecord.fromMap(prevShotMaps.first);
      strokeNumber = prevShot.strokeNumber + 1;

      if (!simulator) {
        final distanceMeters = Geolocator.distanceBetween(
          prevShot.startLat,
          prevShot.startLon,
          currentLat,
          currentLon,
        );
        final traveledYards = distanceMeters * 1.09361;

        await db.update(
          'shots',
          _dirty({
            'end_lat': currentLat,
            'end_lon': currentLon,
            'distance_yards': traveledYards.roundToDouble(),
          }),
          where: 'id = ?',
          whereArgs: [prevShot.id],
        );
      }
    }

    final newShot = ShotRecord(
      id: 'shot_${DateTime.now().millisecondsSinceEpoch}',
      roundId: roundId,
      holeNumber: holeNumber,
      strokeNumber: strokeNumber,
      clubId: clubId,
      lieType: lieType,
      startLat: simulator ? 0 : currentLat,
      startLon: simulator ? 0 : currentLon,
      distanceYards: simulator ? distanceYards.roundToDouble() : 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert('shots', _newRow(newShot.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await syncStrokeCountFromShots(roundId, holeNumber);
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  /// Gives legacy dirty rows a timestamp before they are uploaded.
  Future<List<Map<String, dynamic>>> prepareUnsyncedForPush(
      String table) async {
    final db = await database;
    final rows = await getUnsynced(table);
    final prepared = <Map<String, dynamic>>[];
    for (final row in rows) {
      final updated = (row['updated_at_ms'] as int?) ?? 0;
      if (updated == 0) {
        final now = _nowMs();
        await db.update(
          table,
          {'updated_at_ms': now},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        prepared.add({...row, 'updated_at_ms': now});
      } else {
        prepared.add(row);
      }
    }
    return prepared;
  }

  Future<void> markSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> finishPush(
      String table, String id, Map<String, dynamic> row) async {
    if (readDeleted(row)) {
      final db = await database;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);
      return;
    }
    await markSynced(table, id);
  }

  Future<int> getLastPulledAt() async {
    final db = await database;
    final rows = await db.query('sync_state', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return 0;
    return rows.first['last_pulled_at_ms'] as int? ?? 0;
  }

  Future<void> setLastPulledAt(int millis) async {
    final db = await database;
    await db.insert(
      'sync_state',
      {'id': 1, 'last_pulled_at_ms': millis},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Applies one Firestore document when it is newer than the local row.
  /// Returns true when the local database changes.
  Future<bool> applyRemoteRow(String table, Map<String, dynamic> remote) async {
    final id = remote['id'] as String?;
    if (id == null || id.isEmpty) return false;
    final db = await database;
    final localRows =
        await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    final remoteUpdated = readUpdatedAtMs(remote);
    final action = decideMerge(
      localExists: localRows.isNotEmpty,
      localUpdatedAtMs: localRows.isEmpty
          ? 0
          : (localRows.first['updated_at_ms'] as int? ?? 0),
      remoteUpdatedAtMs: remoteUpdated,
    );
    if (action == MergeAction.keepLocal) return false;

    if (readDeleted(remote)) {
      if (localRows.isEmpty) return false;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);
      return true;
    }

    final row = _sqliteRow(table, remote, remoteUpdated);
    if (table == 'range_drills' &&
        localRows.isNotEmpty &&
        !remote.containsKey('drill_id')) {
      row['drill_id'] = localRows.first['drill_id'];
    }
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    if (table == 'round_scores') {
      final roundId = row['round_id'] as String?;
      if (roundId != null) {
        await _ensureGolfRoundFromScores(db, roundId);
      }
    }
    return true;
  }

  Map<String, Object?> _sqliteRow(
      String table, Map<String, dynamic> remote, int updatedAt) {
    final allowed = _columns[table]!;
    final row = <String, Object?>{};
    for (final column in allowed) {
      if (column == 'updated_at_ms' ||
          column == 'deleted' ||
          column == 'is_synced') {
        continue;
      }
      if (remote.containsKey(column)) row[column] = remote[column];
    }
    row['updated_at_ms'] = updatedAt;
    row['deleted'] = 0;
    row['is_synced'] = 1;
    return row;
  }

  Future<void> _createPracticeDrillsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS practice_drills (
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
  }

  Future<void> _seedPracticeDrills(Database db) async {
    for (final drill in kPracticeDrillSeed) {
      await db.insert(
        'practice_drills',
        {
          'id': drill.id,
          'title': drill.title,
          'category': drill.category,
          'short_description': drill.shortDescription,
          'steps_json': jsonEncode(drill.steps),
          'recommended_clubs': drill.recommendedClubs,
          'is_custom': 0,
          'is_synced': 0,
          'updated_at_ms': 0,
          'deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _createGolfRoundsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS golf_rounds (
        round_id TEXT PRIMARY KEY,
        course_name TEXT NOT NULL,
        started_at_ms INTEGER NOT NULL,
        completed_at_ms INTEGER,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _backfillGolfRounds(Database db) async {
    final rows = await db.rawQuery('''
      SELECT round_id, course_name, COUNT(*) as hole_count
      FROM round_scores
      WHERE deleted = 0
      GROUP BY round_id
    ''');
    for (final row in rows) {
      final roundId = row['round_id'] as String;
      final courseName = row['course_name'] as String;
      final startedAtMs = _roundIdToMs(roundId);
      final hole18 = await db.query(
        'round_scores',
        where: 'round_id = ? AND hole_number = 18 AND deleted = 0',
        whereArgs: [roundId],
        limit: 1,
      );
      final completed =
          hole18.isNotEmpty && (hole18.first['final_score'] as int? ?? 0) > 0;
      await db.insert(
        'golf_rounds',
        {
          'round_id': roundId,
          'course_name': courseName,
          'started_at_ms': startedAtMs > 0 ? startedAtMs : _nowMs(),
          'completed_at_ms': completed ? startedAtMs : null,
          'is_synced': 0,
          'updated_at_ms': _nowMs(),
          'deleted': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _registerGolfRound(
    Database db, {
    required String roundId,
    required String courseName,
    required int startedAtMs,
  }) async {
    await db.insert(
      'golf_rounds',
      _newRow({
        'round_id': roundId,
        'course_name': courseName,
        'started_at_ms': startedAtMs,
        'completed_at_ms': null,
      }),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _ensureGolfRoundFromScores(Database db, String roundId) async {
    final existing = await db.query(
      'golf_rounds',
      where: 'round_id = ?',
      whereArgs: [roundId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    final rows = await db.query(
      'round_scores',
      columns: ['course_name'],
      where: 'round_id = ? AND deleted = 0',
      whereArgs: [roundId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final courseName = rows.first['course_name'] as String;
    final startedAtMs = _roundIdToMs(roundId);
    await _registerGolfRound(
      db,
      roundId: roundId,
      courseName: courseName,
      startedAtMs: startedAtMs > 0 ? startedAtMs : _nowMs(),
    );
  }

  static const _columns = {
    'clubs': [
      'id',
      'name',
      'category',
      'brand',
      'model',
      'min_distance',
      'max_distance',
      'avg_distance',
      'swing_notes',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'shots': [
      'id',
      'round_id',
      'hole_number',
      'stroke_number',
      'club_id',
      'lie_type',
      'start_lat',
      'start_lon',
      'end_lat',
      'end_lon',
      'distance_yards',
      'notes',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'round_scores': [
      'id',
      'round_id',
      'course_name',
      'hole_number',
      'par',
      'strokes',
      'penalties',
      'mulligans',
      'conceded',
      'final_score',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'range_drills': [
      'id',
      'club_id',
      'shot_count',
      'min_yards',
      'max_yards',
      'avg_yards',
      'tempo_notes',
      'venue_name',
      'drill_id',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
  };
}
