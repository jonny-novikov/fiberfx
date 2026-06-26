# The full cache degrades

**Route:** `/echomq/cache/single-flight-and-jittered-ttl/the-full-cache-degrades`  
**Module:** Single-flight & jittered TTL · dive 03  
**Grounding:** `echo/apps/echo_store/lib/echo_store/table.ex` — `insert/4` + `reclaim/1` + `stats/1`.

## The third guarantee

A near-cache can fill. When it does, two choices exist: refuse the insert and return an error to the caller,
or skip the insert and serve the caller anyway from L2 and the loader. `EchoStore.Table` takes the second
path: a full cache **degrades to pass-through, it never fails**.

## `insert/4` — the three-branch decision

Every time a flight completes or a `put/3-4` call writes through, the result is handed to `insert/4`:

```elixir
# insert/4 — three outcomes: insert, reclaim-then-insert, or skip
# The ETS row shape is: {id, value, expires_at, version}
defp insert(state, id, value, version) do
  size = :ets.info(state.name, :size)

  cond do
    # Fast path: the table has room — insert directly.
    size < state.spec.max_size ->
      :ets.insert(state.name, {id, value, expires_at(state.spec), version})

    # Slow path: the table is full, but expired rows may have accumulated
    # since the last sweep. reclaim/1 runs a select_delete right now;
    # if it freed at least one slot, insert into the newly vacated space.
    reclaim(state) > 0 ->
      :ets.insert(state.name, {id, value, expires_at(state.spec), version})

    # Degrade path: the table is full and no expired rows exist.
    # Skip the L1 insert; count the skip; return :skip (not an error).
    true ->
      :counters.add(state.spec.counters, counter(:full_skips), 1)
      :skip
  end
end
```

The caller — `handle_info({:flight, …})` or `handle_call({:put, …})` — replies to waiters with the result
regardless of whether the insert succeeded. A `:skip` means the caller's value is in L2 (or returned
from the loader directly) and the next read will find it there, not in L1. The read path degrades too: it
misses L1, falls through to L2, gets the value, and re-attempts the insert on the way back. Under sustained
pressure the table operates as a straight-through L2 cache.

## `reclaim/1` — on-demand sweep

`reclaim/1` is the same `ets.select_delete` the scheduled sweeper uses, but called inline when the table
is full:

```elixir
# reclaim/1 — a sweep-on-demand when the table is at max_size
# Returns the number of rows deleted; > 0 means space was freed.
defp reclaim(state) do
  now = System.monotonic_time(:millisecond)
  :ets.select_delete(state.name, [{{:_, :_, :"$1", :_}, [{:<, :"$1", now}], [true]}])
end
```

It returns the count of removed rows. If that count is `> 0`, `insert/4` proceeds. If it is `0`, the
table is genuinely full of live rows and the insert is skipped.

## `stats/1` — the live counter snapshot

```elixir
# stats/1 — the counter snapshot plus the live ETS table size
# Counters are updated atomically by :counters.add throughout the GenServer.
def stats(name) do
  {:ok, spec} = EchoStore.spec(name)

  @counters
  |> Map.new(fn {k, i} -> {k, :counters.get(spec.counters, i)} end)
  |> Map.put(:size, :ets.info(name, :size))
end
```

The returned map carries: `hits`, `misses`, `fills`, `l2_hits`, `coalesced`, `swept`, `full_skips`,
`sweeps`, and the live `:size`. These are the eight counters taught in this module; `coh_applied` and
`coh_stale` belong to module 03's coherence law.

## The version on every row

Each row in the ETS table is `{id, value, expires_at, version}` — the 14-byte mint-time version is stored
alongside the value. That version is the seed of module 03 (Coherence — newer wins on the Bus): when a
coherence message arrives with a newer version, the row can be dropped with no coordinator and no external
lock, because the comparison is between two time-ordered branded ids. The version is already there; module
03 teaches what to do with it.

## Pattern ↔ implementation

**The pattern (graceful degradation):** a bounded cache that cannot accept a new entry should degrade
gracefully — serve the read from the backing store, not refuse it — so the service remains available under
memory pressure.

**The implementation (EchoStore.Table):** `insert/4` tries three paths in order: direct insert, reclaim
then insert, skip and count. A skip is not an error; the caller already has the value. The `:full_skips`
counter tracks how often the cache is operating in pass-through mode.

## Recap

`insert/4` is the boundary that keeps a full table from becoming a hard failure: it tries to make room
(reclaim), and if it cannot, it skips the L1 write and lets the caller proceed with the value from L2 or
the loader. The stats surface makes the degrade rate visible — `full_skips / (fills + full_skips)` is the
fraction of fills that did not land in L1. Module 03 (Coherence) turns the `version` field on every live
row into the hook for a newer-wins eviction without a coordinator.

## References

### Sources
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — `ets.info(:size)` and `ets.select_delete` underpin both `insert/4` and `reclaim/1`.
- [Valkey — GET](https://valkey.io/commands/get/) — the L2 read a pass-through falls back to.
- [Söderqvist — A new hash table (Valkey, 2025)](https://valkey.io/blog/new-hash-table/) — the L2 the pass-through falls to, costed at rest.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the version field every row stores alongside its value.

### Related in this course
- `/echomq/cache` — the Cache chapter landing.
- `/echomq/cache/single-flight-and-jittered-ttl` — this module's hub.
- `/echomq/cache/single-flight-and-jittered-ttl/jittered-expiry` — the sweeper that `reclaim/1` mirrors on-demand.
- `/bcs/store` — the manuscript chapter: B4 EchoStore, the declared near-cache.
- `/echomq/bus` — the wire a coherence message (module 03) broadcasts over.
