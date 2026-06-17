# saveStacktrace-1  →  today the failure record is a single last_error field set by @retry's dead-letter arm (jobs.ex:593); a dedicated @save_stacktrace is PROPOSED

> Feature: **data** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   saveStacktrace-1
--@feature   data
--@status    NOT YET (folded)
--@rung      emq.2.2
--@v1        registry/saveStacktrace-1.lua   (KEYS arity 1)
--@v3        today the failure record is a single last_error field set by @retry's dead-letter arm (jobs.ex:593); a dedicated @save_stacktrace is PROPOSED
```

## v1 source

`registry/saveStacktrace-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Save stacktrace and failedReason.
  Input:
    KEYS[1] job key
    ARGV[1]  stacktrace
    ARGV[2]  failedReason
  Output:
     0 - OK
    -1 - Missing key
]]
local rcall = redis.call

if rcall("EXISTS", KEYS[1]) == 1 then
  rcall("HMSET", KEYS[1], "stacktrace", ARGV[1], "failedReason", ARGV[2])

  return 0
else
  return -1
end
```

## v1 → v3 change ledger

| v1 (saveStacktrace-1) | v3 (NOT YET — folded into @retry's dead-letter arm) |
|---|---|
| KEYS[1] job key | -- NO @save_stacktrace script on disk (grep-confirmed) |
| ARGV[1] stacktrace ; ARGV[2] failedReason | -- the ONLY failure record, written on dead-letter only: |
| if EXISTS KEYS[1] == 1 then | HSET KEYS[4] 'last_error' ARGV[5] -- inside @retry (jobs.ex:593) |
| HMSET KEYS[1] "stacktrace" ARGV[1] | -- cleared by reprocess_job/3's HDEL (jobs.ex:912) |
| "failedReason" ARGV[2] ; return 0 | -- two-field {stacktrace, failedReason} → one last_error |
| else return -1 end | -- no standalone host-callable verb (a PROPOSED forward rung) |

## Aligned flow (authoritative side-by-side)

```text
v1 (saveStacktrace-1)                             v3 (NOT YET — folded into @retry's dead-letter arm)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] job key                                   -- NO @save_stacktrace script on disk (grep-confirmed)
ARGV[1] stacktrace ; ARGV[2] failedReason         -- the ONLY failure record, written on dead-letter only:
if EXISTS KEYS[1] == 1 then                        HSET KEYS[4] 'last_error' ARGV[5]   -- inside @retry (jobs.ex:593)
  HMSET KEYS[1] "stacktrace" ARGV[1]              -- cleared by reprocess_job/3's HDEL (jobs.ex:912)
    "failedReason" ARGV[2] ; return 0             -- two-field {stacktrace, failedReason} → one last_error
else return -1 end                                -- no standalone host-callable verb (a PROPOSED forward rung)
```

## Decision & rationale

**Covers → v3.** Persist a richer failure record (`stacktrace` + `failedReason`) → no dedicated port: there is **no** `save_stacktrace` function or `@save_stacktrace` script in `echo_mq` (grep-confirmed). The v1 two-field record collapses to a single `last_error` STRING written **only on the dead-letter transition** by `@retry` (`HSET … 'last_error'`, `jobs.ex:593`) and cleared by `reprocess_job/3` (`HDEL`, `jobs.ex:912`).

**Decision.** v1's two-field `{stacktrace, failedReason}` is collapsed to one `last_error` browse summary, with no standalone verb (`saveStacktrace-1.lua` has no row in `emq.features.md` Part B.2 — an honest gap this registry surfaces). **PROPOSED**: re-derive a dedicated `@save_stacktrace` A-1-clean — one declared `KEYS[1] = Keyspace.job_key(q, id)` (gated), writing separate `stacktrace` + `failed_reason` fields **beside** the kept `last_error`, server-clock-stamped at the failure instant. The natural companion to the **shipped** emq.3.4 failure-policy (`fail_parent_on_failure`, `4c401479`): a flow that fails a parent on a dead child should carry the child's full stacktrace, not just `last_error`. A small forward rung — no v1 form to lift.

**BCS** rich post-mortem on a dead settlement/risk job before reprocess. · **EchoMesh** consistency-first morgue — failure detail is single-writer on the owning node's row, read by recovery sweeps; never a partition-spanning write. · **[when]** rich post-mortem on a dead settlement/risk job before reprocess.
