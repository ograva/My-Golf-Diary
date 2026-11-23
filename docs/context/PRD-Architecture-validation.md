# PRD ↔ Architecture validation — My Golf Diary

| Field | Value |
| :--- | :--- |
| **Date** | 2026-11-23 (MGDV-6 addendum) |
| **Author** | Jason / Watson / Eunice / Quinn (cohorts) |
| **PRD** | [PRD.md](./PRD.md) v1.13 |
| **Architecture** | [Architecture.md](./Architecture.md) v1.21 |
| **Method** | Section-by-section compare after `graphify query` orientation and shipped-code audit (`golf_diary_app/`, `docs/shards/`) |

## Executive summary

**Verdict:** PRD v1.9 and Architecture v1.16 are **aligned on shipped reality** (FWY/SIM On Course, OSM map packs, avatar sync header, onboarding, cart scorecard, partial Vertex diary). Remaining gaps are **documented consistently** in both (sync table expansion, scorecard vs shot precedence, pack catalog coverage, RNGE-004 token compaction, SYNC email verification).

**Trivial PRD fixes applied in this PR:** stale v1.9 revision note (map-provider drift resolved in Arch 1.16), persona copy treating `SYNC-005` as wholly future, and `SYNC-003` AC implying `SYNC-006` is not yet shipped.

**Defer to user / Watson (not edited in PRD here):** terminology harmonization **Course/FWY** and **Simulator/SIM** inside older CRSE AC bullets; expanding `syncFull` per `SYNC-007`; manual-scorecard lock.

---

## 1. Document headers & traceability

| Check | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Version pairing | 1.9 (2026-11-20) | 1.16 (2026-11-20), inputs cite PRD v1.9 | **Aligned** |
| Module prefixes | BAG, CRSE, SCOR, RNGE, SYNC, MGDV | Same in §4 | **Aligned** |
| Stories location | §3 embedded; header says optional `docs/stories/` | — | **Action:** file-per-story tree added in this PR; PRD header updated |
| Stale cross-ref | v1.9 note still asked Watson to reconcile §5.5 Google Static | §5.5 now OSM / CRSE-041, supersedes 1.15 | **Fixed in PRD** (note updated) |

---

## 2. Executive summary & personas

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Four tabs + default On Course | Journey + modules | `HomeShell` default index 2 (§3.1) | **Aligned** |
| PWA | GitHub Pages CI | `publish-pwa.yml`, gh-pages (§6) | **Aligned** |
| Multi-device account | Persona table still said `SYNC-005`–`010` all “future” | `SYNC-005` shipped; `SYNC-006` partial | **Fixed in PRD** — avatar shipped; full retrieve = `SYNC-007+` |

---

## 3. Feature modules — BAG

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| UI pattern | Stat-tile cards `BAG-010`, no Details sheet | MGDV-203, §3.1 | **Aligned** |
| RNGE → club blend | BAG-002 AC (4) | §5.3 pairwise blend | **Aligned** — open product question remains in §7 (overwrite vs blend) |
| Category filter | BAG-001 | `clubs_screen.dart` | **Aligned** (chip filter not persisted — both OK) |

---

## 4. Feature modules — CRSE (FWY / SIM)

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Mode naming | UI labels **FWY** / **SIM**; some AC still say “Course/Simulator mode” | Code uses `!_simulator` = FWY (§5.6) | **Minor drift** — wireframes/keys still use `oncourse-mode-course`; no code change needed; Eunice may add glossary |
| Layouts | CRSE-035 SIM compact, CRSE-036 FWY map shell | §5.6 table | **Aligned** |
| Holing stroke | CRSE-004 shipped | §5.2.1 + tests | **Aligned** |
| Live pin distance | CRSE-005 | §5.4 gating FWY + surveyed coords | **Aligned** |
| Map imagery | CRSE-006 = OSM packs (`CRSE-041`) | §5.5 supersedes Google Static | **Aligned** (was top concern in PRD 1.9 draft note) |
| Legacy tabular HUD / map toggle | Removed on FWY (PRD) | §5.6 explicit removal | **Aligned** |
| CRSE-007 optional sim fields | Chip-based in shipped app | DB v15 optional cols (Arch) | **Aligned** |
| CRSE-008 aim bearing | Full bearing UX in PRD | `aim_direction` L/C/R shipped; lat/lon deferred (§8 gaps) | **Aligned** as known partial |
| CRSE-011 unmapped | Stand-in + full scoring | §5.5 coverage gap + §9 constraint | **Aligned** |
| Map pack auth | Download when online | Anonymous auth OK for Storage read (§6) | **Aligned** — offline play without pack is stand-in/vector |

---

## 5. Feature modules — SCOR

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Cart view | SCOR-004 / MGDV-401 | §3.1, DB prefs on `golfer_profile` | **Aligned** |
| Strokes vs shots | SCOR editor + CRSE finish | §5.2 precedence: fairway/caddy/holing can overwrite manual strokes | **Aligned** — Architecture §8 gaps table; PRD §7 open question — **recommend** product decision on “manual lock” |

---

## 6. Feature modules — RNGE

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Drills catalog | RNGE-003 | `practice_drills` v5, tombstones §9.7 | **Aligned** |
| Session compile | RNGE-005 shipped | §5.3.1, `range_sessions` v6+ | **Aligned** |
| Vertex diary | RNGE-004 partial | §5.7, `firebase_ai`, App Check | **Aligned** |
| Token ceiling | PRD AC + §7 | Arch §5.7; §8 gap “compaction partial” | **Aligned** — forward work |
| syncFull omission | PRD SYNC overview | `range_sessions`, diary tables not in `syncFull` | **Consistent** with `SYNC-007` future |

---

