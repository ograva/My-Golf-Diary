# SHARD-SYNC-002: Manual sync

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-002 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-002 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | SYNC-001, SYNC-005 |

## Description

Sync is manual. The avatar menu item `account-menu-sync` and Settings **Sync now** (`account-settings-sync-now`) both call `runDiarySync`. When Firebase is not configured the snackbar says local data stays on the device. When the player is signed out it asks them to sign in and does not push. A durable verified session runs `syncFull`. A failed write leaves the row dirty.

## Acceptance Criteria

- [x] Unavailable Firebase shows the local-only snackbar and does not throw.
- [x] Signed-out Sync shows the sign-in snackbar and does not call `syncFull`.
- [x] A successful push marks those rows synced. A failed `setDocument` leaves the row in `getUnsynced`.
- [x] Settings **Sync now** uses the same runner as the avatar menu.

## Test coverage

- [x] **Unit/widget:** Signed-out menu snackbar in `test/account_avatar_menu_test.dart`. Dirty-row retry in `test/cloud_sync_service_test.dart`. Settings **Sync now** snackbar in `test/sync_account_shards_test.dart` group `SYNC-002`.
- [x] **Integration (if needed):** Not required. No live Firestore call.
- [x] **Keys:** `account-menu-sync`, `account-settings-sync-now` from `Wireframe_Settings.md` and story SYNC-002.

## Dev notes

- `golf_diary_app/lib/widgets/diary_sync_runner.dart`
- `golf_diary_app/lib/widgets/account_avatar_app_bar_menu.dart`
- `golf_diary_app/lib/screens/account_sync_settings_screen.dart`
- Pull-then-push order is `CloudSyncService.syncFull` (SYNC-004).
