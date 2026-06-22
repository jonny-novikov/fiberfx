# CROSSSLOT prevention

> Route: `/redis-patterns/coordination/hash-tag-colocation/crossslot-prevention` · Dive R2.05.2 · Source:
> `content/fundamental/hash-tag-colocation.md.txt` (slice: *Atomic multi-key operations* + *Limitations*).
> · Grounding: `EchoMQ.Jobs.claim/3` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:283`) and its `@claim` script
> (jobs.ex:126) declare `KEYS[1] = emq:{q}:pending`, `KEYS[2] = emq:{q}:active`, and touch the job row
> `emq:{q}:job:<id>` (the v2 declared-keys law) — all three share the `{q}` hashtag via
> `EchoMQ.Keyspace.queue_key/2`, so all land on one slot and the multi-key `EVALSHA` is legal. Strip the tag and
> the keys scatter; the cluster raises `CROSSSLOT`.

A multi-key command across two slots is refused. A shared tag lands the keys on one slot — and the command is legal
again.

In cluster mode a single command that touches more than one key — `MSET`, a `MULTI`/`EXEC` block, an `EVAL` Lua
script — needs every key on the same slot, or the cluster returns the literal `CROSSSLOT` error.

## The CROSSSLOT error

Valkey cluster splits the keyspace into 16384 hash slots and gives each slot to a node. A multi-key command can run
atomically on one node only, so the cluster enforces a rule before it executes: every key the command names must
hash to the same slot. When two keys in one request land on different slots they live on two different nodes, and no
single node can run the command. The cluster refuses the whole request:

```
MSET user:profile "…" user:settings "…"
(error) CROSSSLOT Keys in request don't hash to the same slot
```

The trap is that a single Valkey node does not enforce this. On one node every key is reachable, so `MSET`, a
`MULTI`/`EXEC` block, and a multi-key `EVAL` all run regardless of how the keys hash. The code passes every test on
a single node, and the first cluster deploy is where the `CROSSSLOT` surfaces — a class of failure that stays
invisible until the topology changes underneath working code.

- **hash slot** — one of 16384 partitions of the keyspace; each owned by one node. A key's slot is
  `CRC16(key) % 16384` over the part the cluster hashes.
- **same-slot rule** — every key a single multi-key command names must hash to one slot, because the command runs
  atomically on the one node that owns it.
- **CROSSSLOT** — the error the cluster returns when a multi-key request spans slots. A single Valkey node never
  raises it.

## Why colocation prevents it

A key's slot is `CRC16(key) % 16384` over the whole key — unless the key carries a hash tag, the first non-empty
`{…}` substring, in which case the cluster hashes only that substring. Two keys that share a tag therefore share a
slot, whatever else differs between them. That is the prevention: arrange the related keys behind one tag and the
multi-key command never spans a slot boundary.

```
# only the tag substring is hashed -> every {orders} key lands on one slot
slot("emq:{orders}:pending") == 105
emq:{orders}:pending   -> slot 105
emq:{orders}:active    -> slot 105
emq:{orders}:schedule  -> slot 105   one slot -> the multi-key claim stays legal
```

Drop the braces and each key hashes in full, so the keys scatter and the move raises `CROSSSLOT`. Colocation is
**prevention** — it removes the failure rather than recovering from it. That is the complement of the previous
chapter's detection pattern: detection (R2.04) is the fallback for keys that genuinely cannot share a slot, such as
a Valkey key paired with a database row; prevention is the first choice whenever the keys *can* be colocated.

## Commands that benefit from colocation

Every command below requires same-slot keys in cluster mode, and a shared tag is what keeps them legal:

| Command | Why it needs one slot |
|---------|-----------------------|
| `MULTI`/`EXEC` | a transaction runs atomically on one node; every key in the block must share a slot. |
| `WATCH` | the optimistic-lock key and the keys the transaction touches must co-locate. |
| `EVAL`/`EVALSHA` | a Lua script's multiple `KEYS` must all hash to one slot. |
| `MGET`/`MSET` | a multi-key read or write spans one node only. |
| `RENAME` | source and destination keys must share a slot. |
| `COPY` | source and destination keys must share a slot. |

## In EchoMQ — the multi-key claim

EchoMQ's `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`) is the worked case. The v2 law is that every
key a script touches is declared in `KEYS`; `claim/3` (jobs.ex:283) builds the key list and runs the script through
`EchoMQ.Connector.eval/5` (EVALSHA-first):

```elixir
# claim/3 (jobs.ex:283) — declared keys, all under the {q} hashtag
keys = [Keyspace.queue_key(queue, "pending"), Keyspace.queue_key(queue, "active")]
argv = [Keyspace.queue_key(queue, "job:"), Integer.to_string(lease_ms)]
Connector.eval(conn, @claim, keys, argv)
```

```lua
-- @claim (jobs.ex:126) — ZPOPMIN pending, HINCRBY attempts (the fencing token), ZADD active on the server clock
local popped = redis.call('ZPOPMIN', KEYS[1])    -- emq:{q}:pending
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id                          -- emq:{q}:job:<id>
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)   -- emq:{q}:active
return {id, redis.call('HGET', jk, 'payload'), att}
```

The script touches three keys: `KEYS[1]` is `emq:{q}:pending`, `KEYS[2]` is `emq:{q}:active`, and the job row
`emq:{q}:job:<id>` is composed inline from `ARGV[1]`. All three are built by `Keyspace.queue_key/2`, which always
wraps the queue name in braces, so all three hash the substring `q` and answer one slot — `slot 105` for the
`{orders}` queue. The script applies in full or not at all: a job leaves `pending` (`ZPOPMIN`), its `attempts`
fencing token is incremented (`HINCRBY`), and it enters `active` with a server-clock lease (`ZADD ... TIME`) in one
indivisible `EVALSHA`. Strip the `{q}` tag and the three keys would scatter, and the claim would raise `CROSSSLOT`.

The bridge: a multi-key command whose keys span slots raises `CROSSSLOT`; colocation via a shared `{q}` tag lands
the keys on one slot, so the command is legal again — prevention, not recovery. In EchoMQ the multi-key `@claim`
stays one atomic `EVALSHA` because `Keyspace.queue_key/2` colocates `pending`, `active`, and the job row on one slot.

Next, R2.05.3 · Cluster auto-detect shows how `slot/1` computes that slot client-side, so the connector can route
and partition without a server round trip — the same arithmetic the cluster runs, run ahead of time on the client.

## References

### Sources
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the 16384 hash slots, hash tags, and
  the `CROSSSLOT` rule for multi-key commands that span slots.
- [Redis — EVAL / scripting introduction](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/)
  — the requirement that every `KEYS` element of a Lua script hash to the same slot in cluster mode.
- [Redis — MSET](https://redis.io/commands/mset/) — a multi-key write that needs all keys on one slot; the simplest
  command a shared hash tag keeps legal.

### Related in this course
- [R2.05 · Hash-tag co-location](/redis-patterns/coordination/hash-tag-colocation) — the module hub: the tag
  mechanic, the first-brace rule, and the placement explorer.
- [R2.05.1 · The tag mechanic](/redis-patterns/coordination/hash-tag-colocation/the-tag-mechanic) — the previous
  dive: how a `{tag}` selects the substring the cluster hashes.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the single-slot atomic move that
  colocation keeps legal in cluster mode.
- [R2.04 · Cross-shard consistency](/redis-patterns/coordination/cross-shard-consistency) — detection, the fallback
  for keys that genuinely cannot share a slot.
