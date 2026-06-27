# R4.06 · Workshop — One sorted set, five readings

> Route: `/redis-patterns/time-delay-priority/workshop` · chapter workshop (capstone) · chapter R4 · Time, Delay & Priority · no dives

Fold the five R4 patterns into one worked scenario: EchoMQ schedules codemojex's notification and digest jobs — a round-start reminder, a daily standings digest, a fairness-deferred send, a failed send that retries, and the ranking the digest carries. Every move is one sorted set read a different way.

The chapter taught five patterns over the sorted set: the delayed queue (R4.01), the scheduler registry (R4.02), the composite priority score (R4.03), backoff-and-retry (R4.04), and the leaderboard ranking (R4.05). This capstone is the one scenario that uses all five at once. codemojex is a live Telegram emoji-guessing game on the EchoMQ + EchoStore + Postgres stack; `Codemojex.NotificationWorker` already drains a notify queue and delivers each notice through the bot under fairness, rate, and delivery control. EchoMQ schedules those jobs, so the scenario is a worked application of the chapter's machinery on a real surface, not a counterfactual. The reminder is a one-shot scheduled job; the digest is a repeatable registration; the over-budget send is deferred, not dropped; the failed send is a backed-off retry; and the digest carries a ranking. One schedule set, one repeat registry, and one ranking set drive the worker, all on the same `ZADD` / range / pop machinery.

## The consumer — codemojex's notification worker

The five jobs in this scenario are all about codemojex entities, and each carries its own branded namespace (cite, do not invent):

- `USR` — a player account.
- `RMM` — a room (a chat where a game runs).
- `RND` — a round (one secret to guess).
- `NOT` — a notification job. `Codemojex.NotificationWorker` mints a `NOT` id with `EchoData.BrandedId.generate!("NOT")` for each re-enqueued occurrence.

