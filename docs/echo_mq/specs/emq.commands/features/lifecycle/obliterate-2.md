# obliterate-2  →  EchoMQ.Admin.obliterate/3 (@obliterate, admin.ex)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   obliterate-2
--@feature   lifecycle
--@status    SHIPPED (ported)
--@rung      emq.2.2 (fix landed emq.2.4)
--@v1        registry/obliterate-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Admin.obliterate/3 (@obliterate, admin.ex)
```

## v1 source

`registry/obliterate-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Completely obliterates a queue and all of its contents
  This command completely destroys a queue including all of its jobs, current or past 
  leaving no trace of its existence. Since this script needs to iterate to find all the job
  keys, consider that this call may be slow for very large queues.

  The queue needs to be "paused" or it will return an error
  If the queue has currently active jobs then the script by default will return error,
  however this behaviour can be overrided using the 'force' option.
  
  Input:
    KEYS[1] meta
    KEYS[2] base

    ARGV[1] count
    ARGV[2] force
]]

local maxCount = tonumber(ARGV[1])
local baseKey = KEYS[2]

local rcall = redis.call

-- Includes
--- @include "includes/removeJobs"
--- @include "includes/removeListJobs"
--- @include "includes/removeZSetJobs"

local function removeLockKeys(keys)
  for i, key in ipairs(keys) do
    rcall("DEL", baseKey .. key .. ':lock')
  end
end

-- 1) Check if paused, if not return with error.
if rcall("HEXISTS", KEYS[1], "paused") ~= 1 then
  return -1 -- Error, NotPaused
end

-- 2) Check if there are active jobs, if there are and not "force" return error.
local activeKey = baseKey .. 'active'
local activeJobs = getListItems(activeKey, maxCount)
if (#activeJobs > 0) then
  if(ARGV[2] == "") then 
    return -2 -- Error, ExistActiveJobs
  end
end

removeLockKeys(activeJobs)
maxCount = removeJobs(activeJobs, true, baseKey, maxCount)
rcall("LTRIM", activeKey, #activeJobs, -1)
if(maxCount <= 0) then
  return 1
end

local delayedKey = baseKey .. 'delayed'
maxCount = removeZSetJobs(delayedKey, true, baseKey, maxCount)
if(maxCount <= 0) then
  return 1
end

local repeatKey = baseKey .. 'repeat'
local repeatJobsIds = getZSetItems(repeatKey, maxCount)
for i, key in ipairs(repeatJobsIds) do
  local jobKey = repeatKey .. ":" .. key
  rcall("DEL", jobKey)
end
if(#repeatJobsIds > 0) then
  for from, to in batches(#repeatJobsIds, 7000) do
    rcall("ZREM", repeatKey, unpack(repeatJobsIds, from, to))
  end
end
maxCount = maxCount - #repeatJobsIds
if(maxCount <= 0) then
  return 1
end

local completedKey = baseKey .. 'completed'
maxCount = removeZSetJobs(completedKey, true, baseKey, maxCount)
if(maxCount <= 0) then
  return 1
end

local waitKey = baseKey .. 'paused'
maxCount = removeListJobs(waitKey, true, baseKey, maxCount)
if(maxCount <= 0) then
  return 1
end

local prioritizedKey = baseKey .. 'prioritized'
maxCount = removeZSetJobs(prioritizedKey, true, baseKey, maxCount)
if(maxCount <= 0) then
  return 1
end

local failedKey = baseKey .. 'failed'
maxCount = removeZSetJobs(failedKey, true, baseKey, maxCount)
if(maxCount <= 0) then
  return 1
end

if(maxCount > 0) then
  rcall("DEL",
    baseKey .. 'events',
    baseKey .. 'delay',
    baseKey .. 'stalled-check',
    baseKey .. 'stalled',
    baseKey .. 'id',
    baseKey .. 'pc',
    baseKey .. 'marker',
    baseKey .. 'meta',
    baseKey .. 'metrics:completed',
    baseKey .. 'metrics:completed:data',
    baseKey .. 'metrics:failed',
    baseKey .. 'metrics:failed:data')
  return 0
else
  return 1
end
```

## v1 → v3 change ledger

| v1 (obliterate-2) | v3 (SHIPPED — EchoMQ.Admin.@obliterate) |
|---|---|
| KEYS[1]=meta, KEYS[2]=base ; ARGV count,force | keys = [meta, base] ; ARGV = [force, budget] |
| HEXISTS meta paused ~= 1 -> -1 (meta gate) | HGET meta paused == false -> err 'EMQSTATE not paused' |
| getListItems(base..'active', max) | -- reads the DECLARED meta key (A-1-clean) |
| #active > 0 and not force -> -2 | ZRANGE base..'active' 0 budget-1 ; >0 & !force -> err |
| removeJobs(active,...) -- HMGET parentKey ✗ | del_job each: jk = base..'job:'..id ; DEL jk, :logs, :lock |
| DEL base..'active'/'delayed'/... + ~13 aux | -- DEL metrics:* gactive glimit ring wake paused repeat |
| -- ~13 string-concat aux keys off baseKey | limiter meta (the §6 aux keys) |

## Aligned flow (authoritative side-by-side)

```text
v1 (obliterate-2)                                v3 (SHIPPED — EchoMQ.Admin.@obliterate)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=meta, KEYS[2]=base ; ARGV count,force    keys = [meta, base] ; ARGV = [force, budget]
HEXISTS meta paused ~= 1 -> -1  (meta gate)      HGET meta paused == false -> err 'EMQSTATE not paused'
getListItems(base..'active', max)                  -- reads the DECLARED meta key (A-1-clean)
#active > 0 and not force -> -2                  ZRANGE base..'active' 0 budget-1 ; >0 & !force -> err
removeJobs(active,...)  -- HMGET parentKey ✗     del_job each: jk = base..'job:'..id ; DEL jk, :logs, :lock
DEL base..'active'/'delayed'/... + ~13 aux       -- DEL metrics:* gactive glimit ring wake paused repeat
  -- ~13 string-concat aux keys off baseKey         limiter meta   (the §6 aux keys)
```

## Decision & rationale

**Covers → v3.** Destroy a *paused* queue iteratively (refuse if not paused / has active unless force, delete every set + job key + ~13 aux keys, bounded by count) → the not-paused gate reads the declared `KEYS[1]=meta`, every job key derives from the declared base, bounded `:more`/`:ok`.

**Decision.** Already the state-of-the-art form; the v1 set zoo collapses to the four braced sets + lane structures + the §6 aux keys. The honest limit: a `de:<did>` with no live referrer is not individually discoverable under declared keys (D-4), released at remove/drain-time instead.

**BCS** a control plane tearing down ephemeral/test venue queues to their keyspace footprint, leaving no trace. · **EchoMesh** consistency-side — a whole-queue, single-`{q}` destruction. · **[when]** tearing down an ephemeral/test venue queue.
