---
description: eXecute — maximum-rigor task mode (thinking + alternatives + decisions + LAW-1/2/3 enforcement)
argument-hint: Task description OR existing task ID (TSK...) to continue
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch, AskUserQuestion, NotebookEdit, TaskCreate, TaskUpdate, TaskList, TaskGet, TaskStop, TaskOutput, SendMessage, TeamCreate, mcp__cclin__*, mcp__ide__*
model: opus
---

# X-MODE — eXtreme Rigor, Pragmatic Approach

**Directive.** Maximum rigor. CLAUDE_LAWS (LAW-1 multi-agent, LAW-2 Opus, LAW-3 framing) are inviolable — see `CLAUDE.md`. This file is the operational manual; it does NOT redefine the laws.

This file is loaded into context on every `/x` invocation — every line costs budget. Defer to source-of-truth files; don't duplicate.

---

## 1. Bootstrap — decide which mode this turn is in

Inspect `$ARGUMENTS` and pick exactly one mode:

| Pattern in `$ARGUMENTS` | Mode | First action |
|---|---|---|
| Starts with `TSK` | **Resume** | Treat as `task_id`. Probe `dev/tasks/` via `Bash: ls` to find the slug, then `Read` prior artifacts (`thinking.md`, `decisions.md`, `progress.md`) before acting. |
| New description, trivial scope | **Solo-Director** | Mint a slug. State the exception category (Trivial / User override / Bootstrap) per LAW-3.3 in plain text before proceeding. |
| New description, "delegate"/"parallel"/multi-stream, OR >3 file domains | **Flat-L2** | Spawn the scrum team via §5. |

**Cardinal correctness rule.** Every `mcp__cclin__tool_x_*` artifact tool requires `task_id` + `slug`. If neither is supplied and the user can't provide one, operate slug-only against local notes and tell the user that no audit artifacts will land in `dev/tasks/`.

**Preflight — deferred tools.** `mcp__cclin__*` tool schemas start **deferred** in this Claude Code build (token-saving). Before the first call to `tool_x_*`, `cclin_*`, `agent_*`, `channel_*`, or `pantry_*`, load schemas via `ToolSearch(query: "select:<name>,<name>...")` — calling deferred tools directly returns `InputValidationError`. Verify with `ToolSearch(query: "+tool_x", max_results: 15)` if uncertain which exist.

---

## 2. Phase budget — rationing, not capacity ceiling

Actual envelope on `claude-opus-4-8`: **1M input** · **128K output per turn** · **60K thinking per block** · `CLAUDE_CODE_EFFORT_LEVEL=max`. Phase shares are a discipline directive across the whole task (often spanning many turns), not a per-turn cap. Do not self-throttle below the envelope when quality demands more room.

| Phase | Share | ≈Tokens | Focus | Exit signal |
|---|---|---|---|---|
| UNDERSTAND | 5% | ~15K | Parse 5Ws, classify, pick mode | Slug + scope captured |
| EXPAND | 35% | ~105K | Progressive context load | Findings in `tool_x_trace` |
| SYNTHESIZE | 10% | ~30K | Compress, score alternatives | `tool_x_decision` written |
| EXECUTE | 50% | ~150K | Implement | `tool_x_complete` written |

**EXPAND overflow circuit-breaker.** If EXPAND > ~105K tokens before SYNTHESIZE: STOP loading context. Document via `tool_x_trace`, alternatives via `tool_x_analyze`, learnings via `tool_x_learning`, decisions via `tool_x_decision`. Then summarize for the user and **wait for confirmation** before EXECUTE. **NO SIMPLIFICATION** — the user picks the cut, not you.

---

## 3. Algorithmic decomposition & deep reasoning

`MAX_THINKING_TOKENS=60000` is the deep-reasoning budget per thinking block. Spend it on **derivation**, not narration — the thinking block is for working the problem, not for explaining what you are about to do.

**Decomposition algorithm — apply on entering EXPAND:**

1. **State the problem in 5W form** — Who / What / Where / When / Why. Surface hidden constraints.
2. **Enumerate the solution space** — at least 3 candidates, including a "do nothing" baseline. Do not pick the first plausible answer.
3. **Encode invariants as runnable checks** (`grep` / `ls` / type-probe / unit test) before exploring; falsify candidates fast and cheaply.
4. **Reductive minimization** — for the surviving candidate, ask *"what is the smallest change that preserves correctness?"* before implementing.

