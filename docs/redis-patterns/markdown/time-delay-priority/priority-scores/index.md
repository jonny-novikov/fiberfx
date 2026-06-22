# R4.03 · Priority with composite scores

> A sorted set orders by score, then lexicographically within an equal score. Encode more than one field into that ordering key and one sorted set becomes a multi-level index — bucket by the high-order field, order by the low. A priority queue is the sharpest case: pack the priority tier and the arrival order into a single score so one pop returns the right job.

This module is grounded in the score-based half of the lexicographic-sorted-set source — its *Composite Keys for Multi-Field Queries*, *Combining with Score-Based Ordering*, and the *Numeric rankings (priority queues)* line of *When to Use Regular Score-Based Sorting*. The source's other half packs fields into the **member** and reads them with `ZRANGEBYLEX`; EchoMQ packs them into the **score** and reads them with `ZPOPMIN`. Same idea — one sorted set, a composite ordering key — two encodings.

## How a sorted set orders (score, then member)

A Redis sorted set keeps its members in order by a numeric **score**. Read it low-to-high and the smallest score is at the head. When two members carry the same score, the set falls back to lexicographic order of the member to break the tie. The ordering is therefore two-level by construction: the score first, the member second.

```
ZADD scores 100 "alice" 200 "bob" 150 "charlie"
ZRANGE scores 0 -1
# Returns: alice, charlie, bob  — sorted by score
```

The score is the whole ordering axis. Choose what number goes in it and the set's order becomes whatever that number means.

## Composite keys: packing two fields into one ordering key

The source's composite-key pattern encodes several fields into one ordering key so a single sorted set answers a hierarchical query. In its lexicographic form the fields go into the member string:

```
ZADD events 0 "user:100:1706648400:login"
ZADD events 0 "user:100:1706648500:click"
ZRANGEBYLEX events [user:100: (user:100:\xff
# All user:100 events, ordered by the next field — the timestamp
```

The *Combining with Score-Based Ordering* section makes the second encoding explicit: members first sort by score, then lexicographically within an equal score, so the score can carry the high-order field while the member carries the low.

```
ZADD hybrid 1 "a:first" 1 "a:second" 2 "b:first" 2 "b:second"
ZRANGE hybrid 0 -1
# Returns: a:first, a:second, b:first, b:second  — bucket by score, order within
```

Bucketing falls out: group items by score (a category, a priority tier) and order within each bucket. A priority queue is the same composite key, encoded entirely in the score — both the tier and the position within it.

## The numeric composite score (the priority queue)

A priority queue needs two things from one ordering: jobs in a higher-priority tier come out first, and within a tier the earliest-arriving job comes out first. EchoMQ packs both into one numeric score.

The score is `priority × 0x100000000 + counter`. `0x100000000` is `2^32`, so multiplying the priority by it shifts the tier into the **high 32 bits**; the arrival counter sits in the **low 32 bits**. One IEEE double carries both fields exactly — a double holds 53 bits of integer precision, ample for small priorities and counters.

The counter is the value of `INCR pc` — an atomic increment of the priority-counter key, taken at the moment the job is added. Every prioritized add reads a fresh, monotonically rising counter, so two jobs in the same tier get two different low-bit fields: the earlier add gets the smaller counter.

A **lower priority number means higher precedence.** Priority 1 produces a smaller high-bit field than priority 2, so its composite score is smaller, and the set keeps it nearer the head. The convention is a direct consequence of the formula plus the consume command below.

## FIFO within a tier

Two jobs of the same priority share the same high 32 bits. The tie is broken by the low 32 bits — the arrival counter. Because `INCR pc` rises by one per add, the first job to arrive in a tier carries the smaller counter and so the smaller composite score. The set orders same-tier jobs by arrival, head first: strict FIFO within the tier, with no second structure and no scan.

Without the counter, a score of `priority` alone would tie every job in a tier, and the set would fall back to member order — the job id — which is not arrival order. The counter is what breaks the tie deterministically and in the order jobs arrived.

## Consuming with ZPOPMIN

A worker takes the next job with `ZPOPMIN` — pop the member with the **smallest** score. The smallest score is the highest-priority tier (the smallest priority number) and, within that tier, the earliest arrival (the smallest counter). One command returns the right job and removes it atomically.

```
ZPOPMIN emq:{queue}:prioritized
# Returns the smallest-score member: highest-priority tier, earliest arrival — and removes it
```

