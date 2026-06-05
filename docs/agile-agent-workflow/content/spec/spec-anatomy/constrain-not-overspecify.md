# A4.3.3 · Constrain, not over-specify — dive

- **Route:** `/course/agile-agent-workflow/spec/spec-anatomy/constrain-not-overspecify`
- **Model copied verbatim:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)
- **Pager:** prev = `.../the-five-ws` · next = hub (`/spec/spec-anatomy`)

## Lead

A spec **constrains the build without over-specifying the solution.** A constraint states what must be true and leaves
the code free; an over-specification dictates the code and leaves nothing for the Author to decide. The cleanest place
to see the line is Scope's `Out`: it constrains by *deferring* — naming the later rung each concern moves to — instead
of forbidding it forever.

## Ground truth — citation chip and the real `courses_of/1`

The bare-filename citations of `f6.1.md` in the prose (the "defer, do not forbid" lead, the "on the Portal" lead,
and the bridge practice cell) are each rendered as a clickable **F6.1 specref chip** — label "F6.1 · Bootstrap the
Phoenix Portal", a one-sentence tooltip ("the first web rung: stand the F5 engine up as a Phoenix app, with one
facade-backed route and a liveness route"), and a link to the spec-ladder viewer at
`/course/agile-agent-workflow/spec/specimens` (bare route + `data-sr-hash="f6-1"`, so it resolves with no JS and
deep-links to the F6.1 stop when enhanced). The chip ids on the page are `sr-defer-f61`, `sr-portal-f61`, and
`sr-bridge-f61`. The `# f6.1.md — Scope · Out` comment inside the `pre.code` block stays a bare label (it is the
illustrated subject, not a dangling citation).

`Portal.courses_of/1` is the **real, as-built facade function** — it returns the courses a user is enrolled in, and
it is exactly what the protected `/my/courses` route calls. It is named verbatim in the D4 Deliverable below and in
the Scope `Out` ("wiring beyond `courses_of/1`"); it is kept as written and is not the retired route
`GET /courses/:user_id` (that route reframing happened at F6.5).

## The line, grounded on the F6.1 rung's spec

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
- practice: the F6.1 rung's `Out` (cited via the F6.1 specref chip) names `(→ F6.2)…(→ F6.6)`; each deferral is a
  constraint, not a forbidden gate.

## References

- Sources: Specification by Example, Continuous Delivery, User Stories Applied.
- Related: hub, `/spec`, `/spec/specimens` (the spec ladder the F6.1 chip links to), `/roadmap/roadmap-anatomy`,
  `/why/two-layers`, `/elixir/phoenix`.
