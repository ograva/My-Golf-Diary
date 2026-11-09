# Backlog — My Golf Diary

Index only. Shard bodies live under `docs/shards/`.

Checked against `main` at `0c151da` on 2026-11-09.

| Shard ID | Title | Module | Priority | Status | Complexity | Story Ref | File |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| SHELL-001 | Keep tab state | Shell | High | Completed | S | None | [SHELL-001](../shards/SHELL/SHELL-001-keep-tab-state.md) |
| BAG-010 | Glance club cards | BAG | High | Not Started | M | BAG-001, BAG-002, BAG-003 | [BAG-010](../shards/BAG/BAG-010-glance-cards.md) |
| CRSE-010 | On Course HUD | CRSE | High | Not Started | L | CRSE-001–004, SYNC-002 | [CRSE-010](../shards/CRSE/CRSE-010-on-course-hud.md) |
| SCOR-010 | Scorecard hole tiles | SCOR | High | Completed | M | SCOR-001, SCOR-003 | [SCOR-010](../shards/SCOR/SCOR-010-hole-tiles.md) |
| SCOR-011 | Hole editor gross preview | SCOR | High | Completed | S | SCOR-002, SCOR-003 | [SCOR-011](../shards/SCOR/SCOR-011-hole-editor-gross.md) |
| RNGE-010 | Range drill layout | RNGE | High | Not Started | M | RNGE-001, RNGE-002 | [RNGE-010](../shards/RNGE/RNGE-010-drill-layout.md) |
| CRSE-020 | Hole coordinate catalog | CRSE | High | Not Started | S | CRSE-005, CRSE-006 | [CRSE-020](../shards/CRSE/CRSE-020-hole-coordinate-catalog.md) |
| CRSE-021 | Live yards to the pin | CRSE | High | Not Started | M | CRSE-005 | [CRSE-021](../shards/CRSE/CRSE-021-live-yards-to-pin.md) |
| CRSE-022 | Hole map view | CRSE | Low | Not Started | L | CRSE-006 | [CRSE-022](../shards/CRSE/CRSE-022-hole-map-view.md) |
| RNGE-020 | Practice drill store | RNGE | High | Not Started | M | RNGE-003 | [RNGE-020](../shards/RNGE/RNGE-020-practice-drill-store.md) |
| RNGE-021 | Practice drill sheet | RNGE | High | Not Started | M | RNGE-003 | [RNGE-021](../shards/RNGE/RNGE-021-practice-drill-sheet.md) |
| RNGE-022 | Swing diary evaluation | RNGE | Low | Not Started | L | RNGE-004 | [RNGE-022](../shards/RNGE/RNGE-022-swing-diary.md) |
| RNGE-023 | Diary history ceiling | RNGE | Low | Not Started | M | RNGE-004 | [RNGE-023](../shards/RNGE/RNGE-023-diary-history-ceiling.md) |
| RNGE-024 | Evaluation log | RNGE | Low | Not Started | S | RNGE-004 | [RNGE-024](../shards/RNGE/RNGE-024-evaluation-log.md) |

## Code check

SHELL-001 is on main: `IndexedStack`, `shell-nav-bar` / `shell-tab-*`, My Bag `reload()` on select, and `loadScorecard()` on select.

SCOR-010 and SCOR-011 match the current scorecard and hole editor, including their keys. Two original SCOR-010 lines were already behind later commits and are corrected in the shard: a known course shows Par 3/4/5 on an unplayed tile, and Start new round uses the save/discard dialog then `startNewRound`. The widget test that opened `scorecard-hole-tile-1` is no longer in `widget_test.dart`.

BAG-010, CRSE-010, and RNGE-010 are still open. Each layout shipped in `7f5791f` and was overwritten by later feature commits, so the shard text was describing a screen that is no longer in the tree. The shards now name the current screen and what is still missing. Do not rebuild them by deleting the later behavior:

- BAG-010: category chips, note dialogs, header Add Club, and range logs are in `clubs_screen.dart`. Glance cards, em dashes for 0 yards, a notes sheet, a first-load spinner, and the `bag-category-chip-*` / `bag-club-card-*` keys are not.
- CRSE-010: simulator yards, hole resume, shot edit, venue lookup, and `applyCoursePar` are in `fairway_tracker_screen.dart`. The title is still `Fairway HUD`. Record shot scrolls with the form. Finish hole is a filled button. Permission denial is a snackbar, not `oncourse-location-banner`. The HUD does not show `Gimme`.
- RNGE-010: putters are excluded, Hit stops at 10, a counter of 0 saves as 10, and the venue field plus session log stay. The title is still `Range Drill Instructor`. There is no bag-baseline card, no save gating, and no `resolveDrillYardages`.

CRSE-020, CRSE-021, and CRSE-022 are unstarted. There is no `ph_golf_hole_coords.dart`, no yards-to-pin line, and no hole map.

RNGE-020 through RNGE-024 are unstarted. The database is still version 4. There is no `practice_drills` table and no Vertex client.

Build CRSE-020 before CRSE-021. CRSE-022 can wait. Build RNGE-020 before RNGE-021. RNGE-022, RNGE-023, and RNGE-024 can wait. RNGE-023 and RNGE-024 follow RNGE-022. CRSE-010 and RNGE-010 are layout rebuilds and do not block these shards. SHELL-001 no longer blocks BAG-010, CRSE-010, SCOR-010, or RNGE-010.
