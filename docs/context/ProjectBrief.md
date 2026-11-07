# Project Brief — My Golf Diary

| Field | Value |
| :--- | :--- |
| **Product** | My Golf Diary |
| **Owner** | Mary (Strategic Analyst cohort) |
| **Status** | Active |
| **App** | Flutter — [`golf_diary_app/`](../../golf_diary_app/) |

## Version History

| Version | Date | Author | Summary of Changes |
| :--- | :--- | :--- | :--- |
| 0.1 | — | — | Stub created. |
| 1.0 | 2025-11-06 | Mary (`/brief`) | Full brief from product intent + alignment with current app build. |

---

## 1. Executive Summary

**My Golf Diary** is a **local-first** mobile app for golfers who want **credible yardages** and an **honest round record** without wrestling the phone at the wrong time. It combines a **club log** (min / max / avg and swing notes), a **GPS fairway shot tracker**, a **scorecard** (penalties, mulligans, concede/gimme), and a **range drill** flow so practice updates the same club picture used on the course.

The shipping app is **Flutter** with a **four-tab bottom nav**—**My Bag**, **On Course**, **Scorecard**, **Range**—so golfers **switch mode by activity**, not by hunting through menus. **Firestore sync** is optional; offline use remains the default story.

---

## 2. Problem Statement

Golfers mix **memory**, paper, and apps that do not connect **bag distances**, **shot history**, and **scoring**. That costs **confidence** at address and **time** reconstructing the round later. The best time to **log a shot** is usually **between swings** (walking to the cart or bag); if capture is slow or buried in navigation, logging stops and data rots.

On the range, players often hit a **block** (e.g. ten balls) then want **min / max / avg**—sometimes from a sim. Without a dedicated path, those numbers do not flow into the **same club record** used on the course, so distances drift and trust erodes.

---

## 3. Target Audience & Personas

- **Rounds-first Rory** — Wants GPS shot lines per hole and a scorecard that matches real play; logs when **stopped** (cart/bag). Success = full round without feeling rushed.

- **Range-first Riley** — Cares about **drill blocks**, min/max/avg, and **tempo notes**. Success = one save updates the **shared club profile** with the bag screen.

- **Bag-first Blake** — Wants **category-organized clubs**, distance bands, and swing reminders; may not log every shot but needs **baseline yardages** before the round.

---

## 4. Strategic Goals & Success Metrics

| Goal | Metric | Baseline / target (6 months) |
| :--- | :--- | :--- |
| Trusted bag data | % non-putter clubs with non-zero avg after month one | Baseline 0; target ≥70% for active users |
| On-course capture | Median shots logged per 18-hole-equivalent session | Establish in v1; trend up quarter over quarter |
| Scorecard completeness | % rounds with 18 holes scored or conceded | Baseline TBD; target ≥60% of “complete” rounds |
| Range → bag | Drill saves per active user per month | Baseline TBD; target ≥2 for engaged practice users |

*Early builds: interviews and manual counts until analytics exist.*

---

## 5. High-Level Feature Areas

| Area | Description |
| :--- | :--- |
| **My Bag** | Clubs by **category** with **min / max / avg** and **swing notes**. Matches **`clubs_screen.dart`** / `Club`. |
| **On Course** | Fairway **HUD**: round, **hole/par**, **lie**, club, **GPS shot capture**, penalty / mulligan / concede. Matches **`fairway_tracker_screen.dart`**, `ShotRecord`, DB services. |
| **Scorecard** | 18-hole grid, **edit** par/strokes/penalties/mulligans/concede, totals vs par. Matches **`scorecard_screen.dart`**, **`scorecard_hole_editor`**. |
| **Range** | Drill flow: club, **shot count** (default ten), **min/max/avg**, notes, save. Matches **`range_drill_screen.dart`**, `RangeDrillLog`. |
| **Data & sync** | **SQLite** local; optional **Firestore** from sync path. Matches **`local_database_service`**, **`cloud_sync_service`**. |
| **Navigation** | Four **bottom tabs** = mode by context—aligns with **`HomeShell`** in **`main.dart`**. |

---

## 6. Scope Definition

### In Scope (v1)

- Club distance log with filters, min/max/avg, swing notes (implemented).
- Fairway tracking with GPS, stroke context, club, lie, distance, notes (implemented; UX can tighten “natural moments” at cart/bag).
- Scorekeeping with penalties, mulligans, concede, vs-par totals (implemented).
- Range drill: block of swings, aggregate distances, notes (implemented).
- Local-first use; Android location permissions documented; iOS when configured.
- Optional Firestore sync where wired.

### Out of Scope (v1)

- Full **course GIS** / flyover maps beyond shot capture needs.
- **Social**, **official handicap authority**, or strict competition-compliance mode.
- **Wearable-first** or watch-primary UX.
- **Automatic** launch-monitor Bluetooth ingest (manual/sim entry only for now).
- **Live multiplayer** score sync.

---

## 7. Technical Constraints & Stack Alignment

**Flutter (Dart ≥3.0)** in **`golf_diary_app/`**: **sqflite**, **geolocator**, **provider** as needed, optional **Firebase**/**Cloud Firestore**, **Material 3** theme in **`app_theme.dart`**.

**Stack rules and non-negotiables** are authoritative in **[Architecture.md](./Architecture.md) § Constraints & non-negotiables** (this repo has no separate `CONSTRAINTS.md`). Tab labels here match the UI: **My Bag**, **On Course**, **Scorecard**, **Range**.

---

## 8. Risks & Open Questions

| Risk | L | I | Mitigation |
| :--- | :-: | :-: | :--- |
| GPS accuracy / battery | M | H | Weak-signal UX; document expectations in Architecture |
| Logging cadence at cart/bag | M | M | Keep **On Course** as hub; minimize taps; validate in usability tests |
| Fairway totals vs manual scorecard | M | M | PRD defines source of truth; Architecture documents rules |
| Sync & privacy | L | H | Default anonymous/local user until auth; rules TBD |

**Open (for PRD):** yards vs meters; iOS location copy; whether drill stats **replace** or **blend** club aggregates; presentation of **mulligans** vs “official” score.

---

## 9. Timeline & Milestones

| Phase | Deliverables |
| :--- | :--- |
| **MVP** | Four-tab app fully usable offline; GPS path clear; README Firebase steps |
| **Hardening** | **`PRD.md`** from this brief; expanded **`Architecture.md`**; Eunice wireframes for fastest on-course path; Quinn on critical tests |
| **Growth** | Auth, analytics, sim import—after v1 habit is proven |
