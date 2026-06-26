# Declared, not discovered

**Dive 01 of Cache-aside, two layers · `/echomq/cache/cache-aside-two-layers/declared-not-discovered`**

The first law of the Cache: **a cache absent from the directory does not exist.**

## The directory

`EchoStore.Directory` is a GenServer that owns the directory ETS table. It is the single source of truth
for every live cache on the node.

`EchoStore.Directory.register(name, spec, owner)` is called by each `EchoStore.Table` process at init.
It inserts `{name, spec}` into the directory table and monitors the owner process with `Process.monitor/1`.
When the owner exits, `handle_info({:DOWN, ...})` deletes the row — the roster is never stale.

`EchoStore.tables/0` returns every declared cache as `[{name, spec}]`, sorted. An operator reads it to see
what is alive on the node. `EchoStore.spec(name)` returns `{:ok, spec} | :error` — `:error` means the cache
is not in the directory, which means it does not exist.

The declared spec map:

```elixir
%{
  kind: "RMM",      # 3-byte namespace — the branded-id kind gate
  ttl_ms: 30_000,   # base TTL for L2 and L1 expiry
  jitter: 0.1,      # 0.0..0.5 — ± band applied to ttl_ms for expiry spread
  max_size: 100_000, # row cap for L1
  sweep_ms: 1_000,  # tick between sweeper runs
  coherence: :none, # :none | :broadcast | :tracking
  counters: ...     # the atomic counter array
}
```

## The two tiers

**L1 — public, read-concurrent ETS.** Created at init:

```elixir
:ets.new(name, [:set, :public, :named_table, read_concurrency: true])
```

`:public` lets any process read; `:named_table` means you reference it by atom, not by a reference. Reads
happen in the **caller's own process** — no GenServer message, no mailbox, no serialization. That is the
performance property: a hit costs only a lookup, and reads scale with the number of schedulers.

Rows are `{id, value, expires_at, version}`. The `expires_at` field is a monotonic millisecond timestamp;
a row is valid while `System.monotonic_time(:millisecond) < expires_at`.

**L2 — the shared Valkey.** Addressed through `EchoStore.Keyspace.key/2`:

```elixir
# EchoStore.Keyspace — key/2
# Composes the full Valkey key for one cache entry.
# The table name is hashtagged: every key for one cache lands on one
# of 16384 Valkey Cluster slots (CRC16 of the brace bytes).
# The id is shape-checked before any key is composed — a malformed id
# raises ArgumentError here, never reaching the wire.
def key(table, id) when is_binary(table) and is_binary(id) do
  unless BrandedId.valid?(id) do
    raise ArgumentError, "invalid branded id in cache key position: #{inspect(id)}"
  end
  "ecc:{" <> table <> "}:" <> id
end
```

The `{table}` hashtag is the Valkey Cluster placement rule: CRC16 is computed over the bytes inside the
braces only, so every key of one cache hashes to the same slot. All of a cache's keys are co-located.

The prefix `ecc:` is fresh beside `emq:` — it never overlaps the bus's keyspace.

## The pattern ↔ implementation pairing

**Pattern:** cache-aside — the application, not the cache, manages the read-through logic. The cache is a
declared tier the application fills on a miss and invalidates on a write.

**Implementation:** `EchoStore.Table` is the declared tier. Its spec — kind, TTL, loader, coherence mode
— is registered in `EchoStore.Directory` at init. The application calls `fetch/3`, `put/3-4`, `invalidate/3`
on the declared name. The directory is the contract: what is declared is what exists.

## Recap

A cache is declared before it is used. Its spec — kind, TTL, jitter, max_size, loader, coherence mode — is
registered in the directory at init. The directory monitors the owner, so a crash removes the row. L1 is a
public ETS table reads happen in the caller's process. L2 is the shared Valkey, keyed `ecc:{table}:id` with
the table hashtagged for Cluster placement. The id is shape-checked before any key is composed.

## References

### Sources
- Erlang/OTP — the ets module: https://www.erlang.org/doc/apps/stdlib/ets.html
- Valkey — Cluster specification: https://valkey.io/topics/cluster-spec/
- Helland — Life Beyond Distributed Transactions: https://ics.uci.edu/~cs223/papers/cidr07p15.pdf
- Söderqvist — A new hash table (Valkey, 2025): https://valkey.io/blog/new-hash-table/

### Related in this course
- `/echomq/cache` — the Cache chapter landing
- `/echomq/cache/cache-aside-two-layers` — module hub
- `/echomq/protocol` — the branded-id gate
- `/bcs/store` — the BCS manuscript chapter
