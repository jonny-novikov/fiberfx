# R4.03.2 · FIFO within a tier

> Two jobs of the same priority share the same high 32 bits of the score. The composite-score pattern breaks the tie with the low 32 bits — an arrival counter from `INCR`. Because the counter rises by one per add, the earliest-arriving job carries the smaller counter, and so the smaller score: strict FIFO within the tier. EchoMQ reaches the same order without a counter at all.

A priority tier is a band of equal high bits. Inside that band the order is whatever the low bits say. This dive shows what fills the low bits — a monotonically rising arrival counter — why it is the right tie-breaker, and the cheaper way the real EchoMQ bus gets the same within-tier order.

## The tie a single field leaves

Score a job by its priority alone and every job in a tier gets the identical score. A sorted set keeps equal-score members in lexicographic order of the member, which for an arbitrary job is its id — not its arrival order. So a priority-only score loses arrival order inside a tier: two jobs added in sequence can come out in id order, which is arbitrary unless the id itself sorts by time.

```
ZADD scored:jobs 1 "job:zeta"    # arrived first
ZADD scored:jobs 1 "job:alpha"   # arrived second
# Equal scores → ordered by member: alpha before zeta — arrival order lost
```

A queue user expects first-in-first-out within a tier. A priority-only score with arbitrary ids cannot give it.

## The counter breaks the tie

The composite-score pattern fills the low 32 bits with an **arrival counter** — the value of an atomic `INCR` on a per-queue counter key, taken inside the same operation that scores the job:

```
counter = INCR pc                    # the new value, atomically, one larger each add
score   = priority × 0x100000000 + counter
```

`INCR` returns the new value after incrementing, atomically. Each add reads a fresh counter, one larger than the last. So within a tier the first add gets the smaller counter, the second a larger one, and so on. The low bits now carry arrival order, and because they sit below the tier bits they break the tie without disturbing it.

The result is FIFO within the tier. Three jobs of priority 1, added in order, take counters `1`, `2`, `3`; their composite scores rise in the same order; the set keeps them head-first by arrival. The interactive below assigns the counters to three same-priority jobs and shows their scores ordering them FIFO — with a toggle to the priority-only score, where the three tie and fall back to member order.

## Why a counter, not a timestamp

A timestamp could order arrivals too, but it ties when two jobs arrive in the same millisecond. The `INCR` counter never ties: it rises by exactly one per add, atomically, regardless of clock resolution. Two jobs added in the same millisecond still get two different counters, so the within-tier order is total and deterministic. The counter is a logical clock for arrivals, immune to wall-clock collisions.

## In EchoMQ — the id is the counter

EchoMQ needs no arrival counter, because the **branded `JOB` id is already a logical clock.** A lane set is written at score 0 — `ZADD <lane> 0 <job-id>` — so the set orders purely by member; and the branded id is a 14-character name carrying a 63-bit snowflake (`ts | node | seq`), so its text sorts as the mint instant. Two jobs minted in the same millisecond still differ in the `seq` field, so the order is total without a side counter. `EchoMQ.Lanes` names this the **order theorem**: *"mint order is the order theorem."* The same FIFO the composite score buys with a low-bit counter, EchoMQ gets for free from the id it already carries.

Precedence between *tiers* is then the lane's weight, not a high-bit field. The consumer is **codemojex**: `Codemojex.Notifier.notify/3` enqueues each notification on `EchoMQ.Lanes.enqueue(conn, "cm.notify", chat_id, job_id, payload)` — a fair lane per chat — so within one chat's lane the notifications come out in mint order, FIFO, with no counter and no second index.

**The bridge.** A textbook sorted set breaks an equal-score tie with arbitrary member order, so the pattern adds an `INCR` arrival counter in the low 32 bits to make it FIFO. EchoMQ writes its lane sets at score 0 and lets the time-ordered branded id be the tie-break: same within-tier FIFO, no counter key, no second structure — the order theorem.

## References

### Sources

- [Redis — *INCR*](https://redis.io/commands/incr/) — the atomic increment behind the arrival counter; returns the new value, one larger each call.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — score a member; the write that places a job in its tier and arrival slot (and the score-0 write EchoMQ uses).
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — equal-score members fall back to member order, the tie the counter — or a time-ordered id — removes.
- [Valkey — *Sorted sets*](https://valkey.io/topics/sorted-sets/) — the engine's own reference for the member ordering EchoMQ's score-0 lane sets rely on.

### Related in this course

- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the module hub.
- [R4.03.1 · Packing two keys in one score](/redis-patterns/time-delay-priority/priority-scores/packing-two-keys-in-one-score) — the previous dive: the tier in the high bits, the counter in the low.
- [R4.03.3 · ZPOPMIN](/redis-patterns/time-delay-priority/priority-scores/zpopmin) — the next dive: the smallest-score pop that returns the FIFO head.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the sibling score, the run-at millisecond.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [/echomq · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the order theorem and fair lanes in depth.
