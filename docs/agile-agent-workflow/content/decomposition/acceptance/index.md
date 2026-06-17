# A2.04 · Acceptance criteria with Given/When/Then

- **Route:** `/course/agile-agent-workflow/decomposition/acceptance`
- **File:** `html/agile-agent-workflow/decomposition/acceptance/index.html`
- **Kind:** module hub (A2 · Decomposition)
- **Accent:** gold (the chapter accent; the executable definition of done)

## Lead

A story's Confirmation (A2.02) earns a precise form: a **Gherkin scenario** written
**Given / When / Then**. The scenario is the shared, executable **definition of done** —
one artifact that product, the Operator, and the Author all read the same way. It states a
behaviour in concrete terms, so "done" is a fact to check rather than an opinion to argue.

## What this module lands

A behaviour-driven example sits between intent and test. It is concrete enough that a human
reads it as a promise and a test runner reads it as a check. The three dives build it:

1. **A2.04.1 · `given-when-then`** — the scenario structure. **Given** sets the context,
   **When** is the single action, **Then** is the observable outcome. One scenario per
   behaviour; concrete values, not abstractions.
2. **A2.04.2 · `examples-as-spec`** — the concrete examples ARE the shared definition of
   done. The Confirmation of the three Cs becomes a scenario; the one artifact product, the
   Operator, and the Author all read.
3. **A2.04.3 · `scenarios-to-tests`** — happy and sad paths. Each scenario becomes an
   acceptance test the Author implements against and the Operator accepts against. This
   foreshadows the A4 spec layer and its harness (named, not re-taught).

## Framing interactive (the hub)

**Build a scenario from a Confirmation.** A `.solid-select` chooses one Portal behaviour
from the value ladder (enrol · browse · open a lesson · track progress). The figure renders
that behaviour's Given/When/Then scenario, and the readout names the three clauses. A pure
function `scenarioFor(behaviour)` returns `{given, when, then}` from a fixed dataset. This
frames the module: a story's Confirmation has a canonical, three-clause shape.

- control ids: `#acBehav` (buttons `enrol|browse|open|track`)
- pure signature: `scenarioFor(behaviour) -> {given, when, then, label}`
- sample readout: `enrol · Given a learner not enrolled · When they enrol · Then they appear in their enrolments exactly once`

## The Portal grounding (no-invent)

The canonical ladder story for the module: **enrol in a course.**

- Happy path — **Given** a learner not enrolled, **When** they enrol, **Then** they appear
  in their enrolments exactly once.
- Sad path — **Given** an already-enrolled learner, **When** they enrol again, **Then** no
  duplicate is created (idempotent).

Other ladder stories named in prose: browse the catalogue, open a lesson, track progress.
Portal API cited: only `Portal.ID.generate/1` and `Portal.ID.decode/1` (`.type`,
`.timestamp`); OTP internals belong to the companion `/elixir` course.

## Bridge

- **Principle:** write the acceptance criterion as a concrete behavioural example in
  Given/When/Then, so one artifact serves as promise and as test.
- **On the Portal:** the enrol rung's Confirmation is a scenario — Given a learner not
  enrolled, When they enrol, Then they appear once — read by product, the Operator, and the
  Author, and run as the rung's acceptance test.

## References

Sources (real, vetted — from the course-home registry):

- Gherkin reference → https://cucumber.io/docs/gherkin/reference/
- Specification by Example → https://gojko.net/books/specification-by-example/
- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied

Related in this course (built routes only):

- `/course/agile-agent-workflow/decomposition` — A2 chapter landing
- `/course/agile-agent-workflow/decomposition/connextra` — A2.02 (the Confirmation this builds on)
- `/course/agile-agent-workflow/decomposition/invest` — A2.03
- `/course/agile-agent-workflow/why/two-layers` — A1.04 (the spec layer the scenario pins to)

## Wiring

- crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.04 · Acceptance criteria
- route-tag: `/course/agile-agent-workflow` · `decomposition` · `acceptance` (current)
- pager: prev `/course/agile-agent-workflow/decomposition` · next `/course/agile-agent-workflow/decomposition/acceptance/given-when-then`
- dives grid: three `a.mod` cards (built) → given-when-then, examples-as-spec, scenarios-to-tests
