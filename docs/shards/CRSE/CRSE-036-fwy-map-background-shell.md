# SHARD-CRSE-036: FWY map-background shell

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-036 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-006, CRSE-007, CRSE-009 |
| **Priority** | High |
| **Status** | Ready for Review |
| **Complexity** | L |
| **Depends On** | CRSE-035, CRSE-041 (pack contract), CRSE-022 (cache service, #67) |
| **Design** | Agent Store `docs/fwy-map-layout-plan.md` rev 5 (user-approved), §2 |

## Description

In **FWY only**, the hole map becomes the screen: a full-bleed background with the **tee at the bottom**, text overlays on a top scrim, a Club / Lie / Aim / Pen / Mul **rail** (right by default, switchable), and **Record shot at ball** as the only dock button. Concede and Finish move to the header overflow (two taps), the hole sheet footer, and a **double-par prompt** that never finishes the hole by itself. Holes without a survey show a generated **stand-in hole**. SIM keeps the CRSE-035 layout unchanged.

This shard also lands the shell parts of CRSE-037 (tee-bottom projection and inverse, pack framing from manifest `frame`), CRSE-038 (Live/Manual setting with the stale-pin gate), CRSE-039 (aim ring and marker snap with derived L/C/R) and CRSE-040 (stand-in from par). The data-model halves of those shards are deferred (see below).

## Acceptance Criteria

- [x] **Background** `oncourse-map-background` fills the body under the AppBar. Mapped hole with a pack: the CRSE-041 PNG drawn from manifest `frame` (centre, `bearingDeg`, `metersPerPixel`), never rotated by the app; `oncourse-map-pack-image` plus `oncourse-map-attribution` (manifest `attribution`, "© OpenStreetMap contributors (ODbL)"). Mapped hole without a pack: plain drawn hole rotated tee-bottom plus `oncourse-map-line-only-badge`. Pack loading shows `oncourse-map-download` under row 3.
- [x] **Framing** fits the tee→green corridor in the area not covered by the top rows, the rail column, both edge gutters, and the dock; re-fits when the rail switches sides.
- [x] **Top overlay** (`oncourse-top-overlay`, gradient scrim, white w600 text with shadow): row 1 `oncourse-course-summary` + `oncourse-mode-toggle`; row 2 `oncourse-course-meta` + `oncourse-gps-badge` (Live/Manual, tap opens `oncourse-gps-sheet`); row 3 `on-course-hole-previous` / `on-course-hole-label` / `on-course-hole-next`, `oncourse-par-summary`, yards (`on-course-distance-to-hole`, or `oncourse-standin-yards` "≈ n yds").
- [x] **Rail** `oncourse-side-rail`, 20dp inset, tiles up to 56dp (scale down to fit 360×640): `oncourse-club-summary`, `oncourse-lie-summary`, `oncourse-aim-summary`, `oncourse-rail-penalty`, `oncourse-rail-mulligan`, `oncourse-rail-side-toggle`. Side persists per device (also in the overflow). The 16dp diary swipe strip stays at the right screen edge, outside the rail.
- [x] **Pen / Mul** tiles open a − n + popover (`oncourse-penalty-step-down|up`, `oncourse-penalty-count`; same for mulligan), clamped at 0.
- [x] **Dock** `oncourse-record-shot-btn` "Record shot at ball" is the only button; `oncourse-shots-peek` "Shots this hole (n) ⌃" opens a draggable sheet (`oncourse-shots-sheet`, 50% → 90%) with Strokes · Pen · Score · Round header and `oncourse-shot-row-{n}` → `ShotEditDialog`.
- [x] **Concede / Finish (FWY)**: overflow `oncourse-overflow-concede` / `oncourse-overflow-finish`, and hole sheet footer `oncourse-hole-sheet-concede` / `oncourse-hole-sheet-finish`. No Concede / Finish buttons in the FWY dock.
- [x] **Double par**: strokes + penalties ≥ 2 × par shows `oncourse-double-par-banner` "Double par (n). Finish hole?" with `oncourse-double-par-finish` / `oncourse-double-par-keep`; Keep hides it for the hole and leaves `oncourse-double-par-finish-chip` beside the peek handle. Shown on mapped, pack, and stand-in holes; never auto-finishes; not in SIM.
- [x] **Live / Manual**: Live uses the CRSE-005 stream. Manual stops the stream; a map tap places `oncourse-manual-pin`; Record saves at the pin, then the pin goes stale and Record is disabled until it moves (tap the stale pin = same spot). Taps in the left 24dp and right 16dp gutters are ignored. Yards come from the pin. Mode persists per device. Location denied offers "Use Manual".
- [x] **Aim**: default target is the pin. `oncourse-aim-summary` toggles Aim mode (`oncourse-aim-mode-banner`, ✕ `oncourse-aim-mode-close`, long press resets). Ring radius = the club's typical yards (median of `getClubYardageTrend`, else bag average, else category default). Taps snap to the ring (`oncourse-aim-target`) or to a manifest marker `oncourse-map-marker-{id}` within 12dp; a marker within 15 yds of the ring is pre-selected; if the pin is inside the ring the target stays the pin (ring faint). Record saves the derived L/C/R in `aim_direction` and resets the target to the pin.
- [x] **Stand-in**: course or hole without coordinates draws a straight hole sized from par (165 / 380 / 510 yds) with `oncourse-standin-badge` "Sample hole · not this course's shape"; strokes placed by cumulative distance; Record uses GPS (Live).
- [x] `on-course-map-toggle`, the HUD card, and the `430` map sizing are removed from FWY. SIM layout and its CRSE-035 tests unchanged.

## Test coverage

- [x] `test/on_course_crse_036_test.dart`: projection maps the Villamor H1 pack corners and round-trips; viewport fit and inverse; ring snap and L/C/R; 390×844 layout (map full-bleed, top rows above the rail, 56dp tiles at right, Record only, gutter outside the rail); 360×640 rail fits above the dock; side toggle persists; pack image + attribution + marker clear of the rail; stand-in; Pen popover + double-par prompt (Keep → chip → Finish); Mul popover; overflow Concede/Finish + hole-sheet Finish; Manual pin gate (stale, gutter ignored, same spot, persists); SIM keeps its layout.
- [x] `test/on_course_crse_032_test.dart`: Aim mode ring tap → "Aim left" on the saved shot; SIM hides the rail.
- [x] Updated for the new shell: `fairway_tracker_screen_test.dart`, `on_course_hole_test.dart`, `on_course_crse_035_test.dart` (SIM-only tests now select SIM first; the old FWY map-pane test is replaced by CRSE-036 tests), `on_course_crse_033_test.dart` (attribution text).

## Deferred (follow-up shards)

- **CRSE-038 data:** `shots.position_source` column, migration, sync and caddy payload. Manual shots are stored with the pin's lat/lon today, indistinguishable from GPS.
- **CRSE-039 data:** `aim_target_lat/lon`, `aim_target_kind`, `aim_marker_id` columns, migration and sync; only the derived L/C/R is saved today.
- **CRSE-040:** Manual pin on stand-in holes (hole-relative `standin_x/y`, `distance_estimated`), "≈ you" dot after stroke 1, per-hole yardage entry `oncourse-hole-yards-field` (`round_scores.hole_yards`), excluding estimates from trends.
- **CRSE-037:** tappable stroke markers on the map, `corners` sanity check, WCAG/glare device check, "partly drawn" badge for `partial`/`generated` holes (open question 3).
- **CRSE-022:** the FWY loader (`HoleMapPackSource` → `CachedHoleMapPackSource`) delegates to `CourseMapCacheService`; the attribution string comes from the contract constant because `HoleMapFrame` does not carry the manifest's `attribution` yet. Version refresh against `index.json` and the SQLite `course_map_cache` table remain with CRSE-022.
- `OncourseMapPane` / `OncourseSatelliteHoleMap` / `OncourseVectorHoleMap` are no longer used by the screen (kept for their tests and the cache-service tests); remove or port to `FwyHoleMap` later.
- `Wireframe_OnCourse.md` / `Wireframe_HoleMap.md` and Architecture §5.5 doc rewrite (plan §4 step 1).

## Dev notes

- `lib/screens/fairway_tracker_screen.dart` — `build` branches: SIM keeps the CRSE-035 scroll view; FWY is `_fwyBody` (a `Stack`).
- `lib/widgets/fwy_hole_map.dart` — background, painter, keyed marker widgets, tap → hole-local metres.
- `lib/widgets/fwy_overlays.dart` — rail tile, map badge, counter popover.
- `lib/on_course/hole_projection.dart` — `HoleProjection` (lat/lon ↔ metres, tee→green up) and `HoleViewport` (fit, screen ↔ metres).
- `lib/on_course/fwy_aim.dart` — aim target, ring snap, L/C/R, typical club yards, `StandinHole`.
- `lib/services/hole_map_pack_source.dart` — thin interface over `CourseMapCacheService`; tests swap `HoleMapPackSource.instance`.
- `lib/services/on_course_settings.dart` — per-device rail side and GPS mode (`oncourse_device_settings` table, created on first use).
- `lib/models/course_map_manifest.dart` — additive `frame`, `markers`, `coverage`, `generated`, `lengthYds`, `attribution`.
- `PlayHeaderOverflowButton.extraActions` adds screen-specific overflow entries.
- Live Record uses the running position stream's latest fix when there is one (a one-shot `getCurrentPosition` can stall on web while `watchPosition` is active); otherwise a one-shot read with a 10 s limit.
