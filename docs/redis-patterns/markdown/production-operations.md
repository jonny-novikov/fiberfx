# R8 · Production & Operations — running the tier at scale

> Operating the Redis/Valkey tier under production load: kernel tuning, persistence and failover,
> and the real case studies — Pinterest, Twitter/X, Uber. The final chapter; it hands off to the
> dedicated EchoMQ course and the manuscript.

Operating the tier is a different skill from designing the patterns. The earlier chapters chose a
data structure and a protocol; this one keeps that choice alive under load — the host tuned away from
its defaults so a fork does not spike, persistence configured so a crash costs about a second rather
than a snapshot interval, and connections that survive a failover. The grounding is EchoMQ's real
production engine: the committed `infra/valkey/conf/valkey.conf` and the kernel settings B8 of the
manuscript applies on a Fly machine, read alongside the source case studies that mapped these
lessons at scale.

## §1 — Why & when: the failure classes this chapter prevents

A production tier fails in a small number of named ways, and each has a setting that prevents it.

- **Latency spike on save.** A background save forks; with transparent huge pages on, a single-byte
  write during copy-on-write copies a whole 2 MB page — a 500x amplification that shows up as a
  10–100x latency spike during `BGSAVE` or `BGREWRITEAOF`.
- **Persistence failure / lost work.** A crash with no append-only log loses every write since the
  last snapshot; an eviction policy that drops keys loses work silently.
- **Dropped connections.** The listen queue defaults to 128; a burst of clients is dropped before the
  server ever accepts them.
- **Fork failure / OOM.** The kernel refuses the fork because it pessimistically assumes the child
  needs as much memory as the parent, even though copy-on-write needs almost none.

The chapter walks each class to the setting that closes it, then to the case study that learned it at
scale.

## §2 — The patterns

Seven modules. R8.01 is built; the rest are specified.

- **R8.01 · Kernel tuning** — host and engine settings that prevent latency spikes and persistence
  failures.
- **R8.02 · Persistence, pooling & failover** — operating the job store as a record of truth: RDB +
  AOF, pool sizing, READONLY-reconnect failover.
- **R8.03 · Pinterest: task queues & partitioning** — functional partitioning and list-based reliable
  queues at scale.
- **R8.04 · Twitter/X: internals & custom structures** — the customizations that became Redis core.
- **R8.05 · Uber: resilience & staggered sharding** — staggered sharding, circuit breakers, graceful
  degradation.
- **R8.06 · Operating EchoMQ** — the bridge: pooling, cluster colocation, metrics and tracing in
  production.
- **R8.07 · Capstone** — the handoff to the dedicated EchoMQ course.

## §3 — How to apply: pick a failure, get the setting

Name the failure mode, and the production setting that prevents it follows. Each verdict is drawn from
the committed `valkey.conf` or the kernel-tuning source.

- **Latency spike on save** → turn transparent huge pages off. The fork's copy-on-write turns a
  one-byte write into a whole-huge-page copy; `echo never > .../transparent_hugepage/enabled`. See
  the THP / overcommit dive.
- **Fork fails / OOM** → `vm.overcommit_memory=1`, so a copy-on-write fork is allowed even when used
  memory is near the box's RAM.
- **Lost work on a crash** → `appendonly yes` with `appendfsync everysec` (a worst-case loss bound of
  about one second) and `maxmemory-policy noeviction` — reject writes loudly rather than drop work
  silently.
- **Dropped connections** → raise the TCP backlog (`tcp-backlog` clamped by `net.core.somaxconn`) and
  the file-descriptor limit, so a burst is accepted rather than dropped.
- **Swap stalls** → `vm.swappiness=1`. A swapped page trades nanoseconds for milliseconds; a single
  swapped page can cause client timeouts.
- **Memory fragmentation** → `activedefrag yes`, which relocates live objects out of sparse jemalloc
  runs to keep `mem_fragmentation_ratio` near 1.

There is no general tuning. Each setting answers one failure class, and the box is tuned by naming the
classes it must survive.

## §4 — The capstone: the handoff

The chapter ends by pointing at the two courses that own the depth it has only operated.

- **Production on Fly, in the manuscript** (`/bcs/fly`). B8 builds the same shape from the inside: the
  release image, Valkey on a Fly machine kernel-tuned away from its defaults, EchoMQ wired into the
  supervision tree and watched by queue depth and lease health, and the `fly.toml`.
- **Operating the tier — the EchoMQ course** (`/echomq`). The dedicated course teaches the system
  these patterns operate. Its **Proof** pillar is where operating-the-tier is proven: the black-box
  conformance suite, the telemetry / OpenTelemetry catalog, and the honest benchmark against Oban.

Notes on Valkey: with `appendonly yes` and `appendfsync everysec` the volume holds an append-only log
and the worst-case loss after a crash is roughly one second of writes, not a whole snapshot interval —
the bound EchoMQ's checkpoints are designed against. `maxmemory-policy noeviction` then surfaces
memory pressure as write errors to alert on, rather than letting work disappear.

## §5 — Up next: the dedicated courses

R8 is the final chapter of the catalog. After the patterns, the reader continues into the courses that
teach the systems and the language behind them.

- **EchoMQ — the protocol** (`/echomq`) — the owned Valkey-native job system, taught in depth.
- **The Branded Component System** (`/bcs`) — the architecture the patterns are applied to.
- **Functional Programming in Elixir** (`/elixir`) — the functional and OTP craft behind the echo data
  layer.

## References

### Sources

- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — the fork, fsync, and
  huge-page behavior the kernel tuning is for.
- [Valkey — Persistence](https://valkey.io/topics/persistence/) — the append-only `everysec` posture
  and its roughly one-second loss bound after a crash.
- [Redis — Administration](https://redis.io/docs/latest/operate/oss_and_stack/management/admin/) — the
  THP, overcommit, and backlog warnings a production node checks at startup.
- Shopify RedisDays presentation, Redis documentation, and production post-mortems from Netflix, Uber,
  and AWS ElastiCache teams — the source for the kernel-tuning settings and the scaling case studies.

### Related in this course

- [R8.01 · Kernel tuning](/redis-patterns/production-operations/kernel-tuning) — the host and engine
  settings worked in full.
- [Redis Patterns Applied — the catalog](/redis-patterns) — the course home and the full pattern map.
- [EchoMQ — the protocol](/echomq) — the dedicated course this chapter hands off to.
- [Production on Fly, in the manuscript](/bcs/fly) — B8 builds this shape from the inside.
- [Functional Programming in Elixir](/elixir) — the craft behind the echo data layer.
