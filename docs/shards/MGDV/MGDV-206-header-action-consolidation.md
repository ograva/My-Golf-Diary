# SHARD-MGDV-206: Header action consolidation (P0)

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-206 |
| **Module** | MGDV / Shell |
| **Story Ref** | MGDV-2, UX audit P0 |
| **Priority** | High |
| **Status** | Ready for Review |
| **Complexity** | M |
| **Depends On** | MGDV-12 (SYNC-005 avatar), #46 single AppBar |

## Description

Consolidate tab **AppBar** trailing actions per Eunice **Header & tab-flow UX audit** (Project store `docs/header-and-flow-ux-audit.md` P0 items 1–3). One **`SharedHeaderActions`** cluster per tab: **account avatar** for global utilities; tier-aware **swing diary** and **caddy QR**; no duplicate `GolferProfileAppBarMenu` beside avatar.

## Acceptance Criteria

- [x] **P0-1** — All four tabs use `SharedHeaderActions`; only `AccountAvatarAppBarMenu` for account/sync/profile/settings; `GolferProfileAppBarMenu` removed from tab AppBars.
- [x] **P0-2** — Caddy QR only on **On Course + Scorecard** when `roundId != null`; hidden on Bag/Range. Scorecard uses `ValueKey('scorecard-invite-caddy')`. `CaddyInviteIconButton` extracted with 48×48 dp.
- [x] **P0-3** — `HeaderActionPolicy` from `GolferProfile.skillTier`: beginner → single overflow (`shell-header-overflow-btn`) for play utilities + avatar; amateur → pinned diary, QR in overflow when round active; seasoned pro → pinned QR + diary when round active (max 2 + avatar).
- [x] Diary pinned keys unchanged: `diary-entry-range`, `diary-entry-on-course`, `diary-entry-scorecard`.
- [x] Widget tests for policy and tier-visible keys.

## Key map

| Key | Where |
| :--- | :--- |
| `account-avatar-button` | `AccountAvatarAppBarMenu` (always) |
| `shell-header-overflow-btn` | Beginner / compressed play utilities |
| `on-course-invite-caddy` | On Course pinned or overflow |
| `scorecard-invite-caddy` | Scorecard pinned or overflow |
| `diary-entry-range` / `on-course` / `scorecard` | Pinned or overflow menu row |

## Files touched

| Path | Change |
| :--- | :--- |
| `lib/ui/header_action_policy.dart` | **New** tier policy |
| `lib/widgets/shared_header_actions.dart` | **New** shared cluster |
| `lib/widgets/caddy_invite_app_bar_button.dart` | **New** QR button |
| `lib/screens/clubs_screen.dart` | Bag: avatar only |
| `lib/screens/range_drill_screen.dart` | Shared header |
| `lib/screens/fairway_tracker_screen.dart` | Shared header |
| `lib/screens/scorecard_screen.dart` | Shared header + Scorecard QR |
| `lib/widgets/golfer_profile_app_bar_menu.dart` | Deprecated |
| `test/header_action_policy_test.dart` | Unit |
| `test/shared_header_actions_test.dart` | Widget |

## Deferred (audit P1+)

- Collapsible caddy banner; tier-aware tooltips; diary post-save on Range only.

## References

- Project store: `/cursor/stores/bc-feeaea10-b0d1-4960-874c-190e168fc2b4/docs/header-and-flow-ux-audit.md`
- MGDV-12: `docs/shards/SYNC/SYNC-005-account-avatar-auth.md`