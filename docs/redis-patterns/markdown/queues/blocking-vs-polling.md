# Blocking vs polling — wake the worker, do not spin it

> Route: `/redis-patterns/queues/blocking-vs-polling` · Module R3.05 · Chapter R3 Reliable Queues.
> · Grounding: EchoMQ's worker fetch loop. When no job is immediately available, the worker blocks on a marker ZSET —
> `EchoMQ.Worker.do_wait_for_job/3` runs `BZPOPMIN emq:{queue}:marker timeout` on a dedicated blocking connection
> (`EchoMQ.RedisConnection.blocking_connection/1`) and returns `:job_available` or `:timeout`. The producer side, when
> adding a job, rings the doorbell: `addBaseMarkerIfNeeded` runs `ZADD emq:{queue}:marker 0 "0"` (verified in
> `addStandardJob-9.lua` and `drain-5.lua`), which makes the blocked `BZPOPMIN` return. The Go port's empty-queue
> worker loop polls instead — `time.Sleep(100 * time.Millisecond)` / `time.Sleep(time.Second)` in
> `apps/echomq-go/pkg/echomq/worker_impl.go` — the cross-runtime contrast. All real in `echo/apps/echomq`.

Guarantee at-least-once message delivery using LMOVE to atomically transfer messages to a processing list, enabling
recovery if consumers crash before completing work.

The reliable queue answers *where a job lives*: it parks in an in-flight list under a lock so a crash leaves it
recoverable, not lost. This module answers a second question the reliable queue raises — *how does a worker take the
next job off an empty queue?* A queue is empty most of the time. A worker that spins a `RPOP`/sleep loop on an idle queue burns a
round-trip on every empty poll and picks a job up to one sleep-interval late. The blocking variant replaces that spin:
the worker parks on a blocking primitive, and Redis returns the instant work arrives. EchoMQ blocks on a dedicated
marker ZSET with `BZPOPMIN`, and adding a job `ZADD`s the marker — the same idea (block instead of poll), a different
primitive.

## The blocking variant

The source's reliable-queue loop, polling form, pops from the work list and falls back to a sleep:

```
# the polling loop: spin, sleep, retry
loop:
  job = RPOPLPUSH work_queue processing   # nil if the queue is empty
  if job == nil:
    sleep(interval)                       # burn the interval, then poll again
    continue
  process(job)
```

For efficient consumption without polling, the source offers the blocking form:

```
BLMOVE work_queue processing:worker1 RIGHT LEFT 30
```

This waits up to 30 seconds for a message to arrive. If the queue is empty, the connection blocks on the server rather
than returning immediately. There is no poll interval and no wasted round-trip: the call returns the instant an element
is available, or after the timeout elapses. `BLMOVE` is the modern blocking move; `BRPOPLPUSH` is its older form; both
park the connection on the work list itself.

EchoMQ keeps the idea and changes the primitive. It does not block on the work list. It blocks on a dedicated **marker
ZSET**, `emq:{queue}:marker`, with `BZPOPMIN` — a doorbell. When a producer adds a job to `wait`, it also `ZADD`s a
member onto the marker, which makes the blocked `BZPOPMIN` return; the worker then fetches the job from `wait`/`active`
on its main connection. Same trade as `BLMOVE` — block instead of poll, wake the instant work arrives, burn no idle
round-trips — applied through a separate signalling key rather than the work list.

## The busy-poll cost

The naive loop is `RPOP wait`; if the result is nil, `sleep(interval)`; repeat. Each empty poll is a wasted
round-trip. A job that arrives one millisecond after a poll waits the rest of the interval before the next poll picks
it up, so average pickup latency is about half the interval. The interval is the only dial, and it has no good
setting: a short interval cuts latency but multiplies the empty round-trips on an idle queue; a long interval cuts the
round-trips but lengthens pickup latency. Polling trades one cost for the other and pays both at the same time.

## Blocking pop

A blocking pop — `BLMOVE`, `BRPOPLPUSH`, or `BZPOPMIN` with a timeout — parks the connection on the Redis server until
an element is available or the timeout elapses. There is no poll interval, so a job is picked up the moment it arrives,
not up to one interval later. There are no empty round-trips, because the call does not return until there is work or
the timeout fires. The cost is the connection: a blocking call ties up the connection for the duration of the block, so
a command sent on the same connection waits behind it. EchoMQ avoids that by parking the block on a **dedicated**
blocking connection (`EchoMQ.RedisConnection.blocking_connection/1`), leaving the worker's main command connection free
for fetches and acknowledgements.

## The marker wake-up

