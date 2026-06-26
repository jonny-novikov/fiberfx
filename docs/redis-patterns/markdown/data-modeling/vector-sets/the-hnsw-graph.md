# R7.05.1 — The HNSW graph

> Dive 1 · `/redis-patterns/data-modeling/vector-sets/the-hnsw-graph`

What a vector set is, how the HNSW graph works, the core commands, and the quantization trade-offs.

## What Is a Vector Set?

A Vector Set is a Redis 8 data type similar to a Sorted Set, but each element carries a **vector** instead of a score. You add items with `VADD`; you query for the nearest neighbours with `VSIM`. The index structure maintained internally is an HNSW (Hierarchical Navigable Small World) graph.

## Core Commands

```
VADD key VALUES 3 0.1 0.5 0.9 my-element             # add an element with an inline vector
VADD key FP32 <binary-blob> my-element               # …or a binary blob (faster for clients)
VSIM key VALUES 3 0.1 0.5 0.9 COUNT 10 WITHSCORES    # find the 10 nearest by a query vector
VSIM key ELE existing-element COUNT 10 WITHSCORES    # …or nearest to an existing element
VCARD key   # count   ·   VDIM key  # dimension   ·   VEMB key ele  # get an element's vector
VREM key element                                     # true deletion, memory reclaimed
```

Options on `VADD`: `Q8` (default, 8-bit quantization, 4× memory reduction, ~96% recall) · `BIN` (1-bit, 32× reduction, ~80% recall) · `NOQUANT` (fp32, best recall) · `M num` (HNSW connectivity, default 16) · `EF num` (build-time exploration factor, default 200).

## The HNSW Graph

HNSW (Hierarchical Navigable Small World) is a graph-based approximate nearest-neighbour algorithm. The graph is organised in layers: the top layer is sparse (long-range connections), lower layers are progressively denser. A query traverses from the top layer downwards — a greedy walk at each layer — reaching the approximate nearest neighbours in **O(log N)** hops rather than a full linear scan.

The key properties:
- Built **automatically** when items are added with `VADD` — no separate index creation step.
- Configurable via `M` (connectivity, more = better recall, more memory) and `EF` (exploration factor, more = better recall, slower).
- `VSIM COUNT 10 EF 500` explores more candidates at query time for higher recall at the cost of latency.

### Throughput and Scale

| Operation | Complexity | Typical Throughput |
|---|---|---|
| VSIM | O(log N) | ~50K ops/sec (3M items, 300 dims) |
| VADD | O(log N) | ~5K ops/sec |
| VREM | O(log N) | Fast, true deletion |
| Load from RDB | O(N) | ~3M items in 15 seconds |

## Quantization Trade-offs

| Type | Memory | Speed | Recall |
|---|---|---|---|
| NOQUANT (fp32) | 4 bytes/dim | Baseline | Best |
| Q8 (default) | 1 byte/dim | ~2× faster | ~96% |
| BIN | 1 bit/dim | ~4× faster | ~80% |

Binary quantization (`BIN`) is suitable for initial candidate retrieval before reranking; Q8 (default) provides a good recall/memory balance for most workloads; `NOQUANT` is for cases where recall loss is unacceptable.

---

### Engine divergence: Redis 8 vs Valkey-search

**Redis 8 Vector Sets** treat vectors as a native type — `VADD` and `VSIM` are built-in, the HNSW graph is automatic.

**Valkey (the BCS engine)** reaches the same algorithm via the **`valkey-search` module** (C++, not core Valkey). The workflow differs: you create an index explicitly, then data lives in Hashes or JSON:

```
FT.CREATE myIndex SCHEMA embedding VECTOR HNSW 6 TYPE FLOAT32 DIM 3 DISTANCE_METRIC COSINE
```

Same underlying HNSW algorithm; opposite API surface. The standalone examples in this module teach the Redis 8 path (the source); the Valkey path is the `valkey-search` module route.

## References

### Sources

- [Redis — Vector sets](https://redis.io/docs/latest/develop/data-types/vector-sets/) — the data-type overview.
- [Redis — VADD](https://redis.io/docs/latest/commands/vadd/) — the command reference and quantization options.
- [Valkey — Search](https://valkey.io/topics/search/) — the valkey-search module; FT.CREATE / FT.SEARCH.
- [Valkey — FT.CREATE](https://valkey.io/commands/ft.create/) — index schema with VECTOR HNSW.
- [Valkey — Introducing Valkey Search](https://valkey.io/blog/introducing-valkey-search/) — module design rationale.

### Related in this course

- [R7.05 · Vectors hub](/redis-patterns/data-modeling/vector-sets) — the module overview.
- [R7.05.2 · RAG and recommendations](/redis-patterns/data-modeling/vector-sets/rag-and-recommendations) — the applications.
- [R7.05.3 · Filtered queries](/redis-patterns/data-modeling/vector-sets/filtered-queries) — hybrid vector + predicate search.
