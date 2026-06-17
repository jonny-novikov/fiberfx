# drain-5  →  EchoMQ.Admin.drain/3 (@drain, admin.ex:109)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   drain-5
--@feature   lifecycle
--@status    SHIPPED (ported)
--@rung      emq.2.2 76fc947c
--@v1        registry/drain-5.lua   (KEYS arity 5)
--@v3        EchoMQ.Admin.drain/3 (@drain, admin.ex:109)
```

## v1 source

`registry/drain-5.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Drains the queue, removes all jobs that are waiting
  or delayed, but not active, completed or failed

  Input:
    KEYS[1] 'wait',
    KEYS[2] 'paused'
    KEYS[3] 'delayed'
    KEYS[4] 'prioritized'
    KEYS[5] 'jobschedulers' (repeat)

    ARGV[1]  queue key prefix
    ARGV[2]  should clean delayed jobs
]]
local rcall = redis.call
local queueBaseKey = ARGV[1]

--- @include "includes/removeListJobs"
--- @include "includes/removeZSetJobs"

-- We must not remove delayed jobs if they are associated to a job scheduler.
local scheduledJobs = {}
local jobSchedulers = rcall("ZRANGE", KEYS[5], 0, -1, "WITHSCORES")

-- For every job scheduler, get the current delayed job id.
for i = 1, #jobSchedulers, 2 do
    local jobSchedulerId = jobSchedulers[i]
    local jobSchedulerMillis = jobSchedulers[i + 1]

    local delayedJobId = "repeat:" .. jobSchedulerId .. ":" .. jobSchedulerMillis
    scheduledJobs[delayedJobId] = true
end

removeListJobs(KEYS[1], true, queueBaseKey, 0, scheduledJobs) -- wait
removeListJobs(KEYS[2], true, queueBaseKey, 0, scheduledJobs) -- paused

if ARGV[2] == "1" then
  removeZSetJobs(KEYS[3], true, queueBaseKey, 0, scheduledJobs) -- delayed
end

removeZSetJobs(KEYS[4], true, queueBaseKey, 0, scheduledJobs) -- prioritized
```

## v1 → v3 change ledger

| v1 (drain-5) | v3 (SHIPPED — EchoMQ.Admin.@drain) |
|---|---|
| KEYS wait,paused,delayed,prioritized,jobsched. | keys = [base 'emq:{q}:', pending, schedule?] |
| ZRANGE jobschedulers WITHSCORES | -- v1 four-set zoo collapses (no wait/paused/prioritized) |
| delayedJobId = "repeat:"..id..":"..millis | for id in ZRANGE setkey: jk = base..'job:'..id |
| -- DATA-derived skip-set id | DEL jk, jk..':logs' -- grammar-rooted (A-1-clean) |
| removeListJobs(wait) ; removeListJobs(paused) | DEL setkey |
| removeZSetJobs(delayed) ; removeZSetJobs(prio.) | -- scheduler-skip = the repeat REGISTRY surviving (D-4) |
| -- removeJob -> HMGET jobKey parentKey (A-1 ✗) | -- active untouched |

## Aligned flow (authoritative side-by-side)

```text
v1 (drain-5)                                     v3 (SHIPPED — EchoMQ.Admin.@drain)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS wait,paused,delayed,prioritized,jobsched.   keys = [base 'emq:{q}:', pending, schedule?]
ZRANGE jobschedulers WITHSCORES                  -- v1 four-set zoo collapses (no wait/paused/prioritized)
  delayedJobId = "repeat:"..id..":"..millis      for id in ZRANGE setkey: jk = base..'job:'..id
    -- DATA-derived skip-set id                    DEL jk, jk..':logs'        -- grammar-rooted (A-1-clean)
removeListJobs(wait) ; removeListJobs(paused)    DEL setkey
removeZSetJobs(delayed) ; removeZSetJobs(prio.)  -- scheduler-skip = the repeat REGISTRY surviving (D-4)
-- removeJob -> HMGET jobKey parentKey  (A-1 ✗)  -- active untouched
```

## Decision & rationale

**Covers → v3.** Empty pending(+ optional delayed), skipping scheduler-owned, leaving active → `KEYS[1]` = the declared queue base root (every job key derives from it, no `parentKey` read), `KEYS[2]` = pending, optional `KEYS[3]` = schedule.

**Decision.** Already the state-of-the-art form; the v1 scheduler-skip re-derives as the repeat registry surviving (D-4 — drain cancels no registered repeatable); `active` untouched. No v3 delta beyond the as-built.

**BCS** clearing a venue's pending settlement/notification backlog during an incident without killing in-flight active jobs. · **EchoMesh** consistency-side — single-slot wipe, partition-local. · **[when]** clearing a venue's pending backlog without killing active jobs.
