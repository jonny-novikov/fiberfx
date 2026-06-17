# updateProgress-3  →  EchoMQ.Jobs.update_progress/4 (@update_progress, jobs.ex:720; the v2 form is a PUBLISH emq:{q}:events, NOT an XADD — D-5/D-6)

> Feature: **data** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   updateProgress-3
--@feature   data
--@status    SHIPPED (ported)
--@rung      emq.2.2 76fc947c
--@v1        registry/updateProgress-3.lua   (KEYS arity 3)
--@v3        EchoMQ.Jobs.update_progress/4 (@update_progress, jobs.ex:720; the v2 form is a PUBLISH emq:{q}:events, NOT an XADD — D-5/D-6)
```

## v1 source

`registry/updateProgress-3.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Update job progress

  Input:
    KEYS[1] Job id key
    KEYS[2] event stream key
    KEYS[3] meta key

    ARGV[1] id
    ARGV[2] progress

  Output:
     0 - OK
    -1 - Missing job.

  Event:
    progress(jobId, progress)
]]
local rcall = redis.call

-- Includes
--- @include "includes/getOrSetMaxEvents"

if rcall("EXISTS", KEYS[1]) == 1 then -- // Make sure job exists
    local maxEvents = getOrSetMaxEvents(KEYS[3])

    rcall("HSET", KEYS[1], "progress", ARGV[2])
    rcall("XADD", KEYS[2], "MAXLEN", "~", maxEvents, "*", "event", "progress",
          "jobId", ARGV[1], "data", ARGV[2]);
    return 0
else
    return -1
end
```

## v1 → v3 change ledger

| v1 (updateProgress-3) | v3 (SHIPPED — EchoMQ.Jobs.update_progress/4) |
|---|---|
| KEYS[1]=job, KEYS[2]=stream, KEYS[3]=meta | keys = [Keyspace.job_key(q, id)] |
| maxEvents = getOrSetMaxEvents(KEYS[3]) -- DATA | if EXISTS KEYS[1] == 0 -> return -1 |
| HSET KEYS[1] "progress" ARGV[2] | HSET KEYS[1] 'progress' ARGV[1] |
| XADD KEYS[2] MAXLEN ~ maxEvents * event progress | PUBLISH ARGV[3]..'events' cjson{event,job,progress} |
| jobId ARGV[1] data ARGV[2] | -- D-5/D-6: a PUBLISH, not an XADD ; no meta maxLen read |

## Aligned flow (authoritative side-by-side)

```text
v1 (updateProgress-3)                            v3 (SHIPPED — EchoMQ.Jobs.update_progress/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=job, KEYS[2]=stream, KEYS[3]=meta        keys = [Keyspace.job_key(q, id)]
maxEvents = getOrSetMaxEvents(KEYS[3]) -- DATA    if EXISTS KEYS[1] == 0 -> return -1
HSET KEYS[1] "progress" ARGV[2]                   HSET KEYS[1] 'progress' ARGV[1]
XADD KEYS[2] MAXLEN ~ maxEvents * event progress  PUBLISH ARGV[3]..'events' cjson{event,job,progress}
  jobId ARGV[1] data ARGV[2]                      -- D-5/D-6: a PUBLISH, not an XADD ; no meta maxLen read
```

## Decision & rationale

**Covers → v3.** Write a job's `progress` + emit a `progress` event → field-write plus a connector `PUBLISH` onto the per-queue channel `emq:{q}:events`. The v1 `XADD … MAXLEN ~ <maxEvents>` and its `getOrSetMaxEvents` meta read are deliberately not reproduced — a channel is not a slot-routed key (no §6 key type, no new transport; rides the RESP3 pub/sub seam).

**Decision.** Keep the field-write + registered-event form; v2 collapsed the per-job progress stream into a PUBLISH whose channel derives from the *declared* queue base root. The event name rides the payload's `event` field (one channel per queue, dispatched by `EchoMQ.Events` at emq.2.3). **PROPOSED**: where a durable, replayable progress *log* is needed (audit, time-travel), it lands as branded-id stream records on the certified wire under declared retention (emq3.2) — not the v1 ad-hoc `XADD`; the transient progress *signal* stays a PUBLISH.

**BCS** a long-running settlement/pricing job's heartbeat the operator dashboard watches. · **EchoMesh** availability-first observability edge — a subscriber-less `PUBLISH` is a no-op; the watch plane degrades, never blocks the write. · **[when]** a long-running settlement/pricing job's heartbeat the operator dashboard watches.
