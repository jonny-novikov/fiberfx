# getCounts-1  →  EchoMQ.Metrics.get_counts/3 (@counts, metrics.ex:54)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getCounts-1
--@feature   metrics
--@status    SHIPPED (ported)
--@rung      emq.2.1 7d98ef86
--@v1        registry/getCounts-1.lua   (KEYS arity 1)
--@v3        EchoMQ.Metrics.get_counts/3 (@counts, metrics.ex:54)
```

## v1 source

`registry/getCounts-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get counts per provided states

    Input:
      KEYS[1]    'prefix'

      ARGV[1...] types
]]
local rcall = redis.call;
local prefix = KEYS[1]
local results = {}

for i = 1, #ARGV do
  local stateKey = prefix .. ARGV[i]
  if ARGV[i] == "wait" or ARGV[i] == "paused" then
    -- Markers in waitlist DEPRECATED in v5: Remove in v6.
    local marker = rcall("LINDEX", stateKey, -1)
    if marker and string.sub(marker, 1, 2) == "0:" then
      local count = rcall("LLEN", stateKey)
      if count > 1 then
        rcall("RPOP", stateKey)
        results[#results+1] = count-1
      else
        results[#results+1] = 0
      end
    else
      results[#results+1] = rcall("LLEN", stateKey)
    end
  elseif ARGV[i] == "active" then
    results[#results+1] = rcall("LLEN", stateKey)
  else
    results[#results+1] = rcall("ZCARD", stateKey)
  end
end

return results
```

## v1 → v3 change ledger

| v1 (getCounts-1) | v3 (SHIPPED — EchoMQ.Metrics.get_counts/3) |
|---|---|
| KEYS[1]=prefix ; ARGV[i]=state names | KEYS[1]=base 'emq:{q}:' (slot root) ; KEYS[2..]=set keys |
| stateKey = prefix .. ARGV[i] -- OPEN CONCAT | for i=2,#KEYS: ZCARD KEYS[i] -- set states |
| wait/paused -> LLEN + v6 marker RPOP | HGET base..'metrics:'..ARGV[i] 'count' -- metric states |
| active -> LLEN ; else -> ZCARD | -- no wait/paused/prioritized LIST (§6 closed registry) |

## Aligned flow (authoritative side-by-side)

```text
v1 (getCounts-1)                                 v3 (SHIPPED — EchoMQ.Metrics.get_counts/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=prefix ; ARGV[i]=state names             KEYS[1]=base 'emq:{q}:' (slot root) ; KEYS[2..]=set keys
stateKey = prefix .. ARGV[i]  -- OPEN CONCAT     for i=2,#KEYS: ZCARD KEYS[i]            -- set states
wait/paused -> LLEN + v6 marker RPOP             HGET base..'metrics:'..ARGV[i] 'count'  -- metric states
active -> LLEN ; else -> ZCARD                   -- no wait/paused/prioritized LIST (§6 closed registry)
```

## Decision & rationale

**Covers → v3.** A count per requested state → closed-registry `get_counts/3` over declared keys: set states `ZCARD`, metric states (`completed`/`failed`) `HGET … count` (completion-deletes leave no set). `validate_states/1` rejects any name outside `@set_states ∪ @metric_states`.

**Decision.** Keep the shipped `@counts` verbatim — declared-keys-clean and slot-sound (even a metric-only request pins `{q}` via the declared base). **PROPOSED**: a one-shot multi-set **snapshot** + an honest `as_of` server-`TIME` stamp (the per-surface staleness budget); no open concatenation reintroduced.

**BCS** the per-state depth row an operator dashboard reads. · **EchoMesh** availability-first — observational, stale-tolerant; it degrades, never refuses (served from the nearest replica). · **[when]** the per-state depth an operator dashboard reads.
