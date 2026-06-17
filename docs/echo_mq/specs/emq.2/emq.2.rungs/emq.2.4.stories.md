# EMQ.2.4 · user stories — the parity closer (the residue + the complete test suite)

> Who wants the emq.2 cluster CLOSED, what they need, and how we will know it works. Each story is Connextra
> with Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/
> Implements line; the file ends with the Coverage line mapping every Deliverable to ≥1 story. The standing
> `EMQ.2.4-US-GATE` carries the Valkey gate (design §7) — a structural gate. emq.2.4 is the FINAL parity rung;
> its primary value is the **complete test suite** that brings the shipped read/ops/watch surface to v1's
> scenario depth, plus the small genuine feature residue the reconcile surfaced.

## EMQ.2.4-US1 — the fork is settled before any build

As a **program Operator**, I want the rate-ceiling-into-claim fork (G1) settled before emq.2.4 builds, so that
the rung does not silently edit a shipped script (or silently leave the auto-refuse unbuilt) — the decision is
mine, recorded, and the triad re-derives to the ruled arm.

Acceptance criteria
- Given the reconcile gap table names G1 as PARTIAL (emq.2.1 named the auto-refuse, emq.2.2 left it unbuilt),
  when emq.2.4 opens, then the fork is presented with both arms steelmanned (Arm 1 the `@claim` edit; Arm 2 the
  documented consult-before-claim contract) and the recommendation (Arm 2) — and **no build artifact exists**
  until the Operator records the ruling.
- Given the Operator rules Arm 2, when the build runs, then D2 ships the documented contract + the unchanged
  pure-read `is_maxed/2`, and no `@claim`/`@gclaim` byte changes.
- Given the Operator rules Arm 1, when the build runs, then D2 edits the claim path and the
  `claim`/`rate`/`limit`/`rotate` conformance scenarios are re-verified byte-identical-or-updated under Apollo.

INVEST — independent (the gate that precedes every build story); testable by the ledger record + the build's
touch-set (Arm 2 → `@claim` byte-unchanged; Arm 1 → the four scenarios re-verified); encodes EMQ.2.4-INV8.
Priority: must · Size: 1 · Implements deliverables: EMQ.2.4-D1.

## EMQ.2.4-US2 — the rate-gate residue is closed to the ruled arm

As a **bus consumer enqueuing under a concurrency ceiling**, I want the over-ceiling-claim behavior delivered
the way the Operator ruled, so that I can rely on a stated, tested contract — whether enforced in the
transition (Arm 1) or documented as a consult-before-claim discipline (Arm 2).

Acceptance criteria
- Given Arm 2 (recommended), when a claimer consults `Metrics.is_maxed/2` and receives `{:error, :rate}`,
  then skipping `Jobs.claim/3`/`Lanes.claim/3` leaves the active set at the ceiling — and a `:valkey` test
  drives the consult-then-skip path end to end.
- Given Arm 1 (if ruled), when a claim is attempted on a queue at its `meta.concurrency` ceiling, then the
  `@claim`/`@gclaim` transition refuses `EMQRATE` (mapped `{:error, :rate}`) before popping, moving no member.
- Given either arm, when the rate read is exercised at/below/above the ceiling, then `is_maxed/2` answers
  `:ok` below the ceiling and refuses `{:error, :rate}` (the `EMQRATE` wire refusal mapped) at/above — the
  pure-read primitive's as-built return shape (`:ok | {:error, :rate}`, NOT a boolean), unchanged.

INVEST — independent of the depth suites; testable by the consult-then-skip (Arm 2) or the transition-refuse
(Arm 1) `:valkey` test; encodes EMQ.2.4-INV1, EMQ.2.4-INV3. Priority: must · Size: 2 · Implements
deliverables: EMQ.2.4-D2.

## EMQ.2.4-US3 — throughput history reads honest-zero, the deferral recorded

As a **bus operator plotting completed/failed throughput**, I want `get_metrics/3`'s `:data` series to honestly
read zero with the hold to emq.8 recorded, so that I never read a phantom series and the deferral of the rolling
series to emq.8's presentation contract is the Operator's recorded call (G2/D-4), not a silent build default.

Acceptance criteria
- Given D3 is RULED the hold to emq.8 (Operator, ledger D-4, 2026-06-14), when `get_metrics/3` is read, then
  `data_points` reads `0` (it `LLEN`s the unwritten `metrics:<which>:data` list — read-no-series-that-is-not-
  written) and the triad records the hold; emq.2.4 writes **no** `:data` series and `@complete`/`@retry` are
  unchanged on the metrics-series side.
- Given the hold is recorded, when the triad is read, then the build-path the reconcile costed is kept as the
  recorded emq.8 alternative (`LPUSH`+`LTRIM` to the §6-registered `metrics:completed:data`/`:failed:data` under
  the declared base root) — documented, not built, so the build did not silently choose.
