# Design audit — as-built vs design system

| Field | Value |
| :--- | :--- |
| **Date** | 2026-11-20 |
| **Author** | Eunice |
| **Baseline** | `origin/main` after PR #76 (43 stories), `golf_diary_app/lib/` |
| **Compared to** | [UI_UX_Design_Guide.md](../UI_UX_Design_Guide.md), [DesignSystem.md](./DesignSystem.md), wireframes in this folder |

This pass **documents shipped UI** and records gaps. It does not change Flutter code.

## Coverage (wireframe inventory)

| Area | Shipped | Wireframe | Story links |
| :--- | :---: | :--- | :--- |
| Shell (IndexedStack + nav) | Yes | [Wireframe_HomeShell.md](./Wireframe_HomeShell.md) | SHELL-001 |
| Onboarding wizard | Yes | [Wireframe_Onboarding.md](./Wireframe_Onboarding.md) | MGDV-201 |
| Golfer profile + sync settings | Yes | [Wireframe_Settings.md](./Wireframe_Settings.md) | MGDV-202, SYNC-010 |
| My Bag stat-tile cards | Yes | [Wireframe_MyBag.md](./Wireframe_MyBag.md) | BAG-010 |
| Range drill + session compile | Yes | [Wireframe_Range.md](./Wireframe_Range.md) | RNGE-001–005 |
| On Course FWY map shell | Yes | [Wireframe_OnCourse.md](./Wireframe_OnCourse.md) | CRSE-036 |
| On Course Simulator HUD | Yes | [Wireframe_OnCourse-Simulator.md](./Wireframe_OnCourse-Simulator.md) | CRSE-035 |
| Scorecard + hole editor | Yes | [Wireframe_Scorecard.md](./Wireframe_Scorecard.md) | SCOR-001–002 |
| Caddy / cart surfaces | Partial | — | MGDV-401, MGDV-501 (no wireframes yet) |

Full index: [README.md](./README.md).

## What matches the design system

| Area | Evidence |
| :--- | :--- |
| Palette & type | `GolfPalette`, `buildGolfTheme()`, `GolfTextStyles.tabularNum` match guide hex and font roles |
| Bag stat tiles | `_ClubBagCard` / `_StatTile` 44dp tiles, hero on `primaryContainer`, em dash for zero ([BAG-010](../../stories/BAG/BAG-010-stat-tile-cards.md)) |
| FWY map shell | `Stack` + `FwyHoleMap`, `oncourse-top-overlay`, `oncourse-side-rail`, docked Record ([CRSE-036](../../stories/CRSE/CRSE-036-fwy-map-shell.md)) |
| Map render tokens | `GolfPalette.mapFairway` … `mapScrim` align with `tools/map_pack/render.py` |
| Overlay chrome | `fwy_overlays.dart`: `fwyOverlayText`, `FwyRailTile`, `fwySurface` |
| Shell keys | `shell-tab-*`, `shell-nav-bar` on `NavigationBar` |
| On Course title | AppBar **On Course** (guide-compliant) |
| Scorecard semantics | Gimme / conceded labeling per SCOR-003 |

## Gaps and inconsistencies

| Issue | Where | Severity | Notes |
| :--- | :--- | :--- | :--- |
| Category chips without `ValueKey` | `ClubsScreen` filter row | Medium | Wireframe lists `bag-category-chip-{cat}` — not in code yet |
| `add-club-button` uses `Key` not `ValueKey` | `ClubsScreen` AppBar | Low | Quinn tests may prefer `ValueKey` |
| FWY rail uses white shadow text on map | `fwyOverlayText` | Low | Acceptable for contrast; not in cream-surface rules |
| Simulator still scroll + dual penalties UI | `FairwayTrackerScreen` SIM branch | Low | Matches SIM wireframe; differs from FWY rail pattern |
| Some legacy keys vs rail summaries | FWY mode | Low | e.g. `oncourse-club-summary` on rail tile |
| Caddy flows unrunnable in wireframes | `caddy_*` screens | Medium | Stories MGDV-501 — document later |
| Historical UX_Audit “two gold CTAs” | FWY dock | **Resolved** | Finish moved to overflow / chips; single filled Record |

## Optional improvements (prioritized)

Do **not** block current look; user approved as-built aesthetic.

1. **P1 — Key hygiene:** Add `ValueKey('bag-category-chip-{cat}')` to category `ChoiceChip`s; normalize `add-club-button` to `ValueKey`; audit SIM sheet keys against wireframe §7.
2. **P2 — Chip height consistency:** Document 44dp stat tiles vs 48dp touch-target rule; consider +4dp vertical padding on category row only (no layout change to cards).
3. **P3 — Rail / overlay theming:** Replace hard-coded `Colors.white` on FWY overlay text with a `GolfPalette.onMapOverlay` token for dark-mode map packs (future).

## Density rules (shipped)

| Tier source | `GolferProfile.skillTier` | UI effect |
| :--- | :--- | :--- |
| Yardage labels | `YardageUiDensity` | Shortest/Usual/Best vs Min/Avg/Max on bag tiles |
| On Course fields | Progressive disclosure helpers | SIM optional fields; FWY aim rail when mapped |
| Onboarding / settings | Same tier chips | MGDV-202, MGDV-203 |

## Handoff

- Implementers: use wireframe **Key map** tables; prefer keys **already in code** when wireframe disagrees.
- Coordinator copy: [eunice-design-audit.md](/cursor/stores/bc-feeaea10-b0d1-4960-874c-190e168fc2b4/docs/eunice-design-audit.md) (Project store).