# A5.5.2 — Task order

- **Route:** `/course/agile-agent-workflow/brief/implementation-prompt/task-order`
- **File:** `html/agile-agent-workflow/brief/implementation-prompt/task-order.html`
- **Eyebrow:** `A5.5.2 · dive 2/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/implementation-prompt` (A5.5).
- **Pager:** prev `…/implementation-prompt/assembling-the-prompt` · next `…/implementation-prompt/definition-of-done`.

## Lead

A5.5.1 assembled the prompt: the four prior parts — references, requirements, topology, agent stories — gathered
into one runnable instruction. This dive teaches the prompt's spine: the **order** the agent builds in. The prompt
does not list its work as a set; it lists it as a sequence — the seven numbered steps of `f6.1.llms.md`, which are
the task DAG `T1→T7` turned into instructions. The instruction that governs them all is one line: **"Build in this
order, keeping the umbrella compiling after each step."** Follow it and the agent never holds a half-compiling
tree; reorder it and a step dispatches to something that does not exist yet.

## Precise definition

**Task order** is the property that the implementation prompt runs its steps in the dependency order of the task
DAG, so that every prefix of the build compiles. Each step satisfies a numbered requirement and depends only on
steps before it. The prompt is the DAG topologically sorted into a list a person can paste and an agent can run
top to bottom.

In `f6.1.llms.md` the seven steps are (verbatim mapping):

1. **Foundation** — `T1` — create `apps/portal_web`, add Phoenix deps (NO ecto), the `PortalWeb` entrypoint,
   telemetry, application, endpoint config.
2. **Endpoint** — `T2 → R1` — `PortalWeb.Endpoint`: the plug stack + the LiveView socket.
3. **Supervision** — `T3 → R2` — `PortalWeb.Application` supervises `[Telemetry, Endpoint]`; `Portal.Application`
   drops the Bandit child (→ three F5 children, `Portal.Store` retained).
4. **Router** — `T4 → R3, R6` — the `:browser` pipeline, `get "/courses/:user_id"`, and `GET /health → 200 "ok"`.
5. **Controller** — `T5 → R4, R8` — `CourseController.index/2` over `Portal.courses_of/1` only; a domain error
   renders 422.
6. **View** — `T6 → R5` — `CourseHTML` + `index.html.heex` + `error.html.heex`, rendering from assigns only.
7. **Verify** — `T7 → R7, R8 + DoD` — compile clean, boot, `/health` 200, render + empty state, injected-error →
   422, endpoint self-heal, the empty invariant grep; report against the F6.1 Definition of Done.

The dependency that the dive makes concrete: **step 5 (Controller) depends on step 4 (Router).** The controller's
`index/2` action is dispatched to by the `get "/courses/:user_id"` route; build the controller before the route
and the action it answers has nothing to call it.

## Worked Portal example (grounded on f6.1.llms.md)

The prompt's preamble — "Build in this order, keeping the umbrella compiling after each step" — is not advice; it
is the DAG's invariant restated. `f6.1.llms.md` annotates each task with the requirements it satisfies
(`T2 … [R1]`, `T4 … [R3, R6]`, `T5 … [R4, R8]`), so the order is traceable: a reviewer can read which requirement
closes at which step.

Out of order, the break is concrete and named. Run the Controller step (5) before the Router step (4):
`CourseController.index/2` exists, but no route dispatches to it, so the courses path is unreachable — and the
`:browser` pipeline the controller needs is not defined yet. The tree no longer holds the property the prompt's
one-line instruction guarantees. Reorder back and every prefix compiles again.

## Interactive 1 — hero (framing): the prompt's seven steps

- **Move taught:** *read the prompt as an ordered walk* — the seven numbered steps mapped to `T1…T7` and their
  `[R…]`, each leaving the tree compiling.
- **Elements:** `<div class="solid-select" id="stepSel">` with seven step buttons `data-step="0..6"` (default
  `step 1` active); SVG `id="stepSvg"` (seven bands `id="ts-band-0..6"`, a current-step label `id="ts-cur"`, a
  requirement readout `id="ts-req"`, a compile state `id="ts-comp"`); readout `id="stepOut"` (`aria-live`).
