# moveToDelayed-8  →  EchoMQ.Jobs.retry/7 non-terminal arm (@retry, jobs.ex)

> Feature: **retry** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   moveToDelayed-8
--@feature   retry
--@status    SHIPPED (ported as retry-reschedule)
--@rung      emq.1
--@v1        registry/moveToDelayed-8.lua   (KEYS arity 8)
--@v3        EchoMQ.Jobs.retry/7 non-terminal arm (@retry, jobs.ex)
```

## v1 source

`registry/moveToDelayed-8.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Moves job from active to delayed set.

  Input:
    KEYS[1] marker key
    KEYS[2] active key
    KEYS[3] prioritized key
    KEYS[4] delayed key
    KEYS[5] job key
    KEYS[6] events stream
    KEYS[7] meta key
    KEYS[8] stalled key

    ARGV[1] key prefix
    ARGV[2] timestamp
    ARGV[3] the id of the job
    ARGV[4] queue token
    ARGV[5] delay value
    ARGV[6] skip attempt
    ARGV[7] optional job fields to update

  Output:
    0 - OK
   -1 - Missing job.
   -3 - Job not in active set.

  Events:
    - delayed key.
]]
local rcall = redis.call

-- Includes
--- @include "includes/addDelayMarkerIfNeeded"
--- @include "includes/getDelayedScore"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/removeLock"
--- @include "includes/updateJobFields"

local jobKey = KEYS[5]
local metaKey = KEYS[7]
local token = ARGV[4] 
if rcall("EXISTS", jobKey) == 1 then
    local errorCode = removeLock(jobKey, KEYS[8], token, ARGV[3])
    if errorCode < 0 then
        return errorCode
    end

    updateJobFields(jobKey, ARGV[7])
    
    local delayedKey = KEYS[4]
    local jobId = ARGV[3]
    local delay = tonumber(ARGV[5])

    local numRemovedElements = rcall("LREM", KEYS[2], -1, jobId)
    if numRemovedElements < 1 then return -3 end

    local score, delayedTimestamp = getDelayedScore(delayedKey, ARGV[2], delay)

    if ARGV[6] == "0" then
        rcall("HINCRBY", jobKey, "atm", 1)
    end

    rcall("HSET", jobKey, "delay", ARGV[5])

    local maxEvents = getOrSetMaxEvents(metaKey)

    rcall("ZADD", delayedKey, score, jobId)
    rcall("XADD", KEYS[6], "MAXLEN", "~", maxEvents, "*", "event", "delayed",
          "jobId", jobId, "delay", delayedTimestamp)

    -- Check if we need to push a marker job to wake up sleeping workers.
    local markerKey = KEYS[1]
    addDelayMarkerIfNeeded(markerKey, delayedKey)

    return 0
else
    return -1
end
```

## v1 → v3 change ledger

| v1 (moveToDelayed-8) | v3 (SHIPPED — non-terminal arm of @retry) |
|---|---|
| KEYS[5]=job key (declared — closer to liftable) | keys = [active, schedule, dead, job_key] |
| removeLock(jobKey, stalled, token) -- :lock fnc | t = TIME ; now = t[1]*1000 + t[2]/1000 -- SERVER clock |
| LREM active -1 jobId ; else -3 | HSET job_key state scheduled |
| score = getDelayedScore(ts, delay) -- (ts+delay | ) ZADD schedule now+tonumber(ARGV[3]) id |
| << 12, CLIENT clock, packed-order tie-break | -- plain run-at, no 0x1000 bit-stuffing |
| HINCRBY atm 1 ; ZADD delayed score jobId | return 'scheduled' -- delayed+scheduled collapse to one zset |

## Aligned flow (authoritative side-by-side)

```text
v1 (moveToDelayed-8)                             v3 (SHIPPED — non-terminal arm of @retry)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[5]=job key (declared — closer to liftable)  keys = [active, schedule, dead, job_key]
removeLock(jobKey, stalled, token)  -- :lock fnc  t = TIME ; now = t[1]*1000 + t[2]/1000   -- SERVER clock
LREM active -1 jobId  ; else -3                   HSET job_key state scheduled
score = getDelayedScore(ts, delay)  -- (ts+delay) ZADD schedule now+tonumber(ARGV[3]) id
  << 12, CLIENT clock, packed-order tie-break       -- plain run-at, no 0x1000 bit-stuffing
HINCRBY atm 1 ; ZADD delayed score jobId          return 'scheduled'   -- delayed+scheduled collapse to one zset
```

## Decision & rationale

**Covers → v3.** Move a locked active job back to the delayed set (the retry/backoff path) → the **non-terminal arm of `@retry`**: below max-attempts it reads server `TIME`, sets `state=scheduled`, and `ZADD now+delay id` on the one `schedule` set (no separate `delayed`); the host `EchoMQ.Backoff.delay_ms/2` computes the delay literal (fixed/exponential/jitter). `emq.features.md` Part B.2 binds `moveToDelayed-8.lua` → `@retry` (✅).

**Decision.** Retain `@retry`'s scheduled arm as the canonical active→scheduled transition; the v1 `0x1000`-baked composite score is **superseded** by the plain server-clock `now+delay` (`TIME` inside the transition is the ratified DQ-2c law; the order theorem already orders by mint). **PROPOSED**: if a non-failure host-initiated defer is ever needed (distinct from a retry), a thin `defer/…` routing the same `ZADD schedule now+delay` over declared `[active, schedule]`, attempts untouched — additive, no new score scheme.

**BCS** backoff-driven retry of settlement/notification jobs; the visibility-fence reschedule. · **EchoMesh** consistency-first — the schedule set is single-slot, server-clock-scored; no cross-node timing trust. · **[when]** a backoff-driven retry of a settlement/notification job — the visibility-fence reschedule.