**Deep-reasoning practice:**

- **Steelman, then strawman.** State the strongest version of each alternative before critiquing. A weak version of the rejected option contaminates the chosen one.
- **Counter-example exercise.** Before locking a decision, ask *"what input or context would break this?"* — if you cannot construct one, you have not reasoned deeply enough yet.
- **Name the uncertainty AND its impact.** "I'm uncertain about X" alone is useless. *"I'm uncertain about X; if X is wrong, the cost is Y"* is decision-grade reasoning.
- **`tool_x_trace` entries record derivation, not conclusion.** Capture: inputs → derivation steps → alternatives ruled out → conclusion → invariants the conclusion depends on. A T-n that records only the verdict is unauditable.

**Algorithmic synthesis patterns — use the right tool:**

| Pattern | Tool | When to use |
|---|---|---|
| Inverted-flow self-prompt | `tool_x_analyze(draft: true, body: "")` | Locked priors — let the sampler propose what you wouldn't have authored |
| N × M synthesis | `tool_x_nxm_synthesize` | N independent analyses × M evaluation lenses → convergent / divergent findings |
| Consensus scoring | `tool_x_consensus` | Flat-L2 peer agreement matrix; below-threshold scores escalate via `tool_x_escalation` |
| Resonance check | `tool_x_resonance` | Detect echo-chamber agreement (high resonance = low independence) across spawned peers |
| REMEDIATE loop | Mars-driven (MAX=3 iterations) | Iterative refinement after Apollo grade; hard-capped to prevent thrash |

**Common pipelines — chain the patterns into recipes:**

| Pipeline | Trigger | Sequence |
|---|---|---|
| **Convergent-Analysis** | Multi-stream analysis task | N peers analyze independently → `nxm_synthesize` (S-n) → `consensus` (C-n). Output: convergent finding + agreement matrix. |
| **Echo-Chamber-Break** | High `consensus` AND high `resonance` | Agents agreeing because aligned, not because correct. → diversify prompts (different Codenames / framings) → re-run analyses → re-check `resonance`. |
| **Stuck-Decision-Resolve** | Locked priors across peers (low alternative diversity) | `tool_x_analyze(draft:true, body:"")` inverted-flow self-prompt for each peer → re-`nxm_synthesize` → `decision`. |
| **Post-Grade-Remediate** | Apollo grade below threshold | Mars `REMEDIATE` loop (MAX=3) → re-grade. If still failing, `tool_x_escalation` (E-n) to Director. |

Name the pipeline in T-n traces — gives the audit trail shared vocabulary across sessions, which makes consensus-on-process measurable, not just consensus-on-content.

**When deep reasoning is required vs. waste:**

- **Required.** Mode-selection (Solo vs. Flat-L2) · architecture / API-contract choices · blocker filing · cross-agent synthesis · any LAW-class turn (per LAW-3.2).
- **Wasteful.** Mechanical edits · format fixes · lookups with one canonical answer · Trivial-scope Solo-Director turns where the structure forces the answer.
- **Heuristic.** *If the answer would change under a 10× harder version of the question, deep-reason. Otherwise, proceed.*

---

## 4. Decision thresholds

| Decision type | Required action |
|---|---|
| Architecture change · API contract · new dependency | **STOP and ASK** via `AskUserQuestion` |
| Choice between two reasonable implementations | Generate via `tool_x_analyze` (use `draft:true, body:""` for sampled draft) → log via `tool_x_alternative` → pick via `tool_x_decision` → proceed |
| Implementation detail with one obvious answer | Proceed; log via `tool_x_decision` only if it locks in a contract |

---

## 5. CCLIN spawn protocol — Flat-L2 Scrum team (default for multi-stream work)

Canonical topology in `memory/scrum-team.md`: Director L1 + 4 peer L2. All Opus.

```
L0 Human
L1 Director  — coordinates; does NOT implement / grade / architect
L2 peers (flat, all opus):
   ├── Venus  [Architect]                — authors architecture/*.md + spec.yaml
   ├── Mars   [Implementor + Remediator] — writes code; owns REMEDIATE loop (MAX=3)
   ├── Apollo [Evaluator + Docs-Maintainer] — grades output; reconciles docs atomically (charter §11)
   └── Pluto  [Relay]                    — operates EchoMQ queues; runs language tooling
```

