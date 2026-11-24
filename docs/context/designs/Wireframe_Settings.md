# Wireframe — Settings & account

| Field | Value |
| :--- | :--- |
| **Widgets** | `GolferProfileSettingsScreen`, `AccountSyncSettingsScreen`, `AccountProfileScreen`, AppBar menus |
| **Stories** | [MGDV-202](../../stories/MGDV/MGDV-202-skill-tier-settings.md), [MGDV-203](../../stories/MGDV/MGDV-203-progressive-disclosure.md), [SYNC-005](../../stories/SYNC/SYNC-005-account-avatar-menu.md) … [SYNC-010](../../stories/SYNC/SYNC-010-sync-settings.md), [SYNC-009](../../stories/SYNC/SYNC-009-profile-screen.md) |
| **Status** | Shipped (as-built) |

## 1. Entry points

| Surface | How opened | Story |
| :--- | :--- | :--- |
| Golfer profile | AppBar **⋮** → Golfer profile (`settings-golfer-profile-entry`) | MGDV-202 |
| Account / sync | Avatar menu → Account or Sync settings | SYNC-005, SYNC-010 |
| Reset onboarding | Golfer profile → **Reset onboarding** | MGDV-201 |

No dedicated Settings tab — settings are **modal routes** from the shared AppBar on Bag, Range, On Course, and Scorecard.

## 2. Golfer profile settings

Scrollable form mirroring onboarding fields plus yardage display mode and baseline sheet.

```
┌─────────────────────────────┐
│ ← Golfer profile            │
├─────────────────────────────┤
│ Age, years playing          │
│ Gender chips                │
│ Skill tier chips            │  drives BAG labels + on-course density
│ Yardage display mode        │  beginner/amateur/full labels
│ Swing diary coach           │  golf-pro · golf-buddy · golf-lady
│ [ Open baseline sheet ]     │
│ [ Reset onboarding ]        │
│ [ Save ]                    │
└─────────────────────────────┘
```

### Key map — golfer profile

| Element | ValueKey | Widget |
| :--- | :--- | :--- |
| Skill tier | `profile-skill-tier-{tier}` | `ChoiceChip` |
| Yardage display | `profile-yardage-display-{mode}` | `ChoiceChip` |
| Swing diary coach | `profile-coach-persona-{golf-pro\|golf-buddy\|golf-lady}` | `RadioListTile` |
| Reset onboarding | `profile-reset-onboarding-btn` | `TextButton` |
| Save | `profile-save-btn` | `FilledButton` |
| Menu entry | `settings-golfer-profile-entry` | `PopupMenuItem` |

**Swing diary coach:** the default is golf-pro. A choice saves right away, on this device only (`shared_preferences`, not SQLite or sync). Every coach gives the same advice at the same depth. Only the wording and references change.

## 3. Account sync settings

| Element | UI |
| :--- | :--- |
| Identity summary | Anonymous / signed-in email |
| Last sync timestamp | Tabular datetime |
| Pending changes count | Unsynced row count |
| **Sync now** | Manual pull/push ([SYNC-002](../../stories/SYNC/SYNC-002-manual-sync.md)) |
| Link to golfer profile | Same screen as §2 |

## 4. Account profile

Sign-in sheet ([SYNC-006](../../stories/SYNC/SYNC-006-google-email-sign-in.md)), sign-out with confirm (`account-profile-sign-out`).

## 5. Related wireframes

- Onboarding first run: [Wireframe_Onboarding.md](./Wireframe_Onboarding.md)
- Baseline capture sheet: keys in `golfer_baseline_sheet.dart` (`golfer-baseline-*`)