# Hash-tag co-location

> Route: `/redis-patterns/coordination/hash-tag-colocation` · Module R2.05 · Source:
> `content/fundamental/hash-tag-colocation.md.txt`
> · Grounding: `EchoMQ.Keyspace.queue_key/2` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) returns
> `emq:{q}:<type>` — the hashtag IS the queue name, so every key of one queue answers one slot. `slot/1` computes
> the cluster slot client-side: CRC16-XMODEM over `hashtag/1` (the first non-empty `{…}` span) modulo 16384, the
> cluster specification's algorithm, so the connector routes without a server round trip. Vectors: the `{orders}`
> queue answers `slot 105`; the specification vector `slot("123456789") == 12739` (CRC16 `0x31C3`).

Force related keys to the same Valkey cluster slot using hash tags, enabling atomic multi-key operations,
transactions, and Lua scripts across logically related data.

Valkey cluster distributes keys across slots by a hash of the key name. A hash tag — a `{...}` substring — controls
which part of the key decides the slot, co-locating related keys so a multi-key `MULTI`/`EXEC` or Lua script stays
legal. R2.04 was the fallback for keys that cannot share a slot; this module is the prevention it substitutes for.

## How Hash Tags Work

Valkey cluster hashes only the substring inside `{...}` to pick the slot:

```
user:{123}:profile    → hashes "123" → slot 5970
user:{123}:settings   → hashes "123" → slot 5970
user:{123}:sessions   → hashes "123" → slot 5970
```

All three keys land on the same slot, so an operation across them runs on one node. Drop the tag and the whole key
is hashed instead, scattering the keys:

```
user:123:profile      → hashes the whole key → slot 8490
user:123:settings     → hashes the whole key → a different slot
```

A multi-key command needs every key on one slot; that is exactly what the tag arranges. The slot is
`CRC16(substring) % 16384` — and because it is pure arithmetic over the key bytes, a client can compute it without
asking the server.

## Basic Pattern: User Data Co-location

Group all of an entity's keys behind one tag value — the entity id:

```
user:{user_id}:profile
user:{user_id}:settings
user:{user_id}:notifications
user:{user_id}:sessions
```

With the keys co-located you can update several fields atomically with `MULTI`/`EXEC`, run a Lua script touching all
of them, and use `WATCH` for optimistic locking across them.

## Atomic Multi-Key Operations

A shared slot is what makes each of these legal across the entity's keys.

**Transaction across related keys.**

```
MULTI
HSET user:{123}:profile name "Alice" updated_at "1706648400"
HSET user:{123}:settings theme "dark"
INCR user:{123}:stats:updates
EXEC
```

Every command runs atomically because the keys share a slot.

**Lua script across keys.**

```
local profile  = redis.call('HGETALL', KEYS[1])
local settings = redis.call('HGETALL', KEYS[2])
redis.call('SET', KEYS[3], cjson.encode({profile, settings}))
return 'OK'
```

Called with three co-located keys: `EVAL <script> 3 user:{123}:profile user:{123}:settings user:{123}:cache`.

**Optimistic locking with WATCH.**

```
WATCH user:{123}:balance user:{123}:pending
balance = GET user:{123}:balance
pending = GET user:{123}:pending
MULTI
SET user:{123}:balance  new_balance
SET user:{123}:pending  new_pending
EXEC
```

If either watched key changes before `EXEC`, the transaction aborts.

## Real Co-location Patterns

The same move recurs across entity kinds — one tag value per entity, atomic operations across its keys.

**Order with line items.**

```
order:{order_id}:header   → order metadata
order:{order_id}:items    → list of line items
order:{order_id}:totals   → computed totals
order:{order_id}:status   → current status
```

An atomic status transition writes the header and the history in one `MULTI`/`EXEC`.

**Distributed counter with inventory.**

```
product:{sku}:stock     → available quantity
product:{sku}:reserved  → reserved for carts
product:{sku}:sold      → sold count
```

