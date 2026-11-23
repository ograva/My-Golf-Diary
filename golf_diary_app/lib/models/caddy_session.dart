/// Local + Firestore pairing record for a single round caddy session.
class CaddySessionRecord {
  const CaddySessionRecord({
    required this.channelId,
    required this.roundId,
    required this.requestToken,
    required this.status,
    required this.role,
    this.golferUid,
    this.caddyUid,
    this.courseName = '',
    this.createdAtMs = 0,
    this.redeemedAtMs = 0,
    this.lastEventMs = 0,
    this.expiresAtMs = 0,
  });

  final String channelId;
  final String roundId;
  final String requestToken;
  final CaddySessionStatus status;
  final CaddySessionRole role;
  final String? golferUid;
  final String? caddyUid;
  final String courseName;
  final int createdAtMs;
  final int redeemedAtMs;
  final int lastEventMs;
  final int expiresAtMs;

  bool get isActive => status == CaddySessionStatus.active;

  CaddySessionRecord copyWith({
    CaddySessionStatus? status,
    String? caddyUid,
    int? redeemedAtMs,
    int? lastEventMs,
  }) {
    return CaddySessionRecord(
      channelId: channelId,
      roundId: roundId,
      requestToken: requestToken,
      status: status ?? this.status,
      role: role,
      golferUid: golferUid,
      caddyUid: caddyUid ?? this.caddyUid,
      courseName: courseName,
      createdAtMs: createdAtMs,
      redeemedAtMs: redeemedAtMs ?? this.redeemedAtMs,
      lastEventMs: lastEventMs ?? this.lastEventMs,
      expiresAtMs: expiresAtMs,
    );
  }

  static CaddySessionRecord fromMap(Map<String, Object?> row) {
    return CaddySessionRecord(
      channelId: row['channel_id'] as String,
      roundId: row['round_id'] as String,
      requestToken: row['request_token'] as String,
      status: CaddySessionStatus.fromWire(row['status'] as String? ?? 'pending'),
      role: CaddySessionRole.fromWire(row['role'] as String? ?? 'golfer'),
      golferUid: row['golfer_uid'] as String?,
      caddyUid: row['caddy_uid'] as String?,
      courseName: row['course_name'] as String? ?? '',
      createdAtMs: row['created_at_ms'] as int? ?? 0,
      redeemedAtMs: row['redeemed_at_ms'] as int? ?? 0,
      lastEventMs: row['last_event_ms'] as int? ?? 0,
      expiresAtMs: row['expires_at_ms'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
        'channel_id': channelId,
        'round_id': roundId,
        'request_token': requestToken,
        'status': status.wire,
        'role': role.wire,
        'golfer_uid': golferUid,
        'caddy_uid': caddyUid,
        'course_name': courseName,
        'created_at_ms': createdAtMs,
        'redeemed_at_ms': redeemedAtMs,
        'last_event_ms': lastEventMs,
        'expires_at_ms': expiresAtMs,
      };
}

enum CaddySessionStatus {
  pending,
  active,
  revoked,
  ended;

  String get wire => name;

  static CaddySessionStatus fromWire(String value) {
    return CaddySessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CaddySessionStatus.pending,
    );
  }
}

enum CaddySessionRole {
  golfer,
  caddy;

  String get wire => name;

  static CaddySessionRole fromWire(String value) {
    return CaddySessionRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CaddySessionRole.golfer,
    );
  }
}

/// Append-only scoring event written by golfer or caddy to the round channel.
class CaddyRoundEvent {
  const CaddyRoundEvent({
    required this.id,
    required this.channelId,
    required this.roundId,
    required this.type,
    required this.holeNumber,
    required this.authorUid,
    required this.updatedAtMs,
    this.delta = 1,
    this.conceded = false,
    this.targetPlayerId,
    this.holeScore,
  });

  final String id;
  final String channelId;
  final String roundId;
  final CaddyEventType type;
  final int holeNumber;
  final String authorUid;
  final int updatedAtMs;
  final int delta;
  final bool conceded;
  final String? targetPlayerId;
  final int? holeScore;

  Map<String, Object?> toFirestore() => {
        'channel_id': channelId,
        'round_id': roundId,
        'type': type.wire,
        'hole_number': holeNumber,
        'author_uid': authorUid,
        'updated_at_ms': updatedAtMs,
        'updatedAtMs': updatedAtMs,
        'delta': delta,
        'conceded': conceded,
        'target_player_id': targetPlayerId,
        'hole_score': holeScore,
      };

  static CaddyRoundEvent fromFirestore(String id, Map<String, dynamic> data) {
    return CaddyRoundEvent(
      id: id,
      channelId: data['channel_id'] as String? ?? '',
      roundId: data['round_id'] as String? ?? '',
      type: CaddyEventType.fromWire(data['type'] as String? ?? 'stroke_add'),
      holeNumber: data['hole_number'] as int? ?? 1,
      authorUid: data['author_uid'] as String? ?? '',
      updatedAtMs: (data['updated_at_ms'] as int?) ??
          (data['updatedAtMs'] as int?) ??
          0,
      delta: data['delta'] as int? ?? 1,
      conceded: data['conceded'] == true,
      targetPlayerId: data['target_player_id'] as String?,
      holeScore: data['hole_score'] as int?,
    );
  }
}

enum CaddyEventType {
  strokeAdd,
  penaltyAdd,
  mulliganAdd,
  concede,
  revoke,
  setHoleScore,
  attestPlayerCard;

  String get wire => switch (this) {
        CaddyEventType.strokeAdd => 'stroke_add',
        CaddyEventType.penaltyAdd => 'penalty_add',
        CaddyEventType.mulliganAdd => 'mulligan_add',
        CaddyEventType.concede => 'concede',
        CaddyEventType.revoke => 'revoke',
        CaddyEventType.setHoleScore => 'set_hole_score',
        CaddyEventType.attestPlayerCard => 'attest_player_card',
      };

  static CaddyEventType fromWire(String value) {
    return switch (value) {
      'stroke_add' => CaddyEventType.strokeAdd,
      'penalty_add' => CaddyEventType.penaltyAdd,
      'mulligan_add' => CaddyEventType.mulliganAdd,
      'concede' => CaddyEventType.concede,
      'revoke' => CaddyEventType.revoke,
      'set_hole_score' => CaddyEventType.setHoleScore,
      'attest_player_card' => CaddyEventType.attestPlayerCard,
      _ => CaddyEventType.strokeAdd,
    };
  }
}