# Product Requirements Document — My Golf Diary

## Document Header

| Version | Status | Date | Owner |
| :--- | :--- | :--- | :--- |
| 1.0 | Approved | 2026-11-06 | Jason (PM cohort) |

**Stories:** Embedded in §3 (16 total). Optional `docs/stories/[PREFIX]/` files can mirror these IDs later.

**Inputs:** [`ProjectBrief.md`](./ProjectBrief.md) v1.0 · Code: `golf_diary_app/lib/` (Flutter).

---

## 1. Executive Summary

My Golf Diary is a **local-first** Flutter companion: **My Bag** (club stats + swing notes), **On Course** (GPS fairway HUD, penalties, mulligans, concede, optional upload), **Scorecard** (18 holes + editor), **Range** (block drill, min/max/avg, notes). The product goal is **one trusted bag** and **traceable rounds** with **mode-based tabs** (bottom nav), not deep menus. Prefixes **BAG**, **CRSE**, **SCOR**, **RNGE**, **SYNC** bind requirements to [`Architecture.md`](./Architecture.md) code map.

---

## 2. Target Users & Personas

| Persona | Job | Design implication |
| :--- | :--- | :--- |
| **Rounds-first Rory** | Log shots + honest score between swings | CRSE + SCOR consistency |
| **Range-first Riley** | Block practice → aggregates on the right club | RNGE → BAG path |
| **Bag-first Blake** | Pre-round yardages + cues | BAG clarity + persistence |

---

## 3. Feature Modules

| Prefix | Module | Code |
| :--- | :--- | :--- |
| `BAG` | My Bag | `clubs_screen.dart`, `Club` |
| `CRSE` | On Course | `fairway_tracker_screen.dart`, `ShotRecord` |
| `SCOR` | Scorecard | `scorecard_screen.dart`, `scorecard_hole_editor.dart` |
| `RNGE` | Range | `range_drill_screen.dart`, `RangeDrillLog` |
| `SYNC` | Cloud (optional) | `cloud_sync_service.dart`, `initializeFirebase` in `main.dart` |

### BAG — My Bag

**Overview:** Category chips, per-club **min/max/avg**, **swing notes** (SQLite).

**BAG-001 — Filter by category**  
As **Blake**, I want **category chips** so I see **only relevant clubs**.  
**AC:** (1) Chip selection filters list. (2) Switching categories updates without restart. (3) Empty category shows safe empty state. (4) Post-resume behavior documented if not persisted.

**BAG-002 — Distance stats**  
As **Blake**, I want **min/max/avg visible** so I know **carry and spread**.  
**AC:** (1) Row shows three stats from DB. (2) Values survive app restart. (3) All-zero still renders safely. (4) RNGE updates propagate per Architecture (refresh/save rule).

**BAG-003 — Swing notes**  
As **Riley**, I want **per-club notes** so **cues travel to the round**.  
**AC:** (1) Edit + explicit save. (2) Success feedback. (3) Notes reload on return. (4) No controller leaks on navigate away.

### CRSE — On Course

**Overview:** Fairway HUD: course, hole/par, lie, club, **GPS shot**, penalties, mulligans, concede, finish hole/round, **sync** action.

**CRSE-001 — Active round**  
As **Rory**, I want **an active round + course name** so **data is grouped**.  
**AC:** (1) Bootstrap ensures/creates active round. (2) Course field tied to round. (3) HUD shows **round total** updates. (4) Bootstrap errors are non-crashing.

**CRSE-002 — GPS shot + pre-shot context**  
As **Rory**, I want **par, lie, club, then GPS capture** so **metadata matches each stroke**.  
**AC:** (1) Par chips persist to hole row when applicable. (2) Lie ∈ {tee, fairway, rough, bunker, green, penalty}. (3) Club chip selects id used on save. (4) On permission grant, record creates shot with hole, stroke, club, lie, lat/lon, time; denied → snackbar; busy blocks double-tap; list refreshes with distance or pending.

**CRSE-003 — Penalties, mulligans, concede**  
As **Rory**, I want **these on the HUD** so **I don’t switch screens mid-round**.  
**AC:** (1) +1/+2 penalties update totals. (2) Mulligan control increments + shows count. (3) Concede applies DB rule + refreshes. (4) Summary matches `RoundScore` after each action.

**CRSE-004 — Finish hole/round**  
As **Rory**, I want **Finish Hole / Finish Round** so **I progress through 18**.  
**AC:** (1) Advances hole & resets lie when &lt;18. (2) Hole 18 action matches final copy/behavior. (3) Persists + updates totals. (4) Invalid round id is safe.

### SCOR — Scorecard

**Overview:** Round picker, **18-hole grid**, totals vs par, **hole editor**, **new round**, conceded markers.

**SCOR-001 — View rounds + grid**  
As **Rory**, I want **recent rounds + 18 holes + totals** so **I verify the card**.  
**AC:** (1) Round selection loads holes 1–18. (2) Out/in/total vs par + penalty/mulligan rollups. (3) Loading doesn’t hang forever. (4) Tab focus can refresh (`loadScorecard`). (5) **New round** action creates round without corrupting prior data (reuse same flow as today).

