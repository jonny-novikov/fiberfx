# Atomic Updates

Five mechanisms for race-free multi-step state changes: WATCH/MULTI/EXEC optimistic locking, Lua scripts, shadow-key + RENAME swap, idempotency-key gating, and ordered-writes-for-crash-safety. Each occupies a different point on the spectrum between strict-atomicity-at-server-cost and at-most-once-via-design. FTR-009 state-machine transitions + BullMQ job-lifecycle transitions are the two canonical Rose Tree consumers — they lean on different variants depending on how tight the atomicity requirement is.

**Primary use-case axes:** A + D — state-machine transitions in both supervisor messaging and session-state persistence.
**Secondary axis:** B — inbox ACK + state flip needs atomic-ish coupling.

## Primitive

Five variants; each solves a different atomicity problem.

**1. WATCH/MULTI/EXEC (optimistic locking):**

- `WATCH <key1> [key2 ...]` — begin monitoring. If any watched key changes before `EXEC`, the transaction aborts (returns nil). Per [`mercury atomic-updates.md §Pattern 1`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt).
- `MULTI` — start queueing commands. Commands after MULTI return `QUEUED` instead of executing.
- `EXEC` — commit all queued commands atomically, or return nil if any WATCHed key mutated.
- Caller retries on nil.

Cluster note: all watched keys must share a slot — see [`hash-tag-colocation.md`](hash-tag-colocation.md).

**2. Lua scripts (server-side atomicity):**

- `EVAL <script> <numkeys> <key1> [key2 ...] <arg1> [arg2 ...]` — run a Lua script atomically. Per [`mercury atomic-updates.md §Pattern 2`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt), Redis serializes script execution; no other command runs during the script.
- `EVALSHA <sha> ...` — run a pre-loaded script by SHA1; fall back to `EVAL` on `NOSCRIPT` error. Per [`mercury atomic-updates.md §Pattern 2`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt).
- Scripts run with all KEYS[] sharing slot in cluster mode.

**3. Shadow-key + RENAME:**

- Build the new value in `tmp:<key>` with many `HSET`/`SET`/etc. calls.
- `RENAME tmp:<key> <key>` — atomic swap; readers see either the old or new complete value, never a partial update. Per [`mercury atomic-updates.md §Pattern 3`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt).
- `COPY tmp:<key> <key> REPLACE` (Redis 6.2+) — alternative without consuming the source.

**4. Idempotency keys:**

- `SET idem:<request-id> "processing" NX PX <ttl-ms>` — atomic check-and-reserve. `NX` succeeds only if the key did not exist. Per [`mercury atomic-updates.md §Pattern 4`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt).
- On success → process the request and store the result: `MSET idem:<id> "complete" idem:<id>:result <payload>`.
- On failure (already present) → return the cached result or "processing" status.

**5. Ordered-writes-for-crash-safety:**

- Sequence writes in an order where any partial-completion state is still valid (or idempotently re-completable).
- Example: flip source-of-truth first (`HSET state retired`), then best-effort cleanup (multiple `DEL`s). A crash between source-of-truth and cleanup leaves the system in a consistent-but-dirty state; a resume pass can finish cleanup.
- Not strictly atomic; chooses crash-safety + simplicity over strict MULTI/EXEC atomicity.

## Rose Tree + FTR-009 Application

FTR-009 uses three of the five variants — each at the appropriate point:

**Lua scripts (echomq-go job-lifecycle transitions).** BullMQ state transitions run as Lua scripts because they touch multiple keys (wait/active/event-stream/lock/stalled) and must be strictly atomic. The FTR-008 `SendMessageBridge` dual-write (`MULTI / XADD topic-key / XADD mailbox-key / EXEC`) uses MULTI/EXEC as the cluster-safe atomicity primitive. See [FTR-009 `mailbox-keyspace.md` §5](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).

**Ordered-writes-for-crash-safety (teammate retirement).** The 12-transition teammate lifecycle retirement sequence is NOT a MULTI/EXEC transaction. Per [FTR-009 `teammate-lifecycle.md` §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md), the sequence is:

