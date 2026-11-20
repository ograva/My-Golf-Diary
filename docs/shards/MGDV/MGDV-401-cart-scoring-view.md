# SHARD-MGDV-401: Scorecard cart scoring view

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-401 |
| **Epic** | MGDV-4 |
| **Module** | SCOR |
| **Story Ref** | MGDV-401, SCOR-004 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | SCOR-010, SCOR-011 (on main) |

## Description

Add a **Cart scoring** layout on the **Scorecard tab** alongside the existing **Classic** 9/18 grid. On Course (CRSE) is unchanged. Reuse `round_scores`, `LocalDatabaseService` penalty/mulligan/concede paths, and existing totals computation. Persist view mode and optional high-contrast cart theme on `golfer_profile` (DB v13).

## Acceptance Criteria

- [x] Scorecard shows **Classic** vs **Cart scoring** toggle when a round list is visible; choice persists across relaunch (`golfer_profile.scorecard_view_mode`).
- [x] **Cart scoring**: horizontal hole 1–N strip (N = course hole count), large stroke display, **+1 stroke**, **Penalty +1**, **Mulligan**, **Gimme/concede** with min 56 dp targets.
- [x] Running **OUT / IN / TOT** vs par banner in cart view matches `computeRoundTotals`.
- [x] Known mapped courses show **tee-to-green yards** on the hole header (catalog coordinates).
- [x] **High contrast** toggle for sun readability; persisted (`scorecard_cart_high_contrast`).
- [x] **Wakelock** enabled while **Cart scoring** + in-progress round; disabled otherwise (`wakelock_plus`).
- [x] `flutter analyze` and `flutter test` pass from `golf_diary_app/`.

## Test coverage

- [x] Widget: cart toggle visible; +1 updates gross on screen.
- [x] Unit: `incrementStrokes` / `ensureHoleRow` on test DB.
- [x] Unit: `catalogTeeToGreenYards` for Intramuros hole 1.

## Keys

| Key | Control |
| :--- | :--- |
| `scorecard-view-mode-toggle` | `SegmentedButton` |
| `scorecard-cart-hole-strip-{n}` | Hole strip chip |
| `scorecard-cart-hole-{n}` | Current hole title |
| `scorecard-cart-stroke-count` | Giant gross |
| `scorecard-cart-stroke-plus` | +1 stroke |
| `scorecard-cart-penalty` | Penalty |
| `scorecard-cart-mulligan` | Mulligan |
| `scorecard-cart-gimme` | Concede |
| `scorecard-cart-high-contrast-switch` | High contrast |
| `scorecard-cart-totals-banner` | OUT/IN/TOT |

## Dev notes

- Files: `scorecard_screen.dart`, `widgets/scorecard_cart_panel.dart`, `models/scorecard_preferences.dart`.
- DB v13 columns on `golfer_profile`; methods `ensureHoleRow`, `incrementStrokes`.