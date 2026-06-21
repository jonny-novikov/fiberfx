---
name: echo-mq-three-movements
description: "EchoMQ program — echo/apps/echo_mq is THE v3 library. DEPTH lives on-disk at docs/echo_mq/program/emq.program.md (the operating manual + agent calibrations). Shipped emq.0. emq.1 emq.2 emq.3 — **MOVEMENT I CLOSED**. Epics layer + AAW Epic/corpus framework instrument live. Recalibration 2026-06-17 (D-1): Mars=code-quality gate+stories, Director verifies code+invariants, Apollo=Mentor ONLY (out of pipeline). Consumer pivot: codemojex (live) + echo_bot (planned Telegram); Exchange dropped; apps/echomq REMOVED. **Movement II OPEN — emq.4.1 (fair-lanes control plane: reassign + DESTRUCTIVE lane-drain) SHIPPED 2026-06-18, HIGH-risk (R3 mid-build → NORMAL→HIGH; gate = blast-radius mutation battery, not the ≥100 loop), conf 54; echomq:3.0.0 era. emq.4.2/4.3/4.4 SHIPPED → the groups family (emq.4) is PARITY-COMPLETE 2026-06-19 (4.4 `361fd663`, Fork B Arm 2 weighted multi-pop, conf 61); next emq.5 (batches). Apollo Stage-7 Operator-grantable (D-4 process-doc reconcile + D-5 destructive-op eval).** This memory = slim pointer + frontier."
metadata:
  node_type: memory
  type: project
  originSessionId: 0be564f9-9bb6-42f9-8196-f11e99620607
---

**The program.** `echo/apps/echo_mq` is THE EchoMQ 2.0 library (Valkey-native, above `echo/apps/echo_wire`);
the v1 line was rewritten fresh into echo_mq and **`apps/echomq` REMOVED** (single source of truth). One program,
three movements; shipped one rung per run through the aaw lead-team (Director-orchestrated → one LAW-4 commit).
The consumers: **codemojex** (`echo/apps/codemojex`, the live Mastermind game on Lanes/Consumer/Events + the BCS
property stores) is the worked present-tense consumer; **echo_bot** (`echo/apps/echo_bot`) is the headline-planned
consumer (Telegram notifications at scale, forward-tense — no bus coupling yet; seam
`EchoBot.Platform.Telegram.send_reply/3`). Exchange is no longer a target. The L2 store beside the bus is **`echo_store`**.

## The depth lives ON DISK — read these (the 2026-06-15 de-bloat)

This memory is a **slim pointer, not the source of truth**. The operating manual, the agent calibrations, the
footguns, and the gate ladder are a committed on-disk doc:
- **`docs/echo_mq/program/emq.program.md`** — THE operating manual: the AAW pipeline, the roster + the
  per-agent calibrations (`emq.{venus,mars,apollo}.md`, same folder), the boundary, the gate ladder, the durable
  footguns, the live frontier.
- `docs/echo_mq/emq.design.md` (canon, S-1..S-7) · `emq.roadmap.md` (plan + ladder) · `emq.progress.md`
  (as-built dashboard) · `emq.features.md` (catalog + **Part C** forward-features) · `emq.testing.md`.
- Run-ledgers (per-rung audit trails): `docs/echo_mq/specs/progress/emq-N-M.progress.md`.

## The live frontier (re-true at each rung close)

Shipped: emq.0 · emq.1 · emq.2.1/2.2/2.3/2.4 (parity cluster CLOSED) · emq.3.1 `f9849efe` · emq.3.2 `68b6baed`
· **emq.3.3 cross-queue flow `7de4e90a`** (outbox-on-{C} + Pump sweep + `:processed` HSETNX idempotent deliver;
conf 47). **emq.3.4 failure-policy + bulk SHIPPED `4c401479`** (the additive `@retry` dead-letter branch + `@flow_fail_deliver`
over the §6-reserved `:failed`/`:unsuccessful`; both enqueue scripts + `@complete`/`@flow_deliver` byte-frozen;
`add_bulk/3` sequential/fail-closed-per-flow + `ignored_failures/3`; conf 50; Apollo BUILD-GRADE; the `emq-3-4-build`
lead-team). **emq.3.5 (grandchildren / deep recursion) SHIPPED 2026-06-15 — MOVEMENT I CLOSED** (the `/echo-mq-ship`
Flat-L2 run; Apollo BUILD-GRADE, NORMAL-risk, Arm A). Forks RULED (ledger D-1): **S2 · Arm A** = host/sweep re-emit
over byte-frozen Lua → **S1 · NORMAL-risk**; S3 · Arm A (unified `add/3` nested-tree clause); S-Bound · 8. D3
completion composes recursively FREE over the byte-frozen `@complete`; the recursive FAILURE hook (D4, the SOLE new
mechanism) is host/sweep re-emit (`Pump.maybe_reemit_parent_death` deliver-loop + `on_same_queue_child_death` from
`retry/7`, reusing emq.3.4's outbox+sweep+`@flow_fail_deliver` one more hop; `parent_fail_link/3` host-reads
ancestry). All 19 `Script.new` bodies byte-frozen; conf 50→52; the **depth-4 multi-tick same-queue** test the
load-bearing proof. **GOTCHA worth keeping**: the same-queue failure half had a REAL production gap — the re-emit was
UNWIRED from `retry/7`, so a same-queue child's death HUNG its parent — hidden behind a FALSE-GREEN (4 test
hand-calls simulating the re-emit production never ran); caught + closed in-cycle (depth-3 tests can't reach the
recursive deliver-loop hop, so the depth-4 multi-tick test is what bites; a Director mutation probe confirmed
depth-4 RED / depth-3 GREEN). The flow family (3.1–3.5) is parity-complete → **Movement II (emq.4–8) opens**. **NEW — the Epics layer** (`docs/echo_mq/epics/`:
emq.epic.0 the meta-epic + emq.epic.1 the v3.x command DSL; the AAW framework Epic/corpus instrument + the
repo-controlled-memory model PENDING Operator grant). Build vs design scope: `emq-3-4` design closed Z-1; the BUILD
ran as the fresh `emq-3-4-build` scope (ledger_dir immutable after init).

