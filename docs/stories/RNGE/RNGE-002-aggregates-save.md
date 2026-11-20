# RNGE-002 — Save drill block

| Field | Value |
| :--- | :--- |
| **ID** | RNGE-002 |
| **Module** | RNGE |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Riley**, I want **min/max/avg saved per block**.

## Acceptance criteria

1. Writes RangeDrillLog with venue and time.
2. Default 10 shots if counter zero.
3. Snackbar on success.
4. Safe parse on bad input.

## Widget keys / telemetry

- `range-save-block-btn`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