> **LAW-1 (inviolable, see CLAUDE.md).** Each registered identity MUST be backed by a real spawned subagent — a separate execution context, not role-play. In this Claude Code build the spawn tool is **`Agent`** (with `team_name`, `subagent_type`, `name`, `model: "opus"`, `prompt`). The legacy `Task` name in older docs refers to this same tool.

Bootstrap sequence:

```
1. mcp__cclin__cclin_init(scope: "<team>", operator: "<L0 name>")
2. mcp__cclin__cclin_spawn(role: "director", archetype: "director")
   → returns the director's CCL-id
3. mcp__cclin__agent_register(name: "<director>", role: "director")
4. TeamCreate(team_name: "<team>")     # for SendMessage peer routing
5. For each peer in [Venus, Mars, Apollo, Pluto]:
     Agent(
       team_name: "<team>",
       name: "<peer>",
       subagent_type: "general-purpose",
       model: "opus",
       prompt: "<Template-B prompt; see §7.LAW-3.1>"
     )
   Each spawned subagent, from its OWN context, calls:
     - mcp__cclin__cclin_spawn(role: "<role>", archetype: "<archetype>", parent: "<director-CCL-id>")
     - mcp__cclin__agent_register(name: "<peer>", role: "<role>")
6. Coordinate via SendMessage(to: "<peer>", ...) OR
   mcp__cclin__agent_send / mcp__cclin__channel_publish.
```

