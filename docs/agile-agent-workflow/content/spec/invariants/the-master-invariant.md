# A4.5.2 · The master invariant — dive

- **Route:** `/course/agile-agent-workflow/spec/invariants/the-master-invariant`
- **File:** `html/agile-agent-workflow/spec/invariants/the-master-invariant.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Model:** lesson ← `why/two-layers/spec.html`

## Lead

One invariant on the Portal's web chapter does more work than any other. It draws the boundary the whole layer
stands on, and it holds for every controller, every LiveView, every template. It is the master invariant. Read
it as the canonical example of what an invariant is: a single universal rule, stated once, that the increment may
never break.

## The master invariant (quoted verbatim)

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No controller,
> LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

"This single rule is what makes the whole ladder safe."

`pre.code`: this exact text, rendered as a `.md` Invariants-line fragment with `.cmt`/`.str`/`.res` spans. No
Elixir source — the only names that appear are inside this verbatim quote.

## Why it is an invariant, not a check

- It is universal: it quantifies over *every* module in the web layer and *every* request. There is no scenario
  for which it may fail.
- A check samples it. F6.1-US3's "search `apps/portal_web/lib/`, find no module references `Portal.Engine`" is one
  check that exercises the master invariant — but the invariant is the universal claim, named once in `f6.1.md`,
  and the check is one of the ways it is exercised.
- The closed error set is a second invariant the master invariant names: `%Portal.Error{}` carries a `code` one of
  `:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`, extended only by an explicit,
  no-catch-all mapping.

## Hero interactive — the boundary the invariant draws

- **Move:** select a web-layer caller (controller / template / liveview) and watch the readout confirm it goes
  through the facade — the master invariant holding for each.
- **Control ids:** `miSel` (`.solid-select`, each `data-c`).
- **Dataset:** controller, template, liveview — each routed to "the Portal facade"; plus a "below the facade"
  node that the web layer may never name.
- **Pure:** `routeFor(i)` → readout naming the caller and the facade-only path; the master invariant holds.
- **Sample readout:** `The controller calls only the Portal facade. Under the master invariant, no web-layer module names Portal.Engine, a repo, or GenServer.call — the rule holds for this caller, as it holds for every caller.`

## Main interactive — invariant vs the check that samples it

- **Move (different):** toggle between the master invariant (the universal rule) and F6.1-US3's static-search
  check (one sample). The readout shows the check exercises the invariant but does not replace it.
- **Control ids:** `miSample` (`.solid-select`).
- **Pure:** `sampleFor(k)` → readout contrasting "for all modules" with "this one search".
- **Sample readout:** `The check searches apps/portal_web/lib/ and finds no Portal.Engine reference — one sample of the master invariant. The invariant is the universal claim it samples; passing the search does not make the rule true for every future module.`

## Bridge

- principle: a master invariant is a single universal rule, stated once, that an increment may never break.
- Portal: F6.1-INV1 — the web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}`
  set — holds for every web-layer module and every request.

## References

- Sources: Continuous Delivery, Specification by Example, Gherkin reference.
- Related: hub `/course/agile-agent-workflow/spec/invariants`,
  `/course/agile-agent-workflow/spec/invariants/invariant-vs-check`, `/course/agile-agent-workflow/why/two-layers`,
  `/elixir/phoenix`.

## Pager

- prev = `/course/agile-agent-workflow/spec/invariants/invariant-vs-check`
- next = `/course/agile-agent-workflow/spec/invariants/always-true`