**SCOR-002 — Hole editor**  
As **Rory**, I want **tap-to-edit** strokes/par/penalties/mulligans/concede/**complete**.  
**AC:** (1) Editor shows existing or defaults. (2) Saves to SQLite + updates aggregates. (3) Validation/clamps per code. (4) Concede marker in grid stays consistent with CRSE rules.

**SCOR-003 — Concede visibility**  
As **Rory**, I want **gimmes visible** on the grid.  
**AC:** (1) Conceded holes distinguished (e.g. *). (2) Updates if editor clears concede. (3) Totals match concede logic. (4) Not color-only if contrast fails.

### RNGE — Range

**Overview:** Non-putter club, **shot count**, min/max/avg fields, notes, **save** `RangeDrillLog`.

**RNGE-001 — Club + shot block**  
As **Riley**, I want **club + shot counter** so **the drill matches my ball count**.  
**AC:** (1) Putter excluded from horizontal chips. (2) Counter increments and displays. (3) Empty club list → empty state. (4) Selected club visually obvious.

**RNGE-002 — Enter aggregates + save**  
As **Riley**, I want **min/max/avg + notes + save** so **the session is recorded**.  
**AC:** (1) Fields parse to `RangeDrillLog` with club, counts, timestamp. (2) Default shot count 10 if counter zero per code. (3) Success snackbar. (4) Bad/non-numeric input fails safely (no crash). (5) After save, counter clears / reload per implemented UX.

### SYNC — Cloud sync (optional)

**Overview:** Firestore push of unsynced rows for `clubs`, `shots`, `round_scores`, `range_drills` under `users/{userId}/...`; default user id until auth.

**SYNC-001 — Firebase optional at launch**  
As **any user**, I want **app to run without Firebase** so **local always works**.  
**AC:** (1) Init failure doesn’t crash app. (2) `CloudSyncService.isAvailable` reflects Firebase. (3) README configure path stays valid. (4) No secrets in repo.

**SYNC-002 — Manual upload**  
As **Rory**, I want **sync from HUD** when online.  
**AC:** (1) If unavailable → snackbar “local only”. (2) If available → run `syncAll` + count message. (3) Rows marked synced after push. (4) No infinite dup push in normal path.

**SYNC-003 — Identity placeholder**  
As **product**, we need **documented `userId`** until auth.  
**AC:** (1) Default id (e.g. `local_user`) called out in README/Architecture. (2) Path stays `users/{userId}/...`. (3) Real auth = future epic. (4) Migration ownership listed in §7.

---

## 4. User Journey Map

1. Open app → sees **bottom tabs** (Bag / On Course / Scorecard / Range).  
2. **Pre-round** → My Bag: category + yardages + notes.  
3. **Tee** → On Course: course name, hole 1, par, lie tee, club, record shots with GPS at natural breaks.  
4. **Adjust** → penalties / mulligans / concede on HUD; **Finish Hole** through the round.  
5. **Verify** → Scorecard: totals; tap hole to fix strokes.  
6. **Range** → pick club, count swings, enter min/max/avg, save.  
7. **Backup** → On Course **cloud upload** if Firebase configured.  
8. **Next round** → new round from scorecard or implied active round behavior.

---

## 5. Non-Functional Requirements

| Area | Requirement |
| :--- | :--- |
| **Performance** | Tabs and shot save feel responsive; GPS read shows busy state (target: feedback ≤ ~2s typical). |
| **Security / privacy** | No keys in source; on-device SQLite; Firestore rules before prod sync (Watson). |
| **Accessibility** | Primary taps ≥48dp where feasible; theme contrast; respect OS font scale on core screens. |
| **Offline** | Bag, fairway, scorecard, range fully usable offline; sync best-effort. |
| **Location** | Request when recording; handle denied/deniedForever; document GPS accuracy limits (Architecture). |
| **Battery** | Single position read per shot (no tight polling) unless product changes. |

---

## 6. Out of Scope

1. Official **handicap** / GHIN / competition compliance mode.  
2. **Vector course maps** / flyovers beyond point capture.  
3. **Social** / live leaderboards / multiplayer real-time sync.  
4. **Auto** launch-monitor **Bluetooth** (manual/sim entry v1).  
5. **Watch-first** capture.  
6. **Web** client.

---

## 7. Open Questions & Dependencies

| Question | Owner |
| :--- | :--- |
| Yards vs meters (global preference)? | Watson + Product |
| RNGE aggregates: overwrite vs blend vs history-only? | Watson |
| Source of truth if shot count ≠ scorecard strokes? | Watson (document in Architecture) |
| iOS **Info.plist** location strings | Watson |
| Auth migration from `local_user` | Product + Watson |
| Analytics for Brief KPIs | Jason + Watson |

**Dependency:** Optional Firebase via `flutterfire configure`; `initializeFirebase` in `main.dart`.

---

## 8. Success Metrics

| KPI (from Brief) | v1 measurement |
| :--- | :--- |
| Clubs with non-zero avg @ 30d | Future SQL/analytics or manual |
| Shots per 18-equivalent | Local query / research |
| Complete 18-hole rounds | `round_scores` completion stats |
| RNGE saves / user / month | `range_drills` counts |

Interim: **5+ interviews** on “log at cart/bag” and “card matches round.”

---

## Document history

| Ver | Date | Summary |
| :--- | :--- | :--- |
| 1.0 | 2026-11-06 | From ProjectBrief v1.0 + code surfaces |
