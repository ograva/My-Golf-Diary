# Wireframe — My Bag

| Field | Value |
| :--- | :--- |
| **Widget** | `ClubsScreen` |
| **PRD** | BAG-001, BAG-002, BAG-003 |
| **Persona** | Blake (glance), Riley (notes) |
| **Status** | Target v1.1 |

## 1. Screen purpose

Show the bag by category with **min / avg / max in yards** and swing notes that survive restart. Notes are edited on purpose, not typed into every visible card.

## 2. Mobile layout

Amended 2026-11-20: **Option B, stat tiles** (Project store `docs/bag-card-compact-design.md` §4). One card layout for every skill tier, ≈136dp tall at 360dp, everything visible at once. There is **no Details button and no details sheet**.

```
┌─────────────────────────────┐
│ My Bag              [ + ]   │  add club, key add-club-button (as built)
├─────────────────────────────┤
│ [Wood] Hybrid Iron Wedge …  │  horizontal chips, height 48
├─────────────────────────────┤
│ ┌───────────────────────────────────────┐ │
│ │ Driver ✎ TaylorMade Stealth 2  (🕘 5 ›)│ │  row 1: name 16/600 + brand 12 inline; sessions chip
│ │ [MIN 210][AVG 230][MAX 255][TREND +6 ╱╲]│ │  row 2: four 44dp tiles, AVG tile primaryContainer
│ │ ✎ "Smooth tempo, finish high — tee…"  │ │  row 3: one-line note, full width
│ └───────────────────────────────────────┘ │  ≈136dp, 8dp gap
│ ┌───────────────────────────────────────┐ │
│ │ 3 Wood                         (🕘 0 ›)│ │
│ │ [MIN —][AVG —][MAX —][TREND —]        │ │  all-zero → em dash, still a card
│ │ ＋ Add swing note                      │ │
│ └───────────────────────────────────────┘ │
└─────────────────────────────┘
```

| Zone | Content | Behavior |
| :--- | :--- | :--- |
| Identity | `club.name` + ✎ glyph, `brand · model` inline (ellipsis) | Tap → `EditClubDialog` |
| Sessions chip | 🕘 `N` › | Tap → `ClubRangeLogSheet` (empty state at 0). Semantics “Range logs (N)” |
| Stat tiles | Shortest/Min · Usual/Avg · Best/Max, numbers in tabular mono, no `yds` unit | Not interactive. `—` when 0 |
| Trend tile | sparkline + `+N` / `−N` delta (`positive` / `negative`) | `first → last yds` in tooltip and semantics. <2 sessions → `—` |
| Notes row | ✎ + italic note, 1 line, ellipsis; empty → ＋ “Add swing note” in `primary` | Tap → `SwingNotesDialog` |

**Skill tier changes labels only:** beginner and amateur read **Shortest · Usual · Best**, full display reads **Min · Avg · Max**. Layout is identical.

**Notes dialog** (tap note row): `SwingNotesDialog`, 3–6 line `TextField`, **Save notes**. Save is explicit (BAG-003).

### What changes vs current code

- Remove the **Details** button and `ClubBagDetailsSheet`. Every field from the sheet is on the card.
- Remove the separate Range logs / Edit notes TextButtons; the sessions chip and the note row are the targets.
- Remove the 48dp sparkline and its caption; the trend is a tile.
- Card padding 12 horizontal, 8dp between cards. Tap targets stay ≥ 48dp.
- All-zero stats render `—`, not `0 yds`, so a starter bag does not look measured.
- Empty category: centered text "No clubs in this category" — no crash (BAG-001).
- Category selection is session-only (not persisted). Documented here so resume returns to **Wood**.

## 3. Larger screens

≥600dp: two-column card grid, same chip filter full width. Card height unchanged.

## 4. Widget inventory

| Widget | Role |
| :--- | :--- |
| `AppBar` | Title "My Bag" |
| `ChoiceChip` in horizontal `ListView` | Category filter |
| `Card` + `InkWell` | Club glance row |
| Stat tiles (`Container`, `primaryContainer` for usual) | Min, avg, max, trend |
| `ActionChip` | Sessions count → range logs sheet |
| `AlertDialog` (`SwingNotesDialog`) | Notes editor |
| `TextField` | Notes, only inside the dialog |
| `ElevatedButton` | Save notes |
| `CircularProgressIndicator` | First load |
| `SnackBar` floating | "Saved swing notes for {name}" |

## 5. Interaction & state map

| State | UI |
| :--- | :--- |
| Loading | Spinner, chips visible but disabled |
| Loaded | Cards for category |
| Empty category | Message, no cards |
| All-zero distances | Em dashes in every tile, same card height |
| <2 range sessions | Trend tile shows `—` |
| Note present | Single truncated line (`maxLines: 1`) |
| Note empty | "＋ Add swing note" in `primary` |
| Dialog open | Save enabled always (empty note is a valid clear) |
| Save success | Pop dialog, snackbar, note row updates |

Switching chips calls `getClubsByCategory` and does not restart the app. Dispose note controllers when the sheet closes.

## 6. UX flow

```mermaid
flowchart TD
  open[My Bag] --> chips[Select category]
  chips --> list[Club cards]
  list --> sheet[Notes dialog]
  list --> logs[Range logs sheet]
  list --> edit[Edit club dialog]
  sheet --> save[Save notes]
  save --> list
  rangeSave[Range drill saved] --> list
```

Range saves update club min/avg/max in SQLite. My Bag must reload when the tab is selected again (same idea as scorecard refresh on tab focus).

## 7. Key map

| Element | ValueKey | Widget |
| :--- | :--- | :--- |
| Wood chip | `bag-category-chip-wood` | `ChoiceChip` |
| Hybrid chip | `bag-category-chip-hybrid` | `ChoiceChip` |
| Iron chip | `bag-category-chip-iron` | `ChoiceChip` |
| Wedge chip | `bag-category-chip-wedge` | `ChoiceChip` |
| Putter chip | `bag-category-chip-putter` | `ChoiceChip` |
| Club card | `bag-club-card-{clubId}` | `Card` |
| Identity / edit club | `bag-club-edit-{clubId}` | `InkWell` |
| Usual / Avg tile value | `bag-hero-yards-{clubId}` | `Text` |
| Shortest / Min value | `bag-min-yards-{clubId}` | `Text` |
| Best / Max value | `bag-max-yards-{clubId}` | `Text` |
| Trend tile | `bag-trend-{clubId}` | `Tooltip` |
| Note row | `bag-notes-text-{clubId}` | `InkWell` |
| Add swing note (empty) | `bag-notes-add-{clubId}` | `InkWell` |
| Range logs / sessions chip | `bag-range-logs-{clubId}` | `ActionChip` |
| Empty state | `bag-empty-category` | `Text` |
| Add club | `add-club-button` | `IconButton` (as built) |
| ~~Details~~ | ~~`bag-details-btn-{clubId}`~~ | Retired 2026-11-20 |

## 8. As built dialogs

The stat-tile card in §2 is the shipped layout. Edit club (brand, model, category, delete with confirm), the swing-notes dialog and the range-log sheet are specified in [Wireframe_ClubEditor.md](./Wireframe_ClubEditor.md). Add Club stays in the AppBar, not at the bottom of the list.
