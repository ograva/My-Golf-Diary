# BAG-001 — Filter by category

| Field | Value |
| :--- | :--- |
| **ID** | BAG-001 |
| **Module** | BAG |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Blake**, I want **category chips** so I see **only relevant clubs**.

## Acceptance criteria

1. Chip selection filters the club list without restarting the app.
2. Switching categories updates the visible clubs immediately.
3. Empty category shows a safe empty state (`bag-empty-category`).
4. Selected category is not required to persist across app restarts.

## Widget keys / telemetry

- `bag-category-chip-{category}`
- `bag-empty-category`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
