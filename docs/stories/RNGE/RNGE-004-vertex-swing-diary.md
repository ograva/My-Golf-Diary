# RNGE-004 — One diary thread

| Field | Value |
| :--- | :--- |
| **ID** | RNGE-004 |
| **Module** | RNGE |
| **Priority** | High |
| **Status** | Partial |
| **Shard** | [RNGE-022-swing-diary.md](../../shards/RNGE/RNGE-022-swing-diary.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Riley**, I want **one diary thread** that logs practice and rounds on its own and answers when I ask.

## Acceptance criteria

1. One thread holds personal notes and AI replies. The existing coach prompt stays and reads diary entries as context.
2. Saving a range club block, with or without a note, writes an entry (club, drill, result, note). Finishing or leaving a FWY or SIM round writes an entry (course, mode, score, short shot summary). Neither write calls the AI.
3. Feedback in the diary submits recent entries. The analysis is saved as an entry in the same thread.
4. A note typed in the diary is saved, then the AI reads the thread and replies in that thread.

## Widget keys / telemetry

- `diary-feedback-btn`
- `diary-composer-field`
- `diary-send-btn`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist. `RNGE-005` still compiles the range session log and does not start a model call.
