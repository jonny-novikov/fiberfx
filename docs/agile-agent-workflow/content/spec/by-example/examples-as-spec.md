# A4.1.1 · Examples as specification — dive

> Source of record for `html/agile-agent-workflow/spec/by-example/examples-as-spec.html`.
> Route: `/course/agile-agent-workflow/spec/by-example/examples-as-spec`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `why/two-layers/spec.html` (lesson, hero-split).

## Lead

The first move of Specification by Example: the concrete examples are not an illustration of the spec — they *are*
the spec. Where an abstract requirement says "handle bad input" and leaves the reader to guess, a worked example
fixes one reading and the build is held to it. The exemplar is F6.1: its course page is defined by three worked
`courses_of/1` examples, and the acceptance harness reads its checks straight from them.

## Precise definition

- **An example as specification** — a single, concrete case stated as Given/When/Then. It pins exactly one
  behaviour, so there is nothing left to interpret.
- **The harness reads from the examples** — the acceptance check for the rung is the set of examples evaluated. No
  example, no check; no check, no proof.
- **Worked example set (F6.1, verbatim grounding)** — `Portal.courses_of/1` over three cases:
  1. a known user id with enrollments → the page renders that user's courses;
  2. a known user id with no enrollments → the page renders an empty state (not an error);
  3. an unknown or malformed user id → the page renders the empty state, a clean `200`, never a `500`.

## Hero interactive — abstract requirement collapses to one example

A `.solid-select` over a fixed `READINGS` dataset. View `abstract`: the requirement "the page must handle a bad
user id" with three divergent readings (return a 404; raise; render an empty page). View `example`: F6.1-US5's
worked example "an unknown id renders the empty state — a clean 200". Pure `openReadings(view)` and
`heroReadout(view)`; live `#esHeroOut`. SVG: three forked arrows (abstract) vs one arrow (example). The readout
shows the count fall from three to one. Static default: `example` lit, "one reading".

## Main interactive — pick an example, read the check it becomes

A `.solid-select` over `EXAMPLES` (the three F6.1 cases). Selecting one renders its Given/When/Then in the SVG and
reports, in `#esMainOut`, the deliverable/story it realizes (D3/D4/D5 · US2, and US5 for the unknown-id case) and
that "the example is the executable check". Pure `checkFor(i)`. This teaches a *different* move from the hero: the
hero collapses many readings to one; the main shows that one example IS the acceptance check, traced to a story.

## The `pre.code` block (NO CODE — markdown fragment only)

A `.stories.md` fragment of F6.1-US2's acceptance, rendered with `.cmt`/`.str`/`.res` spans:
the three Given/When/Then lines for the known-with-enrollments, known-with-none, and unknown-id cases, plus the
Coverage cells `D3→US2 · D4→US2 · D5→US2`. No `def`, no `defmodule`, no Elixir.

## The bridge

- **Principle** — write the spec as worked examples; the examples are the specification and the executable check.
- **Portal practice** — F6.1's course page is defined by three `courses_of/1` examples; the harness runs them as
  the rung's acceptance.

## References

Sources: Specification by Example (`gojko.net`), Gherkin reference (`cucumber.io`), User Stories Applied
(`mountaingoatsoftware.com`). Related: hub `/spec/by-example`, `/spec`, `/decomposition/acceptance`,
`/what/four-artifacts`, `/elixir/phoenix`.

## Pager

prev = hub `/spec/by-example`; next = `/spec/by-example/living-documentation`.
