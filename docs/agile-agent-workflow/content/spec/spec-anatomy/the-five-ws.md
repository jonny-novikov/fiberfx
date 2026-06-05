# A4.3.2 · The five Ws — dive

- **Route:** `/course/agile-agent-workflow/spec/spec-anatomy/the-five-ws`
- **Model copied verbatim:** `html/agile-agent-workflow/why/two-layers/spec.html` (lesson)
- **Pager:** prev = `.../the-six-sections` · next = `.../constrain-not-overspecify`

## Ground-truth note (refinement pass)

- Bare prose citations of `f6.1.md` are framed with the locked **F6.1 spec chip** — label
  "F6.1 · Bootstrap the Phoenix Portal", a one-sentence tooltip, and a link to the spec-ladder viewer at
  `/course/agile-agent-workflow/spec/specimens` (bare route + `data-sr-hash="f6-1"`; the chip JS appends `#f6-1` on
  click, so it resolves with no JS and passes the `links` gate). The chip carries this description: "The first web
  rung: stand the F5 engine up as a Phoenix app, with one facade-backed route and a liveness route." The literal
  chip markup lives only in the `.html`; here it is described in prose.
- Chip-framed citations on this page (one per prose mention): hero kicker, the §ws prose, the §match prose, the
  §portal prose, the bridge practice cell, the recap. Figure/SVG/readout/code-label and Related-link mentions of
  `f6.1.md` are left as plain references (they are not standalone prose citations).
- `Portal.courses_of/1` is the **real, as-built facade function** (`defdelegate courses_of(user_id)` in
  `portal.ex`) — the call `/my/courses` makes. It is **kept** wherever it appears: it is the function, not the
  retired route `GET /courses/:user_id`. There is no route defect on this page.

## Lead

The Rationale section answers five questions — **Why, What, Who, When, Where** — each a single bold bullet. They fix
the *reason* for a rung before its definition: why it is built, what lands, who it serves, when it depends on, and
where the code lives. The five Ws keep the spec honest about intent so an Author never has to invent it.

## The five Ws, verbatim from `f6.1.md` Rationale

- **Why** — "F5 produced a correct engine but no way for a human to reach it over HTTP. The platform needs a web
  front door, and it must be added without disturbing the engine or the boundary that protects it."
- **What** — "a running Phoenix endpoint wired into the existing supervision tree, serving one facade-backed page and
  a liveness route, with the request lifecycle visible end to end."
- **Who** — "Operators (run and serve the platform), Visitors (load a page and see real data), Developers (keep the
  domain core untouched while the web layer is introduced)."
- **When** — "the first rung of the F6 value ladder; depends only on the F5.08 / F5.09 handoff (the `Portal` facade
  and the supervised engine), nothing else."
- **Where** — "a new umbrella app `apps/portal_web`".

## Hero interactive — pick a W, read its answer

- `.solid-select#wPick` five buttons (data-c="elixir"), why active.
- `wFor(k)` over `WS` → `{label, q, quote}`. Readout `#wOut` aria-live names the W, its question, the verbatim answer.

## Main interactive — match a fact to its W

- `.solid-select#mPick` over a fixed `FACTS` dataset; each fact maps to exactly one W.
- `classify(fact)` → `{w, why}`. Readout `#mOut` names the W the fact answers.
  e.g. "depends only on the F5.08 / F5.09 handoff" → **When**; "a new umbrella app `apps/portal_web`" → **Where**.

## pre.code

`# f6.1.md — Rationale (5W)` — the five bold bullets as markdown, `.cmt`/`.str` spans, no Elixir.

## Bridge

- idea: The Rationale answers five Ws — why, what, who, when, where — fixing intent before definition.
- practice: `f6.1.md`'s Rationale names all five; the Author reads them and never invents the reason for a rung.

## References

- Sources: User Stories Applied, Specification by Example, Continuous Delivery.
- Related: hub, `/spec`, `/roadmap/roadmap-anatomy`, `/why/two-layers`, `/elixir/phoenix`.