`Codemojex.NotificationWorker` is the real worker. An `EchoMQ.Consumer` drains the `cm.notify` queue and `handle/1` delivers each notice through the bot, under three layers of control: fairness (a fair lane per chat via `Codemojex.Notifier`, so one chat's burst cannot starve others), rate (a token from `Codemojex.RateLimiter` before each send — global ~30/s, per-chat ~1/s), and delivery (`EchoBot.deliver/3` classifies the Telegram result: success acks, a transient failure re-enqueues with capped exponential backoff up to `@max_attempts` 6, a permanent failure acks-and-drops). The payload is JSON `{chat, text, opts, id, attempt}`. The five readings below are the chapter's patterns assembled on top of that worker.

## The round-start reminder — a one-shot scheduled job (R4.01)

A room schedules the next round to begin at a fixed time; a reminder fires when it does. EchoMQ schedules that reminder for an absolute due time with `EchoMQ.Jobs.enqueue_at(conn, queue, job_id, payload, run_at_ms)`. The job's row is written `state = scheduled` and the branded `JOB` id is parked on the schedule set `emq:{cm.notify}:schedule`, scored by the run-at millisecond. The `@schedule` Lua declares both keys — `KEYS[1]` the job row, `KEYS[2]` the schedule set — guards the id with `if string.sub(ARGV[1], 1, 3) ~= 'JOB'`, and writes `ZADD KEYS[2] score ARGV[1]`.

When the clock reaches the score, `EchoMQ.Jobs.promote(conn, queue, batch)` sweeps the due head with `ZRANGEBYSCORE KEYS[1] -inf now LIMIT 0 batch` — `now` read from the server clock (`redis.call('TIME')`) — then `ZREM`s each due id and moves it to the pending set `emq:{cm.notify}:pending`. The mint-ordered id stays the sort key once promoted, so a job minted earlier but scheduled later sorts, after promotion, by its mint instant.

The takeaway: the reminder is one member on `emq:{cm.notify}:schedule`, scored by its run-at; `enqueue_at/6` writes the score, `promote/3` reads the due range on the server clock, and the visibility fence — not a second queue — is one sorted set.

## The daily standings digest — a repeatable registration (R4.02)

Every day a room gets a standings digest. That is a recurring schedule, not a one-shot, so it is a registration the bus sweeps: `EchoMQ.Repeat.register(conn, queue, name, every_ms, template, first_in_ms)`. The `@register` Lua declares two `{q}`-hashtagged keys — `KEYS[1]` the registry set `emq:{cm.notify}:repeat`, scored by next-run millisecond, and `KEYS[2]` the record hash `emq:{cm.notify}:repeat:<name>`, carrying `every_ms` and the payload `template`. It guards with `if redis.call('EXISTS', KEYS[2]) == 1 then return 0`, so a second register of a live name answers `:exists` and changes nothing.

That EXISTS guard is what makes a reboot safe: a service that boots re-registers all its schedules, and a live name is a no-op rather than a second row. The pump reads due names with `EchoMQ.Repeat.due/3` (`ZRANGEBYSCORE emq:{cm.notify}:repeat -inf now`), mints a fresh `JOB` id per occurrence — never a reused row — and calls `EchoMQ.Repeat.advance/4` to re-score the name to now plus `every_ms`. The `EchoMQ.Metronome` per-queue beat drives that sweep.

The takeaway: the digest is one member on `emq:{cm.notify}:repeat`, scored by its next run and advanced each fire; the `EXISTS`-guarded register keeps the registry at one row per scheduler, so any number of boots adds no duplicate.

## The over-budget send — fairness and a deferred re-enqueue (R4.03)

The chapter packed a priority tier and an arrival counter into one score so a high-precedence job pops ahead. codemojex makes the same "do not let a flood starve the rest" guarantee, but it does it with **fairness plus rate**, not a packed priority score — the honest applied move. `Codemojex.Notifier` enqueues each notice on a fair lane per chat, so one chat's burst rides its own lane; before each send `handle/1` takes a token from `Codemojex.RateLimiter`. When the bucket is empty, `RateLimiter.take(chat)` returns `{:wait, ms}` and the worker does not block the consumer: it re-enqueues the exact notification after the bucket's reported wait with `EchoMQ.Jobs.enqueue_in(conn, queue, job_id, payload, delay_ms)`, and acks. The notice stays durable on the bus, deferred, not dropped.

`enqueue_in/6` is `enqueue_at/6`'s relative twin: the run-at score is computed wire-side from the server clock (`local t = redis.call('TIME')`), so the delay is measured on the same clock `promote/3` and `reap/2` read — never the caller's. The composite-priority score (`priority × 2^32 + arrival`) is the alternative reading of the schedule set; the codemojex design is built on fair lanes and a token bucket instead, and the schedule set carries the deferral.

The takeaway: an over-budget send is re-scheduled with `enqueue_in/6` on the same `emq:{cm.notify}:schedule` set the reminder rides; fairness comes from the per-chat lane and rate from the token bucket, the chapter's priority-score being the contrast reading of the same structure.

## The failed send — a backed-off retry (R4.04)

A delivery fails: Telegram returns a transient 429 or 5xx. `EchoBot.deliver/3` classifies it `{:retry, reason}`, and while `attempt < @max_attempts` the worker re-enqueues the same notice with a growing delay so a struggling endpoint is not hammered. The reschedule re-uses the schedule set: `enqueue_in/6` parks the job on `emq:{cm.notify}:schedule` at the backoff fire-time, and the same `promote/3` sweep brings it back when due. No new structure — the retry is a delayed job whose fire-time is a backoff delay.

The delay curve is `EchoMQ.Backoff.delay_ms(policy, attempts)`, a pure function above the wire: `{:exponential, base, cap}` returns `min(base × 2^(attempts-1), cap)`, clamped at the ceiling. The module's doc vectors are exact — `delay_ms({:exponential, 100, 10_000}, 1) = 100`, `delay_ms({:exponential, 100, 10_000}, 3) = 400`, `delay_ms({:exponential, 100, 10_000}, 20) = 10000` — and `{:jitter, inner}` wraps any inner policy with a uniform draw in `0..inner_delay`, the full-jitter form that spreads a retry storm so a batch that failed together does not re-fire in one synchronized spike. The host computes the literal delay; the wire takes a literal `delay_ms` and never computes a curve.

The takeaway: the failed send is a delayed job whose fire-time is a backoff delay; `EchoMQ.Backoff.delay_ms/2` sizes it, the same `emq:{cm.notify}:schedule` set holds it, and the same `promote/3` sweep returns it — one structure, two uses.

## The ranking the digest carries — a sorted-set ranking (R4.05)

The digest's content names the room's top players. That is a ranking: order players by their round score, read the top-N. `Codemojex.Scoring` computes a player's score from their guess — `points = 100 - 20*d` for each guessed emoji at distance `d` from its secret position, totalled over six positions out of `@max` 600, the percentage `round(total / 600 * 100)` computed never stored. A leaderboard that ranks players by that percentage is exactly this pattern applied to the score: `ZADD board <percentage> <player>`, and the top-N players are a `ZREVRANGE board 0 N-1`, a player's standing a `ZREVRANK`, an around-me view a rank-range read. The rank is computed on read in `O(log N)`, never stored.

The takeaway: the ranking is the leaderboard pattern over the percentage `Codemojex.Scoring` already computes; the score is the data, the ranked view over it is one sorted set away, and the rank is the order, never a stored field.

## Five patterns, one sorted set

Read back through the five moves and one structure stands behind all of them. The reminder scores by a run-at, the digest by a next-run, the deferral by a wait, the retry by a backoff delay, and the ranking by a percentage — five different numbers, one sorted set. The `ZADD` that writes the score, the range read that takes the due head, and the rank read are the same operations every time.

| Move | Set | The score means | The read |
|---|---|---|---|
| Reminder (R4.01) | `emq:{cm.notify}:schedule` | the run-at millisecond | `ZRANGEBYSCORE -inf now` (promote) |
| Digest (R4.02) | `emq:{cm.notify}:repeat` | the next run | `EXISTS` guard + `ZADD` register |
| Deferral (R4.03) | `emq:{cm.notify}:schedule` | now + the bucket's wait | the same promote sweep |
| Retry (R4.04) | `emq:{cm.notify}:schedule` | a backoff delay | the same promote sweep |
| Ranking (R4.05) | a ranking set | a player's percentage | `ZREVRANGE` / `ZREVRANK` |

The pattern lands twice — the chapter's five readings of one sorted set, and codemojex's notification worker assembling them on the real `emq:{q}:` keyspace: a run-at clock, a recurrence registry, a deferral fence, a retry timer, and a ranking. The structure never changes, only the meaning poured into the score.

## Where the durable floor takes over

Every job in this scenario is durable while it waits: a scheduled notice, a deferred send, a backed-off retry all sit on `emq:{cm.notify}:schedule` in Valkey, surviving a worker crash and returned by the `promote/3` sweep on recovery. Past the bus, the persistence floor takes the load that must outlive the volatile tiers: a notification archive or an audit of every notice sent is a fold from the bus into the durable page tier — `EchoStore`'s native engine on CubDB, replicated off-box to Tigris behind a create-only commit fence. Durability is a dial the system turns; the enqueue hot path touches only the bus, never a database on the path of every send.

The full schedule pump — the per-pool metronome, the promote/reap coordination across a consumer pool, the repeat sweep — is the subject of the dedicated EchoMQ course's Queue pillar. The archive and the durability dial are the subject of the persistence course.

## References

### Sources

- [Valkey — *ZADD*](https://valkey.io/commands/zadd/) — the single write behind every move: the run-at score, the next-run register, the deferral, the backoff fire-time, the ranking score.
- [Valkey — *ZRANGEBYSCORE*](https://valkey.io/commands/zrangebyscore/) — the due-range read inside the `@promote` Lua that returns the schedule head at or below the server clock.
- [Valkey — *Sorted sets*](https://valkey.io/topics/data-types/) — the one structure the scenario reads five ways: members ordered by a numeric score, the engine under EchoMQ.
- [Redis — *ZREVRANGE*](https://redis.io/commands/zrevrange/) — the top-N read the ranking digest carries, highest score first.
- [Redis — *Documentation*](https://redis.io/docs/) — sorted sets, ranges, and ranks — the command families the schedule set, repeat registry, and leaderboard are built from.
- [Answer.AI — *The /llms.txt convention*](https://llmstxt.org/) — the machine-readable map convention this course follows for agent readers.

### Related in this course

- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the reminder's and the retry's run-at schedule set.
- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the digest's repeat registry and its EXISTS-guarded register.
- [R4.03 · Priority with composite scores](/redis-patterns/time-delay-priority/priority-scores) — the contrast reading: a packed priority score, where codemojex uses fair lanes.
- [R4.04 · Backoff & retry](/redis-patterns/time-delay-priority/backoff-retry) — the failed send's backoff curve.
- [R4.05 · Leaderboards](/redis-patterns/time-delay-priority/leaderboards) — the ranking the digest carries.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter this workshop closes.
- [/echomq/queue](/echomq/queue) — the EchoMQ course: the schedule pump and the promote/reap coordination in depth.
- [/echo-persistence](/echo-persistence) — the durable floor a scheduled and archived notice reaches: the durability dial, the page tier, the remote.
