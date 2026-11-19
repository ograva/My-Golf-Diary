"""Build a stylised map pack for one course from OpenStreetMap golf features.

    python build_pack.py ph-crse-villamor
    python build_pack.py ph-crse-villamor --version 2 --preview-dir /tmp/previews

Pipeline: Overpass fetch -> per-hole normalise (surveyed tee/green, tee at the
bottom) -> stylised PNG -> markers -> manifest.json. Output goes to
out/<courseId>/ and is never uploaded by this script.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from courses import Course, find_course
from geo import YARDS_PER_M, parse_elements
from hole_frame import HEIGHT_PX, WIDTH_PX, build_frame
from markers import compute_markers
from overpass import golf_features_query, run
from render import ATTRIBUTION, collect_layers, contact_sheet, render_hole, render_preview, synthesise

OUT_DIR = Path(__file__).resolve().parent / "out"
SCHEMA = 1


def _coverage_label(layers: dict, generated: list[str]) -> str:
    osm_core = [k for k in ("green", "fairway", "tee") if layers.get(k) is not None and k not in generated]
    if not generated:
        return "osm"
    return "partial" if osm_core else "generated"


def build(course: Course, version: int, preview_dir: Path | None) -> dict:
    data = run(golf_features_query(course.bbox()))
    feats = parse_elements(data)
    out = OUT_DIR / course.course_id
    out.mkdir(parents=True, exist_ok=True)
    holes, previews = [], []

    for hole in sorted(course.holes, key=lambda h: h.number):
        frame = build_frame(hole, feats)
        layers = collect_layers(frame, feats)
        generated = synthesise(frame, layers)
        coverage = _coverage_label(layers, generated)
        image = render_hole(frame, layers)
        image_path = f"hole_{hole.number}.png"
        image.save(out / image_path, optimize=True)

        markers = compute_markers(frame, feats, course.course_id)
        corners = frame.corners()
        lats = [c["lat"] for c in corners.values()]
        lons = [c["lon"] for c in corners.values()]
        holes.append({
            "holeNumber": hole.number,
            "par": hole.par or hole.effective_par,
            "parSource": hole.par_source,
            "markerPar": hole.effective_par,
            "parWarning": hole.par_warning,
            "lengthYds": frame.length_yds,
            "imagePath": image_path,
            "widthPx": WIDTH_PX,
            "heightPx": HEIGHT_PX,
            "frame": {
                "centerLat": round(frame.uv_to_latlon(frame.u_c, frame.v_c)[0], 7),
                "centerLon": round(frame.uv_to_latlon(frame.u_c, frame.v_c)[1], 7),
                "bearingDeg": round(frame.bearing_deg, 3),
                "metersPerPixel": round(frame.mpp, 5),
            },
            "corners": corners,
            "bbox": {"swLat": min(lats), "swLon": min(lons), "neLat": max(lats), "neLon": max(lons)},
            "tee": {"lat": hole.tee_lat, "lon": hole.tee_lon},
            "green": {"lat": hole.green_lat, "lon": hole.green_lon},
            "centerlineSource": frame.centreline_source,
            "coverage": coverage,
            "generated": generated,
            "markers": [
                {
                    "id": m.id,
                    "kind": m.kind,
                    "lat": round(frame.uv_to_latlon(m.u, m.v)[0], 6),
                    "lon": round(frame.uv_to_latlon(m.u, m.v)[1], 6),
                    "reason": m.reason,
                }
                for m in markers
            ],
        })
        if preview_dir is not None:
            previews.append(render_preview(image, frame, markers, {"coverage": coverage, "generated": generated}))

    manifest = {
        "schema": SCHEMA,
        "courseId": course.course_id,
        "courseName": course.name,
        "version": version,
        "source": "openstreetmap",
        "attribution": ATTRIBUTION,
        "license": "ODbL-1.0 (data); rendered images are a Produced Work",
        "holes": holes,
    }
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False))

    if preview_dir is not None:
        preview_dir.mkdir(parents=True, exist_ok=True)
        for p, h in zip(previews, holes):
            p.save(preview_dir / f"{course.course_id}-hole-{h['holeNumber']:02d}.png", optimize=True)
        summary = {k: sum(1 for h in holes if h["coverage"] == k) for k in ("osm", "partial", "generated")}
        title = (f"{course.name} ({course.course_id}) · OSM holes {summary['osm']}, "
                 f"partial {summary['partial']}, generated {summary['generated']}")
        contact_sheet(previews, title).save(preview_dir / f"{course.course_id}-contact-sheet.png", optimize=True)
    return manifest


def write_index(entries: dict[str, int]) -> None:
    index_path = OUT_DIR / "index.json"
    current = json.loads(index_path.read_text()) if index_path.exists() else {"schema": SCHEMA, "courses": []}
    by_id = {c["courseId"]: c["version"] for c in current["courses"]}
    by_id.update(entries)
    current["courses"] = [{"courseId": k, "version": v} for k, v in sorted(by_id.items())]
    index_path.write_text(json.dumps(current, indent=2))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("courses", nargs="+", help="courseId, slug or canonical name")
    ap.add_argument("--version", type=int, default=1)
    ap.add_argument("--preview-dir", type=Path)
    args = ap.parse_args()
    built = {}
    for key in args.courses:
        course = find_course(key)
        m = build(course, args.version, args.preview_dir)
        built[course.course_id] = m["version"]
        cov = [h["coverage"] for h in m["holes"]]
        n_markers = sum(len(h["markers"]) for h in m["holes"])
        print(f"{course.course_id}: {len(cov)} holes · osm {cov.count('osm')} · partial "
              f"{cov.count('partial')} · generated {cov.count('generated')} · markers {n_markers} "
              f"· avg {sum(h['lengthYds'] for h in m['holes']) / len(cov):.0f} yds")
    write_index(built)
