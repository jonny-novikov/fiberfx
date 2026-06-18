# moveStalledJobsToWait-8  →  EchoMQ.Stalled.check/3 (@sweep_stalled)

> Feature: **claim** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   moveStalledJobsToWait-8
--@feature   claim
--@status    SHIPPED (ported)
--@rung      emq.2.3
--@v1        registry/moveStalledJobsToWait-8.lua   (KEYS arity 8)
--@v3        EchoMQ.Stalled.check/3 (@sweep_stalled)
```

## v1 source

`registry/moveStalledJobsToWait-8.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Move stalled jobs to wait.

    Input:
      KEYS[1] 'stalled' (SET)
      KEYS[2] 'wait',   (LIST)
      KEYS[3] 'active', (LIST)
      KEYS[4] 'stalled-check', (KEY)
      KEYS[5] 'meta', (KEY)
      KEYS[6] 'paused', (LIST)
      KEYS[7] 'marker'
      KEYS[8] 'event stream' (STREAM)

      ARGV[1]  Max stalled job count
      ARGV[2]  queue.toKey('')
      ARGV[3]  timestamp
      ARGV[4]  max check time

    Events:
      'stalled' with stalled job id.
]]
local rcall = redis.call

-- Includes
--- @include "includes/addJobInTargetList"
--- @include "includes/batches"
--- @include "includes/moveJobToWait"
--- @include "includes/trimEvents"

local stalledKey = KEYS[1]
local waitKey = KEYS[2]
local activeKey = KEYS[3]
local stalledCheckKey = KEYS[4]
local metaKey = KEYS[5]
local pausedKey = KEYS[6]
local markerKey = KEYS[7]
local eventStreamKey = KEYS[8]
local maxStalledJobCount = tonumber(ARGV[1])
local queueKeyPrefix = ARGV[2]
local timestamp = ARGV[3]
local maxCheckTime = ARGV[4]

if rcall("EXISTS", stalledCheckKey) == 1 then
    return {}
end

rcall("SET", stalledCheckKey, timestamp, "PX", maxCheckTime)

-- Trim events before emiting them to avoid trimming events emitted in this script
trimEvents(metaKey, eventStreamKey)

