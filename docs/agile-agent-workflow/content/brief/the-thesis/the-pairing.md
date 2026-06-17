# A5.7.1 — The pairing

- **Route:** `/course/agile-agent-workflow/brief/the-thesis/the-pairing`
- **File:** `html/agile-agent-workflow/brief/the-thesis/the-pairing.html`
- **Eyebrow:** `A5.7.1 · dive 1/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / The pairing.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `the-thesis` (link) / `the-pairing` (rcur).
- **Pager:** prev `…/brief/the-thesis` (hub) · next `…/brief/the-thesis/where-value-is-real`.
- **Parent hub:** `/course/agile-agent-workflow/brief/the-thesis` (being authored in parallel — a `links` FAIL
  naming only the hub and the `where-value-is-real` sibling is expected until they land).

## Lead

The thesis the whole course argues, stated as a pairing: a Claude agent is a fast, tireless implementer of
well-specified thin slices; the human is the source of decomposition, judgement, and acceptance. Speed comes from
the agent; direction comes from the human. Each is necessary, neither is sufficient. The F6 ship prompts run this
pairing on the Portal — and they keep judgement with the human at every step but the build.

## Precise definition

The **pairing** is a division of labour, not a hand-off. Across A1–A5 the human (the Operator) owns five layers —
vision, decomposition, the spec, the brief, and acceptance — and the agent (the Author) owns one: implementation.
The agent supplies speed; the workflow supplies direction; the value is the product of the two. A pairing that lets
the agent take a layer it does not own is not faster — it is a fast step in a direction the Operator never set.

The F6 ship prompts (`f6.6.prompt.md`, `f6.7.prompt.md`) are the worked pairing on the Portal. They split the work
across named stages under a Director (the human in the loop):

- **Venus** reconciles the spec against the as-built surface and writes the brief — *decomposition and direction*.
- **Mars** builds to that brief and hardens it — *implementation, the one layer the agent owns*.
- **Apollo** verifies the built tree against the spec — *an independent check, not the builder judging itself*.
- The **Director** (the human) ratifies the reconcile, confirms the liveness gate, and accepts — *judgement*.

The F6.6 prompt is explicit that the discipline lives elsewhere and the spawn carries only the rung delta: "the
spawn carries only what is *new about this rung*… the 'how the agent works' fact has one authority (the agent
definition), and the prompt carries only the delta." The Director "coordinates and ratifies; peers write the code."
The F6.7 prompt adds the liveness gate the human owns: "`mix test` alone does NOT satisfy the liveness criterion —
the endpoint runs `server: false` under test." That gate is the human's acceptance, run on a booted Portal, not the
agent's self-report.

## Worked Portal example

On F6.7 (real-time PubSub and Presence) the pairing reads off the prompt directly. The human reconciles
(decides whether the one new write surface `update_course/2` is in scope and ratifies it), the human briefs
(Venus's brief, ratified by the Director), the agent builds (Mars writes the broadcast helper, the
`connected?/1` subscribe seam, and the Presence tracker), an independent agent verifies (Apollo re-runs the gate
and the liveness two-window smoke and reports BUILD-GRADE or BLOCKED), and the human accepts (the Director confirms
the node boots and `curl :4000/health` is `200` before the one commit). Five of those six moves are the human's;
one — the build — is the agent's. The request lifecycle the agent assembles is taught in the companion course at
`/elixir/phoenix/lifecycle`; this course owns who decides what gets built, not how Phoenix routes a request.

## Interactive 1 — hero figure: "who owns what"

- **Move taught:** the layer split — the human owns every course layer but implementation.
- **Element ids:** selector `#ownSel` (buttons `data-layer="vision|decomposition|spec|brief|implementation|acceptance"`);
  SVG `#ownSvg` with row rects `#own-row-0…#own-row-5`, owner labels `#own-tag-0…#own-tag-5`, and a count
  `#own-count`; readout `#ownOut` (`aria-live="polite"`).
- **Dataset (fixed):** the A1–A5 role split.
  `LAYERS = [{layer:'vision',owner:'operator'},{layer:'decomposition',owner:'operator'},{layer:'spec',owner:'operator'},{layer:'brief',owner:'operator'},{layer:'implementation',owner:'author'},{layer:'acceptance',owner:'operator'}]`.