## 7. Feature modules — SYNC

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Avatar menu | SYNC-005 shipped | `AccountAvatarAppBarMenu` §3.1 | **Aligned** |
| Sign-in | SYNC-006 partial (gaps listed) | `AccountAuthController`, google_sign_in | **Aligned** |
| Anonymous default | SYNC-003 | `SyncIdentity` §6 | **PRD AC(3)** still said durable accounts “future” — **fixed** to partial ship |
| Map packs + sync | Storage `course_maps/` | Same §6 | **Aligned** |
| SYNC-007–010 | Future in PRD | Arch §8 gap on table expansion | **Aligned** — same backlog |
| Profile/settings screens | SYNC-009/010 AC | `account_profile_screen.dart`, `account_sync_settings_screen.dart` exist — polish vs AC | **Mostly shipped UI**; PRD still marks future for completeness of email verification / dirty row counts — OK |

---

## 8. MGDV / shell / PWA / caddy

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Onboarding | MGDV-2-001 shipped | `OnboardingGate` §3.1 | **Aligned** |
| Skill tier / disclosure | MGDV-2-002, BAG-010 | MGDV-203, `yardage_display_copy` | **Aligned** |
| Diary not a tab | MGDV-2-003 | `SwingDiarySheet`, header `diary-entry-*` only | **Aligned** (edge swipe retired) |
| Caddy PWA | Journey step 11 | MGDV-5 §6, `CaddyShell` | **Aligned** — rules hardening deferred per Arch |
| Tab state | — (implicit) | `IndexedStack` SHELL-001 | **Story added** |
| PWA publish | NFR + deps | Workflow §6 | **Story PWA-001 added** |

---

## 9. Data & SQLite

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| DB version | Implied v15 features | **v15** explicit §5, §8 | **Aligned** |
| Yards storage | NFR | §5.1, constraint §9.3 | **Aligned** |
| `golfer_profile` not synced | MGDV + SYNC | §6, SYNC-007 | **Aligned** |

---

## 10. Map packs (CRSE-041)

| Topic | PRD | Architecture | Finding |
| :--- | :--- | :--- | :--- |
| Pipeline | `tools/map_pack/`, shard CRSE-041 | §5.5, repo layout §3 | **Aligned** |
| Client cache | `CourseMapCacheService` | Native disk + web memory (no SQLite table) | **Aligned** — PRD should not promise persistent web disk cache |
| Coverage | Not all PH courses | §8 gap “pack catalog coverage” | **Aligned** |
| Attribution | OSM ODbL | `oncourse-map-attribution` | **Aligned** |

---

## 11. Constraints & NFRs

| Constraint | PRD NFR | Architecture §9 | Finding |
| :--- | :--- | :--- | :--- |
| Local-first offline | Yes | §9.2 | **Aligned** |
| No Maps SDK in Flutter | Out of scope 3D; CRSE-006 OSM | §9.8 no `google_maps_flutter` | **Aligned** |
| No player API keys | RNGE-004 | §9.8 Vertex project-billed | **Aligned** |
| Battery / GPS | CRSE-005 stream rules | §8 GPS bullets | **Aligned** |
| Firestore rules | SYNC deps | §6 rules snippet | **Aligned** |

---

## 12. Recommended follow-ups (not in this PR)

| Priority | Owner | Recommendation |
| :--- | :--- | :--- |
| High | Watson + Athena | Implement or reject **manual scorecard lock** when shots/caddy sync (§5.2) |
| High | Athena | Expand **`syncFull`** for `range_sessions`, `practice_drills`, diary tables when `SYNC-007` prioritized |
| Medium | Jason + Eunice | Glossary: **FWY/SIM** vs Course/Simulator in wireframes and older CRSE AC |
| Medium | Athena | **SYNC-006** email verification before first push; forgot-password |
| Medium | Owner ops | Upload remaining **CRSE-041** packs for catalog courses |
| Low | Athena | RNGE-004 **250k-token** compaction in production prompts |
| Low | Watson | CRSE-038/040 manual pin on stand-in; full aim lat/lon columns |

---

## 13. MGDV-6 club tournament pilot (2026-11-23 addendum)

| Check | PRD | Architecture | Design / QA | Finding |
| :--- | :--- | :--- | :--- | :--- |
| Stories MGDV-6-010…015 | §3 full AC | §5.0.2 planned v18 + Firestore paths | [Wireframe_Tournament.md](./designs/Wireframe_Tournament.md) | **Aligned** — spec ready, not implemented |
| Enrollment auth gate | SYNC-006 durable account | §5.0.2 anonymous until enroll | `tournament-sign-in-gate` | **Aligned** |
| Leaderboard scope | Event enrollees only | `tournament_standing_cache` | `tournament-leaderboard` | **Aligned** |
| No Gscore / payments | Out of scope §6 | No payment tables | fee copy only | **Aligned** |
| Caddy hardening | MGDV-6-015 | §5.0.2 dispute rows + rules upgrade | [Wireframe_CaddyDispute.md](./designs/Wireframe_CaddyDispute.md) | **Aligned** |
| Initial tests | — | §8 testing | [TEST_PLAN_MGDV-6-pilot.md](../testing/TEST_PLAN_MGDV-6-pilot.md) | **Documented** — no Dart tests yet (docs-only pass) |

**Open for implementation:** DB v18 migration, `firestore.rules` tournament match blocks, UI screens.

---

## Sign-off

PRD v1.13 and Architecture v1.21 support **MGDV-6 pilot implementation** (stories, shards, wireframes, test plan). Earlier sections (v1.9 ↔ v1.16) remain directionally valid for shipped modules; prefer Architecture **1.21** and PRD **1.13** for MGDV-6 and recent UX.