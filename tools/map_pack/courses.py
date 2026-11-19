"""Course catalog for the map-pack pipeline.

Reads the app's surveyed tee/green coordinates and hole pars straight from the
Dart sources so the pipeline never drifts from what the app ships, and maps each
canonical course name to its pack `courseId`.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
COORDS_DART = REPO_ROOT / "golf_diary_app/lib/data/ph_golf_hole_coords.dart"
CATALOG_DART = REPO_ROOT / "golf_diary_app/lib/data/ph_golf_catalog.dart"
VENUES_MD = REPO_ROOT / "docs/context/PH_Golf_Venues.md"

# Straight tee-to-green yards a par can plausibly have (generous; doglegs make
# the straight line shorter than the played length).
PAR_LENGTH_YDS = {3: (60, 290), 4: (220, 520), 5: (380, 700), 6: (520, 900)}


@dataclass(frozen=True)
class Hole:
    number: int
    tee_lat: float
    tee_lon: float
    green_lat: float
    green_lon: float
    par: int | None

    @property
    def straight_yds(self) -> float:
        from geo import YARDS_PER_M, distance_m

        return distance_m(self.tee_lat, self.tee_lon, self.green_lat, self.green_lon) * YARDS_PER_M

    @property
    def length_par(self) -> int:
        yds = self.straight_yds
        return 3 if yds < 250 else 4 if yds < 470 else 5

    @property
    def par_warning(self) -> str | None:
        """Catalog par that cannot fit the surveyed length (likely a data error)."""
        if not self.par:
            return None
        lo, hi = PAR_LENGTH_YDS[self.par]
        yds = self.straight_yds
        if lo <= yds <= hi:
            return None
        return f"catalog par {self.par} does not fit {round(yds)} yds tee-to-green"

    @property
    def effective_par(self) -> int:
        """Par used for markers and synthesis: catalog par unless it contradicts
        the surveyed length, then an estimate from the length."""
        if self.par and self.par_warning is None:
            return self.par
        return self.length_par

    @property
    def par_source(self) -> str:
        if not self.par:
            return "estimated"
        return "catalog" if self.par_warning is None else "length"


@dataclass
class Course:
    name: str
    course_id: str
    id_source: str  # "venues" (established ph-crse-*) or "name"
    holes: list[Hole] = field(default_factory=list)

    def bbox(self, pad_m: float = 250.0) -> tuple[float, float, float, float]:
        lats = [h.tee_lat for h in self.holes] + [h.green_lat for h in self.holes]
        lons = [h.tee_lon for h in self.holes] + [h.green_lon for h in self.holes]
        dlat = pad_m / 111_320.0
        dlon = pad_m / 107_000.0  # ~cos(15°) at PH latitudes
        return (min(lats) - dlat, min(lons) - dlon, max(lats) + dlat, max(lons) + dlon)


def _unescape(dart_string: str) -> str:
    return json.loads(f'"{dart_string}"')


def name_slug(name: str) -> str:
    """Same rule as `courseMapPackIdFromName` in course_map_cache_service.dart."""
    return re.sub(r"^-+|-+$", "", re.sub(r"[^a-z0-9]+", "-", name.lower()))


def name_based_id(name: str) -> str:
    return f"ph-crse-{name_slug(name)}"


def _venue_ids() -> dict[str, str]:
    """Canonical name -> established `ph-crse-*` id from PH_Golf_Venues.md tables."""
    ids: dict[str, str] = {}
    for line in VENUES_MD.read_text(encoding="utf-8").splitlines():
        m = re.match(r"\|\s*`(ph-crse-[a-z0-9-]+)`\s*\|\s*([^|]+?)\s*\|", line)
        if m:
            ids.setdefault(m.group(2), m.group(1))
    return ids


def _hole_pars() -> dict[str, list[int]]:
    src = CATALOG_DART.read_text(encoding="utf-8")
    pars: dict[str, list[int]] = {}
    for m in re.finditer(
        r"name:\s*'([^']+)'.*?holePars:\s*\[([0-9,\s]+)\]", src, flags=re.S
    ):
        block_name = m.group(1)
        # Guard against a regex match spanning into the next course entry.
        if "PhGolfCourse(" in src[m.start() : m.end()]:
            continue
        pars[block_name] = [int(x) for x in m.group(2).replace(" ", "").split(",") if x]
    return pars


def load_courses() -> list[Course]:
    src = COORDS_DART.read_text(encoding="utf-8")
    venue_ids = _venue_ids()
    pars = _hole_pars()
    courses: list[Course] = []
    course_re = re.compile(r'^  "(.+?)": \{(.*?)^  \},', re.M | re.S)
    hole_re = re.compile(
        r"(\d+): HoleCoordinates\(\s*teeLat: ([\d.-]+),\s*teeLon: ([\d.-]+),"
        r"\s*greenLat: ([\d.-]+),\s*greenLon: ([\d.-]+)\)"
    )
    for cm in course_re.finditer(src):
        name = _unescape(cm.group(1))
        established = venue_ids.get(name)
        course = Course(
            name=name,
            course_id=established or name_based_id(name),
            id_source="venues" if established else "name",
        )
        course_pars = pars.get(name)
        for hm in hole_re.finditer(cm.group(2)):
            n = int(hm.group(1))
            course.holes.append(
                Hole(
                    number=n,
                    tee_lat=float(hm.group(2)),
                    tee_lon=float(hm.group(3)),
                    green_lat=float(hm.group(4)),
                    green_lon=float(hm.group(5)),
                    par=course_pars[n - 1] if course_pars and n <= len(course_pars) else None,
                )
            )
        courses.append(course)
    return courses


def find_course(key: str) -> Course:
    for c in load_courses():
        if key in (c.course_id, c.name, name_slug(c.name)):
            return c
    raise SystemExit(f"Unknown course: {key}")


if __name__ == "__main__":
    for c in load_courses():
        print(f"{c.course_id:45} {c.id_source:7} holes={len(c.holes):2} {c.name}")
