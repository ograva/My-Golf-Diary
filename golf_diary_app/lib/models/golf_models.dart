class Club {
  final String id;
  final String name;
  final String category;
  final double minDistance;
  final double maxDistance;
  final double avgDistance;
  final String swingNotes;
  final int isSynced;

  Club({
    required this.id,
    required this.name,
    required this.category,
    this.minDistance = 0.0,
    this.maxDistance = 0.0,
    this.avgDistance = 0.0,
    this.swingNotes = '',
    this.isSynced = 0,
  });

  Club copyWith({
    String? name,
    String? category,
    double? minDistance,
    double? maxDistance,
    double? avgDistance,
    String? swingNotes,
    int? isSynced,
  }) {
    return Club(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      minDistance: minDistance ?? this.minDistance,
      maxDistance: maxDistance ?? this.maxDistance,
      avgDistance: avgDistance ?? this.avgDistance,
      swingNotes: swingNotes ?? this.swingNotes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'min_distance': minDistance,
      'max_distance': maxDistance,
      'avg_distance': avgDistance,
      'swing_notes': swingNotes,
      'is_synced': isSynced,
    };
  }

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      minDistance: (map['min_distance'] as num?)?.toDouble() ?? 0.0,
      maxDistance: (map['max_distance'] as num?)?.toDouble() ?? 0.0,
      avgDistance: (map['avg_distance'] as num?)?.toDouble() ?? 0.0,
      swingNotes: map['swing_notes'] as String? ?? '',
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}

class ShotRecord {
  final String id;
  final String roundId;
  final int holeNumber;
  final int strokeNumber;
  final String clubId;
  final String lieType;
  final double startLat;
  final double startLon;
  final double? endLat;
  final double? endLon;
  final double distanceYards;
  final String notes;
  final int timestamp;
  final int isSynced;

  ShotRecord({
    required this.id,
    required this.roundId,
    required this.holeNumber,
    required this.strokeNumber,
    required this.clubId,
    required this.lieType,
    required this.startLat,
    required this.startLon,
    this.endLat,
    this.endLon,
    this.distanceYards = 0.0,
    this.notes = '',
    required this.timestamp,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'round_id': roundId,
      'hole_number': holeNumber,
      'stroke_number': strokeNumber,
      'club_id': clubId,
      'lie_type': lieType,
      'start_lat': startLat,
      'start_lon': startLon,
      'end_lat': endLat,
      'end_lon': endLon,
      'distance_yards': distanceYards,
      'notes': notes,
      'timestamp': timestamp,
      'is_synced': isSynced,
    };
  }

  factory ShotRecord.fromMap(Map<String, dynamic> map) {
    return ShotRecord(
      id: map['id'] as String,
      roundId: map['round_id'] as String,
      holeNumber: map['hole_number'] as int,
      strokeNumber: map['stroke_number'] as int,
      clubId: map['club_id'] as String,
      lieType: map['lie_type'] as String,
      startLat: (map['start_lat'] as num).toDouble(),
      startLon: (map['start_lon'] as num).toDouble(),
      endLat: map['end_lat'] != null ? (map['end_lat'] as num).toDouble() : null,
      endLon: map['end_lon'] != null ? (map['end_lon'] as num).toDouble() : null,
      distanceYards: (map['distance_yards'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      timestamp: map['timestamp'] as int,
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}

class RoundScore {
  final String id;
  final String roundId;
  final String courseName;
  final int holeNumber;
  final int par;
  final int strokes;
  final int penalties;
  final int mulligans;
  final int conceded;
  final int finalScore;
  final int isSynced;

  RoundScore({
    required this.id,
    required this.roundId,
    required this.courseName,
    required this.holeNumber,
    required this.par,
    this.strokes = 0,
    this.penalties = 0,
    this.mulligans = 0,
    this.conceded = 0,
    this.finalScore = 0,
    this.isSynced = 0,
  });

  RoundScore copyWith({
    int? par,
    int? strokes,
    int? penalties,
    int? mulligans,
    int? conceded,
    int? finalScore,
    int? isSynced,
  }) {
    return RoundScore(
      id: id,
      roundId: roundId,
      courseName: courseName,
      holeNumber: holeNumber,
      par: par ?? this.par,
      strokes: strokes ?? this.strokes,
      penalties: penalties ?? this.penalties,
      mulligans: mulligans ?? this.mulligans,
      conceded: conceded ?? this.conceded,
      finalScore: finalScore ?? this.finalScore,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'round_id': roundId,
      'course_name': courseName,
      'hole_number': holeNumber,
      'par': par,
      'strokes': strokes,
      'penalties': penalties,
      'mulligans': mulligans,
      'conceded': conceded,
      'final_score': finalScore,
      'is_synced': isSynced,
    };
  }

  factory RoundScore.fromMap(Map<String, dynamic> map) {
    return RoundScore(
      id: map['id'] as String,
      roundId: map['round_id'] as String,
      courseName: map['course_name'] as String,
      holeNumber: map['hole_number'] as int,
      par: map['par'] as int,
      strokes: map['strokes'] as int? ?? 0,
      penalties: map['penalties'] as int? ?? 0,
      mulligans: map['mulligans'] as int? ?? 0,
      conceded: map['conceded'] as int? ?? 0,
      finalScore: map['final_score'] as int? ?? 0,
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}

class RangeDrillLog {
  final String id;
  final String clubId;
  final int shotCount;
  final double minYards;
  final double maxYards;
  final double avgYards;
  final String tempoNotes;
  final int timestamp;
  final int isSynced;

  RangeDrillLog({
    required this.id,
    required this.clubId,
    required this.shotCount,
    required this.minYards,
    required this.maxYards,
    required this.avgYards,
    this.tempoNotes = '',
    required this.timestamp,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'club_id': clubId,
      'shot_count': shotCount,
      'min_yards': minYards,
      'max_yards': maxYards,
      'avg_yards': avgYards,
      'tempo_notes': tempoNotes,
      'timestamp': timestamp,
      'is_synced': isSynced,
    };
  }

  factory RangeDrillLog.fromMap(Map<String, dynamic> map) {
    return RangeDrillLog(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      shotCount: map['shot_count'] as int,
      minYards: (map['min_yards'] as num).toDouble(),
      maxYards: (map['max_yards'] as num).toDouble(),
      avgYards: (map['avg_yards'] as num).toDouble(),
      tempoNotes: map['tempo_notes'] as String? ?? '',
      timestamp: map['timestamp'] as int,
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}

/// Gross score for a hole: tracked strokes plus penalty strokes.
int computeFinalScore({required int strokes, required int penalties}) {
  return strokes + penalties;
}
