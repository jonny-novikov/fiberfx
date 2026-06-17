# EchoMQ — testing strategy

> How the shipped EchoMQ 2.x bus is proven: the proof stack, the given-when-then matrix that ties every
> shipped user story to the test that proves it, the coverage estimate, and the hot places that become the
> per-rung task ledgers under [`./testing/`](./testing/). Grounded in the as-built tree at `master`
> (`3298e4bc`, the emq.2.4 closer code landed; the §0 green-board is reproduced by the committed harness
> `echo/rungs/bus/emq_2_4_check.sh`) — re-probe the tree before trusting any figure here (the program's
> honest-row law; the roadmap and the working tree drift in both directions).

Canon: [`./emq.design.md`](./emq.design.md) (as-planned) · [`./emq.roadmap.md`](./emq.roadmap.md) (ladder +
statuses) · [`./emq.progress.md`](./emq.progress.md) (as-built) · the per-rung triads under
[`./specs/`](./specs/). This document is the **testing view** beside those three; it adds no contract — it
records how the contracts that shipped are proven, and where the proof is thin.

---

## 0 · emq.2.4 green-board — the observed gate record (2026-06-14)

> The honest gate-ladder record for the **emq.2.4 parity closer** (scope `emq-2-4`). The rung is **code-landed
> on `master`, gate-green, and harness-reproducible** — it is NOT yet "shipped" (the final ship is the cluster
> close: the Director's ratifying fold of the roadmap + dashboard, a later step). Three commits carry the arc:
> **`92a8f042`** (the emq.2.2 obliterate fix — `admin.ex`), **`7c2f2405`** (the Operator docs:
> features/testing/triad/ledger), **`3298e4bc`** (the closer code — the 5 C1 renames, conformance 37→43, the
> 5 depth suites). Every figure below is **output actually observed** by the committed harness
> **[`echo/rungs/bus/emq_2_4_check.sh`](../../echo/rungs/bus/emq_2_4_check.sh)** (LOOP_N=100, owning the
> machine, 2026-06-14 18:04→18:11Z — the committed transcript's run; independently reproduced by the Director
> at LOOP_N=10 and Apollo-2 at LOOP_N=100, all three runs yielding the identical board) — reproduce any line by
> re-running the harness; its committed transcript
> is [`echo/rungs/bus/emq_2_4_check.out`](../../echo/rungs/bus/emq_2_4_check.out). This replaces the prior
> cycle's ephemeral `/tmp`-tee'd proof (which evaporated on a mid-Stage-4 crash) with a committed, re-runnable
> artifact — the Operator's "Harness required". Apollo re-runs the harness independently and confirms this
> board matches reality. The rung is the FOURTH and last of the emq.2 cluster (read 2.1 → ops 2.2 → watch 2.3
> → **close 2.4**).

### Toolchain (the honest row)

| Probe | Command | Observed |
|---|---|---|
| Erlang | `asdf current erlang` (run from `echo/apps/echo_mq`) | **28.5.0.1** (source `echo/.tool-versions`) |
| Engine | `redis-cli -p 6390 ping` | **PONG** — Valkey on **6390** is the truth row (S-4) |

### Compile + suites (per-app, `echo/apps/echo_mq` — never umbrella-wide)

| Gate | Command | Observed |
|---|---|---|
| Compile | `TMPDIR=/tmp mix compile --warnings-as-errors` | **clean** (no warnings) |
| Full suite | `TMPDIR=/tmp mix test --include valkey` | **4 doctests, 250 tests, 0 failures** |
| Pure column | `TMPDIR=/tmp mix test` (no `:valkey`) | 4 doctests, 250 tests, **0 failures, 182 excluded** (the `:valkey` wire suites are excluded by default) |
| Wire column | `TMPDIR=/tmp mix test --only valkey` | 4 doctests, 250 tests, **0 failures, 72 excluded** |

The one `GenServer … terminating (stop) killed` line in the full-suite log is **not a failure** — it is the
captured-log output of the `:resubscribe` scenario's deliberate `CLIENT KILL` reconnect drill.

### Conformance (the protocol-as-parse gate, beyond the unit suites)

- `EchoMQ.Conformance.run/2` over a live 6390 → **`{:ok, 43}`** (43/43 scenarios green; verified both via
  `conformance_run_test.exs` and a direct `mix run` invocation).
- **The split: 37 prior + 6 new = 43.** Mars-1's Stage-1 grew **37 → 42** (the +5 emq.2.4 depth scenarios:
  `unknown_state`, `rate_consult`, `dedup_release`, `extend_locks_batch`, `stalled_group`); the emq.2.2
  obliterate fix adds **42 → 43** (`obliterate_grouped`). **The 37 prior pass byte-unchanged** (name +
  contract + verdict body identical — git-verified: no prior `apply_scenario` probe body appears in the
  diff's removed lines; the only `-` lines are moduledoc prose + the `cancel:` entry's added trailing comma).
- Both pins re-pinned to **43**: `conformance_scenarios_test.exs` (`@run_order`, the pure registry) and
  `conformance_run_test.exs` (`{:ok, 43}`, the wire count).

### The ≥100 determinism loop (the process-touching depth suites — owns the machine, INV7)

