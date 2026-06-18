# moveToActive-11  →  EchoMQ.Jobs.claim/4 (@claim, jobs.ex) + grouped EchoMQ.Lanes.claim/3 (@gclaim, lanes.ex)

> Feature: **claim** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   moveToActive-11
--@feature   claim
--@status    SHIPPED (ported)
--@rung      emq.0/1
--@v1        registry/moveToActive-11.lua   (KEYS arity 11)
--@v3        EchoMQ.Jobs.claim/4 (@claim, jobs.ex) + grouped EchoMQ.Lanes.claim/3 (@gclaim, lanes.ex)
```

## v1 source

`registry/moveToActive-11.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Move next job to be processed to active, lock it and fetch its data. The job
  may be delayed, in that case we need to move it to the delayed set instead.

  This operation guarantees that the worker owns the job during the lock
  expiration time. The worker is responsible of keeping the lock fresh
  so that no other worker picks this job again.

  Input:
    KEYS[1] wait key
    KEYS[2] active key
    KEYS[3] prioritized key
    KEYS[4] stream events key
    KEYS[5] stalled key

    -- Rate limiting
    KEYS[6] rate limiter key
    KEYS[7] delayed key

    -- Delayed jobs
    KEYS[8] paused key
    KEYS[9] meta key
    KEYS[10] pc priority counter

    -- Marker
    KEYS[11] marker key

    -- Arguments
    ARGV[1] key prefix
    ARGV[2] timestamp
    ARGV[3] opts

    opts - token - lock token
    opts - lockDuration
    opts - limiter
    opts - name - worker name
]]
local rcall = redis.call
local waitKey = KEYS[1]
local activeKey = KEYS[2]
local eventStreamKey = KEYS[4]
local rateLimiterKey = KEYS[6]
local delayedKey = KEYS[7]
local opts = cmsgpack.unpack(ARGV[3])

-- Includes
--- @include "includes/getNextDelayedTimestamp"
--- @include "includes/getRateLimitTTL"
--- @include "includes/getTargetQueueList"
--- @include "includes/moveJobFromPrioritizedToActive"
--- @include "includes/prepareJobForProcessing"
--- @include "includes/promoteDelayedJobs"

local target, isPausedOrMaxed, rateLimitMax, rateLimitDuration = getTargetQueueList(KEYS[9],
    activeKey, waitKey, KEYS[8])

-- Check if there are delayed jobs that we can move to wait.
local markerKey = KEYS[11]
promoteDelayedJobs(delayedKey, markerKey, target, KEYS[3], eventStreamKey, ARGV[1],
                   ARGV[2], KEYS[10], isPausedOrMaxed)

local maxJobs = tonumber(rateLimitMax or (opts['limiter'] and opts['limiter']['max']))
local expireTime = getRateLimitTTL(maxJobs, rateLimiterKey)

-- Check if we are rate limited first.
if expireTime > 0 then return {0, 0, expireTime, 0} end

-- paused or maxed queue
if isPausedOrMaxed then return {0, 0, 0, 0} end

local limiterDuration = (opts['limiter'] and opts['limiter']['duration']) or rateLimitDuration

-- no job ID, try non-blocking move from wait to active
local jobId = rcall("RPOPLPUSH", waitKey, activeKey)

-- Markers in waitlist DEPRECATED in v5: Will be completely removed in v6.
if jobId and string.sub(jobId, 1, 2) == "0:" then
    rcall("LREM", activeKey, 1, jobId)
    jobId = rcall("RPOPLPUSH", waitKey, activeKey)
end

if jobId then
    return prepareJobForProcessing(ARGV[1], rateLimiterKey, eventStreamKey, jobId, ARGV[2],
                                   maxJobs, limiterDuration, markerKey, opts)
else
    jobId = moveJobFromPrioritizedToActive(KEYS[3], activeKey, KEYS[10])
    if jobId then
        return prepareJobForProcessing(ARGV[1], rateLimiterKey, eventStreamKey, jobId, ARGV[2],
                                       maxJobs, limiterDuration, markerKey, opts)
    end
end

-- Return the timestamp for the next delayed job if any.
local nextTimestamp = getNextDelayedTimestamp(delayedKey)
if nextTimestamp ~= nil then return {0, 0, 0, nextTimestamp} end

return {0, 0, 0, 0}
```

## v1 → v3 change ledger

| v1 (moveToActive-11) | v3 (SHIPPED — EchoMQ.Jobs.claim/4) |
|---|---|
| KEYS[1..11] wait,active,prioritized,...,marker | keys = [pending, active] ; ARGV base 'emq:{q}:job:' |
| jobId = RPOPLPUSH wait active | popped = ZPOPMIN KEYS[1] -- mint order = order theorem |
| else moveJobFromPrioritizedToActive (ZPOPMIN) | jk = ARGV[1] .. id -- ARGV base carries {q} (S-6) |
| prepareJobForProcessing: SET <prefix><id>:lock | att = HINCRBY jk attempts 1 -- the fencing TOKEN (no :lock) |
| PX lockDuration -- DATA-rooted | now = TIME ; ZADD KEYS[2] now+lease id -- lease IS active score |
| HGETALL row ; emit active event | return {id, HGET jk payload, att} -- pause read FIRST -> :empty |

## Aligned flow (authoritative side-by-side)

```text
v1 (moveToActive-11)                             v3 (SHIPPED — EchoMQ.Jobs.claim/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..11] wait,active,prioritized,...,marker   keys = [pending, active] ; ARGV base 'emq:{q}:job:'
jobId = RPOPLPUSH wait active                    popped = ZPOPMIN KEYS[1]            -- mint order = order theorem
  else moveJobFromPrioritizedToActive (ZPOPMIN)  jk = ARGV[1] .. id                 -- ARGV base carries {q} (S-6)
prepareJobForProcessing: SET <prefix><id>:lock   att = HINCRBY jk attempts 1        -- the fencing TOKEN (no :lock)
  PX lockDuration              -- DATA-rooted     now = TIME ; ZADD KEYS[2] now+lease id  -- lease IS active score
HGETALL row ; emit active event                  return {id, HGET jk payload, att}  -- pause read FIRST -> :empty
```

## Decision & rationale

**Covers → v3.** The worker's fetch primitive — move the next eligible job to `active`, lock it, return its row → `ZPOPMIN pending` + a server-clock lease; the separate `:lock` string and the 3-structure fetch (wait LIST + prioritized ZSET + delayed ZSET) are retired (mint order IS the order theorem).

**Decision.** Keep the as-built `@claim` as canonical — declared `[pending, active]`, the per-job key derived in-script as `ARGV[1] .. id` rooted in the declared queue base (slot-sound, S-6 2026-06-14 ARGV-rooting clarification), server-clock lease, branded id gated host-side at `Keyspace.job_key/2`. **PROPOSED**: the lane-aware `@gclaim` (`LMOVE ring ring LEFT RIGHT` rotates one identity, then `ZPOPMIN` that lane) becomes the mesh-facing default — a node claims only the books it owns; the client-side `LMPOP`/`ZMPOP` stays rejected (one atomic Lua transition, design §12.2).

**BCS** the single-writer claim per player — work is drawn atomically and the lease is the only ownership proof, so the scorer that settles a guess is its sole holder. · **EchoMesh** consistency-first (§4 row 24) — the scoring surface refuses a second writer rather than risk divergence under partition. · **[when]** a scorer claiming one player's work, the lease the only ownership proof.
