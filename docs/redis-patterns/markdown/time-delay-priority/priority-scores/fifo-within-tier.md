# R4.03.2 · FIFO within a tier

> Two jobs of the same priority share the same high 32 bits of the score. The tie is broken by the low 32 bits — the arrival counter from `INCR pc`. Because the counter rises by one per add, the earliest-arriving job carries the smaller counter, and so the smaller score: strict FIFO within the tier.

A priority tier is a band of equal high bits. Inside that band the order is whatever the low bits say. This dive shows what fills the low bits — a monotonically rising arrival counter — and why it is the right tie-breaker.

## The tie a single field leaves

Score a job by its priority alone and every job in a tier gets the identical score. A sorted set keeps equal-score members in lexicographic order of the member, which for a job is its id — not its arrival order. So a priority-only score loses arrival order inside a tier: two jobs added in sequence can come out in id order, which is arbitrary.

```
ZADD prioritized 1 "job:zeta"    # arrived first
ZADD prioritized 1 "job:alpha"   # arrived second
# Equal scores → ordered by member: alpha before zeta — arrival order lost
```

A queue user expects first-in-first-out within a tier. A priority-only score cannot give it.

## The counter breaks the tie

EchoMQ fills the low 32 bits with an **arrival counter** — the value of `INCR pc`, taken inside the same script that scores the job:

```lua
-- inside getPriorityScore (included by addPrioritizedJob-9) — real
local prioCounter = rcall("INCR", priorityCounterKey)
return priority * 0x100000000 + prioCounter % 0x100000000
```

`INCR` returns the new value after incrementing, atomically. Each prioritized add reads a fresh counter, one larger than the last. So within a tier the first add gets the smaller counter, the second a larger one, and so on. The low bits now carry arrival order, and because they sit below the tier bits they break the tie without disturbing it.

The result is FIFO within the tier. Three jobs of priority 1, added in order, take counters `1`, `2`, `3`; their composite scores rise in the same order; the set keeps them head-first by arrival. The interactive below assigns the `INCR pc` counters to three same-priority jobs and shows their scores ordering them FIFO — with a toggle to the priority-only score, where the three tie and fall back to member order.

## Why the counter, not the timestamp

A timestamp could order arrivals too, but it ties when two jobs arrive in the same millisecond — the same problem the delayed score solves with a low-bit shift. The `INCR pc` counter never ties: it rises by exactly one per add, atomically, regardless of clock resolution. Two jobs added in the same millisecond still get two different counters, so the within-tier order is total and deterministic. The counter is a logical clock for arrivals, immune to wall-clock collisions.

## In EchoMQ

The counter key is `EchoMQ.Keys.pc/1` → `emq:{queue}:pc`, documented as the priority counter. It is passed as `KEYS[9]` via `Keys.pc(ctx)` in `EchoMQ.Scripts.add_prioritized_job/4`, which runs `addPrioritizedJob-9.lua`. Inside, `getPriorityScore` reads `rcall("INCR", priorityCounterKey)` and folds it into the low 32 bits of the score, then `rcall("ZADD", prioritizedKey, score, jobId)` adds the job. Every prioritized add takes its arrival number from the same counter, so the whole prioritized set shares one consistent arrival order.

**The bridge.** A textbook sorted set breaks an equal-score tie with lexicographic member order — arbitrary for a job id. EchoMQ breaks the within-tier tie with the `INCR pc` arrival counter packed into the low 32 bits, so same-priority jobs come out in the order they arrived: strict FIFO inside the tier, with no second structure.

## References

### Sources

- [Redis — *INCR*](https://redis.io/commands/incr/) — the atomic increment behind the arrival counter; returns the new value, one larger each call.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — score a member by its composite score; the write that places a job in its tier and arrival slot.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — equal-score members fall back to member order, the tie the counter removes.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the prioritized-jobs protocol EchoMQ ports, where the Lua scripts are the protocol.

### Related in this course

- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the module hub.
- [R4.03.1 · Packing two keys in one score](/redis-patterns/time-delay-priority/priority-scores/packing-two-keys-in-one-score) — the previous dive: the tier in the high bits, the counter in the low.
- [R4.03.3 · ZPOPMIN](/redis-patterns/time-delay-priority/priority-scores/zpopmin) — the next dive: the smallest-score pop that returns the FIFO head.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the low-bit shift that orders within a millisecond.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: intra-group priority in depth.
