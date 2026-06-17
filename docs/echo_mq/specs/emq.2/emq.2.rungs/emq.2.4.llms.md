# EMQ.2.4 · agent brief (llms) — the parity closer

> Implementation brief for the echo_mq implementor (Mars). emq.2.4 CLOSES the emq.2 full-parity cluster: it
> builds the small genuine feature residue the reconcile surfaced and ships the **complete test suite** that
> brings the shipped read/ops/watch surface to v1's scenario DEPTH, with the un-ported v1 depth explicitly
> attributed to its owning rung. Pairs with the spec [`./emq.2.4.md`](emq.2.4.md) and the stories
> [`./emq.2.4.stories.md`](emq.2.4.stories.md). NO-INVENT: every reference is a real module/file or a design
> §; every depth scenario drives a verb `echo_mq` actually ships. **HIGH-RISK** → Apollo MANDATORY + the ≥100
> determinism loop. Framing: third person; no gendered pronouns, no perceptual/interior-state verbs for agents
> or software (components read, compute, refuse, return) — propagate this clause in any sub-prompt.

## References

- [`./emq.2.4.md`](emq.2.4.md) — the spec body (the §0 gap table, the two-part scope, D1–D8, INV1–INV8, **The
  surfaced fork**). Read FIRST; it is authoritative.
- [`./emq.2.4.stories.md`](emq.2.4.stories.md) — the user stories + Given/When/Then acceptance + the Coverage
  line. The acceptance face of the contract.
- [`./emq.2.design.md`](../emq.2.design.md) — the carve + the ADRs (ADR-1 the read→ops→watch carve, ADR-2 the
  parity/family boundary that fixes what is emq.2.4 vs emq.6/emq.8/emq.3/emq3.2). The boundary that keeps the
  test mandate honest.
- [`../emq.features.md`](../../../emq.features.md) — the feature catalog + the v1→v2 parity-proof table (B.1 lib /
  B.2 scripts / B.3 verdict). The map of what is shipped vs deferred.
- The shipped surface (the verbs to TEST AT DEPTH — re-probe at the pre-build reconcile; line numbers are
  hints):
  - `echo/apps/echo_mq/lib/echo_mq/metrics.ex` — `get_counts/3` (a state LIST), `get_job/3`, `get_job_state/3`,
    `get_metrics/3`, `get_deduplication_job_id/3`, `get_rate_limit_ttl/3`, `get_global_rate_limit/2`,
    `is_maxed/2`, `lane_depth/3`, `lane_depths/3`.
  - `echo/apps/echo_mq/lib/echo_mq/admin.ex` — `pause/2`, `resume/2`, `drain/3`, `obliterate/3`.
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — `update_data/4`, `update_progress/4`, `add_log/5`,
    `get_job_logs/3`, `remove_job/4`, `reprocess_job/3`, `extend_lock/5` (`jobs.ex:646`), `extend_locks/4`
    (`jobs.ex:671`); the `@complete` (`jobs.ex:139`) / `@retry` (`jobs.ex:173`) metrics-counter writes (for the
    optional D3 `:data` series).
  - `echo/apps/echo_mq/lib/echo_mq/events.ex` (`EchoMQ.Events`) — `subscribe/2`, `unsubscribe/2`, `close/2`,
    `channel/1`, `publish/5`; `echo/apps/echo_mq/lib/echo_mq/telemetry.ex` (module `EchoMQ.Meter`) — `attach/4`,
    `attach_many/4`, `emit/3`, `span/3`; `stalled_checker.ex` (module `EchoMQ.Stalled`) — `check/3`,
    `job_stalled?/4`; `cancellation_token.ex` (module `EchoMQ.Cancel`) — `new/0`, `cancel/3`, `check/1`,
    `check!/1`; `lock_manager.ex` (+ `lock_manager/core.ex`; modules `EchoMQ.Locks` + `EchoMQ.Locks.Core`) —
    `track_job/3`/`untrack_job/2`/the read trio (the FILE basenames lag the modules until the C1 carry).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `scenarios/0` (the **37** today, `conformance.ex:25`) +
    `run/2`; the pins `test/conformance_scenarios_test.exs` (`@run_order`) + `test/conformance_run_test.exs`
    (`run/2 → {:ok, 37}`).
