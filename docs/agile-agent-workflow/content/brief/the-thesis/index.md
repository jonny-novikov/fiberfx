# A5.7 — Pragmatic Programming with Claude Agents (module hub)

- **Route:** `/course/agile-agent-workflow/brief/the-thesis`
- **File:** `html/agile-agent-workflow/brief/the-thesis/index.html`
- **Eyebrow:** `A5.7 · module hub`
- **Accent:** elixir-purple (chapter signature). **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / A5.7 · The thesis (here).
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `the-thesis` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief` · next `/course/agile-agent-workflow/brief/the-thesis/the-pairing`.

## Lead

A5.1 through A5.6 built the brief and the practice of running it. This module names the thesis the whole course has
argued: **a Claude agent is a fast, tireless implementer of well-specified thin slices; the human is the source of
decomposition, judgement, and acceptance.** The value is the product of the two — neither alone. It names where the
value is real (a well-specified slice) and the failure mode (an under-specified slice). The module ties back to A1's
thesis (`/course/agile-agent-workflow/why`) and A1.05 "correct by definition" (`/course/agile-agent-workflow/why/correct`).

## The precise statement

Pragmatic Programming with Claude Agents is a pairing of two roles:

- **The agent** supplies *speed* and *implementation*. It builds a specified slice fast and tirelessly, and it does
  not tire, drift, or skip steps across a long run.
- **The human** supplies *direction*: decomposition (cutting the work into thin slices), judgement (the calls a spec
  cannot make), and acceptance (reading the result against the spec's Definition of Done, never the agent's
  self-report).

The value of the pairing is the **product** of speed and direction, not their sum. Speed alone, pointed nowhere, is
a fast walk off a cliff. Direction alone, with no implementer, is a plan that never ships. The two compound.

## The worked unit — `f6.1.llms.md`

`f6.1.llms.md` (the real Portal brief for the Phoenix web bootstrap over the unchanged facade) is a slice specified
down to requirements `F6.1-R1…R8`, the task DAG `T1→T7`, and the acceptance gates per agent story `F6.1-AS1…AS4`.
The brief's own closing line is the evidence the value is real on a specified slice — quoted verbatim:

> Efficiency check: each story is two-to-six files behind one command and one gate, and every branch (empty state,
> injected-error render) is already specified — so the agent implements rather than decides.

"So the agent implements rather than decides" is the thesis in one clause: when the slice is specified, the agent's
speed converts directly into progress, because nothing is left for it to decide. The cross-link
`/elixir/phoenix/lifecycle` is the real chapter whose `f6.1.llms.md` this grounds on.

## Dives into (the `.mods` grid — 3 cards, real routes)

- **A5.7.1 · The pairing** — `/course/agile-agent-workflow/brief/the-thesis/the-pairing` — speed from the agent ×
  direction from the workflow; the two roles that compound.
- **A5.7.2 · Where the value is real** — `/course/agile-agent-workflow/brief/the-thesis/where-value-is-real` — on a
  well-specified slice the agent's speed is a multiplier.
- **A5.7.3 · The failure mode** — `/course/agile-agent-workflow/brief/the-thesis/the-failure-mode` — on an
  under-specified slice the agent improvises, and speed multiplies the wrong direction.

## Interactive 1 — hero (framing): "the two roles"

- **Move taught:** *who owns what* — the value is the product of two distinct ownerships.
- **Dataset (fixed):** the two roles —
  - agent: owns `implementation` and `speed`; contributes the *speed* factor.
  - human: owns `decomposition`, `judgement`, `acceptance`; contributes the *direction* factor.
- **Control ids:** `#roleSel` (segmented buttons `data-role="agent"|"human"|"product"`), SVG `#rolesFig`, readout
  `#roleOut` (`aria-live="polite"`).
- **Pure functions:**
  - `ownsOf(role)` → returns the list of what `role` owns + the factor it contributes.
  - `roleReadout(role)` → the readout string for the selected role (or the product view).
- **Static default (JS-off):** the "product" view lit, readout pre-rendered for the product.
- **Sample readout (product):** *"The pairing — value = speed (agent) × direction (human). The agent owns
  implementation and supplies speed; the human owns decomposition, judgement, and acceptance and supplies direction.
  Neither factor alone is the value — the product is."*

## Interactive 2 — content (teaching): "the compounding"  ·  outcome = speed × direction

- **Move taught:** *the multiplier has a sign* — speed multiplies whichever direction the spec set.
- **Dataset (fixed):** a model of one slice. `SPEED = 8` (the agent's, high, constant). `direction` ∈
  { well-specified: `+1`, under-specified: `-1` }. Grounded on `f6.1.llms.md`: a well-specified slice is
  two-to-six files behind one gate, every branch specified (+1); an under-specified slice leaves a decision to the
  agent, which it fills by improvising (−1).
- **Control ids:** `#specSel` (segmented buttons `data-spec="well"|"under"`), SVG `#compFig`, readout `#compOut`
  (`aria-live="polite"`).
- **Pure functions:**
  - `directionOf(spec)` → `+1` for `well`, `-1` for `under`.
  - `outcome(spec)` → `SPEED * directionOf(spec)` (a signed magnitude).
  - `compReadout(spec)` → the readout string.
- **Static default (JS-off):** the "well-specified" view lit, readout pre-rendered for `+8`.
- **Sample readout (well):** *"Well-specified: high speed (8) × right direction (+1) = +8, a large step toward done.
  The agent's speed converts directly to progress."*
- **Sample readout (under):** *"Under-specified: high speed (8) × wrong direction (−1) = −8, a large step away. The
  agent's speed multiplies whichever direction the spec set."*

## Bridge

- **Principle (`.cell.idea`):** the agent is a fast implementer of well-specified slices; the human owns
  decomposition, judgement, and acceptance — and the value is the product.
- **Practice (`.cell.elix`):** `f6.1.llms.md` specifies the slice down to `F6.1-R1…R8`, the `T1→T7` DAG, and the
  gates; the agent builds it fast because nothing is left to decide.
- **Take:** *The agent supplies speed; the workflow supplies direction; multiply them.*

## References

### Sources (3, real, vetted)

- The Pragmatic Programmer →
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
- Extreme Programming Explained → `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`

### Related in this course

- `/course/agile-agent-workflow/why` — A1's thesis (thin, provable slices).
- `/course/agile-agent-workflow/why/correct` — A1.05 "correct by definition".
- `/course/agile-agent-workflow/brief` — A5 · The agent brief (parent chapter).
- `/elixir/phoenix` — Companion · Phoenix (F6), the chapter whose `f6.N.llms.md` briefs this grounds on.

## Wiring notes

- Two trailing `<script>` blocks copied verbatim from `html/agile-agent-workflow/brief/index.html` (the page's own
  interactive script replaces the brief landing's, but the Snowflake decoder + reveal scripts are kept).
- `#refs` link present in `.toc-mini`.
- A `links` FAIL naming only the three sibling dives (`the-pairing`, `where-value-is-real`, `the-failure-mode`) is
  expected until they land in parallel.
