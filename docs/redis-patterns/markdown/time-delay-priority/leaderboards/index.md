# R4.05 · Leaderboards

> Module hub · route `/redis-patterns/time-delay-priority/leaderboards`

A sorted set is a leaderboard: store each player's score, and rank, top-N, and around-me queries fall out of the score
order — no row is ever ranked at write time; the rank is computed on read.

A leaderboard answers one need: who is ahead, and by how much. A list cannot express it — a list keeps members in the
order they were filled, with no notion of which member is highest. A sorted set can. Score each player by their points
and the set orders its members by score for free; the rank of any player is their position in that order, the top-N is
a read of the first N positions, and an around-me window is a read of the positions either side of a player's own. No
position is stored. The rank is recomputed on every read in O(log N), so it is always exactly the score order, never a
stale snapshot. This module takes the textbook leaderboard apart and grounds it in the one that runs live:
**`Codemojex.Board`** keeps one sorted set per game and ranks players by their best linear score.

## Core operations — `ZADD` and the score

A sorted set stores members with associated scores and maintains order by score automatically. The leaderboard is one
sorted set; each member is a player, each score is that player's points.

Add or update a player's score:

```
ZADD leaderboard 1500 "player:alice"
ZADD leaderboard 2300 "player:bob"
ZADD leaderboard 1800 "player:charlie"
```

`ZADD` is the whole write: a member and a score. Re-running `ZADD` on a member that already exists overwrites its
score and re-places it in the order. Read a single player's score with `ZSCORE`, which is O(1):

```
ZSCORE leaderboard "player:alice"
```

