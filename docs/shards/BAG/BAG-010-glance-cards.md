# SHARD-BAG-010: Glance club cards

| Field | Value |
| :--- | :--- |
| **Shard ID** | BAG-010 |
| **Module** | BAG — My Bag |
| **Story Ref** | BAG-001, BAG-002, BAG-003 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | SHELL-001 |

## Description

Replace the always-open notes form on each club card with a glance row: name, min / avg / max in yards, and a one-line note. Editing notes happens in a bottom sheet with an explicit save. Category chips stay session-only and start on Wood.

## Acceptance Criteria

- [ ] Category chips filter the list without restarting the app. An empty category shows `bag-empty-category` and does not throw.
- [ ] A distance of 0 renders as an em dash. Non-zero values render as rounded yards.
- [ ] Tapping a card opens a notes sheet. Save writes `updateClubSwingNotes` and shows a snackbar. Controllers live only in the sheet.
- [ ] First load shows a progress indicator. Reload from the shell refreshes stats after a range save.

## Test coverage

- [ ] **Unit/widget:** After the app pumps, `bag-category-chip-wood` and `bag-club-card-driver` are present once SQLite returns the starter bag.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `bag-category-chip-{category}`, `bag-club-card-{clubId}`, `bag-notes-field-{clubId}`, `bag-save-notes-btn-{clubId}`, `bag-empty-category` from `Wireframe_MyBag.md`.

## Dev notes

- File: `golf_diary_app/lib/screens/clubs_screen.dart`.
- Use `GolfTextStyles.yardage` for the three stats.
- Do not persist the selected category.