EchoMQ's blocking-fetch path makes the handshake precise. The worker blocks on `emq:{queue}:marker` — a ZSET, built
by `EchoMQ.Keys.marker/1` and documented as the *"marker sorted set (for blocking operations)"*. The blocking-fetch
internals are `EchoMQ.Worker.wait_for_job/2` → `do_wait_for_job/3` (both private worker functions): `do_wait_for_job/3`
runs `BZPOPMIN marker_key timeout` and returns `:job_available` when a marker arrived or `:timeout` when none did. The
producer side rings the doorbell: adding a job runs `addBaseMarkerIfNeeded`, which is `ZADD emq:{queue}:marker 0 "0"`
(verified in `addStandardJob-9.lua` and `drain-5.lua`). The full handshake:

1. The worker parks on `BZPOPMIN emq:{queue}:marker timeout` on its dedicated blocking connection.
2. A producer adds a job to `wait` and runs `ZADD emq:{queue}:marker 0 "0"`.
3. The `ZADD` makes the parked `BZPOPMIN` return — `do_wait_for_job/3` reads `:job_available`.
4. The worker fetches the job from `wait`/`active` on its main connection and runs it.

The marker is a signal, not a queue: `BZPOPMIN` pops the lowest-scored member, so one `ZADD` wakes one parked
`BZPOPMIN`. The Go port's empty-queue worker loop is the cautionary contrast: `apps/echomq-go/pkg/echomq/worker_impl.go`
sleeps a fixed interval (`time.Sleep(100 * time.Millisecond)` / `time.Sleep(time.Second)`) when the queue is empty — a
sleep-interval poll rather than a block on the marker.

## When to use

Block instead of poll whenever a worker waits on a queue that is empty much of the time and pickup latency matters. A
busy-poll loop is acceptable only when a blocking connection is not available, or when the producer cannot ring a
signal and the worker must therefore re-check on its own cadence. Otherwise the blocking form wins on both axes it
trades against: lower latency and fewer round-trips at once.

| Concern | Choice |
| --- | --- |
| Wait for the next job | block on a primitive with a timeout, not a `RPOP`/sleep loop |
| The primitive | `BLMOVE`/`BRPOPLPUSH` on the work list, or `BZPOPMIN` on a dedicated marker ZSET |
| The wake-up signal | the producer `ZADD`s the marker (`ZADD emq:{queue}:marker 0 "0"`) when it adds a job |
| The connection | a dedicated blocking connection, so the main command connection stays free |
| Bound the wait | a timeout, so the worker can re-check liveness and is never parked forever |

## The three dives

Each dive takes one part of the move, in order: the cost the polling loop pays, the blocking primitive that removes it,
and the EchoMQ-specific marker handshake that wakes the worker. Read them in order — the cost first, the primitive
second, the marker wake-up third.

- **The busy-poll cost** — the naive `RPOP`/sleep loop: every empty poll is a wasted round-trip, and a job waits up to
  one interval before pickup. The interval is the only dial, and no setting wins.
- **Blocking pop** — `BLMOVE`/`BRPOPLPUSH`/`BZPOPMIN` with a timeout: the connection parks on the server until an
  element arrives, so there is no interval and no wasted round-trip — at the cost of a tied-up connection, which a
  dedicated blocking connection keeps off the main one.
- **The marker wake-up** — the EchoMQ handshake: the worker parks on `BZPOPMIN emq:{queue}:marker`; the producer
  `ZADD`s the marker; the parked `BZPOPMIN` returns; the worker fetches the job.

## References

### Sources
- [Redis — BZPOPMIN](https://redis.io/commands/bzpopmin/) — block on a sorted set until a member is added; the marker
  pop EchoMQ's worker parks on.
- [Redis — BLMOVE](https://redis.io/commands/blmove/) — the modern blocking move, the reliable-queue pop that parks on
  the work list.
- [Redis — BRPOPLPUSH](https://redis.io/commands/brpoplpush/) — the older blocking reliable-queue pop, the form the
  source's `BLMOVE` succeeds.
- [Redis — ZADD](https://redis.io/commands/zadd/) — add a member to a sorted set; the producer's `ZADD marker` that
  wakes a blocked worker.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the ZSET behind the marker and
  the `BZPOPMIN` pop.
- [BullMQ — the queue protocol](https://bullmq.io/) — the marker / `BZPOPMIN` worker wait EchoMQ ports.

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [R3.05.1 · The busy-poll cost](/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost) — the cost the polling
  loop pays.
- [R3.05.2 · Blocking pop](/redis-patterns/queues/blocking-vs-polling/blocking-pop) — the primitive that removes it.
- [R3.05.3 · The marker wake-up](/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up) — the EchoMQ marker
  handshake.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place, where the blocking
  variant is introduced.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the wait/active lists the worker pops from.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop and the blocking connection.
- [E6 · The job lifecycle](/echomq/lifecycle) — the marker / heartbeat coordination and the polyglot concurrency
  models.
