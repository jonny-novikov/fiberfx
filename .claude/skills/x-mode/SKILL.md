---
name: x-mode
description: "Use this skill to ship a spec-driven rung at maximum rigor via the supervised aaw Flat-L2 lead-team — Venus (reconcile-or-create the design) → Mars-1 (spec-driven build + test) → Director (solo review + findings + learning) → Mars-2 (remediate + harden) → Director (ship + one LAW-4 commit), with Apollo a dedicated evaluator mandatory only on a high-risk rung (it uses AskUserQuestion to keep the product shippable). The INPUT is a `<rung>.prompt.md` orchestration runbook (e.g. docs/elixir/specs/phoenix/f6.9.prompt.md): read it and execute its stages as a TRUE team (TeamCreate + mcp__aaw__* registration + the tool_x_* specs ledger), Director-in-loop at every gate, under CLAUDE_LAWS 1/1a/2/3/4. The flow is X-rigorous (deep reasoning, specs triad compliance, adversarial verify) AND pragmatic-fast-ship (thin-but-robust, reductive minimization, one tight increment). Triggers: 'ship <rung>', 'run/launch the <rung> pipeline', 'as a Director fan out venus→mars→apollo', 'execute <rung>.prompt.md', or any request to build a rung that already has a `.prompt.md` + spec triad. Do NOT use for: trivial single-file edits (use Solo-Director /x), course-authoring (use the *-course-writer skills), or any work with no spec triad and no `.prompt.md`."
---

# X-MODE — ship a rung via the supervised lead-team

This skill executes ONE spec-driven rung end-to-end through the **aaw Flat-L2 scrum team**, Director-supervised,
to a single ratifying commit. The **input is a `<rung>.prompt.md`** — the orchestration runbook the Operator
hands over (its "rung in one paragraph", its Mode, its settled forks, its per-stage prompts, its acceptance, its
commit pathspec). This skill turns that runbook into a real, audited, LAW-compliant multi-agent run.

**It is a binding layer, not a re-implementation.** Three sources of truth already hold the discipline — defer to
them, do not duplicate:

1. **`.claude/commands/x.md`** — the X-MODE manual: CLAUDE_LAWS 1/1a/2/3/4, the §5 spawn protocol, the §6 audit
   tools, the §10 commit rules, the §11 evaluator rigor. **The laws live there; this skill enforces them.**
2. **`.claude/agents/{venus,mars,apollo}.md`** — the role charters, carrying every guardrail prior rungs earned.
   Each peer spawn ADOPTS its charter.
3. **the `<rung>.prompt.md`** — the rung delta: what is settled, what each stage builds, what "shipped" means.

## Two standing rules

1. **TRUE team, never role-play (LAW-1).** Every peer is a real `Agent` spawn that registers itself via
   `mcp__aaw__agent_register` from its own context. Running the pipeline by editing files yourself, or by
   "spawning" peers in narration, is **FAKE-N / V-SOLO** — the exact violation this skill exists to prevent.
   The Director coordinates and ratifies; the peers do the work.
2. **Rigor serves the ship (pragmatic-fast-ship).** Maximum rigor is the *method*, a shipped thin-but-robust
   increment is the *goal*. Deep-reason the contracts and the risks; then take the **smallest change that
   preserves correctness** (reductive minimization) and ship it. Do not gold-plate, do not widen scope, do not
   ship untested. One rung, one increment, one commit.

## 0. Bootstrap — read the runbook, declare the mode, deep-reason the rung

Before any spawn (Director, UNDERSTAND→EXPAND phases of x.md §2):

- **Read the `.prompt.md`** named in the request, plus the roadmaps and the spec triad it references
  (`<rung>.md` / `.stories.md` / `.llms.md`). The `.prompt.md` is the authoritative scope for this run.
- **Declare the mode in plain text** — this is **Flat-L2** (multi-stream: a build + a gate + a verify). Solo is
  the exception, not this skill.
