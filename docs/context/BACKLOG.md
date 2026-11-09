# Backlog — My Golf Diary

Index only. Shard bodies live under `docs/shards/`.

Checked against `main` at `0c151da` on 2026-11-09.

| Shard ID | Title | Module | Priority | Status | Complexity | Story Ref | File |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| SHELL-001 | Keep tab state | Shell | High | Completed | S | None | [SHELL-001](../shards/SHELL/SHELL-001-keep-tab-state.md) |
| BAG-010 | Glance club cards | BAG | High | Superseded | M | BAG-001, BAG-002, BAG-003 | [BAG-010](../shards/BAG/BAG-010-glance-cards.md) |
| CRSE-010 | On Course HUD | CRSE | High | Superseded | L | CRSE-001–004, SYNC-002 | [CRSE-010](../shards/CRSE/CRSE-010-on-course-hud.md) |
| SCOR-010 | Scorecard hole tiles | SCOR | High | Completed | M | SCOR-001, SCOR-003 | [SCOR-010](../shards/SCOR/SCOR-010-hole-tiles.md) |
| SCOR-011 | Hole editor gross preview | SCOR | High | Completed | S | SCOR-002, SCOR-003 | [SCOR-011](../shards/SCOR/SCOR-011-hole-editor-gross.md) |
| RNGE-010 | Range drill layout | RNGE | High | Superseded | M | RNGE-001, RNGE-002 | [RNGE-010](../shards/RNGE/RNGE-010-drill-layout.md) |
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

BAG-010, CRSE-010, and RNGE-010 are superseded. The current My Bag, Fairway HUD, and Range screens stay as they are. SCOR-010 was already the current scorecard, so it stays Completed.

The remaining work is PRD v1.3 / v1.4 and Architecture §5.4–§5.6:

- CRSE-020, then CRSE-021: live yards to the pin (`CRSE-005`). CRSE-022 is the later hole map (`CRSE-006`).
- RNGE-020, then RNGE-021: the practice drill catalog (`RNGE-003`).
- RNGE-022, then RNGE-023 and RNGE-024: the Vertex swing diary (`RNGE-004`). These can wait.

None of those shards are started. There is no `ph_golf_hole_coords.dart`, no yards-to-pin line, and no hole map. The database is still version 4. There is no `practice_drills` table and no Vertex client.