- Given the hold, when the metrics scalar counter is read, then `count` is real and monotone across completions
  (the emq.2.1 counter unchanged — the held series touches neither the scalar nor the read path).

INVEST — independent (does not block the test mandate); testable by the honest-0 `data_points` + the recorded
hold + `@complete`/`@retry` unchanged on the series side; encodes EMQ.2.4-INV1, EMQ.2.4-INV4. Priority: could ·
Size: 1 · Implements deliverables: EMQ.2.4-D3.

## EMQ.2.4-US4 — the dedup orphan limit is honest, not papered over

As a **bus operator removing jobs that parked idempotency keys**, I want the dedup-key release behavior
documented as a bounded-complete honest limit, so that I understand a parked `de:` key is released at
remove/drain time (with its `dedup_id`) and an orphan with no live referrer is acknowledged un-swept — never
falsely claimed complete.

Acceptance criteria
- Given a job parked a dedup key and is removed with its `dedup_id`, when `remove_job/4` runs, then the
  `de:<dedup_id>` is released IFF its value equals the job id — a `:valkey` test asserts it.
- Given a queue is drained, when the drain runs, then the drained jobs' dedup keys are released at drain time.
- Given an orphan `de:<did>` with no live referrer, when obliterate runs, then it is acknowledged un-swept
  (no `SCAN` of the `de:` family — the declared-keys honest limit, design §6/S-6) and the triad records why a
  sweep or a backref is rejected (slot-crossing / row-shape change).

INVEST — independent; testable by the bounded-complete release `:valkey` test + the triad's recorded limit;
encodes EMQ.2.4-INV4. Priority: should · Size: 1 · Implements deliverables: EMQ.2.4-D4.

## EMQ.2.4-US5 — the read plane is proven at v1's depth

As a **bus consumer and the conformance harness**, I want the shipped read verbs exercised at v1's scenario
depth, so that counts/state/metrics/dedup/rate/lane reads are trustworthy under concurrency and at the edges —
not only the single happy-path each shipped with.

Acceptance criteria
- Given concurrent enqueue/claim/complete on one queue, when `get_counts/3` is read, then each count equals
  the structure cardinality at the read instant (no drift).
- Given a job in each set and one in-flight between transitions, when `get_job_state/3` is read, then it
  answers `:pending`/`:active`/`:scheduled`/`:dead`/`:unknown`/`:absent` correctly per case.
- Given repeated completion and dead-letter, when `get_metrics/3` is read, then the counter is monotone; given
  the ceiling, the rate read answers at/below/above; given multiple populated groups, the lane reads answer
  each group's separate backlog.

INVEST — independent (read-only, no transition); testable by `metrics_depth_test.exs` (a new `:valkey` suite);
encodes EMQ.2.4-INV2, EMQ.2.4-INV5. Priority: must · Size: 3 · Implements deliverables: EMQ.2.4-D5.

## EMQ.2.4-US6 — the operator plane is proven at v1's depth

As a **bus operator driving a queue's lifecycle**, I want the shipped operator verbs exercised on populated
multi-set queues with active jobs and the precondition refusals fired, so that pause/drain/obliterate/the
mutations behave correctly under load and refuse correctly — not only on an empty queue.

Acceptance criteria
- Given a queue with a non-empty pending and live groups, when paused, then BOTH the flat `Jobs.claim/3` and
  the grouped `Lanes.claim/3` answer empty; resume restores both.
- Given a populated `pending` (+ `schedule`) with active jobs and a registered repeatable, when drained, then
  pending empties, the active jobs survive, and the repeat registry survives (future occurrences keep minting).
- Given a fully-populated **paused** queue, when obliterated, then every set + every §6 auxiliary key clears
  (bounded `:more`/`:ok`); a non-paused queue refuses `EMQSTATE` and a live-active queue refuses (unless
  forced), changing nothing; remove_job clears across all four sets and refuses a locked job `EMQLOCK`;
  reprocess_job moves dead→pending and refuses a non-dead job `EMQSTATE`; update/log on in-flight jobs rewrite
  the row/logs and a missing job is a typed absent.

INVEST — independent (the read plane is the acceptance lens); testable by `admin_depth_test.exs` (a new
`:valkey` suite); encodes EMQ.2.4-INV2, EMQ.2.4-INV3, EMQ.2.4-INV5. Priority: must · Size: 3 · Implements
deliverables: EMQ.2.4-D6.

## EMQ.2.4-US7 — the watch plane is proven at v1's depth, deterministically

As a **long-running consumer, a dashboard, and the conformance harness**, I want the shipped watch verbs
exercised at depth and under the ≥100 determinism loop, so that lease extension, stalled recovery, events, and
telemetry behave correctly under the timers and races they actually run in — proven across runs, not once.

