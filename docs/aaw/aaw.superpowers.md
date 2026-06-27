# AAW — superpowers (the skills plugin) · how it fits

> What this document owns: how the **superpowers** plugin (`obra/superpowers`, the official Claude
> skills library) composes with the AAW discipline already shipping in this repo. It documents an
> **external** surface — the plugin's mechanics and its fourteen skills — and the **integration
> contract** that binds that surface to this repo's laws. It quotes and links the AAW artifacts
> ([aaw.framework.md](aaw.framework.md), [aaw.rules.md](aaw.rules.md),
> [aaw.architect-approach.md](aaw.architect-approach.md), the root [CLAUDE.md](../../CLAUDE.md)); it
> does not restate the contracts they own. The plugin is third-party and versioned — every behavior
> below is grounded in the installed `6.0.3` skill bodies, not invented; re-verify against the
> installed version before relying on a detail, because skills evolve.

## The install fact

| Fact | Value | Source |
| --- | --- | --- |
| Plugin | `superpowers@claude-plugins-official` — "Core skills library for Claude Code: TDD, debugging, collaboration patterns" (Jesse Vincent / Prime Radiant, MIT) | `…/plugin.json` |
| Version | `6.0.3` (git `896224c4`), installed `2026-06-27` | `~/.claude/plugins/installed_plugins.json` |
| **Scope** | **`project`** — enabled for `/Users/jonny/dev/jonnify` only, pinned in `.claude/settings.json` → `enabledPlugins."superpowers@claude-plugins-official": true` | repo settings |
| Ships | **14 skills + 1 `SessionStart` hook**. No slash-commands, no agents, no MCP servers of its own. | `skills/`, `hooks/hooks.json` (`commands/`, `agents/` empty) |

Because the enable lives in committed project settings, the plugin is part of the repository's agent
configuration, not a personal preference — treat a change to it the way you would any other
`.claude/` change.

## How it activates (the mechanics)

1. **The bootstrap hook.** `hooks/hooks.json` registers one `SessionStart` hook with matcher
   `startup|clear|compact`. On every session start, `/clear`, and `/compact` it injects the
   `using-superpowers` skill body into context — the router that makes every other skill
   auto-trigger. (That injection is why the bootstrap appears at the top of a freshly compacted
   session.) Without this hook the skills are inert files on disk; with it they fire at the right
   moments unprompted.
2. **Invocation.** Each skill is loaded through the `Skill` tool as `superpowers:<name>` (e.g.
   `superpowers:brainstorming`). Never read a `SKILL.md` with a file tool to "use" it — that loads
   the text without activating the skill's todo/gate machinery.
3. **The subagent carve-out.** `using-superpowers` opens with `<SUBAGENT-STOP>`: a subagent
   dispatched for a specific task **skips** the bootstrap. This is load-bearing for AAW's fan-out
   formation — Venus/Mars/Apollo and the `*-expert` authors run as dispatched subagents, so they do
   **not** inherit superpowers' auto-triggering. Any superpowers discipline wanted inside a fan-out
   peer must be written into that peer's charter or `*-ship` skill, not assumed.
4. **The priority ladder (the integration lever).** `using-superpowers` states its own precedence
   explicitly: **(1) the user's explicit instructions — CLAUDE.md / direct requests — highest; (2)
   superpowers skills override default system behavior on conflict; (3) the default system prompt —
   lowest.** Every conflict below is resolved by rung (1): the root [CLAUDE.md](../../CLAUDE.md) and
   the standing Operator asks win over any superpowers default. Superpowers is built to defer here —
   the integration work is making the deferral explicit.

## The fourteen skills (the catalog)

Two families. **Process / discipline** skills shape *how to think* and resist rationalization — most
are rigid (an "Iron Law", a "letter = spirit" clause, a red-flags table). **Mechanics** skills are
concrete procedures, templates, and git plumbing — flexible but precise. Descriptions are the
skills' own `description:` frontmatter.

