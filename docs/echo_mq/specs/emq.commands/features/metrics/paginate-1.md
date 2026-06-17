# paginate-1  →  no def paginate; the shipped listing is EchoMQ.Jobs.browse/3 + pending_size/3

> Feature: **metrics** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   paginate-1
--@feature   metrics
--@status    NOT YET
--@rung      emq.2.1 7d98ef86
--@v1        registry/paginate-1.lua   (KEYS arity 1)
--@v3        no def paginate; the shipped listing is EchoMQ.Jobs.browse/3 + pending_size/3
```

## v1 source

`registry/paginate-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
    Paginate a set or hash

    Input:
      KEYS[1] key pointing to the set or hash to be paginated.
    
      ARGV[1]  page start offset
      ARGV[2]  page end offset (-1 for all the elements)
      ARGV[3]  cursor
      ARGV[4]  offset
      ARGV[5]  max iterations
      ARGV[6]  fetch jobs?
      
    Output:
      [cursor, offset, items, numItems]
]]
local rcall = redis.call

-- Includes
--- @include "includes/findPage"

local key = KEYS[1]
local scanCommand = "SSCAN"
local countCommand = "SCARD"
local type = rcall("TYPE", key)["ok"]

if type == "none" then
    return {0, 0, {}, 0}
elseif type == "hash" then
    scanCommand = "HSCAN"
    countCommand = "HLEN"
elseif type ~= "set" then
    return
        redis.error_reply("Pagination is only supported for sets and hashes.")
end

local numItems = rcall(countCommand, key)
local startOffset = tonumber(ARGV[1])
local endOffset = tonumber(ARGV[2])
if endOffset == -1 then 
  endOffset = numItems
end
local pageSize = (endOffset - startOffset) + 1

local cursor, offset, items, jobs = findPage(key, scanCommand, startOffset,
                                       pageSize, ARGV[3], tonumber(ARGV[4]),
                                       tonumber(ARGV[5]), ARGV[6])

return {cursor, offset, items, numItems, jobs}
```

## v1 → v3 change ledger

| v1 (paginate-1) | v3 (PROPOSED — order-theorem browse is the shipped form) |
|---|---|
| KEYS[1]=set\|hash ; ARGV[1..6]=start,end, | primary listing: Jobs.browse/3 (REV BYLEX over pending) |
| cursor,offset,maxIterations,fetch-jobs | + pending_size/3 (ZCARD) -- STABLE by mint order |
| header: "pagination is not stable" | set/hash reads (de:* dedup, meta) -> declared-key HSCAN/SSCAN |
| t = TYPE KEYS[1].ok | CANONICAL v3 paginated read = the stream tier: |
| set -> SSCAN+SCARD ; hash -> HSCAN+HLEN | XRANGE / XAUTOCLAIM where the entry-id IS the cursor |
| findPage: iterate cursor, optional HGETALL | (mint-ordered, emq3.1/3.6 ; MAXLEN/MINID-bounded, emq3.4) |

## Aligned flow (authoritative side-by-side)

```text
v1 (paginate-1)                                  v3 (PROPOSED — order-theorem browse is the shipped form)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]=set|hash ; ARGV[1..6]=start,end,         primary listing: Jobs.browse/3 (REV BYLEX over pending)
  cursor,offset,maxIterations,fetch-jobs           + pending_size/3 (ZCARD) -- STABLE by mint order
header: "pagination is not stable"               set/hash reads (de:* dedup, meta) -> declared-key HSCAN/SSCAN
t = TYPE KEYS[1].ok                              CANONICAL v3 paginated read = the stream tier:
  set -> SSCAN+SCARD ; hash -> HSCAN+HLEN          XRANGE / XAUTOCLAIM where the entry-id IS the cursor
findPage: iterate cursor, optional HGETALL         (mint-ordered, emq3.1/3.6 ; MAXLEN/MINID-bounded, emq3.4)
```

## Decision & rationale

**Covers → v3.** A stable-cursor page of a set or hash. v1's own header **warns the pagination is unstable** (sets are not order-preserving) — the exact weakness the v2 mint-order browse removes. The shipped path is the order-theorem browse (REV BYLEX over `pending`), stable by construction, not an `SSCAN`/`HSCAN` cursor.

**Decision.** The bus's primary listing is already the **order-theorem browse** (REV BYLEX, stable because mint-ordered — directly answering v1's instability warning). For genuinely set/hash-shaped reads (paging the `de:*` dedup space or a `meta` hash), a declared-key `HSCAN`/`SSCAN` scoped under the slot. **PROPOSED canonical**: the stream tier — `XRANGE`/`XAUTOCLAIM` where the **stream entry-id IS the cursor**, what the named emq3 stream consumers (an ordered, replayable event log a downstream consumer reads from a saved position) actually demand.

**BCS** page a large backlog/event log for recorded-runs + backtest replay (the named emq3 consumers). · **EchoMesh** availability-first (AP) read — paged reads resolve from the nearest replica, staleness-bounded; the stream-tier retention is globally replicated. · **[when]** paging a large backlog/event log for recorded-runs + backtest replay.
