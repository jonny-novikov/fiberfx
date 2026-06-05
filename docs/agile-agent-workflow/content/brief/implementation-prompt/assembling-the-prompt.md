# A5.5.1 — Assembling the prompt

- **Route:** `/course/agile-agent-workflow/brief/implementation-prompt/assembling-the-prompt`
- **File:** `html/agile-agent-workflow/brief/implementation-prompt/assembling-the-prompt.html`
- **Eyebrow:** `A5.5.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/implementation-prompt` (A5.5).
- **Pager:** prev `/course/agile-agent-workflow/brief/implementation-prompt` · next
  `/course/agile-agent-workflow/brief/implementation-prompt/task-order`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / Assembling the prompt.
- **Route-tag (segmented):** `course/agile-agent-workflow` (link) / `brief` (link) /
  `implementation-prompt` (link) / `assembling-the-prompt` (rcur).

## Lead

The fifth part of the brief is the implementation prompt — the single instruction an agent runs to build the
increment. The prompt does not introduce anything new. It gathers the four parts that came before — references,
requirements, topology, agent stories — into one runnable pass. This dive teaches the gather: the prompt is the
assembly point of the whole brief, and each part it carries is a guarantee it can give; each part it omits is a
guarantee it cannot.

## Precise definition

The implementation prompt **assembles the four prior parts of the brief into one runnable instruction**. It opens by
naming the sources the agent reads (references), the boundary it must not cross and the build order it follows (from
topology), the requirements it satisfies, and the stories it runs. It fixes no decision the spec has not already
fixed; it only folds the brief's parts into a single pass an agent can execute.

A prompt that drops a part loses the guarantee that part supplied. Drop the references and the prompt no longer tells
the agent which sources to read first. Drop the topology and the prompt no longer fixes the build order or the
unchanged-code boundary.

## Worked Portal example (grounded on the real `f6.1.llms.md`)

The Portal's web bootstrap ships from a real brief, `f6.1.llms.md`. Its `## Comprehensive implementation prompt`
opens with directives that are the prior parts folded in — quoted verbatim:

> "You are implementing spec F6.1 (Bootstrap the Phoenix Portal) as a NEW umbrella app `apps/portal_web` … Read
> `specs/phoenix/f6.1.md`, `specs/phoenix/f6.1.stories.md`, and `specs/design/f0.md` first. Do not change anything
> under the Portal facade: the engine (Portal.Engine), the store, the contexts, and the Portal facade stay exactly
> as F5 left them. Phoenix deps go ONLY in apps/portal_web/mix.exs, so apps/portal/mix.exs stays Phoenix-free …"

Reading those three sources is the **references** part, folded in. "Do not change anything under the Portal facade"
and "Phoenix deps go ONLY in `apps/portal_web/mix.exs`" are the **topology**'s boundary, folded in. The prompt then
runs the **agent stories** (`F6.1-AS1…AS4`) over the task DAG, satisfying the numbered **requirements**
(`F6.1-R1…R8`). Four parts, gathered into one instruction.

The `Portal` facade the prompt pins is reached only through `Portal.courses_of/1`; `Portal.ID.generate/1` mints the
branded id for a record. The web layer never names `Portal.Engine`, a repo, or `GenServer.call`.

## Interactive 1 — hero (framing): which parts the prompt carries

- **Move taught:** the prompt is the gather-point — it carries each of the four prior parts.
- **Dataset:** the four prior parts `{references, requirements, topology, agent stories}`, each with the verbatim
  fragment of the `f6.1.llms.md` prompt that carries it.
- **Pure functions:**
  - `carries(part)` → `true` for all four (the prompt names the sources to read, the no-change boundary, the build
    order, and the stories).
  - `carriedCount()` → 4.
  - `fragmentFor(part)` → the verbatim prompt fragment that carries that part.
  - `heroReadout(part)` → the readout string.
