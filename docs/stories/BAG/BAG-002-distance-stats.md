# BAG-002 — Distance stats on cards

| Field | Value |
| :--- | :--- |
| **ID** | BAG-002 |
| **Module** | BAG |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Blake**, I want **shortest, usual, and best carry** visible so I trust my numbers.

## Acceptance criteria

1. Each club card shows yardage tiles sourced from SQLite.
2. Values survive app restart.
3. All-zero distances render without layout errors.
4. After a Range save, returning to My Bag refreshes stats.

## Widget keys / telemetry

- `bag-min-yards-{clubId}`
- `bag-hero-yards-{clubId}`
- `bag-max-yards-{clubId}`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
