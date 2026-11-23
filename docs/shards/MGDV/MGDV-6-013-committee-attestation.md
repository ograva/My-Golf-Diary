# SHARD-MGDV-6-013: Marker and committee attestation

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-013 |
| **Epic** | MGDV-6 |
| **Module** | MGDV |
| **Story Ref** | MGDV-6-013 |
| **Priority** | High |
| **Status** | Not Started |
| **Complexity** | M |
| **Depends On** | MGDV-6-011, MGDV-6-012 |

## Description

Markers and committee volunteers can attest published player cards for the pilot event. A committee **lock** freezes standings after the published close time; later golfer edits enter a late-correction audit state (notify-only, no prize engine).

## Acceptance Criteria

- [ ] Marker role can attest another golfer’s **published** card per event rules; persist `attested_by_name`, role, and timestamp distinct from self-attest (MGDV-601).
- [ ] **Committee lock** at event `close_at` prevents new standing mutations except flagged late corrections.
- [ ] Late golfer edits after lock show **late correction** workflow (in-app notice; optional push/email out of scope).
- [ ] Caddy attest from MGDV-601 remains valid on non-event rounds; event may require marker in addition.
- [ ] No GCash or payment settlement — fee reminders may be static copy only.

## Test coverage

- [ ] **Unit/widget:** lock window boundary tests; marker attest vs self-attest rows.
- [ ] **Integration (if needed):** lock → golfer edit → standings row shows late flag, not silent rank change without committee action.
- [ ] **Keys:** [Wireframe_Tournament.md](../../context/designs/Wireframe_Tournament.md) §5 (`tournament-marker-attest-btn`, `tournament-committee-lock-banner`, `tournament-late-correction-banner`).
- [ ] **Test plan:** [`TEST_PLAN_MGDV-6-pilot.md`](../../testing/TEST_PLAN_MGDV-6-pilot.md) § MGDV-6-013.

## Dev notes

- Story: [`MGDV-6-013-committee-attestation.md`](../../stories/MGDV/MGDV-6-013-committee-attestation.md).
- Role assignment for marker/committee is pilot-simplified (event config flag or manual uid list in Firestore).
- Prize logic and payouts stay outside the app per PRD and Roadmap §5.3.