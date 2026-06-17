# A2.04.1 · The scenario structure: Given / When / Then

- **Route:** `/course/agile-agent-workflow/decomposition/acceptance/given-when-then`
- **File:** `html/agile-agent-workflow/decomposition/acceptance/given-when-then.html`
- **Kind:** deep-dive lesson (A2.04 · Acceptance, dive 1)
- **Accent:** gold

## Lead

A scenario has three clauses. **Given** fixes the context — the state of the world before
anything happens. **When** is the single action under test. **Then** is the observable
outcome that must hold after. One behaviour, one scenario; concrete values, never
abstractions.

## The precise definition

Gherkin names three keywords:

- **Given** — the precondition. What is true before the action. It sets up the world.
- **When** — the event. The one thing the actor does. Exactly one action per scenario.
- **Then** — the postcondition. The observable result the scenario asserts.

A scenario isolates **one behaviour**. If a `When` describes two actions, or a `Then`
asserts two unrelated outcomes, it is two scenarios wearing one title. The values are
concrete: "a learner not enrolled" and "enrolled exactly once", not "valid input" and
"correct state". A reader checks a concrete example; nobody can check "correct".

## The worked Portal example

The enrol rung's happy-path scenario:

```
Scenario: a learner enrols in a course
  Given a learner who is not enrolled in "Functional Programming"
  When the learner enrols in "Functional Programming"
  Then the learner appears in their enrolments exactly once
```

One Given (the precondition), one When (the action), one Then (the observable). The id
authority is `Portal.ID` — `Portal.ID.generate/1` mints the enrolment id; nothing else
about the engine is asserted here.

## Hero interactive — assemble the scenario

**Slot the clauses.** A `.solid-select` chooses which clause to read — Given, When, or Then
— for the enrol scenario. The figure highlights that clause's panel, and the readout names
what the clause fixes (context · action · outcome). This frames the structure: three clauses,
each with one job.

- control ids: `#gwtWhich` (buttons `given|when|then`)
- pure signature: `clauseOf(k) -> {node, role, text}`
- sample readout: `Given · the precondition · a learner who is not enrolled — the state of the world before the action`

## Main interactive — one behaviour per scenario (the counterexample)

**Count the actions.** A `.solid-select` switches between a **well-formed** scenario (one
When, one Then) and an **overloaded** draft that crams two actions into one When. A pure
function `shape(draft)` counts actions and outcomes and reports whether the draft is one
scenario or two. The overloaded draft is labelled in burgundy — the counterexample shows the
boundary of the concept: a scenario that tests two things tests neither cleanly.

- control ids: `#gwtShape` (buttons `single|double`)
- pure signature: `shape(draft) -> {actions, outcomes, ok, verdict}`
- sample readouts:
  - single → `1 action · 1 outcome · one behaviour — a well-formed scenario`
  - double → `2 actions · 2 outcomes · two behaviours in one — split into two scenarios` (burgundy)

## Bridge

- **Principle:** state a behaviour as Given (context) / When (one action) / Then (observable
  outcome), with concrete values — one scenario per behaviour.
- **On the Portal:** the enrol rung's behaviour is one scenario — Given a learner not
  enrolled, When they enrol, Then they appear in their enrolments exactly once.

## Recap

Three clauses, one behaviour, concrete values. Given sets the world, When fires one action,
Then asserts one observable outcome. Two actions or two outcomes mean two scenarios. The next
dive shows that these concrete examples are not documentation about the spec — they ARE the
shared definition of done.

## References

Sources:

- Gherkin reference → https://cucumber.io/docs/gherkin/reference/
- Specification by Example → https://gojko.net/books/specification-by-example/
- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied

Related (built routes only):

- `/course/agile-agent-workflow/decomposition/acceptance` — the module hub
- `/course/agile-agent-workflow/decomposition/connextra` — A2.02 (the Confirmation)
- `/course/agile-agent-workflow/why/two-layers` — A1.04 (the spec)
- `/course/agile-agent-workflow/decomposition` — the chapter

## Wiring

- pager: prev `…/acceptance` (hub) · next `…/acceptance/examples-as-spec`
