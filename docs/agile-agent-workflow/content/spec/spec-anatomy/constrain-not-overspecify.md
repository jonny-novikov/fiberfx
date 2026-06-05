# A4.3.3 · Constrain, not over-specify — dive

- **Route:** `/course/agile-agent-workflow/spec/spec-anatomy/constrain-not-overspecify`
- **Model copied verbatim:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)
- **Pager:** prev = `.../the-five-ws` · next = hub (`/spec/spec-anatomy`)

## Lead

A spec **constrains the build without over-specifying the solution.** A constraint states what must be true and leaves
the code free; an over-specification dictates the code and leaves nothing for the Author to decide. The cleanest place
to see the line is Scope's `Out`: it constrains by *deferring* — naming the later rung each concern moves to — instead
of forbidding it forever.

## The line, grounded on `f6.1.md`

- **Scope `Out` defers, naming the rung.** Verbatim: "multiple pipelines … (→ F6.2); Ecto persistence (→ F6.3);
  domain and context wiring beyond `courses_of/1` (→ F6.4); rich templates, components, and forms (→ F6.5);
  LiveView (→ F6.6)." The `(→ F6.N)` is the move that turns a refusal into a constraint: not "never", but "not here,
  there".
- **A Deliverable constrains by naming an artifact and a behaviour, not an implementation.** D6 "a liveness route
  `get "/health", …` returning `200` (a plain `"ok"`) without touching the domain" states what must be true; it does
  not say which plug writes the body. D4 "the controller calls **only** `Portal.courses_of/1`" constrains the call,
  not the control flow.
- **An Invariant constrains every value, always** — F6.1-INV1 (master): "`PortalWeb` calls only the `Portal` facade
  and renders only the closed `%Portal.Error{}` set." It forbids a class of code without writing any.
- **Over-specifying** would be "use a `case` not a `cond`" — a solution detail the spec has no business holding.
  "renders the empty state for an unknown id" constrains; "use a `case` not a `cond`" over-specifies.

## Hero interactive — classify a statement

- `.solid-select#csPick` over a fixed `STMTS` dataset; classify each as *constrains* or *over-specifies*.
- `verdict(stmt)` → `{kind, why}`. Readout `#csOut` aria-live.
  e.g. "renders the empty state for an unknown id" → **constrains**; "use a `case` not a `cond`" → **over-specifies**.

## Main interactive — defer vs forbid

- `.solid-select#dfPick` over a fixed `OUTS` dataset of Scope `Out` entries; show the rung each defers to.
- `deferral(item)` → `{rung, kind}`. Readout `#dfOut` reports "deferred → F6.N" vs "forbidden (no rung)".

## pre.code

`# f6.1.md — Scope · Out (each Out names the rung it defers to)` — the Out bullets as markdown, `.cmt`/`.res` spans,
no Elixir.

## Bridge

- idea: A spec constrains the build without over-specifying the solution; Scope's `Out` constrains by deferring.
- practice: `f6.1.md`'s `Out` names `(→ F6.2)…(→ F6.6)`; each deferral is a constraint, not a forbidden gate.

## References

- Sources: Specification by Example, Continuous Delivery, User Stories Applied.
- Related: hub, `/spec`, `/roadmap/roadmap-anatomy`, `/why/two-layers`, `/elixir/phoenix`.
