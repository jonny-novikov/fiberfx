# A4.3 · Anatomy of a spec — module hub

- **Route:** `/course/agile-agent-workflow/spec/spec-anatomy`
- **File:** `html/agile-agent-workflow/spec/spec-anatomy/index.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Model copied verbatim (head/header/footer/scripts):** `html/agile-agent-workflow/why/two-layers/index.html` (hub)
- **Pager:** prev = `/course/agile-agent-workflow/spec` (A4 landing) · next = `/course/agile-agent-workflow/spec/spec-anatomy/the-six-sections`

## Lead

A spec is six named sections. Read the real `f6.1.md` section by section and the shape of a spec becomes a template
you can write any rung to: **Goal · Rationale (5W) · Scope · Deliverables · Invariants · Definition of Done.** The
teaching line of the whole module: a spec **constrains the build without over-specifying the solution** — it says
what must be true, not how to write the code.

## The six sections (from `docs/elixir/specs/phoenix/f6.1.md`, verbatim)

1. **Goal** — the destination, in prose. "After F6.1, the Portal runs as a Phoenix app. A browser request travels
   through the endpoint's plug stack, the router's `:browser` pipeline, and a thin `PortalWeb.CourseController` that
   calls `Portal.courses_of/1`, branches on the closed `%Portal.Error{}` set, and renders a HEEx view."
2. **Rationale (5W)** — why, what, who, when, where. The five bold bullets.
3. **Scope** — `In` and `Out`. `Out` defers, naming the rung each concern moves to ("(→ F6.2)", "(→ F6.3)",
   "(→ F6.6)") — the line between constraining and over-specifying.
4. **Deliverables** — F6.1-D1 … F6.1-D7, each a concrete artifact.
5. **Invariants** — F6.1-INV1 (master) … INV5; properties true for every value, always.
6. **Definition of Done** — a checkbox list, closing on a traceability sentence.

`Portal.courses_of/1` returns the courses a user is enrolled in (explained in plain terms; no source shown).

## Framing interactive (hero) — pick a section, read it on `f6.1.md`

- **Controls:** `.solid-select#secPick` — six buttons (`data-k` = goal · rationale · scope · deliverables ·
  invariants · dod), each `data-c="elixir"`; `goal` is `.active` by default.
- **SVG:** a stacked list of the six sections; the picked one is highlighted.
- **Pure functions:** `sectionFor(k)` over a fixed `SECTIONS` dataset → returns `{label, q, quote}`.
- **Readout** (`#secOut`, aria-live): names the section, its question, and a verbatim phrase.
  Default (Goal): `Goal · question: where does this rung land? · verbatim: "After F6.1, the Portal runs as a Phoenix app".`

## Main interactive — constrain vs over-specify

- **Controls:** `.solid-select#csPick` — statements toggled; classify each as *constrains* or *over-specifies*.
- **Pure functions:** `verdict(stmt)` over a fixed `STMTS` dataset → returns `{kind, why}`.
- **Readout** (`#csOut`, aria-live): reports the verdict.
  Example: "renders the empty state for an unknown id" → **constrains** (states what must be true, leaves the code free);
  "use a `case` not a `cond`" → **over-specifies** (dictates the solution, not the behaviour).

## Bridge

- **idea:** A spec is six named sections that constrain the build without over-specifying the solution.
- **practice:** Read each on the real `f6.1.md`; Scope's `Out` constrains by *deferring*, naming the later rung.

## The three dives

| Dive | Slug | Topic |
|---|---|---|
| A4.3.1 | `the-six-sections` | the six named sections, read in order on `f6.1.md` |
| A4.3.2 | `the-five-ws` | the Rationale's five Ws — why, what, who, when, where |
| A4.3.3 | `constrain-not-overspecify` | the line: constrain the build, not the solution |

## References

- Sources: Specification by Example (gojko.net), Continuous Delivery (continuousdelivery.com),
  User Stories Applied (mountaingoatsoftware.com).
- Related: `/course/agile-agent-workflow/spec`, `/course/agile-agent-workflow/roadmap/roadmap-anatomy`,
  `/course/agile-agent-workflow/why/two-layers`, `/elixir/phoenix`.
