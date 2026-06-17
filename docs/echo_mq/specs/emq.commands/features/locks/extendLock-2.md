# extendLock-2  →  EchoMQ.Jobs.extend_lock/5 (@extend_lock, jobs.ex:940)

> Feature: **locks** · v1→v3 migration record. Authoritative source: the EchoMQ command registry. NO-INVENT: v3 schematics are carried as the repo states them — nothing here is fabricated.

## Header

```text
--@command   extendLock-2
--@feature   locks
--@status    SHIPPED (ported)
--@rung      emq.2.3 3c6461ff
--@v1        registry/extendLock-2.lua   (KEYS arity 2)
--@v3        EchoMQ.Jobs.extend_lock/5 (@extend_lock, jobs.ex:940)
```

## v1 source

`registry/extendLock-2.lua` — the original legacy v1 command, verbatim.

```lua
--[[
  Extend lock and removes the job from the stalled set.

  Input:
    KEYS[1] 'lock',
    KEYS[2] 'stalled'

    ARGV[1]  token
    ARGV[2]  lock duration in milliseconds
    ARGV[3]  jobid

  Output:
    "1" if lock extented succesfully.
]]
local rcall = redis.call
if rcall("GET", KEYS[1]) == ARGV[1] then
  --   if rcall("SET", KEYS[1], ARGV[1], "PX", ARGV[2], "XX") then
  if rcall("SET", KEYS[1], ARGV[1], "PX", ARGV[2]) then
    rcall("SREM", KEYS[2], ARGV[3])
    return 1
  end
end
return 0
```

## v1 → v3 change ledger

| v1 (extendLock-2) | v3 (SHIPPED — EchoMQ.Jobs.extend_lock/5) |
|---|---|
| KEYS: lock, stalled ; ARGV token/dur/jobId | keys = [active, job_key] ; ARGV token, lease_ms |
| GET lock == token ? -- :lock STRING is clock | att = HGET job_key 'attempts' |
| SET lock token PX dur -- caller duration | att ~= token -> EMQSTALE -- attempts fence, no :lock |
| SREM stalled jobId ; return 1 | now = TIME (server clock) |
| else return 0 | ZADD active now+lease_ms <id> -- lease IS the score |

## Aligned flow (authoritative side-by-side)

```text
v1 (extendLock-2)                                v3 (SHIPPED — EchoMQ.Jobs.extend_lock/5)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS: lock, stalled ; ARGV token/dur/jobId       keys = [active, job_key] ; ARGV token, lease_ms
GET lock == token ?   -- :lock STRING is clock    att = HGET job_key 'attempts'
  SET lock token PX dur   -- caller duration      att ~= token -> EMQSTALE   -- attempts fence, no :lock
  SREM stalled jobId ; return 1                    now = TIME (server clock)
else return 0                                     ZADD active now+lease_ms <id>   -- lease IS the score
```

## Decision & rationale

**Covers → v3.** Renew one job's lease → re-score the `active` member under server `TIME`, token-fenced `EMQSTALE`; the v1 separate-`:lock`-string-with-`PX`-TTL form is *not lifted* (the `active`-set score IS the lease).

**Decision.** Hold the shipped server-clock, token-fenced, lease-IS-score form; no `:lock` string. **PROPOSED** delta: return the computed `lease_deadline` (`now + lease_ms`) so a consumer fences its own headroom — a return-shape additive minor, no protocol break.

**BCS** the token-fence is the single-writer guarantee for a long handler (a scoring step) holding a row mid-work. · **EchoMesh** a Best-Effort-Availability corner — a consistency-first lease, correct-always (the CP dial). · **[when]** a long scoring handler renewing its lease so it is not reaped mid-work.
