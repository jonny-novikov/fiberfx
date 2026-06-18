# getState-8  →  EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getState-8
--@feature   metrics
--@status    SHIPPED (ported)
--@rung      emq.2.1
--@v1        registry/getState-8.lua   (KEYS arity 8)
--@v3        EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex)
```

## v1 source

`registry/getState-8.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get a job state

  Input: 
    KEYS[1] 'completed' key,
    KEYS[2] 'failed' key
    KEYS[3] 'delayed' key
    KEYS[4] 'active' key
    KEYS[5] 'wait' key
    KEYS[6] 'paused' key
    KEYS[7] 'waiting-children' key
    KEYS[8] 'prioritized' key

    ARGV[1] job id
  Output:
    'completed'
    'failed'
    'delayed'
    'active'
    'prioritized'
    'waiting'
    'waiting-children'
    'unknown'
]]
local rcall = redis.call

if rcall("ZSCORE", KEYS[1], ARGV[1]) then
  return "completed"
end

if rcall("ZSCORE", KEYS[2], ARGV[1]) then
  return "failed"
end

if rcall("ZSCORE", KEYS[3], ARGV[1]) then
  return "delayed"
end

if rcall("ZSCORE", KEYS[8], ARGV[1]) then
  return "prioritized"
end

-- Includes
--- @include "includes/checkItemInList"

local active_items = rcall("LRANGE", KEYS[4] , 0, -1)
if checkItemInList(active_items, ARGV[1]) ~= nil then
  return "active"
end

local wait_items = rcall("LRANGE", KEYS[5] , 0, -1)
if checkItemInList(wait_items, ARGV[1]) ~= nil then
  return "waiting"
end

local paused_items = rcall("LRANGE", KEYS[6] , 0, -1)
if checkItemInList(paused_items, ARGV[1]) ~= nil then
  return "waiting"
end

if rcall("ZSCORE", KEYS[7], ARGV[1]) then
  return "waiting-children"
end

return "unknown"
```

## v1 → v3 change ledger

| v1 (getState-8) | v3 (SHIPPED — Metrics.get_job_state/3) |
|---|---|
| KEYS[1..8] completed/failed/delayed/active/ | keys = [pending, active, schedule, dead, job_row] |
| wait/paused/waiting-children/prioritized | for k in 1..4: if ZSCORE KEYS[k] id -> state |
| ZSCORE completed/failed/delayed/prioritized | st = HGET KEYS[5] 'state' |
| LRANGE active/wait/paused + checkItemInList | 'awaiting_children' -> that -- flow parent off-set |
| -- O(n) FULL LIST SCAN ; else "unknown" | st -> 'unknown' ; else 'absent' -- O(log n) |

## Aligned flow (authoritative side-by-side)

```text
v1 (getState-8)                                  v3 (SHIPPED — Metrics.get_job_state/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..8] completed/failed/delayed/active/      keys = [pending, active, schedule, dead, job_row]
  wait/paused/waiting-children/prioritized        for k in 1..4: if ZSCORE KEYS[k] id -> state
ZSCORE completed/failed/delayed/prioritized      st = HGET KEYS[5] 'state'
LRANGE active/wait/paused + checkItemInList       'awaiting_children' -> that  -- flow parent off-set
  -- O(n) FULL LIST SCAN ; else "unknown"         st -> 'unknown' ; else 'absent'   -- O(log n)
```

## Decision & rationale

**Covers → v3.** One job's state → four-ZSET `ZSCORE` probe (no LIST scan) + a row-field branch (emq.3.1-D4): `awaiting_children` is a flow parent held out of every set, else `unknown` (in-flight) else `absent`. Id gated at `Keyspace.job_key/2`; the wire string mapped through the closed `@lookup_states` table.

**Decision.** Keep the shipped four-set + row-field probe — declared keys, no scan, branded-gated, closed result table. **PROPOSED**: on a non-authoritative replica return the slot identity / `as_of` so a consumer can tell a strong read from a stale one.

**BCS** the read a runbook/saga makes before any mutate; `awaiting_children` is the flow-parent state a multi-leg saga inspects. · **EchoMesh** consistency-first — a state-of-record read (refuses rather than risk a second writer), the opposite dial from counts. · **[when]** a runbook reading a job's state before any mutate.