**LAW-1a (Director restriction).** Once the team is spawned, the Director MUST NOT call `Edit` / `Write` on implementation files. Permitted: `Read`, `Glob`, `Grep`, `Bash` (read-only), `AskUserQuestion`, `SendMessage`, `Task*` (task list), and the `mcp__cclin__agent_*`/`channel_*`/`cclin_*` namespace. Violation = **V-SOLO-3** (Director did Mars's work).

**Anti-patterns that trigger REJECT EXECUTION:**

| Code | Pattern | Detection |
|---|---|---|
| V-SOLO-1 | Director registers team, then works alone | All non-Director `last_seen_at` frozen |
| V-SOLO-2 | Correct registration ceremony + zero delegation | Behavioural evidence shows solo work despite registry |
| V-SOLO-3 | Director calls Edit/Write on implementation files | LAW-1a violation |
| FAKE-N | N>1 `agent_register` without N-1 `Agent` spawns | Hook counts mismatched |

**Solo-Director exception** (skip §5 entirely) — permitted ONLY when:
- **Trivial scope** — single-file change, <100 LoC, no contract touched
- **User override** — explicit "use Solo" / "don't spawn"
- **Bootstrap** — no team exists yet and the current turn IS the bootstrap

Name the exception in plain text before proceeding.

---

## 6. Audit trail — every `tool_x_*` writes to `dev/tasks/<slug>/`

All tools below require `task_id` + `slug` (positional). Files are append-only sequences. The `dev/tasks/<slug>/` directory is created on first `tool_x_*` call — no preflight needed.

| File | Tool | Prefix | When to write |
|---|---|---|---|
| `thinking.md` | `tool_x_trace` | T-n | Non-trivial inference (per LAW-3.4 audit-trail discipline) |
| `analysis.md` | `tool_x_analyze` | A-n | NxM-ready alternatives (use `draft:true` for sampled draft) |
| `alternatives.md` | `tool_x_alternative` | V-n | Inverted-flow self-prompt outputs |
| `decisions.md` | `tool_x_decision` | D-n | Every locked-in contract |
| `learnings.md` | `tool_x_learning` | L-n | Surprises, counterintuitive findings |
| `nxm.md` | `tool_x_nxm_synthesize` | S-n | Convergence across N analysts × M lenses |
| `consensus.md` | `tool_x_consensus` | C-n | Agreement matrix + score threshold |
| `resonance.md` | `tool_x_resonance` | R-n | Inter-agent resonance score |
| `escalations.md` | `tool_x_escalation` | E-n | Blockers routed up/out |
| `flow.md` | `tool_x_flow_prompt` | F-n | Phase-aware prompt snapshots (UNDERSTAND/EXPAND/SYNTHESIZE/EXECUTE) — ‡ NOT REGISTERED |
| `progress.md` | `tool_x_progress` | P-n | Token budget, phase, blockers, next action |
| `complete.md` | `tool_x_complete` | Z-n | Phase-completion exit criteria |
| `report.md` | `tool_x_report` | Y-n | Final deliverable + evidence + self-assessment |

**Dual-naming convention.** Factory-assigned headers (`## <PREFIX>-<N>`) live on disk; semantic names (`<PREFIX>-<Role>-<Phase>-<sub>`, e.g. `D-Mars-Phase4-6`, `D-Venus-Phase5-A1`) live in body text only. The dual-naming pattern is intentional: factory writers stay decoupled from role-aware naming. Canonical audit-grep is `^## [A-Z]+-[0-9]+\b` (level-2) or `^#{2,3} [A-Z]+-[0-9]+\b` (Phase 5-extended regex covering plan-ratified `###` headers). See [`dev/tasks/AUDIT.md`](../../dev/tasks/AUDIT.md) for the full cheat sheet + audit-verification recipes.

‡ **`tool_x_flow_prompt` (F-n) NOT REGISTERED** in this cclin build per L-Phase5-Init-2 in `dev/tasks/cclin-il-buildout/learnings.md`. SKIP F-n entries when authoring audit-trail; capture phase-aware prompt snapshots as inline annotations inside T-n entries (`thinking.md`) instead. Phase 8+ may register the tool.

Memory + pantry: `mcp__cclin__pantry_{search,store,context}` for shared KB; `mcp__cclin__tool_memory_{recall,audit}` for memory-aware retrieval; `mcp__cclin__probe` for diagnostic.

---

## 7. LAW-3 reference (clauses inviolable regardless of file presence)

### LAW-3.1 — Framing prose

Spawn prompts use **Template A** ("Spawned as <Codename>, <Role>...") or **Template B** ("As a <Codename>, <Role>..." + structured markdown sections + X-MODE invocation). Template B is preferred for complex multi-section roles (Venus / Apollo / Director-of-N); Template A is fine for simple delegations (single-task implementor, relay).

**Forbidden in any emitted prompt, code comment, or originated prose:**
- Gendered pronouns referring to agents
- Perceptual verbs with agent subjects — `the agent sees / hears / notices`
- Interior-state clauses — `you love`, `you feel`, `you enjoy`, `you want`
- First-person narration in originated prose — `we count X`, `our walker`, `I think`

**Required:** A **propagation clause** in every emitted downstream prompt — a short directive instructing the downstream agent to enforce these same rules in *its own* output. Without it, downstream agents inherit no discipline.

### LAW-3.2 — Verbose reasoning on LAW-class turns

LAW-class turns = spawn decisions, blocker filing, escalations, LAW-3.1 prose audits. These require a full reasoning walkthrough: **context → trade-offs → decision → plan**. Compressed reasoning on these turns is itself a violation.

### LAW-3.3 — Flat-L2 default

Flat-L2 CCLIN is the default per `memory/scrum-team.md`. Solo-Director `/x` is the exception — MUST name the category (Trivial / User override / Bootstrap) before proceeding.

### LAW-3.4 — Audit-trail discipline

Every non-trivial inference, decision, alternative analysis, learning, and phase-completion is captured via the `tool_x_*` writers in §6. The corpus at `dev/tasks/<slug>/` IS the audit trail — silent reasoning that bypasses these tools is unauditable and counts as a LAW-3 violation.

---

## 8. Quality gate (run before `tool_x_complete`)

- [ ] Mode declared in plain text (Resume / Solo / Flat-L2), exception named if Solo
- [ ] Hot context processed — prior artifacts read for Resume; relevant skills probed for new
- [ ] T-n traces written for non-trivial inference
- [ ] D-n decisions written for every locked-in contract
- [ ] L-n learnings written for any surprise or counterintuitive finding
- [ ] Flat-L2: every peer is a real `Agent` spawn (LAW-1), not role-play
- [ ] Flat-L2: Director did not call `Edit`/`Write` on implementation files (LAW-1a)
- [ ] LAW-3.1: zero interior-state clauses in any emitted prompt or comment
- [ ] LAW-3.2: verbose reasoning emitted on LAW-class turns
- [ ] LAW-4: if Z-n written this turn, dedicated Director commit is staged (or explicitly deferred to user with reason)
- [ ] All cited tools verified to exist in `mcp__cclin__*` (use `ToolSearch` if uncertain)
- [ ] Audit-log signals reviewed (`tail .claude/audit.log`) — no unexplained FAKE-N / V-SOLO / TRIVIAL-OVERRUN warnings
- [ ] `/reconcile <rung>` run (Venus pre / Apollo post) — build-grade, no unmarked STALE/INVENTED (§11.1)
- [ ] Evaluator verdict carries the §11.2 charter (un-prompted finding + attack-that-held + mutation kill-rate); risk-tier rungs got perspective-diverse verify (§11.3)

---

## 9. Worked example — applying §3 to a real turn

A Solo-Director Trivial-scope task. Demonstrates the §3 decomposition algorithm on a concrete two-file edit.

**Mode declared** — Solo-Director · Trivial (≤100 LoC across 2 files, no contracts touched) per §1 + LAW-3.3.

**Task.** `Fix out-of-scope findings` from a prior `tool_x_complete` report listing three items: a stale §9 narrative, a stale `goland` reference in CLAUDE.md, an unsourced numeric citation in LAW-3.1.

**Step 1 — 5W:**
- *Who* — future Claude reading x.md and CLAUDE.md from a cold start.
- *What* — replace stale §9; remove dead `goland`; drop unsourced scores from LAW-3.1.
- *Where* — `.claude/commands/x.md` (§9 + LAW-3.1) + `CLAUDE.md` (MCP-server summary line).
- *When* — before next `/x` invocation consumes stale content.
- *Why* — §9 should teach §3 by example; the other two are correctness fixes (config drift + unverifiable provenance).

**Step 2 — Solution space** (§9 only; the other two edits are structurally forced):
- **A.** Refresh existing narrative with the most-recent task.
- **B.** Replace with a generic template demonstrating §3.
- **C.** Replace with THIS turn as a self-demonstrating example.
- **D.** Do nothing (baseline).

**Steelman + counter-example.** Strongest case for **C** — the reader experiences §3's algorithm *in the consumption*, not abstractly. Counter-example check: a reader hostile to meta-recursion; mitigation = clearly label as a worked example. **A** rejected — §9-as-history has gone stale twice already; this would be the third stale narrative.

**Step 3 — Invariants checked** before editing: `.mcp.json` confirmed to omit goland (verified prior turn); §9 boundaries identified; CLAUDE.md target line located.

**Step 4 — Reductive minimization.** CLAUDE.md = 8-character delta. x.md §9 = body replacement only. x.md LAW-3.1 = drop one parenthetical. No section renumber.

**Execute.** Three parallel `Edit` calls; verify with `grep` post-edit. No `tool_x_*` artifact written — operating slug-only since no TSK-id supplied (per cardinal rule §1).

A Flat-L2 spawn for three-line mechanical edits with forced answers would be V-SOLO-3 over-engineering. Solo-Director is structurally correct.

---

## 10. LAW-4 — Commit discipline (Director-only, dedicated, contextualized)

> **LAW-4 (inviolable, mirrored in CLAUDE.md).** Each X-Task ends in exactly **one** git commit, made by the Director only, at the moment `tool_x_complete` (Z-n) is written.

**The four sub-rules:**

| Rule | What it forbids | What it requires |
|---|---|---|
| **One commit per X-Task** | Multiple commits for a single task slug | Exactly one commit, made at Z-n |
| **Director-only** | Peer agents (Venus / Mars / Apollo / Pluto) calling `git commit` | The Director is the sole committer; peers leave changes in the working tree for ratification |
| **Complete context** | Bare-subject commits with no audit-trail references | Body MUST cite task slug, the Z-n complete entry, and at minimum the locked D-n decisions + Y-n report |
| **No mid-task commits** | `git commit` during EXECUTE before Z-n | Hold the working-tree state until the task completes |
| **No bundled commits** | One commit spanning two distinct X-Tasks | If two tasks finish, two commits |

**Commit message template:**

```
<type>(<scope>): <subject>

Task: <slug>
Phase: Z-<n> complete
Decisions: D-1, D-3, D-5
Learnings: L-2
Report: Y-1

<short body — the WHY of the change. Reference dev/tasks/<slug>/decisions.md etc. for the WHAT.>
```

**Why this composes with LAW-1a.** LAW-1a says the Director MUST NOT call `Edit` / `Write` on implementation files; peers do that. LAW-4 says the Director IS the committer. Together: **peers write code, Director ratifies via a single contextualized commit.** Clean separation of execution from ratification.

**Solo-Director note.** In Solo mode, the same context plays both Director and implementor — LAW-1a doesn't apply, but LAW-4 still does. One Solo turn → one Z-n → one commit. No mid-turn commits, no bundled commits.

**Pre-commit invariants the Director must check:**
1. Z-n complete entry exists (`grep -q "^## Z-${n}" dev/tasks/<slug>/complete.md`)
2. At least one D-n decision is locked
3. Working tree contains only changes attributable to this task — review **both** `git status --short` (unstaged) **and `git diff --cached --name-only` (already-staged)**
4. Commit message body references real audit artifacts (no fabricated D-n / L-n / Y-n IDs)
5. **Nothing pre-staged sneaks in.** `git diff --cached --name-only` shows ONLY this task's files. In a shared tree the operator may stage unrelated batches out-of-band, and `git commit` commits the whole **index**, not just what you `git add`-ed — so a bare commit can bundle foreign staged files (real incident: an F5.9 commit swept 313 pre-staged `html/` renames → 316 files instead of 3). If foreign files are staged, commit only your paths with a **pathspec commit** (`git commit -F msg -- <exact paths>`); recover a botched bundle with `git reset --soft HEAD~1` then the pathspec commit (this preserves the operator's staging).

