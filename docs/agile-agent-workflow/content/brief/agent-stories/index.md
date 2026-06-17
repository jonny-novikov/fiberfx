# A5.4 — Agent stories (module hub)

- **Route:** `/course/agile-agent-workflow/brief/agent-stories`
- **File:** `html/agile-agent-workflow/brief/agent-stories/index.html`
- **Eyebrow:** `A5.4 · module hub`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Grounds on:** `docs/elixir/specs/phoenix/f6.1.llms.md` — its `## Agent stories` (`F6.1-AS1…AS4`, each a
  Directive + an Acceptance gate) and the `## Execution plan — first two stories` (the worked
  *story → agent story → tasks → files → command → gate* trace).

## Lead

The fourth part of an agent brief is the executable counterpart of a user story. A user story names a need and a
"so that"; an agent story names what the agent does and how the work proves itself done. Each agent story carries
two halves: a **Directive** — the tasks the agent runs — and an **Acceptance gate** — the runnable check that
closes it. This module is the hub for three dives that teach the part in order: the Directive-and-gate pairing,
the worked first-two-stories execution plan, and the acceptance gates that close each story.

## Precise definition

- **An agent story** is one user story made executable: it implements exactly one user story and closes on a
  gate. `f6.1.llms.md` carries four — `F6.1-AS1` through `F6.1-AS4` — each built in task-topology order.
- **The Directive** is the half that sets the agent in motion: the tasks (`T1…T7`) the agent runs to build the
  increment.
- **The Acceptance gate** is the half that closes the story: a runnable check (a boot, a render, a grep, a
  restart) that turns "the agent thinks it is done" into "the work is provably done." A story with a Directive but
  no gate cannot close — the agent has work to do but no signal it is done.

## Worked Portal example (verbatim from f6.1.llms.md)

The brief's `## Agent stories` carries four, each implementing one user story and closing on a gate. Two quoted
verbatim:

> ### F6.1-AS1 — Boot as a Phoenix app [implements F6.1-US1]
> Directive: add Phoenix to `mix.exs`, create the `PortalWeb` entrypoint, telemetry, and endpoint config (T1);
> build `PortalWeb.Endpoint` with the full plug stack and the LiveView socket (T2); add `PortalWeb.Endpoint` to
> `Portal.Application`'s children **after** `{Portal.Engine, []}` (T3); add `GET /health → 200 "ok"` (part of T4).
> Acceptance gate: `mix compile` clean; app boots; `GET /health` returns `200`; tree order is store → engine →
> endpoint.

> ### F6.1-AS3 — Hold the boundary [implements F6.1-US3]
> Directive: ensure the controller calls only `Portal`, and that no module under `apps/portal_web/lib/` names
> `Portal.Engine`, `Repo`, or `GenServer.call`.
> Acceptance gate: `grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` returns nothing;
> `Portal.Application` drops Bandit (→ three F5 children) and the new `PortalWeb.Application` owns
> `[PortalWeb.Telemetry, PortalWeb.Endpoint]`.

The four stories, each split into its two halves:

| Story | User story | Directive (tasks) | Acceptance gate |
|---|---|---|---|
| F6.1-AS1 | F6.1-US1 | T1 deps + entrypoint → T2 endpoint → T3 supervision → /health | `mix compile` clean, app boots, `GET /health` 200, tree order store → engine → endpoint |
| F6.1-AS2 | F6.1-US2 | T4 browser pipeline + courses route → T5 controller → T6 view | a known user renders their courses; no enrollments renders an empty state; the template references only assigns |
| F6.1-AS3 | F6.1-US3 | hold the boundary — controller calls only `Portal` | `grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` returns nothing |
| F6.1-AS4 | F6.1-US4, US5 | confirm `:one_for_one` restarts the endpoint; map `{:error, %Portal.Error{}}` → 422 | killing the endpoint restarts it; an injected `%Portal.Error{}` renders a 422, never a 500 |

The pairing each story made executable: `F6.1-US1 → F6.1-AS1`, `F6.1-US2 → F6.1-AS2`.

## The three dives (`.mods` grid)

- **A5.4.1 · Directive and gate** — `/brief/agent-stories/directive-and-gate` — every agent story is a Directive
  plus a closing Acceptance gate.
