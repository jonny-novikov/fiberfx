# Blocking pop — park the connection, wake on arrival

> Route: `/redis-patterns/queues/blocking-vs-polling/blocking-pop` · Dive R3.05.2 · Module R3.05 blocking-vs-polling
> · Chapter R3 Reliable Queues.
> · Grounding: the source's `Blocking Variant`. EchoMQ's worker parks on a blocking pop — `do_wait_for_job/3` runs
> `BZPOPMIN emq:{queue}:marker timeout` — and uses a **dedicated** blocking connection
> (`EchoMQ.RedisConnection.blocking_connection/1`: *"a dedicated blocking connection for operations like BRPOPLPUSH or
> BZPOPMIN"*) so the main command connection stays free. All real in `echo/apps/echomq`.

A blocking pop removes the poll interval and the wasted round-trips at once. The worker parks on the Redis server and
the call returns the instant an element is available, or after a timeout. It buys that with one cost: a blocking call
ties up the connection for the duration of the block. The discipline is to park the block on a dedicated connection, so
the worker's main connection stays free.

## The primitive

A blocking command does not return immediately on an empty input. It parks the connection on the server until an
element arrives or a timeout elapses. Three forms cover the reliable queue:

```
BLMOVE     wait active RIGHT LEFT 30   # block until wait has an element, then move it; 30s timeout
BRPOPLPUSH wait active 30              # the older blocking move (Redis < 6.2)
BZPOPMIN   marker 30                   # block until the marker ZSET has a member, then pop the lowest
```

Each parks for up to the timeout. `BLMOVE` and `BRPOPLPUSH` block on the work list itself and move an element when one
arrives; `BZPOPMIN` blocks on a sorted set and pops its lowest-scored member. EchoMQ uses the `BZPOPMIN` form on a
marker ZSET — the next dive — but the shape is the same: park, then wake on arrival.

## What blocking removes

Against the polling loop, the blocking pop removes both costs the interval traded between:

```
polling:   poll → nil → sleep → poll → nil → sleep → … → poll → job   (many round-trips, ~½-interval latency)
blocking:  park ────────────────────────────────────── job arrives → return   (1 round-trip, ~0 latency)
```

There is no poll interval, so a job is picked up the moment it arrives, not up to one interval later — pickup latency
is effectively zero. There are no empty round-trips, because the call does not return until there is work or the
timeout fires. The timeout is not a poll interval: it is an upper bound on the park, so the worker can return to
re-check its own liveness and is never blocked forever. A short timeout still costs nothing while idle — re-issuing a
block is not a busy spin.

## The connection cost

The block has one price. While a connection is parked on `BZPOPMIN`, it is busy — a command sent on the **same**
connection waits behind the block until it returns. A worker that blocked on its only connection could not fetch the
job, renew a lock, or acknowledge a result while parked.

```
# one shared connection — the block starves the other commands
conn: BZPOPMIN marker 30     # parked…
conn: SET lock …             # …waits behind the block, cannot run

# a dedicated blocking connection — the main connection stays free
block_conn: BZPOPMIN marker 30   # parks here
main_conn:  SET lock …           # runs immediately on the free connection
```

The fix is a second connection used only for blocking. The worker parks the `BZPOPMIN` on the dedicated connection and
keeps its main connection free for fetches, lock renewals, and acknowledgements.

## In EchoMQ — the dedicated blocking connection

EchoMQ's worker parks on the dedicated connection by design.
`EchoMQ.RedisConnection.blocking_connection/1` — documented as *"a dedicated blocking connection for operations like
BRPOPLPUSH or BZPOPMIN"* — hands the worker a connection used only for the block. The blocking-fetch internals
`EchoMQ.Worker.wait_for_job/2` → `do_wait_for_job/3` run the `BZPOPMIN emq:{queue}:marker timeout` on that connection,
and `do_wait_for_job/3` returns `:job_available` when a marker arrived or `:timeout` when the park elapsed. The worker's
main command connection is untouched while it is parked, so it fetches the woken job and runs the rest of the lifecycle
without waiting behind the block.

```elixir
# EchoMQ.Worker.do_wait_for_job/3 — park on the marker ZSET on the blocking connection (real)
case Redix.command(conn, ["BZPOPMIN", marker_key, timeout_seconds], timeout: :infinity) do
  {:ok, nil}                  -> :timeout         # the park elapsed, no job
  {:ok, [_key, _member, _sc]} -> :job_available   # a marker arrived → a job is available
end
```

The pattern says block on a primitive with a timeout, on a connection set aside for the block; in EchoMQ that is
`BZPOPMIN` on the marker ZSET over `blocking_connection/1`, with the main connection free for the fetch.

## References

### Sources
- [Redis — BLMOVE](https://redis.io/commands/blmove/) — the modern blocking move that parks on the work list until an
  element arrives.
- [Redis — BRPOPLPUSH](https://redis.io/commands/brpoplpush/) — the older blocking reliable-queue pop, the form
  `BLMOVE` succeeds.
- [Redis — BZPOPMIN](https://redis.io/commands/bzpopmin/) — block on a sorted set until a member is added, then pop the
  lowest-scored; the form EchoMQ parks on.
- [BullMQ — the queue protocol](https://bullmq.io/) — the blocking worker wait, on a dedicated connection, that EchoMQ
  ports.

### Related in this course
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the module hub.
- [R3.05.1 · The busy-poll cost](/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost) — the polling loop the
  blocking pop removes.
- [R3.05.3 · The marker wake-up](/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up) — the producer's `ZADD`
  that wakes the parked `BZPOPMIN`.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the wait/active lists the woken worker fetches
  from.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop and the blocking connection.
