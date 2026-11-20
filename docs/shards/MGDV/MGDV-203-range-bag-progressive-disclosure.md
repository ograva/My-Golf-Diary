# SHARD-MGDV-203: Range & Bag progressive disclosure

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-203 |
| **Module** | BAG + RNGE (cross-cutting) |
| **Story Ref** | MGDV-2, BAG-010 (revive) |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | MGDV-202 |

## Description

Implement **skill-tier-aware** UI density on **My Bag** and **Range** without changing SQLite yardage columns or RNGE save payloads. **Beginners** see warmer, shorter copy and fewer numbers up front; **seasoned pros** see full min/max/avg and technical labels when settings allow.

**My Bag (amended 2026-11-20, Option B stat tiles):** One compact card layout (≈136dp at 360dp) for **every** skill tier, with everything visible at once and **no Details button or sheet**. Row 1: club name + brand · model (tap → edit) and a sessions chip (🕘 **N** ›, opens range logs). Row 2: four stat tiles, shortest · usual (tinted, hero) · best · trend (sparkline + delta). Row 3: one-line swing note (tap → notes dialog) or “Add swing note”. Skill tier changes **labels only**: **Shortest · Usual · Best** for beginner / amateur, **Min · Avg · Max** for full mode. Design: Project store `docs/bag-card-compact-design.md` §4. Category chips use human labels (Drivers & woods, etc.) with same `category` enum.

**Range:** AppBar title **Range** (not “Range Drill Instructor”). **Simple mode** shows **usual distance** + save; **Full mode** reveals min/max fields. Shot counter label **Balls hit**. Respect `yardage_display_mode` from MGDV-202.

Copy aligns with `docs/context/designs/UX_Audit.md` (neutral, non-jargon, 48dp targets on new controls).

## Acceptance Criteria

- [ ] My Bag cards show shortest, usual (hero tile), best, trend, session count and the swing note on the card for every skill tier; there is no Details button or sheet. Beginner / **Match skill tier** labels read **Shortest · Usual · Best**; full display reads **Min · Avg · Max**. Card height ≤ 140dp at 360dp, text scale 1.0.
- [ ] Range **simple** mode hides min/max inputs until user expands **More numbers** or toggles full mode in settings; save still writes valid `RangeDrillLog` (when only usual filled, min/max may mirror usual per Architecture blend rules — document in code comment).
- [ ] AppBar titles: **Range**, **On Course**, **My Bag**, **Scorecard** — no “Fairway HUD” or “Range Drill Instructor” in production build.
- [ ] Putter excluded from Range club strip unchanged; putting drills deferred to MGDV-3.
- [ ] All existing ValueKeys used in production (`range-log-this-club`, etc.) remain; add keys only for new toggles.

## Test coverage

- [ ] **Unit/widget:** Beginner profile hides min/max fields on Range until expand. Full mode shows three yardage fields. Bag title uses **Shortest · Usual · Best** for beginner.
- [ ] **Integration (if needed):** Save range block in simple mode still updates club avg in SQLite.
- [ ] **Keys:** `bag-club-card-{clubId}`, `bag-club-edit-{clubId}`, `bag-hero-yards-{clubId}`, `bag-min-yards-{clubId}`, `bag-max-yards-{clubId}`, `bag-trend-{clubId}`, `bag-notes-text-{clubId}`, `bag-notes-add-{clubId}`, `bag-range-logs-{clubId}` (`bag-details-btn-{clubId}` retired), `range-yardage-mode-expand`, `range-usual-yards-field`; retain `Wireframe_MyBag.md` / `Wireframe_Range.md` targets.

## Dev notes

- `clubs_screen.dart`, `range_drill_screen.dart`, `app_theme.dart` / strings helper keyed off `GolferProfile.skillTier` and `yardage_display_mode`.
- Do not resurrect full BAG-010 delete paths; keep Add Club, edit, range history sheets.
- PRD v2 decision: putting distances stay **yards** in persistence (MGDV-3 content).