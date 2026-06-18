# removeDeduplicationKey-1  →  folded into @remove_job's de: branch (jobs.ex); standalone release_dedup/3 PROPOSED

> Feature: **lifecycle** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   removeDeduplicationKey-1
--@feature   lifecycle
--@status    PARTIAL (folded)
--@rung      emq.2.2
--@v1        registry/removeDeduplicationKey-1.lua   (KEYS arity 1)
--@v3        folded into @remove_job's de: branch (jobs.ex); standalone release_dedup/3 PROPOSED
```

## v1 source

`registry/removeDeduplicationKey-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Remove deduplication key if it matches the job id.

  Input:
    KEYS[1] deduplication key

    ARGV[1] job id

  Output:
    0 - false
    1 - true
]]
local rcall = redis.call
local deduplicationKey = KEYS[1]
local jobId = ARGV[1]

local currentJobId = rcall('GET', deduplicationKey)
if currentJobId and currentJobId == jobId then
  return rcall("DEL", deduplicationKey)
end

return 0
```

## v1 → v3 change ledger

| v1 (removeDeduplicationKey-1) | v3 (PARTIAL — folded into @remove_job's de: branch) |
|---|---|
| KEYS[1] = dedup key (DECLARED) ; ARGV[1] jobId | dk = KEYS[6] = emq:{q}:de:<did> (declared) |
| GET KEYS[1] == ARGV[1] ? DEL KEYS[1] | GET dk == ARGV[1] ? DEL dk -- verbatim, in @remove_job |
| return 0 | -- read side: Metrics.get_deduplication_job_id/3 |
| -- the rare v1 op already near-legal (key declar | ed) -- PROPOSED standalone Jobs.release_dedup/3 reuses it |

## Aligned flow (authoritative side-by-side)

```text
v1 (removeDeduplicationKey-1)                    v3 (PARTIAL — folded into @remove_job's de: branch)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] = dedup key  (DECLARED) ; ARGV[1] jobId  dk = KEYS[6] = emq:{q}:de:<did>   (declared)
GET KEYS[1] == ARGV[1] ? DEL KEYS[1]             GET dk == ARGV[1] ? DEL dk        -- verbatim, in @remove_job
return 0                                         -- read side: Metrics.get_deduplication_job_id/3
-- the rare v1 op already near-legal (key declared)  -- PROPOSED standalone Jobs.release_dedup/3 reuses it
```

## Decision & rationale

**Covers → v3.** Release a dedup key iff it still points at this job (GET, compare, DEL on match) → the exact GET-compare-DEL is the `de:` branch of `@remove_job`; the read side ships as `Metrics.get_deduplication_job_id/3` (`metrics.ex`). No standalone release verb.

**Decision.** The one v1 op that was almost legal — only the id form changes (a 14-byte branded receipt). Surface `Jobs.release_dedup/3` reusing the `de:` branch verbatim: one declared `KEYS[1] = emq:{q}:de:<did>`, value-compare. Folded, not re-implemented.

**BCS** a producer that retired a dedup window early can release it explicitly. · **EchoMesh** consistency-side — one `{q}`-gated dedup key, partition-local. · **[when]** a producer retiring a dedup window early.
