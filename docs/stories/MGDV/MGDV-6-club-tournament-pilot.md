# MGDV-6 — Club tournament pilot (epic narrative)

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6-010 … MGDV-6-014 |
| **Module** | MGDV |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | *(none — open after PRD 1.12)* |
| **PRD** | [PRD §3 MGDV-6](../../context/PRD.md) |

## User story

As **Rory** at **Club Intramuros**, I want **to enroll, play under event rules, see event standings, and get a post-tournament diary note** so **the app supports a real club day without replacing club back-office systems**.

## Acceptance criteria

1. Enrollment requires durable auth; pilot events only.
2. Event-locked format and attestation policy on enrolled rounds.
3. Leaderboard scoped to event enrollees; audit on edited-after-attest.
4. Marker/committee attestation and committee lock window.
5. Post-event diary context note without automatic model call.

## Widget keys / telemetry

- TBD with Eunice after Watson aligns data model.

## Notes

Back-office tournament ops (Gscore-class) stay out of scope. Depends on Watson Architecture pass for `tournament_*` tables and Firestore rules.