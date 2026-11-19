# SHARD-CRSE-033: Map / satellite HUD & live markers

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-033 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-009 |
| **Priority** | Medium |
| **Status** | Completed |
| **Complexity** | L |
| **Depends On** | CRSE-034, CRSE-022 |

## Description

When a mapped hole is in **Course** mode and map assets are available, the HUD shows a map-first pane (`oncourse-hole-map`) with cached satellite imagery (Architecture §5.5), tee and green markers, one marker per recorded stroke, and a live player/ball marker driven by the CRSE-005 position stream (throttled). Tabular HUD and map share the same hole context, plan chips, and shot list. **Simulator** mode never mounts the map pane or `on-course-map-toggle`. Offline cache miss falls back per CRSE-034 / CRSE-022 vector rules.

## Acceptance Criteria

- [x] `on-course-map-toggle` and map pane follow the same gating as pin distance (`hasHoleCoordinates` + `!_simulator`); Simulator mode omits toggle, map surface, and live pin overlay entirely.
- [x] Map pane frames current hole bounds from pack `manifest.json` (or vector fallback); plots tee, green/pin, stroke markers from `ShotRecord` coords, and updates live player position from existing pin stream without starting a second high-accuracy stream.
- [x] Switching map ↔ tabular (`oncourse-hud-tabular`) preserves hole index, club/lie plan, and stroke list state without duplicate saves.
- [x] Google Maps attribution visible when satellite pack imagery is shown; no Maps SDK or runtime tile API in the Flutter client (Static → Storage → local image only).

## Test coverage

- [x] **Unit/widget:** Mapped hole + Course mode shows `oncourse-hole-map` or vector `oncourse-map-vector` when pack missing. Simulator selected removes map keys. Stroke insert refreshes marker count.
- [ ] **Integration (if needed):** Wi‑Fi download pack → airplane mode → map still renders (extends CRSE-022 scenario).
- [x] **Keys:** `on-course-map-toggle`, `oncourse-hole-map`, `oncourse-map-vector`, `oncourse-map-download`, `on-course-distance-to-hole` from [`Wireframe_HoleMap.md`](../../context/designs/Wireframe_HoleMap.md) and [`Wireframe_OnCourse.md`](../../context/designs/Wireframe_OnCourse.md).

## Dev notes

- Co-implement with [CRSE-022](./CRSE-022-hole-map-view.md): `CourseMapCacheService`, `firebase_storage` download, `CustomPainter` Mercator overlay.
- **MGDV-18:** Architecture documents Google Maps Static API for pack build only; no secrets in repo.
- Project live pin: `_pinSub`, `PinDistanceClient` / `GeolocatorPinDistanceClient` in `fairway_tracker_screen.dart` and `pin_distance.dart`.
- Fairway aim bearing overlay on map optional after CRSE-032 aim field exists.
- **Ship note (2026-11-19):** Client `CourseMapCacheService` + satellite/vector overlays shipped; Firebase pack builder and device integration test remain **CRSE-022**.