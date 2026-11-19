"""Small Overpass client with mirror fallback, backoff and an on-disk cache."""

from __future__ import annotations

import hashlib
import json
import time
from pathlib import Path

import requests

CACHE_DIR = Path(__file__).resolve().parent / ".cache"
USER_AGENT = "MyGolfDiary-map-pack/0.1 (+https://github.com/ograva/My-Golf-Diary)"
ENDPOINTS = [
    "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]


def golf_features_query(bbox: tuple[float, float, float, float]) -> str:
    s, w, n, e = bbox
    b = f"{s:.6f},{w:.6f},{n:.6f},{e:.6f}"
    return f"""[out:json][timeout:90];
(
  way["golf"]({b});
  relation["golf"]({b});
  way["natural"="water"]({b});
  relation["natural"="water"]({b});
  way["natural"="wood"]({b});
  way["landuse"="forest"]({b});
  way["leisure"="golf_course"]({b});
  relation["leisure"="golf_course"]({b});
);
out geom;"""


def run(query: str, *, use_cache: bool = True, attempts: int = 4) -> dict:
    CACHE_DIR.mkdir(exist_ok=True)
    key = hashlib.sha1(query.encode()).hexdigest()[:16]
    cached = CACHE_DIR / f"{key}.json"
    if use_cache and cached.exists():
        return json.loads(cached.read_text())

    last_error: Exception | None = None
    for attempt in range(attempts):
        for url in ENDPOINTS:
            try:
                resp = requests.post(
                    url,
                    data={"data": query},
                    headers={"User-Agent": USER_AGENT, "Accept": "application/json"},
                    timeout=180,
                )
                if resp.status_code == 200 and resp.text.lstrip().startswith("{"):
                    data = resp.json()
                    cached.write_text(json.dumps(data))
                    return data
                last_error = RuntimeError(f"{url}: HTTP {resp.status_code}")
            except requests.RequestException as exc:
                last_error = exc
        time.sleep(4 * 2**attempt)
    raise RuntimeError(f"Overpass failed after {attempts} rounds: {last_error}")
