import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_database_service.dart';
import 'swing_diary_prompt.dart';

class DiaryMessage {
  const DiaryMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String content;
  final int timestamp;
}

class RangeEvaluation {
  const RangeEvaluation({
    required this.id,
    required this.kind,
    required this.content,
    required this.timestamp,
    this.sessionDate,
    this.sessionId,
  });

  final String id;
  final String kind;
  final String content;
  final int timestamp;
  final String? sessionDate;
  final String? sessionId;
}

class SwingDiaryService {
  SwingDiaryService({LocalDatabaseService? database})
      : _database = database ?? LocalDatabaseService.instance;

  final LocalDatabaseService _database;

  Future<Database> get _db => _database.database;

  Future<bool> isOptedIn() async {
    final rows = await (await _db).query(
      'diary_settings',
      where: 'id = ?',
      whereArgs: ['local'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return (rows.first['opted_in'] as int? ?? 0) == 1;
  }

  Future<void> setOptedIn(bool optedIn) async {
    await (await _db).insert(
      'diary_settings',
      {'id': 'local', 'opted_in': optedIn ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiaryMessage>> listMessages() async {
    final rows = await (await _db).query(
      'swing_diary_messages',
      where: 'deleted = 0',
      orderBy: 'timestamp ASC',
    );
    return rows
        .map((row) => DiaryMessage(
              id: row['id'] as String,
              role: row['role'] as String,
              content: row['content'] as String,
              timestamp: row['timestamp'] as int,
            ))
        .toList();
  }

  Future<List<RangeEvaluation>> listEvaluations() async {
    final rows = await (await _db).query(
      'range_evaluations',
      where: 'deleted = 0',
      orderBy: 'timestamp DESC',
    );
    return rows
        .map((row) => RangeEvaluation(
              id: row['id'] as String,
              kind: row['kind'] as String,
              content: row['content'] as String,
              timestamp: row['timestamp'] as int,
              sessionDate: row['session_date'] as String?,
              sessionId: row['session_id'] as String?,
            ))
        .toList();
  }

  Future<bool> hasDrillToday({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final start = DateTime(clock.year, clock.month, clock.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    final rows = await (await _db).query(
      'range_drills',
      columns: ['id'],
      where: 'deleted = 0 AND timestamp >= ? AND timestamp < ?',
      whereArgs: [start, end],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Builds the next prompt and, only when it would pass [tokenCeiling],
  /// writes one periodic summary before returning.
  Future<DiaryPromptPlan> preparePrompt({
    String question = '',
    int tokenCeiling = kDiaryTokenCeiling,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final drills = await _database.listRangeDrills();
    final sessions = await _database.listRangeSessions();
    final messages = await listMessages();
    final tallies = await _tallies(clock);
    final existing = await _latestBrief();
    final plan = planDiaryPrompt(DiaryPromptInput(
      now: clock,
      drills: drills,
      sessions: sessions,
      turns: [
        for (final message in messages)
          DiaryTurn(role: message.role, content: message.content),
      ],
      tallies: tallies,
      progressBrief: existing,
      question: question,
      tokenCeiling: tokenCeiling,
    ));
    if (plan.summary != null) {
      await _insertEvaluation(
        kind: 'periodic_summary',
        content: plan.summary!,
        promptTokens: plan.tokens,
        coveredThroughMs: plan.coveredThroughMs,
        sessionDate: _ymd(clock),
        nowMs: clock.millisecondsSinceEpoch,
      );
    }
    return plan;
  }

  Future<DiaryMessage> ask({
    required String prompt,
    required String reply,
    required String userText,
    String? sessionId,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final db = await _db;
    final userId = 'dmsg_${clock.millisecondsSinceEpoch}';
    final modelId = 'dmsg_${clock.millisecondsSinceEpoch + 1}';
    final evalId = 'eval_${clock.millisecondsSinceEpoch}';
    final today = await _todayRefs(clock);
    await db.transaction((txn) async {
      await txn.insert('swing_diary_messages', {
        'id': userId,
        'role': 'user',
        'content': userText,
        'timestamp': clock.millisecondsSinceEpoch,
        'is_synced': 0,
        'updated_at_ms': clock.millisecondsSinceEpoch,
        'deleted': 0,
      });
      await txn.insert('swing_diary_messages', {
        'id': modelId,
        'role': 'model',
        'content': reply,
        'timestamp': clock.millisecondsSinceEpoch + 1,
        'is_synced': 0,
        'updated_at_ms': clock.millisecondsSinceEpoch,
        'deleted': 0,
      });
      await txn.insert('range_evaluations', {
        'id': evalId,
        'kind': 'evaluation',
        'session_id': sessionId,
        'session_date': _ymd(clock),
        'content': reply,
        'prompt_tokens': estimateDiaryTokens(prompt),
        'covered_through_ms': null,
        'referenced_drill_ids_json': jsonEncode(today.drillIds),
        'referenced_club_ids_json': jsonEncode(today.clubIds),
        'timestamp': clock.millisecondsSinceEpoch,
        'is_synced': 0,
        'updated_at_ms': clock.millisecondsSinceEpoch,
        'deleted': 0,
      });
    });
    return DiaryMessage(
      id: modelId,
      role: 'model',
      content: reply,
      timestamp: clock.millisecondsSinceEpoch + 1,
    );
  }

  Future<String?> latestTodaySessionId({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final sessions = await _database.listRangeSessions();
    for (final session in sessions) {
      if (_ymd(DateTime.fromMillisecondsSinceEpoch(session.timestamp)) == _ymd(clock)) {
        return session.id;
      }
    }
    return null;
  }

  Future<void> _insertEvaluation({
    required String kind,
    required String content,
    required int promptTokens,
    required int nowMs,
    required String sessionDate,
    int? coveredThroughMs,
  }) async {
    await (await _db).insert('range_evaluations', {
      'id': 'eval_${DateTime.now().microsecondsSinceEpoch}',
      'kind': kind,
      'session_id': null,
      'session_date': sessionDate,
      'content': content,
      'prompt_tokens': promptTokens,
      'covered_through_ms': coveredThroughMs,
      'referenced_drill_ids_json': '[]',
      'referenced_club_ids_json': '[]',
      'timestamp': nowMs,
      'is_synced': 0,
      'updated_at_ms': nowMs,
      'deleted': 0,
    });
  }

  Future<String?> _latestBrief() async {
    final rows = await (await _db).query(
      'range_evaluations',
      columns: ['content'],
      where: 'deleted = 0 AND kind = ?',
      whereArgs: ['periodic_summary'],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['content'] as String?;
  }

  Future<List<ClubTally>> _tallies(DateTime now) async {
    final windowStart = now
        .subtract(const Duration(days: kDiaryRecentWindowDays))
        .millisecondsSinceEpoch;
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT clubs.name AS club_name,
             range_drills.club_id AS club_id,
             COUNT(*) AS session_count,
             AVG(CASE WHEN range_drills.timestamp >= ? THEN range_drills.avg_yards END) AS this_avg,
             AVG(CASE WHEN range_drills.timestamp < ? THEN range_drills.avg_yards END) AS prev_avg
      FROM range_drills
      LEFT JOIN clubs ON clubs.id = range_drills.club_id
      WHERE range_drills.deleted = 0
      GROUP BY range_drills.club_id
      ORDER BY club_name COLLATE NOCASE
    ''', [windowStart, windowStart]);
    final tallies = <ClubTally>[];
    for (final row in rows) {
      final titles = await db.rawQuery('''
        SELECT practice_drills.title AS title, COUNT(*) AS uses
        FROM range_drills
        JOIN practice_drills ON practice_drills.id = range_drills.drill_id
        WHERE range_drills.deleted = 0 AND range_drills.club_id = ?
        GROUP BY practice_drills.title
        ORDER BY uses DESC, title COLLATE NOCASE
        LIMIT 3
      ''', [row['club_id']]);
      tallies.add(ClubTally(
        clubName: (row['club_name'] as String?)?.isNotEmpty == true
            ? row['club_name'] as String
            : 'Removed club',
        sessionCount: (row['session_count'] as num).toInt(),
        thisPeriodAvg: (row['this_avg'] as num?)?.toDouble(),
        previousPeriodAvg: (row['prev_avg'] as num?)?.toDouble(),
        drillTitles: [
          for (final title in titles)
            if (title['title'] != null) title['title'] as String,
        ],
      ));
    }
    return tallies;
  }

  Future<({List<String> drillIds, List<String> clubIds})> _todayRefs(DateTime now) async {
    final drills = await _database.listRangeDrills();
    final today = drills.where((entry) {
      return _ymd(DateTime.fromMillisecondsSinceEpoch(entry.drill.timestamp)) == _ymd(now);
    });
    return (
      drillIds: [for (final entry in today) entry.drill.id],
      clubIds: {for (final entry in today) entry.drill.clubId}.toList(),
    );
  }
}

String _ymd(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
