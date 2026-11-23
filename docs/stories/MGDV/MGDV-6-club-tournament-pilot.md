# MGDV-6 — Club tournament pilot (epic narrative)

| Field | Value |
| :--- | :--- |
| **ID** | MGDV-6 (pilot) |
| **Module** | MGDV |
| **Priority** | High |
| **Status** | Planned |
| **Shard** | Epic index — [MGDV-6-010…015](../../context/BACKLOG.md) |
| **PRD** | [PRD §3 MGDV-6](../../context/PRD.md) |
| **Shipped foundation** | [MGDV-601](MGDV-601-scoring-formats-epic.md) |

## User story

As **Rory** at **Club Intramuros**, I want **to enroll, play under event rules, see event standings, and get a post-tournament diary note** so **the app supports a real club day without replacing club back-office systems**.

## Child stories (planned)

| ID | Story file | Focus |
| :--- | :--- | :--- |
| MGDV-6-010 | [MGDV-6-010-club-tournament-enrollment.md](MGDV-6-010-club-tournament-enrollment.md) | Pilot enrollment + auth |
| MGDV-6-011 | [MGDV-6-011-tournament-event-rules.md](MGDV-6-011-tournament-event-rules.md) | Event-locked round mode |
| MGDV-6-012 | [MGDV-6-012-event-leaderboard.md](MGDV-6-012-event-leaderboard.md) | Event-scoped standings |
| MGDV-6-013 | [MGDV-6-013-committee-attestation.md](MGDV-6-013-committee-attestation.md) | Marker/committee lock |
| MGDV-6-014 | [MGDV-6-014-post-tournament-diary.md](MGDV-6-014-post-tournament-diary.md) | Wrap → Range handoff |
| MGDV-6-015 | [MGDV-6-015-caddy-flight-hardening.md](MGDV-6-015-caddy-flight-hardening.md) | Caddy trust for tournaments |

## Acceptance criteria (epic-level)

1. Enrollment requires durable auth; pilot events only.
2. Event-locked format and attestation policy on enrolled rounds.
3. Leaderboard scoped to event enrollees; audit on edited-after-attest.
4. Marker/committee attestation and committee lock window.
5. Post-event diary context note without automatic model call.
6. Caddy hardening bridges MGDV-501 deferrals when events require caddy submit.

## Widget keys / telemetry

- TBD with Eunice after Watson aligns data model (shipped scoring/flight keys in MGDV-601 wireframes).

## Notes

Back-office tournament ops (Gscore-class) stay out of scope. Depends on Watson Architecture for `tournament_*` tables and Firestore rules. **MGDV-7** (barefoot practice) remains roadmap-only — no stories until storage architecture lands.