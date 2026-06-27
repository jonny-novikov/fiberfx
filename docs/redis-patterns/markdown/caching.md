# R1 · Caching — the read path

> Route: `/redis-patterns/caching` (chapter landing) · Source of structure: the chapter spec
> `specs/caching/caching.md` + the TOC · Grounding: **EchoStore** — the declared near-cache, an L1 of ETS tables
> over the shared L2 Valkey (`echo/apps/echo_store`) — in front of the **codemojex**'s emoji set.
> The first chapter, because caching depends on nothing else.

The most common Valkey use: serving reads fast, and keeping the cache honest when the source changes. Six patterns
from the read-path family — cache-aside, write-through, write-behind, client-side caching, stampede prevention, and
session storage — each with the trade-off that decides when to reach for it. The grounding is EchoStore, the declared
near-cache in front of codemojex's emoji set; the chapter closes by caching that catalog tier end
to end.

## Why & when

A cache trades freshness for speed. It pays off when reads vastly outnumber writes, when the source is slow or
expensive, and when a small window of staleness is acceptable. It hurts when writes are frequent and must be reflected
immediately, when a stale read is incorrect rather than merely old, or when the working set does not fit in memory.
The pattern you pick is a position on that trade-off — not a default.

- **Read-heavy catalog** — an instrument listing read thousands of times between edits → cache-aside (R1.01).
- **Fresh-after-write** — a record that must reflect an edit on the very next read → write-through (R1.02).
- **Write-burst smoothing** — updates written far faster than the database wants → write-behind (R1.03).
- **Hot key under load** — one popular key expiring while thousands ask for it → stampede prevention (R1.05).

Every pattern in this chapter is a different answer to one question: when the cache and the source disagree, who wins,
and for how long.

## The patterns

Six teaching modules, then a workshop. Each module is a hub with three dives.

| Module | Pattern | What it adds |
| --- | --- | --- |
| R1.01 Cache-aside | `cache-aside` (lazy loading) | On a miss, fetch and populate; on a write, invalidate. |
| R1.02 Write-through | `write-through` | Write cache and the source synchronously; reads stay fresh. |
| R1.03 Write-behind | `write-behind` (write-back) | Write Valkey now, sync the source asynchronously through the journal. |
| R1.04 Client-side caching | server-assisted `client-side-caching` | Cache in application memory; the server pushes invalidations. |
| R1.05 Stampede prevention | `cache-stampede-prevention` | Stop a thundering herd regenerating one expired key. |
| R1.06 Session management | `session-management` | Store sessions with TTL expiry. |
| R1.07 Workshop | — | Cache codemojex's emoji set end to end. |

## How to apply

The hard part is not the commands; it is choosing the strategy. Name the constraint that matters most for a workload,
and the pattern follows:

- **Reads dominate** → cache-aside: fill lazily on a miss, invalidate on a write.
- **Fresh after write** → write-through: write both layers synchronously so a read never trails a write.
- **Write throughput** → write-behind: record the intent locally, flush to the source asynchronously over the journal.
- **Same client, repeat reads** → client-side caching: hold hot keys in application memory (L1 ETS); the server pushes invalidations over RESP3.
- **Hot key, high concurrency** → stampede prevention: a single regeneration per herd (single-flight) and a jittered TTL.
- **Per-user state + expiry** → session management: a branded-id-keyed record with a PX TTL.

There is no best caching pattern, only the one that matches the constraint you cannot relax.

## The workshop

The chapter closes with **R1.07**: cache codemojex's emoji set end to end. The instrument listing
and a single instrument are served from EchoStore with cache-aside, kept consistent on edits through coherence,
protected from a stampede on the most-viewed instrument, and measured for hit rate — the read path the later chapters
build on.

## References

### Sources
- [Redis — Patterns](https://redis.io/docs/latest/develop/use/patterns/) — the canonical write-ups of the core caching access patterns.
- [Valkey — SET](https://valkey.io/commands/set/) — set a value with a PX expiry, the cache-aside miss-fill on the engine the connector is gated against.
- [Redis — Client-side caching](https://redis.io/docs/latest/develop/use/client-side-caching/) — server-assisted invalidation via CLIENT TRACKING.
- [Valkey — Client-side caching](https://valkey.io/topics/client-side-caching/) — the RESP3 invalidation push EchoStore's coherence frames with a mint-time version.

### Related in this course
- [R0 · Overview](/redis-patterns/overview) — where Valkey sits under codemojex.
- [R2 · Coordination](/redis-patterns/coordination) — the next chapter.
- [The Branded Component System](/bcs) — Part IV builds the EchoStore near-cache these patterns apply.
- [Functional Programming in Elixir](/elixir) — the functional-Elixir and OTP craft behind the echo data layer.
