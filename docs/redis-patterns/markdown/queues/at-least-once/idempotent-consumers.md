# Idempotent consumers — enroll twice, enrolled once

> Route: `/redis-patterns/queues/at-least-once/idempotent-consumers` · Dive R3.02.2 · Module R3.02 At-least-once.
> · Grounding: the consumer-side idempotency that absorbs at-least-once redelivery. A naturally idempotent effect
> (`SET key value`, set membership) needs no guard; a non-idempotent effect (`INCR`, a charge) needs a dedup marker
> claimed with `SET … NX`. Worked example: a Portal enrollment, where enrolling a student twice equals enrolled once
> because membership is a set. Distinct from EchoMQ's producer-side `EchoMQ.Keys.dedup/2`. Source root: the closing
> idempotency line of the reliable-queue source.

At-least-once delivery hands the consumer a job that may arrive more than once. The fix is not to make delivery
exactly-once — that is impossible — but to make the *effect* idempotent: running the same job twice produces the same
result as running it once. Some effects are idempotent by nature; the rest need a marker.

## Naturally idempotent effects

An effect is idempotent when applying it twice changes nothing the second time. `SET key value` is the clearest
case: it overwrites to the same value however many times it runs, so a redelivered job that sets the same value is
harmless. Set membership is another — adding a member that is already in the set is a no-op. Writing a row by a fixed
primary key with an upsert is idempotent; so is sending mail keyed by a dedup id the mail provider honours.

A naturally idempotent consumer needs no extra machinery. The redelivery runs the effect again, the effect produces
the same state, and at-least-once delivery has already become an exactly-once effect for free. The discipline is to
*recognise* which effects are naturally idempotent and lean on them — choosing a `SET` over an `INCR`, an upsert over
a blind insert — before reaching for a marker.

```
# naturally idempotent — a redelivery changes nothing
SET user:42:status "active"     # run once or run twice: the status is "active" either way
SADD course:7:roster user:42    # add a member already in the set: a no-op
```

## Non-idempotent effects need a marker

The hard cases are effects where the second run *does* change the state. `INCR counter` is the canonical one — two
deliveries increment it twice. A card charge, a row insert with a fresh id, an outbound message without a dedup id:
each accumulates on every redelivery. A non-idempotent consumer double-charges on the duplicate the previous dive
proved is structural.

The guard is a dedup marker keyed by a stable job id. Before the effect runs, claim the marker with `SET … NX` — set
only if absent. If the claim succeeds, this is the first delivery: run the effect. If the claim fails, the marker is
already set, so the effect already ran on an earlier delivery: skip it. The marker carries the exactly-once decision
that the effect itself cannot.

```
# non-idempotent effect, guarded by an NX marker keyed by a stable job id
if SET dedup:{job_id} 1 NX PX 86400000:   # claim the marker; NX = only if absent
    charge_card(job)                       # first delivery: charge once
else:
    skip()                                 # a redelivery: the marker is set, do nothing
```

The marker needs a TTL (`PX`) long enough to outlive the redelivery window but bounded so the key does not live
forever. The marker and the effect are not atomic — a crash between the `SET NX` and the effect leaves the marker set
and the effect un-run — so the guard is a best-effort reduction of duplicates for effects that cannot be made
naturally idempotent, not a hard transaction. Where the effect can be made naturally idempotent, prefer that.

## The worked example — a Portal enrollment

Enrollment is naturally idempotent, and it is the cleanest illustration. Enrolling student S in course C twice must
equal enrolling once: S is on the roster either way, and the seat is taken once. The roster is a set — set membership
is idempotent — so a redelivered enroll job that adds S to the roster a second time is a no-op. The enrollment is
recorded against a stable pair (student, course), so a second record collapses onto the first.

The one part that is not naturally idempotent is the seat count: decrementing it on every delivery would over-count
the seats taken. That is the `INCR`-shaped effect, and it takes the marker. Claim `dedup:{enroll:S:C} 1 NX`; on the
first delivery the claim succeeds and the seat count decrements once; on a redelivery the claim fails and the
decrement is skipped. The roster membership rides on its natural idempotency; the seat count rides on the marker.
Enroll twice, enrolled once: S present once, one seat taken.

Portal's enrollment is event-sourced through the `Portal.Engine` boundary; the not-already-enrolled check in
`authorize/2` runs against the folded state, so a second enroll for the same (student, course) is rejected as
`:already_enrolled` rather than recorded twice — the engine's own idempotency on the same identity. The queue-side
marker and the engine-side check are two layers of the same discipline: make the *effect* of a redelivered enroll
equal the effect of one enroll.

**The bridge.** The pattern says absorb at-least-once redelivery by making the consumer's effect idempotent — natural
idempotency where the effect allows it, an `NX` marker where it does not. In a Portal enrollment the roster
membership is a set (naturally idempotent) and the seat decrement is guarded by an `NX` marker keyed by the
(student, course) pair, so enrolling a student twice equals enrolling once.

## A note on producer-side dedup

EchoMQ carries its own deduplication key, and it is a different mechanism from the consumer marker above.
`EchoMQ.Keys.dedup/2` builds `emq:{queue}:de:{id}` and deduplicates at *enqueue* — a producer enqueuing two jobs
with the same deduplication id has the second dropped. That is **producer-side** dedup; it stops two identical jobs
from entering the queue. It does not make a single in-flight job exactly-once at the consumer, because the recovery
path can still redeliver a job that entered the queue once. The consumer marker in this dive is claimed at
*effect-time*, keyed by the job's identity, and is what absorbs that redelivery. Two keys, two moments — the third
dive separates them in full.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `NX` and `PX` options behind the effect-time idempotency
  marker.
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the queue substrate the at-least-once
  move runs over.
- [BullMQ — the queue protocol](https://bullmq.io/) — custom job ids and deduplication, the worker path EchoMQ
  ports.

### Related in this course
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the module hub.
- [R3.02.1 · At-least-once semantics](/redis-patterns/queues/at-least-once/at-least-once-semantics) — why the
  duplicate the marker absorbs is structural.
- [R3.02.3 · Why exactly-once is a lie](/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie) — producer
  dedup versus consumer idempotency.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic `SET … NX` claim under the
  marker.
- [E6 · The lifecycle](/echomq/lifecycle) — the acknowledge/finish lifecycle, in depth.