-- Move all stalled jobs to wait
local stalling = rcall('SMEMBERS', stalledKey)
local stalled = {}
if (#stalling > 0) then
    rcall('DEL', stalledKey)

    -- Remove from active list
    for i, jobId in ipairs(stalling) do
        -- Markers in waitlist DEPRECATED in v5: Remove in v6.
        if string.sub(jobId, 1, 2) == "0:" then
            -- If the jobId is a delay marker ID we just remove it.
            rcall("LREM", activeKey, 1, jobId)
        else
            local jobKey = queueKeyPrefix .. jobId

            -- Check that the lock is also missing, then we can handle this job as really stalled.
            if (rcall("EXISTS", jobKey .. ":lock") == 0) then
                --  Remove from the active queue.
                local removed = rcall("LREM", activeKey, 1, jobId)

                if (removed > 0) then
                    -- If this job has been stalled too many times, such as if it crashes the worker, then fail it.
                    local stalledCount = rcall("HINCRBY", jobKey, "stc", 1)
                    
                    -- Check if this is a repeatable job by looking at job options
                    local jobOpts = rcall("HGET", jobKey, "opts")
                    local isRepeatableJob = false
                    if jobOpts then
                        local opts = cjson.decode(jobOpts)
                        if opts and opts["repeat"] then
                            isRepeatableJob = true
                        end
                    end
                    
                    -- Only fail job if it exceeds stall limit AND is not a repeatable job
                    if stalledCount > maxStalledJobCount and not isRepeatableJob then
                        local failedReason = "job stalled more than allowable limit"
                        rcall("HSET", jobKey, "defa", failedReason)
                    end
                    
                    moveJobToWait(metaKey, activeKey, waitKey, pausedKey, markerKey, eventStreamKey, jobId,
                        "RPUSH")

                    -- Emit the stalled event
                    rcall("XADD", eventStreamKey, "*", "event", "stalled", "jobId", jobId)
                    table.insert(stalled, jobId)
                end
            end
        end
    end
end

-- Mark potentially stalled jobs
local active = rcall('LRANGE', activeKey, 0, -1)

if (#active > 0) then
    for from, to in batches(#active, 7000) do
        rcall('SADD', stalledKey, unpack(active, from, to))
    end
end

return stalled
```

## v1 → v3 change ledger

| v1 (moveStalledJobsToWait-8) | v3 (SHIPPED — EchoMQ.Stalled.check/3) |
|---|---|
| KEYS stalled SET, wait, active, stalled-check | keys = [active, pending, dead] ; ARGV base/max/limit |
| EXISTS stalled-check -> {} ; SMEMBERS stalled | exp = ZRANGEBYSCORE active -inf now -- one server-clock scan |
| jobKey = ARGV[2] .. jobId -- DATA-rooted | for id in exp: ZREM active id ; st = HINCRBY jk stalled 1 |
| EXISTS <jobKey>:lock == 0 -- :lock absence | st >= max -> HSET state dead, last_error 'stalled', ZADD dead |
| HINCRBY stc ; stc>max & !repeat -> HSET defa | else -> ZADD pending 0 id (grouped id -> its lane) |
| SADD still-active -> stalled -- the 2nd scan | return {recovered, dead} -- v1 'stc' -> row field, no new key |

## Aligned flow (authoritative side-by-side)

```text
v1 (moveStalledJobsToWait-8)                     v3 (SHIPPED — EchoMQ.Stalled.check/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS stalled SET, wait, active, stalled-check    keys = [active, pending, dead] ; ARGV base/max/limit
EXISTS stalled-check -> {} ; SMEMBERS stalled    exp = ZRANGEBYSCORE active -inf now  -- one server-clock scan
jobKey = ARGV[2] .. jobId      -- DATA-rooted      for id in exp: ZREM active id ; st = HINCRBY jk stalled 1
EXISTS <jobKey>:lock == 0      -- :lock absence    st >= max -> HSET state dead, last_error 'stalled', ZADD dead
  HINCRBY stc ; stc>max & !repeat -> HSET defa     else -> ZADD pending 0 id  (grouped id -> its lane)
SADD still-active -> stalled    -- the 2nd scan    return {recovered, dead}  -- v1 'stc' -> row field, no new key
```

## Decision & rationale

**Covers → v3.** The periodic stalled-recovery sweep that reclaims jobs whose worker died holding them → `ZRANGEBYSCORE active -inf <TIME>` takes genuinely expired-lease members on the server clock, recovers below `max_stalled` and dead-letters at/above it; the v1 two-scan "mark, then sweep next time" model collapses to one lease scan.

**Decision.** The as-built `@sweep_stalled` is already the v3 form — the `active`-set deadline IS the staleness fact, so no separate `stalled` candidate SET and no `:lock` probe; declared `[active, pending, dead]` (never the v1 9-key LIST shape), `stc`→the row's `stalled` field, run as an opt-in `:transient` timer above the single-scan `reap/2` (renamed `EchoMQ.Stalled`, not `StalledChecker`, to avoid shadowing the frozen v1 module — emq.2.3 ledger L-1). **PROPOSED**: the v1 repeatable-job dead-letter exemption as a forward additive arm (a per-row policy field gating the dead-letter branch); the as-built sweep currently always dead-letters past `max_stalled`.

**BCS** the crash-recovery safety net for the single-writer model — a dead decider's in-flight leases return to its instrument's queue, and a poison job dead-letters instead of looping the fleet. · **EchoMesh** consistency-first recovery — fold-to-state / restart-to-known-state (Armstrong) made operational, the server-clock lease the only liveness fact the mesh needs. · **[when]** a dead decider's in-flight leases recovering on a survivor; a poison job dead-lettering instead of looping the fleet.
