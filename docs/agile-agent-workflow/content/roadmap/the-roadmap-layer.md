# A3 · The roadmap layer — why a delivery layer, and what a roadmap.md is

- **Route:** `/course/agile-agent-workflow/roadmap/the-roadmap-layer`
- **File:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`
- **Numbering:** A3 · orientation dive 2 (of 3)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`
- **Title:** "Why a delivery layer, and what a roadmap.md is."

## Lead

The second orientation dive of A3. The first dive (`where-we-are`) located the reader and named
WHERE the roadmap sits and WHO acts. This dive answers the next two questions: **WHY** delivery
deserves its own layer, and **WHAT** a `roadmap.md` actually is. It expands the separation A1.04
drew — *how we deliver* (the roadmap) versus *what we build and prove* (the spec) — into the reason
the two are kept apart, and shows the artifact that holds the delivery side: a real `roadmap.md`,
modelled byte-for-byte on the Portal's F6 `phoenix.roadmap.md`.

## Precise definition

**WHY a roadmap layer.** Delivery and definition change on different cadences and answer different
questions. *Definition* answers "what is this rung, and how do we know it is right" — it is the
single source of truth, edited only by feedback. *Delivery* answers "in what order, at what size, to
what milestone do the rungs ship" — and that order moves constantly as the loop learns. If the two
share one artifact, every re-order risks editing a definition, and the spec stops being trustworthy.
Separating them means the order can change under feedback without ever touching what "done" means.
This is the A1.04 separation, now given its motive: a roadmap layer exists so the spec stays the
single source of truth while the plan above it stays cheap to re-order.

**WHAT a roadmap.md is.** A `roadmap.md` is an ordered set of thin-but-robust increments (rungs)
grouped into milestones. Each rung is one line that *points at* a spec and defines no behaviour of
its own — an intent, a demo, and a definition of done, with the contract living one layer down in
the spec the line references. A milestone is a group of rungs that together ship something a real
role can use end to end. The whole file carries one master invariant — the architectural rule every
rung must hold — and a delivery arc that names the order. Nothing in a `roadmap.md` defines
behaviour; it is a map of *order*, not of *meaning*.

## Worked Portal example — the F6 `phoenix.roadmap.md`

The Portal's web chapter (the companion `/elixir` F6) ships from a real `roadmap.md`. It carries
nine rungs (`f6.1`…`f6.9`), grouped into three milestones, over an engine that never changes:

- **Milestone 1 · Ship the catalog** — `f6.1` endpoint, `f6.2` routing, `f6.3` Postgres adapter,
  `f6.4` contexts, `f6.5` rendered catalog. At the end: browse a persistent catalog and add courses.
- **Milestone 2 · Make it live** — `f6.6` interactivity (live search and create), `f6.7` multi-client
  live updates and a viewer count. At the end: search and create with no reloads; every client updates.
- **Milestone 3 · Ship to users** — `f6.8` auth and a deployed clustered release, `f6.9` an operations
  dashboard. At the end: sign in, run behind auth, watch a live dashboard.

Each rung is a line that points at its spec triad (`f6.N.md` / `.stories.md` / `.llms.md`) and
defines no behaviour itself. The master invariant comment governs every rung:

```
# F6 · phoenix.roadmap.md — the Portal on the web. Order only; each rung points at its spec.
#
# master invariant: the web layer calls only the Portal facade and renders only %Portal.Error{}.

## Milestone 1 · Ship the catalog
  f6.1  endpoint      → f6.1.md     # done: GET / renders a page over the facade
  f6.2  routing       → f6.2.md     # done: read/write/live routes + pipelines
  f6.3  Postgres      → f6.3.md     # done: catalog survives a restart
  f6.4  contexts      → f6.4.md     # done: the web reads and writes real domain
  f6.5  catalog view  → f6.5.md     # done: browse and create with inline errors

## Milestone 2 · Make it live
  f6.6  interactivity → f6.6.md     # done: search and create without a reload
  f6.7  PubSub        → f6.7.md     # done: two clients update live; a viewer count

## Milestone 3 · Ship to users
  f6.8  auth & deploy → f6.8.md     # done: sign in; a deployed clustered release
  f6.9  dashboard     → f6.9.md     # done: an operations dashboard, live, under auth
#
# Re-order within the master invariant; not one f6.N.md spec changes when the order does.
```

A line names a rung, its demo and definition of done, and the spec it points at — and stops there.
The behaviour of `f6.1` lives in `f6.1.md`, never in the roadmap line. So the Operator can promote,
drop, or split a rung and not one spec moves; the engine under all nine rungs is the unchanged
`Portal` facade.

## Interactive 1 — hero — anatomy of one roadmap line (show what a line is and is not)

- **Move:** show what a roadmap line *is* and *is not*. A roadmap line names a rung, a milestone, and
  the spec it points at — and defines zero behaviour. Selecting a line decomposes it into those parts.
