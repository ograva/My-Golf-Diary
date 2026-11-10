# Product Requirements Document — My Golf Diary

## Document Header

| Version | Status | Date | Owner |
| :--- | :--- | :--- | :--- |
| 1.5 | Approved | 2026-11-10 | Jason (PM cohort) |

**Stories:** Embedded in §3 (26 total across v1 and planned roadmap). Optional `docs/stories/[PREFIX]/` files can mirror these IDs later. No file-per-story set for this version.

**Inputs:** [`ProjectBrief.md`](./ProjectBrief.md) v1.0 · [`PH_Golf_Venues.md`](./PH_Golf_Venues.md) · [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md) · [`Range_Drills.md`](./Range_Drills.md) · Code: `golf_diary_app/lib/` (Flutter).

---

## 1. Executive Summary

My Golf Diary is a **local-first** Flutter companion: **My Bag** (club stats + swing notes), **On Course** (GPS fairway HUD, live distance-to-hole metric on mapped courses, future cached course map view, penalties, mulligans, concede, optional upload), **Scorecard** (18 holes + editor), and **Range** (structured practice drills selector, block drill min/max/avg, notes, and a future Vertex AI Golf Swing Diary). The product goal is **one trusted bag** and **traceable rounds** with **mode-based tabs** (bottom nav), not deep menus. Cloud backup today is anonymous and per install. A future account menu in the sync slot (`SYNC-005`–`SYNC-010`) adds Google and email/password sign-in so the same diary can be saved to Firestore and opened on another phone or the PWA. Prefixes **BAG**, **CRSE**, **SCOR**, **RNGE**, **SYNC** bind requirements to [`Architecture.md`](./Architecture.md) code map.

---

## 2. Target Users & Personas

| Persona | Job | Design implication |
| :--- | :--- | :--- |
| **Rounds-first Rory** | Log shots + honest score between swings, with live distance to the pin and visual stroke tracking when course coordinates exist | CRSE + SCOR consistency; zero clutter on unmapped courses |
| **Range-first Riley** | Pick structured practice drills, log block aggregates on the right club, and review daily AI swing diary takeaways | RNGE drill catalog + RNGE → BAG path + future AI Swing Diary |
| **Bag-first Blake** | Pre-round yardages + cues | BAG clarity + persistence |

Rory, Riley, and Blake all keep one diary if they switch phones or open the PWA. That multi-device account is future `SYNC-005`–`SYNC-010`. It does not add a fourth persona, and it does not require an account before local play.

---

## 3. Feature Modules

| Prefix | Module | Code / Reference Docs |
| :--- | :--- | :--- |
| `BAG` | My Bag | `clubs_screen.dart`, `Club` |
| `CRSE` | On Course | `fairway_tracker_screen.dart`, `ShotRecord`, [`PH_Golf_Venues.md`](./PH_Golf_Venues.md), [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md) |
| `SCOR` | Scorecard | `scorecard_screen.dart`, `scorecard_hole_editor.dart`, [`PH_Golf_Venues.md`](./PH_Golf_Venues.md) |
| `RNGE` | Range | `range_drill_screen.dart`, `RangeDrillLog`, [`Range_Drills.md`](./Range_Drills.md) |
| `SYNC` | Cloud (optional) | `cloud_sync_service.dart`, `sync_cloud_button.dart` (future account avatar), `initializeFirebase` in `main.dart`, Firebase Storage (future map cache) |

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

**Overview:** Fairway HUD: course lookup & hole par, live distance-to-hole GPS metric (when hole coordinates exist), future cached hole map view with stroke plotting, lie, club, **GPS shot**, penalties, mulligans, concede, finish hole/round, **sync** action.

**CRSE-001 — Active round & course lookup**  
As **Rory**, I want **an active round + course name autocomplete** so **data is grouped and hole pars match my course**.  
**AC:** (1) Bootstrap ensures/creates active round. (2) Course field suggests recent courses and catalog entries from [`PH_Golf_Venues.md`](./PH_Golf_Venues.md) while allowing custom names. (3) Selecting a course with a published card applies hole par to unplayed holes and sets hole count (9 or 18). (4) HUD shows **round total** updates and bootstrap errors are non-crashing.

