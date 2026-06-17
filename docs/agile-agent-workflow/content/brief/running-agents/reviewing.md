# A5.6.3 — Reviewing (dive 3/3)

- **Route:** `/course/agile-agent-workflow/brief/running-agents/reviewing`
- **File:** `html/agile-agent-workflow/brief/running-agents/reviewing.html`
- **Eyebrow:** `A5.6.3 · dive 3/3`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) /
  A5 · The agent brief (`/course/agile-agent-workflow/brief`) / Reviewing.
- **Route-tag:** `course/agile-agent-workflow` (link) / `brief` (link) / `running-agents` (link) /
  `reviewing` (rcur).
- **Pager:** prev `/course/agile-agent-workflow/brief/running-agents/supervising` ·
  next `/course/agile-agent-workflow/brief/running-agents` (back to hub).

## Lead

Briefing handed the agent a complete plan; supervising watched the run against the task gates. What remains
is the review — and the review is where the practice earns its name. A review that sets out to *confirm* the
agent's self-report finds nothing, because the report is written to pass. A review that sets out to *refute*
the work against the spec's Definition of Done finds what the gates missed. The Portal's F6.7 ship prompt
states the discipline literally: adversarially verify, try to refute, and default to fail when uncertain.

## The precise definition

Reviewing is reading the agent's output against the spec's Definition of Done by trying to refute it, not by
confirming the agent's self-report. Three properties make a review adversarial:

1. **It checks the spec, not the report.** The reference is the Definition of Done — the traced, executed
   checks A4 produced — never the agent's "done — tests green."
2. **It tries to refute.** Each check is run as an attempt to find a counterexample, not as a box to tick.
3. **It defaults to fail when uncertain.** A check that cannot be proven passing is treated as failing, so
   ambiguity blocks acceptance rather than passing it.

The one check that separates the two reviews on the Portal is **liveness**: a green `mix test` does not prove
the dev server boots, because the suite runs `server: false`. Only a review that boots the node and curls
`/health` can refute or confirm that the Portal runs.

## The worked Portal example (F6.7 ship prompt — the Apollo verify stage)

Grounds on the Portal's real F6.7 ship prompt. Its verify stage is assigned to Apollo, whose standing
directive is quoted verbatim from `f6.1.llms.md` (the Apollo step of the implementation prompt):

> APOLLO — adversarially verify (try to REFUTE; default FAIL when uncertain)

The F6.7 prompt then names the **liveness gate** as the reason the review must run the real check, not the
report. Verbatim from `f6.7.prompt.md`:

> mix test runs server:false (config/test.exs), so a green suite does NOT prove the dev server boots

and, from the Director's ratify gate in the same file:

> `mix test` alone does NOT satisfy the liveness criterion (the endpoint runs `server: false` under test)

Apollo's adversarial checks on F6.7, all run as attempts to refute:

- **The master-invariant grep** — `CatalogLive` + `Catalog` name only `Portal` / `Portal.PubSub` (no
  `Engine` / `Repo` / `GenServer.call`); the facade boundary holds.
- **Broadcast only on `{:ok, _}`** — the `Portal.Catalog` `broadcast/2` helper fires only after a
  successful write; a failed write broadcasts nothing. This is the rule the review refutes by checking it
  fires on success and is silent on failure — the broadcast-only-on-success rule taught in
  `/elixir/phoenix/pubsub/broadcast`.
- **The liveness two-window smoke** — boot the node, `curl :4000/health` → 200, and run the rung's live
  two-window update; the one check the green suite does not prove.

A confirming review reads the self-report and stops at "tests green." An adversarial review runs the
liveness smoke and finds that the green suite ran `server: false` — the failure the gates alone do not catch.

## Hero interactive (framing) — review against the DoD

- **Element ids:** `#dodSel` (solid-select, two buttons `data-mode="report|dod"`), `#dodOut`
  (`.geo-readout`, `aria-live="polite"`), SVG groups `#dod-report`, `#dod-dod`, and the per-check rows
  `#dod-row-0..3` with status text `#dod-st-0..3`, and a coverage count `#dod-count`.
