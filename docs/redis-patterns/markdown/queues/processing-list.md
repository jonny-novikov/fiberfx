# The processing list — the in-flight move

> Route: `/redis-patterns/queues/processing-list` · Module R3.01 · Chapter R3 Reliable Queues.
> · Pattern slug: `reliable-queue` (primary treatment).
> · Grounding: the real as-built EchoMQ worker path in `echo/apps/echo_mq`. The reliable-queue guarantee — a job is
> never lost, only ever moved — lands in EchoMQ as a **leased claim**: `EchoMQ.Jobs.claim/3`
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`) runs one inline `EchoMQ.Script.new(:claim, …)` script, which `ZPOPMIN`s the
> oldest id off `emq:{queue}:pending`, `HINCRBY`s the row's `attempts` field (the fencing token), `HSET`s the row
> `state = active`, and `ZADD`s the id onto `emq:{queue}:active` scored at `now + lease_ms` on the server clock
> (`TIME`) — pop-and-record in one indivisible EVAL. The `active` sorted set is the in-flight ledger; the lease is the
> recovery clock (`EchoMQ.Jobs.reap/2`, `EchoMQ.Stalled`). Keys are built by `EchoMQ.Keyspace.queue_key/2` →
> `emq:{queue}:<type>`. The worked consumer is **codemojex** (`Codemojex.Guesses.submit/3` mints a `JOB`,
> `EchoMQ.Consumer` drains the lane). All real in `echo/apps/echo_mq` and `echo/apps/codemojex`.

Guarantee at-least-once message delivery by atomically transferring a message from the waiting queue into a processing
list, so recovery is possible if a consumer crashes before completing the work.

Standard queue operations using `RPOP` are unreliable — if a consumer fetches a message and crashes before processing
completes, the message is lost forever. This module is the move that prevents that: take the job and **record** that it
is in flight as one indivisible step, so the message is in exactly one place at every instant and a crashed worker
leaves it recoverable, never gone. The three dives take the move apart: the list as a queue, the atomic transfer
command itself, and the in-flight list as the recovery ledger.

## The Problem with Simple Queues

A naive queue implementation:

1. Producer: `LPUSH queue "message"`
2. Consumer: `RPOP queue` — message is removed from Redis
3. Consumer crashes during processing
4. Message is gone permanently

The `RPOP` removes the message before any work runs. Between the pop and the finish there is a window in which the
message exists nowhere — not in the queue, not yet completed. A deploy, an out-of-memory kill, or a power loss in that
window drops the message with nothing to recover it from.

## The Solution: Atomic Transfer

Instead of removing the message, atomically move it into a "processing" list. The message remains in Redis until it is
explicitly removed after successful processing. The transfer is one command — `RPOPLPUSH`, or the modern
`LMOVE work_queue processing:worker1 RIGHT LEFT` — so there is no instant at which the message is in neither place. A
crashed worker leaves the message parked in the processing list, found and returnable.

## How It Works

The consumer uses `LMOVE` (or the older `RPOPLPUSH`) to atomically transfer a message from the main queue to a
processing queue:

    LMOVE work_queue processing:worker1 RIGHT LEFT   # RPOPLPUSH src dst == LMOVE src dst RIGHT LEFT

The single command removes the message from the right of `work_queue`, adds it to the left of `processing:worker1`, and
does both atomically — no message loss is possible. After successful processing, remove the message from the processing
queue with the ack:

    LREM processing:worker1 1 "message"             # remove only after the work is truly done

For consumption without polling, the blocking form `BLMOVE work_queue processing:worker1 RIGHT LEFT 30` waits up to 30
seconds for a message rather than returning immediately on an empty queue.

## The Processing Lifecycle

A message moves through three steps. **Dequeue**: `LMOVE work_queue processing:worker1 RIGHT LEFT`. **Process**: the
application handles the message. **Acknowledge**: `LREM processing:worker1 1 "message"`. If the worker crashes between
the dequeue and the ack, the message remains in `processing:worker1`. That parked message is the seam reliability rests
on: it is still in Redis, attributable to a worker, and returnable for another attempt. Delivery is therefore
at-least-once — a message is delivered one or more times, never zero. R3.02 makes the consumer idempotent for that;
R3.03 reclaims a stalled message. This module stops at the move.

## Per-Worker Processing Queues

Each worker should have its own processing queue — `processing:worker1`, `processing:worker2`. A per-worker list lets a
recovery monitor attribute a parked message to the worker that holds it, and return it cleanly. The processing list is
not only a buffer; it is the **recovery ledger**, the list of exactly the messages currently in flight per worker.

## Applied — the leased claim in EchoMQ

EchoMQ keeps the guarantee — a job is never lost, only ever moved — but realizes the move with a sorted set and a lease
rather than two LISTs. `EchoMQ.Jobs.claim/3` runs one inline `EchoMQ.Script.new(:claim, …)` script that pops the oldest
id off `emq:{queue}:pending` with `ZPOPMIN`, increments the row's `attempts` field (the fencing token), marks the row
`state = active`, and records the id on `emq:{queue}:active` scored at `now + lease_ms` on the server clock — all in one
indivisible EVAL. The `active` sorted set is the in-flight ledger; its score is the lease deadline. There is no gap: the
id is in `pending` or in `active`, never in neither. A crashed worker leaves the id parked in `active`, and
`EchoMQ.Jobs.reap/2` returns any id whose lease score has passed `now` to `pending` for another worker — recovery on
the server's own clock. The worked consumer is **codemojex**: `Codemojex.Guesses.submit/3` mints a `JOB` branded id and
enqueues a guess on the player's lane; `EchoMQ.Consumer` drains the queue through the claim and settles each job.

```
-- the @claim script (echo/apps/echo_mq/lib/echo_mq/jobs.ex) — pop-and-record, one EVAL
local popped = redis.call('ZPOPMIN', KEYS[1])            -- KEYS[1] = emq:{queue}:pending
if #popped == 0 then return {} end
local id  = popped[1]
local att = redis.call('HINCRBY', jk, 'attempts', 1)     -- the fencing token
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')                             -- the server clock
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id) -- KEYS[2] = emq:{queue}:active, at the lease deadline
```

Keys come from `EchoMQ.Keyspace.queue_key/2`, which builds `emq:{queue}:<type>` with the queue name inside `{…}` so
every key of one queue lands on one cluster slot. The branded `JOB` id is gated at the key builder
(`EchoMQ.Keyspace.job_key/2` raises on an ill-formed id). The full leased state machine — the eight inline scripts, the
attempts fencing token, the protocol governance — is the dedicated EchoMQ Queue pillar; this module teaches the move.

## The three dives

- **R3.01.1 · List as wait + active** — the LIST as a queue: `LPUSH` at one end, `RPOP` at the other, FIFO; a reliable
  queue is two named places, and the job moves between them. In EchoMQ those two places are `emq:{queue}:pending` and
  `emq:{queue}:active`, and the job's state is which set holds its id.
- **R3.01.2 · LMOVE / RPOPLPUSH** — the atomic transfer command itself: `RPOP` then `LPUSH` (two steps, a gap that
  loses a job) versus `RPOPLPUSH` / `LMOVE` (one step); the blocking `BLMOVE`. EchoMQ closes the same gap with one
  EVALSHA `@claim` script and a parked `BLPOP wake` rather than a busy poll.
- **R3.01.3 · The in-flight list** — `active` as the recovery ledger: a parked job whose worker died is still there,
  the lease is the recovery clock, and the ack runs only after the work is truly done. In EchoMQ the ack is
  `EchoMQ.Jobs.complete/4`, token-fenced; `reap/2` and `EchoMQ.Stalled` reclaim a stalled lease.

## References

### Sources

- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the original atomic move that parks a message in the
  in-flight list.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the modern successor (Redis 6.2+), with explicit RIGHT/LEFT
  directions, recommended for new code.
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the list-as-queue primitive the move
  rests on.
- [Redis — LREM](https://redis.io/commands/lrem/) — the ack: remove the message from the in-flight list after done.
- [Valkey — ZPOPMIN](https://valkey.io/commands/zpopmin/) — pop the lowest-scored member of a sorted set, the move
  EchoMQ's leased claim runs on the engine the connector is gated against.
- [Salvatore Sanfilippo — RPOPLPUSH, the reliable queue pattern](https://antirez.com/news/77) — the Redis creator's
  design note on the reliable-queue move.

### Related in this course

- [R3.01.1 · List as wait + active](/redis-patterns/queues/processing-list/list-wait-active) — the list as a queue.
- [R3.01.2 · LMOVE / RPOPLPUSH](/redis-patterns/queues/processing-list/lmove-rpoplpush) — the atomic transfer command.
- [R3.01.3 · The in-flight list](/redis-patterns/queues/processing-list/the-in-flight-list) — the recovery ledger.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place: the three guarantees.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move this rests on.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the worker fetch loop and the leased state machine in depth.
