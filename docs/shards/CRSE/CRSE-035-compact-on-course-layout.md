# SHARD-CRSE-035: Compact On Course layout (Simulator stack + bottom sheets)

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-035 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-007, CRSE-008 (visual economy refinement) |
| **Priority** | High |
| **Status** | Ready for Review |
| **Revision** | r4 — course meta line under the name; Club + Lie as one full-width row of 56dp selectors; Penalty and Mulligan on their own full-width rows (r3: stroke log after Concede / Finish hole; r2: FWY/SIM toggle on course row, stats under hole row, Concede/Finish under Record) |
| **Complexity** | L |
| **Depends On** | CRSE-031, CRSE-032, CRSE-033 |

## Description

Implements the P0 items of the On Course visual economy audit v1.1 (Eunice / Reuben Simulator stack). The per-stroke loop must fit one viewport on ~390×844: a course-name row with a right-aligned **FWY / SIM** segmented toggle and the hole count · par on its own line beneath, a compact hole · par row followed by the hole summary row (strokes / penalties / score / round total), a full-width row of large Club and Lie selectors that open **modal bottom sheets**, only the required **distance travelled** field always visible in Simulator, optional **Carry / To hole / Notes** revealed via chips with per-field hide, full-width penalty and mulligan **stepper** rows, and the **Record** dock (anchored at the bottom of the first viewport) with Concede / Finish hole directly beneath it. The hole's stroke log follows directly after the Concede / Finish hole row and may overflow below the fold. Course mode reuses rows 2, 3, 6 and 7 under a map-first pane; Aim becomes a third selector on the Club / Lie row, opening a sheet, when the hole is mapped.

Supersedes the CRSE-031 tier-gated `oncourse-sim-add-distance-link` / `oncourse-sim-add-note-link` pattern and the 2×2 penalty / mulligan / concede grid from CRSE-030.

## Acceptance Criteria

- [x] **Row 1** `oncourse-course-summary` holds only the course name and edit icon; tap opens `oncourse-course-sheet` with `oncourse-course-name-field` (`VenueNameField`, recents + catalog). Selecting or submitting a course applies catalog par / hole count and closes the sheet. The same row ends with a right-aligned two-segment `SegmentedButton` (`oncourse-mode-toggle`) labelled **FWY** / **SIM** (segment labels keyed `oncourse-mode-course` / `oncourse-mode-simulator`; screen-reader labels **Fairway** / **Simulator**). When the catalog knows the course, `oncourse-course-meta` (e.g. “18 holes · Par 72”) sits on its own line directly under the name.
- [x] **Row 2** keeps `on-course-hole-previous` / `on-course-hole-next` chevrons; tapping `on-course-hole-label` opens `oncourse-hole-sheet` (hole list, read-only strokes / penalties / score; select pops). `oncourse-par-summary` opens `oncourse-par-sheet` with `oncourse-par-chip-3`…`5` (select pops). Hole and Par share this row.
- [x] **Row 2a** `oncourse-hole-stats-row` (Strokes · Penalties · Score · Round total) sits directly under the hole row.
- [x] **Row 3** `oncourse-club-summary` and `oncourse-lie-summary` share one full-width row (equal widths, each ≥56dp tall, small label over the bold value) and open `oncourse-club-sheet` / `oncourse-lie-sheet`. Club sheet lists **Recent** clubs (`oncourse-club-recent-{clubId}`) above all clubs (`oncourse-club-sheet-chip-{clubId}`); one tap selects and closes. Lie sheet chips keep `oncourse-lie-chip-{lie}`.
- [x] **Rows 4–5 (Simulator only)** `oncourse-sim-yards-field` is the only always-visible field (>0 required, CRSE-031 validation unchanged). Chips `oncourse-sim-carry-chip`, `oncourse-sim-to-hole-chip`, `oncourse-sim-notes-chip` reveal `oncourse-sim-carry-field`, `oncourse-sim-distance-to-hole-field`, `oncourse-sim-stroke-note-field`; each field's hide button (`…-hide-btn`) clears the value, removes the field and de-selects its chip. Optionals reset (hidden) after a successful record; club / lie persist.
- [x] **Row 6** penalty and mulligan steppers (`oncourse-penalty-step-down|up`, `oncourse-mulligan-step-down|up`, counts `oncourse-penalty-count` / `oncourse-mulligan-count`) each on its own full-width row (label left, − count + right), in both modes; counts clamp at 0.
- [x] **Row 7** `oncourse-record-shot-btn` dock (bottom of the first viewport; scrolls up only when the user scrolls to the stroke log) is the only filled button; label and GPS rules per mode unchanged (CRSE-031 / CRSE-032). `oncourse-concede-btn` and `oncourse-finish-hole-btn` (outlined, same height) sit directly under Record in the dock with an 8dp gap.
- [x] The page is one scroll view: the form plus the Record / Concede / Finish dock fill the first viewport (dock anchored at its bottom), and the stroke log `oncourse-shots-list-expander` “Shots this hole (n)” sits directly after the Concede / Finish hole row, expanded by default and allowed to overflow below the fold; rows keep `oncourse-shot-row-{n}` and open `ShotEditDialog`.
- [x] **Course mode** hides rows 4–5; yards-to-pin (`on-course-distance-to-hole`) and the HUD / Map toggle (`on-course-map-toggle`) sit on a micro line under row 2 when mapped; Map fills the space the form and dock leave free (min 160dp, max 520dp), so the card never pushes Record / Concede / Finish below the fold. `oncourse-aim-summary` (third selector on the Club / Lie row) opens `oncourse-aim-sheet` (`oncourse-aim-left|center|right`) only on mapped holes. Switching back to Simulator restores the sim stack and in-progress values.
- [x] At 390×844 in Simulator mode, with the 80dp bottom navigation bar the app shell adds, every control above the stroke log (course summary + mode toggle, hole row, stats row, Club / Lie, yards field, optional chips, both steppers, Record, Concede and Finish hole) is on screen without scrolling. The stroke log may overflow.

