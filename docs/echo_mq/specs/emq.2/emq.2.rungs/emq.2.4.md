# EMQ.2.4 · The parity closer — the residue + the complete test suite (Movement I)

> **Status: SPECCED, not built** (the FOURTH and FINAL rung of the emq.2 full-parity cluster; the carve + the
> ADRs are [`./emq.2.design.md`](../emq.2.design.md); authored this design cycle, built a later run). emq.2.4
> is the parity-CLOSING stage: it (1) builds the small genuine residue the emq.2 ⇄ emq.2.{1,2,3} reconcile
> surfaces — the feature decisions the cluster named but left open — and (2) ships the **complete test suite**
> that closes the v1↔v2 coverage gap **for the shipped read/ops/watch surface**, porting v1's scenario DEPTH
> for exactly the verbs `echo_mq` now carries, while explicitly attributing the rest to its owning rung. The
> v1 line (`apps/echomq`) is a **capability reference** — the list of scenario depth to port — never a thing
> migrated from. emq.2.4 stands ON the whole cluster (the read plane emq.2.1, the operator plane emq.2.2, the
> watch plane emq.2.3): its tests drive exactly those shipped verbs. **HIGH-RISK** (process/mint-touching test
> work + an optional `@claim`-touching feature fork) → **Apollo MANDATORY at build** + the **≥100-iteration
> determinism loop**.

## 0 · The reconcile — the rationale (the gap table the closer opens on)

emq.2 promised a **full-parity rewrite** of the v1 capability floor `echo_mq` lacks, carved read → ops →
watch over the as-built floor ([`./emq.2.design.md`](../emq.2.design.md) ADR-1/ADR-2). The cluster delivered:
the read plane (`EchoMQ.Metrics`, 10 verbs — emq.2.1, shipped `7d98ef86`), the operator plane (`EchoMQ.Admin`
+ six `Jobs` mutations — emq.2.2, shipped `76fc947c`), the watch plane (`EchoMQ.Events`/`Meter`/
`Locks`(+`Locks.Core`)/`Stalled`/`Cancel` + `Jobs.extend_lock(s)` — emq.2.3, shipped `3c6461ff`). The
conformance set grew **18 → 37** (+6 read, +8 ops, +5 watch). The FEATURE parity for the carved floor is
**essentially complete**; the reconcile (this design cycle, ledger A-1/A-2) finds the residue concentrated in
a few recorded build deferrals and — the Operator's question — the **test DEPTH**.

**The gap table** (design-promised parity feature | owning sub-rung | as-built status | the gap):

| # | The parity feature the design/cluster named | Owner | As-built status | The gap |
|---|---|---|---|---|
| **G1** | the rate ceiling **auto-refuses an over-ceiling claim** (emq.2.1 D6/US5: "refuses an over-ceiling CLAIM") | emq.2.1 → emq.2.2 | `is_maxed/2` shipped as a **pure-read primitive** (emq.2.1 L-2(2)); the transition-side wiring was routed to emq.2.2; **emq.2.2 did not build it** | **PARTIAL — the one real feature residual → the FORK below** (closing it edits the shipped `@claim`/`@gclaim`) |
| **G2** | the metrics `:data` **rolling time-series** (the design §6 grammar registers `metrics:completed[:data]`) | emq.2.1 | only the scalar `count` is written; `get_metrics/3` reports `data_points = 0` honest-no-phantom (emq.2.1 D4 [REALIZED]) | **RULED — HOLD to emq.8** (Operator, ledger D-4, 2026-06-14): the rolling series waits for emq.8's presentation contract; emq.2.4 writes no `:data` series; `get_metrics/3` stays honest-0. EMQ.2.4-D3 records the **documented hold**, not a build. |
| **G3** | `de:*` dedup orphan **release on obliterate** | emq.2.2 | bounded-complete: `de:` released at remove/drain time; obliterate does not `SCAN` the `de:` family (emq.2.2 D4 [RECONCILE] — declared-keys honest limit) | **DEFERRED-BY-DESIGN — documented, NOT "fixed"** (a stored backref breaks the three-field row INV1; a `SCAN` breaks the A-1 law) |
| **G4** | the v1 `get_job_counts(queue, types)` **batch counts** | emq.2.1 | **COVERED** — `get_counts/3` takes a state LIST and returns the batch map in one call (`metrics.ex`, `is_list(states)`) | **— none** (confirmed not a gap; ledger A-2) |
| **G5** | the v1 **worker abstraction** (`worker.ex` pause/resume/paused?/running?/active_count, `get_next_job`, the concurrency model) | emq.6 | `EchoMQ.Consumer` is partial parity (the consume loop) | **DEFERRED — emq.6** (lifecycle controls; ADR-2) — NOT emq.2.4 |
| **G6** | `get_workers` / `get_workers_count` — the worker **registry** read | emq.6 | emq.2.3 ships the lock PLANE, not the worker roster | **DEFERRED — emq.6** — NOT emq.2.4 |
| **G7** | **distributed** cancel (a cancel from another node) | emq.6 | emq.2.3 ships the local cooperative token | **DEFERRED — emq.6** (ADR-2) — NOT emq.2.4 |
| **G8** | the telemetry **contract** (payload-shape assertions + the engine matrix) | emq.8 | emq.2.3 ships the surface that FIRES (ADR-2 two-layer split) | **DEFERRED — emq.8** — NOT emq.2.4 |
| **G9** | `export_prometheus_metrics` — the Prometheus **format** wrapper | emq.8 | the raw `get_metrics/3` read is shipped | **DEFERRED — emq.8** (presentation; emq.2.1 Scope Out) — NOT emq.2.4 |
| **G10** | the **durable replayable** event stream (ids + range reads) | emq3.2 | emq.2.3 ships the pub/sub subscription (ADR-4) | **DEFERRED — emq3.2** — NOT emq.2.4 |
| **G11** | the parent/child **flow** family (`flow_producer`) | emq.3 | — (the A-1-compatible flow design is real design work, §11.10) | **DEFERRED — emq.3** — NOT emq.2.4 |

