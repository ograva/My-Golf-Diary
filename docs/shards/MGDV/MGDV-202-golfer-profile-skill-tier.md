# SHARD-MGDV-202: Golfer profile & skill tier persistence

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-202 |
| **Module** | MGDV — V2 profile & onboarding |
| **Story Ref** | MGDV-202 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | MGDV-201 |

## Description

Expose wizard-collected demographics and **skill tier** in a **Settings / Golfer profile** surface (extend or sit beside the existing baseline sheet on Range). The golfer can edit age, years playing, gender, skill tier, and **yardage display** preference: **Simple**, **Full**, or **Match skill tier** (default). Changes persist in SQLite immediately and update `swing_diary_prompt` / coaching baseline reads without requiring sync.

Skill tier is the single source for UI density rules consumed by MGDV-203 (Bag/Range). Override in settings always wins over tier defaults.

## Acceptance Criteria

- [x] Settings (or profile sheet) shows current **skill tier**, demographics, and yardage display mode with save feedback.
- [x] **Match skill tier** maps: beginner → simple yardage UI; amateur → simple with optional expand hints; seasoned pro → full stats by default (exact mapping documented in shard MGDV-203).
- [x] Editing skill tier updates the in-memory profile used on next build of Bag and Range screens without app restart.
- [x] **Reset onboarding** action clears `onboarding_completed` and reopens MGDV-201 on next launch (confirm dialog).
- [x] Existing baseline pillars (equipment, swing anchors, physical constraints, training environment) remain editable; new fields do not remove lead-in chips behavior.

## Test coverage

- [x] **Unit/widget:** Changing skill tier in settings persists across `getGolferProfile()`. `Match skill tier` resolves to expected display enum.
- [x] **Integration (if needed):** Optional — diary prompt includes updated profile fields when Vertex is faked.
- [x] **Keys:** `settings-golfer-profile-entry`, `profile-skill-tier-{tier}`, `profile-yardage-display-{mode}`, `profile-save-btn`, `profile-reset-onboarding-btn`.

## Dev notes

- Add `yardage_display_mode` column: `simple` | `full` | `follow_skill_tier`.
- Reuse `GolferBaselineSheet` patterns in `golfer_baseline_sheet.dart` or add `lib/screens/settings_screen.dart` reachable from shell overflow menu (wireframe TBD).
- Keep `golfer_profile` out of `syncFull` until tournament auth (MGDV-6).
- `SwingDiaryPrompt` should read `skill_tier` and demographics when building coaching `systemInstruction`.