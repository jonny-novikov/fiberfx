# EMQ.3.3 · the DESIGN-AUTHORING runbook — author the cross-queue-flow quad (the flow family's third slice)

> **Status: the design-authoring runbook (emq.3.3 has NO triad yet — this commissions it).** This is **NOT** a
> build runbook: it fans out a future **Venus (+ Director)** to **AUTHOR** the emq.3.3 spec quad
> (`emq.3.3.{md,stories.md,llms.md}` + a subsequent `emq.3.3` build runbook) for the **cross-queue flow** — the
> slot-boundary crossing the emq.3 carve routes here. The deliverable of the cycle this runbook drives is the
> **quad + the cross-queue ADR**, never code; the build is a later, separate run off the authored
> `emq.3.3.prompt.md` (the build runbook the authoring cycle produces). Mirror this structure on the
> as-built floor; ground every claim NO-INVENT in [`./emq.3.md`](../emq.3.md) (the carve's **emq.3.3 row** +
> **Fork A's cross-queue arm**) + the as-built emq.3.1/3.2 flow surface + the v1 cross-queue reference
> (`echo/apps/echomq/lib/echomq/flow_producer.ex`). **The `echo-mq-architect` skill is the binding** (the
> authoring Venus loads it; the program law is `.claude/skills/echo-mq-program.md`).

## The family in one paragraph

emq.3 is the parent/flow family — the v1 `flow_producer` capability redesigned so a parent becomes claimable
only when its children complete (fan-in), **under the v2 A-1 declared-keys law**. The dependency graph rides
**declared §6 subkeys of the parent** (`emq:{q}:job:<parent>:dependencies` the outstanding-child counter +
`:processed` the completed-children HASH), each rooted at the parent's declared job key, on the parent's `{q}`
slot, A-1-clean by construction. The family carves into emq.3.1 (single-queue, **SHIPPED** 2026-06-15) · 3.2
(child-result reads, **BUILT + Stage-2 PASS** 2026-06-15, O1 closed) · **3.3 (cross-queue)** · 3.4
(failure-policy + bulk). The full design + the surfaced forks are [`./emq.3.md`](../emq.3.md). **Fork A was RULED
single-queue-first** (Operator 2026-06-14) — so the cross-queue *mechanism* is **emq.3.3's design work**: the
sequencing is settled, the mechanism is not.

## The rung in one paragraph (what emq.3.3 WILL carve — to be authored)

emq.3.3 carves the **cross-queue flow** — a parent and its children in **DIFFERENT queues** (the v1 shape: a
parent in `orders`, children in `validation`/`inventory`/`payments`). Under the v2 braced keyspace each queue is
a **different cluster slot**, so a child's completion **cannot atomically reach** the parent's other-slot
`:dependencies` counter — **no single Lua script** spans both (S-1/§6, the braced-keyspace slot constraint).
The carve routes this to a **completion-signal hop** (Fork A, Arm A — RULED): when a cross-queue child
completes, the decrement is delivered by a **second mechanism** — a per-queue **promote-style sweep** that reads
a declared "parent-waiting" signal and decrements the parent **on the parent's slot** (the `EchoMQ.Pump`/promote
precedent — work crosses a boundary by a sweep, **never** a cross-slot transaction), giving
**eventually-consistent** fan-in across queues (stated honestly — INV7: explicitly NOT "atomic across queues").
Conformance: **`flow_cross_queue`**. The exact mechanism (the signal-key shape, the sweep cadence/trigger, the
crash-recovery window, the shipped-script touch) is **genuine new design** — the forks the authoring Venus must
**surface, not decide**. The family contract is [`./emq.3.md`](../emq.3.md) (INV7 the cross-queue honesty).

## Mode

**Design-authoring cycle** (Director + Venus — **no Mars/Apollo this cycle; the deliverable IS the spec quad**),
the [`./emq.3.2.prompt.md`](emq.3.2.prompt.md) design-cycle precedent (its T-1..T-3 grounding + ADRs preceded
the build) and the venus-charter **Design-Phase** clause (a SYSTEM-founding spec → the architectural design +
ADR set comes FIRST, the triad derives from the approved design — authored solo by Venus, never the
Director/orchestrator; the V-SOLO-4 law). Because emq.3.3 founds a genuinely new mechanism (the cross-slot
completion signal + the sweep), the cycle **opens with a design-make stage** (the cross-queue ADR + the surfaced
forks) **before any triad is locked** — exactly how emq.3.2's design cycle preceded its build.

