# EchoMQ — the protocol, in depth

> Route: `/echomq` (course home). The route-mirror source-of-record for the home page. A **route manifest**: it
> forward-links every pillar and module, so unbuilt routes carry the `soon` pill.

## Hero

EchoMQ is a job queue that is a **protocol, not a library**: it is defined by its Lua scripts and its key layout, so
any runtime that speaks them is a first-class peer. The wire is EchoMQ's own — a declared-key `emq:{q}:` keyspace on
a single **Valkey 9**, where every key of a queue carries the per-queue `{q}` hashtag so it lands in one Valkey
Cluster hash slot and a multi-key Lua script stays legal. This course teaches the whole system in depth, for the
people who run it: why a queue should be a protocol, why Valkey, why the owned wire goes faster, what is inside, and
what the Stream Tier adds. The worked examples are real keys, real Lua, and real module functions with verified
arities, grounded in `echo/apps/echo_mq`. It is the course on the far side of every "→ EchoMQ" door in
[Redis Patterns Applied](/redis-patterns), and the bus the [Branded Component System](/bcs) is built on.

## Why a protocol, not a library

A library binds your work to one language — Sidekiq to Ruby, Celery to Python, Oban to Elixir. EchoMQ's Golden Rule —
the Lua scripts and the key layout *are* the protocol — lets any service that speaks the wire share one queue on one
Valkey, with no bridge between them.

- **Why Valkey.** The BSD-licensed, foundation-governed store with Redis-semantics scripting, AOF durability, and
  hash-field TTL — the neutral substrate of record every durability and conformance claim is phrased against.
- **Why the owned wire goes faster.** A wire whose scripts reach keys they never declare, and whose queues carry no
  hashtags, gives a sharded engine nothing to place — it falls back to a whole-store lock. The owned wire declares
  every Lua key in `KEYS[]` and hashtags every queue, so under **Valkey Cluster** every key of a queue hashes to one
  slot (CRC16 of the `{q}` bytes) and a multi-key script is co-located and legal. The wire's identity is stamped and
  fenced — `@wire_version "echomq:2.4.2"` — so a client speaking a different version can never half-speak it.

## What's new — the Stream Tier

Event streams on the same certified wire, no second protocol: append-ordered, hash-tagged streams with branded
record ids; consumer groups with at-least-once delivery and crash re-delivery; retention as declared policy; a deep
archive folded into the durable floor (`EchoStore.StreamArchive` → `EchoStore.Graft`), restorable after box loss; and
time-travel reads where a branded mint instant becomes a range bound. The course teaches it as it lands.

## Why the BCS architecture builds on EchoMQ

EchoMQ is the **bus and the near-cache of the [Branded Component System](/bcs)**. The BCS course teaches the
architecture — the 14-character branded snowflake, the grammar-total keyspace law, fair lanes, the coherent
cache-aside near-cache — and EchoMQ *is* that architecture, shipped: [the bus](/bcs/bus) (jobs, lanes, the consumer)
and [the cache](/bcs/cache) (the L1/L2 near-cache, kept coherent on the bus) are the modules this course opens up. A
system on the BCS architecture inherits its queue, cache, and coherence from EchoMQ — the worked example is
**codemojex** (`echo/apps/codemojex`), a Telegram emoji-guessing game whose guess jobs, scoring, leaderboard, and
round settlement all ride EchoMQ.

## The map — the six pillars

The whole system, pillar by pillar. The first three are built and readable today; the rest are on the roadmap and
carry the `soon` pill. Each pillar closes with a hands-on workshop. (Each Movement-II pillar applies a
`← redis-patterns R[N]` family; the internal rung it tracks is recorded in the program roadmap, not here.)

**Built — read it today.**

- **Overview** — `/echomq/overview` — `← redis-patterns R0`. The thesis, the protocol below the line, the door.
  Dives: the polyglot thesis · the protocol below the line · the three pillars · the door & the living course.
- **Protocol** — `/echomq/protocol` — `← redis-patterns R0.2, R0.3, R2` — here now. The `emq:{q}:*` key taxonomy +
  job hash, the atomic Lua + EVALSHA dispatch, the owned-keyspace / declared-keys discipline, the version fence, and
  the immutability + branded-id contract. Modules: the-owned-keyspace · the-lua-layer · immutability-and-branded-ids ·
  workshop.
- **Queue** — `/echomq/queue` — `← redis-patterns R3, R4, R6` — here now. The pending/active/dead lifecycle + the
  `@claim` lease, stalled recovery, the `:schedule`/`@promote` machinery, `EchoMQ.Repeat`, backoff-retry, fair lanes,
  groups, batches, lifecycle controls. Doors to `/echo-persistence` at the durability frontier. Modules: the claim
  path · jobs-lanes-consumer · scheduling-and-repeat · the durable floor · workshop.

**On the roadmap — `soon`.**

- **Bus** — `/echomq/bus` — `← redis-patterns R5` — **here now (the landing; its modules soon).** The broker surface above the queue: pub/sub,
  streams, distributed events and cancel over the bus.
- **Cache** — `/echomq/cache` — `← redis-patterns R1, R5` — on the roadmap. EchoStore — the L1 ETS / L2 Valkey
  cache-aside near-cache: branded-Snowflake keyed, single-flight, jittered TTL, version-guarded, bus-coherent.
- **Proof** — `/echomq/proof` — `← redis-patterns R8` — on the roadmap. The black-box conformance suite, the
  `:telemetry`/OTel catalog, the honest benchmark vs Oban.
