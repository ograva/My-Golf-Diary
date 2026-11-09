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

The fairway screen already has venue lookup, Course / Simulator mode, hole resume and stepping, shot edit, and course-name edits through `applyCoursePar` (that renames every row of the round and sets par on unplayed holes). Shot rows already show the club name, lie, and yards or `Distance pending`. The record button ignores taps while `_busy` is set. Finish on the last hole shows a local-save snackbar.

This shard still rebuilds the layout from `Wireframe_OnCourse.md`: title `On Course`, record shot fixed above the tab bar, outlined finish hole, a location banner, the word `Gimme` on the HUD after concede, and the wireframe keys. Keep simulator entry, hole stepping, shot correction, and `applyCoursePar`.

That layout shipped in `7f5791f` and was overwritten. The app bar title is `Fairway HUD` again. Record shot and Finish hole are filled buttons inside the scroll view. Permission denial is only a snackbar. The HUD line does not show `Gimme`.

## Acceptance Criteria

- [ ] App bar title is `On Course`. Record shot is a filled button fixed above the tab bar. Finish hole is outlined. Hole 18 reads `Finish round` and shows a local-save snackbar.
- [x] Editing the course name updates `course_name` for all rows of the active round. Keep `applyCoursePar` so unplayed holes still take catalog par.
- [ ] Permission denied sets a banner (`oncourse-location-banner`) and does not insert a shot. The record button ignores taps while a fix is in progress.
- [ ] Concede still sets strokes to `par * 2` and the HUD shows the word `Gimme`. Mulligans do not change gross.
- [x] Recording a shot still sets strokes from the shot list. The shot row shows club name, lie, and yards or `Distance pending`.

## Test coverage

- [x] **Unit/widget:** `oncourse-record-shot-btn` is found on launch. No live GPS call is asserted. The current shell test covers this key only.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `oncourse-sync-btn`, `oncourse-course-name-field`, `oncourse-par-chip-3|4|5`, `oncourse-club-chip-{clubId}`, `oncourse-lie-chip-{lie}`, `oncourse-record-shot-btn`, `oncourse-penalty-1-btn`, `oncourse-penalty-2-btn`, `oncourse-mulligan-btn`, `oncourse-concede-btn`, `oncourse-finish-hole-btn`, `oncourse-shot-row-{strokeNumber}`, `oncourse-location-banner` from `Wireframe_OnCourse.md`.

## Dev notes

- Files: `golf_diary_app/lib/screens/fairway_tracker_screen.dart`. Name changes already go through `applyCoursePar` (which calls `updateCourseName`). Do not switch that back to a name-only update.
- `ensureActiveRound` still returns an existing round id.
- Do not change `syncStrokeCountFromShots` or penalty math.
- Do not remove simulator mode, hole previous/next, or the shot edit dialog.
