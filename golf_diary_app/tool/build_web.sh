#!/usr/bin/env bash
# Release web build with a published build id.
#
# The id is compiled into the app and written to build/web/app_build.json.
# Installed PWAs compare the two and ask before loading the new version.
# Pass --base-href / for a domain root, or --base-href /My-Golf-Diary/ for Pages.

set -euo pipefail

cd "$(dirname "$0")/.."

BASE_HREF="/"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-href)
      BASE_HREF="${2:?--base-href needs a value}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

STAMP="$(date -u +%Y%m%d%H%M%S)"
if [[ -n "${APP_BUILD_ID:-}" ]]; then
  BUILD_ID="$APP_BUILD_ID"
else
  SHA="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
  BUILD_ID="${SHA}-${STAMP}"
fi

# Local CanvasKit. The CDN build fetches canvaskit.wasm from gstatic and
# the installed PWA cannot paint with no network.
flutter build web --release --base-href "$BASE_HREF" --no-wasm-dry-run \
  --no-web-resources-cdn \
  --dart-define=APP_BUILD_ID="$BUILD_ID"

python3 - "$BUILD_ID" <<'PY'
import json
import sys
from pathlib import Path

build_id = sys.argv[1]
version = "unknown"
for line in Path("pubspec.yaml").read_text().splitlines():
    if line.startswith("version:"):
        version = line.split(":", 1)[1].strip()
        break

web = Path("build/web")
manifest = web / "app_build.json"
manifest.write_text(
    json.dumps({"buildId": build_id, "version": version}, indent=2) + "\n"
)

index_path = web / "index.html"
index = index_path.read_text()
needle = '<meta name="golf-diary-release" content="false">'
replacement = '<meta name="golf-diary-release" content="true">'
if needle not in index:
    raise SystemExit("golf-diary-release meta tag missing from build/web/index.html")
index_path.write_text(index.replace(needle, replacement, 1))

bundle = web / "main.dart.js"
if build_id not in bundle.read_text(errors="ignore"):
    raise SystemExit("APP_BUILD_ID was not compiled into main.dart.js")

bootstrap = (web / "flutter_bootstrap.js").read_text(errors="ignore")
if '"useLocalCanvasKit":true' not in bootstrap:
    raise SystemExit("offline PWA requires local CanvasKit (useLocalCanvasKit)")
if not (web / "canvaskit" / "canvaskit.wasm").exists():
    raise SystemExit("canvaskit.wasm missing from build/web")

skip_names = {"precache_manifest.json", "app_build.json", "pwa_service_worker.js"}
urls = []
for path in sorted(web.rglob("*")):
    if not path.is_file() or path.suffix == ".map" or path.name in skip_names:
        continue
    rel = path.relative_to(web).as_posix()
    if rel.startswith("/") or ".." in rel.split("/"):
        raise SystemExit(f"precache path escaped the web root: {rel}")
    urls.append(rel)
if "index.html" not in urls or "main.dart.js" not in urls:
    raise SystemExit("precache manifest is missing the app shell")

precache = web / "precache_manifest.json"
precache.write_text(json.dumps({"urls": urls}, indent=2) + "\n")
worker = (web / "pwa_service_worker.js").read_text()
if "precache_manifest.json" not in worker:
    raise SystemExit("service worker does not precache the shell")

print(f"Stamped {manifest} buildId={build_id} version={version}")
print(f"Wrote {precache} with {len(urls)} urls")
PY
