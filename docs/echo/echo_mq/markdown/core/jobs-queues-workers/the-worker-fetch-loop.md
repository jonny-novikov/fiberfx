# E2.02.3 · The worker fetch loop

> Movement I · dive 3 · grounded in `EchoMQ.Worker` (`lib/echomq/worker.ex`)

A Worker is a GenServer that pulls jobs from a queue and runs them. Its public API is
`start_link/1`, `pause/2`, `resume/1`, `paused?/1`, and `close/2`. The required options are `:queue`
and `:connection`; `:processor` is the job function. `:concurrency` defaults to **1** (verified
`@default_concurrency 1` — the moduledoc's `concurrency: 10` is only an example), alongside
`:lock_duration` (30000), `:stalled_interval` (30000), and `:max_stalled_count` (1).

## The slot math

The fetch loop is `handle_info(:fetch_jobs, state)`. It computes the free capacity:

    available_slots = state.concurrency - map_size(state.active_jobs)

`active_jobs` is a map of in-flight jobs, so this is the concurrency limit made concrete: **never
more than `concurrency` jobs in flight at once.** For each free slot the worker fetches the next job
via `EchoMQ.Scripts.move_to_active/4` → `moveToActive-11.lua` — the atomic pickup that moves a job id
from wait to active, sets the lock, and returns the job data.

## A BEAM process per job

Each fetched job runs in its **own BEAM process via `Task.async/1`** — "a BEAM process per job".
When the Task finishes, its result returns as a message; the worker moves the job to completed,
failed, or delayed, then re-sends `:fetch_jobs` to refill the freed slot. The loop is event-driven —
it refills on completion — with timer fallbacks (`Process.send_after(self(), :fetch_jobs, …)`) when
the worker is idle, rate-limited, or waiting on a delayed job.

## Three teaching points

1. **Concurrency defaults to 1.** Raising it to N lets up to N jobs run concurrently; the number
   running at once is `min(concurrency, pending)`.
2. **BEAM-process-per-job gives cheap, isolated processes.** A crashing job's Task is monitored and
   treated as failed or stalled **without taking down the worker** — OTP's "let it crash" applied to
   one job at a time.
3. **The locks are renewed while jobs run.** The `EchoMQ.LockManager` renews the locks of all
   in-flight `active_jobs` so a long-running job keeps its claim (the lock protocol is
   `/echomq/core/lock-management`).

## The interactive — the slot math, live

Set `concurrency` with a slider over a fixed set of pending jobs. The readout reports
`available_slots = concurrency - in-flight`, how many run at once (`min(concurrency, pending)`), and
how many wait. A second control steps the cycle: fetch (a slot fills via `moveToActive-11`) → run (a
Task) → complete → refill (`:fetch_jobs` re-sent). The slot count is the whole governor of the loop.

## The bridge — the pickup script, then its three runtimes

- **The protocol (immutable L1/L2):** `moveToActive-11` (the atomic pickup script, L2) plus the wait
  and active keys and the lock key (L1) — frozen across runtimes.
- **Its three runtimes (variable L3/L4):** the Elixir Worker GenServer with a Task per job (a BEAM
  process), Go's goroutine-per-job, Node's async worker — the **same** pickup script, a different
  executor.

The takeaway: the worker is a loop bounded by a number. Redis hands out one job per atomic pickup;
how many to hold and how to run each is set by the executor, the runtime's own choice.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the worker model, concurrency, and the
  pickup script.
- BullMQ — *Home* (`https://bullmq.io/`) — the project EchoMQ implements.
- Redis — *RPOPLPUSH* (`https://redis.io/commands/rpoplpush/`) — the reliable wait→active move the
  pickup performs.
- Redis — *Lists* (`https://redis.io/docs/latest/develop/data-types/lists/`) — the wait and active
  LISTs the loop reads.

### Related in this course

- `/echomq/core/jobs-queues-workers` — E2.02 · the module hub.
- `/echomq/core/jobs-queues-workers/the-stateless-queue` — E2.02.2 · the queue the worker pulls from.
- `/echomq/core/lock-management` — E2.03 · the LockManager that renews in-flight locks.
- `/echomq/core/lifecycle/the-lock-protocol` — E2.01.3 · the lock the pickup acquires.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues.
