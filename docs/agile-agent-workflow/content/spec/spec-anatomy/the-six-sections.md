# A4.3.1 · The six sections — dive

- **Route:** `/course/agile-agent-workflow/spec/spec-anatomy/the-six-sections`
- **Model copied verbatim:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)
- **Pager:** prev = hub (`/spec/spec-anatomy`) · next = `.../the-five-ws`

## Lead

A spec is six named sections in a fixed order, each answering a different question. Read them on the real `f6.1.md`
and the order becomes a template: **Goal · Rationale · Scope · Deliverables · Invariants · Definition of Done.** Goal
sets the destination; Rationale gives the five Ws; Scope draws the boundary; Deliverables list the artifacts;
Invariants name what must always hold; the Definition of Done closes it as a checklist.

## The six sections, verbatim from `f6.1.md`

- **Goal** — "After F6.1, the Portal runs as a Phoenix app. A browser request travels through the endpoint's plug
  stack, the router's `:browser` pipeline, and a thin `PortalWeb.CourseController` that calls `Portal.courses_of/1`,
  branches on the closed `%Portal.Error{}` set, and renders a HEEx view."
- **Rationale (5W)** — Why "F5 produced a correct engine but no way for a human to reach it over HTTP"; What "a
  running Phoenix endpoint wired into the existing supervision tree, serving one facade-backed page and a liveness
  route"; Who "Operators … Visitors … Developers"; When "the first rung of the F6 value ladder"; Where "a new umbrella
  app `apps/portal_web`".
- **Scope** — In "the endpoint and its plug stack; the one supervision-tree change; a `:browser` pipeline; one read
  route to a thin controller over the facade; a HEEx view; a liveness route". Out "multiple pipelines … (→ F6.2);
  Ecto persistence (→ F6.3) … LiveView (→ F6.6)".
- **Deliverables** — F6.1-D1 … F6.1-D7. D6 "a liveness route `get "/health", …` returning `200` (a plain `"ok"`)
  without touching the domain". D4 the controller calling **only** `Portal.courses_of/1`.
- **Invariants** — F6.1-INV1 (master) "`PortalWeb` calls only the `Portal` facade and renders only the closed
  `%Portal.Error{}` set"; F6.1-INV4 "an expected domain failure renders as an HTTP status drawn from the closed error
  set (e.g. `422`), never a `500` or an unhandled crash".
- **Definition of Done** — a checkbox list, closing on "Every deliverable maps to a user story and every invariant is
  exercised by a check (see `./f6.1.stories.md`)".

## Hero interactive — pick a section, read its question

- `.solid-select#sxPick` six buttons (data-c="elixir"), goal active.
- `sectionFor(k)` over `SECTIONS` → `{label, q, quote}`. Readout `#sxOut` aria-live.

## Main interactive — step the order

- `.solid-select#ordPick` six buttons; the order is fixed (1 Goal … 6 DoD).
- `orderFor(n)` over `ORDER` → `{pos, label, role}`. Readout `#ordOut` names position + role.

## pre.code

`# f6.1.md — the six section headings, in order` — markdown headings with `.cmt`/`.str` spans, no Elixir.

## Bridge

- idea: A spec is six named sections, each answering one question, in a fixed order.
- practice: `f6.1.md` carries all six; read in order they are a template for any rung.

## References

- Sources: Specification by Example, Continuous Delivery, User Stories Applied.
- Related: hub, `/spec`, `/roadmap/roadmap-anatomy`, `/why/two-layers`, `/elixir/phoenix`.
