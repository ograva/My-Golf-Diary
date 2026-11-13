import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/golf_models.dart';
import '../models/golfer_profile.dart';
import 'diary_model.dart';
import 'local_database_service.dart';

class DistillResult {
  const DistillResult({
    required this.profile,
    required this.changed,
    required this.summary,
  });

  final GolferProfile profile;
  final bool changed;
  final String summary;
}

class UndistilledNotes {
  const UndistilledNotes({required this.text, required this.newestMs});

  final String text;
  final int newestMs;

  bool get isEmpty => text.trim().isEmpty;
}

const String kProfileDistillSystem = '''
You update a golfer profile from notes the golfer wrote. Keep an existing anchor unless a newer note refines it or the golfer clearly drops it. Do not invent injuries, clubs, venues, or swing methods. Do not copy coach evaluations. Return only the JSON object.
''';

Schema get kProfileDistillSchema => Schema.object(
      properties: {
        'equipmentNotes': Schema.string(
            description: 'Club, shaft, and attack tendencies the golfer stated'),
        'swingAnchors': Schema.string(
            description: 'Tempo, setup, and feels the golfer wants to keep'),
        'physicalConstraints': Schema.string(
            description: 'Joints, tissues, or fatigue the golfer named'),
        'trainingEnvironment': Schema.string(
            description: 'Aids, indoor limits, and typical turf or mats'),
        'changedSummary': Schema.string(
            description: 'One line on what changed, or empty if nothing did'),
      },
    );

/// Pulls golfer-written notes newer than the profile watermark and merges them.
class GolferProfileService {
  GolferProfileService({
    required DiaryModel model,
    LocalDatabaseService? database,
  })  : _model = model,
        _database = database ?? LocalDatabaseService.instance;

  final DiaryModel _model;
  final LocalDatabaseService _database;

