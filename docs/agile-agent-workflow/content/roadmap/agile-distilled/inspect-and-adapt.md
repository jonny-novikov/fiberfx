# A3.1.2 · Inspect and adapt — dive (md source of record)

- **Route:** `/course/agile-agent-workflow/roadmap/agile-distilled/inspect-and-adapt`
- **Pager:** prev `…/agile-distilled/the-values` · next `…/agile-distilled/keep-vs-ceremony`.

## Lead

Under every Agile practice is one engine: build a thing, inspect it, adapt the plan. Strip the ceremony and the engine
remains — it is what the Author/Operator loop runs every rung. The half of the loop after `ship` is exactly
inspect-and-adapt: `demo → review → feedback → adapt`. And what adapts is the spec, not the demo.

## Definition

**Inspect and adapt** is the empirical core of Agile: at the end of an increment, examine what the increment revealed,
then change the plan in response — rather than commit to a plan up front and follow it through. The unit inspected is a
shipped, running increment; the thing adapted is the plan, not the increment that was just demoed.

## Hero interactive — the inspect-and-adapt cycle, mapped to loop stages

- **Intent:** frame the cycle as the loop's second half.
- **Control ids:** `iaSel` (`.solid-select`, `data-k` = cycle phase: build / inspect / adapt); SVG arc nodes
  `ia-arc-<k>`.
- **Readout id:** `iaOut`.
- **Fixed dataset `CYCLE`:** `{k, phase, loopStages, what}`.
  - `build` — build — loop: `sharpen → build → ship` — what: a thin rung becomes running software.
  - `inspect` — inspect — loop: `demo → review` — what: the Operator demos and reviews what shipped.
  - `adapt` — adapt — loop: `feedback → adapt` — what: feedback edits the spec; the roadmap re-orders.
- **Pure functions:** `stagesOf(k)`, `readoutFor(k)`.
- **Sample readout:** `inspect — the loop's demo → review. The Operator runs the shipped rung and judges it against
  the spec; nothing is adapted yet — inspection only reveals.`

## Main interactive — what is inspected, and what adapts (feedback edits the spec)

- **Intent:** prove the consequence — feedback adapts the spec (the single source of truth), never the demo or the code
  in isolation.
- **Control ids:** `tgSel` (`.solid-select`, `data-k` = a candidate target: spec / demo / code / roadmap-order); SVG
  target nodes `tg-node-<k>`.
- **Readout id:** `tgOut`.
- **Fixed dataset `TARGETS`:** `{k, label, adapts: bool, why}`.
  - `spec` — the spec — adapts: **yes** — the single source of truth; feedback lands here, and everything downstream
    regenerates.
  - `roadmap-order` — the roadmap order — adapts: **yes** — re-ordered between rungs as priorities move.
  - `demo` — the demo — adapts: **no** — the demo is read, not written; it is evidence, not a target.
  - `code` — the code in isolation — adapts: **no** — patching code without the spec forks it from the source of truth.
- **Pure functions:** `adaptsTarget(k) -> bool`, `countAdaptable()`, `readoutFor(k)`.
- **Sample readout:** `the spec — feedback adapts this. It is the single source of truth; the story, the brief, the
  code, and the tests are regenerated from it. 2 of 4 candidates are valid adapt targets.`

## Bridge

- **idea:** Inspect a shipped increment; adapt the plan, not the increment.
- **Portal:** On F6, `demo → review → feedback → adapt` runs after every rung ships; feedback edits the rung's spec,
  and the roadmap re-orders — the engine, code, and supervision tree under the `Portal` facade never change to suit it.
- **take:** Inspect-and-adapt is the loop's second half: build reveals, inspection judges, and the spec is what adapts.

## Sources

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