- **Control ids:** `#partSel` (four buttons, `data-part="references|requirements|topology|stories"`).
- **SVG id:** `#carrySvg` with four bands `#cy-band-0..3` and a carried-count `#cy-count`.
- **Readout id:** `#carryOut` (`aria-live="polite"`).
- **Sample readout (references selected):** "References — carried into the prompt: yes (4 of 4 prior parts
  carried). The prompt opens by naming the sources to read first: `f6.1.md`, `f6.1.stories.md`, `f0.md`. The prompt
  is the gather-point of the whole brief."
- **Static default:** the references band lit, `#cy-count` reads `4 of 4`, `#carryOut` carries the references string.

## Interactive 2 — content (teaching): drop a part, lose a guarantee

- **Move taught (different from the hero):** dropping a prior part removes a specific guarantee from the prompt — the
  consequence of an incomplete assembly, not merely the count of parts.
- **Dataset:** the four prior parts, each paired with the guarantee it gives the prompt:
  - references → "tells the agent which sources to read first"
  - requirements → "names the numbered checks the build must satisfy"
  - topology → "fixes the build order and the unchanged-code boundary"
  - agent stories → "names each unit of work and its closing gate"
- **Pure functions:**
  - `guaranteeLost(dropped)` → the guarantee string the prompt can no longer assure (or "none — all four parts
    carried" when `dropped === 'none'`).
  - `guaranteesKept(dropped)` → 4 when nothing dropped, else 3.
  - `dropReadout(dropped)` → the readout string.
- **Control ids:** `#dropSel` (buttons `data-drop="none|references|requirements|topology|stories"`).
- **SVG id:** `#dropSvg` with four cells `#dp-cell-0..3` (the dropped one marked lost) and a kept-count `#dp-count`.
- **Readout id:** `#dropOut` (`aria-live="polite"`).
- **Sample readout (drop references):** "Drop references — the prompt no longer tells the agent which sources to read
  first (guarantees kept: 3 of 4). Each part the prompt omits is a guarantee it cannot give."
- **Sample readout (drop topology):** "Drop topology — the prompt no longer fixes the build order or the
  unchanged-code boundary (guarantees kept: 3 of 4). Each part the prompt omits is a guarantee it cannot give."
- **Static default:** `data-drop="none"` active, all four cells whole, `#dp-count` reads `4 of 4`, `#dropOut` carries
  the all-carried string.

## Bridge + take

- **Principle (idea):** the prompt assembles the brief's parts; each part it omits is a guarantee it cannot give.
- **Portal (elix):** `f6.1.llms.md`'s prompt opens by naming the sources to read, the unchanged-facade boundary, and
  the Phoenix-deps-only-in-`portal_web` constraint — references and topology, folded in.
- **Take:** A complete prompt is the four prior parts gathered into one runnable instruction.

## `/elixir` cross-link

- In-prose: `/elixir/phoenix/lifecycle/endpoint` (the endpoint the prompt's foundation step builds).
- Related in this course: `/elixir/phoenix/lifecycle` (the request lifecycle the F6.1 prompt assembles).

## References — Sources (3, from the registry)

- Anthropic — *Claude Code best practices* → `https://www.anthropic.com/engineering/claude-code-best-practices` —
  assembling a single, complete prompt an agent runs in order.
- The `llms.txt` convention → `https://llmstxt.org/` — the links-first machine-brief form the prompt gathers.
- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — pin every decision the builder must not have to invent.

## Related in this course

- A5.5 · The implementation prompt (`/course/agile-agent-workflow/brief/implementation-prompt`) — the module hub.
- A5.4 · Agent stories (`/course/agile-agent-workflow/brief/agent-stories`) — the fourth part the prompt runs.
- A5.3 · Execution topology (`/course/agile-agent-workflow/brief/execution-topology`) — the third part folded in.
- Companion · Phoenix request lifecycle (`/elixir/phoenix/lifecycle`).
