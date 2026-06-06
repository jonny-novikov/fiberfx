# Hash-Tag Co-Location

Redis Cluster distributes keys across 16,384 slots using CRC16 of the key name. A hash tag `{...}` tells the cluster to hash only the tag content, forcing related keys into the same slot. This is the sole mechanism for multi-key atomic operations, transactions, and Lua scripts in cluster mode. Without hash tags, any `MULTI/EXEC` or `EVAL` touching multiple keys fails with `CROSSSLOT`. Echomq-go auto-detects cluster mode and wraps queue names in `{queue-name}`; FTR-009 pre-wires the same shape for its `{team}`-scoped mailbox keyspace.

**Primary use-case axes:** A + B + D — cluster-mode substrate for supervisor/worker messaging AND human-in-loop mailboxes AND session-state storage (the highest axis-count pattern in the library; fundamentally cross-cutting).
**Secondary axis:** C — TUI keys rarely need co-location but inherit consistent naming.

## Primitive

Redis 3.0+ cluster-slot placement with optional tag directive.

- **Default placement:** CRC16 of the entire key name, modulo 16,384. Per [`mercury hash-tag-colocation.md §How Hash Tags Work`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt), `user:123:profile` and `user:123:settings` hash to different slots because they are different strings.
- **Tagged placement:** if the key contains `{...}`, the cluster hashes only the content between the first `{` and `}`. Per [`mercury hash-tag-colocation.md §How Hash Tags Work`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt), `user:{123}:profile` and `user:{123}:settings` both hash "123" and land in the same slot.
- **First-tag-wins:** per [`mercury hash-tag-colocation.md §Multiple Hash Tags`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt), only the first `{...}` pair determines the slot — `{a}:{b}:key` hashes "a" and ignores "b".
- **Empty tag is a no-op:** `key:{}:suffix` hashes the entire key because the tag body is empty.

Commands requiring co-location:

- `MULTI` / `EXEC` transactions — all keys must share slot.
- `EVAL` / `EVALSHA` Lua scripts — all KEYS must share slot.
- `WATCH <key1> <key2>` — for multi-key optimistic locking per [`atomic-updates.md`](atomic-updates.md).
- `RENAME src dst` / `COPY src dst` — both keys must share slot.
- `SMOVE`, `LMOVE`, `ZUNIONSTORE` with `STORE` target — participants must share slot.

Non-multi-key commands (`GET`, `HSET`, `ZADD`, `XADD`, `LPUSH`, `SADD` on single keys) work identically in cluster and non-cluster modes; hash tags affect placement, not semantics.

Commands that ignore hash-tag placement:

- `KEYS` / `SCAN` — slot-aware only via `SCAN` with `HASH` option, not broadcast fanout.
- `PUBLISH` / `SUBSCRIBE` — per-node in cluster mode; hash tags do not produce cluster-wide fanout.
- `FLUSHDB` — node-scoped.

## Rose Tree + FTR-009 Application

FTR-009 pre-wires cluster-safe placement even at H1 (single-node Redis) so that H3 cluster deployment requires zero keyspace refactoring:

- **Mailbox keyspace pattern:** `cclin:mbox:{<team>}:<agent>:{stream,meta,heartbeat}` — the `{<team>}` hash tag co-locates all of a team's mailbox keys into the same slot. See [FTR-009 `mailbox-keyspace.md` §8.6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) for the forward-pointer to H3.
- **Team-scoped roster + activity:** `cclin:team:{<team>}:{roster,active}` share the same team slot, enabling future atomic multi-key transactions over roster changes.
- **Cross-team operations NOT supported under single-slot model:** a multi-team atomic transaction spanning `{team-a}` and `{team-b}` keys would require cross-slot coordination — see [`mercury hash-tag-colocation.md §Cross-Entity Operations`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt). FTR-009's design respects this boundary (each team is autonomous; cross-team ops route through director-level coordination).
- **Iteration-event streams:** follow the same `{team}` hash-tag placement for cluster readiness.

H1 posture (currently active): single-instance Redis 7.x, where hash tags are no-ops but their syntactic presence is preserved. Auto-detection via `IsRedisCluster(client)` — see the echomq-go reference implementation below.

H3 posture (future, FTR-016): multi-node Redis Cluster. Every per-team operation stays within a single slot; cross-team operations explicitly acknowledge cross-slot cost.

## echomq-go code anchor

EchoMQ is the canonical cluster-detection + auto-tagging implementation:

