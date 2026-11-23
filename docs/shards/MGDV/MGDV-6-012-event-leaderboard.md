# SHARD-MGDV-6-012: Event-scoped leaderboard

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-012 |
| **Epic** | MGDV-6 |
| **Module** | MGDV |
| **Story Ref** | MGDV-6-012 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | MGDV-6-010, MGDV-601 |

## Description

Players enrolled in the same pilot event see standings sorted in the event’s active format. Standings update from flight publish or committee import — not from live shot streams — and surface audit states for mismatch or edited-after-attest.

## Acceptance Criteria

- [ ] Leaderboard lists **only** enrollees for the active `eventId`; sort by Molave points, System 36 net, or gross per event format.
- [ ] Row updates when a player publishes flight hole summaries or committee imports an attested card (no sub-second live feed).
- [ ] **Edited-after-attest** and partner mismatch show as audit badges; no silent overwrite of published totals.
- [ ] Not a global or social graph leaderboard (PRD §6); no friend discovery UI.
- [ ] Last-synced snapshot readable offline with a stale banner when Firestore is unreachable.

## Test coverage

- [ ] **Unit/widget:** sort order per format; audit flag rendering; empty enrolled field state.
- [ ] **Integration (if needed):** two enrolled players, one publish → second device sees updated row after sync/pull.
- [ ] **Keys:** [Wireframe_Tournament.md](../../context/designs/Wireframe_Tournament.md) §4 (`tournament-leaderboard`, `tournament-leaderboard-row-{uid}`, `tournament-leaderboard-stale`).
- [ ] **Test plan:** [`TEST_PLAN_MGDV-6-pilot.md`](../../testing/TEST_PLAN_MGDV-6-pilot.md) § MGDV-6-012.

## Dev notes

- Story: [`MGDV-6-012-event-leaderboard.md`](../../stories/MGDV/MGDV-6-012-event-leaderboard.md).
- Firestore path likely `tournament_events/{eventId}/standings/{uid}` or local cache + pull; align with Watson rules (no public read on unrelated events).
- Reuse MGDV-601 format calculators for display totals — do not duplicate scoring logic.