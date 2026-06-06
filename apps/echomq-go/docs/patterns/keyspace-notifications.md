# Keyspace Notifications

Redis publishes structured events on dedicated pubsub channels when keys mutate or expire. Activated by `CONFIG SET notify-keyspace-events <flags>`; consumed via `PSUBSCRIBE __keyevent@<db>__:*` or `__keyspace@<db>__:<key>`. Useful for reactive alternatives to polling — but inherits pubsub's fire-and-forget semantics, so CCLIN uses polling with age-metadata instead of subscribing to expiration events for the staleness pipeline.

**Primary use-case axis:** B — human-in-loop signalling (TTL-expired reactivity for liveness signals).
**Secondary axes:** A (reactive alternative to supervisor polling), C (future cross-process TUI dashboards may consume).

## Primitive

Redis 2.8+ feature; off by default for CPU reasons. Two pieces: configuration to enable and publication; subscription to consume.

**Configuration:**

- `CONFIG SET notify-keyspace-events <flags>` — enables event generation. Per [`mercury keyspace-notifications.md §Configuration`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), flags are character-composable:
  - `K` — Keyspace events (channel prefix `__keyspace@<db>__`)
  - `E` — Keyevent events (channel prefix `__keyevent@<db>__`)
  - `g` — generic commands (DEL, EXPIRE, RENAME, ...)
  - `$` — string commands
  - `l` — list commands
  - `s` — set commands
  - `h` — hash commands
  - `z` — sorted-set commands
  - `t` — stream commands
  - `x` — expired events
  - `e` — evicted events
  - `A` — alias for `g$lshztdxe` (all except miss/new/overwritten/type-changed)
- At least one of `K` or `E` MUST be present or no events emit.

**Publication (Redis-generated):**

Per [`mercury keyspace-notifications.md §Type of events`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), every operation generates two PUBLISH calls:

```
PUBLISH __keyspace@<db>__:<key>  <event-name>
PUBLISH __keyevent@<db>__:<event-name>  <key>
```

Example event names: `del`, `expire`, `expired`, `set`, `hset`, `lpush`, `xadd`, `xtrim`.

**Subscription:**

- `PSUBSCRIBE __keyevent@0__:expired` — fire a handler for every key expiration in database 0.
- `SUBSCRIBE __keyspace@0__:mykey` — fire a handler for every operation on one specific key.
- `PSUBSCRIBE __keyspace@0__:user:*` — pattern-subscribe to all mutations on user:* keys.

Fire-and-forget semantics apply — per [`mercury keyspace-notifications.md §Type of events`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), disconnected subscribers lose events. Redis Cluster fanout is per-node (each master node publishes its own events; no cluster-wide broadcast).

## Rose Tree + FTR-009 Application

FORWARD-REF: FTR-016

FTR-009 **does not** use keyspace notifications. The staleness-detection pipeline polls instead, and documents the trade-off explicitly:

- Staleness source of truth is `cclin:mbox:<team>:<agent>:meta.heartbeat_last_refresh_ms` (continuous age-in-ms), not the heartbeat-key TTL expiry (binary). See [FTR-009 `staleness-policy.md` §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md).
- The Pluto supervise cron runs every 2 minutes and reads `heartbeat_last_refresh_ms` to compute `age = now - last_refresh` and compare against state-conditional thresholds (active 30m/2h/6h; idle 2h/6h/24h). See [FTR-009 `staleness-policy.md` §2-§3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md).

Why polling instead of keyspace notifications:

1. **Age-in-ms vs. binary.** Keyspace notifications emit `expired` only when the TTL hits zero — a binary signal. The staleness ladder (L1 warning, L2 alert, reap) needs continuous age so age > L1 and age > L2 can fire at different thresholds on the same heartbeat-key before expiry. A binary `expired` event cannot carry this gradation.
2. **Fire-and-forget loses events during reader reconnect.** Per [`mercury keyspace-notifications.md §Type of events`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), keyspace notifications are regular Pub/Sub — a supervisor that reconnects after 2m of downtime loses every expiration event that fired during the gap. A missed L1-crossing is a production-relevant fidelity loss.
3. **Per-node pubsub in cluster mode.** In Redis Cluster, each master publishes its own keyspace events. A supervisor subscribing to one node misses events on other nodes. Polling via `cclin:teams` + per-team roster scan works uniformly across cluster modes.

**When keyspace notifications IS the right choice (documented trade-off):**

- Sub-second TTL reactivity where loss is tolerable — caches, session-invalidation broadcasts, game-lobby cleanup.
- Single-instance Redis with reliable subscriber connection, where the cost of binary expiry is not a correctness issue.
- Cases where polling cadence cannot be tightened further and keyspace `expired` closes the latency gap.

FTR-016 (Redis Cluster deployment) will revisit this pattern — cluster-mode multi-node subscription fanout is a design problem; the forward-pointer is intentional.

## echomq-go code anchor

FORWARD-REF: FTR-016

