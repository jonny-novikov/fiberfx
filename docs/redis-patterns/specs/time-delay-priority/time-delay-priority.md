# R4 · Time, Delay & Priority — the sorted set as a clock

> Scheduling: the sorted set used as a timer wheel and a priority ladder. Five patterns — the delayed queue,
> schedulers and repeatable jobs, composite-score priority, backoff-and-retry, and leaderboards — grounded in
> EchoMQ's `:delayed`/`:repeat` ZSETs and its composite priority score. Depends on R3's jobs.

## Where this chapter starts and ends

- **Start** — R3's reliable queue. The reader can deliver a job now but not schedule it for later, recur it, order
  it by priority, or back it off after a failure.
- **End** — the reader can schedule a job by a future timestamp and promote it when due, run a recurring job without
  duplicates, order a queue by priority with FIFO within a tier, retry with exponential backoff and jitter, and
  build a leaderboard — all on the same ZSET machinery. The workshop schedules Portal's notification and digest jobs.

## The grounding (Redis Pattern Applied)

Grounded in **EchoMQ's time and priority ZSETs**: `bull:{queue}:delayed` scores a job by its fire-time (ms) and
`promoteDelayedJobs` ranges due entries to the wait list; `bull:{queue}:repeat` registers schedulers by next-run
time with an upsert that avoids duplicate jobs on boot; `getPriorityScore` packs `priority * 0x100000000 + counter`
into one double so `ZPOPMIN` yields strict priority then arrival order; and `retryJob` re-uses the delayed ZSET with
`delay = base * 2^(n-1)` plus jitter. Leaderboards reuse the same ZSET commands on Portal's progress rankings.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R4.01 delayed-queue | `delayed-queue` | score a job by fire-time; sweep by score | `:delayed` ZSET + `promoteDelayedJobs` | score = fire-time · ZRANGEBYSCORE promotion · the next-wake computation |
| R4.02 schedulers | `delayed-queue` | recurring jobs via cron/interval | `:repeat` ZSET, upsert | cron vs interval · upsert (no duplicates on boot) · start-to-start cadence |
| R4.03 priority-scores | `lexicographic-sorted-sets` | pack priority + arrival into one score | `getPriorityScore` `priority*0x100000000+pc` | packing two keys in one score · FIFO-within-tier · ZPOPMIN |
| R4.04 backoff-retry | `delayed-queue` | exponential backoff with jitter on the delayed ZSET | `retryJob` (`base * 2^(n-1)`) | exponential backoff · jitter (thundering herd) · the delayed-ZSET reuse |
| R4.05 leaderboards | `leaderboards` | real-time rankings on the same ZSET machinery | Portal progress rankings | ZADD/ZRANK · top-N & around-me · the score-update path |
| R4.06 Workshop | — | schedule Portal's notification/digest jobs | the `:delayed`/`:repeat` ZSETs over Portal jobs | — |

## The door to the EchoMQ course

→ EchoMQ. The scheduler subsystem in depth — the timezone and DST rules, the `:job_slots_busy` guard, the
legacy-repeatable migration, and the parent-child flow scheduling — belongs to the dedicated EchoMQ course. This
chapter teaches the sorted-set time and priority patterns; that course teaches EchoMQ's scheduler.

## Conventions

Pages follow the two mandatory layout rules, pass the ten gates including `refs`, and honour voice and no-invent:
cite the real EchoMQ key, command, or Lua function from the grounding map. The composite priority score
(`priority * 0x100000000 + counter`) is taught from EchoMQ's real `getPriorityScore`, not a paraphrase. See
[`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
