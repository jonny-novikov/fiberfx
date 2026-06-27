# List as wait + active — the queue primitive

> Route: `/redis-patterns/queues/processing-list/list-wait-active` · Dive R3.01.1 · Module R3.01 Processing list.
> · Grounding: the real EchoMQ keyspace. `EchoMQ.Keyspace.queue_key/2` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`)
> builds `emq:{queue}:<type>` — the two places a job lives are `emq:{queue}:pending` (the waiting set) and
> `emq:{queue}:active` (the in-flight set), both sorted sets. A job's state is which set holds its branded `JOB` id;
> the move between them is `EchoMQ.Jobs.claim/3`'s leased claim (`ZPOPMIN pending` → record on `active`). Real in
> `echo/apps/echo_mq`.

Everything in a reliable queue rests on one Redis idea: an ordered collection a worker pops one end of. A LIST is the
plainest form — push at one end, pop at the other, and the order out matches the order in. A reliable queue is two such
collections — a waiting one and an in-flight one — and a job that moves from one to the other. EchoMQ uses sorted sets
rather than LISTs for the same shape, so the order is the mint-ordered branded id, but the principle is identical: two
named places, and a job whose state is which place holds it.

## A list is a queue

`LPUSH key value` prepends to the head; `RPOP key` removes from the tail. Push every new job to the head and pop every
job to process from the tail, and the order out matches the order in: a job pushed first is popped first. That is FIFO,
and it is the entire queue discipline — no extra structure, just push one end and pop the other.

```
LPUSH work 5      # head: [5]
LPUSH work 6      # head: [6, 5]
LPUSH work 7      # head: [7, 6, 5]
RPOP  work        # -> 5   (the oldest, popped from the tail)
RPOP  work        # -> 6
```

The list holds the order for free. The producer pushes at the head; the consumer pops at the tail; the list keeps the
sequence between them. A queue is not a separate data structure — it is a list used with a push at one end and a pop at
the other.

## wait and active are two named places

A reliable queue does not use one collection — it uses two. The first is the **waiting** place: jobs a producer has
enqueued and no worker has yet taken. The second is the **active** (in-flight) place: jobs a worker has taken and is
processing. A job lives in exactly one of them at a time, and its membership names its state. A job in the waiting set
is waiting; a job in the active set is being worked.

The two places are named keys. EchoMQ names them with a queue prefix: `emq:{queue}:pending` is the waiting set and
`emq:{queue}:active` is the in-flight set, where `{queue}` stands in for the queue name. The job does not change — it is
the same branded `JOB` id — but which set holds it changes, and that change is the state transition. Reading a job's
state is asking which set its id is in.

```
emq:{queue}:pending  (sorted set)   jobs enqueued, not yet taken — scored at mint order
emq:{queue}:active   (sorted set)   jobs taken by a worker, in flight — scored at the lease deadline
```

## The move between the two

Taking a job for work means moving its id out of `pending` and into `active`. Doing that as two separate steps — pop
from `pending`, then record on `active` — opens a gap: between the two, the id is in neither set, and a crash there
drops it. The next dive is exactly that gap and the single command that closes it. For now, hold the shape: two named
places, and a job that belongs to whichever one currently holds it.

A per-worker variant of the classic LIST form gives each worker its own in-flight list (`processing:worker1`,
`processing:worker2`), so a recovery monitor can attribute a parked job to the worker that holds it. EchoMQ instead
records the lease deadline as the `active` set's score, so the recovery clock is the score rather than a per-worker
list — R3.01.3 reads that ledger.

## The pattern, applied

EchoMQ names the two places through `EchoMQ.Keyspace.queue_key/2`: `queue_key(queue, "pending")` →
`emq:{queue}:pending` and `queue_key(queue, "active")` → `emq:{queue}:active`, both real in `echo/apps/echo_mq`. A new
job is admitted to `pending` (`EchoMQ.Jobs.enqueue/4`); a worker that takes a job moves its id into `active`. The move
itself is `EchoMQ.Jobs.claim/3`'s leased claim — `ZPOPMIN emq:{queue}:pending` then `ZADD emq:{queue}:active` scored at
the lease deadline, in one indivisible script.

```
# EchoMQ.Keyspace.queue_key/2 — the two named places (real)
emq:{queue}:pending   # EchoMQ.Keyspace.queue_key(queue, "pending")
emq:{queue}:active    # EchoMQ.Keyspace.queue_key(queue, "active")
# the claim moves a JOB id: ZPOPMIN pending  ->  ZADD active <now + lease_ms>
```

`{queue}` is the queue name carried inside the braces so every key of one queue lands on one cluster slot. The branded
`JOB` id is gated at the key builder (`EchoMQ.Keyspace.job_key/2` raises on an ill-formed id).

## References

### Sources
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the list type and its push/pop ends, the
  list-as-queue primitive.
- [Redis — LPUSH](https://redis.io/commands/lpush/) — prepend to the head of a list.
- [Redis — RPOP](https://redis.io/commands/rpop/) — remove and return from the tail of a list.
- [Valkey — ZPOPMIN](https://valkey.io/commands/zpopmin/) — pop the lowest-scored member of a sorted set, the move
  EchoMQ uses to take the oldest pending job.

### Related in this course
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the module hub: the in-flight move.
- [R3.01.2 · LMOVE / RPOPLPUSH](/redis-patterns/queues/processing-list/lmove-rpoplpush) — the single command that moves
  a job between the two places without a gap.
- [R3.01.3 · The in-flight list](/redis-patterns/queues/processing-list/the-in-flight-list) — `active` as the recovery
  ledger.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the three guarantees in one place.
- [/echomq/queue](/echomq/queue) — the dedicated EchoMQ Queue pillar: the worker fetch loop in depth.
