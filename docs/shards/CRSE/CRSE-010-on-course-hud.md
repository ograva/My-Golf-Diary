# SHARD-CRSE-010: On Course HUD

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-010 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-001, CRSE-002, CRSE-003, CRSE-004, SYNC-002 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | SHELL-001 |

## Description

Rebuild the fairway screen so the record action stays on screen. The HUD shows hole, par, strokes, penalties, hole gross, and round total. Penalties, mulligans, concede, and finish hole are outlined. Course name edits persist onto every `round_scores` row for the active round. GPS denial shows a banner and the existing snackbar. Shot rows use the club name.

## Acceptance Criteria

- [ ] App bar title is `On Course`. Record shot is a filled button fixed above the tab bar. Finish hole is outlined. Hole 18 reads `Finish round` and shows a local-save snackbar.
- [ ] Editing the course name updates `course_name` for all rows of the active round.
- [ ] Permission denied sets a banner (`oncourse-location-banner`) and does not insert a shot. The record button ignores taps while a fix is in progress.
- [ ] Concede still sets strokes to `par * 2` and the HUD shows the word `Gimme`. Mulligans do not change gross.
- [ ] Recording a shot still sets strokes from the shot list. The shot row shows club name, lie, and yards or `Distance pending`.

## Test coverage

- [ ] **Unit/widget:** `oncourse-record-shot-btn` is found on launch. No live GPS call is asserted.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `oncourse-sync-btn`, `oncourse-course-name-field`, `oncourse-par-chip-3|4|5`, `oncourse-club-chip-{clubId}`, `oncourse-lie-chip-{lie}`, `oncourse-record-shot-btn`, `oncourse-penalty-1-btn`, `oncourse-penalty-2-btn`, `oncourse-mulligan-btn`, `oncourse-concede-btn`, `oncourse-finish-hole-btn`, `oncourse-shot-row-{strokeNumber}`, `oncourse-location-banner` from `Wireframe_OnCourse.md`.

## Dev notes

- Files: `golf_diary_app/lib/screens/fairway_tracker_screen.dart`, `golf_diary_app/lib/services/local_database_service.dart` (`updateRoundCourseName`).
- `ensureActiveRound` still returns an existing round id. Name changes go through the new update.
- Do not change `syncStrokeCountFromShots` or penalty math.
