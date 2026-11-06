# SHARD-SCOR-010: Scorecard hole tiles

| Field | Value |
| :--- | :--- |
| **Shard ID** | SCOR-010 |
| **Module** | SCOR — Scorecard |
| **Story Ref** | SCOR-001, SCOR-003 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | SHELL-001 |

## Description

Replace the six-column score table with an Out / In / Total banner and Front 9 / Back 9 tiles. Tapping a tile still opens the hole editor. Conceded holes show the word Gimme. Pull to refresh stays. The app bar refresh icon goes away. Starting a round still uses `ensureActiveRound` and does not delete older rounds.

## Acceptance Criteria

- [ ] With a round selected, holes 1–18 render as tiles. Unplayed holes show an em dash. Played holes show gross and versus par (`E`, `+n`, `-n`).
- [ ] A conceded hole shows `Gimme` in addition to any fill color.
- [ ] The summary shows front, back, and total versus par, plus penalty and mulligan totals when they are non-zero.
- [ ] Empty history shows `scorecard-empty-state` and a start action. Round chips appear only when more than one round exists.
- [ ] Loading uses a progress indicator. Tab focus and pull-to-refresh both call `loadScorecard()`.

## Test coverage

- [ ] **Unit/widget:** `scorecard-hole-tile-1` is in the tree after the scorecard loads.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `scorecard-round-chip-{roundId}`, `scorecard-summary-banner`, `scorecard-hole-tile-{n}`, `scorecard-new-round-btn`, `scorecard-empty-state`, `scorecard-loading` from `Wireframe_Scorecard.md`.

## Dev notes

- File: `golf_diary_app/lib/screens/scorecard_screen.dart`.
- Keep `effectiveHoleScore` and `isHolePlayed`.
- Versus-par text uses `GolfTextStyles.scorePositive` / `scoreNegative`.
