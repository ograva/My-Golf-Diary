# SHARD-RNGE-024: Evaluation log

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-024 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-004 |
| **Priority** | Low |
| **Status** | Completed |
| **Complexity** | S |
| **Depends On** | RNGE-022 |

## Description

Let the player read saved range evaluations and periodic summaries without calling Vertex again. The list opens from inside the Swing diary. Do not add a bottom-nav destination or a Range header icon for it. Where this log sits in the rest of the app is still an open product question.

## Acceptance Criteria

- [x] A control inside the Swing diary opens the log. Opening it performs no model call and does not require a network connection.
- [x] Rows come from `range_evaluations`, newest first. An `evaluation` shows its session date and content. A `periodic_summary` is labeled so a reader can tell a progress brief from a day’s evaluation.
- [x] An empty log reads "No evaluations yet."
- [x] The log is absent from the bottom navigation and from the Range header. Range drill save does not depend on this screen.

## Test coverage

- [x] **Unit/widget:** Seed one `evaluation` and one `periodic_summary`. Open the log from the diary and find both texts. Assert the fake model was not called. With no rows, find the empty copy.
- [x] **Integration (if needed):** Not required.
- [x] **Keys:** Proposed, for Eunice to add to `Wireframe_SwingDiary.md`: `diary-evaluation-log-btn`, `diary-evaluation-log`, `diary-evaluation-row-{id}`.

## Dev notes

- PRD §7 leaves the app-level navigation point open. This shard only makes the stored rows readable from the diary sheet.
- Read the local table only. Do not wait for Firestore sync.
- RNGE-023 may be unbuilt. The list still renders `evaluation` rows from RNGE-022.
