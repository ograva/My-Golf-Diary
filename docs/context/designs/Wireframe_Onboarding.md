# Wireframe — Onboarding starter wizard

| Field | Value |
| :--- | :--- |
| **Widget** | `OnboardingStarterWizard` · gated by `OnboardingGate` |
| **Stories** | [MGDV-201](../../stories/MGDV/MGDV-201-onboarding-wizard.md) |
| **Persona** | All — first-run profile before `HomeShell` |
| **Status** | Shipped (as-built) |

## 1. Screen purpose

Collect optional demographics and a required **skill tier** on first launch, persist to SQLite, then enter the main app. **Finish later** saves partial progress and still opens the shell.

## 2. Mobile layout

Four-page `PageView` with dot indicator and back/next chrome.

```
┌─────────────────────────────┐
│ My Golf Diary               │  Playfair-style title (theme)
│ Page 1 of 4                 │
├─────────────────────────────┤
│ [ page body varies ]        │
│  · Age                      │
│  · Years playing            │
│  · Gender chips             │
│  · Skill tier chips         │
├─────────────────────────────┤
│ [Finish later]    [Next →]  │  or [Complete] on last page
└─────────────────────────────┘
```

| Page | Fields | Validation |
| :--- | :--- | :--- |
| 0 | Age (optional numeric) | `validateOnboardingAge` |
| 1 | Years playing (optional) | `validateOnboardingYears` |
| 2 | Gender chips | Optional selection |
| 3 | Skill tier chips | Required before Complete |

## 3. Widget inventory

| Widget | Role |
| :--- | :--- |
| `PageView` | Wizard pages |
| `TextField` | Age, years |
| `ChoiceChip` | Gender, skill tier |
| `TextButton` | Finish later |
| `FilledButton` | Next / Complete |

## 4. Key map

| Element | ValueKey | Widget |
| :--- | :--- | :--- |
| Wizard page shell | `onboarding-wizard-page-{index}` | `Semantics` wrapper |
| Age field | `onboarding-age-field` | `TextField` |
| Years field | `onboarding-years-field` | `TextField` |
| Gender chip | `onboarding-gender-{value}` | `ChoiceChip` |
| Skill tier chip | `onboarding-skill-tier-{tier}` | `ChoiceChip` |
| Finish later | `onboarding-finish-later-btn` | `TextButton` |
| Complete | `onboarding-complete-btn` | `FilledButton` |

## 5. Related

- Skill tier density rules: [MGDV-202](../../stories/MGDV/MGDV-202-skill-tier-settings.md), [MGDV-203](../../stories/MGDV/MGDV-203-progressive-disclosure.md)
- Re-run from settings: [Wireframe_Settings.md](./Wireframe_Settings.md)