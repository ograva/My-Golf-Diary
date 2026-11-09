# SHARD-CRSE-022: Hole map view

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-022 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-006 |
| **Priority** | Low |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | CRSE-020 |

## Description

Let the player switch the On Course pane from the HUD to a hole map when that hole has a tee and a green. The map draws those two points and the saved shots for the hole. Course imagery is downloaded once into Firebase Storage and then onto the device. Without a downloaded photo, and without a network, the pane still draws the tee-to-green line and the shots.

This shard is future work. Do not add the Google Maps or Storage packages until this shard is started.

## Acceptance Criteria

- [ ] `on-course-map-toggle` is present only when the current hole has tee and green coordinates, and only in Course mode.
- [ ] The map pane plots the tee, the green, and each `ShotRecord` from start to end for the open hole. A new shot appears without leaving the map.
- [ ] A course pack stored on the device is used offline. A missing pack on a network downloads from Firebase Storage under `course_maps/{courseId}/` and is kept locally.
- [ ] Offline with no pack shows the vector line (`oncourse-map-vector`) and one snackbar that the course photo is not on the phone. Record shot stays available.

## Test coverage

- [ ] **Unit/widget:** Toggle hidden for an unmapped hole. Toggle visible for a mapped hole. Vector fallback renders when the local pack is absent and the storage client returns unavailable.
- [ ] **Integration (if needed):** One device pass: download a pack on Wi-Fi, enable airplane mode, reopen the hole, and confirm the photo still draws.
- [ ] **Keys:** `on-course-map-toggle`, `oncourse-hole-map`, `oncourse-map-download`, `oncourse-map-vector` from `Wireframe_HoleMap.md`.

## Dev notes

- Layout: `docs/context/designs/Wireframe_HoleMap.md`. Architecture §5.5 and §7 Storage rules.
- Do not put a Google Maps secret in the repo. Writes to Storage are for the cache builder, not every signed-in golfer.
- Record shot remains the filled primary. The map does not replace it.