1. `HSET cclin:mbox:<team>:<agent>:meta state retired` — flip source of truth FIRST
2. `HDEL cclin:team:<team>:roster <agent>` — remove from roster
3. `ZREM cclin:team:<team>:active <agent>` — remove from active ZSET
4. `DEL cclin:mbox:<team>:<agent>:{stream,meta,heartbeat}` — destructive cleanup

A crash between (1) and (4) leaves the mailbox keys intact but `state=retired`. Subsequent reads see retired and skip the mailbox. A resume pass completes cleanup. This is crash-safe without MULTI's overhead.

**Lock-CAS via Lua (heartbeat refresh).** The echomq-go `ExtendLock` Lua script uses compare-and-swap to protect against lock theft — see the echomq-go code anchor below + [`session-management.md`](session-management.md).

FTR-009 does NOT use:

- WATCH/MULTI/EXEC optimistic locking — the state-machine writes are single-key (`HSET meta state <x>`); no cross-key invariant needs WATCH protection.
- Shadow-key + RENAME — state objects are small Hashes, not bulk documents; piecemeal `HSET` is adequate.
- Standalone idempotency keys — handler idempotency is achieved via `extensions.event_id` LRU dedup in the iteration-event consumer per [FTR-009 `iteration-events.md` §8](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md), not by inline `SET NX` key reservation.

## echomq-go code anchor

EchoMQ is a showcase of the Lua-script + lock-CAS variants:

- **ExtendLock — CAS-protected lock refresh.** [`../../pkg/echomq/scripts/scripts.go:1487-1508`](../../pkg/echomq/scripts/scripts.go):
  ```lua
  local rcall = redis.call
  if rcall("GET", KEYS[1]) == ARGV[1] then
    if rcall("SET", KEYS[1], ARGV[1], "PX", ARGV[2]) then
      rcall("SREM", KEYS[2], ARGV[3])
      return 1
    end
  end
  return 0
  ```
  This is the canonical compare-and-swap shape: check token, set with PX, release from stalled set, return 1. Non-matching token → return 0 (lock was stolen). The single-script execution is guaranteed atomic.
- **MoveToActive — multi-key atomic job pickup.** [`../../pkg/echomq/scripts/scripts.go:10-246`](../../pkg/echomq/scripts/scripts.go) — takes 11 KEYS (wait/active/prioritized/event-stream/stalled/rate-limiter/delayed/paused/meta/priority-counter/marker) and atomically: acquires a lock, emits an XADD event, updates `processedOn`, increments attempt counter, handles rate-limit counters + marker. Cannot be decomposed into individual Redis commands without a race.
- **MoveToFinished — multi-key atomic state transition.** [`../../pkg/echomq/scripts/scripts.go:247-1101`](../../pkg/echomq/scripts/scripts.go) — the completed-or-failed state flip. Inside, `XTRIM MAXLEN ~` enforces event-stream retention at [`scripts.go:906`](../../pkg/echomq/scripts/scripts.go) — see [`streams-event-sourcing.md`](streams-event-sourcing.md).
- **RetryJob — state transition with delay-queue promotion.** [`../../pkg/echomq/scripts/scripts.go:1102-1308`](../../pkg/echomq/scripts/scripts.go) — atomically moves a failed job back to wait OR schedules it in delayed ZSET based on backoff config.
- **Go-caller loads scripts once as `redis.NewScript`:** [`../../pkg/echomq/worker_impl.go:14-21`](../../pkg/echomq/worker_impl.go):
  ```go
  var moveToActiveScript = redis.NewScript(scripts.MoveToActive)
  var moveToFinishedScript = redis.NewScript(scripts.MoveToFinished)
  var retryJobScript = redis.NewScript(scripts.RetryJob)
  ```
  The go-redis `redis.Script` helper does `EVALSHA` first with fallback to `EVAL` on `NOSCRIPT` — idiomatic pattern for pre-loaded Lua.
