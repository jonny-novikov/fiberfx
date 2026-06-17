# getJobScheduler-1  →  EchoMQ.Repeat.get/3 (proposed) beside count/2/due/3 (repeat.ex:96/:141)

> Feature: **repeat** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getJobScheduler-1
--@feature   repeat
--@status    PROPOSED (partial)
--@rung      emq.1 e0fa9b03
--@v1        registry/getJobScheduler-1.lua   (KEYS arity 1)
--@v3        EchoMQ.Repeat.get/3 (proposed) beside count/2/due/3 (repeat.ex:96/:141)
```

## v1 source

`registry/getJobScheduler-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get job scheduler record.

  Input:
    KEYS[1] 'repeat' key

    ARGV[1] id
]]

local rcall = redis.call
local jobSchedulerKey = KEYS[1] .. ":" .. ARGV[1]

local score = rcall("ZSCORE", KEYS[1], ARGV[1])

if score then
  return {rcall("HGETALL", jobSchedulerKey), score} -- get job data
end

return {nil, nil}
```

## v1 → v3 change ledger

| v1 (getJobScheduler-1) | v3 (PROPOSED — Repeat.get/3, a near-direct lift) |
|---|---|
| KEYS[1] repeat ; ARGV[1] id | keys = [emq:{q}:repeat, emq:{q}:repeat:<name>] |
| key = KEYS[1]..":"..id -- grammar-rooted (ok) | score = ZSCORE KEYS[1] <name> |
| score = ZSCORE(repeat, id) | record = HMGET / HGETALL KEYS[2] |
| score ? {HGETALL(key), score} : {nil, nil} | return {score, %{every_ms, template}} \| :absent |

## Aligned flow (authoritative side-by-side)

```text
v1 (getJobScheduler-1)                           v3 (PROPOSED — Repeat.get/3, a near-direct lift)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] repeat ; ARGV[1] id                      keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
key = KEYS[1]..":"..id   -- grammar-rooted (ok)  score  = ZSCORE KEYS[1] <name>
score = ZSCORE(repeat, id)                       record = HMGET / HGETALL KEYS[2]
score ? {HGETALL(key), score} : {nil, nil}       return {score, %{every_ms, template}} | :absent
```

## Decision & rationale

**Covers → v3.** Read one scheduler record (`ZSCORE` next-run + `HGETALL` template) → `count/2` reads depth and `due/3` reads records due now, but there is no single-name **point read** yet; add `get/3`. The v1 hash key is grammar-rooted from `KEYS[1]` (benign — already near-lift-legal).

**Decision.** A declared-keys read over both keys composed by `Keyspace.queue_key/2` (one `{q}` slot), honest-row `:absent`. Read-only — no clock, no mint. *(Near-direct lift; prose until the rung authors it.)*

**BCS** an operator console inspects one registered cadence by name without walking the due set. · **EchoMesh** read-side — a point read of one slot's registry, available even when other slots are partitioned. · **[when]** an operator inspecting one cadence by name.
