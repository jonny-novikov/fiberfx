# Torn writes — the problem and the base detector

> Route: `/redis-patterns/coordination/cross-shard-consistency/torn-writes` · Dive R2.04.1 · Source:
> `content/coordination/cross-shard-consistency.md.txt` (slice: *The Problem: Torn Writes* + *Pattern 1: Transaction
> Stamp (Shared Token)*, incl. the client-side-sharding example).
> · Grounding: EchoMQ's real answer to a torn write is **prevention by colocation** — `EchoMQ.Keyspace.queue_key/2`
> (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex:13`) always braces the queue name, so a queue's keys share one slot,
> and `EchoMQ.Jobs.claim/3` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:283`) runs the whole multi-key move as one Lua
> `EVALSHA` over those co-located keys (`EchoMQ.Connector.eval/5`,
> `echo/apps/echo_wire/lib/echo_mq/connector.ex:63`). The shared-token detector here is the fallback for keys that
> genuinely cannot share a slot.

A multi-key write that is not on one slot can tear: write A lands, write B fails, and the pair is left inconsistent
with no transaction to roll back. Pattern 1 is the cheapest detection — stamp every related value with one shared
token, then on read parse both tokens and compare. Equal means both values came from the same logical write; unequal
means torn. Detection only, not prevention: pair it with a recovery policy. It works across anything — cluster shards,
client-side sharding, separate systems — because no coordination between instances is required.

## The problem: torn writes

When two related keys A and B live on different shards, the pair of writes is not one atomic step. The sequence that
tears:

1. The client writes A to shard 1 → success.
2. The client writes B to shard 2 → fails (network error, timeout).

A now holds new data, B holds old data, and there is no transaction to roll back. A read that fetches both returns
inconsistent state. On a single primary a `MULTI`/`EXEC` block or a Lua script would make the pair atomic; across
shards that guarantee is gone, so the application has to detect the tear after the fact.

The reason is structural, not a bug to be fixed in the write path. Two keys on two shards are two independent commands
sent to two independent servers; a network error on the second leaves the first already committed. Nothing links the
two writes, so nothing can undo the first when the second fails. The damage is bounded only by detection: catch the
mismatch on the next read, then repair.

## Pattern 1: transaction stamp (shared token)

Generate one unique token per logical transaction and include it in every related write. A token is a UUID, a ULID,
or random bytes — any value unique to this one logical update. Prefix each value with it:

```
token = generate_random_token()            # UUID, ULID, or random bytes
SET user:123:profile  "{token}:{profile_json}"
SET user:123:settings "{token}:{settings_json}"
```

On read, fetch both values, parse their tokens, and compare:

```
profile  = GET user:123:profile
settings = GET user:123:settings
profile_token  = parse_token(profile)
settings_token = parse_token(settings)
if profile_token == settings_token:
    return parse_payload(profile), parse_payload(settings)   # consistent: same logical write
else:
    trigger_repair()                                          # torn write detected
```

Equal tokens prove both values came from the same logical write. A tear breaks that equality: if the second `SET`
failed, `user:123:settings` still carries the *previous* transaction's token, so the two tokens disagree and the
comparison flags the tear. The check is cheap read-time proof — one string compare — that needs no distributed
transaction and no cluster feature.

### What this buys you

- **Detects inconsistency** without distributed transactions or cluster features — a plain string compare on read.
- **Cheap read-time proof** that both values belong to the same logical write.
- **Works across anything**: cluster shards, separate primaries under client-side sharding, different data centres, or
  even different storage systems entirely.
- **No coordination required**: each `SET` is independent; consistency is validated by the client that reads both
  values.
- **Enables idempotency**: the token doubles as the operation ID, so a retried write is recognisable.

### Limitations

- Detection only, not prevention — a recovery policy still has to follow.
- A bare token does not name which side is newer (the next dive adds a version for that).

### Client-side sharding

The detector earns its place where there is no cluster to coordinate the keys at all. Two independent primaries —
`host1:6379` and `host2:6379` — with one client connected to both. The client mints a token, writes
`SET user:profile "{token}:{data}"` to instance A and `SET user:settings "{token}:{data}"` to instance B, and on read
fetches both and compares the tokens. No clustering, no replication between the instances: consistency is enforced
entirely by the application through token validation. The same comparison works whether the two keys are on two
cluster slots, two standalone primaries, or two different systems — the token travels in the value, not in any engine
feature.

## The pattern, applied — why EchoMQ cannot tear

EchoMQ does not run this detector on its own queue keys, because it removes the tear before it can happen. Every
per-queue key is built by `EchoMQ.Keyspace.queue_key(q, type)`, which is `"emq:{" <> q <> "}:" <> type` — the queue
name always lands inside the braces. Valkey Cluster hashes only the substring inside the first non-empty `{...}`, so
`emq:{orders}:pending` and `emq:{orders}:active` (and the row key `emq:{orders}:job:<id>`) all hash to the same slot.

That colocation lets the whole transition be one inline Lua script. `EchoMQ.Jobs.claim/3` (jobs.ex:283) hands
`Connector.eval/5` two declared keys — `KEYS[1] = emq:{q}:pending`, `KEYS[2] = emq:{q}:active` — and the `@claim`
script (jobs.ex:126) touches the row key `emq:{q}:job:<id>` built from `ARGV[1]`:

```lua
local popped = redis.call('ZPOPMIN', KEYS[1])
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
return {id, redis.call('HGET', jk, 'payload'), att}
```

All three keys share the `{q}` hashtag, so all land on one slot, and the move applies in full or not at all. The v2
law that makes this safe is in `Connector.eval/5` (`connector.ex:63`):
`parts = ["EVALSHA", s.sha, Integer.to_string(length(keys))] ++ keys ++ argv` — **every key a script touches is
declared in `KEYS`; `ARGV` carries values only**. Hand that script a key on a different slot and the engine raises
`CROSSSLOT`. There is no partial write to detect, because the script is the serialization point.

So the token detector is the fallback for the case EchoMQ engineers away: keys that genuinely cannot share a slot —
keys on different shards, or a Valkey read-model paired with codemojex's database of record.

The colocation mechanic itself — the `{tag}` hash, CRC16 mod 16384, `CROSSSLOT` prevention — is the chapter's next
module, **R2.05 hash-tag colocation** (return to the [Coordination chapter](/redis-patterns/coordination) to reach
it). The full v2 script bundle and the EVALSHA/NOSCRIPT dispatch belong to the dedicated EchoMQ course.

## References

### Sources
- [Redis — Cluster specification](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/) — hash
  tags, the 16384 slots, and `CROSSSLOT` for multi-key commands that span slots.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the engine's own slot model: hash only
  the substring inside `{...}`, CRC16 mod 16384, so co-located keys share a slot.
- [Redis — SET](https://redis.io/commands/set/) — the per-value stamped write `SET key "{token}:{data}"`.
- [Redis — EXISTS](https://redis.io/commands/exists/) — the presence check a recovery policy uses to find which side
  is missing.
- [Redis — Transactions](https://redis.io/docs/latest/develop/interact/transactions/) — the single-instance
  atomicity the shared token substitutes for when keys span shards.

### Related in this course
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — the module hub: all four
  detection patterns and the prevention comparison.
- [R2.04.2 · Version tokens](/redis-patterns/coordination/cross-shard-consistency/version-tokens) — the next dive:
  the version that orders the tear the bare token only flags.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-slot atomic move colocation
  keeps legal, and what a tear loses.
- [/echomq/protocol](/echomq/protocol) — the dedicated EchoMQ course: the full v2 script bundle in depth.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the single-writer engine that serializes cross-system state.
