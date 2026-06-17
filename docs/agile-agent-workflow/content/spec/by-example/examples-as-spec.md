# A4.1.1 · Examples as specification — dive

> Source of record for `html/agile-agent-workflow/spec/by-example/examples-as-spec.html`.
> Route: `/course/agile-agent-workflow/spec/by-example/examples-as-spec`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `why/two-layers/spec.html` (lesson, hero-split).
> Ground-truth note (2026-06-05 reconcile): re-grounded off the **retired route** `GET /courses/:user_id` onto the
> as-built protected `/my/courses`. The facade function `Portal.courses_of/1` is **real and as-built** — it is what
> `/my/courses` calls (via `Portal.Enrollment`); only the route name retired, not the function. Bare-filename
> citations replaced with `.specref` chips to `/spec/specimens#f6-5`.

## Lead

The first move of Specification by Example: the concrete examples are not an illustration of the spec — they *are*
the spec. Where an abstract requirement says "handle a bad request" and leaves the reader to guess, a worked example
fixes one reading and the build is held to it. The exemplar is the protected `/my/courses` page: it is defined by
three worked `Portal.Enrollment` examples, and the acceptance harness reads its checks straight from them.

## Precise definition

- **An example as specification** — a single, concrete case stated as Given/When/Then. It pins exactly one
  behaviour, so there is nothing left to interpret.
- **The harness reads from the examples** — the acceptance check for the rung is the set of examples evaluated. No
  example, no check; no check, no proof.
- **Worked example set (`/my/courses`, as-built grounding)** — `Portal.Enrollment` over three cases:
  1. a signed-in learner with enrollments → the page renders their own courses;
  2. a signed-in learner with no enrollments → the page renders an empty state (not an error);
  3. a request with no signed-in learner → it redirects — a learner never sees another's courses (the route is
     PROTECTED).

## Hero interactive — abstract requirement collapses to one example

A `.solid-select` over a fixed `READINGS` dataset. View `abstract`: the requirement "handle a request with no
signed-in learner" with three divergent readings (return a 404; raise; show another learner's courses). View
`example`: the protected `/my/courses` route — an unauthenticated request is redirected, never shown another's
courses. Pure `openReadings(view)` and `heroReadout(view)`; live `#esHeroOut`. SVG: three forked arrows (abstract)
vs one arrow (example). The readout shows the count fall from three to one. Static default: `example` lit,
"one reading".

## Main interactive — pick an example, read the check it becomes

A `.solid-select` over `EXAMPLES` (the three `/my/courses` cases: enrolled learner / no enrollments / not signed
in). Selecting one renders its Given/When/Then in the SVG and reports, in `#esMainOut`, the case it realizes and
that "the example is the executable check". Pure `checkFor(i)`. This teaches a *different* move from the hero: the
hero collapses many readings to one; the main shows that one example IS the acceptance check (one row of three).

## The `pre.code` block (NO CODE — markdown fragment only)

A stories fragment of the `/my/courses` acceptance, rendered with `.cmt`/`.str`/`.res` spans: the three
Given/When/Then lines for the enrolled-learner, no-enrollments, and not-signed-in cases. No `def`, no `defmodule`,
no Elixir. The fragment is cited via the `.specref` chip **F6.5 · Views with HEEx** → `/spec/specimens#f6-5`.

## The bridge

- **Principle** — write the spec as worked examples; the examples are the specification and the executable check.
- **Portal practice** — the `/my/courses` page is defined by three `Portal.Enrollment` examples; the acceptance run
  runs each as the rung's check.

## References

Sources: Specification by Example (`gojko.net`), Gherkin reference (`cucumber.io`), User Stories Applied
(`mountaingoatsoftware.com`). Related: hub `/spec/by-example`, `/spec`, `/spec/specimens`,
`/decomposition/acceptance`, `/what/four-artifacts`, `/elixir/phoenix`.

## Pager

prev = hub `/spec/by-example`; next = `/spec/by-example/living-documentation`.
