# SHARD-SYNC-007: Multi-device diary retrieve

| Field | Value |
| :--- | :--- |
| **Shard ID** | SYNC-007 |
| **Module** | SYNC — Cloud sync |
| **Story Ref** | SYNC-007 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | SYNC-004, SYNC-006 |

## Description

A second phone or the PWA, signed into the same Google or email account, should download and upload the diary. Today `kSyncTables` is only `clubs`, `shots`, `round_scores`, and `range_drills`. This shard adds `golf_rounds`, `practice_drills`, `range_sessions`, and the swing-diary tables to `syncFull`, with the same last-write-wins rules as SYNC-004. `golfer_profile` stays on the device. The snackbar should say how many local rows were replaced because the remote `updatedAtMs` was newer.

## Acceptance Criteria

- [ ] After sign-in, sync pulls then pushes `clubs`, `shots`, `round_scores`, `golf_rounds`, `range_drills`, `practice_drills`, `range_sessions`, and swing-diary rows under `users/{uid}/...`.
- [ ] `golfer_profile` is not in `kSyncTables`.
- [ ] The success snackbar includes how many local rows were replaced. There is no per-row merge screen.
- [ ] Sign-out keeps the on-device SQLite copy and stops further reads and writes for that account.

## Test coverage

- [x] **Unit/widget:** `test/sync_account_shards_test.dart` group `SYNC-007` locks the current four-table set and asserts `golfer_profile` stays out. Replace the “not yet included” expectations when the extra tables join `kSyncTables`. Sign-out keeping SQLite is covered by the profile confirm copy in the SYNC-009 test (local rows are not deleted on sign-out).
- [ ] **Integration (if needed):** Two clients, one uid, after the table expansion: device B sees a round and a range session pushed by device A, including a tombstone.
- [ ] **Keys:** Snackbar has no new key. Sync entry remains `account-menu-sync` and `account-settings-sync-now`.

## Dev notes

- `golf_diary_app/lib/services/sync_constants.dart` — extend `kSyncTables` only together with `LocalDatabaseService._columns` and primary-key handling for `golf_rounds` (`round_id`).
- `golf_diary_app/lib/widgets/diary_sync_runner.dart` — snackbar copy for replaced rows.
- Do not sync `golfer_profile` (Architecture §6, §8 gap “SYNC-007 table expansion”).
- Swing-diary tables stay out until this shard; RNGE-004 offline save must still work with Firebase down.
