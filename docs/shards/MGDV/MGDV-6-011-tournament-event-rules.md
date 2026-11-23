# SHARD-MGDV-6-011: Tournament round under event rules

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-011 |
| **Epic** | MGDV-6 |
| **Module** | MGDV / SCOR |
| **Story Ref** | MGDV-6-011 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | MGDV-6-010, MGDV-601 |

## Description

Starting a round from an enrolled event locks scoring policies to the event configuration and applies attestation rules on completion. Personal rounds outside enrollment continue to behave exactly as MGDV-601.

## Acceptance Criteria

- [ ] **Start from event** pre-selects format, double-eagle policy, and paid-mulligan policy from the event record; golfer cannot pick a conflicting format without leaving the event round.
- [ ] Optional per-event **diary silence** suppresses Vertex calls during the competition window (no model on auto-save paths; composer send still allowed when silence is off).
- [ ] Finish flow enforces event attestation policy (self-only vs marker-required before submit).
- [ ] Unenrolled / personal rounds: no event badge; format toggle and attestation unchanged from MGDV-601.

## Test coverage

- [ ] **Unit/widget:** `ScoringFormat` + event policy overlay tests; attestation gate when marker required.
- [ ] **Integration (if needed):** enrolled round → complete → submit blocked until policy satisfied.
- [ ] **Keys:** [Wireframe_Tournament.md](../../context/designs/Wireframe_Tournament.md) — `scorecard-event-badge`, `scorecard-event-policy-banner`, `tournament-submit-btn`; reuse MGDV-601 attest/format keys.
- [ ] **Test plan:** [`TEST_PLAN_MGDV-6-pilot.md`](../../testing/TEST_PLAN_MGDV-6-pilot.md) § MGDV-6-011.

## Dev notes

- Story: [`MGDV-6-011-tournament-event-rules.md`](../../stories/MGDV/MGDV-6-011-tournament-event-rules.md).
- Store `event_id` on `golf_rounds` when started from enrollment (migration with Architecture).
- Diary silence hooks into §5.7 composer-only Vertex contract — block `Feedback` auto-paths only, not stored notes.