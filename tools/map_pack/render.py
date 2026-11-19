"""Stylised, flat-colour hole rendering (no imagery; OSM vectors only)."""

from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont
from shapely.geometry import LineString, MultiPolygon, Point, Polygon, box
from shapely.ops import unary_union

from geo import Feature, YARDS_PER_M
from hole_frame import HEIGHT_PX, WIDTH_PX, HoleFrame, corridor
from markers import Marker

SS = 2  # supersampling factor

PALETTE = {
    "outside": (138, 150, 118),
    "course": (104, 146, 86),
    "rough": (104, 146, 86),
    "wood": (63, 104, 58),
    "water": (79, 143, 201),
    "water_hazard": (79, 143, 201),
    "fairway": (150, 198, 106),
    "tee": (168, 212, 122),
    "green": (186, 224, 140),
    "bunker": (239, 224, 181),
}
OUTLINE = {
    "water": (154, 196, 232),
    "water_hazard": (154, 196, 232),
    "green": (232, 245, 208),
    "bunker": (214, 192, 140),
    "tee": (214, 236, 184),
}
DRAW_ORDER = ("course", "rough", "wood", "water", "water_hazard", "fairway", "tee", "green", "bunker")
ATTRIBUTION = "© OpenStreetMap contributors (ODbL)"

SYNTH_FAIRWAY_HALF_M = 16.0
SYNTH_GREEN_R_M = 14.0
SYNTH_TEE_HALF_M = (6.0, 9.0)


def _font(size: int):
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _px(frame: HoleFrame, u: float, v: float) -> tuple[float, float]:
    x, y = frame.uv_to_px(u, v)
    return (x * SS, y * SS)


def _polys(g):
    if g is None or g.is_empty:
        return []
    if isinstance(g, Polygon):
        return [g]
    if isinstance(g, MultiPolygon):
        return list(g.geoms)
    if hasattr(g, "geoms"):
        return [p for sub in g.geoms for p in _polys(sub)]
    return []


def _fill(draw, frame, g, fill, outline=None, width=0):
    for poly in _polys(g):
        pts = [_px(frame, u, v) for u, v in poly.exterior.coords]
        if len(pts) >= 3:
            draw.polygon(pts, fill=fill, outline=outline, width=width * SS if outline else 0)


def collect_layers(frame: HoleFrame, feats: list[Feature]):
    view = box(
        frame.u_c - WIDTH_PX * frame.mpp / 2 - 20, frame.v_c - HEIGHT_PX * frame.mpp / 2 - 20,
        frame.u_c + WIDTH_PX * frame.mpp / 2 + 20, frame.v_c + HEIGHT_PX * frame.mpp / 2 + 20,
    )
    layers: dict[str, list] = {k: [] for k in DRAW_ORDER}
    for f in feats:
        if f.kind not in layers:
            continue
        g = frame.geometry_uv(f)
        if g is None or not g.intersects(view):
            continue
        clipped = g.intersection(view)
        if not clipped.is_empty and clipped.geom_type != "LineString":
            layers[f.kind].append(clipped)
    return {k: unary_union(v) if v else None for k, v in layers.items()}


def synthesise(frame: HoleFrame, layers: dict) -> list[str]:
    """Fill missing core features for this hole; returns what was generated."""
    generated = []
    tee, green = frame.tee_uv(), frame.green_uv()
    par = frame.hole.effective_par
    near_green = green.buffer(40)
    near_tee = tee.buffer(30)
    if layers["green"] is None or not layers["green"].intersects(near_green):
        layers["green"] = unary_union([g for g in (layers["green"], green.buffer(SYNTH_GREEN_R_M)) if g])
        generated.append("green")
    if layers["tee"] is None or not layers["tee"].intersects(near_tee):
        hw, hl = SYNTH_TEE_HALF_M
        tee_box = Polygon([(tee.x - hw, tee.y - hl), (tee.x + hw, tee.y - hl),
                           (tee.x + hw, tee.y + hl), (tee.x - hw, tee.y + hl)])
        layers["tee"] = unary_union([g for g in (layers["tee"], tee_box) if g])
        generated.append("tee")
    if par >= 4:
        mid_corridor = corridor(frame, frame.length_m * 0.45, frame.length_m * 0.75, 20)
        if layers["fairway"] is None or not layers["fairway"].intersects(mid_corridor):
            start = min(150 / YARDS_PER_M, frame.length_m * 0.4)
            fw = corridor(frame, start, max(start + 10, frame.length_m - 25), SYNTH_FAIRWAY_HALF_M)
            layers["fairway"] = unary_union([g for g in (layers["fairway"], fw) if g])
            generated.append("fairway")
    return generated


