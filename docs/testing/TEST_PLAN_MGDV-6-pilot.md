# Test plan — MGDV-6 club tournament pilot (Quinn)

| Field | Value |
| :--- | :--- |
| **Date** | 2026-11-23 |
| **Author** | Quinn (QA cohort) |
| **Shards** | MGDV-6-010 … MGDV-6-015 |
| **Wireframes** | [Wireframe_Tournament.md](../context/designs/Wireframe_Tournament.md), [Wireframe_CaddyDispute.md](../context/designs/Wireframe_CaddyDispute.md) |
| **Status** | **Documentation only** — no `golf_diary_app/test/` files in this pass per product owner request. Athena implements tests when development starts (Step 9 refine). |

## Conventions

- Widget tests use `find.byKey(ValueKey('…'))` from wireframe Key maps.
- Fake `FirebaseAuth` for sign-in gate tests; fake Firestore for enrollment pull (or in-memory tournament seed).
- GPS / Vertex not involved except **diary silence** assertions (no model client call on event paths).

## Planned test files (not created yet)

| File | Shard | Notes |
| :--- | :--- | :--- |
| `test/mgdv_6_010_tournament_enrollment_test.dart` | MGDV-6-010 | enroll blocked when auth null; withdraw confirm |
| `test/mgdv_6_011_event_round_rules_test.dart` | MGDV-6-011 | format toggle disabled with `event_id` on round |
| `test/mgdv_6_012_leaderboard_test.dart` | MGDV-6-012 | sort Molave vs gross; stale banner |
| `test/mgdv_6_013_committee_attestation_test.dart` | MGDV-6-013 | lock after `closes_at_ms`; late flag |
| `test/mgdv_6_014_tournament_diary_test.dart` | MGDV-6-014 | system row inserted; mock Vertex never called |
| `test/mgdv_6_015_caddy_dispute_test.dart` | MGDV-6-015 | dispute flag blocks tournament submit when required |

## AC → test matrix (MGDV-6-010)

| AC | Test case | Keys / fakes |
| :--- | :--- | :--- |
| Pilot list only | Seed one `ph-mgdv6-intramuros-pilot` row | `tournament-event-card-*` |
| Sign-in required | Tap enroll without auth → gate | `tournament-sign-in-gate` |
| Local enrollment row | After enroll, SQLite has `enrolled` | repository unit |
| Withdraw | Confirm dialog clears event link | `tournament-withdraw-confirm` |

## AC → test matrix (MGDV-6-011)

| AC | Test case | Keys |
| :--- | :--- | :--- |
| Locked format | Event round disables `scorecard-format-toggle` | badge `scorecard-event-badge` |
| Diary silence | Save paths skip Vertex when flag set | spy on diary service |
| Marker policy | Submit disabled until marker attest | `tournament-submit-btn` |
| Personal round | No event id → MGDV-601 behavior | existing format tests |

## AC → test matrix (MGDV-6-012)

| AC | Test case | Keys |
| :--- | :--- | :--- |
| Enrollees only | Row uids match enrollment set | `tournament-leaderboard-row-*` |
| Publish update | Mock publish bumps standing | integration optional |
| Audit state | Mismatch icon when flag in cache | row decoration |
| Offline stale | Banner when `updated_at_ms` old | `tournament-leaderboard-stale` |

## AC → test matrix (MGDV-6-013)

| AC | Test case | Keys |
| :--- | :--- | :--- |
| Marker attest | Stores name + role | `tournament-marker-attest-btn` |
| Committee lock | Writes rejected after close | `tournament-committee-lock-banner` |
| Late correction | Edit after lock sets flag | `tournament-late-correction-banner` |

## AC → test matrix (MGDV-6-014)

| AC | Test case | Keys |
| :--- | :--- | :--- |
| Wrap note | System diary entry on close | `diary-tournament-wrap` |
| Range link | Tap opens Range tab | `diary-tournament-range-link` |
| No Vertex | Close handler does not call AI | mock |

## AC → test matrix (MGDV-6-015)

| AC | Test case | Keys |
| :--- | :--- | :--- |
| Full flight picker | Four players on strip | `caddy-player-strip` |
| Dispute | Banner + audit, strokes unchanged | `caddy-hole-dispute-btn` |
| Submit gate | Event requires caddy attest | `tournament-submit-btn` |

## Handoff to Athena

When implementing shard **MGDV-6-010**, add the first test file above **before** UI polish; mark shard **Test coverage** checkboxes in `docs/shards/MGDV/` as files land. Run `flutter analyze` + `flutter test` from `golf_diary_app/`.