# R7.05.2 — RAG and recommendations

> Dive 2 · `/redis-patterns/data-modeling/vector-sets/rag-and-recommendations`

The applications of vector search: the RAG pipeline, semantic caching, recommendations, and classification — with the forward-tense codemojex note.

## Retrieval-Augmented Generation (RAG)

RAG enhances Large Language Models by retrieving relevant context from your data before generating responses. Traditional keyword search fails when a user phrases a question differently from how the relevant document is worded; vector search finds semantic matches regardless of exact phrasing.

**The RAG Pipeline:**

1. **Ingest**: Split documents into chunks, generate embeddings, store in a Vector Set.
2. **Query**: Convert the user question to an embedding using the same model.
3. **Retrieve**: `VSIM docs:index … COUNT 5` finds the most relevant chunks.
4. **Augment**: Include the retrieved chunks in the LLM prompt as context.
5. **Generate**: LLM generates an answer grounded in the retrieved context.

```
VADD docs:index FP32 <embedding> "chunk:doc1:p1" SETATTR '{"doc": "manual.pdf", "page": 1}'
VADD docs:index FP32 <embedding> "chunk:doc1:p2" SETATTR '{"doc": "manual.pdf", "page": 2}'

VSIM docs:index FP32 <query_embedding> COUNT 5 WITHSCORES
```

### RAG with Metadata Filtering

```
VSIM docs:index FP32 <query> COUNT 5 FILTER '.doc == "manual.pdf" and .date > "2024-01-01"'
```

## Semantic Caching

Traditional caches fail with natural language because different phrasings produce different cache keys ("Who is the US President?" vs "Current POTUS" vs "Who leads the United States?").

A semantic cache stores the embedding of each query alongside its response. Before calling the LLM, run `VSIM` against the cache: if the top result scores above 0.95, the queries are semantically close enough to reuse the cached response.

```
VSIM query:cache FP32 <query_embedding> COUNT 1 WITHSCORES
# if score > 0.95: return cached response
# otherwise: call LLM, store result
```

Semantic caching can reduce LLM API costs by 40–60% for applications with repetitive queries such as customer support or FAQ bots.

## Recommendations

Find items similar to one a user has interacted with:

```
VSIM products:embeddings ELE "product:123" COUNT 20 FILTER '.category == "electronics" and .in_stock == 1'
```

For a user who has liked multiple items, collect candidates from `VSIM ELE` calls for each liked item, deduplicate, and rank by summed score (items similar to more liked items rank higher).

## Classification

Store labeled examples in a Vector Set:

```
VADD classifier FP32 <embedding> "spam:ex1" SETATTR '{"label": "spam"}'
VADD classifier FP32 <embedding> "ham:ex1"  SETATTR '{"label": "ham"}'
```

Classify a new item by finding its k nearest neighbours and taking the majority vote among their labels. This works for zero-shot and few-shot classification without retraining.

---

### codemojex: the forward-tense note (honest absence)

codemojex ships **zero** vector surface. A grep of `echo/apps/codemojex/lib` finds no `VADD`, `VSIM`, `HNSW`, or embedding code — and there is no planned spike (`infra/` holds `cm-bitmapist` but no `cm-*vector*`).

A "rooms and games you might like" recommender **would** be a natural fit: embed each room's description (game type, emoji set, difficulty) and each player's history, then `VSIM` (or on Valkey, `FT.SEARCH … KNN`) to surface similar rooms at the session start. But codemojex neither ships nor has specced this surface. The note is a hypothetical illustration, not a planned feature.

## References

### Sources

- [Redis — Vector sets](https://redis.io/docs/latest/develop/data-types/vector-sets/) — RAG, semantic cache, and recommendations sections.
- [Redis — VADD](https://redis.io/docs/latest/commands/vadd/) — the command that drives the ingest step.
- [Valkey — Search](https://valkey.io/topics/search/) — the Valkey path to the same patterns via FT.SEARCH.
- [Valkey — FT.CREATE](https://valkey.io/commands/ft.create/) — index schema for Valkey-search.

### Related in this course

- [R7.05 · Vectors hub](/redis-patterns/data-modeling/vector-sets) — the module overview.
- [R7.05.1 · The HNSW graph](/redis-patterns/data-modeling/vector-sets/the-hnsw-graph) — commands, graph structure, quantization.
- [R7.05.3 · Filtered queries](/redis-patterns/data-modeling/vector-sets/filtered-queries) — hybrid vector + predicate search.
