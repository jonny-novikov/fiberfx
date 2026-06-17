# A5.3 — Execution topology · module hub

- **Route:** `/course/agile-agent-workflow/brief/execution-topology`
- **File:** `html/agile-agent-workflow/brief/execution-topology/index.html`
- **Eyebrow:** `A5.3 · module hub`
- **Accent:** elixir-purple (chapter signature). **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / here.
- **Route-tag (segmented, clickable):** `course/agile-agent-workflow` (link) / `brief` (link) /
  `execution-topology` (rcur).

## Lead

The brief's third part. References named the sources and requirements numbered the testable statements (A5.2). Those
requirements imply a runtime shape and a build order — and the **execution topology** writes both down, plus the exact
files the agent touches. Topology answers the three things a spec leaves open about *how the code is assembled*: what
runs, in what order it is built, and in which files. With them fixed, a Claude Author assembles a system bottom-up
without guessing a tree, a sequence, or a path.

## Precise definition

The execution topology of an `.llms.md` brief is three pinned artifacts:

1. **The runtime shape** — the process / supervision tree and how a request flows through it.
2. **The task DAG** — the build order, each step leaving the app compiling.
3. **The file list** — the exact files created, edited, and deleted, and the boundary the agent does not cross.

Grounded on the Portal's real `f6.1.llms.md` `## Execution topology`.

### The runtime shape (verbatim from f6.1.llms.md)

Two app supervisors, both `:one_for_one`:

- `:portal` → `Portal.Application` supervises `[Portal.Store, Portal.EventStore.adapter(), {Portal.Engine, []}]`
  (the F5 three; Bandit dropped, four → three).
- `:portal_web` → `PortalWeb.Application` supervises `[PortalWeb.Telemetry, PortalWeb.Endpoint]` (new).

The `:portal_web → :portal` app dependency orders the boots, so the domain children are ready before the endpoint.

The request flow:

```text
Plug.Static → Plug.RequestId → Plug.Telemetry → Plug.Parsers → Plug.Session → PortalWeb.Router
  → pipeline :browser → scope "/" → CourseController.index/2 → Portal.courses_of/1 (the facade)
  → render CourseHTML :index | :error(422)
GET /health → 200 "ok"   (no domain call — the one path that skips the facade)
```

### The task DAG (verbatim from f6.1.llms.md)

```text
T1 deps + PortalWeb entrypoint
  → T2 PortalWeb.Endpoint (plug stack + LiveView socket)            [R1]
    → T3 wire Endpoint into Portal.Application AFTER the engine     [R2]
      → T4 PortalWeb.Router (:browser pipeline + courses route + /health)  [R3, R6]
        → T5 PortalWeb.CourseController.index/2 over Portal.courses_of/1    [R4, R8]
          → T6 PortalWeb.CourseHTML + index.html.heex + error template      [R5]
            → T7 verify: boot, render, /health, restart, invariant grep     [R7, R8]
```

"Each step leaves the app compiling."

## Dives into (the .mods grid — 3 cards, real routes)

- `A5.3.1 · /brief/execution-topology/runtime-shape` — *The runtime shape* — the two-supervisor tree and how a
  request flows through the plug stack to the facade.
- `A5.3.2 · /brief/execution-topology/the-task-dag` — *The task DAG* — `T1→T7`, each step leaving the app compiling;
  build out of order and a dependency breaks.
- `A5.3.3 · /brief/execution-topology/the-file-list` — *The file list* — the exact touched files, so the agent
  creates and edits the right ones and no others.

## Pager

- prev: `/course/agile-agent-workflow/brief` (A5 · The agent brief)
- next: `/course/agile-agent-workflow/brief/execution-topology/runtime-shape` (A5.3.1)

## Interactive 1 — hero (framing): the three parts of topology

- **Move taught:** what topology *is* — that it answers three distinct questions, one artifact each.
- **Element ids:** selector `#topoSel` (3 buttons `data-part="0..2"`), SVG `#topoSvg` (three stacked bands
  `#topo-0`/`#topo-1`/`#topo-2`), readout `#topoOut`.
- **Dataset:** `PARTS = [{name:'The runtime shape', q:'what runs', role:'the supervision tree and the request flow'},
  {name:'The task DAG', q:'in what order built', role:'T1→T7, each step compiling'}, {name:'The file list', q:'in
  which files', role:'the touched files and the boundary'}]`.
- **Pure functions:** `partAt(i)` returns the part; `questionFor(i)` returns the question it answers;
  `topoReadout(i)` builds the readout string.
- **Sample readout:** `Part 1 · The runtime shape — answers "what runs". The supervision tree and the request flow.
  Topology pins what runs, in what order it is built, and in which files — the three things a spec leaves open about
  how the code is assembled.`

## Interactive 2 — content (teaching): trace a request

- **Move taught:** a *consequence* of the runtime shape — every domain path reaches the facade through one call;
  `/health` is the one path that skips it.
- **Element ids:** stepper `#hopPrev` / `#hopNext`, route toggle `#routeSel` (2 buttons: `courses` / `health`), SVG
  `#hopSvg` (the plug-stack hops as nodes `#hop-0..#hop-7`), readout `#hopOut`.
- **Dataset:** `HOPS = ['Plug.Static','Plug.RequestId','Plug.Telemetry','Plug.Parsers','Plug.Session',
  'PortalWeb.Router','CourseController.index/2','Portal.courses_of/1']` (the courses path, verbatim from
  f6.1.llms.md); the health path stops at the router and returns `200 "ok"` with no domain call.
- **Pure functions:** `hopAt(i)` returns the hop label; `reachesFacade(route)` returns true for `courses`, false for
  `health`; `lastHopFor(route)` returns the terminal hop index for the chosen route; `hopReadout(route, i)` builds
  the readout.
- **Sample readout:** `Hop 8 of 8 · Portal.courses_of/1 — the only domain call. The /courses/:user_id path reaches
  the facade through one call; /health returns 200 "ok" with no domain call — the one path that skips it.`

## Bridge + take

- **Principle (idea):** the topology fixes the runtime shape, the build order, and the files — the three things a spec
  leaves open about how the code is assembled.
- **Practice (elix):** `f6.1.llms.md` pins the two-supervisor tree, the `T1→T7` order, and the touched-file list, so
  the agent assembles bottom-up.
- **Take:** Topology is the difference between "build this" and "build this, in this shape, in this order, here."

## /elixir cross-link

- In-prose: `/elixir/phoenix/lifecycle` (the request lifecycle the topology describes).
- Related-in-course: `/elixir/phoenix/lifecycle` (+ `/elixir/phoenix/contexts` for the facade boundary).

## References — Sources (3)

- The `llms.txt` convention → `https://llmstxt.org/`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
