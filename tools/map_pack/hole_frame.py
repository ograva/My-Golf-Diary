"""Per-hole normalisation: a rotated, portrait frame with the tee at the bottom.

Image pixel (px, py) <-> hole axes (u, v) <-> local metres (x, y) <-> WGS84.
`v` runs from tee to green, `u` is to the golfer's right.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from shapely import affinity
from shapely.geometry import LineString, Point
from shapely.ops import substring

from courses import Hole
from geo import Feature, LocalFrame, YARDS_PER_M, feature_geometry

WIDTH_PX = 720
HEIGHT_PX = 1280
MARGIN_BEHIND_TEE_M = 30.0
MARGIN_BEYOND_GREEN_M = 45.0
MIN_LATERAL_HALF_M = 55.0
HOLE_LINE_MATCH_M = 40.0


@dataclass
class HoleFrame:
    hole: Hole
    local: LocalFrame          # origin at the tee-green midpoint
    ux: float                  # unit vector tee->green in local metres
    uy: float
    length_m: float            # along the centreline
    centreline: LineString     # in hole axes (u, v), tee at v<0
    centreline_source: str     # "osm" or "straight"
    u_c: float                 # frame centre in hole axes
    v_c: float
    mpp: float                 # metres per pixel

    # --- transforms -------------------------------------------------------
    def to_uv(self, x: float, y: float) -> tuple[float, float]:
        return (x * self.uy - y * self.ux, x * self.ux + y * self.uy)

    def uv_to_xy(self, u: float, v: float) -> tuple[float, float]:
        return (u * self.uy + v * self.ux, -u * self.ux + v * self.uy)

    def uv_to_px(self, u: float, v: float) -> tuple[float, float]:
        return (
            WIDTH_PX / 2 + (u - self.u_c) / self.mpp,
            HEIGHT_PX / 2 - (v - self.v_c) / self.mpp,
        )

    def px_to_latlon(self, px: float, py: float) -> tuple[float, float]:
        u = (px - WIDTH_PX / 2) * self.mpp + self.u_c
        v = (HEIGHT_PX / 2 - py) * self.mpp + self.v_c
        return self.local.to_latlon(*self.uv_to_xy(u, v))

    def latlon_to_uv(self, lat: float, lon: float) -> tuple[float, float]:
        return self.to_uv(*self.local.to_xy(lat, lon))

    def uv_to_latlon(self, u: float, v: float) -> tuple[float, float]:
        return self.local.to_latlon(*self.uv_to_xy(u, v))

    def geometry_uv(self, f: Feature):
        g = feature_geometry(f, self.local)
        if g is None:
            return None
        # Rotation of local (x, y) into (u, v) as a shapely affine matrix.
        return affinity.affine_transform(g, [self.uy, -self.ux, self.ux, self.uy, 0, 0])

    @property
    def bearing_deg(self) -> float:
        """Compass bearing of tee->green (0 = north, clockwise)."""
        return (math.degrees(math.atan2(self.ux, self.uy)) + 360) % 360

    @property
    def length_yds(self) -> int:
        return round(self.length_m * YARDS_PER_M)

    def corners(self) -> dict[str, dict[str, float]]:
        out = {}
        for name, (px, py) in {
            "topLeft": (0, 0),
            "topRight": (WIDTH_PX, 0),
            "bottomLeft": (0, HEIGHT_PX),
            "bottomRight": (WIDTH_PX, HEIGHT_PX),
        }.items():
            lat, lon = self.px_to_latlon(px, py)
            out[name] = {"lat": round(lat, 7), "lon": round(lon, 7)}
        return out

    def tee_uv(self) -> Point:
        return Point(self.centreline.coords[0])

    def green_uv(self) -> Point:
        return Point(self.centreline.coords[-1])


def _match_hole_line(hole: Hole, frame: "HoleFrame", feats: list[Feature]) -> LineString | None:
    tee = Point(frame.latlon_to_uv(hole.tee_lat, hole.tee_lon))
    green = Point(frame.latlon_to_uv(hole.green_lat, hole.green_lon))
    best, best_err = None, None
    for f in feats:
        if f.kind != "hole":
            continue
        ref = f.tags.get("ref")
        g = frame.geometry_uv(f)
        if not isinstance(g, LineString):
            continue
        a, b = Point(g.coords[0]), Point(g.coords[-1])
        err_fwd = a.distance(tee) + b.distance(green)
        err_rev = b.distance(tee) + a.distance(green)
        err = min(err_fwd, err_rev)
        if err > 2 * HOLE_LINE_MATCH_M:
            continue
        if ref and ref.isdigit() and int(ref) != hole.number:
            err += 25  # prefer the line tagged with this hole number
        if best_err is None or err < best_err:
            best, best_err = (g if err_fwd <= err_rev else LineString(g.coords[::-1])), err
    if best is None:
        return None
    # Snap the ends onto the surveyed tee and green; the survey is authoritative.
    coords = list(best.coords)
    coords[0], coords[-1] = tee.coords[0], green.coords[0]
    return LineString(coords)


def build_frame(hole: Hole, feats: list[Feature]) -> HoleFrame:
    local = LocalFrame((hole.tee_lat + hole.green_lat) / 2, (hole.tee_lon + hole.green_lon) / 2)
    tx, ty = local.to_xy(hole.tee_lat, hole.tee_lon)
    gx, gy = local.to_xy(hole.green_lat, hole.green_lon)
    d = math.hypot(gx - tx, gy - ty) or 1.0
    frame = HoleFrame(
        hole=hole, local=local, ux=(gx - tx) / d, uy=(gy - ty) / d,
        length_m=d, centreline=LineString(), centreline_source="straight",
        u_c=0.0, v_c=0.0, mpp=1.0,
    )
    tee_uv = frame.to_uv(tx, ty)
    green_uv = frame.to_uv(gx, gy)
    line = _match_hole_line(hole, frame, feats)
    if line is not None:
        frame.centreline, frame.centreline_source = line, "osm"
    else:
        frame.centreline = LineString([tee_uv, green_uv])
    frame.length_m = frame.centreline.length

    us = [c[0] for c in frame.centreline.coords]
    v_lo = tee_uv[1] - MARGIN_BEHIND_TEE_M
    v_hi = green_uv[1] + MARGIN_BEYOND_GREEN_M
    half_u = max(MIN_LATERAL_HALF_M, max(abs(u) for u in us) + 40.0)
    span_v = v_hi - v_lo
    span_u_needed = 2 * half_u
    aspect = WIDTH_PX / HEIGHT_PX
    if span_u_needed > span_v * aspect:
        extra = span_u_needed / aspect - span_v
        v_lo -= extra * 0.4
        v_hi += extra * 0.6
        span_v = v_hi - v_lo
    frame.u_c = (min(us) + max(us)) / 2
    frame.v_c = (v_lo + v_hi) / 2
    frame.mpp = span_v / HEIGHT_PX
    return frame


def along(frame: HoleFrame, s: float) -> tuple[Point, tuple[float, float]]:
    """Point at distance s along the centreline and the unit normal to its right."""
    s = max(0.0, min(frame.centreline.length, s))
    p = frame.centreline.interpolate(s)
    a = frame.centreline.interpolate(max(0.0, s - 3))
    b = frame.centreline.interpolate(min(frame.centreline.length, s + 3))
    dx, dy = b.x - a.x, b.y - a.y
    n = math.hypot(dx, dy) or 1.0
    return p, (dy / n, -dx / n)


def corridor(frame: HoleFrame, start_m: float, end_m: float, half_width: float):
    seg = substring(frame.centreline, start_m, end_m)
    return seg.buffer(half_width, cap_style=1)
