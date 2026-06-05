# A5 · Why a brief layer — orientation dive 1 (md source of record)

- **Route:** `/course/agile-agent-workflow/brief/why` (`brief/why.html`)
- **Eyebrow:** `A5 · orientation dive 1`
- **Crumbs (four-element):** `jonnify / Agile Agent Workflow / A5 · The agent brief / Why a brief layer`
  (the `A5 · The agent brief` segment links `/course/agile-agent-workflow/brief`; `<here>` is `<span class="here">`).
- **Accent:** elixir-purple.
- **Model:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`.
- **Pager:** prev `/course/agile-agent-workflow/brief` (landing); next `/course/agile-agent-workflow/brief/what`.

## Reverse-verification opener (binding)

A4 produced a spec that is correct by definition; A5 exists because **a spec is not code, and an agent without a
brief would decide what the Operator must decide**. The brief fixes every remaining how-to-build decision (the
exact sources, the runtime shape, the build order, the proof gates) and leaves the agent no ambiguity the Operator
must own.

## Lead

A spec defines *what and why and done*. It does not say *how to build it* — which sources to read, in what runtime
shape, in what order, against which gates. Hand a spec straight to an agent and the agent must fill those gaps
itself; the gaps it fills are exactly the decisions the Operator owns. The brief is the layer that fills them first.

## Lede (hero)

> A spec is the source of truth, not a build plan. A brief turns that truth into an unambiguous run: references
> first, every how-to-build decision fixed, none left for the agent to invent.

## Kicker (roadmap altitude)

The spec and the brief are different artifacts with different jobs. The spec is edited only by feedback and stays
authoritative. The brief is written fresh for each rung, derives entirely from the spec, and tells the implementer
how to build — without redefining anything. Conflate them and a build decision rewrites a definition; keep them
apart and the spec stays the source of truth while the brief makes the build runnable.

## Hero interactive — spec-vs-brief diff (framing)

- **id root:** `diffSel` (toggle: `person doc` / `agent brief`) + `diffOut` (`.geo-readout`) + the SVG `diff-*` cells.
- **Dataset (fixed):** the five parts of the A5 brief, grounded on `f6.1.llms.md`. Each part carries
  `{refsFrontLoaded, narrativeLines}` for the two views:
  - person doc: references scattered through prose; narrative lines present (a reader needs the story).
  - agent brief: references front-loaded (all in part 1, links first); narrative lines removed (the agent needs the
    decision, not the prose).
- **Pure fns:** `refsFrontLoaded(view)` (person → 0 of 5 front-loaded; agent → 5 of 5); `narrativeRemoved(view)`
  (person → 0 removed; agent → the narrative lines the agent does not need are removed); `readoutFor(view)`.
- **Sample readout (agent):** `Agent brief — references front-loaded: 5 of 5 (links first, every reference exact);
  narrative lines removed: 4 (the agent reads the decision, not the story). A brief is documentation re-shaped for
  an implementer: links first, prose second.`

## Content interactive — the ambiguity meter

- **id root:** `ambSel` (toggle: `spec only` / `spec + brief`) + `ambOut` (`.geo-readout`) + SVG decision cells.
- **Dataset (fixed):** the four how-to-build decisions a spec leaves to the builder, drawn from `f6.1.llms.md`:
  1. which sources to read (References) — the Phoenix hexdocs, the upstream `Portal` facade contract, `f0.md`.
  2. the runtime shape (Execution topology) — the two-supervisor tree; the endpoint boots after the engine.
  3. the build order (the task DAG T1→T7) — foundation → endpoint → supervision → router → controller → view → verify.
  4. the proof gates (Agent stories' Acceptance gates) — `GET /health` is 200; the master-invariant grep is empty.
- **Pure fns:** `decidedBy(view)` — spec-only leaves all four open (the agent decides); spec+brief closes all four
  (the brief fixes them); `openCount(view)`; `readoutFor(view)`.
- **Sample readout (spec + brief):** `Spec + brief — how-to-build decisions left open to the agent: 0 of 4. The
  brief fixes the sources, the runtime shape, the build order, and the proof gates; the agent implements, it does
  not decide.`

## Principle → Portal practice (bridge)

- **Principle:** an unbriefed agent fills the spec's how-to-build gaps with its own choices — and those choices are
  the Operator's to make.
- **On the Portal:** `f6.1.llms.md` front-loads the references, fixes the two-supervisor topology and the T1→T7
  task order, and names each agent story's Acceptance gate — so the Author building the web bootstrap implements
  the fixed plan rather than deciding the architecture.

## References

- Sources: the `llms.txt` convention (`https://llmstxt.org/`); Anthropic — Building effective agents
  (`https://www.anthropic.com/engineering/building-effective-agents`); The Pragmatic Programmer
  (`https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`).
- Related: `/spec`, `/brief`, `/why/loop`, `/what/four-artifacts`, `/elixir/phoenix`.
