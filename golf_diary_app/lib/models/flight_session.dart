/// One player's published card inside a flight.
class FlightPlayerScore {
  const FlightPlayerScore({
    required this.playerId,
    required this.displayName,
    required this.roundId,
    required this.holeGross,
    required this.updatedAtMs,
    this.attestedAtMs,
    this.attestedByName = '',
    this.attestedHoleGross = const [],
  });

  final String playerId;
  final String displayName;
  final String roundId;
  final List<int> holeGross;
  final int updatedAtMs;
  final int? attestedAtMs;
  final String attestedByName;
  final List<int> attestedHoleGross;

  bool get isAttested => (attestedAtMs ?? 0) > 0;

  bool get mismatchesAttestation {
    if (!isAttested || attestedHoleGross.isEmpty) return false;
    if (attestedHoleGross.length != holeGross.length) return true;
    for (var i = 0; i < holeGross.length; i++) {
      if (holeGross[i] != attestedHoleGross[i]) return true;
    }
    return false;
  }

  int get total => holeGross.fold(0, (sum, hole) => sum + hole);

  FlightPlayerScore copyWith({
    String? displayName,
    List<int>? holeGross,
    int? updatedAtMs,
    int? attestedAtMs,
    String? attestedByName,
    List<int>? attestedHoleGross,
    bool clearAttestation = false,
  }) {
    return FlightPlayerScore(
      playerId: playerId,
      displayName: displayName ?? this.displayName,
      roundId: roundId,
      holeGross: holeGross ?? this.holeGross,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      attestedAtMs:
          clearAttestation ? null : (attestedAtMs ?? this.attestedAtMs),
      attestedByName: attestedByName ?? this.attestedByName,
      attestedHoleGross: clearAttestation
          ? const []
          : (attestedHoleGross ?? this.attestedHoleGross),
    );
  }

  Map<String, Object?> toMap() => {
        'player_id': playerId,
        'display_name': displayName,
        'round_id': roundId,
        'hole_gross': holeGross,
        'updated_at_ms': updatedAtMs,
        'attested_at_ms': attestedAtMs,
        'attested_by_name': attestedByName,
        'attested_hole_gross': attestedHoleGross,
      };

  static FlightPlayerScore fromMap(Map<String, dynamic> map) {
    return FlightPlayerScore(
      playerId: map['player_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      roundId: map['round_id'] as String? ?? '',
      holeGross: [
        for (final value in (map['hole_gross'] as List?) ?? const [])
          (value as num).toInt(),
      ],
      updatedAtMs: map['updated_at_ms'] as int? ?? 0,
      attestedAtMs: map['attested_at_ms'] as int?,
      attestedByName: map['attested_by_name'] as String? ?? '',
      attestedHoleGross: [
        for (final value in (map['attested_hole_gross'] as List?) ?? const [])
          (value as num).toInt(),
      ],
    );
  }
}

class FlightSnapshot {
  const FlightSnapshot({
    required this.flightId,
    required this.hostUid,
    required this.courseName,
    required this.format,
    required this.players,
    this.status = 'open',
  });

  final String flightId;
  final String hostUid;
  final String courseName;
  final String format;
  final String status;
  final List<FlightPlayerScore> players;

  FlightSnapshot copyWith({
    List<FlightPlayerScore>? players,
    String? status,
  }) {
    return FlightSnapshot(
      flightId: flightId,
      hostUid: hostUid,
      courseName: courseName,
      format: format,
      status: status ?? this.status,
      players: players ?? this.players,
    );
  }

  Map<String, Object?> toMap() => {
        'flight_id': flightId,
        'host_uid': hostUid,
        'course_name': courseName,
        'scoring_format': format,
        'status': status,
        'players': [for (final player in players) player.toMap()],
      };

  static FlightSnapshot fromMap(Map<String, dynamic> map) {
    final rawPlayers = (map['players'] as List?) ?? const [];
    return FlightSnapshot(
      flightId: map['flight_id'] as String? ?? '',
      hostUid: map['host_uid'] as String? ?? '',
      courseName: map['course_name'] as String? ?? '',
      format: map['scoring_format'] as String? ?? 'gross',
      status: map['status'] as String? ?? 'open',
      players: [
        for (final player in rawPlayers)
          FlightPlayerScore.fromMap(Map<String, dynamic>.from(player as Map)),
      ],
    );
  }
}
