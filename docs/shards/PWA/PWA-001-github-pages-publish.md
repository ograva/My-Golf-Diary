# SHARD-PWA-001: GitHub Pages publish

| Field | Value |
| :--- | :--- |
| **Shard ID** | PWA-001 |
| **Module** | PWA |
| **Story Ref** | PWA-001 |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | None |

## Description

The Flutter web build publishes to GitHub Pages when `golf_diary_app/` changes on `main`. The workflow builds with base href `/My-Golf-Diary/` and bundles the web SQLite assets. A running PWA offers an update dialog when the published build id differs from the running one. Later dismisses that id until a newer publish exists.

## Acceptance Criteria

- [x] `.github/workflows/publish-pwa.yml` runs on pushes to `main` that touch `golf_diary_app/**` or the workflow file, and on `workflow_dispatch`.
- [x] The web build uses `--base-href /My-Golf-Diary/` and installs the sqflite web bundle.
- [x] `shouldOfferPwaUpdate` is true only when the published build id is non-empty and different from the running id, and false after Later for that same id.
- [x] The update UI uses `pwa-update-dialog`, `pwa-update-confirm`, and `pwa-update-later`.

## Test coverage

- [x] **Unit/widget:** `test/pwa_update_test.dart` (policy and dialog keys). Not re-written. The GitHub Actions workflow is not a `flutter test`; the YAML above is the check for the CI acceptance criteria.
- [x] **Integration (if needed):** Not required in this suite. A live Pages deploy is the publish skill, not `flutter test`.
- [x] **Keys:** `pwa-update-dialog`, `pwa-update-confirm`, `pwa-update-later` from `Wireframe_PwaUpdate.md`. Story copy says `pwa-update-banner`; the shipped control is the dialog.

## Dev notes

- `.github/workflows/publish-pwa.yml`
- `golf_diary_app/tool/build_web.sh`
- `golf_diary_app/lib/pwa/pwa_update_policy.dart`
- `golf_diary_app/lib/pwa/pwa_update_host.dart`
- Architecture §8 PWA / web. No Playwright.
