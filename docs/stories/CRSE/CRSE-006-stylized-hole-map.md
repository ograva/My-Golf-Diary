# CRSE-006 — Stylized hole map and packs

| Field | Value |
| :--- | :--- |
| **ID** | CRSE-006 |
| **Module** | CRSE |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [CRSE-036-fwy-map-background-shell.md](../../shards/CRSE/CRSE-036-fwy-map-background-shell.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Rory**, I want **an offline fairway map**.

## Acceptance criteria

1. FWY shows full-bleed map; SIM has no map pane.
2. CRSE-041 pack shows stylized PNG plus attribution.
3. Vector or stand-in fallback when pack missing.
4. Legacy map toggle removed from FWY.

## Widget keys / telemetry

- `oncourse-map-background`
- `oncourse-map-attribution`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
