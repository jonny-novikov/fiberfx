# A4.1 · Specification by Example — module hub

> Source of record for the module hub `html/agile-agent-workflow/spec/by-example/index.html`.
> Route: `/course/agile-agent-workflow/spec/by-example`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Models copied verbatim: `why/two-layers/index.html` (hub), `roadmap/roadmap-anatomy/what-it-carries.html` (`pre.code` idiom).

## Lead

A roadmap orders the work; a spec defines it. The first question the spec layer answers is *how to write a
requirement that cannot be misread*. The answer this module argues, from Specification by Example: replace the
abstract requirement with **worked examples**, and let the examples double as the executable check. The worked
exemplar is the Portal's first web rung, **F6.1** — its `Portal.courses_of/1` evaluated over three concrete cases
(a known enrolled user, an unknown user that renders the empty state as a `200`, and a user with no enrollments).

## Precise definition

- **Specification by example** — concrete, worked examples are the specification. An abstract requirement ("handle
  bad input") admits many readings; a worked example ("an unknown user id renders the empty state, a 200") pins one.
- **Living documentation** — because the examples are the checks the build runs against, the documentation cannot
  drift from the system: a change that breaks an example breaks a check.
- **Removing ambiguity** — the examples are chosen to collapse the readings of a requirement from many to one,
  before a line of code is written.

`Portal.courses_of/1` returns the courses a given user is enrolled in. (Named only at the spec level — no source.)

## Framing interactive (hub) — abstract requirement vs worked examples

A `.solid-select` chooses one of three views over a fixed dataset:
- **abstract** — the requirement "the page must handle a bad user id" with three divergent readings (404, a crash,
  an empty page). The readout reports three open readings.
- **examples** — F6.1's three worked examples (known user → courses; unknown user → empty state, 200; no
  enrollments → empty state). The readout reports the readings collapsed to one.
- **both** — side by side: many readings narrow to one.

Pure functions over `VIEWS`/`READINGS`: `openReadings(view)` → count, `readoutFor(view)` → string. Live
`#byHubOut` (`aria-live`). SVG: an "abstract" column with three branching arrows vs an "examples" column with one.
Static default: `examples` lit, readout reads "one reading".

## The `.mods` grid — the three dives

- **A4.1.1 — Examples as specification** (`examples-as-spec`) — concrete examples *are* the spec; the harness reads
  from them.
- **A4.1.2 — Living documentation** (`living-documentation`) — because the examples are the checks, the docs cannot
  drift.
- **A4.1.3 — Removing ambiguity** (`removing-ambiguity`) — examples collapse a requirement's readings from many to
  one.

## The bridge

- **Principle** — replace an abstract requirement with worked examples; the examples are the specification, and
  they double as the executable check.
- **Portal practice** — F6.1's spec defines the course page by three worked `courses_of/1` examples; each example
  is a Given/When/Then that the acceptance check runs.

## References

Sources (real, vetted): Specification by Example (`gojko.net`), User Stories Applied (`mountaingoatsoftware.com`),
Gherkin reference (`cucumber.io`). Related: `/spec`, `/decomposition/acceptance`, `/what/four-artifacts`,
`/elixir/phoenix`, and the three dives.

## Pager

prev = `/course/agile-agent-workflow/spec`; next = `/course/agile-agent-workflow/spec/by-example/examples-as-spec`.
