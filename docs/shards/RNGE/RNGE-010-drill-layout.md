# SHARD-RNGE-010: Range drill layout

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-010 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-001, RNGE-002 |
| **Priority** | High |
| **Status** | Superseded |
| **Complexity** | M |
| **Depends On** | SHELL-001 |

## Description

Range already excludes putters, counts hits up to 10, saves a counter of 0 as 10 balls, names the club in the success snackbar, clears the yardage fields, and leaves the tempo note in place. The venue field and the session log (this club / all clubs) are on the screen and stay.

Superseded on 2026-11-09. The current Range screen is the accepted baseline, including the title `Range Drill Instructor`, always-enabled save, and empty min or max stored as 0. Do not rebuild this layout. RNGE-021 adds the drill sheet on this screen.

## Acceptance Criteria

- [ ] Putters are excluded. The selected club shows current min / avg / max, using an em dash when a value is 0.
- [ ] Hit increments up to 10 and then disables. The counter readout is tabular.
- [ ] Save is disabled when avg is missing, non-numeric, negative, or out of order with min and max. Empty min or max is replaced with avg in the log.
- [ ] Success snackbar names the club. Counter and yardage fields clear. The tempo field remains. The baseline card reloads.
- [ ] No non-putter clubs shows `range-empty-clubs` and hides save.

## Test coverage

- [ ] **Unit/widget:** `resolveDrillYardages` covers empty sides, bad order, and a valid triple. The range screen exposes `range-save-drill-btn` and `range-shot-counter-increment`.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `range-club-chip-{clubId}`, `range-bag-baseline`, `range-tempo-field`, `range-shot-counter-increment`, `range-shot-counter`, `range-min-field`, `range-avg-field`, `range-max-field`, `range-save-drill-btn`, `range-empty-clubs` from `Wireframe_Range.md`.

## Dev notes

- File: `golf_diary_app/lib/screens/range_drill_screen.dart`.
- Do not edit the min/max/avg blend in `LocalDatabaseService.saveRangeDrill`.
- Field label: tempo for this drill, with helper text that a non-empty note updates the club cue.
- Keep `VenueNameField` and `RangeSessionLog`. RNGE-021 also depends on both.
