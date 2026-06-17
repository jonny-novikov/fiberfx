# moveJobsToWait-8  →  single-job EchoMQ.Jobs.reprocess_job/3 (jobs.ex:912) + EchoMQ.Jobs.promote/3 (jobs.ex:644) exist; a bulk requeue_set(state, count) is PROPOSED

> Feature: **batches** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   moveJobsToWait-8
--@feature   batches
--@status    PARTIAL
--@rung      emq.2.2
--@v1        registry/moveJobsToWait-8.lua   (KEYS arity 8)
--@v3        single-job EchoMQ.Jobs.reprocess_job/3 (jobs.ex:912) + EchoMQ.Jobs.promote/3 (jobs.ex:644) exist; a bulk requeue_set(state, count) is PROPOSED
```

## v1 source

`registry/moveJobsToWait-8.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Move completed, failed or delayed jobs to wait.

  Note: Does not support jobs with priorities.

  Input:
    KEYS[1] base key
    KEYS[2] events stream
    KEYS[3] state key (failed, completed, delayed)
    KEYS[4] 'wait'
    KEYS[5] 'paused'
    KEYS[6] 'meta'
    KEYS[7] 'active'
    KEYS[8] 'marker'

    ARGV[1] count
    ARGV[2] timestamp
    ARGV[3] prev state

  Output:
    1  means the operation is not completed
    0  means the operation is completed
]]
local maxCount = tonumber(ARGV[1])
local timestamp = tonumber(ARGV[2])

local rcall = redis.call;

-- Includes
--- @include "includes/addBaseMarkerIfNeeded"
--- @include "includes/batches"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/getTargetQueueList"

local metaKey = KEYS[6]
local target, isPausedOrMaxed = getTargetQueueList(metaKey, KEYS[7], KEYS[4], KEYS[5])

local jobs = rcall('ZRANGEBYSCORE', KEYS[3], 0, timestamp, 'LIMIT', 0, maxCount)
if (#jobs > 0) then

    if ARGV[3] == "failed" then
        for i, key in ipairs(jobs) do
            local jobKey = KEYS[1] .. key
            rcall("HDEL", jobKey, "finishedOn", "processedOn", "failedReason")
        end
    elseif ARGV[3] == "completed" then
        for i, key in ipairs(jobs) do
            local jobKey = KEYS[1] .. key
            rcall("HDEL", jobKey, "finishedOn", "processedOn", "returnvalue")
        end
    end

    local maxEvents = getOrSetMaxEvents(metaKey)

    for i, key in ipairs(jobs) do
        -- Emit waiting event
        rcall("XADD", KEYS[2], "MAXLEN", "~", maxEvents, "*", "event",
              "waiting", "jobId", key, "prev", ARGV[3]);
    end

    for from, to in batches(#jobs, 7000) do
        rcall("ZREM", KEYS[3], unpack(jobs, from, to))
        rcall("LPUSH", target, unpack(jobs, from, to))
    end

    addBaseMarkerIfNeeded(KEYS[8], isPausedOrMaxed)
end

maxCount = maxCount - #jobs

if (maxCount <= 0) then return 1 end

return 0
```

## v1 → v3 change ledger

| v1 (moveJobsToWait-8) | v3 (PROPOSED — requeue_set(state, count)) |
|---|---|
| KEYS[1..8] base, events, stateKey, wait, ... | declares [source_set, pending, queue_base] |
| ZRANGEBYSCORE stateKey 0 ts LIMIT 0 count | source = schedule \| dead -- completed is GONE (completion-deletes) |
| HDEL KEYS[1]..jobId finishedOn/... -- DATA-id | HDEL ARGV[base].."job:"..id … -- grammar-derived (A-1), not KEYS[1]..member |
| batches(#jobs,7000): ZREM stateKey ; LPUSH tgt | batched like @promote ; set state=pending, clear last_error |
| "does not support jobs with priorities" | -- caveat dissolves: a grouped member recovers into its lane |

## Aligned flow (authoritative side-by-side)

```text
v1 (moveJobsToWait-8)                            v3 (PROPOSED — requeue_set(state, count))
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..8] base, events, stateKey, wait, ...     declares [source_set, pending, queue_base]
ZRANGEBYSCORE stateKey 0 ts LIMIT 0 count        source = schedule | dead   -- completed is GONE (completion-deletes)
HDEL KEYS[1]..jobId finishedOn/...  -- DATA-id    HDEL ARGV[base].."job:"..id …  -- grammar-derived (A-1), not KEYS[1]..member
batches(#jobs,7000): ZREM stateKey ; LPUSH tgt   batched like @promote ; set state=pending, clear last_error
"does not support jobs with priorities"          -- caveat dissolves: a grouped member recovers into its lane
```

## Decision & rationale

**Covers → v3.** Bulk-move a window of completed/failed/delayed jobs to wait (operator/recovery replay) → single-job equivalents are shipped — `reprocess_job/3` (`@reprocess`: `dead`→`pending`, clears `last_error`, refuses non-`dead` with `EMQSTATE`) + `promote/3` (`@promote`: due `schedule`→`pending`, batched). A bulk, count-windowed retried-set→pending verb across a whole state is **NOT YET** built. The source set `completed` is gone entirely — v2 is completion-deletes (no `completed` set), so only `schedule` and `dead` are real sources.

**Decision.** A bulk `requeue_set(state, count)` over `schedule`/`dead`, declaring `[source_set, pending, queue_base]`, batched like `@promote`/v1's `batches`. The per-job row resets in-script via the **grammar-derived** key `ARGV[base] .. 'job:' .. id` (the slot-sound A-1 form — never the v1 `KEYS[1] .. member`), clearing `last_error` and setting `state=pending`. The v1 "no priorities" caveat dissolves: a grouped member recovers into its lane (the `@promote` group branch), so the v3 form is *more* capable than v1. Forward-tense: v3 builds this as the operator bulk-recovery transition with its conformance scenario.

**BCS** operator bulk-replay — after a deploy fix, return a window of dead/scheduled work to `pending` in mint order, the authoritative backlog the system re-drains. · **EchoMesh** consistency-first with an availability lever — the replay writes the owning slot's `pending` (the regulated ledger stays correct), and the recovered backlog is exactly the consistent state the availability-first cache then serves. · **[when]** an Exchange operator replaying a window of dead/scheduled work onto pending after a deploy fix.
