# A5.8.2 — Run the agent

- **Route:** `/course/agile-agent-workflow/brief/workshop/run-the-agent`
- **File:** `html/agile-agent-workflow/brief/workshop/run-the-agent.html`
- **Eyebrow:** `A5.8.2 · dive 2/3`
- **Parent hub:** `/course/agile-agent-workflow/brief/workshop` (A5.8 · Workshop)
- **Pager:** prev `/course/agile-agent-workflow/brief/workshop/brief-the-rung` · next
  `/course/agile-agent-workflow/brief/workshop/verify-the-increment`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

The brief is written; the agent runs it. A5.8.1 assembled the five parts of the brief for a real rung. This dive
runs the second stage of the workshop: hand the implementation prompt to a Claude Author and run it **in task
order**, keeping the tree compiling after each step, and **supervise the gates** — never advancing the build past a
step whose gate fails.

The worked artifact is the Portal's real web bootstrap, `f6.1.llms.md`. Its comprehensive implementation prompt
opens with a single locked instruction:

> Build in this order, keeping the umbrella compiling after each step:

and then lays out seven numbered steps — Foundation, Endpoint, Supervision, Router, Controller, View, Verify —
each annotated with the task it lands (`T1`…`T7`) and the requirements it satisfies. Running the agent is following
that order and watching each step's gate.

## The precise definition

**Running the agent** is the second stage of the A5 sequence (brief → run → verify). It is two disciplines
applied together:

1. **Task order.** The prompt runs the agent stories `F6.1-AS1…AS4` in the task-DAG order `T1 → T2 → … → T7`. Each
   step leaves the umbrella compiling, so the build never holds a half-assembled tree. Out of order — say, the
   controller before the router — a step dispatches to a route that does not exist yet, and the tree breaks.
2. **Supervision.** Each step closes on a gate: the compile is clean, and the per-story Acceptance gate passes. A
   human supervisor watches those gates. When a step's gate fails, the supervisor intervenes **before** the next
   step, rather than building on a broken step. (This is the F6.6/F6.7 stage-gate practice: a Director in the loop
   between stages, with a bounded remediate loop on a finding.)

The agent supplies the speed of implementation; the human owns the order it runs in and the gate that closes each
step.

## The worked Portal example — `f6.1.llms.md`'s seven steps

The implementation prompt (quoted verbatim, partially):

> Build in this order, keeping the umbrella compiling after each step:
>
> 1. Foundation (T1). Create the new app `apps/portal_web` … then fetch deps …
> 2. Endpoint (T2 → R1). Create `apps/portal_web/lib/portal_web/endpoint.ex` …
> 3. Supervision (T3 → R2). The new `PortalWeb.Application` supervises `[PortalWeb.Telemetry, PortalWeb.Endpoint]` … DROP the `{Bandit, …}` child …
> 4. Router (T4 → R3, R6). Create `apps/portal_web/lib/portal_web/router.ex` … add `get "/courses/:user_id"` … `get "/health"` …
> 5. Controller (T5 → R4, R8). … `index/2` … calls `Portal.courses_of(user_id)` ONLY …
> 6. View (T6 → R5). … `CourseHTML` … templates read only assigns.
> 7. Verify (T7 → R7, R8 + DoD). Confirm `mix compile` is clean … `GET /health` is 200 … the invariant grep is empty …

The seven steps map one-to-one onto the task DAG `T1 → T2 → T3 → T4 → T5 → T6 → T7`, and each carries the
requirements it satisfies. The order is a dependency order: the endpoint (T2) precedes the supervision wiring (T3),
which precedes the router (T4), which the controller (T5) dispatches through.

