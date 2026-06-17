# A5.4.1 — Directive and gate

- **Route:** `/course/agile-agent-workflow/brief/agent-stories/directive-and-gate`
- **File:** `html/agile-agent-workflow/brief/agent-stories/directive-and-gate.html`
- **Eyebrow:** `A5.4.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/agent-stories` (A5.4 · Agent stories).
- **Pager:** prev `/course/agile-agent-workflow/brief/agent-stories` · next
  `/course/agile-agent-workflow/brief/agent-stories/first-two-stories`.

## Lead

The fourth part of the brief is the agent story — the executable counterpart of a user story. A user story carries
a "so that"; an agent story carries two halves instead: a **Directive** (the tasks the agent runs) and an
**Acceptance gate** (the runnable check that closes it). This dive isolates the pairing. The Directive sets the
agent in motion over an ordered run of tasks; the gate is the line at which the work is provably done, for the
agent and for the reviewer alike. A Directive without a gate is open-ended work — the agent builds, but nothing
says when it has arrived.

## Precise definition

An **agent story** = one user story made executable, written as:

- **Directive** — the named tasks the agent performs, in task-DAG order, each citing the requirement it satisfies.
- **Acceptance gate** — the check that closes the story: a real render, a status code, an empty-state, an
  assigns-only template, a grep. The gate is run, not interpreted.

A story with a Directive but no gate cannot close. A story with a gate but no Directive has nothing to run. Both
halves are mandatory.

## Worked Portal example — `F6.1-AS2` (verbatim from `f6.1.llms.md`)

> ### F6.1-AS2 — Render a user's courses [implements F6.1-US2]
> Directive: add the `:browser` pipeline and `get "/courses/:user_id", CourseController, :index` (T4); implement
> `CourseController.index/2` over `Portal.courses_of/1` (T5); build `CourseHTML` + `index.html.heex` rendering from
> assigns (T6).
> Acceptance gate: a known user renders their courses; no enrollments renders an empty state; the template
> references only assigns.

The two halves, read off the real story:

- **Directive (T4 → T6):** the `:browser` pipeline + the courses route `get "/courses/:user_id", CourseController,
  :index` (T4); `CourseController.index/2` calling `Portal.courses_of/1` (T5); `CourseHTML` + `index.html.heex`
  rendering from assigns (T6).
- **Acceptance gate (three checks):** a known user renders their courses; no enrollments renders an empty state;
  the template references only assigns.

The Directive names tasks; the gate names checks. The Directive is what the agent does; the gate is how the work —
and the reviewer — knows it is done.

Grounding ids cited (verbatim from `f6.1.llms.md`): `F6.1-AS1…AS4`, `F6.1-AS2`, `F6.1-US2`, tasks `T4`/`T5`/`T6`,
the facade `Portal.courses_of/1`, the controller `PortalWeb.CourseController` / `.index/2`, the view
`PortalWeb.CourseHTML`. No invented surface. (`Portal.ID.generate/1` / `Portal.ID.decode/1` are the only
freely-nameable APIs; not used here.)

## Interactives (two, teaching different moves)

### Hero (framing) — *the two halves*

- **Element ids:** selector `#halfSel` (buttons `data-part="directive"` / `data-part="gate"`); SVG `class="dq"`
  with bands `#hf-band-dir`, `#hf-band-gate`; counts `#hf-tasks`, `#hf-checks`; readout `#halfOut` (`aria-live`).
- **Dataset (fixed, from `F6.1-AS2`):** Directive = `['T4 :browser pipeline + courses route', 'T5
  CourseController.index/2 over Portal.courses_of/1', 'T6 CourseHTML + index.html.heex from assigns']`; Gate =
  `['a known user renders their courses', 'no enrollments renders an empty state', 'the template references only
  assigns']`.
- **Pure fns:**
  - `halfOf(part)` → `'Directive'` for `directive`, `'Acceptance gate'` for `gate` — labels the chosen half.
  - `itemsOf(part)` → the Directive task list or the gate check list.
  - `countOf(part)` → `itemsOf(part).length` (3 either way).
  - `readoutFor(part)` → the readout string.
- **Sample readout (Directive):** `"F6.1-AS2 · Directive — 3 tasks the agent runs: T4 the :browser pipeline + the
  courses route, T5 CourseController.index/2 over Portal.courses_of/1, T6 CourseHTML from assigns. The Directive
  lists what the agent does."`
- **Sample readout (gate):** `"F6.1-AS2 · Acceptance gate — 3 checks that close the story: a known user renders
  their courses, no enrollments renders an empty state, the template references only assigns. The gate names the
  check that proves it done."`
- **Static default:** Directive view lit, Directive readout shown.

### Content (teaching) — *Directive without a gate is open-ended*

- **Element ids:** selector `#closeSel` (buttons `data-mode="both"` / `data-mode="dir-only"`); SVG `class="dq"`
  with story cells `#cl-cell-0…3` (AS1…AS4), each carrying a `#cl-st-0…3` status label; count `#cl-count`;
  readout `#closeOut` (`aria-live`).
- **Dataset (fixed, `AS1…AS4`):** each story `{id, hasDirective:true, hasGate:true}`. In `dir-only` mode the gate
  is dropped from every story.
- **Pure fns:**
  - `closes(as, mode)` → `mode === 'both' && as.hasGate` — whether the story can close (has a gate to run).
  - `closingCount(mode)` → number of the four stories that close under the mode (4 with the gate, 0 without).
  - `closeReadout(mode)` → the readout string.
- **Sample readout (both):** `"Directive + gate — agent stories that can close: 4 of 4. With its gate, AS2 closes
  when a known user renders their courses; the Directive runs, the gate confirms."`
- **Sample readout (dir-only):** `"Directive only — agent stories that can close: 0 of 4. AS2's Directive still
  runs T4–T6, but nothing says when to stop — the agent builds with no signal it is done."`
- **Static default:** both-halves view, all four stories closing, both readout shown.

The two moves differ: the hero splits ONE story into its two halves (what each half is); the content figure
removes the gate from ALL FOUR stories to prove the consequence (no gate → cannot close).

## Bridge + take

- **Principle (`.cell.idea`):** pair every Directive with an Acceptance gate; a Directive alone is open-ended work.
- **Portal (`.cell.elix`):** `f6.1.llms.md`'s `F6.1-AS2` directs T4 → T6 and closes on a real `courses_of/1`
  render plus the empty-state and assigns-only checks.
- **Take:** The Directive sets the agent in motion; the gate tells it — and the reviewer — when it has arrived.

## Cross-links

- In-prose `/elixir/phoenix/lifecycle/controllers` — the controller `F6.1-AS2` directs (`CourseController.index/2`).
- Related-in-course: `/elixir/phoenix/lifecycle`.

## References — Sources (3, from the registry)

- User Stories Applied → `https://www.mountaingoatsoftware.com/books/user-stories-applied` — the user story whose
  executable counterpart an agent story is.
- INVEST in Good Stories → `https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/` — testable: a
  story carries a check that closes it; the agent story's gate.
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents` — an
  agent needs an explicit, closeable task, not an open-ended goal.

## Related in this course

- `/course/agile-agent-workflow/brief/agent-stories` — A5.4 · Agent stories (the module hub).
- `/course/agile-agent-workflow/brief` — A5 · The agent brief (chapter landing).
- `/course/agile-agent-workflow/spec` — A4 · The spec layer (the user stories an agent story makes executable).
- `/elixir/phoenix/lifecycle` — the companion chapter whose `f6.1.llms.md` this dive grounds on.