- Cluster detection (type-assertion on Redis client): [`../../pkg/echomq/cluster.go:171-175`](../../pkg/echomq/cluster.go) — `IsRedisCluster(client)` checks if the client is `*redis.ClusterClient`.
- KeyBuilder auto-applies hash tags on detection: [`../../pkg/echomq/keys.go:23-28`](../../pkg/echomq/keys.go) — `NewKeyBuilder` stores `useHashTags: IsRedisCluster(client)`; every key method switches on this flag.
- Explicit override for force-on / force-off: [`../../pkg/echomq/keys.go:34-39`](../../pkg/echomq/keys.go) — `NewKeyBuilderWithHashTags(queueName, useHashTags bool)` bypasses auto-detection.
- Key method applies hash tag conditionally (pattern repeats across 14 methods at [`../../pkg/echomq/keys.go:42-197`](../../pkg/echomq/keys.go)):
  ```go
  func (kb *KeyBuilder) Wait() string {
      if kb.useHashTags {
          return fmt.Sprintf("bull:{%s}:wait", kb.queueName)
      }
      return fmt.Sprintf("bull:%s:wait", kb.queueName)
  }
  ```
- CRC16 slot calculation (mirror of the Redis implementation for client-side preflight): [`../../pkg/echomq/cluster.go:52-58`](../../pkg/echomq/cluster.go) — `CalculateCRC16(data)` computes the CRC16-CCITT used by Redis Cluster.
- Hash-tag extraction for slot computation: [`../../pkg/echomq/cluster.go:63-93`](../../pkg/echomq/cluster.go) — `GetClusterSlot(key)` scans for the first `{`, then the first `}` after it, and hashes the substring between (falls back to full-key hash when tag is absent or empty).
- Multi-key slot validation (catches `CROSSSLOT` at client boundary before `EVAL` fires): [`../../pkg/echomq/cluster.go:95-114`](../../pkg/echomq/cluster.go) — `ValidateHashTags(keys)` returns `(bool, firstSlot, perKeySlots)`.
- Hash-tag pattern propagates through every subsystem (heartbeat, stalled, completer, progress, events): [`../../pkg/echomq/worker.go:93`](../../pkg/echomq/worker.go) — "All subsystems... MUST consume [the shared KeyBuilder]" enforces single-source-of-truth for tag placement across the codebase.

BullMQ's Lua scripts all reference KEYS[1..N] passed by the Go caller; because the caller uses the KeyBuilder, every KEYS[i] shares the queue's hash-tag bucket in cluster mode. This is the reference pattern for any multi-key Lua script — all keys share a `{queue}` or `{team}` tag; the Go caller builds them via a single KeyBuilder instance.

## Antipatterns avoided

**1. Placing the tag on the wrong token.** `user:123:{profile}` hashes "profile" — every user's profile lands in the same slot, creating a hot slot that cannot shard. Per [`mercury hash-tag-colocation.md §Hash Tag Placement Rules`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt), the entity identifier is the right tag body — `user:{123}:profile` keeps users distributed across slots while co-locating one user's data.

**2. Multi-key Lua scripts without hash tags in cluster mode.** A script taking `KEYS[1] = "bull:queue:wait"` and `KEYS[2] = "bull:queue:active"` fails with `CROSSSLOT Keys in request don't hash to the same slot` when the client is a `*redis.ClusterClient`. Per [echomq-go `CLAUDE.md §Hash Tag Validation`](../../CLAUDE.md), the fix is to wrap the queue name: `bull:{queue}:wait` + `bull:{queue}:active` share slot.

**3. Empty hash tags.** `{}key:123` hashes the entire key because the tag body is empty. Per [`mercury hash-tag-colocation.md §Empty Hash Tags`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt), avoid empty braces unless the intent is explicit no-op.

**4. Hot-slot concentration from naive co-location.** Wrapping a celebrity user's key in `{celeb-123}` co-locates all their data into one slot and creates a bottleneck when that slot exceeds single-node throughput. Per [`mercury hash-tag-colocation.md §Hot Slot Problem`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt), mitigation strategies include sharding within the entity (`user:{123}:followers:0` ... `:31`), separating hot data into a non-tagged key family, or accepting eventual consistency with replica reads on a separate slot.

**5. Assuming pubsub respects hash-tag placement.** Per [`pubsub-fanout.md`](pubsub-fanout.md), cluster pubsub is per-node. Hash tags affect key placement, not channel scope.

## Cross-references

FTR consumers:

- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — `{team}` hash-tag posture at H1 for H3 cluster readiness
- [FTR-009 `teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) — atomic ordered-write retirement over co-located keys
- FTR-016 (future) — Redis Cluster deployment; this pattern becomes load-bearing
- FTR-014 (future) — multi-team dispatch isolation; uses `{team}` as the co-location unit

Sibling patterns:

- [`atomic-updates.md`](atomic-updates.md) — Lua and `MULTI/EXEC` require co-location in cluster mode
- [`streams-consumer-groups.md`](streams-consumer-groups.md) — stream + group keys must co-locate for consumer-group commands
- [`reliable-queue.md`](reliable-queue.md) — LMOVE source/dest must share slot
- [`delayed-queue.md`](delayed-queue.md) — ZSET + target wait/active lists must share slot for promotion Lua
- [`session-management.md`](session-management.md) — `{team}:<agent>:{meta,heartbeat}` co-location for session-state atomicity

Mercury-design source:

- [`fundamental/hash-tag-colocation.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/hash-tag-colocation.md.txt) — canonical placement rules + hot-slot mitigation

## Worked example

Placement rules comparison:

```bash
# Without hash tags — keys scatter across slots
CLUSTER KEYSLOT "bull:myqueue:wait"    # → slot X
CLUSTER KEYSLOT "bull:myqueue:active"  # → slot Y (different)

# Multi-key EVAL fails:
EVAL "..." 2 bull:myqueue:wait bull:myqueue:active
# (error) CROSSSLOT Keys in request don't hash to the same slot

# With hash tags — keys co-locate
CLUSTER KEYSLOT "bull:{myqueue}:wait"    # → slot Z
CLUSTER KEYSLOT "bull:{myqueue}:active"  # → slot Z (same)
CLUSTER KEYSLOT "bull:{myqueue}:events"  # → slot Z (same)

# Multi-key EVAL succeeds:
EVAL "..." 3 bull:{myqueue}:wait bull:{myqueue}:active bull:{myqueue}:events
# (ok)
```

FTR-009 mailbox co-location:

```bash
# All of team flyer-a1's mailbox + state keys share slot
CLUSTER KEYSLOT "cclin:mbox:{flyer-a1}:mars-3:stream"     # → slot T
CLUSTER KEYSLOT "cclin:mbox:{flyer-a1}:mars-3:meta"       # → slot T
CLUSTER KEYSLOT "cclin:mbox:{flyer-a1}:mars-3:heartbeat"  # → slot T
CLUSTER KEYSLOT "cclin:team:{flyer-a1}:roster"            # → slot T

# Cross-agent-same-team atomic transactions work
MULTI
HSET cclin:mbox:{flyer-a1}:mars-3:meta state retired
HDEL cclin:team:{flyer-a1}:roster mars-3
DEL cclin:mbox:{flyer-a1}:mars-3:stream
EXEC
# (all commands in same slot — atomic)

# Cross-team atomic transactions do NOT work (by design — teams are autonomous)
MULTI
HSET cclin:mbox:{flyer-a1}:mars-3:meta paused 1
HSET cclin:mbox:{echo-b2}:mars-4:meta paused 1
EXEC
# (error) CROSSSLOT — cross-team atomicity requires saga or distributed-lock
```

Go-side auto-detection (the echomq-go KeyBuilder shape):

```go
kb := echomq.NewKeyBuilder("myqueue", client)
// Single-instance Redis: kb.useHashTags = false
//   kb.Wait()    → "bull:myqueue:wait"
// Cluster Redis: kb.useHashTags = true
//   kb.Wait()    → "bull:{myqueue}:wait"

// Force-override for testing / advanced override
kbForced := echomq.NewKeyBuilderWithHashTags("myqueue", true)
kbForced.Wait()    // → "bull:{myqueue}:wait" always

// Multi-key slot validation before EVAL dispatch
keys := []string{kb.Wait(), kb.Active(), kb.Events()}
ok, firstSlot, perKey := echomq.ValidateHashTags(keys)
if !ok {
    return fmt.Errorf("CROSSSLOT: first=%d perKey=%v", firstSlot, perKey)
}
```

Hot-slot mitigation (FTR-014 multi-team isolation scenario):

```bash
# Naive: one celebrity team's keys over-concentrate
CLUSTER KEYSLOT "cclin:mbox:{mega-team}:mars-1:stream"  # → slot H (hot)
CLUSTER KEYSLOT "cclin:mbox:{mega-team}:mars-2:stream"  # → slot H
... # 500 agents all → slot H

# Mitigated: shard by agent bucket within team
CLUSTER KEYSLOT "cclin:mbox:{mega-team:0}:mars-001:stream"  # → slot H1
CLUSTER KEYSLOT "cclin:mbox:{mega-team:1}:mars-002:stream"  # → slot H2
... # 32 buckets × ~16 agents = even distribution across 32 slots

# Loses cross-agent atomicity within the team; gains horizontal scale.
# FTR-014 cites this pattern as a revisit-trigger for 10-team-deployment scale-out.
```
