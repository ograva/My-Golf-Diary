# CRSE-041 — Map pack catalog coverage

| Field | Value |
| :--- | :--- |
| **ID** | CRSE-041 |
| **Module** | CRSE |
| **Priority** | High |
| **Status** | Partial |
| **Shard** | [CRSE-041-map-pack-pipeline.md](../../shards/CRSE/CRSE-041-map-pack-pipeline.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Rory**, I want **packs for catalog courses** when online.

## Acceptance criteria

1. Owner pipeline builds OSM packs.
2. App downloads with authenticated Storage read.
3. Graceful FWY fallback when pack absent.
4. Attribution when imagery visible.

## Widget keys / telemetry

- `oncourse-map-download`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
