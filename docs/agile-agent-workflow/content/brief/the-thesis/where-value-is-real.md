# A5.7.2 — Where the value is real

- **Route:** `/course/agile-agent-workflow/brief/the-thesis/where-value-is-real`
- **File:** `html/agile-agent-workflow/brief/the-thesis/where-value-is-real.html`
- **Eyebrow:** `A5.7.2 · dive 2/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/the-thesis` (A5.7, authored in parallel).
- **Pager:** prev `/course/agile-agent-workflow/brief/the-thesis/the-pairing` · next
  `/course/agile-agent-workflow/brief/the-thesis/the-failure-mode`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / Where the value is real.

## Lead

The dive before this named the pairing: the agent supplies speed, the workflow supplies direction, and the value
is the product of the two. This dive answers the next question precisely — *where, exactly, is that product
positive?* The answer is a well-specified, thin, gated slice. On a slice specified down to its requirements, its
task order, and its gates, the agent's speed converts straight to progress, because nothing is left for the agent
to decide.

## The precise definition

The value is real on a slice that is:

- **thin** — two-to-six files of change, not a system;
- **well-specified** — every branch already decided (the success render, the empty state, the error render), so
  the agent implements rather than chooses;
- **gated** — one command and one runnable check close it, so "done" is a closure over a check, not an opinion.

When all three hold, the agent's direction is fixed at `+1` and its speed is a clean multiplier: each unit of
speed is a unit of progress. The smaller and more specified the slice, the cleaner that multiplier — a larger
slice leaves more surface where an unspecified branch can creep back in.

## The worked Portal example — `f6.1.llms.md`, the two plans

`f6.1.llms.md` is the Portal's web-bootstrap brief, and it carries the evidence verbatim. Its
"Execution plan — first two stories" walks two user stories end to end as *story → agent story → tasks → files →
command → gate*:

- **Plan A — `F6.1-US1` (serve the Portal as a Phoenix app) · via `F6.1-AS1`.** Tasks `T1 → T2 → T3`. Files:
  `apps/portal_web/mix.exs`, `config/config.exs`, `config/runtime.exs`, `apps/portal_web/lib/portal_web.ex`,
  `apps/portal_web/lib/portal_web/application.ex`, `apps/portal_web/lib/portal_web/telemetry.ex`,
  `apps/portal_web/lib/portal_web/endpoint.ex`, `apps/portal/lib/portal/application.ex` (drop Bandit),
  `apps/portal/mix.exs` (drop bandit), `apps/portal_web/lib/portal_web/router.ex` (add `get "/health"`).
  Command: `mix deps.get && mix compile && mix phx.server`, then `curl -i localhost:4000/health`. Gate:
  `200 ok` from `/health`; the `:portal` tree boots before the `:portal_web` tree.
