# R4.05.2 · Top-N and around-me

> Dive 2 · route `/redis-patterns/time-delay-priority/leaderboards/top-n-and-around-me`

Two reads serve every leaderboard view. The top-N is the first N positions of the order; the around-me window is a
slice of positions either side of a player's own. Both read the same order and leave it unchanged.

A leaderboard view is one of two shapes. The first is the top-N — the leader and the players right behind. The second
is around-me — where a single player stands, with a few competitors above and below. Both are reads of the same sorted
order: the top-N reads from the head, and around-me first locates a player's rank, then reads the band centred on it.
Pick a view on the right and watch the index range each read walks.

## Top-N — a read from the head

The top-N is the first N positions of the board read high-to-low. `ZREVRANGE` reads a rank range from the top, and
`WITHSCORES` returns each member's score alongside it:

```
ZREVRANGE leaderboard 0 9 WITHSCORES    # the top 10
```

The arguments `0 9` are rank indices, inclusive — positions 0 through 9, the leader through the tenth player. To read
the top 5, the range is `0 4`; for the top 20, `0 19`. The read walks N members from the head, which is O(log N + N):
the log to find the head, then N to read across. The board is unchanged — `ZREVRANGE` reads the order, never writes
it. Redis 6.2 folded the range commands into a unified `ZRANGE … REV`, which reads the identical top-N; only the
spelling differs.

## Pagination — the top-N, page by page

A large board is read a page at a time, each page a rank range further down the order:

```
ZREVRANGE leaderboard 0 19 WITHSCORES    # page 1: ranks 1–20
ZREVRANGE leaderboard 20 39 WITHSCORES   # page 2: ranks 21–40
```

Page p of size s is the range `(p−1)·s` through `p·s − 1`. `ZCARD` returns the member count, which divided by the page
size gives the page count. Each page is the same head-read, offset down the order.

## Around-me — locate, then read the band

The around-me view shows a player their standing against nearby competitors. It is two reads. First locate the
player's rank with `ZREVRANK`; then read the rank band centred on it:

```
ZREVRANK leaderboard "player:alice"      # say it returns 50
ZREVRANGE leaderboard 45 55 WITHSCORES   # ranks 45–55: alice with five either side
```

With a window half-width k, the band is `rank − k` through `rank + k`. Near the top the band clamps at 0 — a player at
rank 2 with k = 5 reads `0 7`, since there is nothing above rank 0. The band is a slice of the existing order; neither
read changes the set. Locate, then read the band around the located rank.

## In Portal — ranking the progress percent

The pattern is two reads over a sorted order. Portal runs no sorted set. It records a learner's lesson progress as a
**percent** — `Portal.Enrollment.Progress`, the field `percent :: 0..100`, namespace `PRG`, an in-memory store row.
There is no progress ranking; the percent is a stored value.

A ranked view of learners by progress is this dive applied to that data. Score each learner by their percent with
`ZADD board <percent> <learner>`, and the two reads serve the two views: `ZREVRANGE board 0 9 WITHSCORES` reads the ten
learners furthest along, and `ZREVRANK` then a rank-range read shows one learner where they stand among their nearest
peers. State it plainly: the percent is in Portal's store today; the top-N and around-me reads are the standard way to
present a ranked view of it, and both read the percent order without changing it.

**The bridge.** The top-N is a head-read of the score order (`ZREVRANGE 0 N-1`) and around-me is a band centred on a
rank (`ZREVRANK`, then a rank-range read) → Portal stores each learner's progress as a `percent` (the `PRG` struct); a
ranked view scores by that percent and reads the top learners as a head-read and a single learner's neighbourhood as a
band around their rank.

**Take.** Two reads cover every view: the head for the top-N, a band for around-me. Both read the order — Portal's
progress percent, ranked — and leave it untouched.

### A door, not a depth

How a job group presents its own ordered members, and how the queue reads a band of a group's work, is the subject of
the dedicated **EchoMQ course**. The intra-group ranking is [E4 · Groups](/echomq/groups). This dive teaches the top-N
and around-me reads; that course teaches the group reads built on the same order.

## References

### Sources

- [Redis — *ZREVRANGE*](https://redis.io/commands/zrevrange/) — read a rank range from the top, the top-N and the
  pagination read.
- [Redis — *ZREVRANK*](https://redis.io/commands/zrevrank/) — locate a member's rank, the first read of an around-me
  window.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the ordered structure both
  reads walk.

### Related in this course

- [R4.05 · Leaderboards](/redis-patterns/time-delay-priority/leaderboards) — the module hub.
- [R4.05.1 · `ZADD` and `ZREVRANK`](/redis-patterns/time-delay-priority/leaderboards/zadd-and-zrank) — the previous
  dive: the score in, the rank out.
- [R4.05.3 · The score-update path](/redis-patterns/time-delay-priority/leaderboards/the-score-update-path) — the next
  dive: updating a score, the rank recomputed.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the score is the semantic axis.
- [E4 · Groups](/echomq/groups) — the dedicated EchoMQ course: the group reads on the same order.
