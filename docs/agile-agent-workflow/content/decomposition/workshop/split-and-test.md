# A2.07.2 · Split and test

- **Route:** `/course/agile-agent-workflow/decomposition/workshop/split-and-test`
- **File:** `html/agile-agent-workflow/decomposition/workshop/split-and-test.html`
- **Role:** dive 2 of the workshop, grounded in the Portal's REAL F6 (Phoenix) web decomposition. Show *how*
  one vision is split into nine vertical rungs over the unchanged `Portal` facade, then zoom into ONE rung
  (F6.6 · LiveView) as its four real artifacts and prove it with its verbatim Given/When/Then.
- **Accent:** elixir-purple.
- **Companion build:** `/elixir/phoenix/liveview` (where F6.6 is built).

## Lead

The web vision — *serve the Portal to people* — is too big for one rung. The split cuts it into nine vertical
slices (`f6.1`–`f6.9`), each shipping one capability over the unchanged `Portal` facade. Then the test: zoom
into ONE rung, lay out its four artifacts, and prove the slice with Given/When/Then. A slice is ready not
when it is small but when its acceptance can be run.

## The master invariant (quote verbatim from `index.md`)

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No
> controller, LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

This single rule is what makes the ladder cheap: every rung adds web surface without reaching below the
facade, so nothing under the F5 engine ever changes. The rungs depend only downward — F6.6 makes F6.5's
pages live.

## Worked Portal example — the nine-rung split, then one rung

The vision splits into nine vertical rungs, each a capability a real role can use:

- F6.1 boot · F6.2 routing · F6.3 Ecto · F6.4 contexts · F6.5 HEEx views · F6.6 LiveView · F6.7 PubSub ·
  F6.8 auth · F6.9 dashboard.

Zoom into **F6.6 (LiveView)** only. Its delivers line: F6.5's catalog made interactive without reloads —
`CatalogLive` streams from the facade, a two-stage mount, a live search box via `Portal.search_courses/1`, a
live create form. F6.6 is carried by exactly four artifacts:

1. **The roadmap line** — a row in `phoenix.roadmap.md`: *"F6.6 | interactivity (live search, live create,
   streams) | search as you type; create without a reload | `LiveViewTest` (`render_change`/`render_submit`)
   | does the interaction feel right?"* — answers *how it ships* (place in the order, demo, harness,
   feedback asked).
2. **The spec** — `f6.6.md` (Goal · Rationale (5W) · Scope · Deliverables · Invariants · Definition of Done)
   — answers *what & prove*.
3. **The stories** — `f6.6.stories.md` (`US0`…`US5`; Connextra + Given/When/Then, each tagged INVEST +
   priority + size) — answers *acceptance*.
4. **The agent brief** — `f6.6.llms.md` (references, requirements, execution topology, paste-ready prompt) —
   answers *agent instructions*.

## The proof — F6.6-US1 (the full acceptance set, verbatim from `rungs.md`)

Representative story — `F6.6-US1` (Search as I type):

> As a **learner**, I want the course list to filter as I type, so that I find a course without submitting or
> reloading.

Verbatim Given/When/Then (`F6.6-US1`):

> - Given the search box, when I type, then `phx-change="search"` fires `handle_event("search", params,
>   socket)`.
> - Given the event, when it runs, then it filters through the `Portal.search_courses/1` facade function (not
>   the `Catalog` context directly, per `f6.6.md` `## [RECONCILE]`, facade-only) and re-streams `:courses`
>   with `reset: true` (the list is `@streams.courses`, never an assign — INV4 — so the narrowing query drops
>   non-matches).
> - Given each keystroke, when handled, then the rendered list narrows without a reload, and the view names
>   only `Portal`.

Portal API kept EXACT (no-invent relaxed to the real F6 API): `Portal.search_courses/1`, `handle_event/3`,
`@streams.courses` / `stream/3` with `reset: true`. The view names only `Portal`.

## Hero interactive — the four-artifacts inspector for F6.6

**Inspect one artifact at a time.** A segmented control selects roadmap / spec / stories / brief. The figure
highlights the selected artifact; the readout names the file, its role, and the question that artifact
answers. Pure function over the four-artifact dataset.

- control ids: `#satArtifact` (segmented, `data-k` = roadmap|spec|stories|brief)
- pure function: `artifactCard(key) -> { file, role, question, gives }` (questions: how it ships / what &
  prove / what proves it / agent instructions)
- sample readout: "stories — f6.6.stories.md · the acceptance · answers: what proves it. Gives: US0–US5,
  each a Connextra story plus its Given/When/Then, tagged INVEST + priority + size. The proof A2.07.2 runs is
  F6.6-US1."

## Main interactive — the Given/When/Then acceptance runner

**Step the F6.6-US1 scenario.** A segmented control steps Given → When → Then. Each step reports PASS against
a fixed dataset modelling the search box, the fired event, and the re-stream — proving the slice is testable,
not asserted. Distinct from the hero: the hero enumerates the artifacts; the runner executes the proof in one
of them.

- control ids: `#satRun` (segmented, `data-k` = given|when|then)
- pure function: `runStep(step) -> { verdict:'PASS', label, detail }`
- sample readout: "WHEN · PASS — the event runs: it filters through Portal.search_courses/1 (the facade, not
  Catalog directly) and re-streams :courses with reset: true. The list is @streams.courses, never an assign
  (INV4)."
## Principle ↔ practice bridge

- principle: the contract is the spec — a slice is ready when its acceptance is written as Given/When/Then,
  so it is proven, not asserted. Splitting yields slices; the test is whether each one can be run.
- practice: F6.6-US1 — typing fires `phx-change="search"` → `handle_event("search", params, socket)` →
  `Portal.search_courses/1` → re-streams `:courses` with `reset: true`; the view names only `Portal`. The
  proof runs.
- take: a slice converges when its acceptance can be run — and on the Portal that proof is the verbatim
  Given/When/Then of the rung.

## References (Sources — real, vetted)

- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/

## Related (internal — must resolve)

- workshop hub; A2.07.1 vision-to-stories (prev); A2.07.3 order-the-backlog (next); A2.03 invest; A2 landing
- `/elixir/phoenix/liveview` — where F6.6 is built (in prose + Related)
- `/elixir/course` — the Portal's internals

## Pager

- prev: `/course/agile-agent-workflow/decomposition/workshop/vision-to-stories`
- next: `/course/agile-agent-workflow/decomposition/workshop/order-the-backlog`
