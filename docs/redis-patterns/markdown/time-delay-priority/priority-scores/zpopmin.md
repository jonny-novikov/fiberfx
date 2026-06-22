# R4.03.3 · ZPOPMIN

> A worker takes the next prioritized job with `ZPOPMIN` — pop the member with the smallest score. The smallest composite score is the highest-priority tier and, within it, the earliest arrival. One command returns the right job and removes it atomically, then `LPUSH` moves it to the active list.

The composite score packs the tier and the arrival order so that "the right next job" is always the smallest number. This dive walks the consume side: the single pop that reads that number, and why a lower priority value comes out first.

## The smallest score is the right job

The composite score is `priority × 0x100000000 + counter`. A smaller priority number makes a smaller high-bit field; within a tier a smaller arrival counter makes a smaller low-bit field. So the smallest score in the set is, by construction, the highest-priority tier and the earliest arrival within it — exactly the job a priority queue should serve next.

`ZPOPMIN` removes and returns the member with the smallest score:

```
ZPOPMIN emq:{queue}:prioritized
# Returns: [ "job:abc123", "4294967297" ]  — the smallest-score member, removed
```

The pop is atomic: read-and-remove in one step, so two workers polling the same set never claim the same job. The job leaves the prioritized set the instant it is chosen.

## Why a lower priority number wins

The convention that surprises newcomers — priority 1 outranks priority 5 — is a direct consequence of two facts composed. The formula makes a higher-precedence tier a *smaller* score: `1 × 2^32` is smaller than `5 × 2^32`. And `ZPOPMIN` always returns the *smallest* score first. Compose them and the lowest priority number is served first. Nothing reverses or negates the value; the precedence is encoded as "smaller is sooner" and read by "pop the smallest."

The interactive below steps `ZPOPMIN` over a fixed set of prioritized jobs. Each step removes the current smallest score and names the popped job, its tier, and its arrival counter — showing the order march down the tiers and, within each tier, forward through arrivals.

## After the pop: into the active list

In EchoMQ the pop does not stand alone — the popped job id moves straight onto the active list. `moveToActive-11.lua` runs the pop and the push together:

```lua
-- moveToActive-11.lua — real
local prioritizedJob = rcall("ZPOPMIN", priorityKey)
if #prioritizedJob > 0 then
  rcall("LPUSH", activeKey, prioritizedJob[1])
  return prioritizedJob[1]
end
```

`prioritizedJob[1]` is the member — the job id — and `prioritizedJob[2]` is its score. The script pushes the id onto the active list with `LPUSH` and returns it. The prioritized set ranks the work; the active list holds the job the worker is now running. One script does both, so a job cannot be popped and then lost between the two steps.

## In EchoMQ

The prioritized set is `EchoMQ.Keys.prioritized/1` → `emq:{queue}:prioritized`. The consume is `moveToActive-11.lua`: `local prioritizedJob = rcall("ZPOPMIN", priorityKey)` then `rcall("LPUSH", activeKey, prioritizedJob[1])`. The pop honours the composite score `getPriorityScore` wrote on the add side, so the job that comes out is the one the tier and arrival counter ranked first. Re-prioritizing a still-queued job is `EchoMQ.Scripts.change_priority`, which re-scores it with a fresh `getPriorityScore` so its place in the pop order changes.

**The bridge.** A textbook priority queue often needs a structure per tier plus a separate FIFO, then logic to choose across them. EchoMQ needs one sorted set and one `ZPOPMIN`: the composite score already orders by tier then arrival, so the single smallest-score pop returns the right job and removes it, with no scan and no second structure.

## References

### Sources

- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the member with the smallest score, atomically; the consume that serves the highest-priority, earliest-arrival job.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — score-then-member ordering, the basis for "smallest score is the right job."
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — the add side `ZPOPMIN` reads back; the composite score that ranks the job.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the prioritized-jobs protocol EchoMQ ports, where the Lua scripts are the protocol.

### Related in this course

- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the module hub.
- [R4.03.1 · Packing two keys in one score](/redis-patterns/time-delay-priority/priority-scores/packing-two-keys-in-one-score) — the composite score `ZPOPMIN` reads back.
- [R4.03.2 · FIFO within a tier](/redis-patterns/time-delay-priority/priority-scores/fifo-within-tier) — the arrival counter that orders within a tier the pop honours.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the delayed set's score-bounded read, the sibling consume.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: intra-group priority in depth.
