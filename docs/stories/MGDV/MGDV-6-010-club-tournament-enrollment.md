# MGDV-6-010 — Club tournament enrollment (pilot)

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6-010 |
| **Module** | MGDV |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | [MGDV-6-010](../../shards/MGDV/MGDV-6-010-club-tournament-enrollment.md) |
| **PRD** | [PRD §3 MGDV-6-010](../../context/PRD.md) |
| **Epic** | [MGDV-6 club tournament pilot](MGDV-6-club-tournament-pilot.md) |

## User story

As **Rory** at **Club Intramuros**, I want **to enroll in a posted club tournament** from the app so **my diary round is tied to that event** without giving up local-first play.

## Acceptance criteria

1. Tournament list shows **pilot** events only (seed or Firestore doc per Architecture); each event shows name, date, course, **locked scoring format**, and fee copy when configured.
2. **Enroll** requires a **durable account** (Google or email per `SYNC-006`) — aligns with ProjectBrief “anonymous until tournament enrollment.”
3. Enrolling creates a local `tournament_enrollment` row linking `userId`, `eventId`, and optional flight assignment; play remains offline until publish/sync.
4. Golfer can **withdraw** before committee lock with confirm; withdrawn rounds stay personal-only.

## Widget keys / telemetry

- TBD — Eunice: tournament list, event detail, enroll/withdraw (see [Design_Audit](../../context/designs/Design_Audit.md)).

## Notes

Depends on Watson `tournament_*` schema and enrollment auth in Architecture §8. Not Gscore back-office.