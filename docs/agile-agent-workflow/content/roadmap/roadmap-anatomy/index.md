# A3.3 · Anatomy of a roadmap.md — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/roadmap-anatomy`
- **File:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/index.html`
- **Accent:** elixir-purple (`.ex`). **Stamp:** `TSK0Ng9hnHJgW0`.
- **Pager:** prev = `/course/agile-agent-workflow/roadmap` (the chapter landing); next = `…/roadmap-anatomy/what-it-carries` (the module's own first dive).

## Lead

A chapter roadmap is not a to-do list. It is a structured document with named parts, and reading a real one part
by part is the fastest way to learn to write your own. The exemplar is the Portal's real web chapter — F6 (Phoenix)
— and its `phoenix.roadmap.md`: nine rungs `f6.1…f6.9`, three milestones, each rung a line that points at a spec
and defines no behaviour, all under one master invariant.

## The six parts a roadmap carries (verbatim section names from `phoenix.roadmap.md`)

1. **What we are delivering** — the deliverable: "The Portal, served to people: a real web application…".
2. **Where this starts and ends** — the start/end handoff: "Start (the F5 handoff)" → "End (after F6.9)".
3. **Architecture decision — standard Phoenix on the BEAM** — the one structural choice, with its reasoning and its
   reversible cost.
4. **The delivery arc** — the milestones: three, "1 · Ship the catalog", "2 · Make it live", "3 · Ship to users".
5. **Per-rung iterations** — the per-iteration table: rung · ships · demo · harness · feedback asked.
6. **Seams & open decisions** — the open decisions, named not resolved (auth, deployment, dashboard data, …).

Over all of them sits the master invariant (verbatim): "The web layer calls only the `Portal` facade and renders
only the closed `%Portal.Error{}` set. No controller, LiveView, plug, or template names `Portal.Engine`, a repo, or
`GenServer.call`."

## Framing interactive (hub) — the six-part anatomy selector

- **Hero figure.** A part selector over the six real section names. Selecting a part highlights it in an SVG outline
  of the roadmap and shows, in the readout, that part's role and a verbatim phrase from the real file.
- **Element ids:** controls `#anaPick` (six buttons, `data-k` ∈ {delivering, handoff, arch, milestones, table, decisions}),
  SVG `#anaMap`, readout `#anaOut` (`aria-live="polite"`).
- **Pure function:** `partRole(key) -> {label, quote, role}` over a fixed `PARTS` dataset (each entry holds the
  verbatim phrase from `phoenix.roadmap.md`). No mutation; readout = `PARTS[key].role`.
- **Sample readout:** "Per-rung iterations — the per-iteration table: each row is one rung, what it ships, its demo,
  its harness, and the feedback asked. Verbatim: 'each a PR-sized increment'."

## The three dives (≥3, the arc)

| Dive | Title | Route | Arc step |
|---|---|---|---|
| A3.3.1 | What it carries | `…/roadmap-anatomy/what-it-carries` | what a roadmap carries |
| A3.3.2 | The iteration table | `…/roadmap-anatomy/the-iteration-table` | the per-iteration table |
| A3.3.3 | The open decisions | `…/roadmap-anatomy/open-decisions` | the open decisions |

## Bridge (principle → Portal practice)

- **Principle:** A roadmap has a fixed anatomy — deliverable, handoff, architecture decision, milestones, the
  per-iteration table, and the explicitly-named open decisions — and reading those parts is how you learn to write
  one.
- **Portal practice:** `phoenix.roadmap.md` carries all six, under the master invariant. Each rung points at a spec
  and defines no behaviour.

## References — Sources (verbatim, real URLs)

- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

## Related in this course (resolving)

- `/course/agile-agent-workflow/roadmap` — the chapter.
- `/course/agile-agent-workflow/roadmap/the-roadmap-layer` — the anatomy this module expands.
- `/course/agile-agent-workflow/why/two-layers` — roadmap over spec.
- `/course/agile-agent-workflow/what/four-artifacts` — the four artifacts.
- `/elixir/phoenix` — the real F6 chapter.
- `/elixir/course` — the companion course.
