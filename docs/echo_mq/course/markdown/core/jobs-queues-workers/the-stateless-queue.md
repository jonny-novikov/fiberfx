# E2.02.2 · The stateless queue

> Movement I · dive 2 · grounded in `EchoMQ.Queue.add/4` (`lib/echomq/queue.ex`)

The module's thesis lives here: **the queue is stateless.** There is no in-memory queue object that
holds jobs. `EchoMQ.Queue.add("emails", "send", %{...}, connection: :redis)` works with a string name
and a connection — no stateful process — because **Redis holds all the queue state**: the wait LIST,
the delayed and prioritized ZSETs, and the job hashes.

## Two clauses, one stateless path

`EchoMQ.Queue.add(queue, name, data, opts \\ [])` (arity 4) has two verified clauses:

- when `queue` is an **atom or pid** → `GenServer.call(queue, {:add, name, data, opts})` — a
  convenience wrapper around a named or pid Queue process.
- when `queue` is a **binary (string)** → the stateless path:
  - `conn = Keyword.fetch!(opts, :connection)`
  - `prefix = opts[:prefix] || "bull"`
  - `ctx = Keys.new(queue, prefix: prefix)`
  - `job = Job.new(queue, name, data, opts)`
  - then `add_job(conn, ctx, job)`.

The atom/pid clause is only a convenience for callers who want a named process. The string clause is
the real shape of the queue: a name, a connection, and nothing held in memory.

## The add runs the matching script

`add/4` builds a Job and runs the add\* Lua script that matches its target:

- `addStandardJob-9` — a standard job onto the wait LIST.
- `addDelayedJob-6` — when `delay > 0`, onto the delayed ZSET.
- `addPrioritizedJob-9` — when `priority > 0`, onto the prioritized ZSET.

Each script atomically writes the job hash and pushes the job id onto the right state key, so an add
is one atomic step — the hash and the membership land together or not at all. `add_bulk/3` adds many
jobs atomically in one MULTI/EXEC transaction.

## The interactive — what survives a restart

Toggle the queue between "a stateful object holds the jobs" and "Redis holds the state". The readout
reports what survives a process restart:

- **stateful object** — restart loses the in-memory job list; the jobs are gone.
- **Redis holds the state** — restart loses nothing; the jobs persist in `emq:{queue}:wait` and the
  ZSETs, because Redis owns the durable state. A fresh `add/4` call against the same name and
  connection re-attaches to the very same keys.

This is the whole point of a stateless queue: the durable thing is Redis, not the caller.

## The bridge — the keys, then their three runtimes

- **The protocol (immutable L1/L2):** the Redis keys that *are* the queue — `emq:{queue}:wait`
  (LIST), `emq:{queue}:delayed` / `emq:{queue}:prioritized` (ZSETs) — and the add\* scripts that
  write them. Frozen across runtimes.
- **Its three runtimes (variable L3/L4):** Elixir's thin stateless `Queue.add/4`, Go's `queue.Add`,
  Node's `queue.add` — each a thin call onto the **same** keys and the **same** scripts. No runtime
  holds the queue; Redis does.

The takeaway: a queue name is a coordinate, not a container. The component is disposable; the keys
are the queue.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the queue API and the add scripts.
- BullMQ — *Home* (`https://bullmq.io/`) — the project EchoMQ implements.
- Redis — *Lists* (`https://redis.io/docs/latest/develop/data-types/lists/`) — the wait LIST a
  standard add pushes onto.
- Redis — *LPUSH* (`https://redis.io/commands/lpush/`) — the push that admits a job to the queue.

### Related in this course

- `/echomq/core/jobs-queues-workers` — E2.02 · the module hub.
- `/echomq/core/jobs-queues-workers/the-job-model` — E2.02.1 · the job the queue admits.
- `/echomq/core/jobs-queues-workers/the-worker-fetch-loop` — E2.02.3 · the worker that pulls from it.
- `/echomq/core/lifecycle/the-eight-states` — E2.01.1 · the state keys the add writes to.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues.