**The verdict the closer opens on.** Three genuine feature residuals land on emq.2.4 — **G1** (a fork, see
**The surfaced fork** below), **G2** (an improvement, settled by D3's record), **G3** (documented, not fixed).
Everything else is either covered (G4) or a
deliberate deferral to a confirmed rung (G5–G11, ADR-2's boundary — **NOT padded into emq.2.4**). The PRIMARY
mandate is the **test suite** (§3, the second-half Deliverables): closing the depth residue for the shipped
read/ops/watch surface, the deferred-rung depth explicitly attributed.

## Goal

emq.2.4 closes the emq.2 parity cluster: it builds the genuine feature residue the reconcile surfaced (the
rate-gate fork resolved per **The surfaced fork** below; the optional metrics `:data` series per D3's record;
the `de:` orphan documented) and
ships the **complete test suite** that brings the shipped read/ops/watch surface up to v1's scenario DEPTH.
The capability reference for the test mandate is the frozen v1 line's matching test surface — the read depth
(`queue_getters_test.exs`, `queue_integration_test.exs`, `rate_limiter_integration_test.exs`), the operator
depth (`obliterate_test.exs` + the lifecycle paths in `queue_integration_test.exs`), and the watch depth
(`queue_events_integration_test.exs`, the lock paths in `worker_integration_test.exs`,
`worker_cancellation_test.exs`, the stalled paths) — **the multi-job, concurrent, edge-case scenarios for
exactly the verbs `echo_mq` now ships**. emq.2.4 ports that DEPTH, registers each genuine new behavior as a
conformance scenario in the same change (the additive-minor law), and runs the process-touching suites under
the ≥100-iteration determinism loop. It does **not** pad coverage for unshipped rungs: the v1
`job_scheduler` depth is emq.1's (shipped), the worker depth is emq.6's, the OTel depth is emq.8's, and the
v1 stress/concurrency cluster's value (scenario diversity) is carried by the determinism loop, not by
dedicated stress files — each attribution stated, not silently dropped.

## Rationale (5W)

- **Why** — the emq.2 cluster reached **feature** parity for the read/ops/watch floor, but the Operator
  observed the v1 line has dramatically more test depth than v2 (re-probed: v1 **534** tests / **195**
  describes / **41** files / 15,322 test LoC over 13,189 lib LoC = 1.16:1; v2 **201** / **36** / 28 files /
  3,529 over 4,083 = 0.86:1). Some of that gap maps to **deferred** v2 rungs (the worker abstraction → emq.6,
  the OTel contract → emq.8) or a **different discipline** (the ≥100 determinism loop replaces v1's dedicated
  stress files); but a **genuine residue is under-ported scenario depth for the SHIPPED surface** — the
  multi-job, concurrent, edge-case cases v1 asserts for exactly the read/ops/watch verbs `echo_mq` now carries.
  Closing that residue is what lets the cluster CLOSE and `apps/echomq`'s eventual dissolution stand on a
  proven-at-depth `echo_mq` ([`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I, the parity thesis). The
  reconcile also surfaced one open feature decision (G1, the rate-into-claim wiring emq.2.1 named and emq.2.2
  left open) and one improvement (G2, the metrics rolling series) — emq.2.4 is the rung that settles them.
- **What** — emq.2.4 builds, inside `echo/apps/echo_mq`: (1) **the feature residue** — the rate-gate
  resolution (the fork in **The surfaced fork** below; authored to the recommended Arm 2 — the pure-read
  primitive + the documented consult-before-claim contract — an Arm-1 ruling re-scopes to the `@claim` edit
  before the build); the metrics `:data` rolling series **held to emq.8** (the ruled D-4 hold — D3 records it,
  no `:data` write); the `de:` orphan documented as the declared-keys honest limit. (2) **the complete test suite** — the depth scenarios for the
  shipped read plane (counts/state/metrics/dedup/rate/lane reads under concurrency and at the edges), the
  operator plane (pause/drain/obliterate/update/log/remove/reprocess on populated multi-set queues with active
  jobs and the precondition refusals exercised), and the watch plane (lock-extend racing the reaper, the
  stalled sweep under partial-lapse and at the threshold, events across a reconnect, telemetry handler
  delivery, cooperative cancel) — each genuine new behavior a conformance scenario, the process-touching
  suites under the ≥100 loop. The exact depth set traces to the v1 test surface (Deliverables below); no
  scenario here invents a behavior the shipped surface does not have.
- **Who** — the program (the rung that lets the emq.2 cluster CLOSE and `apps/echomq` dissolve on a
  proven-at-depth bus); the bus's consumers, who gain the assurance that every queue-health, operator, and
  watch read they make is exercised at v1's depth before they build on it; the conformance harness, which
  grows by the genuine new scenarios; Apollo, who re-runs the gate ladder + the determinism loop independently
  (MANDATORY — the rung is process/mint-touching). The Exchange platform reads positions/exposure/queue-health
  and drives the work lifecycle through exactly this surface (`exchange.patterns.md` Pattern V; the Jobs
  surface, `exchange.specs.md` §Jobs); the depth proof is what makes that consumption safe. No single TRD rung
  *gates* on emq.2.4 by name (it closes the floor, it adds no feature surface a platform names), recorded not
  asserted.
- **When** — Movement I, **fourth and last of the emq.2 cluster** (emq.2.1 → emq.2.2 → emq.2.3 → **emq.2.4**;
  [`./emq.2.design.md`](../emq.2.design.md) ADR-1's dependency order, extended by this closing rung), after the
  watch plane (emq.2.3) lands. SPECCED this design cycle; BUILT a later run. The rate-gate fork (**The surfaced
  fork** below) settles with the Operator BEFORE the build (the recommended Arm 2 is the one this triad is
  authored to; an Arm-1 ruling is a cheap pre-build re-scope).
- **Where** — `echo/apps/echo_mq` only (the new depth test suites + the conformance scenario additions in
  `conformance.ex`; the rate-gate resolution and the optional `:data` series in `metrics.ex`/`jobs.ex` as
  inline `Script.new/2` attributes — the as-built convention, **not** `priv/`; the pure + `:valkey` + process
  suites). `apps/echomq` is untouched (the capability reference). `echo_wire` is untouched unless the rate-gate
  fork is ruled Arm 1 (which would touch the claim path); the recommended Arm 2 touches no `echo_wire` seam. Exact
  key, structure, and script anchors are pinned at the rung's pre-build reconcile (the lag-1 discipline) — the
  cluster's earlier builds moved the `echo_mq` surface before emq.2.4 tests it.

## Scope

- **In** — (1) **the feature residue:** the rate-gate resolution per **The surfaced fork** below (Arm 2
  recommended: the documented consult-before-claim contract + the pure-read primitive unchanged; Arm 1 if
  ruled: the `@claim`/`@gclaim` ceiling check); the metrics `:data` rolling time-series **held to emq.8** per D3
  (the ruled D-4 hold recorded — no `:data` write, `data_points` honest-0); the `de:` orphan documented as the declared-keys honest limit (a triad
  note + a test asserting the
  bounded-complete release at remove/drain time, NOT a sweep). (2) **the complete test suite** for the shipped
  surface: the read-plane depth (counts equal cardinalities under concurrent enqueue/claim/complete; state
  lookups across every set and the in-flight `:unknown`; metrics under repeated completion/dead; dedup
  read/absent; the rate read at/below/above the ceiling; lane reads over multiple populated groups); the
  operator-plane depth (pause gates flat AND grouped claims; drain on a populated `pending`+`schedule` with
  active jobs surviving + the repeat registry surviving; obliterate on a fully-populated paused queue clearing
  every set + the §6 auxiliary keys, and refusing non-paused/live-active; update_data/progress/log on
  in-flight jobs + the missing-job typed-absent; remove_job clearing across all four sets + refusing a locked
  job + the caller-supplied dedup release; reprocess_job dead→pending + refusing non-dead); the watch-plane
  depth (lock-extend re-scoring past the original reaper deadline + the `EMQSTALE` stale-token refusal + the
  batch extension returning the un-extendable; the stalled sweep recovering below the threshold and
  dead-lettering at it + `job_stalled?` reporting; events delivered to a subscriber over the pub/sub seam +
  surviving a reconnect; a `[:emq, …]` telemetry handler receiving a lifecycle event; the cooperative token
  cancel/check/check!); each genuine new behavior registered as a conformance scenario (additive minor, the
  prior set byte-unchanged); the process-touching suites (the lock plane + the stalled sweep + events) under
  the **≥100-iteration determinism loop**; pure + `:valkey` + process suites green per-app; honest-row
  reporting (Valkey on 6390 the truth row).
- **Out** — any **new feature surface** beyond the §0 residue (emq.2.4 closes the cluster, it does not open a
  new capability); the **deferred-rung depth** — the v1 **worker abstraction** + worker-registry tests
  (`worker_test.exs`, `worker_integration_test.exs` for the worker-abstraction paths → **emq.6**, NOT ported
  here), the **OTel** tests (`telemetry/opentelemetry_test.exs`, the telemetry **contract** →
  **emq.8**, NOT ported here), the **distributed-cancel** tests (→ **emq.6**), the **flow** tests
  (`flow_producer_test.exs` → **emq.3**), the **scheduler-depth** tests (`job_scheduler_*_test.exs` — emq.1's
  surface, already shipped + tested at emq.1; NOT re-ported here); the v1 **dedicated stress/concurrency
  files** (`stress_test.exs`, `high_concurrency_test.exs`, the `concurrency_*` cluster, `redis_baseline_test.exs`
  — their value is scenario DIVERSITY, carried by the **≥100 determinism loop**, NOT by dedicated stress files
  — the gate-ladder discipline, design §The master invariant); any **state-machine rebuild** (the transitions
  are emq.1/emq.2.2's, tested at depth, not rewritten); any new **wire-class** or **key type** beyond the §6
  grammar (the residue adds none; the rate-gate Arm 2 reuses the shipped `EMQRATE`; Arm 1 if ruled adds none);
  any **wire break**; any **edit to the frozen v1 line**; the in-flight `echo/apps/exchange/` +
  `docs/exchange/*`.

## Deliverables

emq.2.4 builds (forward-named; the feature residue + the depth test surface do not yet exist in `echo_mq`):

- **EMQ.2.4-D1** — **the reconcile + the fork-settlement gate (FIRST):** the §0 gap table recorded as the
  rung's rationale (this body), and the rate-gate fork (**The surfaced fork**) **settled by the Operator** before any build artifact
  — Arm 2 (the documented consult-before-claim contract; the pure-read `is_maxed/2` unchanged; no `@claim`
  edit; recommended) vs Arm 1 (the `@claim`/`@gclaim` ceiling check; the named HIGH-RISK shipped-script edit).
  Recorded BEFORE any build story runs (the cluster precedent: the design-make/seam gate is the relocated
  gate). The recommended Arm 2 is the carve this triad is authored to; an Arm-1 ruling re-scopes D2 before the
  build.
- **EMQ.2.4-D2** — **the rate-gate resolution (the feature residue, G1):** under **Arm 2** (recommended) —
  the triad documents the **consult-before-claim** contract (a claimer calls `Metrics.is_maxed/2` before
  `Jobs.claim/3`/`Lanes.claim/3` and skips the claim on `{:error, :rate}`), matching the v1 parity (v1
  `isMaxed-2` is a **pre-claim** read the worker calls, not a step inside `moveToActive-11`); the pure-read
  `is_maxed/2` + `EMQRATE` ship unchanged; **no `@claim` edit**. A `:valkey` test exercises the
  consult-then-skip path end to end. Under **Arm 1** (if the Operator rules it) — `@claim`/`@gclaim` read
  `meta.concurrency` vs `ZCARD active` FIRST and refuse `EMQRATE` (or short-circuit empty) before popping; the
  `claim`/`rate`/`limit`/`rotate` conformance scenarios are re-verified byte-identical-or-updated; the edit is
  the named HIGH-RISK change (Apollo re-verifies INV1 + the order theorem). The triad re-derives D2 to the
  ruled arm at the pre-build reconcile.
- **EMQ.2.4-D3** — **the metrics `:data` rolling series (the improvement, G2) — RULED: the documented hold to
  emq.8** (Operator, ledger D-4, 2026-06-14, at the build launch). emq.2.4 writes **no `:data` series**; the
  triad records the hold to emq.8's presentation contract (the emq.2.1 L-2(1) routing), and `get_metrics/3`'s
  `data_points` stays **honest-0** (the read already `LLEN`s the unwritten `metrics:<which>:data` list and
  reports 0 — no phantom; `metrics.ex` `get_metrics/3`). The build does **not** write the series and does not
  silently choose; D3 is satisfied by recording the hold, not by a build artifact. (The build-path the
  reconcile costed, kept as the recorded alternative for emq.8: `@complete`/`@retry` would `LPUSH`+`LTRIM` the
  completion/dead timestamp onto the §6-registered `emq:{q}:metrics:completed:data`/`:failed:data` list under
  the declared base root, declared-keys-clean, and `get_metrics/3` would then report a real `data_points` with
  no read-side change.) This Deliverable does not block the test mandate.
- **EMQ.2.4-D4** — **the `de:` orphan, documented (G3):** the triad records the bounded-complete dedup release
  as the declared-keys honest limit (no `SCAN` of the `de:` family — it would cross slots and break the A-1
  law; no stored backref — it would change the three-field row the conformance set pins, INV1), and a
  `:valkey` test asserts the **bounded-complete** behavior: a `de:` key released by `remove_job/4` (with its
  caller-supplied `dedup_id`) and by drain is gone, while an orphan with no live referrer is acknowledged
  un-swept (the honest limit asserted, not papered over). No new sweep; no key change.
- **EMQ.2.4-D5** — **the read-plane depth suite:** the v1 read-depth scenarios re-derived against the shipped
  `EchoMQ.Metrics` verbs — counts equal the structure cardinalities under concurrent enqueue/claim/complete;
  the state lookup across every set + the in-flight `:unknown` + the `:absent`; metrics under repeated
  completion and dead-letter (the counter monotone); the dedup read/absent; the rate read at/below/above the
  ceiling; the lane reads over multiple populated groups. A new `:valkey` suite (e.g.
  `metrics_depth_test.exs`); the genuine new verdicts registered as conformance scenarios where they assert a
  behavior the existing read scenarios do not (additive minor).
- **EMQ.2.4-D6** — **the operator-plane depth suite:** the v1 operator-depth scenarios re-derived against
  `EchoMQ.Admin` + the `Jobs` mutations — pause gates BOTH the flat `Jobs.claim/3` and the grouped
  `Lanes.claim/3`; drain on a populated `pending` (+ `schedule`) with active jobs surviving and the repeat
  registry surviving; obliterate on a fully-populated paused queue clearing every set + every §6 auxiliary key,
  bounded `:more`/`:ok`, and refusing non-paused / live-active (changing nothing); update_data/progress/log on
  in-flight jobs + the missing-job typed-absent; remove_job clearing across all four sets + refusing a locked
  job (`EMQLOCK`, untouched) + the caller-supplied dedup release; reprocess_job dead→pending + refusing
  non-dead (`EMQSTATE`, untouched). A new `:valkey` suite (e.g. `admin_depth_test.exs`); the genuine new
  verdicts registered as conformance scenarios where they extend the existing ops scenarios (additive minor).
- **EMQ.2.4-D7** — **the watch-plane depth suite:** the v1 watch-depth scenarios re-derived against
  `EchoMQ.Events`/`Meter`/`Locks`(+`Locks.Core`)/`Stalled`/`Cancel` + `Jobs.extend_lock(s)` — the
  lock-extension re-scoring a member past its original reaper deadline (the extended lease survives a reap that
  would have caught the un-extended one) + the `EMQSTALE` stale-token refusal + the batch `extend_locks`
  returning the un-extendable ids; the stalled sweep recovering a lapsed job below the `max_stalled` threshold
  and dead-lettering at it + `job_stalled?` reporting the marked state; events delivered to a subscriber over
  the connector pub/sub seam AND surviving a reconnect (the emq.1 resubscribe set); a `[:emq, …]` telemetry
  handler receiving a job-lifecycle event; the cooperative token `cancel`/`check`/`check!`. The
  **process-touching** parts (the `Locks` timer, the `Stalled` sweep, the `Events` subscription)
  run under the **≥100-iteration determinism loop** (the lock plane + the sweep run on timers; the master
  invariant gate ladder). A new `:valkey`/process suite (e.g. `watch_depth_test.exs`); the genuine new verdicts
  registered as conformance scenarios where they extend the existing watch scenarios (additive minor).
- **EMQ.2.4-D8** — **the test-attribution record + the proof:** a triad section (and the test suites' module
  docs) **explicitly attributing** the un-ported v1 depth to its owning rung — the worker abstraction +
  worker-registry depth → emq.6, the OTel/telemetry-contract depth → emq.8, the distributed-cancel depth →
  emq.6, the flow depth → emq.3, the scheduler depth → emq.1 (already shipped + tested), and the dedicated
  stress/concurrency files → the ≥100 determinism loop (scenario diversity, not dedicated files) — so the
  coverage is closed for the shipped surface and **honestly bounded** for the rest (no padding for unshipped
  rungs). The conformance set grows by the genuine new scenarios D5–D7 register (the prior **37** byte-unchanged
  — the additive-minor law — the count re-pinned **37 → N** in both pinning tests); pure + `:valkey` + process
  suites green per-app; the ≥100 determinism loop green for the process-touching suites (D7); honest-row
  reporting (Valkey on 6390 the truth row); Apollo re-runs the whole ladder + the loop independently
  (MANDATORY).

## Invariants

- **EMQ.2.4-INV1** — the wire law: zero wire breaks; emq.2.4 adds no key *type* outside the §6 grammar (the
  optional `:data` series is the §6-registered `metrics:*:data` suffix; the rate-gate Arm 2 reuses the shipped
  `EMQRATE`; Arm 1 if ruled adds no type and no class); every conformance addition is an additive protocol
  minor registered with its probe in the same change; **the 37 prior conformance scenarios pass byte-unchanged**
  (name + contract + verdict body identical, git-verified) and the registry grows additively to the new total
  re-pinned in both pinning tests. The five-code fence union stands unextended; no new wire class.
- **EMQ.2.4-INV2** — the test suite closes the gap for the **shipped** surface only, and is **honestly
  bounded**: every new depth scenario drives a verb `echo_mq` actually ships (the read/ops/watch surface
  emq.2.1/2.2/2.3 built); **no scenario tests an unshipped rung's surface** (no worker-abstraction, no OTel
  contract, no distributed-cancel, no flow, no durable-stream test) — the un-ported depth is attributed to its
  owning rung in D8, never silently dropped and never padded. A test for a feature that does not exist is a
  false-green; INV2 forbids it.
- **EMQ.2.4-INV3** — the prior suites stay green (no regression): emq.2.4 adds test coverage and the small §0
  residue; it does not change a shipped transition's behavior except under a ruled Arm-1 rate-gate fork (and
  then only the claim path, re-verified byte-identical-or-updated). The emq.1 + emq.2.1/2.2/2.3 suites + the
  `Conformance.run/2` pass unchanged; a depth test that fails reveals a real defect in the shipped surface (a
  finding, escalated — design §11.12), never a spec defect papered over.
- **EMQ.2.4-INV4** — declared keys, self-justified: any new Lua (the optional `:data` series write; the
  Arm-1 claim-gate read if ruled) is in `KEYS[]` or derived in-script only from a declared `KEYS[n]` root by
  the registered grammar (the master invariant; the A-1 lint); new scripts follow the inline `Script.new/2`
  convention (there is **no `priv/`** in `echo_mq`). The depth tests assert against the as-built keyspace; they
  construct no key outside the §6 grammar.
- **EMQ.2.4-INV5** — branded identity at every job boundary: every depth test that mints or targets a job keys
  the job position through `Keyspace.job_key/2`, which gates `BrandedId.valid?/1` and raises before any wire;
  the multi-job depth scenarios mint **distinct** branded ids per job (the order theorem — two jobs, two ids in
  mint order), and the determinism loop is what surfaces a same-millisecond mint collision (the master-invariant
  hazard — one green run is not proof).
- **EMQ.2.4-INV6** — the family boundary holds (ADR-2): emq.2.4 closes the **emq.2 cluster's** read/ops/watch
  floor and tests exactly it; the worker abstraction / worker-registry / distributed cancel are **emq.6**, the
  telemetry contract / Prometheus export are **emq.8**, the durable stream is **emq3.2**, flows are **emq.3** —
  emq.2.4 ships no feature and no test that pre-empts a family rung, and re-ships no shipped surface (the §0
  residue G1–G3 is the floor the cluster named, not a family).
- **EMQ.2.4-INV7** — the determinism discipline binds the process-touching work: the lock-plane, stalled-sweep,
  and events depth suites (D7) run the **≥100-iteration determinism loop** owning the machine (no concurrent
  liveness server, no sibling heavy I/O); one green run is NOT proof (the master-invariant gate ladder). The
  read/ops depth suites (D5/D6), being synchronous deterministic round-trips with no minting timer, run the
  multi-seed sweep as the honest determinism posture (the emq.2.1 precedent — running the loop on a
  non-process suite would forge load the rung did not introduce).
- **EMQ.2.4-INV8** — the fork + risk gate: no build artifact exists until EMQ.2.4-D1's rate-gate fork is
  Operator-recorded; this triad ships as SPECCED and every surface is written "emq.2.4 builds", never as
  shipped. The rung is **process/mint-touching** (the watch depth suites) **and** carries an optional
  shipped-script-touching feature fork (Arm 1) → **HIGH-RISK** → **Apollo is MANDATORY at build** (the
  dedicated evaluator re-runs the gate ladder + the ≥100 loop independently and re-verifies INV1's
  byte-unchanged conformance with each new scenario probe-registered).

## The surfaced fork — RULED Arm 2 (Operator, 2026-06-14)

> **RESOLVED: Arm 2** (ledger D-3). The Operator ruled the G1 rate-gate fork **Arm 2** (the recommended) on
> 2026-06-14: emq.2.4 holds `is_maxed/2` as the consult-before-claim pure-read, ships **no `@claim` edit**, and
> documents the contract — the faithful v1 parity, the risk kept to the test suite. EMQ.2.4-D1's gate is
> satisfied at spec time; D2 builds Arm 2 directly (no pre-build re-scope). The original surfacing is kept below
> as the decision record.

> **FORK — G1, the rate-ceiling-into-claim wiring.** The reconcile (§0, G1) found the one genuine open
> feature decision the cluster left: emq.2.1 named "the rate ceiling **refuses an over-ceiling claim**"
> (D6/US5) but shipped `is_maxed/2` as a **pure-read primitive** (L-2(2)) and routed the transition-side
> wiring to emq.2.2; emq.2.2 chose FORM b for the queue-wide pause **precisely to avoid editing the shipped
> `@claim`** (the named elevated risk) and did not wire the rate gate. So the auto-refuse is **unbuilt**, and
> closing it lands on emq.2.4 — but the close edits a shipped script. The decision is the Operator's:
>
> - **Arm 1 — wire it into the claim transition.** `@claim`/`@gclaim` read `meta.concurrency` vs `ZCARD
>   active` FIRST and refuse `EMQRATE` (or short-circuit empty) before popping. *Steelman:* operationally
>   complete — an over-ceiling claim **cannot succeed** even if a caller forgets to consult `is_maxed/2`; the
>   ceiling is enforced atomically inside the transition. *Cost:* edits emq.1's **shipped** `@claim` + emq.2.2's
>   claim path; the `claim`/`rate`/`limit`/`rotate` conformance scenarios must be re-verified
>   byte-identical-or-updated; the named HIGH-RISK shipped-script edit (Apollo re-verifies INV1 + the order
>   theorem).
> - **Arm 2 — hold the pure-read primitive + document the contract (RECOMMENDED).** Keep `is_maxed/2` as the
>   read-and-refuse a claimer consults before `claim/3`; emq.2.4 ships **no `@claim` edit**; the triad
>   documents the **consult-before-claim** contract as the parity posture. *Steelman:* this is **also the more
>   faithful v1 parity** — the v1 `isMaxed-2` is a **pre-claim** read the worker calls, **not** a step inside
>   `moveToActive-11.lua`; so Arm 2 matches the reference's own shape, and it keeps emq.2.4's whole risk surface
>   to the **test suite** (the rung's primary mandate). *Cost:* a caller that forgets to consult can over-claim;
>   the auto-refuse the emq.2.1 prose named is delivered as a documented contract, not an enforced transition.
>
> **Recommendation:** Arm 2 — cheaper, lower-risk, and more faithful to the v1 reference. This triad (D2, the
> Scope, the DoD) is authored to **Arm 2**; an **Arm-1 ruling is a cheap pre-build re-scope** of D2 before any
> build run. This is the one architecture/risk decision the Director routes to the Operator; nothing in D2
> builds until it is ruled. (The wider Arm A/Arm B parity-cluster sequencing fork — [`./emq.2.design.md`](../emq.2.design.md)
> §6 — is already settled to Arm A and not reopened here.)

## Definition of Done

- [ ] EMQ.2.4-D1: the §0 gap table recorded as the rationale; the rate-gate fork (**The surfaced fork**)
      settled by the Operator (Arm 2 recommended / Arm 1 if ruled), recorded BEFORE any build artifact (the
      gate that opens the build);
      the triad re-derived to the ruled arm at the pre-build reconcile.
- [ ] The feature residue built: the rate-gate resolution per the ruled arm (D2 — Arm 2's documented
      consult-before-claim contract + the unchanged pure-read primitive, or Arm 1's re-verified `@claim`
      ceiling check); the metrics `:data` series **held to emq.8** (the ruled D-4 hold recorded in D3; no
      `:data` write; `data_points` honest-0); the `de:`
      orphan documented + the bounded-complete release asserted (D4).
- [ ] D5–D7 the depth suites built against the **shipped** read/ops/watch verbs (INV2): read depth (counts
      under concurrency, state across sets, metrics monotone, rate at the edges, lane reads over groups);
      operator depth (pause gates both claims, drain spares active + repeat registry, obliterate clears a
      populated paused queue + refuses non-paused/live-active, the mutations + their typed refusals);
      watch depth (lock-extend survives the reaper + `EMQSTALE`, the stalled sweep below/at the threshold,
      events over the seam + across a reconnect, the telemetry handler, the cooperative token).
- [ ] EMQ.2.4-D8: the un-ported v1 depth **explicitly attributed** to its owning rung (worker → emq.6, OTel →
      emq.8, distributed cancel → emq.6, flow → emq.3, scheduler → emq.1 already-shipped, stress files → the
      ≥100 loop) — closed for the shipped surface, honestly bounded for the rest, no padding (INV2).
- [ ] The conformance set grows by the genuine new depth scenarios; **the 37 prior scenarios pass
      byte-unchanged** and the count re-pins **37 → N** in both pinning tests (INV1 — the additive-minor law).
- [ ] Pure + `:valkey` + process suites green per-app; the **≥100-iteration determinism loop** green for the
      process-touching depth suites (D7/INV7); the read/ops depth suites pass the multi-seed sweep (INV7);
      honest-row reporting (Valkey on 6390 the truth row).
- [ ] No regression (INV3): the emq.1 + emq.2.1/2.2/2.3 suites + `Conformance.run/2` pass unchanged; any depth
      test that fails is triaged as a real shipped-surface finding (escalated), never a spec defect papered
      over. **Apollo MANDATORY** (INV8): the dedicated evaluator re-ran the whole ladder + the loop
      independently and re-verified the byte-unchanged conformance.
- [ ] The emq.2 cluster CLOSES: read (emq.2.1) + ops (emq.2.2) + watch (emq.2.3) + the closer (emq.2.4) are all
      shipped and proven at depth; the spec body remains authoritative and the as-built reconcile syncs it
      post-build.

Stories: [`./emq.2.4.stories.md`](emq.2.4.stories.md) · Agent brief: [`./emq.2.4.llms.md`](emq.2.4.llms.md) ·
Runbook: [`./emq.2.prompt.md`](../emq.2.prompt.md) (the cluster runbook the Director consolidates to drive this
build + close the cluster) · Carve + ADRs: [`./emq.2.design.md`](../emq.2.design.md) (ADR-1 the carve, ADR-2 the
parity/family boundary) · The feature catalog + the parity proof: [`../emq.features.md`](../../../emq.features.md) ·
Depends on: [`./emq.2.1.md`](emq.2.1.md) (read) · [`./emq.2.2.md`](emq.2.2.md) (ops) ·
[`./emq.2.3.md`](emq.2.3.md) (watch) — the shipped surface emq.2.4 tests at depth · Roadmap:
[`../emq.roadmap.md`](../../../emq.roadmap.md) (the emq.2 ladder row) · Design: [`../emq.design.md`](../../../emq.design.md)
§5 (the closed wire-class registry — `EMQRATE` reused, no new class), §6 (the grammar — the `metrics:*:data`
suffix), §11.12 (the escalation protocol — a depth test that fails is a finding), §The master invariant (the
≥100 determinism loop replacing dedicated stress files), S-4 (Valkey the gate) · Capability reference (the test
DEPTH to port): `echo/apps/echomq/test/echomq/{queue_getters,queue_integration,rate_limiter_integration,obliterate,queue_events_integration,worker_cancellation}_test.exs` (the read/ops/watch depth — NOT the worker-abstraction / OTel / flow / scheduler / stress files, which are emq.6/emq.8/emq.3/emq.1/the-loop) · As-built floor:
`echo/apps/echo_mq/lib/echo_mq/{metrics,admin,jobs,events,telemetry,lock_manager,stalled_checker,cancellation_token,conformance}.ex`
(**[RECONCILE]** the watch-plane FILES still carry the v1-style basenames `telemetry.ex`/`lock_manager.ex`(+`lock_manager/core.ex`)/`stalled_checker.ex`/`cancellation_token.ex`, but the MODULES inside are already the collision-free names `EchoMQ.Meter`/`EchoMQ.Locks`(+`EchoMQ.Locks.Core`)/`EchoMQ.Stalled`/`EchoMQ.Cancel` — cite the module by the as-built name; the **C1 carry** Mars executes in Stage 1 renames the files to match the module: `telemetry.ex→meter.ex`, `lock_manager.ex→locks.ex`(+`locks/core.ex`), `stalled_checker.ex→stalled.ex`, `cancellation_token.ex→cancel.ex`) ·
Program front door: [`../echo_mq.md`](../../../echo_mq.md) (the reframed emq.2 row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
