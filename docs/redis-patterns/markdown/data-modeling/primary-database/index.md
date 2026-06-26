# Redis as a primary database

> Route: `/redis-patterns/data-modeling/primary-database` · R7.1 module hub · source-of-record for the served HTML.

**Use Redis as the authoritative data store for applications requiring sub-millisecond latency and high write
throughput, treating disk as a recovery mechanism rather than the primary storage layer.**

A cache holds a copy: lose it and the truth is still in the database behind it. A primary store holds the truth:
there is no second home to fall back on, so the posture has to change — eviction must be off, durability must be
configured, and every relationship the database used to enforce has to be modelled by hand. This module presents
that posture from the source, then grounds it in EchoMQ's real applied choice: the job HASH at
`emq:{q}:job:<JOB>` is the job's only canonical state, written by one atomic script, kept by `noeviction`, made
durable by AOF `everysec`.

> The pattern is taught as the general shape; EchoMQ's real config is named where it diverges. EchoMQ runs
> **AOF-only** (`save ""`, no RDB snapshots) and keeps one machine always running — it does **not** run RDB
> snapshots or Redis Sentinel.

## When Redis works as primary

Redis is a fit as a primary store for state that is hot, operational, and tolerant of roughly a second of loss on
a crash:

- **Real-time application state** — leaderboards, session stores, live dashboards.
- **High-velocity data** — activity streams, gaming state, sensor feeds.
- **Precomputed views** — timeline fan-out, materialized aggregations read far more often than written.
- **Microservices coordination** — distributed locks, rate limiting, feature flags.

It is the wrong choice when the dataset exceeds RAM, when complex multi-key ACID transactions are required, when
ad-hoc queries with joins are common, or when a regulator mandates disk-first storage. The decision is **per
datum**, not global: codemojex keeps the round leaderboard and the in-flight guesses in Valkey, and keeps player
balances in Postgres — money wants the one-transaction coupling Redis gives up.

### The grounding move

| The pattern | Its EchoMQ application |
|---|---|
| Redis as the authoritative data store: there is no truth elsewhere, so the row is the record. | The `emq:{q}:job:<JOB>` HASH is the job's only canonical state — `state` / `attempts` / `payload`, written by the `@enqueue` script in one atomic step, kept by `noeviction`, made durable by AOF `everysec`. There is no shadow copy in Postgres. |

`EchoMQ.Jobs` states it directly: *"Jobs are entities. A job's identity is a branded id under the `JOB`
namespace; its row is a hash at the job key; the pending set is a same-score sorted set whose members are the ids
themselves… Enqueue is one idempotent script: kind policy, duplicate refusal, row write, and pending insertion
happen on the server in one atomic step."* The script is the whole write:

