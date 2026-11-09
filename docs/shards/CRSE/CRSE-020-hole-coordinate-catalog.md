# SHARD-CRSE-020: Hole coordinate catalog

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-020 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-005, CRSE-006 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | None |

## Description

Add a const Dart lookup of surveyed tee and green coordinates from `docs/context/PH_Golf_Course_Hole_Coordinates.md`. Names match `PhGolfCatalog` so a course the player already picked can be tested for a mapped hole. Holes without a survey are absent. Do not invent coordinates, and do not store centroids as pins.

## Acceptance Criteria

- [x] `holeCoordinates(courseName, holeNumber)` returns tee and green latitude and longitude for a fully mapped hole, using the same canonical name as the venue catalog.
- [x] The same call returns null for an unknown course, a course with no hole survey, a hole past the surveyed set, and a hole missing from a partial layout.
- [x] Lookup is trim and case-insensitive. A custom course name returns null.

## Test coverage

- [x] **Unit/widget:** `test/ph_golf_hole_coords_test.dart` covers one full layout, one partial hole that exists, one missing hole on that partial layout, and an unknown name.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** None. This shard has no widgets.

## Dev notes

- Add `golf_diary_app/lib/data/ph_golf_hole_coords.dart`. Architecture §5.4.
- Source of truth is the coordinates markdown, not a runtime parse of that file.
- Constraint: never fabricate hole coordinates (Architecture §9.4).
