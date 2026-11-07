# SHARD-SHELL-001: Keep tab state

| Field | Value |
| :--- | :--- |
| **Shard ID** | SHELL-001 |
| **Module** | App shell (cross-cutting; no PRD prefix) |
| **Story Ref** | None |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | S |
| **Depends On** | None |

## Description

`HomeShell` currently mounts only the selected page, so leaving On Course or Range disposes in-progress state. Keep all four tabs alive, give each destination a stable key, and reload My Bag when that tab is selected. Scorecard already reloads on select.

## Acceptance Criteria

- [ ] The four screens stay mounted while the user switches tabs (`IndexedStack`).
- [ ] Selecting My Bag calls a public reload on `ClubsScreen`. Selecting Scorecard still calls `loadScorecard()`.
- [ ] Navigation bar and destinations expose `shell-nav-bar` and `shell-tab-*` keys.
- [ ] Launch still opens On Course. The widget test no longer expects the title `Fairway HUD`.

## Test coverage

- [ ] **Unit/widget:** `test/widget_test.dart` finds `shell-nav-bar`, `shell-tab-oncourse`, and `oncourse-record-shot-btn` after `pumpWidget(GolfDiaryApp)`.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `shell-nav-bar`, `shell-tab-bag`, `shell-tab-oncourse`, `shell-tab-scorecard`, `shell-tab-range` from `docs/context/designs/Wireframe_HomeShell.md`.

## Dev notes

- File: `golf_diary_app/lib/main.dart`.
- `ClubsScreen` needs a public `State` type and `reloadClubs()`, same pattern as `ScorecardScreenState`.
- Default index remains `1`.
