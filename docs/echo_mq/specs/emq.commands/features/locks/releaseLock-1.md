# releaseLock-1  →  EchoMQ.Locks.untrack_job/2 (the lease releases by natural active-score expiry / complete)

> Feature: **locks** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   releaseLock-1
--@feature   locks
--@status    SHIPPED (ported, re-split)
--@rung      emq.2.3 3c6461ff
--@v1        registry/releaseLock-1.lua   (KEYS arity 1)
--@v3        EchoMQ.Locks.untrack_job/2 (the lease releases by natural active-score expiry / complete)
```

## v1 source

`registry/releaseLock-1.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Release lock

    Input:
      KEYS[1] 'lock',
    
      ARGV[1]  token
      ARGV[2]  lock duration in milliseconds
      
    Output:
      "OK" if lock extented succesfully.
]]
local rcall = redis.call

if rcall("GET", KEYS[1]) == ARGV[1] then
  return rcall("DEL", KEYS[1])
else
  return 0
end
```

## v1 → v3 change ledger

| v1 (releaseLock-1) | v3 (SHIPPED, re-split L-3 — Locks.untrack_job/2) |
|---|---|
| KEYS[1]='lock' ; ARGV[1]=token | (a) lease end: active-score expiry / complete/4 — no DEL |
| GET lock == token ? | (b) marker: untrack_job DELs emq:{q}:job:<id>:lock |
| return DEL lock -- lease end is DEL of STR | (written on Locks.track_job/3, self-expiring PX ≈2×lease) |
| return 0 | @remove_job: EXISTS jk..':lock' -> EMQLOCK (refuse held) |

## Aligned flow (authoritative side-by-side)

```text
v1 (releaseLock-1)                               v3 (SHIPPED, re-split L-3 — Locks.untrack_job/2)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1]='lock' ; ARGV[1]=token                   (a) lease end: active-score expiry / complete/4 — no DEL
GET lock == token ?                              (b) marker: untrack_job DELs emq:{q}:job:<id>:lock
  return DEL lock   -- lease end is DEL of STR        (written on Locks.track_job/3, self-expiring PX ≈2×lease)
return 0                                          @remove_job: EXISTS jk..':lock' -> EMQLOCK (refuse held)
```

## Decision & rationale

**Covers → v3.** Release a lease → the two-part L-3 release: the **lease** ends by natural `active`-score expiry / `complete/4`; `untrack_job/2` DELs the `emq:{q}:job:<id>:lock` **presence marker** (what `@remove_job` reads → `EMQLOCK`). The v1 separate-`:lock`-string `DEL`-as-release is *not lifted* (no lock-string-as-clock exists); it does not double-retire (emq.2.3 D5).

**Decision.** Keep the L-3 two-part release (marker DEL on untrack + a self-expiring marker `PX` TTL ≈2×lease, PEXPIRE-refreshed each beat); the lease end stays score-driven. **PROPOSED**: make the marker DEL idempotent + return prior held-state (honest-row `released`/`already-gone`).

**BCS** releasing the marker unblocks `remove_job` (`EMQLOCK` lifts) — a clean hand-back of a completed branded job. · **EchoMesh** marker self-expiry is the partition-healing escape hatch: a dead holder cannot pin the row past its lease. · **[when]** a clean hand-back of a completed branded job — releasing the marker unblocks `remove_job`.
