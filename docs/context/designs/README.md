# Design artifacts — My Golf Diary

Visual source of truth for **Eunice** wireframes and **Athena** implementation. Canonical moodboard and version history: [UI_UX_Design_Guide.md](../UI_UX_Design_Guide.md).

**As-built audit (2026-11-23):** [Design_Audit.md](./Design_Audit.md) · Product narratives: [docs/stories/](../../stories/README.md) (53 stories).

## Shell & settings

| Wireframe | Widget | Stories |
| :--- | :--- | :--- |
| [Wireframe_HomeShell.md](./Wireframe_HomeShell.md) | `HomeShell` | [SHELL-001](../../stories/SHELL/SHELL-001-keep-tab-state.md) |
| [Wireframe_Onboarding.md](./Wireframe_Onboarding.md) | `OnboardingStarterWizard` | [MGDV-201](../../stories/MGDV/MGDV-201-onboarding-wizard.md) |
| [Wireframe_Settings.md](./Wireframe_Settings.md) | Profile + sync routes | MGDV-202, MGDV-203, SYNC-005–010 |
| [Wireframe_PwaUpdate.md](./Wireframe_PwaUpdate.md) | `PwaUpdateHost` | [PWA-001](../../stories/PWA/PWA-001-github-pages-publish.md), [PWA-002](../../stories/PWA/PWA-002-offline-precache-shell.md) |

## Tabs (NavigationBar order: 0–3)

| # | Label | Wireframe | Widget | Stories |
| :---: | :--- | :--- | :--- | :--- |
| 0 | My Bag | [Wireframe_MyBag.md](./Wireframe_MyBag.md) | `ClubsScreen` | BAG-001, BAG-002, BAG-003, [BAG-010](../../stories/BAG/BAG-010-stat-tile-cards.md) |
| 1 | Range | [Wireframe_Range.md](./Wireframe_Range.md) | `RangeDrillScreen` | RNGE-001–005 |
| 2 | On Course | [Wireframe_OnCourse.md](./Wireframe_OnCourse.md) (FWY) · [Wireframe_OnCourse-Simulator.md](./Wireframe_OnCourse-Simulator.md) (SIM) | `FairwayTrackerScreen` | CRSE-001–011, [CRSE-035](../../stories/CRSE/CRSE-035-sim-compact-layout.md), [CRSE-036](../../stories/CRSE/CRSE-036-fwy-map-shell.md) |
| 3 | Scorecard | [Wireframe_Scorecard.md](./Wireframe_Scorecard.md) · [Wireframe_ScorecardFormats.md](./Wireframe_ScorecardFormats.md) · [Wireframe_Flight.md](./Wireframe_Flight.md) | `ScorecardScreen` | SCOR-001–004, MGDV-601 |

## Dialogs & sheets

| Wireframe | Stories (typical) |
| :--- | :--- |
| [Wireframe_ClubEditor.md](./Wireframe_ClubEditor.md) | BAG-001, BAG-003 |
| [Wireframe_HoleEditor.md](./Wireframe_HoleEditor.md) | SCOR-002 |
| [Wireframe_NewRound.md](./Wireframe_NewRound.md) | SCOR-001 |
| [Wireframe_ShotEdit.md](./Wireframe_ShotEdit.md) | CRSE-002 |
| [Wireframe_PracticeDrills.md](./Wireframe_PracticeDrills.md) | RNGE-003 |
| [Wireframe_SwingDiary.md](./Wireframe_SwingDiary.md) | RNGE-004 |
| [Wireframe_Tournament.md](./Wireframe_Tournament.md) | MGDV-6-010…014 |
| [Wireframe_CaddyDispute.md](./Wireframe_CaddyDispute.md) | MGDV-6-015 |
| [Wireframe_HoleMap.md](./Wireframe_HoleMap.md) | CRSE-006, CRSE-041 |

## Flows

| Flow | File |
| :--- | :--- |
| On Course Course ↔ Simulator | [Flow_OnCourse-Modes.md](./Flow_OnCourse-Modes.md) |
| Range session → evaluate → diary | [Flow_RangeSessionAndEvaluation.md](./Flow_RangeSessionAndEvaluation.md) |
| Club tournament pilot | [Flow_ClubTournamentPilot.md](./Flow_ClubTournamentPilot.md) |

## System

| Doc | Purpose |
| :--- | :--- |
| [DesignSystem.md](./DesignSystem.md) | Tokens, components, Do/Don’t |
| [Design_Audit.md](./Design_Audit.md) | Gaps vs shipped app (2026-11-20) |
| [UX_Audit.md](./UX_Audit.md) | Historical audit (2026-11-09) — superseded by Design_Audit |