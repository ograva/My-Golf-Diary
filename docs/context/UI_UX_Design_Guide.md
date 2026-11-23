# UI/UX Design Guide — My Golf Diary

| Field | Value |
| :--- | :--- |
| **Product** | My Golf Diary |
| **Owner** | Eunice (UI/UX Designer cohort) |
| **Status** | Active |

## Version History

| Version | Date | Author | Summary |
| :--- | :--- | :--- | :--- |
| 1.0 | 2026-11-06 | Eunice (`/moodboard`) | Full design language, color system, typography, iconography, spacing |
| 1.1 | 2026-11-06 | Eunice (`/wireframe`) | Target wireframes for shell + four tabs + hole editor; improvements over as-built UI |
| 1.2 | 2026-11-09 | Eunice (`/wireframe`, `/audit-ux`) | New-feature wireframes, as-built dialogs that were missing, UX audit |
| 1.3 | 2026-11-11 | Eunice (`/wireframe`, `/flow`) | Post-range sit-down flow (`RNGE-005` → `RNGE-004`): session note card, active visit summary, **Save and evaluate session** compilation, compiled session log cards, and seamless handoff to the Vertex AI Swing Diary sheet (`Flow_RangeSessionAndEvaluation.md`) |
| 1.4 | 2026-11-19 | Eunice (`/wireframe`, `/flow`) | On Course **dual-mode** sharding: map-first **Course** HUD (header/footer rail, aim wedge, markers, sticky record), **Simulator** table layout (`Wireframe_OnCourse-Simulator.md`), end-to-end mode flow (`Flow_OnCourse-Modes.md`); skill-tier field density cross-ref MGDV-202/203 |
| 1.5 | 2026-11-20 | Eunice (`/audit-ux all`, `/design-system`) | **As-built capture:** stat-tile My Bag (BAG-010), FWY map shell (CRSE-036), onboarding/settings wireframes; story links on all major wireframes; [Design_Audit.md](./designs/Design_Audit.md) + [designs/README.md](./designs/README.md) |
| 1.6 | 2026-11-20 | Athena | Golfer avatar art + picker (§4 Iconography) |
| 1.7 | 2026-11-20 | Eunice | One diary write affordance: header book icon on every shell tab. Overflow and right-edge swipe removed |
| 1.8 | 2026-11-23 | Eunice | Align wireframes with PRD 1.13: bottom diary composer, range-shot-total cycle, MGDV-601 scorecard formats + flight sheet; refresh SwingDiary + flows |
| 1.9 | 2026-11-23 | Eunice | MGDV-6 pilot: [Wireframe_Tournament.md](./designs/Wireframe_Tournament.md), [Wireframe_CaddyDispute.md](./designs/Wireframe_CaddyDispute.md), [Flow_ClubTournamentPilot.md](./designs/Flow_ClubTournamentPilot.md) |

---

## Moodboard

### 1. Emotional Direction

| Adjective | Persona link | UI expression |
| :--- | :--- | :--- |
| **Confident** | All three personas need to trust the data before they commit to a club | Bold numbers, monospaced stat rows, unambiguous primary CTA per screen |
| **Focused** | Rory logs shots in a 10-second window between swings | Minimal chrome; content fills the screen; no decorative noise |
| **Outdoors-ready** | Phone used in direct sun and twilight | High-contrast surfaces (cream in sun, deep forest at night); OLED-friendly dark |
| **Precise** | Blake reads a yardage like a pro reading a pin sheet | Tabular digits that stack, hairline dividers, tight labels |
| **Premium-quiet** | Great equipment is understated; the app should feel like it belongs in a bag from St Andrews | Serif headings, cream surfaces, gold reserved for accents only |

---

### 2. Color System

Design references: *Augusta Design System* (Wolf Golf), *HoleRecord* (outdoor contrast research), *St Andrews Links* case study (atomic color system).

#### Palette Tokens

