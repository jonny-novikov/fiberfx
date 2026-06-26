# Single-flight & jittered TTL — module hub

**Route:** `/echomq/cache/single-flight-and-jittered-ttl`  
**Pillar:** The Cache · module 02  
**Grounding:** `echo/apps/echo_store/lib/echo_store/table.ex` — all real shipped code, no `[RECONCILE]` markers.

## The frame

Module 01 built the declared near-cache and showed how a read resolves across L1 ETS, L2 Valkey, and the declared
loader. Module 02 is the second half of the read machine: a cache that keeps a herd from turning one miss into N
fills, that keeps cohorts from expiring all at once, and that keeps a full table from becoming a hard failure.

Three laws govern this module:

1. **One fill per herd.** Concurrent misses on the same key coalesce onto a single in-flight load. The first
   caller's flight runs; every other waiter appends and reads that one answer.
2. **Jittered expiry.** Rows expire on `ttl ± ttl·jitter` so a cohort filled together never expires together,
   and no second herd forms at the TTL boundary.
3. **Degrade, not fail.** A full cache becomes a pass-through — it still serves its caller from L2 and the
   loader, it just skips the L1 insert. A full cache never refuses a read.

The three dives teach each law in order, from `EchoStore.Table` source.

## Dives

- **01 · One fill per herd** — `handle_call({:fill, id})` + `launch_flight/2` + the `{:flight}` and `:DOWN`
  handlers: how concurrent misses coalesce, how the owner is never blocked, how a crashed flight fails all
  waiters cleanly.
- **02 · Jittered expiry** — `expires_at/1` (the `ttl ± spread` arithmetic) + `handle_info(:sweep)` (the
  `ets.select_delete` + rearm): how the clock is deliberately uneven and how the sweeper bounds memory.
- **03 · The full cache degrades** — `insert/4` + `reclaim/1` + `stats/1`: the reclaim-then-insert path, the
  `:full_skips` pass-through, and the live counter snapshot.

## References

### Sources
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the read-concurrent L1 table.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{table}` hashtag and one-slot discipline.
- [Valkey — GET](https://valkey.io/commands/get/) — the L2 probe a flight issues.
- [Valkey — SET](https://valkey.io/commands/set/) — the L2 write a fill completes.
- [Helland — Life Beyond Distributed Transactions](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — the entity addressed by a key, cached close to use.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the mint-time id every cached value is framed with.

### Related in this course
- `/echomq/cache` — the Cache chapter landing.
- `/echomq/cache/cache-aside-two-layers` — module 01, the tiers and the read path.
- `/echomq/queue` — the Queue, the other side of the bus.
- `/echomq/protocol` — the keyspace the `ecc:` prefix stands beside.
- `/bcs/store` — the B4 manuscript chapter this pillar realizes.