The harness's gate 5 (`echo/rungs/bus/emq_2_4_check.sh`, `LOOP_N` default **100**) runs, owning the machine:

```
for i in $(seq 1 100); do
  TMPDIR=/tmp mix test --include valkey \
    test/watch_depth_test.exs test/admin_depth_test.exs test/conformance_run_test.exs || break
done
```

- The three suites the loop drives: **`watch_depth`** (the lock plane / stalled sweep / events — timer- and
  pub/sub-touching), **`admin_depth`** (now carrying the **flipped** obliterate test — grouped rows cleared),
  **`conformance_run`** (drives the timer-touching `stalled_group` + the full 43-scenario run, the same-ms
  mint-collision surface).
- Result: **100/100 iterations PASSED, zero failures** — the harness's own counter, which increments only on
  an exit-0 + a `, 0 failures` ExUnit summary and `break`s on the first red iteration. One green run is NOT
  proof of determinism (the master-invariant same-ms mint hazard); the count is the loop's, reproducible by
  re-running the harness (no hand-run, no vanishing `/tmp` file).
- **Cross-run leak check (dbsize-flat):** the harness's gate 7 brackets the loop —
  `redis-cli -p 6390 dbsize` **before == after** (this run: **1 == 1**). The absolute number FLOATS run-to-run
  (Valkey carries a stable resident set between runs — it was 12 at an earlier cycle, 1 at this run); only the
  **before==after DELTA** is asserted, and it is flat — no key accumulation across the 100 iterations (each
  scenario purges its sub-queue; each depth test `on_exit`-purges its queue).

### The multi-seed sweep (the synchronous read/ops depth suites, INV7)

The deterministic-round-trip suites (no minting timer) run the multi-seed sweep instead of the loop (running
the loop on a non-process suite forges load the rung did not introduce — the emq.2.1 precedent). The harness's
gate 6 runs seeds `0, 1, 42, 312540, 999999` over `metrics_depth` (D5), `admin_depth` (D6), `rate_consult`
(D2), `dedup_bound` (D4): **all 5 seeds PASS, zero failures** (reproduce via
`echo/rungs/bus/emq_2_4_check.sh`).

### Roadmap-clearance for emq.2.4 (the cluster-close has no blocker)

| Dependency | Rung | Commit | Status |
|---|---|---|---|
| read plane | emq.2.1 | `7d98ef86` | ✅ shipped |
| operator plane | emq.2.2 | `76fc947c` | ✅ shipped |
| watch plane | emq.2.3 | `3c6461ff` | ✅ shipped |

All three dependencies are shipped on `master`; the emq.2 cluster's closing rung has **no blocker**. emq.2.4
(the residue + the depth suite + the obliterate fix) is **code-landed + gate-green + harness-reproducible**;
the cluster's formal CLOSE — the ratifying fold of the roadmap + dashboard (read + ops + watch + close all
shipped, so `apps/echomq` (the frozen v1 reference) can dissolve on a proven-at-depth `echo_mq`) — is the
Director's later step, not asserted here. This board states the rung is proven-at-depth and ready to close,
not that it has shipped.

### Boundary (faithful)

The diff stays inside `echo/apps/echo_mq`. The ruled arms held: **`jobs.ex` / `metrics.ex` / `lanes.ex` are
absent from the diff** (G1 Arm 2 = no `@claim`/`@gclaim` edit; G2 = no `:data` write). The Mars-2 touches are
`admin.ex` (the obliterate fix), `conformance.ex` (`obliterate_grouped` + the count narrative),
`admin_depth_test.exs` (the flipped finding test + a bounded-grouped test), and the two pin tests.
`echo_wire`, `apps/echomq` (frozen v1), and `mix.lock` are **untouched**.

---

## 1 · What is delivered (the scope this document proves)

The four committed rungs of the EchoMQ 2.x core, each a spec-driven increment with its triad under
`specs/`. The chain of record is the **conformance count**, which every rung grows additively while keeping
the prior scenarios byte-unchanged:

| Rung | Title | Commit | Conformance | User stories | Status |
|---|---|---|---|---|---|
| emq.0 | wire extraction + the §5 founding test pass | `a2d599c8` | → **14** | (foundation) | ✅ shipped |
| **emq.1** | scheduler + retry vocabulary | `e0fa9b03` | 14 → **18** | 7 | ✅ shipped |
| **emq.2.1** | read plane (introspection & metrics) | `7d98ef86` | 18 → **24** | 8 | ✅ shipped |
| **emq.2.2** | operator plane (lifecycle + job mutation) | `76fc947c` | 24 → **32** | 10 | ✅ shipped |
| **emq.2.3** | watch plane (events · meter · locks · stalled · cancel) | `3c6461ff` | 32 → **37** | 8 | ✅ shipped |
| **emq.2.4** | parity closer — feature residue **+ the complete test suite** + the emq.2.2 obliterate fix | `92a8f042` + `3298e4bc` | 37 → **43** | (closer) | 🔨 code-landed + gate-green (§0; close pending) |
| **emq.3.1** | the **single-queue flow** — `Flows.add/3` + `@enqueue_flow` + the `@complete` fan-in + `awaiting_children` | `emq-3-1` lead-team | 43 → **45** | 6 | ✅ shipped (HIGH-risk; Apollo BUILD-GRADE, kill 3/3; harness 9/9 + ≥100 100/100) |
| **emq.3.2** | the **child-result reads** — `Flows.children_values/3` + `dependencies/3`; **closes O1** (the real result via the existing `ARGV[5]` seam, the `@complete` Lua byte-unchanged) | `emq-3-2` cycle | 45 → **46** | 6 | ✅ shipped (NORMAL-risk; ratified — harness `emq_3_2_check.sh` 8/8, Director-reproduced) |

