# A3.2.3 · Continuous feedback — `/roadmap/xp-small-batches/continuous-feedback`

- **File:** `html/agile-agent-workflow/roadmap/xp-small-batches/continuous-feedback.html`
- **Pager:** prev `…/incremental-design` · next hub `/roadmap/xp-small-batches`

## Lead

The third XP practice: feedback after every increment, not at the end. Continuous feedback closes the loop
between rungs — ship a rung, demo it, take feedback, adapt — so a wrong assumption is caught one rung deep
rather than nine. It is the practice that makes the other two pay: small releases and incremental design only
lower risk if a reviewer is in the loop at every release.

## Definition

- **continuous feedback** — a review after every rung, not one review at the end.
- **the loop** — per rung: sharpen → build → ship → demo → review → feedback → adapt (the F6 loop).
- **feedback edits the spec** — feedback changes the single source of truth; the build follows the spec, and no
  shipped page is patched in isolation.

## Worked Portal example

The F6 roadmap states the loop verbatim: "sharpen → build → ship → demo → review → feedback → adapt. Feedback
edits the spec, because the spec is the single source of truth; the build follows the spec." Each rung asks one
feedback question — F6.1 "shell and layout right?", F6.5 "layout, UX, error wording?", F6.7 "what should
propagate; count semantics?" The Operator reviews the shipped increment and returns feedback asking for the
next rung's specs or a change to a shipped one. The agent makes each round cheap by shipping one PR-sized rung
with a green harness, so feedback arrives at every release rather than at the end.

## Hero interactive — feedback rounds vs batch

Over the fixed nine-rung model, choose how many rungs ship between reviews; the SVG marks the review points on
the ladder and the readout reports feedback rounds, worst-case rework (rungs built on an unreviewed assumption),
and the per-rung feedback question for the current rung.

- Control: `#cfBatch` range 1..9.
- Pure: `roundsOf(batch, total)`, `reworkOf(batch)`, `questionAt(rung)` over the fixed F6 questions.
- Readout `#cfOut`: "Review every N rungs · M feedback rounds · worst-case rework N rungs. Rung F6.k asks: …"

## Content interactive — where feedback lands

A second figure: a wrong assumption surfaces in review; choose whether feedback edits the spec or patches the
shipped page, and the readout reports what stays the single source of truth and what drifts.

- Control: `#cfLands` segmented buttons (edit the spec / patch the page).
- Pure: `landsOn(choice)` returning {sourceOfTruth, drift}.
- Readout `#cfLandsOut`.

## Bridge

- **Principle (XP):** Continuous feedback — review every increment; let feedback change the definition, not the
  shipped artifact.
- **On the Portal (F6):** Each rung runs the loop and asks one feedback question; feedback edits the spec
  (the single source of truth), the build follows, and the next rung is planned from it.
- **Take:** Feedback after every rung catches a wrong assumption one rung deep; it edits the spec, never the
  shipped page, so the source of truth never forks.

## Sources

- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery → https://continuousdelivery.com/
- The Pragmatic Programmer → https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