## Test coverage

- [x] **Widget:** 390×844 Simulator viewport inside an 80dp bottom bar — every control through Record / Concede / Finish above the bar with no scroll offset; Club + Lie on one row (same centre, ≥56dp, spanning the width); Penalty / Mulligan on separate full-width rows; asserts toggle on the course row (right-aligned, FWY/SIM text, Fairway/Simulator semantics), Hole + Par on one row, stats row under it, Concede / Finish ≤12dp under Record.
- [x] **Widget:** catalog course shows `oncourse-course-meta` under the name (not inside the name row), toggle stays on the name row.
- [x] **Widget:** 390×844 Fairway, Map selected on a mapped hole (Sherwood H1) — no scroll offset, card above Record, Finish above the bottom bar.
- [x] **Widget:** club sheet recent section + one-tap select pops; lie sheet select pops.
- [x] **Widget:** Carry / To hole / Notes chip reveal → hide clears value and de-selects chip.
- [x] **Widget:** 390×844 after one stroke — no scroll offset with Record / Finish on screen; scrolling reveals the stroke log ≤16dp after the Concede / Finish row.
- [x] **Widget:** penalty / mulligan steppers increment and decrement (clamped at 0).
- [x] **Regression:** CRSE-031 (sim validation, note persist), CRSE-032 (aim via sheet, simulator hides aim), CRSE-033 / CRSE-034 (map toggle, vector fallback, tabular HUD) suites updated for moved widgets and green.

## Dev notes

- `golf_diary_app/lib/screens/fairway_tracker_screen.dart` — rebuild `build` around the 7-row stack; sheets via `showModalBottomSheet`.
- `LocalDatabaseService.incrementMulligans` gains an optional delta (default `+1`, clamped ≥ 0) for the stepper; existing callers unchanged.
- Audit: Agent Store `docs/on-course-visual-economy-audit.md` v1.1 §2–§6 (ValueKeys §6). P1/P2 items (repeat last yards, hole-sheet concede/finish, tablet split, wireframe ASCII refresh) stay out of scope.
