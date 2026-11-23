# Development stories — My Golf Diary

File-per-story product narratives for **Eunice** wireframe coverage and **Poe** sharding. Requirements source of truth remains [PRD §3](../context/PRD.md); engineering detail may live in [shards](../shards/) — stories do not duplicate full shard AC.

**Validation:** [PRD ↔ Architecture](../context/PRD-Architecture-validation.md) (2026-11-20).

## Index by prefix

| Prefix | Folder | Count | Focus |
| :--- | :--- | ---: | :--- |
| **BAG** | [BAG/](BAG/) | 4 | My Bag categories, stat tiles, notes |
| **CRSE** | [CRSE/](CRSE/) | 13 | On Course FWY/SIM, map packs, holing stroke |
| **SCOR** | [SCOR/](SCOR/) | 4 | Grid, editor, cart view |
| **RNGE** | [RNGE/](RNGE/) | 5 | Drills, blocks, session log, diary thread |
| **SYNC** | [SYNC/](SYNC/) | 10 | Auth, sync, avatar menu |
| **MGDV** | [MGDV/](MGDV/) | 14 | Onboarding, disclosure, header actions, cart epic, caddy, MGDV-601 shipped, MGDV-6-010…015 planned |
| **PWA** | [PWA/](PWA/) | 2 | GitHub Pages publish, offline precache shell |
| **SHELL** | [SHELL/](SHELL/) | 1 | Tab state |

**Total:** 53 story files.

### MGDV-6 pilot index

| Story | Status |
| :--- | :--- |
| [MGDV-601](MGDV/MGDV-601-scoring-formats-epic.md) | Shipped |
| [MGDV-6-010 … 015](MGDV/MGDV-6-club-tournament-pilot.md) | Planned (Intramuros pilot) |

## Naming

`[PREFIX]/[PREFIX-###]-[slug].md` — IDs match PRD story IDs where they exist (`BAG-010`, `CRSE-036`, `MGDV-201`, etc.).

## Status legend

| Status | Meaning |
| :--- | :--- |
| **Shipped** | In `golf_diary_app/` today |
| **Partial** | Core shipped; gaps in PRD §7 / Architecture §8 |
| **Planned** | Forward scope, not fully implemented |