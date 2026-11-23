# MGDV-6-011 — Tournament round under event rules

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6-011 |
| **Module** | MGDV / SCOR |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | [MGDV-6-011](../../shards/MGDV/MGDV-6-011-tournament-event-rules.md) |
| **PRD** | [PRD §3 MGDV-6-011](../../context/PRD.md) |
| **Epic** | [MGDV-6 club tournament pilot](MGDV-6-club-tournament-pilot.md) |
| **Depends on** | [MGDV-601](MGDV-601-scoring-formats-epic.md), [MGDV-6-010](MGDV-6-010-club-tournament-enrollment.md) |

## User story

As **Rory**, I want **my scorecard to follow the event’s format and lock window** so **committee rules match what I see**.

## Acceptance criteria

1. Starting a round **from an enrolled event** pre-selects format, double-eagle policy, and paid-mulligan policy from the event; golfer cannot switch to a conflicting format mid-round without leaving the event round.
2. **Diary silence** optional flag per event (no model calls during competition window) — implementation pairs with `MGDV-205` follow-on when event demands it.
3. **Attestation** on completion follows event policy: self-only vs marker-required before submit.
4. Unenrolled personal rounds behave exactly as `MGDV-601`.

## Widget keys / telemetry

- Reuses shipped `scorecard-format-toggle`, `scorecard-attest-btn`; event badge TBD.

## Notes

Event round is a mode overlay on existing scorecard — no duplicate scoring engine.