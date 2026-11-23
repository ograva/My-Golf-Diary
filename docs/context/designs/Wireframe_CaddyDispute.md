# Wireframe — Caddy hole dispute (MGDV-6-015)

| Field | Value |
| :--- | :--- |
| **Widgets** | `CaddyShell`, `ScorecardScreen` merge banner |
| **Stories** | [MGDV-6-015](../../stories/MGDV/MGDV-6-015-caddy-flight-hardening.md), [MGDV-501](../../stories/MGDV/MGDV-501-caddy-pairing.md) |
| **Status** | **Design spec** (extends shipped caddy shell) |

## 1. Player strip (full flight)

`caddy-player-strip` shows up to four players; active player highlighted. `caddy-player-{playerId}` chips.

## 2. Hole score vs dispute

After caddy sets hole gross for non-primary player, golfer sees on Scorecard:

```
┌ Caddy updated hole 7 for Ana ─────────┐
│ Caddy: 5    You had: 4               │
│ [ Accept ]  [ Dispute ]              │  caddy-hole-accept-btn, caddy-hole-dispute-btn
└──────────────────────────────────────┘
```

- **Dispute** sets audit flag only — does not delete caddy row (PRD: no hard reject).
- Tournament events with `require_caddy_attest`: `tournament-submit-btn` disabled until no open disputes.

## 3. Key map

| Element | ValueKey |
| :--- | :--- |
| Player chip | `caddy-player-{playerId}` |
| Accept caddy hole | `caddy-hole-accept-btn` |
| Dispute caddy hole | `caddy-hole-dispute-btn` |
| Dispute banner | `caddy-hole-dispute-banner` |
| Existing attest | `caddy-attest-card`, `scorecard-attest-btn` |