# getStateV2-8  →  folded into EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getStateV2-8
--@feature   metrics
--@status    SHIPPED (subsumed)
--@rung      emq.2.1
--@v1        registry/getStateV2-8.lua   (KEYS arity 8)
--@v3        folded into EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex)
```

## v1 source

`registry/getStateV2-8.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get a job state

  Input: 
    KEYS[1] 'completed' key,
    KEYS[2] 'failed' key
    KEYS[3] 'delayed' key
    KEYS[4] 'active' key
    KEYS[5] 'wait' key
    KEYS[6] 'paused' key
    KEYS[7] 'waiting-children' key
    KEYS[8] 'prioritized' key

    ARGV[1] job id
  Output:
    'completed'
    'failed'
    'delayed'
    'active'
    'waiting'
    'waiting-children'
    'unknown'
]]
local rcall = redis.call

if rcall("ZSCORE", KEYS[1], ARGV[1]) then
  return "completed"
end

if rcall("ZSCORE", KEYS[2], ARGV[1]) then
  return "failed"
end

if rcall("ZSCORE", KEYS[3], ARGV[1]) then
  return "delayed"
end

if rcall("ZSCORE", KEYS[8], ARGV[1]) then
  return "prioritized"
end

if rcall("LPOS", KEYS[4] , ARGV[1]) then
  return "active"
end

if rcall("LPOS", KEYS[5] , ARGV[1]) then
  return "waiting"
end

if rcall("LPOS", KEYS[6] , ARGV[1]) then
  return "waiting"
end

if rcall("ZSCORE", KEYS[7] , ARGV[1]) then
  return "waiting-children"
end

return "unknown"
```

## v1 → v3 change ledger

| v1 (getStateV2-8) | v3 (SHIPPED — subsumed; no separate verb) |
|---|---|
| KEYS[1..8]; ARGV[1]=id -- same as getState | one canonical state read: get_job_state/3 |
| LPOS KEYS[4] id ~= false -> "active" | -- the body is @state_lookup under #getstate-8 |
| -- LPOS, cheaper than LRANGE 0 -1 | -- no wait/paused/active LIST -> LIST-membership |
| ZSET probes unchanged | -- question (and the v1/V2 split) MOOT |

## Aligned flow (authoritative side-by-side)

```text
v1 (getStateV2-8)                                v3 (SHIPPED — subsumed; no separate verb)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..8]; ARGV[1]=id  -- same as getState      one canonical state read: get_job_state/3
LPOS KEYS[4] id ~= false -> "active"             -- the body is @state_lookup under #getstate-8
  -- LPOS, cheaper than LRANGE 0 -1              -- no wait/paused/active LIST -> LIST-membership
ZSET probes unchanged                            --   question (and the v1/V2 split) MOOT
```

## Decision & rationale

**Covers → v3.** The newer-Valkey `getState` variant (`LPOS` instead of `LRANGE`+host scan) → **no separate verb**. The v1 `getState`-vs-`V2` split exists only because v1 keeps wait/paused/active as LISTs; the bus has no such LISTs (all four states are ZSETs probed by `ZSCORE`), so the variant distinction collapses.

**Decision.** No standalone command — identical to `getState`'s `get_job_state/3`; the variant is moot because the v2 keyspace eliminated the LIST. Re-introducing a `V2` would violate "one canonical surface" — there is exactly one state read. **PROPOSED**: only the same replica-honesty carry as `getState`.

**BCS** same as `getState` — the single canonical state read a runbook/saga consults. · **EchoMesh** consistency-first — the same single-id state-of-record read; the variant collapses into it. · **[when]** same as `getState` — the single canonical state read.
