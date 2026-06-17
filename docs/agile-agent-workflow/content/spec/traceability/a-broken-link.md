# A4.6.3 · A broken link — `a-broken-link`

- **Route:** `/course/agile-agent-workflow/spec/traceability/a-broken-link`
- **File:** `html/agile-agent-workflow/spec/traceability/a-broken-link.html`
- **Pager:** prev = `.../the-closure` · next = `/course/agile-agent-workflow/spec/traceability` (hub).

## Lead

The closure is only as strong as its weakest link. This dive does the inverse of the first two: it removes one
link and shows the rule report "not done" — and, more usefully, **name the gap**. A deliverable with no story, a
story with no encodes, a requirement that traces to nothing — each is a hole the completion rule finds from the
text, before a line of behavior is trusted.

## The two ways a link breaks (the closures the text enforces)

From `specs.approach.md`: "Two closures make the chain checkable from the text alone: the stories file ends with a
**Coverage line** (`D#→US# · …`) mapping every Deliverable to the stories that realize it, and each story's
**INVEST line** ends with `encodes FN.M-INV#`, naming the invariants it exercises — so every invariant is
reachable from a story." Break either and the chain has a hole:

- **An uncovered deliverable** — a `D#` absent from the Coverage line: clause (a) fails.
- **An unreachable invariant** — an `INV#` no story `encodes`: clause (d) has no path from a story.

## Worked Portal example — break F6.1

F6.1's intact Coverage line is
`D1→US1 · D2→US1,US3,US4 · D3→US2 · D4→US2,US3,US5 · D5→US2 · D6→US1 · D7→US4,US5.`

- **Drop US4 and US5** (the stories that cover D7) → `D7→` is empty → D7 is an uncovered deliverable → **not done**;
  the gap is named: "D7 (verification) maps to no user story."
- **Drop US2's `encodes F6.1-INV1`** → INV1 is no longer reachable from any story → **not done**; the gap is named:
  "INV1 (master) is exercised by no story's encodes."

In both cases the rule does not say "looks fine"; it names the missing link.

## Hero interactive — break a link, read the gap

- **Element ids:** `<div class="solid-select" id="blMode">` buttons `data-k="intact|uncovered|unreachable"` (`data-c="sage|burg|burg"`, active = `intact`). SVG `class="dq"` showing the deliverable→story rows for F6.1; the broken row renders dashed/red (`row-d7`, link `enc-inv1`). Readout `id="blOut"`.
- **Pure functions:** `breakFor(mode)` over a fixed `CHAIN` dataset (D1…D7 → stories, the encodes map) → `{done, gap, text}`. `intact` → done. `uncovered` → drop D7's stories → not done, gap "D7 maps to no story". `unreachable` → drop US2's encodes → not done, gap "INV1 reachable from no story".
- **Sample readout:** "Uncovered deliverable · D7 maps to no user story, so clause (a) fails. Not done — the gap is named, not guessed."
- **Static default:** `intact` pre-lit; readout = "Intact · every deliverable maps to a story, every invariant is reachable. The chain closes — correct by definition."

## Main interactive — does the rule pass or fail?

- **Element ids:** `<div class="solid-select" id="blCase">` buttons `data-k="case1|case2|case3"` (each a candidate rung state, `data-c="elixir"`). Readout `id="caseOut"`. A `pre.code` block shows each case's Coverage line.
- **Pure functions:** `verdictFor(caseKey)` over a fixed `CASES` dataset → `{done:boolean, reason}`. case1 = full coverage → done; case2 = a missing `D#` → not done; case3 = an `INV#` with no encodes → not done.
- **Sample readout:** "Case 2 · D6 is absent from the Coverage line → clause (a) fails → not done. Completion is a closure; one broken link is enough to open it."
- **Static default:** `case1` pre-lit; readout = "Case 1 · D1…D7 all covered, every invariant reachable → the rule closes → done."

## The bridge

- **idea:** A broken link opens the closure: an uncovered deliverable or an unreachable invariant makes the rung
  not done, and the gap is named from the text — not a judgement call.
- **practice:** Drop D7's stories or US2's `encodes F6.1-INV1` and the rule reports F6.1 not done and points at the
  exact hole — the same check A1.05 calls "correct by definition", run in reverse.

## Take

A closure is only as strong as its links: remove one and the rule reports not done and names the gap — which is
why completion is verified, not asserted, and the chain ties straight back to A1.05.

## References — Sources

- Specification by Example — `https://gojko.net/books/specification-by-example/`
- User Stories Applied — `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- Continuous Delivery — `https://continuousdelivery.com/`

## Related

- `/course/agile-agent-workflow/spec/traceability` (hub)
- `/course/agile-agent-workflow/why/correct` (A1.05)
- `/course/agile-agent-workflow/decomposition/acceptance` (A2.04)
- `/elixir/phoenix`