In EchoMQ the popped job id is then pushed onto the active list. `ZPOPMIN` is the reason a lower priority number wins: the formula makes a higher-precedence job a smaller number, and `ZPOPMIN` always returns the smallest first.

## When a composite score beats two structures, when lexicographic instead

A single composite score earns its place when the ordering is fully numeric and one pop must return the right job: a priority queue, a numeric ranking, any case where the high-order field and the tie-breaker are both numbers. One sorted set then replaces a per-tier structure plus a separate FIFO, and the consume is one `ZPOPMIN`.

Reach for the **member-packed** lexicographic key instead when the fields are strings and the read is a prefix or range query — autocomplete, hierarchical composite keys, time-series with string ids — where `ZRANGEBYLEX` over the member is the natural read. Score-packing and member-packing are the same composite-key idea; the choice is whether the read is a numeric pop or a lexicographic range.

| Pack into the score (numeric) | Pack into the member (lexicographic) |
| --- | --- |
| Priority queues, numeric rankings | Autocomplete, prefix search |
| Read with `ZPOPMIN` / `ZRANGEBYSCORE` | Read with `ZRANGEBYLEX` |
| Tier in high bits, tie-breaker in low bits | Fields delimited in one string, zero-padded |

## The three dives

- **R4.03.1 · Packing two keys in one score** — the core move: `priority × 0x100000000 + counter` puts the tier in the high 32 bits and the arrival counter in the low 32; changing the tier dominates the counter.
- **R4.03.2 · FIFO within a tier** — two jobs of the same priority order by the `INCR pc` arrival counter; the counter breaks the tie deterministically, in arrival order.
- **R4.03.3 · ZPOPMIN** — consumption: `ZPOPMIN` pops the smallest score (highest tier, earliest arrival), then `LPUSH` to the active list; why a lower priority number wins.

## Applied in EchoMQ

The prioritized set is `EchoMQ.Keys.prioritized/1` → `emq:{queue}:prioritized`. The composite score is computed by `getPriorityScore`, an included Lua function whose canonical home is `addPrioritizedJob-9.lua`: `local prioCounter = rcall("INCR", priorityCounterKey)` then `return priority * 0x100000000 + prioCounter % 0x100000000`. The arrival-counter key is `EchoMQ.Keys.pc/1` → `emq:{queue}:pc`, passed as `KEYS[9]` via `Keys.pc(ctx)` in `EchoMQ.Scripts.add_prioritized_job/4` (the public entry that runs `addPrioritizedJob`). The add is `rcall("ZADD", prioritizedKey, score, jobId)`. The consume is `moveToActive-11.lua`: `local prioritizedJob = rcall("ZPOPMIN", priorityKey)` then `rcall("LPUSH", activeKey, prioritizedJob[1])`. Re-prioritizing a queued job is `EchoMQ.Scripts.change_priority`, which re-scores it with a fresh `getPriorityScore`.

**The bridge.** A textbook sorted set buckets by score and orders within the bucket lexicographically by member. EchoMQ packs **both** the priority tier and the arrival order into one numeric score — `priority × 0x100000000 + (INCR pc)` — so a single `ZPOPMIN` returns strict priority, then FIFO within the tier, with no second structure and no scan.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — score-then-member ordering, the basis of the composite score.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — score a member by its composite priority score; the write that adds a prioritized job.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the smallest score: highest-priority tier, earliest arrival, removed atomically.
- [Redis — *INCR*](https://redis.io/commands/incr/) — the atomic arrival counter that breaks the within-tier tie.
- [Redis — *ZRANGEBYLEX*](https://redis.io/commands/zrangebylex/) — the source's other half: member-packed lexicographic ordering, the contrast to score-packing.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the prioritized-jobs protocol EchoMQ ports, where the Lua scripts are the protocol.

### Related in this course

- [R4.03.1 · Packing two keys in one score](/redis-patterns/time-delay-priority/priority-scores/packing-two-keys-in-one-score) — the tier in the high 32 bits, the counter in the low.
- [R4.03.2 · FIFO within a tier](/redis-patterns/time-delay-priority/priority-scores/fifo-within-tier) — the `INCR pc` counter that breaks the tie in arrival order.
- [R4.03.3 · ZPOPMIN](/redis-patterns/time-delay-priority/priority-scores/zpopmin) — the smallest-score pop, and why a lower priority number wins.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the orientation dive that names `getPriorityScore`.
- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the sibling sorted set scored by fire-time.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: intra-group priority and the control plane.
