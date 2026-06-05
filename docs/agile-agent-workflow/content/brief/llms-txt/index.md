# A5.1 — Writing for an agent: the llms.txt convention (module hub)

- **Route:** `/course/agile-agent-workflow/brief/llms-txt`
- **File:** `html/agile-agent-workflow/brief/llms-txt/index.html`
- **Eyebrow:** `A5.1 · module hub`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Grounds on:** `f6.1.llms.md` — its overall *shape*: the links-first References block, then prose.

## Lead

A4 wrote the spec — correct by definition. The orientation dives then framed the brief: `/brief/why` argued a spec
deserves a layer of its own, and `/brief/what` named the five parts, references first. A5.1 takes up the first idea
and goes deeper than either: *how to write for a machine reader at all.* A brief an agent runs is not documentation
for a person. A person reads a narrative and forms intent; an agent reads links and decisions and acts. So the
brief front-loads the exact sources first, keeps only the prose that carries a decision, and names every reference
precisely enough that the agent reads the right thing. That is the `llms.txt` form a machine brief takes — the form
the Portal's real `f6.1.llms.md` follows, and the form this module teaches across three dives.

## Precise definition

A **machine brief** (the `llms.txt` form) is a document written for an agent reader, not a person: a links-first
References block placed before any narrative, followed only by the parts an agent acts on — requirements, the
runtime and build topology, the agent stories, the implementation prompt — with the narrative an agent does not
need removed. The agent reads the sources first, then acts on the decisions; it does not read a story and infer
intent.

## Worked Portal example (verbatim from `f6.1.llms.md`)

The Portal's web bootstrap is briefed in `f6.1.llms.md`. Its top-of-file blockquote states the reading order plainly:

> Read the references first, satisfy the requirements, build in task-topology order, and close each agent story on
> its gate. This brief is self-contained.

Its structure follows that order: a `## References` heading whose six entries are exact links — the Phoenix endpoint
hexdocs, the router hexdocs, the controller hexdocs, the Plug docs, the F0 design system, and the upstream `Portal`
facade contract — placed before any requirement prose. The agent reads all six sources first, then acts on
`F6.1-R1…R8`. The References block opens with links; the prose that follows carries decisions, not narration.

## Both interactives

### Hero interactive (framing) — `reader-mode toggle`

- **Teaches:** a machine brief opens with the exact sources, not a narrative.
- **Dataset:** the section order of `f6.1.llms.md` — References, Requirements, Execution topology, Agent stories, the
  implementation prompt — plus, for each of two reader modes, whether prose or links come first.
- **Control ids:** `#modeSel` (segmented toggle, buttons `data-mode="person"` / `data-mode="agent"`), readout
  `#modeOut`. SVG `#readerSvg` (two stacked column groups: a person-doc column prose-first, an agent-brief column
  links-first; the chosen mode is highlighted).
- **Pure functions:**
  - `firstSectionFor(mode)` → for `"agent"` returns `"References (links)"`; for `"person"` returns
    `"Narrative (prose)"`.
  - `prosePosition(mode)` → for `"agent"` returns `"links-first"`; for `"person"` returns `"prose-first"`.
- **Readout (agent mode):** `Agent brief — first section read: References (links). A machine brief opens with the
  exact sources, not a narrative.`
- **Readout (person mode):** `Person doc — first section read: Narrative (prose). A person reads a story and forms
  intent; an agent reads the sources and acts.`

### Content interactive (teaching) — `count the links the brief front-loads`

- **Teaches:** every reference is placed before any requirement prose, so the agent reads every source first.
- **Dataset:** the six reference lines of `f6.1.llms.md`'s References block, each carrying `beforeProse: true`
  (endpoint hexdocs, router hexdocs, controller hexdocs, Plug docs, the F0 design system, the upstream `Portal`
  facade contract).
- **Control ids:** `#frontSel` (toggle, buttons `data-front="kept"` / `data-front="moved"`), readout `#frontOut`.
  SVG `#frontSvg` (six reference rows above a dashed prose-line; under "moved" the rows fall below the line).
- **Pure function:** `linksBeforeProse(brief)` → counts entries with `beforeProse === true`. Returns 6 when kept,
  0 when the references are moved after the prose.
- **Readout (kept):** `f6.1.llms.md — references front-loaded before any requirement: 6 of 6. The agent reads every
  source first, then acts.`
- **Readout (moved):** `References moved after the prose: 0 of 6 front-loaded. The agent now reads a requirement
  before the source it depends on — and reads it blind.`

The two interactives teach different moves: the hero frames *which kind of document opens with links*; the content
figure proves *the consequence* — six of six references reach the agent before any prose.

## Bridge + take

- **Principle (`.cell.idea`):** a machine reader acts on links and decisions, not narrative; write the sources first.
- **Portal practice (`.cell.elix`):** `f6.1.llms.md` opens with a References block of exact hexdocs plus the `Portal`
  facade contract, then the requirements that cite them.
- **Take:** Write the brief the way an agent reads it — exact links first, prose only where it carries a decision.

## /elixir cross-link

In-prose link to `/elixir/phoenix/lifecycle` — the real chapter whose `f6.1.llms.md` this module grounds on.
Related-in-course also lists `/elixir/phoenix/lifecycle`.

## Dives into (the `.mods` grid)

- **A5.1.1** · `/course/agile-agent-workflow/brief/llms-txt/links-first` — *Links first* — an agent reads the
  sources before any narrative; the brief front-loads exact links.
- **A5.1.2** · `/course/agile-agent-workflow/brief/llms-txt/every-reference-exact` — *Every reference exact* — every
  source is named precisely enough that the agent reads the right thing, not an approximation.
- **A5.1.3** · `/course/agile-agent-workflow/brief/llms-txt/the-machine-brief` — *The shape of a machine brief* — the
  `llms.txt` form: a links block, then the parts an agent acts on, narrative removed.

## Pager

- prev: `/course/agile-agent-workflow/brief` (A5 · The agent brief)
- next: `/course/agile-agent-workflow/brief/llms-txt/links-first` (A5.1.1 · Links first)

## References

### Sources
- llmstxt.org — *The /llms.txt convention* → `https://llmstxt.org/` — a links-first, machine-readable document
  format an agent reads before prose; the convention the brief follows.
- Anthropic — *Building effective agents* → `https://www.anthropic.com/engineering/building-effective-agents` — how
  to brief and structure a coding agent over a well-specified task.
- Hunt & Thomas — *The Pragmatic Programmer* →
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — the tracer-bullet
  discipline of turning a fixed contract into a built increment.

### Related in this course
- `/course/agile-agent-workflow/brief` — A5 · The agent brief (the chapter this module opens).
- `/course/agile-agent-workflow/brief/why` — A5 · dive · Why a brief layer.
- `/course/agile-agent-workflow/brief/what` — A5 · dive · What the chapter covers.
- `/elixir/phoenix/lifecycle` — Companion · Phoenix request lifecycle (the F6.1 rung `f6.1.llms.md` briefs).
- `/elixir/phoenix` — Companion · Phoenix (F6) hub.
