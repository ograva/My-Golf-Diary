# SHARD-RNGE-022: Swing diary evaluation

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-022 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-004 |
| **Priority** | Low |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | RNGE-025, RNGE-026 |

## Description

Add the opt-in Swing diary on Range. An evaluation comments on the compiled session from RNGE-026, including its session note and club blocks, in the light of earlier practice. A follow-up stays in the same thread. Calls go through Vertex AI on this Firebase project. The player does not enter an API key. Each evaluation is saved so it can be reread without another model call. Compacting history past the token ceiling is RNGE-023. The separate reader screen is RNGE-024.

This shard is future work. Do not add the Vertex client until this shard is started.

## Acceptance Criteria

- [ ] The first open explains that range notes are sent to produce the evaluation. **Not now** returns to Range and does not call the model. **Continue** is remembered. There is no API-key field.
- [ ] Offline, or when Firebase or the model client is unavailable, the composer and **Summarize today** are disabled. Copy says the range log is still on the phone. Saving a drill on Range still works.
- [ ] **Summarize today** is enabled only when at least one drill was saved today. The prompt includes, in order, the fixed system role, a per-club tally from SQLite, earlier raw drill history, today in full (drills, steps, min / avg / max, tempo notes), and the latest turns. The reply is shown in the thread, stored in `swing_diary_messages`, and stored again as `range_evaluations.kind = evaluation` with `prompt_tokens` when known.
- [ ] A follow-up in the same thread is appended and still there after restart. A question that names an older day adds that day’s `range_drills` by date and club. Today is never dropped from the prompt.
- [ ] No Gemini API key is read from the player or committed in source. The client is `FirebaseAI.vertexAI()` only.

## Test coverage

- [ ] **Unit/widget:** Opt-in dismiss does not call the fake model. Summarize with a seeded drill invokes the fake once, finds `diary-message-{id}`, and inserts one `evaluation` row whose content matches the reply. Offline flag disables `diary-send-btn`. A prompt built from two days includes both days’ notes while under the ceiling.
- [ ] **Integration (if needed):** Not required. Do not call live Vertex in tests.
- [ ] **Keys:** `range-swing-diary-btn`, `diary-opt-in-continue`, `diary-opt-in-dismiss`, `diary-composer-field`, `diary-send-btn`, `diary-summarize-today-btn`, `diary-message-{id}` from `Wireframe_SwingDiary.md`. That wireframe still says the architecture is unchosen. Follow this shard and Architecture §5.6.

## Dev notes

- Architecture §5.6 and §9.8–9.9. PRD `RNGE-004`. Package: `firebase_ai`, `FirebaseAI.vertexAI()`, App Check, existing anonymous user. Do not add `google_generative_ai`. Do not add a Cloud Function proxy.
- Tables: `swing_diary_messages` (`user` | `model`) and `range_evaluations` as specified in Architecture §5.6. Sync can wait. Estimate `prompt_tokens` (about 4 characters per token is enough) so RNGE-023 can read it.
- Build the prompt in the §5.6 order. If a `periodic_summary` row already exists, include it, but do not create one here.
- The Range header button can stay disabled with tooltip "Swing diary is not on yet" until this shard starts (`Wireframe_Range.md` §9).
