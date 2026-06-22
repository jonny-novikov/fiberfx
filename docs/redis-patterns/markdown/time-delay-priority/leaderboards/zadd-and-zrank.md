# R4.05.1 · `ZADD` and `ZREVRANK`

> Dive 1 · route `/redis-patterns/time-delay-priority/leaderboards/zadd-and-zrank`

A player's score goes in with `ZADD`; the rank comes out with `ZREVRANK`. The score is the ranking key — the set
orders by it, and the rank is a position in that order, computed on read.

A leaderboard rests on one structure: a sorted set whose score is the player's points. Two commands carry it. `ZADD`
writes a member and a score, placing the member in the order. `ZREVRANK` reads a member's position in that order from
the top, where the highest score is rank 0. No rank is stored; the rank is the position, recomputed each time it is
read. Set a score on the right and watch the rank fall out of the order.

## `ZADD` — the score is the write

A sorted set holds members, each with a numeric score, and keeps them ordered by score. The whole write is `ZADD`: a
score and a member.

```
ZADD leaderboard 1500 "player:alice"
```

Run `ZADD` on a member that is already on the board and its score is overwritten, and the member is re-placed in the
order. The score is the entire index — there is no separate ranking column. Reading the set high-to-low gives the
leader first; reading it low-to-high gives the trailing player. A player's own score is read with `ZSCORE`, which is
O(1).

## `ZREVRANK` — the rank is a position

A rank is a player's position in the order, counted from one end. `ZREVRANK` counts from the top, so the leader is
rank 0:

```
ZREVRANK leaderboard "player:bob"   # 0 if bob has the highest score
```

The rank is 0-based: rank 0 is first place, rank 1 is second. The set computes it by walking the order to the member,
which is O(log N) — the cost does not grow with how the board is read, only with its size. Crucially, the rank is not
stored anywhere. It is derived from the score order on each read, so it is always exactly the current order; there is
no snapshot to fall out of date.

## `ZRANK` — the mirror from the bottom

`ZRANK` is the same position counted from the other end — low-to-high, so the lowest score is rank 0:

```
ZRANK leaderboard "player:bob"      # 0 if bob has the lowest score
```

For a board where a higher score is better, `ZREVRANK` is the rank a player wants to see; `ZRANK` answers the opposite
question — how far up from the bottom. The two are mirrors of one position in the same order. If the board holds N
players, a member's `ZRANK` and `ZREVRANK` add up to N − 1. Reading either end leaves the set unchanged.

## In Portal — the percent is the score the rank would read

The pattern is a clean sorted-set leaderboard: score in, rank out. Portal does not run one. What Portal does record is
a learner's progress through a lesson as a **percent** — `Portal.Enrollment.Progress`, the field `percent :: 0..100`,
namespace `PRG`, a row in an in-memory store. Portal has no progress ranking and no Redis sorted set; the percent is a
plain stored value.

Ranking learners by that percent is this dive applied to that data. `ZADD board <percent> <learner>` writes each
learner's percent as a score; `ZREVRANK board <learner>` then reads where that learner stands. The percent is the
score the rank would read. State it plainly: the percent exists in Portal's store today, and the sorted-set rank is
the ordinary structure to add when a ranked view of that percent is wanted — the rank is never stored, only computed
from the percent order on read.

**The bridge.** `ZADD` writes a score and `ZREVRANK` reads a 0-based rank from the score order, computed on read →
Portal stores each learner's lesson progress as a `percent` (the `PRG` struct); a ranking view scores by that percent
(`ZADD board percent learner`) and reads a learner's standing with `ZREVRANK`, the rank derived from the percent order.

**Take.** The score is the write and the rank is the read; nothing stores a rank. Portal stores a progress percent —
the score a `ZREVRANK` would read.

### A door, not a depth

The full ranking machinery — how a group orders its members and resolves equal scores inside the queue — is the
subject of the dedicated **EchoMQ course**. The intra-group ranking is [E4 · Groups](/echomq/groups). This dive teaches
`ZADD` and `ZREVRANK`; that course teaches the group ranking built on the same score order.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add or update a member's score; the single write that places a
  player in the order.
- [Redis — *ZREVRANK*](https://redis.io/commands/zrevrank/) — a member's rank, 0-based from the top, computed on read.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type behind the
  board: members ordered by a numeric score.

### Related in this course

- [R4.05 · Leaderboards](/redis-patterns/time-delay-priority/leaderboards) — the module hub.
- [R4.05.2 · Top-N and around-me](/redis-patterns/time-delay-priority/leaderboards/top-n-and-around-me) — the next
  dive: the two read shapes over this order.
- [R4.05.3 · The score-update path](/redis-patterns/time-delay-priority/leaderboards/the-score-update-path) — updating
  a score and reading the rank again.
- [R4.03 · Composite priority scores](/redis-patterns/time-delay-priority/priority-scores) — packing two axes into one
  score for ties.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: the group ranking on the same score order.
