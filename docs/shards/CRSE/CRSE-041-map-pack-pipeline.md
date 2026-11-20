# SHARD-CRSE-041: Map pack pipeline (OSM → stylised hole maps)

| Field | Value |
| :--- | :--- |
| **Shard ID** | CRSE-041 |
| **Module** | CRSE — On Course |
| **Story Ref** | CRSE-006, CRSE-009, CRSE-041 |
| **Priority** | Medium |
| **Status** | In Progress (spike landed: `tools/map_pack/`) |
| **Complexity** | M |
| **Depends On** | CRSE-020 (surveyed tee/green coordinates) |
| **Feeds** | CRSE-022 (narrowed: app-side fetch, cache, version), CRSE-037 (projection), CRSE-039 (aim markers) |

## Description

Produce the hole map packs that the full-screen Fairway map shows, without Google or other licensed satellite imagery. A standalone Python tool in `tools/map_pack/` (outside the Flutter app) fetches OpenStreetMap golf features through Overpass and normalises each hole to the surveyed tee and green. It renders a stylised flat-colour PNG with the **tee at the bottom**, computes suggested aim **markers**, and writes `manifest.json` and `index.json` following the upload contract below. Uploading to Firebase Storage is done by the project owner and is not part of the tool.

**Why not Google imagery:** Google Maps Platform terms forbid storing or caching imagery for later use and forbid creating derivative works from it. Posterising, tracing, or "cleaning" a Static Maps or Earth image is still a derivative of that image. OSM data is ODbL, and our renders are a Produced Work that needs only attribution.

## Acceptance Criteria

- [x] `python courses.py` lists every course in `ph_golf_hole_coords.dart` with its `courseId` (established `ph-crse-*` from `PH_Golf_Venues.md`, else `ph-crse-<name-slug>`), hole count, and par.
- [x] `python coverage.py` prints per-course OSM counts (fairway, green, tee, bunker, water_hazard, hole, water, wood) and how many surveyed holes match an OSM green, fairway, and hole line, with a grade of Good, Partial, or Sparse.
- [x] `python build_pack.py <courseId> [--version N] [--preview-dir DIR]` writes `out/<courseId>/hole_<n>.png` (720×1280, tee at the bottom), `out/<courseId>/manifest.json`, and updates `out/index.json`. Previews are annotated and not part of the pack.
- [x] Catalog pars that contradict the surveyed length are flagged (`parWarning`), and markers use the length-based par.
- [x] Missing green, tee, or (par 4/5) fairway is generated, and the hole lists it in `generated` with `coverage` = `partial` or `generated`.
- [x] Markers: par 4 → one `target`; par 5 → `target` plus `layup`; par 3 → none. Each has `id`, `kind`, `lat`, `lon`, and `reason`.
- [x] `python validate_pack.py <courseId>` checks a pack against the contract (exit code 1 on failure).
- [x] Spike: run on one well-mapped and one sparse course, with previews reviewed.
- [ ] Owner uploads the first pilot packs following the contract; the CRSE-022 client reads them on device and on the PWA.
- [ ] Missing OSM features on pilot courses are traced **in OpenStreetMap** (Bing or Esri imagery only), and the packs are rebuilt.

## Upload contract (owner's upload; read-only for the app)

### Paths (default Firebase Storage bucket)

```
course_maps/index.json
course_maps/{courseId}/manifest.json
course_maps/{courseId}/hole_{n}.png        # or .webp; name must match imagePath
```

Upload exactly what `build_pack.py` writes under `out/`. Upload images first, then `manifest.json`, then `index.json` last, so a client never sees a version whose files are missing.

### `courseId`

The established ID from `docs/context/PH_Golf_Venues.md` when one exists (all 17 surveyed courses have one, for example `ph-crse-villamor`). Otherwise `ph-crse-` + the course name lower-cased, with non-alphanumeric runs turned into `-`. The app must map the canonical course name to this ID; it no longer uses the bare name slug.

### `index.json`

```json
{ "schema": 1, "courses": [ { "courseId": "ph-crse-villamor", "version": 2 } ] }
```

The app fetches this once per online session and re-downloads a pack when the remote `version` is higher than the local one. Bump `version` (`--version N`) on **any** change to images, markers, or the manifest.

