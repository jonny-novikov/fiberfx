# R4.03 · Priority with composite scores

> A sorted set orders by score, then lexicographically within an equal score. Encode more than one field into that ordering key and one sorted set becomes a multi-level index — bucket by the high-order field, order by the low. A priority queue is the sharpest case: pack the priority tier and the arrival order into a single score so one pop returns the right job.

This module is grounded in the score-based half of the lexicographic-sorted-set source — its *Composite Keys for Multi-Field Queries*, *Combining with Score-Based Ordering*, and the *Numeric rankings (priority queues)* line of *When to Use Regular Score-Based Sorting*. The source's other half packs fields into the **member** and reads them with `ZRANGEBYLEX`; the composite-score form packs them into the **score** and reads them with `ZPOPMIN`. Same idea — one sorted set, a composite ordering key — two encodings.

The pattern is real Redis, and the page teaches it in full. The application turn is the interesting part: the real EchoMQ bus made a **different** design choice for precedence, and the contrast is the lesson. Where the textbook packs precedence *into* the job's score, EchoMQ moves precedence *out* onto the lane — the identity, not the work. The `## Applied in EchoMQ` section grounds that choice in the real Elixir.

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

A priority queue needs two things from one ordering: jobs in a higher-priority tier come out first, and within a tier the earliest-arriving job comes out first. The composite-score pattern packs both into one numeric score.

The score is `priority × 0x100000000 + counter`. `0x100000000` is `2^32`, so multiplying the priority by it shifts the tier into the **high 32 bits**; the arrival counter sits in the **low 32 bits**. One IEEE double carries both fields exactly — a double holds 53 bits of integer precision, ample for small priorities and counters.

The counter comes from an atomic `INCR` on a per-queue counter key, taken at the moment the job is added. Every add reads a fresh, monotonically rising counter, so two jobs in the same tier get two different low-bit fields: the earlier add gets the smaller counter.

A **lower priority number means higher precedence.** Priority 1 produces a smaller high-bit field than priority 2, so its composite score is smaller, and the set keeps it nearer the head. The convention is a direct consequence of the formula plus the consume command below.

## FIFO within a tier

Two jobs of the same priority share the same high 32 bits. The tie is broken by the low 32 bits — the arrival counter. Because the counter rises by one per add, the first job to arrive in a tier carries the smaller counter and so the smaller composite score. The set orders same-tier jobs by arrival, head first: strict FIFO within the tier, with no second structure and no scan.

Without the counter, a score of `priority` alone would tie every job in a tier, and the set would fall back to member order — the job id — which is not arrival order unless the id itself is time-ordered. The counter is the deterministic tie-break, in the order jobs arrived.

## Consuming with ZPOPMIN

A worker takes the next job with `ZPOPMIN` — pop the member with the **smallest** score. The smallest score is the highest-priority tier (the smallest priority number) and, within that tier, the earliest arrival (the smallest counter). One command returns the right job and removes it atomically.

```
ZPOPMIN scored:jobs
# Returns the smallest-score member: highest-priority tier, earliest arrival — and removes it
```

The popped job id then moves on to be worked. `ZPOPMIN` is the reason a lower priority number wins: the formula makes a higher-precedence job a smaller number, and `ZPOPMIN` always returns the smallest first.

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
- **R4.03.2 · FIFO within a tier** — two jobs of the same priority order by the arrival counter; the counter breaks the tie deterministically, in arrival order.
- **R4.03.3 · ZPOPMIN** — consumption: `ZPOPMIN` pops the smallest score (highest tier, earliest arrival); why a lower priority number wins, and how EchoMQ's lane rotation reaches the same head without a packed score.

## Applied in EchoMQ — precedence on the lane, not the score

Here the applied turn differs from the textbook, and the difference is the point. The real EchoMQ bus (`echo/apps/echo_mq`) carries **no numeric per-job priority** — it is *retired by design*. `EchoMQ.Lanes` states it twice in the source: *"there is no numeric per-job priority (retired by design); 'served more' is a property of the identity, not the work,"* and *"there is no numeric per-job priority — 'matters more now' is a change of lane, mint order is the order theorem."*

