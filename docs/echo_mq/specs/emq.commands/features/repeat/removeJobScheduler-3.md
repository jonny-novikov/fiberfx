# removeJobScheduler-3  →  EchoMQ.Repeat.cancel/3 (@repeat_cancel, repeat.ex)

> Feature: **repeat** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   removeJobScheduler-3
--@feature   repeat
--@status    SHIPPED (ported)
--@rung      emq.1
--@v1        registry/removeJobScheduler-3.lua   (KEYS arity 3)
--@v3        EchoMQ.Repeat.cancel/3 (@repeat_cancel, repeat.ex)
```

## v1 source

`registry/removeJobScheduler-3.lua` — the original legacy v1 command, verbatim.

```lua

--[[
  Removes a job scheduler and its next scheduled job.
  Input:
    KEYS[1] job schedulers key
    KEYS[2] delayed jobs key
    KEYS[3] events key

    ARGV[1] job scheduler id
    ARGV[2] prefix key

  Output:
    0 - OK
    1 - Missing repeat job

  Events:
    'removed'
]]
local rcall = redis.call

-- Includes
--- @include "includes/removeJobKeys"

local jobSchedulerId = ARGV[1]
local prefix = ARGV[2]

local millis = rcall("ZSCORE", KEYS[1], jobSchedulerId)

if millis then
  -- Delete next programmed job.
  local delayedJobId = "repeat:" .. jobSchedulerId .. ":" .. millis
  if(rcall("ZREM", KEYS[2], delayedJobId) == 1) then
    removeJobKeys(prefix .. delayedJobId)
    rcall("XADD", KEYS[3], "*", "event", "removed", "jobId", delayedJobId, "prev", "delayed")
  end
end

if(rcall("ZREM", KEYS[1], jobSchedulerId) == 1) then
  rcall("DEL", KEYS[1] .. ":" .. jobSchedulerId)
  return 0
end

return 1
```

## v1 → v3 change ledger

| v1 (removeJobScheduler-3) | v3 (SHIPPED — EchoMQ.Repeat.cancel/3) |
|---|---|
| KEYS[1..3] repeat, delayed, events | keys = [emq:{q}:repeat, emq:{q}:repeat:<name>] |
| millis = ZSCORE(repeat, id) | removed = ZREM KEYS[1] <name> |
| delayedJobId = "repeat:"..id..":"..millis | DEL KEYS[2] |
| ZREM delayed ; removeJobKeys(..) -- DATA-id | return removed -- :cancelled \| :absent |
| ZREM repeat id ; DEL repeat:id | -- next-job removal dropped (occurrence is a branded JOB) |

## Aligned flow (authoritative side-by-side)

```text
v1 (removeJobScheduler-3)                        v3 (SHIPPED — EchoMQ.Repeat.cancel/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..3] repeat, delayed, events               keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
millis = ZSCORE(repeat, id)                      removed = ZREM KEYS[1] <name>
delayedJobId = "repeat:"..id..":"..millis         DEL KEYS[2]
  ZREM delayed ; removeJobKeys(..)  -- DATA-id   return removed                     -- :cancelled | :absent
ZREM repeat id ; DEL repeat:id                   -- next-job removal dropped (occurrence is a branded JOB)
```

## Decision & rationale

**Covers → v3.** Remove a scheduler + its one next-programmed job → `cancel/3` removes the registry member + record over the two declared keys; the v1 "delete the next programmed job" half is *not lifted* (the next occurrence is a freshly-minted `JOB`).

**Decision.** Keep `cancel/3` verbatim in shape; its two keys are `{q}`-co-located by grammar (S-6). The data-rooted next-occurrence removal routes through the Jobs surface against a declared key, never an id splice.

**BCS** cancelling a cadence stops future mints cleanly; in-flight occurrences drain as ordinary jobs. · **EchoMesh** consistency-side — cancellation is a single-slot, partition-local mutation. · **[when]** cancelling a venue's cadence.
