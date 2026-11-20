# SHARD-CRSE-034: Unmapped tabular HUD & map fallback

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-034 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-011 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | CRSE-020, CRSE-021 |

## Description

Shipped for unmapped scoring. On FWY, CRSE-036 replaced the map toggle and embedded tabular card with a stand-in hole; SIM keeps the compact stack (CRSE-035).

When the venue is custom or the active hole lacks surveyed tee/green coordinates, **Course** mode shows the full scoring HUD without pin distance, map toggle, or error placeholders. Partial catalog courses turn off map/pin only on unmapped holes; mapped holes on the same round still get CRSE-005/009 when selected. If the player is offline and the course map pack is missing, the UI falls back to tabular HUD or the vector schematic (`oncourse-map-vector`) per Architecture §5.5 offline rules—never a blocking error state.

## Acceptance Criteria

- [x] Custom course name or `hasHoleCoordinates == false` for active hole: primary card uses `ValueKey('oncourse-hud-tabular')`; no `on-course-distance-to-hole`, no `on-course-map-toggle`, no “maps unavailable” error panel.
- [x] Partial course (e.g. Hallow Ridge): changing hole from unmapped → mapped shows pin line and map toggle; mapped → unmapped hides them without cancelling the round.
- [x] **Record shot at ball** remains available in Course mode with GPS when permitted; switching to Simulator still allows typed yards per `CRSE-031`.
- [x] Offline with no local map pack: one non-blocking snackbar (or inline hint on `oncourse-map-download`) and vector/tabular fallback; recording strokes continues.

## Test coverage

- [x] **Unit/widget:** Unknown course — assert `oncourse-hud-tabular` present and distance/map keys absent. Catalog mapped hole — distance key present. Hole step change toggles gating.
- [x] **Integration (if needed):** Optional: partial-course hole walk in widget test using real catalog names from `ph_golf_hole_coords.dart`.
- [x] **Keys:** `oncourse-hud-tabular`, `on-course-distance-to-hole`, `on-course-map-toggle`, `oncourse-map-vector` from wireframes; semantics label on tabular card for a11y.

## Dev notes

- Centralize gating helper used by CRSE-021 stream, map toggle (CRSE-033), and layout branch in `fairway_tracker_screen.dart` — must respect `_simulator` and `canonicalCourseName` from coords catalog.
- `hasHoleCoordinates` in `ph_golf_hole_coords.dart` is the single source of truth per Architecture §5.4.
- Aligns with CRSE-022 AC for vector fallback when pack missing; this shard owns **when** to show tabular-only vs allow map entry.
- No new Firebase calls required for unmapped paths.