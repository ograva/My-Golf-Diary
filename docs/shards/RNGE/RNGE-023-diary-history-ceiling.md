# SHARD-RNGE-023: Diary history ceiling

| Field | Value |
| :--- | :--- |
| **Shard ID** | RNGE-023 |
| **Module** | RNGE — Range |
| **Story Ref** | RNGE-004 |
| **Priority** | Low |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | RNGE-022 |

## Description

Keep each swing-diary prompt under about 250,000 tokens. While the next prompt fits, send the real drill history, as RNGE-022 already does. When it would pass the ceiling, store a periodic summary of the oldest material and send that brief plus a recent raw window instead. Today’s logs always stay in full. The per-club numbers come from SQLite, not from the model.

## Acceptance Criteria

- [ ] Before a call, the app estimates the prompt. At or under about 250,000 tokens, the prompt still contains the raw earlier history and does not write a `periodic_summary` row.
- [ ] Over the ceiling, the oldest history is compacted into one `range_evaluations` row with `kind = periodic_summary` and `covered_through_ms` set to the newest drill folded into the brief. The next prompt sends that brief, the SQLite per-club tally, a recent raw window (about a month of sessions, or the last several dozen logs), today in full, and the latest turns.
- [ ] The tally includes, per club, session count, average this period versus the previous period, and the drill titles used most. Those figures are computed in SQLite even after the raw notes leave the prompt.
- [ ] Today’s drills are never included in `covered_through_ms` and never omitted from the prompt. A later compaction keeps the previous brief’s facts rather than replacing them with a blank page.
- [ ] No embedding table or vector index is added.

## Test coverage

- [ ] **Unit/widget:** A fixture whose raw history estimates under the ceiling sends that history and writes no `periodic_summary`. A fixture over the ceiling writes one summary row and the following prompt string omits the oldest tempo notes, includes the brief, includes today’s notes, and includes the tally numbers from the fixture.
- [ ] **Integration (if needed):** Not required.
- [ ] **Keys:** None. This shard does not add widgets.

## Dev notes

- Architecture §5.6, constraint §9.9. Use the same fake model seam as RNGE-022. Do not raise the ceiling to fit a long account.
- The recent window is the newer of “about 30 days” and “the last several dozen `range_drills`,” whichever the implementation documents in code comments. Today is additional and always verbatim.
- A periodic summary is also the progress brief on the next call. Do not call Vertex again just to display it.
