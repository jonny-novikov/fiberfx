# A3.9.1 · The glossary — the expandable index

- **Route:** `/course/agile-agent-workflow/roadmap/glossary/glossary`
- **File:** `html/agile-agent-workflow/roadmap/glossary/glossary.html`
- **Numbering:** A3.9 · dive 1 (of 3)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The full expandable accordion. Every key term the course relies on, each with a one-line abstract, its
Source, and a link to the `/elixir/phoenix/<sub>` chapter where the framework implements the idea. The
list degrades: every term and its abstract are present in static markup; JS only enhances expand and
collapse. No browser storage.

## Precise definition (the `TERMS` dataset)

A glossary entry is `{term, category, abstract, source, sourceUrl, elixirRoute, elixirLabel}`. The
fifteen terms (≥12 required):

1. **value ladder** — decomposition — an ordered sequence of user stories, each a thin vertical slice that
   delivers value, climbing from the simplest shippable thing to the full feature. Source: User Stories
   Applied. Framework: `/elixir/phoenix` (the F6 value ladder of nine rungs).
2. **vertical slice** — decomposition — a unit of work that cuts top to bottom (UI to data) and delivers a
   capability a real role can use, rather than a horizontal technical layer. Source: User Stories Applied.
   Framework: `/elixir/phoenix/liveview` (a slice from the live page to the facade).
3. **INVEST** — decomposition — six tests for a good story: Independent, Negotiable, Valuable, Estimable,
   Small, Testable. Source: INVEST in Good Stories. Framework: `/elixir/phoenix` (every F6 rung is one
   small, valuable, testable slice).
4. **Given/When/Then** — spec — the Gherkin form of an acceptance criterion: a precondition, an action, and
   the observable result. Source: Gherkin reference. Framework: `/elixir/phoenix/liveview` (the
   `render_change`/`render_submit` LiveView tests encode it).
