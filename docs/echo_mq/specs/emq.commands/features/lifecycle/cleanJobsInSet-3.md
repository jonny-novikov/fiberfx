# cleanJobsInSet-3  →  Admin.drain/3 is predicate-free today; Admin.clean/4 (server-clock age grace + limit) PROPOSED. (also batches)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   cleanJobsInSet-3
--@feature   lifecycle
--@status    PARTIAL
--@rung      emq.2.2 76fc947c
--@v1        registry/cleanJobsInSet-3.lua   (KEYS arity 3)
--@v3        Admin.drain/3 is predicate-free today; Admin.clean/4 (server-clock age grace + limit) PROPOSED. (also batches)
```

## v1 source

`registry/cleanJobsInSet-3.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Remove jobs from the specific set.

  Input:
    KEYS[1]  set key,
    KEYS[2]  events stream key
    KEYS[3]  repeat key

    ARGV[1]  jobKey prefix
    ARGV[2]  timestamp
    ARGV[3]  limit the number of jobs to be removed. 0 is unlimited
    ARGV[4]  set name, can be any of 'wait', 'active', 'paused', 'delayed', 'completed', or 'failed'
]]
local rcall = redis.call
local repeatKey = KEYS[3]
local rangeStart = 0
local rangeEnd = -1

local limit = tonumber(ARGV[3])

-- If we're only deleting _n_ items, avoid retrieving all items
-- for faster performance
--
-- Start from the tail of the list, since that's where oldest elements
-- are generally added for FIFO lists
if limit > 0 then
  rangeStart = -1 - limit + 1
  rangeEnd = -1
end

-- Includes
--- @include "includes/cleanList"
--- @include "includes/cleanSet"

local result
if ARGV[4] == "active" then
  result = cleanList(KEYS[1], ARGV[1], rangeStart, rangeEnd, ARGV[2], false --[[ hasFinished ]],
                      repeatKey)
elseif ARGV[4] == "delayed" then
  rangeEnd = "+inf"
  result = cleanSet(KEYS[1], ARGV[1], rangeEnd, ARGV[2], limit,
                    {"processedOn", "timestamp"}, false  --[[ hasFinished ]], repeatKey)
elseif ARGV[4] == "prioritized" then
  rangeEnd = "+inf"
  result = cleanSet(KEYS[1], ARGV[1], rangeEnd, ARGV[2], limit,
                    {"timestamp"}, false  --[[ hasFinished ]], repeatKey)
elseif ARGV[4] == "wait" or ARGV[4] == "paused" then
  result = cleanList(KEYS[1], ARGV[1], rangeStart, rangeEnd, ARGV[2], true --[[ hasFinished ]],
                      repeatKey)
else
  rangeEnd = ARGV[2]
  -- No need to pass repeat key as in that moment job won't be related to a job scheduler
  result = cleanSet(KEYS[1], ARGV[1], rangeEnd, ARGV[2], limit,
                    {"finishedOn"}, true  --[[ hasFinished ]])
end

rcall("XADD", KEYS[2], "*", "event", "cleaned", "count", result[2])

return result[1]
```

## v1 → v3 change ledger

| v1 (cleanJobsInSet-3) | v3 (PROPOSED — EchoMQ.Admin.clean/4) |
|---|---|
| KEYS set,events,repeat ; ARGV prefix,ts,limit, | over the four v2 sets (pending/active/schedule/dead) |
| setName | age grace from server TIME ; limit, bounded :more/:ok |
| if setName=="active" cleanList(...) -- DATA | scheduler-skip (the Repeat registry survives) |
| elseif "delayed"/"prioritized" cleanSet(...) | honest count |
| getTimestamp from HASH fields ; skip locked | -- v1 multi-branch dispatch COLLAPSES (no prioritized/ |
| removeJob(prefix-built key) (A-1 ✗) | completed/failed sets under completion-deletes + lanes) |
| XADD events cleaned count | -- event = PUBLISH emq:{q}:events (emq.2.3 watch plane) |

## Aligned flow (authoritative side-by-side)

```text
v1 (cleanJobsInSet-3)                            v3 (PROPOSED — EchoMQ.Admin.clean/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS set,events,repeat ; ARGV prefix,ts,limit,   over the four v2 sets (pending/active/schedule/dead)
  setName                                        age grace from server TIME ; limit, bounded :more/:ok
if setName=="active" cleanList(...)  -- DATA      scheduler-skip (the Repeat registry survives)
elseif "delayed"/"prioritized" cleanSet(...)     honest count
  getTimestamp from HASH fields ; skip locked    -- v1 multi-branch dispatch COLLAPSES (no prioritized/
  removeJob(prefix-built key)  (A-1 ✗)             completed/failed sets under completion-deletes + lanes)
XADD events cleaned count                         -- event = PUBLISH emq:{q}:events (emq.2.3 watch plane)
```

## Decision & rationale

**Covers → v3.** Bulk-remove jobs from one set older than a timestamp, up to a limit, skipping locked + scheduler, emit a `cleaned` event → `drain/3` wipes whole, predicate-free; no age grace, no limit, no per-set dispatch, no scheduler-skip.

**Decision.** Add `Admin.clean/4` over the four v2 sets with a server-clock `TIME` age grace + a limit (`:more`/`:ok`) + a scheduler-skip + an honest count; every job key derives from the declared queue base root, never the ARGV `jobKeyPrefix`. The event is the emq.2.3 watch-plane PUBLISH, replacing v1's `XADD … cleaned`.

**BCS** an operator's age-based hygiene over `Exchange.*` work lanes during an incident. · **EchoMesh** consistency-side — bounded removal under one `{q}` gate. · **[when]** age-based queue hygiene during an incident.
