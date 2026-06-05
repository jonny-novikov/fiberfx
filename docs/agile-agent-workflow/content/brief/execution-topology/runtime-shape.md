# A5.3.1 — The runtime shape

- **Route:** `/course/agile-agent-workflow/brief/execution-topology/runtime-shape`
- **File:** `html/agile-agent-workflow/brief/execution-topology/runtime-shape.html`
- **Eyebrow:** `A5.3.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / The runtime shape.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) /
  `execution-topology` (link) / `runtime-shape` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/execution-topology` · next
  `/course/agile-agent-workflow/brief/execution-topology/the-task-dag`.

## Lead

Execution topology is the third part of the brief. Its first piece is the **runtime shape**: a picture of the
system while it runs — what processes exist, who supervises them, in what order they boot, and how a request
flows from the front door to the domain and back. A spec says *what* a rung must do; the runtime shape says what
the running system looks like, so a Claude Author reproduces the tree the brief draws rather than a tree it
invents.

## The precise definition

The runtime shape names two things and fixes both:

1. **The supervision tree** — the OTP processes and the supervisor over each, with a restart strategy.
2. **The request path** — the ordered hops a request takes from the endpoint through the plug stack to the one
   domain entry point, the facade.

For the Portal's web bootstrap, `f6.1.llms.md` pins this exactly. The tree splits across **two** app
supervisors, each `strategy: :one_for_one`:

- `:portal` app — `Portal.Application` supervises `[Portal.Store, Portal.EventStore.adapter(), {Portal.Engine, []}]`
  (the F5 three, with `Bandit` dropped at F6.1).
- `:portal_web` app — `PortalWeb.Application` supervises `[PortalWeb.Telemetry, PortalWeb.Endpoint]` (new at F6.1).

The boundary is an **app-level dependency arrow**, `:portal_web → :portal`: the umbrella's app-dependency
ordering boots `:portal` first, so the three domain children are ready before the endpoint. The request flows
`Plug.Static → Plug.RequestId → Plug.Telemetry → Plug.Parsers → Plug.Session → PortalWeb.Router →
CourseController.index/2 → Portal.courses_of/1`. The health route is the only path that does not reach the
facade.

## The worked F6 example (verbatim ids)

Grounds on the `## Execution topology` runtime block of `f6.1.llms.md` and quotes **F6.1-R2** verbatim:

> **F6.1-R2** — the tree splits across two app supervisors, each `strategy: :one_for_one`.
> `Portal.Application.start/2` supervises `[Portal.Store, Portal.EventStore.adapter(), {Portal.Engine, []}]` …
> with the `Bandit` child **dropped** (four → three). The new `PortalWeb.Application.start/2` supervises
> `[PortalWeb.Telemetry, PortalWeb.Endpoint]`. The `:portal_web` → `:portal` app dependency orders the boots, so
> the three domain children are ready before the endpoint. [US: F6.1-US1, F6.1-US3, F6.1-US4]

The request-flow line quoted verbatim from the runtime block:
`Plug.Static → Plug.RequestId → Plug.Telemetry → Plug.Parsers → Plug.Session → PortalWeb.Router`, then
`CourseController.index/2 ──calls──▶ Portal.courses_of/1`, and `GET /health → 200 "ok"` with **no domain call**.

The F6.1-era route quoted in the worked example is `GET /courses/:user_id` — this is a verbatim citation of
`f6.1.llms.md`, kept as the source has it; the page does not claim it is the current route.

## Interactives — TWO, teaching different moves

### Hero (framing): the supervision tree

- **Move taught:** read the supervision tree — which children each supervisor owns and the boot order the app
  dependency enforces.
- **Dataset (fixed, from `f6.1.llms.md`):** two supervisors and their children —
  `:portal` → `[Portal.Store, Portal.EventStore.adapter(), {Portal.Engine, []}]`;
  `:portal_web` → `[PortalWeb.Telemetry, PortalWeb.Endpoint]`. Both `:one_for_one`.
