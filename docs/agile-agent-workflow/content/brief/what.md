# A5 · What the chapter covers — orientation dive 2 (md source of record)

- **Route:** `/course/agile-agent-workflow/brief/what` (`brief/what.html`)
- **Eyebrow:** `A5 · orientation dive 2`
- **Crumbs (four-element):** `jonnify / Agile Agent Workflow / A5 · The agent brief / What the chapter covers`.
- **Accent:** elixir-purple.
- **Model:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`.
- **Pager:** prev `/course/agile-agent-workflow/brief/why`; next `/course/agile-agent-workflow/brief/how`.

## Lead

A5 covers two things at roadmap altitude: the five parts of an `.llms.md` brief, and the eight modules that teach
them and the practice around them. The five parts are: references → requirements → execution topology → agent
stories → the comprehensive implementation prompt.

## Lede (hero)

> An `.llms.md` brief has five parts, in order: references, requirements, execution topology, agent stories, and the
> one implementation prompt. The eight modules of A5 teach each part, the practice of running an agent, the thesis,
> and a workshop that ships a first increment.

## Kicker (roadmap altitude)

Each of the five parts has a role, a module that teaches it, and a real Portal artifact it lands on. The brief is
read top to bottom by an agent: references first (links, so the agent reads sources before prose), then the numbered
testable requirements, then the runtime topology and task DAG, then the agent stories with their acceptance gates,
and finally the single prompt that runs the whole build in task order.

## Hero interactive — brief-anatomy selector (framing)

- **id root:** `partSel` (segmented, five parts) + `partOut` (`.geo-readout`) + SVG `anat-*` bands.
- **Dataset (fixed):** the five parts, grounded on the real `f6.1.llms.md` / `f6.6.prompt.md`:
  1. References — every source the agent reads, links first. Teaches A5.2. Lands on `f6.1.llms.md`.
  2. Requirements — numbered, testable (F6.1-R1…R8), each traced to a story. Teaches A5.2. Lands on `f6.1.llms.md`.
  3. Execution topology — the runtime tree, the task DAG (T1→T7), the touched-file list. Teaches A5.3. `f6.1.llms.md`.
  4. Agent stories — F6.1-AS1…AS4, each a Directive + Acceptance gate. Teaches A5.4. Lands on `f6.1.llms.md`.
  5. The implementation prompt — one prompt run in task order to the gates. Teaches A5.5. Lands on `f6.6.prompt.md`.
- **Pure fns:** `partAt(i)` → `{name, role, module, artifact}`; `readoutFor(i)`.
- **Sample readout:** `Part 3 of 5 · Execution topology — the runtime tree, the build-order task DAG (T1…T7), and
  the touched-file list. Taught by A5.3 Execution topology. Lands on f6.1.llms.md — the engine served as a web app,
  bottom-up.`

## Content interactive — the eight-module walk

- **id root:** `modSel` (segmented A5.1–A5.8) + `modOut` (`.geo-readout`) + SVG node row.
- **Dataset (fixed):** the eight modules from `a5.llms.md`, each with `{title, one-line, group}` where group ∈
  {convention, the five parts, practice, thesis, workshop}.
- **Pure fns:** `modAt(i)` → `{id, title, line, group}`; `readoutFor(i)`.
- **Sample readout:** `A5.5 · The comprehensive implementation prompt — the single prompt an agent runs to build the
  increment in task order, self-checking against the gates. Group: the five parts (part 5). One of eight modules A5
  teaches, ship after the landing.`

## Principle → Portal practice (bridge)

- **Principle:** a brief is one document with five named parts; reading it top to bottom assembles a system, not a
  pile of snippets.
- **On the Portal:** `f6.1.llms.md` carries exactly those five parts — References, Requirements (R1…R8), Execution
  topology (tree + T1…T7 + files), Agent stories (AS1…AS4), and the implementation prompt — and an Author runs it to
  build the web bootstrap.

## References

- Sources: the `llms.txt` convention (`https://llmstxt.org/`); Anthropic — Building effective agents
  (`https://www.anthropic.com/engineering/building-effective-agents`); User Stories Applied
  (`https://www.mountaingoatsoftware.com/books/user-stories-applied`).
- Related: `/brief`, `/brief/why`, `/spec`, `/what/four-artifacts`, `/elixir/phoenix`.
