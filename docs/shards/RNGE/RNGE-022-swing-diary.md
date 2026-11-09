# SHARD-RNGE-022: Swing diary

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-022 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-004 |
| **Priority** | Low |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | RNGE-020 |

## Description

Add an opt-in Swing diary opened from Range. It can summarize the drills and notes saved today, and it can answer a follow-up in the same thread. The prompt sent to Google AI includes that day’s range logs, the selected drill steps, and the current club notes. The thread is stored on the device. The composer stays disabled offline and until the player opts in.

This shard is future work. Do not add a Gemini client or ship an API key until this shard is started.

## Acceptance Criteria

- [ ] The first open explains that notes are sent to Google AI. **Not now** returns to Range and does not call the model. **Continue** is remembered.
- [ ] Offline, the composer and **Summarize today** are disabled, with copy that the range log is still on the phone.
- [ ] **Summarize today** is enabled only when at least one drill was saved today. The reply is stored as a diary message and shown in the thread.
- [ ] A later question in the same thread is sent with today’s logs plus earlier diary text. The answer is appended and still there after restart.
- [ ] No model request is made when Firebase or the AI client is unavailable. The range screen still saves drills.

## Test coverage

- [ ] **Unit/widget:** Opt-in dismiss does not call the fake model. Summarize with a seeded drill invokes the fake once and finds `diary-message-{id}`. Offline flag disables `diary-send-btn`.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** `range-swing-diary-btn`, `diary-opt-in-continue`, `diary-opt-in-dismiss`, `diary-composer-field`, `diary-send-btn`, `diary-summarize-today-btn`, `diary-message-{id}` from `Wireframe_SwingDiary.md`.

## Dev notes

- Architecture §5.6. Call Gemini through Firebase Vertex AI or a Cloud Function. Do not commit an API key.
- Persist `swing_diary_messages` in SQLite. Sync can wait.
- The Range header button can stay disabled with tooltip "Swing diary is not on yet" until this shard starts (`Wireframe_Range.md` §9).
