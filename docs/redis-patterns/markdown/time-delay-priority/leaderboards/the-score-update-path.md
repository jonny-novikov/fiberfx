# R4.05.3 · The score-update path

> Dive 3 · route `/redis-patterns/time-delay-priority/leaderboards/the-score-update-path`

A score changes in one of two ways: `ZADD` overwrites it, `ZINCRBY` accumulates onto it. Neither touches a rank,
because no rank is stored — the rank is recomputed from the score order on the next read, so it is always consistent.

Updating a leaderboard means updating a score. There are two updates. `ZADD` sets a score to a new absolute value,
replacing whatever was there. `ZINCRBY` adds a delta to the current score, accumulating. Either way, the member is
re-placed in the order by its new score — and that is the entire update. No rank is written, because no rank is stored;
the rank is derived from the order whenever it is next read. Update a score on the right and watch the order, and the
ranks, recompute.

## `ZADD` — overwrite to an absolute value

`ZADD` sets a member's score to the value given, whether or not the member is already on the board:

```
ZADD leaderboard 2000 "player:alice"    # alice's score is now 2000, replacing any prior score
```

This is the update to use when the new score is known outright — a final result, a recomputed total, a snapshot value.
The member is re-placed in the order by 2000; if alice was at rank 4 and 2000 lifts her above three players, she moves
to rank 1 on the next read. `ZADD` carries the whole new state of the score in one write.

## `ZINCRBY` — accumulate a delta

`ZINCRBY` adds a delta to the current score and returns the new score:

```
ZINCRBY leaderboard 50 "player:alice"   # alice's score rises by 50; returns the new total
```

This is the update to use when points arrive incrementally — fifty more for a win, ten for a step completed. Because
the increment happens inside Redis, two concurrent `ZINCRBY` calls on the same member both apply: the score rises by
the sum of the deltas, with no lost update. A plain read-modify-write in the application would lose one of two
concurrent increments; `ZINCRBY` does not. A member not yet on the board is treated as starting from 0, so the first
`ZINCRBY` of 50 sets the score to 50.

## The rank is recomputed on read, never stored

Neither update writes a rank. The rank of any member is its position in the score order, and the set computes that
position when `ZREVRANK` or a range read asks for it — in O(log N), by walking the order. Two consequences follow.
First, the rank is always exactly the current order: there is no stored rank that an update could leave stale, so a
score change is reflected the instant the rank is next read. Second, updating one member's score can shift the ranks
of many others — lift one player past three and those three each drop a place — but none of those neighbours is
rewritten. Their scores are unchanged; only their computed position differs on the next read. The work of a score
update is O(log N) for the re-placement; the ripple through everyone else's rank costs nothing at write time, because
it is computed at read time.

## In Portal — updating the progress percent a ranking would read

The pattern is a score updated two ways, the rank recomputed on read. Portal runs no sorted set. It records a
learner's lesson progress as a **percent** — `Portal.Enrollment.Progress`, the field `percent :: 0..100`, namespace
`PRG`, an in-memory store row. There is no progress ranking; the percent is a stored value that the learner's activity
moves over time.

A ranking view of learners by progress is this dive applied to that data. As a learner's percent changes, a ranking
board would update its score: `ZADD board <new-percent> <learner>` to set the percent outright, the way a recomputed
progress percent is known as an absolute value. The learner is re-placed by their new percent, and every other
learner's rank recomputes on the next read — no neighbour's percent is touched. State it plainly: Portal updates the
percent in its store today; were a ranked view added, the score update is the same `ZADD`, and the rank is read from
the percent order, never stored.

**The bridge.** A score is updated by `ZADD` (overwrite) or `ZINCRBY` (accumulate), and the rank is recomputed from
the order on read, never stored → Portal stores each learner's progress as a `percent` (the `PRG` struct) and updates
it as the learner advances; a ranking view sets the score with `ZADD board percent learner` on each change and reads
the rank from the percent order.

**Take.** Update the score, not the rank — `ZADD` to overwrite, `ZINCRBY` to accumulate. The rank is read from the
order, so it is never stale. Portal's progress percent is the score such an update would write.

### A door, not a depth

How the queue updates a job's standing within its group, and how the group re-orders on a change, is the subject of
the dedicated **EchoMQ course**. The intra-group ranking is [E4 · Groups](/echomq/groups). This dive teaches the score
update and the rank-on-read; that course teaches the group re-ordering built on it.

## Where this is heading — EchoMQ 2.0

The score-update path is generic sorted-set work — `ZADD` to overwrite, `ZINCRBY` to accumulate, the rank read from
the order. It is not part of the EchoMQ queue protocol. Where EchoMQ does order by a sorted-set score is its priority
queue (R4.03's `emq:{queue}:prioritized`), and the settled **EchoMQ 2.0** design (the protocol break on the first EMQ
rung, `emq.1`) renames that keyspace to `emq:{queue}:prioritized` — the `emq:` prefix replacing `emq:`, every Lua key
declared in `KEYS[]`, `meta.version` bumped to `echomq:2.0.0` — with the score order unchanged. A score update and the
rank it recomputes are a property of the order; they are independent of the prefix or the version.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — set a member's score to an absolute value, overwriting any
  prior score.
- [Redis — *ZINCRBY*](https://redis.io/commands/zincrby/) — add a delta to a member's score in place, with no lost
  update under concurrency.
- [Redis — *ZREVRANK*](https://redis.io/commands/zrevrank/) — read the rank from the order, recomputed on each read.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the ordered structure an
  update re-places a member in.

### Related in this course

- [R4.05 · Leaderboards](/redis-patterns/time-delay-priority/leaderboards) — the module hub.
- [R4.05.2 · Top-N and around-me](/redis-patterns/time-delay-priority/leaderboards/top-n-and-around-me) — the previous
  dive: the two reads over the order.
- [R4.05.1 · `ZADD` and `ZREVRANK`](/redis-patterns/time-delay-priority/leaderboards/zadd-and-zrank) — the score in,
  the rank out.
- [R4.03 · Composite priority scores](/redis-patterns/time-delay-priority/priority-scores) — the same sorted-set
  ordering, packed for ties.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: the group re-ordering on a score change.