5. **the spec triad** — spec — the three files that define one rung: the spec, its user stories, and the
   agent brief — the single source of truth a rung is built from. Source: Specification by Example.
   Framework: `/elixir/phoenix/contexts` (each context built from its rung's triad).
6. **correct by definition** — spec — a rung is done when a closure over its traced, executed checks holds —
   not when it looks finished. Source: Specification by Example. Framework: `/elixir/phoenix/ecto` (the
   F6.3 changeset is the parse boundary the checks run against).
7. **master invariant** — spec — one rule that holds at every rung; for F6, the web layer calls only the
   `Portal` facade and renders only the closed `%Portal.Error{}` set. Source: The Pragmatic Programmer.
   Framework: `/elixir/phoenix` (the F6 master invariant).
8. **roadmap.md** — delivery — the delivery plan: an ordered list of rungs grouped into milestones, each
   line pointing at a spec and defining no behaviour. Source: Continuous Delivery. Framework:
   `/elixir/phoenix` (the F6 `phoenix.roadmap.md`).
9. **thin but robust** — delivery — each rung is a narrow vertical slice built to production quality, not a
   prototype: harnessed, over the facade, supervised. Source: The Pragmatic Programmer. Framework:
   `/elixir/phoenix/lifecycle` (the F6.1 endpoint rung — thin, but a supervised child).
10. **tracer bullet** — delivery — a minimal end-to-end path through every layer, fired early to confirm the
    architecture connects before the layers are filled in. Source: The Pragmatic Programmer. Framework:
    `/elixir/phoenix/lifecycle` (F6.1: request → facade → render, the first end-to-end shot).
11. **walking skeleton** — delivery — the smallest implementation that exercises the whole architecture end
    to end and stays runnable as it grows. Source: Continuous Delivery. Framework:
    `/elixir/phoenix/routing` (the route surface that wires the skeleton together).
12. **the four artifacts** — spec — the spec, the user stories, the agent brief, and the tests — the spec is
    the source; stories and brief are derived from it; the tests are built to it. Source: Specification by
    Example. Framework: `/elixir/phoenix/contexts` (the context code built to the four artifacts).
13. **inspect-and-adapt** — loop — the Agile loop run per rung: ship, demo, take feedback, adapt — feedback
    edits the spec, the build follows. Source: Extreme Programming Explained. Framework:
    `/elixir/phoenix/liveview` (each interactive rung demoed and adapted before the next).
14. **the Author/Operator loop** — loop — the cadence of one rung: the Operator sequences, decomposes, and
    accepts; the Author implements the well-specified slice. Source: Anthropic — Building effective agents.
    Framework: `/elixir/phoenix/contexts` (the contexts an Author builds to an Operator's brief).
15. **deploy as a release** — loop — the live increment: the same engine deployed unchanged as a clustered
    release behind authentication, the loop's end state. Source: Continuous Delivery. Framework:
    `/elixir/phoenix/deployment` (the F6.8 release rung).

## Worked Portal example

Expand **master invariant**. The accordion shows: the abstract (one rule at every rung; for F6, the web
calls only the `Portal` facade and renders only `%Portal.Error{}`), the Source (The Pragmatic Programmer),
and a link to `/elixir/phoenix` where the framework holds that rule across all nine rungs. The entry is
not the lesson — it is the locator. Collapse it; expand **tracer bullet**; the same three faces appear,
pointing at `/elixir/phoenix/lifecycle`.

## Interactive 1 — hero — the accordion (the real expandable index)

- **Move:** the core operation — expand a term to reveal its abstract, Source, and framework link.
- **Markup:** a `<dl>`/`<details>`-free accordion built from buttons + panels, rendered in static markup
  from the `TERMS` dataset (every term + abstract visible without JS). A `.solid-select` of category
  filters narrows which terms show. Expand/collapse is JS-enhanced; without JS every panel is open
  (the static fallback shows all). The hero figure carries a compact 4-term sample accordion; the full
  list is the main interactive below.
- **Control ids:** `glAcc` (the accordion container), each row button `acc-btn-<i>`, panel `acc-panel-<i>`,
  readout `accOut`.
- **Pure functions over `TERMS`:**
  - `expandedCount(state) -> int` — how many panels are open.
  - `readoutFor(term) -> string` — the last-expanded term's abstract + Source + framework label.
- **Degrade:** static markup has every `acc-panel-*` visible (no `hidden`); the JS adds `html.js` gating so
  panels collapse only when JS runs. No storage.
- **Sample readout:** `Expanded: master invariant — one rule at every rung; for F6, the web calls only the
  Portal facade and renders only %Portal.Error{}. Source: The Pragmatic Programmer. Implemented in F6 (the
  Phoenix chapter).`

## Interactive 2 — main — the full accordion + a term lookup (distinct move: search)

- **Move:** look up a term by typing — distinct from clicking to expand. A text filter narrows the visible
  rows; the readout reports the match count and the first match's framework route.
- **Markup:** an `<input type="text">` (`glFilter`) over the full 15-row accordion; pure filtering by
  substring of term + abstract. Without JS the input is inert and all rows show (degrades).
- **Control ids:** `glFilter` (the text input), full accordion `glFull`, rows `row-<i>`, readout `filterOut`.
- **Pure functions over `TERMS`:**
  - `matches(query) -> [int]` — indices whose term or abstract contains the query (case-insensitive).
  - `readoutFor(query) -> string` — the count and the first match's term + `/elixir` route.
- **Sample readout:** `"slice" matches 2 terms. First: value ladder → implemented in F6 (the Phoenix
  chapter). Each match links to where the framework implements it.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** a glossary is a degradable index — every term legible without a script, the
  script only an enhancement that folds the list for scanning.
- **.arrow**
- **.cell.elix (Portal practice):** each term resolves to the real Portal: a link to the
  `/elixir/phoenix/<sub>` chapter where the framework implements the idea, every link 200.
- **.take:** the glossary is the course made lookupable — a fixed list of terms, each to an abstract, a
  Source, and the framework chapter that makes it concrete.

## References

### Sources
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Specification by Example — https://gojko.net/books/specification-by-example/
- Continuous Delivery — https://continuousdelivery.com/

### Related in this course
- A3.9 — Glossary (hub) (`/course/agile-agent-workflow/roadmap/glossary`)
- A3.9.2 — The annotated sources (`/course/agile-agent-workflow/roadmap/glossary/sources`)
- A3.9.3 — The idea→framework crosswalk (`/course/agile-agent-workflow/roadmap/glossary/crosswalk`)
- A2 — Decomposition (`/course/agile-agent-workflow/decomposition`)
- F6 — The Portal on the web (`/elixir/phoenix`)

## Wiring

- Route-tag (5 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) · `glossary`(link) · `glossary`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap/glossary` · next = `/course/agile-agent-workflow/roadmap/glossary/sources`.
- Framework links (all 200): `/elixir/phoenix`, `/elixir/phoenix/lifecycle`, `/elixir/phoenix/routing`,
  `/elixir/phoenix/ecto`, `/elixir/phoenix/contexts`, `/elixir/phoenix/liveview`, `/elixir/phoenix/deployment`.
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
