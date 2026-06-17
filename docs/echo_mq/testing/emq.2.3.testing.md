# emq.2.3 — testing tasks

> Living test ledger for the **watch plane (events · meter · locks · stalled · cancel)** rung (`3c6461ff`,
> conformance 32 → 37). Strategy: [`../emq.testing.md`](../emq.testing.md). Spec triad:
> [`../specs/emq.2.3.md`](../specs/emq.2/emq.2.rungs/emq.2.3.md) · [`.stories.md`](../specs/emq.2/emq.2.rungs/emq.2.3.stories.md) ·
> [`.llms.md`](../specs/emq.2/emq.2.rungs/emq.2.3.llms.md). **Holds the cross-rung offline-CI lead task.** Re-probe the tree
> before trusting a `file:line` here.

## Proof state (as-built)

- **8 user stories**, all proven: 3 wire, 2 process (under the ≥100 loop), 2 pure cores, 1 ledger.
- **Test files**: `events_integration_test.exs` (8, wire) · `jobs_extend_test.exs` (9, wire) ·
  `locks_stalled_test.exs` (13, wire+proc) · `meter_test.exs` (11, pure) · `cancel_test.exs` (19, pure).
- **Conformance**: +5 scenarios — `lock_extend`, `stalled`, `events`, `telemetry`, `cancel` → `{:ok, 37}`;
  process-touching suites run under the **≥100 determinism loop** owning the machine.

### File ↔ module map (PIN — the spec prose and the as-built names differ; cite the `defmodule`)

| File (`lib/echo_mq/`) | Module | Verbs |
|---|---|---|
| `events.ex` | `EchoMQ.Events` | `subscribe/2`·`unsubscribe/2`·`publish/5`·`channel/1` |
| `telemetry.ex` | **`EchoMQ.Meter`** | `attach`·`emit`·`span`·`job_*`/`worker_*` |
| `lock_manager.ex` (+ `/core.ex`) | **`EchoMQ.Locks`** (+ `.Core`) | `track_job`·`untrack_job`·`get_active_job_count`·`is_tracked?` |
| `stalled_checker.ex` | **`EchoMQ.Stalled`** | `check/3`·`job_stalled?/4` |
| `cancellation_token.ex` | **`EchoMQ.Cancel`** | `new/0`·`cancel/3`·`check/1`·`check!/1` |
| `jobs.ex` | `EchoMQ.Jobs` | `extend_lock/5` (`jobs.ex:646`) · `extend_locks/4` (`jobs.ex:671`) |

## Proof table

| US | Proven by | Lane | Conf. |
|---|---|---|---|
| US1 events subscribe | `events_integration_test.exs` | wire | `events` |
| US2 meter attach | `meter_test.exs` (`EchoMQ.Meter`) | pure | `telemetry` |
| US3 extend_lock | `jobs_extend_test.exs` (`Jobs.extend_lock/5`·`extend_locks/4`) | wire | `lock_extend` |
| US4 Locks plane | `locks_stalled_test.exs` (`EchoMQ.Locks`) | wire+proc | (via lock_extend) |
| US5 Stalled sweep | `locks_stalled_test.exs` (`EchoMQ.Stalled`) | wire+proc | `stalled` |
| US6 cancel token | `cancel_test.exs` (`EchoMQ.Cancel`) | pure | `cancel` |
| US7 design gate | `emq.2.3.md` D1 ADR | ledger | — |
| US8 · GATE | conformance tests | wire+pure | all 37 |

## Hot places (this rung)

- **The bulk of the rung is wire/process** — events, extend_lock, Locks, Stalled all need Valkey 6390 and
  timers. This is the rung where the **offline-CI blind spot** bites hardest (strategy §5.1).
- **At-most-once honesty across a disconnect** is the design's stated contract and has **no test**:
  `events_integration_test` proves delivery + resubscribe, but not that a message published *during* the
  disconnect window is **not** redelivered (honest loss, not papered over).
- **Locks/Stalled timer races** — both run on timers; one green run is not proof (the master-invariant gate).
- **`EchoMQ.Meter` zero-cost claim** — guarded by `:erlang.function_exported/3`; `meter_test` runs with
  telemetry available, so the **absent-dependency** path is untested.
- **Server-clock law for the lease** — `extend_lock` must re-score the `active` member from `TIME`
  *in-script*, never the caller's clock; the §4 server-clock invariant is the thing an order-theorem
  regression would silently break.

## Near-term tasks

### Lead task (cross-rung — the emq.2.4 enabler; referenced by every rung ledger)
- [ ] **Stand up a Valkey-6390 CI job** so the 20 `:valkey` echo_mq files **+** the conformance run actually
      execute in CI (today they skip offline). Wire `excoveralls` into the three v2 `mix.exs` and **capture
      the first line/branch coverage baseline** with the engine up. This is strategy §4's unmeasured axis and
      the precondition for emq.2.4's "complete test suite."

### Harden (close the thin proofs)
- [ ] Run `locks_stalled` + `jobs_extend` under the **≥100 loop owning the machine**; commit the run record
      (the timer-race flake surface — strategy §5.2).
- [ ] **Server-clock proof**: skew the caller clock, extend a lease, and assert the deadline is unaffected
      (the re-score reads `TIME` in-script, not the caller) — the §4 law made executable.

### Gaps (missing tests)
- [ ] **At-most-once honesty**: publish a message during the disconnect window; after reconnect assert it is
      **not** redelivered (the stated loss, pinned — strategy §5.3).
- [ ] **Meter zero-cost**: a path with `:telemetry` not attached asserting `emit` is a no-op and never
      raises (the `function_exported/3` guard — strategy §5.6).
- [ ] **Stalled-vs-slow**: a job kept alive by `extend_lock` is **not** swept; a lapsed one is recovered or
      dead-lettered at `max_stalled` (the distinction from the dead-lease reaper).

### Maintenance (keep green)
- [ ] Keep the **file↔module PIN** (above) current — it exists because the spec names (`Meter`/`Locks`/
      `Stalled`/`Cancel`) and the file names (`telemetry`/`lock_manager`/`stalled_checker`/
      `cancellation_token`) diverge; a future reader must not re-confuse them.
- [ ] Keep the `emq.2.3.md` D1 ADR link live (US7 ledger-proven).
- [ ] Re-pin conformance (`{:ok, 37}` → new) on any watch change; prior 32 byte-unchanged.

## Done-when

`redis-cli -p 6390 ping` → `TMPDIR=/tmp mix test --include valkey` green in `echo/apps/echo_mq` →
`Conformance.run/2 → {:ok, 37}` → `locks_stalled` + `jobs_extend` green across `seq 1 100` owning the
machine (the high-risk process/mint posture — Apollo's re-run discipline).