- The capability reference (the DEPTH to port — `echo/apps/echomq/test/echomq/`, READ-ONLY, never edited):
  `queue_getters_test.exs` (read depth), `queue_integration_test.exs` (read + ops paths),
  `rate_limiter_integration_test.exs` (the rate read), `obliterate_test.exs` (obliterate depth),
  `queue_events_integration_test.exs` (events depth), `worker_cancellation_test.exs` (the cancel + lock paths),
  and the lock/stalled paths in `worker_integration_test.exs`. **NOT** the worker-abstraction /
  `telemetry/opentelemetry_test.exs` / `flow_producer_test.exs` / `job_scheduler_*_test.exs` / `stress` /
  `concurrency_*` / `high_concurrency` / `redis_baseline` files (those are emq.6 / emq.8 / emq.3 / emq.1 / the
  ≥100 loop — D8 attributes them, the build does NOT port them).
- The program law: [`../emq.design.md`](../../../emq.design.md) §5 (the wire-class registry — `EMQRATE` reused, no
  new class), §6 (the grammar — the `metrics:*:data` suffix), §7 (the GWT gate), §8 (the engine-hygiene test),
  §11.12 (the escalation protocol — a depth test that fails is a finding), §The master invariant (the ≥100 loop
  replaces dedicated stress files); the gate ladder + the per-app testing law: `.claude/skills/echo-mq-program.md`.

## Requirements

- **EMQ.2.4-R1** — no build artifact exists until the §6 rate-gate fork (G1) is Operator-recorded; the triad
  re-derives D2 to the ruled arm at the pre-build reconcile. [US: EMQ.2.4-US1]
- **EMQ.2.4-R2** — under Arm 2 (recommended): `Metrics.is_maxed/2` + `EMQRATE` ship unchanged; the
  consult-before-claim contract is documented; a `:valkey` test drives consult-then-skip; **no `@claim`/`@gclaim`
  byte change**. Under Arm 1 (if ruled): the claim path reads `meta.concurrency` vs `ZCARD active` and refuses
  `EMQRATE` before popping; the `claim`/`rate`/`limit`/`rotate` scenarios are re-verified
  byte-identical-or-updated. [US: EMQ.2.4-US2]
- **EMQ.2.4-R3** — D3: the metrics `:data` rolling series is **RULED held to emq.8** (Operator, ledger D-4,
  2026-06-14). emq.2.4 writes **no** `:data` series; `get_metrics/3`'s `data_points` stays honest-0 (it `LLEN`s
  the unwritten `metrics:<which>:data` list); `@complete`/`@retry` are unchanged on the metrics-series side; the
  triad records the hold. The build does NOT write the series (the build-path the reconcile costed is the
  recorded emq.8 alternative only). [US: EMQ.2.4-US3]
- **EMQ.2.4-R4** — D4: the `de:` orphan is documented as the declared-keys honest limit (no `SCAN`, no stored
  backref); a `:valkey` test asserts the bounded-complete release (a `de:` key released by `remove_job/4` with
  its `dedup_id` and by drain is gone; an orphan with no referrer is acknowledged un-swept). [US: EMQ.2.4-US4]
- **EMQ.2.4-R5** — D5 `metrics_depth_test.exs`: the read verbs at depth — counts under concurrent
  enqueue/claim/complete equal the cardinalities; state across every set + `:unknown`/`:absent`; metrics
  monotone under repeated completion/dead; rate at/below/above the ceiling; lane reads over multiple populated
  groups. Read-only (INV2: no transition). [US: EMQ.2.4-US5]
- **EMQ.2.4-R6** — D6 `admin_depth_test.exs`: the operator verbs at depth — pause gates flat AND grouped
  claims; drain spares active + the repeat registry; obliterate clears a fully-populated paused queue + refuses
  non-paused/live-active (changing nothing); the mutations + their typed refusals (`EMQLOCK`/`EMQSTATE`/typed
  absent). [US: EMQ.2.4-US6]
