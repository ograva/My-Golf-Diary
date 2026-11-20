# SHARD-SYNC-009: Account profile

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-009 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-009 |
| **Priority** | High |
| **Status** | In Progress |
| **Complexity** | M |
| **Depends On** | SYNC-005 |

## Description

Profile opens from the avatar menu. Signed in, it shows the display name, email, initials or photo, and provider (Google or email). It does not edit clubs, rounds, or drills. Signed out, it says the diary is on this device only and offers the sign-in sheet. Sign out confirms, then clears the Firebase session and leaves SQLite in place. Delete account (Firebase user and `users/{uid}` only, with a separate “Erase diary on this device” confirm) is not built.

## Acceptance Criteria

- [x] Signed-in profile shows display name or email and `Provider: Google` or `Provider: Email`.
- [x] Signed-out profile explains the diary is on this device and offers Sign in.
- [x] Sign out asks first. The confirm button is `account-profile-sign-out`. Confirm copy says the diary stays on this device.
- [ ] Delete account is a second confirm. It deletes the Firebase user and that uid’s cloud docs only. Local SQLite is erased only after a further “Erase diary on this device” confirm.

## Test coverage

- [x] **Unit/widget:** `test/sync_account_shards_test.dart` group `SYNC-009` (signed-out copy, signed-in provider, confirm key, Cancel leaves the session). Confirm is not tapped through to `signOut` because that calls `GoogleSignIn` with no fake.
- [ ] **Integration (if needed):** Delete account against a fake Auth user: cloud path removed, SQLite still readable until the second confirm.
- [x] **Keys:** `account-profile-sign-out` from story SYNC-009 and `Wireframe_Settings.md` §4. Delete account has no key yet.

## Dev notes

- `golf_diary_app/lib/screens/account_profile_screen.dart`
- Opened from `account-menu-profile` in `account_avatar_app_bar_menu.dart`.
- `AccountAuthController.signOut` clears the session. Do not call `LocalDatabaseService` wipe from the first confirm.
- Skill-tier editing stays on the golfer profile screen (MGDV-202), not here.
