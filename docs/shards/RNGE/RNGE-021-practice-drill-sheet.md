# SHARD-RNGE-021: Practice drill sheet

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-021 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-003 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | RNGE-020 |

## Description

Open the practice-drill list from a leading icon on the Range header. Each row shows the title, category, and short description, and expands to the numbered steps. Using a drill shows its title on the Range screen and stores that drill on the next saved session. The player can add a drill and delete one after confirmation.

## Acceptance Criteria

- [ ] `range-header-drills-btn` opens `range-drills-sheet`. Category chips filter the list. All shows every visible drill.
- [ ] Expanding a row shows the steps in order. **Use this drill** closes the sheet and shows the title under the venue field.
- [ ] The next saved `RangeDrillLog` keeps the selected drill id. Clearing the selection before save stores none.
- [ ] Add validates a non-empty title and at least one step. Delete asks "Remove this drill?" and then the row is gone after the sheet reloads.
- [ ] An empty list reads "No drills in this list. Add one."

## Test coverage

- [ ] **Unit/widget:** Pump Range, open the sheet, expand one seeded drill, tap Use, and find the title on the Range body. Delete asks for confirmation and the row is absent after confirm.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `range-header-drills-btn`, `range-drills-sheet`, `range-drills-chip-{category}`, `range-drill-row-{id}`, `range-drill-use-btn`, `range-drill-delete-btn`, `range-drill-add-btn`, `range-drill-save-btn` from `Wireframe_PracticeDrills.md`.

## Dev notes

- Files: `golf_diary_app/lib/screens/range_drill_screen.dart` and a small sheet widget under `lib/widgets/` or `lib/screens/`.
- The icon is `leading` on the AppBar, 48dp. One filled button in the sheet: **Use this drill**. Add’s save is the filled button on the form. Delete is text.
- Keep the existing venue field, counter, and session log. Do not restyle the whole Range screen (that is RNGE-010).