Scope slug: **`emq-3-3`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/emq-3-3.progress.md` (this cycle
opens it — the Stage-0 grounding, the ADR derivation, the surfaced forks, the locked decisions, the quad-authored
report; the build run continues it).

## The deliverable — the emq.3.3 spec quad + the cross-queue ADR (docs/echo_mq/** ONLY)

The authoring cycle produces, grounded NO-INVENT in the carve + the as-built flow surface + the v1 reference:

- **The cross-queue ADR (FIRST — the design-make stage).** Context (the slot-boundary constraint: a parent and
  a cross-queue child are on different slots, no atomic single script — S-1/§6) → the surfaced forks below, each
  with ≥2 steelmanned arms + costs + a recommendation (an architecture choice without an ADR BLOCKS the phase)
  → the decision the Operator rules → the consequences (what each arm forecloses). Recorded in the ledger + the
  `emq.3.3.md` body's design section. The **eventually-consistent** fan-in model (INV7) is stated honestly,
  never pretended atomic.
- **`emq.3.3.md`** (the contract — authored to the v2 laws): §0 (the slice — why third, after the single-queue
  core + the reads) · Goal · 5W · Scope (In: the cross-queue add + the completion-signal hop + the sweep + the
  recovery; Out: the failure-policy reads → emq.3.4, bulk → emq.3.4, deep-recursion grandchildren if the ADR
  bounds it) · D-n (the deliverables, each forward-named) · INV-n as runnable checks (the headline: **INV7 the
  cross-queue honesty** — the contract states its consistency model explicitly, no "atomic across queues" claim;
  + the A-1 declared-keys law over the new signal-key + sweep scripts; + the additive-minor conformance growth
  `46 → N`) · the surfaced forks · the honest bounds · DoD.
- **`emq.3.3.stories.md`** (the acceptance face): US-n Connextra + Given/When/Then (name the observable — a
  cross-queue child completes → the parent is released **on the next sweep tick**, eventually-consistent, never
  "immediately"; the crash-recovery window → the at-least-once recovery proves the parent is **eventually**
  released even if a signal is dropped) + INVEST + the standing **`EMQ.3.3-US-GATE`** Valkey gate + the Coverage
  map (every D-n → ≥1 story).
- **A subsequent `emq.3.3` build runbook** (the build-orchestration prompt — the [`./emq.3.2.prompt.md`](emq.3.2.prompt.md)
  form, but **HIGH-risk**: Apollo MANDATORY + the ≥100 loop). *(Either authored at the close of this cycle, or
  the cycle's report names it as the immediate next authoring step — the Director's call.)*

## The surfaced forks — Venus surfaces, the Operator rules (the design-make stage's output)

The cross-queue mechanism has genuine open wire-shaping decisions. The authoring Venus **records each (Arm 1 /
Arm 2, costs, a RECOMMENDATION) and flags it to the Director for the Operator's gate** (the §11.12 escalation
protocol + the surface-the-fork law) — **decides none**. Ground each in the carve + the as-built surface; the
quad is authored to the recommended arms so the build is build-ready, the forks marked OPEN.

- **The signal-key shape.** A declared §6 subkey (a "parent-waiting" marker the cross-queue child's completion
  writes, that the parent's-queue sweep reads) **vs** a per-queue waiting-SET (a queue-level roster of parents
  awaiting cross-queue children). Each must be **A-1-clean** (declared in `KEYS[]` or grammar-rooted — the v1
  data-value `parent_key` is NOT lifted) and **slot-sound** (the signal lives on a slot the sweep can reach).
- **The sweep cadence/trigger.** Piggyback on the **existing `EchoMQ.Pump`/promote pump** (`pump.ex` `sweep/1`
  already promotes + fires repeats per beat — add a cross-queue-flow decrement pass) **vs** a **dedicated flow
  sweep** (a separate cadence/process for the cross-queue fan-in). State the eventually-consistent latency the
  cadence implies (the parent is released on the next tick, not synchronously — INV7).
- **The crash-recovery window (the at-least-once recovery — the genuinely hard part).** A child completes, then
  the signal is dropped (a crash) **before** the sweep consumes it → the parent could hang. The recovery: how
  does the sweep **reconcile** a completed-but-unsignalled child? (e.g. the sweep re-derives outstanding deps
  from the `:processed`/`:dependencies` state on the parent's slot, idempotently — the at-least-once model.)
  This is the design's correctness keystone; name the recovery mechanism, do not hand-wave it.
- **The shipped-script touch (the HIGH-risk dimension).** The cross-queue child's **`@complete`** must **EMIT**
  the parent-waiting signal (a shipped-script edit), and/or a new `@enqueue_flow_xq` (or an extended
  `@enqueue_flow`) records the cross-queue waiting parent at add. Name exactly which shipped Lua scripts the
  build will touch — this is **why emq.3.3 is HIGH-risk** (the inverse of emq.3.2's NORMAL-risk host-only reads).

## The as-built floor (the design grounds against this — re-probe at the cycle's Stage 0, the lag-1 law)

Anchors drift; the cycle's Stage-0 reconcile re-pins every line. The design extends this surface:

- **The single-queue flow (emq.3.1, SHIPPED — the mechanism emq.3.3 extends across slots)** — `flows.ex`
  `EchoMQ.Flows.add/3` (a parent + same-queue children, atomic on one slot); `@enqueue_flow` (`SET KEYS[2] n`
  the `:dependencies` STRING counter; the parent held from `pending`); the `@complete` **fan-in branch**
  (`HSET KEYS[4] ARGV[1] ARGV[5]` + `DECR` the parent's `:dependencies` + at-zero release) — the
  **same-slot** decrement emq.3.3 must deliver **across** a slot. `awaiting_children` the held-parent row state.
- **The child-result reads (emq.3.2, BUILT — the read surface the cross-queue parent also uses)** — `flows.ex`
  `children_values/3` (`HGETALL` of `:processed`) + `dependencies/3` (`GET` of the `:dependencies` counter,
  `{:ok, 0}` sentinel); `complete/5` (`result \\ nil`, the result via the existing `ARGV[5]`). O1 closed.
- **The promote-sweep precedent (the cross-slot delivery mechanism Fork A names)** — `pump.ex` `EchoMQ.Pump.sweep/1`
  (`Jobs.promote/3` + `fire_repeats/3` per beat → `{:ok, %{promoted, fired}}`); `:tick_ms` the beat, `:batch` the
  LIMIT. The cross-queue decrement is a sweep pass in this shape (work crosses a boundary by a sweep).
- **The A-1 derivation precedent (the cross-queue scripts must be A-1-clean)** — `jobs.ex` `@extend_locks`
  (`base .. 'job:' .. id` — a per-job key derived in-script from a declared queue base root; every id gated
  `Keyspace.job_key/2` host-side before the wire). The signal-key + sweep scripts extend exactly this shape.
- **The conformance floor** — `conformance.ex` `scenarios/0` (the live count is **46** as-built post-emq.3.2:
  the emq.2 cluster → 43, emq.3.1 `flow_add`+`flow_fanin` → 45, emq.3.2 `flow_children_values` → 46; **re-probe
  the LIVE count** at Stage 0 — do NOT hardcode 46; emq.3.3 adds `flow_cross_queue` additive-minor `46 → N`, the
  prior set byte-unchanged, both pin tests re-pinned).
- **The flow-subkey lifecycle carry (still NAMED, still open — N1)** — `admin.ex` `del_job` + `@drain`'s `wipe()`
  FIXED enumerations exclude the flow subkeys (the emq.3.1 L-5 / emq.3.2 N1 carry to the emq.3.x lifecycle rung);
  emq.3.3's cross-queue signal-key joins this lifecycle picture — the authoring Venus **names** its cleanup
  disposition too (the §2 subkey-lifecycle guardrail: a new subkey NAMES what retires it).
- **The v1 cross-queue reference (READ, never edit, the FORM not lifted)** —
  `echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2` at `:123`, `add_bulk/2` at `:183`; the per-node
  `queue_name` spanning at `:25-52` — the parent in `orders`, children in `validation`/`inventory`/`payments`,
  even grandchildren cross-queue; the data-value `parent_key` tree that v2 must NOT lift).

## The pipeline — the design-authoring flow (Director + Venus; the build is a LATER run)

Each spawned stage is a real `Agent` that adopts its `.claude/agents/<role>.md` charter, LOADS its
`echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds the
gate between stages. **This cycle spawns no Mars/Apollo** (the deliverable is the spec, not code).

