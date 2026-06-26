# R8.06.1 · Cluster colocation

> Dive · `/redis-patterns/production-operations/operating-echomq/cluster-colocation`
> `EchoMQ.Keyspace.slot/1` — the `{q}` hashtag pins a queue's keys to one of 16384 cluster slots.

A single-node Valkey lets a Lua `EVAL` touch any keys at all. A Valkey Cluster does not: the keyspace is
split across 16384 hash slots, and one command may only touch keys that hash to the same slot, or the
server refuses it with `CROSSSLOT`. A job system runs multi-key scripts on every operation — claim reads
one set and writes another, complete moves a job between two keys — so on a cluster, a queue's keys must
all land on one slot. EchoMQ guarantees that by construction, and `EchoMQ.Keyspace.slot/1` is where the
guarantee is computed.

## The hashtag and the slot

Valkey Cluster gives applications one lever over placement: a **hashtag**. If a key contains a `{…}`
substring, the slot is computed from the bytes inside the braces alone, not the whole key. So
`emq:{orders}:pending` and `emq:{orders}:active` both hash on `orders` — the same slot — even though the
full keys differ. EchoMQ builds every queue key braced: the queue name is the hashtag, every key of one
queue shares it, and so every key of one queue lands on one slot.

`EchoMQ.Keyspace.slot/1` computes that slot client-side:

- `hashtag/1` returns the substring inside the first `{…}` when present and non-empty, else the whole key.
- `slot/1` is `rem(crc16(hashtag(key), 0), 16384)` — CRC16-XMODEM over the hashtag, modulo 16384, the
  cluster specification's exact algorithm.

Computing it client-side means the connector can route a key to its node, and partition by slot, without a
server round trip. The source pins one known vector: `slot("123456789") == 12739` (CRC16 `0x31C3`).

```elixir
# echo/apps/echo_mq/lib/echo_mq/keyspace.ex
@spec slot(binary()) :: 0..16383
def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)

def hashtag(key) do
  with [_, rest] <- :binary.split(key, "{"),
       [tag, _] when tag != "" <- :binary.split(rest, "}") do
    tag
  else
    _ -> key
  end
end
```

## Why the braced keyspace keeps Lua legal

The braced keyspace is not decoration — it is what keeps a queue's multi-key Lua legal at cluster scale.
Consider a claim: it reads `emq:{q}:pending`, writes `emq:{q}:active`, and touches the job HASH
`emq:{q}:job:<JOB>`. All three keys share the `{q}` hashtag, so all three hash to one slot, so the `EVAL`
touches one slot and the cluster accepts it. Drop the brace and the three keys scatter across slots; the
same `EVAL` answers `CROSSSLOT` and the operation cannot run atomically. The brace is what lets a script
stay a single atomic step on a cluster — the colocation the bus depends on.

This is the same braced key the keyspace requires for the gate: a `JOB` id is gated at the key builder,
every key is born braced, and every key a Lua script touches is declared in its `KEYS[]`. Colocation and
the gate are two readings of one rule — every key of a queue draws from one braced grammar.

## The bridge

| The pattern — colocate related keys on one cluster slot | Its EchoMQ application |
|---|---|
| A hashtag forces a key family onto one of 16384 slots, so a multi-key command stays in one slot | `EchoMQ.Keyspace.slot/1` is `rem(crc16(hashtag(key), 0), 16384)` over the `{q}` hashtag; every key of a queue shares the brace, so a queue's multi-key Lua `EVAL` is always `CROSSSLOT`-safe in cluster mode |

The take: colocation on a cluster is a placement problem, and the hashtag solves it by construction. EchoMQ
braces the queue name into every key, so a queue's keys are one slot and its scripts are one atomic step —
no `CROSSSLOT`, no manual sharding, the hashtag is the shard key.

## The production angle

Deploy the bus on a Valkey Cluster and nothing in the application changes. Each queue's keys already carry
the `{q}` hashtag, so each queue already lands on one slot; the cluster spreads queues across slots and
nodes for you, and each queue's scripts stay legal because they never leave their slot. For codemojex, the
`cm` queue's keys share the `{cm}` brace — one slot — and the bot workers draining `cm` all address that
one slot; the colocation is automatic. The deeper protocol — the full Lua inventory, the lane and lease
mechanics that run on those colocated keys — is the dedicated EchoMQ course.

## References

### Sources

- [Valkey — *Cluster specification*](https://valkey.io/topics/cluster-spec/) — the 16384 hash slots, the
  `{hashtag}` rule that forces a key family onto one slot, and the `CROSSSLOT` constraint on multi-key
  commands.
- [Valkey — *CLUSTER KEYSLOT*](https://valkey.io/commands/cluster-keyslot/) — the command that returns a
  key's slot, the server-side counterpart to `slot/1`'s client-side CRC16.
- [Redis — *Keyspace*](https://redis.io/docs/latest/develop/use/keyspace/) — key naming conventions and the
  hash-tag mechanism the braced keyspace builds on.

### Related in this course

- [R8.06 · Operating EchoMQ](/redis-patterns/production-operations/operating-echomq) — the module hub.
- [R8.06.2 · Prometheus and OpenTelemetry](/redis-patterns/production-operations/operating-echomq/prometheus-and-opentelemetry) — observing the colocated bus.
- [R8.06.3 · The polyglot fleet](/redis-patterns/production-operations/operating-echomq/the-polyglot-fleet) — scaling a fleet over the same wire.
- [/echomq · the Queue pillar](/echomq/queue) — the lanes and leases that run on the colocated keys.
- [/bcs · The bus](/bcs/bus) — the braced keyspace and the BCS law on the wire.
