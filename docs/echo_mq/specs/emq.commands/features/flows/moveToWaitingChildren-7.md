# moveToWaitingChildren-7  →  fan-in in Flows/@complete; explicit await_children/… PROPOSED

> Feature: **flows** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   moveToWaitingChildren-7
--@feature   flows
--@status    PARTIAL
--@rung      emq.3.1
--@v1        registry/moveToWaitingChildren-7.lua   (KEYS arity 7)
--@v3        fan-in in Flows/@complete; explicit await_children/… PROPOSED
```

## v1 source

`registry/moveToWaitingChildren-7.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Moves job from active to waiting children set.

  Input:
    KEYS[1] active key
    KEYS[2] wait-children key
    KEYS[3] job key
    KEYS[4] job dependencies key
    KEYS[5] job unsuccessful key
    KEYS[6] stalled key
    KEYS[7] events key

    ARGV[1] token
    ARGV[2] child key
    ARGV[3] timestamp
    ARGV[4] jobId
    ARGV[5] prefix

  Output:
    0 - OK
    1 - There are not pending dependencies.
   -1 - Missing job.
   -2 - Missing lock
   -3 - Job not in active set
   -9 - Job has failed children
]]
local rcall = redis.call
local activeKey = KEYS[1]
local waitingChildrenKey = KEYS[2]
local jobKey = KEYS[3]
local jobDependenciesKey = KEYS[4]
local jobUnsuccessfulKey = KEYS[5]
local stalledKey = KEYS[6]
local eventStreamKey = KEYS[7]
local token = ARGV[1]
local timestamp = ARGV[3]
local jobId = ARGV[4]

--- Includes
--- @include "includes/removeLock"

local function removeJobFromActive(activeKey, stalledKey, jobKey, jobId,
    token)
  local errorCode = removeLock(jobKey, stalledKey, token, jobId)
  if errorCode < 0 then
    return errorCode
  end

  local numRemovedElements = rcall("LREM", activeKey, -1, jobId)

  if numRemovedElements < 1 then
    return -3
  end

  return 0
end

local function moveToWaitingChildren(activeKey, waitingChildrenKey, stalledKey, eventStreamKey,
    jobKey, jobId, timestamp, token)
  local errorCode = removeJobFromActive(activeKey, stalledKey, jobKey, jobId, token)
  if errorCode < 0 then
    return errorCode
  end

  local score = tonumber(timestamp)

  rcall("ZADD", waitingChildrenKey, score, jobId)
  rcall("XADD", eventStreamKey, "*", "event", "waiting-children", "jobId", jobId, 'prev', 'active')

  return 0
end

if rcall("EXISTS", jobKey) == 1 then
  if rcall("ZCARD", jobUnsuccessfulKey) ~= 0 then
    return -9
  else
    if ARGV[2] ~= "" then
      if rcall("SISMEMBER", jobDependenciesKey, ARGV[2]) ~= 0 then
        return moveToWaitingChildren(activeKey, waitingChildrenKey, stalledKey, eventStreamKey,
          jobKey, jobId, timestamp, token)
      end
  
      return 1
    else
      if rcall("SCARD", jobDependenciesKey) ~= 0 then 
        return moveToWaitingChildren(activeKey, waitingChildrenKey, stalledKey, eventStreamKey,
          jobKey, jobId, timestamp, token)
      end
  
      return 1
    end    
  end
end

return -1
```

## v1 → v3 change ledger

| v1 (moveToWaitingChildren-7) | v3 (PROPOSED — EchoMQ.Flows.await_children/…) |
|---|---|
| ZCARD jobUnsuccessfulKey ~= 0 ? -9 -- failed | -- add-time fan-in SHIPPED (parent held awaiting_children, |
| SISMEMBER jobDependenciesKey ARGV[2] -- named | :dependencies=N, released at zero by @complete); SELF-PARK = gap |
| or SCARD jobDependenciesKey ~= 0 ? | # host reads dep-count + :unsuccessful card HOST-SIDE |
| removeLock ; ZADD wait-children jobId -- par | k # (parent_of/3, never a Lua hash-rooted key, S-6/INV2) |
| else return 1 -- nothing pending, worker goes | # one same-slot park; {:awaiting,n}/{:ready,0}/{:failed_children} |

## Aligned flow (authoritative side-by-side)

```text
v1 (moveToWaitingChildren-7)                     v3 (PROPOSED — EchoMQ.Flows.await_children/…)
─────────────────────────────────────────       ─────────────────────────────────────────────────
ZCARD jobUnsuccessfulKey ~= 0 ? -9  -- failed    -- add-time fan-in SHIPPED (parent held awaiting_children,
SISMEMBER jobDependenciesKey ARGV[2]  -- named      :dependencies=N, released at zero by @complete); SELF-PARK = gap
  or SCARD jobDependenciesKey ~= 0 ?             # host reads dep-count + :unsuccessful card HOST-SIDE
    removeLock ; ZADD wait-children jobId -- park # (parent_of/3, never a Lua hash-rooted key, S-6/INV2)
else return 1   -- nothing pending, worker goes  # one same-slot park; {:awaiting,n}/{:ready,0}/{:failed_children}
```

## Decision & rationale

**Covers → v3.** A worker voluntarily parks its own active job pending children → the **add-time** fan-in is shipped (`Flows` holds the parent `awaiting_children` with `:dependencies = N`, released at zero by the `@complete` hook), but the distinct v1 capability — a worker parking its *already-active* job pending a runtime-discovered child — has **no dedicated v2 verb**.

**Decision.** Add an explicit `await_children/…` verb on `EchoMQ.Flows`: the host reads the outstanding-dependency count + `:unsuccessful` cardinality **HOST-SIDE** (the `parent_of/3`/`dependencies/3` pattern), then one same-slot transition parks the parent on its slot. The failed-children guard is preserved as a host read + a declared-key check, never a data-rooted `SISMEMBER`. *(Prose until the rung authors it.)*

**BCS** dynamic flows where a parent discovers children at runtime (composing settlement DAGs). · **EchoMesh** consistency-first within a slot — the parent's await is a same-slot guarded transition, not a cross-region promise. · **[when]** a dynamic flow where a parent discovers children at runtime.
