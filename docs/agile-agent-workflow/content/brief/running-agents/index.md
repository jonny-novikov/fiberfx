# A5.6 — Running Claude agents well (module hub)

- **Route:** `/course/agile-agent-workflow/brief/running-agents`
- **File:** `html/agile-agent-workflow/brief/running-agents/index.html`
- **Eyebrow:** `A5.6 · module hub`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / here.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `running-agents` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief` · next `/course/agile-agent-workflow/brief/running-agents/briefing`.

## Lead

A5.1–A5.5 wrote the brief and assembled it into one runnable prompt. The brief is complete; what remains
is the human practice of running it. A5.6 names that practice: **brief, supervise, review** — a loop the
human owns around a prompt the agent runs. The hard rule the whole module turns on: review against the
spec's Definition of Done, never the agent's self-report.

## The precise definition

Running a Claude agent well is the practice around the implementation prompt, in three moves:

1. **Brief** — hand the agent a complete, unambiguous `.llms.md` so it implements rather than decides.
2. **Supervise** — watch the run against the task gates; let a passing stage proceed, intervene on a
   failing one, and bound the retries.
3. **Review** — read the output against the spec's Definition of Done, not the agent's self-report.

The value is in the *gates*, not in parallelism. The agent runs the prompt; the human owns the gate.

## The worked Portal example (F6.6 / F6.7 ship prompts)

Grounds on the Portal's real F6.6 and F6.7 ship prompts — the orchestration briefs that run a rung by
fanning out a lead-team (Venus reconcile + brief → Mars build, then harden → Apollo verify), with the
Director in the loop at each gate. The gates the prompts carry:

- **warnings-as-errors** at compile (`mix compile --warnings-as-errors`).
- **the determinism loop ≥100** — re-run the suite ≥100 times for an id-touching, process-touching rung
  (`for i in $(seq 1 100); do mix test || break; done`).
- **the liveness check** — the standing criterion the review must run, not the report.

The liveness criterion, quoted verbatim from `f6.7.prompt.md`:

> mix test runs server:false (config/test.exs), so a green suite does NOT prove the dev server boots

and, from the Director's ratify gate:

> `mix test` alone does NOT satisfy the liveness criterion (the endpoint runs `server: false` under test).

So a green `mix test` proves the suite passes, not that the Portal boots. The reviewer boots the node and
curls `/health` (200), and runs the rung's live two-window update — the gate F6.6 documented but F6.7 first
ran. The mode line, also verbatim: "Director-in-loop between stages — not a deterministic `Workflow`
fan-out … the value is in the *gates*, not in parallelism."

## Hero interactive (framing) — the three practices

- **Element ids:** `#practiceSel` (solid-select, three buttons `data-p="0|1|2"`), `#practiceOut`
  (`.geo-readout`, `aria-live="polite"`), the SVG groups `#prac-0`, `#prac-1`, `#prac-2`.
- **Dataset:** `{brief, supervise, review}` — each with its purpose and the move it makes around the
  prompt.
- **Pure fn:** `practiceAt(i)` returns `{name, purpose}`; `readoutFor(i)` composes the readout string.
- **Sample readout:** `"Practice 1 · Brief — hand the agent a complete, unambiguous .llms.md so it
  implements rather than decides. The loop around one prompt: set up, watch, check — and the human owns
  every move but the run."`
- **Default (JS-off):** practice 0 (brief) lit, practice-0 readout present in static markup.
- **Teaches:** the *shape* of the practice — three moves around one prompt.

## Content interactive (teaching) — self-report vs the gate

- **Element ids:** `#reviewSel` (solid-select, two buttons `data-mode="report|gate"`), `#reviewOut`
  (`.geo-readout`, `aria-live="polite"`), the SVG groups `#rev-report`, `#rev-gate`.
- **Dataset:** the agent's self-report (`"done — tests green"`) vs the spec's Definition of Done (the
  checks `mix test` cannot prove, with the liveness check flagged: the node boots and `/health` is 200).
  Each check tagged `provenByTest: true|false`.
- **Pure fns:** `reviewSource(mode)` returns what each review checks against (the report, or the DoD);
  `livenessProven(mode)` returns whether the chosen review proves the dev server boots (false for the
  report and for `mix test` alone, true only when the gate is run live).
- **Sample readout:** `"Run the gate — mix test is green but runs server: false; the liveness check (the
  node boots, /health is 200) is the one the review must run, not the report. Self-report proves: tests
  green. Liveness proven: no — until the node is booted."`
- **Default (JS-off):** `gate` mode lit, gate readout present in static markup.
- **Teaches:** a *different* move from the hero — not the shape of the practice but the one check that
  separates "the agent says done" from "the work is provably done."

## The bridge + take

- **Principle (idea cell):** brief, supervise, review — and review against the Definition of Done, never
  the agent's self-report.
- **Practice (elix cell):** the F6.7 ship prompt requires the liveness check at review — a green
  `mix test` proves nothing about a running server (`server: false` under test), so the reviewer boots the
  node and curls `/health`.
- **Take:** Running an agent well is a loop the human owns — the agent runs the prompt; the human owns the
  gate.

## Dives into (the .mods grid — 3 cards)

- `A5.6.1 · /brief/running-agents/briefing` — *Briefing* — hand the agent a complete, unambiguous brief so
  it implements rather than decides.
- `A5.6.2 · /brief/running-agents/supervising` — *Supervising* — watch the run against the task gates;
  know when to let it run and when to intervene.
- `A5.6.3 · /brief/running-agents/reviewing` — *Reviewing* — read the output against the spec's Definition
  of Done, not the agent's self-report.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/liveview` (the F6.6 rung the ship prompt builds).
- **Related in this course:** `/elixir/phoenix` (the companion hub) plus internal A5 routes.

## Sources (3, from the registry — real, vetted)

- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
- Anthropic — Claude Code best practices → `https://www.anthropic.com/engineering/claude-code-best-practices`
- User Stories Applied → `https://www.mountaingoatsoftware.com/books/user-stories-applied`