```lua
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

The HASH carries three fields — `state` (pending / active / scheduled / dead), `attempts` (the integer fence),
`payload` (the body). `claim`, `complete`, and `retry` mutate that same row. There is no second canonical copy.

> A primary-database datum is one whose **truth has no second home**. That is a judgment made per datum, not a
> global switch — codemojex keeps the job in Valkey and the wallet in Postgres.

## Persistence configuration

If disk is recovery and not the source of truth, the persistence policy sets how much recent work a crash can
take. The source enables both mechanisms for a general primary store:

```
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000
```

### RDB — snapshotting

Point-in-time snapshots via `fork()`: compact files and a fast restart, but everything since the last snapshot is
lost on a crash. Useful for disaster-recovery backups and bootstrapping a fresh instance.

### AOF — the append-only log

A write log of every operation. The `appendfsync` policy sets the loss bound:

| Policy | Durability | Latency | Use |
|---|---|---|---|
| `always` | maximum | high | financial transactions |
| `everysec` | ~1 second loss | low | most production workloads |
| `no` | OS-dependent | minimal | caching layer |

For a primary store, `everysec` is the standard choice — about a second of worst-case loss for a far better
write path.

### Hybrid (RDB preamble)

`aof-use-rdb-preamble yes` starts the AOF with a compact RDB snapshot followed by incremental commands —
combining a fast restart with the AOF's durability.

EchoMQ's **real applied choice** diverges from the source's "enable both": it runs **AOF-only** with `save ""`,
so RDB snapshotting never competes for a second fork, and keeps `aof-use-rdb-preamble yes` so the rewrite still
uses the compact RDB format. The committed `valkey.conf` comment is exact: *"AOF is the single source of
durability. One fork source. AOF everysec bounds worst-case loss to about one second… RDB snapshotting is
disabled so it does not compete for a second fork; the AOF still uses an RDB preamble for fast rewrite."* The
result is a ~1s loss bound EchoMQ's checkpoints are designed against. The **persistence** dive carves this slice,
and doors onward to `/echo-persistence` — the ~1s AOF bound is one rung of a durability dial whose next rungs
replicate the record off-box.

## Data modeling without SQL

A primary store gives up the relational engine: there are no joins, no foreign keys, no query planner.
Denormalization and explicit indexing become the application's job.

- **Primary keys** — store an entity in a Hash under a namespaced key: `HSET user:1001 username "alice" karma 42`.
- **Secondary indexes** — build them by hand with Sets or Sorted Sets: `SET user:email:alice@example.com 1001`
  for a lookup; `ZADD users:by:age 25 1001` for a range.
- **One-to-many** — a Set holds the relationship: `SADD user:1001:followers 1002 1003`.
- **Referential integrity** — Redis enforces no foreign keys, so a delete that must stay consistent is a Lua
  script that walks the relationships and removes both ends atomically.

EchoMQ models exactly this way: the job is a Hash keyed by a branded id, and the pending set is a same-score
Sorted Set whose members are the ids themselves — byte order is mint order, so the queue carries no second index.
The key is built by hand and the branded id is gated before it is used:

```elixir
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

def job_key(queue, branded) when is_binary(branded) do
  if EchoData.BrandedId.valid?(branded) do
    queue_key(queue, "job:") <> branded
  else
    raise ArgumentError, "job_key requires a valid branded id"
  end
