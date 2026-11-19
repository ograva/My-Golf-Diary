"""Report OSM golf-feature coverage for every surveyed course.

    python coverage.py            # markdown table to stdout
    python coverage.py --json     # machine-readable rows
"""

from __future__ import annotations

import argparse
import json
from collections import Counter

from courses import Course, load_courses
from geo import LocalFrame, feature_geometry, parse_elements, point
from overpass import golf_features_query, run

GREEN_MATCH_M = 40.0
HOLE_LINE_MATCH_M = 40.0
FAIRWAY_MATCH_M = 25.0


def hole_matches(course: Course, feats) -> dict:
    frame = LocalFrame(course.holes[0].tee_lat, course.holes[0].tee_lon)
    geoms = {k: [] for k in ("green", "fairway", "hole")}
    for f in feats:
        if f.kind in geoms:
            g = feature_geometry(f, frame)
            if g is not None:
                geoms[f.kind].append(g)
    greens = fairways = lines = 0
    for h in course.holes:
        tee = point(frame, h.tee_lat, h.tee_lon)
        green = point(frame, h.green_lat, h.green_lon)
        if any(g.distance(green) <= GREEN_MATCH_M for g in geoms["green"]):
            greens += 1
        if any(
            g.distance(tee) <= HOLE_LINE_MATCH_M and g.distance(green) <= HOLE_LINE_MATCH_M
            for g in geoms["hole"]
        ):
            lines += 1
        mid = point(frame, (h.tee_lat + h.green_lat) / 2, (h.tee_lon + h.green_lon) / 2)
        if h.effective_par >= 4 and any(g.distance(mid) <= FAIRWAY_MATCH_M for g in geoms["fairway"]):
            fairways += 1
    par45 = sum(1 for h in course.holes if h.effective_par >= 4)
    return {"greens": greens, "fairways": fairways, "par45": par45, "lines": lines}


def grade(row: dict) -> str:
    n = row["holes"]
    g, fw, ln = row["greens"] / n, row["fairways"] / max(row["par45"], 1), row["lines"] / n
    if g >= 0.8 and fw >= 0.6:
        return "Good"
    if g >= 0.4 or ln >= 0.5:
        return "Partial"
    return "Sparse"


def coverage_rows() -> list[dict]:
    rows = []
    for course in load_courses():
        data = run(golf_features_query(course.bbox()))
        feats = parse_elements(data)
        counts = Counter(f.kind for f in feats)
        row = {
            "course": course.name,
            "courseId": course.course_id,
            "idSource": course.id_source,
            "holes": len(course.holes),
            **{k: counts.get(k, 0) for k in
               ("fairway", "green", "tee", "bunker", "water_hazard", "hole", "water", "wood")},
            **hole_matches(course, feats),
        }
        row["grade"] = grade(row)
        rows.append(row)
    return rows


def to_markdown(rows: list[dict]) -> str:
    head = (
        "| Course | courseId | Fairway | Green | Tee | Bunker | Water hazard | Hole line"
        " | Water | Wood | Greens matched | Fairways matched | Hole lines matched | Grade |\n"
        "| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: | :---: | :---: | :--- |"
    )
    lines = [head]
    for r in rows:
        lines.append(
            f"| {r['course']} | `{r['courseId']}` | {r['fairway']} | {r['green']} | {r['tee']}"
            f" | {r['bunker']} | {r['water_hazard']} | {r['hole']} | {r['water']} | {r['wood']}"
            f" | {r['greens']}/{r['holes']} | {r['fairways']}/{r['par45']} | {r['lines']}/{r['holes']}"
            f" | {r['grade']} |"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    rows = coverage_rows()
    print(json.dumps(rows, indent=2) if args.json else to_markdown(rows))
