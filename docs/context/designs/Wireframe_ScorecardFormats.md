# Wireframe — Scorecard formats & attestation (MGDV-601)

| Field | Value |
| :--- | :--- |
| **Widgets** | Shared course dialog, `ScorecardCartPanel` format line, `showScorecardHoleEditor` |
| **Stories** | [MGDV-601](../../stories/MGDV/MGDV-601-scoring-formats-epic.md) |
| **Persona** | Rory — tournament-style scoring and card sign-off |
| **Status** | Course dialog shared with On Course (2026-11-24) |

## 1. Purpose

Gross stays the stored stroke count; **Molave** and **System 36** are **derived** totals. Optional course rating/slope feed an **Unofficial estimate** handicap line after three rated 18-hole rounds. **Attest card** locks the round until an edit clears attestation.

## 2. Format in the shared course dialog

Scorecard and On Course open one dialog. Title **Course**. See [Wireframe_NewRound.md](./Wireframe_NewRound.md).

```
┌─────────────────────────────────────────┐
│ Course                                  │
│ Course name                             │
│ [ Wack Wack — East          ]           │
│ [ Gross | Molave | System 36 ]          │  scorecard-format-toggle
│ Double eagle  [7] [6]                   │  Molave only
│ Rating [66.0]  Slope [113]              │  scorecard-course-rating, -slope
│              Cancel              Save   │
└─────────────────────────────────────────┘
```

Under the course name on the scorecard, read-only indicators (`bodySmall`):

- Format name. Molave adds `· double eagle 7` or `6`.
- `CR 72.1 · Slope 130` only when a rating or slope is set.
- `Unofficial estimate …` only when an estimate exists (`scorecard-handicap-estimate`).

The OUT / IN / TOT banner keeps the score. Its format sentence uses `scorecard-format-total`. Cart view keeps `scorecard-cart-format-total`. The name row does not repeat that sentence.

### Attestation (below the card)

Shown only after the round is finished. **Finish round** (`scorecard-finish-round`) opens the attest sheet right away; **Skip** leaves the round finished and unattested. **Attested score PDF** (`scorecard-attest-pdf-link`) shows under the badge only after the function returns a file. See [Wireframe_Scorecard.md](./Wireframe_Scorecard.md) § Round controls.

```
│ FRONT 9 / BACK 9 or cart                │
│ Attested by Pat · marker                │  scorecard-attest-badge, finished only
│ [ Finish round ]  or  [ Attest card ]   │  one primary slot
│ [ Start new round ] [ Delete round ]    │
```

- Open round: **Finish round** only. No badge.
- Finished, not attested: badge **Not attested** and **Attest card**.
- Attested: badge, plus **Attested score PDF** only when `attest_pdf_path` is set.
- Edited after attest (after **Edit finished round**): **Edited after attest** and **Attest card** again.

### Tokens

- Format toggle: `SegmentedButton`, one segment selected, no stroke rewrite on change. Same keys from Scorecard and On Course.
- Handicap line: always prefixed **Unofficial estimate** — never NGAP official copy.
- Attest dialog keys: `scorecard-attest-name`, `scorecard-attest-role`, `scorecard-attest-save`, `scorecard-attest-skip` (reads **Skip** after Finish, **Cancel** otherwise).
- Edit while attested: `scorecard-attest-edit-confirm` before the course dialog writes, and before cart/hole mutations.
- Flight: leading overflow, `scorecard-flight-btn`. Not under the course name.

## 3. Cart panel

When cart view is active, `_CartTotalsBar` may show format summary via `scorecard-cart-format-total` under classic totals.

## 4. Hole editor (paid mulligan)

Switch `hole-editor-paid-mulligan` — one per nine, excluded from gross and HIO points. Molave live points: `hole-editor-molave-points`. Triple pick-up confirm: `scorecard-molave-pickup`.

See [Wireframe_HoleEditor.md](./Wireframe_HoleEditor.md).

## 5. Key map

| Element | ValueKey |
| :--- | :--- |
| Format toggle | `scorecard-format-toggle` (shared course dialog) |
| Format total | `scorecard-format-total` |
| Double eagle | `scorecard-double-eagle-7`, `scorecard-double-eagle-6` |
| Rating / slope | `scorecard-course-rating`, `scorecard-slope` |
| Attest | `scorecard-attest-btn`, `scorecard-attest-badge` |
| Handicap | `scorecard-handicap-estimate` |
| Flight | `scorecard-flight-btn` |
| Cart format | `scorecard-cart-format-total` |
| Paid mulligan | `hole-editor-paid-mulligan` |