- **Pure functions:**
  - `roleOwns(layer)` → `'operator' | 'author'` (looks the layer up in `LAYERS`).
  - `operatorLayers()` → count of layers the operator owns (5 of 6).
  - `ownReadout(layer)` → the readout string for a selected layer.
- **Default (static markup):** `implementation` selected — the one layer the agent owns — so the static figure
  already shows the contrast.
- **Sample readout (implementation):** `"implementation — owner: the agent (Author). This is the one layer of the
  six the human does not own: the human owns vision, decomposition, the spec, the brief, and acceptance (5 of 6);
  the agent implements. Speed from the agent, direction from the human."`
- **Sample readout (decomposition):** `"decomposition — owner: the human (Operator). The human owns 5 of 6 layers
  — every layer but implementation; the agent owns implementation. The pairing keeps direction with the human."`

## Interactive 2 — content figure: "the loop"

- **Move taught (different):** ownership across the loop's five steps over one rung — judgement stays with the human
  at every step except the build.
- **Element ids:** selector `#stepSel` (buttons `data-step="0..4"` for decompose/brief/build/review/accept);
  SVG `#stepSvg` with step cells `#step-cell-0…#step-cell-4`, owner labels `#step-tag-0…#step-tag-4`, a
  human-owned count `#step-count`; readout `#stepOut` (`aria-live="polite"`).
- **Dataset (fixed):** the Author/Operator loop (A1.03) over one rung.
  `STEPS = [{step:'decompose',owner:'human'},{step:'brief',owner:'human'},{step:'build',owner:'agent'},{step:'review',owner:'human'},{step:'accept',owner:'human'}]`.
- **Pure functions:**
  - `stepOwner(i)` → `'human' | 'agent'` (the owner of step `i`).
  - `humanSteps()` → count of steps the human owns (4 of 5).
  - `stepReadout(i)` → the readout string for step `i`.
- **Default (static markup):** step `2` (build) selected — the one agent-owned step — so the static figure already
  shows that ownership returns to the human on either side of it.
- **Sample readout (build, i=2):** `"Step 3 of 5 — build — owner: the agent (Author). This is the only step of the
  five the human does not own: decompose, brief, review, and accept stay with the human (4 of 5). The loop hands
  the agent one step and takes judgement straight back."`
- **Sample readout (accept, i=4):** `"Step 5 of 5 — accept — owner: the human (Operator). The human owns 4 of 5
  steps — every step but the build; the agent builds. Ownership stays with the human at every step except the
  build."`

The two interactives teach different moves: the hero shows the **static layer ownership** across A1–A5 (six layers,
one owned by the agent), the content shows **ownership traversing the loop's five steps** over a single rung (the
agent owns exactly one step, and judgement returns immediately on both sides).

## Bridge + take

- **Principle (idea):** the pairing is speed from the agent and direction from the human; each is necessary,
  neither sufficient. The human owns decomposition, judgement, and acceptance; the agent implements.
- **Practice (Portal):** the F6 ship prompts split the work — the human reconciles, briefs, and accepts; the agent
  builds; an independent agent verifies. The Director coordinates and ratifies; the peers write the code.
- **Take:** Pragmatic programming with an agent is a pairing — the human directs, the agent implements, and the
  loop keeps judgement with the human.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/lifecycle` (the request lifecycle the agent assembles on the Portal).
- **Related in this course:** `/elixir/phoenix` (the companion F6 chapter hub); the parent hub
  `/course/agile-agent-workflow/brief/the-thesis`; `/course/agile-agent-workflow/why/loop` (A1.03, the loop this
  dive grounds the second interactive on); `/course/agile-agent-workflow/brief` (the chapter landing).

## References — Sources (3, from the vetted registry)

- The Pragmatic Programmer → `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — pragmatic programming as a discipline of dividing decisions from implementation.
- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
  — the agent is a fast implementer of a well-structured task; the human supplies the structure.
- Extreme Programming Explained → `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`
  — pairing as a practice: two roles working one task, neither sufficient alone.