- **EMQ.2.4-R7** — D7 `watch_depth_test.exs`: the watch verbs at depth — lock-extend survives the reaper past
  the original deadline + `EMQSTALE` + the batch un-extendable; the stalled sweep below/at the threshold +
  `job_stalled?`; events over the seam + across a reconnect; the telemetry handler; the cooperative token. The
  process-touching parts run the **≥100-iteration determinism loop**. [US: EMQ.2.4-US7]
- **EMQ.2.4-R8** — D8: the un-ported v1 depth is explicitly attributed (worker → emq.6, OTel → emq.8,
  distributed cancel → emq.6, flow → emq.3, scheduler → emq.1, stress files → the ≥100 loop); **no scenario
  tests an unshipped rung's surface** (INV2 — a false-green is forbidden); the **37 prior conformance scenarios
  pass byte-unchanged** and the count re-pins **37 → N** in both pinning tests (the additive-minor law). [US:
  EMQ.2.4-US8]
- **EMQ.2.4-R9** — the Valkey gate holds: the depth suites + `Conformance.run/2` run on the truth row (Valkey
  6390); every exercised key is grammar-total (design §6); the engine-hygiene gate passes (§8); honest-row
  reporting; Apollo re-runs the ladder + the ≥100 loop independently (MANDATORY). [US: EMQ.2.4-US-GATE]
- **EMQ.2.4-R10** — boundary + process laws: the diff stays inside `echo/apps/echo_mq` (Arm 2 touches no
  `echo_wire`; Arm 1 would touch the claim path only); `apps/echomq` is untouched (the capability reference);
  per-app testing only (umbrella-wide `mix test` banned); agents run no git; the Director commits by pathspec.
  [US: EMQ.2.4-US8]

## Execution topology

```text
Runtime (unchanged by emq.2.4 except the optional D3 + the ruled-arm D2):
  the as-built bus — EchoMQ.{Jobs, Admin, Metrics, Lanes, Consumer, Pump, Repeat, Backoff}
    over EchoMQ.Keyspace (braced emq:{q}:) over the EchoWire facade (Connector, RESP3, Script)
  the watch plane (emq.2.3, shipped 3c6461ff) — EchoMQ.{Events, Meter, Locks(+Locks.Core), Stalled,
    Cancel} + Jobs.extend_lock(s) — opt-in supervised processes beside the Consumer
    (the FILES still basename the v1 way — telemetry/lock_manager/stalled_checker/cancellation_token.ex —
     until the Stage-1 C1 carry renames them to meter/locks/stalled/cancel.ex; cite the MODULE name)
  emq.2.4 adds NO new runtime module; it adds TEST suites + (optional D3) a metrics-series write inside the
    EXISTING @complete/@retry transitions + (ruled Arm 1 only) a ceiling read inside the EXISTING @claim/@gclaim
  the truth row: Valkey on 6390; the engine gate + the conformance harness assert against it
```

