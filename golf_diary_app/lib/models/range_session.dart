import 'dart:convert';

/// One club block frozen into a compiled range session.
class RangeSessionBlock {
  const RangeSessionBlock({
    required this.clubId,
    required this.clubName,
    required this.shotCount,
    required this.minYards,
    required this.avgYards,
    required this.maxYards,
    required this.tempoNotes,
    this.drillId,
    this.drillTitle,
    this.drillSteps = const [],
  });

  final String clubId;
  final String clubName;
  final int shotCount;
  final double minYards;
  final double avgYards;
  final double maxYards;
  final String tempoNotes;
  final String? drillId;
  final String? drillTitle;
  final List<String> drillSteps;

  Map<String, Object?> toJson() => {
        'clubId': clubId,
        'clubName': clubName,
        'shotCount': shotCount,
        'minYards': minYards,
        'avgYards': avgYards,
        'maxYards': maxYards,
        'tempoNotes': tempoNotes,
        'drillId': drillId,
        'drillTitle': drillTitle,
        'drillSteps': drillSteps,
      };

  factory RangeSessionBlock.fromJson(Map<String, Object?> json) {
    final steps = json['drillSteps'];
    return RangeSessionBlock(
      clubId: json['clubId'] as String? ?? '',
      clubName: json['clubName'] as String? ?? '',
      shotCount: (json['shotCount'] as num?)?.toInt() ?? 0,
      minYards: (json['minYards'] as num?)?.toDouble() ?? 0,
      avgYards: (json['avgYards'] as num?)?.toDouble() ?? 0,
      maxYards: (json['maxYards'] as num?)?.toDouble() ?? 0,
      tempoNotes: json['tempoNotes'] as String? ?? '',
      drillId: json['drillId'] as String?,
      drillTitle: json['drillTitle'] as String?,
      drillSteps: steps is List
          ? [for (final step in steps) step.toString()]
          : const [],
    );
  }
}

/// A visit compiled from unlinked club blocks and an optional session note.
class RangeSession {
  const RangeSession({
    required this.id,
    required this.venueName,
    required this.sessionNote,
    required this.blocks,
    required this.timestamp,
  });

  final String id;
  final String venueName;
  final String sessionNote;
  final List<RangeSessionBlock> blocks;
  final int timestamp;

  bool includesClub(String clubId) =>
      blocks.any((block) => block.clubId == clubId);

  factory RangeSession.fromMap(Map<String, Object?> map) {
    final raw = map['compiled_summary_json'] as String? ?? '[]';
    final decoded = jsonDecode(raw);
    final blocks = decoded is List
        ? [
            for (final item in decoded)
              if (item is Map)
                RangeSessionBlock.fromJson(Map<String, Object?>.from(item)),
          ]
        : <RangeSessionBlock>[];
    return RangeSession(
      id: map['id'] as String,
      venueName: map['venue_name'] as String? ?? '',
      sessionNote: map['session_note'] as String? ?? '',
      blocks: blocks,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }
}