**33 shipped user stories** (7 + 8 + 10 + 8) across the first four emq.2.x rungs; emq.2.4 is the parity CLOSER
(the depth suite + the residue + the obliterate fix, §0). The original single `emq.2.md` (v1→v2 migration) was
**superseded 2026-06-13** and never built — it is not in scope.

**The flow family (emq.3) opens Movement I's closer.** emq.3.1 (the single-queue flow, **shipped**) + emq.3.2
(the child-result reads, **shipped**) add the parent/child flow surface — the A-1-compatible
redesign carries the dependency graph in declared §6 subkeys of the parent (the v1 data-value `parent_key` NOT
lifted). Their proof tables are §3; the per-rung ledgers are [`testing/emq.3.1.testing.md`](./testing/emq.3.1.testing.md)
+ [`testing/emq.3.2.testing.md`](./testing/emq.3.2.testing.md). The remaining sub-rungs (cross-queue → emq.3.3 ·
failure-policy + bulk → emq.3.4) stay 📋. **The post-emq.3.2 echo_mq case count is 275** (the harden track's
measured final — 4 doctests + 275 tests, 0 failures; reconciled at the rung's Stage-6 close under the
one-owner-per-file law: the code+test owner establishes it, this view records it); the per-axis breakdown is §4.

> **This document feeds emq.2.4.** The roadmap's next rung *is* "the complete test suite closing the v1↔v2
> depth gap." This strategy + the per-rung task ledgers are the grounding artifact for that build: §5's hot
> places and the `testing/emq.N.testing.md` task lists are the emq.2.4 backlog, made executable.

---

## 2 · The proof stack — five layers, each a distinct gate

EchoMQ does not have one test suite; it has **five layers of proof**, each catching what the layer below
hides. A claim is "shipped" only when its layer is green.

1. **Pure column** (`async: true`, no engine). Argument guards (`FunctionClauseError` before any wire), the
   branded-id gate at the key builder (`BrandedId.valid?/1` raises), the RESP codec, the pure decision cores
   (`Pump.Core`, `Locks.Core`, `Backoff`, `Cancel`), and the **conformance registry pin**
   (`conformance_scenarios_test.exs` — the **43** names in run order, post-emq.2.4). Runs anywhere, including
   offline CI.
