# SHARD-MGDV-6-014: Post-tournament handoff to practice

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-014 |
| **Epic** | MGDV-6 |
| **Module** | MGDV / RNGE |
| **Story Ref** | MGDV-6-014 |
| **Priority** | Medium |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | MGDV-6-013, RNGE-004 |

## Description

When the committee closes a pilot event, each enrolled golfer gets a structured diary context note summarizing format total, optional field median, and weak holes. The note does not call Vertex unless the player sends a follow-up in the composer. Deep links may open Range with tagged drill suggestions (Roadmap A2).

## Acceptance Criteria

- [ ] On event **close**, enrolled golfers receive a persisted diary system entry with format total and field comparison when standings data exists.
- [ ] Entry includes biggest leak holes (worst vs par or format points) derived from stored `round_scores`.
- [ ] **No automatic Vertex call** on close; composer send still follows §5.7.
- [ ] Optional deep link to Range with drill tags (putting, approach); personal non-event rounds unchanged.

## Test coverage

- [ ] **Unit/widget:** note builder from standings + round rows; asserts no `generateContent` on close path.
- [ ] **Integration (if needed):** close event → diary thread shows system note → tap link opens Range tab.
- [ ] **Keys:** no new composer keys; `diary-tournament-wrap` or reuse system message styling (TBD).

## Dev notes

- Story: [`MGDV-6-014-post-tournament-diary.md`](../../stories/MGDV/MGDV-6-014-post-tournament-diary.md).
- Use existing `swing_diary_messages` system role or equivalent local flag for non-user-authored rows.
- Drill prescription detail may split to a small RNGE shard later if A2 scope grows.