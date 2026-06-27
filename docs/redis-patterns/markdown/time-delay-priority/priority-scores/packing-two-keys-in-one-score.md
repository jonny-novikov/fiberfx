# R4.03.1 · Packing two keys in one score

> A priority queue needs two orderings at once: by tier, then by arrival within a tier. The composite-score pattern packs both into one number — `priority × 0x100000000 + counter` — putting the tier in the high 32 bits and the arrival counter in the low 32. One score, two fields, one sorted set.

The whole pattern rests on one decision: what number goes in the score. A delayed queue puts the fire-time there. A priority queue puts a **composite** there — a number whose high bits carry the priority tier and whose low bits carry the arrival order. This dive takes that number apart, then shows the different answer the real EchoMQ bus chose.

## The problem: two orderings, one score

A sorted set offers one ordering axis — the score. A priority queue wants two. Jobs in a higher-priority tier must come out before jobs in a lower tier, and within one tier the earliest-arriving job must come out first. A single number has to express both.

The move is positional. Reserve the high bits of the score for the tier and the low bits for the arrival order. Then the score compares tier-first automatically: any difference in the high bits dominates any difference in the low bits, because the high bits are worth more. Comparing two composite scores compares their tiers first and, only when the tiers are equal, their arrival counters.

## The formula

The composite score is computed positionally:

```
priority × 0x100000000  +  counter
└──── high 32 bits ────┘    └─ low 32 ─┘
        the tier             the arrival order
```

`0x100000000` is `2^32` — `4294967296`. Multiplying the priority by it shifts the tier left thirty-two binary places, leaving the low thirty-two bits at zero. The arrival counter — an atomic `INCR` on a per-queue counter key, taken at the moment the job is added — then fills those low bits. The result is one number whose top half is the tier and whose bottom half is the position within the tier.

```
ZADD scored:jobs 4294967297 "job-A"   # priority 1, counter 1 → 1·2^32 + 1
ZADD scored:jobs 8589934594 "job-B"   # priority 2, counter 2 → 2·2^32 + 2
```

One IEEE double carries the whole thing exactly. A double holds 53 bits of integer precision; a small priority shifted into the high 32 bits plus a counter in the low 32 stays well under that ceiling, so the score is exact and the ordering never rounds.

## The tier dominates the counter

Because the tier sits in the high bits, any change in the tier outweighs every value the counter can take. Two jobs in tier 1, however far apart their counters, both score below any job in tier 2 — the smallest tier-2 score is `2 × 2^32`, larger than the largest tier-1 score, which is `1 × 2^32 + (2^32 − 1)`. The high bits set the band; the low bits position within it.

The interactive below sets a priority and a counter on two sliders, computes the composite score, and shows the high-32 / low-32 split. Raise the priority by one and the score jumps by a full `2^32`, dwarfing any counter move — the demonstration that the tier dominates.

## A lower number wins

The formula makes a higher-precedence job a **smaller** number: priority 1 produces a smaller high-bit field than priority 2, so its composite score is smaller. The consume command is `ZPOPMIN`, which returns the smallest score first. The two compose into the convention a queue user sees: **a lower priority number means higher precedence.** Priority 1 beats priority 2 because 1 makes the smaller score and `ZPOPMIN` pops the smallest.

## In EchoMQ — the number moves to the lane

The real EchoMQ bus does **not** pack precedence into a job's score. `EchoMQ.Lanes` says so in the source: *"there is no numeric per-job priority (retired by design); 'served more' is a property of the identity, not the work."* EchoMQ keeps the two orderings the composite score combines, but separates them across two structures instead of two bit-ranges of one number.

The arrival order — the low bits in the textbook — is the **branded `JOB` id** itself. A lane set is written at score 0 (`ZADD <lane> 0 <job-id>`), so the set orders purely by member, and the typed, time-ordered branded id makes that member order the **mint order**. The high-bit tier becomes the lane's **weight**: `EchoMQ.Lanes.weight/4` writes a `gweight` hash (group → weight), and `EchoMQ.Lanes.wclaim/3` serves a higher-weight lane a larger share per rotation. The bit-packing trick is unnecessary because the precedence never lives in the job's number at all.

```elixir
# EchoMQ.Lanes.weight/4 (lanes.ex) — the "high bits" become a lane weight, verbatim
def weight(conn, queue, group, w) when is_integer(w) and w >= 1 do
  _ = lane_key!(queue, group)
  keys = [Keyspace.queue_key(queue, "gweight")]
  case Connector.eval(conn, @gweight, keys, [group, Integer.to_string(w)]) do
    {:ok, 1} -> :ok
    other -> other
  end
end
```

**The bridge.** A textbook composite key packs two fields into one ordering key — the tier in the high 32 bits, the arrival counter in the low 32, read with one `ZPOPMIN`. EchoMQ splits the two apart: arrival order is the branded id's mint order (a score-0 set), and the tier becomes the lane's `gweight`. The precedence moves from the bits of a number onto the identity of a lane.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add a member with its score; the write that scores a prioritized job by its composite number.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — score-then-member ordering, the axis the composite score occupies.
- [Redis — *INCR*](https://redis.io/commands/incr/) — the atomic increment that produces the arrival counter folded into the low bits.
- [Valkey — *Sorted sets*](https://valkey.io/topics/sorted-sets/) — the engine's own reference for the score-then-member order behind both encodings.

### Related in this course

- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the module hub.
- [R4.03.2 · FIFO within a tier](/redis-patterns/time-delay-priority/priority-scores/fifo-within-tier) — the next dive: the counter, and EchoMQ's score-0 mint order.
- [R4.03.3 · ZPOPMIN](/redis-patterns/time-delay-priority/priority-scores/zpopmin) — the smallest-score pop that reads this score.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the sibling score, the run-at millisecond for time.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [/echomq · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the lane ring and fair-share weight in depth.
