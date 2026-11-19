# SHARD-CRSE-031: Simulator post-shot logging

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-031 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-007 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | None |

## Description

In **Simulator** mode, the HUD follows a post-shot rhythm: club and lie are set, then the player records the stroke with required **distance travelled** yards and optional simulator **carry**, **distance-to-hole**, and **stroke note**. No GPS read or permission prompt. Fields hide when switching to **Course** mode; hole stepper, par chips, penalties, and finish-hole behavior stay shared with Course mode per PRD `CRSE-002`/`CRSE-004` refinements.

## Acceptance Criteria

- [ ] With `oncourse-mode-simulator` selected, optional `oncourse-sim-carry-field` and `oncourse-sim-distance-to-hole-field` appear per wireframe (skill-tier may collapse behind `oncourse-sim-add-distance-link`); required `oncourse-sim-yards-field` must be valid (>0) before save; optional fields may be blank.
- [ ] `oncourse-sim-stroke-note-field` (or PRD alias `oncourse-stroke-note-field` mapped consistently in one key) persists text on the `ShotRecord` row for the stroke and reloads on hole change within the round.
- [ ] **Record stroke** (`oncourse-record-shot-btn`) saves typed yards without fabricated lat/lon; stroke list shows club and yards; no location banner or GPS call in Simulator mode.
- [ ] Switching to `oncourse-mode-course` hides simulator-only fields and restores **Record shot at ball** GPS rules from `CRSE-002`; switching back restores simulator layout without losing in-progress typed values on the form until saved.

## Test coverage

- [ ] **Unit/widget:** Widget test: Simulator mode, enter travelled yards, optional carry/note, tap record — row appears with `oncourse-shot-row-{n}`. Invalid zero yards shows validation copy and does not insert row.
- [ ] **Integration (if needed):** Toggle Course ↔ Simulator mid-round; confirm no Geolocator call in Simulator (mock).
- [ ] **Keys:** `oncourse-mode-simulator`, `oncourse-sim-yards-field`, `oncourse-sim-carry-field`, `oncourse-sim-distance-to-hole-field`, `oncourse-sim-stroke-note-field`, `oncourse-sim-add-distance-link`, `oncourse-sim-add-note-link`, `oncourse-record-shot-btn` from [`Wireframe_OnCourse-Simulator.md`](../../context/designs/Wireframe_OnCourse-Simulator.md) §7.

## Dev notes

- Extend `fairway_tracker_screen.dart` Simulator branch in `build` and `_recordShot`; gate with `_simulator`.
- `ShotRecord` already has `notes` in `golf_models.dart`; add nullable columns for simulator carry / distance-to-hole if not folded into `distanceYards` + notes — bump SQLite schema in `local_database_service.dart` with migration (local-first; sync fields optional).
- `recordFairwayHit` / insert path must accept simulator-only payloads (zero coords acceptable per Architecture §5 GPS rules for sim).
- Layout targets: sticky 64dp record dock, tier-gated optional fields per wireframe §8 vs as-built table.