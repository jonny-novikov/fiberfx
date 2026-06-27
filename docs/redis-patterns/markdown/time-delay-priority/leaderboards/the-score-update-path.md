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

## In codemojex — the best-of overwrite in `Board.record/3`

codemojex's score update is `ZADD`, with a best-of fold so a rank only ever climbs. The score worker is the authority:
`Codemojex.ScoreWorker.handle/1` scores a guess with the pure engine and records the result on the board:

```elixir
# Codemojex.ScoreWorker.handle/1 (excerpt) — score, then record on the board
s = Scoring.score(secret, emojis)          # the linear total, out of 600
# …store the GES guess, count the attempt…
eff = Board.record(game, player, s.total)  # ZADD the player's best base to cm:<game>:board
```

`Codemojex.Board.record/3` reads the player's current best from `cm:<game>:base`, takes `new_base = max(old, base)`,
and writes it to the board with `Cmd.zadd("cm:<game>:board") |> Cmd.score(new_base, player)`. That is an absolute
overwrite to the best-so-far — never `ZINCRBY`, because the rank is the best single result, not a running sum. A
re-delivered guess re-scores identically (the engine is pure) and the `max/2` fold makes the write idempotent: a lower
or equal base leaves the rank where it was. No rank is stored; the next `Board.top/2` read recomputes the whole order.

**The bridge.** A score is updated by `ZADD` (overwrite) or `ZINCRBY` (accumulate), and the rank is recomputed from
the order on read, never stored → `Codemojex.Board.record/3` writes each player's best linear total with
`Cmd.zadd("cm:<game>:board") |> Cmd.score(new_base, player)` — a best-of overwrite, idempotent on re-delivery; the rank
is read from the order, never written.

**Take.** Update the score, not the rank — `ZADD` to overwrite, `ZINCRBY` to accumulate. The rank is read from the
order, so it is never stale. codemojex's `Board.record/3` is that `ZADD`, folded to the player's best base.

### A door, not a depth

How the EchoMQ queue updates a job's standing and re-orders its work on a change is the subject of the dedicated
**EchoMQ course** — open onto [the Queue pillar](/echomq/queue). And because the board is a derived view, how a score
survives a restart belongs to the [persistence floor](/echo-persistence): the durable substrate rebuilds the volatile
board from the record of what was scored. This dive teaches the score update and the rank-on-read; those courses teach
the queue re-ordering and the durable rebuild.

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
- [The persistence floor](/echo-persistence) — how a derived board survives a restart, rebuilt from the durable tier.
