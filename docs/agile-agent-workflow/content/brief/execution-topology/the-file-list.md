# A5.3.3 — The file list

- **Route:** `/course/agile-agent-workflow/brief/execution-topology/the-file-list`
- **File:** `html/agile-agent-workflow/brief/execution-topology/the-file-list.html`
- **Eyebrow:** `A5.3.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/execution-topology` (A5.3 · Execution topology).
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / The file list.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) / `execution-topology` (link) /
  `the-file-list` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/execution-topology/the-task-dag` (A5.3.2 · The task DAG) ·
  next `/course/agile-agent-workflow/brief/execution-topology` (back to the A5.3 hub).

## Lead

The runtime shape says what runs; the task DAG says in what order it is built. The third thing the topology pins is
**which files the change touches** — the "Touched files" paragraph of the brief. It names every file the agent
creates, every file it edits, and the one it deletes, and it pins everything below the facade boundary as
unchanged. A file list is the change's blast radius, written down before the agent runs.

## Precise definition

The **file list** is the enumerated set of paths the increment touches, tagged by action — *created*, *edited*, or
*deleted* — together with the explicit boundary of what stays unchanged. It bounds the work two ways at once: it
tells the agent which files to write, and it tells the agent (and the reviewer) which files must not move. A change
with a written file list has a known blast radius; a change without one can spread anywhere the agent decides.

## Worked Portal example — `f6.1.llms.md` "Touched files" (verbatim grounding)

The F6.1 web-bootstrap brief's "Touched files" paragraph lists, verbatim:

**New app `apps/portal_web/`** (created):
- `apps/portal_web/mix.exs`
- `apps/portal_web/lib/portal_web.ex`
- `apps/portal_web/lib/portal_web/application.ex`
- `apps/portal_web/lib/portal_web/telemetry.ex`
- `apps/portal_web/lib/portal_web/endpoint.ex`
- `apps/portal_web/lib/portal_web/router.ex`
- `apps/portal_web/lib/portal_web/controllers/course_controller.ex`
- `apps/portal_web/lib/portal_web/controllers/course_html.ex`
- `apps/portal_web/lib/portal_web/controllers/course_html/index.html.heex`
- `apps/portal_web/lib/portal_web/controllers/course_html/error.html.heex`

**Core touches (two lines only)** (edited):
- `apps/portal/lib/portal/application.ex` — drops the `Bandit` child (four → three).
- `apps/portal/mix.exs` — drops the `bandit` dep.

**Deleted:**
- `apps/portal/lib/portal_web/router.ex` — the old `Portal.Web.Router` (a `Plug.Router`), replaced by the Phoenix
  `PortalWeb.Router` in the new app.

**Pinned unchanged (the boundary):** the engine (`Portal.Engine`), the store (`Portal.Store`), the contexts, and
the `Portal` facade stay exactly as F5 left them. No file below that boundary appears in the list, by design.

## Hero interactive (framing move) — *new, edited, deleted*

- **Element ids:** `#actSel` (control: `created` / `edited` / `deleted` toggle), `#act-…` SVG rows, `#act-count`
  readout figure, `#actOut` (`.geo-readout`, `aria-live="polite"`).
- **Dataset:** the `f6.1.llms.md` touched files tagged by action — 10 created (the new `apps/portal_web/` files),
  2 edited (`application.ex` drops Bandit; `mix.exs` drops the dep), 1 deleted (the old `Portal.Web.Router`).
- **Pure functions:**
  - `actionOf(file) :: "created" | "edited" | "deleted"` — the action tag for one file.
  - `filesByAction(action) :: [file]` — the files carrying a given action.
  - `countByAction(action) :: integer` — how many files carry that action.
- **Sample readout (created):** `Created — files the agent adds: 10 of 13 touched. The new apps/portal_web/ app:
  mix.exs, the entrypoint, telemetry, the endpoint, the router, the controller, the view, and two templates.`
- **Move taught:** an agent reads the file list as three actions — *create* the new app's files, *edit* two core
  files, *delete* one. The action is part of the instruction, not left to the agent.

## Content interactive (teaching move) — *touch only the listed files*

- **Element ids:** `#scopeSel` (control: `edit a listed file` / `edit the engine`), `#scope-…` SVG markers,
  `#scope-verdict` figure, `#scopeOut` (`.geo-readout`, `aria-live="polite"`).
- **Dataset:** the touched-file set (13 listed paths) **plus** the "do not modify" boundary (`Portal.Engine`,
  `Portal.Store`, the contexts, the `Portal` facade). One candidate edit per mode.
- **Pure functions:**
  - `inScope(file) :: boolean` — whether a path is in the brief's touched-file list.
  - `verdictFor(file) :: "in scope" | "out of scope"` — the rendered verdict for one candidate edit.
- **Sample readout (in scope):** `Editing apps/portal_web/lib/portal_web/router.ex is in scope — it is one of the
  13 listed files. The brief lists the files the agent touches and pins the rest as unchanged.`
- **Sample readout (out of scope):** `Editing Portal.Engine is out of scope — it sits below the facade boundary the
  brief pins unchanged. The file list is the change's blast radius; nothing below the boundary is in it.`
- **Move taught:** the file list is not only a to-do list of files to write — it is a fence. An edit to a listed
  file is in scope; an edit to anything below the boundary is out of scope, even when it would "work."

The two interactives teach different moves: the hero classifies the listed files by **action** (what the agent does
to each); the content figure tests an arbitrary edit against the **boundary** (whether a file is in the list at all).

## Bridge

- **`.cell.idea` (principle):** the file list bounds the change — the agent creates and edits exactly the named
  files, and nothing below the boundary.
- **`.arrow`**
- **`.cell.elix` (Portal practice):** `f6.1.llms.md` lists every new `apps/portal_web/` file, the two core touches,
  and the one deletion, and pins the engine, store, contexts, and `Portal` facade as unchanged.
- **`.take`:** A file list is the change's blast radius, written down before the agent runs.

## In-prose `/elixir` cross-link

`/elixir/phoenix/contexts/boundaries` — the boundary the file list respects (the web layer reaches the domain only
through the `Portal` facade, never `Portal.Engine`).

## References

**Sources (3, real, vetted):**
- The `llms.txt` convention → `https://llmstxt.org/`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`

**Related in this course:**
- `/course/agile-agent-workflow/brief/execution-topology` — the A5.3 module hub.
- `/course/agile-agent-workflow/brief/execution-topology/the-task-dag` — the build order the files realise.
- `/course/agile-agent-workflow/brief` — the A5 chapter landing.
- `/elixir/phoenix/lifecycle` — the real chapter whose `f6.1.llms.md` this grounds on.
- `/elixir/phoenix/contexts` — the contexts the boundary protects.
