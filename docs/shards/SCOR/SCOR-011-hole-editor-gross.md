# SHARD-SCOR-011: Hole editor gross preview

| Field | Value |
| :--- | :--- |
| **Shard ID** | SCOR-011 |
| **Module** | SCOR — Scorecard |
| **Story Ref** | SCOR-002, SCOR-003 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | SCOR-010 |

## Description

The hole editor sheet already shows a live gross and versus-par readout, 56dp steppers, and the wireframe keys. Concede forces strokes to twice par and locks the complete switch. Clamps are unchanged. This has been on main since the design-system commit.

## Acceptance Criteria

- [x] Gross preview equals strokes plus penalties. Versus par is an em dash when strokes are 0 and the hole is not conceded. Otherwise it shows `E`, `+n`, or `-n`.
- [x] Changing par while concede is on updates strokes to `par * 2`. Changing strokes clears concede.
- [x] Strokes clamp to 0–20, penalties to 0–10, mulligans to 0–20. Decrement is disabled at 0.
- [x] Save still calls `saveManualHoleScore` and closes the sheet.

## Test coverage

- [ ] **Unit/widget:** Opening a hole tile shows `hole-editor-gross` and `hole-editor-save-btn`. That assertion lived in `widget_test.dart` at `7f5791f` and is not in the current shell test.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `hole-editor-par-chip-3|4|5`, `hole-editor-strokes-dec|inc`, `hole-editor-penalties-dec|inc`, `hole-editor-mulligans-dec|inc`, `hole-editor-concede-switch`, `hole-editor-complete-switch`, `hole-editor-save-btn`, `hole-editor-gross` from `Wireframe_HoleEditor.md`.

## Dev notes

- File: `golf_diary_app/lib/screens/scorecard_hole_editor.dart`.
- Mulligans stay out of gross. Copy under the title notes that a later GPS shot can replace the stroke count.