### Stage 0 — Venus (architect): the pre-design reconcile + the grounding

Directive: run the lag-1 reconcile (re-probe every as-built anchor above against the post-emq.3.2 tree — the
single-queue flow, the reads, the promote-sweep `sweep/1`, the `@extend_locks` A-1 precedent, the live
conformance count, the v1 cross-queue reference). Confirm **Fork A is RULED single-queue-first** (so the
cross-queue mechanism is the open design) and the emq.3.1/3.2 surface the cross-queue flow stands on. Gate: the
grounding delta table (MATCH / `[RECONCILE]`); the as-built floor the design extends; the BUILD-the-DESIGN /
BLOCKED verdict.

### Stage 1 — Venus (architect): the design-make stage — the cross-queue ADR + the surfaced forks

Directive (the venus Design-Phase clause — authored **solo by Venus**, never the Director): author the
cross-queue ADR (context → the four surfaced forks above, each ≥2 steelmanned arms + costs + a recommendation →
the decision the Operator rules → the consequences). State the **eventually-consistent** fan-in model explicitly
(INV7 — never "atomic across queues"). Name the crash-recovery mechanism (the at-least-once reconciliation) and
the shipped-script touch (the HIGH-risk dimension). **Surface the forks; decide none** — each is the Operator's
call (an architecture / wire-shaping / recovery-model fork). Gate: the ADR with ≥2 steelmanned arms per fork; the
forks surfaced to the Director for the Operator; **no fork decided by Venus**.