- **Deep-reason the rung** (x.md §3, a LAW-class turn → verbose reasoning, LAW-3.2): state the 5W; enumerate the
  solution space incl. a do-nothing baseline; encode the rung's invariants as runnable checks (grep / `mix
  xref` / a probe); ask "what is the smallest change that preserves correctness?". Record the derivation as a
  `tool_x_trace` (T-n), not just the verdict.
- **Confirm the Stage-1 gate is reachable** — the triad exists and the `.prompt.md`'s "settled forks" carry no
  open Operator decision. If a fork is open, STOP and `AskUserQuestion` (x.md §4) before spawning.

## 1. Stand up the TRUE team (x.md §5)

`scope` = the rung slug — **lowercase alphanumeric + dashes only, NO dots** (`tool_x_*` enforces
`^[a-z0-9][a-z0-9-]*$`, and `TeamCreate` silently rewrites a dot to a dash, so a dotted name split-brains across
the three namespaces). Use the dashed form everywhere — e.g. **`portal-f6-9`**, never `portal-f6.9`. `operator` =
the human (`jonny`). `workspace` = `/Users/jonny/dev/jonnify`. Sequence:

```
1. mcp__aaw__init(scope, operator, workspace, ttl_days: 30)
2. mcp__aaw__spawn(scope, role: "director", archetype: "director", name: "director")  → director CCL-id
3. mcp__aaw__agent_register(scope, name: "director", role: "director", ccl_id: <from step 2>)
4. TeamCreate(team_name: scope, agent_type: "director")          # creates the team + its task list (SendMessage routing)
5. mcp__aaw__tool_x_trace(task_id: scope, slug: scope, body: "T-1 — UNDERSTAND: ...")  # opens the scope ledger <ledger_dir>/<scope>.progress.md, lands the §0 derivation
```

**Specialized peers — the tool-availability rule.** The `.claude/agents/{venus,mars,apollo}.md` defs do **not**
list `mcp__aaw__*` in their tools allowlist, so a `subagent_type: venus` spawn cannot register or write audit
artifacts. **Spawn `subagent_type: "general-purpose"`** (full toolset incl. aaw) and make each peer a
specialist via its **prompt** — adopt the `.claude/agents/<role>.md` charter. `general-purpose` + charter IS the
"specialized agent" in this protocol (it is how the prior real team `portal-f5-refine` registered Venus/Mars/Apollo).

Create one Task per stage (`TaskCreate`) so the team coordinates and progress is visible.

Sequential, Director-in-loop. A team `Agent` spawn runs as an **async teammate** — the call returns immediately
(`agent_id: <Name>@<scope>`) and the peer's report **auto-delivers as a later turn** when it messages the
director or goes idle; **do NOT poll** (the harness delivers teammate messages automatically). "Sequential" is
the Director **holding the gate** — not spawning the next stage until the current peer's report has arrived and
the gate has passed. Review each report, check the gate, then advance. Lift each stage's concrete instruction
from the `.prompt.md`'s matching stage block; the per-spawn contract (§3 below) wraps it.

| Stage | Peer (role) | Does | Director gate before advancing |
|---|---|---|---|
| 1 | **Venus** (architect) | the design — **reconcile it if it exists, create it if it does not** (the fork) — then finalize the triad to **build-grade** + log locked contracts as `tool_x_decision` (D-n) | the design is settled (reconciled or freshly created); no open fork; every claim MATCH or `[RECONCILE]`-DEFERRED; the brief is internally consistent (no deliverable/invariant referenced-but-undefined) |
| 2 | **Mars-1** (implementor) | **specification-driven implementation + testing**: build to the brief, cite the spec line for every public call, invent nothing, keep the diff inside the boundary, write the rung's own tests, **compile clean** | compiles; the deliverables exist; the tests Mars wrote pass; the diff stays inside the boundary; report names any realization-over-literal |
| 3 | **Director** (solo review) | the **solo review** — a fresh-gate reconcile + an independent re-run of the gate + ≥1 adversarial probe + a mutation spot-check (Edit-in, kill, **revert net-zero**) — then **docs update + findings + learning consolidation** (the REMEDIATE list for Mars-2) | the build is faithful + inside the boundary; findings recorded (`tool_x_report` + REMEDIATE items as learnings/decisions); the Director authored **no production code** (LAW-1a — probes revert clean) |
| 4 | **Mars-2** (implementor, harden) | **remediation + hardening**: close the Stage-3 findings + run the rung's full gate (tests + liveness + the rung's special checks + the determinism loop); the **REMEDIATE loop, MAX=3** | every gate item PASS/explained; the REMEDIATE list closed; tests green; liveness/determinism holds; boundary grep empty |
| 5 | **Director** (solo ship) | **ensure the rung is shipped per the AAW pragmatic-agile framework**: the solo ship-gate + **one LAW-4 commit** (§4 below) + the Stage-6 feedback fold | gate green; D-n + Z-n present; pathspec excludes operator out-of-band; tree/rebase checked |
| ◇ | **Apollo** (evaluator) — **DEDICATED, MANDATORY ONLY ON A HIGH-RISK RUNG** (runs between Stage 4 and Stage 5) | the **§11.2 charter** (prompted-checks table + ≥1 un-prompted finding + ≥1 attack-that-held + a mutation kill-rate) → **`AskUserQuestion` to resolve every ambiguity and keep the product shippable** → spec-sync → **BUILD-GRADE / BLOCKED** + mentor diffs | (high-risk only) Apollo's verdict is BUILD-GRADE; every `AskUserQuestion` resolved by the Operator; the charter complete; survivors triaged |

**Why Mars twice, with the Director review between (the fast-ship/rigor balance).** Mars-1 makes it *work* to the
brief (a thin vertical slice + its own tests); the **Director's solo review** (Stage 3) finds the gaps and
consolidates them into a REMEDIATE list; Mars-2 makes it *right* against the gate and the Given/When/Then stories
(remediate + harden + REMEDIATE). This is the pragmatic core — ship a thin increment, prove it, rather than
gold-plate up front or ship unverified. **Resume the Stage-2 Mars** for the harden pass (`SendMessage`, preserving
build context) — one Mars identity, two passes (keeps the registry honest, avoids a FAKE-N smell).

**The solo-Director review is the default; Apollo is the high-risk escalation.** The Director's Stage-3 review is
the standard verification floor — and it must be a **real** pass (a fresh-gate reconcile + an independent gate
re-run + an adversarial probe + a mutation spot-check), never a glance at the implementor's report; re-run what
the runbook *names*, do not accept a claimed-equivalent. **Apollo spawns only when the rung is high-risk** — an
auth / data / deploy / security / irreversible-migration dimension (the `.prompt.md`'s risk tier). On such a rung
Apollo is **MANDATORY**: a dedicated evaluator with the §11.2 charter who **uses `AskUserQuestion` to resolve any
ambiguity with the Operator and keep the product shippable** before the Director's ship. For a normal rung Apollo
does not spawn; the Director's solo review (Stage 3) + the solo ship-gate (Stage 5) are the verification.

**Build new products — no shims, no backward-compat.** The AAW team develops new complex products, **not** a
maintenance line. **Breaking changes are accepted with NO shims and NO backward-compatibility layers.** Do not add
a compat shim to preserve an old surface; change the surface and update every caller in the same rung. This is why
the spec is the source of truth and the reconcile keeps it current — there is no legacy contract to honor, and a
rung that "keeps the old path working alongside the new" has widened its own scope against this rule.

**Stage 6 — feedback loop (Director).** After the commit, fold forward: reconcile the roadmaps to the new reality,
write/extend the retrospective, and — under an **explicit Operator grant only** — apply the mentoring diffs (from
the Director's Stage-3 learning consolidation, or from Apollo on a high-risk rung) to the peer agent defs (the
harness fences peer-def edits; a redirect is not a grant). Surface the next frontier / killer-feature shortlist.
If this rung closes a milestone, frame the retrospective as the milestone capstone.

## 2b. The Design Phase variant — when the deliverable IS the spec (x.md §12)

Distinguish two "no design yet" cases. Stage 1's **create** branch handles a *rung-level* design that does not
exist yet — one Venus authors it inline, then the build pipeline proceeds normally. The **Design Phase** below is
the heavier case: founding or re-founding a whole *SYSTEM* spec, where the risk warrants a dual-architect
formation and an explicit Operator approval before any code.

When the `.prompt.md` declares a **Design Phase** (a SYSTEM spec founded or re-founded — no settled
design to brief from), §2's build pipeline is replaced by the §12 formation: **Venus-1 ∥ Venus-2
(independent architectural designs + ADR sets, identical locked-constraints briefs, distinct leading
lenses, spawned in one message, no sibling reads until both land) → cross-review → Apollo design
evaluation → Director ratify → OPERATOR APPROVAL**. Mars does not spawn; **no production code exists
before the approved design**; the spec triads derive from the design afterward. Stage gates: both
designs on disk → reviews exchanged → Apollo's convergence/divergence verdict with ADR-completeness
+ constraint-fidelity checks → the Director's synthesis → the Operator's explicit feedback. Git
follows the fan-out discipline (peers + Director run none; the Operator commits out-of-band at
approval) unless the runbook assigns a LAW-4 commit. Authored 2026-06-10 after the `emq.*`
orchestrator-solo rewrite (V-SOLO-4) — the violation this variant exists to prevent.

## 3. The per-spawn contract (Template B + the ceremony)

Every peer prompt (x.md §5/§7, LAW-3.1) carries, in order:

1. **Framing** — "As <Codename>, the <Role> on team `<scope>`, …". Third person for any agent reference; **no
   gendered pronouns, no perceptual verbs (sees/notices), no interior-state (you feel/want), no first-person
   narration** in emitted prose.
2. **Adopt the charter** — "Read and operate by `.claude/agents/<role>.md` — that is the operating discipline."
3. **The aaw ceremony, from your own context** —
   `mcp__aaw__spawn(scope: "<scope>", role: "<role>", archetype: "<architect|implementor|evaluator>", parent_id: "<director CCL-id>")`
   then `mcp__aaw__agent_register(scope: "<scope>", name: "<Codename>", role: "<role>")`. (Preflight: load the
   aaw schemas via `ToolSearch(query: "select:mcp__aaw__spawn,mcp__agent_register,...")` —
   they start deferred.)
4. **The rung delta** — the matching stage block from the `<rung>.prompt.md`, verbatim or tightened.
5. **The audit directive** — write the derivation as `tool_x_trace` (T-n), every locked contract as
   `tool_x_decision` (D-n), alternatives as `tool_x_alternative` (V-n), surprises as `tool_x_learning` (L-n),
   the final summary as `tool_x_report` (Y-n) — all with `task_id: "<scope>", slug: "<scope>"`. Peers do **not**
   commit (LAW-1a / LAW-4).
6. **The propagation clause (LAW-3.1, REQUIRED)** — "Enforce these same framing rules in your own output and in
   any prompt you emit."
7. **Report back** — "Report via `SendMessage(to: \"director\", …)`; leave all changes in the working tree for
   the Director to ratify."

## 4. LAW-4 — the single ratifying commit (Director-only)

The Director is the **sole committer**, at the moment `tool_x_complete` (Z-n) is written, exactly once
(x.md §10). Preconditions, checked in order:

1. The verification is green: the **Director's Stage-3 solo review** is clean (its findings closed by Mars-2) and
   the Stage-4 gate passes — and, **on a high-risk rung, Apollo's verdict is BUILD-GRADE** with every
   `AskUserQuestion` resolved.
2. **≥1 `tool_x_decision` (D-n)** is locked, and a **`tool_x_complete` (Z-n)** is written this turn (the LAW-4
   trigger — the aaw server enforces "Z-n requires ≥1 D-n").
3. `git status --short` **and** `git diff --cached --name-only` reviewed; `.git/rebase-merge` / `rebase-apply`
   checked (the operator stages + rebases out-of-band — the working tree, not any commit, is the source of truth).
4. **Pathspec commit** — `git commit -F <msgfile> -- <exact paths from the .prompt.md's Stage-5 pathspec>`.
   **NEVER `git add -A`; NEVER a bare `git commit`** (it commits the whole index, sweeping operator pre-staged
   files). Exclude operator out-of-band paths the `.prompt.md` enumerates. Recover a botched bundle with
   `git reset --soft HEAD~1` then the pathspec commit (guard the reset on the expected HEAD first).
5. The message body cites the **slug, the Z-n, the D-n decisions, and the Y-n report** (x.md §10 template).

## 5. Quality gate — run before `tool_x_complete` (mirrors x.md §8)

- [ ] Mode declared Flat-L2 (plain text); the `.prompt.md` + triad + roadmaps read.
- [ ] T-n derivation written for the §0 reasoning; D-n for every locked contract; L-n for surprises.
- [ ] Every peer is a **real `Agent` spawn** that **self-registered** (LAW-1, no FAKE-N); the Director called no
      `Edit`/`Write` on implementation files (LAW-1a).
- [ ] LAW-3.1: zero interior-state / perceptual / first-person-agent clauses in any emitted prompt; the
      propagation clause present in each.
- [ ] The design is settled pre-build (Venus reconciled it or created it); the post-build reconcile ran — the
      **Director's Stage-3 solo review** by default, **Apollo** on a high-risk rung — build-grade, no unmarked STALE/INVENTED.
- [ ] The Director's Stage-3 review was a real pass (fresh-gate reconcile + independent re-run + adversarial probe
      + mutation spot-check), not a glance; on a high-risk rung **Apollo's verdict carries the §11.2 charter**
      (un-prompted finding + attack-that-held + mutation kill-rate) and resolved every `AskUserQuestion`.
- [ ] LAW-4: Z-n written → exactly one Director pathspec commit staged; nothing foreign in `--cached`.
- [ ] `mcp__aaw__status(scope)` shows the registered peers; `tail .claude/audit.log` (if present) shows
      no unexplained FAKE-N / V-SOLO warnings.

## 6. Map

- The laws + full protocol: [`.claude/commands/x.md`](../../commands/x.md) (LAWS, §5 spawn, §6 audit, §10
  commit, §11 evaluator rigor).
- The role charters: `.claude/agents/venus.md`, `.claude/agents/mars.md`, `.claude/agents/apollo.md`.
- The reconcile differ: [`.claude/commands/reconcile.md`](../../commands/reconcile.md) (Venus pre / Apollo post).
- The rung delta: the `<rung>.prompt.md` named in the request (the authoritative scope for the run).
- The audit trail of the run: the scope ledger `<scope>.progress.md` (`{<scope>-<channel>}` tagged sections holding the T/A/V/D/L/S/C/E/P/Y/Z entries — the locked single-file model, exemplar `docs/echomq/specs/emq/design/emq-design.progress.md`) + `mcp__aaw__status`.
