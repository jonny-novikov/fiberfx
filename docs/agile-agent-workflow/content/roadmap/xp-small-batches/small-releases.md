# A3.2.1 · Small releases — `/roadmap/xp-small-batches/small-releases`

- **File:** `html/agile-agent-workflow/roadmap/xp-small-batches/small-releases.html`
- **Pager:** prev hub `/roadmap/xp-small-batches` · next `…/incremental-design`

## Lead

The first XP practice: release small, release often. A small release is one whose batch — the amount of work
between two reviews — is as close to a single increment as the work allows. Smaller batches lower the cost of a
mistake (less to undo), shorten feedback latency (a review sooner), and raise learning per cycle (more reviews
for the same total work).

## Definition

- **batch** — the work shipped between two reviews. The unit XP shrinks.
- **small release** — a release whose batch is one increment (one rung): cheap to ship, cheap to review, cheap
  to undo.
- **feedback latency** — how long (measured in rungs of work) until a slice meets a reviewer. Smaller batch →
  shorter latency.

## Worked Portal example

The F6 (Phoenix) chapter is nine rungs `f6.1…f6.9`. F6 does not ship all nine at once; it ships F6.1 (the
endpoint), demos it, takes feedback, then plans F6.2. Each rung is a PR-sized increment — "a spec triad, the
slice, a green harness, a demo, a feedback note." That is a batch of one. The whole `phoenix.roadmap.md` is
written so the batch never grows past a single rung.

## Hero interactive — release plan over a batch dial

Shrink the batch (rungs-per-release) across the fixed nine-rung F6 ladder; the SVG lays out the resulting
releases and the readout reports release count, max blast radius (rungs at risk in one release), and feedback
latency.

- Control: `#srBatch` range 1..9.
- Pure: `releasesOf(batch, total)`, `latencyOf(batch)`, `blastOf(batch)`.
- Readout `#srOut`: "Batch = N · M releases across 9 rungs · feedback after every N rungs · max blast radius N
  rungs. …"

## Content interactive — risk vs learning curve

A second figure over the same model: select a batch size and the readout reports the **risk index** and
**learning-per-cycle** as a trade-off, proving they move in opposite directions as the batch shrinks.

- Control: `#srTrade` segmented buttons (batch 1 / 3 / 9).
- Pure: `riskOf(batch)`, `learningOf(batch)`.
- Readout `#srTradeOut`.

## Bridge

- **Principle (XP):** Small releases — ship the smallest increment that is worth reviewing, and ship it often.
- **On the Portal (F6):** F6.1 ships and is demoed before F6.2 is planned; every rung is a batch of one,
  PR-sized, behind the unchanged `Portal` facade.
- **Take:** A small release is a batch of one; the F6 ladder is nine of them, each shipped and reviewed before
  the next.

## Sources

- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery → https://continuousdelivery.com/
- The Pragmatic Programmer → https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