- **Script dispatch site:** [`../../pkg/echomq/worker_impl.go:112`](../../pkg/echomq/worker_impl.go) — `moveToActiveScript.Run(ctx, redisClient, keys, args...)`.

BullMQ's Lua-script-per-transition shape (not MULTI/EXEC) is the correct choice because:

1. Conditional logic (rate-limit check, paused-queue branching, delayed-promotion) cannot be expressed in MULTI/EXEC command sequences.
2. Scripts are cluster-safe as long as all KEYS share slot (enforced by [`hash-tag-colocation.md`](hash-tag-colocation.md)).
3. SHA1-cached scripts (`EVALSHA`) minimize parse overhead per call.

## Antipatterns avoided

**1. Using MULTI/EXEC for conditional logic.** MULTI cannot branch — commands queue unconditionally and EXEC commits them all. If the logic is "if balance > amount, DECR; else abort", MULTI cannot express it. Per [`mercury atomic-updates.md §Pattern 2`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt), Lua is the correct tool for conditional atomicity. BullMQ uses Lua everywhere for this reason.

**2. Lock refresh without CAS check.** Extending a lock via `SET <lockKey> <token> PX <ttl>` unconditionally overwrites whatever token is currently there — including a lock stolen by another worker. Per [echomq-go `heartbeat.go:97-102`](../../pkg/echomq/heartbeat.go), the `ExtendLock` Lua performs `GET` → token-check → `SET` atomically, returning 0 on theft so the heartbeat loop can stop and abandon the job.

**3. WATCH in a tight retry loop without backoff.** A hot row under contention can exhaust retries by accidentally colliding every attempt. Per [`mercury atomic-updates.md §Retry Loop`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt), bound retries (typically 5) and add exponential backoff; WATCH failures signal contention, not transient Redis errors.

**4. Non-idempotent handlers without idempotency keys.** At-least-once delivery (see [`reliable-queue.md`](reliable-queue.md)) means handlers may run twice. Without idempotency keys OR a handler-internal dedupe, the second run produces double-effects. Per [echomq-go `CLAUDE.md §Idempotency`](../../CLAUDE.md), handlers MUST be idempotent (idempotency key, DB unique constraint, or external idempotency token).

**5. RENAME across slots in cluster mode.** `RENAME tmp:key final:key` fails with `CROSSSLOT` if the two keys hash to different slots. Per [`mercury atomic-updates.md §Pattern 3 Cluster Note`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt), tag both keys consistently: `{scope}:tmp` and `{scope}:final`.

**6. Ordering retirement writes incorrectly — cleanup before source-of-truth flip.** If `DEL` runs first and the crash precedes `HSET state retired`, subsequent reads see a mailbox with partial keys (stream deleted; meta present) — a corrupt state. FTR-009 retirement flips source-of-truth FIRST for exactly this reason; see [FTR-009 `teammate-lifecycle.md` §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md).

## Cross-references

FTR consumers:

- [FTR-009 `teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) — 12-transition state machine; retirement uses ordered-writes
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — bridgeEnvelope dual-write uses MULTI/EXEC
- [FTR-009 `reader-loop.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) — XACK is its own atomic surface; handler atomicity is application-level
- FTR-010 (future) HITL — draft-approval state machine likely uses Lua for complex conditional transitions

Sibling patterns:

- [`streams-consumer-groups.md`](streams-consumer-groups.md) — XACK is atomic and does not need MULTI
- [`reliable-queue.md`](reliable-queue.md) — LMOVE is a single atomic operation; Lua covers multi-key variants
- [`session-management.md`](session-management.md) — lock-CAS refresh pattern applied to session identity
- [`hash-tag-colocation.md`](hash-tag-colocation.md) — required for any multi-key Lua or MULTI in cluster mode
- [`delayed-queue.md`](delayed-queue.md) — ZRANGEBYSCORE + ZREM atomic claim is a mini-atomic-update

Mercury-design source:

