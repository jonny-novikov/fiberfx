# R7.05 — Vectors & similarity search

> Module hub · `/redis-patterns/data-modeling/vector-sets`

Store vectors and find similar items using Redis 8's native Vector Sets—an HNSW-based data structure supporting semantic search, RAG, recommendations, and classification with optional filtered queries.

Vector Sets are a Redis data type similar to Sorted Sets, but elements are associated with vectors instead of scores. They enable finding items most similar to a query vector (or to an existing element) using approximate nearest neighbor search based on HNSW (Hierarchical Navigable Small World) graphs.

## When to Use Vector Sets

- **Semantic search**: Find documents or products by meaning, not keywords
- **RAG (Retrieval Augmented Generation)**: Ground LLM responses in your data
- **Recommendations**: "Users who liked X also liked…"
- **Classification**: Assign categories based on vector similarity
- **Deduplication**: Find near-duplicates in content
- **Anomaly detection**: Find items far from normal patterns

## Core Commands

```
VADD key VALUES 3 0.1 0.5 0.9 my-element             # add an element with an inline vector
VADD key FP32 <binary-blob> my-element               # …or a binary blob (faster for clients)
VSIM key VALUES 3 0.1 0.5 0.9 COUNT 10 WITHSCORES    # find the 10 nearest by a query vector
VSIM key ELE existing-element COUNT 10 WITHSCORES    # …or nearest to an existing element
VCARD key   # count   ·   VDIM key  # dimension   ·   VEMB key ele  # get an element's vector
VREM key element                                     # true deletion, memory reclaimed
```

Quantization on `VADD`: `Q8` (default — 8-bit, 4× reduction, ~96% recall) · `BIN` (1-bit, 32× reduction, ~80% recall) · `NOQUANT` (fp32, best recall). `M` (HNSW connectivity, default 16) and `EF` (exploration) tune recall vs memory.

Similarity scores are cosine, rescaled to 0–1 (1.0 identical, 0.5 orthogonal, 0.0 opposite).

## Similarity Scores

Vector Sets normalize vectors on insertion and use cosine similarity. Scores range from 0 to 1. The formula is `(cosine_similarity + 1) / 2`, rescaled from [-1, 1] to [0, 1].

## Filtered Search

Attach JSON attributes to elements:

```
VADD movies VALUES 128 ... "inception" SETATTR '{"year": 2010, "genre": "scifi", "rating": 8.8}'
VSIM movies VALUES 128 ... FILTER '.year >= 2000 and .genre == "scifi"' COUNT 10
```

## RAG Pattern

Store document chunks with embeddings, retrieve relevant context, augment the LLM prompt, generate.

## Semantic Cache Pattern

Check cache before calling LLM: if a `VSIM` top-1 result scores > 0.95, return the cached response (40–60% LLM-cost reduction on repetitive queries).

## Recommendations Pattern

```
VSIM products:embeddings ELE "product:123" COUNT 20 FILTER '.category == "electronics"'
```

## Classification Pattern

Store labeled examples; classify new items by kNN majority vote among `VSIM` results.

## Performance

| Operation | Complexity | Typical Throughput |
|---|---|---|
| VSIM | O(log N) | ~50K ops/sec (3M items, 300 dims) |
| VADD | O(log N) | ~5K ops/sec |
| VREM | O(log N) | Fast, true deletion |

## Quantization Trade-offs

| Type | Memory | Speed | Recall |
|---|---|---|---|
| NOQUANT (fp32) | 4 bytes/dim | Baseline | Best |
| Q8 (default) | 1 byte/dim | ~2× faster | ~96% |
| BIN | 1 bit/dim | ~4× faster | ~80% |

## Scaling

Partition vectors across instances (shard by `crc32(element) % num_shards`); query all shards in parallel and merge by score client-side.

## Memory Optimization

Use Q8 quantization (default), tune M (default 16), use REDUCE for high-dimensional vectors, keep element names short, minimize JSON attributes to filterable fields only.

---

### The engine divergence — Vector Sets vs Valkey-search

**Redis 8 Vector Sets** are a **native data type** (element ⇒ vector). HNSW is built **automatically — no `FT.CREATE` step**. Commands: `VADD`/`VSIM`/`VREM`/`VEMB`/`VCARD`/`VDIM`.

**Valkey (the BCS engine)** reaches vector search via the **`valkey-search` module** (a C++ module, **not core**):

```
FT.CREATE myIndex SCHEMA embedding VECTOR HNSW 6 TYPE FLOAT32 DIM 3 DISTANCE_METRIC COSINE
FT.SEARCH myIndex "*=>[KNN 10 @embedding $vec]" PARAMS 2 vec <binary>
```

Same HNSW algorithm; opposite surfaces. The standalone examples here teach Vector Sets (the source); the Valkey-search path is named in the engine note.

---

### codemojex: the honest absence

codemojex ships **zero** vector surface — no `VADD`/`VSIM`/embedding in `echo/apps/codemojex/lib` (grep-verified), and there is no planned spike (`infra/` holds `cm-bitmapist` but no `cm-*vector*`). A "rooms/games you might like" recommender **would** embed each room or player profile and find similar items via `VSIM` (or, on Valkey, `FT.SEARCH … KNN`) — but codemojex neither ships nor has specced it.

## References

### Sources

- [Redis — Vector sets](https://redis.io/docs/latest/develop/data-types/vector-sets/) — the data-type overview and command reference.
- [Redis — VADD](https://redis.io/docs/latest/commands/vadd/) — add an element with its vector; the quantization options.
- [Valkey — Search](https://valkey.io/topics/search/) — the valkey-search module: FT.CREATE / FT.SEARCH over Hash/JSON.
- [Valkey — FT.CREATE](https://valkey.io/commands/ft.create/) — create a search index with a VECTOR HNSW schema field.
- [Valkey — Introducing Valkey Search](https://valkey.io/blog/introducing-valkey-search/) — the module announcement and design rationale.

### Related in this course

- [R7.04 · Bitmaps](/redis-patterns/data-modeling/bitmap-patterns) — another structure from the memory/modeling family.
- [R7.03 · Probabilistic data structures](/redis-patterns/data-modeling/probabilistic-data-structures) — memory/accuracy trade-offs in a different form.
- [R7.01 · Redis as a primary database](/redis-patterns/data-modeling/primary-database) — the chapter hub for the modeling family.
- R7.06 · Geospatial — the next modeling structure (not yet built).
