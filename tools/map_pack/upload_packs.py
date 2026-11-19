"""Upload validated packs from out/ to Firebase Storage per the CRSE-041 contract.

    python upload_packs.py ph-crse-villamor ph-crse-cebu-cc
    python upload_packs.py --all --dry-run

Credentials: a service account with Storage Object Admin on the bucket, either as a key
file in GOOGLE_APPLICATION_CREDENTIALS or as the key JSON in FIREBASE_SERVICE_ACCOUNT_JSON.
Images go first, then each manifest, then index.json last, so clients never see a version
whose files are missing.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from validate_pack import validate

OUT_DIR = Path(__file__).resolve().parent / "out"
PREFIX = "course_maps"
CACHE_CONTROL = "public, max-age=300"
DEFAULT_BUCKET = "novusinc-8df79.appspot.com"


def _client():
    from google.cloud import storage
    from google.oauth2 import service_account

    raw = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON")
    if raw:
        info = json.loads(raw)
        creds = service_account.Credentials.from_service_account_info(info)
        return storage.Client(project=info.get("project_id"), credentials=creds)
    return storage.Client()


def _put(bucket, local: Path, remote: str, content_type: str, dry_run: bool) -> None:
    print(f"{'DRY ' if dry_run else ''}upload {local.relative_to(OUT_DIR)} -> {remote}")
    if dry_run:
        return
    blob = bucket.blob(remote)
    blob.cache_control = CACHE_CONTROL
    blob.upload_from_filename(str(local), content_type=content_type)


def _merged_index(bucket, course_ids: list[str], dry_run: bool) -> dict:
    remote: dict = {"schema": 1, "courses": []}
    if bucket is not None and not dry_run:
        blob = bucket.blob(f"{PREFIX}/index.json")
        if blob.exists():
            remote = json.loads(blob.download_as_text())
    versions = {c["courseId"]: c["version"] for c in remote.get("courses", [])}
    for cid in course_ids:
        versions[cid] = json.loads((OUT_DIR / cid / "manifest.json").read_text())["version"]
    return {"schema": 1, "courses": [{"courseId": k, "version": v} for k, v in sorted(versions.items())]}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("course_ids", nargs="*")
    ap.add_argument("--all", action="store_true", help="every pack under out/")
    ap.add_argument("--bucket", default=DEFAULT_BUCKET, help="bucket name (default: the app's default bucket)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    ids = sorted(p.name for p in OUT_DIR.iterdir() if (p / "manifest.json").exists()) if args.all else args.course_ids
    if not ids:
        ap.error("give course ids or --all")

    failed = {cid: errs for cid in ids if (errs := validate(cid))}
    if failed:
        for cid, errs in failed.items():
            print(f"{cid}: {len(errs)} validation error(s), e.g. {errs[0]}", file=sys.stderr)
        return 1

    bucket = None if args.dry_run else _client().bucket(args.bucket.removeprefix("gs://"))
    for cid in ids:
        pack = OUT_DIR / cid
        manifest = json.loads((pack / "manifest.json").read_text())
        for h in manifest["holes"]:
            img = pack / h["imagePath"]
            ctype = "image/webp" if img.suffix == ".webp" else "image/png"
            _put(bucket, img, f"{PREFIX}/{cid}/{h['imagePath']}", ctype, args.dry_run)
        _put(bucket, pack / "manifest.json", f"{PREFIX}/{cid}/manifest.json", "application/json", args.dry_run)

    index = _merged_index(bucket, ids, args.dry_run)
    index_path = OUT_DIR / "index.upload.json"
    index_path.write_text(json.dumps(index, indent=2) + "\n")
    _put(bucket, index_path, f"{PREFIX}/index.json", "application/json", args.dry_run)
    print(f"done: {len(ids)} course(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
