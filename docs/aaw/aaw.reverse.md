# AAW — the reverse playbook (retrospective specification)

> How AAW solves the reverse task: production code exists, no spec does. The playbook derives the roadmap and
> the specifications **from** the tree — every cited surface verified at its source — then maps every
> invariant to a running check and hardens the gaps with the lead-team until the invariants are met. The
> forward direction's contract ([specs.approach.md](../elixir/specs/specs.approach.md)) still owns the
> templates and the traceability chain; this playbook defines what reverses, what survives, and the gates the
> reverse direction adds.

## When this mode applies — and what inverts

Use reverse mode when working code ships without a spec system: a vendored library, an inherited service, a
production app that grew faster than its documents. In the delta-taxonomy vocabulary of
[aaw.rules.md](aaw.rules.md), everything begins **MISSING** — the code has it, no spec names it — so the code
is the only authority for surface facts, and the spec is *derived*, not implemented.

Three things invert from forward mode; everything else survives.

1. **Canonicality.** The code wins on as-built surface facts: names, arities, key shapes, return types,
   runtime topology. The spec records; it never redesigns. An intent-level doubt — "this looks wrong on
   purpose" — is a recorded delta for the Operator, never a silent correction in either artifact.
2. **The build brief becomes a verify brief.** There is nothing to implement; the agent brief's job is to
   ground, confirm, and harden. Its comprehensive prompt is a grounding-and-hardening prompt, not a build
   prompt.
3. **Done means proven, not built.** A reverse rung closes when every documented surface is confirmed
   present and every invariant maps to a check that actually runs — or to an explicitly recorded gap.

## The workflow

Seven stages. Stages 1–5 are the fan-out formation; stage 6 is the lead-team; stage 7 closes the loop on the
framework itself.

1. **The survey wave** (researchers; read-only; fan out wide). Build the verified inventory: module →
   public function → **arity** → `file:line` → one-line behavior, plus the artifact taxonomies the target
   carries (scripts, keys, schemas, test files and their tags). Cross-check the surveyors against each other:
   a surface one cites and another contradicts is unverified — probe it in source. No inventory claim is
   trusted untested, including the orchestrator's own bank: in the first run of this playbook, a module
   *file* that never existed survived one survey and died only at the adversarial design review.
2. **The ladder design** (orchestrator — never delegated). Cut the as-built system into rungs. The code's
   module boundaries are evidence, not the answer: a rung is one coherent subsystem a maintainer would reason
   about in one pass. A **cross-cutting concern** — implemented as threads through several modules with no
   module of its own — gets a named invariant on the index, not a rung.
3. **The senior instruments** (orchestrator). Author the chapter index (the as-built ladder, the
   target-intrinsic master invariant, the as-shipped error vocabulary, per-rung abstracts), the roadmap (the
   reconcile-and-harden plan with its iteration table), the **progress record** (mandatory — it will carry
   the verification notes, the delta records, and the invariant→check table; it is the run's durable memory),
   and the exemplar rung triad the fan-out copies.
4. **The triad fan-out** (authors; at most two concurrent, the heaviest rung alone). Each author applies the
   exemplar's template to a fixed, grounded brief. The brief carries only verified inventory facts — the
   brief is not exempt from no-invent — and the author cites every surface as `module.fun/arity` with its
   `file:line`.
5. **Adversarial grounding verification** (domain experts; read-only; may widen moderately). Independent
   experts re-verify every triad against the tree: no invented surface, exact arities, resolvable
   `file:line`, real script/key names. Convergence is the bar — a claim is verified when two independent
   checks agree; a disagreement is probed in source. Findings land in the progress record as taxonomy deltas;
   an INVENTED or STALE loops back to stage 4 **before** any hardening.
6. **The invariant→check hardening loop** (lead-team). First, md-first: write the table — every invariant ×
   the check that pins it (`test file:line`, property, tag) or the explicit gap. Then triage the gaps with
   the Operator (scope is an Operator decision made *before* this stage: record-only · tests/docs ·
   production code), author the hardening runbook, and run the lead-team pipeline on the target tree until
   the chosen gaps close — each hardening rung gated, verdict-graded, and committed by the Director as one
   pathspec commit. A genuinely failing invariant — the code violates a property it should hold — is a
   defect finding: the Operator decides fix-now (a lead-team rung) or record-and-defer.
7. **The fold-back** (orchestrator). The run's findings sharpen the framework: a workflow stage that
   misfired, a template section that fought the mode, a gate that missed — each folds into this playbook or
   [aaw.rules.md](aaw.rules.md) as an inspect-and-adapt edit. A framework that runs its own retrospective is
   the point.

## The reverse triad — what re-keys, what survives

The triad keeps the forward shape — same files, same section count, same traceability ids — so the structure
gates pass unforked. Two sections re-key their *semantics*, marked by a parenthetical in the heading; the
heading words themselves stay.

| Forward section | Reverse semantics |
| --- | --- |
| Goal | unchanged — "after this rung, subsystem X is specified and its invariants proven against the as-built code" |
| Rationale (5W) | unchanged — **Where** names the as-built modules and files; **When** is the rung's place in the verification ladder |
| Scope (In/Out) | unchanged — Out defers surfaces to the rung that owns them, same dependency discipline |
| Deliverables → `## Deliverables (Surfaces — as-built)` | each `<RUNG>-S#` is an as-built surface: `module.fun/arity` — `file:line` — one-line behavior. Nothing is created; everything is located |
| Invariants | unchanged in form — properties the as-built code holds (or must hold); each will map to a check in stage 6 |
| Definition of Done → `## Definition of Done (Verification)` | checkboxes close on proof: every surface confirmed present · every invariant mapped to a running check or an explicit recorded gap · expert verification convergent · links resolve |

- **`.stories.md`** survives nearly intact: the role becomes the maintainer/operator of the system —
  *"As a maintainer, I want subsystem X's behavior pinned by a running check, so that a refactor cannot
  silently break it."* Given/When/Then states **observed** behavior. The INVEST line still ends in
  `encodes <RUNG>-INV#`; the Coverage line maps `S#→US#`.
- **`.llms.md`** becomes the **reconcile/verify brief**: References list the as-built modules, scripts, and
  test files (with the chapter index and this playbook); Requirements are **grounding assertions** — each
  `R#` a checkable claim about as-built behavior, traced `[US: …]`; Execution topology renders the
  **as-built runtime topology** (the processes and timers that exist now) plus a **verification DAG** (the
  order to confirm surfaces and run checks) and a `Touched files:` line naming the rung's own spec files and
  the progress record; Agent stories are verify/harden stories, each `[implements …]` with a Directive
  ("confirm…", "map INV# to…", "add the property test for…") and an Acceptance gate that runs; the closing
  fenced block is the **comprehensive grounding-and-hardening prompt**.

## The added gates

Reverse mode adds four gates on top of the standard six (voice · structure · traceability · fences · links ·
format, owned by [specs.approach.md](../elixir/specs/specs.approach.md)):

- **Grounding** — every cited artifact (module, function, script, key, test) exists in the tree.
- **No-invent** — no surface appears in a spec that is absent from the verified inventory; a brief or spec
  naming a surface the inventory lacks is itself the defect.
- **Exact-arity** — every function citation carries its true arity, read from the `def` site, never inferred
  from a call site or a doc table.
- **file:line-resolves** — cited locations spot-check true against the current tree (line drift within a
  hunk is tolerated and re-pinned; a citation into a nonexistent file is INVENTED).

Three conventions earned by the first executed run (the EchoMQ-core chapter, 2026-06-10):

- **Cross-boundary semantics are verified at the boundary, not on one side.** A result-shape claim about a
  script must be validated against the runtime's conversion rules (Redis truncates a Lua `{nil,nil}` table
  to an empty array; integers coerce), never against the script source alone — one side of the wire is not
  the wire.
