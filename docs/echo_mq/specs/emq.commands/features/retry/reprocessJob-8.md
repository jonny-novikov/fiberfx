# reprocessJob-8  →  EchoMQ.Jobs.reprocess_job/3 (@reprocess, jobs.ex)

> Feature: **retry** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   reprocessJob-8
--@feature   retry
--@status    SHIPPED (ported)
--@rung      emq.2.2
--@v1        registry/reprocessJob-8.lua   (KEYS arity 8)
--@v3        EchoMQ.Jobs.reprocess_job/3 (@reprocess, jobs.ex)
```

## v1 source

`registry/reprocessJob-8.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Attempts to reprocess a job

  Input:
    KEYS[1] job key
    KEYS[2] events stream
    KEYS[3] job state
    KEYS[4] wait key
    KEYS[5] meta
    KEYS[6] paused key
    KEYS[7] active key
    KEYS[8] marker key

    ARGV[1] job.id
    ARGV[2] (job.opts.lifo ? 'R' : 'L') + 'PUSH'
    ARGV[3] propVal - failedReason/returnvalue
    ARGV[4] prev state - failed/completed
    ARGV[5] reset attemptsMade - "1" or "0"
    ARGV[6] reset attemptsStarted - "1" or "0"

  Output:
     1 means the operation was a success
    -1 means the job does not exist
    -3 means the job was not found in the expected set.
]]
local rcall = redis.call;

-- Includes
--- @include "includes/addJobInTargetList"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/getTargetQueueList"

local jobKey = KEYS[1]
if rcall("EXISTS", jobKey) == 1 then
  local jobId = ARGV[1]
  if (rcall("ZREM", KEYS[3], jobId) == 1) then
    local attributesToRemove = {}

    if ARGV[5] == "1" then
      table.insert(attributesToRemove, "atm")
    end

    if ARGV[6] == "1" then
      table.insert(attributesToRemove, "ats")
    end

    rcall("HDEL", jobKey, "finishedOn", "processedOn", ARGV[3], unpack(attributesToRemove))

    local target, isPausedOrMaxed = getTargetQueueList(KEYS[5], KEYS[7], KEYS[4], KEYS[6])
    addJobInTargetList(target, KEYS[8], ARGV[2], isPausedOrMaxed, jobId)

    local parentKey = rcall("HGET", jobKey, "parentKey")

    if parentKey and rcall("EXISTS", parentKey) == 1 then
      if ARGV[4] == "failed" then
        if rcall("ZREM", parentKey .. ":unsuccessful", jobKey) == 1 or
          rcall("ZREM", parentKey .. ":failed", jobKey) == 1 then
          rcall("SADD", parentKey .. ":dependencies", jobKey)
        end
      else
        if rcall("HDEL", parentKey .. ":processed", jobKey) == 1 then
          rcall("SADD", parentKey .. ":dependencies", jobKey)
        end
      end
    end

    local maxEvents = getOrSetMaxEvents(KEYS[5])
    -- Emit waiting event
    rcall("XADD", KEYS[2], "MAXLEN", "~", maxEvents, "*", "event", "waiting",
      "jobId", jobId, "prev", ARGV[4]);
    return 1
  else
    return -3
  end
else
  return -1
end
```

## v1 → v3 change ledger

| v1 (reprocessJob-8) | v3 (SHIPPED — EchoMQ.Jobs.@reprocess) |
|---|---|
| KEYS jobKey, state-set, wait, events | keys = [job_key, dead, pending] ; ARGV[1]=id |
| ZREM <state> id ; HDEL finishedOn/returnvalue | if EXISTS job_key == 0 -> -1 |
| addJobInTargetList(wait, id) -- re-enqueue | if ZREM dead id ~= 1 -> EMQSTATE not dead |
| parentKey = HGET jobKey parentKey -- DATA VALUE | HDEL job_key last_error ; HSET job_key state pending |
| SADD (parentKey..':dependencies') ; ZREM … | ZADD pending 0 id ; return 1 |
| -- keys rooted in a hash field (illegal) | -- only `dead` is a retained terminal state |

## Aligned flow (authoritative side-by-side)

```text
v1 (reprocessJob-8)                              v3 (SHIPPED — EchoMQ.Jobs.@reprocess)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS jobKey, state-set, wait, events             keys = [job_key, dead, pending] ; ARGV[1]=id
ZREM <state> id ; HDEL finishedOn/returnvalue    if EXISTS job_key == 0 -> -1
addJobInTargetList(wait, id)  -- re-enqueue       if ZREM dead id ~= 1 -> EMQSTATE not dead
parentKey = HGET jobKey parentKey  -- DATA VALUE  HDEL job_key last_error ; HSET job_key state pending
SADD (parentKey..':dependencies') ; ZREM …       ZADD pending 0 id ; return 1
  -- keys rooted in a hash field (illegal)        -- only `dead` is a retained terminal state
```

## Decision & rationale

**Covers → v3.** Reprocess a finished/failed job (drop from its state set, clear finish fields, re-enqueue, mend parent links) → `reprocess_job/3` does `dead`→`pending`, clears `last_error`, refuses a non-dead job (`EMQSTATE`); `emq.features.md` Part B.2 binds `reprocessJob-8.lua` → `@reprocess` (✅). The v1 parent-dependency mend is deliberately **not** in this port (flows are the emq.3 family).

**Decision.** The single-job dead→pending recovery is shipped and kept (only `dead` is a retained terminal state). **PROPOSED**: extend `@reprocess` with the A-1-clean flow fan-in re-link (the v1 parent-dependency mend) via declared §6 parent subkeys (`:dependencies`/`:processed`), once the flow subkeys are the source of truth (the emq.3.x flow surface) — never the v1 `parentKey` hash read.

**BCS** the post-fix "re-run a dead settlement/reconciliation job" recovery the operator runbook drives. · **EchoMesh** a CP-side recovery verb — deterministic, single-slot, audited; the consistency-first ledger/queue's repair lever. · **[when]** the post-fix "re-run a dead settlement/reconciliation job" the operator runbook drives.