- **Dataset:** the review's check set. Four checks, each tagged `inDoD: true` and `inReport: false|true`:
  compile clean (in report), suite green (in report), the master-invariant grep (DoD only), the liveness
  smoke (DoD only). The self-report covers only what the agent ran; the DoD covers every traced check.
- **Pure fns:** `checkedAgainst(mode)` returns the reference set name (`'the agent self-report'` or
  `"the spec's Definition of Done"`); `covered(mode)` counts how many of the four checks that reference
  set includes (`report` → 2; `dod` → 4); `dodReadout(mode)` composes the readout.
- **Sample readout:** `"Reviewed against the Definition of Done — checks the review runs: 4 of 4 (compile,
  suite, the invariant grep, the liveness smoke). The reviewer checks the spec, not the report — and the
  report covers only 2 of the 4."`
- **Default (JS-off):** `dod` mode lit, the DoD readout and `4 of 4` present in static markup.
- **Teaches:** *what the review checks against* — the spec's Definition of Done, a wider set than the
  agent's self-report.

## Content interactive (teaching) — refute, don't confirm

- **Element ids:** `#refSel` (solid-select, two buttons `data-mode="confirm|refute"`), `#refOut`
  (`.geo-readout`, `aria-live="polite"`), SVG group rows `#ref-row-0..2` with verdict text `#ref-v-0..2`,
  and a found-count `#ref-count`.
- **Dataset:** the three Apollo adversarial checks on F6.7, each carrying a `holds` flag (whether the check
  actually passes when run as a refutation attempt) and a `provenByTest` flag (whether `mix test` alone
  proves it): the master-invariant grep (`holds: true`, `provenByTest: true`), broadcast-only-on-success
  (`holds: true`, `provenByTest: true`), the liveness two-window smoke (`holds: true`, `provenByTest:
  false` — the suite ran `server: false`). A *confirming* review reads the self-report and runs none of the
  refutation checks that the report does not already claim; an *adversarial* review runs all three and
  default-fails the one the suite cannot prove until it is run live.
- **Pure fns:** `refuted(mode)` returns, per check, whether the chosen review actually exercises it as a
  refutation (confirm → only the two the report already proves; refute → all three); `liveCheckRun(mode)`
  returns whether the liveness smoke is run (false for confirm, true for refute); `refCount(mode)` counts
  the checks a review runs as refutations (`confirm` → 2; `refute` → 3); `refReadout(mode)` composes the
  readout.
- **Sample readout:** `"Try to refute — adversarial checks run: 3 of 3. The green suite ran server: false,
  so the liveness check is the one that can fail; an adversarial review runs it and finds it, a confirming
  review does not. Default FAIL when uncertain: the liveness smoke is run, not assumed."`
- **Default (JS-off):** `refute` mode lit, the refute readout and `3 of 3` present in static markup.
- **Teaches:** a *different* move from the hero — not what the review checks against, but *how* it checks:
  by trying to refute (and so catching the liveness gap), rather than by confirming the report.

## The bridge + take

- **Principle (idea cell):** review by trying to refute the work against the spec's Definition of Done,
  defaulting to fail when uncertain — not by confirming the agent's self-report.
- **Practice (elix cell):** F6.7's Apollo verifies the master-invariant grep, the broadcast-only-on-success
  rule, and the liveness two-window smoke, refuting before it accepts — and treats the green `server: false`
  suite as no proof of a running server.
- **Take:** A review that tries to confirm the agent finds nothing; a review that tries to refute it finds
  what the gates missed.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/pubsub/broadcast` (the broadcast-only-on-success rule the review
  refutes).
- **Related in this course:** `/elixir/phoenix` (the companion hub) plus internal A5 routes.

## Sources (3, from the registry — real, vetted)

- Anthropic — Building effective agents → `https://www.anthropic.com/engineering/building-effective-agents`
- Anthropic — Claude Code best practices → `https://www.anthropic.com/engineering/claude-code-best-practices`
- The Pragmatic Programmer →
  `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
