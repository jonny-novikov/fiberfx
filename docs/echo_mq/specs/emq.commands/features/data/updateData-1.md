# updateData-1  →  EchoMQ.Jobs.update_data/4 (@update_data, jobs.ex)

> Feature: **data** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   updateData-1
--@feature   data
--@status    SHIPPED (ported)
--@rung      emq.2.2
--@v1        registry/updateData-1.lua   (KEYS arity 1)
--@v3        EchoMQ.Jobs.update_data/4 (@update_data, jobs.ex)
```

## v1 source

`registry/updateData-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Update job data

  Input:
    KEYS[1] Job id key

    ARGV[1] data

  Output:
    0 - OK
   -1 - Missing job.
]]
local rcall = redis.call

if rcall("EXISTS",KEYS[1]) == 1 then -- // Make sure job exists
  rcall("HSET", KEYS[1], "data", ARGV[1])
  return 0
else
  return -1
end
```

## v1 → v3 change ledger

| v1 (updateData-1) | v3 (SHIPPED — EchoMQ.Jobs.update_data/4) |
|---|---|
| KEYS[1] job key ; ARGV[1] data | keys = [Keyspace.job_key(q, id)] (gated) |
| if EXISTS KEYS[1] == 1 then | if EXISTS KEYS[1] == 0 -> return -1 -- -1 → {:error,:gone} |
| HSET KEYS[1] "data" ARGV[1] ; return 0 | HSET KEYS[1] 'payload' ARGV[1] -- "data" → 'payload' |
| else return -1 end | return 1 |

## Aligned flow (authoritative side-by-side)

```text
v1 (updateData-1)                                v3 (SHIPPED — EchoMQ.Jobs.update_data/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] job key ; ARGV[1] data                   keys = [Keyspace.job_key(q, id)]  (gated)
if EXISTS KEYS[1] == 1 then                       if EXISTS KEYS[1] == 0 -> return -1   -- -1 → {:error,:gone}
  HSET KEYS[1] "data" ARGV[1] ; return 0          HSET KEYS[1] 'payload' ARGV[1]      -- "data" → 'payload'
else return -1 end                                return 1
```

## Decision & rationale

**Covers → v3.** Replace a job's `data` blob → in-place `HSET` of the as-built `payload` field over one declared key; the v1 `data` field renames to `payload`, the missing-job sentinel maps `-1 → {:error, :gone}`. One of the few v1 forms already shape-legal — `KEYS[1]` is a fully-formed job key, not data-rooted.

**Decision.** Keep the emq.2.2 form verbatim — one declared `KEYS[1]`, the branded id gated at `Keyspace.job_key/2` (INV5), `payload` on the row. **PROPOSED** delta: the immutability discipline at the stream tier (emq3.2) — for a job whose result becomes a retained, replayable record, a payload mutation is modeled as a new appended fact, not an in-place `HSET`, so a fold-to-state replay reconstructs true history; the queue-tier row stays mutable working state (in-place replace correct).

**BCS** re-arms a job's payload before claim (settlement/reconciliation re-targets). · **EchoMesh** consistency-first — a single-slot `HSET` on the owning node, refuses (`:gone`) on a missing row, no cross-region write. · **[when]** re-arming a job's payload before claim (a settlement/reconciliation re-target).
