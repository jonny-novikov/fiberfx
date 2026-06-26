# noeviction — refuse the write, do not drop the record

> R7.1.2 · dive 2 of *Redis as a primary database*. Route: `/redis-patterns/data-modeling/primary-database/noeviction`.

`maxmemory-policy` is a menu, and the menu choice is the line between a cache and a system of record. The cache
policies — `allkeys-lru`, `allkeys-lfu`, `volatile-ttl`, and their kin — **delete keys under memory pressure** so
the server can keep serving the next write. `noeviction` does the opposite: when the keyspace reaches `maxmemory`,
it **refuses the write** and returns an error. If Valkey holds your record of truth, eviction is silent data loss —
a leaderboard row, a job, a guess lock, gone with no trace and no warning. So a system of record runs `noeviction`,
and memory pressure stops being a vanished record and becomes a **loud error to alert on**.

## The menu, and what each entry does at the cap

Every entry below answers one question: *when the keyspace is full and a write arrives, what gives?* The cache
policies sacrifice a stored key; `noeviction` sacrifices the incoming write.

- **`allkeys-lru` / `allkeys-lfu`** — evict from the **whole keyspace** by least-recently-used (or
  least-frequently-used) approximation. A write past the cap deletes the coldest key to make room, then succeeds.
  This is the right posture for a pure cache: every value is reconstructable from a backing store, so dropping one
  costs a miss, not a record.
- **`volatile-lru` / `volatile-lfu` / `volatile-ttl` / `volatile-random`** — evict only keys that carry a TTL,
  by the named rule (`volatile-ttl` takes the shortest remaining life first). Keys with no expiry are immune. If
  the keyspace fills with non-volatile keys, these behave like `noeviction` — the write is refused because there is
  nothing eligible to evict.
- **`noeviction`** — evict nothing. A write that would exceed `maxmemory` is rejected with an OOM error
  (`OOM command not allowed when used memory > 'maxmemory'`). Reads still serve. The data already stored is never
  touched; the new write is the thing that fails, loudly, where it can be seen.

The cache policies keep serving by **forgetting**. `noeviction` keeps the truth by **refusing**. A system of
record cannot afford to forget, so it accepts the refusal as the cost of never losing a record.

## Memory pressure under each posture

Put the same write — a new job row at a full keyspace — to two servers, one on `allkeys-lru` and one on
`noeviction`, and the divergence is the whole lesson:

- **`allkeys-lru`**: the write **succeeds**. To make room, Valkey approximates the least-recently-used key and
  deletes it. If that key was a cache entry, the system is fine — the next read refills it. If that key was the
  *only copy* of a record — a job HASH, a wallet balance, a settled round — it is **gone**, silently, and nothing
  in the response says so. This is the record-of-truth catastrophe: a store that is also the only source of truth
  must never silently delete.
- **`noeviction`**: the write **fails** with an OOM error. The job is not enqueued; the caller sees the error;
  the alert fires on `used_memory` crossing the threshold. Nothing already stored is lost. The operator raises
  `maxmemory`, or sheds load, with the full record intact. Memory pressure became a signal, not a leak.

The trade is explicit and one-directional: `noeviction` gives up the ability to keep accepting writes under
pressure, and buys the guarantee that no stored record is ever dropped to make room. For a cache that is the wrong
trade; for a system of record it is the only acceptable one.

## In EchoMQ — the job HASH is the record of truth

EchoMQ's job row has no second canonical copy. The `@enqueue` script writes the row in one atomic step —
`HSET emq:{q}:job:<JOB-id> state pending attempts 0 payload <body>` — and `claim` / `complete` / `retry` mutate
**that same HASH**. There is no shadow row in Postgres to fall back on if the key disappears. That is precisely why
EchoMQ's Valkey runs `noeviction`: an evicted job key is a lost job, and a queue that silently drops keys is a
queue that silently loses work.

The committed tuning surface (`infra/valkey/conf/valkey.conf`) sets it directly, and the comment states the intent:

```
# noeviction means a runaway keyspace REJECTS writes loudly instead of being OOM-killed silently.
maxmemory 512mb
maxmemory-policy noeviction
maxmemory-clients 64mb
```

Two design choices ride alongside it. First, `maxmemory` is a **guardrail set far above the working set**, not a
working ceiling — the live dataset is single-digit megabytes, so 512 MB leaves roughly half the box for fork
copy-on-write and buffers, and the cap exists to turn a runaway into an alert long before the OOM killer acts.
Second, the write path is fenced at acknowledgement:

```
# Fail the write rather than acknowledge data that may not survive.
propagation-error-behavior panic
```

`propagation-error-behavior panic` makes the server fail a write rather than acknowledge data that may not
survive — the same posture as `noeviction`, applied to propagation rather than to memory: refuse, do not pretend.
The manuscript states the principle for the bus directly (`bcs.8.md` §B8.2): *"Eviction is the wrong posture for a
job store: a queue that silently drops keys is a queue that silently loses work, so memory pressure must surface as
write errors and alerts."*

### The bridge

| The pattern | Its EchoMQ application |
|---|---|
| The eviction-policy menu: cache policies delete a key under pressure to keep serving; `noeviction` refuses the write instead, so nothing stored is lost. | EchoMQ chooses `noeviction` because the job HASH is the record of truth — an evicted key is a lost job. `maxmemory` is a guardrail far above the working set, paired with `propagation-error-behavior panic`. |

**Take:** the eviction policy is the line between a cache and a system of record. A cache evicts to keep serving; a
record of truth refuses the write and turns memory pressure into a loud, alertable error — because there is no
second copy to fall back on.

## Notes on Valkey

`maxmemory-policy` selects what happens at the `maxmemory` cap: the `allkeys-*` policies evict from the whole
keyspace, the `volatile-*` policies evict only keys with a TTL, and `noeviction` rejects writes with an OOM error
while continuing to serve reads — [valkey.io/topics/lru-cache](https://valkey.io/topics/lru-cache/).

## References

### Sources

- [Valkey — Key eviction](https://valkey.io/topics/lru-cache/) — the `maxmemory-policy` menu: the LRU/LFU
  approximations, the volatile vs allkeys split, and `noeviction`.
- [Valkey — CONFIG SET](https://valkey.io/commands/config-set/) — set `maxmemory` and `maxmemory-policy` at
  runtime without a restart.
- [Valkey — Persistence](https://valkey.io/topics/persistence/) — AOF and RDB, the durability beneath the
  record of truth this policy protects.
- [Valkey — HSET](https://valkey.io/commands/hset/) — the command that writes the job HASH the eviction policy
  must never drop.

### Related in this course

- [R7.1 · Redis as a primary database](/redis-patterns/data-modeling/primary-database) — the module hub: the
  store as the system of record.
- [R7.1.1 · System of record](/redis-patterns/data-modeling/primary-database/system-of-record) — the row is the
  record, and the per-datum decision.
- [R7.1.3 · Persistence](/redis-patterns/data-modeling/primary-database/persistence) — RDB vs AOF; the durability
  bound under the record of truth.
- [The Branded Component System — production on Fly](/bcs/fly/valkey-on-a-fly-machine) — the production posture
  of this exact config.
