# retryJob-11  →  split across EchoMQ.Jobs.retry/7 (@retry, jobs.ex:593) + reprocess_job/3 (jobs.ex:912); a single active→pending-now lock-released requeue_active/4 is PROPOSED

> Feature: **retry** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   retryJob-11
--@feature   retry
--@status    PARTIAL
--@rung      emq.1/2.2 e0fa9b03/76fc947c
--@v1        registry/retryJob-11.lua   (KEYS arity 11)
--@v3        split across EchoMQ.Jobs.retry/7 (@retry, jobs.ex:593) + reprocess_job/3 (jobs.ex:912); a single active→pending-now lock-released requeue_active/4 is PROPOSED
```

## v1 source

`registry/retryJob-11.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Retries a failed job by moving it back to the wait queue.

    Input:
      KEYS[1]  'active',
      KEYS[2]  'wait'
      KEYS[3]  'paused'
      KEYS[4]  job key
      KEYS[5]  'meta'
      KEYS[6]  events stream
      KEYS[7]  delayed key
      KEYS[8]  prioritized key
      KEYS[9]  'pc' priority counter
      KEYS[10] 'marker'
      KEYS[11] 'stalled'

      ARGV[1]  key prefix
      ARGV[2]  timestamp
      ARGV[3]  pushCmd
      ARGV[4]  jobId
      ARGV[5]  token
      ARGV[6]  optional job fields to update

    Events:
      'waiting'

    Output:
     0  - OK
     -1 - Missing key
     -2 - Missing lock
     -3 - Job not in active set
]]
local rcall = redis.call

-- Includes
--- @include "includes/addJobInTargetList"
--- @include "includes/addJobWithPriority"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/getTargetQueueList"
--- @include "includes/isQueuePausedOrMaxed"
--- @include "includes/promoteDelayedJobs"
--- @include "includes/removeLock"
--- @include "includes/updateJobFields"

local target, isPausedOrMaxed = getTargetQueueList(KEYS[5], KEYS[1], KEYS[2], KEYS[3])
local markerKey = KEYS[10]

-- Check if there are delayed jobs that we can move to wait.
-- test example: when there are delayed jobs between retries
promoteDelayedJobs(KEYS[7], markerKey, target, KEYS[8], KEYS[6], ARGV[1], ARGV[2], KEYS[9], isPausedOrMaxed)

local jobKey = KEYS[4]

if rcall("EXISTS", jobKey) == 1 then
  local errorCode = removeLock(jobKey, KEYS[11], ARGV[5], ARGV[4]) 
  if errorCode < 0 then
    return errorCode
  end

  updateJobFields(jobKey, ARGV[6])

  local numRemovedElements = rcall("LREM", KEYS[1], -1, ARGV[4])
  if (numRemovedElements < 1) then return -3 end

  local priority = tonumber(rcall("HGET", jobKey, "priority")) or 0

  --need to re-evaluate after removing job from active
  isPausedOrMaxed = isQueuePausedOrMaxed(KEYS[5], KEYS[1])

  -- Standard or priority add
  if priority == 0 then
    addJobInTargetList(target, markerKey, ARGV[3], isPausedOrMaxed, ARGV[4])
  else
    addJobWithPriority(markerKey, KEYS[8], priority, ARGV[4], KEYS[9], isPausedOrMaxed)
  end

  rcall("HINCRBY", jobKey, "atm", 1)

  local maxEvents = getOrSetMaxEvents(KEYS[5])

  -- Emit waiting event
  rcall("XADD", KEYS[6], "MAXLEN", "~", maxEvents, "*", "event", "waiting",
    "jobId", ARGV[4], "prev", "active")

  return 0
else
  return -1
end
```

## v1 → v3 change ledger

| v1 (retryJob-11) | v3 (PARTIAL — split + requeue_active/4 PROPOSED) |
|---|---|
| KEYS active/wait/prioritized/lock/stalled | keys = [active, wait, job_key] -- all declared |
| removeLock(<jobKey>:lock, ARGV token) | -- :lock string fence → EMQSTALE attempts fence |
| -- DATA-VALUE token string | ZREM active <id> -- lease retired here |
| LREM active -1 jobId ; else -3 | ZADD/RPUSH dest <id> -- dest = pending \| lane |
| priority = HGET jobKey priority -- DATA arm | -- destination NOT chosen from a data-value priority |
| priority==0 ? wait : prioritized ; HINCRBY atm | -- prioritized arm RETIRED (§6); lane-aware instead |

## Aligned flow (authoritative side-by-side)

```text
v1 (retryJob-11)                                 v3 (PARTIAL — split + requeue_active/4 PROPOSED)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS active/wait/prioritized/lock/stalled        keys = [active, wait, job_key]   -- all declared
removeLock(<jobKey>:lock, ARGV token)            -- :lock string fence → EMQSTALE attempts fence
  -- DATA-VALUE token string                     ZREM active <id>                 -- lease retired here
LREM active -1 jobId  ; else -3                  ZADD/RPUSH dest <id>             -- dest = pending | lane
priority = HGET jobKey priority  -- DATA arm     -- destination NOT chosen from a data-value priority
priority==0 ? wait : prioritized ; HINCRBY atm   -- prioritized arm RETIRED (§6); lane-aware instead
```

## Decision & rationale

**Covers → v3.** Move a failed job from `active` back to `wait`/`prioritized` immediately, releasing its lock → the two as-built halves cover the worker-driven retry-with-backoff (`@retry`) and the operator dead→pending reprocess (`@reprocess`), but there is **no** single "active→pending now, lock-released" operator kick (grep-confirmed); add `requeue_active/4`.

**Decision.** Re-derive the v1 effect under braces as a declared-keys `requeue_active/4` (`active`→`pending`, lane-aware): no data-value lock token (the `attempts`-token `EMQSTALE` fence instead), the lease retired by the `ZREM active`, the destination `pending` (or the grouped id's lane). The v1 `prioritized` arm does not return (retired, §6). *(Prose until the rung authors it.)*

**BCS** the operator "kick a stuck claim back to the front" control for a scoring/settlement lane. · **EchoMesh** consistency-first (CP-side) operator action — manual, audited, single-writer-serialized, not an availability path. · **[when]** an operator kicking a stuck claim back to the front of a scoring/settlement lane.