  Future<UndistilledNotes> collectUndistilledNotes(GolferProfile profile) async {
    final db = await _database.database;
    final since = profile.distilledThroughMs;
    final lines = <String>[];
    var newest = since;

    void consider(int stamp) {
      if (stamp > newest) newest = stamp;
    }

    final sessions = await db.query(
      'range_sessions',
      where: 'deleted = 0 AND (timestamp > ? OR updated_at_ms > ?)',
      whereArgs: [since, since],
      orderBy: 'timestamp ASC',
    );
    for (final row in sessions) {
      final note = (row['session_note'] as String? ?? '').trim();
      final venue = (row['venue_name'] as String? ?? '').trim();
      final stamp = row['timestamp'] as int? ?? 0;
      consider(stamp);
      consider(row['updated_at_ms'] as int? ?? 0);
      if (note.isNotEmpty) {
        lines.add('Session note${venue.isEmpty ? '' : ' @ $venue'}: $note');
      }
      final raw = row['compiled_summary_json'] as String? ?? '[]';
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final cue = (item['tempoNotes'] as String? ?? '').trim();
          final club = (item['clubName'] as String? ?? '').trim();
          if (cue.isEmpty) continue;
          lines.add('Session cue${club.isEmpty ? '' : ' ($club)'}: $cue');
        }
      }
    }

    final drills = await db.rawQuery('''
      SELECT range_drills.tempo_notes AS cue,
             range_drills.venue_name AS venue,
             range_drills.timestamp AS stamp,
             clubs.name AS club_name
      FROM range_drills
      LEFT JOIN clubs ON clubs.id = range_drills.club_id
      WHERE range_drills.deleted = 0
        AND TRIM(COALESCE(range_drills.tempo_notes, '')) != ''
        AND (range_drills.timestamp > ? OR range_drills.updated_at_ms > ?)
      ORDER BY range_drills.timestamp ASC
    ''', [since, since]);
    for (final row in drills) {
      consider(row['stamp'] as int? ?? 0);
      final club = (row['club_name'] as String?)?.trim();
      final venue = (row['venue'] as String? ?? '').trim();
      lines.add(
          'Drill cue${club == null || club.isEmpty ? '' : ' ($club)'}${venue.isEmpty ? '' : ' @ $venue'}: ${(row['cue'] as String).trim()}');
    }

    final clubs = await db.query(
      'clubs',
      where:
          'deleted = 0 AND updated_at_ms > ? AND (TRIM(COALESCE(brand, \'\')) != \'\' OR TRIM(COALESCE(model, \'\')) != \'\' OR TRIM(COALESCE(swing_notes, \'\')) != \'\')',
      whereArgs: [since],
    );
    for (final row in clubs) {
      consider(row['updated_at_ms'] as int? ?? 0);
      final club = Club.fromMap(Map<String, dynamic>.from(row));
      final spec = [club.brand.trim(), club.model.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      final cue = club.swingNotes.trim().isEmpty ? '' : ' cue: ${club.swingNotes.trim()}';
      lines.add('Bag ${club.name}${spec.isEmpty ? '' : ' ($spec)'}:$cue');
    }

    final messages = await db.query(
      'swing_diary_messages',
      where: 'deleted = 0 AND role = ? AND timestamp > ?',
      whereArgs: ['user', since],
      orderBy: 'timestamp ASC',
    );
    for (final row in messages) {
      final text = (row['content'] as String? ?? '').trim();
      consider(row['timestamp'] as int? ?? 0);
      if (text.isEmpty || text.toLowerCase() == 'summarize today') continue;
      lines.add('Golfer: $text');
    }

    return UndistilledNotes(text: lines.join('\n'), newestMs: newest);
  }

  Future<DistillResult?> distillIfNeeded({DiaryCancel? cancel}) async {
    if (!_model.available) return null;
    final current = await _database.getGolferProfile();
    final notes = await collectUndistilledNotes(current);
    if (notes.isEmpty) return null;
    final raw = await _model.generateJson(
      systemInstruction: kProfileDistillSystem,
      responseSchema: kProfileDistillSchema,
      cancel: cancel,
      prompt: '''
Current profile:
equipmentNotes: ${current.equipmentNotes}
swingAnchors: ${current.swingAnchors}
physicalConstraints: ${current.physicalConstraints}
trainingEnvironment: ${current.trainingEnvironment}

New golfer notes:
${notes.text}
''',
    );
    if (raw == null || raw.trim().isEmpty) return null;
    final merged = mergeDistilledBaseline(
      current: current,
      rawJson: raw,
      distilledThroughMs: notes.newestMs,
    );
    await _database.saveGolferProfile(merged.profile);
    final saved = await _database.getGolferProfile();
    return DistillResult(
      profile: saved,
      changed: merged.changed,
      summary: merged.summary,
    );
  }
}

class MergedProfile {
  const MergedProfile(this.profile, this.changed, this.summary);
  final GolferProfile profile;
  final bool changed;
  final String summary;
}

MergedProfile mergeDistilledBaseline({
  required GolferProfile current,
  required String rawJson,
  required int distilledThroughMs,
}) {
  final decoded = jsonDecode(_jsonObject(rawJson));
  if (decoded is! Map) {
    throw const FormatException('Profile distillation was not an object');
  }
  String keep(String key, String previous) {
    final next = decoded[key];
    if (next is! String || next.trim().isEmpty) return previous;
    return next.trim();
  }

  final summary = decoded['changedSummary'] is String
      ? (decoded['changedSummary'] as String).trim()
      : '';
  final next = current.copyWith(
    equipmentNotes: keep('equipmentNotes', current.equipmentNotes),
    swingAnchors: keep('swingAnchors', current.swingAnchors),
    physicalConstraints: keep('physicalConstraints', current.physicalConstraints),
    trainingEnvironment: keep('trainingEnvironment', current.trainingEnvironment),
    distilledThroughMs: distilledThroughMs,
  );
  final changed = next.equipmentNotes != current.equipmentNotes ||
      next.swingAnchors != current.swingAnchors ||
      next.physicalConstraints != current.physicalConstraints ||
      next.trainingEnvironment != current.trainingEnvironment;
  return MergedProfile(next, changed, summary);
}

String _jsonObject(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('```')) {
    final lines = trimmed.split('\n');
    return lines
        .skip(1)
        .takeWhile((line) => !line.trim().startsWith('```'))
        .join('\n');
  }
  return trimmed;
}