| Token | Hex | Role | Notes |
| :--- | :--- | :--- | :--- |
| `fairwayGreen` | `#1A5E3A` | `colorScheme.primary` | Brand CTA, active states |
| `fairwayDark` | `#0F4228` | AppBar dark bg, pressed state | Deep surface on dark screens |
| `fairwayLight` | `#6DBF8C` | `colorScheme.primary` (dark mode) | Primary on deep forest bg |
| `birdieGold` | `#C8A84B` | `colorScheme.secondary` | Gold accent — light mode |
| `birdieGoldDark` | `#D4B85A` | `colorScheme.secondary` (dark mode) | Brighter on dark bg |
| `cream` | `#FAF7F0` | `colorScheme.surface` (light) | Base background — never pure white |
| `creamElevated` | `#F0EDE5` | `colorScheme.surfaceContainer` (light) | Cards |
| `creamSunken` | `#E8E5DC` | `colorScheme.surfaceContainerHigh` (light) | Inputs, steppers |
| `hairline` | `#D8D2C4` | `colorScheme.outline` (light) | 0.5px dividers on cream |
| `deepForest` | `#0E1611` | `colorScheme.surface` (dark) | OLED base |
| `forestElevated` | `#162019` | `colorScheme.surfaceContainer` (dark) | Cards on dark |
| `forestSunken` | `#1E2D22` | `colorScheme.surfaceContainerHigh` (dark) | Inputs on dark |
| `forestHairline` | `#2A3A2E` | `colorScheme.outline` (dark) | Dividers on dark |
| `inkPrimary` | `#1C1C1E` | `colorScheme.onSurface` (light) | Body text, digits — not pure black |
| `inkSecondary` | `#5C5C5C` | `colorScheme.onSurfaceVariant` (light) | Labels, captions |
| `inkTertiary` | `#8A8A8A` | Hints | |
| `inkOnDark` | `#F0EDE5` | `colorScheme.onSurface` (dark) | Cream text on deep forest |
| `inkOnDarkSub` | `#A0A8A2` | `colorScheme.onSurfaceVariant` (dark) | Sub-labels on dark |
| `positive` | `#1A5E3A` | Birdie / under par | Same hue as brand — intentional |
| `negative` | `#8B2E2E` | Bogey / over par / error | Muted burgundy, not alarming red |
| `negativeLight` | `#CF8484` | Error text on dark bg | |
| `warning` | `#A67B2E` | Penalty, soft rate-limit | |
| `mapFairway` … `mapScrim` | see `GolfPalette` in `app_theme.dart` | Hole map / FWY overlays (pack render parity) |

**Usage rules:**
- Never use `Colors.white` or `Colors.black` directly — use cream / inkPrimary.
- **Gold lives on green**: use `birdieGold` on green surfaces or as a secondary stat accent. On cream, use `fairwayGreen`.
- Error state uses `negative` (burgundy), not material red.

#### ColorScheme mapping (Material 3)

| M3 role | Light | Dark |
| :--- | :--- | :--- |
| primary | `#1A5E3A` | `#6DBF8C` |
| onPrimary | white | `#002112` |
| primaryContainer | `#B8E8C8` | `#1A5E3A` |
| secondary | `#C8A84B` | `#D4B85A` |
| surface | `#FAF7F0` | `#0E1611` |
| surfaceContainer | `#F0EDE5` | `#162019` |
| error | `#8B2E2E` | `#CF8484` |
| outline | `#D8D2C4` | `#2A3A2E` |

---

### 3. Typography

Three families in strict roles:

| Role | Family | Use |
| :--- | :--- | :--- |
| **Display / Headline** | Playfair Display (serif) | Screen titles, section headers, big stats labels |
| **Body / Title / Label** | Inter (sans-serif) | Navigation labels, body copy, action labels, chips |
| **Numbers** | Roboto Mono (monospaced) | All yardages, scores, stroke counts, distances — tabular digits stack across rows |

**Principle:** Playfair is display only. Never body copy, never chip labels, never inside an input.

#### Scale → Material 3 text roles

| M3 role | Family | Size | Weight | Use in My Golf Diary |
| :--- | :--- | :--- | :--- | :--- |
| `displaySmall` | Playfair Display | 36 | 400 | Big stat headlines (future screens) |
| `headlineLarge` | Playfair Display | 32 | 700 | Screen-level title |
| `headlineMedium` | Playfair Display | 28 | 600 | Section header |
| `headlineSmall` | Playfair Display | 24 | 600 | Hole number, club name in list |
| `titleLarge` | Inter | 22 | 600 | AppBar title on major screens |
| `titleMedium` | Inter | 16 | 600 | Card header, stat label |
| `bodyLarge` | Inter | 16 | 400 | Swing notes, description copy |
| `bodyMedium` | Inter | 14 | 400 | List body, note text |
| `bodySmall` | Inter | 12 | 400 | Timestamps, helper text |
| `labelLarge` | Inter | 14 | 700 / tracked | Uppercase section headers, button label |
| `labelSmall` | Inter | 11 | 600 / tracked | Min / Avg / Max caption above number |

