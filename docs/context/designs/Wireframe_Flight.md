# Wireframe — Flight sync (`FlightSheet`)

| Field | Value |
| :--- | :--- |
| **Widget** | `FlightSheet`, `FlightJoinScreen` |
| **Stories** | [MGDV-601](../../stories/MGDV/MGDV-601-scoring-formats-epic.md) |
| **Persona** | Rory — share hole totals with up to three partners |
| **Status** | **As-built** (2026-11-23) |

## 1. Purpose

Opaque flight code links up to **four** diaries on the same game. Only **hole gross summaries** sync — not shots, diary, or swing notes. Partner **attest** snapshots hole gross; later edits flag **Edited after attest**.

## 2. Flight sheet (from Scorecard)

```
┌─────────────────────────────────────────┐
│ Flight                              [×] │
├─────────────────────────────────────────┤
│ [ Mint flight ]                         │  flight-mint-btn
│ Code: ABC123…              [QR ▣]       │  flight-code, flight-qr
│ Join code [________] [ Join ]           │  flight-join-field, flight-join-btn
│ [ Publish my card ]                     │  flight-publish-btn
│ ┌ Player A  Molave 38 ─────────────────┐│  flight-player-{id}
│ │ Hole 3 mismatch (attested 5, now 6)   ││
│ [ Attest Player B ]                     │  flight-attest-{id}
└─────────────────────────────────────────┘
```

PWA invite URL: `?mode=flight&token=` → `FlightJoinScreen` (`flight-join-token`, `flight-join-continue`) then golfer joins from this sheet.

## 3. Visual rules

- QR uses `qr_flutter`; high contrast on cream card.
- Mismatch rows use warning tone + text label (not color alone).
- No public social chrome — flight is private to minted code holders.

## 4. Key map

| Element | ValueKey |
| :--- | :--- |
| Open | `scorecard-flight-btn` |
| Mint | `flight-mint-btn` |
| Code / QR | `flight-code`, `flight-qr` |
| Join | `flight-join-field`, `flight-join-btn` |
| Publish | `flight-publish-btn` |
| Player row | `flight-player-{id}` |
| Attest | `flight-attest-{id}` |
| Deep link | `flight-join-token`, `flight-join-continue` |