# updateJobScheduler-12  →  EchoMQ.Repeat.advance/4 + EchoMQ.Pump (@repeat_advance, repeat.ex)

> Feature: **repeat** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   updateJobScheduler-12
--@feature   repeat
--@status    SHIPPED (ported)
--@rung      emq.1
--@v1        registry/updateJobScheduler-12.lua   (KEYS arity 12)
--@v3        EchoMQ.Repeat.advance/4 + EchoMQ.Pump (@repeat_advance, repeat.ex)
```

## v1 source

`registry/updateJobScheduler-12.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Updates a job scheduler and adds next delayed job

  Input:
    KEYS[1]  'repeat' key
    KEYS[2]  'delayed'
    KEYS[3]  'wait' key
    KEYS[4]  'paused' key
    KEYS[5]  'meta'
    KEYS[6]  'prioritized' key
    KEYS[7]  'marker',
    KEYS[8]  'id'
    KEYS[9]  events stream key
    KEYS[10] 'pc' priority counter
    KEYS[11] producer key
    KEYS[12] 'active' key

    ARGV[1] next milliseconds
    ARGV[2] jobs scheduler id
    ARGV[3] Json stringified delayed data
    ARGV[4] msgpacked delayed opts
    ARGV[5] timestamp
    ARGV[6] prefix key
    ARGV[7] producer id

    Output:
      next delayed job id  - OK
]] local rcall = redis.call
local repeatKey = KEYS[1]
local delayedKey = KEYS[2]
local waitKey = KEYS[3]
local pausedKey = KEYS[4]
local metaKey = KEYS[5]
local prioritizedKey = KEYS[6]
local nextMillis = tonumber(ARGV[1])
local jobSchedulerId = ARGV[2]
local timestamp = tonumber(ARGV[5])
local prefixKey = ARGV[6]
local producerId = ARGV[7]
local jobOpts = cmsgpack.unpack(ARGV[4])

-- Includes
--- @include "includes/addJobFromScheduler"
--- @include "includes/getOrSetMaxEvents"
--- @include "includes/getJobSchedulerEveryNextMillis"

local prevMillis = rcall("ZSCORE", repeatKey, jobSchedulerId)

-- Validate that scheduler exists.
-- If it does not exist we should not iterate anymore.
if prevMillis then
    prevMillis = tonumber(prevMillis)

    local schedulerKey = repeatKey .. ":" .. jobSchedulerId
    local schedulerAttributes = rcall("HMGET", schedulerKey, "name", "data", "every", "startDate", "offset")

    local every = tonumber(schedulerAttributes[3])
    local now = tonumber(timestamp)

    -- If every is not found in scheduler attributes, try to get it from job options
    if not every and jobOpts['repeat'] and jobOpts['repeat']['every'] then
        every = tonumber(jobOpts['repeat']['every'])
    end

    if every then
        local startDate = schedulerAttributes[4]
        local jobOptsOffset = jobOpts['repeat'] and jobOpts['repeat']['offset'] or 0
        local offset = schedulerAttributes[5] or jobOptsOffset or 0
        local newOffset

        nextMillis, newOffset = getJobSchedulerEveryNextMillis(prevMillis, every, now, offset, startDate)

        if not offset then
            rcall("HSET", schedulerKey, "offset", newOffset)
            jobOpts['repeat']['offset'] = newOffset
        end
    end

    local nextDelayedJobId = "repeat:" .. jobSchedulerId .. ":" .. nextMillis
    local nextDelayedJobKey = schedulerKey .. ":" .. nextMillis

    local currentDelayedJobId = "repeat:" .. jobSchedulerId .. ":" .. prevMillis

    if producerId == currentDelayedJobId then
        local eventsKey = KEYS[9]
        local maxEvents = getOrSetMaxEvents(metaKey)

        if rcall("EXISTS", nextDelayedJobKey) ~= 1 then

            rcall("ZADD", repeatKey, nextMillis, jobSchedulerId)
            rcall("HINCRBY", schedulerKey, "ic", 1)

            rcall("INCR", KEYS[8])

            -- TODO: remove this workaround in next breaking change,
            -- all job-schedulers must save job data
            local templateData = schedulerAttributes[2] or ARGV[3]

            if templateData and templateData ~= '{}' then
                rcall("HSET", schedulerKey, "data", templateData)
            end

            local delay = nextMillis - now

            -- Fast Clamp delay to minimum of 0
            if delay < 0 then
                delay = 0
            end

            jobOpts["delay"] = delay

            addJobFromScheduler(nextDelayedJobKey, nextDelayedJobId, jobOpts, waitKey, pausedKey, KEYS[12], metaKey,
                prioritizedKey, KEYS[10], delayedKey, KEYS[7], eventsKey, schedulerAttributes[1], maxEvents, ARGV[5],
                templateData or '{}', jobSchedulerId, delay)

            -- TODO: remove this workaround in next breaking change
            if KEYS[11] ~= "" then
                rcall("HSET", KEYS[11], "nrjid", nextDelayedJobId)
            end

            return nextDelayedJobId .. "" -- convert to string
        else
            rcall("XADD", eventsKey, "MAXLEN", "~", maxEvents, "*", "event", "duplicated", "jobId", nextDelayedJobId)
        end
    end
