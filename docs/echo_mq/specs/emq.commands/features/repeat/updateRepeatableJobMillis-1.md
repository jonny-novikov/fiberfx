# updateRepeatableJobMillis-1  →  EchoMQ.Repeat.advance/4 (@repeat_advance, repeat.ex)

> Feature: **repeat** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   updateRepeatableJobMillis-1
--@feature   repeat
--@status    PARTIAL
--@rung      emq.1 — folds into advance/4
--@v1        registry/updateRepeatableJobMillis-1.lua   (KEYS arity 1)
--@v3        EchoMQ.Repeat.advance/4 (@repeat_advance, repeat.ex)
```

## v1 source

`registry/updateRepeatableJobMillis-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Adds a repeatable job

    Input:
      KEYS[1] 'repeat' key

      ARGV[1] next milliseconds
      ARGV[2] custom key
      ARGV[3] legacy custom key TODO: remove this logic in next breaking change
      
      Output:
        repeatableKey  - OK
]]
local rcall = redis.call
local repeatKey = KEYS[1]
local nextMillis = ARGV[1]
local customKey = ARGV[2]
local legacyCustomKey = ARGV[3]

if rcall("ZSCORE", repeatKey, customKey) then
    rcall("ZADD", repeatKey, nextMillis, customKey)
    return customKey
elseif rcall("ZSCORE", repeatKey, legacyCustomKey) ~= false then
    rcall("ZADD", repeatKey, nextMillis, legacyCustomKey)
    return legacyCustomKey
end

return ''
```

## v1 → v3 change ledger

| v1 (updateRepeatableJobMillis-1) | v3 (PROPOSED — folded into EchoMQ.Repeat.advance/4) |
|---|---|
| KEYS[1] repeat ; ARGV next/custom/legacy | keys = [emq:{q}:repeat, emq:{q}:repeat:<name>] |
| ZSCORE(repeat, customKey) ? ZADD…customKey | ZADD emq:{q}:repeat <next_at> <name> -- one named member |
| elseif ZSCORE(repeat, legacyKey) ? ZADD…legacy | -- legacy/custom DUALITY dropped (single closed registry, S-1) |
| else '' | return {:ok, :advanced \| :absent} |

## Aligned flow (authoritative side-by-side)

```text
v1 (updateRepeatableJobMillis-1)                 v3 (PROPOSED — folded into EchoMQ.Repeat.advance/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] repeat ; ARGV next/custom/legacy         keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
ZSCORE(repeat, customKey) ? ZADD…customKey       ZADD emq:{q}:repeat <next_at> <name>   -- one named member
elseif ZSCORE(repeat, legacyKey) ? ZADD…legacy   -- legacy/custom DUALITY dropped (single closed registry, S-1)
else ''                                          return {:ok, :advanced | :absent}
```

## Decision & rationale

**Covers → v3.** Legacy re-score of a repeatable by custom-or-legacy key → folded into `advance/4` (an explicit-next-at re-score over the branded-name registry); the legacy/custom-key **duality is dropped** (one closed registry, S-1).

**Decision.** One name-keyed registration under braced `emq:{q}:repeat` (S-1) means there is no second key shape to reconcile — the dual-key probe is a v1-only artifact the closed registry eliminates. Folded, not re-implemented.

**BCS** one re-score path; no legacy key-shape branching for the platform to special-case. · **EchoMesh** consistency-side — a single-slot re-score, partition-local. · **[when]** a one-shot re-score of a live repeatable.
