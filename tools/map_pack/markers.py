"""Suggested aim markers per hole.

Candidates are sampled on a forward arc from the ball inside a carry band,
scored by the distance they leave to the green, and penalised inside hazard
buffers. Par 4s get one `target`; par 5s get a `target` plus a `layup`.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from shapely.geometry import Point
from shapely.ops import unary_union

from geo import Feature, YARDS_PER_M
from hole_frame import HoleFrame

# Carry bands in yards from the shot's start point.
TEE_BAND_YDS = (190, 240)
SECOND_BAND_YDS = (150, 200)
MIN_LEFT_AFTER_TEE_YDS = 50
LAYUP_PREFERRED_LEFT_YDS = 100
STEP_M = 4.0
ARC_HALF_DEG = 35.0
ARC_STEP_DEG = 2.0
LATERAL_MAX_M = 30.0  # max distance from the hole centreline unless in fairway

# Hazard buffers (metres) and penalties (score points ≈ yards).
HAZARDS = {
    "water": (15.0, 400.0),
    "water_hazard": (15.0, 400.0),
    "bunker": (8.0, 150.0),
    "wood": (5.0, 80.0),
}
FAIRWAY_BONUS = 60.0
LATERAL_COST_PER_M = 1.0


@dataclass
class Marker:
    id: str
    kind: str          # "target" | "layup"
    u: float
    v: float
    reason: str


def _layers(frame: HoleFrame, feats: list[Feature]):
    raw: dict[str, list] = {k: [] for k in (*HAZARDS, "fairway")}
    for f in feats:
        if f.kind in raw:
            g = frame.geometry_uv(f)
            if g is not None and g.geom_type in ("Polygon", "MultiPolygon", "GeometryCollection"):
                raw[f.kind].append(g)
    hazards = {
        k: (unary_union(v), unary_union(v).buffer(HAZARDS[k][0])) for k, v in raw.items()
        if k in HAZARDS and v
    }
    fairway = unary_union(raw["fairway"]) if raw["fairway"] else None
    return hazards, fairway


def _best(frame, start: Point, band_yds, score_left, hazards, fairway):
    """Search a forward arc around `start` (handles doglegs better than offsets
    from a straight line) and keep candidates near the hole corridor."""
    green = frame.green_uv()
    line = frame.centreline
    heading = math.atan2(green.y - start.y, green.x - start.x)
    best = None
    r = band_yds[0] / YARDS_PER_M
    r_end = band_yds[1] / YARDS_PER_M
    while r <= r_end:
        a = -ARC_HALF_DEG
        while a <= ARC_HALF_DEG:
            t = heading + math.radians(a)
            c = Point(start.x + r * math.cos(t), start.y + r * math.sin(t))
            off_line = c.distance(line)
            in_fw = fairway is not None and fairway.contains(c)
            if off_line <= LATERAL_MAX_M or in_fw:
                left_yds = c.distance(green) * YARDS_PER_M
                score = score_left(left_yds) + LATERAL_COST_PER_M * off_line
                hits = []
                for kind, (_, buffered) in hazards.items():
                    if buffered.contains(c):
                        score += HAZARDS[kind][1]
                        hits.append(kind)
                if in_fw:
                    score -= FAIRWAY_BONUS
                if best is None or score < best[0]:
                    best = (score, c, left_yds, r * YARDS_PER_M, in_fw, hits)
            a += ARC_STEP_DEG
        r += STEP_M
    return best


def _reason(c: Point, left_yds: float, carry_yds: float, in_fw: bool, hits, hazards, fairway) -> str:
    parts = [f"{round(carry_yds)} yds carry", f"leaves {round(left_yds)} yds"]
    if fairway is None:
        parts.append("no fairway data")
    elif in_fw:
        parts.append("in fairway")
    else:
        parts.append("off fairway")
    if hits:
        parts.append("inside " + "/".join(sorted(set(hits))) + " buffer")
    elif hazards:
        clear = min(raw.distance(c) for raw, _ in hazards.values())
        parts.append(f"{round(clear * YARDS_PER_M)} yds clear of hazards")
    else:
        parts.append("no hazard data")
    return ", ".join(parts)


def compute_markers(frame: HoleFrame, feats: list[Feature], course_id: str) -> list[Marker]:
    par = frame.hole.effective_par
    if par <= 3:
        return []
    hazards, fairway = _layers(frame, feats)
    tee = frame.tee_uv()
    out: list[Marker] = []

    max_left_tee = frame.length_yds - MIN_LEFT_AFTER_TEE_YDS
    band = (min(TEE_BAND_YDS[0], max_left_tee - 30), min(TEE_BAND_YDS[1], max_left_tee))
    if band[1] <= band[0]:
        return []
    first = _best(frame, tee, band, lambda left: left, hazards, fairway)
    if first is None:
        return []
    _, c1, left1, carry1, fw1, hits1 = first
    out.append(Marker(
        id=f"{course_id}-h{frame.hole.number}-target",
        kind="target", u=c1.x, v=c1.y,
        reason=_reason(c1, left1, carry1, fw1, hits1, hazards, fairway),
    ))

    if par >= 5 and left1 > LAYUP_PREFERRED_LEFT_YDS + 40:
        second = _best(
            frame, c1, SECOND_BAND_YDS,
            lambda left: abs(left - LAYUP_PREFERRED_LEFT_YDS),
            hazards, fairway,
        )
        if second is not None:
            _, c2, left2, carry2, fw2, hits2 = second
            out.append(Marker(
                id=f"{course_id}-h{frame.hole.number}-layup",
                kind="layup", u=c2.x, v=c2.y,
                reason=_reason(c2, left2, carry2, fw2, hits2, hazards, fairway),
            ))
    return out
