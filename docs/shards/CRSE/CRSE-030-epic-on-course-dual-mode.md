# SHARD-CRSE-030: On Course dual-mode (epic)

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-030 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-001, CRSE-002, CRSE-004, CRSE-007, CRSE-008, CRSE-009, CRSE-011, CRSE-035, CRSE-036 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | XL |
| **Depends On** | CRSE-021 |

## Description

Program epic for PRD v1.8 **On Course dual-mode enhancement**: one `FairwayTrackerScreen` with **Course** vs **Simulator** chips, shared round/hole/scoring chrome, and mode-specific capture rhythms. Child shards implement simulator post-shot fields (`CRSE-007`), course plan/aim/segment yards (`CRSE-008`), map/satellite HUD markers (`CRSE-009`), and unmapped tabular fallback plus offline map miss handling (`CRSE-011`). Incremental UI/layout deltas from Eunice v1.4 wireframes land in the child shards; no wholesale replacement of shipped CRSE-005 pin distance.

**Child shards (dependency order):**

| Order | Shard | Story | File |
| :---: | :--- | :--- | :--- |
| 1 | CRSE-034 | CRSE-011 | [CRSE-034-unmapped-tabular-map-fallback.md](./CRSE-034-unmapped-tabular-map-fallback.md) |
| 2 | CRSE-031 | CRSE-007 | [CRSE-031-simulator-post-shot-logging.md](./CRSE-031-simulator-post-shot-logging.md) |
| 3 | CRSE-032 | CRSE-008 | [CRSE-032-course-plan-aim-record.md](./CRSE-032-course-plan-aim-record.md) |
| 4 | CRSE-033 | CRSE-009 | [CRSE-033-map-satellite-hud-markers.md](./CRSE-033-map-satellite-hud-markers.md) |

Map imagery follows Architecture §5.5 (OSM packs, CRSE-041). CRSE-022’s toggle pane is superseded by CRSE-036. Child shards CRSE-031 through CRSE-036 are Completed in `golf_diary_app/`.

## Acceptance Criteria

- [x] Every child shard reaches **Ready for Review** or **Completed** without regressing CRSE-020/021 coordinate gating or SYNC-002 non-blocking sync.
- [x] Mode chip persistence and GPS stream lifecycle match [`Flow_OnCourse-Modes.md`](../../context/designs/Flow_OnCourse-Modes.md) (stop pin stream on Simulator; restart on Course when mapped).
- [x] PRD refinements to `CRSE-001` (venue/hole context), `CRSE-002` (dual capture), and `CRSE-004` (finish hole / holed rules) are satisfied by the union of child ACs; no separate route for Simulator.
- [x] All new interactive widgets use Eunice `ValueKey`s from `Wireframe_OnCourse.md`, `Wireframe_OnCourse-Simulator.md`, and `Wireframe_HoleMap.md`.

## Test coverage

- [x] **Unit/widget:** Epic closure = green `flutter test` for widgets added in CRSE-031–034; existing `fairway_tracker_screen_test.dart` (if present) updated per child.
- [x] **Integration (if needed):** One manual pass per [`Flow_OnCourse-Modes.md`](../../context/designs/Flow_OnCourse-Modes.md) § acceptance checklist after all children ship.
- [x] **Keys:** Cross-ref child shards; no new keys at epic level.

## Dev notes

- **Screen:** `golf_diary_app/lib/screens/fairway_tracker_screen.dart` — `_simulator` flag, `_recordShot`, `_beginPinWatch`, `recordFairwayHit` in `local_database_service.dart`.
- **Catalog / gating:** `ph_golf_hole_coords.dart` (`hasHoleCoordinates`), `ph_golf_catalog.dart`, `pin_distance.dart`.
- **Design:** [`UI_UX_Design_Guide.md`](../../context/UI_UX_Design_Guide.md) v1.4; skill-tier density defers to MGDV-202/203 where wireframes say tier-gated fields.
- Ship children in table order unless parallel work is isolated (031 can run beside 034).