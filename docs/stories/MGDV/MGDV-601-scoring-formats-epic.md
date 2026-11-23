# MGDV-601 — Scoring formats, flight, and caddy hole scores

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-601 |
| **Module** | MGDV / SCOR |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [MGDV-601-scoring-formats.md](../../shards/MGDV/MGDV-601-scoring-formats.md) |
| **PRD** | [PRD §3 MGDV-6](../../context/PRD.md) |

## User story

As **Rory**, I want **Philippine tournament formats on my own card**, **flight sync**, and **caddy hole scores for my group** so **I can practise formats and audit a round without a second scoring app**.

## Acceptance criteria

1. Gross, Molave, and System 36 derived from stored strokes.
2. Paid tournament mulligan: one per nine; not HIO-eligible.
3. Local attestation with edit-invalidate flow.
4. Optional rating/slope and unofficial handicap after three rated 18s.
5. Flight QR publishes hole grosses only; partner attest mismatch flag.
6. Caddy player strip and hole scores for non-primary players.

## Widget keys / telemetry

- `scorecard-format-toggle`, `scorecard-flight-btn`, `flight-qr`
- `caddy-player-strip`, `caddy-attest-card`

## Notes

Shipped in PR #86. Remaining MGDV-6 club tournament stories are MGDV-6-010+ in PRD 1.12.