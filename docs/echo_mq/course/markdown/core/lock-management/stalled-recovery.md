# E2.03.2 · Stalled recovery

> Route: `/echomq/core/lock-management/stalled-recovery` · Movement I · The Core · `← redis-patterns R3`

## The fact

A job is **stalled** when a worker took it — it sits in `active` — but failed to complete it or
renew its lock before the lock's `PX` TTL expired. That happens when the worker process crashes,
the machine loses power, a network failure blocks lock renewal, or the job processor blocks without
yielding. `EchoMQ.StalledChecker` finds such jobs and recovers them, and it does so in **two
phases** so a transient timing blip does not fail a healthy job.

## The worked example — on the real `EchoMQ.StalledChecker`

The stalled checker is a `GenServer` driving a single timer:

```elixir
timer_ref = Process.send_after(self(), :check_stalled, stalled_interval)
```

`stalled_interval` defaults to **30_000 ms**. On each `:check_stalled`, `do_check` lists the active
jobs and probes their locks:

```elixir
defp do_check(connection, ctx, max_stalled_count) do
  case RedisConnection.command(connection, ["LRANGE", Keys.active(ctx), 0, -1]) do
    {:ok, []}       -> {:ok, %{recovered: 0, failed: 0}}
    {:ok, job_ids}  -> check_jobs_stalled(connection, ctx, job_ids, max_stalled_count)
    {:error, _} = e -> e
  end
end
```

`check_jobs_stalled` builds one `EXISTS emq:{queue}:{jobId}:lock` per active id and runs them as a
single **pipeline**. A job whose lock returns `0` has no lock and is flagged stalled:

```elixir
stalled_jobs =
  Enum.zip(job_ids, results)
  |> Enum.filter(fn {_id, exists} -> exists == 0 end)
  |> Enum.map(fn {id, _} -> id end)
```

So the stall signal is the **absence of the lock key** for a job that is still in `active`. The
recovery itself runs the Lua script.

### Two-phase: mark, then recover

EchoMQ uses two-phase detection so it never fails a job on a single bad reading:

1. **Mark phase** — a job with no valid lock is moved into the **stalled** SET.
2. **Recover phase** — on the *next* check, a job still in the stalled set is either requeued
   (→ `wait`) or moved to `failed`, decided by `max_stalled_count`.

The two phases prevent a false positive from a transient timing window: a job that briefly looked
lockless but is in fact healthy clears itself on the next pass instead of being failed.

### The recovery script

The recovery is **`moveStalledJobsToWait-8.lua`** — the `-8` is the `numkeys`. The canonical
wrapper `EchoMQ.Scripts.move_stalled_jobs_to_wait(conn, ctx, max_stalled_count, opts)` passes
**eight keys**:

```elixir
keys = [
  Keys.stalled(ctx), Keys.wait(ctx), Keys.active(ctx), Keys.failed(ctx),
  Keys.stalled_check(ctx), Keys.meta(ctx), Keys.paused(ctx), Keys.marker(ctx)
]
```

The recovery result the StalledChecker returns is `{:ok, %{recovered: count, failed: count}}` —
`recovered` is how many jobs were requeued to `wait`, `failed` how many had exhausted their stall
count and were moved to `failed`. The checker emits telemetry for each: `:stalled_recovered` and
`:stalled_failed`.

### The public API

- `start_link/1` — start the checker as a supervised child.
- `check(connection, queue, opts \\ [])` — arity 3, a manual trigger; returns
  `{:ok, %{recovered: n, failed: n}}`.
- `job_stalled?(connection, queue, job_id, opts \\ [])` — arity 4, a single-job probe.

### Defaults

- `stalled_interval` — **30_000 ms** (the sweep period).
- `max_stalled_count` — **1**. A job that stalls more than once usually signals a real bug —
  repeated crashes on specific job data, resource exhaustion, an external-service failure — so the
  default fails the job rather than looping forever. Raising it is generally not recommended;
  investigate why the job stalls instead.

## The protocol and its three runtimes

The stall signal — the **absence of the lock key** for a job still in `active` — and the recovery
script **`moveStalledJobsToWait-8.lua`** are frozen **L1/L2**, the same in every runtime. The
Elixir checker — `LRANGE active`, a pipelined `EXISTS`-lock probe, the recovery script, all on one
`GenServer` timer — is the Elixir runtime's own **L3/L4**. Go and Node.js run the same detection
signal and the same recovery script with their own checker process. (Go's stalled recovery is part
of its non-atomic critical path — separate commands rather than embedded Lua — but that cross-runtime
contrast is E2.04's subject; here the signal and the recovery script are what stay fixed.)

## Recap

- A job is stalled when it sits in `active` with no live lock — its worker died or stopped renewing.
- The checker lists `active`, pipelines `EXISTS` over each lock, and flags the jobs whose lock is
  gone.
- Recovery is two-phase — mark to the stalled set, then on the next sweep requeue or fail by
  `max_stalled_count`.
- `moveStalledJobsToWait-8.lua` (eight keys) does the atomic move; the checker reports
  `%{recovered, failed}` and emits `:stalled_recovered` / `:stalled_failed`.
- Defaults: `stalled_interval` 30_000 ms, `max_stalled_count` 1.

## References

### Sources

- BullMQ — Documentation — the two-phase stalled-job detection and recovery sweep EchoMQ
  implements. https://docs.bullmq.io/
- Redis — LRANGE — the read of the active list the checker scans each sweep.
  https://redis.io/commands/lrange/
- Redis — EXISTS — the pipelined lock-presence probe that flags a stalled job.
  https://redis.io/commands/exists/

### Related in this course

- `/echomq/core/lock-management` — E2.03 · the module hub.
- `/echomq/core/lock-management/one-timer-not-n` — E2.03.1 · the renewal that, when it fails, leaves
  a job for this checker to recover.
- `/echomq/core/lifecycle/the-lock-protocol` — E2.01.3 · the lock whose absence is the stall signal.
- `/redis-patterns/queues` — redis-patterns R3 · the reliable-queue pattern this recovery upholds.
