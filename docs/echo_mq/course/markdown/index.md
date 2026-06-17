# EchoMQ — the protocol, in depth

> Route: `/echomq` (course home). The route-mirror source-of-record for the home page. A **route manifest**: it
> forward-links every chapter and module, so unbuilt routes carry the `soon` pill.

## Hero

EchoMQ is a job queue that is a **protocol, not a library**: it runs across **Elixir**, **Go**, and **Node.js** against
a single **Valkey**, because the Lua scripts and the key layout *are* the protocol — any runtime that speaks them is a
first-class peer. In **EchoMQ 2.0** that wire is EchoMQ's own: a declared-key `emq:{q}:` keyspace built for
**Dragonfly**'s thread-per-shard engine — a deliberate break from the BullMQ-compatible v1 line, which is now frozen at
1.3.0. This course teaches the whole system in depth, for the people who run it: why a queue should be a protocol, why
Valkey, why 2.0 goes faster, what is inside, what is new, and what is coming in **EchoMQ 3.0**. The worked examples are
real keys, real Lua, and real module functions with verified arities. It is the course on the far side of every
"→ EchoMQ" door in [Redis Patterns Applied](/redis-patterns), and the bus the [Branded Component System](/bcs) is
built on.

## Why a protocol, not a library

A library binds your work to one language — Sidekiq to Ruby, Celery to Python, Oban to Elixir, BullMQ to Node. EchoMQ's
Golden Rule — the Lua scripts and the key layout are the protocol — lets one Elixir service, one Go worker, and one Node
dashboard share one queue on one Valkey, with no bridge between them.

- **Why Valkey.** The BSD-licensed, foundation-governed store with Redis-semantics scripting, AOF durability, and
  hash-field TTL — the neutral substrate of record every durability and conformance claim is phrased against.
- **Why 2.0 goes faster.** The v1 line rode the BullMQ wire — scripts reach keys they never declare, queues carry no
  hashtags — so a thread-per-shard engine has nothing to place and falls back to a whole-store lock. EchoMQ 2.0 owns its
  wire: `emq:{q}:` hashtags every queue and every Lua key is declared, so **Dragonfly** shards and parallelizes what the
  old wire serialized. The break was made once, versioned and fenced (`echomq:2.0.0`); the v1 line is frozen at 1.3.0.

## What's new — and what's next

- **EchoMQ 2.0 — here now.** The owned `emq:{q}:` keyspace, every Lua key declared, branded integer-snowflake ids minted
  at the edge, and a one-way version fence (`echomq:2.0.0`) so a v1 client can never half-speak it — taught in depth on
  the real code.
- **EchoMQ 3.0 — on the roadmap.** Event streams on the same certified wire, no second protocol: append-ordered
  hash-tagged streams with branded record ids; consumer groups with at-least-once delivery and crash re-delivery for
  BEAM *and* non-BEAM readers; retention as declared policy; a deep SQLite archive under a shadow, restorable after box
  loss; and time-travel reads where a branded mint instant becomes a range bound. On the roadmap, not yet shipped —
  this course teaches it as it lands.

## Why the BCS architecture builds on EchoMQ

EchoMQ is the **bus and the near-cache of the [Branded Component System](/bcs)**. The BCS course teaches the
architecture — the 14-byte branded snowflake, the grammar-total keyspace law, fair lanes, the coherent cache-aside
near-cache — and EchoMQ *is* that architecture, shipped: [the bus](/bcs/bus) (jobs, lanes, the consumer) and
[the cache](/bcs/cache) (the L1/L2 near-cache, kept coherent on the bus) are the modules this course opens up. A system
on the BCS architecture inherits its queue, cache, and coherence from EchoMQ — the worked example is **codemoji**
(`echo/apps/codemoji`), a code-breaking game whose guess jobs, scoring, leaderboard, and prize settlement
all ride EchoMQ.

## The map

The whole system, chapter by chapter. The first three chapters are the core you can read today; the rest are the
features on the owned 2.0 wire — some here now, the others on the roadmap. Each chapter closes with a hands-on workshop.
(Each Movement-II chapter applies a `← redis-patterns R[N]` family; the internal rung it tracks is recorded in the
program roadmap, not here.)

**The core — read it today.**

- **E0 · Overview** — `/echomq/overview` — `← redis-patterns R0`. The thesis, the four layers, the door. Dives: the
  polyglot thesis · the four layers · the door & the living course.
- **E1 · The protocol & the data layer** — `/echomq/protocol` — `← redis-patterns R0.3, R2` — here now. L1/L2, the
  wire. Modules: four-layer-model · job-hash · lua-scripts · immutability · workshop.
- **E2 · The lifecycle, components & runtimes** — `/echomq/core` — `← redis-patterns R3` — here now. Modules:
  lifecycle · jobs-queues-workers · lock-management · runtimes · workshop.

**The features — on the owned 2.0 wire.**

- **E3 · EchoMQ 2.0 — the protocol break** — `/echomq/substrate` — `← redis-patterns R0.2, R2` — here now. The
  foundation of 2.0: the owned keyspace, declared keys, the versioned fence. Modules: owned-keyspace · declared-keys ·
  version-fence · probes · workshop.
- **E4 · Groups** — `/echomq/groups` — `← redis-patterns R4, R6` — on the roadmap. Modules: round-robin ·
  park-dont-poll · control-plane · recovery · workshop.
- **E5 · Batches** — `/echomq/batches` — `← redis-patterns R3, R6` — on the roadmap. Modules: atomic-fetch · shaping ·
  affinity-and-finish · workshop.
- **E6 · Lifecycle controls** — `/echomq/lifecycle` — `← redis-patterns R3, R4, R5` — on the roadmap. Modules: ttl ·
  cancel · checkpoints · workshop.
- **E7 · EchoCache** — `/echomq/cache` — `← redis-patterns R1, R5` — on the roadmap. The near-cache. Modules:
  two-layers · single-flight · coherence · workshop.
- **E8 · Conformance, telemetry & the benchmark gate** — `/echomq/production` — `← redis-patterns R8` — on the roadmap.
  Modules: conformance · telemetry · benchmark · workshop.