- **Markup:** a `.solid-select` of the nine real F6 rungs (`f6.1`…`f6.9`); an SVG that renders the
  selected line decomposed into four labelled cells: {rung id, milestone, the spec it points at,
  "behaviour defined here = none"}. `f6.1` pre-selected.
- **Control ids:** `lineSel` (the button group, nine `button[data-rung]`), readout `lineOut`, SVG
  cells `ln-rung` / `ln-ms` / `ln-spec` / `ln-beh`.
- **Pure functions over a fixed `RUNGS` array (id/intent/milestone/spec/dod):**
  - `partsOf(i) -> {rung, milestone, spec, behaviour:"none"}` — decompose the line at index `i`.
  - `readoutFor(i) -> string` — id · intent · milestone · → spec · behaviour defined here = none.
- **Default selection:** `f6.1` (index 0).
- **Sample readout:** `f6.1 — "the engine served as a web app" · milestone 1 · Ship the catalog →
  points at f6.1.md (done: GET / renders a page over the facade). Behaviour defined in this line:
  none — the contract lives in the spec it points at.`

## Interactive 2 — main — re-order without redefining (prove the WHY)

- **Move:** prove the WHY — order is decoupled from definition. A small ordered list of rungs with a
  re-sort by value / risk / dependency; a pure function recomputes the delivery order while a "spec
  edits" counter stays pinned at **0**. Distinct from the hero: the hero anatomises one line; this
  one proves the consequence across the whole list.
- **Markup:** a `.solid-select` of three orderings (`by value` / `by risk` / `by dependency`); an SVG
  row of five rung cards (a representative slice of the F6 ladder) repositioned by the chosen key; a
  pinned "spec edits = 0" counter that never moves.
- **Control ids:** `reSort` (three `button[data-k]`), readout `reOut`, the five card groups
  `re-card-0`…`re-card-4`, the counter `re-count`.
- **Pure functions over a fixed `RUNGS5` array (card/value/risk/dep):**
  - `order(key) -> [int]` — the five card indices stably sorted by `key` (value/risk descending,
    dependency ascending); stable on ties.
  - `specEdits(_key) -> 0` — re-ordering edits zero specs; the count is invariant under any ordering.
  - `readoutFor(key) -> string` — re-ordered by `key`; the delivery order changed; spec edits = 0.
- **Invariant proven:** any re-order changes only the delivery order; `specEdits` is identically 0 for
  every key. Order is decoupled from definition.
- **Sample readout:** `Re-ordered by dependency — the delivery order changed; spec edits = 0. A
  roadmap line points at a spec; re-ordering the plan never edits one.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** Plan how you deliver, separately from what you build. Delivery order
  changes constantly under feedback; the definition of a rung changes only when feedback edits it. Keep
  them in separate layers and the plan stays cheap while the definition stays trustworthy.
- **.arrow**
- **.cell.elix (Portal practice):** `phoenix.roadmap.md` orders nine rungs (`f6.1`…`f6.9`) into three
  milestones over an unchanged engine — each line points at its spec triad and defines no behaviour, so
  the order re-plans without touching one spec.
- **.take:** A `roadmap.md` is a map of order, not of meaning — it points at the specs, defines none,
  and re-orders freely; that separation is the whole reason the delivery layer is kept apart.

## References

### Sources
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/ — keeping the system
  releasable at every increment; the delivery discipline a roadmap layer plans.
- Beck, K. — *Extreme Programming Explained* — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
  — small batches and the planning game: rungs ordered by value and risk, re-ordered as you learn.
- Hunt & Thomas — *The Pragmatic Programmer* — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
  — thin-but-robust increments and orthogonality: keeping the plan independent of the definition.

### Related in this course
- A1.04 — Two layers: roadmap and specs (`/course/agile-agent-workflow/why/two-layers`) — the
  separation this dive expands (primary).
- A0.2.2 — The four artifacts (`/course/agile-agent-workflow/what/four-artifacts`) — the per-rung
  artifacts a roadmap line points at.
- A0.2 — The two-layer model (`/course/agile-agent-workflow/what/two-layer-model`) — the layer model
  named earlier.
- A2 — Decomposition (`/course/agile-agent-workflow/decomposition`) — the backlog this layer sequences.
- Companion — Phoenix (F6) (`/elixir/phoenix`) — the real chapter built from a `phoenix.roadmap.md`.
- A3 — The roadmap layer (`/course/agile-agent-workflow/roadmap`) — the chapter landing.
- Companion — Functional Programming in Elixir (`/elixir/course`) — the Portal's Elixir foundations.

## Wiring

- Route-tag (4 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) ·
  `the-roadmap-layer`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap/where-we-are` · next =
  `/course/agile-agent-workflow/roadmap/the-road-ahead`. Both siblings are authored in parallel — a
  `links` FAIL on those two routes is expected until they land.
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
