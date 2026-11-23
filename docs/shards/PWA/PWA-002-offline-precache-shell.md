# SHARD-PWA-002: Offline precache shell

| Field | Value |
| :--- | :--- |
| **Shard ID** | PWA-002 |
| **Module** | PWA |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | PWA-001 |

## Description

The installed PWA opens from a precached app shell. First paint does not wait on Firebase initialization.

## Acceptance criteria

- [x] Service worker `golf-diary-shell-v2` precaches shell assets via `precache_manifest.json`.
- [x] Web build uses local CanvasKit (`--no-web-resources-cdn`).
- [x] `main` calls `runApp` before optional cloud startup (`unawaited(_startOptionalCloud())`).
- [x] Optional Firebase startup times out (`kOptionalFirebaseStartupLimit`).
- [x] `pwa_offline_shell_test.dart` guards the contract.

## Keys

| Key | Control |
| :--- | :--- |
| `pwa-update-banner` | New build prompt (PWA-001) |