### `manifest.json`

| Field | Type | Notes |
| :--- | :--- | :--- |
| `schema` | int | `1` |
| `courseId`, `courseName` | string | `courseId` must equal the folder name |
| `version` | int | Matches `index.json` |
| `source` | string | `openstreetmap` |
| `attribution` | string | Shown on the map whenever a pack image is visible: `© OpenStreetMap contributors (ODbL)` |
| `license` | string | Informational |
| `holes[]` | array | One entry per surveyed hole |
| `holes[].holeNumber`, `par`, `lengthYds` | int | `lengthYds` along the centreline |
| `holes[].parSource` | string | `catalog`, `estimated` (no catalog par), or `length` (catalog par contradicts the surveyed length) |
| `holes[].markerPar` | int | Par the markers were computed for |
| `holes[].parWarning` | string \| null | Set when the catalog par contradicts the surveyed length; the app keeps scoring with `par` |
| `holes[].imagePath`, `widthPx`, `heightPx` | | 720×1280 portrait; **pre-rotated, tee at the bottom** |
| `holes[].frame` | object | `centerLat`, `centerLon` (image centre), `bearingDeg` (compass bearing of tee→green, which is "up" in the image), `metersPerPixel` |
| `holes[].corners` | object | `topLeft`, `topRight`, `bottomLeft`, `bottomRight` → `{lat, lon}`: the exact image corners |
| `holes[].bbox` | object | Axis-aligned bounds of the corners, for older clients only; **do not use it to project a rotated image** |
| `holes[].tee`, `holes[].green` | `{lat, lon}` | Surveyed points (same as the app catalog) |
| `holes[].centerlineSource` | string | `osm` or `straight` |
| `holes[].coverage` | string | `osm`, `partial`, or `generated` |
| `holes[].generated` | string[] | Any of `green`, `tee`, `fairway` drawn without OSM data |
| `holes[].markers[]` | array | `{id, kind: "target"\|"layup", lat, lon, reason}`; empty for par 3 |

**Projection for the app (CRSE-037):** for a point at local metres east/north of `frame.center`, rotate by `bearingDeg` so that tee→green points up, then divide by `metersPerPixel` and offset from the image centre. `corners` lets the app check its maths. The app never rotates pack images; it only rotates its own vector and stand-in drawings.

### Storage access (owner)

- Rules: `match /course_maps/{path=**} { allow read: if request.auth != null; allow write: if false; }`. Uploads use admin credentials (`gsutil` or the console), never the app.
- Bucket CORS for the PWA origins (GitHub Pages and `http://localhost:*`), `GET` only.
- No API keys for any map provider are needed or allowed.

## Marker algorithm

1. **Band:** tee shot 190–240 yds from the tee, capped to leave at least 50 yds. Par-5 second shot: 150–200 yds from the first marker.
2. **Candidates:** a forward arc of ±35° around the ball-to-green direction, in 4 m radial steps and 2° angular steps. A candidate is kept only within 30 m of the centreline or inside a fairway polygon.
3. **Score (lower is better):** yards left to the green (tee target), or |yards left − 100| for the par-5 layup; plus 1 point per metre from the centreline; plus hazard penalties inside buffers (water and water hazards 15 m → +400, bunkers 8 m → +150, wood 5 m → +80); minus 60 inside a fairway.
4. **Output:** the best candidate per shot, with a `reason` (for example "214 yds carry, leaves 166 yds, in fairway, 23 yds clear of hazards"). Holes with no fairway or hazard data say so in `reason`.

## Dev notes

- Inputs come from the app's Dart sources (`ph_golf_hole_coords.dart`, `ph_golf_catalog.dart`) and `PH_Golf_Venues.md`, so packs match what the app ships.
- Overpass: the public mirrors are rate-limited. The client caches responses in `.cache/` and falls back across mirrors with backoff, at one query per course.
- ODbL: rendered PNGs are a Produced Work (attribution required). The manifest's marker coordinates are derived from OSM data; if the manifests are published, offer them under ODbL.
- Fix gaps upstream in OSM (Bing or Esri tracing only), then rebuild. Never trace Google.
- See the Agent Store plan `docs/fwy-map-layout-plan.md` (revision 5) for the full FWY design.
