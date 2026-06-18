# pause-7  →  EchoMQ.Admin.pause/2 + resume/2 (@pause/@resume, admin.ex; a paused FIELD on emq:{q}:meta, no wait↔paused RENAME)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   pause-7
--@feature   lifecycle
--@status    SHIPPED (ported)
--@rung      emq.2.2
--@v1        registry/pause-7.lua   (KEYS arity 7)
--@v3        EchoMQ.Admin.pause/2 + resume/2 (@pause/@resume, admin.ex; a paused FIELD on emq:{q}:meta, no wait↔paused RENAME)
```

## v1 source

`registry/pause-7.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Pauses or resumes a queue globably.

  Input:
    KEYS[1] 'wait' or 'paused''
    KEYS[2] 'paused' or 'wait'
    KEYS[3] 'meta'
    KEYS[4] 'prioritized'
    KEYS[5] events stream key
    KEYS[6] 'delayed'
    KEYS|7] 'marker'

    ARGV[1] 'paused' or 'resumed'

  Event:
    publish paused or resumed event.
]]
local rcall = redis.call

-- Includes
--- @include "includes/addDelayMarkerIfNeeded"

local markerKey = KEYS[7]
local hasJobs = rcall("EXISTS", KEYS[1]) == 1
--TODO: check this logic to be reused when changing a delay
if hasJobs then rcall("RENAME", KEYS[1], KEYS[2]) end

if ARGV[1] == "paused" then
    rcall("HSET", KEYS[3], "paused", 1)
    rcall("DEL", markerKey)
else
    rcall("HDEL", KEYS[3], "paused")

    if hasJobs or rcall("ZCARD", KEYS[4]) > 0 then
        -- Add marker if there are waiting or priority jobs
        rcall("ZADD", markerKey, 0, "0")
    else
        addDelayMarkerIfNeeded(markerKey, KEYS[6])
    end
end

rcall("XADD", KEYS[5], "*", "event", ARGV[1]);
```

## v1 → v3 change ledger

| v1 (pause-7) | v3 (SHIPPED — EchoMQ.Admin.@pause / @resume) |
|---|---|
| KEYS wait\|paused, paused\|wait, meta, marker | @pause: keys = [emq:{q}:meta] |
| EXISTS KEYS[1] ? RENAME KEYS[1] KEYS[2] | HSET KEYS[1] paused '1' ; return 1 |
| -- physically MOVE the whole list | @resume: keys = [emq:{q}:meta] |
| "paused" -> HSET meta paused 1 ; DEL marker | HDEL KEYS[1] paused ; return 1 |
| else HDEL meta paused ; addDelayMarkerIfNeeded | -- no wait↔paused RENAME (one pending set) |
| XADD events <event> | -- claim/gclaim BYTE-FROZEN ; paused read first -> :empty |

## Aligned flow (authoritative side-by-side)

```text
v1 (pause-7)                                     v3 (SHIPPED — EchoMQ.Admin.@pause / @resume)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS wait|paused, paused|wait, meta, marker      @pause:  keys = [emq:{q}:meta]
EXISTS KEYS[1] ? RENAME KEYS[1] KEYS[2]            HSET KEYS[1] paused '1' ; return 1
  -- physically MOVE the whole list              @resume: keys = [emq:{q}:meta]
"paused" -> HSET meta paused 1 ; DEL marker        HDEL KEYS[1] paused ; return 1
else HDEL meta paused ; addDelayMarkerIfNeeded   -- no wait↔paused RENAME (one pending set)
XADD events <event>                              -- claim/gclaim BYTE-FROZEN ; paused read first -> :empty
```

## Decision & rationale

**Covers → v3.** Pause/resume globally (RENAME `wait`↔`paused`, set/clear `meta.paused`, manage the delay marker, XADD a `paused`/`resumed` event) → FORM b: a `paused` FIELD on the declared `emq:{q}:meta`; the claim paths read it first; no RENAME (one `pending` set), `@claim`/`@gclaim` byte-frozen.

**Decision.** `Jobs.claim/3` / `Lanes.claim/3` read the `paused` field first and answer `:empty` (FORM b, D-2). The v1 marker/`addDelayMarkerIfNeeded` machinery does not survive (the `schedule` run-at score is the visibility fence); the `paused`/`resumed` event PUBLISH rides the emq.2.3 watch plane (`EchoMQ.Events`), not this script. The claim scripts stay byte-frozen — pause is an additive gate, not a wire break.

**BCS** an operator quiescing a runaway venue lane's claiming during an incident without moving the backlog. · **EchoMesh** consistency-side — a single `meta` field flip, partition-local. · **[when]** quiescing a runaway venue lane without moving the backlog.
