# Architecture — My Golf Diary

## Document Header

| Version | Status | Date | Owner |
| :--- | :--- | :--- | :--- |
| 1.18 | Active | 2026-11-20 | Watson |

**Inputs:** [`PRD.md`](./PRD.md) v1.11 · [`ProjectBrief.md`](./ProjectBrief.md) v1.0 · [`PH_Golf_Venues.md`](./PH_Golf_Venues.md) · [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md) · [`Range_Drills.md`](./Range_Drills.md) · shards **`CRSE-035`–`036`**, **`CRSE-041`**.

---

## 1. System Overview

**My Golf Diary** is a **local-first** Flutter app (mobile + **PWA** on GitHub Pages) under [`golf_diary_app/`](../../golf_diary_app/). The **system of record** is **SQLite** (`sqflite`, **v16**). **On Course** splits **FWY** (fairway / outdoor) vs **SIM** (simulator): FWY uses a full-bleed **`FwyHoleMap`** shell (`CRSE-036`) with GPS shot capture, Live/Manual ball position, aim ring, and OSM stylized packs when cached (`CRSE-006` / `CRSE-041`); SIM keeps a compact scroll + bottom sheets (`CRSE-035`). Each **`ShotRecord`** stores ball position (or typed sim yards); segment distance is **Haversine** → yards. Live yards-to-green (`CRSE-005`) uses a filtered `geolocator` stream when surveyed coords exist and mode is FWY.

