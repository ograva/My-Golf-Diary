# SHARD-CRSE-032: Course plan, aim & record at ball

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-032 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-008 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | CRSE-020 |

## Description

In **Course** mode, club and lie chips plan the next stroke. On mapped holes, an optional **aim** control (`oncourse-aim-left` / `oncourse-aim-center` / `oncourse-aim-right` or PRD `oncourse-aim-bearing`) is saved on the shot when set. **Record shot at ball** takes a single sparse GPS fix; the stroke list shows **segment yards** between successive ball positions on the hole using the same Haversine helper as live pin distance. Penalties, mulligans, and concede from `CRSE-003` still drive hole gross without double-counting strokes.

## Acceptance Criteria

- [ ] **Course** mode only: aim wedge visible when `hasHoleCoordinates(course, hole)` is true; selection persists on save and reloads when editing a stroke; hidden on unmapped holes and in Simulator mode.
- [ ] `oncourse-record-shot-btn` label reads **Record shot at ball** in Course mode; one `getCurrentPosition` (or existing `_readGps` pattern) per tap; denied permission shows snackbar + optional `oncourse-location-banner` without crash.
- [ ] When stroke *n* and *n−1* on the active hole both have coordinates, `oncourse-shot-row-{n}` displays segment yards (rounded whole yards); otherwise shows **Distance pending** or omits segment per wireframe.
- [ ] Stroke count increments from shot rows; applying penalty/mulligan/concede updates `RoundScore` totals consistently with manual shot count (no duplicate stroke inflation).

## Test coverage

- [ ] **Unit/widget:** Fake GPS positions two taps apart; assert segment yards on second row. Aim chips fire save with expected stored value. Unmapped hole hides aim wedge.
- [ ] **Integration (if needed):** Optional golden path on one mapped catalog hole with permission granted (device/manual).
- [ ] **Keys:** `oncourse-aim-left`, `oncourse-aim-center`, `oncourse-aim-right`, `oncourse-record-shot-btn`, `oncourse-shot-row-{strokeNumber}`, `oncourse-club-chip-{id}`, `oncourse-lie-chip-{lie}` from [`Wireframe_OnCourse.md`](../../context/designs/Wireframe_OnCourse.md) §7; flow refs in [`Flow_OnCourse-Modes.md`](../../context/designs/Flow_OnCourse-Modes.md).

## Dev notes

- Reuse `Geolocator.distanceBetween` × `1.09361` pattern from `pin_distance.dart` / CRSE-021.
- Store aim as enum or degrees on `ShotRecord` (new column + migration); map to sync JSON when dirty.
- `_recordShot`, `_shots` list UI in `fairway_tracker_screen.dart`; `ShotEditDialog` if aim editable post-hoc.
- Optional `oncourse-yards-to-marker` readout on map-first layout ties to aim target; defer full map chrome to CRSE-033.