# E2.04.1 · The Elixir architecture

> Route: `/echomq/core/runtimes/the-elixir-architecture` · Movement I · The Core
> Hero back-link: `← redis-patterns R3` → `/redis-patterns/queues`.

The Elixir runtime (`echo/apps/echomq`, v`1.3.0`) is EchoMQ's reference implementation. Everything it does above the
wire is **L3/L4** — its OTP shape — and the wire underneath is the same `emq:` keyspace and the same Lua scripts every
runtime shares. Five facts define its architecture, all read from the real source.

## Library-only, host-supervised

EchoMQ-Elixir ships **no `Application` and no supervision tree of its own**. The host application supervises the
runtime's processes as children. The `EchoMQ.Worker` moduledoc shows the host wiring:

```elixir
children = [
  {EchoMQ.RedisConnection, name: :redis, url: "redis://localhost:6379"},
  {EchoMQ.Worker, name: :my_worker, queue: "my_queue", connection: :redis,
    processor: &MyApp.Jobs.process/1, concurrency: 10}
]
```

There is no `EchoMQ.Application` to start; the worker and the connection pool are children the host owns. (The
in-tree `EchoMQ.RedisConnection` `use Supervisor` is the connection-pool internal, not a queue supervision tree.)

## One BEAM process per job

`EchoMQ.Worker` is a `GenServer` with `@default_concurrency 1`. On each fetch cycle it computes its spare capacity
directly:

```elixir
available_slots = state.concurrency - map_size(state.active_jobs)
```

For every available slot it fetches a job and starts a `Task.async` to run the processor — **one BEAM process per
running job** (`worker.ex` line ~1284):

```elixir
task = Task.async(fn ->
  run_processor(processor_fn, job, worker_pid, telemetry_mod, telemetry_metadata)
end)
active_jobs = Map.put(state.active_jobs, job.id, {job, task.ref})
```

A crash in one job's process does not take down the worker or its siblings — that is the OTP isolation Elixir buys for
free. Node, by contrast, runs concurrency on a single event loop.

## The fetch step is one atomic script

A worker picks the next job up by running `Scripts.move_to_active/4`, which drives `moveToActive-11.lua` (eleven
declared keys):

```elixir
case Scripts.move_to_active(state.connection, state.keys, state.token, opts) do
  {:ok, [job_data, job_id, _limit_delay, _delay_until]} -> ...
end
```

The pop-and-mark-active is one Lua round-trip, atomic on Redis. That atomicity is L2 — the wire — not an Elixir
property.

## One timer per worker for lock renewal

`EchoMQ.LockManager` keeps every held lock fresh with **one** `Process.send_after(:extend_locks)` timer per worker,
not one per job. When the timer fires, `handle_info(:extend_locks, state)` scans the tracked jobs and batch-renews the
due ones in a single `Scripts.extend_locks/5` call over `extendLocks-1.lua` (one stalled key, all ids and tokens packed
into `ARGV`). The renewal cost is flat — one timer, one round-trip — regardless of the worker's concurrency.

## A pooled connection and EVALSHA dispatch

`EchoMQ.RedisConnection` is a NimblePool-backed pool (`use Supervisor`) exposing `command/3` and `pipeline/3`. Every
script runs through `EchoMQ.Scripts.execute_raw/4`, which dispatches **EVALSHA first** and falls back to EVAL on a
NOSCRIPT error (`scripts.ex` line ~256):

```elixir
case RedisConnection.command(conn, ["EVALSHA", sha, num_keys | keys ++ encoded_args]) do
  {:error, %Redix.Error{message: "NOSCRIPT" <> _}} -> # reload, then EVAL
  result -> result
end
```

EVALSHA sends the script's SHA, not its body, so a cached script costs one short round-trip.

## Protocol → its Elixir runtime (the Movement-I bridge)

- **The protocol (immutable L1/L2):** the `emq:` keyspace, `moveToActive-11.lua`, `extendLocks-1.lua`, the field names
  — frozen and shared.
- **Its Elixir runtime (variable L3/L4):** a host-supervised, library-only set of OTP processes — one BEAM process per
  job via `Task.async`, one `LockManager` timer per worker, a NimblePool connection, EVALSHA dispatch.

**The take.** The Elixir runtime is the reference: it owns no supervision tree, runs one BEAM process per job, renews
every lock with one timer, and dispatches every script via EVALSHA. All of that is L3/L4 — the wire underneath is the
shared protocol.

## The 2.0 fork — EchoMQ leaves the BullMQ wire

The architecture above drives the **v1 line (frozen at `1.3.0`)** — the `emq:` keyspace and the BullMQ scripts. emq.1
ships EchoMQ 2.0, and this same OTP shape drives the v2 wire: the worker still fetches via one atomic script and the
`LockManager` still renews with one timer, but the scripts now declare every key in `KEYS[]` and write the `emq:{q}:…`
keyspace the core hashtags transparently, so the reference runtime is the first to speak v2. The host-supervised,
library-only design does not change — only the wire it drives.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the worker fetch loop, the lock-renewal protocol, and the
  scripts this runtime drives.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the cached-script dispatch `execute_raw/4` uses.
- Redis — *Documentation* (`https://redis.io/docs/`) — the command reference for the scripts the worker runs.

### Related in this course

- `/echomq/core/runtimes` — E2.04 · The three runtimes & interop (the module hub).
- `/echomq/core/runtimes/the-go-gaps` — the Go port's honest status, contrasted with this reference.
- `/echomq/core/lock-management/one-timer-not-n` — E2.03.1 · the one-timer LockManager in full.
- `/echomq/core/jobs-queues-workers` — E2.02 · the worker fetch loop and the job model.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the pattern this runtime applies).
