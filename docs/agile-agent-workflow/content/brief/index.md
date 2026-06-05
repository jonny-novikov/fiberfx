# A5 · The agent brief (`.llms.md`) & implementation — chapter landing (md source of record)

- **Route:** `/course/agile-agent-workflow/brief` (`brief/index.html`)
- **Eyebrow:** `A5 · chapter overview`
- **Crumbs (two-element, landing form):** `Agile Agent Workflow / A5 · The agent brief`
- **Accent:** elixir-purple (`--elixir` / `--elixir-bright`; `<span class="ex">` already renders this).
- **Model:** `html/agile-agent-workflow/roadmap/index.html` (A3 landing).
- **Stamp:** `TSK0Ng9hnHJgW0` (verbatim in the copied footer).

## Lead

A spec says *what and why and done*. A brief tells a Claude Author *how to build* it — the exact sources to read,
the runtime shape, the build order, the proof gates — and the practice of running that agent well. A5 wraps the A4
spec in a machine-readable brief (an `.llms.md`) and runs an Author to turn the spec into a built increment.

## Lede (hero)

> A4 wrote the spec — correct by definition. A5 wraps that spec in a brief a Claude Author can run: links first,
> every reference exact, the runtime shape and build order fixed, the proof gates named. The spec stays the source
> of truth; the brief leaves the agent no decision the Operator must own.

## Kicker (roadmap altitude)

A4 produced a spec — acceptance criteria, Given/When/Then, invariants, traceability. A spec defines *what and why
and done*; it is not, on its own, runnable by an agent. The agent brief is the layer that fixes every remaining
*how-to-build* decision and turns the spec into code — practised on the **Portal**, against its real `.llms.md`
briefs and implementation prompts.

## Framing interactive 1 (hero `.hero-split` figure) — the brief's five parts

- **id root:** `partSel` (segmented selector) + `partOut` (`.geo-readout`, `aria-live`) + the SVG `anat-*` cells.
- **Dataset (fixed):** the five parts of an `.llms.md`, grounded on the real `f6.1.llms.md`:
  1. References — every source the agent reads, links first (e.g. the Phoenix endpoint/router/controller hexdocs,
     the upstream `Portal` facade contract, `f0.md` the design system).
  2. Requirements — numbered, testable (F6.1-R1…R8), each traced to a user story.
  3. Execution topology — the runtime tree + the task DAG (T1→T7) + the touched-file list.
  4. Agent stories — F6.1-AS1…AS4, each a Directive + an Acceptance gate.
  5. The comprehensive implementation prompt — the single prompt an agent runs in task order, ending on the gates.
- **Pure fns:** `partAt(i)` → `{name, role, teaches, artifact}`; `frontLoadedAt(i)` (references part is index 0 →
  reports "links first"); `readoutFor(i)` → the readout string.
- **Sample readout:** `Part 1 · References — every source the agent reads, links first. Teaches: A5.2 References
  and requirements. Lands on: f6.1.llms.md (the real Portal brief). The brief front-loads exact links so the agent
  assembles a system, not a pile of snippets.`

## Framing interactive 2 (main content) — the course-arc selector re-centred on A5

- **id root:** `arcSel` (segmented A0–A7) + `arcOut` (`.geo-readout`) + the SVG spine `arc-0..arc-7`.
- **Dataset (fixed, 8 parts):** A0–A4 `built`, A5 `here` (pre-selected, index 5), A6–A7 `planned`.
- **Pure fns:** `partsBefore(i)` (count of `built` before i); `readoutFor(i)`. The A5 readout tail names the A4
  spec as the input A5 wraps.
- **Sample readout:** `A5 · The agent brief — /brief. Delivers: the .llms.md and the implementation pass the
  Author builds against. Status: you are here. · 5 of 8 parts built before this one; the A4 spec — correct by
  definition — is the input this chapter wraps in a runnable brief.`

## Orientation `.mods` grid — the three dive cards (real `<a>`, `built` pills)

- `why` → `/course/agile-agent-workflow/brief/why` — why a brief layer.
- `what` → `/course/agile-agent-workflow/brief/what` — the five parts and the eight modules ahead.
- `how` → `/course/agile-agent-workflow/brief/how` — write the brief, run the agent, review against the spec.

## Module preview — A5 lists its eight modules (`<div class="mod soon">`, no href, `soon` pills)

A5.1 Writing for an agent: the llms.txt convention · A5.2 References and requirements · A5.3 Execution topology ·
A5.4 Agent stories · A5.5 The comprehensive implementation prompt · A5.6 Running Claude agents well · A5.7
Pragmatic Programming with Claude Agents · A5.8 Workshop — briefing the agent for Portal. A `.note` says the modules
ship after the landing, fanned out one Author per module against the seeded triad (`a5.{md,stories.md,llms.md}`).

## Principle → Portal practice (bridge)

- **Principle:** a spec defines the work; a brief tells an implementer how to build it — references first, every
  decision the spec fixed restated for the builder, none left open.
- **On the Portal:** `f6.1.llms.md` is a real brief — references, F6.1-R1…R8, the topology + task DAG, F6.1-AS1…AS4,
  and the implementation prompt — that an Author runs to ship the web bootstrap over the unchanged `Portal` facade.

## References

- Sources (real, vetted): the `llms.txt` convention (`https://llmstxt.org/`); Anthropic — Building effective agents
  (`https://www.anthropic.com/engineering/building-effective-agents`); The Pragmatic Programmer
  (`https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`).
- Related in this course: `/spec`, `/why/loop`, `/what/four-artifacts`, `/roadmap`, `/elixir/phoenix`,
  `/elixir/course`.

## Pager / wiring

- Pager prev: `/course/agile-agent-workflow/spec` (A4 landing). Pager next: `/course/agile-agent-workflow/brief/why`.
- No-invent held: only `Portal.ID.generate/1`/`decode/1` are named as free API; every brief/requirement/agent-story
  example is verbatim from `f6.1.llms.md`; the agent is never anthropomorphised.
