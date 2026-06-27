# Cross-shard consistency

> Route: `/redis-patterns/coordination/cross-shard-consistency` · Module R2.04 · Source:
> `content/coordination/cross-shard-consistency.md.txt`
> · Grounding: EchoMQ's real answer is **prevention by colocation** — `EchoMQ.Keyspace.queue_key/2`
> (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex:13`) always braces the queue name, so a queue's keys share one slot,
> and `EchoMQ.Connector.eval/5` (`echo/apps/echo_wire/lib/echo_mq/connector.ex:63`) runs the whole multi-key
> transition as one Lua `EVALSHA` over those co-located keys. The detection patterns on this page are the fallback
> for keys that genuinely cannot share a slot.

Detect and handle torn writes across multiple Redis instances using transaction stamps, version tokens, and commit
markers when atomic multi-key operations aren't possible.

These patterns work with any multi-primary Valkey setup: cluster shards, client-side sharding across independent
primaries, or even separate deployments. The central idea is that consistency detection runs at the application layer
through shared tokens embedded in the values themselves — no coordination between instances is required. When the
keys can share a slot, prevention is the better answer (the chapter's next module); these patterns are what you reach
for when they cannot.

## The Problem: Torn Writes

When two related keys A and B live on different shards, the pair of writes is not one atomic step:

1. The client writes A to shard 1 → success.
2. The client writes B to shard 2 → fails (network error, timeout).

A now holds new data, B holds old data, and there is no transaction to roll back. A read that fetches both returns
inconsistent state. With a single primary a multi-key transaction or a Lua script would make the pair atomic; across
shards that guarantee is gone, so the application has to detect the tear after the fact.

## Pattern 1: Transaction Stamp (Shared Token)

Generate one unique token per logical transaction and include it in every related write.

```
token = generate_random_token()            # UUID, ULID, or random bytes
SET user:123:profile  "{token}:{profile_json}"
SET user:123:settings "{token}:{settings_json}"
```

On read, fetch both values, parse their tokens, and compare:

```
profile  = GET user:123:profile
settings = GET user:123:settings
if parse_token(profile) == parse_token(settings):
    return parse_payload(profile), parse_payload(settings)   # same logical write
else:
    trigger_repair()                                          # torn write detected
```

Equal tokens prove both values came from the same logical write; unequal tokens flag a tear. The check is cheap
read-time proof that needs no distributed transaction and no cluster feature, and the token doubles as the operation
ID for idempotency. The cost: this is detection only, not prevention — you still need a recovery policy — and a bare
token does not tell you which side is newer. Because each `SET` is independent and no coordination is required, the
same check works across cluster shards, client-side-sharded primaries, separate data centres, or even different
storage systems.

## Pattern 2: Version-Stamped Values

A bare token catches a tear but cannot order the two sides. Adding a version both detects the tear and identifies
which write to keep:

```
SET user:123:profile  "{timestamp}:{token}:{payload}"
SET user:123:settings "{timestamp}:{token}:{payload}"
```

On mismatch, accept the value with the higher timestamp or trigger a full refresh. Wall-clock timestamps order by the
clock, which is vulnerable to skew between hosts. For ordering that does not depend on clocks, use a monotonic
counter:

```
version = INCR user:123:version
SET user:123:profile  "{version}:{payload}"
SET user:123:settings "{version}:{payload}"
```

`INCR` advances a single monotonic source, so the higher version is always the newer write — last-write-wins becomes
a correct decision rather than a clock-dependent guess.

## Pattern 3: Commit Marker

Write all data first, then write a commit marker as the final step:

```
# Phase 1: write data (may partially fail)
SET txn:abc:A "{payload_A}"
SET txn:abc:B "{payload_B}"
# Phase 2: mark committed
SET txn:abc:committed "1" EX 3600
```

A reader accepts the data only if the marker exists:

```
if EXISTS txn:abc:committed:
    a = GET txn:abc:A
    b = GET txn:abc:B          # safe to use
else:
    # transaction incomplete — ignore or wait
```

A crash before the marker leaves the data present but invisible, so a torn state is never read. This resembles
two-phase commit, with the marker acting as the decision record. Where Pattern 1 detects a tear *after* reading both
values, a commit marker prevents the torn read in the first place — at the cost of one extra key and a second round
trip.

## Pattern 4: Append-Only Logs with Shared Tokens

For event-sourced systems, append to per-key logs with shared tokens:

```
RPUSH user:123:profile:log  "{token}:{profile_change}"
RPUSH user:123:settings:log "{token}:{settings_change}"
```

To find the latest consistent state: read recent entries from both logs (`LRANGE ... -N -1`), then find the newest
token that appears in **both** logs — that token identifies the latest complete transaction. A sorted-set variant
scores entries by timestamp:

```
ZADD user:123:events {timestamp} "{token}:profile:{payload}"
ZADD user:123:events {timestamp} "{token}:settings:{payload}"
```

Query from newest, grouping by token until one token has all expected parts.

## Recovery Strategies

When a tear is detected, the response depends on what guarantees the values carry:

- **Re-read with backoff** — the write may still be in progress; retry a few times with increasing delays before
  declaring a tear.
- **Accept newest** — if values carry timestamps or versions, regenerate the older side from the newer
  (`if profile_version > settings_version: regenerate_settings_from_profile()`).
- **Consult the source of truth** — re-fetch from the authoritative database, mint a fresh token, and rewrite both
  values together.
- **Serve stale with background repair** — return the most recent data immediately and queue an async repair job.

## When to Use These Patterns

**Use transaction stamps when** keys must live on different shards (no hash-tag option), detection plus repair is an
acceptable substitute for prevention, or cross-system consistency is needed (Valkey plus a database plus a cache).

**Use commit markers when** you need clear transaction boundaries, incomplete transactions should be invisible to
readers, and the overhead of one extra key per transaction is acceptable.

**Use version stamps when** you need to determine which write is newest, last-write-wins semantics are acceptable, and
you want automatic conflict resolution.

## Comparison with Prevention Strategies

| Approach | Guarantees | Overhead | Complexity |
|----------|------------|----------|------------|
| Hash tags (same slot) | Atomic | None | Low |
| Transaction stamps | Detect only | Per-value token | Medium |
| Commit markers | Detect + visibility | Extra key | Medium |
| Version stamps | Detect + ordering | Per-value version | Medium |
| External coordinator | Atomic | Network + latency | High |

When the keys can share a slot, prevention wins on every column: a hash tag co-locates them and a multi-key Lua
script stays atomic, so there is no tear to detect. These detection patterns are the fallback for the keys that
genuinely cannot.

## The pattern, applied — one slot, one EVAL, no tear

EchoMQ does not run any of these detectors on its own queue keys, because it removes the tear before it can happen.
Every per-queue key is built by `EchoMQ.Keyspace.queue_key(q, type)`, which is literally
`"emq:{" <> q <> "}:" <> type` — the queue name is always inside the braces. Valkey Cluster hashes only the substring
in the first non-empty `{...}`, so `emq:{orders}:pending` and `emq:{orders}:active` (and the row key
`emq:{orders}:job:<id>`) all hash to the same slot. The client computes the slot itself: `Keyspace.slot/1` runs
CRC16-XMODEM over `Keyspace.hashtag/1` modulo 16384, the cluster specification's own algorithm, so the connector can
route without a server round trip (known vector: `slot("123456789") == 12739`).

Because the keys co-locate, the whole transition is one inline Lua script. `EchoMQ.Jobs.claim/3`
(`echo/apps/echo_mq/lib/echo_mq/jobs.ex:283`) calls `Connector.eval(conn, @claim, keys, argv)` with two declared
keys — `KEYS[1] = emq:{q}:pending`, `KEYS[2] = emq:{q}:active` — and the script touches the row key
`emq:{q}:job:<id>` built from `ARGV[1]`. All three share the `{q}` hashtag, so all land on one slot, and `@claim`
(`ZPOPMIN pending` → `HINCRBY <jobkey> attempts 1` → `HSET state active` → `ZADD active …`) applies in full or not at
all. The v2 law that makes this safe is in `Connector.eval/5`
(`echo/apps/echo_wire/lib/echo_mq/connector.ex:63`): `parts = ["EVALSHA", s.sha, Integer.to_string(length(keys))] ++
keys ++ argv` — **every key a script touches is declared in `KEYS`; `ARGV` carries values only**. Hand that script a
key on a different slot and the engine raises `CROSSSLOT`; the braced keyspace is precisely what keeps it from
happening.

So the bridge is: a cross-shard detection pattern (shared token, version stamp, commit marker) is what an application
reaches for when prevention is unavailable; EchoMQ's answer is prevention by colocation — one slot, one Lua `EVAL`
over co-located keys, the script as the serialization point. Detection is the fallback only when the keys genuinely
cannot share a slot — keys on different shards, or a Valkey read-model paired with codemojex's database
of record.

The colocation mechanic itself — the `{tag}` hash, CRC16 mod 16384, `CROSSSLOT` prevention — is the next module,
**R2.05 hash-tag colocation** (return to the [Coordination chapter](/redis-patterns/coordination) to continue). The
full v2 script bundle, the EVALSHA/NOSCRIPT dispatch, and the version fence (`{emq}:version` → `echomq:3.0.0`) are
taught in depth in the dedicated EchoMQ course.

## The three dives

- **R2.04.1 · Torn writes** — the problem and the base detector: a multi-key write off one slot can tear; Pattern 1
  stamps both values with one shared token and compares them on read. Why EchoMQ cannot tear: one slot + one Lua
  `EVAL`.
- **R2.04.2 · Version tokens** — detect *and* order: `{timestamp}:{token}:{payload}` orders by clock, a monotonic
  `INCR` version orders without one, so a mismatch resolves last-write-wins. EchoMQ's applied version token is
  `attempts` (monotone via `HINCRBY`); a stale writer is caught by `EMQSTALE`.
- **R2.04.3 · Commit markers** — make an incomplete transaction invisible: write data, then `SET txn:id:committed`;
  a reader accepts only when `EXISTS` returns the marker. EchoMQ needs no marker: the single Lua `EVAL` over
  co-located keys is the serialization.

## References

### Sources
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — hash
  tags, the 16384 slots, and `CROSSSLOT` for multi-key commands across slots.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the engine's own slot model: hash only
  the substring inside `{...}`, CRC16 mod 16384, so co-located keys share a slot.
- [Redis — SET](https://redis.io/commands/set/) — the stamped writes and the commit marker (`SET ... EX`).
- [Redis — INCR](https://redis.io/commands/incr/) — the monotonic version counter behind Pattern 2.
- [Redis — EXISTS](https://redis.io/commands/exists/) — the read-visibility gate behind the commit marker.
- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — the single-instance
  atomicity these patterns substitute for when keys span shards.

### Related in this course
- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter, and the home of R2.05 hash-tag
  colocation.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-slot atomic move colocation
  keeps legal.
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the claim lease on the same
  co-located keys.
- [/echomq/protocol](/echomq/protocol) — the dedicated EchoMQ course: the full v2 script bundle and the version fence in depth.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the single-writer engine that serializes cross-system state.
