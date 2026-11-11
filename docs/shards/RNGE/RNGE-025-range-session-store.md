# SHARD-RNGE-025: Range session store

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-025 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-005 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | RNGE-020 |

## Description

Add SQLite `range_sessions` and a nullable `range_drills.session_id` so a range visit can be compiled into one session log. Bump the database to version 6 with an upgrade from version 5. Compiling a session stores the venue, the overall session note, and a snapshot of the club blocks, then links those blocks to the new session. This shard is the store only. The Range wrap-up card is RNGE-026. Vertex evaluation stays in RNGE-022.

## Acceptance Criteria

- [ ] A new database and an upgraded version-5 database both have `range_sessions` and nullable `range_drills.session_id`. Existing `range_drills` rows keep `session_id` null.
- [ ] Compiling a session inserts one `range_sessions` row with venue, session note, timestamp, and `compiled_summary_json` that snapshots each block’s club id and name, shot count, min / avg / max, tempo note, drill id, drill title, and drill steps.
- [ ] The same compile sets `session_id` on the included `range_drills` rows and leaves other blocks unlinked. A second compile of those same rows does not attach them again.
- [ ] Compiling with no blocks and an empty session note is rejected. A note-only compile, with no blocks, still inserts a session. Re-opening the database keeps the session and the links.

## Test coverage

- [ ] **Unit/widget:** Extend `test/local_database_service_test.dart` for a version-5 upgrade, a multi-club compile, a note-only compile, a rejected empty compile, and the snapshot fields.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** None. UI is RNGE-026.

## Dev notes

- Architecture §5 and §5.3.1. Planned version 6. Columns match `range_sessions` and `range_drills.session_id` there.
- `compiled_summary_json` is the copy the log and RNGE-022 read. Do not depend on a later club rename or a deleted custom drill to rebuild the snapshot.
- Do not add `range_sessions` to `syncFull` in this shard.
- Do not call Vertex AI here.
