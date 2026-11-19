"""OSM element parsing and a local metric frame per hole."""

from __future__ import annotations

import math
from dataclasses import dataclass

from shapely.geometry import LineString, Point, Polygon
from shapely.ops import unary_union
from shapely.validation import make_valid

EARTH_R = 6_371_008.8
YARDS_PER_M = 1.09361

# OSM tag -> pipeline feature kind. Order matters only for readability.
KINDS = (
    "fairway",
    "green",
    "tee",
    "bunker",
    "water_hazard",
    "hole",
    "water",
    "wood",
    "rough",
    "course",
)


def classify(tags: dict) -> str | None:
    golf = tags.get("golf")
    if golf in ("fairway", "green", "tee", "bunker", "hole", "rough"):
        return golf
    if golf in ("water_hazard", "lateral_water_hazard"):
        return "water_hazard"
    if tags.get("natural") == "water":
        return "water"
    if tags.get("natural") == "wood" or tags.get("landuse") == "forest":
        return "wood"
    if tags.get("leisure") == "golf_course":
        return "course"
    return None


@dataclass
class Feature:
    kind: str
    osm_id: str
    tags: dict
    rings: list[list[tuple[float, float]]]  # (lat, lon) rings or a single line


def parse_elements(data: dict) -> list[Feature]:
    feats: list[Feature] = []
    for el in data.get("elements", []):
        kind = classify(el.get("tags", {}))
        if kind is None:
            continue
        rings: list[list[tuple[float, float]]] = []
        if el["type"] == "way" and "geometry" in el:
            rings.append([(p["lat"], p["lon"]) for p in el["geometry"]])
        elif el["type"] == "relation":
            for m in el.get("members", []):
                if m.get("role") in ("outer", "") and "geometry" in m:
                    rings.append([(p["lat"], p["lon"]) for p in m["geometry"]])
        if rings:
            feats.append(Feature(kind, f"{el['type']}/{el['id']}", el.get("tags", {}), rings))
    return feats


class LocalFrame:
    """Equirectangular metres around an origin; accurate to <0.1% over a hole."""

    def __init__(self, lat0: float, lon0: float):
        self.lat0 = lat0
        self.lon0 = lon0
        self.kx = math.cos(math.radians(lat0)) * math.pi / 180 * EARTH_R
        self.ky = math.pi / 180 * EARTH_R

    def to_xy(self, lat: float, lon: float) -> tuple[float, float]:
        return ((lon - self.lon0) * self.kx, (lat - self.lat0) * self.ky)

    def to_latlon(self, x: float, y: float) -> tuple[float, float]:
        return (self.lat0 + y / self.ky, self.lon0 + x / self.kx)


def feature_geometry(f: Feature, frame: LocalFrame):
    """Polygon (areas) or LineString (hole centrelines, unclosed ways)."""
    parts = []
    for ring in f.rings:
        pts = [frame.to_xy(lat, lon) for lat, lon in ring]
        closed = len(pts) >= 4 and pts[0] == pts[-1]
        if f.kind == "hole" or not closed:
            if len(pts) >= 2:
                parts.append(LineString(pts))
        else:
            parts.append(make_valid(Polygon(pts)))
    if not parts:
        return None
    return parts[0] if len(parts) == 1 else unary_union(parts)


def distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = p2 - p1
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * EARTH_R * math.asin(math.sqrt(a))


def point(frame: LocalFrame, lat: float, lon: float) -> Point:
    return Point(frame.to_xy(lat, lon))