```text
Tasks (each step leaves echo_mq compiling --warnings-as-errors; per-app only):
  0. RECONCILE (lag-1) — re-probe the shipped surface (metrics/admin/jobs/events/telemetry/stalled/cancel/
     lock_manager verbs + arities), the conformance count (= 37), the two pins; confirm the v1 reference depth
     files. Classify MATCH/STALE/INVENTED/MISSING. BLOCK on any STALE/INVENTED/MISSING.
  1. D1 — confirm the §6 rate-gate fork is Operator-RULED (the gate); re-derive D2 to the arm. No artifact first.
  2. D2 — the rate-gate residue to the ruled arm (Arm 2: the documented contract + a consult-then-skip test,
     @claim byte-unchanged; Arm 1: the @claim ceiling read + re-verify the 4 scenarios).
  3. D5 — metrics_depth_test.exs (read depth; read-only; multi-seed sweep).
  4. D6 — admin_depth_test.exs (ops depth; the read plane is the lens; the typed refusals fired).
  5. D7 — watch_depth_test.exs (watch depth; the ≥100 loop for the process-touching parts).
  6. D3 — the metrics :data series HELD to emq.8 (ruled D-4) — record the hold, write no series; does not block D5–D7.
  7. D4 — the de: orphan documented + the bounded-complete release test.
  8. D8 — the attribution record; register the genuine NEW depth scenarios in conformance.ex; re-pin 37 → N in
     BOTH pin tests, the 37 prior byte-unchanged.
  9. GATE — per-app compile; pure + :valkey + process suites; Conformance.run/2 → {:ok,N}; the ≥100 loop (D7);
     the engine-hygiene test; honest-row. THEN Apollo re-runs it all independently (MANDATORY).
Touched files (both forks ruled — Arm 2 + the D-4 hold — so NO @claim/@gclaim edit and NO :data series write;
the only lib/ MUTATIONS are the C1 file renames + the conformance scenarios):
  NEW: test/metrics_depth_test.exs, test/admin_depth_test.exs, test/watch_depth_test.exs, test/rate_consult_test.exs (D2 Arm-2)
  RENAME (C1 — module already renamed, file basename lags): lib/echo_mq/telemetry.ex→meter.ex,
        lib/echo_mq/lock_manager.ex→locks.ex (+ lock_manager/core.ex→locks/core.ex),
        lib/echo_mq/stalled_checker.ex→stalled.ex, lib/echo_mq/cancellation_token.ex→cancel.ex (+ the test files
        referencing them, if any basename-coupled); a pure rename — no module-body change
  EDIT: lib/echo_mq/conformance.ex (the new scenarios + count), test/conformance_scenarios_test.exs +
        test/conformance_run_test.exs (re-pin 37→N); test/dedup_bound_test.exs (D4) or fold into an existing ops test
  NOT EDITED (the ruled arms foreclose them): lib/echo_mq/jobs.ex @claim/@gclaim + metrics-series side (Arm 2 +
        D-4 hold — byte-unchanged); lib/echo_mq/metrics.ex (no Arm-1 wiring); echo/apps/echo_wire (Arm 2)
  UNTOUCHED: echo/apps/echomq (the reference), echo/apps/echo_wire (Arm 2), echo/mix.lock (no new dep)
```

## Agent stories

- **EMQ.2.4-AS1** [implements EMQ.2.4-US1] — Directive: confirm the §6 rate-gate fork is Operator-ruled in the
  ledger; re-derive D2 (this brief + the spec) to the ruled arm; record the reconcile delta (the shipped
  surface, the conformance count = 37, the pins). Acceptance gate: the fork ruling is in the ledger and no
  `.ex`/test artifact predates it; the reconcile table is BUILD-GRADE (every claim MATCH or `[RECONCILE]`).
- **EMQ.2.4-AS2** [implements EMQ.2.4-US2] — Directive: close the rate-gate residue to the ruled arm — Arm 2:
  document the consult-before-claim contract + write the consult-then-skip `:valkey` test, `@claim`
  byte-unchanged; Arm 1: edit `@claim`/`@gclaim` to read `meta.concurrency` vs `ZCARD active` and refuse
  `EMQRATE`, then re-verify the `claim`/`rate`/`limit`/`rotate` scenarios. Acceptance gate: Arm 2 → `git diff
  jobs.ex` shows `@claim`/`@gclaim` unchanged + the consult-then-skip test green; Arm 1 → the four scenarios
  re-verified byte-identical-or-updated + the transition-refuse test green.
- **EMQ.2.4-AS3** [implements EMQ.2.4-US5] — Directive: write `metrics_depth_test.exs` porting the v1 read
  depth (`queue_getters`/`queue_integration`/`rate_limiter_integration`) against the shipped `Metrics` verbs —
  counts under concurrency, state across sets, metrics monotone, rate at the edges, lane reads over groups.
  Acceptance gate: the suite is green on Valkey 6390 and passes the multi-seed sweep; every test drives a
  shipped `Metrics` verb (no unshipped surface).
- **EMQ.2.4-AS4** [implements EMQ.2.4-US6] — Directive: write `admin_depth_test.exs` porting the v1 operator
  depth (`obliterate`/`queue_integration` paths) against `Admin` + the `Jobs` mutations — pause gates both
  claims, drain spares active + repeat, obliterate clears a populated paused queue + refuses, the mutations +
  their typed refusals. Acceptance gate: the suite is green; the read plane reads the asserted effects; every
  refusal (`EMQLOCK`/`EMQSTATE`/typed absent) is exercised.
