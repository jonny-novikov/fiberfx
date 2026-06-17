# emq-3 — AAW scope ledger

## {emq-3-thinking} Thinking

### T-1 — emq.3 design cycle: §0 derivation + ground truth + the two-Venus fan-out

MODE: Flat-L2 DESIGN PHASE (Director + Venus-3-1 + Venus-3-2; NO Mars build, NO Apollo — Apollo is out of design phases, aaw D-7 lock). Scope emq-3. Operator jonny. Ledger docs/echo_mq/specs/emq-3.progress.md. Opened right after the emq.2 cluster CLOSED (emq.2.4 shipped via the emq-2-4 recycle: obliterate 92a8f042 · closer 3298e4bc · harness f3e7893d · ship-close f6b86e97 · Apollo-2 BUILD-GRADE).

WHY (Operator directive). The emq.2 parity cluster is closed; the frontier is emq.3 (the parent/flow family, which closes Movement I). The Operator opened the emq.3 design cycle + a feature-roadmap reconcile: (a) reconcile the status docs (emq3.specs.md + emq.progress.md); (b) author the emq.3 triad + bootstrap the first workload emq.3.1; (c) reconcile the [RECONCILE] feature files docs/echo_mq/roadmap/{groups,batches,observables}.md — mark mandatory-for-2.0, fill rationale + 5W + the emq.[N] rung mapping; (d) EXPLICITLY resolve the Apollo Y-3 §4 flag (the @extend_locks ARGV-rooted key).

