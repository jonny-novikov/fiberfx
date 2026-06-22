# R4 · The road ahead

> Route: `/redis-patterns/time-delay-priority/the-road-ahead` · R4 · Time, Delay & Priority · orientation dive

One data structure — the sorted set — carries this whole chapter. The granular ladder
R4.01→R4.06 takes one score reading at a time, and on the far side of the patterns waits the
system that runs them: the scheduler subsystem of the EchoMQ course. This dive surveys the arc
and opens that door.

This is an orientation dive. It has no single Redis-pattern source. It is grounded in the real
chapter ladder (the [redis-patterns TOC](../../redis-patterns.toc.md)) and the real EchoMQ
cross-link map.

## The arc — one score reading at a time

The sorted set is the constant; the meaning of the score changes module to module. R4 walks the
chapter one reading at a time, and each module is grounded in one real EchoMQ surface.

- **R4.01 · The delayed queue** — score a job by its fire-time and sweep the due head by score.
  Grounded in the `:delayed` ZSET (scored `(timestamp + delay) × 0x1000`) and the
  `promoteDelayedJobs` sweep (`ZRANGEBYSCORE` of the due head, then `ZREM` to the wait list).
- **R4.02 · Schedulers & repeatable jobs** — recurring jobs via cron or interval. Grounded in
  the `:repeat` ZSET, upserted with `ZADD nextMillis customKey` and a `ZSCORE` check so a reboot
  re-registers the recurring job instead of duplicating it.
- **R4.03 · Priority with composite scores** — pack a priority tier and an arrival counter into
  one number. Grounded in `getPriorityScore`: `priority × 0x100000000 + (INCR pc) % 0x100000000`
  — the tier in the high 32 bits, a monotonic arrival counter in the low 32 (FIFO within a tier).
- **R4.04 · Backoff & retry** — exponential backoff with jitter, rescheduled onto the delayed
  set. Grounded in `EchoMQ.Backoff.calculate/4` (`base × 2^(n-1)`, then jitter) for the delay,
  and `retryJob-11.lua` for the reschedule onto `:delayed`.
- **R4.05 · Leaderboards** — real-time rankings on the same ZSET machinery. Grounded not in
  EchoMQ but in Portal progress rankings, which use the same `ZADD` / `ZRANK` / `ZREVRANGE`
  commands the rest of the chapter teaches.
- **R4.06 · Workshop** — schedule Portal's notification and digest jobs over the `:delayed` and
  `:repeat` sets, putting the whole chapter to work on one real surface.

The reliable queue learned its lifecycle in R3; here it learns a clock and an order. Read the arc
as one queue gaining one sense — *when*, and *in what order* — from one ZSET read two ways.

## The door beyond — the living EchoMQ course

R4 teaches the transferable sorted-set patterns. The engine that runs them — the scheduler
subsystem — is the subject of the dedicated **EchoMQ course** (`/echomq`), a living, agile-spec
course built in two movements. Movement I (E1–E2) teaches the as-built core library; Movement II
(E3–E8) is a living spine that tracks the EMQ extension ladder rung by rung, each page standing on
the triangle of the redis-patterns pattern, the `emq.N` implementation spec, and the as-built code.

What the scheduler subsystem owns beyond the patterns:

- **scheduler timezone & DST** — cron schedules computed in a named timezone across a
  daylight-saving boundary, so a recurring job fires at the right local time. Extends R4.02
  schedulers; owned by **E6 · Lifecycle controls**.
- **the busy-slot guard** — a recurring job whose previous run has not finished is not double-run;
  the scheduler holds the next fire until the slot is free. Extends R4.02 schedulers; owned by
  **E6 · Lifecycle controls**.
- **legacy-repeatable migration** — moving older repeat keys onto the current `:repeat` registry
  without losing or duplicating a schedule. Extends R4.02 schedulers; owned by **E6 · Lifecycle
  controls**.
- **parent-child flow scheduling** — a delayed or prioritized job that gates a child flow, so the
  child fires only after the parent is due and complete. Extends R4.03 priority; owned by
  **E4 · Groups**.

Per the cross-link map, R4 opens onto two EchoMQ chapters: **E6 · Lifecycle controls** (the
delay / promote / retry / TTL scheduler depth) and **E4 · Groups** (intra-group priority and the
control plane, the home of R4.03 priority and the fairness arc).

A note on honesty. The course-level map pairs R4/R5 with E6/E7, but E7 is EchoCache, the near-cache
— unrelated to time, delay, or priority. The honest, content-grounded doors are E6 and E4; that
choice is recorded in `r4.progress.md`. The served `/echomq` pages ship as the build lands.

## The bridge

**The patterns.** R4.01–R4.06 teach the sorted-set techniques applied: a job scored by fire-time,
a composite priority, a recurring registry, a backoff reschedule. Each lands twice — the technique
and its trade-offs, then the one real EchoMQ excerpt that proves it.

→

**The system.** The EchoMQ scheduler subsystem applies them all under one engine: timezone and DST,
the busy-slot guard, legacy migration, and parent-child flow scheduling. Where this course cites
one excerpt as proof, that course teaches the subsystem that runs it.

**Take:** the patterns are the vocabulary; the EchoMQ scheduler is the engine. Learn the score
readings here, then go run them there.

## A door, not a depth

This chapter proves each pattern with one real excerpt and stops there. The deeper scheduler —
timezone and DST arithmetic, the busy-slot guard, the legacy-repeatable migration, parent-child
flow scheduling — is the subject of the dedicated EchoMQ course, not of this one. This page names
that door and steps through it.

- The EchoMQ course home: [`/echomq`](/echomq).
- R4's specific doors: [E6 · Lifecycle controls](/echomq/lifecycle),
  [E4 · Groups](/echomq/groups).

Start building with [`/echomq`](/echomq).

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the one
  structure this whole chapter reads two ways: a clock scored by fire-time and a priority ladder
  scored by a composite number.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the command that sweeps the
  due head of the delayed set, the engine of R4.01's promote step.
- [BullMQ](https://bullmq.io/) — the queue protocol whose scheduler EchoMQ ports across three
  runtimes, the source of the `:delayed` / `:prioritized` / `:repeat` score conventions.
- [llms.txt — *The /llms.txt convention*](https://llmstxt.org/) — the machine-readable map format
  both this course and the EchoMQ course publish for agents.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter this dive closes.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) —
  dive 1: one ZSET read two ways, a timer wheel and a priority ladder.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — dive 2: the score
  is the whole semantic axis — fire-time, composite priority, next-run-millis.
- [R3 · The road ahead](/redis-patterns/queues/the-road-ahead) — the parallel orientation dive that
  surveys the full course arc and the first EchoMQ doors.
