#!/usr/bin/env bash
# Send a reCAPTCHA Enterprise assessment for project novusinc-8df79.
#
# This is the manual check from the reCAPTCHA console. The PWA does not call
# this URL. Firebase App Check exchanges the browser token itself.
#
# Usage:
#   RECAPTCHA_API_KEY=... ./tool/recaptcha_assessment.sh TOKEN [USER_ACTION]
#   RECAPTCHA_API_KEY=... ./tool/recaptcha_assessment.sh --dry-run TOKEN [USER_ACTION]
#
# TOKEN is the string returned by grecaptcha.enterprise.execute().
# USER_ACTION is optional and must match the action passed to execute().
# RECAPTCHA_API_KEY is the project API key. It is not written to request.json.

set -euo pipefail

cd "$(dirname "$0")"

DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY=1
  shift
fi

TOKEN="${1:?Pass the grecaptcha.enterprise.execute() token}"
ACTION="${2:-}"
SITE_KEY="6Lcd0xwuAAAAAITS9nQa0SdLNAUqYqkSYJKlbnc3"
OUT="${RECAPTCHA_REQUEST_JSON:-request.json}"

if [[ "$DRY" -eq 0 && -z "${RECAPTCHA_API_KEY:-}" ]]; then
  echo "Set RECAPTCHA_API_KEY to the project API key." >&2
  exit 1
fi

python3 - "$TOKEN" "$ACTION" "$SITE_KEY" "$OUT" <<'PY'
import json
import sys

token, action, site_key, out = sys.argv[1:5]
event = {"token": token}
if action:
    event["expectedAction"] = action
event["siteKey"] = site_key
with open(out, "w", encoding="utf-8") as handle:
    json.dump({"event": event}, handle, indent=2)
    handle.write("\n")
print(f"Wrote {out}")
PY

if [[ "$DRY" -eq 1 ]]; then
  echo "Dry run. No request was sent."
  exit 0
fi

curl -sS -X POST \
  -H "Content-Type: application/json" \
  "https://recaptchaenterprise.googleapis.com/v1/projects/novusinc-8df79/assessments?key=${RECAPTCHA_API_KEY}" \
  --data-binary @"$OUT"
echo