- [`fundamental/atomic-updates.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/atomic-updates.md.txt) — all 5 pattern variants enumerated

## Worked example

WATCH/MULTI/EXEC optimistic locking (mercury-design canonical shape; not used by FTR-009 but available):

```bash
# Deduct from an account balance atomically, with retry on contention
WATCH account:123:balance

# Read current state
GET account:123:balance
# "500"

# Application logic: validate, compute new balance
# new_balance = 500 - 100 = 400

MULTI
SET account:123:balance 400
EXEC
# If another client changed balance after WATCH, EXEC returns (nil) — retry
```

Lua script (the BullMQ + FTR-009 preferred shape):

```bash
# Load once; use SHA thereafter
EVAL "
  local current = tonumber(redis.call('GET', KEYS[1])) or 0
  local amount = tonumber(ARGV[1])
  if current < amount then
    return {err='insufficient'}
  end
  redis.call('DECRBY', KEYS[1], amount)
  redis.call('INCRBY', KEYS[2], amount)
  return 'OK'
" 2 account:{123}:balance account:{456}:balance 100
# Cluster-safe because both keys share {123}? No — {123} vs {456} are different slots.
# To be cluster-safe across entities, use a saga/compensating-transaction pattern
# per cross-shard-consistency (not covered by this FTR).
```

FTR-009 retirement ordered-write sequence (the crash-safe non-MULTI variant):

```bash
# 1) FIRST flip source of truth (resume pass reads this to decide cleanup status)
HSET cclin:mbox:{flyer-a1}:mars-3:meta state retired

# 2) Remove from multi-agent roster
HDEL cclin:team:{flyer-a1}:roster mars-3

# 3) Remove from active ZSET
ZREM cclin:team:{flyer-a1}:active mars-3

# 4) Destructive cleanup (can be MULTI, but individual DELs are also fine)
DEL cclin:mbox:{flyer-a1}:mars-3:stream \
    cclin:mbox:{flyer-a1}:mars-3:meta \
    cclin:mbox:{flyer-a1}:mars-3:heartbeat

# Crash between (1) and (4): subsequent reads see state=retired; resume pass continues cleanup.
# Crash before (1): no state change; retry retire is a no-op from the caller's perspective.
```

Lua lock-CAS refresh (the echomq-go `ExtendLock` pattern, used by heartbeat):

```bash
# KEYS[1] = lock key; KEYS[2] = stalled set
# ARGV[1] = worker's lock token; ARGV[2] = new lock duration in ms; ARGV[3] = jobID
EVAL "
  local rcall = redis.call
  if rcall('GET', KEYS[1]) == ARGV[1] then
    if rcall('SET', KEYS[1], ARGV[1], 'PX', ARGV[2]) then
      rcall('SREM', KEYS[2], ARGV[3])
      return 1
    end
  end
  return 0
" 2 bull:{myqueue}:job-abc:lock bull:{myqueue}:stalled \
  worker-token-xyz 30000 job-abc
# Returns 1 if this worker still holds the lock; 0 if lock was stolen.
```

Go-side Lua-caller pattern (mirrors [`../../pkg/echomq/worker_impl.go:14-21`](../../pkg/echomq/worker_impl.go)):

```go
// Load once at package init (no runtime cost)
var moveToActiveScript = redis.NewScript(scripts.MoveToActive)

// Invoke per operation — go-redis handles EVALSHA → EVAL fallback on NOSCRIPT
keys := buildMoveToActiveKeys(kb)  // all cluster-safe via shared hash tag
args := []interface{}{
    kb.Prefix(),
    timestamp,
    packedOpts,
}
result, err := moveToActiveScript.Run(ctx, redisClient, keys, args...).Result()
```

Idempotency key (for handlers that cannot be made idempotent otherwise):

```bash
# Atomic check-and-reserve; TTL long enough to cover worst-case processing
SET idem:charge:req-abc "processing" NX PX 86400000
# (integer) 1  → we own this request; process it
# (integer) 0  → already seen; return cached result
MSET idem:charge:req-abc "complete" idem:charge:req-abc:result <charge-id>

# Second arrival:
SET idem:charge:req-abc "processing" NX PX 86400000  # → nil (already present)
GET idem:charge:req-abc:result                        # → <charge-id>
```