> **The Operator's gate (between Stage 1 and Stage 2).** The Director routes the surfaced forks to the Operator;
> the Operator rules the signal-key shape, the sweep cadence, the recovery model, and the shipped-script touch.
> The quad is then authored to the ruled arms.

### Stage 2 — Venus (architect): author the quad to the ruled ADR arms

Directive: author `emq.3.3.{md,stories.md,llms.md}` to the v2 laws + the ruled arms (the `echo-mq-architect`
craft — the triad shape, the INV-n as runnable checks, the additive-minor conformance, the §2 subkey-lifecycle
naming for the new signal-key, the A-1 declared-keys law over the new scripts, forward-tense for the unbuilt
surface, NO-INVENT grounding). Derive stories + brief FROM the body (the body authoritative). Author a subsequent
**`emq.3.3` build runbook** (HIGH-risk — Apollo MANDATORY + the ≥100 loop), or name it as the immediate next
step. Gate: the quad authored; every claim grounded; the forks marked OPEN; the **HIGH-risk** tier stated; the
Coverage map closed (every D-n → ≥1 story).

### Stage 3 — Director: closure + the records commit + the frontier fold

Preconditions: the quad authored + the ADR recorded + the forks surfaced; **≥1 `tool_x_decision` (D-n)** + a
**`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff --cached --name-only` reviewed. Then
the **pathspec** commit (below; NEVER `git add -A`). **Same turn:** flip the emq.3.3 row in the roadmap
([`../emq.roadmap.md`](../../../emq.roadmap.md)) + the dashboard ([`../emq.progress.md`](../../../emq.progress.md)) from
"design-authoring" → **SPECCED**; surface the **next frontier** (the emq.3.3 BUILD — `/echo-mq-ship emq.3.3`,
HIGH-risk; then emq.3.4 failure-policy + bulk → Movement I CLOSES). The message cites the slug, the Z-n, the D-n,
and the Y-n report.

## Risk tier (of the rung emq.3.3 will BUILD — stated so the authoring cycle carries it forward)

emq.3.3 the BUILD is **HIGH-risk** — the inverse of emq.3.2's NORMAL-risk. Two elevated dimensions: **(a)** it
founds a **new cross-slot completion signal** (the parent-waiting signal-key + the sweep that consumes it — new
mechanism, the cross-queue crossing the whole family deferred to its own rung), and **(b)** it **likely edits a
shipped Lua script** (the cross-queue child's `@complete` must EMIT the signal, and/or `@enqueue_flow` records
the waiting parent — a shipped-`@complete`-edit, the emq.3.1 HIGH-risk precedent). So the BUILD requires **Apollo
MANDATORY** + the **≥100 determinism loop** (a cross-queue flow mints parent + children across queues — the
mint-touching surface). The authoring cycle (this runbook) is **lower-risk** (it authors a spec, edits no code),
but it MUST encode the build's HIGH-risk tier into the quad + the build runbook so the build carries it. **State
this at the design-make stage:** the consistency model is eventually-consistent (INV7), the recovery is
at-least-once, the shipped-script touch is named — the three properties that set the HIGH-risk tier.

## The Stage-3 commit pathspec (Director-only — the emq.3.3 DESIGN AUTHORING, docs only)

Commit exactly the authoring cycle's measured surface (docs only — **no code this cycle**):

```text
docs/echo_mq/specs/emq.3.3.md                 (the contract — NEW)
docs/echo_mq/specs/emq.3.3.stories.md          (NEW)
docs/echo_mq/specs/emq.3.3.prompt.md           (this runbook + the LATER build runbook the cycle authors)
docs/echo_mq/specs/emq-3-3.progress.md         (the cycle's ledger — NEW)
docs/echo_mq/specs/emq-3-3.registry.json       (if the run mints one)
docs/echo_mq/specs/emq.3.md                    (the carve's emq.3.3 row → SPECCED)
docs/echo_mq/emq.roadmap.md                    (the emq.3.3 row → SPECCED)
docs/echo_mq/emq.progress.md                   (the dashboard fold)
docs/echo_mq/emq.features.md                   (the flow row → emq.3.3 specced, if touched)
```

**EXCLUDE** (Operator out-of-band — never sweep into the cycle commit): `echo/apps/**` (no code this cycle),
`echo/apps/mercury_*/**`, `html/**`, the F# course, and any
`[emq]`/`[bcs]`/`[mercury]` commits the Operator lands between stages. **Never `git add -A`.** The
authoring agents run **no git** (the Director commits by pathspec).

