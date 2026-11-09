# UX audit — My Golf Diary

| Field | Value |
| :--- | :--- |
| **Command** | `/audit-ux all` |
| **Date** | 2026-11-09 |
| **Author** | Eunice |
| **Compared to** | `UI_UX_Design_Guide.md`, `DesignSystem.md`, `app_theme.dart`, PRD v1.3, current `golf_diary_app/lib/screens/` |

Wireframes now exist for every screen and dialog in the app, plus the four planned surfaces. This audit is the compliance check. It does not change Flutter code.

## Coverage

| Surface | In the app | Wireframe before this pass | Now |
| :--- | :--- | :--- | :--- |
| Home shell | Yes | Yes | Updated with sync and PWA |
| My Bag list | Yes | Yes (target glance cards) | Updated; as-built dialogs added |
| Add / edit club, notes, range log | Yes | Missing | [Wireframe_ClubEditor.md](./Wireframe_ClubEditor.md) |
| On Course HUD | Yes | Yes (target dock) | Updated for catalog, simulator, distance, map |
| Shot edit | Yes | Missing | [Wireframe_ShotEdit.md](./Wireframe_ShotEdit.md) |
| Scorecard | Yes | Yes | Updated for 9-hole cards and par labels |
| New round / save-before-new | Yes | Missing | [Wireframe_NewRound.md](./Wireframe_NewRound.md) |
| Hole editor | Yes | Yes | Unchanged; still matches the sheet |
| Range | Yes | Yes (target) | Updated for venue, log chips, drills, diary |
| PWA update | Yes, web | Missing | [Wireframe_PwaUpdate.md](./Wireframe_PwaUpdate.md) |
| Practice drills | No | — | [Wireframe_PracticeDrills.md](./Wireframe_PracticeDrills.md) |
| Live yards to pin | No | — | On Course §9 |
| Hole map | No | — | [Wireframe_HoleMap.md](./Wireframe_HoleMap.md) |
| Swing diary | No | — | [Wireframe_SwingDiary.md](./Wireframe_SwingDiary.md) |

## Design-system compliance

What already matches `GolfPalette` and the type rules:

- Theme tokens in `app_theme.dart` match the guide (cream, fairway green, gold, burgundy error, Playfair / Inter / Roboto Mono).
- Scorecard to-par uses positive and negative styles, and a conceded hole says **Gimme**, not color alone.
- Hole editor uses tabular gross and  the stepper keys from its wireframe.
- Tab labels and icon pairs match the shell wireframe.

What does not match yet (as built):

| Issue | Where | Guide rule | Severity |
| :--- | :--- | :--- | :--- |
| Two filled primaries | On Course Record (green, 80dp) and Finish (gold, 72dp) | One filled primary. Gold is accent, not a second CTA. | High for Rory in sun and gloves |
| AppBar titles | "Fairway HUD", "Range Drill Instructor" | Short titles: On Course, Range | Low |
| Notes on every bag card | My Bag | Glance card; notes in a sheet | Medium |
| Chip lanes at 44dp | On Course club and lie rows | 48dp minimum | Medium |
| `AppColors.green` / `.amber` on the two On Course buttons | Fairway tracker | `colorScheme` / `GolfPalette` only | Low (aliases exist, but gold-as-primary breaks the accent rule) |
| Shot delete has no confirm | Shot edit | Destructive actions confirm | Medium |
| Keys | Many controls still unlabeled (`par` chips, course field, range venue, new-round Start) | Every interactive control has a key | Medium for Quinn |

New wireframes follow the system: one filled action, yards labeled, distance and map hidden when there is no coordinate, diary off without a network and without opt-in, drill delete confirmed.

## Persona check

- **Rory:** Distance-to-pin is a single tabular line, not a second screen. It disappears in the simulator and on unmapped holes so a custom course does not show a wrong number. The map is optional and never removes Record.
- **Riley:** Drills open from the left of the Range header, steps are readable before a block, and a deleted drill stays deleted. The diary is a later sheet, not mixed into the save form.
- **Blake:** Add club stays in the header. Brand, model, and the range sparkline are specified even though the glance-card target would simplify the list.

## Touch, contrast, semantics

- Planned controls are 48dp (drill icon, map toggle, diary send, steppers already 56dp in the hole-editor target).
- Yardages use Roboto Mono on cream or deep forest. Do not put `birdieGold` text on `cream`; the distance line uses `onSurface`.
- Distance, Gimme, and empty drill states include words, not color only.
- Add `Semantics` label "Yards to the pin" on `on-course-distance-to-hole` when that line is built. The map overlay needs a text alternative: "Hole {n}, {count} shots" for the paint.

## Key gaps to close when Athena builds

Use the keys already written on the new wireframes. Where code and an older wireframe disagree, prefer the key **already in code** (`add-club-button`, `sync-cloud-button`, `on-course-shot-save`, `scorecard-hole-tile-{n}`, `range-log-this-club`) and keep the wireframe’s extra keys for controls that do not exist yet.
