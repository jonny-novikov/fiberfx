# R7 · Data Modeling & Memory

> Route: `/redis-patterns/data-modeling` · Chapter landing (manifest) · BCS contract-sheet identity (redis-red).
> Grounding: EchoMQ's real job HASH under a system-of-record posture in `echo/apps/echo_mq` — the `@enqueue` script
> writes the `state`/`attempts`/`payload` row at `emq:{q}:job:<JOB>`, kept by `noeviction` and durable by AOF
> `everysec` (`infra/valkey/conf/valkey.conf`) — and the manuscript production chapter `docs/echo/bcs/bcs.8.md §B8.2`
> + the durability dial `bcs.5.md`, worked through the **codemojex** consumer (`echo/apps/codemojex` — its per-datum
> split: game state in Valkey, money in Postgres). Engine: Valkey 9. Doors: `/bcs/fly` (the production config) +
> `/bcs/persistence` + `/echo-persistence` (the durable floor) + `/bcs/store` (EchoStore — the cache tier, the
> contrast).

Redis is not only a cache. With the right persistence and eviction posture it is a system of record. This chapter
teaches how data is modeled in RAM and how memory is spent: Redis as a primary database, compact encodings,
probabilistic structures, bitmaps, vector sets, and geospatial — with EchoMQ's memory discipline as the worked case
study and codemojex's read-models as the worked consumer.

## Overview

Every chapter before this one used Redis structures as machinery: a sorted set held the schedule, a list held the
work, a stream held the log. This chapter asks a different question — not what structure to reach for, but how the
data lives in RAM and whose truth it is. Two threads run through it. The first is **the store as a system of
record**: with `noeviction` and an append-only log, the row in Valkey is not a copy of something durable elsewhere —
it is the record, and there is no second home to fall back on. The second is **memory as a budget**: a value in RAM
costs more than a value on disk, so the modeling family is the set of techniques that spend that budget well —
compact encodings, probabilistic counters that trade accuracy for size, bitmaps that pack a million flags into a
hundred and twenty-five kilobytes, and structures that answer a question without storing every answer.

EchoMQ is the worked case study because it makes both decisions in the open. The job HASH at `emq:{q}:job:<JOB>` is
the job's only canonical state — `state`, `attempts`, `payload`, written by one atomic `@enqueue` script and mutated
in place by `claim`, `complete`, and `retry`. No shadow row sits in Postgres waiting to correct it. The committed
`valkey.conf` makes that posture real: `maxmemory-policy noeviction` so a runaway keyspace rejects writes loudly
instead of dropping work silently, `appendonly yes` with `appendfsync everysec` so a crash loses at most about a
second, and `save ""` so RDB snapshotting never competes for a second fork. The worked consumer, codemojex, then
shows the judgment is made **per datum**: the round leaderboard and the guess locks live in Valkey (`cm:*`); the
player wallet and the transaction ledger live in Postgres.

## Why & when

Reach for Redis as a primary store when the data is hot, operational, and tolerant of about a second of loss — and
keep it out of Redis when it is money. Each demand below has one matching answer, and the chapter is the set of those
answers.

- **Sub-millisecond reads and high write throughput.** When the access pattern is point reads and writes at a rate a
  relational store would strain on, treat RAM as the primary storage layer and disk as a recovery mechanism. EchoMQ's
  enqueue/claim/complete cycle is exactly this shape: every operation touches one key, server-side, in one
  round-trip.
- **The truth has no second home.** When the row in Redis is the authoritative state — not a cache of a database
  somewhere — it must survive a crash and must never be evicted. That is `noeviction` plus an append-only log, and it
  is a per-datum decision: the job HASH is the record; the wallet balance is not.
- **The footprint must fit in RAM.** A value in memory is the expensive value, so the encoding matters. Small hashes
  and sets stay in a compact listpack/intset layout; short field names and capped structures keep the resident set
  small. EchoMQ minimises its job rows for exactly this reason.
- **An exact answer is not worth its memory.** Counting uniques, testing membership, or summarising a distribution
  exactly can cost more memory than the answer is worth. Probabilistic structures trade a bounded error for a fixed,
  tiny footprint — the deliberate contrast with EchoMQ's exact, per-id deduplication.
- **A boolean per entity, by the million.** When the datum is one bit per user per day — active or not, opted-in or
  not — a bitmap packs millions of flags into kilobytes and aggregates them with a single command.
- **Nearness and location are first-class.** Similarity search over vectors and radius queries over coordinates are
  modeling problems Redis answers natively, without a separate search service.

## The patterns

Seven modules. The first is built; the rest are specified. Each module is a hub with its dives, grounded in the real
echo data layer where it has an honest home and in a clean standalone example where it does not.

- **R7.01 · Redis as a primary database** *(built)* — the store as the system of record, not a cache: when Redis is
  the authoritative store, how to persist it, how to model without SQL, and the per-datum judgment of what belongs in
  RAM. Grounded in EchoMQ's job HASH (`emq:{q}:job:<JOB>`) under `noeviction` + AOF.
- **R7.02 · Memory optimization** *(soon)* — compact encodings (listpack, intset) and short field names; capped
  structures with `LTRIM` and `MAXLEN ~`. Grounded in EchoMQ's memory discipline.
