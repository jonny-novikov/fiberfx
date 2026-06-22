# Probabilistic early refresh

> Route: `/redis-patterns/caching/cache-stampede-prevention/early-refresh` · Module R1.05 · dive 2 · Source:
> `content/fundamental/cache-stampede-prevention.md.txt` (*Solution 1: Probabilistic Early Expiration (X-Fetch)* — How
> It Works · The Algorithm · Outcome) · Grounding: EchoCache's jittered TTL `expires_at/1`
> (`echo/apps/echo_cache/lib/echo_cache/table.ex`). **Honest framing:** X-Fetch is taught as the pattern; the applied
> mechanism EchoCache really runs is expiry jitter, not probabilistic early expiration.

No lock, no waiting. Each read may rebuild the key early, with a chance that rises as the TTL nears zero, so one
request refreshes moments before it would expire. Probabilistic early expiration — X-Fetch — decouples logical expiry
from physical expiry.

## Logical expiry, not physical

Plain cache-aside sets a physical TTL: at the deadline the key vanishes and the next read misses. X-Fetch keeps a
physical TTL too, but treats it as a *logical* deadline the value tries to beat. The trick is to refresh ahead of the
deadline — while the key is still present and serving — so the key never has to physically expire under load.

To decide when, each read needs two facts stored alongside the value: the time the value was last computed, and how
long that computation took (call it `delta`). The first gives the time remaining before expiry; the second sizes the
head start a refresh needs, because a value that takes longer to rebuild should start rebuilding earlier. The outcome
is statistical, not coordinated: out of thousands of reads approaching the deadline, the formula makes it
overwhelmingly likely that exactly one fires the early rebuild, and the rest carry on serving the fresh value.

## The X-Fetch formula

The decision is the one the source gives. A read triggers a refresh when:

```
# refresh early when this is true:
now - delta * beta * log(rand()) >= expiry
# equivalently, refresh when now is within  delta * beta * (-log(rand))  of expiry
```

The pieces: `delta` is the time the last regeneration took; `beta` is a tuning factor, conventionally 1.0; and
`rand()` is a fresh uniform draw in the open interval (0, 1). Because `rand()` is below 1, `log(rand())` is negative,
so `delta * beta * log(rand())` subtracts a positive margin from `expiry` — it brings the effective deadline
*earlier* by a random amount.

When the key is fresh, `now` is far below `expiry`, and only an extreme random draw (a very small `rand`, giving a
large margin) clears the threshold — so a refresh is rare. As `now` nears `expiry`, an ever-larger share of random
draws clear it, and the refresh probability climbs toward one. Raising `beta` shifts the whole curve earlier; a
larger `delta` — a costlier rebuild — also refreshes earlier, giving the slow rebuild the head start it needs.

The formula is a probability, so on rare runs two requests refresh, or a run of unlucky draws lets the key physically
expire and falls back to a normal miss. That is why X-Fetch is often paired with a mutex fallback for the hard miss —
the recommendation the module closes on.

## Outcome

Instead of thousands of simultaneous source reads at expiration, a single request refreshes the cache moments before
expiration while all others continue serving cached data. The traffic spike is smoothed into a single early rebuild,
at the cost of one or two source reads and a brief, bounded staleness window — and with no lock and no waiting.

## On EchoCache — jitter, not XFetch

Here the honesty matters. EchoCache does **not** implement the probabilistic XFetch rule above — there is no
`now - delta·beta·log(rand)` test in the code, and this dive does not claim one. What EchoCache runs against the same
problem — a cohort that expires together and re-herds — is **expiry jitter**. Every row draws its expiry from
`ttl ± ttl·jitter`:

```elixir
defp expires_at(spec) do
  base = System.monotonic_time(:millisecond) + spec.ttl_ms
  spread = trunc(spec.ttl_ms * spec.jitter)

  if spread == 0 do
    base
  else
    base + :rand.uniform(2 * spread + 1) - spread - 1
  end
end
```

The moduledoc states the goal directly: *"Rows expire on a jittered clock — `ttl ± ttl·jitter` — so a cohort filled
together never expires together."* The two ideas share an aim — stop a synchronized expiry from creating the herd —
but reach it differently: X-Fetch refreshes one read *before* the deadline; jitter *spreads the deadlines* so no two
rows of a cohort hit it at once. The L2 row carries its expiry on the server's own clock, written with `SET ... PX`
so Valkey expires it even if every node forgets. The functional-Elixir & OTP craft behind the echo data layer — the
sweeper tick, `:rand.uniform`, the monotonic clock — is the [`/elixir` course](/elixir/pragmatic/state).

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — `PX` for the jittered millisecond TTL EchoCache writes to L2.
- [Redis — TTL](https://redis.io/commands/ttl) — the remaining time-to-live X-Fetch inspects to size the gap to expiry.
- [Redis — Documentation](https://redis.io/docs/) — key expiry and the string commands that store the value with its timestamp and delta.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry, eviction, and smoothing regeneration load.

### Related in this course
- [R1.05 · Cache stampede prevention](/redis-patterns/caching/cache-stampede-prevention) — the module hub.
- [R1.05.1 · Lock-on-miss](/redis-patterns/caching/cache-stampede-prevention/lock-on-miss) — the deterministic alternative and the X-Fetch fallback.
- [R1.05.3 · Request coalescing](/redis-patterns/caching/cache-stampede-prevention/coalescing) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under the Exchange Platform.
- [/echomq](/echomq) — the EchoMQ protocol behind the cache's coherence lane.