---

## 11. Evaluator rigor — defeating the drift and the rubber-stamp

Two recurring failure modes the F5/F6 ladder exposed, with the practices that close them. The verification value is **front-loaded**: most novel catches happen at reconcile/review, *before* the Evaluator runs — so the Evaluator's job is to *license confidence that none remain*, which is harder than finding bugs and is where a rubber-stamp hides.

### 11.1 `/reconcile` — the spec↔code differ (kills surface drift)

The #1 unguarded defect is spec-vs-code drift: a brief claims a surface the code lacks (INVENTED) or the code drifts from the spec (STALE) — gates check presence, not *correspondence*, so it ships (F5.8/F5.9 14-delta; the F6.1 unreachable-422, caught only by a manual `@spec` read). The **`/reconcile <rung>`** skill mechanizes the catch: extract every `Module.fun/arity`, return shape, struct field, tree child, "Touched files" path, and code-asserting invariant from the spec triad; probe the code (grep/AST/`mix xref`/`@spec`); emit a delta table (MATCH/STALE/INVENTED/MISSING/DEFERRED); a rung is build-grade iff every claim is MATCH or DEFERRED.
- **Wire-in:** in Flat-L2, **Venus runs `/reconcile <rung>` as step 1** (pre-build → catches INVENTED) and **Apollo runs `/reconcile <rung> post`** at close (→ catches as-built drift). The lag-1 discipline becomes an executable gate, not a remembered practice.

