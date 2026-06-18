# getRanges-1  →  no def get_ranges; closest as-built EchoMQ.Jobs.browse/3 + Metrics.get_counts/3

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getRanges-1
--@feature   metrics
--@status    NOT YET
--@rung      emq.2.1
--@v1        registry/getRanges-1.lua   (KEYS arity 1)
--@v3        no def get_ranges; closest as-built EchoMQ.Jobs.browse/3 + Metrics.get_counts/3
```

## v1 source

`registry/getRanges-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get job ids per provided states

    Input:
      KEYS[1]    'prefix'

      ARGV[1]    start
      ARGV[2]    end
      ARGV[3]    asc
      ARGV[4...] types
]]
local rcall = redis.call
local prefix = KEYS[1]
local rangeStart = tonumber(ARGV[1])
local rangeEnd = tonumber(ARGV[2])
local asc = ARGV[3]
local results = {}

local function getRangeInList(listKey, asc, rangeStart, rangeEnd, results)
  if asc == "1" then
    local modifiedRangeStart
    local modifiedRangeEnd
    if rangeStart == -1 then
      modifiedRangeStart = 0
    else
      modifiedRangeStart = -(rangeStart + 1)
    end

    if rangeEnd == -1 then
      modifiedRangeEnd = 0
    else
      modifiedRangeEnd = -(rangeEnd + 1)
    end

    results[#results+1] = rcall("LRANGE", listKey,
      modifiedRangeEnd,
      modifiedRangeStart)
  else
    results[#results+1] = rcall("LRANGE", listKey, rangeStart, rangeEnd)
  end
end

for i = 4, #ARGV do
  local stateKey = prefix .. ARGV[i]
  if ARGV[i] == "wait" or ARGV[i] == "paused" then
    -- Markers in waitlist DEPRECATED in v5: Remove in v6.
    local marker = rcall("LINDEX", stateKey, -1)
    if marker and string.sub(marker, 1, 2) == "0:" then
      local count = rcall("LLEN", stateKey)
      if count > 1 then
        rcall("RPOP", stateKey)
        getRangeInList(stateKey, asc, rangeStart, rangeEnd, results)
      else
        results[#results+1] = {}
      end
    else
      getRangeInList(stateKey, asc, rangeStart, rangeEnd, results)
    end
  elseif ARGV[i] == "active" then
    getRangeInList(stateKey, asc, rangeStart, rangeEnd, results)
  else
    if asc == "1" then
      results[#results+1] = rcall("ZRANGE", stateKey, rangeStart, rangeEnd)
    else
      results[#results+1] = rcall("ZREVRANGE", stateKey, rangeStart, rangeEnd)
    end
  end
end

return results
```

## v1 → v3 change ledger

| v1 (getRanges-1, ~70 lines) | v3 (PROPOSED — no script on disk; declared-keys browse) |
|---|---|
| KEYS[1]=prefix ; ARGV[1..3]=start,end,asc | KEYS = [pending, active, schedule, dead] -- §6-closed |
| ARGV[4..]=state names | pending -> ZRANGE k '+' '-' BYLEX REV LIMIT 0 n |
| stateKey = prefix .. ARGV[i] -- OPEN CONCAT | (the order theorem — no second index) |
| wait/paused/active -> LRANGE (v6-marker-aware) | active/schedule/dead -> ZRANGE / ZREVRANGE k start end |
| else -> ZRANGE / ZREVRANGE the ZSET | -- forward: XRANGE <minId>-<maxId> on the stream tier (emq3.6) |

## Aligned flow (authoritative side-by-side)

```text
v1 (getRanges-1, ~70 lines)                      v3 (PROPOSED — no script on disk; declared-keys browse)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=prefix ; ARGV[1..3]=start,end,asc        KEYS = [pending, active, schedule, dead]  -- §6-closed
  ARGV[4..]=state names                           pending -> ZRANGE k '+' '-' BYLEX REV LIMIT 0 n
stateKey = prefix .. ARGV[i]  -- OPEN CONCAT       (the order theorem — no second index)
wait/paused/active -> LRANGE (v6-marker-aware)    active/schedule/dead -> ZRANGE / ZREVRANGE k start end
else -> ZRANGE / ZREVRANGE the ZSET              -- forward: XRANGE <minId>-<maxId> on the stream tier (emq3.6)
```

## Decision & rationale

**Covers → v3.** Job-ids per state over a `[start,end]` window. v1 builds the state key by `prefix .. ARGV[i]` (open concatenation) over v1 LIST/ZSET structures §6 retires. No port exists by design (§6 retires `wait`/`paused`/`prioritized`; completion-deletes leave no `completed`/`failed` set).

**Decision.** Re-derive as a windowed per-state browse over the **four as-built sets** under the v2 laws: `pending` via the order-theorem REV BYLEX (no second index), `active`/`schedule`/`dead` via `ZRANGE`/`ZREVRANGE`. One inline `Script.new/2`, **every set key in KEYS[]** (the open `prefix..ARGV[i]` concat replaced by enumerated, registry-closed `KEYS[n]`); branded ids gated at `Keyspace.job_key/2`. Forward of parity the canonical windowed read becomes `XRANGE` over mint-instant bounds (emq3.6 time-travel).

**BCS** read a queue's backlog/morgue by state for the operator runbook, no second index. · **EchoMesh** consistency-first (CP) read of the regulated bus state — which set holds an id. · **[when]** reading a queue's backlog/morgue by state for the operator runbook.
