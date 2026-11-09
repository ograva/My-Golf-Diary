# SHARD-CRSE-021: Live yards to the pin

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-021 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-005 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | CRSE-020 |

## Description

Show remaining yards from the phone to the current hole’s green while On Course is in Course mode and that hole has coordinates. Hide the line in Simulator mode, on a custom or unmapped course, and on an unmapped hole. The readout uses a short location stream and stops when the screen is not the place that should be tracking.

## Acceptance Criteria

- [ ] On a mapped hole in Course mode, the HUD shows whole yards labeled `yds to pin` (`on-course-distance-to-hole`). The value is `distanceBetween` meters times `1.09361`, rounded.
- [ ] Simulator mode, a custom course, and a hole with no green coordinate do not build that text. There is no error placeholder.
- [ ] The location stream uses a distance filter of about 3 meters and is cancelled when the widget is disposed, the mode switches to Simulator, or the hole or course becomes unmapped.
- [ ] A denied location permission hides the yardage and keeps the existing shot-tracking message. Recording a shot still works as it does today.

## Test coverage

- [ ] **Unit/widget:** Widget test with a fake position stream. Selecting a mapped course shows the key and a known yardage. Switching to Simulator removes the key. An unknown course name leaves the key absent.
- [ ] **Integration (if needed):** Not required. Do not call a live GPS fix in tests.
- [ ] **Keys:** `on-course-distance-to-hole` from `Wireframe_OnCourse.md` §7 and §9. Semantics label: "Yards to the pin".

## Dev notes

- Files: `golf_diary_app/lib/screens/fairway_tracker_screen.dart`, `ph_golf_hole_coords.dart`.
- Ship on the current Fairway HUD. CRSE-010 is superseded, so do not wait for a layout rebuild.
- Do not start a stream on the web build if `Geolocator` cannot provide a position; hide the line.
- Yards stay the display unit (Architecture §5.1, §9.3).
