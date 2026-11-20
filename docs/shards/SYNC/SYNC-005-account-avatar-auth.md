# SHARD-SYNC-005: Account avatar and durable sign-in

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-005 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-005, SYNC-006 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | L |
| **Depends On** | SYNC-001, SYNC-003 |

## Description

`AccountAvatarAppBarMenu` replaces the legacy cloud icon on My Bag, Range, On Course, and Scorecard. The menu opens Login, Sync, Profile, and Settings. Google and email/password sign-in ship on the login sheet, including create-account, forgot-password email, and inline errors. An unverified email account cannot push; Google can. Anonymous play still works when Firebase is absent or the player never signs in.

Account delete, the replace-this-device conflict path, change-password, and the wider `syncFull` table set are **not** this shard. They are SYNC-007, SYNC-008, SYNC-009, and SYNC-010.

## Acceptance Criteria

- [x] `account-avatar-button` is on every tab. Signed out it is a generic icon; signed in it can show initials.
- [x] Menu keys `account-menu-login`, `account-menu-sync`, `account-menu-profile`, `account-menu-settings`. Signed-out Sync explains that sign-in is required and does not call `syncFull`.
- [x] Login sheet: `account-login-google`, `account-login-email`, `account-login-password`, `account-login-submit`, create/sign-in toggle, and Forgot password.
- [x] Email/password push waits on `isEmailVerified`. Google push does not. Failure leaves SQLite unchanged. Local play does not require an account.

## Test coverage

- [x] **Unit/widget:** `test/account_avatar_menu_test.dart`, `test/account_login_sheet_test.dart`, `test/account_session_test.dart`. Forgot-password empty email is covered in `test/sync_account_shards_test.dart`.
- [x] **Integration (if needed):** Not required. Live Google and Firebase Auth stay out of `flutter test`.
- [x] **Keys:** `account-avatar-button`, `account-menu-login`, `account-menu-sync`, `account-menu-profile`, `account-menu-settings`, `account-login-google`, `account-login-email`, `account-login-password`, `account-login-submit` from `Wireframe_Settings.md` and the PRD SYNC-005 menu. Forgot password has no ValueKey yet.

## Dev notes

- `golf_diary_app/lib/widgets/account_avatar_app_bar_menu.dart`
- `golf_diary_app/lib/widgets/account_login_sheet.dart`
- `golf_diary_app/lib/services/account_auth_controller.dart`
- `golf_diary_app/lib/services/account_session.dart`
- `golf_diary_app/lib/widgets/shared_header_actions.dart` (MGDV-206)
- Passwords never go into SQLite. Architecture §9.8.