Acceptance criteria
- Given a claimed job whose lease is extended, when the reaper runs past the ORIGINAL deadline, then the
  extended job survives the reap that would have caught the un-extended one; a stale attempts-token refuses
  `EMQSTALE`; the batch `extend_locks` returns the un-extendable ids.
- Given a job whose lease lapsed without extension, when the stalled sweep runs, then it is recovered below the
  `max_stalled` threshold and dead-lettered at it; `job_stalled?` reports the marked state.
- Given a subscriber over the connector pub/sub seam, when a lifecycle event publishes AND when the connector
  reconnects, then the subscriber receives the event and the subscription survives the reconnect; an attached
  `[:emq, …]` telemetry handler receives a lifecycle event; a cooperative token answers cancelled and `check!`
  raises.
- Given the process-touching depth suites, when the **≥100-iteration determinism loop** runs owning the
  machine, then every iteration is green (a same-millisecond mint collision or a timer race surfaces only
  across runs — one green run is not proof).

INVEST — independent (watches the shipped surface); testable by `watch_depth_test.exs` (a new `:valkey`/process
suite) under the ≥100 loop; encodes EMQ.2.4-INV2, EMQ.2.4-INV5, EMQ.2.4-INV7. Priority: must · Size: 5 ·
Implements deliverables: EMQ.2.4-D7.

## EMQ.2.4-US8 — the coverage is closed for the shipped surface and honestly bounded

As a **program reviewer and the next-rung author**, I want the un-ported v1 depth explicitly attributed to its
owning rung, so that the coverage is closed for what `echo_mq` ships and honestly bounded for what it does not
— no test for an unshipped feature (a false-green) and no silent gap.

Acceptance criteria
- Given the v1 test surface, when emq.2.4's suites are authored, then every depth scenario drives a verb
  `echo_mq` actually ships (read/ops/watch) — and **no** scenario tests the worker abstraction, the OTel
  contract, distributed cancel, flows, or the durable stream.
- Given the un-ported v1 depth, when D8 is recorded, then it is attributed by rung: worker abstraction +
  worker-registry → emq.6; OTel/telemetry-contract → emq.8; distributed cancel → emq.6; flow → emq.3;
  scheduler → emq.1 (already shipped + tested); the dedicated stress/concurrency files → the ≥100 determinism
  loop (scenario diversity, not dedicated files).
- Given the new depth scenarios, when registered, then the **37 prior conformance scenarios pass
  byte-unchanged** and the count re-pins **37 → N** in both pinning tests (the additive-minor law); the cluster
  CLOSES (read + ops + watch + closer all shipped and proven at depth).

INVEST — independent (the closing record); testable by the attribution record + the byte-unchanged conformance
+ the re-pinned count; encodes EMQ.2.4-INV1, EMQ.2.4-INV2, EMQ.2.4-INV6. Priority: must · Size: 2 · Implements
deliverables: EMQ.2.4-D8.

## EMQ.2.4-US-GATE — the Valkey gate holds across the parity close (the standing gate)

As the **program**, I want the engine gate to hold across emq.2.4's depth suites and the residue, so that the
parity close is proven on the truth row (Valkey, current stable) with honest-row reporting and the master
invariant unbroken — every key braced and grammar-total, the version fence intact, the conformance set
additive-only.

Acceptance criteria
- Given the truth row is Valkey on 6390, when the depth suites + `Conformance.run/2` run, then every key the
  exercised verbs touch is `emq:{q}:<suffix>` or a `{emq}:` reserve member (grammar-total, design §6), the
  version fence reads `echomq:2.0.0`, and the engine-hygiene gate passes (design §8); a host without Valkey
  runs the probes elsewhere and reports them as that row, never the truth row.
- Given the conformance additions, when the registry is read, then the prior **37** scenarios are byte-unchanged
  and the new depth scenarios register beside them (`run/2 → {:ok, N}`), each with its probe in the same change.
- Given the rung is process/mint-touching (and optionally `@claim`-touching under Arm 1), when it ships, then
  **Apollo** has re-run the gate ladder + the ≥100 determinism loop independently and re-verified the
  byte-unchanged conformance.

INVEST — independent (the standing structural gate); testable by `conformance_run_test.exs` (`{:ok, N}` on
6390) + the engine-hygiene test + the Apollo re-run; encodes EMQ.2.4-INV1, EMQ.2.4-INV7, EMQ.2.4-INV8.
Priority: must · Size: 2 · Implements deliverables: EMQ.2.4-D8.

---
Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5 · D6→US6 · D7→US7 · D8→US8,US-GATE.
Spec: emq.2.4.md · Agent brief: emq.2.4.llms.md.
