# List as wait + active — the queue primitive

> Route: `/redis-patterns/queues/processing-list/list-wait-active` · Dive R3.01.1 · Module R3.01 Processing list.
> · Grounding: EchoMQ names two LISTs per queue — `EchoMQ.Keys.wait/1` builds `emq:{queue}:wait` and
> `EchoMQ.Keys.active/1` builds `emq:{queue}:active`. A job moves between these two named lists; the move is
> `moveToActive-11.lua`'s `rcall("RPOPLPUSH", waitKey, activeKey)`. Real in `echo/apps/echomq`.

Everything in a reliable queue rests on one Redis type: the LIST. A list is an ordered sequence of strings with cheap
push and pop at both ends. Treat one end as the tail and the other as the head, push at one and pop at the other, and a
list becomes a first-in-first-out queue. A reliable queue is two such lists — a waiting list and an in-flight list — and
a job that moves from one to the other.

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

## wait and active are two named lists

A reliable queue does not use one list — it uses two. The first is the **waiting** list: jobs a producer has enqueued
and no worker has yet taken. The second is the **active** (in-flight) list: jobs a worker has taken and is processing.
A job lives in exactly one of them at a time, and its position names its state. A job in the waiting list is waiting; a
job in the active list is being worked.

The two lists are named keys. EchoMQ names them with a queue prefix: `emq:{queue}:wait` is the waiting list and
`emq:{queue}:active` is the in-flight list, where `{queue}` stands in for the queue name. The job does not change — it
is the same string id — but which list holds it changes, and that change is the state transition. Reading a job's state
is asking which list it is in.

```
emq:{queue}:wait    (LIST)   jobs enqueued, not yet taken
emq:{queue}:active  (LIST)   jobs taken by a worker, in flight
```

## The move between the two lists

Taking a job for work means moving it out of the waiting list and into the active list. Doing that as two separate
commands — pop from `wait`, then push to `active` — opens a gap: between the two, the job is in neither list, and a
crash there drops it. The next dive is exactly that gap and the single command that closes it. For now, hold the shape:
two named lists, and a job that belongs to whichever one currently holds it.

A per-worker variant gives each worker its own in-flight list (`processing:worker1`, `processing:worker2`), so a
recovery monitor can attribute a parked job to the worker that holds it. The lists are still LISTs, and the move is
still a move between two of them — only the destination is now worker-specific. R3.01.3 builds on that.

## The pattern, applied

EchoMQ names the two lists with `EchoMQ.Keys.wait/1` (`"#{base(ctx)}:wait"` → `emq:{queue}:wait`) and
`EchoMQ.Keys.active/1` (`"#{base(ctx)}:active"` → `emq:{queue}:active`), both real in `echo/apps/echomq`. A new job is
pushed to the waiting list; a worker that takes a job moves it into the active list. The move itself is
`moveToActive-11.lua`'s `rcall("RPOPLPUSH", waitKey, activeKey)` — the job leaves the `wait` LIST and lands in the
`active` LIST as one command.

```lua
-- moveToActive-11.lua — the two lists, named (real)
local waitKey = KEYS[1]      -- emq:{queue}:wait   (EchoMQ.Keys.wait/1)
local activeKey = KEYS[2]    -- emq:{queue}:active (EchoMQ.Keys.active/1)
local jobId = rcall("RPOPLPUSH", waitKey, activeKey)  -- wait -> active
```

`{queue}` is a documentation placeholder for the queue name — the real builder is `EchoMQ.Keys.base/1`
(`"#{prefix}:#{name}"`), not the cluster hash-tag `{tag}`.

## References

### Sources
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the list type and its push/pop ends, the
  list-as-queue primitive.
- [Redis — LPUSH](https://redis.io/commands/lpush/) — prepend to the head of a list.
- [Redis — RPOP](https://redis.io/commands/rpop/) — remove and return from the tail of a list.
- [BullMQ — the queue protocol](https://bullmq.io/) — the wait/active list layout EchoMQ ports.

### Related in this course
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the module hub: the in-flight move.
- [R3.01.2 · LMOVE / RPOPLPUSH](/redis-patterns/queues/processing-list/lmove-rpoplpush) — the single command that moves
  a job between the two lists without a gap.
- [R3.01.3 · The in-flight list](/redis-patterns/queues/processing-list/the-in-flight-list) — `active` as the recovery
  ledger.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the three guarantees in one place.
- [E2 · the engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop in depth.
