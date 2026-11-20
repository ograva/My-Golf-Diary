# BAG-010 — Stat-tile club cards

| Field | Value |
| :--- | :--- |
| **ID** | BAG-010 |
| **Module** | BAG |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [BAG-010-glance-cards.md](../../shards/BAG/BAG-010-glance-cards.md) |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Blake**, I want **one compact card per club** with trend and session history.

## Acceptance criteria

1. One card per club at phone width; no Details button.
2. Sessions chip opens range logs for that club.
3. Four tiles: shortest, usual carry (hero), best, trend sparkline.
4. Yardage labels follow skill tier.
5. Edit opens club dialog; add-club remains in AppBar.

## Widget keys / telemetry

- `bag-club-card-{clubId}`
- `bag-range-logs-{clubId}`
- `bag-trend-{clubId}`
- `add-club-button`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
