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
    }
  }
}