# The Queue — EchoMQ, In Depth (route mirror: `/echomq/queue`)

> Route-mirror md for the Queue chapter **landing**. The HTML at `html/echomq/queue/index.html` reflects this.
> All grounding is **real code** in `echo/apps/echo_mq` — this chapter carries **no `[RECONCILE]` markers**.

## Thesis

The Queue is the first pillar: **distribute work over the wire**. A producer enqueues a job; one worker claims it,
runs it, and completes it; a failure retries with backoff or dies into a morgue. It is a **state machine over four
sorted sets** — `pending`, `active`, `schedule`, `dead` — where the **active-set score is the lease deadline** and the
row's **`attempts` is the fencing token** (no separate lock). Above the machine sit fair **lanes** over a rotating
ring, a **consumer loop** that parks instead of polling, bulk **batches**, the **lifecycle controls** (schedule,
backoff, repeat, cancel, checkpoint, stalled, the operator plane), and parent/child **flows** with an atomic fan-in.

## The life of a job (the framing interactive)

A job is one row and a place in one of four sorted sets; every verb moves it between places.

- **pending** — waiting to be claimed; arrives by a fresh enqueue, a promoted schedule, a reaped lease, or a released
  flow parent; leaves by `claim → active`. Members are the branded ids themselves, so byte order is mint order.
- **active** — leased to one worker; the active-set score IS the lease deadline, the row's `attempts` IS the fencing
  token; leaves by `complete → done`, `retry → scheduled|dead`, or `reap → pending` if the lease lapses.
- **scheduled** — parked until a run-at time (a visibility fence, not a second queue); arrives by `enqueue_at`/
  `enqueue_in` or a backoff retry; leaves by `promote → pending` once due.
- **dead** — failed past max attempts (the morgue); `last_error` records why; leaves only by `reprocess_job → pending`.
- **awaiting_children** — a flow parent held out of pending with a `:dependencies` counter of N; the fan-in releases it.

## The modules

1. **The lifecycle** (`/echomq/queue/the-lifecycle`) — the state machine: the four sorted sets, the lease that is the
   active score, attempts as the fencing token; claim/complete/retry/reap/reprocess.
2. **Jobs, lanes & the consumer** (`/echomq/queue/jobs-lanes-consumer`) — the idempotent `@enqueue` producer; fair
   lanes over a rotating `ring` (`LMOVE` rotate-one-step); the supervised consumer loop that parks on `BLPOP wake`.
3. **Batches** (`/echomq/queue/batches`) — `enqueue_many/3` (the `EVALSHA` pipeline, per-item verdicts in order),
   `Flows.add_bulk/3` (fail-closed per flow), `extend_locks/4` (batch lease extension under one clock read).
4. **Lifecycle controls** (`/echomq/queue/lifecycle-controls`) — scheduling + `Backoff` + `Repeat`; `Cancel` +
   `extend_lock` + `Stalled`; the `Admin` queue-scope plane + the per-job operator verbs.
5. **Flows** (`/echomq/queue/flows`) — parent/child orchestration: the atomic same-queue `@enqueue_flow` + the fan-in;
   `children_values`/`dependencies`/`ignored_failures`; cross-queue (host-orchestrated, eventually-consistent) + the
   failure policy.
6. **Workshop** (`/echomq/queue/workshop`) — trace one job across the four sets, then compose a flow.

## Redis Patterns Applied (the door)

The far side of `/redis-patterns` queue chapters: **R3 · Queues** (`/redis-patterns/queues`) — the reliable-queue,
ack, and visibility patterns this state machine makes concrete; **R4 · Time, delay & priority**
(`/redis-patterns/time-delay-priority`) — the delayed/scheduled jobs the schedule set carries. **R6 · Flow control**
(orchestration) lands in the Flows module (R6 not yet built — named, not linked).

## The durable floor (the door to Echo Persistence)

A queue keeps its history in memory until a system decides how much to keep. What it trims is not lost:
`EchoStore.StreamArchive` folds the trimmed segments into the durable `EchoStore.Graft` floor — CubDB's append-only
B-tree, on to Tigris object storage — deep history without resident memory, readable beside the live tail. The fold
itself is real code (`echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`); the durable floor is taught in
full in Echo Persistence (`/echo-persistence`), narrated in the manuscript at `docs/echo/bcs/bcs.3.md` B3.3 / `bcs.5.md`.

## References

### Sources
- Valkey — Documentation (`https://valkey.io/docs/`) — the store the sets, rows, and scripts run inside.
- Valkey — ZPOPMIN (`https://valkey.io/commands/zpopmin/`) — the oldest-pending pop the claim is built on.
- Valkey — LMOVE (`https://valkey.io/commands/lmove/`) — the rotate-one-step the fair-lane ring uses.
- Valkey — BLPOP (`https://valkey.io/commands/blpop/`) — the park the consumer loop blocks on.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the load-once, run-by-SHA dispatch every transition uses.

### Related in this course
- The Protocol (`/echomq/protocol`) — the substrate the Queue runs on.
- Overview (`/echomq/overview`) — the chapter that frames the three pillars.
- redis-patterns R3 · Queues (`/redis-patterns/queues`) — the near side of the door.
- Echo Persistence (`/echo-persistence`) — the durable floor a trimmed queue history folds into.
- The Branded Component System (`/bcs`) — the architecture the wire belongs to.
