# Blocking vs polling — park the worker, do not spin it

> Route: `/redis-patterns/queues/blocking-vs-polling` · Module R3.05 · Chapter R3 Reliable Queues.
> Grounding: the real Elixir `EchoMQ.Consumer` (`echo/apps/echo_mq/lib/echo_mq/consumer.ex`). When no job is
> immediately serviceable, the consumer parks on a dedicated wake key with `BLPOP emq:{queue}:wake <beat>` and
> returns the instant readiness arrives as a wake or the beat elapses — "park, don't poll: a parked consumer costs
> the wire nothing." The producer side rings the doorbell from inside the admit/promote/reclaim Lua:
> `LPUSH emq:{queue}:wake '1'` then `LTRIM emq:{queue}:wake 0 63` (verified in `jobs.ex`, `lanes.ex`, `stalled.ex`),
> which makes the parked `BLPOP` return. The beat (`:beat_ms`, default 1000) is the fallback timeout that doubles as
> the reap/promote cadence; `:lease_ms` defaults to 30_000. For a pool, one `EchoMQ.Metronome` holds the single block
> per queue and fans readiness to registered-idle consumers — one blocker, the herd gone. All real in
> `echo/apps/echo_mq`. The worked consumer is **codemojex** (`echo/apps/codemojex`).

Guarantee at-least-once message delivery using an atomic transfer to a processing list, enabling recovery if
consumers crash before completing work.

The reliable queue answers *where a job lives*: it parks in an in-flight state under a server-clock lease so a crash
leaves it recoverable, not lost. This module answers a second question the reliable queue raises — *how does a worker
take the next job off an empty queue?* A queue is empty most of the time. A worker that spins a pop/sleep loop on an
idle queue burns a round-trip on every empty poll and picks a job up to one sleep-interval late. The blocking variant
replaces that spin: the worker parks on a blocking primitive, and the engine returns the instant work arrives. EchoMQ
parks on a dedicated wake key with `BLPOP` and rings it with `LPUSH` when a job is admitted — the same idea (park
instead of poll), made precise as a per-queue doorbell.

## The blocking variant

The source's reliable-queue loop, in polling form, pops from the work list and falls back to a sleep:

```
# the polling loop: spin, sleep, retry
loop:
  job = pop work_queue -> processing   # nil if the queue is empty
  if job == nil:
    sleep(interval)                    # burn the interval, then poll again
    continue
  process(job)
```

For efficient consumption without polling, the source offers the blocking form:

```
BLMOVE work_queue processing:worker1 RIGHT LEFT 30
```

This waits up to 30 seconds for a message to arrive. If the queue is empty, the connection parks on the server rather
than returning immediately. There is no poll interval and no wasted round-trip: the call returns the instant an
element is available, or after the timeout elapses. `BLMOVE` is the modern blocking move; `BRPOPLPUSH` is its older
form; both park the connection on the work list itself.

EchoMQ keeps the idea and changes the primitive. The consumer does not park on the work list. It parks on a dedicated
wake key, `emq:{queue}:wake` — a short capped LIST — with `BLPOP emq:{queue}:wake <beat>`. When a producer admits a
job, the admit script also runs `LPUSH emq:{queue}:wake '1'` (then `LTRIM emq:{queue}:wake 0 63` to bound the list),
which makes the parked `BLPOP` return; the consumer then drains the ring with `EchoMQ.Lanes.claim/3`. Same trade as
`BLMOVE` — park instead of poll, wake the instant work arrives, burn no idle round-trips — applied through a separate
signalling key rather than the work list, so a wake fires regardless of which lane the new work landed on.

## The busy-poll cost

The naive wait is a spin: pop the work list; if the result is nil, `sleep(interval)`; repeat. Each empty poll is a
wasted round-trip — a command sent and a nil sent back, for no work. A job that arrives one millisecond after a poll
waits the rest of the interval before the next poll picks it up, so average pickup latency is about half the interval.
The interval is the only dial, and it has no good setting: a short interval cuts latency but multiplies the empty
round-trips on an idle queue; a long interval cuts the round-trips but lengthens pickup latency. Polling pays for
*checking* whether work exists separately from *doing* the work, so it pays both costs at the same time. The first
dive quantifies the trade with a poll-cost calculator.

## Blocking pop

A blocking pop — `BLMOVE`, `BRPOPLPUSH`, or `BLPOP` with a timeout — parks the connection on the server until an
element is available or the timeout elapses. There is no poll interval, so a job is picked up the moment it arrives,
not up to one interval later. There are no empty round-trips, because the call does not return until there is work or
the timeout fires.

The cost is the connection. While a connection is parked on a blocking call, it is occupied — a command sent on the
*same* connection waits behind the block. EchoMQ parks the block on a **dedicated connector lane** (the consumer's
moduledoc: "a dedicated connector — blocking verbs get their own lane"), so the lane that drains and settles jobs is
never tied up by a park. The second dive builds the primitive and the dedicated-connection discipline.

## The wake-up doorbell

EchoMQ's consumer loop makes the handshake precise. The consumer beats on a cadence: reap expired leases, promote due
schedules, drain the ring with rotating claims, then park on the wake key with `BLPOP emq:{queue}:wake <beat>` until
readiness arrives as a wake or the beat elapses. The park is `EchoMQ.Consumer`'s `park/1`:

