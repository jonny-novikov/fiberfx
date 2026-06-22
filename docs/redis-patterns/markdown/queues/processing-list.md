# The processing list — the in-flight move

> Route: `/redis-patterns/queues/processing-list` · Module R3.01 · Chapter R3 Reliable Queues.
> · Pattern slug: `reliable-queue` (primary treatment).
> · Grounding: EchoMQ's worker fetch loop. `EchoMQ.Scripts.move_to_active/4` runs `moveToActive-11.lua`, whose body
> is `rcall("RPOPLPUSH", waitKey, activeKey)` — a job leaves `emq:{queue}:wait` and lands in `emq:{queue}:active`
> under a lock in one atomic step, so a crash parks it recoverable, never lost. `EchoMQ.Keys.wait/1` /
> `EchoMQ.Keys.active/1` / `EchoMQ.Keys.lock/2` name the keys. All real in `echo/apps/echomq`.

Guarantee at-least-once message delivery using LMOVE to atomically transfer messages to a processing list, enabling
recovery if consumers crash before completing work.

Standard queue operations using `RPOP` are unreliable — if a consumer fetches a message and crashes before processing
completes, the message is lost forever. This module is the move that prevents that: pop from one list and push to a
second, in-flight list as one indivisible command, so the message is in exactly one list at every instant and a crashed
worker leaves it recoverable. The three dives take the move apart: the list as a queue, the atomic transfer command
itself, and the in-flight list as the recovery ledger.

## The Problem with Simple Queues

A naive queue implementation:

1. Producer: `LPUSH queue "message"`
2. Consumer: `RPOP queue` — message is removed from Redis
3. Consumer crashes during processing
4. Message is gone permanently

The `RPOP` removes the message before any work runs. Between the pop and the finish there is a window in which the
message exists nowhere — not in the queue, not yet completed. A deploy, an OOM kill, or a power loss in that window
drops the message with nothing to recover it from.

## The Solution: Atomic Transfer

Instead of removing the message, atomically move it to a "processing" list. The message remains in Redis until it is
explicitly deleted after successful processing. The transfer is one command — `RPOPLPUSH` or the modern `LMOVE` — so
there is no instant at which the message is in neither list. A crashed worker leaves the message parked in the
processing list, found and returnable.

## How It Works

The consumer uses `LMOVE` (or the older `RPOPLPUSH`) to atomically transfer a message from the main queue to a
processing queue:

```
LMOVE work_queue processing:worker1 RIGHT LEFT
```

This single command:

- Removes the message from the right of `work_queue`
- Adds it to the left of `processing:worker1`
- Does both atomically — no message loss is possible

The older `RPOPLPUSH source dest` is the same move in fixed directions: `RPOPLPUSH src dst` is exactly
`LMOVE src dst RIGHT LEFT`. After successful processing, remove the message from the processing queue:

```
LREM processing:worker1 1 "message"
```

For consumption without polling, the blocking form `BLMOVE work_queue processing:worker1 RIGHT LEFT 30` waits up to 30
seconds for a message rather than returning immediately on an empty queue.

## The Processing Lifecycle

1. **Dequeue**: `LMOVE work_queue processing:worker1 RIGHT LEFT`
2. **Process**: the application handles the message
3. **Acknowledge**: `LREM processing:worker1 1 "message"`

If the worker crashes between steps 1 and 3, the message remains in `processing:worker1`. That parked message is the
seam reliability rests on: it is still in Redis, attributable to a worker, and returnable to the main queue for another
attempt. Delivery is therefore **at-least-once** — a message is delivered one or more times, never zero — which R3.02
makes the consumer idempotent for, and R3.03 reclaims a stalled message with. This module stops at the move.

## Per-Worker Processing Queues

Each worker should have its own processing queue (`processing:worker1`, `processing:worker2`). A per-worker list lets a
recovery monitor attribute a parked message to the worker that holds it and return it cleanly. The processing list is
not only a buffer — it is the recovery ledger, a list of exactly the messages currently in flight per worker.

## The pattern, applied

EchoMQ's worker fetch loop is this move in real code, in `echo/apps/echomq`. `EchoMQ.Scripts.move_to_active/4` runs
`moveToActive-11.lua`, whose move is `rcall("RPOPLPUSH", waitKey, activeKey)`, where `waitKey` is `emq:{queue}:wait`
and `activeKey` is `emq:{queue}:active` (`EchoMQ.Keys.wait/1` and `EchoMQ.Keys.active/1`). The job leaves `wait` and
lands in `active` under a lock named by `EchoMQ.Keys.lock/2` (`emq:{queue}:<id>:lock`) in one atomic script — a crash
leaves it in `active`, recoverable, never lost.

```lua
-- moveToActive-11.lua — the atomic in-flight move (real)
local waitKey = KEYS[1]      -- emq:{queue}:wait
local activeKey = KEYS[2]    -- emq:{queue}:active
local jobId = rcall("RPOPLPUSH", waitKey, activeKey)  -- wait -> active, atomically
```

The `{queue}` here is a documentation placeholder for the queue name; the real builder is `EchoMQ.Keys.base/1`
(`"#{prefix}:#{name}"`), so the queue `my_queue` yields `emq:my_queue:wait`. This is not the cluster hash-tag `{tag}`
that forces slot colocation — it is the queue name standing in for readability.

The full worker fetch loop — the eleven-key `moveToActive` include graph, the heartbeat manager that renews the lock,
and the polyglot concurrency models — is the dedicated EchoMQ course. This module teaches the move; that course teaches
the engine that runs it.

## The three dives

- **R3.01.1 · List as wait + active** — the LIST as a queue: `LPUSH` at one end, `RPOP` at the other, FIFO; `wait` and
  `active` are two named lists, and the job moves between them.
- **R3.01.2 · LMOVE / RPOPLPUSH** — the atomic transfer command itself: `RPOP` then `LPUSH` (two steps, a gap that
  loses a job) versus `RPOPLPUSH` / `LMOVE` (one step); the blocking `BLMOVE` / `BRPOPLPUSH`.
- **R3.01.3 · The in-flight list** — `active` as the recovery ledger: a parked job whose worker died is still there,
  per-worker lists, and the `LREM active 1 job` ack only after the work is truly done.

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the original atomic move that parks a message in the
  in-flight list, the heart of `moveToActive-11.lua`.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the modern successor (Redis 6.2+), with explicit `RIGHT`/`LEFT`
  directions, recommended for new code.
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the list-as-queue primitive the whole move
  rests on.
- [Salvatore Sanfilippo — RPOPLPUSH, the reliable queue pattern](https://antirez.com/news/77) — the Redis creator's
  design note on the reliable-queue move.
- [BullMQ — the queue protocol](https://bullmq.io/) — the wait/active worker path EchoMQ ports, where "the Lua scripts
  are the protocol."

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the whole reliable-queue family.
- [R3.01.1 · List as wait + active](/redis-patterns/queues/processing-list/list-wait-active) — the list as a queue.
- [R3.01.2 · LMOVE / RPOPLPUSH](/redis-patterns/queues/processing-list/lmove-rpoplpush) — the atomic transfer command.
- [R3.01.3 · The in-flight list](/redis-patterns/queues/processing-list/the-in-flight-list) — the recovery ledger.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place: the three guarantees.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move this rests on.
- [E2 · the engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop in depth.
