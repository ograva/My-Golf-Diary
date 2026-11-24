import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/ph_golf_catalog.dart';
import '../data/practice_drill_seed.dart';
import '../models/caddy_session.dart';
import '../models/golf_models.dart';
import '../models/golfer_profile.dart';
import '../models/practice_drill.dart';
import '../models/range_session.dart';
import '../models/round_summary.dart';
import '../models/scoring_format.dart';
import 'sync_constants.dart';
import 'sync_merge.dart';

const kEmptyRangeSessionMessage =
    'Log a club block or write a session note before saving the session.';

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
      version: 18,
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
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE range_drills ADD COLUMN session_id TEXT');
      await _createRangeSessionsTable(db);
    }
    if (oldVersion < 7) {
      await _createDiaryTables(db);
    }
    if (oldVersion < 8) {
      await _createGolferProfileTableLegacy(db);
    }
    if (oldVersion < 9) {
      await _upgradeGolferProfileOnboarding(db);
    }
    if (oldVersion < 10) {
      await _upgradeGolferProfileYardageDisplay(db);
    }
    if (oldVersion < 11) {
      await _createDiaryContextNotesTable(db);
    }
    if (oldVersion < 12) {
      await _createPracticeDrillsTable(db);
      await _seedPracticeDrills(db);
    }
    if (oldVersion < 13) {
      await _upgradeGolferProfileScorecardView(db);
    }
    if (oldVersion < 14) {
      await _createCaddyTables(db);
    }
    if (oldVersion < 15) {
      await _addColumnIfMissing(
        db,
        'shots',
        'aim_direction',
        "TEXT NOT NULL DEFAULT 'center'",
      );
      await _addColumnIfMissing(db, 'shots', 'sim_carry_yards', 'REAL');
      await _addColumnIfMissing(
          db, 'shots', 'sim_distance_to_hole_yards', 'REAL');
    }
    if (oldVersion < 16) {
      await _addColumnIfMissing(
        db,
        'golfer_profile',
        'avatar_choice',
        "TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 17) {
      await _addColumnIfMissing(
        db,
        'golf_rounds',
        'scoring_format',
        "TEXT NOT NULL DEFAULT 'gross'",
      );
      await _addColumnIfMissing(
        db,
        'golf_rounds',
        'molave_double_eagle_pts',
        'INTEGER NOT NULL DEFAULT 7',
      );
      await _addColumnIfMissing(
        db,
        'golf_rounds',
        'paid_mulligan_fee_php',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(db, 'golf_rounds', 'course_rating', 'REAL');
      await _addColumnIfMissing(db, 'golf_rounds', 'slope_rating', 'INTEGER');
      await _addColumnIfMissing(db, 'golf_rounds', 'attested_at_ms', 'INTEGER');
      await _addColumnIfMissing(
        db,
        'golf_rounds',
        'attested_by_name',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        'golf_rounds',
        'attested_role',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        'golf_rounds',
        'edited_after_attest_count',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'round_scores',
        'paid_mulligans',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _createCaddyPlayerTables(db);
    }
    if (oldVersion < 18) {
      await _addColumnIfMissing(
        db,
        'round_scores',
        'round_finished_at_ms',
        'INTEGER',
      );
      await _addColumnIfMissing(db, 'golf_rounds', 'flight_id', 'TEXT');
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('round_scores', 'golf_rounds')",
      );
      if (tables.length == 2) {
        await db.execute('''
        UPDATE round_scores
        SET round_finished_at_ms = (
              SELECT g.completed_at_ms FROM golf_rounds g
              WHERE g.round_id = round_scores.round_id
            )
        WHERE deleted = 0 AND round_id IN (
          SELECT round_id FROM golf_rounds WHERE completed_at_ms IS NOT NULL
        )
      ''');
      }
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String sqlType,
  ) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    if (tables.isEmpty) return;
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    final hasCol = cols.any((row) => row['name'] == column);
    if (hasCol) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $sqlType');
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
        sim_carry_yards REAL,
        sim_distance_to_hole_yards REAL,
        notes TEXT,
        aim_direction TEXT NOT NULL DEFAULT 'center',
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
        paid_mulligans INTEGER NOT NULL DEFAULT 0,
        conceded INTEGER NOT NULL DEFAULT 0,
        final_score INTEGER NOT NULL DEFAULT 0,
        round_finished_at_ms INTEGER,
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
        session_id TEXT,
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
    await _createRangeSessionsTable(db);
    await _createDiaryTables(db);
    await _createGolferProfileTable(db);
    await _createCaddyTables(db);
    await _createCaddyPlayerTables(db);

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
    return rows.map(_summaryFromRow).toList();
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

  /// Club blocks not yet folded into a [RangeSession].
  Future<List<RangeDrillSummary>> listUncompiledRangeDrills(
      {String? clubId}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT range_drills.*, clubs.name AS club_name
      FROM range_drills
      LEFT JOIN clubs ON clubs.id = range_drills.club_id
      WHERE range_drills.deleted = 0 AND range_drills.session_id IS NULL
      ${clubId == null ? '' : 'AND range_drills.club_id = ?'}
      ORDER BY range_drills.timestamp ASC
    ''', clubId == null ? null : [clubId]);
    return rows.map(_summaryFromRow).toList();
  }

  /// Newest compiled visit first. [clubId] keeps sessions that contain that club.
  Future<List<RangeSession>> listRangeSessions({String? clubId}) async {
    final db = await database;
    final rows = await db.query(
      'range_sessions',
      where: 'deleted = 0',
      orderBy: 'timestamp DESC',
    );
    final sessions = rows.map(RangeSession.fromMap).toList();
    if (clubId == null) return sessions;
    return sessions.where((session) => session.includesClub(clubId)).toList();
  }

  /// Freezes [blockIds], or every unlinked block, plus [sessionNote].
  ///
  /// Rows that already have a session stay on that session. A note with no
  /// blocks is saved. No blocks and a blank note is rejected.
  Future<RangeSession> compileRangeSession({
    required String sessionNote,
    String venueName = '',
    List<String>? blockIds,
  }) async {
    final db = await database;
    final note = sessionNote.trim();
    final where = StringBuffer('deleted = 0 AND session_id IS NULL');
    final args = <Object?>[];
    if (blockIds != null) {
      if (blockIds.isEmpty) {
        where.write(' AND 0');
      } else {
        where.write(
            ' AND id IN (${List.filled(blockIds.length, '?').join(',')})');
        args.addAll(blockIds);
      }
    }
    final rows = await db.query(
      'range_drills',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'timestamp ASC',
    );
    if (rows.isEmpty && note.isEmpty) {
      throw ArgumentError(kEmptyRangeSessionMessage);
    }
    final blocks = await _snapshotBlocks(db, rows);
    final now = _nowMs();
    final id = 'rsess_$now';
    final summary = jsonEncode([for (final block in blocks) block.toJson()]);
    await db.transaction((txn) async {
      await txn.insert('range_sessions', {
        'id': id,
        'venue_name': venueName.trim(),
        'session_note': note,
        'compiled_summary_json': summary,
        'timestamp': now,
        'is_synced': 0,
        'updated_at_ms': now,
        'deleted': 0,
      });
      for (final row in rows) {
        await txn.update(
          'range_drills',
          {
            'session_id': id,
            'is_synced': 0,
            'updated_at_ms': now,
          },
          where: 'id = ? AND session_id IS NULL',
          whereArgs: [row['id']],
        );
      }
    });
    return RangeSession(
      id: id,
      venueName: venueName.trim(),
      sessionNote: note,
      blocks: blocks,
      timestamp: now,
    );
  }

  Future<List<RangeSessionBlock>> _snapshotBlocks(
      DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    final blocks = <RangeSessionBlock>[];
    for (final row in rows) {
      final log = RangeDrillLog.fromMap(row);
      final clubs = await db.query(
        'clubs',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [log.clubId],
        limit: 1,
      );
      final clubName =
          clubs.isEmpty ? 'Removed club' : clubs.first['name'] as String;
      String? drillTitle;
      var steps = const <String>[];
      if (log.drillId != null && log.drillId!.isNotEmpty) {
        final drills = await db.query(
          'practice_drills',
          where: 'id = ?',
          whereArgs: [log.drillId],
          limit: 1,
        );
        if (drills.isNotEmpty) {
          final drill = PracticeDrill.fromMap(drills.first);
          drillTitle = drill.title;
          steps = drill.steps;
        }
      }
      blocks.add(RangeSessionBlock(
        clubId: log.clubId,
        clubName: clubName,
        shotCount: log.shotCount,
        minYards: log.minYards,
        avgYards: log.avgYards,
        maxYards: log.maxYards,
        tempoNotes: log.tempoNotes,
        drillId: log.drillId,
        drillTitle: drillTitle,
        drillSteps: steps,
      ));
    }
    return blocks;
  }

  RangeDrillSummary _summaryFromRow(Map<String, Object?> row) {
    final name = row['club_name'] as String?;
    return RangeDrillSummary(
      drill: RangeDrillLog.fromMap(row),
      clubName: (name == null || name.isEmpty) ? 'Removed club' : name,
    );
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
    // `golf_rounds` is local-only, so the hole rows carry the finish to other devices.
    await db.update(
      'round_scores',
      _dirty({'round_finished_at_ms': now}),
      where: 'round_id = ? AND deleted = 0',
      whereArgs: [roundId],
    );
  }

  /// Soft-deletes a round. Hole and shot tombstones sync, so every device drops it.
  Future<void> deleteRound(String roundId) => discardRound(roundId);

  /// Remembers the flight this round was shared or joined through.
  Future<void> linkRoundToFlight(String roundId, String flightId) async {
    final db = await database;
    await db.update(
      'golf_rounds',
      _dirty({'flight_id': flightId}),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  /// True when the round was shared through a flight or a caddy session.
  Future<bool> roundHasFlight(String roundId) async {
    final db = await database;
    final linked = await db.query(
      'golf_rounds',
      columns: ['flight_id'],
      where: "round_id = ? AND flight_id IS NOT NULL AND flight_id != ''",
      whereArgs: [roundId],
      limit: 1,
    );
    if (linked.isNotEmpty) return true;
    final caddy = await db.query(
      'caddy_sessions',
      columns: ['channel_id'],
      where: 'round_id = ? AND deleted = 0',
      whereArgs: [roundId],
      limit: 1,
    );
    return caddy.isNotEmpty;
  }

  /// Removes an in-progress round the golfer chose not to keep.
  Future<void> discardRound(String roundId) async {
    final db = await database;
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
    final round = await db.query(
      'golf_rounds',
      columns: ['completed_at_ms'],
      where: 'round_id = ?',
      whereArgs: [score.roundId],
      limit: 1,
    );
    await db.insert(
      'round_scores',
      _newRow({
        ...score.toMap(),
        'round_finished_at_ms':
            round.isEmpty ? null : round.first['completed_at_ms'],
      }),
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
    int paidMulligans = 0,
  }) async {
    final existing = await getHoleScore(roundId, holeNumber);
    final strokeCount = conceded ? par * 2 : strokes.clamp(0, 99);
    final penCount = penalties.clamp(0, 99);
    final gross = computeFinalScore(strokes: strokeCount, penalties: penCount);
    final finalScore = holeComplete || conceded ? gross : 0;
    final mates = await getScoresForRound(roundId);
    final paidByHole = {
      for (final hole in mates) hole.holeNumber: hole.paidMulligans,
    };
    final paid = clampPaidMulligan(
      holeNumber: holeNumber,
      requested: paidMulligans,
      paidByHole: paidByHole,
    );

    final score = RoundScore(
      id: existing?.id ?? '${roundId}_h$holeNumber',
      roundId: roundId,
      courseName: existing?.courseName ?? courseName,
      holeNumber: holeNumber,
      par: par,
      strokes: strokeCount,
      penalties: penCount,
      mulligans: mulligans,
      paidMulligans: paid,
      conceded: conceded ? 1 : 0,
      finalScore: finalScore,
      isSynced: 0,
    );
    await upsertHoleScore(score);
  }

  Future<RoundFormatSettings> getRoundFormat(String roundId) async {
    final db = await database;
    final rows = await db.query(
      'golf_rounds',
      where: 'round_id = ? AND deleted = 0',
      whereArgs: [roundId],
      limit: 1,
    );
    if (rows.isEmpty) return RoundFormatSettings(roundId: roundId);
    final row = rows.first;
    final attested = row['attested_at_ms'] as int?;
    return RoundFormatSettings(
      roundId: roundId,
      format: ScoringFormat.parse(row['scoring_format'] as String?),
      molaveDoubleEaglePoints: row['molave_double_eagle_pts'] as int? ?? 7,
      paidMulliganFeePhp: row['paid_mulligan_fee_php'] as int? ?? 0,
      courseRating: (row['course_rating'] as num?)?.toDouble(),
      slopeRating: row['slope_rating'] as int?,
      attestedAtMs: attested == 0 ? null : attested,
      attestedByName: row['attested_by_name'] as String? ?? '',
      attestedRole: row['attested_role'] as String? ?? '',
      editedAfterAttestCount: row['edited_after_attest_count'] as int? ?? 0,
    );
  }

  Future<void> saveRoundFormat(RoundFormatSettings settings) async {
    final db = await database;
    await db.update(
      'golf_rounds',
      _dirty({
        'scoring_format': settings.format.storageValue,
        'molave_double_eagle_pts':
            normalizeDoubleEaglePoints(settings.molaveDoubleEaglePoints),
        'paid_mulligan_fee_php': settings.paidMulliganFeePhp,
        'course_rating': settings.courseRating,
        'slope_rating': settings.slopeRating,
      }),
      where: 'round_id = ?',
      whereArgs: [settings.roundId],
    );
  }

  Future<void> attestRound({
    required String roundId,
    required String name,
    required String role,
  }) async {
    final db = await database;
    await db.update(
      'golf_rounds',
      _dirty({
        'attested_at_ms': _nowMs(),
        'attested_by_name': name.trim(),
        'attested_role': role,
        'edited_after_attest_count': 0,
      }),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  /// Clears the lock and counts the edit. The attestor name stays for the badge.
  Future<void> invalidateAttestation(String roundId) async {
    final current = await getRoundFormat(roundId);
    if (!current.isAttested &&
        current.editedAfterAttestCount == 0 &&
        current.attestedByName.isEmpty) {
      return;
    }
    final db = await database;
    await db.update(
      'golf_rounds',
      _dirty({
        'attested_at_ms': null,
        'edited_after_attest_count':
            current.editedAfterAttestCount + (current.isAttested ? 1 : 0),
      }),
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
  }

  /// Newest-first unofficial differentials for completed 18-hole rated rounds.
  Future<List<double>> handicapDifferentials({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'golf_rounds',
      where:
          'deleted = 0 AND completed_at_ms IS NOT NULL AND course_rating IS NOT NULL AND slope_rating IS NOT NULL',
      orderBy: 'completed_at_ms DESC',
      limit: limit,
    );
    final diffs = <double>[];
    for (final row in rows) {
      final roundId = row['round_id'] as String;
      final rating = (row['course_rating'] as num).toDouble();
      final slope = row['slope_rating'] as int;
      final holes = await getScoresForRound(roundId);
      final inputs = [
        for (final hole in holes)
          holeInputFromScore(
            holeNumber: hole.holeNumber,
            par: hole.par,
            strokes: hole.strokes,
            penalties: hole.penalties,
            conceded: hole.conceded,
            paidMulligans: hole.paidMulligans,
            finalScore: hole.finalScore,
          ),
      ];
      final played = inputs.where((hole) => hole.played).length;
      if (played < 18 || slope <= 0) continue;
      diffs.add(scoreDifferential(
        adjustedGross: adjustedRoundGross(inputs),
        courseRating: rating,
        slopeRating: slope,
      ));
    }
    return diffs;
  }

  Future<double?> unofficialHandicapEstimate() async {
    return unofficialHandicapIndex(await handicapDifferentials());
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
    String? aimDirection,
  }) async {
    final db = await database;
    final fields = <String, Object?>{
      'club_id': clubId,
      'lie_type': lieType,
      'is_synced': 0,
    };
    if (aimDirection != null) {
      fields['aim_direction'] = aimDirection;
    }
    await db.update(
      'shots',
      fields,
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

  /// Ensures a [round_scores] row exists for manual cart/classic edits.
  Future<RoundScore> ensureHoleRow({
    required String roundId,
    required String courseName,
    required int holeNumber,
  }) async {
    final existing = await getHoleScore(roundId, holeNumber);
    if (existing != null) return existing;
    final par = PhGolfCatalog.parForHole(courseName, holeNumber) ?? 4;
    final row = RoundScore(
      id: '${roundId}_h$holeNumber',
      roundId: roundId,
      courseName: courseName,
      holeNumber: holeNumber,
      par: par,
    );
    await upsertHoleScore(row);
    return row;
  }

  /// Adds [delta] to stroke count (cart +1). Clears concede when adding strokes.
  Future<void> incrementStrokes({
    required String roundId,
    required String courseName,
    required int holeNumber,
    int delta = 1,
  }) async {
    final hole = await ensureHoleRow(
      roundId: roundId,
      courseName: courseName,
      holeNumber: holeNumber,
    );
    final clearedConcede = delta > 0 && hole.conceded == 1;
    final strokes = (clearedConcede ? 0 : hole.strokes) + delta;
    final strokeCount = strokes.clamp(0, 99);
    final finalScore = strokeCount > 0 || hole.penalties > 0
        ? computeFinalScore(strokes: strokeCount, penalties: hole.penalties)
        : 0;
    final updated = hole.copyWith(
      strokes: strokeCount,
      conceded: clearedConcede ? 0 : hole.conceded,
      finalScore: finalScore,
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

  Future<void> incrementMulligans(String roundId, int holeNumber,
      [int delta = 1]) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null) return;
    final mulligans = (hole.mulligans + delta).clamp(0, 99);
    await upsertHoleScore(hole.copyWith(mulligans: mulligans, isSynced: 0));
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
    await _recordHoledStroke(roundId, holeNumber);
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

  /// Logs the putt that drops the ball, so Finish Hole scores strokes +
  /// penalties + 1. Skipped once the player has picked up at double par, on a
  /// conceded hole, or when the hole already ends with a holed stroke.
  Future<void> _recordHoledStroke(String roundId, int holeNumber) async {
    final hole = await getHoleScore(roundId, holeNumber);
    if (hole == null || hole.conceded == 1) return;
    if (hole.par > 0 && hole.strokes + hole.penalties >= 2 * hole.par) return;
    final shots = await getShotsForHole(roundId, holeNumber);
    if (shots.isNotEmpty && shots.last.isHoled) return;

    final db = await database;
    final putters = await db.query(
      'clubs',
      columns: ['id'],
      where: "category = 'putter' AND deleted = 0",
      limit: 1,
    );
    final now = _nowMs();
    final shot = ShotRecord(
      id: 'holed_shot_$now',
      roundId: roundId,
      holeNumber: holeNumber,
      strokeNumber: shots.isEmpty ? 1 : shots.last.strokeNumber + 1,
      clubId: putters.isEmpty ? 'putter' : putters.first['id'] as String,
      lieType: 'green',
      startLat: 0,
      startLon: 0,
      notes: kHoledShotNote,
      timestamp: now,
    );
    await db.insert('shots', _newRow(shot.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await syncStrokeCountFromShots(roundId, holeNumber);
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
    String aimDirection = 'center',
    double? simCarryYards,
    double? simDistanceToHoleYards,
    String notes = '',
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
      aimDirection: simulator ? 'center' : aimDirection,
      simCarryYards: simulator ? simCarryYards : null,
      simDistanceToHoleYards: simulator ? simDistanceToHoleYards : null,
      notes: simulator ? notes.trim() : '',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert('shots', _newRow(newShot.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await syncStrokeCountFromShots(roundId, holeNumber);
  }

  /// Caddy stroke without GPS — inserts audit shot then derives [round_scores].
  Future<void> recordCaddyStroke({
    required String roundId,
    required int holeNumber,
    required String courseName,
    String clubId = 'caddy-log',
    String lieType = 'fairway',
  }) async {
    await ensureHoleRow(
      roundId: roundId,
      courseName: courseName,
      holeNumber: holeNumber,
    );
    final db = await database;
    final prevShotMaps = await db.query(
      'shots',
      where: 'round_id = ? AND hole_number = ? AND deleted = 0',
      whereArgs: [roundId, holeNumber],
      orderBy: 'stroke_number DESC',
      limit: 1,
    );
    var strokeNumber = 1;
    if (prevShotMaps.isNotEmpty) {
      strokeNumber = (prevShotMaps.first['stroke_number'] as int) + 1;
    }
    final newShot = ShotRecord(
      id: 'caddy_shot_${_nowMs()}',
      roundId: roundId,
      holeNumber: holeNumber,
      strokeNumber: strokeNumber,
      clubId: clubId,
      lieType: lieType,
      startLat: 0,
      startLon: 0,
      distanceYards: 0,
      timestamp: _nowMs(),
    );
    await db.insert('shots', _newRow(newShot.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await syncStrokeCountFromShots(roundId, holeNumber);
  }

  Future<void> _createCaddyTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caddy_sessions (
        channel_id TEXT PRIMARY KEY,
        round_id TEXT NOT NULL,
        request_token TEXT NOT NULL,
        status TEXT NOT NULL,
        role TEXT NOT NULL,
        golfer_uid TEXT,
        caddy_uid TEXT,
        course_name TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL DEFAULT 0,
        redeemed_at_ms INTEGER NOT NULL DEFAULT 0,
        last_event_ms INTEGER NOT NULL DEFAULT 0,
        expires_at_ms INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caddy_pending_events (
        id TEXT PRIMARY KEY,
        channel_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createCaddyPlayerTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caddy_flight_players (
        channel_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        player_name TEXT NOT NULL,
        PRIMARY KEY (channel_id, player_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caddy_player_holes (
        id TEXT PRIMARY KEY,
        channel_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        hole_number INTEGER NOT NULL,
        par INTEGER NOT NULL,
        gross INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
  }

  Future<void> addCaddyFlightPlayer({
    required String channelId,
    required String playerId,
    required String playerName,
  }) async {
    final db = await database;
    await db.insert(
      'caddy_flight_players',
      {
        'channel_id': channelId,
        'player_id': playerId,
        'player_name': playerName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<({String id, String name})>> listCaddyFlightPlayers(
    String channelId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'caddy_flight_players',
      where: 'channel_id = ?',
      whereArgs: [channelId],
      orderBy: 'player_name ASC',
    );
    return [
      for (final row in rows)
        (
          id: row['player_id'] as String,
          name: row['player_name'] as String,
        ),
    ];
  }

  Future<void> saveCaddyPlayerHole({
    required String channelId,
    required String playerId,
    required int holeNumber,
    required int par,
    required int gross,
  }) async {
    final db = await database;
    await db.insert(
      'caddy_player_holes',
      {
        'id': '${channelId}_${playerId}_$holeNumber',
        'channel_id': channelId,
        'player_id': playerId,
        'hole_number': holeNumber,
        'par': par,
        'gross': gross,
        'updated_at_ms': _nowMs(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<int, int>> caddyPlayerGrossByHole({
    required String channelId,
    required String playerId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'caddy_player_holes',
      where: 'channel_id = ? AND player_id = ?',
      whereArgs: [channelId, playerId],
    );
    return {
      for (final row in rows) row['hole_number'] as int: row['gross'] as int,
    };
  }

  Future<void> upsertCaddySession(CaddySessionRecord session) async {
    final db = await database;
    await db.insert(
      'caddy_sessions',
      {
        ...session.toMap(),
        'updated_at_ms': _nowMs(),
        'deleted': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CaddySessionRecord?> getCaddySession(String channelId) async {
    final db = await database;
    final rows = await db.query(
      'caddy_sessions',
      where: 'channel_id = ? AND deleted = 0',
      whereArgs: [channelId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CaddySessionRecord.fromMap(rows.first);
  }

  Future<CaddySessionRecord?> getActiveCaddySessionForGolfer() async {
    final db = await database;
    final rows = await db.query(
      'caddy_sessions',
      where:
          "role = 'golfer' AND deleted = 0 AND status IN ('pending', 'active')",
      orderBy: 'updated_at_ms DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CaddySessionRecord.fromMap(rows.first);
  }

  Future<CaddySessionRecord?> getActiveCaddySessionForCaddy() async {
    final db = await database;
    final rows = await db.query(
      'caddy_sessions',
      where: "role = 'caddy' AND deleted = 0 AND status = 'active'",
      orderBy: 'updated_at_ms DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CaddySessionRecord.fromMap(rows.first);
  }

  Future<void> updateCaddySessionStatus(
    String channelId,
    CaddySessionStatus status,
  ) async {
    final db = await database;
    await db.update(
      'caddy_sessions',
      {
        'status': status.wire,
        'updated_at_ms': _nowMs(),
      },
      where: 'channel_id = ?',
      whereArgs: [channelId],
    );
  }

  Future<void> setCaddySessionLastEventMs(String channelId, int ms) async {
    final db = await database;
    await db.update(
      'caddy_sessions',
      {'last_event_ms': ms, 'updated_at_ms': _nowMs()},
      where: 'channel_id = ?',
      whereArgs: [channelId],
    );
  }

  Future<void> queueCaddyPendingEvent(
    String channelId,
    CaddyRoundEvent event,
  ) async {
    final db = await database;
    await db.insert(
      'caddy_pending_events',
      {
        'id': event.id,
        'channel_id': channelId,
        'payload_json': jsonEncode(event.toFirestore()),
        'updated_at_ms': event.updatedAtMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CaddyRoundEvent>> takeCaddyPendingEvents(String channelId) async {
    final db = await database;
    final rows = await db.query(
      'caddy_pending_events',
      where: 'channel_id = ?',
      whereArgs: [channelId],
      orderBy: 'updated_at_ms',
    );
    final events = <CaddyRoundEvent>[];
    for (final row in rows) {
      final decoded = jsonDecode(row['payload_json'] as String);
      if (decoded is Map<String, dynamic>) {
        events.add(CaddyRoundEvent.fromFirestore(row['id'] as String, decoded));
      }
      await db.delete(
        'caddy_pending_events',
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    return events;
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  /// True when any synced table still has a live row (including the starter bag).
  Future<bool> hasLocalSyncRows() async {
    final db = await database;
    for (final table in kSyncTables) {
      final rows = await db.query(
        table,
        columns: ['id'],
        where: 'deleted = 0',
        limit: 1,
      );
      if (rows.isNotEmpty) return true;
    }
    return false;
  }

  Future<bool> hasLiveRow(String table, String id) async {
    final db = await database;
    final rows = await db.query(
      table,
      columns: ['id'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Deletes local sync rows whose ids are not in [remoteIds].
  ///
  /// Used only after the golfer confirms replacing this device with a remote
  /// diary that has live entries.
  Future<int> deleteLocalRowsMissingFrom(
    Map<String, Set<String>> remoteIds,
  ) async {
    final db = await database;
    var removed = 0;
    await db.transaction((txn) async {
      for (final table in kSyncTables) {
        final keep = remoteIds[table] ?? const <String>{};
        final local = await txn.query(table, columns: ['id']);
        for (final row in local) {
          final id = row['id'] as String?;
          if (id == null || keep.contains(id)) continue;
          removed += await txn.delete(
            table,
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    });
    return removed;
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
      if (table == 'round_scores') {
        final roundId = localRows.first['round_id'] as String?;
        if (roundId != null) await _retireRoundWithoutHoles(db, roundId);
      }
      return true;
    }

    final row = _sqliteRow(table, remote, remoteUpdated);
    if (table == 'range_drills' && localRows.isNotEmpty) {
      if (!remote.containsKey('drill_id')) {
        row['drill_id'] = localRows.first['drill_id'];
      }
      if (!remote.containsKey('session_id')) {
        row['session_id'] = localRows.first['session_id'];
      }
    }
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    if (table == 'swing_diary_messages') {
      // The golfer opted in when this thread was written on another device.
      await db.insert(
        'diary_settings',
        {'id': 'local', 'opted_in': 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    if (table == 'round_scores') {
      final roundId = row['round_id'] as String?;
      if (roundId != null) {
        await _ensureGolfRoundFromScores(db, roundId);
        final finishedAt = row['round_finished_at_ms'] as int?;
        if (finishedAt != null) {
          await db.update(
            'golf_rounds',
            {'completed_at_ms': finishedAt},
            where: 'round_id = ? AND completed_at_ms IS NULL',
            whereArgs: [roundId],
          );
        }
      }
    }
    return true;
  }

  /// A round deleted on another device arrives as hole tombstones only.
  Future<void> _retireRoundWithoutHoles(Database db, String roundId) async {
    final live = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM round_scores WHERE round_id = ? AND deleted = 0',
      [roundId],
    ));
    if ((live ?? 0) > 0) return;
    await db.update(
      'golf_rounds',
      {'deleted': 1},
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
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

  Future<void> _createRangeSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS range_sessions (
        id TEXT PRIMARY KEY,
        venue_name TEXT,
        session_note TEXT,
        compiled_summary_json TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createDiaryContextNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diary_context_notes (
        id TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        content TEXT NOT NULL,
        context_date TEXT NOT NULL,
        round_id TEXT,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createDiaryTables(Database db) async {
    await _createDiaryContextNotesTable(db);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS swing_diary_messages (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS range_evaluations (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        session_id TEXT,
        session_date TEXT,
        content TEXT NOT NULL,
        prompt_tokens INTEGER,
        covered_through_ms INTEGER,
        referenced_drill_ids_json TEXT,
        referenced_club_ids_json TEXT,
        timestamp INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diary_settings (
        id TEXT PRIMARY KEY,
        opted_in INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createGolferProfileTableLegacy(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS golfer_profile (
        id TEXT PRIMARY KEY,
        equipment_notes TEXT NOT NULL DEFAULT '',
        swing_anchors TEXT NOT NULL DEFAULT '',
        physical_constraints TEXT NOT NULL DEFAULT '',
        training_environment TEXT NOT NULL DEFAULT '',
        dismissed_prompts_json TEXT NOT NULL DEFAULT '[]',
        distilled_through_ms INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createGolferProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS golfer_profile (
        id TEXT PRIMARY KEY,
        equipment_notes TEXT NOT NULL DEFAULT '',
        swing_anchors TEXT NOT NULL DEFAULT '',
        physical_constraints TEXT NOT NULL DEFAULT '',
        training_environment TEXT NOT NULL DEFAULT '',
        dismissed_prompts_json TEXT NOT NULL DEFAULT '[]',
        distilled_through_ms INTEGER NOT NULL DEFAULT 0,
        age INTEGER,
        years_playing INTEGER,
        gender TEXT NOT NULL DEFAULT '',
        skill_tier TEXT NOT NULL DEFAULT '',
        yardage_display_mode TEXT NOT NULL DEFAULT 'follow_skill_tier',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        bag_nickname TEXT NOT NULL DEFAULT '',
        scorecard_view_mode TEXT NOT NULL DEFAULT 'classic',
        scorecard_cart_high_contrast INTEGER NOT NULL DEFAULT 0,
        avatar_choice TEXT NOT NULL DEFAULT '',
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at_ms INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeGolferProfileYardageDisplay(Database db) async {
    await db.execute(
      "ALTER TABLE golfer_profile ADD COLUMN yardage_display_mode TEXT NOT NULL DEFAULT 'follow_skill_tier'",
    );
  }

  Future<void> _upgradeGolferProfileScorecardView(Database db) async {
    await db.execute(
      "ALTER TABLE golfer_profile ADD COLUMN scorecard_view_mode TEXT NOT NULL DEFAULT 'classic'",
    );
    await db.execute(
      'ALTER TABLE golfer_profile ADD COLUMN scorecard_cart_high_contrast INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _upgradeGolferProfileOnboarding(Database db) async {
    await db.execute('ALTER TABLE golfer_profile ADD COLUMN age INTEGER');
    await db
        .execute('ALTER TABLE golfer_profile ADD COLUMN years_playing INTEGER');
    await db.execute(
        "ALTER TABLE golfer_profile ADD COLUMN gender TEXT NOT NULL DEFAULT ''");
    await db.execute(
        "ALTER TABLE golfer_profile ADD COLUMN skill_tier TEXT NOT NULL DEFAULT ''");
    await db.execute(
        'ALTER TABLE golfer_profile ADD COLUMN onboarding_completed INTEGER NOT NULL DEFAULT 0');
    await db.execute(
        "ALTER TABLE golfer_profile ADD COLUMN bag_nickname TEXT NOT NULL DEFAULT ''");
  }

  Future<GolferProfile> getGolferProfile() async {
    final db = await database;
    final rows = await db.query(
      'golfer_profile',
      where: 'id = ? AND deleted = 0',
      whereArgs: [GolferProfile.rowId],
      limit: 1,
    );
    if (rows.isEmpty) return const GolferProfile();
    return GolferProfile.fromMap(rows.first);
  }

  Future<void> saveGolferProfile(GolferProfile profile) async {
    final db = await database;
    await db.insert(
      'golfer_profile',
      _dirty(profile.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Practice venues and course names the golfer actually logged, most used first.
  Future<List<String>> frequentVenueNames({int limit = 8}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT name FROM (
        SELECT TRIM(venue_name) AS name
        FROM range_sessions
        WHERE deleted = 0 AND TRIM(venue_name) != ''
        UNION ALL
        SELECT TRIM(course_name) AS name
        FROM golf_rounds
        WHERE deleted = 0 AND TRIM(course_name) != ''
      )
      WHERE name != ''
      GROUP BY name
      ORDER BY COUNT(*) DESC, name COLLATE NOCASE
      LIMIT ?
    ''', [limit]);
    return [for (final row in rows) row['name'] as String];
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
        scoring_format TEXT NOT NULL DEFAULT 'gross',
        molave_double_eagle_pts INTEGER NOT NULL DEFAULT 7,
        paid_mulligan_fee_php INTEGER NOT NULL DEFAULT 0,
        course_rating REAL,
        slope_rating INTEGER,
        attested_at_ms INTEGER,
        attested_by_name TEXT NOT NULL DEFAULT '',
        attested_role TEXT NOT NULL DEFAULT '',
        edited_after_attest_count INTEGER NOT NULL DEFAULT 0,
        flight_id TEXT,
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
      'sim_carry_yards',
      'sim_distance_to_hole_yards',
      'notes',
      'aim_direction',
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
      'paid_mulligans',
      'conceded',
      'final_score',
      'round_finished_at_ms',
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
      'session_id',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'range_sessions': [
      'id',
      'venue_name',
      'session_note',
      'compiled_summary_json',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'diary_context_notes': [
      'id',
      'source',
      'content',
      'context_date',
      'round_id',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'swing_diary_messages': [
      'id',
      'role',
      'content',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
    'range_evaluations': [
      'id',
      'kind',
      'session_id',
      'session_date',
      'content',
      'prompt_tokens',
      'covered_through_ms',
      'referenced_drill_ids_json',
      'referenced_club_ids_json',
      'timestamp',
      'is_synced',
      'updated_at_ms',
      'deleted',
    ],
  };
}