end
```

The key is `emq:{q}:job:<JOB-branded-id>`. The brace is not decoration — it is the cluster hash tag, so every key
of one queue lands on one slot (the referential-integrity script stays a single-slot, multi-key transaction).

## Case study: LamerNews

LamerNews — a Hacker News clone by antirez — runs a complete web application on Redis alone, and is the canonical
demonstration of the modeling discipline above.

- **User storage** — `user:1001` is a Hash of `{username, password_hash, karma, created_at}`, with
  `username.to.id:alice` and `auth:sha1token` as String indexes. Session validation is O(1) — no database
  round-trip on the common path.
- **News ranking** — `news.top` is a Sorted Set scored by `VOTES / (AGE_HOURS ^ GRAVITY)`. A vote recomputes the
  rank and re-`ZADD`s it; the homepage is one command, `ZREVRANGE news.top 0 29`.
- **Comment threading** — all comments for an item live in one Hash; the application reads them with `HGETALL`,
  builds the parent-child tree in memory, and renders recursively. Relational logic moves to the application
  layer.

The shape is EchoMQ's shape: an entity as a Hash, a Sorted Set as the ordered index, and the application holding
the logic the relational engine used to hold.

## Production patterns from scale

Three patterns recur where Redis is the primary store at scale:

- **Pinterest — virtual sharding.** Billions of follower relationships are spread across 8192 logical shards
  mapped onto physical instances, giving predictable distribution and easier rebalancing across many
  single-threaded processes. EchoMQ's `{q}` hash tag is the same idea at queue granularity — every key of one
  queue lands on one of 16384 cluster slots.
- **Twitter — timeline precomputation.** The home timeline is a capped List per user (~800 entries); a tweet
  fans out to followers' timeline Lists, and a read is `LRANGE timeline:user_id 0 199` — O(1), not a join. Write
  amplification is traded for read simplicity.
- **DoorDash — listpack-Hash memory.** Switching a feature store from flat `SET feature:1001:age 25` pairs to one
  `HSET feature:1001 age 25 city "NYC"` Hash cut memory ~40%: a small Hash uses Redis's compact listpack
  encoding. The job HASH benefits from the same encoding — three short fields under one key.

## Operational requirements

Running a primary store has obligations a cache does not.

- **High availability.** The source uses Redis Sentinel for automatic failover and `min-replicas-to-write` to
  prevent split-brain. EchoMQ's real posture is different — "auto-stop off, one machine always running" (it does
  **not** run Sentinel) — and the *operating-at-scale* depth (Sentinel, pooling, failover) is the subject of
  **R8.02 · Persistence, pooling & failover**, not this module.
- **Avoid blocking O(N) commands.** In a single-threaded server, an O(N) command blocks everything: never `KEYS *`
  (use `SCAN`), avoid `HGETALL` on a Hash of millions of fields, prefer `UNLINK` to `DEL` for a large key.
- **Watch for hot keys and big keys.** A single hot key saturates a CPU core; a big key spikes latency during
  operations. `redis-cli --hotkeys` and `--bigkeys` surface them.

EchoMQ pairs `noeviction` with `propagation-error-behavior panic` and a `maxmemory` set as a loud guardrail far
above the working set, not a working ceiling — the **noeviction** dive carves this slice. The bcs.8 manuscript
puts the posture plainly: *"Eviction is the wrong posture for a job store: a queue that silently drops keys is a
queue that silently loses work, so memory pressure must surface as write errors and alerts."*

> The Oban comparison: Oban keeps jobs in the same Postgres as the data, so a job and a business row commit in one
> transaction. EchoMQ puts the job's truth in Valkey for the in-memory hot path and the durability dial, and gives
> up that one-transaction coupling. The trade is stated beside the win — EchoMQ does not have Oban's coupling.

## The three dives

- **R7.1.1 · System of record** — the row is the record: the `@enqueue` `HSET` writes it and
  `claim`/`complete`/`retry` mutate that same row, while codemojex splits per datum (the board and guess locks in
  Valkey, the wallet and ledger in Postgres). Closes with the Oban contrast.
- **R7.1.2 · noeviction** — `maxmemory-policy` is a menu; the cache policies delete keys under pressure to keep
  serving, `noeviction` refuses the write instead. A system of record runs `noeviction` so memory pressure is a
  loud error to alert on, not a vanished job.
- **R7.1.3 · Persistence (RDB / AOF)** — two durability mechanisms and the loss bound each sets; EchoMQ's AOF-only,
  `everysec`, RDB-preamble choice; and the durability frontier that doors to `/echo-persistence`.

## References

### Sources

- [Valkey — Persistence](https://valkey.io/topics/persistence/) — RDB snapshots, the AOF, and the `appendfsync`
  loss bound that makes Redis a durable primary store.
- [Valkey — Eviction (LRU cache)](https://valkey.io/topics/lru-cache/) — the `maxmemory-policy` menu; why a
  system of record runs `noeviction`.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a queue's
  keys onto one of 16384 slots, keeping a multi-key Lua script legal.
- [Valkey — HSET](https://valkey.io/commands/hset/) — set fields on a Hash; the row write at the heart of the
  primary-store model.
- [antirez — LamerNews](https://github.com/antirez/lamernews) — a complete web application on Redis alone; the
  canonical modeling-without-SQL case study.

### Related in this course

- R7.1.1 · System of record — the row is the record; the per-datum decision; the Oban contrast.
- R7.1.2 · noeviction — the policy menu; refuse the write rather than drop the record.
- R7.1.3 · Persistence — RDB vs AOF, the loss bound, and the durability frontier.
- R7 · Data Modeling & Memory — the chapter landing.
- /bcs/fly — Valkey on a Fly machine: the production posture of this exact config.
- /bcs/store — EchoStore, the near-cache: a *cache* tier, the contrast to a system of record.