## Acceptance — "the design is authored" means

- The **cross-queue ADR** records the slot-boundary context + the four surfaced forks (each ≥2 steelmanned arms +
  costs + a recommendation) + the Operator-ruled decision + the consequences; the **eventually-consistent** model
  (INV7) is stated explicitly, the at-least-once recovery named, the shipped-script touch named.
- The **quad** is authored: `emq.3.3.md` (the contract, D-n + INV-n as runnable checks — INV7 the cross-queue
  honesty the headline; the additive-minor `46 → N`; the A-1 law over the new signal-key + sweep scripts; the §2
  subkey-lifecycle naming for the signal-key) · `.stories.md` (US-n + the US-GATE + Coverage — the observable
  named as eventually-consistent, never "immediate") · a subsequent
  `emq.3.3` build runbook (HIGH-risk).
- **NO-INVENT:** every claim grounded in [`./emq.3.md`](../emq.3.md) (the carve + Fork A's cross-queue arm), the
  as-built emq.3.1/3.2 flow surface + the promote-sweep precedent, or the v1 cross-queue reference; the
  cross-queue *mechanism* is the design's own (forward-tense, surfaced-not-decided).
- The **HIGH-risk** tier (of the build) is encoded into the quad + the build runbook (Apollo MANDATORY + the ≥100
  loop). The forks are **surfaced, not decided** by Venus; the Operator rules; the quad is authored to the ruled
  arms with the forks marked OPEN. The Director ships the records by pathspec; the frontier folds to the emq.3.3
  BUILD.

Inputs: [`./emq.3.md`](../emq.3.md) (the family contract + the carve + **Fork A's cross-queue arm** — the
authoritative ground) · The SHIPPED/BUILT slices (the floor the cross-queue flow extends):
[`./emq.3.1.md`](emq.3.1.md) (the single-queue flow + the `@complete` fan-in branch) +
[`./emq.3.2.md`](emq.3.2.md) (the child-result reads + the host-only completion) ·
[`./emq.3.2.prompt.md`](emq.3.2.prompt.md) (the build-runbook FORM the cycle's build runbook mirrors, but
HIGH-risk) · The v1 cross-queue reference (READ-ONLY, the FORM not lifted):
`echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2`, `add_bulk/2`, the per-node `queue_name` spanning, the
data-value `parent_key` tree) · The promote-sweep precedent: `echo/apps/echo_mq/lib/echo_mq/pump.ex`
(`EchoMQ.Pump.sweep/1`) · Canon: [`../emq.design.md`](../../../emq.design.md) §11.10 (the deferral + the owed flow
design), §6 (the grammar — the slot constraint that forces the cross-queue fork), §5 (no new wire class), S-1/§6
(the braced keyspace — the slot constraint), S-6 (the declared-keys A-1 law), §11.12 (the escalation protocol) ·
Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I (the closer) · The feature catalog:
[`../emq.features.md`](../../../emq.features.md) (the emq.3 row) · Skills: `.claude/skills/echo-mq-architect.md` (the
binding — the authoring Venus's craft) + `echo-mq-program.md` (the program law) + `echo-mq-ship.md` (the binding
for the LATER build) · Approach: [`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)

---

# PART II · the BUILD orchestration runbook — ship the cross-queue flow (the flow family's third slice, HIGH-risk)

> **Status: the build runbook (authored at the close of the design cycle, per PART I's plan).** PART I commissioned
> the design (the quad + the cross-queue ADR — the forks ruled **D-1..D-5** in [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md));
> PART II ships the rung: it fans out the **echo-mq-ship** lead-team (Venus → Mars-1 → Director review → Mars-2 →
> **Apollo MANDATORY** → Venus reconcile → Director ship) to build emq.3.3 to the authored triad. The triad is the
> contract ([`./emq.3.3.md`](emq.3.3.md) authoritative · [`./emq.3.3.stories.md`](emq.3.3.stories.md)); the canon is [`../emq.design.md`](../../../emq.design.md); the binding is the
> **`echo-mq-ship`** skill (Venus loads `echo-mq-architect`, Mars `echo-mq-implementor`, Apollo `echo-mq-evaluator`).
> **HIGH-risk** — a shipped `@complete` edit + a new cross-slot mechanism → **Apollo MANDATORY** + the **≥100 loop**.

## The rung in one paragraph (the build)

emq.3.3 carves the **cross-queue flow** — a parent and its DIRECT children in different queues — fanned in by a
**completion-signal hop** (D-1..D-4): the cross-queue child's `@complete` **emits** `(parent_queue, parent_id,
child_id, result)` into a durable per-queue **outbox** on the child's slot (atomically with the active-ZREM, **one
EVAL** — the no-drop guarantee), and a per-queue **sweep** (a third `EchoMQ.Pump.sweep/1` pass
`deliver_flow_completions`) drains the outbox and delivers the decrement to the parent **on the parent's slot** via
a new **`@flow_deliver`** script that records the child in `:processed` (**HSETNX** guard) and DECRs `:dependencies`
only on first-record, at-zero releasing the parent — **eventually-consistent** (INV7, the parent released on the
next sweep tick, never synchronously) and **at-least-once → effectively-once** (a re-delivery is a no-op). The
cross-queue **add** (`Flows.add/3`) is host-orchestrated, **NON-atomic across slots**, parent-first, fail-closed.
Conformance grows **46 → 47** (`flow_cross_queue`). The new outbox subkey's cleanup is a **NAMED CARRY** (D-5c).

## Mode

**`echo-mq-ship`** (the HIGH-risk variant — the [`./emq.3.2.prompt.md`](emq.3.2.prompt.md) form, but with the
HIGH-risk dimensions emq.3.2 lacked: **Apollo MANDATORY** + a shipped-script edit to byte-prove). Scope slug
**`emq-3-3`**; ledger [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md) (PART I opened it — the build continues it);
Operator `jonny`; workspace `/Users/jonny/dev/jonnify`. The forks are **already ruled** (D-1..D-5), so the build's
Stage 0 RE-CONFIRMS them + re-probes the as-built floor (the lag-1 law) — there is **no fork gate** to re-open
(the 2026-06-15 governing directive dissolved the Operator land-gate; the Director rules + ships with delegated
authority — **no AskUserQuestion**).

## The pipeline — the HIGH-risk flow (Venus → Mars-1 → Director review → Mars-2 → Apollo MANDATORY → Venus → Director ship)

Each spawned stage is a real `Agent` that adopts its `.claude/agents/<role>.md` charter, LOADS its
`echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The Director holds the
gate between stages. **Apollo is MANDATORY** (HIGH-risk — a shipped-script edit + a new cross-slot mechanism).

### Stage 0 — Venus (architect): the pre-build reconcile + the fork re-confirmation

Directive: run the lag-1 reconcile (re-probe every as-built anchor in PART II's brief against the current tree —
`flows.ex` `add/3`+`reject_cross_queue/2`, `jobs.ex` `@complete`+the single-queue fan-in branch+`complete/5`+`parent_of/3`,
`pump.ex` `sweep/1`, `conformance.ex` the live count, `keyspace.ex` `queue_key/2`). Re-confirm the forks are ruled
**D-1..D-5** and the triad is authored to them. Gate: the grounding delta table (MATCH / `[RECONCILE]`); the
live conformance count (47 expected post-build, 46 as the pre-build floor); the BUILD-GRADE verdict. **(Stage 0 is
ALREADY DONE this run — the design-make reconcile T-2; the build re-affirms it against any Operator out-of-band
landing between stages.)**

### Stage 1 — Mars-1 (implementor): build the cross-queue flow

Directive (the `echo-mq-implementor` craft; build to Reqs 1–6 + the
build-order DAG T1–T5): (1) **the cross-queue add** (`flows.ex` — admit cross-queue children; host-orchestrated
parent-first, non-atomic, fail-closed; write `parent` + `parent_queue`; replace `reject_cross_queue/2`); (2) **the
outbox emit** (`jobs.ex` — the additive `@complete` cross-queue branch, the single-queue fan-in branch `:181-188`
BYTE-FROZEN; the host `complete`/`parent_of` extension); (3) **the sweep-deliver** (`pump.ex` —
`deliver_flow_completions` + `@flow_deliver`, the `:processed` HSETNX guard; `sweep/1`'s return grows); (4)
`flow_cross_queue` conformance + the count re-pin 46 → 47 (both pins); (5) the `:valkey` cross-queue suite. Run the
per-app gate (compile warnings-as-errors; `TMPDIR=/tmp mix test --include valkey` inside `echo/apps/echo_mq`).
Gate: compile clean; the cross-queue suite green; `Conformance.run/2` → `{:ok, 47}`; the `@complete` `git diff`
shows only ADDED lines (the single-queue branch byte-frozen); **runs NO git**.

### Stage 2 — Director: solo review (a REAL pass)

Directive: a real diff read against the triad. Verify: the **shipped-script byte-proof** (the `@complete` `git
diff` — the non-flow / flat / grouped-lane / single-queue-flow branches `:152-191` byte-identical; only the new
cross-queue branch added — the HIGH-risk headline); the **declared-keys/slot grep** (every key of the emit branch
on the child's slot {C}, every key of `@flow_deliver` on the parent's slot {P} — no cross-slot key, the F-1 trap
the 6390 single-node engine will NOT catch); the **eventually-consistent** observable (the scenario asserts the
parent held pre-sweep, released post-sweep — never synchronous); the **idempotency** proof (a double-deliver
DECRs once); the **no-invent** check (no v1 data-value `parent_key` lifted; the host builds declared keys);
`admin.ex` untouched (B5/INV9). Produce the REMEDIATE list. **Apollo is MANDATORY** — confirm the dedicated
evaluator is spawned at Stage 4.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder)

Directive: clear the REMEDIATE list; run the full ladder — per-app compile warnings-as-errors; the `:valkey`
cross-queue suite; the prior emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2} suites + `Conformance.run/2` **unchanged**
(no regression — INV3); the prior 46 conformance byte-unchanged + `flow_cross_queue` probe-registered; the
**≥100-iteration determinism loop** over the mint/process-touching cross-queue scenario **owning the machine**
(`for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done` — a cross-queue flow mints a
parent + N children across queues, the same-ms mint hazard surfaces only across runs); the per-attr `git diff`
proving the single-queue `@complete` branch byte-frozen. Gate: all green; the ≥100 loop green; **runs NO git**.