- **EMQ.2.4-AS5** [implements EMQ.2.4-US7] — Directive: write `watch_depth_test.exs` porting the v1 watch depth
  (`queue_events_integration`/`worker_cancellation` + the lock/stalled paths) against `Events`/`Meter`/the
  lock plane (`Locks`)/`Stalled`/`Cancel` — lock-extend survives the reaper + `EMQSTALE`, the stalled
  sweep below/at the threshold, events over the seam + across a reconnect, the telemetry handler, the token;
  run the process-touching parts under the ≥100 loop. Acceptance gate: the suite is green AND the ≥100
  determinism loop is 100/100 owning the machine.
- **EMQ.2.4-AS6** [implements EMQ.2.4-US3] — Directive: record the metrics `:data` series as **held to emq.8**
  (the RULED D-4 hold) — emq.2.4 writes NO `:data` series; `@complete`/`@retry` are unchanged on the
  metrics-series side; `get_metrics/3`'s `data_points` stays honest-0 (it `LLEN`s the unwritten
  `metrics:<which>:data`). Do NOT build the rolling series. Acceptance gate: `get_metrics/3` reads `data_points`
  0; `git diff jobs.ex` shows `@complete`/`@retry` unchanged on the series side; the triad records the hold.
- **EMQ.2.4-AS7** [implements EMQ.2.4-US4] — Directive: document the `de:` orphan as the declared-keys honest
  limit (no `SCAN`, no backref — the rejection reasons recorded) + write the bounded-complete release test (a
  `de:` key released by `remove_job/4` with its `dedup_id` and by drain is gone; an orphan is acknowledged
  un-swept). Acceptance gate: the test is green and the triad records why a sweep/backref is rejected.
- **EMQ.2.4-AS8** [implements EMQ.2.4-US8, EMQ.2.4-US-GATE] — Directive: record the attribution (the un-ported
  v1 depth → its owning rung); register the genuine NEW depth scenarios in `conformance.ex` `scenarios/0` with
  their probes; re-pin **37 → N** in both pin tests, the 37 prior byte-unchanged; run the full gate ladder +
  the engine-hygiene test; hand to Apollo for the independent re-run. Acceptance gate: `Conformance.run/2 →
  {:ok, N}`; `git diff conformance.ex` shows the 37 prior entries byte-identical; both pins assert N; the
  engine-hygiene test green; Apollo's independent ladder + ≥100 loop green; no test drives an unshipped surface.

## Execution plan — first two stories

1. **EMQ.2.4-AS1 — the fork gate + the reconcile.** No file written yet. Confirm the ledger carries the
   Operator's G1 ruling (Arm 2 recommended). Re-probe `metrics.ex`/`admin.ex`/`jobs.ex`/the watch modules +
   `conformance.ex` (`scenarios/0` == 37, both pins) + the v1 reference depth files; classify every claim
   MATCH/STALE/INVENTED/MISSING; BLOCK on any non-MATCH. Re-derive D2's text to the ruled arm. Gate: the ruling
   is recorded, no artifact predates it, the reconcile is BUILD-GRADE.
2. **EMQ.2.4-AS2 — the rate-gate residue.** Under Arm 2: add the consult-before-claim contract to the docs +
   `test/rate_consult_test.exs` (enqueue past the ceiling, `is_maxed/2 → {:error,:rate}`, skip the claim, assert
   the active set stayed at the ceiling); `TMPDIR=/tmp mix compile --warnings-as-errors` (exit 0); `TMPDIR=/tmp
   mix test test/rate_consult_test.exs --include valkey` (green). `git diff lib/echo_mq/jobs.ex` shows
   `@claim`/`@gclaim` byte-unchanged. Gate: the test is green and the shipped claim scripts are untouched.

## Comprehensive implementation prompt