def render_hole(frame: HoleFrame, layers: dict) -> Image.Image:
    img = Image.new("RGB", (WIDTH_PX * SS, HEIGHT_PX * SS), PALETTE["outside"])
    draw = ImageDraw.Draw(img)
    for kind in DRAW_ORDER:
        g = layers.get(kind)
        if g is not None:
            _fill(draw, frame, g, PALETTE[kind], OUTLINE.get(kind), 2 if kind in OUTLINE else 0)
    line = [_px(frame, u, v) for u, v in frame.centreline.coords]
    _dashed(draw, line, fill=(255, 255, 255), width=2 * SS, dash=14 * SS, gap=10 * SS)
    return img.resize((WIDTH_PX, HEIGHT_PX), Image.LANCZOS)


def _dashed(draw, pts, fill, width, dash, gap):
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        seg = LineString([(x1, y1), (x2, y2)])
        d = 0.0
        while d < seg.length:
            a = seg.interpolate(d)
            b = seg.interpolate(min(seg.length, d + dash))
            draw.line([(a.x, a.y), (b.x, b.y)], fill=fill, width=width)
            d += dash + gap


def render_preview(base: Image.Image, frame: HoleFrame, markers: list[Marker], meta: dict) -> Image.Image:
    """Review image: base map plus tee/green/markers and labels (not shipped)."""
    img = base.copy().convert("RGBA")
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    f_small, f_big = _font(22), _font(30)

    def pt(u, v):
        return frame.uv_to_px(u, v)

    tee, green = frame.tee_uv(), frame.green_uv()
    tx, ty = pt(tee.x, tee.y)
    d.polygon([(tx, ty - 16), (tx - 14, ty + 10), (tx + 14, ty + 10)], fill=(255, 255, 255, 255),
              outline=(30, 30, 30, 255))
    gx, gy = pt(green.x, green.y)
    d.ellipse([gx - 9, gy - 9, gx + 9, gy + 9], fill=(220, 40, 40, 255), outline=(255, 255, 255, 255), width=3)
    for m in markers:
        mx, my = pt(m.u, m.v)
        color = (255, 196, 0, 255) if m.kind == "target" else (0, 200, 255, 255)
        d.rectangle([mx - 10, my - 10, mx + 10, my + 10], fill=color, outline=(20, 20, 20, 255), width=3)
        left = round(Point(m.u, m.v).distance(green) * YARDS_PER_M)
        d.text((mx + 16, my - 14), f"{m.kind} · {left}y", font=f_small, fill=(255, 255, 255, 255),
               stroke_width=3, stroke_fill=(0, 0, 0, 255))

    d.rectangle([0, 0, WIDTH_PX, 120], fill=(0, 0, 0, 140))
    d.text((20, 14), f"Hole {frame.hole.number} · Par {frame.hole.par or frame.hole.effective_par}{'' if frame.hole.par_source == 'catalog' else '*'} · {frame.length_yds} yds",
           font=f_big, fill=(255, 255, 255, 255))
    d.text((20, 58), f"OSM: {meta['coverage']}  ·  line: {frame.centreline_source}", font=f_small,
           fill=(230, 230, 230, 255))
    notes = []
    if meta["generated"]:
        notes.append("generated: " + ", ".join(meta["generated"]))
    if frame.hole.par_warning:
        notes.append(f"par check: markers use par {frame.hole.effective_par}")
    if notes:
        d.text((20, 86), " · ".join(notes), font=f_small, fill=(255, 210, 120, 255))
    d.rectangle([0, HEIGHT_PX - 40, WIDTH_PX, HEIGHT_PX], fill=(0, 0, 0, 140))
    d.text((20, HEIGHT_PX - 34), ATTRIBUTION, font=f_small, fill=(255, 255, 255, 255))
    return Image.alpha_composite(img, overlay).convert("RGB")


def contact_sheet(previews: list[Image.Image], title: str, cols: int = 6) -> Image.Image:
    tw, th = 240, 427
    rows = (len(previews) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw, rows * th + 60), (24, 28, 24))
    d = ImageDraw.Draw(sheet)
    d.text((16, 14), title, font=_font(28), fill=(255, 255, 255))
    for i, p in enumerate(previews):
        sheet.paste(p.resize((tw, th), Image.LANCZOS), ((i % cols) * tw, 60 + (i // cols) * th))
    return sheet
