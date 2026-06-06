# Session Management

Store identity state in a Redis Hash for field-level access, bound liveness by a short-TTL heartbeat key with sliding refresh, track multi-device ownership via a Set (or Hash) per principal, and broadcast invalidations over Pub/Sub. This pattern names the shape that FTR-009 uses for per-teammate lifecycle meta, not a web-session story — the primitives are identical; the actors are agents + teams + iteration-events instead of browsers + users + cookies.

**Primary use-case axis:** D — session-state persist/restore (lifecycle meta + heartbeat TTL).
**Secondary axes:** A (worker's own lifecycle state), B (operator identity tracking for multi-device aspirations).

## Primitive

Hash-based session storage plus a sidecar heartbeat + multi-principal tracking + invalidation fanout.

Core commands:

- `HSET <session-key> field1 val1 field2 val2 ...` — set multiple session attributes. Per [`mercury session-management.md §Hash-Based Sessions`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt).
- `HGETALL <session-key>` — retrieve the complete session; `HMGET` for a subset; `HINCRBY` for counter fields.
- `HSET <session-key> last_access <ms>` — update a single field without rewriting the whole session.
- `EXPIRE <key> <seconds>` — set or update TTL. Sliding expiration resets this on each access — per [`mercury session-management.md §Sliding Expiration`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt).
- `SET <key> <value> EX <seconds>` — string-based session variant when field-level access is not required.
- `SET <key> <value> EX <seconds> XX` — refresh existing session only; no create. Useful for "extend only if still alive" semantics.
- `SADD <principal>:<sessions> <session-id>` — track multiple concurrent sessions for one principal. Per [`mercury session-management.md §Multi-Device Session Tracking`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt).
- `SMEMBERS <principal>:<sessions>` — enumerate active sessions for logout-all-devices.
- `DEL <session-key>` + `SREM <principal>:<sessions> <session-id>` — single-device logout.
- `PUBLISH <channel> <session-id>` — broadcast invalidation across app servers (see [`pubsub-fanout.md`](pubsub-fanout.md)).

Semantics: per-key TTL drives automatic expiry; active usage refreshes TTL (sliding window); explicit DEL drives immediate logout. Multi-server consistency leans on pubsub for cross-process cache coherence.

## Rose Tree + FTR-009 Application

FTR-009's teammate-lifecycle maps directly to this pattern with the role of "user session" taken by "agent's presence within a team":

- **Session-state Hash:** `cclin:mbox:<team>:<agent>:meta` holds `state`, `archetype`, `created_at`, `heartbeat_last_refresh_ms`, `last_activity`, and other lifecycle fields. See [FTR-009 `teammate-lifecycle.md` §1](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) + [FTR-009 `mailbox-keyspace.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).
- **Heartbeat TTL key:** `cclin:mbox:<team>:<agent>:heartbeat` is a string key with 60-second TTL refreshed every 15s by the reader loop. See [FTR-009 `mailbox-keyspace.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) + [FTR-009 `reader-loop.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).
- **Multi-principal roster:** `cclin:team:<team>:roster` Hash maps `<agent> -> <role>` — the "multi-device session for one user" analogue is "multi-agent for one team". See [FTR-009 `mailbox-keyspace.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).
- **Active-activity ZSET:** `cclin:team:<team>:active` keys agents by score = last-activity unix-ms. Reads power the "Supervise" TUI tab. See [FTR-009 `mailbox-keyspace.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).
- **Session invalidation via retirement:** `teammate_retire` MCP tool writes `meta.state = "retired"` then executes ordered DEL of stream/meta/heartbeat keys — see [`atomic-updates.md`](atomic-updates.md) + [FTR-009 `teammate-lifecycle.md` §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md).
- **Cross-server invalidation:** FTR-009 single-process at H1; future FTR-018 web dashboard will need pubsub-based invalidation fanout per [`session-management.md` and `pubsub-fanout.md`](pubsub-fanout.md).

Sliding-expiration discipline: the reader loop refreshes `heartbeat` every 15s (writing `SET <key> 1 EX 60`) AND updates `meta.heartbeat_last_refresh_ms` as continuous-age ground truth. See [FTR-009 `staleness-policy.md` §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) — the continuous age is what drives the L1/L2/reap staleness ladder, because binary TTL expiry cannot.

Lifecycle state transitions gate on session state in a way classical sessions do not:

- `bootstrap` — created, heartbeat not yet firing
- `idle` — integrated, no active assignment
- `active` — executing work
- `remediate` — failed grade, revision in progress
- `stale` — heartbeat missed (L1); recoverable
- `retired` — terminal (mailbox cleanup)

See [FTR-009 `teammate-lifecycle.md` §1-§3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) for the full 6-state / 12-transition machine.

## echomq-go code anchor

EchoMQ's lock-heartbeat pattern is the session-management shape applied to job ownership instead of agent identity:

- Lock-key as session identity: [`../../pkg/echomq/keys.go:127-132`](../../pkg/echomq/keys.go) — `Lock(jobID)` returns `bull:<queue>:<jobID>:lock`. A worker "owns" a job while the lock exists with its token.
- Sliding-TTL refresh (exactly the FTR-009 heartbeat mechanic): [`../../pkg/echomq/heartbeat.go:60-105`](../../pkg/echomq/heartbeat.go) — `heartbeatLoop` runs a `time.Ticker` at `HeartbeatInterval` (default 15s) and invokes the `ExtendLock` Lua script to refresh the lock's `PX` duration. Failure counter tracked at [`heartbeat.go:91-101`](../../pkg/echomq/heartbeat.go).
- Lock-token CAS (protects against the "lock was stolen" race): [`../../pkg/echomq/scripts/scripts.go:1487-1508`](../../pkg/echomq/scripts/scripts.go) — `ExtendLock` Lua script checks `GET lockKey == token` before `SET PX`, returning 1 on success / 0 on theft.
- Session-end cleanup on completion: [`../../pkg/echomq/worker_impl.go:241-242`](../../pkg/echomq/worker_impl.go) — the Completer releases the lock and moves the job to `completed`/`failed`.
- Stalled-session recovery: [`../../pkg/echomq/stalled.go`](../../pkg/echomq/stalled.go) — scans the `active` list and on missing lock (session expired) resurrects the job for retry. This is the session-invalidation-via-TTL-expiry shape.

Lock duration default: 30s; heartbeat interval: 15s (half of TTL per [echomq-go `CLAUDE.md §Important Timing Parameters`](../../CLAUDE.md)). Identical rhythm to FTR-009's 60s-heartbeat + 15s-refresh (3x safety factor for network jitter).

## Antipatterns avoided

**1. Fixed-expiration sessions.** A session created with `EXPIRE 1800` and never refreshed logs out an actively working operator 30 minutes after login. Per [`mercury session-management.md §Sliding Expiration`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt), active usage MUST refresh the TTL — otherwise sessions expire from creation time, not from last-activity time.

**2. Storing large payloads inline in session.** A session containing a complete user profile + cart + preferences is costly to deserialize on every read. Per [`mercury session-management.md §Memory Optimization`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt), store only identifiers + essential hot fields; dereference to the primary store on cache-miss. EchoMQ + FTR-009 follow this — the Hash carries identity + state enum + counters, not bulk payload.

**3. Cross-server cache incoherence on logout.** Without pubsub invalidation, a user logs out on server A but continues to hold a valid session cache on server B. Per [`mercury session-management.md §Real-Time Session Invalidation`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt), broadcast on logout via `PUBLISH session:invalidate <id>`; every server subscribes and drops its local cache. FTR-009 is single-process at H1; FTR-018 will need this pattern.

**4. No dedicated ownership-CAS on heartbeat refresh.** A worker that extends its lock without checking the token clobbers a competing worker's claim. Per the echomq-go `ExtendLock` Lua at [`../../pkg/echomq/scripts/scripts.go:1487-1508`](../../pkg/echomq/scripts/scripts.go), the CAS check `if GET(lockKey) == token` is essential to detect lock-theft and abort the heartbeat (heartbeat.go:97-102).

## Cross-references

FTR consumers:

- [FTR-009 `teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) — 6-state machine on session-style meta Hash
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — keyspace registry (meta, heartbeat, roster, active)
- [FTR-009 `reader-loop.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) — 15s heartbeat refresh cadence
- [FTR-009 `staleness-policy.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) — continuous age drives L1/L2/reap thresholds
- FTR-010 (future) — HITL draft-approval sessions (either reuse teammate-lifecycle or its own session shape)
- FTR-018 (future) — web dashboard cross-server session invalidation via pubsub

Sibling patterns:

- [`atomic-updates.md`](atomic-updates.md) — ordered-write retirement sequence + Lua CAS for lock refresh
- [`hash-tag-colocation.md`](hash-tag-colocation.md) — cluster-mode slot placement for `{team}:<agent>:{meta,heartbeat}` co-location
- [`keyspace-notifications.md`](keyspace-notifications.md) — reactive TTL-expiry alternative (rejected by FTR-009 for continuous-age reasons)
- [`pubsub-fanout.md`](pubsub-fanout.md) — invalidation broadcast surface for cross-server logout
- [`streams-consumer-groups.md`](streams-consumer-groups.md) — mailbox stream that pairs with each session

Mercury-design source:

- [`community/session-management.md`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt) — Hash + sliding TTL + multi-device + invalidation reference
- [`community/pubsub.md`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt) — invalidation-fanout channel semantics

## Worked example

FTR-009 teammate-promote flow — this is the session-creation analogue:

```bash
# Promote a Mars teammate into team flyer-a1 (creates "session")
HSET cclin:mbox:flyer-a1:mars-3:meta \
     state idle \
     archetype mars \
     created_at 1714000000000 \
     heartbeat_last_refresh_ms 1714000000000

# Register in the team roster (multi-agent equivalent of multi-device)
HSET cclin:team:flyer-a1:roster mars-3 implementor

# Track presence in team index
SADD cclin:teams flyer-a1

# Initialize heartbeat key with sliding TTL
SET cclin:mbox:flyer-a1:mars-3:heartbeat 1 EX 60

# Create consumer group for mailbox stream
XGROUP CREATE cclin:mbox:flyer-a1:mars-3:stream \
              cclin:mbox:flyer-a1:mars-3:stream:grp \$ MKSTREAM
```

Reader-loop refresh every 15 seconds (the sliding-TTL heartbeat):

```bash
# Refresh heartbeat TTL + update continuous-age ground truth
SET cclin:mbox:flyer-a1:mars-3:heartbeat 1 EX 60
HSET cclin:mbox:flyer-a1:mars-3:meta \
     heartbeat_last_refresh_ms 1714000015000

# Touch the active-ZSET so supervise tab surfaces recent activity
ZADD cclin:team:flyer-a1:active 1714000015000 mars-3
```

Multi-device analogue — enumerate agents for "logout all" semantics:

```bash
# List every agent in a team (the "active sessions for user X" equivalent)
HGETALL cclin:team:flyer-a1:roster
# 1) "mars-3"
# 2) "implementor"
# 3) "venus-2"
# 4) "architect"
# 5) "apollo-4"
# 6) "evaluator"
```

Retirement (the "logout" analogue) — ordered-write per [`atomic-updates.md`](atomic-updates.md):

```bash
# First flip state to retired (source of truth for subsequent reads)
HSET cclin:mbox:flyer-a1:mars-3:meta state retired

# Remove from active + roster + teams index
HDEL cclin:team:flyer-a1:roster mars-3
ZREM cclin:team:flyer-a1:active mars-3

# Delete session keys in a single DEL
DEL cclin:mbox:flyer-a1:mars-3:stream \
    cclin:mbox:flyer-a1:mars-3:meta \
    cclin:mbox:flyer-a1:mars-3:heartbeat

# (Future FTR-018) Broadcast invalidation across all web-dashboard processes
PUBLISH cclin:session:invalidate mars-3@flyer-a1
```

Go-side sliding-TTL heartbeat mirror (the echomq-go pattern applied to sessions):

```go
type HeartbeatKeeper struct {
    redis   redis.Cmdable
    key     string
    interval time.Duration  // 15s (half of 30s TTL)
    ttl      time.Duration  // 60s for FTR-009; 30s for BullMQ locks
}

func (h *HeartbeatKeeper) Run(ctx context.Context) {
    ticker := time.NewTicker(h.interval)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            if err := h.redis.Set(ctx, h.key, 1, h.ttl).Err(); err != nil {
                // log; continue. Metric counter bumps on each failure.
                continue
            }
        }
    }
}
```
