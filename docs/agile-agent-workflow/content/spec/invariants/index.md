# A4.5 · Invariants: properties that must always hold — module hub

- **Route:** `/course/agile-agent-workflow/spec/invariants`
- **File:** `html/agile-agent-workflow/spec/invariants/index.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Model:** hub ← `why/two-layers/index.html`

## Lead

A spec defines a slice; an invariant is the part of that definition that holds for *every* value, *always*.
An acceptance check is the other part: it holds for *one* scenario. The two are not the same kind of claim,
and naming them apart is the discipline of this module. An invariant pins a rule the increment must never
break, whatever the input; a check proves one example behaves. A4.5 teaches the difference, grounds it on the
Portal's real master invariant, and shows why a rung is done only when every invariant holds *and* every check
passes.

## Precise definition

- **Invariant** — a property true for every value an increment can take, at all times. It is universally
  quantified ("for all"); it is named once and exercised by checks, not stated per scenario.
- **Acceptance check** — a property true for one specified scenario (a single Given/When/Then). It is
  existentially scoped ("for this case"); it proves one example.
- The two compose: an invariant is *exercised by* checks, but it is not *replaced by* them. No finite set of
  passing checks proves an invariant; the invariant is the universal claim the checks sample.

## The canonical invariant — the master invariant (quoted verbatim)

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No controller,
> LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

"This single rule is what makes the whole ladder safe." It holds for every request, every controller, every
template — a universal claim, an invariant. Contrast it with F6.1-US5's first Given/When/Then: "an unknown user
id renders the empty state (a `200`)" — that is an acceptance check for one scenario.

"The error set is closed" is also an invariant: `%Portal.Error{}` carries a `code` one of
`:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`, extended only by an explicit,
no-catch-all mapping.

## Framing interactive (hero) — classify invariant vs check

- **Move:** classify each statement in a fixed dataset as *invariant* or *check*.
- **Control ids:** `invSel` (a `.solid-select` of statement buttons, each `data-c`).
- **Dataset (fixed):** the master invariant (invariant), "the error set is closed" (invariant), F6.1-US5's
  "unknown id → 200" (check), F6.1-US2's "known user renders their courses" (check).
- **Pure functions:** `classify(i)` → `"invariant" | "check"`; `readoutFor(i)` → the readout string naming the
  classification and why (universal vs one scenario).
- **Sample readout:** `Invariant · holds for every value, always. "The web layer calls only the Portal facade …" is a universal rule — true for every request, every controller, every template. Named once; exercised by checks, never replaced by them.`

## Three dives

1. `invariant-vs-check` — A4.5.1 — tell the two apart: universal rule vs one scenario.
2. `the-master-invariant` — A4.5.2 — read the Portal's master invariant as the canonical invariant.
3. `always-true` — A4.5.3 — why "for all" needs more than a finite set of passing checks.

## References

- Sources: Specification by Example (gojko.net), Continuous Delivery (continuousdelivery.com), Gherkin reference
  (cucumber.io).
- Related: `/course/agile-agent-workflow/spec`, `/course/agile-agent-workflow/why/correct`,
  `/course/agile-agent-workflow/why/two-layers`, `/elixir/phoenix`.

## Pager

- prev = `/course/agile-agent-workflow/spec`
- next = `/course/agile-agent-workflow/spec/invariants/invariant-vs-check`
