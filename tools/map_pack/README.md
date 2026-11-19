# Map pack pipeline (CRSE-041)

Builds stylised, licence-safe hole maps for On Course from **OpenStreetMap** golf features. No Google or other satellite imagery is used. Output goes to `out/` and is **not uploaded** by these scripts; upload follows the contract in [`docs/shards/CRSE/CRSE-041-map-pack-pipeline.md`](../../docs/shards/CRSE/CRSE-041-map-pack-pipeline.md).

This is a standalone tool and is not part of the Flutter app.

## Setup

```bash
cd tools/map_pack
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
```

## Commands

```bash
python courses.py                      # list courses, courseIds and hole counts
python coverage.py                     # OSM coverage table (markdown); --json for rows
python build_pack.py ph-crse-villamor --preview-dir /tmp/previews
python build_pack.py ph-crse-villamor ph-crse-cebu-cc --version 2
```

`build_pack.py` writes `out/<courseId>/manifest.json`, `out/<courseId>/hole_<n>.png`, and `out/index.json`. With `--preview-dir`, it also writes annotated review images (one per hole, plus a contact sheet). The previews are for review only and are not part of the pack.

## Upload (owner, admin credentials)

```bash
pip install -r requirements-upload.txt
python validate_pack.py ph-crse-villamor              # exit 1 on contract errors
python upload_packs.py --all --dry-run
python upload_packs.py --all
python verify_read.py                                # signed-in read OK, anonymous read refused
```

`upload_packs.py` validates every pack, uploads images, then each `manifest.json`, then `course_maps/index.json` last (merged with the versions already in the bucket). The target is the app's default bucket `novusinc-8df79.appspot.com` (the one `FirebaseStorage.instance` reads). It needs a service account with Storage Object Admin on the bucket, as a key file in `GOOGLE_APPLICATION_CREDENTIALS` or as the key JSON in `FIREBASE_SERVICE_ACCOUNT_JSON`.

Bucket access lives at the repo root: `storage.rules` (authenticated read of `course_maps/**`, no client writes) is deployed with `firebase deploy --only storage --project novusinc-8df79`, and `storage.cors.json` (GET only, PWA origins) is applied with `gcloud storage buckets update gs://novusinc-8df79.appspot.com --cors-file=storage.cors.json`. GCS matches CORS origins exactly, so run Flutter web locally with `--web-port 8080`.

## Pipeline

1. **Fetch:** one Overpass query per course bbox (surveyed holes padded by 250 m) for `golf=*`, `natural=water`, `natural=wood`, `landuse=forest`, and `leisure=golf_course`. Responses are cached in `.cache/`, and the client falls back across public mirrors with backoff.
2. **Normalise per hole:** the surveyed tee and green from `golf_diary_app/lib/data/ph_golf_hole_coords.dart` are authoritative. The OSM `golf=hole` line is used as the centreline when its ends fall within 40 m of the surveyed tee and green; otherwise the centreline is straight. The frame is rotated so that the tee is at the bottom and the green at the top, at 720×1280 px.
3. **Render:** flat colours, no imagery. Missing core features (green, tee, or a par-4/5 fairway) are generated and listed in `generated`.
4. **Markers:** for par 4 and 5, candidates are sampled on a forward arc from the ball inside the carry band (tee 190–240 yds; second shot 150–200 yds). They are scored by distance left, distance from the centreline, hazard-buffer penalties (water 15 m, bunker 8 m, wood 5 m), and a fairway bonus. Par 4s get a `target`; par 5s get a `target` and a `layup` (aiming to leave about 100 yds).
5. **Manifest:** a per-hole frame (`centerLat/Lon`, `bearingDeg`, `metersPerPixel`), image `corners`, a `bbox` for older clients, tee and green, `coverage` (`osm` | `partial` | `generated`), and `markers[]`.

Course and par data come from the app's Dart sources, so the pipeline matches what the app ships. A catalog par that cannot fit the surveyed tee-to-green length (for example a par 5 at 190 yds) is reported in `parWarning`, and the markers use the length-based par (`markerPar`). `courseId` is the established `ph-crse-*` ID from `docs/context/PH_Golf_Venues.md`, or `ph-crse-<name-slug>` when a course has none.

## Licence

Data: © OpenStreetMap contributors, ODbL 1.0. Every rendered map must show "© OpenStreetMap contributors". Missing features should be fixed **in OpenStreetMap** by tracing Bing or Esri imagery in an OSM editor, **never Google**, and then re-running this tool.
