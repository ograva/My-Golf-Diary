# SYNC-004 — Last-write-wins

| Field | Value |
| :--- | :--- |
| **ID** | SYNC-004 |
| **Module** | SYNC |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Rory**, I want **consistent merge rules**.

## Acceptance criteria

1. Newer updatedAt wins.
2. Tombstones delete locally.
3. Delete uploads tombstone first.
4. PWA matches mobile.

## Widget keys / telemetry

- _(see PRD / wireframes)_

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
