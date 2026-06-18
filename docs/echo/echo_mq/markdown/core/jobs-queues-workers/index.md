# E2.02 · Jobs, queues & workers

> Movement I · The Core (as-built) · `← redis-patterns R3`

The lifecycle (E2.01) is the *shape* of a job's life. This module is the *three components* that
move a job along it: the **Job** that carries the work, the **Queue** that admits it, and the
**Worker** that runs it. All three are thin Elixir code over Redis — Redis holds the state, the
components are runtime materializations.

The module's thesis: **the components are stateless over the protocol.** A Job is a thin struct over
a Redis hash; a Queue is a string name plus a connection, with no in-memory store; a Worker is a
GenServer fetch loop bounded by `concurrency`, with one BEAM process per job. Pull any component out
and Redis still holds every queue's state, byte-for-byte the same for Elixir, Go, and Node.js.

## The three components

- **The Job** — `EchoMQ.Job` (`lib/echomq/job.ex`). `Job.new/4` builds a `%EchoMQ.Job{}` struct from
  `(queue_name, name, data, opts)`. The struct is a runtime view; the job's canonical state lives in
  Redis as a hash. The `opts` map routes the job — `:delay`, `:priority`, `:parent`, `:job_id`.
- **The Queue** — `EchoMQ.Queue.add/4` (`lib/echomq/queue.ex`). The stateless add path: a string
  name plus a `:connection` is enough; there is no queue object holding jobs. Redis holds the wait
  LIST and the delayed / prioritized ZSETs.
- **The Worker** — `EchoMQ.Worker` (`lib/echomq/worker.ex`). A GenServer whose fetch loop keeps at
  most `concurrency` jobs in flight (default 1), each running in its own BEAM process via
  `Task.async/1`, picked up atomically by `EchoMQ.Scripts.move_to_active/4` → `moveToActive-11.lua`.

## The framing interactive — pull a component out

Toggle each component between "holds state in itself" and "Redis holds the state". A Job's state,
a Queue's job list, and a Worker's in-flight set all live in Redis (the hash, the wait LIST, the
active LIST + lock). Pulling a component and restarting it loses nothing of the queue, because Redis
owns the durable state — the readout names what survives a process restart for each component.

## How it fits — the protocol and its three runtimes

The three components stand on the immutable layers E1 froze. **L1** is the keys and the hash field
names; **L2** is the Lua scripts (`addStandardJob-9`, `moveToActive-11`, …). Those do not move
across runtimes. **L3** is the executor and **L4** the API — `EchoMQ.Job`, `EchoMQ.Queue.add/4`,
`EchoMQ.Worker` are Elixir's; Go and Node.js drive the same hashes, keys, and scripts their own way.

EchoMQ-Elixir is **library-only** — it ships no `Application` or supervision tree of its own; the
host app supervises `EchoMQ.Worker` and `EchoMQ.RedisConnection`. The default key prefix is `bull`,
so a queue's keys read `emq:{queue}:wait`, `emq:{queue}:active`, and so on.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the Job, Queue, and Worker model EchoMQ
  rides, and the add scripts behind each.
- BullMQ — *Home* (`https://bullmq.io/`) — the project the wire protocol comes from.
- Redis — *Lists* (`https://redis.io/docs/latest/develop/data-types/lists/`) — the LIST behind the
  wait and active queues a worker fetches from.
- Redis — *RPOPLPUSH* (`https://redis.io/commands/rpoplpush/`) — the reliable wait→active move at
  the heart of the worker pickup.

### Related in this course

- `/echomq/core` — E2 · The core (the chapter landing).
- `/echomq/core/lifecycle` — E2.01 · The lifecycle & state machine (the shape this module fills).
- `/echomq/core/jobs-queues-workers/the-job-model` — E2.02.1 · The job model.
- `/echomq/core/jobs-queues-workers/the-stateless-queue` — E2.02.2 · The stateless queue.
- `/echomq/core/jobs-queues-workers/the-worker-fetch-loop` — E2.02.3 · The worker fetch loop.
- `/echomq/protocol` — E1 · The protocol (the immutable wire these components ride).
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the pattern this module deepens).
