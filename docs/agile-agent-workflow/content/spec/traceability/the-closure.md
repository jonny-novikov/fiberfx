# A4.6.2 · The closure — `the-closure`

- **Route:** `/course/agile-agent-workflow/spec/traceability/the-closure`
- **File:** `html/agile-agent-workflow/spec/traceability/the-closure.html`
- **Pager:** prev = `.../the-chain` · next = `.../a-broken-link`.

## Lead

A chain that walks is not yet a guarantee. The guarantee is the **completion rule** — four clauses that, taken
together, make "done" a closure rather than a claim. This dive reads the rule clause by clause over F6.1 and ties
it back to A1.05: "correct by definition" means exactly this closure, with no behavior unpinned and no gate merely
asserted.

## The completion rule (verbatim, in a pre.code block)

```
A rung is done only when
  (a) every Deliverable maps to at least one User story,
  (b) every User story's acceptance criteria pass,
  (c) every Requirement is satisfied, and
  (d) every Invariant holds under test.
"Correct by definition" means exactly this closure: there is no behavior in
the increment that is not pinned by an acceptance check or an invariant, and
no gate that is merely asserted rather than run.
```

## Worked Portal example — the four clauses on F6.1

- **(a) Deliverables → stories.** F6.1's Coverage line maps D1…D7 to US1…US5:
  `D1→US1 · D2→US1,US3,US4 · D3→US2 · D4→US2,US3,US5 · D5→US2 · D6→US1 · D7→US4,US5.` No deliverable is absent.
- **(b) Acceptance criteria pass.** Each story's Given/When/Then is run — e.g. US1's "GET /health → 200 ok".
- **(c) Requirements satisfied.** Each `F6.1-R#` carries `[US: …]` and is implemented.
- **(d) Invariants hold.** INV1 (master) … INV5 (parse, don't validate) each exercised by a check.

When all four hold, the rung is closed. "Asserted, not run" is the failure A1.05 named — a gate written but never
executed proves nothing.

## Hero interactive — close the four clauses

- **Element ids:** `<div class="solid-select" id="clClause">` buttons `data-k="a|b|c|d"`, `data-c="elixir"`. SVG `class="dq"` with four clause rows `cl-a`, `cl-b`, `cl-c`, `cl-d` and a closure badge `cl-badge`. Readout `id="clOut"`.
- **Pure functions:** `clauseFor(key)` over a fixed `CLAUSE` dataset (the four clauses, each verbatim + its F6.1 evidence) → `{lit, text}`; `closureState()` reports all four hold → "closed".
- **Sample readout:** "(a) every Deliverable maps to a User story — on F6.1 the Coverage line covers D1…D7. Clause holds."
- **Static default:** clause `a` pre-lit; closure badge reads "closed".

## Main interactive — assert vs. run

- **Element ids:** `<div class="solid-select" id="clGate">` buttons `data-k="run|assert"` (`data-c="sage|burg"`). SVG `id="gateSvg"` showing a gate that is run (green check) vs merely asserted (open). Readout `id="gateOut"`.
- **Pure functions:** `gateFor(mode)` over a fixed `GATE` dataset → `{proven:boolean, text}`. `run` → the check executes against the increment → proven. `assert` → the gate is written but never executed → not proven; the rung is not done.
- **Sample readout:** "Asserted, not run · the gate is written but never executed, so it proves nothing. Correct by definition requires the gate to run — A1.05's rule, made operational."
- **Static default:** `run` pre-lit; readout = "Run · the acceptance check executes against the increment and passes, so the behavior is pinned. The clause holds."

## The bridge

- **idea:** "Done" is a closure over four clauses — deliverables covered, criteria pass, requirements satisfied,
  invariants hold — and every gate is run, not asserted.
- **practice:** F6.1 closes only when its Coverage line covers D1…D7, every Given/When/Then passes, every
  Requirement is met, and INV1…INV5 hold under test — the rung's Definition of Done.

## Take

The completion rule is the guarantee: a rung is done only when all four clauses close and every gate is run — the
exact closure A1.05 calls "correct by definition".

## References — Sources

- Continuous Delivery — `https://continuousdelivery.com/`
- Specification by Example — `https://gojko.net/books/specification-by-example/`
- User Stories Applied — `https://www.mountaingoatsoftware.com/books/user-stories-applied`

## Related

- `/course/agile-agent-workflow/spec/traceability` (hub)
- `/course/agile-agent-workflow/why/correct` (A1.05)
- `/course/agile-agent-workflow/decomposition/acceptance` (A2.04)
- `/elixir/phoenix`