```text
You are the echo_mq implementor (Mars) building emq.2.4 — the FINAL rung of the emq.2 full-parity cluster:
the parity CLOSER. Load the echo-mq-implementor skill + .claude/skills/echo-mq-program.md. Read emq.2.4.md
(the spec — authoritative), emq.2.4.stories.md (the acceptance), and emq.2.design.md (the carve/ADR-2
boundary). Framing: third person; no gendered pronouns; no perceptual/interior-state verbs for agents or
software (components read, compute, refuse, return).

THE CONTRACT. emq.2.4 (1) closes the small genuine feature residue the reconcile surfaced and (2) ships the
COMPLETE TEST SUITE that brings the SHIPPED read/ops/watch surface to v1's scenario DEPTH — with the un-ported
v1 depth EXPLICITLY ATTRIBUTED to its owning rung. The single hardest rule (INV2): every depth scenario drives
a verb echo_mq ACTUALLY SHIPS; NO test exercises an unshipped rung's surface (worker abstraction → emq.6, OTel
contract → emq.8, distributed cancel → emq.6, flows → emq.3, durable stream → emq3.2) — a test for a feature
that does not exist is a false-green, forbidden. The v1 stress/concurrency FILES are NOT ported; their value
(scenario diversity) is carried by the ≥100 determinism loop. apps/echomq is a capability REFERENCE (read-only,
never edited); echo_mq is the single source of truth, no migration framing.

STAGE 0 — RECONCILE (lag-1). Re-probe the shipped surface: EchoMQ.Metrics (get_counts/3 takes a state LIST,
get_job/3, get_job_state/3, get_metrics/3, get_deduplication_job_id/3, get_rate_limit_ttl/3,
get_global_rate_limit/2, is_maxed/2, lane_depth/3, lane_depths/3), EchoMQ.Admin (pause/2, resume/2, drain/3,
obliterate/3), EchoMQ.Jobs (update_data/4, update_progress/4, add_log/5, get_job_logs/3, remove_job/4,
reprocess_job/3, extend_lock/5, extend_locks/4), the watch modules (Events, Meter, Stalled.check/3,
Cancel, Locks + Locks.Core — files still basenamed telemetry/stalled_checker/cancellation_token/lock_manager.ex
until the C1 carry), conformance.ex scenarios/0 (= 37) + both pins. Classify
MATCH/STALE/INVENTED/MISSING; BLOCK on any non-MATCH and escalate to the Director. Confirm the v1 reference
DEPTH files (queue_getters/queue_integration/rate_limiter_integration/obliterate/queue_events_integration/
worker_cancellation_test.exs + the lock/stalled paths in worker_integration_test.exs) — and confirm the
EXCLUDED files (worker-abstraction / opentelemetry / flow_producer / job_scheduler / stress / concurrency_* /
high_concurrency / redis_baseline) are NOT ported.

STAGE 1 — D1 the fork gate. Confirm the G1 rate-gate fork is Operator-RULED in the ledger (Arm 2 recommended:
the documented consult-before-claim contract + the unchanged pure-read is_maxed/2, NO @claim edit; Arm 1 if
ruled: the @claim/@gclaim ceiling read). NO .ex/test artifact predates the ruling. Re-derive D2 to the arm.

STAGE 2 — D2 the rate-gate residue (to the ruled arm). Arm 2: document the consult-before-claim contract; write
test/rate_consult_test.exs (consult is_maxed/2 → {:error,:rate} → skip the claim → assert the ceiling held);
git diff jobs.ex shows @claim/@gclaim BYTE-UNCHANGED. Arm 1 (only if ruled): edit @claim/@gclaim to read
meta.concurrency vs ZCARD active and refuse EMQRATE before popping; re-verify the claim/rate/limit/rotate
conformance scenarios byte-identical-or-updated; flag the elevated risk for Apollo.

STAGE 3 — D5/D6/D7 the depth suites (the PRIMARY mandate). Port the v1 DEPTH for exactly the shipped verbs:
  • test/metrics_depth_test.exs (D5): counts under concurrent enqueue/claim/complete == cardinalities; state
    across every set + :unknown + :absent; metrics monotone under repeated completion/dead; rate at/below/above
    the ceiling; lane reads over multiple populated groups. Read-only — no transition (INV2). Multi-seed sweep.
  • test/admin_depth_test.exs (D6): pause gates BOTH Jobs.claim/3 AND Lanes.claim/3; drain on a populated
    pending(+schedule) spares active + the repeat registry; obliterate on a fully-populated PAUSED queue clears
    every set + every §6 auxiliary key (bounded :more/:ok) + refuses non-paused/live-active (changing nothing);
    remove_job clears across all four sets + refuses a locked job EMQLOCK + the caller-supplied dedup release;
    reprocess_job dead→pending + refuses non-dead EMQSTATE; update/log on in-flight + missing-job typed absent.
    The read plane (Metrics) is the acceptance lens.
  • test/watch_depth_test.exs (D7): lock-extend re-scores a member PAST its original reaper deadline (the
    extended job survives a reap that catches the un-extended) + EMQSTALE on a stale token + extend_locks
    returns the un-extendable; the stalled sweep recovers below max_stalled and dead-letters at it +
    job_stalled? reports; events delivered over the connector pub/sub seam AND surviving a reconnect; a [:emq,…]
    telemetry handler fires; the cooperative token cancel/check/check!. Run the PROCESS-TOUCHING parts under the
    ≥100 determinism loop (owning the machine — no concurrent liveness server).

STAGE 4 — D3/D4 the small residue. D3: the metrics :data series is RULED HELD to emq.8 (Operator, ledger D-4) —
write NO :data series; @complete/@retry UNCHANGED on the metrics-series side; get_metrics/3 data_points stays
honest-0 (it LLENs the unwritten metrics:<which>:data); record the hold in the triad. Do NOT build the rolling
series. D4: document the de: orphan as the declared-keys honest limit (no SCAN, no
backref — record why) + a bounded-complete release test (a de: key released by remove_job/4 with its dedup_id
and by drain is gone; an orphan is acknowledged un-swept).

STAGE 5 — D8 the close. Record the attribution (worker→emq.6, OTel→emq.8, distributed cancel→emq.6, flow→emq.3,
scheduler→emq.1-shipped, stress files→the ≥100 loop). Register the genuine NEW depth scenarios in
conformance.ex scenarios/0 with their probe bodies; re-pin 37 → N in BOTH conformance_scenarios_test.exs
(@run_order) AND conformance_run_test.exs ({:ok, N}); the 37 prior byte-IDENTICAL (git diff proves it).

STAGE 6 — THE GATE LADDER (run before reporting; per-app only). asdf current erlang (re-probe, don't hardcode);
redis-cli -p 6390 ping → PONG. TMPDIR=/tmp mix compile --warnings-as-errors (echo_mq; + echo_wire only if Arm 1
touched it). TMPDIR=/tmp mix test (pure). TMPDIR=/tmp mix test --include valkey (the :valkey + process suites).
Conformance.run/2 → {:ok, N} on 6390. The ≥100 determinism loop for the process-touching depth suites
(for i in $(seq 1 100); do TMPDIR=/tmp mix test test/watch_depth_test.exs --include valkey || break; done) —
100/100. The engine-hygiene test (design §8). Honest-row reporting (Valkey 6390 the truth row). NO umbrella-wide
mix test. NO git (the Director commits by pathspec). A depth test that FAILS is a real shipped-surface finding —
ESCALATE to the Director (design §11.12), never paper it over.

STAGE 7 — APOLLO (MANDATORY — HIGH-RISK). Hand to the dedicated evaluator: re-run the whole ladder + the ≥100
loop INDEPENDENTLY; re-verify the 37 prior conformance byte-unchanged with each new scenario probe-registered;
adversarially verify INV2 (no test drives an unshipped surface) + (Arm 1) INV1 + the order theorem.

DONE = every DoD box in emq.2.4.md checked: the fork ruled + D2 to the arm; D5–D7 green at depth + the ≥100
loop 100/100; D8 attribution recorded + 37→N re-pinned (37 prior byte-unchanged); D3/D4 settled; no regression;
Apollo's independent re-run green; the emq.2 cluster CLOSES (read+ops+watch+closer all shipped, proven at
depth).
```
