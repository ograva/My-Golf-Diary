# CRSE-004 — Finish hole and holing stroke

| Field | Value |
| :--- | :--- |
| **ID** | CRSE-004 |
| **Module** | CRSE |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [CRSE-010-on-course-hud.md](../../shards/CRSE/CRSE-010-on-course-hud.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Rory**, I want **Finish Hole** to count a holing stroke when appropriate.

## Acceptance criteria

1. Finish advances hole index and loads catalog par.
2. Final hole completes the round.
3. Holing stroke unless double-par pickup, concede, or holed.
4. Totals consistent with scorecard rows.

## Widget keys / telemetry

- `oncourse-finish-hole-btn`
- `oncourse-double-par-banner`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
