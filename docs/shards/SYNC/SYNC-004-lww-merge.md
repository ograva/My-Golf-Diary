# SHARD-SYNC-004: Last-write-wins merge

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-004 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-004 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | SYNC-001, SYNC-003 |

## Description

Pull applies a remote row only when its `updatedAtMs` is newer than the local row. Equal timestamps keep the local row. A remote tombstone deletes the local row. Deleting a club uploads a tombstone before the local row is gone. The same `decideMerge` path runs on device and on the PWA. There is no per-row merge screen.

## Acceptance Criteria

- [x] A newer remote row replaces the local row. An equal or older remote row does not.
- [x] A remote `deleted: true` row removes the local club.
- [x] `deleteClub` pushes a tombstone and then drops the local unsynced row after a successful sync.
- [x] PWA and mobile share `CloudSyncService` and `decideMerge`. No second merge implementation.

## Test coverage

- [x] **Unit/widget:** `test/cloud_sync_service_test.dart` (newer remote, tombstone pull, delete tombstone push). Not re-written in the sync account file.
- [x] **Integration (if needed):** Not required.
- [x] **Keys:** None.

## Dev notes

- `golf_diary_app/lib/services/sync_merge.dart` (`decideMerge`)
- `golf_diary_app/lib/services/cloud_sync_service.dart`
- `golf_diary_app/lib/services/local_database_service.dart` (`applyRemoteRow`, `deleteClub`)
- Architecture §6 last-write-wins. Table scope is SYNC-007.
