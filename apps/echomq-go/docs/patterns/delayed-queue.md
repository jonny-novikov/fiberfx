# Delayed Queue

Schedule work for future execution using a Sorted Set where the score is the Unix timestamp at which the task should run and the member is the task identifier or payload. `ZRANGEBYSCORE -inf <now>` polls due tasks; `ZREM` atomically claims a task to prevent duplicate processing. Combine with Lua for atomic poll-and-claim. FTR-009 uses this shape for staleness L2 escalation debounce; echomq-go uses it for BullMQ's delayed-job promotion.

**Primary use-case axis:** A — supervisor/worker messaging (scheduled retries + debounce + batched ops).
**Secondary axes:** B (deferred operator notifications, future). Explicitly N/A on axes C + D per [`adr-001-pattern-taxonomy.md` §3](../architecture/adr-001-pattern-taxonomy.md).

## Primitive

Sorted Sets with timestamp scores.

Core commands:

- `ZADD <key> <score> <member>` — schedule. `<score>` is the unix timestamp (seconds, ms, or BullMQ's composite `ts * 0x1000 + priority` encoding). Per [`mercury delayed-queue.md §Data Model`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt).
- `ZRANGEBYSCORE <key> -inf <now> [LIMIT 0 N]` — poll for due tasks; returns members with score ≤ now. Per [`mercury delayed-queue.md §Polling for Ready Tasks`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt).
- `ZREM <key> <member>` — atomic claim. Returns 1 if the caller successfully removed the entry, 0 if another worker claimed it first. Per [`mercury delayed-queue.md §Claiming Tasks Atomically`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt), only proceed with processing if ZREM returned 1.
- `ZRANGE <key> 0 0 WITHSCORES` — peek at earliest task; if no tasks are due, sleep until its score to avoid busy-waiting. Per [`mercury delayed-queue.md §Avoiding Busy Waiting`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt).
- Combined poll-and-claim via Lua: atomic `ZRANGEBYSCORE` + loop `ZREM` inside a single script. Per [`mercury delayed-queue.md §Combining with Lua`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt).
- `ZADD <key> <new-score> <member>` — reschedule on retry; updates the score if the member already exists. Per [`mercury delayed-queue.md §Retry with Backoff`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt).

Semantics: tasks persist in Redis until claimed via ZREM; the ZSET is naturally sorted for efficient range queries. Multiple workers can poll concurrently — the atomic ZREM serializes claims per task.

## Rose Tree + FTR-009 Application

Two FTR-009 uses:

**1. Staleness L2 escalation debounce.** `cclin:stale:level2` ZSET keys agents by unix-ms score of L2-threshold crossing. The Pluto supervise cron reads this with `ZRANGEBYSCORE` to find escalation candidates and files B-NNN blockers on the active-at-escalation subset. Resume clears the entry with `ZREM`. See [FTR-009 `staleness-policy.md` §5](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) + [FTR-009 `mailbox-keyspace.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).

Two sibling ZSETs:

- `cclin:stale:level1` — L1-crossed mailboxes; same pattern, indefinite retention (cleaned on Transition-6 resume).
- `cclin:stale:reaped` — audit trail of reap events; 24-hour retention via `ZREMRANGEBYSCORE` daily cleanup.

**2. Remediation retry scheduling (implicit).** The Mars-Apollo remediation loop (see `~/.claude/projects/-Users-jonny-dev-fireheadz/memory/feedback_remediation_loop_clause.md`) uses scheduled re-dispatches of Mars to address Apollo's feedback. A future FTR adopting this canonical pattern would schedule retries via a `cclin:remediation:pending` ZSET keyed by unix-ms of next-attempt.

FTR-009 does NOT use this pattern for mailbox delivery itself — mailbox messages use Streams + consumer groups (see [`streams-consumer-groups.md`](streams-consumer-groups.md)), which already handle retry via XAUTOCLAIM. Delayed-queue is the right shape only when delivery is time-triggered (not event-triggered).

## echomq-go code anchor

EchoMQ implements the BullMQ delayed-job pattern — the canonical reference for this shape in the repo:

- Delayed ZSET key builder (cluster-safe via hash tags): [`../../pkg/echomq/keys.go:58-63`](../../pkg/echomq/keys.go) — `Delayed()` returns `bull:<queue>:delayed` or `bull:{<queue>}:delayed`.
- Delayed-job insertion on producer side: [`../../pkg/echomq/queue_impl.go:108-117`](../../pkg/echomq/queue_impl.go):
  ```go
  if job.Delay > 0 {
      delayedTimestamp := job.Timestamp + job.Delay
      return q.redisClient.ZAdd(ctx, q.keyBuilder.Delayed(), redis.Z{
          Score:  float64(delayedTimestamp),
          Member: job.ID,
      }).Err()
  }
  ```
  Scheduled execution timestamp = creation timestamp + delay offset.
- Atomic poll-and-promote via Lua inside `MoveToActive`: [`../../pkg/echomq/scripts/scripts.go:187-215`](../../pkg/echomq/scripts/scripts.go) — the `promoteDelayedJobs` Lua function:
  ```lua
  local function promoteDelayedJobs(delayedKey, markerKey, targetKey, prioritizedKey,
      eventStreamKey, prefix, timestamp)
    local jobs = rcall("ZRANGEBYSCORE", delayedKey, 0,
                       (timestamp + 1) * 0x1000 - 1, "LIMIT", 0, 1000)
    if #jobs > 0 then
      rcall("ZREM", delayedKey, unpack(jobs))
      -- ... promote to wait or prioritized queue ...
      rcall("XADD", eventStreamKey, "*", "event", "waiting", "jobId", jobId,
            "prev", "delayed")
    end
  end
  ```
  The composite score format (`timestamp * 0x1000 + priority`) embeds priority in the ZSET score to preserve priority-ordering within the same time bucket. `(timestamp + 1) * 0x1000 - 1` computes the upper bound for "all jobs due at or before this timestamp".
- Next-delayed-timestamp peek for busy-wait avoidance: [`../../pkg/echomq/scripts/scripts.go:52-60, 358-366`](../../pkg/echomq/scripts/scripts.go) — `getNextDelayedTimestamp` runs `ZRANGE delayedKey 0 0 WITHSCORES` and returns the earliest timestamp so the worker can sleep precisely.
- Retry-with-backoff on job failure: [`../../pkg/echomq/scripts/scripts.go:1102-1308`](../../pkg/echomq/scripts/scripts.go) — `RetryJob` Lua script ZADDs the failed job back into `delayed` with a new timestamp computed from the backoff config (`exponential` or `fixed`).
- Worker loop triggers delayed promotion on every pickup: [`../../pkg/echomq/worker_impl.go:112`](../../pkg/echomq/worker_impl.go) — `moveToActiveScript.Run` includes the `promoteDelayedJobs` call before attempting to pop the next job.

EchoMQ's delayed-queue is cluster-safe (all keys share slot via `{<queue>}`) and exactly-once per delayed entry (ZREM is atomic).

## Antipatterns avoided

**1. ZRANGEBYSCORE without ZREM = duplicate processing.** A worker that polls with `ZRANGEBYSCORE` and then processes without atomically removing the entry races with concurrent pollers. Per [`mercury delayed-queue.md §Claiming Tasks Atomically`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt), the correct shape is: poll → attempt ZREM → only proceed on ZREM=1.

**2. Busy-polling an empty delayed queue.** A worker that polls every 100ms against an empty ZSET wastes CPU. Per [`mercury delayed-queue.md §Avoiding Busy Waiting`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt), peek at `ZRANGE key 0 0 WITHSCORES`; if empty or score is in the future, sleep until that timestamp (capped at a max to pick up new insertions). echomq-go's `MoveToActive` uses the `getNextDelayedTimestamp` helper to return the next wake time to the Go caller.

**3. Placing delayed + target queues in different slots (cluster mode).** The promotion Lua script needs atomic access to both `delayed` and `wait`/`prioritized` keys — cluster mode requires shared slot via hash tag. Per [`hash-tag-colocation.md`](hash-tag-colocation.md), wrap the queue name: `bull:{queue}:delayed` + `bull:{queue}:wait` co-locate.

**4. Composite score collision.** Two entries ZADDed with identical scores receive lexicographic ordering by member — a pitfall if member format is not monotonic. echomq-go's composite `timestamp * 0x1000 + priority` packs priority into the score's low bits so concurrent same-timestamp insertions still order by priority; jobs with identical timestamp + priority fall through to member-lexicographic ordering (job UUIDs), which is acceptable for FIFO ties.

**5. Unbounded ZSET growth.** A delayed-queue ZSET without claim-rate-matching-insertion-rate grows without bound. Per [`mercury delayed-queue.md §Use Cases`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt) implicitly, monitor ZSET cardinality + apply `ZREMRANGEBYSCORE` with stale-threshold for cases where unclaimable entries can accumulate. FTR-009's `cclin:stale:reaped` explicitly applies 24-hour ZREMRANGEBYSCORE.

## Cross-references

FTR consumers:

- [FTR-009 `staleness-policy.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) — L1/L2 ZSETs for stale-state debounce + reap audit
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — `cclin:stale:level{1,2,reaped}` keyspace registry
- [FTR-009 `teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) — transitions 5 (→ stale) / 6 (resume) / 9 (idle stale) / 10 (auto-reap) touch the ZSETs
- FTR-010 (future) — HITL deferred notifications may use this pattern

Sibling patterns:

- [`atomic-updates.md`](atomic-updates.md) — ZREM is a mini-atomic-claim; Lua for atomic poll-and-claim-batch
- [`reliable-queue.md`](reliable-queue.md) — complements delayed-queue: "what" (reliable-queue) + "when" (delayed-queue)
- [`streams-consumer-groups.md`](streams-consumer-groups.md) — the event-triggered substrate; delayed-queue is time-triggered
- [`hash-tag-colocation.md`](hash-tag-colocation.md) — required for cluster-mode promote-to-wait Lua
- [`streams-event-sourcing.md`](streams-event-sourcing.md) — promotion emits an event on state change (`prev delayed` → `waiting`)

Mercury-design source:

- [`fundamental/delayed-queue.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/delayed-queue.md.txt) — canonical primitive reference

## Worked example

Basic schedule + poll + claim:

```bash
# Schedule a task for 5 minutes from now (score = unix-ts-ms)
ZADD delayed_tasks 1714000300000 "task:email-abc"

# Separate task detail in a Hash
HSET task:email-abc type send_email recipient user@example.com

# Poll for ready tasks (up to 10)
ZRANGEBYSCORE delayed_tasks -inf 1714000310000 LIMIT 0 10
# 1) "task:email-abc"

# Atomic claim — only one worker succeeds per task
ZREM delayed_tasks "task:email-abc"
# (integer) 1  → this worker claimed it; proceed to process
# (integer) 0  → another worker claimed it first; skip

# Process the task (application logic reads task:email-abc hash)
HGETALL task:email-abc
# ... process ...
DEL task:email-abc  # cleanup task detail

# Retry on failure — reschedule 60 seconds later
ZADD delayed_tasks 1714000370000 "task:email-abc"
```

Avoiding busy waiting — peek next due time:

```bash
# Get earliest scheduled task
ZRANGE delayed_tasks 0 0 WITHSCORES
# 1) "task:email-def"
# 2) "1714000450000"

# If score is in future, sleep until then (capped at max-poll-interval)
# - now_ms = 1714000310000
# - next_ms = 1714000450000
# - sleep for min(next_ms - now_ms, 5000) = 5 seconds, then peek again
```

Atomic poll-and-claim via Lua (preferred for high-contention scenarios):

```bash
EVAL "
  local tasks = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', 0, ARGV[2])
  for i, task in ipairs(tasks) do
    redis.call('ZREM', KEYS[1], task)
  end
  return tasks
" 1 delayed_tasks 1714000310000 10
# Returns the claimed tasks; ZREM happens atomically inside the script
```

FTR-009 staleness L2 debounce (the canonical FTR-009 use):

```bash
# Pluto supervise cron detects an agent crossed L2 threshold (heartbeat > 2h)
ZADD cclin:stale:level2 1714000300000 "flyer-a1:mars-3"

# Cron pass — find all current L2-crossed agents
ZRANGEBYSCORE cclin:stale:level2 -inf 1714000310000
# 1) "flyer-a1:mars-3"
# 2) "flyer-a1:venus-2"

# For each, check prior state: if active, file B-NNN via Pluto
# (pseudocode — see FTR-009 staleness-policy.md §5 for Go implementation)

# On resume (heartbeat refreshed), clear the debounce entry
ZREM cclin:stale:level2 "flyer-a1:mars-3"

# Audit trail of reaps — 24h retention
ZADD cclin:stale:reaped 1714000500 "flyer-a1:mars-3"
# Daily cleanup cron
ZREMRANGEBYSCORE cclin:stale:reaped 0 1713913900  # delete entries older than 24h
```

echomq-go delayed-job promotion (the BullMQ scheduling shape; composite score):

```bash
# Producer schedules a job with 30-second delay
ZADD bull:{myqueue}:delayed 1714000330000 "job-abc"
# Score encodes both timestamp and priority: timestamp * 0x1000 + priority

# Worker picks up — MoveToActive Lua runs promoteDelayedJobs as a first step
# Pseudocode derived from scripts.go:187-215:
promoteDelayedJobs(
    "bull:{myqueue}:delayed",      # delayed ZSET
    "bull:{myqueue}:marker",        # marker key
    "bull:{myqueue}:wait",          # target wait list
    "bull:{myqueue}:prioritized",   # target prioritized ZSET
    "bull:{myqueue}:events",        # emit "prev=delayed → waiting" event
    "bull:{myqueue}:",              # key prefix
    current_timestamp_ms
)
# 1. ZRANGEBYSCORE bull:{myqueue}:delayed 0 <upper-bound> LIMIT 0 1000
# 2. For each due job: ZREM, then LPUSH/ZADD to wait/prioritized, XADD event
```

Go-side producer (mirrors [`../../pkg/echomq/queue_impl.go:108-117`](../../pkg/echomq/queue_impl.go)):

```go
if job.Delay > 0 {
    delayedTimestamp := job.Timestamp + job.Delay  // unix-ms
    return q.redisClient.ZAdd(ctx, q.keyBuilder.Delayed(), redis.Z{
        Score:  float64(delayedTimestamp),
        Member: job.ID,
    }).Err()
}
```

Go-side polling with peek-ahead (for custom delayed-queue outside BullMQ):

```go
for {
    // Peek earliest
    peek, err := client.ZRangeWithScores(ctx, "delayed_tasks", 0, 0).Result()
    if err != nil || len(peek) == 0 {
        time.Sleep(5 * time.Second) // idle poll cap
        continue
    }
    due := time.UnixMilli(int64(peek[0].Score))
    if wait := time.Until(due); wait > 0 {
        time.Sleep(minDuration(wait, 5*time.Second))
        continue
    }
    // Atomic claim
    removed, err := client.ZRem(ctx, "delayed_tasks", peek[0].Member).Result()
    if err != nil || removed == 0 {
        continue // lost race
    }
    // process(peek[0].Member.(string))
}
```
