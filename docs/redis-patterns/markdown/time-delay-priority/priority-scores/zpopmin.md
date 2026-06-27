# R4.03.3 · ZPOPMIN

> A worker takes the next prioritized job with `ZPOPMIN` — pop the member with the smallest score. The smallest composite score is the highest-priority tier and, within it, the earliest arrival. One command returns the right job and removes it atomically. EchoMQ reaches the same head through a rotating ring of lanes, served by weight.

The composite score packs the tier and the arrival order so that "the right next job" is always the smallest number. This dive walks the consume side: the single pop that reads that number, why a lower priority value comes out first, and the lane rotation that serves the same head without a packed score.

## The smallest score is the right job

The composite score is `priority × 0x100000000 + counter`. A smaller priority number makes a smaller high-bit field; within a tier a smaller arrival counter makes a smaller low-bit field. So the smallest score in the set is, by construction, the highest-priority tier and the earliest arrival within it — exactly the job a priority queue should serve next.

`ZPOPMIN` removes and returns the member with the smallest score:

```
ZPOPMIN scored:jobs
# Returns: [ "job-A", "4294967297" ]  — the smallest-score member, removed
```

The pop is atomic: read-and-remove in one step, so two workers polling the same set never claim the same job. The job leaves the set the instant it is chosen.

## Why a lower priority number wins

The convention that surprises newcomers — priority 1 outranks priority 5 — is a direct consequence of two facts composed. The formula makes a higher-precedence tier a *smaller* score: `1 × 2^32` is smaller than `5 × 2^32`. And `ZPOPMIN` always returns the *smallest* score first. Compose them and the lowest priority number is served first. Nothing reverses or negates the value; the precedence is encoded as "smaller is sooner" and read by "pop the smallest."

The interactive below steps `ZPOPMIN` over a fixed set of prioritized jobs. Each step removes the current smallest score and names the popped job, its tier, and its arrival counter — showing the order march down the tiers and, within each tier, forward through arrivals.

## In EchoMQ — the same head, by a rotating ring

EchoMQ serves the highest-precedence work next, but not by popping the smallest composite score from one set. It has no per-job priority score to pop. Instead `EchoMQ.Lanes.wclaim/3` runs a **weighted rotation**: one `LMOVE` rotates a ring of serviceable lanes exactly once, then serves that lane a fair share of `K = min(weight, lane depth, glimit headroom)` heads in one atomic turn. The per-lane `ZPOPMIN` still does the pop — but it pops the head of *the rotated lane*, which the score-0 set keeps in mint order, so within a lane it is FIFO.

```lua
-- @gwclaim (lanes.ex) — rotate the ring once, then serve K heads of that lane, trimmed
local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')   -- rotate the ring of serviceable lanes
local lane = ARGV[1] .. 'g:' .. g .. ':pending'
local w = tonumber(redis.call('HGET', ARGV[1] .. 'gweight', g) or '1')  -- the lane's throughput share
local k = w
if depth < k then k = depth end                                    -- never over-pop the lane
-- ... for _ = 1, k do  local popped = redis.call('ZPOPMIN', lane)  ...  end
```

A higher-weight lane is served proportionally more over a window, never all of it — so precedence is the lane's weight and fairness is constructed by the rotation, not read from a packed number. The consumer **codemojex** rides this directly: `Codemojex.NotificationWorker` drains the `cm.notify` lanes, one fair lane per chat, so one chat's burst cannot starve others.

**The bridge.** A textbook priority queue serves the next job with one `ZPOPMIN` over a composite score that already orders by tier then arrival. EchoMQ keeps the per-lane `ZPOPMIN` for the within-lane FIFO, but reaches *across* tiers with a weighted ring rotation in `wclaim/3`: precedence is the lane's `gweight`, the head is the lane's mint-ordered front, and one atomic turn serves the share.

## References

### Sources

- [Valkey — *ZPOPMIN*](https://valkey.io/commands/zpopmin/) — pop the member with the smallest score, atomically; the consume EchoMQ runs per lane on the engine it ships on.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — the same command's Redis reference; pop the smallest-score member.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — score-then-member ordering, the basis for "smallest score is the right job."
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — the add side `ZPOPMIN` reads back; the score that ranks the job (score 0 in EchoMQ's lane sets).

### Related in this course

- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the module hub.
- [R4.03.1 · Packing two keys in one score](/redis-patterns/time-delay-priority/priority-scores/packing-two-keys-in-one-score) — the composite score this pop reads back.
- [R4.03.2 · FIFO within a tier](/redis-patterns/time-delay-priority/priority-scores/fifo-within-tier) — the arrival counter, and EchoMQ's score-0 mint order.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the delayed set's score-bounded read, the sibling consume.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [/echomq · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the lane ring, weighted rotation, and the order theorem.
