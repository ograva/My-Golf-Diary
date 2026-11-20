# SYNC-005 — Account avatar, Google/email auth (MGDV-12)

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-005 |
| **Tracker** | MGDV-12 |
| **Status** | In Progress (vertical slice) |
| **Depends On** | SYNC-001 anonymous sync, shell AppBar actions |

## Shipped in this slice

- [x] **SYNC-005** — `AccountAvatarAppBarMenu` replaces `SyncCloudButton` on all four tabs; PRD menu keys and avatar key.
- [x] **SYNC-006** — Login sheet: Google + email/password, create/sign-in toggle, forgot password; inline errors; email verification blocks **push** (pull-only until verified).
- [x] **SYNC-009** (partial) — Account profile screen (Firebase identity only); signed-out explains local-only; sign-out keeps SQLite.
- [x] **SYNC-010** (partial) — Settings: Firebase status, sign-in state, last pull, dirty row count, sync now, link to **local** golfer profile editor.
- [x] Sign-out clears Firebase session; anonymous play still allowed via `initializeFirebase` + `SyncIdentity.ensureSignedIn()` for legacy/background use.
- [x] Widget/unit tests with fakes (`debugSetSession`); `google_sign_in` dependency for Android/web path.

- [x] Illustrated golfer avatar (`GolferAvatarCircle`): Google photo → profile avatar (choice or gender × tier) → initials → generic icon; picker in Golfer profile settings; DB v16 `avatar_choice`.

## Deferred (follow-up shards)

- [ ] **SYNC-008** — Full `linkWithCredential` success path is implemented; **“Replace this device with the account”** and complete upload-then-download conflict flow.
- [ ] **SYNC-009** — Delete account + optional “Erase diary on this device”.
- [ ] **SYNC-010** — Change password UI for email accounts (reset email only today).
- [ ] **SYNC-007** — Extend `kSyncTables` / `_columns` for `golf_rounds` (PK `round_id`), `practice_drills`, `range_sessions`, swing-diary tables (Architecture lists these as planned; merge layer only supports four tables today).

## SYNC-007 gap note

`syncFull` still syncs: `clubs`, `shots`, `round_scores`, `range_drills` only (`sync_constants.dart`). Adding `golf_rounds`, `practice_drills`, `range_sessions`, and diary tables requires `LocalDatabaseService._columns` entries and PK handling for `golf_rounds` before Firestore push/pull is safe.

## Key paths

| Area | Path |
| :--- | :--- |
| Avatar menu | `golf_diary_app/lib/widgets/account_avatar_app_bar_menu.dart` |
| Login sheet | `golf_diary_app/lib/widgets/account_login_sheet.dart` |
| Auth | `golf_diary_app/lib/services/account_auth_controller.dart` |
| Session model | `golf_diary_app/lib/services/account_session.dart` |
| Sync runner | `golf_diary_app/lib/widgets/diary_sync_runner.dart` |
| Account profile | `golf_diary_app/lib/screens/account_profile_screen.dart` |
| Golfer avatar | `golf_diary_app/lib/models/golfer_avatar.dart`, `golf_diary_app/lib/widgets/golfer_avatar_circle.dart`, `golf_diary_app/assets/avatars/` |
| Sync settings | `golf_diary_app/lib/screens/account_sync_settings_screen.dart` |

## Tests

- `golf_diary_app/test/account_session_test.dart`
- `golf_diary_app/test/account_avatar_menu_test.dart`
- `golf_diary_app/test/golfer_avatar_test.dart`
- `golf_diary_app/test/account_login_sheet_test.dart`