```elixir
# EchoMQ.Consumer.park/1 — park on the wake key for one beat, no spin (real, Elixir)
defp park(s) do
  secs = :erlang.float_to_binary(s.beat_ms / 1000, decimals: 3)
  wake = Keyspace.queue_key(s.queue, "wake")          # emq:{queue}:wake
  _ = Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)
  :ok
end
```

The producer side rings the doorbell from inside the admit Lua: pushing a job onto the ring runs
`LPUSH emq:{queue}:wake '1'`, then `LTRIM emq:{queue}:wake 0 63` to cap the list at 64 tokens (the same two calls
appear in the promote and reclaim scripts in `jobs.ex`, `lanes.ex`, and `stalled.ex`). The `LPUSH` makes the parked
`BLPOP` return, and the consumer drains. The wake key is a signal, not a queue: `BLPOP` pops one element, so one
`LPUSH` wakes one parked block. The beat is the fallback: when no wake arrives, `BLPOP` times out after one beat and
the loop runs its reap/promote pump anyway, so a due schedule or an expired lease is never stranded. The third dive
walks the full handshake and the pool's one-blocker `EchoMQ.Metronome`.

## When to use

Park instead of poll whenever a worker waits on a queue that is empty much of the time and pickup latency matters. A
busy-poll loop is acceptable only when a blocking connection is not available, or when the producer cannot ring a
signal and the worker must re-check on its own cadence. Otherwise the blocking form wins on both axes it trades
against: lower latency and fewer round-trips at once. EchoMQ takes a third position for a pool — one
`EchoMQ.Metronome` holds the single block per queue and pokes idle consumers, so the connection cost of blocking is
paid once, not once per worker.

| Concern | Choice |
| --- | --- |
| Wait for the next job | park on a primitive with a timeout, not a pop/sleep loop |
| The primitive | `BLMOVE`/`BRPOPLPUSH` on a work list, or `BLPOP` on a wake key |
| The wake signal | the admit script `LPUSH`es the wake key (`LPUSH emq:{queue}:wake '1'`, `LTRIM … 0 63`) |
| The connection | a dedicated connector lane, so the drain/settle lane stays free |
| Bound the wait | the beat (`:beat_ms`) is the timeout, so the loop re-runs its pump and is never parked forever |
| A pool | one `EchoMQ.Metronome` blocks per queue and pokes idle consumers — one blocker, no herd |

## The three dives

Each dive takes one part of the move, in order: the cost the polling loop pays, the blocking primitive that removes
it, and the EchoMQ-specific wake handshake that returns the parked consumer.

- **R3.05.1 · The busy-poll cost** — the naive pop/sleep loop: every empty poll is a wasted round-trip, a job waits
  up to one interval before pickup, and the interval is the only dial — no setting wins.
- **R3.05.2 · Blocking pop** — `BLMOVE`/`BRPOPLPUSH`/`BLPOP` with a timeout park the connection until work arrives —
  no interval, no wasted round-trips — on a dedicated connector lane that keeps the drain lane free.
- **R3.05.3 · The wake-up doorbell** — the EchoMQ handshake: the consumer parks on `BLPOP emq:{queue}:wake`; the admit
  script `LPUSH`es the wake key; the parked block returns; the beat is the fallback; the pool's `EchoMQ.Metronome`
  blocks once and fans readiness out.

## The bridge

**The pattern:** park on a primitive with a timeout instead of polling, so the worker wakes the instant work arrives
and burns no idle round-trips. Ring a signal when work is added, so one ring wakes one parked worker.

**Its EchoMQ application:** `EchoMQ.Consumer` parks on `BLPOP emq:{queue}:wake <beat>` on a dedicated connector lane;
the admit Lua `LPUSH`es the wake key (capped by `LTRIM … 0 63`), the beat is the fallback cadence, and for a pool one
`EchoMQ.Metronome` holds the single block. **codemojex** rides this: `EchoMQ.Consumer` drains the guess queue through
`Lanes.claim`, woken when `Codemojex.Game` admits a guess `JOB`.

## On Valkey

`BLPOP` removes and returns the first element of a list, or parks the connection until an element is pushed or the
timeout elapses — the engine wakes exactly one of several connections parked on the same key, in the order they
parked (valkey.io/commands/blpop). The reap/promote cadence reads the **server clock** (`TIME`) so no host timestamp
crosses a lease.

## References

### Sources

- [Valkey — BLPOP](https://valkey.io/commands/blpop/) — block until an element is pushed to a list; the park the consumer makes on the wake key.
- [Valkey — LPUSH](https://valkey.io/commands/lpush/) — push the wake token that returns a parked `BLPOP`.
- [Redis — BLMOVE](https://redis.io/commands/blmove/) — the modern blocking reliable-queue pop the source uses.
- [Redis — BRPOPLPUSH](https://redis.io/commands/brpoplpush/) — the older blocking reliable-queue pop.
- [Redis — Documentation](https://redis.io/docs/) — lists, blocking commands, and the reliable-queue access pattern in context.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [R3.05.1 · The busy-poll cost](/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost) — the cost the loop pays.
- [R3.05.2 · Blocking pop](/redis-patterns/queues/blocking-vs-polling/blocking-pop) — the primitive that removes it.
- [R3.05.3 · The wake-up doorbell](/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up) — the EchoMQ wake handshake.
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the wait/active states the consumer drains.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the consumer loop and the wake key in depth.
