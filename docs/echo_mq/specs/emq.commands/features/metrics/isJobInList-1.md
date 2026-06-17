# isJobInList-1  →  no def in_list; re-derives as a declared-key ZSCORE (the @state_lookup mechanism)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   isJobInList-1
--@feature   metrics
--@status    NOT YET
--@rung      emq.2.1 7d98ef86
--@v1        registry/isJobInList-1.lua   (KEYS arity 1)
--@v3        no def in_list; re-derives as a declared-key ZSCORE (the @state_lookup mechanism)
```

## v1 source

`registry/isJobInList-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Checks if job is in a given list.

  Input:
    KEYS[1]
    ARGV[1]

  Output:
    1 if element found in the list.
]]

-- Includes
--- @include "includes/checkItemInList"

local items = redis.call("LRANGE", KEYS[1] , 0, -1)
return checkItemInList(items, ARGV[1])
```

## v1 → v3 change ledger

| v1 (isJobInList-1, full) | v3 (PROPOSED — no membership LIST on disk) |
|---|---|
| KEYS[1]=list ; ARGV[1]=id | bus has no membership LIST (pending is a ZSET, ZPOPMIN-drained) |
| items = LRANGE KEYS[1] 0 -1 -- WHOLE list | ZSCORE over the relevant set (the @state_lookup mechanism): |
| checkItemInList(items, id) | if ZSCORE KEYS[1] id then return 1 end |
| -- linear scan -> 1/nil (O(n)) | one declared KEYS[n] root ; id gated at the key builder |

## Aligned flow (authoritative side-by-side)

```text
v1 (isJobInList-1, full)                         v3 (PROPOSED — no membership LIST on disk)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=list ; ARGV[1]=id                        bus has no membership LIST (pending is a ZSET, ZPOPMIN-drained)
items = LRANGE KEYS[1] 0 -1  -- WHOLE list        ZSCORE over the relevant set (the @state_lookup mechanism):
checkItemInList(items, id)                          if ZSCORE KEYS[1] id then return 1 end
  -- linear scan -> 1/nil  (O(n))                 one declared KEYS[n] root ; id gated at the key builder
```

## Decision & rationale

**Covers → v3.** Is an id a member of a given LIST → re-derived as **O(log n) sorted-set membership**, never a linear `LRANGE` scan. The bus has no membership LISTs — `pending` is a ZSET drained by `ZPOPMIN` — so the v1 mechanism has no structure to run against.

**Decision.** Re-derive as O(log n) sorted-set membership: a declared-key `ZSCORE` over the relevant set (the exact mechanism `@state_lookup` uses for the four sets), one declared `KEYS[n]` root, branded id gated at the key builder. **PROPOSED** — strictly better than v1: the order theorem means the set is mint-ordered and membership is logarithmic, never an `LRANGE 0 -1` pull.

**BCS** confirm an order/job's set residency cheaply — "is this id still pending/active" without pulling the whole set. · **EchoMesh** consistency-first membership probe — exact, partition-refusing on the CP side. · **[when]** confirming a job's set residency without pulling the whole set.
