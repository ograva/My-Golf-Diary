# Wireframe — Swing diary (`SwingDiarySheet`)

| Field | Value |
| :--- | :--- |
| **Widget** | `SwingDiarySheet` |
| **Stories** | [RNGE-004](../../stories/RNGE/RNGE-004-vertex-swing-diary.md), [RNGE-005](../../stories/RNGE/RNGE-005-session-log-compile.md) |
| **Persona** | Riley / Rory — one thread for practice, rounds, and coaching when they ask |
| **Status** | **As-built** (PRD 1.13, 2026-11-23) |

## 1. Screen purpose

A modal sheet (~85% viewport height) for **one ongoing diary thread**. Entry is only the **header book icon** on all four tabs (`diary-entry-*`). There is no diary tab, no Feedback button, and no Summarize today control in the main view.

1. **Thread** — triggered entries (range block, FWY/SIM round finish/leave, scorecard finish summary) appear as list tiles without a model call.
2. **Ask** — multiline **composer** pinned at the **bottom**; **Send** stores the note then calls Vertex when opted in and online.
3. **History** — **Evaluation log** (`diary-evaluation-log-btn`) reads local `range_evaluations` only.

Compile from Range (**Save and evaluate session**) does **not** auto-open this sheet or auto-call Vertex.

## 2. Mobile layout

```
┌─────────────────────────────────────────┐
│ Swing diary                             │  titleLarge
├─────────────────────────────────────────┤
│ ░░░ scrollable thread ░░░░░░░░░░░░░░░░ │
│ [You]  Range · 7 Iron · 155 avg …       │  diary-message-{id}
│ [Evaluation]  Markdown reply …         │
│ [Lead-in chips] [Baseline] [Eval log]   │  when opted in
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
├─────────────────────────────────────────┤
│ ┌ How did your body feel?        [↑] │ │  diary-composer-field (1–6 lines)
│ └─────────────────────────────────────┘ │  diary-send-btn / diary-send-busy
└─────────────────────────────────────────┘
```

Composer: `surfaceContainerHigh`, 24dp radius, `minLines: 1`, `maxLines: 6`, wrap while typing. Send disabled when empty or `_busy`; busy state shows a 32×20dp `GolfPuttLoader` in the send button (`diary-send-busy`): a ball rolls along a `primary` line and drops into the cup beside a pin flag. Until the first streamed chunk arrives, a larger 120×32dp loader sits in an **Evaluation** row in the thread (`diary-golf-loader`).

Coach voice comes from Settings → Golfer profile → **Swing diary coach** (golf-pro default). The sheet has no persona control.

### Opt-in gate (first model use)

Unchanged pattern: privacy copy, `diary-opt-in-continue`, `diary-opt-in-dismiss`. No model id debug line in the sheet.

### Offline / unavailable

`diary-offline-copy` when Vertex unavailable; golfer text can still be composed; Send stays disabled until online + opt-in.

## 3. Visual hierarchy

- Thread scrolls in the **Expanded** region; composer is **never** inside the scroll view.
- User bubbles: golfer avatar (`GolferAvatarCircle`, 16dp) on "You" rows.
- Model replies: `DiaryMarkdownBody`, title **Evaluation**.

## 4. Widget inventory

| Widget | Role |
| :--- | :--- |
| `ListView` | Thread messages |
| `TextField` | `diary-composer-field` |
| `IconButton` | `diary-send-btn` / busy putt loader |
| `GolfPuttLoader` | `diary-send-busy`, `diary-golf-loader` |
| `TextButton` | `diary-evaluation-log-btn`, baseline, lead-ins |
| `_EvaluationLog` | `diary-evaluation-log` reader |

**Removed from main sheet (do not wireframe):** `diary-feedback-btn`, `diary-summarize-today-btn`, Save note on this device.

## 5. Interaction map

| Action | Behavior |
| :--- | :--- |
| Open from header | Same sheet state; reload thread |
| Send | Save user message → Vertex stream → append model row |
| Busy | Cancel via `diary-eval-cancel`; retry `diary-eval-retry` |
| Evaluation log | Full-screen list inside sheet; Back returns to thread |

## 6. Key map

| Element | ValueKey |
| :--- | :--- |
| Shell entry | `diary-entry-bag`, `diary-entry-range`, `diary-entry-on-course`, `diary-entry-scorecard` |
| Composer | `diary-composer-field` |
| Send | `diary-send-btn` |
| Busy | `diary-send-busy` (send button), `diary-golf-loader` (thread row before first chunk) |
| Message | `diary-message-{id}` |
| Eval log | `diary-evaluation-log-btn`, `diary-evaluation-log` |
| Opt-in | `diary-opt-in-continue`, `diary-opt-in-dismiss` |
| Offline | `diary-offline-copy` |