GROUND TRUTH (verified against the tree):
1. emq.3 = THE PARENT/FLOW FAMILY (Movement I; the cluster that closes it). Ports v1 flow_producer.ex (add/2, add_bulk/2 — echo/apps/echomq, FROZEN v1, READ-only reference): a flow is a TREE of jobs (parent + children, recursive); a parent completes only when its children complete (fan-in). THE CORE DESIGN CHALLENGE (design §11.10 / decision 10): the v1 flow/scheduler script families ROOT KEY OPERANDS IN DATA VALUES — "structurally inexpressible under the declared-keys invariant"; "an A-1-compatible flow design is real design work for the family rungs." So emq.3's hard problem = parent→child dependency tracking + fan-in completion under the v2 A-1 declared-keys law (every Lua key in KEYS[] or rooted in a declared KEYS[n] — the as-built @enqueue: KEYS[1]=job row, KEYS[2]=pending zset, NEVER data-derived). Venus-3-1 designs it OR surfaces the fork (STOP + escalate; never silently decide a wire-shaping seam — §11.12 escalation protocol).
2. THE FEATURE-ROADMAP MAPPING (per emq.features.md lines 172-192/266-334 — reconcile-against, no rung-map drift): groups.md → emq.4 (groups deepened: per-group + LOCAL rate-limit/concurrency, max group size, pause groups, prioritized intra-group, FLAME backends); batches.md → emq.5 (batches: bulk, min_size/timeout, group-affinity, batch concurrency, failing/events/dynamic-rate/manual/delayed); observables.md → emq.6 (lifecycle controls: cancelable jobs, TTL, resumable state — the worker-side cooperative cancel/token shipped emq.2.3; DISTRIBUTED cancel → emq.6). Each roadmap/*.md [RECONCILE] resolves to: mandatory-for-2.0? + rationale + 5W + rung.
3. THE @extend_locks FLAG (Apollo Y-3 §4): jobs.ex @extend_locks (Jobs.extend_locks/4, emq.2.3, emq.features.md:310) derives its per-job row key from ARGV[1] (base), not a declared KEYS[n] root — slot-sound in practice (ARGV[1]=queue_key carries the same {q} as KEYS[1]), the pre-existing Jobs.* convention, NOT a defect. EXPLICITLY resolve: slot into a rung (candidate emq.4 groups — the Lua/lanes surface — or emq.8 the proof/A-1-lint rung) + record the A-1-WORDING resolution (ratify "an ARGV-base that carries the {q} slot is an A-1 extension" OR mandate a declared KEYS[n] root for strictness — surfaced for the Operator, not decided by the peer).

DELIVERABLES + SPLIT:
- DIRECTOR: reconcile emq3.specs.md (the 3.x STREAM tier — distinct from emq.3; status/alignment to reflect emq.2 CLOSED + the ladder state; it stays PROPOSED) + emq.progress.md (the emq.3 frontier: design cycle open). Set up scope/ledger; gate the Venus output; the single design commit + the ledger close.
- VENUS-3-1 (the deep rung design): the emq.3 triad (emq.3.md + emq.3.stories.md + emq.3.llms.md) — the parent/flow family, the A-1-compatible flow design grounded in §11.10 + the v1 flow_producer + the as-built Jobs declared-keys pattern + the emq.2.x triad shape — AND the first-workload bootstrap emq.3.1.{prompt,stories,llms}.md (carve the first buildable sub-rung).
- VENUS-3-2 (the feature reconcile): reconcile docs/echo_mq/roadmap/{groups,batches,observables}.md ([RECONCILE] → mandatory-for-2.0 + rationale + 5W + rung mapping, aligned with emq.features.md) + EXPLICITLY resolve the @extend_locks Y-3 §4 flag.

SMALLEST CHANGE / NO-INVENT: DOCS ONLY (design phase; zero echo_mq code). Every feature cites a real v1 module/file or a design §; forward-tense for unshipped surface; the flow design is genuine new design (§11.10 mandate) — surface every open seam (the flow keyspace, the parent/child dependency representation under declared-keys, the fan-in completion mechanism) for the Operator, never silently decide a wire-shaping fork. BOUNDARY: docs/echo_mq/{specs/emq.3.*, specs/emq.3.1.*, roadmap/*.md, emq3.specs.md, emq.progress.md} + the ledger; apps/echomq (frozen v1) READ-only; exclude all Operator out-of-band. PIPELINE: Director ground-truth + status reconcile → Venus-3-1 ∥ Venus-3-2 (parallel) → Director gate (read every artifact, re-probe, accept/REMEDIATE) → one design commit + the ledger close.

## {emq-3-progress} Progress

### P-1 — Director gate (checkpoint): Venus-3-1 family triad + Venus-3-2 reconcile — BOTH BUILD-GRADE (verified the artifacts, not the reports)

VENUS-3-1 (the emq.3 family triad — emq.3.md, checkpoint before emq.3.1): read against ground truth.
- THE A-1-COMPATIBLE FLOW DESIGN is sound + grounded: the dependency graph carried in DECLARED §6 subkeys OF THE PARENT (job:<parent>:{dependencies,processed,failed,unsuccessful}, rooted at the parent's declared job key, on the parent's {q} slot → A-1-clean + slot-sound BY CONSTRUCTION). VERIFIED: §6 reserved these subkeys at the founding; the v1 moveToFinished-15.lua:140-141 names them — the canon ANTICIPATED this rung. The fan-in gate = the parent's ABSENCE from `pending` until :dependencies hits zero (so @claim BYTE-UNCHANGED — the emq.2.2-D2 separate-gate discipline); the ONE shipped-script edit = a guarded fan-in hook on @complete (non-flow path byte-unchanged, INV3). The @extend_locks `base .. 'job:' .. id` derivation correctly cited as the A-1 precedent.
- THE §11.10 READING CONFIRMED (the Director adopts it): "structurally inexpressible under declared keys" = the v1 FORM (data-value rooting), NOT flows-in-general; the reserved §6 subkeys make an A-1-compatible flow expressible = the "real design work" §11.10 assigned. No spec⇄design contradiction.
- THE CARVE sound: emq.3.1 single-queue (the atomic tracer bullet) → 3.2 child-result reads → 3.3 cross-queue → 3.4 failure-policy + bulk, dependency-ordered. INV1-8 are runnable checks.
- 3 FORKS well-surfaced (Arm 1/Arm 2 + costs + recommendation, NOT decided): A single-queue-first (the build-gating decision) · B counter+the-idempotency-guard · C awaiting_children-state. The triad authored to the recommended arms (buildable). GREENLIT to emq.3.1 (SendMessage), requiring emq.3.1.prompt.md capture the HIGH-RISK tier (@complete edit → Apollo MANDATORY at BUILD + INV3 re-verify) + Fork B's double-complete idempotency guard as a build requirement.

VENUS-3-2 (the roadmap reconcile + the flag): verified groups.md + a1-extend-locks.md; 0 [RECONCILE] markers remain across all 4 files.
- THE RECONCILE is build-grade: each feature gets Mandatory-for-2.0? (nuanced — No/Partially-shipped/Shipped-emq.4-deepens) + Rationale + 5W (grounded in the as-built @glimit/@gclaim/ring/Lanes + the Exchange consumer) + Rung. The "as-built floor" note keeps the forward-tense honest ("emq.4 EXTENDS Lanes", never "Lanes builds"). NO-INVENT. groups→emq.4, batches→emq.5, observables→emq.6 (aligned with emq.features.md, no drift).
- THE @extend_locks RESOLUTION (a1-extend-locks.md): build-grade. The finding stated precisely (jobs.ex:671/581/682/680/591); PROVEN slot-sound (ARGV[1]=emq:{q}: shares the {q} hashtag with KEYS[1]) + NOT a defect (the dynamic-id convention; the singular @extend_lock declares both keys); SLOTTED into emq.4 (recommended — sets the convention before Movement-II dynamic-id scripts copy it; emq.8 fallback); the A-1-WORDING fork surfaced (Arm 1 RATIFY-the-convention as an S-6 wording extension, RECOMMENDED, no code edit · Arm 2 MANDATE a declared KEYS[n] root, edits shipped code). Correctly notes the S-6 edit is an emq.design.md change the DIRECTOR carries to the Operator.

THE OPEN OPERATOR DECISIONS to surface at the close (AskUserQuestion): FORK A (the flow shape — gates the emq.3.1 build) + the @extend_locks A-1-wording (Arm 1 ratify — an S-6 canon edit). Forks B/C (cheap pre-build re-scopes) + the slot (emq.4) carry as recommended. Venus-3-2 stood down (deliverable gated complete); awaiting Venus-3-1's emq.3.1 4-file set to complete the gate (→ P-2) and close.

### P-2 — Director gate: Venus-3-1's emq.3.1 bootstrap — BUILD-GRADE (verified the artifacts) + one lag-1 REMEDIATE (37→43)

VENUS-3-1 COMPLETE: the family triad (P-1) + the emq.3.1 bootstrap (7 files: emq.3.{md,stories,llms} + emq.3.1.{md,stories,llms,prompt}). Gated emq.3.1.md + emq.3.1.prompt.md against ground truth:
- emq.3.1.md (the single-queue-flow slice): D1 the Fork-A gate FIRST · D2 EchoMQ.Flows.add/3 + @enqueue_flow (atomic, kind-law-first, parent withheld from `pending`) · D3 the fan-in hook on @complete (idempotent DECR via the was_active guard; non-flow path byte-unchanged) · D4 awaiting_children · D5 flow_add+flow_fanin (the count re-pins N_prior→N_prior+2 — parametric, correct) · D6 the proof (≥100 loop, Apollo MANDATORY). Authored to Fork A·A / B·counter+guard / C·awaiting_children. The HONEST Out list (cross-queue→3.3, child-reads→3.2, failure-policy+bulk→3.4; the hang-on-dead-child limit STATED, not papered).
- emq.3.1.prompt.md (the HIGH-RISK runbook): captured ALL Director requirements — HIGH-RISK + Apollo MANDATORY (the @complete edit + the multi-id mint); the Fork A build gate ("nothing builds until Fork A is ruled"); Fork B's double-complete idempotency guard as a BUILD requirement; INV3 non-flow byte-unchanged; the Stage-6 pathspec + EXCLUDE (Operator out-of-band); the conformance count NEVER hardcoded (re-probe at Stage 0). The 7-stage HIGH-RISK pipeline.

ONE LAG-1 REMEDIATE (the gate caught it): the specs reference the conformance floor as 37 (the emq.2.3 count), but emq.2.4 SHIPPED this session → 43. Re-pin sent to Venus-3-1 (37→43 across emq.3.md/stories/llms + emq.3.1.prompt.md; keep the re-probe directives; emq.3.1.md D5's parametric N_prior is correct, left). Non-blocking (the build re-probes); fixed for accuracy + the no-stale-figures discipline.

VERDICT: emq.3.1 BUILD-GRADE — buildable AS AUTHORED the moment the Operator rules Fork A. emq.progress.md folded (emq.3 → SPECCED; the frontier → the emq.3.1 build). Awaiting Venus-3-1's 37→43 re-pin, then the close: D-1 (the design decisions) + Z-1; one design commit (the 7 emq.3.* + the 4 roadmap files + emq3.specs.md + emq.progress.md + the ledger); AskUserQuestion (Fork A + the @extend_locks A-1-wording).

## {emq-3-decisions} Decisions

### D-1 — emq.3 design cycle: the design ACCEPTED (the A-1-compatible flow design + the carve + the roadmap reconcile + the @extend_locks slot/wording)

The Director gated both architects against ground truth (P-1 + P-2 — verified the artifacts, not the reports) + the 37→43 lag-1 re-pin (Venus-3-1 applied it; verified complete — the lone remaining "37" is the correct "37 → 43" growth history at emq.3.1.prompt.md:90). DECISIONS LOCKED:

1. THE A-1-COMPATIBLE FLOW DESIGN (emq.3.md) ACCEPTED as the family contract: the parent→child dependency graph in DECLARED §6 subkeys OF THE PARENT (job:<parent>:{dependencies,processed,failed,unsuccessful}, rooted at the parent's declared job key, on the parent's {q} slot — A-1-clean + slot-sound BY CONSTRUCTION; §6 reserved these subkeys at the founding — the canon anticipated this rung). The fan-in gate = the parent's ABSENCE from `pending` (so @claim byte-unchanged — the emq.2.2-D2 separate-gate discipline); the ONE shipped-script edit = a guarded fan-in hook on @complete (non-flow path byte-unchanged). The §11.10 reading confirmed: "structurally inexpressible" = the v1 FORM (data-value rooting), NOT flows-in-general.

2. THE CARVE: emq.3 → emq.3.1 (single-queue flow, the atomic tracer bullet) → 3.2 (child-result reads) → 3.3 (cross-queue) → 3.4 (failure-policy + bulk), dependency-ordered. emq.3.1 SPECCED this cycle (the 4-file bootstrap; HIGH-RISK runbook — the @complete edit → Apollo MANDATORY at build).

3. THE ROADMAP FEATURE RECONCILE (Venus-3-2): groups→emq.4 · batches→emq.5 · observables→emq.6, each [RECONCILE] resolved with mandatory-for-2.0 + rationale + 5W + rung (0 markers remaining; grounded in the as-built Lanes; aligned with emq.features.md, no drift).

4. THE @extend_locks A-1 FLAG (Apollo Y-3 §4): SLOTTED into emq.4 (a1-extend-locks.md — set the convention before Movement-II dynamic-id scripts copy it; emq.8 the fallback); the A-1-WORDING fork surfaced (Arm 1 RATIFY the convention as an S-6 wording extension, recommended, no code · Arm 2 MANDATE a declared KEYS[n] root, edits shipped code). The S-6 edit (if Arm 1) is an emq.design.md change the DIRECTOR carries to the Operator.

5. THE STATUS DOCS reconciled (Director): emq3.specs.md (the 3.x tier alignment → emq.2 CLOSED + emq.3 frontier; stays PROPOSED); emq.progress.md (emq.3 → SPECCED, the frontier → the emq.3.1 build, roll-up specced 1).

THE OPEN OPERATOR DECISIONS (surfaced at this close via AskUserQuestion — NOT decided by the peers): FORK A (the flow shape — single-queue-first recommended; GATES the emq.3.1 build) + the @extend_locks A-1-wording (Arm 1 ratify recommended — an S-6 canon edit). Forks B (counter+guard) + C (awaiting_children) authored to the recommended arms — cheap pre-build re-scopes, rulable at the build launch.

BOUNDARY: docs only (design phase, zero echo_mq code). apps/echomq + apps/echo_mq READ-only (grounding). The frozen ledgers untouched. The peers ran no git.

### D-2 — Operator rulings on the 4 emq.3 design forks: ALL to the RECOMMENDED arms (2026-06-14, AskUserQuestion at the design-cycle close)

1. FORK A (the flow shape) = SINGLE-QUEUE FIRST (recommended). emq.3.1 builds the same-queue atomic flow; the cross-queue crossing is emq.3.3 over an eventually-consistent completion sweep. CONSEQUENCE: the emq.3.1 build gate is UNBLOCKED — the triad is authored to exactly this arm, so NO re-scope; emq.3.1 is build-ready (the build's Stage-0 confirms Fork A = Arm A, a no-op re-derive).
2. THE @extend_locks A-1-WORDING = RATIFY THE CONVENTION (recommended, Arm 1). Extend S-6 so an ARGV-base that PROVABLY carries the same braced {q} slot as a declared KEYS[n] is an A-1-compatible root (the slot-soundness obligation made explicit). @extend_locks is A-1-compliant AS-IS — zero code edit. CONSEQUENCE: the Director carries the S-6 wording extension into emq.design.md (Operator-ratified via this ruling); the convention is set BEFORE the Movement-II dynamic-id scripts (emq.4 max-group-size, emq.5 batch-claim) are authored; emq.8 then lints against the ruled wording. The reconcile stays slotted at emq.4 (a1-extend-locks.md).
3. FORK B (the dependency representation) = COUNTER + the idempotency guard (recommended). :dependencies is a string-integer count; the double-complete guard (gate the DECR on the child's active→done transition, the was_active guard @complete already uses) is a build requirement. The triad is authored to this arm.
4. FORK C (the parent waiting state) = NEW awaiting_children STATE (recommended). The waiting parent reads state=awaiting_children, reported distinctly by Metrics.get_job_state/3; the read plane stays truthful. The triad is authored to this arm.

NET: all 4 rulings = the recommended arms = the arms the triad is ALREADY authored to. So emq.3.1 is BUILD-READY with NO pre-build re-scope. Director follow-up (this turn): fold the S-6 wording extension into emq.design.md (the @extend_locks Arm-1 ratification, Operator-approved) + mark the emq.3 specs' forks RULED + the emq.progress.md frontier (emq.3.1 build unblocked). The emq.3.1 build (/echo-mq-ship emq.3.1) is unblocked.

## {emq-3-complete} Complete

### Z-1 — emq-3 design cycle COMPLETE: emq.3 SPECCED (the parent/flow family + the emq.3.1 bootstrap) + the roadmap feature reconcile + the @extend_locks resolution

The emq.3 design cycle is complete — opened right after the emq.2 cluster CLOSED (emq.2.4 shipped). PIPELINE: Director T-1 (the §0 derivation + the two-Venus fan-out) → Venus-3-1 ∥ Venus-3-2 (parallel architects) → Director gate (P-1 + P-2, both BUILD-GRADE; the 37→43 lag-1 re-pin verified) → Director close (D-1 + this).

DELIVERED (DOCS — design phase, ZERO echo_mq code):
- THE emq.3 FAMILY TRIAD (Venus-3-1): emq.3.{md,stories,llms}.md — the parent/flow family, the A-1-compatible flow design (the dependency graph in declared §6 parent subkeys; the fan-in gate as the parent's absence from `pending`; the one guarded @complete edit), the carve (3.1→3.4), INV1-8, 3 surfaced forks.
- THE emq.3.1 BOOTSTRAP (Venus-3-1): emq.3.1.{md,stories,llms,prompt}.md — the single-queue flow (the first buildable slice), HIGH-RISK (the @complete edit → Apollo MANDATORY at build), the 7-stage runbook, the honest Out list (the hang-on-dead-child limit stated, not papered).
- THE ROADMAP FEATURE RECONCILE (Venus-3-2): roadmap/{groups,batches,observables}.md — every [RECONCILE] resolved (mandatory-for-2.0 + rationale + 5W + rung; groups→emq.4 · batches→emq.5 · observables→emq.6) + roadmap/a1-extend-locks.md (the @extend_locks Y-3 §4 resolution: slot emq.4 + the A-1-wording fork, Arm 1 ratify recommended).
- THE STATUS DOCS (Director): emq3.specs.md (the 3.x tier alignment) + emq.progress.md (emq.3 → SPECCED).

DECISIONS: D-1 (the design accepted). PROGRESS: P-1 (Venus-3-1 family triad + Venus-3-2 reconcile gate), P-2 (Venus-3-1 emq.3.1 gate). LEARNINGS (one process note): a TARGETED REMEDIATE sent through the team channel can be misread by a teammate as a stale TASK re-run — Venus-3-1 applied the 37→43 re-pin CORRECTLY but its "no action" message was about a separate re-delivered task assignment; the Director resolved it by verifying the ARTIFACT (the grep), not the report.

THE OPEN OPERATOR DECISIONS (surfaced via AskUserQuestion at this close): FORK A (the flow shape — single-queue-first; GATES the emq.3.1 build) + the @extend_locks A-1-wording (Arm 1 ratify — an S-6 canon edit). Forks B/C carry as recommended arms (cheap pre-build re-scopes).

NEXT: the emq.3.1 BUILD (/echo-mq-ship emq.3.1) once the Operator rules Fork A — the single-queue flow, HIGH-RISK (Apollo MANDATORY). Then emq.3.2-3.4 → Movement I CLOSES → Movement II (emq.4 groups · emq.5 batches · emq.6 lifecycle — the reconciled roadmap) opens. The @extend_locks A-1-wording (if Arm 1) folds into emq.design.md S-6 + the emq.4 triad.

PROCESS: a fresh emq-3 design-cycle team (Director + Venus-3-1 + Venus-3-2 — parallel architects; design phase, no Mars/Apollo per D-7). Records-freeze held. The peers ran no git; the Director commits by guarded pathspec.
