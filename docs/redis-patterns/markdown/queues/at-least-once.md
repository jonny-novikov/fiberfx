# At-least-once — delivered more than once, never zero

> Route: `/redis-patterns/queues/at-least-once` · Module R3.02 · Chapter R3 Reliable Queues.
> · Grounding: the real EchoMQ worker path in `echo/apps/echo_mq`. A job is a branded `JOB` entity with a leased
> state machine — `EchoMQ.Jobs.enqueue/4` writes a waiting job, `claim/3` leases it on the server clock, `complete/5`
> and `retry/7` settle it, and a job that exhausts its tries fails. The lease is what makes the bus safe: a worker
> that dies holding a job loses the lease, and the job is reclaimable rather than lost (`bcs.3.md` B3.2). The branded
> `JOB` id is the idempotency key — `enqueue` refuses a duplicate id (`EXISTS KEYS[1] == 1 → :duplicate`), gated at
> `EchoMQ.Keyspace.job_key/2`; the worked consumer is **codemojex** (`Codemojex.ScoreWorker`).

Guarantee at-least-once message delivery using LMOVE to atomically transfer messages to a processing list, enabling
recovery if consumers crash before completing work.

R3.01 built the move that loses no job: the worker moves a job *into* an in-flight list with `LMOVE` (or the older
`RPOPLPUSH`), so a crash leaves the job parked and recoverable rather than gone. That move makes redelivery
*possible* — and that is the point. This module reads the consequence of that choice. A reliable queue does not
deliver a job once and exactly once; it delivers it **one or more times, never zero**. The cost of never losing a
job is that a job can run twice, and the responsibility for absorbing that lands on the consumer. Make the consumer
idempotent — running the same job twice must produce the same effect as running it once — and at-least-once delivery
yields an exactly-once *effect*.

## Recovery from Failures

A separate monitor process — a reaper — periodically scans the processing list for stalled messages. For each job
that has sat there longer than a timeout, it treats the worker as dead and moves the job back to the main queue. R3.01
grounded this in EchoMQ's stalled sweep. The recovery path is what makes the queue reliable, and it is also what
makes redelivery inevitable.

The window is precise. A worker takes a job into the in-flight list under a lease, applies the effect — charges a
card, writes a row, sends a mail — and then crashes *before* it can acknowledge the job. The effect already happened;
the acknowledgement did not. The reaper finds a job whose lease expired, returns it to the main queue, and a second
worker runs it again. The effect runs twice.

> **This guarantees "at-least-once" delivery — messages may be processed multiple times but are never lost.**

That sentence from the source is the whole bargain. The dependency chain is exact: R3.01's in-flight move makes
redelivery *possible* (that is the design); a finish-then-crash before the acknowledgement makes it *inevitable*;
therefore the consumer must be idempotent. There is no fourth option that removes the duplicate without
reintroducing the loss.

## Delivery Guarantees

This pattern provides **at-least-once** delivery, which is two properties stated together:

- **Messages are never lost** — a job always exists in some place (the pending set, the active set), so no crash
  drops it.
- **Messages may be processed multiple times** — a worker that crashes after the effect but before the
  acknowledgement leaves the job leased, and recovery runs it again.

The three delivery guarantees that bound the design space are worth naming side by side. **At-most-once** removes the
job before the work, so a crash loses it — zero or one delivery, never a duplicate, but a job can vanish.
**At-least-once** keeps the job until the acknowledgement, so a crash redelivers it — one or more deliveries, never
zero, but a job can repeat. **Exactly-once** would be one delivery and exactly one — and it is not achievable as a
*delivery* guarantee, because the acknowledgement itself can be lost, which is the subject of the third dive.

A reliable queue must keep the job until it is acknowledged, so it is at-least-once. That is not a defect of the
implementation; it is the only point on the spectrum that loses no job.

> **For exactly-once semantics, make message handlers idempotent — processing the same message twice should produce
> the same result as processing it once.**

This is where the work moves to the consumer. Idempotency is the property that closes the gap: it converts
at-least-once *delivery* into an exactly-once *effect*. Some effects are naturally idempotent — a `SET key value`
overwrites to the same value however many times it runs. Others are not — an `INCR`, a charge, a row insert — and
those need a guard: a marker keyed by a stable id, so the second delivery finds the marker and skips.

## The pattern, applied — the branded JOB id is the idempotency key

