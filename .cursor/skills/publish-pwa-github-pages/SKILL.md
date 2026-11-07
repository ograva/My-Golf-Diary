---
name: publish-pwa-github-pages
description: "Build the Flutter web PWA and publish it to GitHub Pages (gh-pages). Use when the user asks to deploy the PWA, publish to GitHub Pages, or update the live web site."
---

# Publish PWA to GitHub Pages

Deploy My Golf Diary’s Flutter web build to the repository’s GitHub Pages site.

## When to use

- User asks to publish, deploy, or update the **PWA** on **GitHub Pages**
- User wants a live URL such as `https://<owner>.github.io/My-Golf-Diary/`
- After web/PWA fixes that should go live

Do **not** use this skill for APK builds or GitHub Releases — use `publish-github-release-pwa-apk`.

## Preconditions

1. Work from a clean git state on a branch that includes the current web app under `golf_diary_app/`.
2. Confirm Flutter works: `flutter --version` and `cd golf_diary_app && flutter pub get`.
3. Confirm GitHub CLI auth: `gh auth status` (needs `repo` scope).
4. Read repo visibility: `gh repo view --json nameWithOwner,isPrivate,defaultBranchRef`.
5. Confirm web SQLite assets exist before building:
   - `golf_diary_app/web/sqlite3.wasm`
   - `golf_diary_app/web/sqflite_sw.js`
   - If missing: `cd golf_diary_app && dart run sqflite_common_ffi_web:setup`

## Constants for this repo

| Item | Value |
| :--- | :--- |
| App directory | `golf_diary_app/` |
| Pages branch | `gh-pages` |
| Project Pages URL | `https://<owner>.github.io/My-Golf-Diary/` |
| Build base href | `/My-Golf-Diary/` |
| Pages source | branch `gh-pages`, path `/` |

Replace `<owner>` with the GitHub owner from `gh repo view` (for this repo usually `ograva`).

## Steps

### 1. Build the web app for Pages

```bash
cd golf_diary_app
dart run sqflite_common_ffi_web:setup
./tool/build_web.sh --base-href /My-Golf-Diary/
```

`tool/build_web.sh` compiles `APP_BUILD_ID` into the app and writes the same id to `build/web/app_build.json`. Installed PWAs compare those and ask before reloading onto the new publish.

Verify:

- `build/web/index.html` contains `<base href="/My-Golf-Diary/">`
- `build/web/index.html` contains `<meta name="golf-diary-release" content="true">`
- `build/web/manifest.json` exists and `orientation` is `portrait`
- `build/web/sqlite3.wasm` and `build/web/sqflite_sw.js` exist
- `build/web/pwa_service_worker.js` and `build/web/app_build.json` exist, and `app_build.json` `buildId` is non-empty

### 2. Publish an orphan `gh-pages` branch

Do **not** merge `gh-pages` into `main`. Force-push a clean tree of `build/web` only:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
OWNER_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
REMOTE_URL="$(git -C "$REPO_ROOT" remote get-url origin)"
TMP="$(mktemp -d)"

cp -a "$REPO_ROOT/golf_diary_app/build/web/." "$TMP/"
touch "$TMP/.nojekyll"

cd "$TMP"
git init -b gh-pages
git config user.name "$(git -C "$REPO_ROOT" config user.name)"
git config user.email "$(git -C "$REPO_ROOT" config user.email)"
git add -A
git commit -m "Deploy My Golf Diary PWA to GitHub Pages"
git remote add origin "$REMOTE_URL"
git push origin gh-pages --force
```

Confirm the tip has many files (not only `.nojekyll`):

```bash
git ls-tree -r --name-only HEAD | wc -l
```

### 3. Point GitHub Pages at `gh-pages`

Enable or update Pages:

```bash
gh api -X POST "repos/${OWNER_REPO}/pages" \
  -f build_type=legacy \
  -f source[branch]=gh-pages \
  -f source[path]=/ \
  || gh api -X PUT "repos/${OWNER_REPO}/pages" \
  -f build_type=legacy \
  -f source[branch]=gh-pages \
  -f source[path]=/
```

Poll status:

```bash
gh api "repos/${OWNER_REPO}/pages"
gh api "repos/${OWNER_REPO}/pages/builds/latest"
```

Probe the site:

```bash
curl -sI "https://$(gh repo view --json owner -q .owner.login).github.io/My-Golf-Diary/" | head
curl -sI "https://$(gh repo view --json owner -q .owner.login).github.io/My-Golf-Diary/manifest.json" | head
```

### 4. Report to the user

Always report:

- Pages URL
- Whether the build status is `built`, `building`, or `errored`
- That diary data stays in the visitor’s browser (IndexedDB), separate from the APK

## Private repository blocker

If the repo is **private** and Pages status is `errored` with only `Page build failed`, GitHub Pages for private repos requires a paid plan (GitHub Pro / Team / Enterprise).

Tell the user they must pick one:

1. **Make the repo public** (Settings → General → Change visibility), then wait for Pages to rebuild, **or**
2. **Upgrade** the owner account/org so private Pages is allowed, then re-run this skill / push `gh-pages` again, **or**
3. Skip Pages and use the release zip / another static host (see `publish-github-release-pwa-apk`)

Do not claim the site is live while `https://<owner>.github.io/My-Golf-Diary/` returns 404 or Pages status is `errored`.

## Smoke check after a successful build

1. Open the Pages URL on desktop.
2. Confirm My Bag / On Course / Scorecard / Range load without a `databaseFactory` error.
3. Optionally save a short swing note, refresh, and confirm it remains.

## Safety

- Never commit secrets into `gh-pages`.
- Never force-push `main` or feature branches as part of this skill.
- Prefer orphan `gh-pages` deploys so build artifacts do not clutter app history.
