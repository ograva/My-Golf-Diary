---
name: publish-github-release-pwa-apk
description: "Build the Flutter PWA zip and Android APK, then publish both as assets on a GitHub Release. Use when the user asks for a GitHub release, downloadable PWA zip, APK artifact, or sideload build."
---

# Publish GitHub Release (PWA zip + APK)

Build portable My Golf Diary artifacts and attach them to a GitHub Release.

## When to use

- User asks for a **GitHub release** with the **PWA** and/or **APK**
- User wants a downloadable `*.zip` web build or `*.apk` for sideloading
- User says “publish a release”, “cut a release”, or “ship PWA and APK”

Do **not** use this skill to deploy the live Pages site — use `publish-pwa-github-pages` for that.

## Preconditions

1. Clean or intentionally committed tree on the branch that should be tagged.
2. `cd golf_diary_app && flutter pub get` succeeds.
3. `gh auth status` works with `repo` scope.
4. For the PWA zip:
   - Ensure `web/sqlite3.wasm` and `web/sqflite_sw.js` exist, or run `dart run sqflite_common_ffi_web:setup`
5. For the APK:
   - Android SDK + cmdline tools must be available (`flutter doctor` should not show a missing Android toolchain)
   - If Android SDK is missing, install/configure it or report the blocker and still publish the PWA zip if requested

## Version / tag

Ask the user for a tag if they did not give one. Default pattern for this project:

- First PWA-oriented release style: `v0.1.0-pwa`
- Or semver from `golf_diary_app/pubspec.yaml` `version:` (use the `x.y.z` before `+build`)

Tag rules:

- Annotated tag on the intended commit
- Tag name must not already point at the wrong commit; confirm with `git rev-parse <tag>` / `gh release view <tag>`

## Artifact names

| Artifact | Suggested filename | Notes |
| :--- | :--- | :--- |
| Web PWA | `my-golf-diary-pwa.zip` | Contents of `build/web` (portable `base-href /`) |
| Android APK | `my-golf-diary.apk` | From `build/app/outputs/flutter-apk/app-release.apk` |

Save copies under `/opt/cursor/artifacts/` when running as a Cloud Agent so they are easy to attach and inspect.

## Steps

### 1. Build the PWA zip

Use a **portable** base href (`/`) so the unzipped site can be hosted at a domain root. Do **not** use `/My-Golf-Diary/` in the release zip (that path is for GitHub Pages only).

```bash
cd golf_diary_app
dart run sqflite_common_ffi_web:setup
flutter build web --release --base-href / --no-wasm-dry-run

# Verify portrait + sqlite assets
python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path('build/web/manifest.json').read_text())
html = Path('build/web/index.html').read_text()
assert m.get('orientation') == 'portrait'
assert Path('build/web/sqlite3.wasm').exists()
assert Path('build/web/sqflite_sw.js').exists()
assert "orientation.lock('portrait')" in html or 'screen-orientation' in html
print('PWA build checks OK')
PY

rm -f /opt/cursor/artifacts/my-golf-diary-pwa.zip
(cd build/web && zip -r /opt/cursor/artifacts/my-golf-diary-pwa.zip . -x '*.map')
```

### 2. Build the release APK

```bash
cd golf_diary_app
flutter build apk --release
cp -f build/app/outputs/flutter-apk/app-release.apk /opt/cursor/artifacts/my-golf-diary.apk
```

If `flutter build apk` fails because the Android SDK is missing:

1. Say clearly that the APK could not be built in this environment
2. Continue with the PWA zip if that part succeeded
3. List what the user needs locally: Android SDK, accept licenses, then re-run this skill or `flutter build apk --release`

Signing note for this repo: `android/app/build.gradle` currently uses the **debug** signing config for release. That is fine for sideload/testing releases. Call that out in the release notes. Do not pretend it is Play Store–ready without a real upload keystore.

### 3. Tag and create the GitHub Release

From the repo root, on the commit to ship:

```bash
TAG="<tag>"   # e.g. v0.1.1
git tag -a "$TAG" -m "My Golf Diary $TAG"
git push origin "$TAG"

ASSETS=()
[[ -f /opt/cursor/artifacts/my-golf-diary-pwa.zip ]] && ASSETS+=(/opt/cursor/artifacts/my-golf-diary-pwa.zip)
[[ -f /opt/cursor/artifacts/my-golf-diary.apk ]] && ASSETS+=(/opt/cursor/artifacts/my-golf-diary.apk)

if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "${ASSETS[@]}" --clobber
else
  gh release create "$TAG" "${ASSETS[@]}" \
    --title "My Golf Diary $TAG" \
    --notes-file - <<EOF
## My Golf Diary $TAG

### Assets
- \`my-golf-diary-pwa.zip\` — unzip and serve over HTTPS (static host). Opening \`index.html\` as a local file will not install as a PWA.
- \`my-golf-diary.apk\` — Android sideload build (included when the Android toolchain was available).

### Notes
- Browser diary data stays in that browser (SQLite / IndexedDB). Clearing site storage or using another browser starts a fresh diary. The APK keeps a separate on-device database.
- The web app requests portrait orientation on phones (manifest + Screen Orientation API when the browser allows it).
- APK release signing currently uses the debug keystore unless that was changed — sideload only, not Play Store upload.
EOF
fi

gh release view "$TAG" --json url,tagName,assets
```

### 4. Report to the user

Include:

- Release URL
- Which assets uploaded (PWA zip / APK)
- Any skipped artifact and why
- Reminder that Pages is a separate step (`publish-pwa-github-pages`)

## Optional: also update Pages

If the user asked for both a release **and** a live site, after the release succeeds run the `publish-pwa-github-pages` skill (rebuild with `--base-href /My-Golf-Diary/`, not the portable `/` build).

## Safety

- Do not put API keys, keystores, or `google-services.json` secrets into release assets or notes.
- Do not use `gh` to open or merge PRs as part of this skill; only tags/releases/asset upload.
- Prefer `--clobber` when replacing assets on an existing tag the user asked to refresh.