The per-story Acceptance gates the supervisor watches (from `f6.1.llms.md`'s Agent stories):

- **AS1** (boot): `mix compile` clean; app boots; `GET /health` returns 200; tree order store → engine → endpoint.
- **AS2** (render): a known user renders their courses; no enrollments renders an empty state; the template
  references only assigns.
- **AS3** (boundary): `grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` returns nothing.
- **AS4** (self-heal / fail soft): killing the endpoint restarts it; an injected `%Portal.Error{}` renders a 422,
  never a 500.

## Hero interactive (framing) — *run in task order*

- **Move taught:** advance through the prompt's seven steps in order and read the per-step compile state.
- **Element ids:** controls `#runSel` (a stepper: `‹ prev` / `next ›` buttons advancing a step index 0–6); SVG
  `#runSvg` with seven step rows `#run-step-0`…`#run-step-6` and a current-step marker; readout `#runOut`
  (`aria-live="polite"`).
- **Dataset (fixed, from `f6.1.llms.md`):** the seven ordered steps —
  `[{t:'T1', name:'Foundation', reqs:'—'}, {t:'T2', name:'Endpoint', reqs:'R1'}, {t:'T3', name:'Supervision', reqs:'R2'}, {t:'T4', name:'Router', reqs:'R3, R6'}, {t:'T5', name:'Controller', reqs:'R4, R8'}, {t:'T6', name:'View', reqs:'R5'}, {t:'T7', name:'Verify', reqs:'R7, R8'}]`.
- **Pure functions:**
  - `stepAt(i)` → the step record at index `i`.
  - `compilesAfter(i)` → `true` for every `i` (in task order each step leaves the tree compiling).
  - `runReadout(i)` → the readout string.
- **Sample readout (i = 3):** `Step 4 of 7 — T4 Router (satisfies R3, R6). Tree state after this step: compiling. In task order each step builds on a compiling tree — the router exists before the controller dispatches through it.`
- **Degrades:** the SVG and the stepper sit in static markup at step 0 (Foundation) with a correct default readout;
  JS only advances the index.

## Content interactive (teaching) — *supervise the gates*

- **Move taught (different from the hero):** the hero advances the order; this one watches a *gate* and shows the
  supervisor intervening when a step's gate fails — supervision, not ordering.
- **Element ids:** controls `#gateSel` (toggle `all pass` / `step 5 fails`); SVG `#gateSvg` with seven step gates
  `#gate-st-0`…`#gate-st-6` and an intervention marker `#gate-stop`; readout `#gateOut` (`aria-live="polite"`).
- **Dataset (fixed):** the seven steps, each with its per-step gate label (compile clean + the per-story Acceptance
  gate). Under `all pass` every gate passes; under `step 5 fails` step index 4 (the Controller, T5) fails its gate.
- **Pure functions:**
  - `stepGate(i, mode)` → `'pass'` | `'fail'` for step `i` under `mode`.
  - `firstFail(mode)` → the index of the first failing step, or `-1` when none.
  - `advancesTo(mode)` → the last step the build is allowed to reach (the step before the first failure, or 7 when
    none fail) — the supervisor does not build past a failing step.
  - `gateReadout(mode)` → the readout string.
- **Sample readout (mode = `step 5 fails`):** `Step 5's gate fails — the build reaches step 5 and stops. The supervisor intervenes before step 6, rather than building the view on a controller that does not pass its gate. Supervision watches the gate, not the keystrokes.`
- **Sample readout (mode = `all pass`):** `Every step's gate passes — the build advances through all 7 steps. Each step compiles and closes its Acceptance gate, so the next step builds on a verified one.`
- **Degrades:** static default `all pass`, all seven gates lit green, correct readout; JS toggles the failing mode.

## Bridge + take

- **Principle (`.cell.idea`):** Run the implementation prompt in task order and supervise the gates; do not build
  past a failing step.
- **Practice (`.cell.elix`):** `f6.1.llms.md`'s prompt runs Foundation → Endpoint → Supervision → Router →
  Controller → View → Verify, the umbrella compiling after each; the F6 ship prompts gate each stage, with the
  Director in the loop and a bounded remediate loop on a finding.
- **Take:** Running the agent is following the prompt's order and watching its gates — the build never advances on a
  broken step.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/lifecycle/request-path` — the request path the ordered run assembles
  (the endpoint → router → controller → facade flow the seven steps build bottom-up).
- **Related in this course:**
  - `/course/agile-agent-workflow/brief/workshop` — the workshop hub.
  - `/course/agile-agent-workflow/brief/implementation-prompt` — A5.5, the prompt this run executes.
  - `/course/agile-agent-workflow/brief/running-agents/supervising` — A5.6.2, the supervision practice this applies.
  - `/course/agile-agent-workflow/brief/execution-topology/the-task-dag` — A5.3.2, the task DAG this order follows.
  - `/elixir/course` — the companion course that builds the engine and the web layer.
  - `/elixir/phoenix/lifecycle` — the real rung whose prompt this run executes.

## Sources (3, from the registry)

- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
- Anthropic — Claude Code best practices → `https://www.anthropic.com/engineering/claude-code-best-practices`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
