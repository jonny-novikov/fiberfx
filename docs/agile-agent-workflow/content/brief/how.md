# A5 · How you learn and build it — orientation dive 3 (md source of record)

- **Route:** `/course/agile-agent-workflow/brief/how` (`brief/how.html`)
- **Eyebrow:** `A5 · orientation dive 3`
- **Crumbs (four-element):** `jonnify / Agile Agent Workflow / A5 · The agent brief / How you learn and build it`.
- **Accent:** elixir-purple.
- **Model:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`.
- **Pager:** prev `/course/agile-agent-workflow/brief/what`; next `/course/agile-agent-workflow/reliability`
  (the A6 landing — built by a sibling agent this batch; expected `links` transient until A6 lands).

## Lead

The method has four moves: write the brief part by part, run the agent, review the output against the spec's
Definition of Done (never the agent's self-report), and intervene when the review finds a gap. The Portal practice
is the A5.8 workshop: brief the engine chapter and make a first full pass from spec to running code.

## Lede (hero)

> Write the brief part by part, run the Author, then review the output against the spec's Definition of Done — never
> the agent's self-report. A critical review reads the code against the gates; a self-report reads the agent's word
> for it.

## Kicker (roadmap altitude)

The hardest discipline in running an agent well is review. An agent reports its own success, and that report is not
evidence. The course's own practice — adversarial verification, the gate-invisible checks — reviews the built tree
against the spec's gates. Each acceptance gate a critical review actually runs closes; an acceptance gate the review
takes on the agent's word stays open.

## Hero interactive — review-the-output checklist (framing)

- **id root:** `revSel` (toggle: `agent self-report` / `critical review`) + `revOut` (`.geo-readout`) + SVG gate cells.
- **Dataset (fixed):** the four real acceptance gates from F6.1-AS4 + the F6.1 verification gate (grounded on
  `f6.1.llms.md` / `f6.6.prompt.md`):
  1. an unknown/malformed user id renders the empty state (200), never a 500.
  2. an injected `%Portal.Error{}` renders a 422 (the error path is unit-verified).
  3. killing `PortalWeb.Endpoint` restarts it under the supervisor and a later request succeeds.
  4. `grep -rE "Portal.Engine|Repo|GenServer.call" apps/portal_web/lib/` is empty (the master invariant).
- **Pure fns:** `closedBy(view)` — self-report closes 0 (it asserts, runs nothing); critical-review closes 4 (each
  gate run against the code); `closedCount(view)`; `readoutFor(view)`.
- **Sample readout (critical review):** `Critical review — acceptance gates closed: 4 of 4. Each gate is run against
  the built tree (the 422 path, the empty state, the supervisor restart, the invariant grep). Review against the
  spec, never the self-report.`

## Content interactive — the four-move method walk

- **id root:** `moveSel` (segmented: write / run / review / intervene) + `moveOut` (`.geo-readout`) + SVG step row.
- **Dataset (fixed):** the four moves of running an agent well:
  1. write — assemble the brief part by part (references → requirements → topology → agent stories → prompt).
  2. run — paste the implementation prompt; the Author builds in task order to the gates.
  3. review — read the built tree against the spec's Definition of Done, gate by gate.
  4. intervene — when the review finds a gap, feedback edits the spec, the Author re-runs (ties A1.03 adapt).
- **Pure fns:** `moveAt(i)` → `{name, who, action}`; `readoutFor(i)`. (`who` = Operator for write/review/intervene;
  Author for run — preserving the ownership line.)
- **Sample readout:** `Move 3 of 4 · review — the Operator reads the built tree against the spec's Definition of
  Done, gate by gate, never the agent's self-report. The judgement stays with the Operator; the agent implements.`

## Principle → Portal practice (bridge)

- **Principle:** an agent reports its own success; that report is not evidence. Review the built work against the
  spec's gates, not the agent's word.
- **On the Portal:** the A5.8 workshop briefs the engine chapter and runs the Author; the review runs each F6
  acceptance gate against the built tree (the 422 path, the supervisor restart, the master-invariant grep) before
  the increment is accepted.

## References

- Sources: Anthropic — Building effective agents (`https://www.anthropic.com/engineering/building-effective-agents`);
  Anthropic — Claude Code best practices (`https://www.anthropic.com/engineering/claude-code-best-practices`); The
  Pragmatic Programmer (`https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`).
- Related: `/brief`, `/brief/what`, `/why/loop`, `/spec`, `/reliability`, `/elixir/phoenix`.
