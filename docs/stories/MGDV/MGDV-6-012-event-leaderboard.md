# MGDV-6-012 — Event-scoped leaderboard

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6-012 |
| **Module** | MGDV |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | [MGDV-6-012](../../shards/MGDV/MGDV-6-012-event-leaderboard.md) |
| **PRD** | [PRD §3 MGDV-6-012](../../context/PRD.md) |
| **Epic** | [MGDV-6 club tournament pilot](MGDV-6-club-tournament-pilot.md) |
| **Depends on** | [MGDV-6-010](MGDV-6-010-club-tournament-enrollment.md), [MGDV-601](MGDV-601-scoring-formats-epic.md) |

## User story

As **a flight member**, I want **standings in my tournament** in the event’s format so **we see order of play without a public social network**.

## Acceptance criteria

1. Leaderboard shows **only players enrolled in the same event**; sort by active format total (Molave points, System 36 net, or gross).
2. Updates when a player **publishes** from flight channel or committee **imports** attested card — no live shot stream.
3. Mismatch / edited-after-attest surfaced as audit state, not silent overwrite.
4. Not a global or friend-graph leaderboard (see PRD §6).
5. Readable offline from last sync snapshot with stale banner.

## Widget keys / telemetry

- TBD — `tournament-leaderboard`, stale-sync banner.

## Notes

Firestore vs SQLite source of standings is an Architecture decision; UI must not imply a social graph.