# E2.01.1 · The eight states

> Route: `/echomq/core/lifecycle/the-eight-states` · Movement I · The Core (as-built, present tense) · dive 1
> Back-link: ← redis-patterns R3 (`/redis-patterns/queues`)

## The fact

A job in EchoMQ occupies **exactly one of eight states** at any moment, and each state is one Redis key built by one
function in `EchoMQ.Keys`. The state's Redis type — LIST or ZSET — is part of the contract, and two of the eight are
**terminal**.

| State | Redis location | Type | Key function | Terminal? |
|---|---|---|---|---|
| wait | `emq:{q}:wait` | LIST | `EchoMQ.Keys.wait/1` | no |
| paused | `emq:{q}:paused` | LIST | `EchoMQ.Keys.paused/1` | no |
| delayed | `emq:{q}:delayed` (score = run-at ms) | ZSET | `EchoMQ.Keys.delayed/1` | no |
| prioritized | `emq:{q}:prioritized` (score = priority) | ZSET | `EchoMQ.Keys.prioritized/1` | no |
| active | `emq:{q}:active` | LIST | `EchoMQ.Keys.active/1` | no |
| completed | `emq:{q}:completed` (score = finished-at ms) | ZSET | `EchoMQ.Keys.completed/1` | **terminal** |
| failed | `emq:{q}:failed` | ZSET | `EchoMQ.Keys.failed/1` | **terminal** (after max retries) |
| waiting-children | `emq:{q}:waiting-children` | ZSET | `EchoMQ.Keys.waiting_children/1` | no |

Terminal means `completed` and `failed` (the latter only once attempts are exhausted) — a job there has reached the
end of its run; every other state can still transition. A ninth relevant key is the stalled SET
`EchoMQ.Keys.stalled/1`, which is not a job state but the lock-miss detection set the stalled checker reads.

## The worked example — where a job goes on `add`, and what each state is

The target state on `add` is decided by the job's options, and the add script differs per target:

- **no delay, no priority** → `wait` (`addStandardJob-9`)
- **`delay > 0`** → `delayed` (`addDelayedJob-6`)
- **`priority > 0`** → `prioritized` (`addPrioritizedJob-9`)
- **has a parent** → the parent enters `waiting-children` (`addParentJob-6`)

Read one state at a time:

- **wait** — ready for processing in FIFO order; a `LIST`, dequeued by `RPOP`.
- **paused** — ready, but held while the queue is paused; a `LIST` (`pause-7` moves jobs here).
- **delayed** — waiting for its scheduled time; a `ZSET` scored by run-at ms, promoted to `wait` when due.
- **prioritized** — ready, ordered by priority rather than FIFO; a `ZSET` scored by priority, dequeued by `ZPOPMIN`.
- **active** — held by a worker; a `LIST`, with a UUID lock token set under a TTL while the job runs.
- **completed** — terminal; a `ZSET` scored by finished-at ms.
- **failed** — terminal unless retried into `delayed`; a `ZSET`.
- **waiting-children** — a flow parent awaiting its children; a `ZSET`, promoted when the dependencies set empties.

## The protocol ↔ runtime pairing (the Golden Rule)

The eight state keys are **L1 — immutable and shared**. The same `emq:{q}:wait` LIST and `emq:{q}:completed` ZSET
exist in every runtime, byte-for-byte; only the executor that reads and writes them varies.

- **The protocol (immutable L1)** — the eight keys `EchoMQ.Keys` builds, with their fixed Redis types.
- **Its three runtimes (variable L3)** — Elixir builds each key with `EchoMQ.Keys.wait/1`, `active/1`, … over a Redix
  pool; Go and Node.js build the same key strings their own way. The location and the type are the contract.

## Recap

A job is in exactly one of eight states; each is one key built by one `EchoMQ.Keys` function, with a fixed type
(LIST for wait/paused/active, ZSET for the rest). `completed` and `failed` are terminal. The state is L1 — the same
location in every runtime.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the eight job states and their Redis locations.
- Redis — *Lists* (`https://redis.io/docs/latest/develop/data-types/lists/`) — the LIST behind wait, paused, and active.
- Redis — *Sorted sets* (`https://redis.io/docs/latest/develop/data-types/sorted-sets/`) — the ZSET scoring behind
  delayed (run-at), prioritized (priority), and the terminal sets.

### Related in this course

- `/echomq/core/lifecycle` — E2.01 · The lifecycle & state machine (the module hub).
- `/echomq/protocol` — E1 · The protocol (the L1 key taxonomy these states belong to).
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (states-as-locations, applied).