### 11.2 Evaluator charter (kills the rubber-stamp)

An all-PASS verdict is indistinguishable from a lazy-PASS, and a green suite that stays green under mutation is decorative. Every Evaluator (Apollo) verdict MUST report:
1. **the prompted-checks table** — the Director's listed probes, each PASS/FAIL with `file:line` evidence;
2. **≥1 un-prompted finding** — or an explicit "swept dimensions X, Y, Z; clean" — because the Director's checklist encodes the *Director's* blind spots, and the highest-value finding is the one nobody asked for;
3. **≥1 attack that held** — a concrete refutation attempt that *failed* (proof the stance was adversarial, not confirmatory);
4. **a mutation kill-rate**, not pass/fail — N mutants introduced, M killed; the **survivors are the to-do list** (a green test that survives its mutation is named and FAILED).

### 11.3 Risk-tiered, perspective-diverse verify

One Evaluator covers correctness well and other lenses thinly. Tier the rung:
- **Standard rung** → one Apollo (correctness lens) + the §11.2 charter.
- **Web / auth / data / deploy rung** (e.g. F6.1, F6.3, F6.8) → **perspective-diverse verify**: a correctness-Apollo AND a security/ops-Apollo (session secrets, CSRF, secure headers, secret handling, runtime config), each a distinct context. A front door verified only for correctness ships its security gaps.

Boundary claims ("the web names only the facade") are proven by **`mix xref`/call-graph**, not string-grep alone — an alias can dodge a grep, not a compile-time edge.