end
```

## v1 → v3 change ledger

| v1 (updateJobScheduler-12) | v3 (SHIPPED — Repeat.advance/4 + Pump) |
|---|---|
| KEYS[1..12] repeat/.../producer/active | keys = [emq:{q}:repeat, emq:{q}:repeat:<name>] |
| prevMillis = ZSCORE(repeat, schedulerId) | if EXISTS KEYS[2] == 0 -> |
| currentId = "repeat:"..id..":"..prevMillis | ZREM KEYS[1] <name> ; return 0 -- sweep dangling member |
| if producerId == currentId -- re-entry guard | ZADD KEYS[1] <next_at> <name> ; return 1 |
| ZADD repeat next id ; INCR id ; addJob.. | -- producer-id guard SUPERSEDED by the pump's single sweep |
| else XADD events duplicated | -- next-at from server TIME (DQ-2c); :advanced \| :absent |

## Aligned flow (authoritative side-by-side)

```text
v1 (updateJobScheduler-12)                       v3 (SHIPPED — Repeat.advance/4 + Pump)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..12] repeat/.../producer/active           keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
prevMillis = ZSCORE(repeat, schedulerId)         if EXISTS KEYS[2] == 0 ->
currentId = "repeat:"..id..":"..prevMillis           ZREM KEYS[1] <name> ; return 0   -- sweep dangling member
if producerId == currentId  -- re-entry guard    ZADD KEYS[1] <next_at> <name> ; return 1
  ZADD repeat next id ; INCR id ; addJob..       -- producer-id guard SUPERSEDED by the pump's single sweep
else XADD events duplicated                      -- next-at from server TIME (DQ-2c); :advanced | :absent
```

## Decision & rationale

**Covers → v3.** Iterate a scheduler (per-occurrence advance) → `advance/4` re-scores the registration to now+`every_ms` and sweeps a dangling member when cancelled mid-sweep; the v1 producer-id re-entry guard is **superseded** by the pump's single owner-started sweep.

**Decision.** Keep `advance/4` + the pump; the producer-id guard needs no data-rooted string (the pump is the single owner-started cadence, a `:transient` opt-in child); `next_at` from server `TIME`. The mid-sweep-cancel sweep is the honest-row, slot-sound replacement for v1's `duplicated` emission.

**BCS** the pump advances each venue's cadence idempotently; a mid-sweep cancel is swept, never resurrected. · **EchoMesh** availability dial — the owner-started cadence keeps occurrences flowing per slot with no cross-slot coordination. · **[when]** the pump advancing each venue's cadence.
