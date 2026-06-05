# A5.4.2 — The first two stories

- **Route:** `/course/agile-agent-workflow/brief/agent-stories/first-two-stories`
- **File:** `html/agile-agent-workflow/brief/agent-stories/first-two-stories.html`
- **Eyebrow:** `A5.4.2 · dive 2/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / The first two stories.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `agent-stories` (link) /
  `first-two-stories` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/agent-stories/directive-and-gate` · next
  `/course/agile-agent-workflow/brief/agent-stories/acceptance-gates`.
- **Parent hub:** `/course/agile-agent-workflow/brief/agent-stories` (A5.4).

## Lead

A5.4.1 showed that one agent story is a Directive plus an Acceptance gate. This dive walks the first two stories of
the Portal's web bootstrap end to end, before any agent runs them, to confirm the path from a user story to a
verified change is short and leaves no decision the spec has not already fixed. The brief's
`## Execution plan — first two stories` is exactly that worked trace: each plan is *story → agent story → tasks →
files → command → gate*, and an agent runs the steps top to bottom and stops at the gate.

## Precise definition

A **first-two-stories execution plan** is a worked trace, written into the brief before the agent runs, that
follows the first one or two user stories through their agent stories, the tasks those agent stories carry, the
exact files each touches, the one command that builds and exercises them, and the one gate that closes them. Its
purpose is a confidence check: if the first two stories run short and gated on paper, the rest will run short and
gated in practice. It fixes no new decision — every branch it walks is already specified upstream.

## Worked F6 example — verbatim from `f6.1.llms.md` `## Execution plan — first two stories`

> "A worked trace of how the framework turns a user story into a verified change, to confirm the path is short and
> leaves no decision to the agent that the spec has not already fixed. Each plan is *story → agent story → tasks →
> files → command → gate*; an agent runs the steps top to bottom and stops at the gate."

### Plan A — F6.1-US1 (serve the Portal as a Phoenix app) · via F6.1-AS1

1. Tasks `T1 → T2 → T3` (foundation → endpoint → supervision).
2. Files (5): `apps/portal_web/mix.exs` (+ phoenix), `config/config.exs`, `config/runtime.exs`,
   `apps/portal_web/lib/portal_web.ex`, `apps/portal_web/lib/portal_web/application.ex`,
   `apps/portal_web/lib/portal_web/telemetry.ex`, `apps/portal_web/lib/portal_web/endpoint.ex`,
   `apps/portal/lib/portal/application.ex` (drop Bandit), `apps/portal/mix.exs` (drop bandit),
   `apps/portal_web/lib/portal_web/router.ex` (add `get "/health"`).
   (For the interactive's "files behind one gate" count we use the new `apps/portal_web` foundation/endpoint/
   supervision set Plan A creates — the foundation, application, telemetry, endpoint, and the `/health` router —
   five new files; the two core touches drop Bandit and are edits to existing files.)
3. Command: `mix deps.get && mix compile && mix phx.server`, then `curl -i localhost:4000/health`.
4. Gate (closes US1): `200 ok` from `/health`; the `:portal` tree boots (store → adapter → engine) before the
   `:portal_web` tree (telemetry → endpoint); both strategies `:one_for_one`. Requirements satisfied: F6.1-R1,
   F6.1-R2, F6.1-R6.

### Plan B — F6.1-US2 (see a user's courses) · via F6.1-AS2

1. Tasks `T4 → T5 → T6` (browser pipeline + route → controller → view).
2. Files (5): `apps/portal_web/lib/portal_web/router.ex` (`get "/courses/:user_id"` in a `:browser` scope),
   `apps/portal_web/lib/portal_web/controllers/course_controller.ex`,
   `apps/portal_web/lib/portal_web/controllers/course_html.ex`, `course_html/index.html.heex`,
   `course_html/error.html.heex`.
3. Command: `mix test apps/portal_web/test/portal_web/controllers/course_controller_test.exs`, plus a manual
   `curl localhost:4000/courses/USR_known`.
4. Gate (closes US2): a known user renders their courses; no enrollments — or an unknown/malformed id — renders an
   empty state (`200`); the `422` render path is unit-verified via an injected `%Portal.Error{}` from the closed
   error set (F6.1-R4 / INV4); `grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` is empty
   (F6.1-R7 / INV1). Requirements satisfied: F6.1-R3, F6.1-R4, F6.1-R5, F6.1-R8.