The score is the entire ordering. Reading the set high-to-low gives the leader at the top; reading low-to-high gives
the trailing player. Nothing else indexes the board. This is the move `Codemojex.Board.record/3` makes: it folds the
player's best base score (`new_base = max(old, base)`) and writes it straight to the board — `Cmd.zadd("cm:<game>:board")
|> Cmd.score(new_base, player)`.

## Rank vs reverse rank

A rank is a player's position in the order. Redis offers the position from each end:

- `ZRANK` returns the position sorted low-to-high — the lowest score is rank 0.
- `ZREVRANK` returns the position sorted high-to-low — the highest score is rank 0.

For a leaderboard where a higher score is better, `ZREVRANK` is the one to read: the leader sits at rank 0, the
runner-up at rank 1. A rank is 0-based, so "rank 0" is first place. The two commands are mirrors of one position in
the same order; reading one end never changes the set.

```
ZREVRANK leaderboard "player:alice"   # 0 = top
ZRANK leaderboard "player:alice"      # 0 = bottom
```

## Players around a rank

To show a player their standing against nearby competitors, read a window of positions either side of their own. First
find the player's rank, then read the rank window around it:

```
ZREVRANGE leaderboard 45 55 WITHSCORES
```

This reads positions 45 through 55 from the top — the players ranked 46th through 56th in 1-based terms. The same two
reads serve any "around-me" view: `ZREVRANK` to locate the player's position, then a rank-range read centred on it.
The window is a slice of the existing order; the board is unchanged.

## Tiebreaking with composite scores

When two players share a score, a plain sorted set falls back to comparing the members lexicographically — not the
order a ranking should hold. A sorted set has no secondary sort key, so encode both the points and the tiebreaker into
a single score. For a score achieved at a timestamp, pack the points into the high digits and the inverted timestamp
into the low digits:

```
composite = points * 10000000000 + (MAX_TIMESTAMP - timestamp)
```

Higher points always dominate; for equal points, the earlier timestamp ranks higher because it is subtracted from a
maximum. The points are recovered by integer division. This is the same score-packing idea the priority queue uses to
order equal-priority jobs by arrival — covered in
[R4.03 · Composite priority scores](/redis-patterns/time-delay-priority/priority-scores). One score carries two axes,
the high digits dominating the low.

## Pagination and efficient player info

A large board is read a page at a time — each page is a rank range:

```
ZREVRANGE leaderboard 0 19 WITHSCORES    # page 1: ranks 1–20
ZREVRANGE leaderboard 20 39 WITHSCORES   # page 2: ranks 21–40
```

`ZCARD` returns the member count, which gives the page count. To read a player's rank and score together in one
network round trip, pipeline the two reads:

```
ZREVRANK leaderboard "player:alice"
ZSCORE leaderboard "player:alice"
```

Both run in a single round trip when pipelined, returning the rank and the score together.

## Variations — time-windowed and aggregating

A "this week" or "today" board is a separate sorted set under a time-keyed name, given a TTL so it expires on its own:

```
ZADD leaderboard:weekly:2024-W05 1500 "player:alice"
EXPIRE leaderboard:daily:2024-01-30 172800
```

Several windows combine with `ZUNIONSTORE`, whose `AGGREGATE` option chooses how scores merge — `SUM` for total
points across days, `MAX` for a personal best, `MIN` for a best time. Redis 6.2 folded the range commands into a
unified `ZRANGE` with a `REV` option, so `ZRANGE … REV` reads the same top-N as the older `ZREVRANGE`; the ordering is
identical, only the spelling changed.

## The pattern, applied — codemojex's per-game leaderboard

The pattern lands twice: the textbook sorted-set leaderboard, and the one codemojex runs. **codemojex** is a Telegram
emoji-guessing game on the same stack. Its competitive state lives in Valkey, and the leaderboard is exactly this
pattern, in the real code:

- The score is the linear total from `Codemojex.Scoring` — `points = 100 - 20 * d` per emoji at distance `d`, summed
  over six positions, out of 600. The same secret and guess always yield the same total, so a re-delivered guess
  re-scores identically.
- The board is one sorted set per game, keyed `cm:<game>:board`. `Codemojex.Board.record/3` reads the player's best
  base from `cm:<game>:base`, folds the higher of the old and new (`new_base = max(old, base)`), and writes it to the
  board with `Cmd.zadd("cm:<game>:board") |> Cmd.score(new_base, player)` — the raw linear best is the sole rank, no
  tier ladder, no first-mover bonus.
- The read is the top-N: `Codemojex.Board.top/2` runs `Cmd.zrevrange("cm:<game>:board", 0, n - 1) |> Cmd.withscores()`,
  highest first. `Codemojex.View.leaderboard/2` returns `{player, max_score}` rows from it, withholding everyone's
  guesses — the leaderboard is the one place a player sees others, and only their scores.

The score worker is the authority: `Codemojex.ScoreWorker.handle/1` scores a guess with the pure engine
(`s = Scoring.score(secret, emojis)`) and records the result on the board (`Board.record(game, player, s.total)`). The
rank is never stored — it is the player's position in the score order, recomputed on every read of the board.

**The bridge.** A sorted set ranks players by score in O(log N), with the rank computed on read and never stored →
`Codemojex.Board` keeps one sorted set per game (`cm:<game>:board`), writes each player's best linear total with `ZADD`
(via `EchoWire.Cmd.zadd/1` + `Cmd.score/3`), and reads the top-N with `ZREVRANGE … WITHSCORES` (`Board.top/2`). The
board stores scores; the rank is the order.

**Take.** A leaderboard never stores a rank; it stores scores and reads the order. codemojex's board is a sorted set
per game with each player's best linear score — the rank is whatever the order says on read.

## The three dives

- [R4.05.1 · `ZADD` and `ZREVRANK`](/redis-patterns/time-delay-priority/leaderboards/zadd-and-zrank) — the leaderboard
  core: `ZADD` a score, read `ZREVRANK` (0-based from the top) and its mirror `ZRANK`; the score is the ranking key.
- [R4.05.2 · Top-N and around-me](/redis-patterns/time-delay-priority/leaderboards/top-n-and-around-me) — the two read
  shapes: `ZREVRANGE 0 N-1 WITHSCORES` for the top-N (what `Board.top/2` runs), and the around-me window — `ZREVRANK`
  to find a rank, then a rank-range read centred on it.
- [R4.05.3 · The score-update path](/redis-patterns/time-delay-priority/leaderboards/the-score-update-path) — updating
  a score: `ZADD` overwrites (the best-of write `Board.record/3` makes), `ZINCRBY` accumulates; the rank is recomputed
  on read, never stored, which is why it is O(log N) and always consistent.

### A door, not a depth

A leaderboard is a generic sorted-set ranking — it is not part of the EchoMQ queue protocol. Where EchoMQ ranks for
real is the **Queue pillar**: the queue orders work by a packed schedule/priority score in the `emq:{q}:` keyspace,
the same score-order idea a leaderboard uses. codemojex's board rides Valkey beside that queue. From here, open onto
[the Queue pillar](/echomq/queue) for the EchoMQ ranking in depth, and onto
[the persistence floor](/echo-persistence) for how a score survives a restart — the board is a derived view that a
durable substrate rebuilds.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the score-ordered structure
  a leaderboard is: members held in order of a numeric score.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add or update a player's score on the board.
- [Redis — *ZREVRANGE*](https://redis.io/commands/zrevrange/) — read the top-N, highest scores first.
- [Redis — *ZREVRANK*](https://redis.io/commands/zrevrank/) — a member's rank, 0-based from the top.
- [Redis — *ZINCRBY*](https://redis.io/commands/zincrby/) — accumulate a score in place.

### Related in this course

- [R4.05.1 · `ZADD` and `ZREVRANK`](/redis-patterns/time-delay-priority/leaderboards/zadd-and-zrank) — the leaderboard
  core: score in, rank out.
- [R4.05.2 · Top-N and around-me](/redis-patterns/time-delay-priority/leaderboards/top-n-and-around-me) — the two read
  shapes over one order.
- [R4.05.3 · The score-update path](/redis-patterns/time-delay-priority/leaderboards/the-score-update-path) — overwrite,
  accumulate, rank on read.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [R4.03 · Composite priority scores](/redis-patterns/time-delay-priority/priority-scores) — the same score-packing
  idea, there for ties.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the orientation dive: the score is
  the semantic axis.
- [The Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the queue's score-ordered work in depth.
- [The persistence floor](/echo-persistence) — how a derived board survives a restart, rebuilt from the durable tier.
