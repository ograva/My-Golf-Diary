# SHARD-RNGE-026: Range session wrap-up

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-026 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-005 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | RNGE-025 |

## Description

Add the sit-down wrap-up on Range. After the golfer saves one or more club blocks, they can write an overall session note, review those blocks, and tap Save and evaluate session. That compiles the visit with RNGE-025 and shows the compiled card in the Range session log. This shard does not call Vertex. When the diary is not available, the button saves the session and says it is stored for later evaluation.

## Acceptance Criteria

- [x] `range-session-note-field` is separate from the per-club Swing Cue field. Switching club chips reloads the club cue and leaves the session note as typed.
- [x] `range-visit-summary-preview` lists the uncompiled blocks from this visit: club, shot count, min / avg / max, cue, and drill title when one was used. Saving a drill block adds it to that preview.
- [x] `range-save-evaluate-session-btn` flushes a pending block when the counter or a yardage field has input, then compiles the visit. The session note clears, the preview clears, and `range-compiled-session-{id}` appears in `range-session-log-list` with the note and the blocks.
- [x] With no blocks, no pending input, and an empty session note, the button does not write a session and tells the golfer to log a block or write a note. A note-only wrap-up still saves.
- [x] The compiled card stays after restart. This club filters compiled cards to ones that include the selected club. The button does not open a model call.

## Test coverage

- [x] **Unit/widget:** Pump Range, save two club blocks, type a session note, switch clubs, and expect the note to remain. Tap Save and evaluate session and find the compiled card text. Restart the widget and find the card again. An empty tap finds the prompt and no new session row.
- [x] **Integration (if needed):** Not required.
- [x] **Keys:** `range-visit-wrapup-card`, `range-visit-summary-preview`, `range-session-note-field`, `range-save-evaluate-session-btn`, `range-session-log-list`, `range-compiled-session-{sessionId}` from `Wireframe_Range.md`.

## Dev notes

- Files: `golf_diary_app/lib/screens/range_drill_screen.dart`, `golf_diary_app/lib/widgets/range_session_log.dart`. Store API from RNGE-025.
- Keep **Save Drill Session** as the per-club save. The wrap-up card sits under it. Flow: `docs/context/designs/Flow_RangeSessionAndEvaluation.md`.
- Do not add `firebase_ai` or open `SwingDiarySheet` in this shard. RNGE-022 consumes the compiled row later.