- **R7.03 · Probabilistic data structures** *(soon)* — HyperLogLog, Bloom and Cuckoo filters, Count-Min and
  T-Digest: trade a bounded error for a fixed footprint. Taught as the contrast with EchoMQ's exact deduplication.
- **R7.04 · Bitmaps** *(soon)* — millions of boolean flags in minimal memory, aggregated with `BITCOUNT`; a
  standalone daily-active-cohort example, with codemojex analytics as a forward-tense note (the planned analytics
  spike, not a live surface).
- **R7.05 · Vectors & similarity search** *(soon)* — native vector sets (Redis 8 / Valkey HNSW) for semantic search
  and recommendations; a standalone example, with a codemojex recommendation note (forward-tense — codemojex has no
  vector surface today).
- **R7.06 · Geospatial** *(soon)* — locations and radius queries on a geohash sorted set; a standalone
  `GEOADD`/`GEOSEARCH` example.
- **R7.07 · Workshop** *(soon)* — codemojex's dashboard read-models: the round leaderboard, the unique-players count,
  and the activity view, each a fold of operational state.

## How to apply

The hard part is not the structure but the judgment: whose truth is this datum, and what does it cost in RAM. Name
the datum and its tolerances — how much loss it can survive, whether it needs a transaction, how exact the answer
must be — and the home and the modeling technique follow. A job can lose about a second and never needs to join a
business row in one transaction, so it lives in Valkey as the record of truth under `noeviction` and AOF. A wallet
balance must be exact to the cent and must move with the ledger row atomically, so it lives in Postgres. The same
question, asked per datum, places every value in the stack.

This is the move the chapter teaches and EchoMQ demonstrates: *Redis as a primary database* is never a global switch
thrown once. It is a per-datum decision made against two axes — loss tolerance and transactional need — and the
modeling family is the set of techniques for spending the RAM budget once a datum has earned its place there.

## The workshop

The chapter's worked consumer is codemojex (`echo/apps/codemojex`), and its read-models make the whole argument
concrete. Game state — the round leaderboard (`Codemojex.Board`, the sorted set `cm:<game>:board`) and the per-player
guess locks (`Codemojex.Locks`, the hash `cm:<round>:lock:<player>`) — lives in Valkey because it is hot,
operational, and tolerant of about a second of loss. Money — the player balances (`Codemojex.Wallet`) and the
append-only transaction ledger (`Codemojex.Ledger`) — lives in Postgres because a balance must be exact and must
move with its ledger row in one transaction. The dashboard read-models are folds of the operational side: the
leaderboard is a `ZREVRANGE`, the uniques a probabilistic count, the activity view a replay. R7 builds those
read-models on the same per-datum discipline R7.01 establishes.

The contrast that frames the chapter is **Oban**: Oban keeps its jobs in the same Postgres as the application data,
so a job and a business row commit in one transaction — one store, one transaction, full coupling. Echo separates
the bus (the job HASH in Valkey) from the store and buys an in-memory hot path plus a durability dial; it gives up
that one-transaction coupling. Each design names its trade. EchoMQ chooses the in-memory record and the ~1s AOF
bound; the next rungs of the dial — `EchoStore.Graft` committing per record, then Tigris off-box — carry the record
further from loss without putting a database on the path of every dequeue. That dial is the durable floor, taught
end to end at `/echo-persistence`.

## Up next

R7 establishes that Redis can be a system of record and how its data is modeled in RAM. The chapter that follows is
the operations concern over that same record.

- **R8 · Production & Operations** *(soon)* — running the tier at scale: kernel tuning, persistence and failover,
  the case studies, and the capstone door to the dedicated EchoMQ course.

## References

### Sources

- [Valkey — Persistence (RDB and the append-only file)](https://valkey.io/topics/persistence/) — the `appendonly`
  `everysec` posture and a roughly one-second loss bound after a crash, the durability mechanism R7.01 is built on.
- [Valkey — Eviction (the LRU/LFU cache)](https://valkey.io/topics/lru-cache/) — the `maxmemory-policy` menu;
  `noeviction` refuses the write rather than dropping a key, the posture a system of record needs.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces every key of
  one queue onto one of the 16384 hash slots, which keeps a multi-key script legal.
- [Oban](https://hexdocs.pm/oban/Oban.html) — jobs and data in one Postgres transaction; the trade EchoMQ makes the
  other way, in-memory record plus the durability dial.

### Related in this course

- `/redis-patterns/data-modeling/primary-database` — R7.01 · the store as the system of record, with the
  system-of-record, noeviction, and persistence dives.
- `/redis-patterns/caching/cache-aside` — R1.01 · the cache tier the system of record is the opposite of: a
  near-cache holds a copy whose truth lives elsewhere.
- `/bcs/fly/valkey-on-a-fly-machine` — the manuscript figure home (B8.2): the production posture of the same
  `noeviction` + AOF configuration.
- `/bcs/persistence` — the durability dial (B5): the single-writer engine, the lazy reader, the portable remote, and
  the Oban trade in depth.
- `/echo-persistence` — the durable floor beneath the ~1s AOF bound: the Graft engine and the off-box Tigris remote.
- `/bcs/store` — EchoStore (B4): the near-cache that is explicitly *not* a system of record — a derived, droppable
  tier.
