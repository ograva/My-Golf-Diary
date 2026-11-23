# Wireframe — Club tournament pilot (MGDV-6-010…014)

| Field | Value |
| :--- | :--- |
| **Widgets** | `TournamentListScreen`, `TournamentEventSheet`, `TournamentLeaderboardScreen`, overlays on `ScorecardScreen`, `SwingDiarySheet` |
| **Stories** | [MGDV-6-010](../../stories/MGDV/MGDV-6-010-club-tournament-enrollment.md) … [MGDV-6-014](../../stories/MGDV/MGDV-6-014-post-tournament-diary.md) |
| **Persona** | Rory @ Club Intramuros |
| **Status** | **Design spec** (not shipped) — 2026-11-23 |

## 1. Entry

Scorecard AppBar overflow **Tournaments** (`scorecard-tournaments-btn`) opens list. Signed-out users hit full-screen gate (`tournament-sign-in-gate`) with link to `account-avatar-button` flow — no anonymous enroll.

## 2. Event list (MGDV-6-010)

```
┌─────────────────────────────────────────┐
│ ← Tournaments                           │
├─────────────────────────────────────────┤
│ Intramuros Club Day          [Pilot]    │  tournament-event-card-{eventId}
│ Sat 12 Apr · Molave · CMGC                │
│ Fee: copy-only PHP reminder              │
│ [ Enroll ]                               │  tournament-enroll-btn
├─────────────────────────────────────────┤
│ (empty) No pilot events — pull to refresh│  tournament-event-list-empty
└─────────────────────────────────────────┘
```

- `tournament-event-list` = scroll list; pull-to-refresh when online.
- Enrolled state: **Enrolled** chip + `tournament-withdraw-btn` (confirm dialog `tournament-withdraw-confirm`).
- Offline: last cache from `tournament_events_cache` with banner `tournament-cache-stale`.

## 3. Start round under event (MGDV-6-011)

`Wireframe_NewRound.md` gains **Play for event** section when enrolled:

- `new-round-event-picker` lists enrolled events only.
- Selected event locks format toggles (`scorecard-format-toggle` disabled) and shows `scorecard-event-badge` with event title.
- `scorecard-event-policy-banner` when `diary_silence` — “No AI during competition” (composer still visible; Send allowed if silence off per event flag).

Finish round: if `marker_required`, `scorecard-attest-btn` must include role **marker** before `tournament-submit-btn` enables.

## 4. Leaderboard (MGDV-6-012)

```
┌─────────────────────────────────────────┐
│ ← Standings · Intramuros Club Day       │
├─────────────────────────────────────────┤
│ ⚠ Showing last sync 2h ago            │  tournament-leaderboard-stale
│ 1  Ana · Molave 41        audit ✓      │  tournament-leaderboard-row-{uid}
│ 2  Rory · Molave 38       mismatch ⚠   │
└─────────────────────────────────────────┘
```

- `tournament-leaderboard` = list; sort label reflects event format.
- Audit icons: edited-after-attest, partner mismatch (reuse flight warning tone).

## 5. Marker / committee (MGDV-6-013)

On leaderboard row or published card detail:

- `tournament-marker-attest-btn` for marker role (name field `tournament-marker-name`).
- After `closes_at`: `tournament-committee-lock-banner` on list + leaderboard.
- Late edit: `tournament-late-correction-banner` on scorecard; standings row shows flag, rank frozen.

## 6. Post-tournament diary (MGDV-6-014)

System message in diary thread (non-user bubble):

```
┌ Tournament wrap — Intramuros Club Day ─┐
│ Molave 38 · Field median 40            │  diary-tournament-wrap
│ Holes 12, 15 cost most vs par          │
│ [ Open Range — approach drills ]       │  diary-tournament-range-link
└────────────────────────────────────────┘
```

No Vertex call on insert. Range deep link opens tab 1 with optional drill tag chip pre-filter.

## 7. Key map (tournament)

| Element | ValueKey |
| :--- | :--- |
| Open tournaments | `scorecard-tournaments-btn` |
| List | `tournament-event-list` |
| Event row | `tournament-event-card-{eventId}` |
| Enroll / withdraw | `tournament-enroll-btn`, `tournament-withdraw-btn`, `tournament-withdraw-confirm` |
| Sign-in gate | `tournament-sign-in-gate` |
| Stale cache | `tournament-cache-stale`, `tournament-leaderboard-stale` |
| Event badge on card | `scorecard-event-badge` |
| Policy banner | `scorecard-event-policy-banner` |
| Submit to event | `tournament-submit-btn` |
| Leaderboard | `tournament-leaderboard` |
| Leaderboard row | `tournament-leaderboard-row-{uid}` |
| Committee lock | `tournament-committee-lock-banner` |
| Late correction | `tournament-late-correction-banner` |
| Marker attest | `tournament-marker-attest-btn`, `tournament-marker-name` |
| Diary wrap | `diary-tournament-wrap`, `diary-tournament-range-link` |
| New round event | `new-round-event-picker` |

**MGDV-6-015** caddy dispute keys: see [Wireframe_CaddyDispute.md](./Wireframe_CaddyDispute.md).