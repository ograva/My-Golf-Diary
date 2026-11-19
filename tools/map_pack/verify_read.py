"""Check deployed Storage access for map packs the way the app sees it.

    python verify_read.py
    python verify_read.py --object course_maps/ph-crse-villamor/manifest.json

Signs in anonymously with the app's public web API key (Anonymous Auth must be enabled),
reads the object with that ID token, and expects an unauthenticated read to be refused.
Exit code 1 if either expectation fails.
"""

from __future__ import annotations

import argparse
import sys
from urllib.parse import quote

import requests

WEB_API_KEY = "AIzaSyCs1BB64kAYt-nilCV1oPSuga0E0bYtIRM"
DEFAULT_BUCKET = "novusinc-8df79.appspot.com"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", default=DEFAULT_BUCKET)
    ap.add_argument("--object", default="course_maps/index.json")
    args = ap.parse_args()

    signup = requests.post(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={WEB_API_KEY}",
        json={"returnSecureToken": True},
        timeout=30,
    )
    signup.raise_for_status()
    token = signup.json()["idToken"]

    url = f"https://firebasestorage.googleapis.com/v0/b/{args.bucket}/o/{quote(args.object, safe='')}?alt=media"
    authed = requests.get(url, headers={"Authorization": f"Firebase {token}"}, timeout=30)
    anon = requests.get(url, timeout=30)

    ok_authed = authed.status_code == 200
    ok_anon = anon.status_code in (401, 403)
    print(f"authenticated GET {args.object}: HTTP {authed.status_code} ({len(authed.content)} bytes) {'OK' if ok_authed else 'FAIL'}")
    print(f"unauthenticated GET {args.object}: HTTP {anon.status_code} {'OK' if ok_anon else 'FAIL (expected 401/403)'}")
    return 0 if ok_authed and ok_anon else 1


if __name__ == "__main__":
    sys.exit(main())
