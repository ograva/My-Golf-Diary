# Wireframe — Scorecard formats & attestation (MGDV-601)

| Field | Value |
| :--- | :--- |
| **Widgets** | `ScorecardFormatBar`, `ScorecardCartPanel` format line, `showScorecardHoleEditor` |
| **Stories** | [MGDV-601](../../stories/MGDV/MGDV-601-scoring-formats-epic.md) |
| **Persona** | Rory — tournament-style scoring and card sign-off |
| **Status** | **As-built** (2026-11-23) |

## 1. Purpose

Gross stays the stored stroke count; **Molave** and **System 36** are **derived** totals. Optional course rating/slope feed an **Unofficial estimate** handicap line after three rated 18-hole rounds. **Attest card** locks the round until an edit clears attestation.

## 2. Format bar (below round header)

```
┌─────────────────────────────────────────┐
│ [ Gross | Molave | System 36 ]          │  scorecard-format-toggle
│ Molave 42 pts · Gross +6                │  scorecard-format-total
│ Double eagle  [7] [6]                   │  Molave only
│ Rating [66.0]  Slope [113]              │  scorecard-course-rating, -slope
│ Attested by Pat (marker)                  │  scorecard-attest-badge
│ [ Attest card ]                         │  scorecard-attest-btn
│ Unofficial estimate Handicap -2.0       │  scorecard-handicap-estimate
│ [ Flight ]                              │  scorecard-flight-btn
└─────────────────────────────────────────┘
```

### Tokens

- Format toggle: `SegmentedButton`, one segment selected, no stroke rewrite on change.
- Handicap line: always prefixed **Unofficial estimate** — never NGAP official copy.
- Attest dialog keys: `scorecard-attest-name`, `scorecard-attest-role`, `scorecard-attest-save`.
- Edit while attested: `scorecard-attest-edit-confirm` before cart/hole mutations.

## 3. Cart panel

When cart view is active, `_CartTotalsBar` may show format summary via `scorecard-cart-format-total` under classic totals.

## 4. Hole editor (paid mulligan)

Switch `hole-editor-paid-mulligan` — one per nine, excluded from gross and HIO points. Molave live points: `hole-editor-molave-points`. Triple pick-up confirm: `scorecard-molave-pickup`.

See [Wireframe_HoleEditor.md](./Wireframe_HoleEditor.md).

## 5. Key map

| Element | ValueKey |
| :--- | :--- |
| Format toggle | `scorecard-format-toggle` |
| Format total | `scorecard-format-total` |
| Double eagle | `scorecard-double-eagle-7`, `scorecard-double-eagle-6` |
| Rating / slope | `scorecard-course-rating`, `scorecard-slope` |
| Attest | `scorecard-attest-btn`, `scorecard-attest-badge` |
| Handicap | `scorecard-handicap-estimate` |
| Flight | `scorecard-flight-btn` |
| Cart format | `scorecard-cart-format-total` |
| Paid mulligan | `hole-editor-paid-mulligan` |