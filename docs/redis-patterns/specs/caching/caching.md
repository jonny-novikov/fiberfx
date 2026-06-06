# R1 · Caching — the read path

> The most common Redis use: serving reads fast and keeping the cache consistent when the source changes. Six
> patterns from the read-path family, grounded in Portal's catalog cache machine — the first chapter, because
> caching is the gateway concept and depends on nothing else.

## Where this chapter starts and ends

- **Start** — the reader knows Redis string/hash commands and TTL but reaches for the wrong caching strategy
  (`SETEX` where `SET … NX PX` is idiomatic; a fixed TTL where early-refresh is needed). No prior chapter is assumed.
- **End** — the reader can choose between cache-aside, write-through, write-behind, and client-side caching for a
  workload, prevent a stampede on a hot key, and store sessions with correct expiry — and has cached Portal's
  catalog tier end to end in the workshop.

## The grounding (Redis Pattern Applied)

The cache family is **not** an EchoMQ pattern set — it is grounded in **Portal's catalog cache machine** (the read
cache in front of the F5 engine) and its session store (F6.8.1). One bonus crossing: EchoMQ's `ScriptLoader` caches
Lua-script SHA1s the same way an application caches data, so R1.04 shows the client-side-caching idea reflected in a
real script cache (`apps/echomq-go/pkg/echomq/scripts/loader.go`). There is no →EchoMQ door from this chapter; the
queue grounding begins at R2.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R1.01 cache-aside | `cache-aside` | on miss fetch and populate; on write invalidate | Portal catalog reads | GET/SETEX miss-fill · explicit invalidation · TTL & staleness |
| R1.02 write-through | `write-through` | write cache + DB synchronously; reads always fresh | Portal write path | synchronous dual write · the consistency guarantee · the latency cost |
| R1.03 write-behind | `write-behind` | write Redis, sync the DB asynchronously | Portal write buffer | the async buffer · the durability trade-off · coalescing writes |
| R1.04 client-side-caching | `client-side-caching` | cache in app memory; Redis pushes invalidations | `CLIENT TRACKING`; EchoMQ `ScriptLoader` SHA1 cache | CLIENT TRACKING · invalidation push · the SHA1 script-cache parallel |
| R1.05 cache-stampede-prevention | `cache-stampede-prevention` | stop a herd regenerating one expired key | Portal hot-key refresh | lock-on-miss · probabilistic early refresh · request coalescing |
| R1.06 session-management | `session-management` | sessions with TTL expiry | Portal F6.8.1 session store | Hash vs String vs JSON · TTL expiry · the auth-session tie-in |
| R1.07 Workshop | — | cache Portal's catalog tier end to end | Portal catalog + cache machine | — |

## The door to the EchoMQ course

None for this chapter. The cache family is Portal-grounded; the EchoMQ grounding (and the first →door) begins at R2.
The one EchoMQ crossing here is the SHA1 script cache in R1.04, shown as a parallel, not a door.

## Conventions

Pages in this chapter follow the two mandatory layout rules (clickable segmented route-tag; canonical 3-column
footer with the `TSK…` Snowflake stamp), pass the ten jonnify-cms gates including `refs`, and honour the voice and
no-invent rules: cite only the real Portal surface or the named Redis command, never a fabricated cache API. See
[`../redis-patterns.md`](../redis-patterns.md) for the full contract.

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
