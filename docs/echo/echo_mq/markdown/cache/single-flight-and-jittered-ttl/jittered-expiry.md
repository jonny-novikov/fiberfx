# Jittered expiry

**Route:** `/echomq/cache/single-flight-and-jittered-ttl/jittered-expiry`  
**Module:** Single-flight & jittered TTL · dive 02  
**Grounding:** `echo/apps/echo_store/lib/echo_store/table.ex` — `expires_at/1` + `handle_info(:sweep)`.

## The jitter problem

When a collection of keys is filled together — a cohort from a bulk loader, a set of items fetched on the
same request — they share the same `monotonic_ms + ttl_ms` expiry if TTL is fixed. At that moment every
row in the cohort expires together and every caller that reads any of them gets a miss simultaneously. A
thundering herd forms at the first miss and repeats at the TTL boundary: the same herd, on a timer.

Jitter breaks the synchrony. Each row's expiry is drawn from a uniform band around the declared TTL so
the cohort spreads its deaths across time.

## `expires_at/1`

```elixir
# expires_at/1 — a uniform ± spread around the declared TTL
# spec.jitter is in 0.0..0.5 (enforced at init)
defp expires_at(spec) do
  base   = System.monotonic_time(:millisecond) + spec.ttl_ms
  spread = trunc(spec.ttl_ms * spec.jitter)    # how far from base to allow

  if spread == 0 do
    base          # jitter 0.0 → exactly TTL, no randomness
  else
    # :rand.uniform(n) returns 1..n; this shifts that range to -spread..(spread-1)
    # so the result is base - spread .. base + spread (approximately)
    base + :rand.uniform(2 * spread + 1) - spread - 1
  end
end
```

With `ttl_ms = 10_000` and `jitter = 0.2`, `spread = 2_000`. The expiry for any single row is drawn
uniformly from `base - 2000 .. base + 2000`. A cohort of 100 rows filled at the same millisecond will
have its expirations spread across a 4-second window, not stacked at one tick.

## The sweeper

Jitter alone is not enough: rows that have expired are not automatically removed from the ETS table — ETS
has no built-in TTL eviction. The sweeper closes the loop.

```elixir
# handle_info(:sweep) — the periodic eviction pass
# Deletes every row whose expires_at (field 3, index $1) is before now.
# Counts both the rows removed (:swept) and the number of sweeps (:sweeps).
# Re-arms itself for the next tick every time it runs.
def handle_info(:sweep, state) do
  now = System.monotonic_time(:millisecond)

  removed =
    :ets.select_delete(state.name, [
      # match spec: {id, value, expires_at, version}
      # guard: expires_at < now
      {{:_, :_, :"$1", :_}, [{:<, :"$1", now}], [true]}
    ])

  :counters.add(state.spec.counters, counter(:swept), removed)
  :counters.add(state.spec.counters, counter(:sweeps), 1)
  Process.send_after(self(), :sweep, state.spec.sweep_ms)  # re-arm
  {:noreply, state}
end
```

The sweeper is armed once at `init/1` with `Process.send_after(self(), :sweep, sweep_ms)` and re-arms
itself after each pass. Memory is bounded by the declaration: a table declared with `sweep_ms: 1_000` and
`ttl_ms: 60_000` will never accumulate more than approximately `max_size` rows older than `ttl_ms + jitter*ttl_ms`.

## Pattern ↔ implementation

**The pattern (jittered TTL):** add a random offset to each item's expiry so a cohort that was populated
together expires at different times, preventing the mass-miss that causes a thundering herd at the boundary.

**The implementation (EchoStore.Table):** `expires_at/1` draws from `ttl ± spread` (`spread = ttl · jitter`)
using `:rand.uniform`. The sweeper runs on a fixed tick (`sweep_ms`) and uses `ets.select_delete` with a
guard on the `expires_at` field — no per-row timer, no extra process per entry.

## Recap

Two functions bound the cohort problem: `expires_at/1` spreads each row's death across a jitter band, and
`handle_info(:sweep)` removes dead rows on a fixed tick. Together they ensure that a cache under steady load
neither stampedes at a TTL boundary nor grows without bound between sweeps. The `:swept` and `:sweeps`
counters in `stats/1` make both rates observable.

## References

### Sources
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — `ets.select_delete` with a match spec is the sweeper's primitive.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the hashtag discipline the keyspace uses.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the version field the row carries alongside its expiry.

### Related in this course
- `/echomq/cache` — the Cache chapter landing.
- `/echomq/cache/single-flight-and-jittered-ttl` — this module's hub.
- `/echomq/cache/single-flight-and-jittered-ttl/one-fill-per-herd` — the coalescing law that `expires_at/1` feeds.
- `/redis-patterns/caching` — R1 caching: the TTL-staleness and stampede patterns this dive applies.
