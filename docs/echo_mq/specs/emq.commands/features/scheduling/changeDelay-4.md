# changeDelay-4  →  reschedule/4 (proposed) beside @schedule/@promote

> Feature: **scheduling** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   changeDelay-4
--@feature   scheduling
--@status    NOT YET (proposed)
--@rung      emq.1
--@v1        registry/changeDelay-4.lua   (KEYS arity 4)
--@v3        reschedule/4 (proposed) beside @schedule/@promote
```

## v1 source

`registry/changeDelay-4.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Change job delay when it is in delayed set.
  Input:
    KEYS[1] delayed key
    KEYS[2] meta key
    KEYS[3] marker key
    KEYS[4] events stream

    ARGV[1] delay
    ARGV[2] timestamp
    ARGV[3] the id of the job
    ARGV[4] job key

  Output:
    0 - OK
   -1 - Missing job.
   -3 - Job not in delayed set.

  Events:
    - delayed key.
]]
local rcall = redis.call

-- Includes
--- @include "includes/addDelayMarkerIfNeeded"
--- @include "includes/getDelayedScore"
--- @include "includes/getOrSetMaxEvents"

if rcall("EXISTS", ARGV[4]) == 1 then
  local jobId = ARGV[3]

  local delay = tonumber(ARGV[1])
  local score, delayedTimestamp = getDelayedScore(KEYS[1], ARGV[2], delay)

  local numRemovedElements = rcall("ZREM", KEYS[1], jobId)

  if numRemovedElements < 1 then
    return -3
  end

  rcall("HSET", ARGV[4], "delay", delay)
  rcall("ZADD", KEYS[1], score, jobId)

  local maxEvents = getOrSetMaxEvents(KEYS[2])

  rcall("XADD", KEYS[4], "MAXLEN", "~", maxEvents, "*", "event", "delayed",
    "jobId", jobId, "delay", delayedTimestamp)

  -- mark that a delayed job is available
  addDelayMarkerIfNeeded(KEYS[3], KEYS[1])

  return 0
else
  return -1
end
```

## v1 → v3 change ledger

| v1 (changeDelay-4) | v3 (NOT YET — reschedule/4 proposed) |
|---|---|
| KEYS[1..4] delayed,meta,marker,events | keys = [schedule, job_key] -- job key DECLARED, not ARGV[4] |
| ARGV[4] = job key -- DATA-supplied operand | re-ZADD the schedule member at a TIME-derived run-at (DQ-2c) |
| EXISTS ARGV[4] ? | not on schedule -> EMQSTATE ; missing -> :gone |
| score = getDelayedScore(..) -- (ts+delay)<<12 | -- v1 12-bit bit-baking dissolves (mint already orders) |
| ZREM ; HSET ARGV[4] delay ; ZADD ; marker | -- marker machinery does not return |

## Aligned flow (authoritative side-by-side)

```text
v1 (changeDelay-4)                               v3 (NOT YET — reschedule/4 proposed)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..4] delayed,meta,marker,events            keys = [schedule, job_key]   -- job key DECLARED, not ARGV[4]
ARGV[4] = job key  -- DATA-supplied operand      re-ZADD the schedule member at a TIME-derived run-at (DQ-2c)
EXISTS ARGV[4] ?                                 not on schedule -> EMQSTATE ; missing -> :gone
  score = getDelayedScore(..)  -- (ts+delay)<<12 -- v1 12-bit bit-baking dissolves (mint already orders)
  ZREM ; HSET ARGV[4] delay ; ZADD ; marker      -- marker machinery does not return
```

## Decision & rationale

**Covers → v3.** Re-score a job already in `delayed` to a new delay → no `change_delay` exists (grep-confirmed); add `reschedule/4` — re-`ZADD` the `schedule` member under a server-`TIME`-derived run-at, the job key a **declared** key (not the v1 data-supplied `ARGV[4]`).

**Decision.** A declared-keys `reschedule/4` (queue, job_id, new_run_at | new_delay) over `[schedule, job_key]`, branded id gated at `Keyspace.job_key/2`, server clock (DQ-2c); additive, no new score scheme. *(Schematic withheld per NO-INVENT — prose until the rung authors it.)*

**BCS** lets an operator push out / pull in a scheduled or repeatable job without drop-and-re-add. · **EchoMesh** a CP-side admin write; staleness here is a *budget knob* (M4 dial), not an availability path. · **[when]** an operator pushing out a scheduled job during an incident.
