# A5.3.2 — The task DAG

- **Route:** `/course/agile-agent-workflow/brief/execution-topology/the-task-dag`
- **File:** `html/agile-agent-workflow/brief/execution-topology/the-task-dag.html`
- **Eyebrow:** `A5.3.2 · dive 2/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / The task DAG.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) /
  `execution-topology` (link) / `the-task-dag` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/execution-topology/runtime-shape` · next
  `/course/agile-agent-workflow/brief/execution-topology/the-file-list`.

## Lead

The runtime shape says what the running system looks like. The **task DAG** says how to assemble it: a fixed
build order in which every step leaves the app compiling. A spec lists what a rung must do; the task DAG turns
that into an ordered chain of tasks, each one depending on the steps before it, so a Claude Author builds
bottom-up and never holds a half-compiling tree.

## The precise definition

A task DAG is a build order written as a directed chain (a directed acyclic graph): each task names the
requirements it satisfies, and each task can run only after the tasks it depends on. Two properties matter:

1. **Each step leaves the app compiling.** A task adds the smallest unit that still builds, so the tree is never
   broken between steps.
2. **The order is a dependency order.** A later task assumes the earlier ones exist. Run a task before its
   prerequisite and a dependency breaks — the later code references something not yet built.

For the Portal's web bootstrap, `f6.1.llms.md` pins the order exactly.

## The worked F6 example (verbatim ids)

Grounds on the `## Execution topology` task-topology block of `f6.1.llms.md`, quoted verbatim:

> **Task topology (build order; each step leaves the app compiling).**
>
> `T1 deps + entrypoint → T2 endpoint [R1] → T3 supervision [R2] → T4 router [R3, R6] → T5 controller [R4, R8] →
> T6 view [R5] → T7 verify [R7, R8]`

The chain reads bottom-up:

- **T1** — add Phoenix deps + the `PortalWeb` entrypoint + telemetry + endpoint config.
- **T2** — `PortalWeb.Endpoint` (plug stack + LiveView socket). Satisfies **R1**.
- **T3** — wire the endpoint into `Portal.Application` after the engine. Satisfies **R2**.
- **T4** — `PortalWeb.Router` (`:browser` pipeline + the courses route + `/health`). Satisfies **R3, R6**.
- **T5** — `PortalWeb.CourseController.index/2` over `Portal.courses_of/1`. Satisfies **R4, R8**.
- **T6** — `PortalWeb.CourseHTML` + `index.html.heex` + the error template. Satisfies **R5**.
- **T7** — verify: boot, render, `/health`, endpoint restart, the invariant grep. Satisfies **R7, R8**.

The dependency the content interactive proves: **T5 (controller) depends on T4 (router) and T2 (endpoint)** — the
controller's action is dispatched by a route that the router must already define, and the router is mounted only
because the endpoint exists. Build T5 before T4 and the route it dispatches to does not exist yet.

## Interactives — TWO, teaching different moves

### Hero (framing): the build order

- **Move taught:** walk the build order `T1 → T7` and read, at each step, the task, the requirements it
  satisfies, and that the app compiles after it.
- **Dataset (fixed, from `f6.1.llms.md`):** the seven tasks with their `[R…]` annotations —
  `T1 deps + entrypoint []`, `T2 endpoint [R1]`, `T3 supervision [R2]`, `T4 router [R3, R6]`,
  `T5 controller [R4, R8]`, `T6 view [R5]`, `T7 verify [R7, R8]`.
- **Element ids:** stepper controls `#dagBack` / `#dagNext` (buttons); SVG `#dagSvg` with node rects
  `#dag-node-0..6` and a position label `#dag-pos`; readout `#dagOut` (`aria-live="polite"`).
- **Pure functions:**
  - `taskAt(i)` → the task object `{id, name, reqs}` at step `i` (0–6).
  - `reqsAt(i)` → the `[R…]` requirement-id array the task at `i` satisfies.
  - `dagReadout(i)` → readout string.
- **Sample readout (default, step 0 = T1):** *"Step 1 of 7 — T1: deps + entrypoint. Requirements satisfied: none
  yet (the foundation). The app compiles after this step."*
- **Sample readout (step 4 = T5):** *"Step 5 of 7 — T5: controller. Requirements satisfied: R4, R8. The app
  compiles after this step."*

### Content (teaching): build out of order, break a dependency

- **Move taught:** show that the order is a dependency order — moving the controller (T5) before the router (T4)
  leaves the controller dispatched by a route that does not exist, one broken dependency.
- **Dataset (fixed, from `f6.1.llms.md`):** the `T1→T7` chain plus the one dependency edge the dive teaches —
  `T5` depends on `{T4, T2}`. Two orderings: in-order `[T1,T2,T3,T4,T5,T6,T7]` and swapped
  `[T1,T2,T3,T5,T4,T6,T7]` (T5 before T4).
- **Element ids:** selector `#ordSel` (buttons `data-order="inorder"`, `data-order="swapped"`); SVG `#ordSvg`
  with the two ordered node rects `#ord-node-0..6`, the broken edge `#ord-break`, and a broken-count text
  `#ord-count`; readout `#ordOut` (`aria-live="polite"`).
- **Pure functions:**
  - `brokenDeps(order)` → array of unmet dependencies (each `{task, missing}`) given an ordering; `[]` in order,
    `[{task: 'T5', missing: 'T4'}]` for the swap.
  - `brokenCount(order)` → integer count of unmet dependencies (0 in order, 1 swapped).
  - `ordReadout(order)` → readout string.
- **Sample readout (default, `inorder`):** *"In order: 0 broken dependencies. Each task runs after the steps it
  depends on, so the tree compiles at every step."*
- **Sample readout (`swapped`):** *"T5 before T4: 1 broken dependency. The controller (T5) is dispatched by a
  route the router (T4) has not defined yet — the route it dispatches to does not exist."*

Both interactives degrade: the SVG, the controls, and a correct default readout are in static markup; JS only
enhances. No browser storage. `prefers-reduced-motion` honoured by the shared reveal script.

## The bridge + take

- **Principle (`.cell.idea`):** the task DAG fixes the build order so the system compiles at every step; out of
  order, a dependency breaks.
- **Portal (`.cell.elix`):** `f6.1.llms.md` orders `T1 → T7` with `[R…]` traces; the endpoint (T2) precedes the
  supervision wiring (T3), which precedes the router (T4), which precedes the controller (T5).
- **Take:** *A task DAG is a build order an agent can follow without ever holding a half-compiling tree.*

## In-prose `/elixir` cross-link

`/elixir/phoenix/lifecycle/request-path` — the request path the ordered build assembles, taught in the companion
course's request lifecycle.

## References

### Sources (3)
- `https://llmstxt.org/` — llmstxt.org — *The /llms.txt convention* — the links-first machine-brief form that
  carries the task DAG.
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — Hunt &
  Thomas — *The Pragmatic Programmer* — build incrementally; keep the system working at every step (tracer bullets).
- `https://www.anthropic.com/engineering/building-effective-agents` — Anthropic — *Building effective agents* —
  why a coding agent needs the build order fixed, not an open-ended goal.

### Related in this course
- `/course/agile-agent-workflow/brief/execution-topology` — A5.3 · the module hub.
- `/course/agile-agent-workflow/brief/execution-topology/runtime-shape` — A5.3.1 · the runtime shape the order
  assembles.
- `/course/agile-agent-workflow/brief` — A5 · the chapter landing.
- `/elixir/phoenix/lifecycle` — Companion · the request lifecycle the ordered build produces.
