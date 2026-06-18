# addPrioritizedJob-9  →  EchoMQ.Lanes.enqueue/5 (@genqueue, lanes.ex), no prioritized set (D-9)

> Feature: **groups** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   addPrioritizedJob-9
--@feature   groups
--@status    SHIPPED (ported, re-aimed)
--@rung      emq.1
--@v1        registry/addPrioritizedJob-9.lua   (KEYS arity 9)
--@v3        EchoMQ.Lanes.enqueue/5 (@genqueue, lanes.ex), no prioritized set (D-9)
```

## v1 source

`registry/addPrioritizedJob-9.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Adds a priotitized job to the queue by doing the following:
    - Increases the job counter if needed.
    - Creates a new job key with the job data.
    - Adds the job to the "added" list so that workers gets notified.

    Input:
      KEYS[1] 'marker',
      KEYS[2] 'meta'
      KEYS[3] 'id'
      KEYS[4] 'prioritized'
      KEYS[5] 'delayed'
      KEYS[6] 'completed'
      KEYS[7] 'active'
      KEYS[8] events stream key
      KEYS[9] 'pc' priority counter

      ARGV[1] msgpacked arguments array
            [1]  key prefix,
            [2]  custom id (will not generate one automatically)
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
local priorityKey = KEYS[4]

local completedKey = KEYS[6]
local activeKey = KEYS[7]
local eventsKey = KEYS[8]
local priorityCounterKey = KEYS[9]

local jobId
local jobIdKey
local rcall = redis.call

local args = cmsgpack.unpack(ARGV[1])

local data = ARGV[2]
local opts = cmsgpack.unpack(ARGV[3])

local parentKey = args[5]
local parent = args[7]
local repeatJobKey = args[8]
local deduplicationKey = args[9]
local parentData

-- Includes
--- @include "includes/addJobWithPriority"
--- @include "includes/deduplicateJob"
--- @include "includes/storeJob"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/handleDuplicatedJob"
--- @include "includes/isQueuePausedOrMaxed"

if parentKey ~= nil then
    if rcall("EXISTS", parentKey) ~= 1 then return -5 end

    parentData = cjson.encode(parent)
end

local jobCounter = rcall("INCR", idKey)

local maxEvents = getOrSetMaxEvents(metaKey)

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

local deduplicationJobId = deduplicateJob(opts['de'], jobId, KEYS[5],
  deduplicationKey, eventsKey, maxEvents, args[1])
if deduplicationJobId then
  return deduplicationJobId
end

-- Store the job.
local delay, priority = storeJob(eventsKey, jobIdKey, jobId, args[3], ARGV[2],
                                 opts, timestamp, parentKey, parentData,
                                 repeatJobKey)

-- Add the job to the prioritized set
local isPausedOrMaxed = isQueuePausedOrMaxed(metaKey, activeKey)
addJobWithPriority( KEYS[1], priorityKey, priority, jobId, priorityCounterKey, isPausedOrMaxed)

-- Emit waiting event
rcall("XADD", eventsKey, "MAXLEN", "~", maxEvents, "*", "event", "waiting",
      "jobId", jobId)

-- Check if this job is a child of another job, if so add it to the parents dependencies
if parentDependenciesKey ~= nil then
    rcall("SADD", parentDependenciesKey, jobIdKey)
end

return jobId .. "" -- convert to string
```

## v1 → v3 change ledger

| v1 (addPrioritizedJob-9) | v3 (SHIPPED — EchoMQ.Lanes.enqueue/5) |
|---|---|
| KEYS[1..9] …,prioritized,…,pc(counter) | keys = [job_key, g:<g>:pending, ring, |
| priority = opts['priority'] -- DATA field | paused, glimit, gactive, wake] (all declared) |
| score = priority*0x100000000 + INCR(pc)%… | ZADD KEYS[2] 0 ARGV[1] -- score-0 lane, ring is the rota |
| ZADD prioritized <packed> jobId -- GLOBAL set | if not SISMEMBER ring & serviceable -> RPUSH ring <g> |
| parentKey/deps = args[5]/args[6] -- DATA roots | -- no prioritized/pc; fairness CONSTRUCTED by rotation |

## Aligned flow (authoritative side-by-side)

```text
v1 (addPrioritizedJob-9)                         v3 (SHIPPED — EchoMQ.Lanes.enqueue/5)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..9] …,prioritized,…,pc(counter)           keys = [job_key, g:<g>:pending, ring,
priority = opts['priority']  -- DATA field               paused, glimit, gactive, wake] (all declared)
score = priority*0x100000000 + INCR(pc)%…        ZADD KEYS[2] 0 ARGV[1]   -- score-0 lane, ring is the rota
ZADD prioritized <packed> jobId  -- GLOBAL set   if not SISMEMBER ring & serviceable -> RPUSH ring <g>
parentKey/deps = args[5]/args[6]  -- DATA roots   -- no prioritized/pc; fairness CONSTRUCTED by rotation
```

## Decision & rationale

**Covers → v3.** Priority enqueue → re-aimed to **per-group fairness**: `Lanes.enqueue/5` admits onto a score-0 per-group lane ZSET and maintains the rotating ring; `Lanes.claim/3` (`lanes.ex`) rotates one step and serves the head. There is **no** numeric-priority script (the only `priorit` hits in `lib/` are admin/metrics comments noting the bus has no `prioritized` set); the v1 packed-score-plus-counter scheme is not ported (`emq.features.md` B.2 row 328; §6 — the v1 lifecycle types retire).

**Decision.** Keep fair lanes as the priority model — the rotating ring replaces the global priority number, giving per-identity fairness over one shared machine; all keys declared and `{q}`-co-located. **PROPOSED** delta (emq.4): intra-group priority is a non-zero lane score on the existing `g:<group>:pending` ZSET — **no new key family**, never a global `prioritized` key or a `pc` counter. The v1 packed-score-plus-secondary-counter scheme does not return.

**BCS** fair lanes give codemojex many-players-on-one-queue isolation (no noisy-neighbour starvation) a single global priority integer cannot. · **EchoMesh** consistency-first / coordinated end — bounded, fair, per-identity service is a server-side invariant computed on the bus, not a client hint a partition could distort. · **[when]** a player's work admitted onto its own lane — one Lanes group per player, no noisy-neighbour starvation.
