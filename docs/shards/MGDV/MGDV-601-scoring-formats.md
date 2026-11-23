# SHARD-MGDV-601: Individual scoring formats

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-601 |
| **Epic** | MGDV-6 |
| **Module** | SCOR |
| **Priority** | High |
| **Status** | Completed |
| **Complexity** | L |
| **Depends On** | MGDV-401 |

## Description

A golfer can score one round as gross, Molave, or System 36 without changing stored strokes. Optional course rating and slope produce an unofficial handicap estimate. The card can be attested on the device. A flight QR shares hole totals with up to four diaries, and a caddy can enter a hole score for another player in the flight.

## Acceptance criteria

- [x] Gross stays the default. Molave and System 36 are derived from par, strokes, penalties, and concede.
- [x] System 36 net appears only after 18 played holes.
- [x] One paid tournament mulligan per nine, excluded from hole-in-one points.
- [x] Attesting a card locks it until an edit clears the attestation.
- [x] Course rating and slope are optional. The handicap line is labeled an unofficial estimate and needs three rated 18-hole rounds.
- [x] A flight code publishes hole totals only. A partner attestation flags a later edit.
- [x] A caddy can set a hole score for another player without writing that score onto the golfer's card, and can attest the golfer's card.

## Keys

| Key | Control |
| :--- | :--- |
| `scorecard-format-toggle` | Gross / Molave / System 36 |
| `scorecard-format-total` | Format summary |
| `scorecard-attest-btn` | Attest card |
| `scorecard-attest-badge` | Attestation state |
| `scorecard-handicap-estimate` | Unofficial estimate |
| `scorecard-flight-btn` | Open the flight sheet |
| `flight-qr` | Flight invite |
| `caddy-player-strip` | Flight player picker |
| `caddy-score-plus` | Hole score up |
| `caddy-attest-card` | Caddie attestation |
