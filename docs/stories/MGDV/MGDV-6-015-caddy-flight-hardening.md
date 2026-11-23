# MGDV-6-015 — Extend caddy flight hardening

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6-015 |
| **Module** | MGDV |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | [MGDV-6-015](../../shards/MGDV/MGDV-6-015-caddy-flight-hardening.md) (closes [MGDV-501](../../shards/MGDV/MGDV-501-caddy-pairing-v1.md) deferrals) |
| **PRD** | [PRD §3 MGDV-6-015](../../context/PRD.md) |
| **Epic** | [MGDV-6 club tournament pilot](MGDV-6-club-tournament-pilot.md) |
| **Depends on** | [MGDV-501](MGDV-501-caddy-pairing.md), [MGDV-601](MGDV-601-scoring-formats-epic.md) |

## User story

As **operations**, I want **production-safe caddy redeem and accept/dispute** when tournaments rely on caddy entry so **flight audit is trustworthy**.

## Acceptance criteria

1. Document overlap with [`MGDV-501`](../../shards/MGDV/MGDV-501-caddy-pairing-v1.md) deferrals: player picker for one device scoring full flight, accept/dispute golfer vs caddy hole, hardened token redeem.
2. Tournament events may **require** caddy-attested submit before leaderboard publish.
3. Architecture defines Firestore rules upgrade path (pilot uses same loose auth as caddy v1 until hardened).

## Widget keys / telemetry

- Shipped: `caddy-player-strip`, `caddy-attest-card`; dispute/accept flow TBD.

## Notes

Shipped MGDV-603 hole-score mode is v1; this story closes trust gaps for club pilot.