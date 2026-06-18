# removeRepeatable-3  →  EchoMQ.Repeat.cancel/3 (@repeat_cancel, repeat.ex)

> Feature: **repeat** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   removeRepeatable-3
--@feature   repeat
--@status    SHIPPED (ported, new form)
--@rung      emq.1
--@v1        registry/removeRepeatable-3.lua   (KEYS arity 3)
--@v3        EchoMQ.Repeat.cancel/3 (@repeat_cancel, repeat.ex)
```

## v1 source

`registry/removeRepeatable-3.lua` — the original legacy v1 command, verbatim.

```lua

--[[
  Removes a repeatable job
  Input:
    KEYS[1] repeat jobs key
    KEYS[2] delayed jobs key
    KEYS[3] events key

    ARGV[1] old repeat job id
    ARGV[2] options concat
    ARGV[3] repeat job key
    ARGV[4] prefix key

  Output:
    0 - OK
    1 - Missing repeat job

  Events:
    'removed'
]]
local rcall = redis.call
local millis = rcall("ZSCORE", KEYS[1], ARGV[2])

-- Includes
--- @include "includes/removeJobKeys"

-- legacy removal TODO: remove in next breaking change
if millis then
  -- Delete next programmed job.
  local repeatJobId = ARGV[1] .. millis
  if(rcall("ZREM", KEYS[2], repeatJobId) == 1) then
    removeJobKeys(ARGV[4] .. repeatJobId)
    rcall("XADD", KEYS[3], "*", "event", "removed", "jobId", repeatJobId, "prev", "delayed");
  end
end

if(rcall("ZREM", KEYS[1], ARGV[2]) == 1) then
  return 0
end

-- new removal
millis = rcall("ZSCORE", KEYS[1], ARGV[3])

if millis then
  -- Delete next programmed job.
  local repeatJobId = "repeat:" .. ARGV[3] .. ":" .. millis
  if(rcall("ZREM", KEYS[2], repeatJobId) == 1) then
    removeJobKeys(ARGV[4] .. repeatJobId)
    rcall("XADD", KEYS[3], "*", "event", "removed", "jobId", repeatJobId, "prev", "delayed")
  end
end

if(rcall("ZREM", KEYS[1], ARGV[3]) == 1) then
  rcall("DEL", KEYS[1] .. ":" .. ARGV[3])
  return 0
end

return 1
```

## v1 → v3 change ledger

| v1 (removeRepeatable-3) | v3 (SHIPPED — EchoMQ.Repeat.cancel/3) |
|---|---|
| KEYS[1..3] repeat, delayed, events | keys = [emq:{q}:repeat, emq:{q}:repeat:<name>] |
| LEGACY: millis = ZSCORE(repeat, ARGV2) | removed = ZREM KEYS[1] <name> |
| repeatJobId = ARGV1..millis -- DATA-id | DEL KEYS[2] |
| NEW: "repeat:"..ARGV3..":"..millis -- DATA-id | return removed -- :cancelled \| :absent |
| ZREM delayed ; removeJobKeys(..) per path | -- dual legacy/new branches COLLAPSE to one (no legacy ids) |

## Aligned flow (authoritative side-by-side)

```text
v1 (removeRepeatable-3)                           v3 (SHIPPED — EchoMQ.Repeat.cancel/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..3] repeat, delayed, events               keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
LEGACY: millis = ZSCORE(repeat, ARGV2)           removed = ZREM KEYS[1] <name>
  repeatJobId = ARGV1..millis   -- DATA-id        DEL KEYS[2]
NEW: "repeat:"..ARGV3..":"..millis  -- DATA-id    return removed                    -- :cancelled | :absent
  ZREM delayed ; removeJobKeys(..) per path      -- dual legacy/new branches COLLAPSE to one (no legacy ids)
```

## Decision & rationale

**Covers → v3.** Legacy + new removal of a repeatable → `cancel/3` is the **single** removal verb; the v1 dual legacy/new branches collapse to one (no legacy ids exist in the v2 keyspace), and the data-rooted next-job removal is dropped.

**Decision.** One branded-name registry under braces → no legacy-id reconciliation path to carry; the next-occurrence (a branded `JOB`) is removed via the Jobs surface against a declared key.

**BCS** removing a repeatable is one verb regardless of vintage; clean for lifecycle ops. · **EchoMesh** consistency-side — single-slot removal, partition-local. · **[when]** removing a repeatable regardless of vintage.
