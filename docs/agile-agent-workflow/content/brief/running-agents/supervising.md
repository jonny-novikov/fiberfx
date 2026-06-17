# A5.6.2 — Supervising · `/course/agile-agent-workflow/brief/running-agents/supervising`

> **Eyebrow** A5.6.2 · dive 2/3. **Parent hub** `/brief/running-agents`. **Accent** elixir-purple.
> **Stamp** `TSK0Ng9hnHJgW0`. **Pager** prev `…/brief/running-agents/briefing` · next `…/brief/running-agents/reviewing`.

## Route + crumbs

- Route-tag: `course/agile-agent-workflow` (link) / `brief` (link) / `running-agents` (link) / `supervising` (rcur).
- Crumbs: `jonnify` (`/elixir`) / `Agile Agent Workflow` (`/course/agile-agent-workflow`) / `A5 · The agent brief`
  (`/course/agile-agent-workflow/brief`) / `Supervising` (here).

## Lead

Briefing handed the agent a complete plan. Supervising is what the human does while the plan runs. The move is not
to read every keystroke; it is to watch the **gates** — the per-stage checks the F6 ship prompts place between
build, harden, and verify — and to know the one point at which the human takes the run back.

## Precise definition

**Supervision** is staying in the loop at each gate of a multi-stage agent run: let a stage whose gate passed
proceed; intervene on a stage whose gate failed; and bound the agent's own retries so a stuck run escalates to the
human instead of looping forever. The supervisor watches the gate result, not the keystrokes.

## The worked F6 example (grounded on `f6.6.prompt.md` / `f6.7.prompt.md`)

The Portal's F6.6 (LiveView) and F6.7 (real-time PubSub & Presence) rungs each ship through the same staged
lead-team: **Venus** (reconcile + brief) → **Mars** ×2 (build, then harden) → **Apollo** (verify), with a gate
between every stage. The F6.6 ship prompt names the mode and the reason supervision is gate-watching, not
parallel automation, verbatim:

> Real `Agent` spawns + SendMessage coordination, **Director-in-loop between stages — not a deterministic
> `Workflow` fan-out**. The rung is sequential (Mars builds from Venus's brief; Apollo verifies Mars's tree) with
> two human-grade decision points (the reconcile result, the final commit), so **the value is in the *gates***, not
> in parallelism. — `f6.6.prompt.md`

The stage chain and its per-stage gate:

- **build (Mars-1)** — gate: the tree compiles warnings-as-errors and the Given/When/Then stories pass.
- **harden (Mars-2)** — gate: added LiveViewTest coverage is green across the determinism loop.
- **verify (Apollo)** — gate: the master-invariant grep is empty and the liveness check holds.

When Apollo returns a finding, the run does **not** stop at the human immediately and it does **not** loop forever.
Mars runs a bounded **REMEDIATE loop**: it addresses the finding and re-runs the gate, **up to a maximum of three
attempts**; past three, the run **escalates to the human**. Supervision is bounded, not infinite — the agent
remediates within the bound, and the human owns the escalation.

This is the F6.6 LiveView rung whose event handlers a supervised run builds: see the companion
`/elixir/phoenix/liveview/events`.

## Interactive 1 (hero, framing): *let it run, or intervene*

- **Move taught:** supervision = read the gate at each stage; a passing gate proceeds, a failing gate is
  intervened on.
- **Dataset (fixed):** the stage chain `STAGES = [build, harden, verify]`, each with a `passed` flag derived from
  the F6 stages (build green, harden green, verify failing in the default scenario so the figure shows an
  intervention).
- **Controls:** a `.solid-select` toggle between two scenarios — `clean` (all three gates pass) and `finding`
  (verify's gate fails). Static default = `finding` (so the static markup already shows the supervisor stopping at
  the failing gate).
- **Pure functions:**
  - `gatePasses(stage, scenario)` → boolean — whether that stage's gate passed under the scenario.
  - `actionAt(stage, scenario)` → `"proceed"` | `"intervene"` — proceed on a pass, intervene on a fail.
  - `firstFailing(scenario)` → stage name or `null` — the first stage whose gate failed.
- **Element ids:** select `#supSel`; SVG `.dq` with stage rows `#sup-stage-0..2`, status labels
  `#sup-st-0..2`, the action readout `#sup-action`; live readout `#supOut`.
- **Sample readout (finding scenario):** `"On a finding: build (gate passed) → proceed; harden (gate passed) →
  proceed; verify (gate failed) → intervene. The supervisor lets a passing stage run and stops on the first
  failing gate — it watches the gates, not the keystrokes."`
- **Sample readout (clean):** `"Clean run: all three gates passed — build → proceed, harden → proceed, verify →
  proceed. With every gate green, the supervisor lets the run proceed to the human's final decision point."`

## Interactive 2 (content, teaching): *the remediate loop (MAX 3)*

- **Move taught:** the retry bound — an agent remediates a finding up to three times, then escalates; supervision
  is bounded, not infinite. (Different move from the hero: the hero reads the gate per stage; the content figure
  reads the **retry budget** of one stage's gate.)
- **Dataset (fixed):** `MAX_ATTEMPTS = 3`; the attempt counter `0..4` drives the figure.
- **Controls:** a range slider `#remRange` (0–4) plus a stepper feel; the value reflects the attempt number.
  Static default = `2` (within bound).
- **Pure functions:**
  - `escalates(attempts)` → boolean — `attempts > MAX_ATTEMPTS` (true past three).
  - `owner(attempts)` → `"agent"` | `"human"` — the agent owns attempts within the bound; the human owns the
    run once it escalates.
  - `attemptsLeft(attempts)` → number — `max(0, MAX_ATTEMPTS - attempts)`.
- **Element ids:** range `#remRange`, value `#remVal`; SVG `.dq` with three attempt pips `#rem-pip-0..2`, an
  escalate marker `#rem-esc`, the owner label `#rem-owner`; live readout `#remOut`.
- **Sample readout (attempts = 2):** `"Attempt 2 of 3 — the agent remediates the finding and re-runs the gate;
  1 attempt left, owner: agent. On a finding, the agent remediates up to 3 times; past 3 it escalates to the
  human — supervision is bounded, not infinite."`
- **Sample readout (attempts = 4):** `"Attempt 4 — past the bound of 3, the run escalates; owner: human. The
  agent remediates up to 3 times; past 3 it escalates to the human — supervision is bounded, not infinite."`

## Bridge + take

- **`.cell.idea` (principle):** supervise against the task gates — let a passing stage run, intervene on a failing
  one, and bound the retries so a stuck run reaches the human.
- **`.cell.elix` (Portal practice):** the F6 ship prompts gate each stage (Director-in-loop, the value is in the
  gates); Mars remediates an Apollo finding a maximum of three times, then escalates.
- **`.take`:** Supervision is watching the gates, not the keystrokes — and knowing the point at which the human
  takes over.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/liveview/events` (the F6.6 event handlers a supervised run builds).
- **Related in this course:** `/elixir/phoenix` (the companion Phoenix chapter), plus internal A5 routes.

## References (3 Sources)

- Anthropic — *Building effective agents* → `https://www.anthropic.com/engineering/building-effective-agents`.
- Anthropic — *Claude Code best practices* → `https://www.anthropic.com/engineering/claude-code-best-practices`.
- *User Stories Applied* → `https://www.mountaingoatsoftware.com/books/user-stories-applied`.