- **A hardening rung creates new observation surface — expect new findings.** The first gate that COMPLETES
  (a test suite that previously never terminated) observes states no prior run could; a latent defect
  surfacing there is a finding credited to the rung, recorded as a delta with its own disposition fork —
  never a regression blamed on the rung that exposed it.
- **Post-hardening line drift is recorded, not rewritten.** When the rung's own edits shift later line
  numbers, the affected triads carry one dated drift note (citations are pre-rung anchors, valid against
  `<commit>^`; the post-rung homes live in the run record) and only the live index row is refreshed — a
  mass re-pin of historical citations is churn, not fidelity.

## Template — the reverse spec, compact

```text
# C-N · <subsystem name> (as-built)
> <one-sentence: what this subsystem is, in the running system>

## Goal
<subsystem specified; invariants proven against the as-built code>

## Rationale (5W)
- **Why**   — <why this subsystem must be pinned>
- **What**  — <the as-built capability being specified>
- **Who**   — <maintainer / operator / consumer roles>
- **When**  — <place in the verification ladder; depends on C-…>
- **Where** — <the as-built modules and files; the boundary respected>

## Scope
- **In**  — <the surfaces this rung specifies>
- **Out** — <surfaces owned by other rungs, named>

## Deliverables (Surfaces — as-built)
- **C-N-S1** — `Module.fun/arity` — `path/to/file.ex:L` — <one-line behavior>

## Invariants
- **C-N-INV1** — <property the as-built code holds>

## Definition of Done (Verification)
- [ ] every surface confirmed present at its cited location
- [ ] every invariant mapped to a running check (file:line) or an explicit recorded gap
- [ ] expert verification convergent (two independent confirmations)
- [ ] links resolve; gates pass

Stories: ./c-n.stories.md · Agent brief: ./c-n.llms.md · Index: ./core.md · Playbook: <relative path to this file>
```

## References

- The framework definition: [aaw.framework.md](aaw.framework.md) · the rules and the delta taxonomy:
  [aaw.rules.md](aaw.rules.md).
- The forward contract the triad shape conforms to: [specs.approach.md](../elixir/specs/specs.approach.md).
- The "code wins" precedent: [redlock](../elixir/redlock/redlock.md) — "where this chapter and the running
  code disagree, the code wins and the spec is corrected."
- The reconcile machinery, in code form: `.claude/commands/reconcile.md` (the bidirectional differ whose
  post-build direction this playbook generalizes).

---

Index: [aaw.md](aaw.md) · Definition: [aaw.framework.md](aaw.framework.md) ·
Rules: [aaw.rules.md](aaw.rules.md) · Roadmap: [aaw.roadmap.md](aaw.roadmap.md)
