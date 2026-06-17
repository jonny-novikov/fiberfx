# extendLocks-1  →  EchoMQ.Jobs.extend_locks/4 (@extend_locks, jobs.ex:965)

> Feature: **locks** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   extendLocks-1
--@feature   locks
--@status    SHIPPED (ported)
--@rung      emq.2.3 3c6461ff
--@v1        registry/extendLocks-1.lua   (KEYS arity 1)
--@v3        EchoMQ.Jobs.extend_locks/4 (@extend_locks, jobs.ex:965)
```

## v1 source

`registry/extendLocks-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Extend locks for multiple jobs and remove them from the stalled set if successful.
  Return the list of job IDs for which the operation failed.

  KEYS[1] = stalled key
  
  ARGV[1] = baseKey
  ARGV[2] = tokens
  ARGV[3] = jobIds
  ARGV[4] = lockDuration (ms)

  Output:
    An array of failed job IDs. If empty, all succeeded.
]]
local rcall = redis.call

local stalledKey = KEYS[1]
local baseKey = ARGV[1]
local tokens = cmsgpack.unpack(ARGV[2])
local jobIds = cmsgpack.unpack(ARGV[3])
local lockDuration = ARGV[4]

local jobCount = #jobIds
local failedJobs = {}

for i = 1, jobCount, 1 do
    local lockKey = baseKey .. jobIds[i] .. ':lock'
    local jobId = jobIds[i]
    local token = tokens[i]

    local currentToken = rcall("GET", lockKey)
    if currentToken then
        if currentToken == token then
            local setResult = rcall("SET", lockKey, token, "PX", lockDuration)
            if setResult then
                rcall("SREM", stalledKey, jobId)
            else
                table.insert(failedJobs, jobId)
            end
        else
            table.insert(failedJobs, jobId)
        end
    else
        table.insert(failedJobs, jobId)
    end
end

return failedJobs
```

## v1 → v3 change ledger

| v1 (extendLocks-1) | v3 (SHIPPED — EchoMQ.Jobs.extend_locks/4) |
|---|---|
| KEYS=[stalled] ; ARGV baseKey/tokens/ids/dur | keys = [active] ; ARGV base 'emq:{q}:', lease_ms, (id,token)… |
| jobIds = cmsgpack.unpack(ARGV[3]) | now = TIME -- ONE read scores the whole batch |
| lockKey = baseKey..jobId..':lock' -- DATA-ROOT | jk = base..'job:'..id -- slot-rooted ARGV (carries {q}, S-6) |
| GET lockKey == token ? SET …PX dur -- per-str | HGET jk 'attempts' == token ? |
| else insert failedJobs | ZADD active now+lease <id> -- lease IS the score |
| return failedJobs | else insert failed ; return failed |

## Aligned flow (authoritative side-by-side)

```text
v1 (extendLocks-1)                               v3 (SHIPPED — EchoMQ.Jobs.extend_locks/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS=[stalled] ; ARGV baseKey/tokens/ids/dur     keys = [active] ; ARGV base 'emq:{q}:', lease_ms, (id,token)…
jobIds = cmsgpack.unpack(ARGV[3])                now = TIME   -- ONE read scores the whole batch
lockKey = baseKey..jobId..':lock'   -- DATA-ROOT  jk = base..'job:'..id   -- slot-rooted ARGV (carries {q}, S-6)
GET lockKey == token ? SET …PX dur   -- per-str   HGET jk 'attempts' == token ?
else insert failedJobs                             ZADD active now+lease <id>   -- lease IS the score
return failedJobs                                else insert failed ; return failed
```

## Decision & rationale

**Covers → v3.** Batch-renew many leases → one `TIME` read, variadic `(id,token)` ARGV pairs slot-rooted off `KEYS[1]=active`, returns `failed` (drives the `Locks` beat); the v1 per-loop `base..id..":lock"` synthesized from a `cmsgpack`-unpacked **data value** is the canonical declared-keys violation, retired.

**Decision.** Keep the as-built variadic A-1 form (the **2026-06-14 slot-rooted-ARGV ruling**, design §1 S-6 — an ARGV base may root an in-script derived key iff it provably carries the `{q}` slot); the single `TIME` read amortizes the whole held set. **PROPOSED**: surface `Locks.extend/1`'s `{extended, dropped}` as the plane's telemetry.

**BCS** one server-clock read amortizes the whole held set — a bulk-fence for a worker draining many branded jobs. · **EchoMesh** the single-`TIME` batch keeps every lease on one consistency clock — the availability-corner lease, fleet-wide. · **[when]** one server-clock read amortizing the whole held set for a worker draining many branded jobs.
