# addLog-2  →  EchoMQ.Jobs.add_log/5 + get_job_logs/3 (@add_log, jobs.ex)

> Feature: **data** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   addLog-2
--@feature   data
--@status    SHIPPED (ported)
--@rung      emq.2.2
--@v1        registry/addLog-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Jobs.add_log/5 + get_job_logs/3 (@add_log, jobs.ex)
```

## v1 source

`registry/addLog-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Add job log

  Input:
    KEYS[1] job id key
    KEYS[2] job logs key

    ARGV[1] id
    ARGV[2] log
    ARGV[3] keepLogs

  Output:
    -1 - Missing job.
]]
local rcall = redis.call

if rcall("EXISTS", KEYS[1]) == 1 then -- // Make sure job exists
  local logCount = rcall("RPUSH", KEYS[2], ARGV[2])

  if ARGV[3] ~= '' then
    local keepLogs = tonumber(ARGV[3])
    rcall("LTRIM", KEYS[2], -keepLogs, -1)

    return math.min(keepLogs, logCount)
  end

  return logCount
else
  return -1
end
```

## v1 → v3 change ledger

| v1 (addLog-2) | v3 (SHIPPED — EchoMQ.Jobs.add_log/5) |
|---|---|
| KEYS[1]=job, KEYS[2]=logs (separately passed) | keys = [job_key(q,id), job_key(q,id)..":logs"] |
| count = RPUSH KEYS[2] ARGV[2] | if EXISTS KEYS[1] == 0 -> return -1 -- logs DERIVED → slot-sound |
| if ARGV[3] ~= '' then | count = RPUSH KEYS[2] ARGV[1] |
| LTRIM KEYS[2] -keepLogs -1 | if ARGV[2] ~= '' then keep = tonumber(ARGV[2]) |
| return min(keepLogs, count) end | LTRIM KEYS[2] -keep -1 ; if keep < count -> return keep |
| return count | return count -- {:ok, n} \| {:error, :gone} |

## Aligned flow (authoritative side-by-side)

```text
v1 (addLog-2)                                     v3 (SHIPPED — EchoMQ.Jobs.add_log/5)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=job, KEYS[2]=logs (separately passed)     keys = [job_key(q,id), job_key(q,id)..":logs"]
count = RPUSH KEYS[2] ARGV[2]                      if EXISTS KEYS[1] == 0 -> return -1   -- logs DERIVED → slot-sound
if ARGV[3] ~= '' then                              count = RPUSH KEYS[2] ARGV[1]
  LTRIM KEYS[2] -keepLogs -1                        if ARGV[2] ~= '' then keep = tonumber(ARGV[2])
  return min(keepLogs, count) end                    LTRIM KEYS[2] -keep -1 ; if keep < count -> return keep
return count                                       return count       -- {:ok, n} | {:error, :gone}
```

## Decision & rationale

**Covers → v3.** Append a line to a job's logs (keep-N trim) → `RPUSH` + optional `LTRIM` with an honest returned count. The model A-1-clean re-derivation: instead of the v1 *separately-passed* `KEYS[2]`, the logs list key is **derived from the declared row key** (`job_key(q,id) <> ":logs"`), provably sharing the braced `{q}` slot (the §6 `:logs` subkey).

**Decision.** Keep the emq.2.2 form — both keys declared and co-located by grammar (S-1 / the co-location law), keep-N trim and honest count preserved; `add_log/5` returns `{:ok, n}`/`{:error, :gone}`, `get_job_logs/3` `LRANGE`s the list. **PROPOSED**: retention-as-policy for the trimmed-away lines (emq3.4/3.5) — the `:logs` keep-N is a per-job staleness budget; deep history that must survive box-loss folds to the `EchoStore.Graft` archive (local CubDB → Tigris) rather than being silently `LTRIM`med to nothing.

**BCS** per-job audit trail for a scoring/settlement worker's diagnostics. · **EchoMesh** consistency-first but bounded — the `:logs` list co-locates by hashtag; retained-but-trimmed, a staleness-budget candidate for the archive. · **[when]** the per-job audit trail a scoring/settlement worker writes for diagnostics.
