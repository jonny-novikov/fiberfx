# A3.3.3 · The open decisions — dive

- **Route:** `/course/agile-agent-workflow/roadmap/roadmap-anatomy/open-decisions`
- **File:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/open-decisions.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Pager:** prev = `…/roadmap-anatomy/the-iteration-table`; next = `…/roadmap-anatomy` (back to the hub).

## Lead

A good roadmap names what it has not decided. The "Seams & open decisions" section of `phoenix.roadmap.md` lists
each unresolved choice, says where it will be made, and what the seam is — so the plan is honest about its own
uncertainty instead of pretending it is gone.

## The open decisions (verbatim from `phoenix.roadmap.md`)

- **Authentication (F6.8).** Verbatim: "The likely path is `mix phx.gen.auth` for password accounts, with the
  `Accounts` context from F6.4 as the seam; the choice of social/SSO and session model is decided then."
- **Deployment & clustering (F6.8).** Verbatim: "An Elixir release plus a clustering strategy (for example
  `libcluster`)…the deploy target (a managed platform or containers) is decided then."
- **Dashboard data (F6.9).** Verbatim: "the dashboard folds live events…which metrics it shows and whether it
  embeds `LiveDashboard` is decided then."
- **Catalog browsing read.** Verbatim: "Browsing the available catalog uses `Catalog.list_courses/0` (F6.4),
  distinct from the learner-scoped `courses_of/1` on the F5 facade".
- **The Postgres `EventStore` adapter.** Verbatim: "Its body, schema, and migration land in F6.3 behind the F5.8
  port, so enrollment is durable in production while tests stay on the in-memory adapter."

## Hero interactive — open vs decided

- **What it frames.** Each listed decision is classified {open · where it resolves}. Picking one shows the
  verbatim decision and the rung it is deferred to. None is resolved on the roadmap; the roadmap only names it.
- **Element ids:** controls `#decPick` (buttons: auth, deploy, dashboard, browse, eventstore), readout `#decOut`
  (`aria-live="polite"`), SVG `#decMap` marking each as open / deferred-to-rung.
- **Pure function:** `decisionOf(key) -> {name, status, resolvesAt, quote}` over a fixed `DECISIONS` dataset
  (`status` is the constant `"open / named, not resolved"` for the deferred ones). Readout composes the fields.
- **Sample readout:** "Authentication — open / named, not resolved · resolves at F6.8 · verbatim: 'the choice of
  social/SSO and session model is decided then'."

## Main interactive — the master invariant holds across the open seams

- **What it proves.** The open decisions are real, but the master invariant constrains them: whatever auth,
  deployment, or dashboard becomes, "the web layer calls only the `Portal` facade". A toggle picks a resolution for
  an open decision; the invariant readout stays "holds" because the facade boundary is fixed.
- **Element ids:** controls `#invPick` (resolutions for one decision: e.g. auth = phx.gen.auth | external SSO),
  readout `#invOut` (`aria-live="polite"`), SVG `#invBox` showing the facade boundary.
- **Pure function:** `invariantHolds(resolution) -> true` (constant — every allowed resolution is over the facade)
  and `boundary(resolution) -> "Portal facade"`. Readout = "invariant: holds — over the Portal facade".
- **Sample readout:** "Resolution: external SSO. Master invariant: holds — the web layer calls only the Portal
  facade and renders only %Portal.Error{}. The open decision is named; the boundary is fixed."

## Bridge

- **Principle:** Name the open decisions, where each resolves, and the seam — an honest roadmap states its
  uncertainty instead of hiding it; a fixed invariant bounds every resolution.
- **Portal practice:** `phoenix.roadmap.md`'s "Seams & open decisions"; the master invariant "the web layer calls
  only the `Portal` facade and renders only the closed `%Portal.Error{}` set" holds across all of them.

## References — Sources (verbatim, real URLs)

- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

## Related (resolving)

- `/course/agile-agent-workflow/roadmap/roadmap-anatomy` — the hub.
- `/course/agile-agent-workflow/roadmap/the-roadmap-layer` — the anatomy expanded.
- `/elixir/phoenix` — the real F6 chapter.
- `/elixir/course` — the companion course.