So EchoMQ does not pack a precedence field into a job's score. Its pending and lane sets are written at **score 0** — `ZADD <set> 0 <job-id>` — and the branded `JOB` id (typed, time-ordered) is the whole ordering: byte order is mint order, so a lane serves first-in-first-out by id with no second index. That is the **order theorem**: the same arrival-ordering the composite score reaches with a counter, EchoMQ reaches for free because the id already sorts as the mint instant.

Precedence between *identities* is the per-lane **weight**. `EchoMQ.Lanes.weight/4` writes a `gweight` hash (group → weight); `EchoMQ.Lanes.wclaim/3` runs the weighted rotation: one `LMOVE` rotates the ring of serviceable lanes exactly once, then serves that lane a fair **share** of K heads in one atomic turn, where `K = min(weight, lane depth, glimit headroom)`. A higher-weight lane is served proportionally more over a window, never all of it — fairness is constructed by the rotation, not encoded in a job's number.

```elixir
# EchoMQ.Lanes.weight/4 — set a lane's fair-share weight (the gweight hash, group -> weight)
def weight(conn, queue, group, w) when is_integer(w) and w >= 1 do
  _ = lane_key!(queue, group)
  keys = [Keyspace.queue_key(queue, "gweight")]
  case Connector.eval(conn, @gweight, keys, [group, Integer.to_string(w)]) do
    {:ok, 1} -> :ok
    other -> other
  end
end
```

The @gwclaim Lua reads that weight and serves the share:

```lua
-- @gwclaim (lanes.ex) — rotate the ring once, then serve K = min(weight, depth, headroom) heads
local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')   -- rotate the ring of serviceable lanes
local lane = ARGV[1] .. 'g:' .. g .. ':pending'
local w = tonumber(redis.call('HGET', ARGV[1] .. 'gweight', g) or '1')  -- the lane's throughput share
if w < 1 then w = 1 end
local k = w
if depth < k then k = depth end                                    -- never over-pop the lane
-- ... clamp k to the glimit headroom, then ZPOPMIN k heads of THIS lane on one server-clock lease
```

The consumer that rides this is **codemojex**, the Telegram emoji-guessing game on the same stack. `Codemojex.Notifier.notify/3` enqueues every notification on `EchoMQ.Lanes.enqueue(conn, "cm.notify", chat_id, job_id, payload)` — *a fair lane keyed by chat id* — so one chat's burst cannot starve others, and `Codemojex.NotificationWorker` drains the lanes by the rotation. The precedence is the **chat's lane**, not a score on the message.

**The bridge.** A textbook priority queue packs the tier and the arrival order into one score so a single `ZPOPMIN` returns the right job. EchoMQ moves the precedence off the job entirely: arrival order is the branded id's mint order (score-0 sets, the order theorem), and tier precedence is the **lane's weight** served by `wclaim/3` over a rotating ring. Same goal — the right work served first, fairly — reached by putting the precedence on the identity instead of in the number.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — score-then-member ordering, the basis of the composite score.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — score a member by its composite priority score; the write that adds a prioritized job.
- [Valkey — *ZPOPMIN*](https://valkey.io/commands/zpopmin/) — pop the smallest score: highest-priority tier, earliest arrival, removed atomically; the engine EchoMQ runs on.
- [Redis — *INCR*](https://redis.io/commands/incr/) — the atomic arrival counter that breaks the within-tier tie in the composite-score form.
- [Redis — *ZRANGEBYLEX*](https://redis.io/commands/zrangebylex/) — the source's other half: member-packed lexicographic ordering, the contrast to score-packing.
- [Valkey — *Sorted sets*](https://valkey.io/topics/sorted-sets/) — the engine's own reference for the score-then-member order EchoMQ's score-0 lane sets depend on.

### Related in this course

- [R4.03.1 · Packing two keys in one score](/redis-patterns/time-delay-priority/priority-scores/packing-two-keys-in-one-score) — the tier in the high 32 bits, the counter in the low.
- [R4.03.2 · FIFO within a tier](/redis-patterns/time-delay-priority/priority-scores/fifo-within-tier) — the arrival counter, and EchoMQ's score-0 mint-order alternative.
- [R4.03.3 · ZPOPMIN](/redis-patterns/time-delay-priority/priority-scores/zpopmin) — the smallest-score pop, and the lane rotation that reaches the same head.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the orientation dive on the sorted set as a meaning-bearing index.
- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the sibling sorted set scored by fire-time.
- [/echomq · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the lane ring, fair-share weight, and the order theorem in depth.
