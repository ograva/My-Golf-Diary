import 'dart:math';

import '../models/flight_session.dart';
import '../models/golf_models.dart';
import '../models/scoring_format.dart';
import 'flight_channel_store.dart';
import 'local_database_service.dart';
import 'sync_identity.dart';

/// Hosts and joins a flight without merging private shots or diary threads.
class FlightService {
  FlightService({
    LocalDatabaseService? database,
    FlightChannelStore? store,
  })  : _db = database ?? LocalDatabaseService.instance,
        _store = store ?? defaultFlightStore();

  final LocalDatabaseService _db;
  final FlightChannelStore _store;

  static String opaqueToken() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(24, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  Future<FlightSnapshot> mintFlight({
    required String roundId,
    required String courseName,
    required ScoringFormat format,
    required String displayName,
  }) async {
    final host = SyncIdentity.currentUserId ?? 'local_golfer';
    final flight = FlightSnapshot(
      flightId: opaqueToken(),
      hostUid: host,
      courseName: courseName,
      format: format.storageValue,
      players: [
        await _playerFromRound(
          playerId: host,
          displayName: displayName,
          roundId: roundId,
        ),
      ],
    );
    await _store.saveFlight(flight);
    return flight;
  }

  Future<FlightSnapshot?> joinFlight({
    required String flightId,
    required String roundId,
    required String displayName,
  }) async {
    final flight = await _store.readFlight(flightId);
    if (flight == null || flight.players.length >= 4) return flight;
    final playerId = SyncIdentity.currentUserId ?? 'local_${opaqueToken()}';
    if (flight.players.any((player) => player.playerId == playerId)) {
      return flight;
    }
    final next = flight.copyWith(
      players: [
        ...flight.players,
        await _playerFromRound(
          playerId: playerId,
          displayName: displayName,
          roundId: roundId,
        ),
      ],
    );
    await _store.saveFlight(next);
    return next;
  }

  Future<FlightSnapshot?> publishRound({
    required String flightId,
    required String playerId,
    required String roundId,
    required String displayName,
  }) async {
    final flight = await _store.readFlight(flightId);
    if (flight == null) return null;
    final published = await _playerFromRound(
      playerId: playerId,
      displayName: displayName,
      roundId: roundId,
    );
    final players = [
      for (final player in flight.players)
        if (player.playerId == playerId)
          published.copyWith(
            attestedAtMs: player.attestedAtMs,
            attestedByName: player.attestedByName,
            attestedHoleGross: player.attestedHoleGross,
          )
        else
          player,
    ];
    if (!players.any((player) => player.playerId == playerId)) {
      players.add(published);
    }
    final next = flight.copyWith(players: players);
    await _store.saveFlight(next);
    return next;
  }

  /// A playing partner locks another card. Later hole edits show as a mismatch.
  Future<FlightSnapshot?> attestPlayer({
    required String flightId,
    required String playerId,
    required String attestorName,
  }) async {
    final flight = await _store.readFlight(flightId);
    if (flight == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final players = [
      for (final player in flight.players)
        if (player.playerId == playerId)
          player.copyWith(
            attestedAtMs: now,
            attestedByName: attestorName,
            attestedHoleGross: List<int>.from(player.holeGross),
          )
        else
          player,
    ];
    final next = flight.copyWith(players: players);
    await _store.saveFlight(next);
    return next;
  }

  Future<FlightPlayerScore> _playerFromRound({
    required String playerId,
    required String displayName,
    required String roundId,
  }) async {
    final holes = await _db.getScoresForRound(roundId);
    final byHole = {for (final hole in holes) hole.holeNumber: hole};
    final gross = <int>[];
    for (var n = 1; n <= 18; n++) {
      final hole = byHole[n];
      if (hole == null || !isHolePlayed(hole)) {
        gross.add(0);
      } else {
        gross.add(effectiveHoleScore(hole));
      }
    }
    return FlightPlayerScore(
      playerId: playerId,
      displayName: displayName,
      roundId: roundId,
      holeGross: gross,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
