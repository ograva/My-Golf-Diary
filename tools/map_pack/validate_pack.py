"""Check out/<courseId>/ against the CRSE-041 upload contract before uploading.

    python validate_pack.py ph-crse-villamor
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image

from courses import find_course

OUT_DIR = Path(__file__).resolve().parent / "out"
MAX_IMAGE_BYTES = 600_000
MARKER_KINDS = {"target", "layup"}
COVERAGE = {"osm", "partial", "generated"}


def validate(course_id: str) -> list[str]:
    errors: list[str] = []
    course = find_course(course_id)
    pack = OUT_DIR / course.course_id
    manifest_path = pack / "manifest.json"
    if not manifest_path.exists():
        return [f"missing {manifest_path}"]
    m = json.loads(manifest_path.read_text())

    for key in ("schema", "courseId", "version", "attribution", "holes"):
        if key not in m:
            errors.append(f"manifest: missing '{key}'")
    if m.get("courseId") != course.course_id:
        errors.append(f"manifest: courseId {m.get('courseId')!r} != folder {course.course_id!r}")
    if not isinstance(m.get("version"), int) or m["version"] < 1:
        errors.append("manifest: version must be a positive integer")
    if "OpenStreetMap" not in m.get("attribution", ""):
        errors.append("manifest: attribution must credit OpenStreetMap contributors")

    surveyed = {h.number for h in course.holes}
    seen = set()
    for h in m.get("holes", []):
        n = h.get("holeNumber")
        seen.add(n)
        where = f"hole {n}"
        if n not in surveyed:
            errors.append(f"{where}: not a surveyed hole for this course")
        for key in ("par", "parSource", "markerPar", "imagePath", "widthPx", "heightPx", "frame", "corners", "bbox", "coverage", "markers"):
            if key not in h:
                errors.append(f"{where}: missing '{key}'")
        img = pack / h.get("imagePath", "")
        if not img.is_file():
            errors.append(f"{where}: image {img.name} missing")
        else:
            if img.stat().st_size > MAX_IMAGE_BYTES:
                errors.append(f"{where}: {img.name} is {img.stat().st_size} bytes (> {MAX_IMAGE_BYTES})")
            with Image.open(img) as im:
                if im.size != (h.get("widthPx"), h.get("heightPx")):
                    errors.append(f"{where}: image is {im.size}, manifest says {h.get('widthPx')}x{h.get('heightPx')}")
        if h.get("coverage") not in COVERAGE:
            errors.append(f"{where}: coverage must be one of {sorted(COVERAGE)}")
        ids = set()
        for mk in h.get("markers", []):
            if mk.get("kind") not in MARKER_KINDS:
                errors.append(f"{where}: marker kind {mk.get('kind')!r}")
            if mk.get("id") in ids:
                errors.append(f"{where}: duplicate marker id {mk.get('id')}")
            ids.add(mk.get("id"))
            for key in ("lat", "lon", "reason"):
                if key not in mk:
                    errors.append(f"{where}: marker missing '{key}'")
    missing = surveyed - seen
    if missing:
        errors.append(f"holes missing from manifest: {sorted(missing)}")

    index = OUT_DIR / "index.json"
    if not index.exists():
        errors.append("out/index.json missing")
    else:
        entries = {c["courseId"]: c["version"] for c in json.loads(index.read_text()).get("courses", [])}
        if entries.get(course.course_id) != m.get("version"):
            errors.append("index.json version does not match manifest version")
    return errors


if __name__ == "__main__":
    failed = False
    for key in sys.argv[1:]:
        errs = validate(key)
        print(f"{key}: {'OK' if not errs else 'FAIL'}")
        for e in errs:
            print(f"  - {e}")
        failed |= bool(errs)
    sys.exit(1 if failed else 0)
