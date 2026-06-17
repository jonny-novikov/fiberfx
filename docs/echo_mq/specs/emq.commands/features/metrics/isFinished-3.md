# isFinished-3  →  no def is_finished; a thin finished?/3 over EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex:148)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   isFinished-3
--@feature   metrics
--@status    PARTIAL
--@rung      emq.2.1 7d98ef86
--@v1        registry/isFinished-3.lua   (KEYS arity 3)
--@v3        no def is_finished; a thin finished?/3 over EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex:148)
```

## v1 source

`registry/isFinished-3.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Checks if a job is finished (.i.e. is in the completed or failed set)

  Input: 
    KEYS[1] completed key
    KEYS[2] failed key
    KEYS[3] job key

    ARGV[1] job id
    ARGV[2] return value?
  Output:
    0 - Not finished.
    1 - Completed.
    2 - Failed.
   -1 - Missing job. 
]]
local rcall = redis.call
if rcall("EXISTS", KEYS[3]) ~= 1 then
  if ARGV[2] == "1" then

    return {-1,"Missing key for job " .. KEYS[3] .. ". isFinished"}
  end  
  return -1
end

if rcall("ZSCORE", KEYS[1], ARGV[1]) then
  if ARGV[2] == "1" then
    local returnValue = rcall("HGET", KEYS[3], "returnvalue")

    return {1,returnValue}
  end
  return 1
end

if rcall("ZSCORE", KEYS[2], ARGV[1]) then
  if ARGV[2] == "1" then
    local failedReason = rcall("HGET", KEYS[3], "failedReason")

    return {2,failedReason}
  end
  return 2
end

if ARGV[2] == "1" then
  return {0}
end

return 0
```

## v1 → v3 change ledger

| v1 (isFinished-3) | v3 (PARTIAL — finished?/3 over get_job_state/3) |
|---|---|
| KEYS[1]=completed, KEYS[2]=failed, KEYS[3]=job | no `completed` set (completion-deletes, §6) |
| ARGV[1]=id, ARGV[2]=return-value flag | finished?/3 over @state_lookup (body #getstate-8): |
| ZSCORE KEYS[1] id -> 1 (+ HGET returnvalue) | :dead -> the only retained terminal state |
| ZSCORE KEYS[2] id -> 2 (+ HGET failedReason) | :absent -> a vanished completion |
| else 0 | -- id gated at Keyspace.job_key/2 (raises before wire) |

## Aligned flow (authoritative side-by-side)

```text
v1 (isFinished-3)                                v3 (PARTIAL — finished?/3 over get_job_state/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=completed, KEYS[2]=failed, KEYS[3]=job   no `completed` set (completion-deletes, §6)
ARGV[1]=id, ARGV[2]=return-value flag            finished?/3 over @state_lookup (body #getstate-8):
ZSCORE KEYS[1] id -> 1 (+ HGET returnvalue)       :dead -> the only retained terminal state
ZSCORE KEYS[2] id -> 2 (+ HGET failedReason)      :absent -> a vanished completion
else 0                                           -- id gated at Keyspace.job_key/2 (raises before wire)
```

## Decision & rationale

**Covers → v3.** Is a job finished → subsumed by `get_job_state/3`. v1's "finished" universe is the two terminal **sets** `completed`+`failed`; the bus keeps no `completed` set (completion-deletes, §6 — the row is removed), so only `:dead` (the morgue) is retained and "completed" is a `metrics:completed` count, not a per-id lookup.

**Decision.** A thin `finished?/3` over `get_job_state/3`: `:dead` is the bus's only retained terminal state, `:absent` answers a vanished completion; declared KEYS = four sets + the row. **PROPOSED**: durable per-job finished-history (which completion-deletes drop) is recovered by **terminal-outcome replay off the stream tier** (emq3.3 journal-fold, emq3.5 archive) — the live bus is intentionally amnesiac about success.

**BCS** "did this trade-job terminate?" — `dead` (the morgue) is the retained answer; live outcome rides the metrics counter. · **EchoMesh** consistency-first point read; the durable history emq3.5 archives serves the availability-first audit/backtest surface. · **[when]** "did this trade-job terminate?" — `dead` is the retained answer.
