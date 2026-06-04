# A2.04.2 · Examples as the specification

- **Route:** `/course/agile-agent-workflow/decomposition/acceptance/examples-as-spec`
- **File:** `html/agile-agent-workflow/decomposition/acceptance/examples-as-spec.html`
- **Kind:** deep-dive lesson (A2.04 · Acceptance, dive 2)
- **Accent:** gold

## Lead

A concrete example is not documentation about the specification. The example IS the
specification. The Confirmation of the three Cs (A2.02), written Given/When/Then, is the one
artifact product, the Operator, and the Author all read — and the same artifact a test runner
executes.

## The precise definition

Specification by example replaces a prose requirement ("enrolment is idempotent") with a
concrete, behavioural illustration ("Given an already-enrolled learner, When they enrol again,
Then no duplicate is created"). The example is unambiguous because it is concrete: there is one
reading of "no duplicate is created", and many readings of "idempotent".

The artifact is **shared**. Three audiences read the same scenario:

- **Product** reads it as the agreed behaviour — the promise.
- **The Operator** reads it as the acceptance check — the test of done.
- **The Author** (the Claude agent) reads it as the precise behaviour to implement against.

One artifact, three readings, no translation between them. The Confirmation was already this
shape (A2.02.2 called it "a Given/When/Then skeleton"); writing it as a scenario gives it the
form everyone can read and a runner can execute.

## The worked Portal example

The enrol Confirmation, promoted to the shared spec for the rung:

```
# The Confirmation (A2.02) — now the shared definition of done for the rung.
Scenario: enrolling twice does not duplicate the enrolment
  Given a learner already enrolled in "Functional Programming"
  When the learner enrols in "Functional Programming" again
  Then the learner appears in their enrolments exactly once
```

Product agrees this is the behaviour; the Operator accepts the rung against it; the Author
builds `Portal.ID.generate(:enrolment)` and the enrol path to satisfy it. The same words
serve all three.

## Hero interactive — one artifact, three readings

**Switch the reader.** A `.solid-select` chooses the audience — product, Operator, or Author.
The figure highlights that reader against the single enrol scenario, and the readout states
how that reader uses the very same artifact (promise · acceptance check · build target). This
frames the lesson: one scenario, three readings, no translation.

- control ids: `#easWho` (buttons `product|operator|author`)
- pure signature: `readingFor(who) -> {node, role, text}`
- sample readout: `Product reads the scenario as the agreed behaviour — the promise. Same words the Operator accepts against and the Author builds to.`

## Main interactive — concrete vs abstract (the counterexample)

**Sharpen the criterion.** A `.solid-select` toggles a Confirmation between an **abstract**
prose form ("enrolment works correctly") and a **concrete** scenario form. A pure function
`ambiguity(form)` reports the number of defensible readings — many for the abstract form, one
for the concrete. The abstract form is labelled in burgundy: a criterion with several readings
is a criterion nobody can accept against, because two people will disagree about "correct".

- control ids: `#easForm` (buttons `abstract|concrete`)
- pure signature: `ambiguity(form) -> {readings, acceptable, verdict}`
- sample readouts:
  - abstract → `"enrolment works correctly" · many readings · not acceptable — whose "correct"?` (burgundy)
  - concrete → `"enrolled exactly once; a second enrol does not change the count" · one reading · acceptable`

## Bridge

- **Principle:** make the acceptance criterion a concrete example, not a prose claim — the
  example is the spec, shared by everyone and executed as the test.
- **On the Portal:** the enrol Confirmation, written Given/When/Then, is the rung's spec —
  product's promise, the Operator's acceptance check, and the Author's build target, in one
  artifact.

## Recap

The example is the specification. Written as a scenario, the Confirmation becomes one shared
artifact — promise, acceptance check, and build target — with a single reading. Abstract prose
has many readings and cannot be accepted against. The next dive turns the scenario into the
acceptance test itself: happy and sad paths, implemented against and accepted against.

## References

Sources:

- Specification by Example → https://gojko.net/books/specification-by-example/
- Gherkin reference → https://cucumber.io/docs/gherkin/reference/
- User Stories Applied → https://www.mountaingoatsoftware.com/books/user-stories-applied

Related (built routes only):

- `/course/agile-agent-workflow/decomposition/acceptance` — the module hub
- `/course/agile-agent-workflow/decomposition/connextra` — A2.02 (the three Cs)
- `/course/agile-agent-workflow/why/two-layers` — A1.04 (the spec layer)
- `/course/agile-agent-workflow/decomposition` — the chapter

## Wiring

- pager: prev `…/acceptance/given-when-then` · next `…/acceptance/scenarios-to-tests`
