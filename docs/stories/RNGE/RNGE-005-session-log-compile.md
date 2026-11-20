# RNGE-005 — Compile session log

| Field | Value |
| :--- | :--- |
| **ID** | RNGE-005 |
| **Module** | RNGE |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [RNGE-026-range-session-wrapup.md](../../shards/RNGE/RNGE-026-range-session-wrapup.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Riley**, I want **one log per range visit**.

## Acceptance criteria

1. Session note survives club switches.
2. Save and evaluate writes range_sessions.
3. List shows compiled sessions.
4. Works offline before Vertex.

## Widget keys / telemetry

- `range-save-evaluate-session-btn`
- `range-session-log-list`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
