# A3.2 · Extreme Programming for small batches — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/xp-small-batches`
- **File:** `html/agile-agent-workflow/roadmap/xp-small-batches/index.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Pager:** prev `/course/agile-agent-workflow/roadmap` · next `…/roadmap/xp-small-batches/small-releases`

## Lead

Extreme Programming named the practices that make a release small and safe: small releases, incremental
design, and continuous feedback. Re-cast for an Author/Operator pair, those three practices become the cadence
the workflow runs at — one rung shipped, demoed, and reviewed before the next is planned. The argument of this
module: small batches lower risk and raise learning per cycle, and a Claude agent makes a small batch cheap
enough to be the default.

## What the module teaches

XP's small-batch practices, each mapped to the Author/Operator loop and grounded on the real F6 (Phoenix) rung
cadence — nine rungs `f6.1…f6.9`, three milestones, shipped one rung at a time.

- **A3.2.1 · Small releases** — why a smaller batch lowers risk and feedback latency and raises learning per
  cycle. The principle XP made famous: release small, release often.
- **A3.2.2 · Incremental design** — the design grows one rung at a time, never up front. Each rung adds only
  the structure its slice needs, behind a stable facade.
- **A3.2.3 · Continuous feedback** — feedback after every rung, not at the end. The loop closes between rungs;
  feedback edits the spec, never the shipped page.

## The framing interactive (hub)

A **batch-size dial** over a fixed model. Shrink the batch (rungs-per-release) and the readout reports risk,
feedback-latency, and learning-per-cycle, all derived by pure functions. This is the module's whole thesis in
one control: smaller batches fall in risk and latency and rise in learning.

- Control: `#bsDial` range (1..9 rungs per release), buttons for preset sizes.
- Pure: `riskOf(batch)`, `latencyOf(batch)`, `learningOf(batch)` over the fixed F6 nine-rung model.
- Readout `#bsOut`: "Batch = N rungs per release · risk index R · feedback latency L rungs · learning per
  cycle K. …"

## Bridge

- **Principle (XP):** Small releases, incremental design, continuous feedback — keep the batch small so each
  release is cheap to ship, cheap to review, and cheap to undo.
- **On the Portal (F6):** The `phoenix.roadmap.md` is nine rungs, each a PR-sized slice shipped and demoed
  before the next; the agent turns each rung into a triad and a green harness, so the batch stays one rung.
- **Take:** Small batches are an XP idea; with an agent that ships one well-specified rung at a time, they are
  the cheap default rather than a discipline you must force.

## References (Sources — real vetted)

- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery → https://continuousdelivery.com/
- The Pragmatic Programmer → https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

## Related (resolving)

- `/course/agile-agent-workflow/roadmap`
- `/course/agile-agent-workflow/why/failure-modes`
- `/course/agile-agent-workflow/why/loop`
- `/course/agile-agent-workflow/decomposition/workshop`
- `/course/agile-agent-workflow/roadmap/the-road-ahead`
- `/elixir/phoenix` · `/elixir/course`
