# A4.1.3 · Removing ambiguity — dive

> Source of record for `html/agile-agent-workflow/spec/by-example/removing-ambiguity.html`.
> Route: `/course/agile-agent-workflow/spec/by-example/removing-ambiguity`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `why/two-layers/spec.html` (lesson, hero-split).
> Ground-truth note (2026-06-05 reconcile): re-grounded off the retired "handle a bad user id" / `/courses/:user_id`
> onto the as-built protected `/my/courses` (`Portal.Enrollment`); the surviving reading is the **redirect** (access)
> case, not the retired empty-state-200 case. Bare-filename citations replaced with `.specref` chips to
> `/spec/specimens#f6-5`.

## Lead

The closing move of the module names the mechanism the first two relied on: a worked example *removes ambiguity*. An
abstract requirement is a set of possible readings; the work of specifying by example is choosing the examples that
narrow that set to one — before a line of code is written. The exemplar is the treatment of "handle a request with
no signed-in learner" on the protected `/my/courses` route: worked cases close every reading the phrase left open,
down to one — a redirect, never another learner's courses.

## Precise definition

- **Ambiguity** — a requirement that admits more than one reading. "Handle a request with no signed-in learner"
  could mean a 404, a crash, showing another learner's courses, or a redirect; the phrase does not decide.
- **Removing ambiguity** — adding worked examples until exactly one reading survives. Each example rules out the
  readings it contradicts.
- **Grounding** — the abstract "handle a bad request to /my/courses" is pinned to "a request with no signed-in
  learner is redirected — never another learner's courses". One reading remains; the rest (a 404, a crash, showing
  another's courses) are removed.

## Hero interactive — add examples, watch the surviving readings fall to one

A `.fold-ctrl` range slider `0..3` over a fixed dataset (the abstract phrase has 4 candidate readings: a 404, a
crash, render another learner's courses, a redirect — the survivor). Each added example removes the readings it
contradicts. At 0 examples: 4 readings open. At 3 examples: 1 reading survives (the redirect). Pure
`survivingReadings(n)`, `heroReadout(n)`; live `#raHeroOut`. SVG: four reading boxes that grey out as examples are
added, the surviving one (`ra-k3`, the redirect) lit elixir-purple. Static default (slider at 3): "1 reading
survives".

## Main interactive — classify a statement: ambiguous requirement vs pinning example

A `.solid-select` over a fixed `STATEMENTS` dataset: "handle bad input" → ambiguous; "not signed in → redirected" →
pins one reading; "show something reasonable" → ambiguous; "no enrollments → renders the empty state" → pins one
reading. Selecting one reports, in `#raMainOut`, whether it is *ambiguous* (many readings) or a *pinning example*
(one reading) and why. Pure `classify(i)`. A different move from the hero: the hero counts readings as examples
accumulate; the main judges a single statement.

## The `pre.code` block (NO CODE — markdown fragment only)

A spec fragment: the abstract DoD phrasing "the page must handle a bad request gracefully" set against the pinning
`/my/courses` Given/When/Then (a request with no signed-in learner → redirected), rendered with `.cmt`/`.str`/`.res`.
The contrast is the lesson: one line read many ways, three examples that leave one. No Elixir. Cited via the
`.specref` chip **F6.5 · Views with HEEx** → `/spec/specimens#f6-5`.

## The bridge

- **Principle** — choose worked examples until exactly one reading of the requirement survives; the examples
  remove the ambiguity before code is written.
- **Portal practice** — the Portal pins "handle a bad request to /my/courses" to three `Portal.Enrollment` cases;
  the redirect reading is the one that survives, and it is the acceptance check.

## References

Sources: Specification by Example (`gojko.net`), Gherkin reference (`cucumber.io`), User Stories Applied
(`mountaingoatsoftware.com`). Related: hub `/spec/by-example`, `living-documentation`, `/spec`, `/spec/specimens`,
`/decomposition/acceptance`, `/elixir/phoenix`.

## Pager

prev = `/spec/by-example/living-documentation`; next = hub `/spec/by-example`.
