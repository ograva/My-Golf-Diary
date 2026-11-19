# SHARD-CRSE-035: Compact On Course layout (Simulator stack + bottom sheets)

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-035 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-007, CRSE-008 (visual economy refinement) |
| **Priority** | High |
| **Status** | Ready for Review |
| **Complexity** | L |
| **Depends On** | CRSE-031, CRSE-032, CRSE-033 |

## Description

Implements the P0 items of the On Course visual economy audit v1.1 (Eunice / Reuben Simulator stack). The per-stroke loop must fit one viewport on ~390×844: a one-line course summary, a compact hole · par · mode row, club/lie summary pills that open **modal bottom sheets**, only the required **distance travelled** field always visible in Simulator, optional **Carry / To hole / Notes** revealed via chips with per-field hide, a single penalty · mulligan **stepper** row, and the existing sticky **Record** dock. Concede / Finish hole and the stroke list move below the fold (list collapsed). Course mode reuses rows 2, 3, 6 and 7 under a map-first pane; Aim becomes a third pill opening a sheet when the hole is mapped.

Supersedes the CRSE-031 tier-gated `oncourse-sim-add-distance-link` / `oncourse-sim-add-note-link` pattern and the 2×2 penalty / mulligan / concede grid from CRSE-030.

## Acceptance Criteria

- [x] **Row 1** `oncourse-course-summary` shows the course name on one line (+ catalog caption when known); tap opens `oncourse-course-sheet` with `oncourse-course-name-field` (`VenueNameField`, recents + catalog). Selecting or submitting a course applies catalog par / hole count and closes the sheet.
- [x] **Row 2** keeps `on-course-hole-previous` / `on-course-hole-next` chevrons; tapping `on-course-hole-label` opens `oncourse-hole-sheet` (hole list, read-only strokes / penalties / score; select pops). `oncourse-par-summary` opens `oncourse-par-sheet` with `oncourse-par-chip-3`…`5` (select pops). Mode chips `oncourse-mode-course` / `oncourse-mode-simulator` sit on the same row.
- [x] **Row 3** `oncourse-club-summary` and `oncourse-lie-summary` pills open `oncourse-club-sheet` / `oncourse-lie-sheet`. Club sheet lists **Recent** clubs (`oncourse-club-recent-{clubId}`) above all clubs (`oncourse-club-sheet-chip-{clubId}`); one tap selects and closes. Lie sheet chips keep `oncourse-lie-chip-{lie}`.
- [x] **Rows 4–5 (Simulator only)** `oncourse-sim-yards-field` is the only always-visible field (>0 required, CRSE-031 validation unchanged). Chips `oncourse-sim-carry-chip`, `oncourse-sim-to-hole-chip`, `oncourse-sim-notes-chip` reveal `oncourse-sim-carry-field`, `oncourse-sim-distance-to-hole-field`, `oncourse-sim-stroke-note-field`; each field's hide button (`…-hide-btn`) clears the value, removes the field and de-selects its chip. Optionals reset (hidden) after a successful record; club / lie persist.
- [x] **Row 6** penalty and mulligan steppers (`oncourse-penalty-step-down|up`, `oncourse-mulligan-step-down|up`, counts `oncourse-penalty-count` / `oncourse-mulligan-count`) on one row, in both modes; counts clamp at 0.
- [x] **Row 7** sticky `oncourse-record-shot-btn` dock is the only filled button; label and GPS rules per mode unchanged (CRSE-031 / CRSE-032).
- [x] Below the fold: `oncourse-concede-btn` and `oncourse-finish-hole-btn` (outlined), then `oncourse-shots-list-expander` “Shots this hole (n)”, collapsed by default; rows keep `oncourse-shot-row-{n}` and open `ShotEditDialog`.
- [x] **Course mode** hides rows 4–5; yards-to-pin (`on-course-distance-to-hole`) and the HUD / Map toggle (`on-course-map-toggle`) sit on a micro line under row 2 when mapped; Map fills the space above the plan rows. `oncourse-aim-summary` pill opens `oncourse-aim-sheet` (`oncourse-aim-left|center|right`) only on mapped holes. Switching back to Simulator restores the sim stack and in-progress values.
- [x] At 390×844 in Simulator mode, course summary, club pill, yards field, steppers and Record are all on screen without scrolling.

## Test coverage

- [x] **Widget:** 390×844 Simulator viewport — summary, club pill, yards field, steppers, Record visible with no scroll offset.
- [x] **Widget:** club sheet recent section + one-tap select pops; lie sheet select pops.
- [x] **Widget:** Carry / To hole / Notes chip reveal → hide clears value and de-selects chip.
- [x] **Widget:** penalty / mulligan steppers increment and decrement (clamped at 0).
- [x] **Regression:** CRSE-031 (sim validation, note persist), CRSE-032 (aim via sheet, simulator hides aim), CRSE-033 / CRSE-034 (map toggle, vector fallback, tabular HUD) suites updated for moved widgets and green.

## Dev notes

- `golf_diary_app/lib/screens/fairway_tracker_screen.dart` — rebuild `build` around the 7-row stack; sheets via `showModalBottomSheet`.
- `LocalDatabaseService.incrementMulligans` gains an optional delta (default `+1`, clamped ≥ 0) for the stepper; existing callers unchanged.
- Audit: Agent Store `docs/on-course-visual-economy-audit.md` v1.1 §2–§6 (ValueKeys §6). P1/P2 items (repeat last yards, hole-sheet concede/finish, tablet split, wireframe ASCII refresh) stay out of scope.