Current echomq-go does not subscribe to keyspace notifications. BullMQ delayed-job promotion (see [`delayed-queue.md`](delayed-queue.md)) uses ZSET polling inside the `MoveToActive` Lua script at [`../../pkg/echomq/scripts/scripts.go:187-215`](../../pkg/echomq/scripts/scripts.go) — the same rationale as FTR-009 staleness: continuous score-comparison beats binary expiry.

Pub/Sub infrastructure already in echomq-go (for reference — used for keyspace-style fanout in the future):

- `redis.Cmdable.Subscribe(ctx, channels...)` via the standard go-redis client is available but unused in current BullMQ paths.

## Antipatterns avoided

**1. Using keyspace `expired` for session-absent detection when liveness age matters.** A subscriber waiting on `__keyevent@0__:expired` learns that a heartbeat TTL hit zero — not that the heartbeat is 30 seconds old. Per [FTR-009 `staleness-policy.md` §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md), "Why not rely only on TTL expiry? TTL expiry is a binary signal (fresh/expired). Age-in-milliseconds is continuous — enables the L1/L2/reap ladder."

**2. Treating keyspace events as durable.** Per [`mercury keyspace-notifications.md §Type of events`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), keyspace notifications are fire-and-forget pubsub — disconnected subscribers miss every event during the gap. If the reactive handler must run for every event, the pattern is wrong — use a tail-the-stream approach with a durable record of state changes.

**3. Enabling `KEA` globally when only `Ex` is needed.** `KEA` emits every keyspace + keyevent event for generic/string/list/set/hash/zset/stream operations — a significant CPU cost at high write throughput. Per [`mercury keyspace-notifications.md §Configuration`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), enable only the flag set the handler actually consumes: `Ex` for expirations, `El` for list mutations, etc.

**4. Assuming cluster-wide event delivery.** Per [`mercury keyspace-notifications.md`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt), Redis Cluster publishes keyspace events per-node; a subscriber to one master misses events from other masters. Cluster-aware consumers must subscribe on every master and dedupe — a design problem that FTR-016 defers.

## Cross-references

FTR consumers:

- [FTR-009 `staleness-policy.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/staleness-policy.md) — explicit rejection of keyspace-notifications in favor of polling + age-meta
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — heartbeat-key TTL used as hint, not source of truth
- FTR-016 (future) Redis Cluster — revisit per-node subscription fanout
- FTR-018 (future) web dashboard — may use keyspace events for cache-invalidation fanout

Sibling patterns:

- [`pubsub-fanout.md`](pubsub-fanout.md) — generic pubsub primitive; keyspace-notifications is a specialized Redis-generated variant
- [`session-management.md`](session-management.md) — legitimate pubsub use for cross-server session invalidation
- [`streams-event-sourcing.md`](streams-event-sourcing.md) — durable alternative when event loss is intolerable

Mercury-design source:

- [`commands/content/develop/pubsub/keyspace-notifications.md`](/Users/jonny/dev/mercury-design/redis-patterns/commands/content/develop/pubsub/keyspace-notifications.md.txt) — primitive reference + flag enumeration
- [`community/pubsub.md`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt) — Pub/Sub semantics this variant inherits

## Worked example

Enable expired-event notifications and subscribe:

```bash
# Enable keyevent channels for expiration events in database 0
CONFIG SET notify-keyspace-events Ex

# Set a key with a short TTL
SET session:abc123 "{\"user_id\":1}" EX 30

# In another connection, subscribe to expiration events
PSUBSCRIBE __keyevent@0__:expired
# After 30 seconds, receives:
# 1) "pmessage"
# 2) "__keyevent@0__:expired"
# 3) "__keyevent@0__:expired"
# 4) "session:abc123"
```

Go-side reactive session-cleanup handler (for reference; NOT used in FTR-009):

```go
// Enable keyspace notifications (once, at deploy time)
client.ConfigSet(ctx, "notify-keyspace-events", "Ex")

// Reactive handler — drop local cache on key expiration
pubsub := client.PSubscribe(ctx, "__keyevent@0__:expired")
defer pubsub.Close()

for msg := range pubsub.Channel() {
    expiredKey := msg.Payload
    localCache.Evict(expiredKey)
}
```

Contrast — the FTR-009 polling approach (the chosen design):

```go
// Pluto supervise cron — every 2 minutes
func (s *Supervisor) Sweep(ctx context.Context) {
    teams, _ := s.redis.SMembers(ctx, "cclin:teams").Result()
    for _, team := range teams {
        roster, _ := s.redis.HGetAll(ctx, "cclin:team:"+team+":roster").Result()
        for agent := range roster {
            metaKey := fmt.Sprintf("cclin:mbox:%s:%s:meta", team, agent)
            meta, _ := s.redis.HMGet(ctx, metaKey,
                "state", "heartbeat_last_refresh_ms").Result()
            lastMs, _ := strconv.ParseInt(meta[1].(string), 10, 64)
            age := time.Since(time.UnixMilli(lastMs))
            s.applyThresholds(ctx, team, agent, meta[0].(string), age)
        }
    }
}
```

The polling variant carries continuous age (drives L1/L2/reap ladder) and survives the 2-minute supervise window even if every Redis node restarts — the keyspace-events variant cannot.
