# A5.4.3 — Acceptance gates

- **Route:** `/course/agile-agent-workflow/brief/agent-stories/acceptance-gates`
- **File:** `html/agile-agent-workflow/brief/agent-stories/acceptance-gates.html`
- **Eyebrow:** `A5.4.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/agent-stories`
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) /
  `agent-stories` (link) / `acceptance-gates` (rcur).
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / Acceptance gates (here).
- **Pager:** prev `/course/agile-agent-workflow/brief/agent-stories/first-two-stories` ·
  next `/course/agile-agent-workflow/brief/agent-stories` (back to hub).

## Lead

The Directive sets the agent in motion; the Acceptance gate is where it stops. A gate is the runnable
check that closes an agent story — and the line between "the agent thinks it is done" and "the work is
provably done." A story with no gate can never close: the agent has work to do, but no signal that it is
finished, and the reviewer has nothing to run.

This is the third dive of A5.4. The first named the two halves of an agent story (Directive and gate); the
second walked the first two stories end to end. This one isolates the gate: what makes a check a gate, and
why a story without one is incomplete.

## Definition

An **Acceptance gate** is a single runnable check that closes one agent story. It is not the agent's
self-report ("done — it compiles"); it is a command the human (or a script) runs whose pass/fail is
unambiguous. Every agent story in a well-formed brief carries exactly one. A story whose gate is absent is
flagged incomplete — it is a Directive with no closing condition.

## The worked Portal example — the four gates of `f6.1.llms.md`

Grounded on the Acceptance gate line of each of `F6.1-AS1…AS4` in the real `f6.1.llms.md` (quoted verbatim):

- **`F6.1-AS1` — Boot as a Phoenix app.** Gate: `mix compile` clean; app boots; `GET /health` returns
  `200`; tree order is store → engine → endpoint. *(check kind: boot)*
- **`F6.1-AS2` — Render a user's courses.** Gate: a known user renders their courses; no enrollments
  renders an empty state; the template references only assigns. *(check kind: render)*
- **`F6.1-AS3` — Hold the boundary.** Gate:
  `grep -rE "Portal\.Engine|Repo|GenServer\.call" apps/portal_web/lib/` returns nothing;
  `Portal.Application` drops Bandit (→ three F5 children) and the new `PortalWeb.Application` owns
  `[PortalWeb.Telemetry, PortalWeb.Endpoint]`. *(check kind: grep)*
- **`F6.1-AS4` — Self-heal and fail soft.** Gate: killing the endpoint restarts it and a later request
  succeeds; an unknown/malformed user id renders the empty state (`200`); the `422` render path is
  unit-verified via an injected `%Portal.Error{}` with a message from the closed set. *(check kind: restart + 422)*

Each gate is a different kind of check — a boot, a real render, a static grep, a self-heal-plus-fail-soft —
but every one is runnable and its result is unambiguous. AS3's gate is a literal grep that must return
nothing; AS4's closes on the endpoint self-healing under `:one_for_one` and an injected `%Portal.Error{}`
rendering `422`, never `500`.

The in-prose `/elixir` cross-link points at `/elixir/phoenix/contexts/vs-facade` — the facade-vs-engine
boundary that AS3's grep guards (no module under `apps/portal_web/lib/` may name `Portal.Engine`).

## Interactive 1 — hero, framing: "the four gates"

- **Container:** `.hero-split` figure, `id="gateSel"` selector, `svg.dq` with id `gates`, readout `#gateOut`.
- **Move it teaches:** every one of the four stories closes on a different runnable check — the gate is the
  story's closing condition, made concrete per story.
