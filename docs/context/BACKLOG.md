# Backlog — My Golf Diary

Index only. Shard bodies live under `docs/shards/`.

Checked against the working tree on 2026-11-11, after RNGE-005 was specified in the PRD, Architecture, and Range wireframes.

| Shard ID | Title | Module | Priority | Status | Complexity | Story Ref | File |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| SHELL-001 | Keep tab state | Shell | High | Completed | S | None | [SHELL-001](../shards/SHELL/SHELL-001-keep-tab-state.md) |
| BAG-010 | Glance club cards | BAG | High | Superseded | M | BAG-001, BAG-002, BAG-003 | [BAG-010](../shards/BAG/BAG-010-glance-cards.md) |
| CRSE-010 | On Course HUD | CRSE | High | Superseded | L | CRSE-001–004, SYNC-002 | [CRSE-010](../shards/CRSE/CRSE-010-on-course-hud.md) |
| SCOR-010 | Scorecard hole tiles | SCOR | High | Completed | M | SCOR-001, SCOR-003 | [SCOR-010](../shards/SCOR/SCOR-010-hole-tiles.md) |
| SCOR-011 | Hole editor gross preview | SCOR | High | Completed | S | SCOR-002, SCOR-003 | [SCOR-011](../shards/SCOR/SCOR-011-hole-editor-gross.md) |
| RNGE-010 | Range drill layout | RNGE | High | Superseded | M | RNGE-001, RNGE-002 | [RNGE-010](../shards/RNGE/RNGE-010-drill-layout.md) |
| CRSE-020 | Hole coordinate catalog | CRSE | High | Completed | S | CRSE-005, CRSE-006 | [CRSE-020](../shards/CRSE/CRSE-020-hole-coordinate-catalog.md) |
| CRSE-021 | Live yards to the pin | CRSE | High | Completed | M | CRSE-005 | [CRSE-021](../shards/CRSE/CRSE-021-live-yards-to-pin.md) |
| CRSE-022 | Hole map view | CRSE | Low | Not Started | L | CRSE-006 | [CRSE-022](../shards/CRSE/CRSE-022-hole-map-view.md) |
| RNGE-020 | Practice drill store | RNGE | High | Completed | M | RNGE-003 | [RNGE-020](../shards/RNGE/RNGE-020-practice-drill-store.md) |
| RNGE-021 | Practice drill sheet | RNGE | High | Completed | M | RNGE-003 | [RNGE-021](../shards/RNGE/RNGE-021-practice-drill-sheet.md) |
| RNGE-025 | Range session store | RNGE | High | Not Started | M | RNGE-005 | [RNGE-025](../shards/RNGE/RNGE-025-range-session-store.md) |
| RNGE-026 | Range session wrap-up | RNGE | High | Not Started | M | RNGE-005 | [RNGE-026](../shards/RNGE/RNGE-026-range-session-wrapup.md) |
| RNGE-022 | Swing diary evaluation | RNGE | Low | Not Started | L | RNGE-004 | [RNGE-022](../shards/RNGE/RNGE-022-swing-diary.md) |
| RNGE-023 | Diary history ceiling | RNGE | Low | Not Started | M | RNGE-004 | [RNGE-023](../shards/RNGE/RNGE-023-diary-history-ceiling.md) |
| RNGE-024 | Evaluation log | RNGE | Low | Not Started | S | RNGE-004 | [RNGE-024](../shards/RNGE/RNGE-024-evaluation-log.md) |

## Code check

SHELL-001 is on main: `IndexedStack`, `shell-nav-bar` / `shell-tab-*`, My Bag `reload()` on select, and `loadScorecard()` on select.

SCOR-010 and SCOR-011 match the current scorecard and hole editor, including their keys. Two original SCOR-010 lines were already behind later commits and are corrected in the shard: a known course shows Par 3/4/5 on an unplayed tile, and Start new round uses the save/discard dialog then `startNewRound`. The widget test that opened `scorecard-hole-tile-1` is no longer in `widget_test.dart`.

BAG-010, CRSE-010, and RNGE-010 are superseded. The current My Bag, Fairway HUD, and Range screens stay as they are. SCOR-010 was already the current scorecard, so it stays Completed.

CRSE-020 and CRSE-021 are done. A mapped hole on the Fairway HUD shows whole yards to the pin. Simulator mode, a custom course, an unmapped hole, and a missing location fix hide that line. The coordinate catalog is `ph_golf_hole_coords.dart`.

RNGE-020 and RNGE-021 are done. The database is version 5. `practice_drills` is seeded from the reference catalog, and a player can add or hide a drill from the Range sheet. The next saved range session stores that drill id. `practice_drills` is still outside `syncFull`.

Next to build:

- RNGE-025, then RNGE-026: the session note and compiled range session log (`RNGE-005`). These do not call Vertex.
- RNGE-022, then RNGE-023 and RNGE-024: the Vertex swing diary (`RNGE-004`). RNGE-022 now waits on the compiled session from RNGE-026.
- CRSE-022: the hole map (`CRSE-006`). It does not block the range session work.