- **Dataset:** `STEPS` = the seven `f6.1.llms.md` steps, each `{n, name, task, reqs, calls}` (verbatim
  Foundation/Endpoint/Supervision/Router/Controller/View/Verify; tasks `T1..T7`; reqs per the mapping).
- **Pure functions:**
  - `stepAt(i)` → the step record at index `i`.
  - `reqsLabel(i)` → the `[R…]` string for step `i` ("—" for the foundation step which has no R, "R7, R8 + DoD"
    for verify).
  - `stepReadout(i)` → the readout string.
- **Sample readout (step 5, Controller):** *"Step 5 of 7 — Controller (T5, satisfies R4, R8). The controller is
  built after the router that dispatches to it; the umbrella compiles after this step. The prompt runs the stories
  in the task-DAG order, T1 to T7."*
- **Degrade:** static markup ships step 1 active, its band lit, `ts-cur`/`ts-req`/`ts-comp` filled, and `stepOut`
  carrying the step-1 readout. JS only re-paints on click.

## Interactive 2 — content (teaching): out-of-order prompt breaks

- **Move taught (different from the hero):** *a reordering breaks a dependency* — moving the controller before the
  router leaves a step that dispatches to a route that does not exist, so the tree stops compiling.
- **Elements:** `<div class="solid-select" id="ordSel">` with two buttons `data-order="written"` (default active)
  and `data-order="swap"`; SVG `id="ordSvg"` (seven step chips `id="ord-chip-0..6"` in the active order, a
  broken-edge marker, a broken-dependency count `id="ord-broken"`); readout `id="ordOut"` (`aria-live`).
- **Dataset:** `EDGES` = the dependency edges of the DAG (each step depends on the step before it; the load-bearing
  one for this dive: Controller(5) depends on Router(4)). `ORDERS` = `{written: [1..7], swap: [1,2,3,5,4,6,7]}`
  (controller and router transposed).
- **Pure functions:**
  - `brokenDeps(order)` → the count of edges whose prerequisite appears *after* the dependent in `order` (0 for
    `written`, 1 for `swap`).
  - `firstBreak(order)` → the first dependent step whose prerequisite is not yet built ("controller (step 5)"
    under `swap`, `null` under `written`).
  - `ordReadout(order)` → the readout string.
- **Sample readout (swap):** *"Move the controller (step 5) before the router (step 4) and step 5 dispatches to a
  route that does not exist yet — the tree breaks. Broken dependencies: 1."*
- **Default readout (written):** *"As written: the tree compiles after every step. Broken dependencies: 0 of 6 —
  each step depends only on a step already built."*
- **Degrade:** static markup ships the `written` order, chips 1..7 in sequence, `ord-broken` = 0, and `ordOut`
  carrying the written readout. JS only re-paints on toggle.

## Bridge + take

- **`.cell.idea` (principle):** *the prompt runs the agent stories in the task-DAG order, so the tree compiles
  after every step.*
- **`.arrow` →**
- **`.cell.elix` (Portal):** *`f6.1.llms.md`'s prompt builds Foundation → Endpoint → Supervision → Router →
  Controller → View → Verify, keeping the umbrella compiling after each step, with each step's `[R…]` traced.*
- **`.take`:** *Task order in the prompt is the task DAG made into instructions — follow it and the build never
  holds a broken tree.*

## In-prose `/elixir` cross-link

`/elixir/phoenix/routing/routes` — the router step (4) the controller step (5) depends on: the route that
dispatches to `CourseController.index/2`.

## References

**Sources (3):**
- Anthropic — Claude Code best practices → `https://www.anthropic.com/engineering/claude-code-best-practices`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
- The `llms.txt` convention → `https://llmstxt.org/`

**Related in this course:**
- `/course/agile-agent-workflow/brief/implementation-prompt` — A5.5 hub.
- `/course/agile-agent-workflow/brief/execution-topology/the-task-dag` — A5.3.2, the task DAG this prompt orders.
- `/course/agile-agent-workflow/brief/agent-stories` — A5.4, the stories the prompt runs.
- `/elixir/phoenix/lifecycle` — the companion rung this prompt builds.
- `/elixir/phoenix/routing/routes` — the router step the controller step depends on.
