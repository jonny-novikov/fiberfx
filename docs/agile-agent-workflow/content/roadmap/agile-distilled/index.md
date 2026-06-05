# A3.1 · Agile, distilled — module hub (md source of record)

- **Route:** `/course/agile-agent-workflow/roadmap/agile-distilled`
- **File:** `html/agile-agent-workflow/roadmap/agile-distilled/index.html`
- **Accent:** elixir-purple (`.ex`). **Stamp:** `TSK0Ng9hnHJgW0`.
- **Pager:** prev `/course/agile-agent-workflow/roadmap` · next `…/agile-distilled/the-values`.

## Lead

Working software in short cycles, responding to change, inspect-and-adapt. A handful of principles actually drive the
Author/Operator loop; the rest is ceremony — useful in some settings, dead weight here. This module separates the two
and lands the load-bearing few on the Portal's real F6 cadence.

## Definition

The **distilled set** is the smallest group of Agile principles the workflow cannot run without. Each load-bearing
principle names a concrete **move in the loop** (`sharpen → build → ship → demo → review → feedback → adapt`).
Ceremony is a practice that adds process without adding a move the one-agent / one-reviewer loop already needs.

## The arc (three dives)

1. **A3.1.1 the-values** — the four Agile values, and which the loop relies on (working software in short cycles,
   responding to change).
2. **A3.1.2 inspect-and-adapt** — the engine under every Agile practice: build a thing, inspect it, adapt the plan.
   On the Portal it is `demo → review → feedback → adapt`, and feedback edits the spec, not the demo.
3. **A3.1.3 keep-vs-ceremony** — classify each common practice keep / adapt / drop for a one-agent pair.

## Framing interactive (the hub) — classify a principle: load-bearing vs ceremony

- **Control ids:** `adSel` (a `.solid-select` of principle buttons, `data-k`); SVG nodes `ad-node-<k>` selectable.
- **Readout id:** `adOut` (`aria-live="polite"`).
- **Fixed dataset `PRINCIPLES`:** `{k, label, kind: "load-bearing"|"ceremony", move, why}`.
  - `working-software` — load-bearing — move: **ship**. Each rung ships running software, not a document about it.
  - `respond-to-change` — load-bearing — move: **adapt**. Feedback re-orders the roadmap and edits the spec.
  - `short-cycles` — load-bearing — move: **the whole loop**. One thin rung per turn keeps the cycle short.
  - `inspect-and-adapt` — load-bearing — move: **demo → review → feedback**. Build, inspect, adapt the plan.
  - `working-agreement` — load-bearing — move: **sharpen**. The Operator sharpens intent into the spec.
  - `estimation-poker` — ceremony — move: none. A consensus-estimation ritual a one-agent pair does not need.
  - `velocity-charts` — ceremony — move: none. Throughput metrics for a multi-person team, not one agent.
  - `daily-standup` — ceremony — move: none. A team sync; the loop's review is the standing checkpoint.
- **Pure functions:**
  - `kindOf(k) -> "load-bearing" | "ceremony"`
  - `moveOf(k) -> string` (the loop move, or "none")
  - `countKept() -> int` / `countDropped() -> int` over the dataset.
  - `readoutFor(k) -> string`.
- **Sample readout:** `respond-to-change — load-bearing. Drives the loop move: adapt. 5 of 8 principles are
  load-bearing; this one survives because feedback re-orders the roadmap and edits the spec between rungs.`

## Bridge (principle → Portal practice)

- **idea:** Keep only the principles that drive a move; drop the ceremony that does not.
- **Portal:** The F6 roadmap runs `sharpen → build → ship → demo → review → feedback → adapt` per rung — five
  load-bearing principles, each a named move; the team rituals are dropped for a one-agent / one-reviewer pair.
- **take:** Agile distilled is the handful of principles that name a move in the loop — everything else is ceremony.

## Sources

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

## Related (resolving only)

`/course/agile-agent-workflow/roadmap`, `/course/agile-agent-workflow/why`, `/course/agile-agent-workflow/why/loop`,
`/course/agile-agent-workflow/decomposition`, `/course/agile-agent-workflow/roadmap/the-roadmap-layer`,
`/elixir/phoenix`, `/elixir/course`.
