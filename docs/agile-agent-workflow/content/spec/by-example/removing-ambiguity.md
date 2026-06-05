# A4.1.3 · Removing ambiguity — dive

> Source of record for `html/agile-agent-workflow/spec/by-example/removing-ambiguity.html`.
> Route: `/course/agile-agent-workflow/spec/by-example/removing-ambiguity`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `why/two-layers/spec.html` (lesson, hero-split).

## Lead

The closing move of the module names the mechanism the first two relied on: a worked example *removes ambiguity*. An
abstract requirement is a set of possible readings; the work of specifying by example is choosing the examples that
narrow that set to one — before a line of code is written. The exemplar is F6.1's treatment of "handle a bad user
id": three worked cases close every reading the phrase left open.

## Precise definition

- **Ambiguity** — a requirement that admits more than one reading. "Handle bad input" could mean a 404, a crash, an
  empty page, or a redirect; the phrase does not decide.
- **Removing ambiguity** — adding worked examples until exactly one reading survives. Each example rules out the
  readings it contradicts.
- **Grounding** — the abstract "the page must handle a bad user id" is pinned by F6.1 to "an unknown or malformed
  id renders the empty state — a clean 200, never a 500". One reading remains; the rest are removed.

## Hero interactive — add examples, watch the surviving readings fall to one

A `.fold-ctrl` range slider `0..3` over a fixed `READINGS` dataset (the abstract phrase has 4 candidate readings;
each added example removes the readings it contradicts). At 0 examples: 4 readings open. At 3 examples: 1 reading
survives. Pure `survivingReadings(n)`, `heroReadout(n)`; live `#raHeroOut`. SVG: four reading boxes that grey out
as examples are added, the surviving one lit elixir-purple. Static default (slider at 3): "1 reading survives".

## Main interactive — classify a statement: ambiguous requirement vs pinning example

A `.solid-select` over a fixed `STATEMENTS` dataset (e.g. "handle bad input" → ambiguous; "an unknown id renders
the empty state, a 200" → pins one reading; "show something reasonable" → ambiguous; "a known user with no
enrollments renders an empty state, not an error" → pins one reading). Selecting one reports, in `#raMainOut`,
whether it is *ambiguous* (many readings) or a *pinning example* (one reading) and why. Pure `classify(i)`. A
different move from the hero: the hero counts readings as examples accumulate; the main judges a single statement.

## The `pre.code` block (NO CODE — markdown fragment only)

A `.md` fragment: the abstract Scope/DoD phrasing "the page must handle a bad user id" set against the pinning
F6.1 Definition-of-Done line and F6.1-US5's Given/When/Then, rendered with `.cmt`/`.str`/`.res`. The contrast is
the lesson: one line that is read many ways, three examples that leave one. No Elixir.

## The bridge

- **Principle** — choose worked examples until exactly one reading of the requirement survives; the examples
  remove the ambiguity before code is written.
- **Portal practice** — F6.1 pins "handle a bad user id" to three `courses_of/1` cases; the empty-state-200 reading
  is the one that survives, and it is the acceptance check.

## References

Sources: Specification by Example (`gojko.net`), Gherkin reference (`cucumber.io`), User Stories Applied
(`mountaingoatsoftware.com`). Related: hub `/spec/by-example`, `living-documentation`, `/spec`,
`/decomposition/acceptance`, `/elixir/phoenix`.

## Pager

prev = `/spec/by-example/living-documentation`; next = hub `/spec/by-example`.
