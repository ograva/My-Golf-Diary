# MGDV-6-013 — Marker and committee attestation

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6-013 |
| **Module** | MGDV |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | [MGDV-6-013](../../shards/MGDV/MGDV-6-013-committee-attestation.md) |
| **PRD** | [PRD §3 MGDV-6-013](../../context/PRD.md) |
| **Epic** | [MGDV-6 club tournament pilot](MGDV-6-club-tournament-pilot.md) |
| **Depends on** | [MGDV-601](MGDV-601-scoring-formats-epic.md), [MGDV-6-011](MGDV-6-011-tournament-event-rules.md) |

## User story

As **a marker or committee volunteer**, I want **to attest a player’s card for the event** so **disputes have a named record**.

## Acceptance criteria

1. Marker role can attest another golfer’s **published** hole summary or full card per event rules; stores `attested_by_name`, role, and timestamp.
2. **Committee lock** freezes standings for the event after published close time; further golfer edits flag **late correction** workflow (notify only — no auto prize logic in app).
3. Caddy attest from `MGDV-601` remains valid for non-event rounds; event may require marker in addition.
4. No payment settlement or GCash integration in v1 pilot — copy-only fee reminders allowed.

## Widget keys / telemetry

- Extends `scorecard-attest-btn`; committee lock TBD.

## Notes

Pilot scope is audit trail and freeze — not prize calculation or payments.