class Club {
  final String id;
  final String name;
  final String category;
  final String brand;
  final String model;
  final double minDistance;
  final double maxDistance;
  final double avgDistance;
  final String swingNotes;
  final int isSynced;

  Club({
    required this.id,
    required this.name,
    required this.category,
    this.brand = '',
    this.model = '',
    this.minDistance = 0.0,
    this.maxDistance = 0.0,
    this.avgDistance = 0.0,
    this.swingNotes = '',
    this.isSynced = 0,
  });

  Club copyWith({
    String? name,
    String? category,
    String? brand,
    String? model,
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
      brand: brand ?? this.brand,
      model: model ?? this.model,
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
      'brand': brand,
      'model': model,
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
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
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
      endLat:
          map['end_lat'] != null ? (map['end_lat'] as num).toDouble() : null,
      endLon:
          map['end_lon'] != null ? (map['end_lon'] as num).toDouble() : null,
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
  final String venueName;
  final int timestamp;
  final int isSynced;
  final String? drillId;

  RangeDrillLog({
    required this.id,
    required this.clubId,
    required this.shotCount,
    required this.minYards,
    required this.maxYards,
    required this.avgYards,
    this.tempoNotes = '',
    this.venueName = '',
    required this.timestamp,
    this.isSynced = 0,
    this.drillId,
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
      'venue_name': venueName,
      'timestamp': timestamp,
      'is_synced': isSynced,
      'drill_id': drillId,
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
      venueName: map['venue_name'] as String? ?? '',
      timestamp: map['timestamp'] as int,
      isSynced: map['is_synced'] as int? ?? 0,
      drillId: map['drill_id'] as String?,
    );
  }
}

/// A saved range session plus the club name shown in the chronological log.
class RangeDrillSummary {
  const RangeDrillSummary({required this.drill, required this.clubName});

  final RangeDrillLog drill;
  final String clubName;
}

/// Gross score for a hole: tracked strokes plus penalty strokes.
int computeFinalScore({required int strokes, required int penalties}) {
  return strokes + penalties;
}

/// Score shown on the scorecard: finalized holes use [RoundScore.finalScore].
int effectiveHoleScore(RoundScore hole) {
  if (hole.finalScore > 0) return hole.finalScore;
  return computeFinalScore(strokes: hole.strokes, penalties: hole.penalties);
}

bool isHolePlayed(RoundScore hole) {
  return hole.finalScore > 0 || hole.strokes > 0 || hole.conceded == 1;
}

/// Compares two [Club]s in standard golf bag order:
/// Driver first, then woods numbered incrementally, hybrids numbered
/// incrementally, irons 2–9+, wedges (pitching, gap, sand, lob), other, and
/// putter last after all.
int compareClubs(Club a, Club b) {
  return _ClubSortKey.fromClub(a).compareTo(_ClubSortKey.fromClub(b));
}

/// Returns a new list of [clubs] sorted in intuitive golf bag order.
List<Club> sortClubs(Iterable<Club> clubs) {
  final sorted = clubs.toList();
  sorted.sort(compareClubs);
  return sorted;
}

class _ClubSortKey implements Comparable<_ClubSortKey> {
  const _ClubSortKey({
    required this.groupRank,
    required this.primaryRank,
    required this.secondaryRank,
    required this.normalizedName,
    required this.id,
  });

  factory _ClubSortKey.fromClub(Club club) {
    final lower = club.name.trim().toLowerCase();
    final category = club.category.trim().toLowerCase();

    final isPutter =
        category == 'putter' || RegExp(r'\bputter\b').hasMatch(lower);
    final isMiniDriver = RegExp(r'\bmini\s*-?\s*driver\b').hasMatch(lower);
    final isDriver = !isMiniDriver &&
        (lower == 'driver' ||
            lower == 'dr' ||
            RegExp(r'^1\s*-?\s*(?:w|wood)\b').hasMatch(lower) ||
            RegExp(r'\bdriver\b').hasMatch(lower));

    final int groupRank;
    if (isPutter) {
      groupRank = 5;
    } else if (isDriver || isMiniDriver || category == 'wood') {
      groupRank = 0;
    } else if (category == 'hybrid') {
      groupRank = 1;
    } else if (category == 'iron') {
      groupRank = 2;
    } else if (category == 'wedge') {
      groupRank = 3;
    } else {
      groupRank = 4;
    }

    if (isDriver) {
      return _ClubSortKey(
        groupRank: groupRank,
        primaryRank: 0.0,
        secondaryRank: 0.0,
        normalizedName: lower,
        id: club.id,
      );
    }

    if (isMiniDriver) {
      return _ClubSortKey(
        groupRank: groupRank,
        primaryRank: 0.5,
        secondaryRank: 0.0,
        normalizedName: lower,
        id: club.id,
      );
    }

    final wedgeRank = _wedgeTypeRank(lower);
    if (wedgeRank != null) {
      return _ClubSortKey(
        groupRank: groupRank,
        primaryRank: wedgeRank,
        secondaryRank: _extractClubNumber(lower) ?? 0.0,
        normalizedName: lower,
        id: club.id,
      );
    }

    final number = _extractClubNumber(lower);
    if (number != null) {
      return _ClubSortKey(
        groupRank: groupRank,
        primaryRank: number,
        secondaryRank: category == 'wedge' ? 1.0 : 0.0,
        normalizedName: lower,
        id: club.id,
      );
    }

    return _ClubSortKey(
      groupRank: groupRank,
      primaryRank: 999.0,
      secondaryRank: 0.0,
      normalizedName: lower,
      id: club.id,
    );
  }

  final int groupRank;
  final double primaryRank;
  final double secondaryRank;
  final String normalizedName;
  final String id;

  static double? _wedgeTypeRank(String lower) {
    if (RegExp(r'\b(pitching|pw|p\s*-?\s*wedge)\b').hasMatch(lower) ||
        lower == 'p') {
      return 46.0;
    }
    if (RegExp(r'\b(gap|gw|g\s*-?\s*wedge|approach|aw|a\s*-?\s*wedge|attack|uw|u\s*-?\s*wedge|utility\s+wedge)\b')
            .hasMatch(lower) ||
        lower == 'g' ||
        lower == 'a') {
      return 51.0;
    }
    if (RegExp(r'\b(sand|sw|s\s*-?\s*wedge)\b').hasMatch(lower) ||
        lower == 's') {
      return 55.0;
    }
    if (RegExp(r'\b(lob|lw|l\s*-?\s*wedge)\b').hasMatch(lower) ||
        lower == 'l') {
      return 59.5;
    }
    return null;
  }

  static const _wordNumbers = <String, double>{
    'one': 1.0,
    'two': 2.0,
    'three': 3.0,
    'four': 4.0,
    'five': 5.0,
    'six': 6.0,
    'seven': 7.0,
    'eight': 8.0,
    'nine': 9.0,
    'ten': 10.0,
    'eleven': 11.0,
  };

  static double? _extractClubNumber(String lower) {
    final digitMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    if (digitMatch != null) {
      final value = double.tryParse(digitMatch.group(1)!);
      if (value != null) {
        final isHighLaunch =
            RegExp(r'\b\d+\s*(?:hl|high\s+launch)\b').hasMatch(lower);
        return isHighLaunch ? value + 0.5 : value;
      }
    }
    for (final entry in _wordNumbers.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(lower)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  int compareTo(_ClubSortKey other) {
    final groupCmp = groupRank.compareTo(other.groupRank);
    if (groupCmp != 0) return groupCmp;
    final primaryCmp = primaryRank.compareTo(other.primaryRank);
    if (primaryCmp != 0) return primaryCmp;
    final secondaryCmp = secondaryRank.compareTo(other.secondaryRank);
    if (secondaryCmp != 0) return secondaryCmp;
    final nameCmp = normalizedName.compareTo(other.normalizedName);
    if (nameCmp != 0) return nameCmp;
    return id.compareTo(other.id);
  }
}
