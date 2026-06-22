# R4.03.1 · Packing two keys in one score

> A priority queue needs two orderings at once: by tier, then by arrival within a tier. EchoMQ packs both into one number — `priority × 0x100000000 + counter` — putting the tier in the high 32 bits and the arrival counter in the low 32. One score, two fields, one sorted set.

The whole pattern rests on one decision: what number goes in the score. A delayed queue puts the fire-time there. A priority queue puts a **composite** there — a number whose high bits carry the priority tier and whose low bits carry the arrival order. This dive takes that number apart.

## The problem: two orderings, one score

A sorted set offers one ordering axis — the score. A priority queue wants two. Jobs in a higher-priority tier must come out before jobs in a lower tier, and within one tier the earliest-arriving job must come out first. A single number has to express both.

The move is positional. Reserve the high bits of the score for the tier and the low bits for the arrival order. Then the score compares tier-first automatically: any difference in the high bits dominates any difference in the low bits, because the high bits are worth more. Comparing two composite scores compares their tiers first and, only when the tiers are equal, their arrival counters.

## The formula

EchoMQ computes the score with `getPriorityScore`, an included Lua function whose canonical home is `addPrioritizedJob-9.lua`:

```lua
-- getPriorityScore.lua (included by addPrioritizedJob-9) — real
local function getPriorityScore(priority, priorityCounterKey)
  local prioCounter = rcall("INCR", priorityCounterKey)
  return priority * 0x100000000 + prioCounter % 0x100000000
end
```

`0x100000000` is `2^32` — `4294967296`. Multiplying the priority by it shifts the tier left thirty-two binary places, leaving the low thirty-two bits at zero. The arrival counter, taken `% 2^32`, then fills those low bits. The result is one number whose top half is the tier and whose bottom half is the position within the tier.

```
priority × 0x100000000  +  (INCR pc) % 0x100000000
└──── high 32 bits ────┘    └──── low 32 bits ────┘
        the tier                the arrival counter
```

One IEEE double carries the whole thing exactly. A double holds 53 bits of integer precision; a small priority shifted into the high 32 bits plus a counter in the low 32 stays well under that ceiling, so the score is exact and the ordering never rounds.

## The tier dominates the counter

Because the tier sits in the high bits, any change in the tier outweighs every value the counter can take. Two jobs in tier 1, however far apart their counters, both score below any job in tier 2 — the smallest tier-2 score is `2 × 2^32`, larger than the largest tier-1 score, which is `1 × 2^32 + (2^32 − 1)`. The high bits set the band; the low bits position within it.

The interactive below sets a priority and a counter on two sliders, computes the composite score, and shows the high-32 / low-32 split. Raise the priority by one and the score jumps by a full `2^32`, dwarfing any counter move — the demonstration that the tier dominates.

## A lower number wins

The formula makes a higher-precedence job a **smaller** number: priority 1 produces a smaller high-bit field than priority 2, so its composite score is smaller. The consume command is `ZPOPMIN`, which returns the smallest score first. The two compose into the convention a queue user sees: **a lower priority number means higher precedence.** Priority 1 beats priority 2 because 1 makes the smaller score and `ZPOPMIN` pops the smallest.

## In EchoMQ

The prioritized set is `EchoMQ.Keys.prioritized/1` → `emq:{queue}:prioritized`. The arrival-counter key is `EchoMQ.Keys.pc/1` → `emq:{queue}:pc`. The public entry `EchoMQ.Scripts.add_prioritized_job/4` runs `addPrioritizedJob-9.lua`, passing `Keys.pc(ctx)` as `KEYS[9]`; the script calls `getPriorityScore` and then `rcall("ZADD", prioritizedKey, score, jobId)`. The same `getPriorityScore` is reused verbatim across the priority-aware scripts, so every path that scores a prioritized job packs the tier and counter the same way.

**The bridge.** A textbook composite key packs two fields into one ordering key — the source packs them into the member and reads with `ZRANGEBYLEX`. EchoMQ packs them into the **score**: the tier in the high 32 bits, the arrival counter in the low 32, so one numeric score orders by tier first and arrival second, read with one `ZPOPMIN`.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add a member with its score; the write that scores a prioritized job by its composite number.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — score-then-member ordering, the axis the composite score occupies.
- [Redis — *INCR*](https://redis.io/commands/incr/) — the atomic increment that produces the arrival counter folded into the low bits.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the prioritized-jobs protocol EchoMQ ports, where the Lua scripts are the protocol.

### Related in this course

- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the module hub.
- [R4.03.2 · FIFO within a tier](/redis-patterns/time-delay-priority/priority-scores/fifo-within-tier) — the next dive: the counter that breaks the within-tier tie.
- [R4.03.3 · ZPOPMIN](/redis-patterns/time-delay-priority/priority-scores/zpopmin) — the smallest-score pop that reads this score.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the sibling score, shifted twelve bits for time.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: intra-group priority in depth.
