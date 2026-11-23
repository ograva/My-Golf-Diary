import 'dart:math';

import 'package:firebase_core/firebase_core.dart';

import '../models/caddy_session.dart';
import 'caddy_round_channel_store.dart';
import 'local_database_service.dart';
import 'sync_identity.dart';

/// Mint QR tokens, redeem caddy sessions, and publish round events.
class CaddyPairingService {
  CaddyPairingService({
    LocalDatabaseService? database,
    CaddyRoundChannelStore? channelStore,
  })  : _db = database ?? LocalDatabaseService.instance,
        _channelStore = channelStore ?? _defaultStore();

  final LocalDatabaseService _db;
  final CaddyRoundChannelStore _channelStore;

  static const _sessionTtlMs = 8 * 60 * 60 * 1000;

  static CaddyRoundChannelStore _defaultStore() {
    if (Firebase.apps.isEmpty) {
      return MemoryCaddyRoundChannelStore();
    }
    return FirestoreCaddyRoundChannelStore();
  }

  static String _opaqueToken() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  Future<CaddySessionRecord?> getGolferActiveSession() =>
      _db.getActiveCaddySessionForGolfer();

  Future<CaddySessionRecord?> getCaddyActiveSession() =>
      _db.getActiveCaddySessionForCaddy();

  /// Golfer mints single-use channel + local session row.
  Future<CaddySessionRecord> mintInvite({
    required String roundId,
    required String courseName,
  }) async {
    final uid =
        await SyncIdentity.ensureSignedIn() ?? (Firebase.apps.isEmpty ? 'local_golfer' : null);
    if (uid == null) {
      throw StateError('Sign in required to invite a caddy');
    }
    final channelId = _opaqueToken();
    final now = DateTime.now().millisecondsSinceEpoch;
  final expiresAt = now + _sessionTtlMs;

    await _channelStore.createChannel(
      channelId: channelId,
      golferUid: uid,
      roundId: roundId,
      courseName: courseName,
      expiresAtMs: expiresAt,
    );

    final session = CaddySessionRecord(
      channelId: channelId,
      roundId: roundId,
      requestToken: channelId,
      status: CaddySessionStatus.pending,
      role: CaddySessionRole.golfer,
      golferUid: uid,
      courseName: courseName,
      createdAtMs: now,
      expiresAtMs: expiresAt,
    );
    await _db.upsertCaddySession(session);
    return session;
  }

  /// Caddy redeems QR token (single-use → active).
  Future<CaddySessionRecord?> redeemInvite(String requestToken) async {
    final uid =
        await SyncIdentity.ensureSignedIn() ?? (Firebase.apps.isEmpty ? 'local_caddy' : null);
    if (uid == null) return null;
    final channelId = requestToken.trim();
    final channel = await _channelStore.readChannel(channelId);
    if (channel == null) return null;

    final redeemed = await _channelStore.redeemChannel(
      channelId: channelId,
      caddyUid: uid,
    );
    if (!redeemed) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final session = CaddySessionRecord(
      channelId: channelId,
      roundId: channel['round_id'] as String,
      requestToken: channelId,
      status: CaddySessionStatus.active,
      role: CaddySessionRole.caddy,
      golferUid: channel['golfer_uid'] as String?,
      caddyUid: uid,
      courseName: channel['course_name'] as String? ?? '',
      createdAtMs: channel['created_at_ms'] as int? ?? now,
      redeemedAtMs: now,
      expiresAtMs: channel['expires_at_ms'] as int? ?? 0,
    );
    await _db.upsertCaddySession(session);
    return session;
  }

  Future<void> revokeSession(String channelId) async {
    await _channelStore.updateChannelStatus(channelId, 'revoked');
    await _db.updateCaddySessionStatus(channelId, CaddySessionStatus.revoked);
    final uid = SyncIdentity.currentUserId ?? 'golfer';
    await publishEvent(
      channelId: channelId,
      roundId: (await _db.getCaddySession(channelId))?.roundId ?? '',
      type: CaddyEventType.revoke,
      holeNumber: 1,
      authorUid: uid,
    );
  }

  Future<CaddyRoundEvent> publishEvent({
    required String channelId,
    required String roundId,
    required CaddyEventType type,
    required int holeNumber,
    required String authorUid,
    int delta = 1,
    bool conceded = false,
    String? targetPlayerId,
    int? holeScore,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final event = CaddyRoundEvent(
      id: 'cev_${now}_${Random().nextInt(9999)}',
      channelId: channelId,
      roundId: roundId,
      type: type,
      holeNumber: holeNumber,
      authorUid: authorUid,
      updatedAtMs: now,
      delta: delta,
      conceded: conceded,
      targetPlayerId: targetPlayerId,
      holeScore: holeScore,
    );

    try {
      await _channelStore.appendEvent(channelId, event);
    } catch (_) {
      await _db.queueCaddyPendingEvent(channelId, event);
    }
    await _db.setCaddySessionLastEventMs(channelId, now);
    return event;
  }

  Future<void> flushOfflineQueue(String channelId) async {
    final queued = await _db.takeCaddyPendingEvents(channelId);
    if (queued.isEmpty) return;
    await _channelStore.flushPendingEvents(channelId, queued);
  }

  Stream<List<CaddyRoundEvent>> watchGolferEvents(CaddySessionRecord session) {
    return _channelStore.watchEvents(
      session.channelId,
      afterUpdatedAtMs: session.lastEventMs,
    );
  }

  Future<List<CaddyRoundEvent>> pullEvents(CaddySessionRecord session) =>
      _channelStore.listEventsAfter(
        session.channelId,
        session.lastEventMs,
      );
}