**CRSE-002 — GPS shot + pre-shot context**  
As **Rory**, I want **par, lie, club, then GPS capture** so **metadata matches each stroke**.  
**AC:** (1) Par chips persist to hole row when applicable. (2) Lie ∈ {tee, fairway, rough, bunker, green, penalty}. (3) Club chip selects id used on save. (4) On permission grant, record creates shot with hole, stroke, club, lie, lat/lon, time; denied → snackbar; busy blocks double-tap; list refreshes with distance or pending.

**CRSE-003 — Penalties, mulligans, concede**  
As **Rory**, I want **these on the HUD** so **I don’t switch screens mid-round**.  
**AC:** (1) +1/+2 penalties update totals. (2) Mulligan control increments + shows count. (3) Concede applies DB rule + refreshes. (4) Summary matches `RoundScore` after each action.

**CRSE-004 — Finish hole/round**  
As **Rory**, I want **Finish Hole / Finish Round** so **I progress through the course card**.  
**AC:** (1) Advances hole, loads next hole's catalog par (or 4), & resets lie when below course hole count. (2) Final hole (9 or 18) action completes the round. (3) Persists + updates totals. (4) Invalid round id is safe.

**CRSE-005 — Live GPS distance to hole**  
As **Rory**, I want **a live distance-from-hole yardage readout on the On Course HUD in Course mode** so **I can pick the right club for my approach**.  
**AC:** (1) Active **only** when On Course is in `Course` mode (off in `Simulator` mode) **and** the selected course + current hole have verified Tee and Green/Pin coordinates in [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md). (2) When coordinates are absent (unmapped course, unmapped hole on a partial course, or custom course), the distance-to-hole UI is completely hidden/turned off with no error state. (3) Computes Haversine distance (`Geolocator.distanceBetween` in meters × `1.09361`) from the player's live GPS position to the current hole's Green/Pin coordinate, displayed in whole yards (`ValueKey('on-course-distance-to-hole')`). (4) Updates as the player moves on the active hole and automatically pauses/stops location streaming when leaving the On Course tab, switching to Simulator mode, or selecting an unmapped hole/course to preserve battery.

**CRSE-006 — On-Course hole map view & cached course maps (Future Feature)**  
As **Rory**, I want **to switch between the HUD and a hole map view that plots tee-to-green geometry and my recorded strokes** so **I can visualize hole layout and shot dispersion offline**.  
**AC:** (1) Map toggle (`ValueKey('on-course-map-toggle')`) is enabled only when the active course and hole have tee and green coordinates in [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md). (2) Map view frames the vector line between the hole's Tee coordinate and Green/Pin coordinate and plots markers/polylines for each recorded `ShotRecord` (`start_lat/lon` → `end_lat/lon`) on the current hole. (3) **Map caching & sync architecture:** Course map imagery/tiles are fetched via Google Maps API, cached per course in **Firebase Storage**, and synced down to local device storage so once a course map is downloaded, the map view renders offline on the fairway without repeated live Google Maps API calls. (4) If offline and the course map cache is not yet downloaded locally, gracefully falls back to the standard HUD or a simplified coordinate vector canvas.

### SCOR — Scorecard

**Overview:** Round picker, **18-hole (or 9-hole) grid**, totals vs par, **hole editor**, **new round**, conceded markers.

**SCOR-001 — View rounds + grid**  
As **Rory**, I want **recent rounds + hole grid + totals** so **I verify the card**.  
**AC:** (1) Round selection loads holes (1–9 or 1–18 based on course card) and displays catalog par on unplayed tiles. (2) Out/in/total vs par + penalty/mulligan rollups. (3) Loading doesn’t hang forever. (4) Tab focus can refresh (`loadScorecard`). (5) **New round** action offers course autocomplete and creates a round with hole 1's catalog par without corrupting prior data.

