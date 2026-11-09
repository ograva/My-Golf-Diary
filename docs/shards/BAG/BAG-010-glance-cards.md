# SHARD-BAG-010: Glance club cards

| Field | Value |
| :--- | :--- |
| **Shard ID** | BAG-010 |
| **Module** | BAG — My Bag |
| **Story Ref** | BAG-001, BAG-002, BAG-003 |
| **Priority** | High |
| **Status** | Superseded |
| **Complexity** | M |
| **Depends On** | SHELL-001 |

## Description

My Bag filters by category, edits notes in a dialog, and shows brand, model, a yardage sparkline, and past range sessions. The glance-card rebuild is not scheduled.

Superseded on 2026-11-09. The current My Bag screen is the accepted baseline. Do not rebuild the glance cards. A distance of 0 still renders as `0 yds`. There is no first-load spinner and no `bag-category-chip-*` or `bag-club-card-*` key.

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
- Do not remove Add Club, club edit/delete, or the range-log sheet while rebuilding the card.
