# RNGE-004 — One diary thread

| Field | Value |
| :--- | :--- |
| **ID** | RNGE-004 |
| **Module** | RNGE |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [RNGE-022-swing-diary.md](../../shards/RNGE/RNGE-022-swing-diary.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Riley**, I want **one diary thread** that logs practice and rounds on its own and answers when I ask.

## Acceptance criteria

1. One thread; header book icon on all tabs (`diary-entry-*`).
2. Range block and round finish/leave write entries without a model call.
3. Bottom composer (`diary-composer-field`) multiline; Send (`diary-send-btn`) with busy spinner (`diary-send-busy`).
4. No Feedback / Save note / Summarize buttons in main sheet; evaluation log via `diary-evaluation-log-btn`.

## Widget keys / telemetry

- `diary-composer-field`
- `diary-send-btn`
- `diary-send-busy`

## Notes

PRD 1.13. Watson to align Architecture §5.7.