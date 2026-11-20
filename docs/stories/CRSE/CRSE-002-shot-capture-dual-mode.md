# CRSE-002 — Shot capture (FWY vs SIM)

| Field | Value |
| :--- | :--- |
| **ID** | CRSE-002 |
| **Module** | CRSE |
| **Priority** | High |
| **Status** | Shipped |
| **PRD** | [PRD §3](../../context/PRD.md) |

## User story

As **Rory**, I want **GPS on FWY** and **typed yards on SIM**.

## Acceptance criteria

1. Lie and club are chosen before save.
2. FWY: Record shot at ball captures GPS or manual pin.
3. SIM: distance travelled required; no GPS prompt.
4. Busy state prevents double-tap.

## Widget keys / telemetry

- `oncourse-record-shot-btn`
- `oncourse-sim-yards-field`
- `oncourse-mode-toggle`

## Notes

Product narrative for wireframe coverage; shard files hold engineering AC where they exist.
