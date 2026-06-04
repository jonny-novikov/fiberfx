# A1.05.1 · The closure — "done" is a closed set, not a feeling

- **Route:** `/course/agile-agent-workflow/why/correct/the-closure`
- **File:** `html/agile-agent-workflow/why/correct/the-closure.html`
- **Chapter / module:** A1 · Why → A1.05 · Correct by definition · dive 1
- **Accent:** elixir-purple.

## Lead

"Done" is the most overloaded word on a project. It can mean *the code exists*, *it ran once on my machine*, *it
looks finished*, or *I signed it off*. In this workflow it means exactly one thing: **the rung's closure is
complete**. A closure is a finite, named set of acceptance checks; the rung is done when the set is closed — every
member has executed and passed, and nothing is outstanding.

That word *closed* carries the weight. A set is closed when there is nothing left to add and nothing left
unresolved: every check is in the set on purpose, and every check is green. "Looks done" is a statement about
appearance; "closure complete" is a statement about a set you can enumerate and re-run. The first is a feeling; the
second is a fact a machine can confirm.

## Precise definition

- **Closure (of a rung)** — the finite set of acceptance checks that, all green, mean the rung is correct. It is
  defined up front (from the spec, A1.04.2) and frozen for that rung.
- **Closed** — the set is closed when every member has executed and passed and no member is outstanding. One
  outstanding member ⇒ not closed ⇒ not done.
- **Outstanding** — a check in the set that has not yet passed (never run, or run and failed). Done is the absence
  of any outstanding check, not a high pass-count.

The trap the dive names: **a majority is not a closure.** Four of five green is not "mostly done"; it is *not
done*, because the one outstanding check is the part most likely to be the sad path everyone wanted to skip.

## Worked Portal example

The canonical ladder rung "enrol in a course." Its closure is five acceptance checks (the same fixed set the hub
meter uses):

- C1 browse → the catalogue lists courses
- C2 enrol → an enrolment is recorded
- C3 enrol twice → no duplicate (the idempotent sad path)
- C4 open a lesson → its content is returned
- C5 progress → it advances and persists

The code can compile, C1, C2, C4 and C5 can be green, and the rung is still **not done** while C3 is outstanding —
because "enrol twice creates no duplicate" is precisely the invariant a learner hits in the wild. The closure is
closed only when C3 is proven too.

## Interactive 1 (hero figure) — the closure ring

A ring of the five checks for "enrol in a course." Toggle each between *proven* (filled, sage) and *outstanding*
(hollow, burgundy). The ring closes — a continuous gold arc — only when all five are proven; one outstanding check
breaks the arc. The readout states the count and the verdict.

- Fixed dataset: the five checks C1–C5 above.
- Pure function: `ringVerdict(states) -> {proven, total, closed}` with `closed = states.every(proven)`.
- Readout (all proven): `closure 5/5 · the ring is CLOSED — the rung is done`
- Readout (C3 outstanding): `closure 4/5 · OPEN — C3 (enrol twice → no duplicate) is outstanding; not done`

## Interactive 2 (main content) — majority is not a closure

A small bar that contrasts "pass-count" thinking with "closure" thinking. A slider sets how many of the five checks
are green (0–5); a fixed toggle marks whether the one sad-path check (C3) is among them. The readout shows that
*only* 5/5 reads DONE — every intermediate count, however high, reads NOT done — and calls out that a 4/5 with C3
missing is the common false "done."

- Fixed dataset: total = 5, the sad-path check is C3.
- Pure functions: `doneByCount(green, total) -> green === total`; `verdictLabel(green, total, sadGreen)`.
- Readout (4/5, C3 missing): `4/5 green · NOT done — the missing one is C3, the sad path. A majority is not a
  closure.`
- Readout (5/5): `5/5 green · DONE — the set is closed.`

## Principle ↔ practice bridge

- **Principle:** done is a closed set of executed, passing checks — defined up front, complete only when every
  member is green; a majority is not a closure.
- **On the Portal:** the "enrol" rung is done only when all five acceptance checks — including "enrol twice → no
  duplicate" — have executed green; four of five leaves the rung not done.
- **Take:** a rung is done when its closure is complete — every check in the set executed and green, nothing
  outstanding — not when it looks done.

## References — Sources (real, vetted)

- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ —
  "done" as the customer's acceptance tests passing, not a developer's opinion.
- Specification by Example → https://gojko.net/books/specification-by-example/ — the set of agreed examples as the
  living definition of done.
- Continuous Delivery → https://continuousdelivery.com/ — "done means released," held by an automated pipeline.

## Related in this course

- `/course/agile-agent-workflow/why/correct` — the A1.05 hub.
- `/course/agile-agent-workflow/why/correct/proven-not-asserted` — the next dive (proven vs asserted).
- `/course/agile-agent-workflow/decomposition/acceptance` — A2.04, the Given/When/Then checks that form the closure.
- `/course/agile-agent-workflow/why/failure-modes` — A1.01, provable completion of a thin slice.
- `/course/agile-agent-workflow/why` — the chapter.

## Pager

- prev → `/course/agile-agent-workflow/why/correct` (hub)
- next → `/course/agile-agent-workflow/why/correct/proven-not-asserted`
