# SHARD-MGDV-6-010: Club tournament enrollment (pilot)

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-010 |
| **Epic** | MGDV-6 |
| **Module** | MGDV + SYNC |
| **Story Ref** | MGDV-6-010 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | L |
| **Depends On** | MGDV-601, SYNC-006 |

## Description

Signed-in golfers at the Intramuros pilot can browse posted club tournaments, enroll to tie a round to an event, and withdraw before committee lock. Event metadata (format lock, dates, fee copy) is read from seed data and/or Firestore; enrollment persists locally in SQLite first so play stays offline-capable.

## Acceptance Criteria

- [ ] Pilot tournament list shows only configured events with name, date, course, locked scoring format, and optional fee copy.
- [ ] **Enroll** is blocked until Google or email sign-in succeeds (`SYNC-006`); anonymous golfers see sign-in prompt with PRD copy.
- [ ] Enrolling writes `tournament_enrollment` (or Architecture-named equivalent) linking `userId`, `eventId`, and optional flight id; no network required to start a round.
- [ ] **Withdraw** before committee lock with confirm; withdrawn enrollment does not attach new rounds to the event.

## Test coverage

- [ ] **Unit/widget:** repository tests for enroll/withdraw state; gate when `FirebaseAuth.currentUser` is null.
- [ ] **Integration (if needed):** seed two events; enroll in one; verify round start sheet offers event context.
- [ ] **Keys:** [Wireframe_Tournament.md](../../context/designs/Wireframe_Tournament.md) §7 (`tournament-event-list`, `tournament-enroll-btn`, `tournament-withdraw-btn`, `tournament-sign-in-gate`).
- [ ] **Test plan:** [`TEST_PLAN_MGDV-6-pilot.md`](../../testing/TEST_PLAN_MGDV-6-pilot.md) § MGDV-6-010 — Dart files **not written** in docs-only handoff.

## Dev notes

- Story: [`MGDV-6-010-club-tournament-enrollment.md`](../../stories/MGDV/MGDV-6-010-club-tournament-enrollment.md).
- Watson must land `tournament_events` / `tournament_enrollments` schema + Firestore rules before UI ships; until then, stub pilot events in a feature flag seed.
- Enrollment auth is the ProjectBrief “anonymous until tournament” gate — do not require account for personal rounds.
- `golf_rounds` remains out of `syncFull` until SYNC-007; enrollment sync path may use a slim Firestore mirror.