- **A5.4.2 · The first two stories** — `/brief/agent-stories/first-two-stories` — the worked execution plan that
  proves the path from story to verified change is short and unambiguous.
- **A5.4.3 · Acceptance gates** — `/brief/agent-stories/acceptance-gates` — the check that closes a story; a story
  with no gate is flagged.

## Interactive 1 — hero (framing): user story → agent story

- **Element ids:** `#pairSel` (solid-select: `F6.1-US1` / `F6.1-US2`), SVG `.anat` (two stacked rows: the user
  story, an arrow, the agent story), readout `#pairOut`.
- **Dataset:** the two pairings `F6.1-US1 → F6.1-AS1` and `F6.1-US2 → F6.1-AS2`, each carrying the user story's
  "so that", the matching agent story id, its Directive summary, and its gate.
- **Pure functions:**
  - `agentStoryFor(usId)` → the agent story object whose `implements` field is `usId`.
  - `pairReadout(usId)` → readout string.
- **Sample readout (US1):** `F6.1-US1 (serve the Portal as a Phoenix app) → F6.1-AS1. The user story names a need
  and a "so that"; the agent story is its executable counterpart — a Directive (T1→T3 + /health) and an Acceptance
  gate (compile clean, /health 200, tree order store → engine → endpoint).`
- **Sample readout (US2):** `F6.1-US2 (see a user's courses) → F6.1-AS2. The agent story makes the need
  executable — a Directive (T4→T6: pipeline + route, controller, view) and an Acceptance gate (a known user
  renders their courses; no enrollments renders an empty state; the template references only assigns).`

## Interactive 2 — content (teaching): split a story into Directive and gate

- **Element ids:** `#splitSel` (solid-select: `Directive + gate` / `drop AS3's gate`), SVG grid of four cells
  (one per story, each showing two halves), readout `#splitOut`.
- **Dataset:** `F6.1-AS1…AS4`, each split into its Directive and its Acceptance gate.
- **Pure functions:**
  - `hasBothHalves(as)` → boolean — true when the story carries both a Directive and a gate.
  - `bothHalvesCount(stories)` → count of stories with both halves (4 as written; 3 once AS3's gate is dropped).
  - `splitReadout(mode)` → readout string.
- **Sample readout (both halves):** `All four agent stories carry a Directive and a gate: 4 of 4. AS3's gate is an
  empty invariant grep; AS1's is /health 200 plus the boot order. Each story closes on a runnable check.`
- **Sample readout (drop the gate):** `Drop AS3's gate and it cannot close: 3 of 4 carry both halves. The agent
  has work to do — hold the boundary — but no signal it is done; without the grep, nothing proves the boundary
  held.`

## Bridge

- **Principle (`.cell.idea`):** an agent story is a user story made executable: a Directive the agent runs and an
  Acceptance gate that closes it.
- **Practice (`.cell.elix`):** `f6.1.llms.md`'s `F6.1-AS1` directs T1→T3 and closes on `GET /health` 200 + the
  boot order; `F6.1-AS3` closes on an empty invariant grep.
- **Take:** A user story says what someone needs; an agent story says what the agent does and how the work proves
  itself done.

## Cross-link

- In-prose `/elixir/phoenix/lifecycle` (where these stories are built).

## References

### Sources

- Cohn, M. — *User Stories Applied* — `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- Jeffries, R. — *INVEST in Good Stories, and SMART Tasks* —
  `https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/`
- Anthropic — *Building effective agents* — `https://www.anthropic.com/engineering/building-effective-agents`

### Related in this course

- `/course/agile-agent-workflow/brief/agent-stories/directive-and-gate`
- `/course/agile-agent-workflow/brief/agent-stories/first-two-stories`
- `/course/agile-agent-workflow/brief/agent-stories/acceptance-gates`
- `/course/agile-agent-workflow/brief` — A5 · The agent brief
- `/course/agile-agent-workflow/brief/execution-topology` — A5.3 · the task DAG the stories map onto
- `/elixir/phoenix/lifecycle` — where these stories are built
- `/elixir/phoenix` — the companion Phoenix chapter

## Pager

- prev `/course/agile-agent-workflow/brief` (A5 · The agent brief)
- next `/course/agile-agent-workflow/brief/agent-stories/directive-and-gate` (A5.4.1, first dive)

## Crumbs

jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
(`/course/agile-agent-workflow/brief`) / here.
