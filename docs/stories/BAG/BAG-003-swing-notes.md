# BAG-003 — Swing notes on card

| Field | Value |
| :--- | :--- |
| **ID** | BAG-003 |
| **Module** | BAG |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Riley**, I want **per-club cues on the bag card** so they travel to the round.

## Acceptance criteria

1. Player can add or edit notes from the card.
2. Save persists swing_notes to SQLite.
3. Notes reload when returning to My Bag.
4. Navigating away does not leak text controllers.

## Widget keys / telemetry

- `bag-notes-add-{clubId}`
- `bag-notes-text-{clubId}`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
