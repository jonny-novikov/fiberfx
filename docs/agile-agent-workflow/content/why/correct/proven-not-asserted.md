# A1.05.2 · Proven, not asserted — the definition of done is the set of passing checks

- **Route:** `/course/agile-agent-workflow/why/correct/proven-not-asserted`
- **File:** `html/agile-agent-workflow/why/correct/proven-not-asserted.html`
- **Chapter / module:** A1 · Why → A1.05 · Correct by definition · dive 2
- **Accent:** elixir-purple.

## Lead

Two statements can use the same words and mean opposite things. "Enrol twice creates no duplicate" can be an
**assertion** — someone says it holds — or a **proof** — a check ran with an already-enrolled learner and returned
no duplicate. The closure (A1.05.1) is made of the second kind only. A check that was asserted but never executed
is not a member of the closure; it is a claim.

"Correct by definition" follows directly: the definition of done *is* the set of passing checks. Correctness is not
a separate judgement laid on top of the work and then argued about — it is the property of having every check in
the set execute and pass. Change the set, and you change what done means; run the set, and you learn whether it is
done. Nothing else is consulted.

## Precise definition

- **Proven** — a check that executed and passed. It has a run behind it: real inputs, the real operation, an
  observed green result.
- **Asserted** — a claim that a check passes, with no execution behind it. It may be true; it is not yet a member
  of the closure.
- **Trace** — the spine that makes a proof reachable: requirement → user story → acceptance check → execution.
  Every deliverable is reachable from a passing check; every passing check traces back to a requirement. A gap in
  the trace is a deliverable nobody proved or a check that proves nothing required.
- **Correct by definition** — done is defined *as* the set of passing checks; there is no second, separate verdict.

## Worked Portal example

Rung "enrol in a course," the idempotent sad path. The spec (A1.04.2) states the invariant: an already-enrolled
learner who enrols again produces no duplicate. The trace runs:

- requirement: a learner is enrolled at most once per course
- → user story: "as a learner I enrol in a course" (A2.02 form)
- → acceptance check (A2.04 Given/When/Then): *Given* an already-enrolled learner, *When* they enrol again, *Then*
  the enrolment count stays one
- → execution: the check runs against the real enrol path and observes count == 1

Asserted, this is a sentence in a document. Proven, it is a green check with a run behind it — and only the proven
form belongs to the closure. The Author (the Claude agent) builds to the spec; the Operator accepts against the
executed check, never against the sentence.

## Interactive 1 (hero figure) — proven vs asserted

A two-state switch on a single check (the C3 sad path). In *asserted* mode the check shows a claim with no run
behind it; in *proven* mode it shows the same check with an execution trace and a green result. The readout makes
the difference explicit: only the proven state counts toward the closure.

- Fixed dataset: the one check C3 "enrol twice → no duplicate," its trace, and a real run result (count == 1).
- Pure function: `checkStatus(mode) -> {counts, label}` where `counts = (mode === 'proven')`.
- Readout (asserted): `asserted · a claim, no run behind it — does NOT count toward the closure`
- Readout (proven): `proven · ran with an already-enrolled learner → count == 1 (green) — counts toward the
  closure`

## Interactive 2 (main content) — follow the trace

The traceability spine as four linked nodes: requirement → story → check → execution. Step a marker along the
spine; at each node the readout names what that node holds and whether the link to the next is intact. A second
control can break one link (drop the check, or drop the execution), and the readout reports the gap: a deliverable
nobody proved, or a check that proves nothing required.

- Fixed dataset: the four nodes for the C3 invariant, in order.
- Pure functions: `traceNode(i) -> {name, holds}`; `traceIntact(droppedLink) -> {intact, gap}`.
- Readout (intact, at execution): `execution · the check ran → count == 1 · trace intact: requirement → story →
  check → execution`
- Readout (check dropped): `gap · the requirement reaches no executed check — the invariant is asserted, not
  proven`

## Principle ↔ practice bridge

- **Principle:** the definition of done is the set of *passing* (executed, green) checks, joined to requirements by
  a trace — proven, never merely asserted; correctness is not a separate judgement on top.
- **On the Portal:** the "no duplicate enrolment" invariant counts only as an executed Given/When/Then that traces
  back to the requirement — a sentence in the spec that was never run is asserted, not proven.
- **Take:** correct by definition means the definition of done is the set of passing checks — proven, not asserted —
  with a trace from each requirement to its green execution.

## References — Sources (real, vetted)

- Specification by Example → https://gojko.net/books/specification-by-example/ — executable specifications: the
  examples are run, not merely written.
- Continuous Delivery → https://continuousdelivery.com/ — the pipeline proves each candidate by execution before it
  advances.
- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ —
  acceptance tests that execute, owned by the customer, as the verdict.

## Related in this course

- `/course/agile-agent-workflow/why/correct` — the A1.05 hub.
- `/course/agile-agent-workflow/why/correct/the-closure` — the previous dive (done as a closed set).
- `/course/agile-agent-workflow/why/correct/gates` — the next dive (the mechanical gates).
- `/course/agile-agent-workflow/decomposition/acceptance` — A2.04, the Given/When/Then that the trace ends in.
- `/course/agile-agent-workflow/why/two-layers` — A1.04, the spec the checks derive from.
- `/course/agile-agent-workflow/why` — the chapter.

## Pager

- prev → `/course/agile-agent-workflow/why/correct/the-closure`
- next → `/course/agile-agent-workflow/why/correct/gates`
