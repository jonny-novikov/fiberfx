# A3.1.1 · The values — dive (md source of record)

- **Route:** `/course/agile-agent-workflow/roadmap/agile-distilled/the-values`
- **Pager:** prev `…/agile-distilled` · next `…/agile-distilled/inspect-and-adapt`.

## Lead

The Agile Manifesto is four value preferences: each names a thing valued *more* and a thing valued *less*. Two of the
four are the engine of the Author/Operator loop; the others matter but are not what makes the loop turn. This dive
takes each preference and reads off the loop move it becomes on the Portal.

## Definition

An **Agile value** is a stated preference — "X over Y" — that biases a decision under uncertainty. It is not a rule; it
is a tie-breaker. The loop is built on two of them: **working software over comprehensive documentation** (each rung
ships running software) and **responding to change over following a plan** (feedback re-orders the roadmap).

## Hero interactive — which value the loop relies on

- **Intent:** frame the four values, lit by how load-bearing each is for the loop.
- **Control ids:** `valSel` (`.solid-select`, `data-k`); SVG bars `val-bar-<k>`.
- **Readout id:** `valOut`.
- **Fixed dataset `VALUES`:** `{k, over, under, weight: "load-bearing"|"supporting", move}`.
  - `software` — working software / comprehensive documentation — load-bearing — move: **ship**.
  - `change` — responding to change / following a plan — load-bearing — move: **adapt**.
  - `collaboration` — customer collaboration / contract negotiation — supporting — move: **sharpen** (the Operator
    sharpens intent with the Author each turn).
  - `individuals` — individuals and interactions / processes and tools — supporting — move: **review** (the human
    judges; the tools assist).
- **Pure functions:** `weightOf(k)`, `moveOf(k)`, `readoutFor(k)`.
- **Sample readout:** `change — responding to change over following a plan. Load-bearing for the loop. Becomes the
  move: adapt — feedback re-orders the roadmap between rungs.`

## Main interactive — each value as a loop move

- **Intent:** prove the consequence — preference X over Y maps to a specific stage the loop runs.
- **Control ids:** `mvSel` (`.solid-select`, `data-k` = stage); SVG loop-stage nodes `mv-stage-<k>`.
- **Readout id:** `mvOut`.
- **Fixed dataset `MOVES`:** the value → stage map, read in the other direction (stage → which value it honours).
  - `ship` ← working software · `adapt` ← responding to change · `sharpen` ← customer collaboration ·
    `review` ← individuals and interactions. (`build`, `demo`, `feedback` are loop stages the values support jointly.)
- **Pure functions:** `valueAt(stage)`, `readoutForStage(stage)`.
- **Sample readout:** `Stage: ship. Honours the value "working software over comprehensive documentation" — the rung
  delivers running software, not a document about it.`

## Bridge

- **idea:** Prefer working software and responding to change; the rest are tie-breakers.
- **Portal:** On F6 each rung *ships* running web surface (working software) and the roadmap is *re-ordered* by
  feedback (responding to change) — the two load-bearing values made concrete as the loop's `ship` and `adapt`.
- **take:** Two of the four Agile values run the loop; the other two steady the hands that run it.

## Sources

- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
