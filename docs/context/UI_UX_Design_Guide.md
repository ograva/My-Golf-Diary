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
- **Tab icons:**
  - My Bag → `Icons.golf_course`
  - On Course → `Icons.my_location`
  - Scorecard → `Icons.scoreboard_outlined` (selected: `Icons.scoreboard`)
  - Range → `Icons.fitness_center`
- **Action icons:** `Icons.cloud_upload_outlined` (sync), `Icons.add`, `Icons.refresh`.
- **Size:** 24dp interactive, 20dp decorative inline.
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

**Touch targets:** minimum **48 × 48dp** for all interactive controls. Primary CTA buttons: `Size.fromHeight(56)`. Chip touch area ≥48dp tall.

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

Target layouts (v1.1). These replace the as-built form stacks. Implementation stays in `golf_diary_app/lib/screens/` and must keep PRD behavior (yards, strokes-from-shots, mulligans excluded from gross, concede = 2× par).

| Screen | Widget | File |
| :--- | :--- | :--- |
| App shell | `HomeShell` | [Wireframe_HomeShell.md](./designs/Wireframe_HomeShell.md) |
| My Bag | `ClubsScreen` | [Wireframe_MyBag.md](./designs/Wireframe_MyBag.md) |
| On Course | `FairwayTrackerScreen` | [Wireframe_OnCourse.md](./designs/Wireframe_OnCourse.md) |
| Scorecard | `ScorecardScreen` | [Wireframe_Scorecard.md](./designs/Wireframe_Scorecard.md) |
| Hole editor | `showScorecardHoleEditor` | [Wireframe_HoleEditor.md](./designs/Wireframe_HoleEditor.md) |
| Range | `RangeDrillScreen` | [Wireframe_Range.md](./designs/Wireframe_Range.md) |
| Practice drills | Range sheet | [Wireframe_PracticeDrills.md](./designs/Wireframe_PracticeDrills.md) |
| Range session & evaluation flow | Range → Compiled Summary → Vertex AI Diary | [Flow_RangeSessionAndEvaluation.md](./designs/Flow_RangeSessionAndEvaluation.md) |
| Hole map | On Course map pane | [Wireframe_HoleMap.md](./designs/Wireframe_HoleMap.md) |
| Swing diary | Range evaluation & coaching sheet | [Wireframe_SwingDiary.md](./designs/Wireframe_SwingDiary.md) |
| Shot edit | `ShotEditDialog` | [Wireframe_ShotEdit.md](./designs/Wireframe_ShotEdit.md) |
| New round | Scorecard dialogs | [Wireframe_NewRound.md](./designs/Wireframe_NewRound.md) |
| Club editor | Bag dialogs | [Wireframe_ClubEditor.md](./designs/Wireframe_ClubEditor.md) |
| PWA update | `PwaUpdateDialog` | [Wireframe_PwaUpdate.md](./designs/Wireframe_PwaUpdate.md) |

Audit: [UX_Audit.md](./designs/UX_Audit.md).

### Planned improvements (why the wireframes differ from the code)

| Surface | As built | Target |
| :--- | :--- | :--- |
| My Bag | Notes field + Save on every card; chips ~48px tall including padding squeeze | Glance cards (name + min/avg/max). Notes open in a sheet. Category chips ≥48dp. Empty and loading states. |
| On Course | One long form. Record and Finish are both large filled buttons. Course field eats the first viewport. | Sticky **Record Shot** dock. HUD card for hole/par/score. Course name compact. Penalties/mulligan/concede/finish are secondary. GPS denied and busy states explicit. |
| Scorecard | Six-column table, ~40dp rows, blue/orange fills | Out/In/Total banner, then **Front 9 / Back 9** hole tiles (≥48dp). Concede uses label `Gimme`, not color alone. |
| Hole editor | Works; numbers not tabular; no live gross prominence | Stepper sheet with live **gross** and **vs par**. 56dp steppers. |
| Range | Three cramped fields; counter beside a small button; no bag baseline | Two-stage flow: (1) On-mat club block capture (`Save Drill Session` updates club averages and adds to today's active visit); (2) Post-session sit-down card with a persistent **Session Note** (`range-session-note-field`), a live **This Visit's Summary** preview of clubs/drills logged, and **Save and Evaluate Session** (`range-save-evaluate-session-btn`) that compiles the session log and opens the Vertex AI Swing Diary evaluation. |

**Global rules for every wireframe**

- One filled primary action per screen. Everything else is outlined, text, or a chip.
- Numbers use `GolfTextStyles` (Roboto Mono). Labels use Inter. Screen titles use Playfair via `AppBar`.
- Colors come from `colorScheme` / `GolfPalette`. Under par = `positive`. Over par = `negative`. Gold is accent only.
- Every interactive control has a `ValueKey` from that screen’s key map.
- Yards are labeled `yds`. Do not introduce meters in these layouts.
