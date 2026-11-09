# SHARD-RNGE-020: Practice drill store

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-020 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-003 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | None |

## Description

Add SQLite `practice_drills` and seed the reference drills from `docs/context/Range_Drills.md`. The player can insert a custom drill and hide any drill, including a seeded one. A hidden seeded drill stays hidden after restart. Bump the database to version 5 with an `onUpgrade` path from version 4.

## Acceptance Criteria

- [ ] A new database and an upgraded version-4 database both contain the seeded drills, with stable ids from the reference doc, `is_custom = 0`, and `deleted = 0`.
- [ ] Listing drills returns only `deleted = 0`, ordered by category then title.
- [ ] Creating a drill stores title, category, short description, and ordered steps. Empty title is rejected.
- [ ] Deleting a seeded or custom drill sets `deleted = 1` and a new `updated_at_ms`. The next list omits it. Re-opening the database does not insert that seed again.

## Test coverage

- [ ] **Unit/widget:** Extend `test/local_database_service_test.dart` for seed count, custom insert, seeded delete, and upgrade from a version-4 file.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** None. UI is RNGE-021.

## Dev notes

- Schema: Architecture §5, planned version 5. Table columns include `steps_json`, `is_custom`, `is_synced`, `updated_at_ms`, `deleted`.
- Seed with `ConflictAlgorithm.ignore` so a tombstoned seed is not revived.
- Do not add `practice_drills` to `syncFull` in this shard. Sync can follow once the local list is stable.
- Optional nullable `range_drills.drill_id` may be added here if the column is unused until RNGE-021.