2. **Wire column** (`@moduletag :valkey`, `async: false`, **Valkey on port 6390**). Every verb's behavior
   against the live engine — the truth row. Excluded by default (`ExUnit.start(exclude: [:valkey])`); run
   with `--include valkey` against a live 6390. **This is where most behavioral proof lives** (22 of
   echo_mq's 32 test files, post-emq.2.4), and it is the layer an offline run silently skips.
3. **The conformance suite** (`EchoMQ.Conformance.run/2` → `{:ok, 43}` post-emq.2.4). 43 wire-level scenarios
   that read the protocol as a parse, not prose. Its own gate beyond the unit suites — it has caught two
   harness bugs the standalone suites missed (an inverted mint-order guard; a too-early promote). Pinned two
   ways: the registry pin (pure) + the live count pin (`conformance_run_test.exs`, wire).
4. **The ≥100 determinism loop** (`for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done`). For
   process / engine / id-minting suites only — a same-millisecond branded-id mint collision flakes only
   *across* runs (the emq.0/emq.1 arc hit it). The loop must **own the machine** (no concurrent liveness
   server, no sibling heavy I/O). A pure-read rung (emq.2.1) runs a **multi-seed sweep** instead and states
   that posture honestly.
5. **The §11.2 adversarial charter** (the evaluator's probes — applied by review, not a file): the **order
   theorem** (byte = mint), **declared keys** (every Lua key in `KEYS[]` or rooted in a declared `KEYS[n]` —
   an `ARGV`-passed base is *not* a declared root), **no invented surface**, the **destructive / fence /
   at-most-once** probes, and **no catch-all** where the contract forbids one.

### The gate ladder (run before any rung reports — `echo/CLAUDE.md` §3 + the program skill)

```
1. asdf current                         # re-probe the toolchain; never hardcode a version
2. redis-cli -p 6390 ping  → PONG       # the live engine is Valkey on 6390, NOT Redis 6379
3. TMPDIR=/tmp mix compile --warnings-as-errors   # per touched app — never umbrella-wide
4. TMPDIR=/tmp mix test [--include valkey]         # per app; UMBRELLA-WIDE mix test is BANNED
5. EchoMQ.Conformance.run(conn, q) → {:ok, 43}     # the protocol-as-parse gate (post-emq.2.4)
6. for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done   # process/mint suites only
```

Process laws: agents run **no git**; the Director commits once per rung by pathspec; the diff stays inside
`echo/apps/echo_mq` (+ the one named `echo/apps/echo_wire` connector seam).

---

## 3 · The given-when-then matrix — every shipped story, and the test that proves it

Each user story's full Given/When/Then acceptance criteria live in its `specs/emq.N.stories.md`. This matrix
condenses each to its proving essence and binds it to the as-built test (`file` under
`echo/apps/echo_mq/test/`) and the conformance scenario that re-proves it as a parse. **Lane** = which proof
layer carries it: `pure` · `wire` (needs Valkey 6390) · `proc` (process/timer, under the ≥100 loop) ·
`ledger` (the design-gate stories, proven by the rung's ADR + the declared-keys analysis, not a runtime
test).

### emq.1 — scheduler + retry vocabulary (`e0fa9b03`)

| US | Given → When → Then (essence) | Proving test | Lane | Conf. |
|---|---|---|---|---|
| US1 scheduled enqueue | a due time → `enqueue_at/in` → fresh `JOB` id, invisible before due, claimable after promote | `scheduled_enqueue_test.exs` | wire | `schedule` |
| US2 repeatables | one registration → two occurrences fire → two **distinct mint-ordered** ids; cancel stops the mint | `repeat_test.exs` | wire | `repeat` |
| US3 retry + poison drill | a backoff policy + a persistent handler → retry → `:scheduled` (last_error kept), then `:dead` **at exactly** max attempts | `backoff_test.exs` (pure) · `consumer_test.exs` (raise→retry) · conformance poison | pure+wire | `backoff` |
| US4 promote pump | pump + due entries → a tick → promoted within one cadence; **not** started → the unchanged worker | `pump_test.exs` · `pump_core_test.exs` (pure) | wire+pure | (via run) |
| US5 resubscribe | active subs + a dropped socket → reconnect → subscriptions re-issued, feed answers | `resubscribe_test.exs` | wire | `resubscribe` |
| US6 design gate | an ADR with ≥2 steelmanned alternatives exists before any `.ex`/Lua artifact | `emq.1.md` D1 + declared-keys analysis | ledger | — |
| US7 · GATE | prior **14** byte-unchanged + 4 new → `{:ok, 18}` | `conformance_run_test.exs` · `conformance_scenarios_test.exs` | wire+pure | all |

### emq.2.1 — read plane (`7d98ef86`)

| US | Given → When → Then (essence) | Proving test | Lane | Conf. |
|---|---|---|---|---|
| US1 counts | jobs across states → `get_counts/3` → each = the set cardinality; unknown state → `{:error, {:unknown_state, _}}`; read mutates nothing | `metrics_test.exs` (counts) | wire | `counts` |
| US2 job + state | a branded id → `get_job/3` / `get_job_state/3` → the 3-field row / the holding set; missing → typed absent; ill-formed id raises at the builder | `metrics_test.exs` (lookup) · guard | wire+pure | `state` |
| US3 metrics | completed/failed jobs → `get_metrics/3` → the counter the terminal transition tallied; `:data` series honest-0 (deferred emq.8) | `metrics_test.exs` (metrics) | wire | `metrics` |
| US4 dedup read | a parked dedup key → `get_deduplication_job_id/3` → its branded id; absent → typed absent | `metrics_test.exs` (dedup) | wire | `dedup` |
| US5 rate / is_maxed | a limited queue → `get_rate_limit_ttl` / `is_maxed/2` → remaining TTL / `EMQRATE` at the ceiling → `{:error, :rate}` | `metrics_test.exs` (rate) | wire | `rate` |
| US6 lane depth | grouped jobs → per-lane read → each group's backlog over `Lanes.depth/2`; no rotation change | `metrics_test.exs` (lane) | wire | `lane_depth` |
| US7 design gate | the placement ADR (a new `EchoMQ.Metrics`) recorded before any artifact | `emq.2.1.md` D1 | ledger | — |
| US8 · GATE | prior **18** byte-unchanged + 6 new → `{:ok, 24}` | conformance tests | wire+pure | all |

### emq.2.2 — operator plane (`76fc947c`)

| US | Given → When → Then (essence) | Proving test | Lane | Conf. |
|---|---|---|---|---|
| US1 pause/resume | non-empty pending → `pause/2` → claim answers **empty**, backlog intact; `resume/2` restores; distinct from `Lanes.pause` (a `meta.paused` field, not a v1 LIST rename) | `admin_test.exs` | wire | `queue_pause` |
| US2 drain | pending + active → `drain/3` → pending emptied + rows deleted, **active untouched**; `include_schedule:` empties schedule; protects the repeat registry | `admin_test.exs` | wire | `drain` |
| US3 obliterate | a **paused** queue → `obliterate/3` → every set + §6 aux key + reachable row gone, bounded by `budget` (`:more`/`:ok`); non-paused → `EMQSTATE`; live active → `EMQSTATE` unless `force` | `admin_test.exs` | wire | `obliterate` |
| US4 update_data | any state → `update_data/4` → payload replaced; missing → `{:error, :gone}` | `jobs_ops_test.exs` | wire | `update_data` |
| US5 update_progress | a job → `update_progress/4` → progress field written **+ a progress event published**; missing → `:gone`, **no phantom emit** | `jobs_ops_test.exs` | wire | `update_progress` |
| US6 logs | a job → `add_log/5` → lands on the `logs` subkey, keep-N trims; `get_job_logs/3` reads in order; missing → `:gone` | `jobs_ops_test.exs` | wire | `job_logs` |
| US7 remove_job | a job → `remove_job/4` → cleared from its set + row/logs deleted; **locked** → `EMQLOCK`, untouched; missing → `:gone` | `jobs_ops_test.exs` | wire | `remove_job` |
| US8 reprocess | a `dead` job → `reprocess_job/3` → `pending`, last_error cleared; **not** dead → `EMQSTATE`; paused stays unclaimable | `jobs_ops_test.exs` | wire | `reprocess_job` |
| US9 design gate | placement / pause form-b / `EMQ*` class words / drain-obliterate scope ADR recorded before any artifact | `emq.2.2.md` D1 | ledger | — |
| US10 · GATE | prior **24** byte-unchanged + 8 new (+ `EMQLOCK`/`EMQSTATE` probes) → `{:ok, 32}` | conformance tests | wire+pure | all |

### emq.2.3 — watch plane (`3c6461ff`)

> As-built module names differ from the spec's prose. The matrix cites the **real `defmodule`**: file
> `telemetry.ex` = `EchoMQ.Meter`, `lock_manager.ex` = `EchoMQ.Locks`, `stalled_checker.ex` =
> `EchoMQ.Stalled`, `cancellation_token.ex` = `EchoMQ.Cancel`, `events.ex` = `EchoMQ.Events`.

| US | Given → When → Then (essence) | Proving test | Lane | Conf. |
|---|---|---|---|---|
| US1 events | a subscriber → a lifecycle transition → the event over the connector `{:emq_push, …}` seam; survives a drop (emq.1 resubscribe); existing seam, no `SSUBSCRIBE` | `events_integration_test.exs` | wire | `events` |
| US2 meter | an attached handler → a lifecycle event → the `[:emq, …]` event; **zero cost** when `:telemetry` not loaded | `meter_test.exs` (`EchoMQ.Meter`) | pure | `telemetry` |
| US3 extend_lock | a claimed job + live token → `Jobs.extend_lock/5` (`jobs.ex:646`) → the `active` member re-scored to a **server-clock** deadline; stale token → `EMQSTALE`; batch `extend_locks/4` (`jobs.ex:671`) returns the failed ids | `jobs_extend_test.exs` | wire | `lock_extend` |
| US4 Locks plane | the plane tracking a held job → its timer beats → `extend_lock` per tracked job; `track`/`untrack`/`get_active_job_count`; **opt-in** = the unchanged worker | `locks_stalled_test.exs` (`EchoMQ.Locks`) | wire+proc | (via lock_extend) |
| US5 Stalled sweep | a lease lapsed without extension → `EchoMQ.Stalled.check/3` → recovered or dead-lettered at `max_stalled`, on the server clock; distinct from the dead-lease reaper | `locks_stalled_test.exs` (`EchoMQ.Stalled`) | wire+proc | `stalled` |
| US6 cancel | a token → `Cancel.cancel/3` → `check/1` cancelled, `check!/1` raises; un-cancelled → ok; worker-side only (distributed cancel is emq.6) | `cancel_test.exs` (`EchoMQ.Cancel`) | pure | `cancel` |
| US7 design gate | the event/meter/lock/stalled design ADR recorded before any artifact | `emq.2.3.md` D1 | ledger | — |
| US8 · GATE | prior **32** byte-unchanged + 5 new → `{:ok, 37}`; process suites under the **≥100 loop** | conformance tests | wire+pure | all |

### emq.3.1 — single-queue flow (`emq-3-1` lead-team)

> The FIRST sub-rung of the parent/flow family (HIGH-risk — it edited the shipped `@complete` Lua, the fan-in
> hook). The dependency graph rides **declared §6 subkeys of the parent** (`emq:{q}:job:<parent>:dependencies`
> the STRING counter, `…:processed` the HASH) — the v1 data-value `parent_key` NOT lifted. Ledger:
> [`testing/emq.3.1.testing.md`](./testing/emq.3.1.testing.md).

| US | Given → When → Then (essence) | Proving test | Lane | Conf. |
|---|---|---|---|---|
| US1 atomic add | a parent + N same-queue children → `Flows.add/3` → N+1 distinct `JOB` ids on one slot; children claimable; parent withheld (`awaiting_children`, `:dependencies = N`) | `flow_add_test.exs` | wire | `flow_add` |
| US2 fan-in release | the parent claims `:empty` until the last child completes, then claimable | `flow_fanin_test.exs` | wire+proc | `flow_fanin` |
| US3 idempotent decrement | a double-complete of a child decrements the parent **exactly once** (the `was_active == 1` gate) | `flow_fanin_test.exs` | wire+proc | `flow_fanin` |
| US4 refusals | a cross-queue child → rejected host-side, nothing written; a non-`JOB` parent/child → `EMQKIND` (atomic rollback); an ill-formed id raises at `Keyspace.job_key/2` | `flow_add_test.exs` (the refusals describe) | wire+pure | `flow_add` |
| US5 claim gate | `@claim` byte-unchanged — the gate is the parent's **absence from `pending`**, not a check inside `@claim` | `flow_fanin_test.exs` + the empty `@claim` diff | wire | (via `flow_fanin`) |
| US6 design gate / dead-child bound (INV9) | the A-1 flow ADR before any artifact; a child that dies to `dead` does **NOT** decrement — the parent stays `awaiting_children` (the dead-child handling → emq.3.4) | `emq.3.1.md` D1 + `flow_fanin_test.exs` (the INV9 describe) | ledger+wire | — |
| US· GATE | prior **43** byte-unchanged + 2 new → `{:ok, 45}`; the flow suites under the **≥100 loop** | conformance tests | wire+pure | all 45 |

### emq.3.2 — child-result reads (`emq-3-2` cycle)

> The SECOND sub-rung (NORMAL-risk — **no** shipped Lua script edited; the real result rode the EXISTING
> `ARGV[5]` seam, the `@complete` Lua byte-unchanged). It **closes emq.3.1's O1** (the `:processed` value is the
> real result, not a `child_id → child_id` presence marker) and adds the two **pure** reads. Ledger:
> [`testing/emq.3.2.testing.md`](./testing/emq.3.2.testing.md).

| US | Given → When → Then (essence) | Proving test | Lane | Conf. |
|---|---|---|---|---|
| US1 fork gate | Fork R1 (Arm B, the real-result completion) + Fork R2 (Arm A, the count) ruled before any build artifact; the triad authored to the ruled arms | the `emq-3-2` ledger + the empty `@complete` diff | ledger | — |
| US2 children_values | two children completed with **distinct** results → `{:ok, %{child_id => result}}` (the results, provably not the ids); empty parent → `{:ok, %{}}`; ill-formed id raises | `flow_children_values_test.exs` (the O1-close describe) | wire | `flow_children_values` |
| US3 dependencies | the count N → N−k → **0** at full fan-in (Fork R2·A); a non-flow parent → the `{:ok, 0}` sentinel; ill-formed id raises | `flow_children_values_test.exs` (the dependencies describe) | wire | `flow_children_values` |
| US4 real-result completion (R1·B, host-only) | the result rides the EXISTING `ARGV[5]`; the `@complete` Lua byte-unchanged (SHA-verified); the non-flow completion byte-unchanged; **O1 closed** | `flow_children_values_test.exs` (distinct-results) + the **15-attr empty-Lua-diff SHA proof** | wire+ledger | `flow_children_values` |
| US5 purity + named lifecycle | a double-read leaves `:dependencies` + `:processed` **byte-identical** (pure); the flow-subkey cleanup **named** (the `obliterate`-sweep + per-flow cleanup → emq.3.x), emq.3.2 adds **zero** cleanup (`admin.ex` untouched) | `flow_children_values_test.exs` (the purity + lifecycle describes) | wire+ledger | `flow_children_values` |
| US6 · GATE | prior **45** byte-unchanged + 1 new → `{:ok, 46}`; the read suite under the **≥100 loop**; the emq.1 + emq.2.{1–4} + emq.3.1 suites unchanged (INV3); Apollo OPTIONAL (NORMAL-risk) | conformance tests + the ≥100 loop | wire+pure+proc | all 46 |

---

## 4 · Coverage estimate

Coverage is reported on **four axes**, because a single line-% would mislead in a protocol engine whose
proof is mostly behavioral and engine-gated.

| Axis | Measure | Value | How established |
|---|---|---|---|
| **User-story acceptance** | shipped US with ≥1 defined proof | **45 / 45 (100%)** (33 emq.2.x + 6 emq.3.1 + 6 emq.3.2) | the §3 matrix — every US binds to a test or a design ledger |
| → executable subset | capability US with ≥1 runnable test | **35 / 35 (100%)** | the non-gate, non-ledger rows of §3 |
| → process-proven subset | design-gate US (ADR + declared-keys analysis) | 6 / 6 | the emq.1–2.3 design gates + emq.3.1-US6 + emq.3.2-US1 — ledger, by design |
| **Conformance (protocol-as-parse)** | wire scenarios green against the truth row | **46 / 46** (post-emq.3.2 — 43 + `flow_add` + `flow_fanin` + `flow_children_values`) | `conformance_run_test.exs` → `{:ok, 46}` |
| **Test population** | as-built test cases | echo_mq **275** (post-emq.3.2, the harden track's measured final: 4 doctests + 275 tests, 0 failures; +`flow_add` 9 +`flow_fanin` 6 +`flow_children_values` 10 + the harden additions over the 251 emq.2.4 board) · echo_wire **18** · echo_cache **68** | `TMPDIR=/tmp mix test --include valkey` (the full per-app run) |
| **Code line/branch** | measured coverage % | **UNMEASURED** | see the gap below |

> **emq.2.4 lifted the depth axis.** The closer added the five depth suites (`metrics_depth`, `admin_depth`,
> `dedup_bound`, `rate_consult`, `watch_depth`) and the grouped-obliterate proof, taking echo_mq from 201 → 251
> test cases and the conformance set 37 → 43 — closing the v1↔v2 depth residue for the **shipped**
> read/ops/watch surface. The un-ported v1 depth stays attributed forward (worker → emq.6, OTel → emq.8,
> flow → emq.3, scheduler → emq.1, stress → the ≥100 loop), never padded into emq.2.4 (INV2).
>
> **The flow family (emq.3.1/3.2) lifted the flow axis.** The single-queue flow (emq.3.1: `flow_add` 9 +
> `flow_fanin` 6 = 15 cases) + the child-result reads (emq.3.2: `flow_children_values` 10 cases) added the
> parent/flow surface and grew the conformance set 43 → 46 — closing the flow row of the v1↔v2 depth gap for the
> single-queue, one-level shape. The remaining flow depth stays attributed forward (cross-queue → emq.3.3,
> failure-policy + bulk → emq.3.4, dead-child release → emq.3.4), never padded here (INV8).

### The unmeasured axis (the honest gap)

- **No coverage baseline exists for the v2 apps.** `excoveralls` is wired only on the **frozen v1**
  `echomq`; the three v2 apps use the built-in `test_coverage: [summary: [threshold: 0]]` with no captured
  number. A real line/branch baseline requires (a) wiring `excoveralls` into the v2 `mix.exs` files and
  (b) a **live Valkey on 6390** — because **22 of echo_mq's 32 test files are `:valkey`-tagged**
  (post-emq.2.4), an offline `mix test` exercises only the pure column and would report a deceptively low
  line-%. → an emq.2.4 task
  (§5, `testing/emq.2.3.testing.md` + a cross-rung task).
- **Qualitative estimate:** the **public verb surface is densely covered** — every public function has ≥1
  wire scenario *and* a conformance probe *and* (for the guarded entry points) a pure guard test. The thin
  regions are not the happy paths but the **timing-dependent and honesty-dependent** edges: pub/sub
  at-most-once across a disconnect, the lock/stalled timer races, and the bounded-completeness `[RECONCILE]`
  limits (the `de:` orphan). Those are §5's hot places.

### The v1 ↔ v2 depth gap (what emq.2.4 closes)

| | v1 `echomq` (frozen reference) | v2 `echo_mq` (pre-emq.2.4) | v2 `echo_mq` (post-emq.2.4) |
|---|---|---|---|
| Test files | 41 | 27 | **32** |
| Test cases | 531 | 201 | **251** |

The gap is **partly attributed, not pure debt** (roadmap emq.2.4 row): un-ported v1 depth is assigned
forward — worker lifecycle → emq.6 · OpenTelemetry contract → emq.8 · flow/parent → emq.3 · scheduler →
already at emq.1 · stress → the ≥100 loop. The **residual** — the depth a shipped read/ops/watch surface
should carry but did not yet — is exactly what emq.2.4's "complete test suite" closed (§0): the 5 depth
suites took v2 from 27 → 32 files and 201 → 251 cases for the shipped read/ops/watch verbs. §5 records what
remains.

---

## 5 · Hot places (the near-term testing backlog)

The highest-risk, highest-value gaps, surfaced by the §11.2 charter against the as-built tree. Each becomes
actionable tasks in the per-rung ledger named beside it. **These are the emq.2.4 backlog.**

1. **The offline-CI blind spot** (cross-rung, top priority). 20/27 echo_mq files need Valkey 6390; no CI runs
   them. Today "tests pass" offline proves only the pure column. → stand up a Valkey-backed test job + a
   captured coverage baseline. → `testing/emq.2.3.testing.md` (lead) + every rung ledger references it.
2. **Determinism is run by hand, never captured.** The ≥100 loop is a convention, not an artifact — no log,
   no CI gate. The process suites (`locks_stalled`, `jobs_extend`, `pump`) are the flake surface. →
   `emq.1` (pump/mint) + `emq.2.3` (locks/stalled) ledgers.
3. **Pub/sub at-most-once honesty is asserted in prose, not tested.** `events_integration_test` proves
   delivery + resubscribe, but the *honest loss* across the disconnect window (a message published while
   disconnected is **not** redelivered) is the design's stated contract and has no regression test. →
   `emq.2.3` ledger.
4. **The cross-rung lock seam.** `emq.2.2`'s `remove_job` refuses a **locked** job (`EMQLOCK`), but the lock
   subkey only became real at `emq.2.3`'s `Locks` plane — the 2.2 test sets the lock by hand. A real
   integration test (2.3 holds a lease → 2.2 `remove_job` refuses) does not exist. → `emq.2.2` + `emq.2.3`.
5. **The `[RECONCILE]` bounded-completeness limits — now partly guarded (emq.2.4).** Obliterate does **not**
   sweep `de:*` dedup orphans (no `SCAN` under declared keys); drain protects the repeat registry. These are
   deliberate limits, now **pinned** by emq.2.4's `dedup_release` conformance scenario + `dedup_bound_test`
   (the orphan is asserted un-swept, the honest limit caught if a future "fix" breaks declared-keys). **The
   one genuine defect this hot-place hid is now FIXED:** obliterate formerly DELed each `g:<g>:pending` lane
   ZSET but leaked the grouped job rows (a grouped-but-unclaimed job's `emq:{q}:job:<id>` survived) — the
   emq.2.2-D4 spec promised "every reachable job row." emq.2.4's depth suite caught it (an INV3 finding), and
   the fix (`admin.ex` — del_job each lane member before DELing the lane, budget-accounted) + the
   `obliterate_grouped` conformance scenario + the flipped `admin_depth` test now guard it. → `emq.2.2` ledger.
6. **The Meter zero-cost guard.** `EchoMQ.Meter` claims zero cost when `:telemetry` is absent
   (`function_exported/3`). `meter_test` runs *with* telemetry available — the absent-dependency path is
   untested. → `emq.2.3` ledger.
7. **No generative / property proof of the order theorem.** "byte = mint" is the master identity invariant,
   proven by example (two occurrences) but never by a property over many mints in a tight same-millisecond
   loop — the exact condition that flaked the emq.0/emq.1 arc. → `emq.1` ledger.
8. **The G1 rate-gate fork — RULED Arm 2 (resolved emq.2.4).** `emq.2.1`'s `is_maxed`/`EMQRATE` ships as a
   pure-read primitive; the Operator ruled (2026-06-14) the **consult-before-claim** contract — `is_maxed/2`
   stays the pre-claim read a claimer consults (the faithful v1 parity; no `@claim`/`@gclaim` edit). emq.2.4
   built the pinning proof: the `rate_consult` conformance scenario + `rate_consult_test` exercise the
   consult-then-skip path end to end (at the ceiling `is_maxed` refuses `{:error, :rate}`; a skipping claimer
   leaves `active` at the ceiling), so the contract is a deliberate, tested posture — not a silent drift. The
   seam is closed.
9. **The flow-subkey lifecycle carry (emq.3.1 L-5 / emq.3.2 N1 — a NAMED carry, partly tested).** The flow
   subkeys `emq:{q}:job:<parent>:{dependencies,processed}` **outlive** the parent row (`@complete` `DEL`s only
   the row), `obliterate` (`del_job`'s FIXED `:logs`/`:lock` enumeration excludes them), AND `@drain`'s `wipe()`
   (a SECOND obliterate-class leak surface — `DEL jk, jk..':logs'`, no `:lock`, no flow subkeys; the same
   destructive-sweep-with-FIXED-subkey-list class). This is **correct** for emq.3.1's write + emq.3.2's read
   scope (the reads need the subkeys to exist), and emq.3.2 added the **honest-bound test** that they **survive**
   the parent's own completion + `obliterate` (`flow_children_values_test.exs` — caught, not a green-board blind
   spot). The **cleanup** (the `obliterate`-sweep + `@drain`'s `wipe()` gaining the two subkeys + per-flow
   completion cleanup) is **not built** — a NAMED carry to the **emq.3.x lifecycle rung** (each fold-in re-tiers
   out of NORMAL-risk: per-flow cleanup edits the shipped `@complete` → HIGH-risk; the sweep is an `Admin`-surface
   change). → `emq.3.1` + `emq.3.2` ledgers.
10. **The O2 per-completion `parent_of` round-trip (emq.3.1 O2 — DECLINED at emq.3.2, an open carry).**
    `complete` does one host-side `HGET <child> 'parent'` per completion; the optional fold into the claim result
    was **declined** at emq.3.2 (correctness-neutral, out of the read API's scope). An open carry to whichever
    rung wants the round-trip removed; not a defect. → `emq.3.2` ledger.

---

## 6 · The document set + maintenance protocol

| File | Holds |
|---|---|
| `emq.testing.md` (this) | the strategy, the §3 matrix, the §4 coverage, the §5 hot-place index |
| [`testing/emq.1.testing.md`](./testing/emq.1.testing.md) | scheduler/retry/pump/resubscribe — proof table + tasks |
| [`testing/emq.2.1.testing.md`](./testing/emq.2.1.testing.md) | read plane — proof table + tasks |
| [`testing/emq.2.2.testing.md`](./testing/emq.2.2.testing.md) | operator plane — proof table + tasks |
| [`testing/emq.2.3.testing.md`](./testing/emq.2.3.testing.md) | watch plane — proof table + tasks (+ the offline-CI lead task) |
| [`testing/emq.3.1.testing.md`](./testing/emq.3.1.testing.md) | single-queue flow — proof table + tasks (the dead-child INV9 + the lifecycle carry) |
| [`testing/emq.3.2.testing.md`](./testing/emq.3.2.testing.md) | child-result reads — proof table + tasks (the empty-Lua-diff proof + the lifecycle carry, partly tested) |

**Maintenance law (permanent):** these are **living** documents, kept beside the code.

- On each new rung (emq.3.3, emq.3.4, emq.4, …): re-probe the tree, add a row to §1, a sub-table to §3, update
  the §4 counts, add a §5 hot-place if the rung opens one, and add `testing/emq.N.testing.md`.
- **Records-freeze:** the §0 emq.2.4 observed-board (2026-06-14) is a historical anchor — never rewrite it;
  later rungs are added alongside it.
- **Re-probe before trusting any figure.** Module names, line numbers, and counts drift; the working tree
  and origin/master drift in both directions (this document was authored after a `git pull` corrected a
  local tree that lagged the team's emq.2.3 push). Treat every `file:line` here as a hint to confirm, never
  a fact to cite blind.
- A task is **done** only when its proof runs in the gate ladder (a doctest is inert until a test file
  invokes `doctest`; a wire test is inert until Valkey is up in CI).
