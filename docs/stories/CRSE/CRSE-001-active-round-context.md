# CRSE-001 — Active round and course context

| Field | Value |
| :--- | :--- |
| **ID** | CRSE-001 |
| **Module** | CRSE |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Rory**, I want **course pickers and hole context** so par and hole count match where I play.

## Acceptance criteria

1. App ensures an active round without crashing on errors.
2. Course field suggests catalog and recent venues.
3. Catalog course applies hole count and default pars.
4. Hole stepper respects 9/18 and loads saved rows.

## Widget keys / telemetry

- `oncourse-course-name-field`
- `on-course-hole-label`
- `on-course-hole-previous`
- `on-course-hole-next`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
