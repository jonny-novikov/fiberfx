# A1.05 · Correct by definition — module hub

- **Route:** `/course/agile-agent-workflow/why/correct`
- **File:** `html/agile-agent-workflow/why/correct/index.html`
- **Chapter:** A1 · Why an Agile Agent Workflow
- **Accent:** elixir-purple (`--elixir-bright`) for the accent word; the course signature.

## Lead

A1.01 named the unit a rung should be; A1.02 named the principles that keep it ownable; A1.03 gave the loop its
motion; A1.04 split the two planning layers. This module fixes the last open word: **done**. In this workflow
"done" is not a feeling and not a sign-off — it is a **closure over traced, executed checks**. A rung is done when
its closure is complete: every deliverable realized by a story, every story accepted, every invariant proven —
nothing outstanding, nothing merely "looks done."

The phrase the module argues: **correct by definition**. The definition of done *is* the set of passing checks, not
a separate judgement laid on top of the work. When every check in the set has run and passed, the rung is correct
because that is what correct was defined to mean.

## Precise definition

- **Closure** — a finite, named set of acceptance checks for a rung. The rung is done when the set is closed:
  every member has executed and passed, and no member is outstanding.
- **Proven** — a check that ran and passed (executed, green). The opposite is **asserted** — a check someone says
  passes, without execution behind it.
- **Trace** — the spine that connects a deliverable to its proof: requirement → user story → acceptance check →
  execution. Every deliverable is reachable from a passing check, and every passing check traces back to a
  requirement.
- **Quality gate** — a mechanical check that holds the closure: it runs without human judgement and returns
  pass/fail, so "A+" becomes a repeatable result rather than an opinion.

## The framing interactive (hub) — the closure meter

A fixed rung (Portal "enrol in a course") with five acceptance checks. The control toggles each check
proven/outstanding; the meter computes whether the closure is complete. The readout states the count and the
verdict: done only when all five are proven. Teaches that "done" is the *whole* set, not a majority — one
outstanding check leaves the rung not done.

Fixed dataset (the rung's closure):
- C1 browse the catalogue lists courses
- C2 enrol records an enrolment
- C3 enrol twice creates no duplicate (the idempotent sad path)
- C4 open a lesson returns its content
- C5 progress advances and persists

Pure function: `closureVerdict(states) -> {proven, total, done}` where `done = (proven === total)`.

Readout (all proven): `closure 5/5 proven · the rung is DONE — every check executed and green`
Readout (one outstanding): `closure 4/5 proven · NOT done — C3 (enrol twice → no duplicate) is outstanding`

## The three dives (the `.mods` grid)

The arc *what done is → how it is established → what holds it*:

1. **A1.05.1 · `the-closure`** — "done" is a closed set, not a feeling. Every acceptance criterion executed and
   green, every invariant proven; a rung is done when its closure is complete.
2. **A1.05.2 · `proven-not-asserted`** — proven (the check ran and passed) vs asserted (someone says so). The
   traceability spine. "Correct by definition" = the definition of done *is* the set of passing checks.
3. **A1.05.3 · `gates`** — the mechanical quality gates that hold the closure and make "A+" repeatable. The course
   practises this with the `cms` ten gates; the Portal practises it with its harness/CI.

## References — Sources (real, vetted)

- Continuous Delivery → https://continuousdelivery.com/ — the deployment pipeline as a chain of automated gates.
- Specification by Example → https://gojko.net/books/specification-by-example/ — executable specifications as the
  shared, living definition of done.
- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ —
  the customer's acceptance tests as the definition of done.

## Related in this course

- `/course/agile-agent-workflow/why` — A1 chapter.
- `/course/agile-agent-workflow/why/two-layers` — A1.04, the spec as the single source of truth the checks derive
  from.
- `/course/agile-agent-workflow/why/failure-modes` — A1.01, provable completion of a thin slice.
- `/course/agile-agent-workflow/decomposition/acceptance` — A2.04, the Given/When/Then checks that prove "done".

## Pager

- prev → `/course/agile-agent-workflow/why` (A1 landing)
- next → `/course/agile-agent-workflow/why/correct/the-closure` (the first dive)

## Wiring

Hub `.hero` (single column, full-width framing figure below — the loop-hub pattern). One framing interactive (the
closure meter). `.mods` grid of three real subpage routes. References + 3-column footer + stamp verbatim.
