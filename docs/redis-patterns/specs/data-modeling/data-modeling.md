# R7 · Data Modeling & Memory — how data lives in RAM

> How data is modeled and how memory is spent: Redis as a system of record, compact encodings, probabilistic
> structures, bitmaps, vectors, and geospatial. Six patterns from the modeling family, grounded in Portal's
> dashboard read-models, with EchoMQ's memory discipline as the worked example for optimization.

## Where this chapter starts and ends

- **Start** — the queue chapters (R3–R6), which used Redis structures as machinery. The reader can run a queue but
  has not treated Redis as the authoritative data store or reasoned about its memory footprint.
- **End** — the reader can run Redis as a system of record with the right persistence and eviction settings, cut
  memory with compact encodings and short fields, trade accuracy for memory with probabilistic structures, model
  flags with bitmaps, run similarity search with vector sets, and query locations geospatially. The workshop builds
  Portal's dashboard read-models.

## The grounding (Redis Pattern Applied)

Grounded in **Portal's read-models** with **EchoMQ's memory discipline** as the optimization case study: EchoMQ
treats the job HASH as the record of truth under `noeviction`, and minimises memory with compressed field names
(`atm`/`ats`/`stc`/`deid`), `LTRIM`-capped metrics, and `MAXLEN ~`-capped streams — the concrete
`memory-optimization` example. The probabilistic module is the **contrast** to EchoMQ's exact `de:{id}` dedup.
Bitmaps, vectors, and geospatial are grounded in Portal's analytics, recommendations, and a standalone example.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R7.01 primary-database | `redis-as-primary-database` | Redis as the system of record, not a cache | EchoMQ job HASH; `noeviction` | system-of-record · `noeviction` · persistence (RDB/AOF) |
| R7.02 memory-optimization | `memory-optimization` | compact encodings and short fields | EchoMQ compressed fields, `LTRIM`, `MAXLEN ~` | listpack/intset encodings · short field names · capped structures |
| R7.03 probabilistic | `probabilistic-data-structures` | trade accuracy for memory | **contrast** with EchoMQ's exact `de:{id}` dedup | HyperLogLog · Bloom/Cuckoo · Count-Min/T-Digest |
| R7.04 bitmaps | `bitmap-patterns` | millions of boolean flags in minimal memory | Portal daily-active-learner analytics | 1-bit flags · BITCOUNT aggregates · daily-active patterns |
| R7.05 vectors | `vector-sets` + `vector-search-ai` | native vector sets for semantic search | Portal course recommendations (Redis 8 HNSW) | Redis 8 HNSW vector sets · RAG / recommendations · filtered queries |
| R7.06 geospatial | `geospatial` | locations and radius queries on a geohash sorted set | standalone GEOADD/GEOSEARCH + a Portal note | GEOADD/GEOSEARCH · radius/box queries · the geohash sorted-set |
| R7.07 Workshop | — | Portal's dashboard read-models | leaderboard + HyperLogLog uniques + recommendations | — |

## The door to the EchoMQ course

No dedicated door from this chapter — the modeling family is grounded in Portal's read-models, not EchoMQ's protocol.
The one EchoMQ crossing is R7.02's memory optimization (the compressed-field discipline), shown as the worked
example, not a door. The operations of running Redis as a primary store continue in R8.

## Conventions

Pages follow the two mandatory layout rules, pass the ten gates including `refs`, and honour voice and no-invent:
cite the real Portal surface, the named Redis command, or EchoMQ's real memory technique. R7.05 covers both
`vector-sets` (the structure) and `vector-search-ai` (its application) as one module, since they are the same
technique. See [`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