**Monospaced numbers** (`GolfTextStyles.tabularNum`): Roboto Mono, `FontFeature.tabularFigures()`. Used for all score digits, yardages, counters, and stat values so columns align.

---

### 4. Iconography

- **Library:** Material Icons (`Icons.*`) — always filled variant for primary actions; outlined for secondary / inactive tab.
- **Tab icons** (index 0→3): My Bag `Icons.golf_course` · Range `Icons.fitness_center` · On Course `Icons.my_location` · Scorecard `Icons.scoreboard` (filled when selected).
- **Action icons:** `Icons.cloud_upload_outlined` (sync), `Icons.add`, `Icons.refresh`.
- **Diary write (one affordance):** `Icons.auto_stories_outlined` on a 48×48dp `IconButton`, tooltip **Swing diary**. It sits in the AppBar actions, immediately left of the account avatar, on **My Bag, Range, On Course, and Scorecard**. Same control for every skill tier. Keys: `diary-entry-bag`, `diary-entry-range`, `diary-entry-on-course`, `diary-entry-scorecard`. It opens `SwingDiarySheet`. There is no diary bottom tab, no task button, no Diary row in the ⋮ menu, and no right-edge swipe.
- **Size:** 24dp interactive, 20dp decorative inline.
- **Golfer avatars:** illustrated circular portraits (`assets/avatars/`, female/male × beginner/amateur/seasoned, plus one alternate amateur art per gender) fill the account avatar slot: header 40dp, Account profile 72dp, Settings 56dp, diary "You" rows 32dp. A Google photo takes precedence. The Settings picker rings the selection in `colorScheme.primary`, and **Auto** follows gender × tier.
- **Color:** selected = `colorScheme.onPrimaryContainer` on indicator; unselected = `colorScheme.onSurfaceVariant`.

---

### 5. Spacing & Layout Grid

| Token | Value | Use |
| :--- | :--- | :--- |
| xs | 4 dp | Tight internal gaps (chip padding adjust) |
| sm | 8 dp | Between related items (stat chips) |
| md | 12 dp | Between card rows |
| base | 16 dp | Standard body padding |
| lg | 24 dp | Between sections |
| xl | 32 dp | Above primary CTA block |
| safe | MediaQuery safe insets | Bottom nav, notches |

**Grid:** single-column mobile-first, 16dp horizontal gutter. No explicit column grid for v1; content width is screen − 32dp padding.

**Touch targets:** minimum **48 × 48dp** for interactive controls. Primary CTA buttons: `Size.fromHeight(56)` (On Course FWY record dock uses **64dp** height). **Stat tiles** on My Bag are **44dp** tall (visual density); tap targets on card rows use `minHeight: 48` on identity and notes `InkWell`s.

### Component density (shipped)

| Component | Size / token | File |
| :--- | :--- | :--- |
| Bag stat tile | 44dp height, 8dp radius, hero on `primaryContainer` | `clubs_screen.dart` `_StatTile` |
| FWY rail tile | square `FwyRailTile`, `fwySurface` 12dp radius | `fwy_overlays.dart` |
| FWY overlay text | white w600 + shadow on map | `fwyOverlayText` |
| Category chips | 48dp strip height | `ClubsScreen` filter row |
| NavigationBar | Material 3 default | `home_shell.dart` |

---

## Theme Tokens (developer handoff)

See [`docs/context/designs/DesignSystem.md`](./designs/DesignSystem.md) for the full implementable `ThemeData` code.

| Token | Dart symbol | Value |
| :--- | :--- | :--- |
| primary (light) | `GolfPalette.fairwayGreen` | `#1A5E3A` |
| primary (dark) | `GolfPalette.fairwayLight` | `#6DBF8C` |
| secondary (light) | `GolfPalette.birdieGold` | `#C8A84B` |
| surface (light) | `GolfPalette.cream` | `#FAF7F0` |
| surface (dark) | `GolfPalette.deepForest` | `#0E1611` |
| error | `GolfPalette.negative` | `#8B2E2E` |
| positive score | `GolfPalette.positive` | `#1A5E3A` |
| body font | — | Inter (google_fonts) |
| display font | — | Playfair Display (google_fonts) |
| number font | — | Roboto Mono (google_fonts) |

---

## Wireframes

