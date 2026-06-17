# changePriority-7  →  no priority re-score; Lanes group re-assignment / weighted rotation (emq.4)

> Feature: **groups** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   changePriority-7
--@feature   groups
--@status    RETIRED (capability retired by design, §6)
--@rung      emq.1
--@v1        registry/changePriority-7.lua   (KEYS arity 7)
--@v3        no priority re-score; Lanes group re-assignment / weighted rotation (emq.4)
```

## v1 source

`registry/changePriority-7.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Change job priority
  Input:
    KEYS[1] 'wait',
    KEYS[2] 'paused'
    KEYS[3] 'meta'
    KEYS[4] 'prioritized'
    KEYS[5] 'active'
    KEYS[6] 'pc' priority counter
    KEYS[7] 'marker'

    ARGV[1] priority value
    ARGV[2] prefix key
    ARGV[3] job id
    ARGV[4] lifo

    Output:
       0  - OK
      -1  - Missing job
]]
local jobId = ARGV[3]
local jobKey = ARGV[2] .. jobId
local priority = tonumber(ARGV[1])
local rcall = redis.call

-- Includes
--- @include "includes/addJobInTargetList"
--- @include "includes/addJobWithPriority"
--- @include "includes/getTargetQueueList"
--- @include "includes/pushBackJobWithPriority"

local function reAddJobWithNewPriority( prioritizedKey, markerKey, targetKey,
    priorityCounter, lifo, priority, jobId, isPausedOrMaxed)
    if priority == 0 then
        local pushCmd = lifo and 'RPUSH' or 'LPUSH'
        addJobInTargetList(targetKey, markerKey, pushCmd, isPausedOrMaxed, jobId)
    else
        if lifo then
            pushBackJobWithPriority(prioritizedKey, priority, jobId)
        else
            addJobWithPriority(markerKey, prioritizedKey, priority, jobId,
                priorityCounter, isPausedOrMaxed)
        end
    end
end

if rcall("EXISTS", jobKey) == 1 then
    local metaKey = KEYS[3]
    local target, isPausedOrMaxed = getTargetQueueList(metaKey, KEYS[5], KEYS[1], KEYS[2])
    local prioritizedKey = KEYS[4]
    local priorityCounterKey = KEYS[6]
    local markerKey = KEYS[7]

    -- Re-add with the new priority
    if rcall("ZREM", prioritizedKey, jobId) > 0 then
        reAddJobWithNewPriority( prioritizedKey, markerKey, target,
            priorityCounterKey, ARGV[4] == '1', priority, jobId, isPausedOrMaxed)
    elseif rcall("LREM", target, -1, jobId) > 0 then
        reAddJobWithNewPriority( prioritizedKey, markerKey, target,
            priorityCounterKey, ARGV[4] == '1', priority, jobId, isPausedOrMaxed)
    end

    rcall("HSET", jobKey, "priority", priority)

    return 0
else
    return -1
end
```

## v1 → v3 change ledger

| v1 (changePriority-7) | v3 (RETIRED — re-aimed to EchoMQ.Lanes, emq.4) |
|---|---|
| KEYS[4]=prioritized, KEYS[6]=pc(counter) | no change_priority verb (grep-confirmed) |
| ARGV[1]=priority(DATA) ARGV[2]=prefix | no priority concept in jobs.ex / lanes.ex |
| jobKey = ARGV[2] .. jobId -- DATA-prefix concat | the prioritized ZSET is RETIRED by design (§6) |
| ZREM prioritized / LREM wait ; reAddWithPriority | re-aim: change a job's LANE / re-weight rotation |
| HSET jobKey priority ARGV[1] | -- re-aim, NOT re-implement; no re-score returns |

## Aligned flow (authoritative side-by-side)

```text
v1 (changePriority-7)                            v3 (RETIRED — re-aimed to EchoMQ.Lanes, emq.4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[4]=prioritized, KEYS[6]=pc(counter)         no change_priority verb (grep-confirmed)
ARGV[1]=priority(DATA) ARGV[2]=prefix            no priority concept in jobs.ex / lanes.ex
jobKey = ARGV[2] .. jobId  -- DATA-prefix concat  the prioritized ZSET is RETIRED by design (§6)
ZREM prioritized / LREM wait ; reAddWithPriority  re-aim: change a job's LANE / re-weight rotation
HSET jobKey priority ARGV[1]                      -- re-aim, NOT re-implement; no re-score returns
```

## Decision & rationale

**Covers → v3.** Re-position a job at a new priority score → **no priority re-score verb** in `echo_mq` (grep-confirmed; `jobs.ex`/`lanes.ex` carry no `priority`/`prioritized`). The v1 `prioritized` ZSET is retired (mint order **is** the order theorem; per-group **Lanes** replace priority), so there is nothing to re-prioritize: "matters more now" re-aims to changing the job's lane / re-weighting the rotation.

**Decision.** **Re-aim, not re-implement** — a job's fairness is its *group membership* + the rotating ring, never a per-job numeric score. The forward equivalent of "this venue's work matters more now" is `Lanes` group control: re-assign the lane, or tune weighted/deficit rotation + ceilings (the emq.4 "groups deepened" rung). No `prioritized` ZSET re-implement.

**BCS** per-player fairness (one Lanes group per player) replaces per-job priority for the work surface. · **EchoMesh** lane fairness is the AP-leaning "keep all players answering under contention" dial (emq.4). · **[when]** "this player's work matters more now" — re-aimed to a Lanes weighting, not a per-job re-score.
