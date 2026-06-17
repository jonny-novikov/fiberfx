# removeChildDependency-1  →  (v3 TBD)

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   removeChildDependency-1
--@feature   lifecycle
--@status    NOT YET (as a named verb)
--@rung      [removeChildDependency-1.lua](../registry/removeChildDependency-1.lua) → EchoMQ.Flows.drop_dependency/3 PROPOSED (v2 :dependencies is a STRING counter, no member to SREM). (also **flows**)
--@v1        registry/removeChildDependency-1.lua   (KEYS arity 1)
--@v3        
```

## v1 source

`registry/removeChildDependency-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Break parent-child dependency by removing
  child reference from parent

  Input:
    KEYS[1] 'key' prefix,

    ARGV[1] job key
    ARGV[2] parent key

    Output:
       0  - OK
       1  - There is not relationship.
      -1  - Missing job key
      -5  - Missing parent key
]]
local rcall = redis.call
local jobKey = ARGV[1]
local parentKey = ARGV[2]

-- Includes
--- @include "includes/removeParentDependencyKey"

if rcall("EXISTS", jobKey) ~= 1 then return -1 end

if rcall("EXISTS", parentKey) ~= 1 then return -5 end

if removeParentDependencyKey(jobKey, false, parentKey, KEYS[1], nil) then
  rcall("HDEL", jobKey, "parentKey", "parent")

  return 0
else
  return 1
end
```

## v1 → v3 change ledger

| v1 (removeChildDependency-1) | v3 (PROPOSED — EchoMQ.Flows.drop_dependency/3) |
|---|---|
| KEYS[1]=key prefix ; ARGV jobKey, parentKey | keys built from Keyspace.job_key(q, parent_id) |
| -- BOTH keys are DATA VALUES (A-1 ✗) | -- v2 :dependencies is a STRING counter, no SREM |
| if EXISTS jobKey ~= 1 -> -1 | HSETNX <parent>:processed <child> <result> |
| if EXISTS parentKey ~= 1 -> -5 | DECR <parent>:dependencies -- the @flow_deliver shape |
| SREM <parentKey>:dependencies jobKey | at-zero -> release parent to pending |
| HDEL jobKey parentKey parent | -- cross-queue detach rides flow:outbox + sweep |

## Aligned flow (authoritative side-by-side)

```text
v1 (removeChildDependency-1)                     v3 (PROPOSED — EchoMQ.Flows.drop_dependency/3)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=key prefix ; ARGV jobKey, parentKey      keys built from Keyspace.job_key(q, parent_id)
  -- BOTH keys are DATA VALUES  (A-1 ✗)          -- v2 :dependencies is a STRING counter, no SREM
if EXISTS jobKey ~= 1 -> -1                       HSETNX <parent>:processed <child> <result>
if EXISTS parentKey ~= 1 -> -5                    DECR  <parent>:dependencies     -- the @flow_deliver shape
SREM <parentKey>:dependencies jobKey              at-zero -> release parent to pending
HDEL jobKey parentKey parent                      -- cross-queue detach rides flow:outbox + sweep
```

## Decision & rationale

**Covers → v3.** Break one parent↔child link (`SREM` child from the parent SET, `HDEL` parent from the child, move parent to wait if last) → no named verb on disk; the closest as-built is the *automatic* fan-in `DECR` inside `@flow_deliver`, which fires on child *completion*, not an operator detach.

**Decision.** Add `Flows.drop_dependency/3`: on the parent's `{q}` slot record the child in the declared `:processed` HASH, `DECR` the declared `:dependencies` counter, release at zero — every key host-built from `Keyspace.job_key`, never a value-read `parent_key`. A cross-queue detach rides the same `flow:outbox` hop.

**BCS** a multi-leg `Exchange.*` flow cancels one leg without failing the parent. · **EchoMesh** consistency-side — a single parent slot's fan-in fact, partition-local. · **[when]** cancelling one leg of a multi-leg flow without failing the parent.