A Lua reserve reads stock, and if enough, `DECRBY`s stock and `INCRBY`s reserved in one atomic script — possible
only because all three keys share the `{sku}` slot.

**Session with related state.**

```
session:{session_id}:data     → session payload
session:{session_id}:user     → user reference
session:{session_id}:cart     → shopping cart
session:{session_id}:expires  → expiration tracking
```

Session operations stay atomic and race-free because the keys share the `{session_id}` slot.

## Hash Tag Placement Rules

Where you put the braces decides what is hashed. Three rules:

**The first `{...}` wins.** The first balanced tag in the key determines the slot:

```
{user:123}:profile    → hashes "user:123"
user:{123}:profile    → hashes "123"
user:123:{profile}    → hashes "profile" (probably wrong — won't colocate)
```

Be consistent. The convention is to put the entity id in the tag.

**An empty tag `{}` hashes the whole key.** No co-location:

```
key:{}:suffix         → hashes the whole key
```

Avoid an empty tag unless that is intended.

**Only the first tag is used.** A second `{...}` is ignored:

```
{a}:{b}:key           → hashes "a", ignores "b"
```

## Hot Slot Problem

Co-location concentrates load. If one entity is extremely hot — a celebrity user, a viral product — its slot
becomes a bottleneck. Three mitigations:

**Shard within the entity.** Spread the hot collection across tagged sub-keys (`user:{123}:followers:0`,
`user:{123}:followers:1`, …) so the load splits while staying co-located.

**Separate the hot data.** Keep the co-located core (`user:{123}:profile`) and move a high-volume read-only
collection to its own untagged key (`user_followers:123`) on a different slot.

**Accept eventual consistency for read-heavy data.** Keep writes co-located behind the tag
(`user:{123}:profile`) and replicate to a non-tagged read replica (`user:123:profile:cache`) on a different slot.

## Limitations

**Cross-entity operations still need cross-shard patterns.** A tag co-locates one entity's keys; an operation
spanning two entities does not co-locate:

```
user:{alice}:balance  → slot A
user:{bob}:balance    → slot B   (cannot be one atomic step)
```

A transfer between two users reaches for the cross-shard detection patterns of R2.04 instead.

**Some cluster commands ignore slots.** `KEYS` and `SCAN` are cluster-wide, not slot-aware; `FLUSHDB` affects a
whole node; some pub/sub operations cross slots. A hash tag does not change those.

**Resharding can move a slot.** During cluster resharding, slots migrate between nodes; an operation on a moving
slot may fail temporarily, so clients retry.

## Design Guidelines

1. **Plan key structure early** — changing a hash-tag pattern requires data migration.
2. **One entity per tag value** — `{user:123}` groups user 123's data.
3. **Don't over-co-locate** — only group keys that need atomic operations together.
4. **Monitor slot distribution** — make sure no slot is much hotter than the rest.
5. **Document the convention** — the team should use one consistent pattern.

## Commands That Benefit

| Command | Benefit |
|---------|---------|
| `MULTI`/`EXEC` | Atomic transactions |
| `WATCH` | Optimistic locking |
| `EVAL`/`EVALSHA` | Lua scripts |
| `MGET`/`MSET` | Multi-key read/write |
| `RENAME` | Atomic key swap |
| `COPY` | Key duplication |

Each requires every key on one slot; the tag is what arranges that.

## Example: Complete User Module

```
user:{id}:profile       # Hash: name, email, avatar
user:{id}:settings      # Hash: preferences
user:{id}:sessions      # Set: active session IDs
user:{id}:notifications # List: recent notifications
user:{id}:stats         # Hash: counters

# Atomic profile update with audit
MULTI
HSET  user:{123}:profile name "New Name" updated_at "1706648400"
RPUSH user:{123}:audit "profile_updated:1706648400"
EXEC
```

Both writes hit one slot, so the update and its audit land together or not at all.