| Skill | Family | Rigid? | Use when |
| --- | --- | --- | --- |
| `using-superpowers` | process | rigid | Start of any conversation — the router that finds and gates every other skill. |
| `brainstorming` | process | rigid (hard-gate) | Before **any** creative work — turn an idea into an approved design + spec before code. |
| `writing-plans` | mechanics | prescriptive | A spec exists; produce a bite-sized, TDD-shaped implementation plan before touching code. |
| `using-git-worktrees` | mechanics | rigid | Starting feature work needing isolation / before executing a plan. |
| `subagent-driven-development` | mechanics | rigorous | Execute a plan's independent tasks in-session: fresh implementer per task + two-verdict review. |
| `executing-plans` | mechanics | prescriptive | Execute a plan in a separate session with human checkpoints (when subagents are unavailable). |
| `test-driven-development` | process | rigid | Implementing any feature/bugfix — RED-GREEN-REFACTOR, no production code without a failing test. |
| `systematic-debugging` | process | rigid | Any bug/test-failure/surprise — root-cause investigation **before** any fix. |
| `verification-before-completion` | process | rigid | About to claim done/fixed/passing — run the proof command first; evidence before assertion. |
| `requesting-code-review` | mechanics | flexible | Completing a task / before merge — dispatch a reviewer subagent with crafted context. |
| `receiving-code-review` | process | discipline | Receiving review feedback — verify before implementing; no performative agreement. |
| `dispatching-parallel-agents` | mechanics | flexible | 2+ independent problem domains with no shared state — fan out one agent each. |
| `finishing-a-development-branch` | mechanics | rigid | Work complete + tests green — pick merge/PR/keep/discard and clean up the worktree. |
| `writing-skills` | process (meta) | rigid | Creating/editing a skill — TDD applied to process documentation (baseline → minimal skill → close loopholes). |

