# A5.1.3 — The shape of a machine brief

- **Route:** `/course/agile-agent-workflow/brief/llms-txt/the-machine-brief`
- **File:** `html/agile-agent-workflow/brief/llms-txt/the-machine-brief.html`
- **Eyebrow:** `A5.1.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Parent hub:** `/course/agile-agent-workflow/brief/llms-txt` (A5.1).
- **Pager:** prev `…/brief/llms-txt/every-reference-exact` · next `…/brief/llms-txt` (back to the hub).
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `llms-txt` (link) / `the-machine-brief` (rcur).
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief
  (`/course/agile-agent-workflow/brief`) / The shape of a machine brief.

## Lead

The two dives before this one taught how an agent reads: links before prose (A5.1.1), every reference exact
(A5.1.2). This one names the **whole shape** those rules add up to — the fixed skeleton a machine brief always
has. Once an agent learns the skeleton, every brief reads the same way: the sources first, then the parts the
agent acts on, the story it does not need removed.

## Precise definition

A **machine brief** is a document written for an implementer rather than a reader. It has a **fixed shape**, and
the Portal's real `f6.1.llms.md` is the worked instance of it. Its five sections, in order:

1. `## References` — the links-first reading list (the endpoint/router/controller hexdocs, Plug, the F0 design
   system, the upstream `Portal` facade contract). Read before anything else.
2. `## Requirements` — the numbered, testable statements `F6.1-R1…R8`.
3. `## Execution topology` — the runtime tree, the `T1→T7` task DAG, the touched-file list.
4. `## Agent stories` — `F6.1-AS1…AS4`, each a Directive plus an Acceptance gate.
5. `## Comprehensive implementation prompt` — the single prompt that runs the stories in task order and ends on
   the verification gates.

The shape is the convention. Two properties define it against a document written for a person:

- **Links first.** References is section 1 — the sources sit at the top, not scattered through the prose where a
  reader would meet them.
- **Narrative removed.** A person-doc spends paragraphs on motivation, history, and prose transitions. The
  machine brief keeps the decisions the agent acts on and drops the story it does not need.

## Worked Portal example (grounding — `f6.1.llms.md`)

Quote the section skeleton of the real `f6.1.llms.md` verbatim, in order:

```text
## References
## Requirements
## Execution topology
## Agent stories
## Comprehensive implementation prompt
```

And its top-of-file blockquote (verbatim): *"Read the references first, satisfy the requirements, build in
task-topology order, and close each agent story on its gate. This brief is self-contained."* The blockquote names
the skeleton as an instruction: references → requirements → topology → stories → the prompt that runs them.

Every `f6.N.llms.md` in the Portal's Phoenix chapter follows the same five-section skeleton — that sameness is the
point. An agent that has read one knows where to look in the next.

## Hero interactive (framing) — assemble the skeleton

- **id root:** `skel`. Controls: `#skelSel` two buttons — `data-view="ordered"` (the machine-brief order, active
  by default) and `data-view="scattered"` (a person-doc where References is not first).
- **Dataset (fixed):** the five `f6.1.llms.md` section headings, in canonical order:
  `['## References', '## Requirements', '## Execution topology', '## Agent stories', '## Comprehensive implementation prompt']`.
- **Pure functions:**
  - `sectionAt(i)` → returns the heading at index `i` in canonical order.
  - `referencesIndex(view)` → in `ordered`, References is at index `0`; in `scattered`, References sits at index
    `2` (buried mid-document, the person-doc shape).
  - `skelReadout(view)` → the readout string.
- **SVG:** five stacked bands, the References band highlighted when it is at the top (`ordered`); a small "agent
  reads first →" marker points at whichever band is index 0.
- **Readout (ordered):** *"Machine brief — five sections in fixed order; References is section 1 of 5, read
  first. The skeleton is links block, then the parts an agent acts on."*
- **Readout (scattered):** *"Person doc — References sits at section 3 of 5, buried in the prose. An agent reading
  top-down meets requirements before it has the sources they cite."*