> "Efficiency check: each story is two-to-six files behind one command and one gate, and every branch (empty state,
> injected-error render) is already specified — so the agent implements rather than decides."

## Hero interactive (framing) — the plan chain

- **id prefix:** `chain`. SVG `id="chainSvg"`; selector `id="chainSel"` (buttons `data-step` 0..5);
  readout `id="chainOut"` (`aria-live="polite"`).
- **Dataset:** the five links of Plan A, as the chain `US1 → AS1 → T1,T2,T3 → files → command → gate` (six nodes:
  story, agent story, tasks, files, command, gate). Plan B is the same chain shape for `US2 → AS2 → T4,T5,T6`.
- **Pure functions:**
  - `linkAt(i)` → returns the i-th link object `{key, label, detail}` of the active plan's chain.
  - `chainLength()` → returns 6 (the fixed number of links).
  - `chainReadout(i)` → returns the readout string for the i-th link.
- **Move taught:** walk the worked path from a user story to a verified change, one link at a time.
- **Sample readout (link 5, gate):** `"Plan A · link 6 of 6 — gate: GET /health returns 200 ok; the :portal tree
  boots store → engine before :portal_web (telemetry → endpoint). One command, one gate close US1 — the worked
  path from a user story to a verified change."`
- **Degrade:** the SVG shows the full chain with link 0 (US1) lit and its readout in static markup; JS only steps.

## Content interactive (teaching) — files behind one gate

- **id prefix:** `fbg`. SVG `id="fbgSvg"`; selector `id="fbgSel"` (buttons `data-plan="A" | "B"`);
  readout `id="fbgOut"` (`aria-live="polite"`).
- **Dataset:** Plan A and Plan B, each with its file list and its single command + single gate. Plan A = the five
  new `apps/portal_web` foundation/endpoint/supervision files; Plan B = router, controller, view, and the two
  `.heex` templates (5 files).
- **Pure functions:**
  - `filesPerGate(plan)` → returns the count of files behind the plan's one command + one gate (5 for A, 5 for B).
  - `commandsFor(plan)` / `gatesFor(plan)` → each returns 1 (one command, one gate per plan).
  - `fbgReadout(plan)` → returns the readout string for the plan.
- **Move taught (distinct from the hero):** the hero walks the *sequence* of one plan link by link; this counts the
  *blast radius* — how few files stand behind a single command and a single gate, the efficiency that lets the
  agent implement rather than decide.
- **Sample readout (Plan B):** `"Plan B (see a user's courses): 5 files behind 1 command and 1 gate — the router,
  controller, view, and two templates. Every branch (empty state, injected-error → 422) is already specified, so
  the agent implements rather than decides."`
- **Degrade:** the SVG shows Plan A's five files and its 1-command/1-gate footer lit, readout in static markup; JS
  toggles the plan.

## Bridge

- **Principle (`.cell.idea`):** walk the first two stories end to end before the agent runs, to confirm the path is
  short and leaves no decision the spec has not already fixed.
- **Practice (`.cell.elix`):** `f6.1.llms.md`'s Plan A and Plan B each map a user story to its agent story, tasks,
  files, one command, and one gate.
- **Take:** If the first two stories run short and gated on paper, the rest will run short and gated in practice.

## In-prose `/elixir` cross-link

`/elixir/phoenix/lifecycle/request-path` — the request path the ordered build assembles.

## References

### Sources (3, real, vetted)
- User Stories Applied → `https://www.mountaingoatsoftware.com/books/user-stories-applied` — the user story whose
  executable counterpart the plan walks.
- INVEST in Good Stories → `https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/` — a small,
  testable story is one whose path to done is short and gated.
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — tracer bullets: walk a thin path end to end first to confirm it is short.

### Related in this course
- `/course/agile-agent-workflow/brief/agent-stories` — A5.4 hub.
- `/course/agile-agent-workflow/brief/agent-stories/directive-and-gate` — A5.4.1, the Directive + gate of one story.
- `/course/agile-agent-workflow/brief/execution-topology/the-task-dag` — the `T1→T7` order the plans run in.
- `/course/agile-agent-workflow/spec` — A4, the spec the plan fixes nothing beyond.
- `/elixir/phoenix/lifecycle` — the companion chapter whose `f6.1.llms.md` this dive grounds on.
