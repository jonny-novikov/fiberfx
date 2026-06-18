# addRepeatableJob-2  →  EchoMQ.Repeat.register/6 (@repeat_register, repeat.ex)

> Feature: **repeat** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   addRepeatableJob-2
--@feature   repeat
--@status    SHIPPED (ported)
--@rung      emq.1
--@v1        registry/addRepeatableJob-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Repeat.register/6 (@repeat_register, repeat.ex)
```

## v1 source

`registry/addRepeatableJob-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Adds a repeatable job

    Input:
      KEYS[1] 'repeat' key
      KEYS[2] 'delayed' key
      
      ARGV[1] next milliseconds
      ARGV[2] msgpacked options
            [1]  name
            [2]  tz?
            [3]  pattern?
            [4]  endDate?
            [5]  every?
      ARGV[3] legacy custom key TODO: remove this logic in next breaking change
      ARGV[4] custom key
      ARGV[5] prefix key

      Output:
        repeatableKey  - OK
]]
local rcall = redis.call
local repeatKey = KEYS[1]
local delayedKey = KEYS[2]

local nextMillis = ARGV[1]
local legacyCustomKey = ARGV[3]
local customKey = ARGV[4]
local prefixKey = ARGV[5]

-- Includes
--- @include "includes/removeJob"

local function storeRepeatableJob(repeatKey, customKey, nextMillis, rawOpts)
  rcall("ZADD", repeatKey, nextMillis, customKey)
  local opts = cmsgpack.unpack(rawOpts)

  local optionalValues = {}
  if opts['tz'] then
    table.insert(optionalValues, "tz")
    table.insert(optionalValues, opts['tz'])
  end

  if opts['pattern'] then
    table.insert(optionalValues, "pattern")
    table.insert(optionalValues, opts['pattern'])
  end

  if opts['endDate'] then
    table.insert(optionalValues, "endDate")
    table.insert(optionalValues, opts['endDate'])
  end
  
  if opts['every'] then
    table.insert(optionalValues, "every")
    table.insert(optionalValues, opts['every'])
  end

  rcall("HMSET", repeatKey .. ":" .. customKey, "name", opts['name'],
    unpack(optionalValues))

  return customKey
end

-- If we are overriding a repeatable job we must delete the delayed job for
-- the next iteration.
local prevMillis = rcall("ZSCORE", repeatKey, customKey)
if prevMillis then
  local delayedJobId =  "repeat:" .. customKey .. ":" .. prevMillis
  local nextDelayedJobId =  repeatKey .. ":" .. customKey .. ":" .. nextMillis

  if rcall("ZSCORE", delayedKey, delayedJobId)
   and rcall("EXISTS", nextDelayedJobId) ~= 1 then
    removeJob(delayedJobId, true, prefixKey, true --[[remove debounce key]])
    rcall("ZREM", delayedKey, delayedJobId)
  end
end

-- Keep backwards compatibility with old repeatable jobs (<= 3.0.0)
if rcall("ZSCORE", repeatKey, legacyCustomKey) ~= false then
  return storeRepeatableJob(repeatKey, legacyCustomKey, nextMillis, ARGV[2])
end

return storeRepeatableJob(repeatKey, customKey, nextMillis, ARGV[2])
```

## v1 → v3 change ledger

| v1 (addRepeatableJob-2) | v3 (SHIPPED — EchoMQ.Repeat.register/6) |
|---|---|
| KEYS: repeat, delayed | keys = [emq:{q}:repeat (members = names), |
| ARGV: next / opts / legacy / custom / prefix | emq:{q}:repeat:<name> (hash)] |
| prevMillis = ZSCORE(repeat, customKey) | if EXISTS KEYS[2] -> return 0 -- idempotent (:exists) |
| delayedJobId = "repeat:"..customKey..":"..prev | HSET KEYS[2] every_ms <ms> template <t> |
| removeJob(..) ; ZREM delayed -- DATA-VALUE | ZADD KEYS[1] <first_at> <name> -- member = name |
| ZADD repeat next customKey ; HMSET opts | -- no delayed-twin: fresh JOB minted per occurrence |

## Aligned flow (authoritative side-by-side)

```text
v1 (addRepeatableJob-2)                          v3 (SHIPPED — EchoMQ.Repeat.register/6)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS: repeat, delayed                            keys = [emq:{q}:repeat   (members = names),
ARGV: next / opts / legacy / custom / prefix             emq:{q}:repeat:<name>  (hash)]
prevMillis = ZSCORE(repeat, customKey)           if EXISTS KEYS[2] -> return 0       -- idempotent (:exists)
delayedJobId = "repeat:"..customKey..":"..prev   HSET KEYS[2] every_ms <ms> template <t>
  removeJob(..) ; ZREM delayed   -- DATA-VALUE   ZADD KEYS[1] <first_at> <name>      -- member = name
ZADD repeat next customKey ; HMSET opts          -- no delayed-twin: fresh JOB minted per occurrence
```

## Decision & rationale

**Covers → v3.** Register/override a repeatable schedule → idempotent `register/6` over the two declared keys; the v1 override-delete-stale-delayed half is *not lifted* (each occurrence mints a fresh branded `JOB`, so there is no data-rebuilt twin to reverse-engineer).

**Decision.** Keep the registry + the fresh-mint-per-occurrence law; both keys gated at the builder, co-located by `{q}` grammar (S-6). **PROPOSED** delta: carry the v1 `pattern`/`tz`/`endDate` cron fields as extra hash fields, the next score computed host-side — never a Lua key rooted in a data value.

**BCS** a recurring sweep registers once; every run is a first-class, mint-ordered, browsable job. · **EchoMesh** consistency-side — one queue owns its `{q}` repeat slot; the owning node's pump is the single writer that mints + advances. · **[when]** a consumer registering a recurring cadence once.
