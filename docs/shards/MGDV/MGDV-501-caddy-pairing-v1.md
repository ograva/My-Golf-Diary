# SHARD-MGDV-501: Caddy pairing & stroke logging v1

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-501 |
| **Epic** | MGDV-5 |
| **Module** | CRSE + SCOR + SYNC |
| **Story Ref** | MGDV-501 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | L |
| **Depends On** | MGDV-4 (cart view), CRSE shot→score derivation |

## Description

Golfer mints a **single-use opaque QR** (`?mode=caddy&request=<token>`) during an active round. Caddy opens **Web PWA shell** (On Course + Scorecard tabs only), records **per-stroke** events, and syncs over **internet** via Firestore `caddy_round_channels/{channelId}/events`. Golfer app **subscribes** and merges into local SQLite (`recordCaddyStroke` → `syncStrokeCountFromShots`).

## Acceptance Criteria — v1 (this PR)

- [x] Golfer: **Invite caddy** on On Course when round active → QR + URL (no raw uid in query).
- [x] PWA deep link `mode=caddy` routes to **CaddyPairingGate** → two-tab **CaddyShell**.
- [x] Caddy **+1 stroke** (and penalty/mulligan/gimme) publishes channel events; **offline queue** in `caddy_pending_events`.
- [x] Golfer **Caddy connected** banner + **Revoke**; merge host applies caddy strokes to SQLite.
- [x] Firestore schema + **v1 security rules** for `caddy_round_channels` (documented limits).
- [x] Architecture § caddy channel; DB v14 `caddy_sessions` + `caddy_pending_events`.
- [x] `flutter test` green.

## Deferred (follow-up shards)

- [ ] **Player picker** — one caddy device scores full flight (PH norm).
- [ ] **Hole-segment accept** — golfer accept/dispute workflow per roadmap (no hard reject).
- [ ] **Hardened rules** — event writes bound to active session principal (not channel-id-only).
- [ ] **Production token redeem** Cloud Function or App Check attestation.
- [ ] Sync caddy channel into `syncFull` tables push for multi-device golfer.

## Keys

| Key | Control |
| :--- | :--- |
| `on-course-invite-caddy` | QR invite on fairway |
| `caddy-invite-qr` | QR image |
| `caddy-connected-banner` | Golfer banner |
| `caddy-revoke-btn` | Revoke session |
| `caddy-on-course-stroke-plus` | Caddy +1 |
| `caddy-shell-nav` | Two-tab nav |

## Test coverage

- [x] Unit: mint → redeem → event → `recordCaddyStroke` / strokes count.
- [x] Unit: invite URL has opaque token only.
- [x] Unit: revoke marks channel revoked.

## Dev notes

- Files: `caddy_pairing_service.dart`, `caddy_round_channel_store.dart`, `caddy_shell.dart`, `caddy_invite_sheet.dart`, `caddy_golfer_merge_host.dart`.
- Manual edit vs caddy stroke: **caddy stroke wins** on hole until product adds manual lock (Architecture §5.2).