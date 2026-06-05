# A4.1.2 · Living documentation — dive

> Source of record for `html/agile-agent-workflow/spec/by-example/living-documentation.html`.
> Route: `/course/agile-agent-workflow/spec/by-example/living-documentation`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `why/two-layers/spec.html` (lesson, hero-split).
> Ground-truth note (2026-06-05 reconcile): re-grounded off the **retired route** `GET /courses/:user_id` onto the
> as-built protected `/my/courses`. The facade function `Portal.courses_of/1` is **real and as-built** — it is what
> `/my/courses` calls (via `Portal.Enrollment`); only the route name retired, not the function. Bare-filename
> citations replaced with `.specref` chips to `/spec/specimens#f6-5`. The behaviour-change demo regresses the
> **not-signed-in** access case (redirect → renders) rather than the retired unknown-id case.

## Lead

The second consequence of making examples the specification: the documentation cannot drift from the system. A
prose document about behaviour and the code it describes are two sources that fork the moment one is edited and the
other is not. A worked example is one source — it is both the documentation a human reads and the check the build
runs. Edit a behaviour and the example fails; the documentation announces its own staleness instead of lying.

## Precise definition

- **Living documentation** — documentation that is executed, not asserted. Because the example doubles as the
  check, a behaviour change that the example no longer matches breaks the check, so the document and the system
  cannot diverge silently.
- **Drift** — the gap that opens between a static document and the system it describes. Specification by Example
  removes the gap by removing the second source.
- **Grounding** — the protected `/my/courses` page's three `Portal.Enrollment` examples are its documentation and
  its acceptance at once. If the not-signed-in behaviour changed from "redirect" to "render whatever courses the
  request named", the not-signed-in example would fail — the document would not quietly mislead, and the access rule
  would not be silently broken.

## Hero interactive — two sources drift; one source cannot

A `.solid-select` over a fixed `MODES` dataset. View `two-sources`: a prose doc and the code as separate nodes; the
readout reports a drift gap that grows as behaviour changes. View `one-source`: the worked example as a single node
feeding both the human and the build; the readout reports drift = 0 because the example is the check. Pure
`driftFor(mode)`, `heroReadout(mode)`; live `#ldHeroOut`. SVG: two diverging boxes vs one box with two outward
arrows. Static default: `one-source` lit, "drift: 0". (Generic — no route premise.)

## Main interactive — change a behaviour, watch the example flag the staleness

A `.solid-select` toggles a behaviour change on the **not-signed-in** case (redirect → renders). When the toggle is
off, all three `/my/courses` examples (enrolled learner / no enrollments / not signed in) match the system and the
readout reports "documentation current". When on, the not-signed-in example no longer matches and the readout
reports "example fails → documentation is stale, not silently wrong". Pure `statusFor(toggled)`; live `#ldMainOut`.
This teaches a different move from the hero: the hero contrasts one-source vs two-source structurally; the main
demonstrates the self-announcing staleness on a single concrete example.

## The `pre.code` block (NO CODE — markdown fragment only)

A spec fragment: the `/my/courses` Definition-of-Done line "a request with no signed-in learner is redirected"
paired with the matching Given/When/Then, rendered with `.cmt`/`.str`/`.res`. A note that a behaviour change is
reflected by editing the spec — feedback edits the spec, never the example in isolation. No Elixir. Cited via the
`.specref` chip **F6.5 · Views with HEEx** → `/spec/specimens#f6-5`.

## The bridge

- **Principle** — make the examples the specification and they become living documentation: executed, not
  asserted, so it cannot drift from the system.
- **Portal practice** — the `/my/courses` page's three `Portal.Enrollment` examples are its documentation and its
  acceptance check at once; a behaviour change fails the matching example.

## References

Sources: Specification by Example (`gojko.net`), Gherkin reference (`cucumber.io`), User Stories Applied
(`mountaingoatsoftware.com`). Related: hub `/spec/by-example`, `examples-as-spec`, `/spec`, `/spec/specimens`,
`/what/four-artifacts`, `/elixir/phoenix`.

## Pager

prev = `/spec/by-example/examples-as-spec`; next = `/spec/by-example/removing-ambiguity`.