- **Element ids:** selector `#supSel` (buttons `data-sup="portal"`, `data-sup="portal_web"`); SVG `#supSvg` with
  highlighted child groups `#sup-child-0..2` (portal) and the readout count text `#sup-count`; readout
  `#supOut` (`aria-live="polite"`).
- **Pure functions:**
  - `childrenOf(sup)` → array of child labels for the chosen supervisor.
  - `childCount(sup)` → integer child count (3 for `portal`, 2 for `portal_web`).
  - `bootOrder()` → the fixed boot order string `store → engine → endpoint` (the app dependency enforces it).
  - `supReadout(sup)` → readout string.
- **Sample readout (default, `portal`):** *":portal — Portal.Application (:one_for_one) supervises 3 children:
  Portal.Store, Portal.EventStore.adapter(), {Portal.Engine, []}. The :portal_web → :portal app dependency boots
  the domain first: store → engine → endpoint."*

### Content (teaching): which path reaches the facade

- **Move taught:** trace a request to its one domain entry point — which route reaches `Portal.courses_of/1`,
  and which path skips the facade entirely.
- **Dataset (fixed, from `f6.1.llms.md`):** two request paths —
  `GET /courses/:user_id` → through the plug stack to `Portal.courses_of/1`;
  `GET /health` → `200 "ok"`, no domain call.
- **Element ids:** selector `#pathSel` (buttons `data-route="courses"`, `data-route="health"`); SVG `#pathSvg`
  with hop chain rects `#hop-0..5` and a terminal facade node `#path-end`; readout `#pathOut`
  (`aria-live="polite"`).
- **Pure functions:**
  - `reachesFacade(route)` → boolean: `true` for `courses`, `false` for `health`.
  - `hopsFor(route)` → array of hop labels for the chosen route (the plug stack + the terminal).
  - `terminalOf(route)` → the terminal label (`Portal.courses_of/1` or `200 "ok"`).
  - `pathReadout(route)` → readout string.
- **Sample readout (default, `courses`):** *"GET /courses/:user_id reaches the facade: yes — through the plug
  stack to Portal.courses_of/1, the one domain entry point. GET /health returns 200 with no domain call — the one
  path that skips the facade."*

Both interactives degrade: the SVG, the selector buttons, and a correct default readout are in static markup; JS
only enhances. No browser storage. `prefers-reduced-motion` honoured by the shared reveal script.

## The bridge + take

- **Principle (`.cell.idea`):** the runtime shape names what runs and how a request flows, so the agent builds
  the tree and the path the brief draws, not a tree it invents.
- **Portal (`.cell.elix`):** `f6.1.llms.md` pins two `:one_for_one` supervisors and the boundary as an app-level
  dependency arrow `:portal_web → :portal`; every domain path reaches the facade, and only `/health` skips it.
- **Take:** *The runtime shape is the brief's picture of the running system the agent must reproduce.*

## In-prose `/elixir` cross-link

`/elixir/phoenix/lifecycle/endpoint` — the endpoint at the top of the `:portal_web` tree, taught in the
companion course's request lifecycle.

## References

### Sources (3)
- `https://llmstxt.org/` — llmstxt.org — *The /llms.txt convention* — the links-first machine-brief form that
  carries the runtime topology.
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — Hunt &
  Thomas — *The Pragmatic Programmer* — design by contract: pin the runtime shape so the builder reproduces it.
- `https://www.anthropic.com/engineering/building-effective-agents` — Anthropic — *Building effective agents* —
  why a coding agent needs the running shape fixed, not an open-ended goal.

### Related in this course
- `/course/agile-agent-workflow/brief/execution-topology` — A5.3 · the module hub.
- `/course/agile-agent-workflow/brief` — A5 · the chapter landing.
- `/course/agile-agent-workflow/spec` — A4 · the spec a runtime shape derives from.
- `/elixir/phoenix/lifecycle` — Companion · the request lifecycle the runtime shape describes.
