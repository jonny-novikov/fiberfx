# getRateLimitTtl-2  →  EchoMQ.Metrics.get_rate_limit_ttl/3 (@rate_ttl, metrics.ex:221)

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getRateLimitTtl-2
--@feature   metrics
--@status    SHIPPED (ported)
--@rung      emq.2.1 7d98ef86
--@v1        registry/getRateLimitTtl-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Metrics.get_rate_limit_ttl/3 (@rate_ttl, metrics.ex:221)
```

## v1 source

`registry/getRateLimitTtl-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get rate limit ttl

    Input:
      KEYS[1] 'limiter'
      KEYS[2] 'meta'

      ARGV[1] maxJobs
]]

local rcall = redis.call

-- Includes
--- @include "includes/getRateLimitTTL"

local rateLimiterKey = KEYS[1]
if ARGV[1] ~= "0" then
  return getRateLimitTTL(tonumber(ARGV[1]), rateLimiterKey)
else
  local rateLimitMax = rcall("HGET", KEYS[2], "max")
  if rateLimitMax then
    return getRateLimitTTL(tonumber(rateLimitMax), rateLimiterKey)
  end

  return rcall("PTTL", rateLimiterKey)
end
```

## v1 → v3 change ledger

| v1 (getRateLimitTtl-2) | v3 (SHIPPED — Metrics.@rate_ttl) |
|---|---|
| KEYS[1]=limiter, KEYS[2]=meta ; ARGV[1]=maxJobs | keys=[queue_key(q,"limiter"), queue_key(q,"meta")] |
| max from HGET KEYS[2] 'max' when maxJobs==0 | max = ARGV[1] ; if 0 -> HGET KEYS[2] 'max' |
| getRateLimitTTL(max, limiterKey): | if max>0 and max <= GET KEYS[1]: |
| if max <= GET limiter -> PTTL (DEL at 0) | pttl = PTTL KEYS[1] ; if pttl>0 return pttl |
| return PTTL limiter | return 0 |

## Aligned flow (authoritative side-by-side)

```text
v1 (getRateLimitTtl-2)                           v3 (SHIPPED — Metrics.@rate_ttl)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=limiter, KEYS[2]=meta ; ARGV[1]=maxJobs  keys=[queue_key(q,"limiter"), queue_key(q,"meta")]
max from HGET KEYS[2] 'max' when maxJobs==0      max = ARGV[1] ; if 0 -> HGET KEYS[2] 'max'
getRateLimitTTL(max, limiterKey):                if max>0 and max <= GET KEYS[1]:
  if max <= GET limiter -> PTTL (DEL at 0)         pttl = PTTL KEYS[1] ; if pttl>0 return pttl
return PTTL limiter                              return 0
```

## Decision & rationale

**Covers → v3.** Remaining limiter TTL in ms → declared `[limiter, meta]`: read `max` from meta when `ARGV[1]`=0, compare to `GET limiter`, return `PTTL` when positive. Both key operands were already in `KEYS[]` in v1 (lift-able — no data-value key root).

**Decision.** Hold as-shipped — braced keyspace + declared-keys + honest-row. **PROPOSED**: extend the same read to the **per-group/per-instrument** limiter window (the `EMQRATE`-class temporal-fairness knob over `EchoMQ.Lanes`) so EchoMesh reads a per-venue rate window's reopen-time, not just the queue-global one.

**BCS** read how long until the rate window reopens — a throttle a consumer consults before scaling out producers. · **EchoMesh** consistency-first read against the regulated window; the rate fence is exact, never best-effort. · **[when]** a consumer reading the rate-window reopen before scaling out producers.