- **Dataset (fixed, from `f6.1.llms.md`):** the four agent stories, each `{id, title, gate, kind}`:
  - AS1 / Boot as a Phoenix app / "mix compile clean; app boots; GET /health 200; tree order store → engine → endpoint" / boot
  - AS2 / Render a user's courses / "a known user renders their courses; no enrollments renders an empty state; the template references only assigns" / render
  - AS3 / Hold the boundary / "grep -rE … apps/portal_web/lib/ returns nothing; Portal.Application drops Bandit; PortalWeb.Application owns [Telemetry, Endpoint]" / grep
  - AS4 / Self-heal and fail soft / "killing the endpoint restarts it; unknown id → empty state 200; an injected %Portal.Error{} → 422" / restart + 422
- **Controls:** four buttons (AS1 / AS2 / AS3 / AS4), `data-c="elixir"`. AS1 active by default in static markup.
- **Pure functions:**
  - `gateOf(as)` → the gate string for a story id.
  - `kindOf(as)` → the check kind ("boot" / "render" / "grep" / "restart + 422").
  - `gateReadout(as)` → the readout string.
- **Readout (`#gateOut`, aria-live):** e.g. for AS1 — *"F6.1-AS1 (Boot as a Phoenix app) closes on a boot
  check: mix compile clean, GET /health 200, tree order store → engine → endpoint. The gate is one runnable
  check, not a self-report."*
- **Static default state:** AS1 selected, its gate rendered, readout shows the AS1 boot gate.

## Interactive 2 — content, teaching: "find the storyless gate / the gateless story"

- **Container:** `.fig`, `id="missSel"` selector, `svg.dq` with id `miss`, readout `#missOut`.
- **Move it teaches (different from hero):** every story must carry a gate; a story with no closing check is
  incomplete and can never close — the readout flags it.
- **Dataset (fixed):** `AS1…AS4` each with a gate present; a toggle injects a fifth synthetic story
  `AS5* (no gate)`.
- **Controls:** two buttons — "four stories" (default, all gated) vs "add a gateless story" (injects AS5*).
- **Pure functions:**
  - `missingGate(stories)` → the array of story ids with no closing check (`[]` when all four; `['AS5*']`
    when the synthetic story is injected).
  - `missCount(view)` → the number of stories with no gate.
  - `missReadout(view)` → the readout string.
- **Readout (`#missOut`, aria-live):** default — *"All four agent stories have a gate: 0 missing. Each one
  closes on a runnable check."* On inject — *"Add a story with no gate and the readout flags it incomplete:
  1 missing (AS5*). A story with no gate can never close — the agent has work to do but no signal it is
  done."*
- **Static default state:** "four stories" selected, all four cells marked gated, count 0 missing.

(Mirrors the A5.4 acceptance criterion: a story whose gate is missing is flagged.)

## Bridge + take

- **Principle (`.cell.idea`):** the Acceptance gate is the runnable check that closes a story; a story with
  no gate is incomplete.
- **Practice (`.cell.elix`):** `f6.1.llms.md` closes `F6.1-AS3` on `grep … apps/portal_web/lib/` being empty
  and `F6.1-AS4` on the endpoint self-healing under `:one_for_one` and an injected `%Portal.Error{}`
  rendering `422`.
- **Take:** A gate is the line between "the agent thinks it is done" and "the work is provably done."

## References

**Sources (3, vetted registry):**
- User Stories Applied → `https://www.mountaingoatsoftware.com/books/user-stories-applied`
- INVEST in Good Stories → `https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/`
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`

**Related in this course:**
- `/course/agile-agent-workflow/brief/agent-stories/directive-and-gate` — the two halves a gate completes.
- `/course/agile-agent-workflow/brief/agent-stories/first-two-stories` — the stories these gates close.
- `/course/agile-agent-workflow/brief/agent-stories` — the module hub.
- `/course/agile-agent-workflow/brief/implementation-prompt` — the prompt that ends on these gates.
- `/elixir/phoenix/lifecycle` — the companion chapter whose `f6.1.llms.md` carries `F6.1-AS1…AS4`.

In-prose `/elixir` cross-link: `/elixir/phoenix/contexts/vs-facade` (the boundary AS3's grep guards).
