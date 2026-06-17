# A3.9.3 · The idea→framework crosswalk — where each idea lands in the code

- **Route:** `/course/agile-agent-workflow/roadmap/glossary/crosswalk`
- **File:** `html/agile-agent-workflow/roadmap/glossary/crosswalk.html`
- **Numbering:** A3.9 · dive 3 (of 3)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The idea→framework map. Each course idea, mapped to the `/elixir/phoenix/<sub>` chapter that implements it
— the F6 rungs run as built code. The crosswalk is where the course's abstractions become routes you can
open: lifecycle, routing, ecto, contexts, heex, liveview, pubsub, deployment, live-dashboard, each 200.

## Precise definition (the `CROSSWALK` dataset)

A crosswalk row is `{idea, rung, sub, route, ships}` — the course idea, the F6 rung that realises it, the
`/elixir/phoenix/<sub>` chapter, and what that rung ships. The nine rungs, verbatim from
`docs/elixir/specs/phoenix/phoenix.roadmap.md`:

1. **the tracer bullet / served app** → F6.1 → `/elixir/phoenix/lifecycle` — the engine served as a web app:
   request → facade → render, the first end-to-end shot.
2. **the walking skeleton / route surface** → F6.2 → `/elixir/phoenix/routing` — read/write/REST/live routes,
   pipelines, and plugs; the skeleton wired together.
3. **durable persistence** → F6.3 → `/elixir/phoenix/ecto` — the Postgres adapter behind the F5 port; data
   survives a restart; the changeset is the parse boundary (correct by definition).
4. **the domain over the facade** → F6.4 → `/elixir/phoenix/contexts` — `Catalog`/`Enrollment`/`Accounts`;
   the web reads and writes real domain through one boundary per context.
5. **the rendered catalog** → F6.5 → `/elixir/phoenix/heex` — the index, the `course_card`, the form, inline
   errors; the catalog browsable in HEEx.
6. **interactivity / inspect-and-adapt** → F6.6 → `/elixir/phoenix/liveview` — live search and live create
   without reloads; each interactive rung demoed and adapted.
7. **multi-client live updates** → F6.7 → `/elixir/phoenix/pubsub` — PubSub and Presence; two windows, one
   creates, the other updates live, with a viewer count.
8. **deploy as a release** → F6.8 → `/elixir/phoenix/deployment` — real users behind auth on a deployed,
   clustered release.
9. **the operations dashboard** → F6.9 → `/elixir/phoenix/live-dashboard` — a dashboard folding live events,
   under auth, clustered.

The master invariant spans all nine: the web calls only the `Portal` facade and renders only the closed
`%Portal.Error{}` set.

## Worked Portal example

The crosswalk is the F6 `phoenix.roadmap.md` read as a lookup table. Take "durable persistence": the
roadmap line is F6.3, the milestone is "ship the catalog", the spec it points at is the F6.3 triad, and
the behaviour the line defines is **none** — the line orders the work; the spec defines it. Open
`/elixir/phoenix/ecto` and the idea is built code: the Postgres adapter behind the F5 port, the changeset
the parse boundary. Every row of the crosswalk runs the same: idea → rung → route → built code.

## Interactive 1 — hero — the idea→rung locator (pick an idea, get its route)

- **Move:** select a course idea, get the F6 rung and the `/elixir` route that implements it.
- **Markup:** a `.solid-select` of idea buttons over an SVG ladder of nine rung nodes F6.1–F6.9; the chosen
  idea lights its rung and the readout names the route + what it ships. Every idea→route pair in static markup.
- **Control ids:** `ideaSel` (button group), rung nodes `rung-1`…`rung-9`, readout `ideaOut`.
- **Pure functions over `CROSSWALK`:**
  - `rungFor(idea) -> int` — the rung index (1–9).
  - `readoutFor(idea) -> string` — the idea, the rung, the route, and what it ships.
- **Default selection:** the tracer bullet (F6.1).
- **Sample readout:** `Idea "durable persistence" → F6.3 → /elixir/phoenix/ecto: the Postgres adapter behind
  the F5 port; data survives a restart; the changeset is the parse boundary.`

## Interactive 2 — main — the milestone grouper (distinct move: rungs → milestones)

- **Move:** group the nine rungs into the three shippable milestones — distinct from the per-idea lookup.
  Select a milestone, see which rungs and routes ship in it and what you can do at its end.
- **Markup:** a `.solid-select` of three milestone buttons (ship-the-catalog · make-it-live · ship-to-users)
  over the same nine-rung SVG ladder; the chosen milestone lights its rungs and the readout lists them.
- **Control ids:** `mileSel` (button group), rung nodes shared with hero (`rung-1`…`rung-9`) — note: distinct
  SVG instance with its own ids `mrung-1`…`mrung-9` to avoid duplicate ids, readout `mileOut`.
- **Pure functions over a fixed `MILESTONES` array (key/label/rungs[]/end-state):**
  - `rungsIn(key) -> [int]` — the rung indices in the milestone.
  - `readoutFor(key) -> string` — the milestone, its rungs and routes, and the end-state.
- **Sample readout:** `Milestone 1 · Ship the catalog → F6.1–F6.5 (lifecycle, routing, ecto, contexts,
  heex). At the end: browse a persistent catalog and add courses, server-rendered, with inline errors.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** a roadmap line orders the work and points at a spec; it defines no behaviour —
  re-ordering the rungs never edits a spec.
- **.arrow**
- **.cell.elix (Portal practice):** the F6 `phoenix.roadmap.md` is exactly that — nine lines, three
  milestones, each pointing at a rung's spec and its `/elixir/phoenix/<sub>` chapter, defining no behaviour.
- **.take:** the crosswalk turns the course into routes — every idea to a rung, every rung to a chapter of
  built code, all of it under one master invariant.

## References

### Sources
- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

### Related in this course
- A3.9 — Glossary (hub) (`/course/agile-agent-workflow/roadmap/glossary`)
- A3.9.1 — The glossary (`/course/agile-agent-workflow/roadmap/glossary/glossary`)
- A3.9.2 — The annotated sources (`/course/agile-agent-workflow/roadmap/glossary/sources`)
- A3 — The roadmap layer (`/course/agile-agent-workflow/roadmap`)
- F6 — The Portal on the web (`/elixir/phoenix`)

## Wiring

- Route-tag (5 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) · `glossary`(link) · `crosswalk`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap/glossary/sources` · next = `/course/agile-agent-workflow/roadmap/glossary` (back to hub).
- Framework links (all 200): `/elixir/phoenix/{lifecycle,routing,ecto,contexts,heex,liveview,pubsub,deployment,live-dashboard}`.
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
