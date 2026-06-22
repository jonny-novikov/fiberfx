# States as locations — the place is the state

> Route: `/redis-patterns/queues/atomic-state-machine/states-as-locations` · Dive R3.04.1 · Module R3.04 Atomic state
> machine. Grounding: EchoMQ holds no status field. `EchoMQ.Keys.wait/1`, `active/1`, `delayed/1`, `prioritized/1`,
> `completed/1` and `failed/1` build the keys a job id lives in; a transition moves the id from one structure to
> another. The atomic move that does it is `moveToFinished-14.lua`. All real in `echo/apps/echomq`.

The value the lifecycle updates is not a balance and not a status column. It is a **job's location** — the Redis key
its id lives in. A transition moves the id to the next key.

## The state is the location

The atomic-updates pattern names the thing being updated as a value at a key. Applied to a queue, that value is the
job's place. A naive queue stores a `status` field on the job record — `"wait"`, `"active"`, `"done"` — and updates it
as the job moves. Two facts can then disagree: where the job actually sits, and what its status claims. A crash
between writing the status and moving the job leaves the pair out of sync, with nothing to reconcile them.

EchoMQ holds no status field. A job's state *is* the Redis key its id lives in. There is no separate column to fall
out of sync, because the location is the state.

## The five locations

A job id lives in exactly one place at a time, and the structure type carries meaning:

- `emq:{queue}:wait` — a LIST of ids waiting to run.
- `emq:{queue}:active` — a LIST of ids in flight under a lock.
- `emq:{queue}:delayed` — a ZSET, scored by the time the job is due.
- `emq:{queue}:prioritized` — a ZSET, scored by priority.
- `emq:{queue}:completed` / `emq:{queue}:failed` — ZSETs of terminal ids, scored by finish time, so old entries trim
  by age or count.

`EchoMQ.Keys` builds each from the queue context — `wait/1`, `active/1`, `delayed/1`, `prioritized/1`, `completed/1`,
`failed/1`. The `{queue}` here is the queue-name placeholder the key builder fills in (`EchoMQ.Keys.base/1`), the
documentation form the shipped queue dives use.

## A transition moves the id

A transition is moving the id from one key to the next, plus an update to the job hash `emq:{queue}:<id>`. Enqueue
pushes the id onto `wait`. Pick up moves it from `wait` into `active`. Finish moves it from `active` into `completed`.
Fail moves it from `active` into `failed`. Delay scores it into `delayed`. The id is in exactly one structure at every
instant — and which structure it is in is the job's state. LIST membership means waiting or in flight; ZSET membership
means scheduled or terminal.

Because the state is the location and a transition is a move across structures, the move must be atomic. A move that
removes the id from one key and adds it to another in two separate commands has a window where the id is in neither, or
in both. That is why the whole transition runs as one Lua script — `moveToFinished-14.lua`, one `EVALSHA` over the
fourteen keys that name every location at once.

### The pattern, applied

The atomic-updates value-at-a-key becomes a job-id-at-a-location. In EchoMQ the locations are
`EchoMQ.Keys.wait/active/delayed/prioritized/completed/failed`, the job hash is `EchoMQ.Keys.job/2`, and a transition
moves the id between them in one `moveToFinished-14.lua` step. No status column means no second fact to disagree with
where the job sits.

A door, not a depth: the full key taxonomy and the include graph that names every structure a transition touches is
E6 · the lifecycle in the dedicated EchoMQ course.

## References

### Sources
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the `wait` and `active` structures a job
  id is pushed onto and moved between.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the scored `delayed`,
  `prioritized`, `completed` and `failed` locations.
- [Redis — Hashes](https://redis.io/docs/latest/develop/data-types/hashes/) — the job hash `emq:{queue}:<id>` updated
  alongside the move.
- [BullMQ — the queue protocol](https://bullmq.io/) — the `wait`/`active`/`completed`/`failed` location model EchoMQ
  ports.

### Related in this course
- [R3.04 · Atomic state machine](/redis-patterns/queues/atomic-state-machine) — the module: the transition as one
  EVALSHA.
- [R3.04.2 · Read-decide-write in one EVALSHA](/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha) —
  the next dive: the move across these locations as one indivisible call.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — the standalone orientation dive on the same
  framing.
- [R3.01 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the in-flight move that parks a job in
  `active`.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the read-modify-write the transition is built
  on.
- [E6 · The job lifecycle](/echomq/lifecycle) — the dedicated EchoMQ course: the full key taxonomy and transition
  graph.