## The pattern, applied — `emq:{q}:` and the client-side slot

EchoMQ's queue keys are co-located by exactly this rule, and the grammar makes it a law rather than a convention.
`EchoMQ.Keyspace.queue_key/2` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) returns `"emq:{" <> q <> "}:" <> type` —
so every per-queue key wraps the queue name in braces. The hashtag IS the queue name. The pending set, the active
set, the schedule, the dead set, and a job's own row all carry the same `{q}` tag, so they answer one slot by
construction:

```
emq:{orders}:pending              → hashes "orders"
emq:{orders}:active               → hashes "orders"
emq:{orders}:job:ORD0NgWEfAEJfs   → hashes "orders"
```

The committed manuscript record froze the consequence: *"pending, active, meta, and the job row of `{orders}` all
answer slot 105; `{fills}` answers 4165."* (`docs/echo/bcs/content/bcs3.1.md`). The reserve base `{emq}:` carries
the cross-queue facts — `{emq}:version` and `{emq}:locks` — under its own tag.

The slot is computed **client-side**. `EchoMQ.Keyspace.slot/1` is `rem(crc16(hashtag(key), 0), 16384)` —
CRC16-XMODEM (polynomial `0x1021`) over the brace substring, the cluster specification's algorithm, with the known
vector asserted: `slot("123456789") == 12739` (CRC16 `0x31C3`). Because the slot is pure arithmetic over the key
bytes, the connector can route and partition without a server round trip. Today the topology is single-instance, so
the slot function is committed and parked; on the clustered day it becomes routing, and the co-location law means
every per-queue Lua transition written between now and then survives the move with no edit.

So the bridge is direct: hash tags force related keys onto one slot so a multi-key `MULTI`/`EXEC` or Lua script
stays legal; in EchoMQ the braced `emq:{q}:` keyspace makes that automatic, and `slot/1` computes the slot
client-side so routing needs no round trip.

The closed `emq:{q}:<type>` grammar, the `{emq}:` reserve, and the version fence are the subject of the dedicated
**[EchoMQ course](/echomq)** and the [BCS keyspace chapter](/bcs/bus/the-keyspace) — the companion
courses that teach the keyspace in full. Return to the [Coordination chapter](/redis-patterns/coordination) to
continue toward the chapter's closing workshop.

## The three dives

- **R2.05.1 · The tag mechanic** — how Valkey cluster hashes only the `{tag}` substring: the first-brace rule,
  empty tags, multiple tags, and the real `slot/1`/`hashtag/1` over CRC16-XMODEM % 16384.
- **R2.05.2 · CROSSSLOT prevention** — why a multi-key `MULTI`/`EXEC` or Lua script raises `CROSSSLOT` across slots,
  and how the `{q}` tag keeps a queue's multi-key `@claim` script on one slot.
- **R2.05.3 · Cluster auto-detect** — `slot/1` computed client-side (CRC16 % 16384) so the connector can route and
  partition without a server round trip — the "auto-detect" is the client-side slot computation.

## References

### Sources
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — hash tags, the 16384 slots, and the
  `{…}` rule: the first non-empty brace span, else the whole key.
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — the
  CRC16 slot model and `CROSSSLOT` for multi-key commands across slots.
- [Valkey — CLUSTER KEYSLOT](https://valkey.io/commands/cluster-keyslot/) — the command that returns a key's slot,
  the server-side equivalent of the client-side `slot/1`.
- [Redis — MULTI](https://redis.io/commands/multi/) — the transaction block whose keys must share one slot in
  cluster mode.

### Related in this course
- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter this module belongs to.
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — detection, the fallback
  this prevention substitutes for.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-slot atomic move that
  co-location keeps legal.
- [EchoMQ — the protocol](/echomq/protocol) — the `emq:{q}:` keyspace and the version fence in depth.
- [BCS — the keyspace](/bcs/bus/the-keyspace) — the committed slot-locality record.
