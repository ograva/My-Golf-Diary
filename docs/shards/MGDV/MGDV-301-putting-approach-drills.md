# SHARD-MGDV-301: Putting & approach Range drills

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-301 |
| **Epic** | MGDV-3 |
| **Module** | RNGE |
| **Story Ref** | RNGE-003, v2 roadmap A2 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | MGDV-203 (Range copy baseline) |

## Description

Extend the seeded practice-drill catalog and Range UI for **Putting** (practice green) and **Approach** (range bay) short game. Distances persist in **yards**; putting may use small yard values (e.g. 3 ft ≈ 1 yd). Putter appears in the club strip only when a Putting-category drill is active.

## Acceptance Criteria

- [ ] `Range_Drills.md` and `practice_drill_seed.dart` include Putting (≥4) and Approach (≥3) drills with stable `rng-drl-*` ids.
- [ ] Drill sheet shows category filter chips including **Putting** and **Approach**, practice-area label, and **Beginner-friendly** chip where tagged.
- [ ] DB version bump seeds new drills on upgrade without reviving user-deleted drills (`INSERT OR IGNORE`).
- [ ] Range club strip shows **putter only** when Putting drill selected; Approach drills prioritize **wedge** clubs.
- [ ] Putting drill active shows yardage hint (yards in DB); save path unchanged (`RangeDrillLog`).
- [ ] `flutter analyze` and `flutter test` pass.

## Test coverage

- [ ] Unit: `clubsForRangeStrip` putter/approach filtering.
- [ ] Widget: Putting chip category + putter visible after drill pick; Driver hidden.
- [ ] Seed count matches `kPracticeDrillSeed.length`.

## Dev notes

- Keys: `range-drill-focus-strip`, `range-putting-yardage-hint`, `range-drills-chip-putting`, `range-drill-beginner-{id}`.
- Shard supersedes MGDV-203 AC item deferring putter to MGDV-3.