- **Teaches:** the *order* — that a machine brief front-loads the links block, and what breaks when it does not.

## Content interactive (teaching) — narrative kept vs removed

- **id root:** `narr`. Controls: `#narrSel` two buttons — `data-view="person"` (person doc) and
  `data-view="machine"` (machine brief, active by default).
- **Dataset (fixed):** a per-section line budget for the same five sections, under each reader. A person doc adds
  narrative lines (motivation, transitions); the machine brief keeps only the actionable lines.
  Per section `[decisionLines, narrativeLines]`:
  References `[6, 3]`, Requirements `[8, 4]`, Execution topology `[7, 5]`, Agent stories `[4, 3]`,
  Implementation prompt `[7, 2]`. (decisionLines = lines the agent acts on; narrativeLines = story for a reader.)
- **Pure functions:**
  - `decisionLines()` → sum of decisionLines across the five sections (constant; both readers keep these).
  - `narrativeLines()` → sum of narrativeLines across the five sections.
  - `linesKept(view)` → `person` keeps decision + narrative; `machine` keeps decision only.
  - `narrativeRemoved(view)` → `machine` removes all narrativeLines; `person` removes none.
  - `narrReadout(view)` → the readout string.
- **SVG:** two stacked bars per section — a solid "decisions" segment (always present) and a faded "narrative"
  segment that is struck through / dropped in the machine view; a running total at the foot.
- **Readout (machine):** *"Machine brief — decision lines kept: 32; narrative lines removed: 17. The brief keeps
  the decisions, drops the story the agent does not need."*
- **Readout (person):** *"Person doc — decision lines kept: 32; narrative lines removed: 0 (49 total). A reader
  needs the story; an agent needs the decision and acts on it."*
- **Teaches:** a *different move* from the hero — not the order, but **what is dropped**: the same content carries
  the same decisions under both readers, but the machine brief sheds the narrative the agent does not act on.

## Bridge

- **principle (`.cell.idea`):** A machine brief has a fixed shape: links, then the actionable parts, narrative
  removed. The shape is the convention.
- **→**
- **Portal (`.cell.elix`):** Every `f6.N.llms.md` follows the same skeleton — References, Requirements, Execution
  topology, Agent stories, the prompt — so an agent that has read one knows where to look in the next.
- **`.take`:** The shape is the convention; once an agent learns it, every brief reads the same way.

## Recap

A machine brief is not a document for a person with the links moved up. It is a fixed five-section skeleton —
References, Requirements, Execution topology, Agent stories, the implementation prompt — links first, narrative
removed. The convention is the value: every `f6.N.llms.md` reads the same way, so an agent never re-learns where to
look. This closes A5.1 (the convention); A5.2 fills the skeleton's first two parts — references and requirements.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix` — the companion chapter whose `f6.N.llms.md` briefs all follow this
  skeleton.
- **Related in this course:** `/elixir/phoenix/lifecycle` (the chapter whose `f6.1.llms.md` is the worked
  instance) + internal A5 routes.

## References — Sources (3, from the registry)

- llmstxt.org — *The /llms.txt convention* — `https://llmstxt.org/`.
- Anthropic — *Building effective agents* — `https://www.anthropic.com/engineering/building-effective-agents`.
- Hunt, A. & Thomas, D. — *The Pragmatic Programmer* —
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`.

## Gate

```zsh
FLAGS="--routes-from /course/agile-agent-workflow=html/agile-agent-workflow --chapter-alias a0=what,a1=why,a2=decomposition,a3=roadmap,a4=spec,a5=brief,a6=reliability,a7=portal --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} html/agile-agent-workflow/brief/llms-txt/the-machine-brief.html
```

`prev` (`…/brief/llms-txt/every-reference-exact`) and `next`/hub (`…/brief/llms-txt`) are built in parallel — a
`links` FAIL naming only those is expected until they land; every other gate must PASS.
