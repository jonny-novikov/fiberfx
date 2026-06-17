# getCountsPerPriority-4  →  re-derived as per-lane depth EchoMQ.Metrics.lane_depths/3 (also metrics: per-lane / per-instrument backlog the trading bus reads)

> Feature: **groups** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   getCountsPerPriority-4
--@feature   groups
--@status    RETIRED (retired by design)
--@rung      emq.1
--@v1        registry/getCountsPerPriority-4.lua   (KEYS arity 4)
--@v3        re-derived as per-lane depth EchoMQ.Metrics.lane_depths/3 (also metrics: per-lane / per-instrument backlog the trading bus reads)
```

## v1 source

`registry/getCountsPerPriority-4.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Get counts per provided states

    Input:
      KEYS[1] wait key
      KEYS[2] paused key
      KEYS[3] meta key
      KEYS[4] prioritized key

      ARGV[1...] priorities
]]
local rcall = redis.call
local results = {}
local waitKey = KEYS[1]
local pausedKey = KEYS[2]
local prioritizedKey = KEYS[4]

-- Includes
--- @include "includes/isQueuePaused"

for i = 1, #ARGV do
  local priority = tonumber(ARGV[i])
  if priority == 0 then
    if isQueuePaused(KEYS[3]) then
      results[#results+1] = rcall("LLEN", pausedKey)
    else
      results[#results+1] = rcall("LLEN", waitKey)
    end
  else
    results[#results+1] = rcall("ZCOUNT", prioritizedKey,
      priority * 0x100000000, (priority + 1)  * 0x100000000 - 1)
  end
end

return results
```

## v1 → v3 change ledger

| v1 (getCountsPerPriority-4) | v3 (RETIRED — re-aimed to @lane_counts) |
|---|---|
| KEYS[1..4]=wait,paused,meta,prioritized | ARGV[1]=base 'emq:{q}:', ARGV[2..]=group ids |
| p==0 -> isPaused(meta) ? LLEN paused : LLEN wait | for each group g: |
| -- key choice from a DATA read | ZCARD base..'g:'..g..':pending' -- declared-base-rooted |
| p!=0 -> ZCOUNT prioritized p*2^32 ..(p+1)*2^32-1 | -- per-lane depth; no prioritized, no meta.paused branch |

## Aligned flow (authoritative side-by-side)

```text
v1 (getCountsPerPriority-4)                      v3 (RETIRED — re-aimed to @lane_counts)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1..4]=wait,paused,meta,prioritized          ARGV[1]=base 'emq:{q}:', ARGV[2..]=group ids
p==0 -> isPaused(meta) ? LLEN paused : LLEN wait  for each group g:
       -- key choice from a DATA read              ZCARD base..'g:'..g..':pending'  -- declared-base-rooted
p!=0 -> ZCOUNT prioritized p*2^32 ..(p+1)*2^32-1  -- per-lane depth; no prioritized, no meta.paused branch
```

## Decision & rationale

**Covers → v3.** Counts per priority band over the global `prioritized` ZSET → **no `prioritized` set exists**; re-derived as **per-lane depth** — `Metrics.lane_depths/3` over `g:<group>:pending`, branded-group-gated (the as-built `Metrics.lane_depth/3`, `metrics.ex:277`, delegates to `Lanes.depth/3`, `lanes.ex:193`). The v1 priority-band cardinalities become per-segment (per-instrument lane) depths.

**Decision.** Re-derive as per-lane depth over the lane ZSETs, branded-group-gated; read-only. **PROPOSED** delta (emq.4): an intra-lane priority dimension is a `ZCOUNT` over a score *window* on the same `g:<group>:pending` ZSET — **no new key** — never the v1 64-bit-packed `prioritized` band, never a `meta.paused` branch that picks the key.

**BCS** per-lane backlog is the fair-lane / per-instrument depth the trading bus reads. · **EchoMesh** availability-first — per-segment (per-instrument lane) depth, observational only. · **[when]** the per-lane / per-instrument backlog the trading bus reads to balance work across groups.