- **Plan B — `F6.1-US2` (see a user's courses) · via `F6.1-AS2`.** Tasks `T4 → T5 → T6`. Files (five):
  `router.ex`, `course_controller.ex`, `course_html.ex`, `course_html/index.html.heex`,
  `course_html/error.html.heex`. Command: `mix test … course_controller_test.exs` plus a manual
  `curl localhost:4000/courses/USR_known`. Gate: a known user renders their courses; an unknown/malformed id
  renders an empty state (`200`); the `422` render path is unit-verified via an injected `%Portal.Error{}`; the
  master-invariant grep is empty.

The brief closes with the line that makes the thesis evidence rather than assertion — quoted verbatim on the page:

> Efficiency check: each story is two-to-six files behind one command and one gate, and every branch (empty state,
> injected-error render) is already specified — so the agent implements rather than decides.

Two-to-six files, one command, one gate, every branch specified. That is the shape of a slice where the agent's
speed is pure progress.

In-prose `/elixir` cross-link: `/elixir/phoenix/lifecycle/request-path` — the request path the ordered, specified
build assembles.

## Interactive 1 — hero (framing): files behind a gate

**Move taught:** measure the artifact. A specified slice is small, fast, and gated — count the files standing
behind a single command and a single gate.

- **Controls:** `#fbgSel` — two buttons (`data-plan="A"` / `data-plan="B"`, `data-c="elixir"`); Plan A active
  by default in static markup.
- **SVG:** `#fbg` — a stack of file bands (one per file in the selected plan) above a single command band and a
  single gate band, with a `#fbg-count` file-count and a `#fbg-ratio` files-per-gate readout text.
- **Dataset (fixed, from `f6.1.llms.md`):**
  - Plan A: 10 files (`['apps/portal_web/mix.exs','config/config.exs','config/runtime.exs','portal_web.ex',
    'application.ex','telemetry.ex','endpoint.ex','portal/application.ex','portal/mix.exs','router.ex (+/health)']`),
    1 command, 1 gate.
  - Plan B: 5 files (`['router.ex','course_controller.ex','course_html.ex','index.html.heex','error.html.heex']`),
    1 command, 1 gate.
- **Pure functions:**
  - `filesOf(plan)` → the file list for the plan.
  - `filesPerGate(plan)` → `filesOf(plan).length` (files behind the plan's single command + single gate).
  - `branchesSpecified(plan)` → all branches specified (true for both plans).
  - `fbgReadout(plan)` → the readout string.
- **Sample readout (Plan B):** "Plan B (see a user's courses): 5 files behind one command and one gate; every
  branch already specified. A specified slice is small, fast, and gated — the shape where the agent's speed is a
  clean multiplier."
- **Sample readout (Plan A):** "Plan A (serve the Portal as a Phoenix app): 10 files behind one command and one
  gate; every branch already specified. Two-to-six is the per-story shape; the whole bootstrap is still one
  command and one gate."
- **Degrade:** static markup ships Plan A lit with its 10 bands and a correct default readout. JS only re-renders
  on toggle.

## Interactive 2 — content (teaching): speed × specification

**Move taught:** compute the consequence. With direction fixed at `+1` (well-specified), progress = speed ×
specification — and the cleaner the specification, the more of the agent's speed converts to progress. This is a
*different* move from the hero (which counts files): here the reader varies the slice and watches net progress
respond, with direction held positive.

- **Controls:** `#sxsSel` — three buttons selecting slice size (`data-slice="thin"` / `data-slice="medium"` /
  `data-slice="broad"`; `data-c="elixir"`); thin active by default in static markup. (The agent's speed is fixed
  high across all three — the variable is the slice, not the agent.)
- **SVG:** `#sxs` — a bar whose filled width is the converted-progress fraction, with `#sxs-spec` (specification
  level), `#sxs-conv` (conversion fraction), and a fixed `direction = +1` marker.
- **Dataset (fixed model; direction = +1 throughout — this dive is the positive case):**
  - `SPEED = 100` (the agent's speed, high and fixed).
  - slice → specification fraction (how completely the slice's branches are pinned): `thin → 1.0`,
    `medium → 0.8`, `broad → 0.55`. Thinner slices are more completely specified, so more speed converts.
  - `DIRECTION = +1` (well-specified — fixed for this dive).
- **Pure functions:**
  - `specOf(slice)` → the specification fraction for the slice.
  - `valueAdded(spec, speed)` → `DIRECTION * speed * spec` (net progress; `DIRECTION` is `+1` here).
  - `convPct(slice)` → `Math.round(specOf(slice) * 100)` (percent of speed that converts to progress).
  - `sxsReadout(slice)` → the readout string.
- **Sample readout (thin):** "Well-specified, thin slice: direction +1, every branch pinned (spec 100%) — 100 of
  100 units of the agent's speed convert to progress. The smaller and more specified the slice, the cleaner the
  multiplier."
- **Sample readout (broad):** "Well-specified but broad slice: direction +1, spec 55% — 55 of 100 units convert;
  the rest is surface where an unspecified branch can creep back. Thin and gated keeps the multiplier clean."
- **Degrade:** static markup ships the thin slice with a full bar and a correct default readout; JS only
  re-renders on toggle.

## Bridge + take

- **Principle (`.cell.idea`):** the agent's value is real on a well-specified, thin, gated slice — speed with a
  fixed direction. Each unit of speed is a unit of progress only when nothing is left to decide.
- **Portal (`.cell.elix`):** `f6.1.llms.md`'s stories are two-to-six files behind one command and one gate, every
  branch (empty state, injected-error render) already specified — so the agent implements rather than decides.
- **Take:** Specify thin and gate hard, and the agent's speed is pure progress.

## References

### Sources (3, real external links from the registry)

- The Pragmatic Programmer →
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — design by contract:
  pin every decision so the value of speed is never spent on a guess.
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents` — a
  coding agent is most effective on an explicit, well-scoped task, not an open-ended goal.
- Extreme Programming Explained → `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`
  — small, tested increments are the unit where feedback and speed compound.

### Related in this course

- `/course/agile-agent-workflow/brief/the-thesis` — A5.7, the thesis module hub.
- `/course/agile-agent-workflow/brief/the-thesis/the-pairing` — A5.7.1, speed × direction, the two roles.
- `/course/agile-agent-workflow/brief/agent-stories/first-two-stories` — A5.4.2, the worked first-two-stories plan.
- `/course/agile-agent-workflow/spec` — A4, the spec a thin slice is specified against.
- `/elixir/phoenix` — companion Phoenix (F6) chapter, the worked `f6.1.llms.md` slice.

## Wiring notes

- Two inline `<script>` blocks copied verbatim from `brief/why.html` (the decoder + the reveal enhancer), with the
  page's own interactive logic in the first script.
- `#refs` link present in the `.toc-mini`.
- Clamp spacing kept spaced (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`).
- No invented Portal API: only real `f6.1.llms.md` surfaces (`F6.1-US1/US2`, `F6.1-AS1/AS2`, `T1…T6`, the file
  lists, `Portal.courses_of/1`, `%Portal.Error{}`, the master-invariant grep) quoted as they appear in source.
