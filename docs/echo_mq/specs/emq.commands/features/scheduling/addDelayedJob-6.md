# addDelayedJob-6  →  EchoMQ.Jobs.enqueue_at/5 + enqueue_in/5 (@schedule, jobs.ex:38)

> Feature: **scheduling** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   addDelayedJob-6
--@feature   scheduling
--@status    SHIPPED (ported)
--@rung      emq.1 e0fa9b03
--@v1        registry/addDelayedJob-6.lua   (KEYS arity 6)
--@v3        EchoMQ.Jobs.enqueue_at/5 + enqueue_in/5 (@schedule, jobs.ex:38)
```

## v1 source

`registry/addDelayedJob-6.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Adds a delayed job to the queue by doing the following:
    - Increases the job counter if needed.
    - Creates a new job key with the job data.

    - computes timestamp.
    - adds to delayed zset.
    - Emits a global event 'delayed' if the job is delayed.
    
    Input:
      KEYS[1] 'marker',
      KEYS[2] 'meta'
      KEYS[3] 'id'
      KEYS[4] 'delayed'
      KEYS[5] 'completed'
      KEYS[6] events stream key

      ARGV[1] msgpacked arguments array
            [1]  key prefix,
            [2]  custom id (use custom instead of one generated automatically)
            [3]  name
            [4]  timestamp
            [5]  parentKey?
            [6]  parent dependencies key.
            [7]  parent? {id, queueKey}
            [8]  repeat job key
            [9] deduplication key

      ARGV[2] Json stringified job data
      ARGV[3] msgpacked options

      Output:
        jobId  - OK
        -5     - Missing parent key
]]
local metaKey = KEYS[2]
local idKey = KEYS[3]
local delayedKey = KEYS[4]

local completedKey = KEYS[5]
local eventsKey = KEYS[6]

local jobId
local jobIdKey
local rcall = redis.call

local args = cmsgpack.unpack(ARGV[1])

local data = ARGV[2]

local parentKey = args[5]
local parent = args[7]
local repeatJobKey = args[8]
local deduplicationKey = args[9]
local parentData

-- Includes
--- @include "includes/addDelayedJob"
--- @include "includes/deduplicateJob"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/handleDuplicatedJob"
--- @include "includes/storeJob"

if parentKey ~= nil then
    if rcall("EXISTS", parentKey) ~= 1 then return -5 end

    parentData = cjson.encode(parent)
end

local jobCounter = rcall("INCR", idKey)

local maxEvents = getOrSetMaxEvents(metaKey)
local opts = cmsgpack.unpack(ARGV[3])

local parentDependenciesKey = args[6]
local timestamp = args[4]

if args[2] == "" then
    jobId = jobCounter
    jobIdKey = args[1] .. jobId
else
    jobId = args[2]
    jobIdKey = args[1] .. jobId
    if rcall("EXISTS", jobIdKey) == 1 then
        return handleDuplicatedJob(jobIdKey, jobId, parentKey, parent,
            parentData, parentDependenciesKey, completedKey, eventsKey,
            maxEvents, timestamp)
    end
end

local deduplicationJobId = deduplicateJob(opts['de'], jobId, delayedKey, deduplicationKey,
  eventsKey, maxEvents, args[1])
if deduplicationJobId then
  return deduplicationJobId
end

local delay, priority = storeJob(eventsKey, jobIdKey, jobId, args[3], ARGV[2],
    opts, timestamp, parentKey, parentData, repeatJobKey)

addDelayedJob(jobId, delayedKey, eventsKey, timestamp, maxEvents, KEYS[1], delay)

-- Check if this job is a child of another job, if so add it to the parents dependencies
if parentDependenciesKey ~= nil then
    rcall("SADD", parentDependenciesKey, jobIdKey)
end

return jobId .. "" -- convert to string
```

## v1 → v3 change ledger

| v1 (addDelayedJob-6) | v3 (SHIPPED — Jobs.enqueue_at/5 + enqueue_in/5) |
|---|---|
| KEYS[1..6] marker,meta,id,delayed,completed,ev | keys = [job_key(q,id), queue_key(q,"schedule")] |
| delay = opts['delay'] -- DATA field | if sub(ARGV[1],1,3) ~= 'JOB' -> EMQKIND |
| score = (args[4]+delay)*0x1000 -- CLIENT clock | if ARGV[3]=='in': t=TIME; now=t1*1000+floor(t2/1000) -- SERVER clock |
| << 12, a 12-bit FIFO tiebreak | score = now + ARGV[4] |
| ZADD delayed score jobId | else score = ARGV[4] -- absolute run-at |
| parentKey=args[5] ; parentDeps=args[6] -- DATA | ZADD KEYS[2] score ARGV[1] -- visibility fence |

## Aligned flow (authoritative side-by-side)

```text
v1 (addDelayedJob-6)                             v3 (SHIPPED — Jobs.enqueue_at/5 + enqueue_in/5)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..6] marker,meta,id,delayed,completed,ev   keys = [job_key(q,id), queue_key(q,"schedule")]
delay = opts['delay']         -- DATA field      if sub(ARGV[1],1,3) ~= 'JOB' -> EMQKIND
score = (args[4]+delay)*0x1000  -- CLIENT clock  if ARGV[3]=='in': t=TIME; now=t1*1000+floor(t2/1000)  -- SERVER clock
  << 12, a 12-bit FIFO tiebreak                    score = now + ARGV[4]
ZADD delayed score jobId                         else score = ARGV[4]                       -- absolute run-at
parentKey=args[5] ; parentDeps=args[6]  -- DATA  ZADD KEYS[2] score ARGV[1]                 -- visibility fence
```

## Decision & rationale

**Covers → v3.** Delayed enqueue (run-at packed into a `delayed` ZSET score with a 12-bit id tiebreak) → the as-built `@schedule`: a **visibility fence on the `schedule` set**, the delay priced inside the script from server `TIME` (for `enqueue_in`), a plain run-at score (no bit-stuffing — mint order already orders).

**Decision.** The `schedule` set is a visibility fence, not a second queue (§6): the promote pump (`Jobs.promote/3`) releases due members to `pending`, where the mint-ordered id is the sort key; server `TIME` replaces the client clock (the lease/clock law). **PROPOSED**: a handler-driven dynamic-delay re-score onto the same `schedule` set (emq.4, beside `changeDelay`).

**BCS** scheduled settlement and retry jobs share one `schedule` set and one timing source. · **EchoMesh** the trade-staleness-for-availability dial made physical — a server-clock fence is sound from a laptop to a Fly fleet. · **[when]** a scheduled or backoff-retry job parked to a future run-at.
