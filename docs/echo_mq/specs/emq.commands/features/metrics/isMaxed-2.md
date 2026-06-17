# isMaxed-2  →  EchoMQ.Metrics.is_maxed/2 (@is_maxed, metrics.ex:260)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   isMaxed-2
--@feature   metrics
--@status    SHIPPED (ported)
--@rung      emq.2.1 7d98ef86
--@v1        registry/isMaxed-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Metrics.is_maxed/2 (@is_maxed, metrics.ex:260)
```

## v1 source

`registry/isMaxed-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Checks if queue is maxed.

  Input:
    KEYS[1] meta key
    KEYS[2] active key

  Output:
    1 if element found in the list.
]]

local rcall = redis.call

-- Includes
--- @include "includes/isQueueMaxed"

return isQueueMaxed(KEYS[1], KEYS[2])
```

## v1 → v3 change ledger

| v1 (isMaxed-2) | v3 (SHIPPED — Metrics.@is_maxed) |
|---|---|
| KEYS[1]=meta, KEYS[2]=active | keys=[queue_key(q,"meta"), queue_key(q,"active")] |
| cap = HGET KEYS[1] 'concurrency' | cap = HGET KEYS[1] 'concurrency' |
| if LLEN KEYS[2] >= cap -> return true | if cap>0 and ZCARD KEYS[2] >= cap: -- active is a ZSET |
| -- active is a LIST ; bare boolean | error_reply('EMQRATE at concurrency ceiling') |
| return false | return 0 -- -> {:error, :rate} |

## Aligned flow (authoritative side-by-side)

```text
v1 (isMaxed-2)                                   v3 (SHIPPED — Metrics.@is_maxed)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=meta, KEYS[2]=active                     keys=[queue_key(q,"meta"), queue_key(q,"active")]
cap = HGET KEYS[1] 'concurrency'                 cap = HGET KEYS[1] 'concurrency'
if LLEN KEYS[2] >= cap -> return true            if cap>0 and ZCARD KEYS[2] >= cap:   -- active is a ZSET
  -- active is a LIST ; bare boolean               error_reply('EMQRATE at concurrency ceiling')
return false                                     return 0                              -- -> {:error, :rate}
```

## Decision & rationale

**Covers → v3.** At the concurrency ceiling? → a **read-and-refuse**: `HGET meta 'concurrency'`, and if `ZCARD active >= cap` it `redis.error_reply('EMQRATE …')` → `{:error, :rate}`; else `:ok`. v1 returned a bare boolean over an active **LIST**; v2 uses a typed `EMQRATE` wire refusal over the active **ZSET**.

**Decision.** Hold as-shipped — the v1 boolean evolves into the typed `EMQRATE` wire refusal (design §5 additive minor, in the closed wire-class registry with EMQKIND/EMQSTALE/EMQLOCK/EMQSTATE), the consult-before-claim contract the conformance set proves. **PROPOSED**: carry the same gate to per-lane ceilings across mesh nodes (`EchoMQ.Lanes`).

**BCS** the scale-out gate — a producer/strategy consults the ceiling before claiming, so the system never over-admits. · **EchoMesh** consistency-first admission gate — a hard refuse (the CP "refuse rather than risk a second writer" posture). · **[when]** the scale-out gate consulted before over-admitting.