**SCOR-002 — Hole editor**  
As **Rory**, I want **tap-to-edit** strokes/par/penalties/mulligans/concede/**complete**.  
**AC:** (1) Editor shows existing row par, or catalog par for that hole, or default 4. (2) Saves to SQLite + updates aggregates. (3) Validation/clamps per code. (4) Concede marker in grid stays consistent with CRSE rules.

**SCOR-003 — Concede visibility**  
As **Rory**, I want **gimmes visible** on the grid.  
**AC:** (1) Conceded holes distinguished (e.g. `Gimme`). (2) Updates if editor clears concede. (3) Totals match concede logic. (4) Not color-only if contrast fails.

### RNGE — Range

**Overview:** Header left-side drill selector drawer/sheet, non-putter club, **shot count**, min/max/avg fields, notes, **save** `RangeDrillLog`, plus a future Vertex AI Golf Swing Diary that comments on today’s drills in the light of earlier practice.

**RNGE-001 — Club + shot block**  
As **Riley**, I want **club + shot counter** so **the drill matches my ball count**.  
**AC:** (1) Putter excluded from horizontal chips. (2) Counter increments and displays. (3) Empty club list → empty state. (4) Selected club visually obvious.

**RNGE-002 — Enter aggregates + save**  
As **Riley**, I want **min/max/avg + notes + save** so **the session is recorded**.  
**AC:** (1) Fields parse to `RangeDrillLog` with club, counts, venue name, timestamp. (2) Default shot count 10 if counter zero per code. (3) Success snackbar. (4) Bad/non-numeric input fails safely (no crash). (5) After save, counter clears / reload per implemented UX.

**RNGE-003 — Structured practice drill catalog & custom drill manager**  
As **Riley**, I want **a list of practice drills accessible from a small icon on the left side of the Range header—with a short description, step-by-step instructions, and the ability to add my own drills or delete ones I don't like** so **my range sessions have clear structure**.  
**AC:** (1) A compact icon button on the left side of the Range AppBar (`ValueKey('range-header-drills-btn')`) opens the Practice Drills sheet/drawer. (2) The list is pre-populated from [`Range_Drills.md`](./Range_Drills.md), displaying each drill's title, category, and short description, and expanding on tap to show the numbered step-by-step instructions. (3) Selecting a drill links or copies the drill title/cue into the active Range session so the user can follow the steps and log their block. (4) Users can **add a custom drill** (title, category, short description, step-by-step instructions) and **delete any drill** (custom or seeded) they do not like, with changes persisted locally in SQLite (and sync-ready via tombstones/flags).

**RNGE-004 — Vertex AI range evaluation and Golf Swing Diary (Future Feature)**  
As **Riley**, I want **today’s range notes assessed against what I have been practicing, in a continuous diary I can keep reading**, so **I can see whether a cue or a yardage is actually moving**.  
**AC (Future Scope):** (1) **Today in context:** An on-demand evaluation covers that day’s drills, steps, min / avg / max, and tempo notes, and it says what the player has been focusing on and how those numbers compare with earlier sessions. (2) **Continuous diary:** Follow-up questions stay in one thread. A question about a specific older day uses that day’s saved logs. (3) **History that stays affordable:** While the prompt is under about 250,000 tokens, the model sees the real drill history. Past that ceiling, older history is replaced by a stored progress brief plus a per-club tally, a recent raw window remains, and today stays in full. The project owner pays Vertex AI while this stays under about 1,000 people. The player does not enter an API key. (4) **A log the player can read:** Every evaluation and every periodic summary is saved locally and can be reread without another model call. Range logging still works offline when Vertex is unreachable. Where the log appears in navigation is decided later.

```mermaid
flowchart LR
  subgraph Range_Tab [Range Tab]
    Today["Today's drills, in full"]
    History["Earlier drills, raw while the prompt fits"]
    Brief["Progress brief and per-club tally, after the ceiling"]
  end
  subgraph Vertex [Vertex AI, project billed]
    Eval["Evaluation of today against past focus"]
  end
  subgraph Log [Readable log]
    Rows["Saved evaluations and periodic summaries"]
  end
  Today --> Eval
  History --> Eval
  Brief --> Eval
  Eval --> Rows
```

### SYNC — Cloud sync (optional)

**Overview:** Bidirectional sync of `clubs`, `shots`, `round_scores`, `golf_rounds`, `range_drills` (and future custom drills / swing-diary rows / map cache metadata) with Firestore database `my-golf-diary` under `users/{uid}/...` and Firebase Storage for shared course map caches. The same path serves the phone and the web PWA (IndexedDB). **Today** Anonymous Auth supplies `uid`, and the AppBar action on every tab is `SyncCloudButton` (`Key('sync-cloud-button')`, cloud icon) which runs `syncFull` immediately. **Future** `SYNC-005`–`SYNC-010` replace that slot with an avatar menu so a Google or email/password account can own the diary across devices. Local SQLite remains the source while offline.

**SYNC-001 — Firebase optional at launch**  
As **any user**, I want **app to run without Firebase** so **local always works**.  
**AC:** (1) Init failure doesn’t crash app. (2) `CloudSyncService.isAvailable` reflects Firebase or an injected remote. (3) README configure path stays valid. (4) No server secrets in repo. Public client config may live in `firebase_options.dart`.

**SYNC-002 — Manual sync**  
As **Rory**, I want **sync from any tab** when online.  
**AC:** (1) If unavailable → snackbar “local only”. (2) If available → `syncFull` reports pulled and pushed counts. (3) Successful pushes are marked synced. A failed write stays dirty. (4) No infinite dup push in the normal path.

**SYNC-003 — Anonymous identity**  
As **product**, each install syncs as its Firebase anonymous user.  
**AC:** (1) `SyncIdentity.ensureSignedIn()` is the user id. (2) Path stays `users/{uid}/...` on database `my-golf-diary`. (3) Durable Google and email/password accounts are future `SYNC-006` and `SYNC-008`; until they ship, each install keeps its own anonymous uid. (4) Old `users/local_user` data is not migrated automatically.

**SYNC-004 — Pull and last-write-wins**  
As **Rory**, I want **another browser or phone to pick up my diary**.  
**AC:** (1) Pull applies a remote row only when its `updatedAtMs` is newer. (2) A remote tombstone removes the local row. (3) Deleting a club uploads a tombstone before the local row disappears. (4) PWA and mobile share this behavior.

**SYNC-005 — Account avatar menu (Future Feature)**  
As **Rory**, I want **one avatar where the sync icon sits** so I can **sign in, sync, open my profile, or open settings** without a fifth tab.  
**Placement:** The control replaces `SyncCloudButton` in the `AppBar.actions` slot already used on My Bag, On Course, Scorecard, and Range. One icon only. The cloud icon does not remain beside it.  
**AC:** (1) Signed out, the control is `Key('account-avatar-button')` with a generic account icon and tooltip “Account”. Signed in, the same key shows the Google photo or initials from display name, then email. (2) Tap opens a menu with exactly four entries: Login `Key('account-menu-login')`, Sync `Key('account-menu-sync')`, Profile `Key('account-menu-profile')`, Settings `Key('account-menu-settings')`. (3) Signed out, Login opens the sign-in sheet (`SYNC-006`); Sync does not call `syncFull` and explains that sign-in is required to save to Firestore; Profile and Settings still open, and Profile offers sign-in rather than account details. Signed in, Login reads “Sign out” and signs out without deleting SQLite; Sync runs the same manual sync as `SYNC-002`. (4) Opening the menu never starts GPS, never blocks shot capture, and dismisses on outside tap. Sync result stays the existing snackbar (`pulled` / `pushed` / `failed`).

**SYNC-006 — Google and email/password sign-in (Future Feature)**  
As **Riley**, I want **to sign in with Google or email and password** so **my diary has an account I can open again**.  
**AC:** (1) The Login sheet offers Google (`Key('account-login-google')`) and email/password (`Key('account-login-email')`, `Key('account-login-password')`, `Key('account-login-submit')`) with a create-account / sign-in toggle and “Forgot password” for email. (2) Google uses Firebase Auth on Android, iOS, and the web PWA and lands on the same `users/{uid}` for that Google account. Email/password create and sign-in use Firebase Auth; wrong password, weak password, invalid email, and email-already-in-use show an inline error and leave local data unchanged. (3) An email/password account must verify email before the first cloud push. Until verified, play stays local and Sync explains why. Google accounts are treated as verified. (4) The app still launches and records bag, course, scorecard, and range with no account and when Firebase init fails (`SYNC-001`). Passwords are never written to SQLite, logs, or the repo. (5) A successful sign-in persists across relaunch until Sign out.

**SYNC-007 — Retrieve the diary on another device (Future Feature)**  
As **Blake**, I want **a second phone or the PWA signed into the same account** to **download and upload my diary**.  
**AC:** (1) After sign-in, Sync pulls then pushes `clubs`, `shots`, `round_scores`, `golf_rounds`, `range_drills`, and `practice_drills` (plus future swing-diary rows) under `users/{uid}/...` on database `my-golf-diary`, using `SYNC-004` last-write-wins. (2) Device B, signed into the same Google or email account, shows rows Device A successfully pushed, including tombstones. (3) The snackbar includes how many local rows were replaced because the remote `updatedAtMs` was newer. There is no per-row merge screen. (4) Sign-out keeps the on-device SQLite copy and stops further cloud reads and writes for that account. The next sync requires sign-in. A reinstall plus the same account recovers the cloud copy only.

**SYNC-008 — Keep this device’s diary when the account changes (Future Feature)**  
As **Rory**, I want **the rounds already on this phone to follow me** when I **create a durable account**.  
**AC:** (1) If this install is anonymous and has local diary rows, Google or email sign-in links that anonymous user (`linkWithCredential` / equivalent) so existing `users/{uid}` docs stay put. (2) If link fails because that Google or email account already exists, the sheet offers two explicit actions. “Upload this device, then download the account” pushes local rows into the signed-in uid, then pulls with last-write-wins. “Replace this device with the account” pulls that account and does not push this device’s rows; on-device-only rows are removed only after that second confirm. Neither copy is discarded silently. (3) Legacy `users/local_user` cloud docs are still not migrated. Local rows that never synced follow the same choice. (4) Cancel returns to the anonymous or signed-out state the device had before the attempt.

**SYNC-009 — Profile (Future Feature)**  
As **Riley**, I want **a profile** so I can **see who is signed in and leave the account**.  
**AC:** (1) Profile, opened from the avatar menu, shows display name, email, Google photo or initials, and provider (Google or email). It does not edit clubs, rounds, or drills. (2) Signed out, the same screen explains that the diary is on this device only and offers the sign-in sheet. (3) Sign out (`Key('account-profile-sign-out')`) confirms, clears the Firebase session, returns the avatar to the generic icon, and leaves SQLite in place. (4) Delete account is a second, separate confirm. It deletes the Firebase Auth user and cloud docs under that `users/{uid}` only. Local SQLite remains unless the player also confirms “Erase diary on this device”.

**SYNC-010 — Settings (Future Feature)**  
As **Blake**, I want **settings beside sync** so I can **see whether the cloud has my latest diary**.  
**AC:** (1) Settings, opened from the avatar menu, shows Firebase availability, signed-in email or “Not signed in”, last successful sync time, and the count of local rows with `is_synced = 0`. (2) “Sync now” is the same action as the menu’s Sync item, including the signed-out explanation. (3) Email accounts get “Change password” and “Send verification email” here; Google accounts do not show password fields. (4) This screen does not add a units toggle, handicap, or social controls. Yards stay the stored unit until a separate decision changes that.

---

## 4. User Journey Map

1. Open app → sees **bottom tabs** (Bag / On Course / Scorecard / Range).  
2. **Pre-round** → My Bag: category + yardages + notes.  
3. **Tee** → On Course: pick course (autocomplete sets hole pars), view live GPS **distance to hole** (when course coordinates exist), record shots with GPS at natural breaks, or toggle to the cached **hole map view** (future) to inspect stroke coordinates.  
4. **Adjust** → penalties / mulligans / concede on HUD; **Finish Hole** advances with the course card's next par.  
5. **Verify** → Scorecard: totals; tap hole to fix strokes or par.  
6. **Range — Select Drill** → tap the left header icon on Range to open the **Practice Drills** list ([`Range_Drills.md`](./Range_Drills.md)), read the step-by-step explainer (or add/delete custom drills), and apply a drill to the session.  
7. **Range — Log Block** → pick club, count swings, enter min/max/avg and tempo notes, save.  
8. **Range — Swing Diary (Future)** → ask for an evaluation of today’s drills against earlier practice, continue the thread, and later reread saved evaluations and periodic summaries.  
9. **Account & backup** → today, the cloud icon on any tab runs anonymous sync when Firebase is configured. Future: that same slot is an avatar (`SYNC-005`) with Login, Sync, Profile, and Settings. After Google or email sign-in, Sync writes the diary to that account and another device on the same account retrieves it (`SYNC-006`, `SYNC-007`).  
10. **Next round** → new round from scorecard or implied active round behavior.

---

## 5. Non-Functional Requirements

| Area | Requirement |
| :--- | :--- |
| **Performance** | Tabs and shot save feel responsive; GPS read shows busy state (target: feedback ≤ ~2s typical). Cached course maps load from local disk without blocking shot capture. |
| **Security / privacy** | No keys in source; on-device SQLite; Firestore and Firebase Storage rules before production sync. Swing-diary calls use Vertex AI billed to the project. Players do not supply a Gemini key. Future accounts (`SYNC-006`) use Firebase Auth only: passwords never sit in SQLite or logs, email/password accounts verify before the first cloud push, and rules stay `request.auth.uid == userId`. |
| **Accessibility** | Primary taps ≥48dp where feasible; theme contrast; respect OS font scale on core screens. |
| **Offline** | Bag, fairway, scorecard, range, and seeded/custom drill catalog fully usable offline; distance-to-hole works offline via device GPS + bundled coordinates; cached course maps render offline once synced from Firebase Storage; AI assessment requires connectivity. Sign-in and sync need a network. A persisted session still records offline and syncs on the next successful Sync. |
| **Location** | Request when recording or showing live hole distance; handle denied/deniedForever; automatically hide distance-to-hole on unmapped courses or Simulator mode. |
| **Battery** | Single position read per shot by default; live distance-to-hole uses a throttled/distance-filtered location stream (`distanceFilter` ≥ 2–5m) active only while On Course is visible on a mapped hole in Course mode. |

---

## 6. Out of Scope (Current v1 Baseline)

1. Official **handicap** / GHIN / competition compliance mode.  
2. **3D flyover animations** or full commercial CAD course modeling (hole map view is scoped to cached 2D Google Maps / satellite imagery + tee-to-pin and stroke coordinate overlays).  
3. **Social** / live leaderboards / multiplayer real-time sync.  
4. **Auto** launch-monitor **Bluetooth** hardware ingest (manual/sim entry v1).  
5. **Watch-first** capture.  
6. A separate non-Flutter web client. The Flutter PWA is in scope for sync.  
7. A **login wall**. Local play works with no account.  
8. **Social** profiles, public diaries, friend graphs, or more than one signed-in account at a time.  
9. **Sign in with Apple**, phone OTP, or providers other than Google and email/password, unless App Store review requires Apple (see §7).  
10. A **manual row-by-row merge** UI. Multi-device conflicts stay last-write-wins.

*(Note: **CRSE-006** cached course map view, **RNGE-004** Vertex AI swing diary, and **SYNC-005–SYNC-010** account avatar, Google and email/password sign-in, and multi-device retrieve are future features. Range logging and on-course capture do not depend on them.)*

---

## 7. Open Questions & Dependencies

| Question | Owner |
| :--- | :--- |
| Yards vs meters (global preference)? | Watson + Product |
| RNGE aggregates: overwrite vs blend vs history-only? | Watson |
| Source of truth if shot count ≠ scorecard strokes? | Watson (document in Architecture) |
| Google Maps Static/Tile API licensing & Firebase Storage bucket structure for per-course map caching (`CRSE-006`) | Watson |
| Where the saved evaluation and periodic-summary log appears in navigation (`RNGE-004`) | Jason + Eunice |
| What replaces project-billed Vertex AI if the diary reaches about 1,000 people | Jason + Watson |
| iOS **Info.plist** location strings | Watson |
| If iOS App Store review requires Sign in with Apple whenever Google sign-in is offered, add it before the iOS ship of `SYNC-006`. Product decision until then: Google and email/password only | Jason + Watson |
| Email-verification copy and how long an unverified account may keep playing local-only (`SYNC-006`) | Jason |
| Analytics for Brief KPIs | Jason + Watson |

**Dependencies:**
- Firebase project `novusinc-8df79`, Firestore database `my-golf-diary`, Anonymous Auth enabled, and `firestore.rules` deployed to that database. `initializeFirebase` in `main.dart`.
- Future `SYNC-006`: enable Google and Email/Password on that same project (no new Firebase project). Android needs the app’s SHA fingerprints; the PWA domain must be an authorized domain. Anonymous linking behavior is specified in `SYNC-008`.
- [`PH_Golf_Course_Hole_Coordinates.md`](./PH_Golf_Course_Hole_Coordinates.md) for `CRSE-005` live distance-to-hole and `CRSE-006` hole map bounds.
- [`Range_Drills.md`](./Range_Drills.md) for `RNGE-003` seeded practice drills.
- Future: a Firebase Storage bucket and a Google Maps key (`CRSE-006`). Vertex AI on `novusinc-8df79` for `RNGE-004`, with App Check. No separate Gemini API product and no player API key.

---

## 8. Success Metrics

| KPI (from Brief) | v1 / Roadmap measurement |
| :--- | :--- |
| Clubs with non-zero avg @ 30d | Future SQL/analytics or manual |
| Shots per 18-equivalent | Local query / research |
| Complete 18-hole rounds | `round_scores` completion stats |
| RNGE saves / user / month | `range_drills` counts + % of sessions using a structured drill (`RNGE-003`) |
| Swing diary use (future) | Share of range days that produce a saved evaluation, and whether players reopen the evaluation log (`RNGE-004`) |
| Diary recovered on a second device (future) | Among players who create a Google or email account, share who complete a successful Sync on a second install within 30 days. Count Firebase Auth users against distinct installs; no new analytics SDK in this story (`SYNC-007`) |

Interim: **5+ interviews** on “log at cart/bag” and “card matches round.”

---

## Document history

| Ver | Date | Summary |
| :--- | :--- | :--- |
| 1.0 | 2026-11-06 | From ProjectBrief v1.0 + code surfaces |
| 1.1 | 2026-11-07 | SYNC-004 pull/merge, anonymous uid, PWA in scope for sync |
| 1.2 | 2026-11-08 | Reference [`PH_Golf_Venues.md`](./PH_Golf_Venues.md) lookup table for CRSE, SCOR, and RNGE |
| 1.3 | 2026-11-09 | Add `CRSE-005` (live GPS distance to hole on mapped courses), `CRSE-006` (future On-Course hole map view with Google Maps + Firebase Storage cache), `RNGE-003` (Range header drill picker + custom add/delete + [`Range_Drills.md`](./Range_Drills.md)), and `RNGE-004` (future Google AI daily range assessment & RAG Golf Swing Diary chat) |
| 1.4 | 2026-11-09 | Align `RNGE-004` with Architecture 1.3: Vertex AI billed to the project under about 1,000 people, raw history until about 250,000 tokens, then a stored progress brief, and a readable log of evaluations and periodic summaries. No embeddings and no player API key in this phase |
| 1.5 | 2026-11-10 | Future account menu in the sync slot: `SYNC-005` avatar with Login, Sync, Profile, and Settings; `SYNC-006` Google and email/password; `SYNC-007` same diary on another device; `SYNC-008` link or explicit upload when leaving anonymous auth; `SYNC-009` profile; `SYNC-010` sync settings. Local play stays signed-out. Not in the current build |
