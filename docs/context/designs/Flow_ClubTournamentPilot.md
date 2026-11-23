# Flow — Club tournament pilot (MGDV-6)

| Field | Value |
| :--- | :--- |
| **Stories** | MGDV-6-010 … MGDV-6-015 |
| **Wireframe** | [Wireframe_Tournament.md](./Wireframe_Tournament.md) |
| **Architecture** | [Architecture.md](../Architecture.md) §5.0.2 |

```mermaid
flowchart TD
  A[Scorecard] -->|scorecard-tournaments-btn| B[Tournament list]
  B -->|signed out| G[tournament-sign-in-gate]
  G -->|SYNC-006| B
  B -->|tournament-enroll-btn| C[Enrolled]
  C -->|new-round-event-picker| D[Event round]
  D -->|play + MGDV-601 format locked| E[Submit attested card]
  E -->|tournament-submit-btn| F[Standings publish]
  F -->|tournament-leaderboard| H[Event leaderboard]
  H -->|committee lock| I[tournament-committee-lock-banner]
  I -->|close| J[diary-tournament-wrap]
  J -->|diary-tournament-range-link| K[Range drills]
  D -.->|optional caddy| L[CaddyShell]
  L -->|dispute| M[caddy-hole-dispute-btn]
```

**Offline loops:** enroll and play stay on SQLite; leaderboard reads `tournament_standing_cache` with stale banner until sync.