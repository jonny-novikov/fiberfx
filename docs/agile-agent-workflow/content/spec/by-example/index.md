# A4.1 · Specification by Example — module hub

> Source of record for the module hub `html/agile-agent-workflow/spec/by-example/index.html`.
> Route: `/course/agile-agent-workflow/spec/by-example`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Models copied verbatim: `why/two-layers/index.html` (hub), `roadmap/roadmap-anatomy/what-it-carries.html` (`pre.code` idiom).
> Ground-truth note (2026-06-05 reconcile): the worked example was re-grounded off the **retired route**
> `GET /courses/:user_id` onto the **as-built** routes — the public catalog `/courses` (`Portal.Catalog`, anyone)
> and the learner's own enrollments `/my/courses` (PROTECTED). The facade function `Portal.courses_of/1` is **real
> and as-built** — it is what `/my/courses` calls (via `Portal.Enrollment`); only the route name retired, not the
> function. Bare-filename citations are replaced with the `.specref` chip linking to `/spec/specimens`.

## Lead

A roadmap orders the work; a spec defines it. The first question the spec layer answers is *how to write a
requirement that cannot be misread*. The answer this module argues, from Specification by Example: replace the
abstract requirement with **worked examples**, and let the examples double as the executable check. The worked
exemplar is the Portal's protected learner-enrollments page **`/my/courses`** (`Portal.Enrollment`) — three concrete
cases: an enrolled learner sees their own courses, a learner with no enrollments sees the empty state, and an
unauthenticated request is redirected (a learner never sees another learner's courses).

## Precise definition

- **Specification by example** — concrete, worked examples are the specification. An abstract requirement ("handle a
  bad request") admits many readings; a worked example ("a request with no signed-in learner is redirected") pins one.
- **Living documentation** — because the examples are the checks the build runs against, the documentation cannot
  drift from the system: a change that breaks an example breaks a check.
- **Removing ambiguity** — the examples are chosen to collapse the readings of a requirement from many to one,
  before a line of code is written.

The as-built routes named at spec level (no source): the public catalog `GET /courses` (`Portal.Catalog`, anyone)
and a learner's own enrollments `GET /my/courses` (`Portal.Enrollment`, PROTECTED).

## Framing interactive (hub) — abstract requirement vs worked examples

A `.solid-select` chooses one of three views over a fixed `VIEWS` dataset:
- **abstract** — the requirement "handle a bad request to the learner-courses page" with three divergent readings
  (a 404, a crash, showing another learner's courses). The readout reports three open readings.
- **examples** — the three worked cases of the protected `/my/courses` route (enrolled learner → own courses; no
  enrollments → empty state; not signed in → redirected). The readout reports the readings collapsed to one: a
  learner sees only their own courses.
- **both** — side by side: many readings narrow to one.

Pure functions over `VIEWS`: `openReadings(view)` → count, `readoutFor(view)` → string. Live `#byHubOut`
(`aria-live`). Static default: `examples` lit, readout reads "one reading".

## The `.mods` grid — the three dives

- **A4.1.1 — Examples as specification** (`examples-as-spec`) — concrete examples *are* the spec; the harness reads
  from them. Pinned on the catalog and `/my/courses` cases.
- **A4.1.2 — Living documentation** (`living-documentation`) — because the examples are the checks, the docs cannot
  drift.
- **A4.1.3 — Removing ambiguity** (`removing-ambiguity`) — examples collapse a requirement's readings from many to
  one.

## The bridge

- **Principle** — replace an abstract requirement with worked examples; the examples are the specification, and
  they double as the executable check.
- **Portal practice** — the learner-enrollments page `/my/courses` is defined by three worked `Portal.Enrollment`
  examples; each is a Given/When/Then that the acceptance check runs. Cited via the `.specref` chip
  **F6.5 · Views with HEEx** (the HEEx rung that reconciled the learner route into the protected `/my/courses`).

## References

Sources (real, vetted): Specification by Example (`gojko.net`), User Stories Applied (`mountaingoatsoftware.com`),
Gherkin reference (`cucumber.io`). Related: `/spec`, `/spec/specimens`, `/decomposition/acceptance`,
`/what/four-artifacts`, `/elixir/phoenix`, and the three dives.

## Pager

prev = `/course/agile-agent-workflow/spec`; next = `/course/agile-agent-workflow/spec/by-example/examples-as-spec`.
