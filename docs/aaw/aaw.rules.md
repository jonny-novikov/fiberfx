# AAW — The Rules of the Game

> The normative companion of [aaw.framework.md](aaw.framework.md): the fences, formations, laws, gates, and
> taxonomies that govern play. Every rule here was earned by a shipped rung and cites where it is defined or
> where it fired; none is aspirational. Where a rule and the evidenced practice disagree, the practice wins
> and the rule is corrected — these rules describe the game as it is actually won.

## How to read these rules

Rules are stated in the imperative; the named sources are the defining authorities (one authority per fact —
this document quotes and links, it does not re-own). Repository paths in code form (`.claude/commands/x.md`,
`.claude/agents/venus.md`) name tool-configuration sources of record; links point only at documents. The
templates, the traceability chain, and the completion rule live in
[specs.approach.md](../elixir/specs/specs.approach.md) and are not restated here.

## The roles and their fences

A role may edit only what its fence allows. The durable discipline lives in the agent charters
(`.claude/agents/*.md`); a spawn prompt carries only the rung's delta — that asymmetry is what makes the
framework cheap to run, and why mentoring folds lessons into the charter rather than into any one prompt.

| Role | Owns | Edits | Never |
| --- | --- | --- | --- |
| Operator (human) | intent, priorities, acceptance; every architecture / API-contract / new-dependency / routing decision; the go/no-go | the decision record; out-of-band commits | writes a page or the code; lets a green gate substitute for reading the work |
| Director (orchestrator) | scope lock, briefs, stage gates, ratification; the lead-team rung commit; the program corpus (epics · kb) | briefs, runbooks, progress records; shared manifest/landing files (orchestrator-only relink) | implementation files once a team is spawned; grading its own build |
| Spec-steward (Venus) | the pre-build reconcile + the build-grade brief | the spec triad only | implementation files; deciding a fork (it surfaces forks) |
| Implementor (Mars) | the build, then the hardening pass | code + tests only | the spec triad (feedback routes through the steward); inventing an arity, struct, route, or return; `git commit` |
| Verifier (Apollo) | the post-build reconcile, independent gate re-run, the verdict; the process guide and retrospective; mentoring | spec triad + tests, `*.operator.md`, the retrospective; peer charters only as Director-ratified proposals | production code; softening a verdict because the fix is obvious; `git commit` |
| Fan-out authors (spec-author, domain experts) | one page or one rung triad each, from a fixed design | only their assigned files | the shared landing/TOC/index (orchestrator-only); designing the rung; any git |
| Researchers (Explore) | read-only survey; verified inventories | nothing | writes of any kind |

**The guardrail rule.** A recurring finding becomes one named guardrail line in the responsible charter,
cited to the rung that earned it. A finding that recurs despite its guardrail proves the guardrail is
mis-worded — sharpen the existing line; never stack a second on top. Aim a guardrail at the peer whose
*contract* the finding implicates, not the peer who typed the defect.

## The two formations

One game, two formations; the deliverable type decides.

- **The lead-team** (production code): a sequential six-stage pipeline — steward reconcile + brief →
  implementor build → implementor harden → verifier verdict → Director ratify + commit → Director feedback
  fold — run as a true registered team, Director-in-loop at every stage gate. "Sequential" is the Director
  holding the gate: the next stage is not spawned until the current peer's report has arrived and the gate
  has passed. Within a stage, read-only analysis may fan out; the build itself is single-threaded.
- **The fan-out** (content and specs): the orchestrator senior-authors the design — the chapter docs, the
  exemplar, each rung's fixed deliverables and invariants — then fans the mechanical application to parallel
  authors in waves, then adversarially gates everything and relinks the shared files itself. Decisions are
  never delegated; template application always is.

A reverse-mode run composes both: the fan-out authors and verifies the derived specs; the lead-team executes
any hardening that edits the target tree.

**Formation availability (earned 2026-06-10, the first reverse run):** when the team-registration tooling is
not available in a session, the lead-team runs as real spawned peer agents — separate execution contexts
under their charters, the Director holding every stage gate — and the runbook records that formation
honestly. The substance of LAW-1 is real spawns, not registration ceremony; claiming a registered team
without the tooling would be the actual violation.

## The events: rules of the cadence

- **The rung pipeline gates** (lead-team): no stage advances past an open fork; a build advances only
  compiling clean with the diff inside the boundary; a hardening pass advances only with the gate green and
  the boundary grep empty; a verdict advances only at BUILD-GRADE with survivors triaged; the commit lands
  only with the audit trail complete.