## Movement II — the extension family (OPEN)

emq.4 (groups deepened, 4.1–4.4) chapter SPECCED 2026-06-18 (`d3c252c1`, spec-only). **emq.4.1 (fair-lanes
operator control plane) SHIPPED 2026-06-18** — `Lanes.reassign/4` + `@greassign` (the multi-key atomic lane
move: ZREM src + ZADD dst score-0 + **`HSET <row> group=dst`** the load-bearing rewrite — `group` is denormalized
onto the job row and read at `jobs.ex` complete/retry/promote/reap to find the lane + adjust `gactive`, so the
move is NOT a ZSET swap; re-aims the RETIRED v1 changePriority/getCountsPerPriority, no numeric priority) +
`Lanes.drain/3` + `@gdrain` (the lane-scoped DESTRUCTIVE drain = `Admin.@drain` scoped to one lane; blast radius
bounded BY CONSTRUCTION — no SCAN/KEYS*, max damage provable from the declared key list). conf 52→54
additive-minor. **HIGH-risk** — R3 (the destructive drain) surfaced **MID-BUILD** → Operator ruled BUILD (D-5) →
NORMAL→HIGH; the gate was the **blast-radius mutation battery** (over-reach `HDEL gactive` + under-clean
skip-ring-`LREM` both caught), NOT the ≥100 loop (the drain mints no id / touches no TIME / starts no process — the
loop would forge load). Fork C (intra-group priority) PARKED — lanes stay score-0 (the ring's `ZPOPMIN` head =
mint-order FIFO = the order theorem). 3 commits: `6bca0d6d` rung · `7dc828ff` 3.0-note · `6d79e17e`
program-calibration. **Version arc: Movement II = the `echomq:3.0.0` era** — additive minors over the frozen
`echomq:2.0.0` wire, ratified as the `echomq:3.0.0` major at emq.8 (no rung bumps the wire). **Apollo Stage-7
gained Operator-grantable extensions** (D-4 process-doc reconcile of `docs/echo_mq/program` against the as-built
run + D-5 destructive-op adversarial eval; both PROPOSE-only/docs-only). **emq.4.2/4.3/4.4 SHIPPED → the groups family (emq.4) is PARITY-COMPLETE 2026-06-19.** 4.2 group-aware recovery (`@greap_group`, a group-scoped stalled-sweep into the member's own lane). 4.3 the park-don't-poll metronome (`EchoMQ.Metronome` — one `BLPOP wake` blocker per queue + an idle-consumer registry, BEAM-message fan-out, opt-in; owns NO Valkey lease, decides in a pure `Metronome.Core`; `@gclaim` byte-frozen; `174e1d7f`). **emq.4.4 (weighted/deficit rotation + the starvation drill) SHIPPED 2026-06-19 `361fd663`** — Fork B ruled **Arm 2 (additive weighted multi-pop)**: a new `@gwclaim` serves a serviceable lane K=min(weight, ZCARD lane, glimit headroom) heads per ring rotation on one shared server-clock lease; weight rides a new `emq:{q}:gweight` HASH set by `weight/4`, served by `wclaim/3`; `@gclaim`/`claim/3` byte-FROZEN (equal round-robin + weighted coexist); conf 59→61; NORMAL+ (Mars-2 collapsed for zero findings, Apollo not mandated). **Craft (L-1):** for a fairness property a terminal depth-0 drill is a WEAK no-op-defeater (a no-rotation FIFO drain also empties every lane via the re-ring guard) — use a bounded-early-window INTERLEAVING witness. **RECONCILED 2026-06-19:** the emq.4 family fold is folded into the canon docs (emq.roadmap.md line 36/impl-index/ladder · emq.progress.md · emq.changelog.md spine+table · emq.4.md chapter PROPOSED→SHIPPED) — the docs had LAGGED (showed 55/4.3-RULED/4.4-next); now show conf 61, emq.4 CLOSED. Conformance lineage pinned: 52→54(4.1)→55(4.2)→57(ewr.2.5 pool_enqueue/order)→59(ewr.2.6 native_lock×2)→59(**4.3 metronome +0, a BEAM process/lease, NOT a wire scenario**)→61(4.4). Two planes: wire @wire_version FROZEN echomq:2.4.2, mix label climbs (2.4.4). **emq.5 (batches) family OPEN — emq.5.1 (batch-claim spine) SHIPPED 2026-06-20** via /echo-mq-ship Flat-L2 (`1c36b70a` foundation = the carve reconcile + the emq.5.1 triad / `bca36d0c` rung): the NEW inline `@bclaim` = a count-variant `ZPOPMIN emq:{q}:pending` loop ×N INSIDE the script (the non-grouped generalization of `@gwclaim`; ZCARD-clamp k=min(size,depth), one `TIME`, one batch lease deadline, per-member `HINCRBY attempts`; design §6.2, NOT a client-side LMPOP/ZMPOP) + `Jobs.claim_batch/4` (the manual-pull host API, pause-first, returns `{:ok,[{id,payload,att}]}` | `:empty`). Forks RULED: **D-1 the LOOP** (vs native count-arg) / **D-2 return-the-short-batch** (non-blocking; M=0/paused→:empty; oversized N>depth→depth — the min_size/timeout cadence stays 5.2's) / **D-3 +3 conformance → 64** (Operator chose granular over the +2→63 lean: `batch_claim`·`batch_claim_short`·`batch_partial_failure`) / **D-4 label 2.5.0** (the batches family opens; wire `@wire_version` FROZEN echomq:2.4.2 — label-plane only climbs). `@claim` + every shipped script BYTE-FROZEN (jobs.ex 94 ins/0 del). Declared-keys A-1 = `KEYS[1]=pending`/`KEYS[2]=active` PIN the {q} slot, the row `jk=ARGV[1]..id` rides it. Director verify (Mars-2 COLLAPSED, zero findings) = byte-freeze + **F-1-declared-keys-by-hand** + order-theorem + a net-zero `ZPOPMIN→ZPOPMAX` mutation caught 6× + **TWO independent ≥100 determinism loops** (100/0 each, different load shapes). **Craft (L-1):** INV3's prose called the `@claim`/`@bclaim` ARGV row-key base "a declared root by the A-1 rule" — TIGHTENED to "an ARGV base is NOT a declared root; the real braced `KEYS[]` pin the {q} slot, the row rides it" (the as-built code comment jobs.ex:192-196 already stated it right). F-1 is **gate-invisible on single-node Valkey** → the Director's manual declared-keys review is the ONLY defense, not any green gate. **NEXT: emq.5.2** min_size/timeout shaping (a batch-aware `EchoMQ.Consumer` mode over `@bclaim` + a pure accumulate/flush core; a right-size-collapse candidate — no new Lua/lease); 5.3 affinity (`@gbclaim`+gactive, Apollo rec. for the L-1 fairness-witness) / 5.4 partitioned finish (over byte-frozen `@complete`/`@retry`/`@schedule`) ride `@bclaim`.

## Critical operational quick-ref (DEPTH in emq.program.md)

Per-app `mix` only (umbrella `mix test` BANNED) · **erlang 28.5.0.1** (re-probe; the 28.1 advice is DEAD) ·
`TMPDIR=/tmp` on every mix · **Valkey 6390** · the **concurrent-index race** (the Operator commits out-of-band →
guarded pathspec commit, re-verify `git diff --cached`, `git commit -- <path>` partial, NEVER `git add -A`) ·
the **mutation-revert** (inverse Edit, never `git checkout` — L-3) · **`SCRIPT FLUSH`** before re-testing a Lua
mutation (EVALSHA-first) · committed harness ≠ ephemeral `/tmp` proof · the **persistence law** (record the
verdict + SendMessage before idle) · `echo_mq` not under `mix format` · **spec home convention:** `specs/` =
chapter triads only, decomposition → `specs/emq.N/`, ledgers → `specs/progress/`.

## The pipeline (2026-06-17 recalibration, D-1 — Operator-directed)

**Venus** = spec-steward + strawman spec author; frames the seam forks as four-part Arms (Rationale/5W/Steelman/
Steward, per `docs/aaw/aaw.architect-approach.md`). **Director** = orchestrator: rules each Arm with the Operator
via the **mandatory `AskUserQuestion`**, then independently **verifies code + invariants**, then consolidates the
rung's findings+learnings for Apollo. **Mars** = PRIMARY code-quality gate (the gate ladder + the adversarial
battery: declared-keys, mutation kill-rate w/ `SCRIPT FLUSH`, order theorem) + the story-gen coverage (moved from
Apollo). **Apollo = the Mentor ONLY**, out of the per-rung pipeline — folds the Director's consolidated findings
into agent calibrations (PROPOSE-ONLY, sharpen-don't-stack); the cold-run marathon is retired. Details:
`emq.program.md` + `emq.{venus,mars,apollo}.md`.

Related: [[echo-store-rename]], [[echomq-umbrella-app]], [[bcs-course]],
[[x-mode-cclin-leadteam]], [[local-valkey-replaces-redis]], [[exchange-platform]].