Several skills ship helpers worth knowing: `brainstorming` carries a browser "visual companion"
(`scripts/`); `subagent-driven-development` ships `task-brief` / `review-package` scripts and
implementer/reviewer prompt templates; `requesting-code-review` ships the `code-reviewer.md` template
(reused as SDD's final whole-branch review); `systematic-debugging` ships `find-polluter.sh` and
root-cause/defense-in-depth technique docs; `writing-skills` ships Anthropic's best-practices
reference and a flowchart renderer.

## The canonical chain (the guide)

Left to right, the skills compose into one end-to-end loop. The arrows are the skills' own terminal
handoffs, not a suggestion:

```
using-superpowers            (router — fires first, always)
   └─ brainstorming          idea → approved design doc   (HARD-GATE: no code until approved)
        └─ writing-plans      design → bite-sized plan + Global Constraints
             └─ using-git-worktrees     isolated branch + clean test baseline
                  └─ subagent-driven-development   ── or ──   executing-plans
                       │  (in-session, fresh agent/task,            (separate session,
                       │   two-verdict review, fix loop)             human checkpoints)
                       │
                       ├─ test-driven-development        every task: RED → GREEN → REFACTOR
                       ├─ systematic-debugging           every bug: root cause before fix
                       ├─ requesting/receiving-code-review   review between tasks
                       └─ verification-before-completion  gate every "done" claim
                            └─ finishing-a-development-branch   merge / PR / keep / discard + cleanup
```

`dispatching-parallel-agents` is the cross-cutting fan-out mechanic; `writing-skills` is the meta-loop
that authors and hardens all the others. The discipline that distinguishes superpowers from generic
prompting lives in four rigid laws worth internalizing:

- **brainstorming** — "This is too simple to need a design" is a named anti-pattern; the gate applies
  to *every* project. Its only legal next step is `writing-plans`.
- **test-driven-development** — `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`. Code written before
  its test is deleted, not adapted. "If you didn't watch the test fail, you don't know it tests the
  right thing."
- **systematic-debugging** — `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`. Four phases, each
  gating the next; after three failed fixes, stop and question the architecture, not the hypothesis.
- **verification-before-completion** — `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`.
  "should"/"probably"/"seems to" and premature "Done!" are red flags; run the command in this message
  or do not make the claim.

## The crosswalk — superpowers ↔ AAW

This repo already runs a full methodology. The plugin is a *second* one. Most of it reinforces AAW;
a few defaults conflict and defer to CLAUDE.md (next section). Read this as: where each superpowers
skill lands against the practice already in [aaw.rules.md](aaw.rules.md) and the `*-ship` skills.

| superpowers skill | AAW counterpart | Relationship |
| --- | --- | --- |
| `brainstorming` | the architect's four-part-arms fork + Operator ruling ([aaw.architect-approach.md](aaw.architect-approach.md)); Venus reconcile | **Overlap.** Both gate design before code. AAW's is heavier (Steelman/Steward arms, the Operator rules forks, NO-INVENT at source). Use superpowers brainstorming for greenfield/exploratory work *without* a rung; defer to the architect's approach the moment the choice is the Operator's. |
| `writing-plans` | the `<rung>.prompt.md` runbook + the spec triad ([specs.approach.md](../elixir/specs/specs.approach.md)) | **Overlap.** A rung that already has a `.prompt.md` + triad does not need a parallel superpowers plan; the triad is the plan. Superpowers `writing-plans` fits non-rung tasks. |
| `subagent-driven-development` / `executing-plans` | x-mode Flat-L2 lead-team (Venus → Mars-1 → Director → Mars-2 → Director ship) via [`/x`](../../.claude/commands/x.md) | **Overlap / choose one.** Both are "fresh subagent per task + review loop". For an echo_mq / codemojex / graft rung, x-mode is the orchestrator (it binds the gate ladder, the branded-id law, the LAW-4 commit). Reserve SDD for tasks with no `*-ship` skill. |
| `test-driven-development` | the gate ladder mandates *passing* tests, not *test-first* | **Gap filled.** AAW requires `mix test` green but does not mandate RED-GREEN-REFACTOR. Adopting TDD inside Mars's build is a strict strengthening. |
| `systematic-debugging` | — | **Gap filled.** AAW has no codified debugging discipline; the four-phase Iron Law is pure addition. |
| `verification-before-completion` | the Director's independent gate re-run; "report outcomes faithfully" (root CLAUDE.md) | **Reinforces.** Same honesty stance, stated as a per-claim gate. |
| `requesting` / `receiving-code-review` | the Director solo review + the Apollo evaluator | **Reinforces.** "Never skip review because simple" and "verify feedback, no performative agreement" match the Director/Apollo gates. |
| `dispatching-parallel-agents` | the fan-out formation; the `Workflow` tool; concurrency-asymmetry rule (≤2 heavy authors) | **Reinforces, with a caveat.** AAW caps concurrent heavy authoring at two ([aaw.rules.md](aaw.rules.md)); honor that cap over an unbounded fan-out. |
| `using-git-worktrees` / `finishing-a-development-branch` | LAW-4 pathspec commit; "commit only when asked"; "Operator runs deploys" | **Conflict — see below.** These two skills want to branch, auto-commit, merge, push, and open PRs; this repo forbids most of that without an explicit ask. |
| `writing-skills` | the `echo-mq-*`, `codemojex-*`, `*-course-writer` skills already in `.claude/skills/` | **Opportunity.** The repo's own skills are exactly the artifact `writing-skills` is built to harden. |

## The conflicts CLAUDE.md resolves (load-bearing)

Superpowers' priority ladder puts user instructions first, so these are not contradictions to fix in
the plugin — they are points where the agent must let the repo's law win:

- **Commit & merge discipline.** `test-driven-development` ends each cycle with "Commit";
  `finishing-a-development-branch` offers Merge / Push+PR / Discard. The root CLAUDE.md is stricter
  and **overrides**: *commit only when asked; pathspec only, never `git add -A`; the Operator
  pre-stages out-of-band, so re-verify `git diff --cached --name-only` is purely the rung; do not
  push unless asked* (and the standing ask: the Director commits each rung as a single LAW-4 pathspec
  commit). Take superpowers' TDD discipline; **do not take its auto-commit cadence** on rung work.
- **Deploys.** `finishing-a-development-branch`'s "Push + PR" must yield to *the Operator always
  deploys themselves* — never originate a deploy or an unrequested push.
- **Output locations.** Superpowers writes design docs to `docs/superpowers/specs/YYYY-MM-DD-*.md`,
  plans to `docs/superpowers/plans/*.md`, and an SDD ledger to `.superpowers/sdd/progress.md` (none
  exist yet). AAW's homes are `docs/<program>/specs/` (triads), `specs/progress/` (ledgers), and the
  design doc beside the chapter. For rung work, **redirect superpowers to the AAW path** (the skills
  honor a user-stated location); reserve the `docs/superpowers/` tree for non-rung, off-program work
  so it never shadows a program's canon.
- **"Tests pass" means the gate ladder.** Superpowers' generic "run the project's suite" is, for echo
  work, the per-app ladder: `TMPDIR=/tmp`, Valkey on `:6390`, `mix compile --warnings-as-errors`,
  `mix test`, `EchoMQ.Conformance.run/2`, the ≥100 determinism loop where a rung touches id-mint /
  process / lease. Bind `verification-before-completion` to *that* command set, not a bare `mix test`.
- **NO-INVENT & branded ids.** Already absolute in this repo (and, usefully, in superpowers' own
  94%-rejection contributor culture). No conflict — both forbid fabricated surface; superpowers'
  `verification-before-completion` and `receiving-code-review` reinforce it.

## Opportunities to improve

Concrete, in priority order. None of these touch `.claude/` config or commit anything — they are
recommendations for the Operator to ratify.

1. **Write the bridge into CLAUDE.md (highest leverage).** Add a short "superpowers defers to" note in
   the root [CLAUDE.md](../../CLAUDE.md): commit/push/deploy discipline overrides
   `finishing-a-development-branch`; "tests pass" = the gate ladder; rung design/plan paths use the
   AAW tree, not `docs/superpowers/`. Because the agent reads CLAUDE.md at rung 1 of the priority
   ladder, this is the single change that makes every conflict above resolve automatically.
2. **Adopt the gap-fillers now.** `test-driven-development`, `systematic-debugging`, and
   `verification-before-completion` add discipline AAW does not mandate and conflict with nothing.
   The cheapest win is to fold "Mars builds test-first; bugs go through systematic-debugging; every
   `done` is verification-gated" into the Mars charter / `echo-mq-implementor` skill so it survives
   the `<SUBAGENT-STOP>` carve-out.
3. **Settle the design-step owner per work type.** Decide once: a **rung** (has a `*-ship` skill or a
   `.prompt.md`) uses the architect's approach + triad and x-mode; a **non-rung greenfield** task
   uses brainstorming → writing-plans → SDD. Document the switch so the two design disciplines never
   both fire on the same work.
4. **Make fan-out peers superpowers-aware.** Since dispatched subagents skip the bootstrap, the
   disciplines you want inside Venus/Mars/Apollo and the `*-expert` authors must be named in their
   charters. Audit each charter for the three gap-fillers above; add what is missing.
5. **Use `writing-skills` to harden the repo's own skills.** The `echo-mq-*`, `codemojex-ship`,
   `graft-ship`, and `*-course-writer` skills are behavior-shaping documents with no eval harness.
   `writing-skills` (baseline-without → minimal skill → close loopholes, micro-tested against a
   no-guidance control) is the method to pressure-test them. A good first target is any skill that has
   drifted from as-built surface.
6. **Telemetry posture.** `brainstorming`'s optional visual companion loads a remote logo carrying the
   superpowers version (no project/prompt data). Disable with `SUPERPOWERS_DISABLE_TELEMETRY=1` (it
   also honors `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`) if the Operator wants
   zero outbound from the toolchain.
7. **Pin the provenance; update deliberately.** The enable records version `6.0.3` and a commit SHA.
   Skill bodies are tuned behavior — an update can change a gate. Treat `/plugin` updates as a
   reviewed change (re-read this doc's grounding), not an automatic one.
8. **Mind the failure mode of two methodologies.** The real risk is not either discipline but
   *thrash* — half a superpowers plan and half a triad on the same rung. The mitigation is owner
   clarity (item 3) plus the priority ladder (item 1): one design artifact, one plan artifact, one
   orchestrator per unit of work.

## Conventions

This document is a **companion reference**, not an AAW rung — it sits beside the AAW1–4 value ladder
in [aaw.md](aaw.md) and carries no triad or progress dashboard. It describes the plugin **as
installed**; where a claim here and the installed `6.0.3` skill body disagree, the skill body wins and
this document is corrected (the tree's master invariant: one authority per fact, the practice wins).
Voice and grounding per [aaw.rules.md](aaw.rules.md): plain prose, NO-INVENT, link don't restate.

## References

- The skills, verbatim: `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.3/skills/`
  (the 14 `SKILL.md` bodies) and the plugin `README.md` / `CLAUDE.md`.
- Upstream: <https://github.com/obra/superpowers> · the release note
  <https://blog.fsck.com/2025/10/09/superpowers/>.
- The enable + provenance: `.claude/settings.json` (`enabledPlugins`) and
  `~/.claude/plugins/installed_plugins.json`.
- The AAW contracts this composes with: [aaw.framework.md](aaw.framework.md) (roles, the
  surface-forks boundary, the values), [aaw.rules.md](aaw.rules.md) (the LAWS, formations, gates,
  voice), [aaw.architect-approach.md](aaw.architect-approach.md) (the design-fork method),
  [specs.approach.md](../elixir/specs/specs.approach.md) (the triad templates), and the root
  [CLAUDE.md](../../CLAUDE.md) (the commit / deploy / gate-ladder laws that win every conflict).

---

Index: [aaw.md](aaw.md) · Definition: [aaw.framework.md](aaw.framework.md) · Rules: [aaw.rules.md](aaw.rules.md) ·
Architect: [aaw.architect-approach.md](aaw.architect-approach.md) · Reverse: [aaw.reverse.md](aaw.reverse.md) ·
Roadmap: [aaw.roadmap.md](aaw.roadmap.md)
