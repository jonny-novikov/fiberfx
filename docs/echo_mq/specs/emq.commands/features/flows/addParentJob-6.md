# addParentJob-6  →  EchoMQ.Flows.add/3 + add_bulk/3 (@enqueue_flow/@hold_parent/@enqueue_flow_child, flows.ex)

> Feature: **flows** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   addParentJob-6
--@feature   flows
--@status    SHIPPED (ported)
--@rung      emq.3.1–3.4
--@v1        registry/addParentJob-6.lua   (KEYS arity 6)
--@v3        EchoMQ.Flows.add/3 + add_bulk/3 (@enqueue_flow/@hold_parent/@enqueue_flow_child, flows.ex)
```

## v1 source

`registry/addParentJob-6.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Adds a parent job to the queue by doing the following:
    - Increases the job counter if needed.
    - Creates a new job key with the job data.
    - adds the job to the waiting-children zset

    Input:
      KEYS[1] 'meta'
      KEYS[2] 'id'
      KEYS[3] 'delayed'
      KEYS[4] 'waiting-children'
      KEYS[5] 'completed'
      KEYS[6] events stream key

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
local metaKey = KEYS[1]
local idKey = KEYS[2]

local completedKey = KEYS[5]
local eventsKey = KEYS[6]

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
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/handleDuplicatedJob"
--- @include "includes/storeJob"

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

-- Store the job.
storeJob(eventsKey, jobIdKey, jobId, args[3], ARGV[2], opts, timestamp,
         parentKey, parentData, repeatJobKey)

local waitChildrenKey = KEYS[4]
rcall("ZADD", waitChildrenKey, timestamp, jobId)
rcall("XADD", eventsKey, "MAXLEN", "~", maxEvents, "*", "event",
      "waiting-children", "jobId", jobId)

-- Check if this job is a child of another job, if so add it to the parents dependencies
if parentDependenciesKey ~= nil then
    rcall("SADD", parentDependenciesKey, jobIdKey)
end

return jobId .. "" -- convert to string
```

## v1 → v3 change ledger

| v1 (addParentJob-6) | v3 (SHIPPED — EchoMQ.Flows.add/3, same-queue atomic) |
|---|---|
| parentKey = args[5] -- DATA VALUE | kind-gate JOB on parent + every child id (EMQKIND pre-wire) |
| EXISTS parentKey ? -5 -- key root from data | HSET child state=pending …, parent ARGV[1] -- parent = DATA field |
| parentDependenciesKey = args[6] -- DATA VALUE | ZADD pending 0 <child> -- score-0 mint order |
| SADD parentDependenciesKey jobIdKey -- a SET | HSET parent state=awaiting_children ; SET :dependencies = N |
| of child KEYS, illeg | al -- STRING counter (Fork R2.A); cross-q parent-first, fail-closed |

## Aligned flow (authoritative side-by-side)

```text
v1 (addParentJob-6)                              v3 (SHIPPED — EchoMQ.Flows.add/3, same-queue atomic)
─────────────────────────────────────────       ─────────────────────────────────────────────────
parentKey            = args[5]   -- DATA VALUE   kind-gate JOB on parent + every child id (EMQKIND pre-wire)
EXISTS parentKey ? -5  -- key root from data     HSET child state=pending …, parent ARGV[1]  -- parent = DATA field
parentDependenciesKey = args[6]  -- DATA VALUE   ZADD pending 0 <child>           -- score-0 mint order
SADD parentDependenciesKey jobIdKey  -- a SET     HSET parent state=awaiting_children  ; SET :dependencies = N
                            of child KEYS, illegal -- STRING counter (Fork R2.A); cross-q parent-first, fail-closed
```

## Decision & rationale

**Covers → v3.** Add a parent job for a parent/child flow → `add/3` (parent + flat child list) over the declared §6 subkeys; the same-queue land is one atomic `@enqueue_flow`, the cross-queue land parent-first + fail-closed via `@hold_parent` + `@enqueue_flow_child`. The v1 data-rooted `parentKey`/`parentDependenciesKey` are **not lifted** — the linkage is a `parent` DATA field on each child row, read host-side to drive the parent's *declared* keys.

**Decision.** Keep the as-built shape (already braced, branded-gated, declared-keys, honest-row); every id gated at `Keyspace.job_key/2` (raises pre-wire, INV4). `add_bulk/3` is the v1 `flow_producer add_bulk` parity (SHIPPED emq.3.4). **PROPOSED** delta: a declared `<> ":roster"` subkey (Fork **R2.B**, the v1 `get_dependencies/1` "which children remain" answer v2 dropped for the bare counter) composed exactly like `:dependencies` — so the mesh can list *which* legs remain, never rooting a key in data.

**BCS** the flow is the composite work unit — a parent job whose children are its legs, fanned in by the 14-byte branded id. · **EchoMesh** segmented by construction — a same-queue flow is **consistency-first** (one `{q}` slot, atomic fan-in); a cross-queue flow is **availability-first** (eventually-consistent outbox fan-in, INV5/INV7). · **[when]** a parent job whose children are its legs.