### Stage 4 (MANDATORY) — Apollo (evaluator): the HIGH-risk verification

Directive (the `echo-mq-evaluator` craft; the §11.2 charter): re-run the gate ladder + the ≥100 loop
**INDEPENDENTLY** (do not trust Mars's report — re-run the suites, re-walk the diff). Adversarially verify: the
**shipped-script byte-proof** (the `@complete` single-queue/non-flow branches byte-identical — the explicit
per-attr SHA/`git diff`, the HIGH-risk evidence); the **declared-keys/slot soundness** (no cross-slot key in
either new script — re-run the grep; name the single slot of each script's key set); the **no-drop guarantee**
(the emit's RPUSH + active-ZREM are one EVAL — a completed cross-queue child always has an outbox entry); the
**idempotency keystone** (a re-delivery is a no-op — DECR once); the **eventually-consistent honesty** (no "atomic
across queues" claim anywhere; the parent released on the sweep tick); the **additive-minor** (46 → 47, the prior
set byte-unchanged, both pins). Render the **BUILD-GRADE / BLOCKED** verdict the Director ratifies. Apollo edits
the spec triad/tests/`.operator.md`/retrospective (Director-ratified the peer agent-defs) — **never production
code, never commits.** Uses `AskUserQuestion` only to keep the product shippable (a genuine product fork).

### Stage 5 — Venus (architect): the post-build reconcile

Directive: diff the triad against the as-built surface; flip every `[ ]` DoD box to `[x]` with the as-built
`file:line`; sync the body's forward-tense ("emq.3.3 builds …") to the as-built present tense for what shipped;
re-pin every line anchor (the build moved the surface); confirm INV1–INV10 as runnable checks against the shipped
code. Gate: the post-build reconcile delta + the BUILD-GRADE verdict; the triad synced to as-built; **edits ONLY
the spec triad — no `.ex`/`.exs`; runs NO git.**

### Stage 6 — Director: closure + ONE LAW-4 commit + the frontier fold

Preconditions (x-mode §4): the gate green + the reconcile build-grade + **Apollo BUILD-GRADE** (MANDATORY); **≥1
`tool_x_decision`** + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff --cached
--name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec** commit (below; NEVER `git
add -A`). **Same turn:** flip the emq.3.3 row in the roadmap ([`../emq.roadmap.md`](../../../emq.roadmap.md)) + the
dashboard ([`../emq.progress.md`](../../../emq.progress.md)) to **SHIPPED**; surface the **next frontier** (emq.3.4
failure-policy + bulk + grandchildren → **Movement I CLOSES** → Movement II emq.4–emq.8). The message cites the
slug, the Z-n, the D-n, and the Y-n report.

## Risk tier (the build)

emq.3.3 the BUILD is **HIGH-risk** — the inverse of emq.3.2's NORMAL-risk. Two elevated dimensions: **(a)** it
founds a **new cross-slot completion signal** (the outbox + the sweep-deliver — a new mechanism, the cross-slot
crossing the whole family deferred to its own rung); **(b)** it **edits a shipped Lua script** (`@complete` gains
an additive cross-queue branch). So the build requires **Apollo MANDATORY** + the **≥100 determinism loop** (a
cross-queue flow mints a parent + N children across queues — the mint-touching surface). The three properties that
set the tier, named + tested not hand-waved: the consistency model is **eventually-consistent** (INV7/INV5); the
recovery is **at-least-once → effectively-once** (the `:processed` HSETNX guard, INV6; the no-drop atomic emit,
INV7-emit); the shipped-script touch is the **one additive `@complete` branch** (the single-queue branch
byte-frozen, INV3 — the regression bound Apollo byte-proves).

## The Stage-6 commit pathspec (Director-only — the emq.3.3 BUILD)

Commit exactly the build's measured surface:

```text
echo/apps/echo_mq/lib/echo_mq/flows.ex                 (the cross-queue admit path)
echo/apps/echo_mq/lib/echo_mq/jobs.ex                  (the additive @complete cross-queue branch + host complete/parent_of)
echo/apps/echo_mq/lib/echo_mq/pump.ex                  (deliver_flow_completions + @flow_deliver)
echo/apps/echo_mq/lib/echo_mq/conformance.ex           (flow_cross_queue + the count re-pin 46→47)
echo/apps/echo_mq/test/flow_cross_queue_test.exs        (NEW — :valkey)
echo/apps/echo_mq/test/conformance_run_test.exs         (the count re-pin → 47)
echo/apps/echo_mq/test/conformance_scenarios_test.exs   (the count re-pin → 47)
docs/echo_mq/specs/emq.3.3.md                           (the triad — Stage-5 synced + DoD boxes)
docs/echo_mq/specs/emq.3.3.stories.md
docs/echo_mq/specs/emq.3.3.prompt.md                    (this runbook — PART I design + PART II build)
docs/echo_mq/specs/emq-3-3.progress.md                  (the ledger)
docs/echo_mq/specs/emq.3.md                             (the carve's emq.3.3 row → SHIPPED)
docs/echo_mq/emq.roadmap.md                             (the emq.3.3 row → SHIPPED)
docs/echo_mq/emq.progress.md                            (the dashboard fold)
docs/echo_mq/emq.features.md                            (the flow row → emq.3.3 shipped, if touched)
```

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit):
`echo/apps/mercury_*/**`, `html/**`, the F# course, `docs/echo/mesh/**` (the Operator's concurrent course), and
any `[emq]`/`[bcs]`/`[mercury]` commits the Operator lands between stages. **`keyspace.ex` and
`admin.ex` are UNTOUCHED** (verify they are NOT in the diff — the outbox composes via the existing `queue_key/2`;
the lifecycle carry is deferred). **Never `git add -A`.** The build agents run **no git** (the Director commits by
pathspec).

## Acceptance — "shipped" means

- The cross-queue add admits cross-queue children (host-orchestrated, non-atomic across slots, parent-first,
  fail-closed; each child carries `parent` + `parent_queue`); the `reject_cross_queue/2` refusal is replaced (D2).
- The outbox emit is the additive `@complete` branch (the single-queue fan-in branch `:181-188` BYTE-FROZEN,
  git-proven); the cross-queue child's completion RPUSHes `(parent_queue, parent_id, child_id, result)` into
  `emq:{C}:flow:outbox` atomically with the active-ZREM (one EVAL — the no-drop guarantee, INV7) (D3).
- The sweep-deliver releases the parent eventually-consistently (on the next tick — INV5) via `@flow_deliver`'s
  `:processed` HSETNX guard, idempotent (a re-delivery is a no-op — INV6) (D4).
- `flow_cross_queue` registered additive-minor (46 → 47, the prior 46 byte-unchanged, both pins re-pinned —
  INV8); the `:valkey` cross-queue suite green; the **≥100 loop** green; the prior suites + `Conformance.run/2`
  unchanged (INV3); **Apollo BUILD-GRADE** (MANDATORY); honest-row reporting (Valkey on 6390).
- The new outbox subkey's lifecycle is NAMED, deferred (B5/INV9); `admin.ex` untouched. The spec body stays
  authoritative; Stage 5 syncs it to the as-built surface; the roadmap + dashboard flip to SHIPPED; the frontier
  folds to emq.3.4 (→ Movement I CLOSES).

Inputs (the build): [`./emq.3.3.md`](emq.3.3.md) (authoritative) · [`./emq.3.3.stories.md`](emq.3.3.stories.md)
· [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md)
(D-1..D-5 ruled) · [`./emq.3.md`](../emq.3.md) (the family + Fork A + INV7) · the shipped slices
[`./emq.3.1.md`](emq.3.1.md) + [`./emq.3.2.md`](emq.3.2.md) · the build-runbook FORM
[`./emq.3.2.prompt.md`](emq.3.2.prompt.md) (NORMAL-risk; this one is HIGH-risk) · Canon
[`../emq.design.md`](../../../emq.design.md) §6/§11.10/§5/S-6/S-1 · Skills: `echo-mq-ship` (the binding) +
`echo-mq-implementor` + `echo-mq-evaluator` + `echo-mq-architect` + `echo-mq-program.md` (the program law) ·
Approach [`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
