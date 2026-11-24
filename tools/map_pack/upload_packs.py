"""Upload validated packs from out/ to Firebase Storage per the CRSE-041 contract.

    python upload_packs.py ph-crse-villamor ph-crse-cebu-cc
    python upload_packs.py --all --dry-run
    python upload_packs.py --migrate-legacy --all

Credentials: a service account with Storage Object Admin on the bucket, either as a key
file in GOOGLE_APPLICATION_CREDENTIALS or as the key JSON in FIREBASE_SERVICE_ACCOUNT_JSON.
FIREBASE_SERVICE_ACCOUNT_JSON may instead hold a `firebase login:ci` refresh token (starts
with 1//); the signed-in user then needs write access to the bucket.

Packs go to course_maps/{courseId}/v{version}/ and are never overwritten in place, so they
are cached as immutable; only course_maps/index.json changes, and it is served no-cache.
Images go first, then each manifest, then index.json last, so clients never see a version
whose files are missing.

--migrate-legacy copies packs already in the bucket at the pre-versioning paths
(course_maps/{courseId}/manifest.json, hole_*.png) to course_maps/{courseId}/v{version}/
server-side, without out/. The legacy objects are left in place for older app builds.
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
PACK_CACHE_CONTROL = "public, max-age=31536000, immutable"
INDEX_CACHE_CONTROL = "no-cache"
DEFAULT_BUCKET = "novusinc-8df79.appspot.com"
PROJECT_ID = "novusinc-8df79"
FIREBASE_CLI_CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
FIREBASE_CLI_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi"


def pack_prefix(course_id: str, version: int) -> str:
    return f"{PREFIX}/{course_id}/v{version}"


def _client():
    from google.cloud import storage
    from google.oauth2 import service_account

    raw = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if raw.startswith("1//"):
        from google.oauth2.credentials import Credentials

        # A `firebase login:ci` refresh token; it is bound to the Firebase CLI's public OAuth client.
        creds = Credentials(
            None,
            refresh_token=raw,
            client_id=FIREBASE_CLI_CLIENT_ID,
            client_secret=FIREBASE_CLI_CLIENT_SECRET,
            token_uri="https://oauth2.googleapis.com/token",
        )
        return storage.Client(project=PROJECT_ID, credentials=creds)
    if raw:
        info = json.loads(raw)
        creds = service_account.Credentials.from_service_account_info(info)
        return storage.Client(project=info.get("project_id"), credentials=creds)
    return storage.Client()


def _put(bucket, local: Path, remote: str, content_type: str, cache_control: str, dry_run: bool) -> None:
    print(f"{'DRY ' if dry_run else ''}upload {local.relative_to(OUT_DIR)} -> {remote} ({cache_control})")
    if dry_run:
        return
    blob = bucket.blob(remote)
    blob.cache_control = cache_control
    blob.upload_from_filename(str(local), content_type=content_type)


def _copy(bucket, src: str, dst: str, dry_run: bool) -> bool:
    print(f"{'DRY ' if dry_run else ''}copy {src} -> {dst} ({PACK_CACHE_CONTROL})")
    if dry_run:
        return True
    source = bucket.blob(src)
    if not source.exists():
        print(f"  missing {src}", file=sys.stderr)
        return False
    copied = bucket.copy_blob(source, bucket, dst)
    copied.cache_control = PACK_CACHE_CONTROL
    copied.patch()
    return True


def _remote_index(bucket, dry_run: bool) -> dict:
    remote: dict = {"schema": 1, "courses": []}
    if bucket is not None and not dry_run:
        blob = bucket.blob(f"{PREFIX}/index.json")
        if blob.exists():
            remote = json.loads(blob.download_as_text())
    return remote


def _merged_index(bucket, course_ids: list[str], dry_run: bool) -> dict:
    remote = _remote_index(bucket, dry_run)
    versions = {c["courseId"]: c["version"] for c in remote.get("courses", [])}
    for cid in course_ids:
        versions[cid] = json.loads((OUT_DIR / cid / "manifest.json").read_text())["version"]
    return {"schema": 1, "courses": [{"courseId": k, "version": v} for k, v in sorted(versions.items())]}


def migrate_legacy(bucket, ids: list[str], dry_run: bool) -> int:
    """Copy unversioned packs to v{version}/ for ids listed in the bucket's index.json."""
    index = _remote_index(bucket, dry_run=False)
    versions = {c["courseId"]: c["version"] for c in index.get("courses", [])}
    failed = 0
    for cid in ids or sorted(versions):
        legacy = bucket.blob(f"{PREFIX}/{cid}/manifest.json")
        if not legacy.exists():
            print(f"{cid}: no legacy manifest, skipped")
            continue
        manifest = json.loads(legacy.download_as_text())
        version = manifest.get("version", 1)
        if versions.get(cid) != version:
            print(f"{cid}: legacy manifest v{version} is not the index version {versions.get(cid)}, skipped", file=sys.stderr)
            failed += 1
            continue
        dst = pack_prefix(cid, version)
        ok = all(_copy(bucket, f"{PREFIX}/{cid}/{h['imagePath']}", f"{dst}/{h['imagePath']}", dry_run) for h in manifest["holes"])
        if ok:
            ok = _copy(bucket, f"{PREFIX}/{cid}/manifest.json", f"{dst}/manifest.json", dry_run)
        failed += 0 if ok else 1
    index_blob = bucket.blob(f"{PREFIX}/index.json")
    print(f"{'DRY ' if dry_run else ''}set {PREFIX}/index.json cache-control {INDEX_CACHE_CONTROL}")
    if not dry_run and index_blob.exists():
        index_blob.cache_control = INDEX_CACHE_CONTROL
        index_blob.patch()
    print(f"done: {len(ids or versions) - failed} course(s) migrated, {failed} failed")
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("course_ids", nargs="*")
    ap.add_argument("--all", action="store_true", help="every pack under out/ (or in index.json with --migrate-legacy)")
    ap.add_argument("--bucket", default=DEFAULT_BUCKET, help="bucket name (default: the app's default bucket)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--migrate-legacy", action="store_true", help="copy bucket packs from the unversioned layout to v{n}/")
    args = ap.parse_args()

    if args.migrate_legacy:
        if not args.all and not args.course_ids:
            ap.error("give course ids or --all")
        bucket = _client().bucket(args.bucket.removeprefix("gs://"))
        return migrate_legacy(bucket, [] if args.all else args.course_ids, args.dry_run)

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
        dst = pack_prefix(cid, manifest["version"])
        for h in manifest["holes"]:
            img = pack / h["imagePath"]
            ctype = "image/webp" if img.suffix == ".webp" else "image/png"
            _put(bucket, img, f"{dst}/{h['imagePath']}", ctype, PACK_CACHE_CONTROL, args.dry_run)
        _put(bucket, pack / "manifest.json", f"{dst}/manifest.json", "application/json", PACK_CACHE_CONTROL, args.dry_run)

    index = _merged_index(bucket, ids, args.dry_run)
    index_path = OUT_DIR / "index.upload.json"
    index_path.write_text(json.dumps(index, indent=2) + "\n")
    _put(bucket, index_path, f"{PREFIX}/index.json", "application/json", INDEX_CACHE_CONTROL, args.dry_run)
    print(f"done: {len(ids)} course(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
