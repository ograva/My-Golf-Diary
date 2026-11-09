# SHARD-SCOR-010: Scorecard hole tiles

| Field | Value |
| :--- | :--- |
| **Shard ID** | SCOR-010 |
| **Module** | SCOR — Scorecard |
| **Story Ref** | SCOR-001, SCOR-003 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | SHELL-001 |

## Description

Out / In / Total banner and Front 9 / Back 9 tiles are on `ScorecardScreen`. Tapping a tile opens the hole editor. Conceded holes show the word Gimme. Pull to refresh stays. The app bar has no refresh icon.

This layout has been on main since the design-system commit and survived the later scorecard commits. Two follow-ups changed the original shard text: a known course shows **Par 3 / 4 / 5** under an unplayed gross dash (`090b85b`), and Start new round asks to save or discard an in-progress round, then calls `startNewRound` (`32af013`). Completed rounds are kept. A 9-hole card hides Back 9.

## Acceptance Criteria

- [x] With a round selected, holes render as tiles (Back 9 hidden when the course is 9 holes). Unplayed gross is an em dash. A known course shows Par 3, 4, or 5 under that dash; an unknown course shows an em dash there too. Played holes show gross and versus par (`E`, `+n`, `-n`).
- [x] A conceded hole shows `Gimme` in addition to any fill color.
- [x] The summary shows front, back, and total versus par, plus penalty and mulligan totals when they are non-zero.
- [x] Empty history shows `scorecard-empty-state` and a start action. Round chips appear only when more than one round exists.
- [x] Loading uses a progress indicator. Tab focus and pull-to-refresh both call `loadScorecard()`.

## Test coverage

- [ ] **Unit/widget:** `scorecard-hole-tile-1` is in the tree after the scorecard loads. That assertion lived in `widget_test.dart` at `7f5791f` and is not in the current shell test.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `scorecard-round-chip-{roundId}`, `scorecard-summary-banner`, `scorecard-hole-tile-{n}`, `scorecard-new-round-btn`, `scorecard-empty-state`, `scorecard-loading` from `Wireframe_Scorecard.md`.

## Dev notes

- File: `golf_diary_app/lib/screens/scorecard_screen.dart`.
- Keep `effectiveHoleScore` and `isHolePlayed`.
- Versus-par text uses `GolfTextStyles.scorePositive` / `scoreNegative`.
