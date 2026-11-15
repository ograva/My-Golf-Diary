# SHARD-MGDV-205: Swing diary chat area (cross-tab)

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-205 |
| **Module** | RNGE + CRSE + SCOR (diary shell) |
| **Story Ref** | MGDV-2b, RNGE-004 |
| **Priority** | Medium |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | MGDV-201, RNGE-022 (completed) |

## Description

Evolve the shipped Range-only swing diary into a **dedicated chat area** that is **not a fifth bottom tab**. One continuous thread ingests context from **Range** (compiled session logs), **On Course** (round/hole notes when added), and **Scorecard** (post-round reflections). Entry points: persistent affordance on each tab (e.g. header icon or floating **Diary** chip) opening the same `SwingDiarySheet` route with shared state.

UI is **conversation-first** (composer + thread), not a form grid. Default composer placeholder: **How did your body feel?** (UX audit / v2 roadmap). AI evaluation remains opt-in, Vertex-only, local-first offline behavior unchanged from RNGE-022. Daily or per-session evaluation scope follows existing `SwingDiaryService` patterns; extend prompt assembly to include non-range notes when present.

## Acceptance Criteria

- [ ] User opens the diary from **Range**, **On Course**, and **Scorecard** and sees the **same** message thread and composer.
- [ ] No fifth tab appears in `HomeShell`; diary is a modal route / full-screen sheet above the shell.
- [ ] Adding a scorecard or on-course note (when those fields exist or via “Add note for today”) appends golfer text to SQLite in a table or column linkable in diary prompts (design: `diary_context_notes` or reuse session/round notes with `source` enum).
- [ ] Opt-in, offline, and **Summarize today** rules from RNGE-022 remain; copy states diary is optional and local range data still saves offline.
- [ ] Skill tier and demographics from `golfer_profile` inform system prompts only, not separate UI skins.

## Test coverage

- [ ] **Unit/widget:** Opening diary from On Course finds prior Range messages. Opt-in dismiss still blocks model on all entry paths.
- [ ] **Integration (if needed):** Fake model receives compiled session + appended on-course note in one prompt when user asks a follow-up.
- [ ] **Keys:** `diary-entry-range`, `diary-entry-on-course`, `diary-entry-scorecard`, plus existing `range-swing-diary-btn`, `diary-composer-field`, `diary-send-btn`, `diary-message-{id}` from `Wireframe_SwingDiary.md`.

## Dev notes

- Refactor navigation: shared `DiaryLauncher` widget; deprecate Range-only assumption in tests.
- Architecture §5.6 — no player API keys; diary tables stay out of `syncFull`.
- Coordinate with Eunice for shell-level diary affordance wireframe update (not a new tab).
- Optional follow-on shard for MGDV-6 if tournament rounds need diary silence during competition.