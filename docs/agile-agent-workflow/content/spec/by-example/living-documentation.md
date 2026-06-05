# A4.1.2 · Living documentation — dive

> Source of record for `html/agile-agent-workflow/spec/by-example/living-documentation.html`.
> Route: `/course/agile-agent-workflow/spec/by-example/living-documentation`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `why/two-layers/spec.html` (lesson, hero-split).

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
- **Grounding** — F6.1's three `courses_of/1` examples are the page's documentation and its acceptance at once. If
  the unknown-id behaviour changed from "empty state, 200" to "404", the unknown-id example would fail — the
  document would not quietly mislead.

## Hero interactive — two sources drift; one source cannot

A `.solid-select` over a fixed `MODES` dataset. View `two-sources`: a prose doc and the code as separate nodes; the
readout reports a drift gap that grows as behaviour changes (a fixed `editCount` over the dataset). View
`one-source`: the worked example as a single node feeding both the human and the build; the readout reports drift =
0 because the example is the check. Pure `driftFor(mode)`, `heroReadout(mode)`; live `#ldHeroOut`. SVG: two
diverging boxes vs one box with two outward arrows. Static default: `one-source` lit, "drift: 0".

## Main interactive — change a behaviour, watch the example flag the staleness

A `.solid-select` over the three F6.1 examples; a second control toggles a behaviour change on the *unknown-id*
case (200 → 404). When the toggle is off, all three examples match the system and the readout reports
"documentation current". When on, the unknown-id example no longer matches and the readout reports "example fails →
documentation is stale, not silently wrong". Pure `statusFor(toggled)`; live `#ldMainOut`. This teaches a
different move from the hero: the hero contrasts one-source vs two-source structurally; the main demonstrates the
self-announcing staleness on a single concrete example.

## The `pre.code` block (NO CODE — markdown fragment only)

A `.md`/`.stories.md` fragment: the F6.1 Definition-of-Done line "an unknown user renders an empty state" paired
with F6.1-US5's Given/When/Then for the unknown id, rendered with `.cmt`/`.str`/`.res`. A note that a behaviour
change is reflected by editing the spec — feedback edits the spec, never the example in isolation. No Elixir.

## The bridge

- **Principle** — make the examples the specification and they become living documentation: executed, not
  asserted, so it cannot drift from the system.
- **Portal practice** — F6.1's three `courses_of/1` examples are the page's documentation and its acceptance check
  at once; a behaviour change fails the matching example.

## References

Sources: Specification by Example (`gojko.net`), Gherkin reference (`cucumber.io`), User Stories Applied
(`mountaingoatsoftware.com`). Related: hub `/spec/by-example`, `examples-as-spec`, `/spec`,
`/what/four-artifacts`, `/elixir/phoenix`.

## Pager

prev = `/spec/by-example/examples-as-spec`; next = `/spec/by-example/removing-ambiguity`.