- **The lag-1 reconcile** is an executable gate, not a remembered practice: before a build, the steward
  reconciles the spec against the code it depends on (catching invented surfaces); after a build, the
  verifier reconciles the spec against what shipped (catching drift). A spec written ahead of its
  dependencies stays honest by carrying explicit `[RECONCILE]` deferral markers.
- **Md-first checkpointing.** Durable markdown lands before or alongside heavy work, so a reaped or
  timed-out agent's progress is recoverable from the tree. An agent timeout is a recoverable event; the
  working tree, not any report, is the source of truth.
- **Concurrency asymmetry.** Exploration (read-only survey) fans out wide. Heavy authoring runs at most two
  agents concurrently, and the most complex unit runs alone. Read-only verification may widen moderately.
  Load-sensitive gates — determinism loops, liveness probes — run uncontended: concurrent heavy load has
  produced failures that reproduce no other way (the F6.8.1 restart-storm and wall-clock-skew breaks fired
  only under contention).
- **Concurrent-wave siblings are not cross-linked.** A link into a sibling that another agent is authoring
  in the same wave is deferred and restored by the orchestrator after the wave lands.
- **Standing runtime state** lives in the Operator's session or the deploy — never in a spawned agent. An
  agent's processes are reaped at turn end; its sole reliable handoff for a running system is the one-line
  boot command.
- **Commit rules.** Always pathspec commits (`git commit -F msg -- <paths>`); never `git add -A`; never a
  bare commit (a bare commit has bundled hundreds of foreign pre-staged files). Lead-team: exactly one
  scoped commit per rung, made by the Director at close. Fan-out: agents and the orchestrator run no git at
  all; the Operator commits batches out-of-band at natural boundaries, and the tree may go clean between
  turns.
- **The corpus instrument (Epics).** A cross-cutting body no single rung owns — a command catalogue, a
  knowledge base — lives as an **Epic**: a thin index (`<epic>.md`) + per-feature slices under a `#{…}`
  cross-reference grammar, one authority per fact, loaded one slice at a time (never a monolith).
  Git-controlled and Director-owned; the program's operating manual + agent calibrations live at the program
  level (not under `specs/`, which holds triads). Earned by emq (the 1290-line catalogue that had no per-rung
  home — `emq.epic.0`).

## The LAWS

Defined in `.claude/commands/x.md` and the operator guides; quoted verbatim where the law is one line.

- **LAW-1.** "Each registered identity MUST be backed by a real spawned subagent — a separate execution
  context, not role-play."
- **LAW-1a.** "Once the team is spawned, the Director MUST NOT call `Edit` / `Write` on implementation
  files."
- **LAW-2.** "All peers run on fable." *Dated divergence note (2026-06-10):* four authoring charters now pin
  `model: fable`, and the lead-team path spawns general-purpose peers with the charter applied via prompt —
  the law's intent (one consistent, strongest-available model per peer) stands. *Operator revision (2026-07-02):*
  the law's letter now names `fable` (Fable 5), reconciling it with the charters.
- **LAW-3.** Emitted prose — prompts, comments, specs — carries no gendered pronouns for agents, no
  perceptual or interior-state verbs applied to software, no first-person narration, and propagates this rule
  to every downstream prompt.
- **LAW-4.** "Each X-Task ends in exactly one git commit, made by the Director only" — at the moment the
  completion record is written; never mid-task, never bundled with foreign changes.
- **FAKE-N and the V-SOLO family.** Registering N identities without N real spawns, registering then working
  alone, ceremony with zero delegation, or a Director editing implementation files after spawning a team —
  each rejects the execution. The team must be real or must not be claimed.

## The gates

- **A check counts only if it RUNS.** The deepest gate principle, earned repeatedly: an inert doctest; a
  liveness claim while the port was dead; a CSS `clamp()` that parsed as invalid and silently dropped 204
  pages to user-agent defaults; a release that crashed where the test suite was green; a deploy that failed
  where the local boot succeeded; a mutation harness that ran zero tests and reported a pass. Corollary:
  climb the tier that exposes the fault the one below hides (unit → suite → boot → release → deploy).
- **The verifier reproduces the gate.** A green run reported by the builder is one piece of evidence, not a
  passed gate; the verifier re-runs it independently — and audits its own harness, because a wrong harness
  forges false passes.
- **The anti-rubber-stamp charter.** Every verification verdict carries: the prompted-checks table (each
  PASS/FAIL with `file:line`), at least one un-prompted finding (or the named sweeps that came back clean),
  at least one attack that held, and a mutation kill-rate rather than a pass/fail — the survivors are the
  to-do list.
