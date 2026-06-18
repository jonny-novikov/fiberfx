# removeJob-2  →  EchoMQ.Jobs.remove_job/4 (@remove_job, jobs.ex; refuses locked EMQLOCK, -1→:gone)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   removeJob-2
--@feature   lifecycle
--@status    SHIPPED (ported)
--@rung      emq.2.2
--@v1        registry/removeJob-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Jobs.remove_job/4 (@remove_job, jobs.ex; refuses locked EMQLOCK, -1→:gone)
```

## v1 source

`registry/removeJob-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
    Remove a job from all the statuses it may be in as well as all its data.
    In order to be able to remove a job, it cannot be active.

    Input:
      KEYS[1] jobKey
      KEYS[2] repeat key

      ARGV[1] jobId
      ARGV[2] remove children
      ARGV[3] queue prefix

    Events:
      'removed'
]]

local rcall = redis.call

-- Includes
--- @include "includes/isJobSchedulerJob"
--- @include "includes/isLocked"
--- @include "includes/removeJobWithChildren"

local jobId = ARGV[1]
local shouldRemoveChildren = ARGV[2]
local prefix = ARGV[3]
local jobKey = KEYS[1]
local repeatKey = KEYS[2]

if isJobSchedulerJob(jobId, jobKey, repeatKey) then
    return -8
end

if not isLocked(prefix, jobId, shouldRemoveChildren) then
    local options = {
        removeChildren = shouldRemoveChildren == "1",
        ignoreProcessed = false,
        ignoreLocked = false
    }

    removeJobWithChildren(prefix, jobId, nil, options)
    return 1
end
return 0
```

## v1 → v3 change ledger

| v1 (removeJob-2) | v3 (SHIPPED — EchoMQ.Jobs.@remove_job) |
|---|---|
| KEYS[1]=jobKey, KEYS[2]=repeat ; ARGV prefix | keys = [job_key, pending, active, schedule, |
| removeJobWithChildren(prefix, jobId, ...) | dead, de:<did>] (all declared) |
| failedSet = prefix.."failed" -- ARGV-rooted | if EXISTS jk == 0 -> return -1 (:gone) |
| recurses on child VALUES (A-1 ✗) | if EXISTS jk..':lock' -> err 'EMQLOCK' (locked) |
| if isJobSchedulerJob(...) -> -8 | ZREM pending/active/schedule/dead <id> |
| return 1 | GET de:<did> == id ? DEL de:<did> ; DEL jk, jk:logs |

## Aligned flow (authoritative side-by-side)

```text
v1 (removeJob-2)                                 v3 (SHIPPED — EchoMQ.Jobs.@remove_job)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=jobKey, KEYS[2]=repeat ; ARGV prefix     keys = [job_key, pending, active, schedule,
removeJobWithChildren(prefix, jobId, ...)                dead, de:<did>]   (all declared)
  failedSet = prefix.."failed"  -- ARGV-rooted   if EXISTS jk == 0 -> return -1            (:gone)
  recurses on child VALUES  (A-1 ✗)              if EXISTS jk..':lock' -> err 'EMQLOCK'    (locked)
if isJobSchedulerJob(...) -> -8                  ZREM pending/active/schedule/dead <id>
return 1                                         GET de:<did> == id ? DEL de:<did>  ; DEL jk, jk:logs
```

## Decision & rationale

**Covers → v3.** Remove one job from every state + all its data; refuse if locked → all six keys declared, ZREMs the four sets, DELs the row + `:logs`, releases the dedup key iff it matches; the v1 data-value child recursion is *not lifted*.

**Decision.** Keep the six-declared-keys form verbatim (already state-of-the-art); the locked refusal reads the Locks presence marker, the dedup release is GET-compare-DEL. **PROPOSED** delta: a declared-keys **recursive** variant walking the `Flows` `:dependencies`/`:processed` subkeys, never the v1 data-value `parent_key`; FLAT first (grandchildren → emq.3.5).

**BCS** a settlement-job cleanup removes one branded id cleanly, refusing while a worker holds the lock. · **EchoMesh** consistency-side — a single-slot, partition-local teardown of one `{q}`-gated job. · **[when]** an operator runbook removing one branded settlement job.
