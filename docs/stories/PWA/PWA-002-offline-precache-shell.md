# PWA-002 — Offline precache shell

| Field | Value |
| :--- | :--- |
| **ID** | PWA-002 |
| **Module** | PWA |
| **Priority** | High |
| **Status** | Shipped |
| **Shard** | [PWA-002-offline-precache-shell.md](../../shards/PWA/PWA-002-offline-precache-shell.md) |
| **PRD** | [PRD §5 NFR Web/PWA](../../context/PRD.md) |

## User story

As **Blake**, I want **the installed PWA to open instantly** even when Firebase is slow or offline.

## Acceptance criteria

1. Precached navigation shell.
2. Firebase optional on startup.
3. Local CanvasKit bundle.
4. Regression test in `pwa_offline_shell_test.dart`.

## Notes

Shipped PR #85.