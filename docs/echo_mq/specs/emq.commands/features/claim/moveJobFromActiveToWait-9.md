# moveJobFromActiveToWait-9  →  recovery EchoMQ.Jobs.reap/2 (@reap, jobs.ex) + Stalled.check/3; a token-fenced voluntary requeue is PROPOSED

> Feature: **claim** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   moveJobFromActiveToWait-9
--@feature   claim
--@status    PARTIAL (partial)
--@rung      emq.0
--@v1        registry/moveJobFromActiveToWait-9.lua   (KEYS arity 9)
--@v3        recovery EchoMQ.Jobs.reap/2 (@reap, jobs.ex) + Stalled.check/3; a token-fenced voluntary requeue is PROPOSED
```

## v1 source

`registry/moveJobFromActiveToWait-9.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Function to move job from active state to wait.
  Input:
    KEYS[1]  active key
    KEYS[2]  wait key
    
    KEYS[3]  stalled key
    KEYS[4]  paused key
    KEYS[5]  meta key
    KEYS[6]  limiter key
    KEYS[7]  prioritized key
    KEYS[8]  marker key
    KEYS[9]  event key

    ARGV[1] job id
    ARGV[2] lock token
    ARGV[3] job id key
]]
local rcall = redis.call

-- Includes
--- @include "includes/addJobInTargetList"
--- @include "includes/pushBackJobWithPriority"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/getTargetQueueList"
--- @include "includes/removeLock"

local jobId = ARGV[1]
local token = ARGV[2]
local jobKey = ARGV[3]

if rcall("EXISTS", jobKey) == 0 then
  return -1
end

local errorCode = removeLock(jobKey, KEYS[3], token, jobId)
if errorCode < 0 then
  return errorCode
end

local metaKey = KEYS[5]
local removed = rcall("LREM", KEYS[1], 1, jobId)
if removed > 0 then
  local target, isPausedOrMaxed = getTargetQueueList(metaKey, KEYS[1], KEYS[2], KEYS[4])

  local priority = tonumber(rcall("HGET", ARGV[3], "priority")) or 0

  if priority > 0 then
    pushBackJobWithPriority(KEYS[7], priority, jobId)
  else
    addJobInTargetList(target, KEYS[8], "RPUSH", isPausedOrMaxed, jobId)
  end

  local maxEvents = getOrSetMaxEvents(metaKey)

  -- Emit waiting event
  rcall("XADD", KEYS[9], "MAXLEN", "~", maxEvents, "*", "event", "waiting",
    "jobId", jobId, "prev", "active")
end

local pttl = rcall("PTTL", KEYS[6])

if pttl > 0 then
  return pttl
else
  return 0
end
```

## v1 → v3 change ledger

| v1 (moveJobFromActiveToWait-9) | v3 (PARTIAL — Jobs.reap/2 + Stalled.check/3) |
|---|---|
| ARGV[1]=jobId ARGV[2]=lockToken ARGV[3]=jobKey | keys = [active, pending] ; ARGV base 'emq:{q}:' |
| removeLock(jobKey,..): GET <jobKey>:lock==token | now = TIME |
| else -6 / -2 -- lock-string fe | nce exp = ZRANGEBYSCORE active -inf now -- expired leases only |
| LREM active 1 jobId | for id in exp: ZREM active id ; ZADD pending 0 id |
| priority = HGET ARGV[3] "priority" -- DATA arm | -- voluntary requeue PROPOSED: attempts-fenced, no morgue |
| >0 -> pushBackJobWithPriority (prioritized) | -- priority arm -> lane g:<group>:pending, no prioritized set |

## Aligned flow (authoritative side-by-side)

```text
v1 (moveJobFromActiveToWait-9)                   v3 (PARTIAL — Jobs.reap/2 + Stalled.check/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
ARGV[1]=jobId ARGV[2]=lockToken ARGV[3]=jobKey   keys = [active, pending] ; ARGV base 'emq:{q}:'
removeLock(jobKey,..): GET <jobKey>:lock==token  now = TIME
  else -6 / -2                 -- lock-string fence  exp = ZRANGEBYSCORE active -inf now  -- expired leases only
LREM active 1 jobId                              for id in exp: ZREM active id ; ZADD pending 0 id
priority = HGET ARGV[3] "priority"  -- DATA arm   -- voluntary requeue PROPOSED: attempts-fenced, no morgue
  >0 -> pushBackJobWithPriority (prioritized)    -- priority arm -> lane g:<group>:pending, no prioritized set
```

## Decision & rationale

**Covers → v3.** The *worker-initiated* voluntary return of a still-held active job to wait → the crash-recovery direction is shipped (`@reap` returns expired-lease members to `pending`); a dedicated voluntary "give it back" verb that bumps no attempt and writes no morgue has no counterpart yet (`@retry`, the nearest exit, consumes the attempt).

**Decision.** **PROPOSED** `requeue/4`: an `attempts`-token-fenced (the v1 lock-token fence → the `EMQSTALE` attempts fence, the established complete/retry pattern) active→pending move that does **not** increment attempts and does **not** touch the morgue, declaring `[active, pending, job_key]` with the row gated at `Keyspace.job_key/2`. The v1 priority branch resolves via the lane arm (grouped child → `emq:{q}:g:<group>:pending`, mirroring `@reap`'s group branch), never a separate `prioritized` set. Registered with its own conformance scenario (additive-minor law).

**BCS** a worker cleanly yielding work it cannot finish back to the single-writer queue without burning a retry attempt — the cooperative give-back the decider/gateway needs under backpressure. · **EchoMesh** consistency-first — the give-back lands on the job's owning slot (the same authoritative `pending` set), so a node shedding load never forks ownership. · **[when]** a worker yielding work it cannot finish back to the single-writer queue without burning a retry attempt.
