import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/caddy_session.dart';
import 'sync_constants.dart';

abstract class CaddyRoundChannelStore {
  Future<void> createChannel({
    required String channelId,
    required String golferUid,
    required String roundId,
    required String courseName,
    required int expiresAtMs,
  });

  Future<Map<String, dynamic>?> readChannel(String channelId);

  Future<bool> redeemChannel({
    required String channelId,
    required String caddyUid,
  });

  Future<void> updateChannelStatus(String channelId, String status);

  Future<void> appendEvent(String channelId, CaddyRoundEvent event);

  Stream<List<CaddyRoundEvent>> watchEvents(
    String channelId, {
    required int afterUpdatedAtMs,
  });

  Future<List<CaddyRoundEvent>> listEventsAfter(
    String channelId,
    int afterUpdatedAtMs,
  );

  Future<void> flushPendingEvents(
    String channelId,
    List<CaddyRoundEvent> queued,
  );
}

class FirestoreCaddyRoundChannelStore implements CaddyRoundChannelStore {
  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: kFirestoreDatabaseId,
      );

  CollectionReference<Map<String, dynamic>> _channels() =>
      _firestore.collection('caddy_round_channels');

  CollectionReference<Map<String, dynamic>> _events(String channelId) =>
      _channels().doc(channelId).collection('events');

  @override
  Future<void> createChannel({
    required String channelId,
    required String golferUid,
    required String roundId,
    required String courseName,
    required int expiresAtMs,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _channels().doc(channelId).set({
      'channel_id': channelId,
      'request_token': channelId,
      'golfer_uid': golferUid,
      'round_id': roundId,
      'course_name': courseName,
      'status': 'pending',
      'expires_at_ms': expiresAtMs,
      'created_at_ms': now,
      'updated_at_ms': now,
    });
  }

  @override
  Future<Map<String, dynamic>?> readChannel(String channelId) async {
    final doc = await _channels().doc(channelId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Future<bool> redeemChannel({
    required String channelId,
    required String caddyUid,
  }) async {
    final ref = _channels().doc(channelId);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      final status = data['status'] as String? ?? 'pending';
      final expires = data['expires_at_ms'] as int? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (status != 'pending') return status == 'active';
      if (expires > 0 && now > expires) return false;
      tx.update(ref, {
        'status': 'active',
        'caddy_uid': caddyUid,
        'redeemed_at_ms': now,
        'updated_at_ms': now,
      });
      return true;
    });
  }

  @override
  Future<void> updateChannelStatus(String channelId, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _channels().doc(channelId).update({
      'status': status,
      'updated_at_ms': now,
    });
  }

  @override
  Future<void> appendEvent(String channelId, CaddyRoundEvent event) async {
    await _events(channelId).doc(event.id).set(event.toFirestore());
  }

  @override
  Stream<List<CaddyRoundEvent>> watchEvents(
    String channelId, {
    required int afterUpdatedAtMs,
  }) {
    return _events(channelId)
        .where('updated_at_ms', isGreaterThan: afterUpdatedAtMs)
        .orderBy('updated_at_ms')
        .snapshots()
        .map((snap) => [
              for (final doc in snap.docs)
                CaddyRoundEvent.fromFirestore(doc.id, doc.data()),
            ]);
  }

  @override
  Future<List<CaddyRoundEvent>> listEventsAfter(
    String channelId,
    int afterUpdatedAtMs,
  ) async {
    final snap = await _events(channelId)
        .where('updated_at_ms', isGreaterThan: afterUpdatedAtMs)
        .orderBy('updated_at_ms')
        .get();
    return [
      for (final doc in snap.docs)
        CaddyRoundEvent.fromFirestore(doc.id, doc.data()),
    ];
  }

  @override
  Future<void> flushPendingEvents(
    String channelId,
    List<CaddyRoundEvent> queued,
  ) async {
    for (final event in queued) {
      await appendEvent(channelId, event);
    }
  }
}

/// In-memory store for unit tests and offline-only demos.
class MemoryCaddyRoundChannelStore implements CaddyRoundChannelStore {
  final Map<String, Map<String, dynamic>> channels = {};
  final Map<String, Map<String, CaddyRoundEvent>> events = {};

  @override
  Future<void> createChannel({
    required String channelId,
    required String golferUid,
    required String roundId,
    required String courseName,
    required int expiresAtMs,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    channels[channelId] = {
      'channel_id': channelId,
      'request_token': channelId,
      'golfer_uid': golferUid,
      'round_id': roundId,
      'course_name': courseName,
      'status': 'pending',
      'expires_at_ms': expiresAtMs,
      'created_at_ms': now,
      'updated_at_ms': now,
    };
  }

  @override
  Future<Map<String, dynamic>?> readChannel(String channelId) async {
    return channels[channelId];
  }

  @override
  Future<bool> redeemChannel({
    required String channelId,
    required String caddyUid,
  }) async {
    final data = channels[channelId];
    if (data == null) return false;
    final status = data['status'] as String;
    if (status == 'active') return true;
    if (status != 'pending') return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    data['status'] = 'active';
    data['caddy_uid'] = caddyUid;
    data['redeemed_at_ms'] = now;
    data['updated_at_ms'] = now;
    return true;
  }

  @override
  Future<void> updateChannelStatus(String channelId, String status) async {
    final data = channels[channelId];
    if (data == null) return;
    data['status'] = status;
    data['updated_at_ms'] = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Future<void> appendEvent(String channelId, CaddyRoundEvent event) async {
    events.putIfAbsent(channelId, () => {});
    events[channelId]![event.id] = event;
  }

  @override
  Stream<List<CaddyRoundEvent>> watchEvents(
    String channelId, {
    required int afterUpdatedAtMs,
  }) async* {
    yield await listEventsAfter(channelId, afterUpdatedAtMs);
  }

  @override
  Future<List<CaddyRoundEvent>> listEventsAfter(
    String channelId,
    int afterUpdatedAtMs,
  ) async {
    final map = events[channelId];
    if (map == null) return [];
    return map.values
        .where((e) => e.updatedAtMs > afterUpdatedAtMs)
        .toList()
      ..sort((a, b) => a.updatedAtMs.compareTo(b.updatedAtMs));
  }

  @override
  Future<void> flushPendingEvents(
    String channelId,
    List<CaddyRoundEvent> queued,
  ) async {
    for (final event in queued) {
      await appendEvent(channelId, event);
    }
  }
}