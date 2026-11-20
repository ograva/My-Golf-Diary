# SHARD-SYNC-003: Anonymous identity

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-003 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-003 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | SYNC-001 |

## Description

When Firebase is up, `SyncIdentity.ensureSignedIn()` is the install’s user id and documents live under `users/{uid}/...` on the named database `my-golf-diary`. An anonymous session is not a durable account and cannot push. Google and email sign-in are SYNC-006. Linking that anonymous uid is SYNC-008. Old `users/local_user` documents are not migrated.

## Acceptance Criteria

- [x] Firestore database id is `my-golf-diary`, not `(default)`.
- [x] `SyncIdentity.ensureSignedIn()` is the only uid used for diary paths. It no-ops when Firebase is down.
- [x] An anonymous `AccountSession` is not `isDurableAccount` and cannot push.
- [x] Nothing in the client copies `users/local_user` into the anonymous uid.

## Test coverage

- [x] **Unit/widget:** `test/sync_account_shards_test.dart` group `SYNC-003` (database id and anonymous session). `ensureSignedIn` needs a live Firebase Auth user and is not called from the suite.
- [x] **Integration (if needed):** Not required.
- [x] **Keys:** None.

## Dev notes

- `golf_diary_app/lib/services/sync_constants.dart` (`kFirestoreDatabaseId`)
- `golf_diary_app/lib/services/sync_identity.dart`
- `golf_diary_app/lib/services/account_session.dart`
- Architecture §6 anonymous auth. Durable linking stays in SYNC-008.
