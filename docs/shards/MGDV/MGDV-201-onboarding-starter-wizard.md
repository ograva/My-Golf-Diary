# SHARD-MGDV-201: Onboarding starter wizard

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-201 |
| **Module** | MGDV — V2 profile & onboarding |
| **Story Ref** | MGDV-201 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | None |

## Description

After first launch (or until completed), show a short **starter wizard** before the four-tab shell. Collect demographics for AI and defaults: **age**, **years playing**, and **gender** (stored for personalization prompts only — never used to swap UI strings). On the final step the golfer picks **skill tier**: **beginner**, **amateur**, or **seasoned pro**, which drives copy density and progressive disclosure (see MGDV-203). Data persists in local SQLite on the existing `golfer_profile` row (DB migration). The wizard is skippable only via explicit **Finish later** that still lands on Range or Bag; **Complete** sets `onboarding_completed` so the wizard does not reappear unless the user resets it from Settings.

All writes stay **local-first**; profile extensions remain outside `syncFull` per Architecture until a future SYNC epic.

## Acceptance Criteria

- [x] On a fresh install (or `onboarding_completed = 0`), the app shows the wizard instead of `HomeShell` until the user completes or taps **Finish later**.
- [x] Steps collect **age** (integer, sensible clamp 8–99), **years playing** (integer, 0–80), and **gender** (enum or free-text bucket: prefer fixed choices plus **Prefer not to say**). Empty gender is allowed but wizard copy encourages an answer for AI baseline.
- [x] Final step requires **skill tier** ∈ {`beginner`, `amateur`, `seasoned_pro`} with one-line descriptions (neutral, non-gendered copy per UX audit).
- [x] **Complete** saves to `golfer_profile`, sets `onboarding_completed = 1`, and opens `HomeShell` (default tab unchanged unless MGDV-202 sets range-first preference).
- [x] **Finish later** saves partial answers if any, leaves `onboarding_completed = 0`, and opens `HomeShell`; wizard reappears on next cold start until completed.
- [x] No Firebase or network required to finish the wizard.

## Test coverage

- [x] **Unit/widget:** Wizard appears when `onboarding_completed` is false; completing sets flag and shows `shell-nav-bar`. Invalid age/years show inline validation without crash.
- [x] **Integration (if needed):** Cold start after Complete does not show wizard again.
- [x] **Keys:** `onboarding-wizard-page-{n}`, `onboarding-age-field`, `onboarding-years-field`, `onboarding-gender-{option}`, `onboarding-skill-tier-{tier}`, `onboarding-complete-btn`, `onboarding-finish-later-btn` (add to settings wireframe when Eunice updates).

## Dev notes

- Extend `golfer_profile` table (DB v9): `age`, `years_playing`, `gender`, `skill_tier`, `onboarding_completed`, optional `bag_nickname`. Update `GolferProfile` in `golf_diary_app/lib/models/golfer_profile.dart` and `LocalDatabaseService` migration path.
- Gate in `main.dart` or a thin `OnboardingGate` widget above `HomeShell`.
- Gender values feed Vertex / diary prompts only (Architecture §5.6 coaching baseline); **do not** branch UI labels on gender (preferences.md).
- Reference: Project store `docs/v2-roadmap.md` § Product decisions (2026-11-16).