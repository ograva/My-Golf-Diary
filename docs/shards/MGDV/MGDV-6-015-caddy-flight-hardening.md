# SHARD-MGDV-6-015: Caddy flight hardening (tournament trust)

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-015 |
| **Epic** | MGDV-6 |
| **Module** | MGDV + SYNC |
| **Story Ref** | MGDV-6-015 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | MGDV-501, MGDV-601, MGDV-6-011 |

## Description

Closes MGDV-501 deferred items needed for trustworthy club pilots: flight-wide player picker on one caddy device, golfer accept/dispute per hole vs caddy entry, and hardened token redeem / Firestore rules. Events may require caddy-attested submit before leaderboard publish.

## Acceptance Criteria

- [ ] **Player picker** on caddy device can score full flight (up to four players) with `caddy-player-strip` persistence per Architecture v17 tables.
- [ ] Golfer **accept/dispute** workflow for caddy hole scores (no hard reject — dispute flags audit state).
- [ ] **Hardened rules:** channel writes bound to active session principal; document v1 vs pilot rule upgrade in Architecture.
- [ ] **Production redeem:** opaque token validation path (Cloud Function or App Check) documented and wired for pilot.
- [ ] Event config may set `require_caddy_attest_before_publish`; submit blocked until satisfied when enabled.

## Test coverage

- [ ] **Unit/widget:** dispute flag on merge host; picker switches active player; redeem rejects expired/revoked tokens.
- [ ] **Integration (if needed):** caddy scores hole for player B → golfer dispute → leaderboard publish shows audit.
- [ ] **Keys:** `caddy-player-strip`, `caddy-attest-card`, `caddy-hole-dispute` (TBD), existing invite QR keys.

## Dev notes

- Story: [`MGDV-6-015-caddy-flight-hardening.md`](../../stories/MGDV/MGDV-6-015-caddy-flight-hardening.md).
- Implements deferred bullets on [`MGDV-501-caddy-pairing-v1.md`](MGDV-501-caddy-pairing-v1.md); mark those deferred items done as this shard completes.
- Coordinate with MGDV-6-013 attestation so caddy + marker requirements compose without duplicate attest rows.