**As-built layouts** aligned with `golf_diary_app/lib/screens/` (2026-11-23, PRD 1.13). Index with story IDs: [designs/README.md](./designs/README.md). Fresh audit: [Design_Audit.md](./designs/Design_Audit.md).

| Screen | Widget | File | Stories (examples) |
| :--- | :--- | :--- | :--- |
| App shell | `HomeShell` | [Wireframe_HomeShell.md](./designs/Wireframe_HomeShell.md) | SHELL-001 |
| Onboarding | `OnboardingStarterWizard` | [Wireframe_Onboarding.md](./designs/Wireframe_Onboarding.md) | MGDV-201 |
| Settings | Profile + sync routes | [Wireframe_Settings.md](./designs/Wireframe_Settings.md) | MGDV-202, SYNC-010 |
| My Bag | `ClubsScreen` | [Wireframe_MyBag.md](./designs/Wireframe_MyBag.md) | BAG-010 |
| On Course (FWY) | `FairwayTrackerScreen` | [Wireframe_OnCourse.md](./designs/Wireframe_OnCourse.md) | CRSE-036 |
| On Course (SIM) | `FairwayTrackerScreen` | [Wireframe_OnCourse-Simulator.md](./designs/Wireframe_OnCourse-Simulator.md) | CRSE-035 |
| On Course flows | Mode loops | [Flow_OnCourse-Modes.md](./designs/Flow_OnCourse-Modes.md) | CRSE-* |
| Scorecard | `ScorecardScreen` | [Wireframe_Scorecard.md](./designs/Wireframe_Scorecard.md), [Wireframe_ScorecardFormats.md](./designs/Wireframe_ScorecardFormats.md), [Wireframe_Flight.md](./designs/Wireframe_Flight.md) | SCOR-001, MGDV-601 |
| Hole editor | `showScorecardHoleEditor` | [Wireframe_HoleEditor.md](./designs/Wireframe_HoleEditor.md) | SCOR-002 |
| Range | `RangeDrillScreen` | [Wireframe_Range.md](./designs/Wireframe_Range.md) | RNGE-005 |
| Practice drills | Range sheet | [Wireframe_PracticeDrills.md](./designs/Wireframe_PracticeDrills.md) | RNGE-003 |
| Range → diary flow | Compiled session | [Flow_RangeSessionAndEvaluation.md](./designs/Flow_RangeSessionAndEvaluation.md) | RNGE-004 |
| Hole map | `FwyHoleMap` | [Wireframe_HoleMap.md](./designs/Wireframe_HoleMap.md) | CRSE-006 |
| Swing diary | `SwingDiarySheet` | [Wireframe_SwingDiary.md](./designs/Wireframe_SwingDiary.md) | RNGE-004 |
| Shot edit | `ShotEditDialog` | [Wireframe_ShotEdit.md](./designs/Wireframe_ShotEdit.md) | CRSE-002 |
| New round | Scorecard dialogs | [Wireframe_NewRound.md](./designs/Wireframe_NewRound.md) | SCOR-001 |
| Club editor | Bag dialogs | [Wireframe_ClubEditor.md](./designs/Wireframe_ClubEditor.md) | BAG-001 |
| PWA update | `PwaUpdateHost` | [Wireframe_PwaUpdate.md](./designs/Wireframe_PwaUpdate.md) | PWA-001 |
| Tournaments (pilot) | `TournamentListScreen` (planned) | [Wireframe_Tournament.md](./designs/Wireframe_Tournament.md) | MGDV-6-010…014 |
| Caddy dispute | `CaddyShell` | [Wireframe_CaddyDispute.md](./designs/Wireframe_CaddyDispute.md) | MGDV-6-015 |
| Tournament flow | — | [Flow_ClubTournamentPilot.md](./designs/Flow_ClubTournamentPilot.md) | MGDV-6 |

### Optional improvements (not redesign)

See [Design_Audit.md](./designs/Design_Audit.md) § Optional improvements. Examples: `ValueKey` on bag category chips; formalize `onMapOverlay` token for FWY text; caddy wireframes for MGDV-501.

**Global rules for every wireframe**

- One filled primary action per screen. Everything else is outlined, text, or a chip.
- Numbers use `GolfTextStyles` (Roboto Mono). Labels use Inter. Screen titles use Playfair via `AppBar`.
- Colors come from `colorScheme` / `GolfPalette`. Under par = `positive`. Over par = `negative`. Gold is accent only.
- Every interactive control has a `ValueKey` from that screen’s key map.
- Yards are labeled `yds`. Do not introduce meters in these layouts.
