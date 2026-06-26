# R7.05.3 — Filtered queries

> Dive 3 · `/redis-patterns/data-modeling/vector-sets/filtered-queries`

Attach JSON metadata to vector elements and query by both vector similarity and structured predicates in one step — hybrid search.

## Attaching Metadata

Use `SETATTR` on `VADD` to attach a JSON object to each element:

```
VADD movies VALUES 128 ... "inception" SETATTR '{"year": 2010, "genre": "scifi", "rating": 8.8}'
VADD movies VALUES 128 ... "arrival"   SETATTR '{"year": 2016, "genre": "scifi", "rating": 7.9}'
VADD movies VALUES 128 ... "parasite"  SETATTR '{"year": 2019, "genre": "drama", "rating": 8.5}'
```

Attributes can be updated later with `VSETATTR`.

## The FILTER Expression

Pass `FILTER '<expr>'` to `VSIM` to restrict results to elements whose metadata matches:

```
VSIM movies VALUES 128 ... FILTER '.year >= 2000 and .genre == "scifi"' COUNT 10
```

### Filter Expression Syntax

| Operator type | Examples |
|---|---|
| Comparisons | `.year >= 1980`, `.rating < 9.0`, `.year == 2010`, `.genre != "horror"` |
| Logic | `and` / `or` / `not` (also `&&` / `\|\|` / `!`) |
| Arithmetic | `.budget / 1000000 > 100` |
| Containment | `.director in ["Spielberg", "Nolan"]` |
| Selectors | `.field` accesses any JSON attribute |

Examples:

```
.year >= 1980 and .year < 1990
.genre == "action" and .rating > 8.0
.director in ["Spielberg", "Nolan"]
(.budget / 1000000) > 100 and .rating > 7
```

Elements with missing fields or invalid JSON are **silently excluded** — no error, no partial result; they simply do not appear.

## Filter Effort (FILTER-EF)

By default, Vector Sets explore `COUNT * 100` candidates when filtering. For very selective filters, increase the effort:

```
VSIM key ... FILTER '.rare_field == 1' FILTER-EF 5000
```

Setting `FILTER-EF 0` explores until `COUNT` is satisfied, potentially scanning the entire index. The trade-off: higher `FILTER-EF` means better recall for selective predicates at the cost of latency.

## Hybrid Search

A filtered vector query is **hybrid search**: a vector neighbourhood AND a structured predicate in a single operation. No post-processing join, no two-stage pipeline:

```
VSIM movies VALUES 128 ... FILTER '.year >= 2000 and .genre == "scifi"' COUNT 10 WITHSCORES
```

This finds the 10 movies most similar to the query vector **that are also science fiction released after 2000**. Traditional keyword search can handle the predicate; vector search handles the similarity; hybrid search handles both at once.

## References

### Sources

- [Redis — Vector sets](https://redis.io/docs/latest/develop/data-types/vector-sets/) — the FILTER section and SETATTR reference.
- [Redis — VADD](https://redis.io/docs/latest/commands/vadd/) — SETATTR option at insert time.
- [Valkey — Search](https://valkey.io/topics/search/) — the Valkey path to hybrid search via FT.SEARCH and filter expressions.
- [Valkey — FT.CREATE](https://valkey.io/commands/ft.create/) — defining VECTOR schema fields on Valkey-search.

### Related in this course

- [R7.05 · Vectors hub](/redis-patterns/data-modeling/vector-sets) — the module overview.
- [R7.05.1 · The HNSW graph](/redis-patterns/data-modeling/vector-sets/the-hnsw-graph) — commands and graph structure.
- [R7.05.2 · RAG and recommendations](/redis-patterns/data-modeling/vector-sets/rag-and-recommendations) — RAG and semantic cache patterns.
