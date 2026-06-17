# promote-9  →  EchoMQ.Jobs.promote/3 (@promote due-sweep, jobs.ex:540); targeted promote_now/3 (proposed)

> Feature: **scheduling** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   promote-9
--@feature   scheduling
--@status    PARTIAL
--@rung      emq.1 e0fa9b03
--@v1        registry/promote-9.lua   (KEYS arity 9)
--@v3        EchoMQ.Jobs.promote/3 (@promote due-sweep, jobs.ex:540); targeted promote_now/3 (proposed)
```

## v1 source

`registry/promote-9.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Promotes a job that is currently "delayed" to the "waiting" state

    Input:
      KEYS[1] 'delayed'
      KEYS[2] 'wait'
      KEYS[3] 'paused'
      KEYS[4] 'meta'
      KEYS[5] 'prioritized'
      KEYS[6] 'active'
      KEYS[7] 'pc' priority counter
      KEYS[8] 'event stream'
      KEYS[9] 'marker'

      ARGV[1]  queue.toKey('')
      ARGV[2]  jobId

    Output:
       0 - OK
      -3 - Job not in delayed zset.

    Events:
      'waiting'
]]
local rcall = redis.call
local jobId = ARGV[2]

-- Includes
--- @include "includes/addJobInTargetList"
--- @include "includes/addJobWithPriority"
--- @include "includes/getTargetQueueList"

if rcall("ZREM", KEYS[1], jobId) == 1 then
    local jobKey = ARGV[1] .. jobId
    local priority = tonumber(rcall("HGET", jobKey, "priority")) or 0
    local metaKey = KEYS[4]
    local markerKey = KEYS[9]

    -- Remove delayed "marker" from the wait list if there is any.
    -- Since we are adding a job we do not need the marker anymore.
    -- Markers in waitlist DEPRECATED in v5: Remove in v6.
    local target, isPausedOrMaxed = getTargetQueueList(metaKey, KEYS[6], KEYS[2], KEYS[3])
    local marker = rcall("LINDEX", target, 0)
    if marker and string.sub(marker, 1, 2) == "0:" then rcall("LPOP", target) end

    if priority == 0 then
        -- LIFO or FIFO
        addJobInTargetList(target, markerKey, "LPUSH", isPausedOrMaxed, jobId)
    else
        addJobWithPriority(markerKey, KEYS[5], priority, jobId, KEYS[7], isPausedOrMaxed)
    end

    rcall("XADD", KEYS[8], "*", "event", "waiting", "jobId", jobId, "prev",
          "delayed");

    rcall("HSET", jobKey, "delay", 0)

    return 0
else
    return -3
end
```

## v1 → v3 change ledger

| v1 (promote-9) | v3 (PARTIAL — Jobs.promote/3 due-sweep, @promote) |
|---|---|
| KEYS[1] delayed … ; ARGV[1]=prefix ARGV[2]=id | keys = [schedule, pending] ; ARGV[2] = batch |
| ZREM delayed jobId | t=TIME ; now = t1*1000 + floor(t2/1000) |
| jobKey = ARGV[1]..jobId -- ARGV concat | due = ZRANGEBYSCORE schedule -inf now LIMIT 0 batch |
| priority = HGET jobKey priority -- arm by DATA | for id in due: ZREM schedule id |
| LPUSH wait \| addJobWithPriority(prioritized) | g = HGET job:id group ; lane(g) or ZADD pending 0 id -- mint order |

## Aligned flow (authoritative side-by-side)

```text
v1 (promote-9)                                   v3 (PARTIAL — Jobs.promote/3 due-sweep, @promote)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] delayed … ; ARGV[1]=prefix ARGV[2]=id    keys = [schedule, pending] ; ARGV[2] = batch
ZREM delayed jobId                               t=TIME ; now = t1*1000 + floor(t2/1000)
jobKey = ARGV[1]..jobId       -- ARGV concat     due = ZRANGEBYSCORE schedule -inf now LIMIT 0 batch
priority = HGET jobKey priority  -- arm by DATA  for id in due: ZREM schedule id
  LPUSH wait | addJobWithPriority(prioritized)     g = HGET job:id group ; lane(g) or ZADD pending 0 id  -- mint order
```

## Decision & rationale

**Covers → v3.** Promote ONE specific delayed job (by id) → the shipped `@promote` promotes *all due* `schedule` members on the server clock (lane-aware, no `prioritized`); the targeted single-id force-promote is the gap — add `promote_now/3`.

**Decision.** Retain the due-sweep `@promote`; **PROPOSED** a sibling `promote_now/3` (declared `[schedule, pending]`, id gated at `Keyspace.job_key/2`) — a single `ZREM schedule id` + `ZADD pending 0 id` (or the grouped id's lane) ignoring due-time; honest-row `{:ok,1}`/`{:ok,0}` (the v1 `-3`). No `prioritized` arm (retired §6).

**BCS** operator/early-trigger of a scheduled job. · **EchoMesh** consistency-first — a targeted single-slot move, deterministic, no clock-skew dependence. · **[when]** an operator force-promoting one scheduled job ahead of its due time.
