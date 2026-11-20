# SHARD-SYNC-010: Sync settings

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-010 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-010 |
| **Priority** | High |
| **Status** | In Progress |
| **Complexity** | M |
| **Depends On** | SYNC-002, SYNC-005, MGDV-202 |

## Description

Settings opens from the avatar menu. It shows whether Firebase is configured, the signed-in email or “Not signed in”, the last successful pull, and how many local rows in `kSyncTables` have not uploaded. **Sync now** is the same action as the menu Sync item. An unverified email account can send a verification email from this screen. Change password is not on the screen (reset email is on the login sheet). The golfer skill profile link stays local SQLite and is separate from the Firebase account. There is no units toggle, handicap, or social control.

## Acceptance Criteria

- [x] Settings shows Firebase availability, sign-in state, last pull, and the dirty-row count for `kSyncTables`.
- [x] `account-settings-sync-now` calls `runDiarySync`, including the signed-out and Firebase-down explanations.
- [x] An unverified email account sees **Send verification email**. Google accounts do not see a password field.
- [x] Skill tier stays editable only through `settings-golfer-profile-entry` and is not part of the Firebase profile.
- [ ] Email accounts get **Change password** on this screen.

## Test coverage

- [x] **Unit/widget:** `test/sync_account_shards_test.dart` group `SYNC-010` (status lines, Sync now key, golfer-profile key, verification button for an unverified email session, no password field for Google).
- [ ] **Integration (if needed):** Not required until Change password writes through Firebase Auth.
- [x] **Keys:** `account-settings-sync-now`, `settings-golfer-profile-entry` from `Wireframe_Settings.md`. Send verification email and Change password have no ValueKeys yet.

## Dev notes

- `golf_diary_app/lib/screens/account_sync_settings_screen.dart`
- Dirty count loops `kSyncTables` only. When SYNC-007 adds tables, this count must include them.
- `sendEmailVerification` is `AccountAuthController.sendEmailVerification`.
- Do not add a yards/meters toggle here (Architecture §9.3).
