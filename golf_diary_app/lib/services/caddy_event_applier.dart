import '../data/ph_golf_catalog.dart';
import '../models/caddy_session.dart';
import 'local_database_service.dart';

/// Applies caddy channel events into golfer SQLite (stroke-derived scorecard).
class CaddyEventApplier {
  CaddyEventApplier({LocalDatabaseService? database})
      : _db = database ?? LocalDatabaseService.instance;

  final LocalDatabaseService _db;

  Future<void> apply(
    CaddyRoundEvent event, {
    required String courseName,
  }) async {
    switch (event.type) {
      case CaddyEventType.strokeAdd:
        await _db.recordCaddyStroke(
          roundId: event.roundId,
          holeNumber: event.holeNumber,
          courseName: courseName,
        );
      case CaddyEventType.penaltyAdd:
        await _db.incrementPenalties(
          event.roundId,
          event.holeNumber,
          event.delta,
        );
      case CaddyEventType.mulliganAdd:
        await _db.incrementMulligans(event.roundId, event.holeNumber);
      case CaddyEventType.concede:
        await _db.concedeHole(event.roundId, event.holeNumber);
      case CaddyEventType.revoke:
        break;
      case CaddyEventType.setHoleScore:
        if (_scoresAnotherPlayer(event)) {
          await _db.saveCaddyPlayerHole(
            channelId: event.channelId,
            playerId: event.targetPlayerId!,
            holeNumber: event.holeNumber,
            par: PhGolfCatalog.parForHole(courseName, event.holeNumber) ?? 4,
            gross: event.holeScore ?? event.delta,
          );
          break;
        }
        await _db.saveManualHoleScore(
          roundId: event.roundId,
          courseName: courseName,
          holeNumber: event.holeNumber,
          par: PhGolfCatalog.parForHole(courseName, event.holeNumber) ?? 4,
          strokes: event.holeScore ?? event.delta,
          penalties: 0,
          holeComplete: true,
        );
      case CaddyEventType.attestPlayerCard:
        if (_scoresAnotherPlayer(event)) break;
        await _db.attestRound(
          roundId: event.roundId,
          name: 'Caddy',
          role: 'caddy',
        );
    }
  }

  bool _scoresAnotherPlayer(CaddyRoundEvent event) {
    final target = event.targetPlayerId;
    return target != null && target.isNotEmpty && target != 'primary';
  }
}