**Scoring** is **`round_scores`** per hole with **`finishHole`** holing-stroke rules (`CRSE-004`). **Range** ships compiled **`range_sessions`** (`RNGE-005`). The **diary** (`RNGE-004`) is one ongoing thread: a range-block save and a finished or left **FWY**/**SIM** round write entries and do not call the model; **Feedback** and a typed note call **Vertex AI** and store the reply in that thread. **My Bag** uses skill-tier **stat-tile** cards (`MGDV-203`; no Details sheet). Optional **Firebase**: Firestore **`my-golf-diary`** LWW sync for core tables; **Firebase Storage** `course_maps/` for hole packs; **`AccountAvatarAppBarMenu`** (`SYNC-005`) + partial durable sign-in (`SYNC-006`). Web uses the same code path with `sqflite_common_ffi_web` (IndexedDB).

```mermaid
flowchart LR
  subgraph device [Device_Local_First]
    UI[Flutter_UI_PWA_and_mobile]
    CAT["Catalogs Venues Coords Drills"]
    LDS[LocalDatabaseService]
    DB[(SQLite_v16)]
    PACK[(course_maps_cache)]
    GPS[Geolocator]
    UI --> CAT
    UI --> LDS
    LDS --> DB
    GPS -->|"Shot read + CRSE-005 stream"| UI
    PACK -->|"FwyHoleMap offline CRSE-006"| UI
  end
  subgraph build [Owner_only_not_in_app]
    MP[tools_map_pack_OSMPNG]
  end
  subgraph cloud [Optional_Cloud_and_AI]
    FS[(Firestore_my_golf_diary)]
    FST[(Firebase_Storage_course_maps)]
    GEMINI["Vertex_AI RNGE-004"]
  end
  MP -->|admin_upload| FST
  CS[CloudSyncService] --> FS
  UI --> CS
  FST -->|"Auth getData pack download"| PACK
  UI -->|"Feedback or typed note RNGE-004"| GEMINI
  GEMINI -->|"reply stored in the diary thread"| DB
```

---

## 2. Technology Stack

| Tool / library | Version / note | Purpose |
| :--- | :--- | :--- |
| Flutter / Dart | SDK `>=3.0.0 <4.0.0` | UI & logic |
| sqflite / sqflite_common_ffi / sqflite_common_ffi_web | `^2.3.0` / `^2.3.3` / `^1.0.0` | Local SQLite on mobile, desktop tests, and web PWA (IndexedDB) |
| path | `^1.9.0` | DB & local cache paths |
| geolocator | `^14.1.2` | Single-shot GPS capture, live distance-to-hole stream (`CRSE-005`), & `distanceBetween` |
| firebase_core | `^5.1.0` | Optional Firebase initialization |
| firebase_auth | `^7.0.1` | Anonymous Auth + partial Google/email (`AccountAuthController`, `SYNC-006`) |
| firebase_storage | `^14.1.0` | Authenticated `getData` download of OSM hole packs (`course_maps/`) |
| cloud_firestore | `^7.1.0` | Optional pull/push LWW sync on named DB `my-golf-diary` |
| firebase_ai | `^5.1.0` | Vertex AI (`FirebaseAI.agentPlatform()`) swing diary — owner-billed, no player API keys |
| firebase_app_check | `^0.5.1` | Web reCAPTCHA Enterprise before diary calls |
| google_sign_in | `^6.2.2` | Google durable sign-in (`SYNC-006`) |
| path_provider | `^2.1.5` | Native `course_maps/{courseId}/` disk cache |
| provider | `^6.1.2` | State management where needed |
| google_fonts | `^9.0.0` | Playfair Display, Inter, Roboto Mono |
| wakelock_plus | `^1.3.2` | Optional cart scoring keep-awake (`MGDV-401`) |
| qr_flutter | `^4.1.0` | Caddy invite QR (`MGDV-5`) |
| http | `^1.1.0` | Abort in-flight Vertex streams |
| *Map packs (server)* | Python `tools/map_pack/` + Overpass | OSM → stylized PNG + `manifest.json`; owner uploads — **no Maps SDK in Flutter** |
| *PWA publish* | [`.github/workflows/publish-pwa.yml`](../../.github/workflows/publish-pwa.yml) | Push to `main` touching `golf_diary_app/**` builds web and force-pushes orphan `gh-pages` |
| *Agent tooling* | [`.cursor/rules/graphify.mdc`](../../.cursor/rules/graphify.mdc) | Mandatory `graphify query` before code exploration (`AGENTS.md` / `CLAUDE.md`) |

---

## 3. Repository & App Layout

```
My-Golf-Diary/
├── tools/map_pack/                   # CRSE-041 pipeline (Python, not Flutter)
├── storage.rules                     # course_maps/** read if auth; write deny clients
├── storage.cors.json                 # GET for PWA + localhost web origins
├── firebase.json                     # Storage rules target
├── .github/workflows/publish-pwa.yml
├── graphify-out/                     # Knowledge graph (graphify mandatory before code exploration)
└── golf_diary_app/lib/
    ├── main.dart                     # Firebase init, OnboardingGate, HomeShell (default tab On Course)
    ├── data/                         # ph_golf_catalog, ph_golf_hole_coords, practice_drill_seed
    ├── models/                       # golf_models, course_map_manifest, golfer_profile, range_session, caddy_session, …
    ├── on_course/                    # hole_projection, fwy_aim, on_course_shot_segment, hud gating
    ├── pwa/                          # build ID, update host, published-build probe
    ├── range/                        # club chip helpers
    ├── screens/                      # clubs, fairway_tracker (FWY/SIM), range, scorecard, home_shell, onboarding, account/caddy shells
    ├── services/                     # local_database_service (v16), course_map_cache_service, account_auth_controller, swing_diary_*, …
    ├── ui/                           # header_action_policy, yardage_display_copy
    ├── widgets/                      # fwy_hole_map, fwy_overlays, shared_header_actions, account_avatar_app_bar_menu, …
    └── theme/app_theme.dart

golf_diary_app/android/app/src/main/AndroidManifest.xml
golf_diary_app/ios/Runner/Info.plist
```

### 3.1 App shell, headers & navigation

- **`HomeShell`:** four-tab `NavigationBar` — **My Bag**, **Range**, **On Course** (default index), **Scorecard** — `IndexedStack` preserves tab state (`SHELL-001`).
- **`OnboardingGate`:** starter wizard (`onboarding_starter_wizard.dart`) until `golfer_profile.onboarding_completed`; PWA `?mode=caddy` bypasses to `CaddyShell`.
- **Trailing header:** every tab uses **`SharedHeaderActions`** → **`AccountAvatarAppBarMenu`** (`account-avatar-button`: Login, Sync, Profile, Settings — `SYNC-005` shipped). Legacy `sync_cloud_button.dart` remains for tests/reference; production UI is the avatar menu.
- **Golfer avatar** (`golfer_avatar.dart`, `golfer_avatar_circle.dart`): bundled portraits in `assets/avatars/` (512px PNG, transparent corners). One **`GolferAvatarCircle`** renders the header button, Account profile, Settings, and the diary sheet's "You" rows. **Precedence:** a signed-in Google `photoUrl` wins, as `SYNC-005` already specified. Next comes the illustrated avatar: `golfer_profile.avatar_choice` when set, otherwise female/male × tier (`seasoned_pro` → *seasoned*). Then initials for a signed-in account with no avatar, then the generic icon. Non-binary and prefer-not-to-say golfers get no gendered default and can pick any portrait. The menu re-provides `GolferProfileScope` to the Profile and Settings routes it pushes, so edits refresh the header.
- **Leading header:** **Bag** — add-club; **Range** — drills icon; **On Course FWY** — `PlayHeaderOverflowButton` (⋯: diary, caddy invite, Concede/Finish, on-course settings); **On Course SIM** — same overflow pattern; **Scorecard** — tier-aware diary/caddy per `HeaderActionPolicy`.
- **Diary access:** `SwingDiarySheet` via pinned diary button or overflow; **On Course** adds right-edge swipe (`oncourse-diary-edge-swipe`) — must not steal rail/map gutters (`CRSE-036`).
- **MGDV-203 Bag:** one stat-tile card per club (~136dp); **Details sheet retired**; session count chip → range log sheet.

---

## 4. Module Breakdown (PRD prefixes)

| Prefix | UI & Widgets | Data & Persistence |
| :--- | :--- | :--- |
| `BAG` | `clubs_screen.dart` stat-tile cards (`MGDV-203`) | `clubs`; reads `golfer_profile` for yardage labels |
| `CRSE` | `fairway_tracker_screen.dart`, `fwy_hole_map.dart`, `fwy_overlays.dart`, `venue_name_field.dart` | `shots` (+ `aim_direction`, sim optional cols v15), `round_scores`, `golf_rounds`; `CourseMapCacheService` + `course_map_manifest.dart`; coords catalog `CRSE-005`; FWY `CRSE-036` / SIM `CRSE-035` |
| `SCOR` | `scorecard_screen.dart`, `scorecard_cart_panel.dart` (`MGDV-401`), `scorecard_hole_editor.dart` | `round_scores`, `golf_rounds`; `golfer_profile.scorecard_view_mode`, `scorecard_cart_high_contrast` |
| `RNGE` | `range_drill_screen.dart`, `range_session_log.dart`, `practice_drill_sheet.dart`, `SwingDiarySheet` (`RNGE-004` one thread) | `range_drills` → `clubs`; `practice_drills`; shipped `range_sessions`; diary thread tables |
| `SYNC` | `account_avatar_app_bar_menu.dart`, `account_auth_controller.dart`, `diary_sync_runner.dart` | `CloudSyncService` → Firestore; `SyncIdentity`; Storage pack reads; `google_sign_in` |
| `MGDV` | `onboarding_starter_wizard.dart`, `golfer_profile_settings_screen.dart`, caddy widgets | `golfer_profile` (skill tier, onboarding, scorecard prefs); caddy Firestore + SQLite v14 tables |

---

## 5. Data Models & SQLite

**DB:** `golf_diary.db`, currently **version 16** (`LocalDatabaseService._initDB`). Migration chain: v2 club identity + range venue; v3 sync metadata; v4 `golf_rounds`; v5 `practice_drills` + `drill_id`; v6 **`range_sessions`** + `session_id` (`RNGE-005` **shipped**); v7 diary tables + `diary_settings`; v8 `golfer_profile`; v13 scorecard view prefs on profile; v14 caddy session/queue; **v15** `shots.aim_direction` (default `center`), `shots.sim_carry_yards`, `shots.sim_distance_to_hole_yards` (`CRSE-007`/`008` partial); **v16** `golfer_profile.avatar_choice` (`''` = auto).

**Still outside `syncFull` today:** `practice_drills`, `range_sessions`, swing-diary tables, `golfer_profile`, caddy queue — expand when `SYNC-007` lands (PRD).

### Tables (current)

- **`clubs`** — `id`, `name`, `category`, `brand`, `model`, `min_distance`, `max_distance`, `avg_distance` (yards), `swing_notes`, `is_synced`, `updated_at_ms`, `deleted`. Starter bag seeded on create.
- **`shots`** — above plus **`aim_direction`** (`left`/`center`/`right`, v15); optional **`sim_carry_yards`**, **`sim_distance_to_hole_yards`** (simulator, v15). **`isHoled`** is derived: `notes == 'Holed'` (`kHoledShotNote`). Holed strokes use putter + `lie_type` green (`finishHole` / `_recordHoledStroke`).
- **`round_scores`** — `id`, `round_id`, `course_name`, `hole_number`, `par`, **`strokes`**, `penalties`, `mulligans`, `conceded`, **`final_score`**, `is_synced`, `updated_at_ms`, `deleted`.
- **`golf_rounds`** — `round_id`, `course_name`, `started_at_ms`, `completed_at_ms`, `is_synced`, `updated_at_ms`, `deleted`.
- **`range_drills`** — same columns including nullable **`session_id`** → `range_sessions.id` (NULL = active visit block or legacy row).
- **`practice_drills` *(v5 — `RNGE-003`)*** — `id TEXT PRIMARY KEY`, `title TEXT NOT NULL`, `category TEXT NOT NULL`, `short_description TEXT NOT NULL`, `steps_json TEXT NOT NULL` (JSON array of step strings), `recommended_clubs TEXT`, `is_custom INTEGER NOT NULL DEFAULT 0`, `is_synced INTEGER NOT NULL DEFAULT 0`, `updated_at_ms INTEGER NOT NULL DEFAULT 0`, `deleted INTEGER NOT NULL DEFAULT 0`.
  - *Seed & Delete Mechanics:* On DB upgrade/create, `practice_drills` seeds the 12 reference drills from [`Range_Drills.md`](./Range_Drills.md) using their stable IDs (`rng-drl-*`) with `ConflictAlgorithm.ignore`. When a user deletes any drill (seeded or custom), `deleted = 1` and `updated_at_ms = _nowMs()` are set. Queries filter `WHERE deleted = 0`, ensuring deleted seeded drills stay hidden across restarts and sync.
- **`range_sessions` *(v6 — `RNGE-005` shipped)*** — `id TEXT PRIMARY KEY`, `venue_name TEXT NOT NULL DEFAULT ''`, `session_note TEXT NOT NULL DEFAULT ''`, `compiled_summary_json TEXT NOT NULL DEFAULT '[]'`, `timestamp INTEGER NOT NULL`, `is_synced INTEGER NOT NULL DEFAULT 0`, `updated_at_ms INTEGER NOT NULL DEFAULT 0`, `deleted INTEGER NOT NULL DEFAULT 0`.
  - `compiled_summary_json` snapshots the ordered list of club blocks at compile time (`clubId`, `clubName`, `shotCount`, `minYards`, `avgYards`, `maxYards`, `tempoNotes`, `drillId`, `drillTitle`, `drillSteps`) so the compiled session log remains self-contained for the Range session log even if a club or custom drill is later edited or deleted. Compiling this row does not call the model (`RNGE-004`, §5.7).

**Scoring helpers** (`golf_models.dart`): `computeFinalScore(strokes, penalties) = strokes + penalties` — **mulligans** stored but **not** in gross formula (display/practice).

### 5.1 Yards vs meters

- **Storage:** all distance columns are **yards**.
- **GPS math:** `distanceBetween` → meters → **`meters * 1.09361`** in `recordFairwayHit` and in `CRSE-005` live distance-to-hole.
- **v1:** no user-facing meters preference; adding one needs PRD + conversion layer.

### 5.2 Strokes vs shots (source of truth)

| Concept | Where | Meaning |
| :--- | :--- | :--- |
| **Shot** | `shots` | GPS-logged stroke on a hole (club, lie, positions). |
| **Strokes (scoring)** | `round_scores.strokes` | Used for **gross** with penalties. |

**Fairway path:** `recordFairwayHit` inserts a shot, then **`syncStrokeCountFromShots`** sets **`strokes = shots.length`** for that hole. So **recording a GPS shot overwrites** the hole’s stroke count with **shot count** (manual scorecard strokes can be replaced).

**Manual path:** `saveManualHoleScore` writes `strokes` directly; no auto-reconcile until another `syncStrokeCountFromShots` runs.

**HUD:** `strokes = holeScore?.strokes ?? shots.length`.

**Architectural stance:** `round_scores` is the **scorecard row**; `shots` is the **GPS audit**. Precedence for `strokes` after fairway capture is **syncStrokeCountFromShots** until product adds “manual lock” or merge rules.

#### 5.2.1 Finish hole & holing stroke (`CRSE-004` — shipped)

`LocalDatabaseService.finishHole`:

1. **`syncStrokeCountFromShots`** on the active hole.
2. **`_recordHoledStroke`** unless: hole **conceded**; **pickup at double par** (`strokes + penalties ≥ 2 × par`); or the last shot is already **`isHoled`**. Otherwise appends one **putter / green** shot with note **`Holed`**, then syncs strokes again.
3. Recomputes **`final_score`** for non-conceded holes; advances hole or **`completeRound`** on last hole.

**Concede:** `concedeHole` sets `conceded = 1`, `strokes = par × 2`, updates `final_score` — **no** holing stroke on subsequent `finishHole` (see `finish_hole_holing_stroke_test.dart`). **Known gap:** concede then manual scorecard edit vs shot-sync precedence — same class of conflict as §5.2 / caddy merge (PRD §7).

### 5.3 RNGE → club (`saveRangeDrill`)

After inserting **`range_drills`**, updates **`clubs`** for `log.clubId`:

- **min:** if club min was 0 → use `log.minYards`; else `min(club.min, log.minYards)`
- **max:** `max(club.max, log.maxYards)`
- **avg:** if club avg was 0 → `log.avgYards`; else `(club.avg + log.avgYards) / 2` (pairwise blend—not a true running mean over all shots)
- **swing_notes:** replace with `log.tempoNotes` if non-empty
- mark `is_synced = 0`

**Diary entry (`RNGE-004`):** the same save appends one thread entry and does not call Vertex. The entry holds the club, the drill when one is linked, the result (shot count and min/avg/max yards), and the per-club note when the golfer wrote one. A block with no note still writes the entry. Storage is §5.7.

Changing this math requires **Version History** + migration if schema changes.

### 5.3.1 Session Note & Compiled Range Session Log (`RNGE-005` — shipped v6)

A range visit often spans several clubs and drills before the golfer wraps up with personal takeaways. `RNGE-005` separates **per-club block capture** from **visit-level session compilation**:

```mermaid
flowchart TD
  subgraph Active_Range_Visit [Active Range Visit on RangeDrillScreen]
    ClubBlocks["Save Drill Session (1..N club blocks)\nWrites range_drills with session_id = NULL\nUpdates clubs min/max/avg + swing_notes\nWrites one diary entry; no model call"]
    SessionNote["Session Note TextField\n(ValueKey('range-session-note-field'))\nPersists across club chip switches"]
  end
  Trigger["Tap Save and evaluate session\n(ValueKey('range-save-evaluate-session-btn'))"]
  Flush{"Unsaved block inputs\n(shots > 0 or yards entered)?"}
  SavePending["Flush pending block via saveRangeDrill()"]
  Compile["Compile RangeSessionLogEntry:\n• venue_name, session_note, timestamp\n• Attach active visit's uncompiled range_drills\n• Snapshot club names, yardages, cues, & drill steps\n• Insert range_sessions + set range_drills.session_id"]
  UIList["Render in Range Session Log\n(ValueKey('range-session-log-list'))"]
  Saved["Confirmation: session log stored\non this device. No model call"]

  ClubBlocks --> Trigger
  SessionNote --> Trigger
  Trigger --> Flush
  Flush -->|Yes| SavePending --> Compile
  Flush -->|No| Compile
  Compile --> UIList
  Compile --> Saved
```

- **Two Distinct Note Scopes on `RangeDrillScreen`:**
  1. **Per-club Swing Cue & Mechanics Note (`_notesController`):** Reloads from `club.swingNotes` when switching club chips (or when tapping a practice drill title in `PracticeDrillSheet`) and saves onto each `RangeDrillLog` row and `clubs.swing_notes`.
  2. **Session Note (`_sessionNoteController`, `ValueKey('range-session-note-field')`):** Holds the golfer's overall thoughts and personal review of the range visit. Owned by `RangeDrillScreenState` (and preserved across tab switches by `HomeShell`'s `IndexedStack`), it is **never** overwritten when the golfer switches club chips or saves an individual club block.
- **Tracking Active Visit Blocks:**
  - As the golfer records clubs during a visit, `RangeDrillScreenState` tracks the IDs of `RangeDrillLog` rows saved during the current visit (or queries `range_drills` from today where `session_id IS NULL` and `deleted = 0`).
- **`compileAndSaveRangeSession` Transaction (`LocalDatabaseService`):**
  1. **Pending Block Flush:** When the golfer taps **Save and evaluate session** (`ValueKey('range-save-evaluate-session-btn')`), if the current club form has unsaved shot/yardage input (`_shotCounter > 0` or any of min/avg/max is non-empty), `RangeDrillScreen` first flushes that block via `saveRangeDrill` so no work is lost. If neither any club block in the visit nor a non-empty `session_note` exists, the button prompts the golfer to log a club block or write a session note first.
  2. **Compilation:** Joins the visit's `RangeDrillLog` rows with `clubs` (for `clubName`) and `practice_drills` (for `drill.title` and `drill.steps`), serializes the structured block list into `compiled_summary_json`, inserts a new `range_sessions` row (`id: 'rsess_${nowMs}'`), and sets `session_id = id` on the member `range_drills` rows inside a single SQLite transaction.
  3. **Post-Compile Reset:** Clears `_sessionNoteController`, resets the active visit's pending block list, and reloads the screen.
- **Session Log Rendering (`ValueKey('range-session-log-list')`):**
  - `RangeSessionLog` displays compiled `range_sessions` entries (showing date/time, venue, the overall `session_note`, and a compact breakdown of each club/drill block in the session) alongside any standalone/legacy `range_drills` rows, while preserving the existing `This club` / `All clubs` filter (filtering compiled sessions that include the selected club).
- **Handoff to `RNGE-004`:**
  - Each `saveRangeDrill` already wrote one diary entry (§5.3, §5.7). `compileAndSaveRangeSession` returns the persisted `RangeSessionLogEntry` and stops. Online or offline, the screen confirms the session log is stored on this device. It does not open an evaluation and does not call Vertex.

### 5.4 Live GPS Distance to Hole (`CRSE-005`)

- **Coordinate Lookup (`ph_golf_hole_coords.dart`):** Encodes verified WGS84 6-decimal Tee and Green/Pin coordinates from [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md) keyed by canonical course name and `holeNumber` (1–18).
- **Gating Rule:** `hasHoleCoordinates(courseName, holeNumber)` is true **only** when On Course is in `Course` mode (`!_simulator`) and a verified `HoleCoordinates(teeLat, teeLon, greenLat, greenLon)` entry exists for that exact course and hole.
  - Full 18-hole mapped courses (16 layouts) enable the metric on holes 1–18.
  - Partial courses (e.g., Hallow Ridge H1–H4, H6–H9; Sherwood Hills mapped holes) enable the metric **only** on mapped holes and turn it off on unmapped holes.
  - Unmapped courses (centroid-only or custom names) keep the metric and stream completely off.
- **Stream Lifecycle & Battery:**
  - When gated **on**, `FairwayTrackerScreenState` subscribes to `Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3))` (3-meter movement threshold) and performs an initial `getCurrentPosition` read so yardage appears immediately.
  - Remaining yardage is `((Geolocator.distanceBetween(pos.latitude, pos.longitude, greenLat, greenLon)) * 1.09361).round()`, rendered in `ValueKey('on-course-distance-to-hole')`.
  - The stream subscription is **cancelled immediately** on `dispose()`, when switching to `Simulator` mode, when changing to an unmapped course/hole, or when app lifecycle pauses.

### 5.5 OSM hole map packs & offline cache (`CRSE-006` / `CRSE-041` — shipped client; packs in progress)

**Decision (supersedes Architecture 1.15 Google Static path):** Hole imagery is **stylized OpenStreetMap** golf features rendered offline — **not** Google Maps satellite tiles. Google Maps Static/Tile APIs are **out of scope** for v1 (licensing forbids redistributing cached satellite; see shard [`CRSE-041`](../../docs/shards/CRSE/CRSE-041-map-pack-pipeline.md)). Architecture **1.15** remains in Version History for audit only.

```mermaid
flowchart TD
  FWY["FWY mode FwyHoleMap"] --> Local{"Pack on disk or web memory cache?"}
  Local -->|Yes| RenderPNG["hole_N.png + manifest frame + markers overlay"]
  Local -->|No| Remote{"course_maps in Storage + auth?"}
  Remote -->|Yes| DL["CourseMapCacheService getData"] --> RenderPNG
  Remote -->|No coords| Standin["StandinHole from par CRSE-036"]
  Remote -->|Coords no pack| Vector["Vector tee-green line badge"]
```

**Build pipeline (owner, not Flutter):** [`tools/map_pack/`](../../tools/map_pack/) — Overpass → normalize to surveyed tee/green → flat-colour PNG (720×1280, tee at bottom) + per-hole **`markers[]`** (target/layup) in `manifest.json`. Upload via `upload_packs.py` to **`course_maps/{courseId}/`** and merge **`course_maps/index.json`** versions. Contract: shard CRSE-041 + `tools/map_pack/README.md`.

**Client (`CourseMapCacheService`):**

- **`courseId`:** `ph-crse-*` map in `kCourseMapPackIds` (must match `courses.py`).
- **Fetch:** `SyncIdentity.ensureSignedIn()` then `FirebaseStorage.instance.ref(path).getData()` (10 MB cap); reads `index.json` once per session, compares versions, downloads manifest + hole PNGs.
- **Native cache:** `<appDocDir>/course_maps/{courseId}/`.
- **Web PWA:** in-memory `_memoryPacks` for the session; repeat fetches rely on browser HTTP cache (`Cache-Control` at upload) — **no** per-hole SQLite `course_map_cache` table today.
- **Manifest:** `CourseMapManifest` / `HoleMapFrame` with `frame.centerLat/Lon`, `bearingDeg`, `metersPerPixel`, `holes[].markers[]` for aim snap (`CRSE-039`).
- **Attribution:** `oncourse-map-attribution` — **© OpenStreetMap contributors (ODbL)** when pack image visible.

**Caching tiers**

| Tier | Location | Writer | Reader |
| :--- | :--- | :--- | :--- |
| 1 | OSM Overpass + `build_pack.py` | Owner laptop/CI | — |
| 2 | `gs://…/course_maps/{courseId}/manifest.json`, `hole_{n}.png` | `upload_packs.py` (service account) | Authenticated app `getData` |
| 3 | App doc dir or web memory | App after download | `FwyHoleMap` / `fwy_hole_map.dart` |

**Coverage gap:** Pipeline exists; not every catalog course has a published pack yet — FWY falls back to vector or stand-in without error (PRD `CRSE-011`).

### 5.6 FWY map-background shell & SIM compact layout (`CRSE-036` / `CRSE-035` — shipped)

| Mode | UI shell | Map |
| :--- | :--- | :--- |
| **FWY** (`!_simulator`) | Full-bleed **`FwyHoleMap`**; top scrim overlay (`oncourse-top-overlay`); side **rail** (club / lie / aim / pen / mul); shots peek sheet; **Record shot at ball** only in dock | Pack PNG, vector line, or **stand-in** (`StandinHole.forPar`) |
| **SIM** (`_simulator`) | Single-scroll compact stack + bottom sheets (`CRSE-035`); Record / Concede / Finish dock | **No** map pane |

**FWY specifics (see shard CRSE-036):**

- **Live vs Manual GPS** (`oncourse-gps-badge`, `OnCourseSettings`): Manual pin with stale-fix gate; diary edge swipe (`oncourse-diary-edge-swipe`) ignores rail gutters.
- **Aim ring** (`fwy_aim.dart`, `on_course_aim.dart`): snap to ring or manifest markers; persists **`shots.aim_direction`** L/C/R (v15); full bearing columns deferred.
- **Double par:** banner `oncourse-double-par-banner` — never auto-finishes; pairs with §5.2.1 holing-stroke skip.
- **Header:** leading overflow (diary, caddy, settings entries); trailing account avatar — legacy **`on-course-map-toggle`** / tabular FWY card **removed**.
- **Diary (`RNGE-004`):** finishing the round, or leaving it, in **FWY** or **SIM** writes one thread entry (course, mode, score, short shot summary) and does not call the model. See §5.7.

### 5.7 One diary thread (`RNGE-004` — locked in PRD 1.11)

PRD v1.11 retired the auto-evaluate path. **Save and evaluate session** compiles `range_sessions` (§5.3.1) and does not call the model. The diary is **one ongoing thread**: a personal log and an AI sounding board. It opens from Range, On Course (overflow and `oncourse-diary-edge-swipe`), and Scorecard. It is not a fifth tab. Entries stay on device and can be re-read offline.

The running client still starts a model call from **Save and evaluate session**. That path is retired here. §8 records the gap. This alignment adds no table and no column.

**When the model is not called.** These writes are local only:

1. **Range block.** `saveRangeDrill` writes one entry whether or not the golfer wrote a note. The entry holds club, drill when one is linked, result (shot count and min/avg/max yards), and the per-club note when one was written. `range_drills` and the club min/max/avg update (§5.3) still happen.
2. **FWY or SIM round.** Finishing the round, or leaving it, writes one entry: course, mode (`FWY` or `SIM`), score, and a short shot summary. `diary_context_notes.round_id` stores the round.
3. **Compile (`RNGE-005`).** `compileAndSaveRangeSession` stores the session log and confirms it on device. It does not write a second diary entry for blocks already saved, and it does not call Vertex.

**When the model is called.** Only these two, and only when the golfer has opted in, Firebase is up, and App Check is active. Offline, or before opt-in, the golfer's text stays in the thread and no call is made until Vertex can run.

1. **Feedback** (`diary-feedback-btn`). Submits recent thread entries, inside the token ceiling. The model returns an analysis. That analysis is saved as an entry in the same thread. Feedback is how a run of triggered entries is sent for coaching. It does not itself write a range or round entry.
2. **Typed note** (`diary-composer-field`, `diary-send-btn`). The text is saved as an entry first. The model then reads the thread, including that entry, and the reply is saved in the same thread on that turn.

```mermaid
sequenceDiagram
  participant User as Golfer
  participant App as Flutter App (SQLite)
  participant AI as Vertex AI Gemini

  User->>App: Save range block, or finish or leave FWY/SIM
  App->>App: Write one thread entry. No model call
  alt Feedback
    User->>App: Tap Feedback
    App->>App: Load coach prompt plus recent thread entries
  else Typed note
    User->>App: Send a typed note
    App->>App: Store the note, then load the thread including it
  end
  App->>AI: Prompt stays under about 250000 tokens
  AI-->>App: Analysis or reply
  App->>App: Save that text as the next entry in the same thread
  Note over App: Over the ceiling, store a periodic summary and drop the oldest raw text from the next prompt
```

**Who pays.** Unchanged. `FirebaseAI.agentPlatform()` (the `firebase_ai` 5.1 rename of `vertexAI()`) with App Check when the Firebase app is already configured, and the existing anonymous user. The model is `gemini-3.8-flash`. `gemini-2.5-flash` was shut down on Agent Platform on 2026-10-20. No `google_generative_ai` client and no API key in the binary. The project owner pays Vertex AI on `novusinc-8df79` while the diary stays under about **1,000 people**. At about 1,000 people, stop and plan again. Players do not paste their own Gemini keys. Vertex is billed only for tokens sent. The 250,000 figure is a ceiling, not the size of a new player's prompt. Opt-in is a local `diary_settings` row and is not part of `syncFull`. There is no second persona.

**What each call contains**, in order. The existing coach prompt stays. Diary entries are its context. A compiled `range_sessions` row is not attached and does not start the call.

1. **Coaching `systemInstruction`** (`Content.system` in `VertexDiaryModel`): a universal biomechanics / physio / caddie method, then this golfer's `golfer_profile` baseline, current bag, and frequent venues. Empty pillars add one optional Caddie Check-In. The method does not hard-code one person's clubs or injuries. Yardages stay grounded in the logged SQLite numbers.
2. **Current bag (`clubs` from SQLite)** — club names, categories, brand/model specs, recorded `min / avg / max yd`, and per-club `swing_notes`.
3. **Progress brief** — present only after a periodic summary exists. It states clubs and drills they returned to, cues they wrote, and how min / avg / max moved.
4. **Per-club tally** from SQLite, not from the model: session count, average this period versus the previous period, and the drill titles used most. Numbers stay exact after older notes are shortened.
5. **Diary thread entries, still raw**, while the whole prompt (including `systemInstruction`) is under the ceiling: range-block entries, FWY/SIM round entries, typed notes, and earlier model replies. Feedback sends the recent entries. A typed note is already stored, so the model reads it with the rest of the thread.
6. **This ask, in full** — the recent entries Feedback submitted, or the thread including the note just typed. That material is not folded into the progress brief.

**250,000-token ceiling.** Count the prompt before the call. While it fits, send the raw thread so the reply can see focus and progress directly. When the next call would pass about 250,000 tokens, compact the oldest material:

- Write a **periodic summary** row (the new progress brief) from the thread plus the previous brief. Keep the comparison facts above.
- Leave a recent raw window (about a month of entries, or the last several dozen) verbatim.
- Leave the entries this call is about in full.
- Later calls send the brief, the tally, the recent window, and those entries. Cost per message stays flat after the ceiling. It does not grow because the account is older.

**What is stored.** One visible thread, in `swing_diary_messages`, ordered by `timestamp`. Roles stay `user` and `model`. The sheet renders this list. No new table.

| Write | `swing_diary_messages` | Also stored | Model |
| :--- | :--- | :--- | :--- |
| Range block | `role = user`. Content is club, drill when linked, shot count, min/avg/max yards, and the note when present | `diary_context_notes` (`source = range`) with the same content | No |
| FWY/SIM finish or leave | `role = user`. Content is course, mode, score, and a short shot summary | `diary_context_notes` (`source = on_course`, `round_id` set) | No |
| Typed note | `role = user`. Content is the text, saved before any call | `diary_context_notes` (`source = diary`) | Then yes, if opted in and online |
| Feedback analysis or typed-note reply | `role = model`. Content is the analysis or reply | `range_evaluations` with `kind = evaluation` (same text) | This row **is** the call's result |
| Periodic summary | Shown in the thread, marked as a compaction note | `range_evaluations` with `kind = periodic_summary` | Written locally when the next prompt would pass the ceiling. Not a golfer-facing ask |

`diary_context_notes` (shipped): `id`, `source`, `content`, `context_date`, `round_id`, `timestamp`, plus the usual `is_synced` / `updated_at_ms` / `deleted`. A range block with no prose note still inserts a row; the result fields are the content. An empty string is not a valid entry.

`range_evaluations` (shipped, v7). `session_id` is no longer the thing that starts a call. Feedback and typed-note replies may leave it null. A periodic summary leaves it null.

| Column | Purpose |
| :--- | :--- |
| `id` | Primary key |
| `kind` | `evaluation` (a thread reply) or `periodic_summary` (the progress brief) |
| `session_id` | Nullable. Not the trigger |
| `session_date` | `YYYY-MM-DD` the note is about |
| `content` | The text the player can read. For `evaluation`, the same text as the `model` message |
| `prompt_tokens` | Size of the prompt that produced it, when known |
| `covered_through_ms` | For a periodic summary, the newest thread timestamp folded into the brief |
| `referenced_drill_ids_json` | Drills cited |
| `referenced_club_ids_json` | Clubs cited |
| `timestamp` | When the row was written |
| `is_synced`, `updated_at_ms`, `deleted` | Same sync shape as other diary tables. Sync can wait |

An `evaluation` row is the durable copy of a model entry in the thread. A `periodic_summary` row is the progress brief used in later prompts and shown in the same thread, marked so a reader can tell a compaction note from an analysis. Both are enough to re-read offline without calling Vertex again.

Do not add an embedding index in this phase. A question about a specific older day loads that day's thread entries by date and adds only those rows. When a number the entry does not carry is needed, load that day's `range_drills` or `range_sessions` by date and club as well. The compiled session log is not the prompt.

---

## 6. Sync & External Services

- **Init:** `initializeFirebase()` in `main.dart` / `cloud_sync_service.dart` uses [`firebase_options.dart`](../../golf_diary_app/lib/firebase_options.dart). Failure is soft; the app stays local-only.
- **Database:** named Firestore database `my-golf-diary` via `FirebaseFirestore.instanceFor(databaseId: ...)`. Do not write the `(default)` database.
- **Identity:** Firebase **Anonymous Auth** by default; **`AccountAuthController`** adds Google / email-password (`SYNC-006` partial). `SyncIdentity.ensureSignedIn()` and map-pack reads require **some** Firebase Auth session (anonymous OK). Enable Anonymous (+ Google/Email when testing durable accounts) in console.
- **Map packs:** Storage paths under `course_maps/`; same anonymous gate as sync. Deploy [`storage.rules`](../../storage.rules): read if `request.auth != null`; **write: false** for clients. CORS: [`storage.cors.json`](../../storage.cors.json) for PWA + `localhost` (GET only).
- **PWA:** [`.github/workflows/publish-pwa.yml`](../../.github/workflows/publish-pwa.yml) on `main` → `flutter build web` with `APP_BUILD_ID` = git SHA → orphan **`gh-pages`**. `PwaUpdateHost` prompts when published build is newer.
- **Client config:** `firebase_options.dart` holds the public web client config (API key is not a server secret). Re-run `flutterfire configure` when Android or iOS apps are registered.

**CloudSyncService.syncFull**

1. **Pull** every doc in `users/{uid}/{table}` for `clubs`, `shots`, `round_scores`, `range_drills`, `golf_rounds` (and `practice_drills` / `range_sessions` once enabled for sync).
2. **Last-write-wins:** remote `updatedAtMs` newer than local `updated_at_ms` replaces the row (`is_synced = 1`). A remote `deleted: true` tombstone removes the local row (or marks seeded `practice_drills` hidden with `deleted = 1`). An equal or older remote leaves the local row.
3. **Push** rows with `is_synced = 0`. A failed write stays dirty. A pushed tombstone is then removed locally (except seeded `practice_drills` rows, which retain `deleted = 1` locally so the seed is not re-inserted on next launch); the cloud doc stays so other devices can see the delete.

Club delete is a tombstone (`deleted = 1`), not an immediate local `DELETE`, so the next sync can tell other devices.

### MGDV-5 — Caddy round channel (v1)

Pairing uses a top-level Firestore collection **`caddy_round_channels/{channelId}`** where `channelId` is the opaque single-use token in the PWA QR (`?mode=caddy&request=`). Golfer mints while an active round exists; caddy redeems once (transaction → `status: active`). Stroke/score actions append to **`events`**; the golfer app **`CaddyGolferMergeHost`** listens and applies via **`recordCaddyStroke`** → **`syncStrokeCountFromShots`**. Caddy offline writes queue in SQLite **`caddy_pending_events`** and flush on reconnect.

**v1 limits:** Event writes are authenticated but not yet bound to session principal in rules (see `firestore.rules` comment). **Manual golfer scorecard edits** on the same hole can be overwritten when the next caddy stroke syncs (same precedence as GPS shot sync in §5.2). **Player picker**, hole-segment accept, and hardened rules are follow-up shards.

**PWA entry:** `OnboardingGate` bypasses golfer onboarding when `mode=caddy` is present and loads **`CaddyShell`** (On Course + Scorecard tabs only).

### Firestore security rules

Rules live in [`firestore.rules`](../../firestore.rules) and [`firebase.json`](../../firebase.json) targets database `my-golf-diary`. Deploy them on that database, not `(default)`:

```bash
firebase deploy --only firestore:my-golf-diary
```

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{subcollection}/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Do not** ship `allow read, write: if true` on user paths. Rows previously stored under `users/local_user` are not migrated.

---

## 7. Security & Privacy

- SQLite at rest = OS defaults; no app-level encryption in v1.
- `firebase_options.dart` is public client config. Do not commit **service account keys**, **Maps API keys**, or **Gemini API keys** in repository source. Map-pack upload uses owner credentials outside the app (`GOOGLE_APPLICATION_CREDENTIALS` / `FIREBASE_SERVICE_ACCOUNT_JSON` in `tools/map_pack/` only).
- Sync exposes data to cloud—deploy the named-database rules and turn on Anonymous Auth before production use.
- **Firebase Storage (`CRSE-041`):** `course_maps/**` — authenticated read only; all writes via admin upload scripts (`allow write: if false` in [`storage.rules`](../../storage.rules)).
- **Vertex AI (`RNGE-004`):** `FirebaseAI.agentPlatform()` on this Firebase project (`firebase_ai` 5.1 renamed `vertexAI()`). The owner pays while the diary stays under about 1,000 people. Calls run only for **Feedback** and a typed diary note (§5.7). Players do not supply Gemini keys. No model key in the client.

---

## 8. Performance, Platform & Testing

- **GPS:**
  - **Shot capture (`CRSE-002`):** single `getCurrentPosition` per “Record Shot”.
  - **Live distance to hole (`CRSE-005`):** distance-filtered position stream (`distanceFilter: 3` meters) active **only** while `FairwayTrackerScreen` is mounted, in **FWY** mode, and on a hole with verified coordinates. Cancelled off-screen, in **SIM** mode, or on unmapped hole.
- **DB:** version **15** (see §5 migration chain).
- **PWA / web:** `sqflite_common_ffi_web` + `PwaUpdateHost`; map packs session-cached in memory on web.

**Android** — `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.

**iOS** — `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Golf Diary uses your location to measure shot distances on the course.</string>
```

Background location **not** required for current flows.

**Testing:** `flutter test`; coverage includes `on_course_crse_036_test.dart`, `finish_hole_holing_stroke_test.dart`, `course_map_cache_service_test.dart`, `mgdv_203_progressive_disclosure_test.dart`, `header_action_policy_test.dart`. **Code exploration:** agents run **`graphify query`** before grep/read (`.cursor/rules/graphify.mdc`, `AGENTS.md`).

**Known implementation gaps (documented; do not paper over in code via Architecture):**

| Gap | Notes |
| :--- | :--- |
| Manual scorecard strokes vs `syncStrokeCountFromShots` | GPS/caddy/holing path can overwrite manual entry (§5.2) |
| `SYNC-007` table expansion | `range_sessions`, diary tables, profile still local-only in `syncFull` |
| Pack catalog coverage | CRSE-041 pipeline shipped; not all PH courses uploaded |
| RNGE-004 production ceiling | 250k-token compaction policy partial in live prompts |
| RNGE-004 thread writes | §5.7 is the locked contract. The running client still calls Vertex from **Save and evaluate session**. Block saves and FWY/SIM finish-or-leave do not yet write the §5.7 thread entries |
| CRSE-038/040 deferrals | Manual pin on stand-in; full aim lat/lon columns |

---

## 9. Constraints & non-negotiables

1. **Stack:** Flutter/Dart under `golf_diary_app/lib/`.
2. **Local-first:** works offline without Firebase or AI connectivity.
3. **Units:** Yards in persistence and HUD distance-to-hole (`meters * 1.09361`); document metric UX in PRD before changing.
4. **Live GPS Gating (`CRSE-005` & FWY map):** Never fabricate surveyed tee/green coordinates. Turn off live yards-to-pin on unmapped holes and in **SIM** mode. FWY may show **stand-in** geometry (not survey) when coords or packs are missing — label with `oncourse-standin-badge`.
5. **Strokes vs shots:** any change to `syncStrokeCountFromShots` updates §5.2 + PRD.
6. **RNGE blend:** changes require Version History + migration if schema changes.
7. **Seeded vs Custom Drills (`RNGE-003`):** deleting a seeded drill must persist via tombstone/flag (`deleted = 1`) so it does not reappear on app restart.
8. **Firestore, Storage & Secrets:** no wide-open production rules on user data; **no Google Maps keys** in the Flutter repo; **no Gemini API keys** in the client. Hole maps are **OSM-produced packs** only (CRSE-041). Swing-diary uses Vertex AI billed to the project. Do not add player-supplied API keys. **No runtime `google_maps_flutter` / Mapbox SDK** for v1.
9. **Compiled Range Session Log & Diary thread (`RNGE-005` & `RNGE-004`):** Session-level notes (`range-session-note-field`) must stay separate from per-club swing cues so switching club chips never erases the visit note. **Save and evaluate session** (`range-save-evaluate-session-btn`) persists the compiled `range_sessions` row locally first (flushing any unsaved club block) and does not call the model. Saving a range block, and finishing or leaving a FWY or SIM round, each write one diary entry and do not call the model. The only model calls are **Feedback** (`diary-feedback-btn`) and a typed note (`diary-composer-field`, `diary-send-btn`), and only after that golfer text is already stored. Those calls stay under about 250,000 tokens; past that, persist a periodic summary and keep a recent raw window of thread entries. Store the analysis or reply in the same thread.
10. **Theme/keys:** `app_theme.dart`; FWY keys include `oncourse-map-background`, `oncourse-diary-edge-swipe`, `oncourse-double-par-banner`, `oncourse-map-attribution`; Bag `bag-club-card-{clubId}`; account `account-avatar-button`; see PRD 1.9 and Eunice wireframes.
11. **Dependencies:** justify in Version History when adding packages.

---

## Version History (architecture)

| Version | Date | Author | Summary |
| :--- | :--- | :--- | :--- |
| 0.1 | — | — | Stub |
| 1.0 | 2026-11-06 | Watson | Full tech spec: strokes vs shots, yards, RNGE→club, Firestore rules, iOS plist |
| 1.1 | 2026-11-07 | Watson | Named Firestore `my-golf-diary`, anonymous auth, pull-then-push LWW, tombstones |
| 1.2 | 2026-11-09 | Watson | Align with PRD v1.3: DB v4 (`golf_rounds`) + planned v5 (`practice_drills`), venue catalog, `CRSE-005` gated live GPS distance-to-hole stream, `CRSE-006` Google Maps → Firebase Storage → local offline map cache, `RNGE-003` seeded/custom drill persistence, and `RNGE-004` Google AI (Gemini) RAG Golf Swing Diary architecture |
| 1.3 | 2026-11-09 | Watson | RNGE-004 uses Vertex AI billed to the project under about 1,000 people. Prompts send raw drill history up to about 250,000 tokens, then a stored periodic summary plus a recent window, with today always in full. Evaluations and periodic summaries are kept in `range_evaluations` for a later reader log |
| 1.4 | 2026-11-09 | Watson | §1 names the swing diary as Vertex AI so it matches PRD 1.4. No change to the §5.6 design |
| 1.5 | 2026-11-09 | Athena | DB is version 5: `practice_drills` is seeded locally and `range_drills.drill_id` stores the drill used for a session. `practice_drills` is not in `syncFull` yet |
| 1.6 | 2026-11-11 | Watson | Align with PRD v1.5 (`RNGE-005`): add §5.3.1 for the visit-level session note (`range-session-note-field`) and compiled Range Session Log (`range_sessions` table + `range_drills.session_id` in planned DB v6, `range-save-evaluate-session-btn`, `range-session-log-list`), and wire compiled `range_sessions` as the primary payload into `RNGE-004` Vertex AI evaluation (`range_evaluations.session_id`) |
| 1.7 | 2026-11-11 | Athena | Shipped DB v6 (`range_sessions`, `range_drills.session_id`) and DB v7 (`swing_diary_messages`, `range_evaluations`, local `diary_settings` opt-in). Those tables stay out of `syncFull`. The diary client is `FirebaseAI.agentPlatform()` because `firebase_ai` 5.1 renamed `vertexAI()`. Recent raw window is the later of 30 days and the 36th newest non-today log |
| 1.8 | 2026-11-12 | Athena | Swing diary still calls Vertex from the app. `http` is a direct dependency so an in-flight `generateContentStream` can be aborted. No Cloud Function proxy |
| 1.9 | 2026-11-12 | Athena | Web startup activates Firebase App Check with the public reCAPTCHA Enterprise site key before diary calls. A failed activation does not turn Firebase off. Android and iOS providers stay off while those apps reuse the web client config |
| 1.10 | 2026-11-12 | Athena | Swing diary model is `gemini-3.8-flash`. Agent Platform shut down `gemini-2.5-flash` on 2026-10-20 |
| 1.11 | 2026-11-13 | Athena | Upgraded swing diary prompt with a structured biomechanics / physio / caddie `systemInstruction` (`Content.system`), live `clubs` bag snapshot, session venue/shot/spread formatting without duplicating compiled drill blocks, and zero-dependency Markdown table & `──►` diagram rendering in `SwingDiarySheet` |
| 1.12 | 2026-11-13 | Athena | DB v8 `golfer_profile` replaces the hardcoded personal baseline. Lead-in chips sit beside the session note and diary composer. Distillation reads only golfer-written notes after `distilled_through_ms` and never model replies |
| 1.13 | 2026-11-15 | Athena | MGDV-401 cart scoring on Scorecard tab. DB v13 adds `scorecard_view_mode` and `scorecard_cart_high_contrast` on `golfer_profile`. **`wakelock_plus`** keeps the screen awake during cart scoring on an in-progress round only (optional UX; no GPS change on CRSE). |
| 1.14 | 2026-11-15 | Athena | MGDV-5 caddy pairing: Firestore `caddy_round_channels`, PWA `mode=caddy`, DB v14 session/queue tables, `recordCaddyStroke`, **`qr_flutter`** for invite QR |
| 1.15 | 2026-11-19 | Watson | `CRSE-006` map provider decision: Google **Maps Static API** (server-side cache builder) → Firebase Storage → on-device WebP; reject runtime `google_maps_flutter`/Mapbox/OSM/Esri/MapKit for v1; document Reuben GCP enablement and key isolation |
| 1.16 | 2026-11-20 | Watson | Align with **PRD v1.9**: **supersede 1.15** with **CRSE-041 OSM** packs + `CourseMapCacheService`; **CRSE-036/035** FWY/SIM shells; holing stroke §5.2.1; DB **v15**; `SYNC-005` avatar; MGDV-203 stat tiles; PWA gh-pages workflow; graphify agent rule; known gaps table §8 |
| 1.17 | 2026-11-20 | Athena | Illustrated golfer avatars: `assets/avatars/`, DB **v16** `golfer_profile.avatar_choice`, `GolferAvatarCircle` precedence (Google photo → illustrated → initials → icon), Settings picker with amateur alternates |
| 1.18 | 2026-11-20 | Watson | Align with **PRD v1.11**: §5.7 is one diary thread. Range-block and FWY/SIM finish-or-leave writes do not call the model. **Feedback** and a typed note do, and the reply is stored in that thread. `RNGE-005` compile no longer starts evaluation. Token ceiling and project billing unchanged. No new table |
| 1.19 | 2026-11-23 | Athena | DB **v17**: round scoring format, paid tournament mulligans, course rating/slope, local attestation, and caddy flight player tables. Formats and the unofficial handicap estimate are derived. `golf_rounds` stays out of `syncFull`. |
