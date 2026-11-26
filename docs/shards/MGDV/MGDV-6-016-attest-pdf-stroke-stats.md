# SHARD-MGDV-6-016: Attested PDF on-course stats page

| Field | Value |
| :--- | :--- |
| **Shard ID** | MGDV-6-016 |
| **Epic** | MGDV-6 |
| **Module** | MGDV |
| **Story Ref** | MGDV-6-016 |
| **Priority** | Medium |
| **Status** | Completed |
| **Complexity** | M |
| **Depends On** | MGDV-601 (attestation PDF) |

## Description

The attested score PDF gains a second page with on-course stroke statistics when the round has recorded On Course strokes. Page 1 (scorecard, selfie with signature overlay) is unchanged. The app computes a `strokeStats` summary at attest time (`attest_stroke_stats.dart`); `attestScorePdf` only draws it.

## Acceptance Criteria

- [x] Page 2 only when the round has `shots` rows other than the auto "Holed" putt; already-attested payloads stay one page.
- [x] Club table: woods, hybrids, irons down to 9-iron (no wedges or putter): shots, min, avg, max yards. Distance = manual yards, else GPS start to next start; segments under 5 or over 400 yds are ignored.
- [x] Per hole: gross, strokes to approach (first non-putt shot starting ≤ 60 yds from the green; fallback = last shot before the first putt, marked `*`), putts, penalties, mulligans, gimme, clubs before the approach.
- [x] Penalty strokes are excluded from strokes to approach. Mulligans are a count only. A gimme (conceded hole) counts as one putt.
- [x] Green lie on On Course: optional paced yards-to-hole picker (1, 2, 3, 5, 7, 10, 15, 20+, Other) replaces GPS distance; stored as synced `shots.putt_distance_yards` (DB v21). Page 2 shows first-putt yards per hole, average, and putts made by range.
- [x] Cards: longest shot, most-used club (excluding putter and approach shots), putts, penalty/mulligan/gimme totals, GIR, fairways hit (par 4/5, second-shot lie), up and down, 3-putts.

## Test coverage

- [x] `golf_diary_app/test/attest_stroke_stats_test.dart`
- [x] `golf_diary_app/test/on_course_putt_distance_test.dart` (picker Keys, save, holed putt distance)
- [x] `functions/attest_score_pdf.test.js` (page count 1 vs 2, malformed payload)
- [x] Keys: [Wireframe_OnCourse.md](../../context/designs/Wireframe_OnCourse.md) § Key map
- [x] Layout: [Wireframe_ScorecardFormats.md](../../context/designs/Wireframe_ScorecardFormats.md) § 6 Attested PDF page 2
