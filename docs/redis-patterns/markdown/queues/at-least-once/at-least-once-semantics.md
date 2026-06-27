# At-least-once semantics — one or more times, never zero

> Route: `/redis-patterns/queues/at-least-once/at-least-once-semantics` · Dive R3.02.1.
> · Grounding: the real EchoMQ leased state machine in `echo/apps/echo_mq`. `EchoMQ.Jobs.claim/3` leases the oldest
> pending job on the server clock (`TIME`) and makes it active; `EchoMQ.Jobs.complete/5` settles it; a worker that
> dies holding a job loses the lease and `EchoMQ.Jobs.reap/2` returns the expired lease to pending — crash recovery on
> the server's clock (`bcs.3.md` B3.2). Held-until-acknowledged plus recover-on-expired-lease is at-least-once: never
> lost, possibly twice.

One or more times, never zero. A reliable queue holds the job until its acknowledgement — the only choice that loses
no job, and the choice that lets a job run twice.

## The three guarantees

Three delivery guarantees bound every queue design, and the spectrum is set by one decision: when does the job leave
the queue, before the work or after the acknowledgement.

- **At-most-once.** The job is removed before the work runs — `RPOP` and process. A crash mid-job loses the job: zero
  deliveries. The guarantee is that a job is delivered no more than once; the price is that it can be delivered zero
  times. Acceptable only when a dropped job is harmless.
- **At-least-once.** The job is held until the acknowledgement — leased to a worker and only settled after the work
  confirms. A crash mid-job redelivers the job: one delivery or more. The guarantee is that a job is delivered at
  least once; the price is that it can be delivered twice. This is the reliable queue.
- **Exactly-once.** One delivery and exactly one. This is what everyone wants, and it is not achievable as a
  *delivery* guarantee, because the acknowledgement itself can be lost — the third dive in this module is that
  argument. What is buildable is an exactly-once *effect*, by making the consumer idempotent on top of at-least-once
  delivery.

A reliable queue must keep the job until it is acknowledged, so it lands on at-least-once — the only point on the
spectrum that never drops a job.

## Why the lease-until-ack move yields at-least-once

R3.01 moved a job into an in-flight position under a lock instead of popping it out. EchoMQ does the same with a
lease, not a list pop: `EchoMQ.Jobs.claim/3` pops the oldest pending member, marks it active, and scores it on the
active set at `now + lease_ms` — `now` read from the server clock (`TIME`), so the deadline is the server's, not the
caller's. A healthy worker settles the job before the lease expires. When a worker crashes, it settles nothing, the
lease deadline passes, and `EchoMQ.Jobs.reap/2` finds the job still in the active set past its deadline and returns it
to pending.

The recovery path is what makes the queue reliable, and it is precisely why a job can run twice. A leased job is never
lost — that is the win. But a leased job whose deadline passed is redelivered — that is the cost. The two are the same
mechanism viewed from two angles. The recovery cannot be kept while the redelivery is removed, because removing the
recovery is exactly what loses the job.

```elixir
# EchoMQ.Jobs.@claim — lease the oldest pending job on the server clock (real, trimmed)
local popped = redis.call('ZPOPMIN', KEYS[1])        -- the oldest pending member
if #popped == 0 then return {} end
local id = popped[1]
local att = redis.call('HINCRBY', jk, 'attempts', 1) -- the fencing token, minted at the lease
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')                          -- the SERVER clock, never the caller's
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)  -- score on the active set at the lease deadline
```

## The duplicate window

The duplicate is not a rare corner; it has a precise window. A worker leases a job. It applies the effect — charges
the card, writes the row. Then it crashes *after the effect but before the acknowledgement* (`complete/5`). The effect
is done; Valkey has no record of it. The lease deadline passes. The reaper finds a job past its deadline and returns
it to pending. A second worker runs it again. The card is charged twice.

This window is irreducible. No reordering closes it: if the acknowledgement comes first, the job leaves the active set
before the work, and a crash now loses it (back to at-most-once). The acknowledgement has to come after the work,
which means there is always a moment where the work is done and the acknowledgement is not. A crash in that moment
redelivers. The window is small, but it is never zero — and over enough jobs, a never-zero probability fires.

## In EchoMQ — the worker loop that is at-least-once

`EchoMQ.Consumer` is the at-least-once loop in real code. It drains the queue through `Lanes.claim` on a default
`:lease_ms` of 30 000, runs the handler, and settles: on `:ok` it calls `EchoMQ.Jobs.complete(conn, queue, id, att)`,
on an error or a raise it calls `EchoMQ.Jobs.retry(...)`. The `att` is the `attempts` token the claim minted; it
fences the settlement, so only the current lease-holder may complete or retry the job. A worker that crashes between
the handler returning and `complete/5` running settles nothing — the lease expires, `reap/2` returns the job to
pending, and the loop redelivers it. Held-until-acknowledged plus recover-on-expired-lease is exactly at-least-once:
never lost, possibly twice.

```elixir
# EchoMQ.Consumer.drain/1 — claim, handle, settle on the fencing token (real, trimmed)
case Lanes.claim(s.conn, s.queue, s.lease_ms) do
  :empty -> :ok
  {:ok, {id, payload, att, group}} ->
    verdict = try do s.handler.(%{id: id, payload: payload, attempts: att, group: group}) rescue ... end
    case verdict do
      :ok            -> Jobs.complete(s.conn, s.queue, id, att)   # settle with the attempts token
      {:error, why}  -> Jobs.retry(s.conn, s.queue, id, att, s.retry_delay_ms, s.max_attempts, why)
    end
end
```

**The bridge.** Hold the job until the acknowledgement and recover a crashed one: at-least-once delivery — never lost,
possibly twice. The duplicate is structural, not a defect. In EchoMQ, `Jobs.claim/3` leases the job on the server
clock and `Jobs.reap/2` returns an expired lease to pending — the redelivery that makes the guarantee at-least-once.

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the original atomic move into the in-flight list, held
  until acknowledged: the heart of at-least-once.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the modern successor (Redis 6.2+) with explicit `RIGHT`/`LEFT`
  directions.
- [Valkey — ZPOPMIN](https://valkey.io/commands/zpopmin/) — the oldest-first pop the EchoMQ claim script runs over the
  mint-ordered pending set, on the engine the connector is gated against.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee overview.

### Related in this course
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the module hub.
- [R3.02.2 · Idempotent consumers](/redis-patterns/queues/at-least-once/idempotent-consumers) — the next dive: absorb
  the duplicate at the consumer.
- [R3.02.3 · Why exactly-once is a lie](/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie) — why no
  protocol closes the window.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the move-under-lock that yields
  at-least-once.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move under the in-flight list.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the leased state machine and the worker loop in depth.