- **Gate sets are owned by their deliverable** and referenced, not restated: spec-system gates (voice ·
  structure · traceability · fences · links · format) in [specs.approach.md](../elixir/specs/specs.approach.md);
  course-page gates in each course's authoring guide; build gates in each chapter's roadmap. Reverse-mode
  work adds the grounding gates defined in [aaw.reverse.md](aaw.reverse.md).
- **Voice.** Plain, specific prose. The forbidden set — `revolutionary`, `blazing fast`, `magical`, `simply`,
  `just`, `obviously`, `effortless` — plus: no first person outside a story's Connextra "I want", no
  exclamation marks or emoji, no perceptual or interior-state verbs applied to software (a function does not
  "see", "want", or "decide").

## The two directions and the delta taxonomy

The reconcile pass diffs spec against code and classifies every claim; the taxonomy is the shared vocabulary
of both directions (defining source: `.claude/commands/reconcile.md`).

| Delta | Meaning | Resolution |
| --- | --- | --- |
| **MATCH** | spec claim == as-built | none |
| **STALE** | spec says X, code says Y | pre-build: correct the spec · post-build: route the code fix to the implementor |
| **INVENTED** | spec references a surface that does not exist | correct the spec — or build the surface if in scope |
| **MISSING** | code has it, the spec omits it | add to the spec, or mark out of scope |
| **DEFERRED** | the claim carries a `[RECONCILE]` marker + reason | allowed — the lag-1 discipline |

**Direction-dependent canonicality.** Pre-build, the spec body wins: it is the contract, and code-facing
claims are corrected to it. Post-build, the code wins on as-built surface facts: the verifier syncs the spec
body to record what shipped — but only to record, never to redesign; an intent-level divergence is a STALE
surfaced to the Operator, never a silent sync. In reverse mode, where no spec yet exists, everything begins
MISSING and the code is the only authority for surface facts.

**The verdict.** A rung is **BUILD-GRADE** iff every promise is MATCH or an explicit `[RECONCILE]`-marked
DEFERRED; any STALE, INVENTED, or MISSING **BLOCKS** until corrected. A BLOCKED rung stays BLOCKED even when
the one-line fix is obvious — the fix routes through the pipeline; the grade does not move. The taxonomy's
deterministic core (grep, AST, cross-reference) is unrationalizable: judgment never overrides a deterministic
MISSING or INVENTED.

## Feedback, mentoring, and the retrospective

- **Feedback edits the spec** — never the code directly, never a derived artifact on its own. Route a change
  through the spec and the next rung rebuilds correctly; route it around the spec and the spec and code fork.
- **Process feedback edits the agent definition and the retrospective** — the durable channel. Charter edits
  are propose-only from the verifier, applied by the Director under an explicit Operator grant; the harness
  fences self-modification of charters, and that brake is respected, not worked around.
- **The retrospective** is written per rung into the chapter's progress record, with six recurring
  sub-sections: *Went exceptionally well · Went well · Went not well · Opportunities to improve (process) ·
  Gaps carried forward · Spec & agent-definition refinements* — closed by a distilled chapter-level lesson.
- **Dashboards report; specs define.** A status board may lag the source of truth and says so; the specs and
  the roadmap reconciled at rung-close are authoritative.

## Decisions

Every deliberately deferred choice is a **named decision** in the roadmap's "Seams & open decisions" — a
decision, not a surprise. The Operator's decision rights are absolute over: architecture, public API
contracts, new dependencies, routing identity, hardening scope, the accept/iterate call, and mentoring
grants. An agent that meets an unsettled fork stops and surfaces it with alternatives; it does not pick.

## References

- The definition this document constrains: [aaw.framework.md](aaw.framework.md).
- The reverse-mode playbook: [aaw.reverse.md](aaw.reverse.md).
- The forward contract (templates, traceability, completion): [specs.approach.md](../elixir/specs/specs.approach.md).
- Defining sources of record, in code form: `.claude/commands/x.md` (the LAWS, the audit ledger),
  `.claude/agents/{venus,mars,apollo}.md` (the charters and their guardrails),
  `.claude/commands/reconcile.md` (the delta taxonomy), `docs/elixir/specs/phoenix/phoenix.operator.md` (the
  operator's field manual), `docs/elixir/specs/phoenix/f6.progress.md` (the retrospective form and the
  mentoring ledger).
- The "code wins" precedent for reverse canonicality: [redlock](../elixir/redlock/redlock.md).

---

Index: [aaw.md](aaw.md) · Definition: [aaw.framework.md](aaw.framework.md) ·
Reverse: [aaw.reverse.md](aaw.reverse.md) · Roadmap: [aaw.roadmap.md](aaw.roadmap.md)