EchoMQ's idempotency starts at the identity, not at a side key. A job is a branded `JOB` entity, and its identity is
the key: `EchoMQ.Jobs.enqueue/4` runs one idempotent Lua script that admits by kind, **refuses a duplicate id**, and
writes the row and the pending entry atomically. The duplicate refusal is a single line — `if redis.call('EXISTS',
KEYS[1]) == 1 then return 0 end` — and the host maps that `0` to `{:ok, :duplicate}`. Two enqueues that carry the
same branded `JOB` id collapse to one row, because the id *is* the key, gated at `EchoMQ.Keyspace.job_key/2`.

```elixir
# EchoMQ.Jobs.enqueue/4 — one idempotent script; the branded JOB id is the key (real)
@enqueue Script.new(:enqueue, """
         if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
           return redis.error_reply('EMQKIND job id must be JOB-namespaced')
         end
         if redis.call('EXISTS', KEYS[1]) == 1 then
           return 0                                  -- duplicate id: refuse, the host reads {:ok, :duplicate}
         end
         redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
         redis.call('ZADD', KEYS[2], 0, ARGV[1])
         return 1
         """)
```

That refusal is **producer-side admission**: it stops two enqueues of the *same* id from both creating work. It is
**not** consumer exactly-once, because the recovery path can still redeliver a job that entered the queue once — a
worker that leases a job, applies the effect, and crashes before the acknowledgement loses its lease, and the reaper
returns the job to pending for another worker. The consumer absorbs that redelivery by being idempotent: the worker
loop hands the handler the job and, on `:ok`, calls `EchoMQ.Jobs.complete/5` with the `attempts` token; the token is
the per-claim fence, so only the current lease-holder may settle the job (`bcs.3.md` B3.2). Producer admission and
consumer idempotency are two disciplines protecting two moments — the enqueue and the effect.

**The bridge.** The pattern says a reliable queue is at-least-once and the consumer must be idempotent. In EchoMQ the
branded `JOB` id refuses a duplicate *enqueue* (`Jobs.enqueue` returns `:duplicate`), while the consumer absorbs a
duplicate *delivery* the recovery path cannot avoid — `Codemojex.ScoreWorker` scores a guess and answers `:ok` for an
unknown game (a drop, never a retry loop), the at-least-once consumer in the live app.

## The persistence floor — a job that exhausts its tries

A job that fails past its `max_attempts` does not vanish; `retry/7` moves it to the morgue (`dead`) and the row
survives. Where a queue keeps deep history — a stream of completed work trimmed into the archive — that history lands
on the durable floor: `EchoStore.StreamArchive` folds trimmed `EchoMQ.Stream` segments into the native Graft engine
(CubDB) and on to Tigris, deep history without resident memory (`bcs.5.md` B5.3). The durability dial — hold nothing,
a bounded window, or commit-per-record off-box — is the subject of the persistence course.

## The three dives

- **At-least-once semantics** — the three delivery guarantees and why the lease-until-ack move yields at-least-once;
  the duplicate-on-crash-after-process-before-ack window. Messages are never lost; they may run more than once.
- **Idempotent consumers** — make the handler idempotent: a naturally idempotent effect versus a marker for a
  non-idempotent counter. Worked example: a codemojex guess, where scoring the same `JOB` twice writes one `GES`.
- **Why exactly-once is a lie** — the acknowledgement-gap argument: exactly-once *delivery* is impossible because the
  acknowledgement can be lost; exactly-once *effect* via idempotency is what you build. The branded-id refusal is
  producer-side admission, not consumer exactly-once.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `NX` option behind an effect-time idempotency marker (`SET …
  NX`): claim the key only if absent.
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the at-least-once move into the in-flight list that
  makes redelivery possible.
- [Valkey — EXISTS](https://valkey.io/commands/exists/) — the existence check the enqueue script runs to refuse a
  duplicate branded id, on the engine the connector is gated against.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee overview.

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [R3.02.1 · At-least-once semantics](/redis-patterns/queues/at-least-once/at-least-once-semantics) — the three
  guarantees and the duplicate window.
- [R3.02.2 · Idempotent consumers](/redis-patterns/queues/at-least-once/idempotent-consumers) — the marker and the
  naturally idempotent effect.
- [R3.02.3 · Why exactly-once is a lie](/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie) — the
  acknowledgement-gap argument.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move the lease-under-lock rests
  on.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the leased state machine, lanes, the schedule set.
- [/echo-persistence](/echo-persistence) — the durability floor a dead-lettered job and the stream archive reach.
