# Development stories — My Golf Diary

File-per-story product narratives for **Eunice** wireframe coverage and **Poe** sharding. Requirements source of truth remains [PRD §3](../context/PRD.md); engineering detail may live in [shards](../shards/) — stories do not duplicate full shard AC.

**Validation:** [PRD ↔ Architecture](../context/PRD-Architecture-validation.md) (2026-11-20).

## Index by prefix

| Prefix | Folder | Count | Focus |
| :--- | :--- | ---: | :--- |
| **BAG** | [BAG/](BAG/) | 4 | My Bag categories, stat tiles, notes |
| **CRSE** | [CRSE/](CRSE/) | 13 | On Course FWY/SIM, map packs, holing stroke |
| **SCOR** | [SCOR/](SCOR/) | 4 | Grid, editor, cart view |
| **RNGE** | [RNGE/](RNGE/) | 5 | Drills, blocks, session log, swing diary |
| **SYNC** | [SYNC/](SYNC/) | 10 | Auth, sync, avatar menu |
| **MGDV** | [MGDV/](MGDV/) | 5 | Onboarding, disclosure, cart epic, caddy |
| **SHELL** | [SHELL/](SHELL/) | 1 | Tab state |
| **PWA** | [PWA/](PWA/) | 1 | GitHub Pages publish |

**Total:** 43 story files.

## Naming

`[PREFIX]/[PREFIX-###]-[slug].md` — IDs match PRD story IDs where they exist (`BAG-010`, `CRSE-036`, `MGDV-201`, etc.).

## Status legend

| Status | Meaning |
| :--- | :--- |
| **Shipped** | In `golf_diary_app/` today |
| **Partial** | Core shipped; gaps in PRD §7 / Architecture §8 |
| **Planned** | Forward scope, not fully implemented |