# SHARD-SYNC-001: Firebase optional at launch

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-001 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-001 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | None |

## Description

The diary is local-first. `initializeFirebase` catches a failed startup and returns false so Bag, Range, On Course, and Scorecard still open. `CloudSyncService.isAvailable` is true only when an injected remote exists or Firebase is already running. Public client config may live in `firebase_options.dart`. Server secrets do not.

## Acceptance Criteria

- [x] A failed Firebase init does not crash the app (`initializeFirebase` returns false).
- [x] `CloudSyncService.isAvailable` is false with no remote and no Firebase app, and true when a `DiaryRemote` is injected.
- [x] `syncFull` / `pullAll` / `syncAll` return an empty result when the service is unavailable.
- [x] No service-account or API secret is required to build or to play offline.

## Test coverage

- [x] **Unit/widget:** `test/sync_account_shards_test.dart` group `SYNC-001`. Live `Firebase.initializeApp` is not called from the suite.
- [x] **Integration (if needed):** Not required.
- [x] **Keys:** None. This shard has no new widgets.

## Dev notes

- `golf_diary_app/lib/services/cloud_sync_service.dart` (`initializeFirebase`, `CloudSyncService.isAvailable`)
- `golf_diary_app/lib/firebase_options.dart` is public client config, not a server secret.
- Architecture §9.2 local-first and §9.8 secrets.
