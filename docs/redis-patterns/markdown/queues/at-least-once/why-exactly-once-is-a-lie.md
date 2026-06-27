# Why exactly-once is a lie — the acknowledgement can be lost

> Route: `/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie` · Dive R3.02.3.
> · Grounding: the acknowledgement-gap argument, and the precise distinction in EchoMQ. The branded `JOB` id is the
> idempotency key at *enqueue* — `EchoMQ.Jobs.enqueue/4` runs `if redis.call('EXISTS', KEYS[1]) == 1 then return 0`,
> which the host reads as `{:ok, :duplicate}` — and the `attempts` token fences a settlement so only the current
> lease-holder may `complete/5` or `retry/7` (`bcs.3.md` B3.2). Producer admission and consumer idempotency are two
> moments; neither closes the acknowledgement gap, and that is the point.

The acknowledgement can be lost. A queue that picks no-loss must redeliver on a missing acknowledgement, and no
protocol closes that gap — so exactly-once delivery is unreachable.

## The acknowledgement gap

The argument is the two-generals problem in queue clothing. A worker leases a job, does the work, and sends an
acknowledgement. The queue settles the job when the acknowledgement arrives. Now ask: what happens if the
acknowledgement is lost in transit, or the worker crashes the instant after sending it.

The queue is in a position with no clean exit. It leased the job and received no acknowledgement. Two histories
produce that exact state, and from the outside the two are indistinguishable:

- **The work never ran** (a real loss), so the job must be redelivered. Or
- **The work ran and the acknowledgement was lost**, so redelivering runs the work twice.

To guarantee no loss, the queue must redeliver on a missing acknowledgement. But redelivering on a missing
acknowledgement runs the second history twice. There is no third behaviour: redeliver and risk a duplicate, or do not
redeliver and risk a loss. A confirmation of the confirmation does not help — that message can be lost too, and the
regress never bottoms out. The gap is structural, not an implementation gap.

```text
worker:  lease job -> do work -> send ACK  ──╳   (ACK lost here)
queue:   leased job, no ACK on record -> must redeliver to avoid loss -> work runs twice
         # "work never ran" and "ACK was lost" leave the queue in the same state
```

So a queue picks a side. A reliable queue picks no-loss, which forces redeliver-on-missing-ack, which is
at-least-once. The duplicate is the price of never losing a job, and it is paid at the acknowledgement gap. In EchoMQ
the gap is concrete: a worker holds a job leased on the server clock, and a lease whose deadline passes is reaped back
to pending whether the work ran or not — the reaper cannot tell the two histories apart.

## Exactly-once effect is the real target

Exactly-once *delivery* is unreachable; exactly-once *effect* is reachable, and it is what the phrase should mean.
Hold at-least-once delivery — never lose a job — and make the consumer idempotent so a redelivery changes nothing the
second time. The effect happens once even though the delivery may happen twice. Systems that advertise
"exactly-once" deliver this: at-least-once transport plus an idempotent or deduplicating consumer. The honest framing
moves the guarantee from the delivery to the effect, where it can actually hold.

This reframing is not a downgrade. It is more honest and it is more robust, because it puts the duplicate-handling
where the duplicate is observable — at the effect, keyed by the job's identity — rather than pretending a transport
layer can resolve a lost acknowledgement.

## Two moments, two disciplines

The sharpest error in this area is to point at a deduplication check and call it exactly-once. EchoMQ's
`EchoMQ.Jobs.enqueue/4` refuses a duplicate branded `JOB` id at enqueue — `if redis.call('EXISTS', KEYS[1]) == 1
then return 0` — and the host reads that `0` as `{:ok, :duplicate}`. This is real and useful, and it is
**producer-side admission**: it collapses two enqueues that carry the same id to one row, before the job is ever
claimed.

That is a different job from consumer exactly-once. Producer admission answers "two enqueues carried the same id —
keep one." Consumer idempotency answers "one job was delivered twice by the recovery path — apply its effect once."
The reaper can redeliver a single leased job whose deadline passed regardless of the admission check, because that
job already entered the queue exactly once. So the branded-id refusal does nothing to close the acknowledgement gap
at the consumer.

The settlement side has its own fence, and it is not exactly-once delivery either. `complete/5` and `retry/7` read the
job's `attempts` value and refuse a token mismatch (`EMQSTALE`), so a worker whose lease was reaped and re-claimed by
another worker cannot settle the job out from under its new owner. That fence keeps two workers from corrupting one
job's state; it does not stop the job from being *delivered* twice. Three mechanisms, three moments — admission at
enqueue, the fence at settlement, idempotency at the effect — and none of them is exactly-once delivery, because no
mechanism can be.

```text
# the three moments — none of them is exactly-once delivery
enqueue:    Jobs.enqueue  -> EXISTS KEYS[1] == 1 ? return 0 (:duplicate)   # admission: collapse same-id enqueues
settle:     Jobs.complete -> attempts token mismatch ? EMQSTALE            # fence: only the lease-holder settles
effect:     the consumer's own idempotency (a marker, or a natural no-op)  # absorb a recovery-path redelivery
```

**The bridge.** Exactly-once delivery is impossible because the acknowledgement can be lost; build an exactly-once
effect on at-least-once delivery and an idempotent consumer. In EchoMQ the branded `JOB` id collapses duplicate
*enqueues* and the `attempts` token fences a *settlement* — neither is consumer exactly-once; the exactly-once effect
is the consumer's, made by an effect-time marker or a naturally idempotent effect.

## In EchoMQ — admission and the fence are not exactly-once

The grounding is precise, and it is the discipline of this whole module. EchoMQ's branded-id refusal is real
producer-side admission, and the `attempts` token is a real settlement fence; both are useful and neither is
consumer exactly-once. The exactly-once *effect* a reliable queue ships is the consumer's, made by an effect-time
marker or a naturally idempotent effect, as the previous dive built with the codemojex scorer.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `NX` marker behind the consumer-side exactly-once effect.
- [Valkey — EXISTS](https://valkey.io/commands/exists/) — the existence check the enqueue script runs to refuse a
  duplicate branded id, on the engine the connector is gated against.
- [Salvatore Sanfilippo — RPOPLPUSH (the reliable queue pattern)](https://antirez.com/news/77) — the design note for
  the reliable-queue move, by the creator of Redis.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee framing.

### Related in this course
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the module hub.
- [R3.02.1 · At-least-once semantics](/redis-patterns/queues/at-least-once/at-least-once-semantics) — the three
  guarantees and the structural duplicate.
- [R3.02.2 · Idempotent consumers](/redis-patterns/queues/at-least-once/idempotent-consumers) — the exactly-once
  effect, built.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic `SET … NX` claim.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: admission, the fence, and the lifecycle in depth.
