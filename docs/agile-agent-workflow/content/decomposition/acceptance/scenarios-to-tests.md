# A2.04.3 · From scenarios to acceptance tests

- **Route:** `/course/agile-agent-workflow/decomposition/acceptance/scenarios-to-tests`
- **File:** `html/agile-agent-workflow/decomposition/acceptance/scenarios-to-tests.html`
- **Kind:** deep-dive lesson (A2.04 · Acceptance, dive 3)
- **Accent:** gold

## Lead

A behaviour has a **happy path** and **sad paths**. Each scenario becomes an acceptance
test: the Author implements against it, the Operator accepts against it. The set of scenarios
for a rung is its definition of done — and the seed of the A4 spec layer and its harness.

## The precise definition

- **Happy path** — the behaviour when everything is in order. The enrol that succeeds.
- **Sad path** — a defined, expected deviation that the behaviour must still handle. A second
  enrol that must not duplicate; an enrol in a course that does not exist.

A rung is not done when the happy path passes. It is done when the happy path passes **and**
the sad paths hold. Each scenario maps to one acceptance test:

- The **Author** implements *against* it — the scenario is the precise behaviour to satisfy.
- The **Operator** accepts *against* it — the scenario is the check that says the rung is done.

The same scenarios that were the shared spec (A2.04.2) are now executable acceptance tests.
This is where the **A4 spec layer** and its harness take over: A4 turns the scenario set into
a runnable specification with a harness that executes it on every change. (Named here, taught
there.)

## The worked Portal example

The enrol rung's acceptance set — one happy, one sad:

```
# Happy path
Scenario: a learner enrols
  Given a learner not enrolled in "Functional Programming"
  When the learner enrols in "Functional Programming"
  Then the learner appears in their enrolments exactly once

# Sad path (idempotent)
Scenario: enrolling twice
  Given a learner already enrolled in "Functional Programming"
  When the learner enrols in "Functional Programming" again
  Then no duplicate is created — the learner appears exactly once
```

As an acceptance test the Author implements against:

```
id = Portal.ID.generate(:enrolment)         # one enrolment id
assert count_enrolments(learner, course) == 1   # happy path holds
# enrol again …
assert count_enrolments(learner, course) == 1   # sad path holds — idempotent
```

`Portal.ID.generate/1` is the only engine surface asserted; the rest of the OTP machinery is
the companion `/elixir` course's territory.

## Hero interactive — happy and sad paths

**Run the acceptance set.** A `.solid-select` chooses a path — the happy enrol or the sad
double-enrol. The figure renders that scenario and a pure check computes the resulting
enrolment count from a fixed dataset; the readout reports the count and whether the path holds
(exactly one in both cases). This frames the lesson: done means happy AND sad pass.

- control ids: `#sttPath` (buttons `happy|sad`)
- pure signature: `enrolCount(path) -> {count, holds, text}`
- sample readout: `Sad path · enrol an already-enrolled learner · count stays 1 · holds — idempotent, no duplicate created`

## Main interactive — definition of done as a closure

**Cover the rung.** Checkboxes (rendered as a `.solid-select` multi-state, or a small toggle
set) let the reader include or omit the sad path from the acceptance set. A pure function
`done(set)` reports whether the rung's definition of done is complete: happy alone is **not
done** (the sad path can still duplicate); happy plus sad is **done**. Omitting the sad path
is labelled in burgundy — the counterexample: a green happy path with an unguarded sad path is
a rung that passes its test and still ships the bug.

- control ids: `#sttCover` (buttons `happy|sad` as include-toggles, both selectable)
- pure signature: `done(included) -> {covered, total, complete, gap, verdict}`
- sample readouts:
  - happy only → `1 of 2 paths · happy passes, sad unguarded · NOT done — a second enrol can still duplicate` (burgundy)
  - happy + sad → `2 of 2 paths · happy and sad hold · done — the rung's definition of done is closed`

## Bridge

- **Principle:** a rung is done when its happy path and its sad paths both pass as acceptance
  tests — the scenario set is the definition of done.
- **On the Portal:** the enrol rung is done when both scenarios hold — the learner enrols
  once, and a second enrol does not duplicate — each run as an acceptance test the Author
  implements against and the Operator accepts against.

## Recap

Happy and sad paths, each an acceptance test, together the definition of done. The Author
implements against them; the Operator accepts against them; the same scenarios that were the
shared spec are now the checks. A4 turns this scenario set into a runnable specification with
a harness. With acceptance pinned, the chapter's later modules split stories and order the
value ladder.

## References

Sources:

- Specification by Example → https://gojko.net/books/specification-by-example/
- Gherkin reference → https://cucumber.io/docs/gherkin/reference/
- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied

Related (built routes only):

- `/course/agile-agent-workflow/decomposition/acceptance` — the module hub
- `/course/agile-agent-workflow/decomposition/invest` — A2.03
- `/course/agile-agent-workflow/why/two-layers` — A1.04 (the spec layer A4 builds on)
- `/course/agile-agent-workflow/decomposition` — the chapter

## Wiring

- pager: prev `…/acceptance/examples-as-spec` · next `…/acceptance` (back to hub)
