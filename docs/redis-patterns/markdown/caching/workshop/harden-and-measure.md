# Harden and measure

> Route: `/redis-patterns/caching/workshop/harden-and-measure` · Module R1.07 · stage 3 of 3 · Source: none — a
> **capstone** dive synthesizing cache-stampede-prevention (R1.05) and hit-rate measurement applied to the Exchange
> Platform's instrument catalog; no single `content/…md.txt` author source. · Grounding: the single-flight `flights`
> map, the jittered TTL, and `EchoCache.Table.stats/1` (`echo/apps/echo_cache`).

The one instrument every order touches draws a herd when its row expires. EchoCache absorbs that herd by construction —
the single-flight `flights` map coalesces concurrent misses onto one fill, and a jittered TTL keeps a cohort from
expiring together — and `EchoCache.Table.stats/1` reads the hit rate off the cache's own counters. This is the final
stage. The deeper functional-Elixir and OTP craft behind the owner is [`/elixir`](/elixir).

## One fill per herd, by construction

A stampede — the thundering herd — happens when a popular key expires and every concurrent reader misses in the same
instant. Each miss would read the source, so the loader is hit once per reader at once. EchoCache closes that by
construction, not by a lock. Misses route through the table's owner, and concurrent misses on one id **coalesce** onto
a single flight: the first caller's miss launches `launch_flight/2`; a concurrent miss on the same id finds the flight
already in the `flights` map and joins its waiter list (`put_in(state.flights[id], {ref, [from | waiters]})`,
incrementing the `coalesced` counter). The flight checks L2, falls through to the loader, writes both layers, and the
owner replies to **every** waiter with the one answer.

The moduledoc states the law: *"Concurrent misses on a key coalesce onto a single in-flight load … every waiter reads
the one answer."* The committed gate proves it: two hundred concurrent cold readers, the loader runs once, one hundred
ninety-nine waiters coalesced, every reader holding the one answer. There is no `SET NX PX` lock here and none is
needed — the herd is absorbed by the owner's single-flight bookkeeping, not by a distributed mutex.

- the `flights` map — `id -> {ref, waiters}` in the owner's state; the first miss launches a flight, the rest join.
- `launch_flight/2` — the single flight: `GET ecc:{instruments}:<id>` → loader → `SET … PX`, then reply to all
  waiters.
- the `coalesced` counter — bumped for every miss that joins an in-flight load instead of launching its own.
- one answer — `Enum.each(waiters, &GenServer.reply(&1, reply))`: the herd costs one loader run.

## No synchronized expiry — the jittered clock

Rows filled together must not expire together, or the TTL itself schedules the next herd. `expires_at/1` draws each
row's expiry from `ttl ± ttl·jitter`: `base + :rand.uniform(2 * spread + 1) - spread - 1`, where `spread = trunc(ttl *
jitter)`. A cohort filled in the same instant spreads its expiries across a band, so the re-fill is a trickle, not a
herd. The committed gate shows it: four hundred rows filled in twenty-four milliseconds expire one hundred
thirty-eight milliseconds apart at jitter 0.2 — no synchronized re-herd. The sweeper then reclaims dead rows on a
fixed tick (`select_delete` of expired rows), so memory is bounded by the declaration, not by luck.

Set the jitter to the herd a surface fears: 0.1–0.2 spreads a cohort across a fifth of its TTL, enough to turn a
synchronized re-fill into a trickle. This is the honest mechanism EchoCache implements — expiry jitter plus
single-flight — not a probabilistic early-expiration scheme; the early-refresh variant of stampede prevention is the
R1.05 module's territory, and EchoCache's real answer is the jittered clock.

The herd is absorbed twice over: the single-flight coalesces a herd that has already formed, and the jittered TTL stops
a cohort from forming one on expiry. Neither is a lock; both are construction.

## Make the hit rate a number

A cache you cannot measure is a cache you cannot tune. `EchoCache.Table.stats/1` returns the counter snapshot plus the
live size: `hits, misses, fills, l2_hits, coalesced, swept, full_skips, sweeps, coh_applied, coh_stale`, and `size`.
Every counter is a `:counters` slot bumped on the hot path — atomic, lock-free, never a `GenServer.call`, which is why
a hit stays `762 ns`. The hit rate is a division: `hits / (hits + misses)` — the share of reads served without
touching the loader.

Run a read load below and watch the counters fill. The readout reports the `hits` and `misses` tallies, the hit rate
they compute, and the `coalesced` count under a herd. A hot instrument kept warm drives the rate up; a short TTL that
expires the row mid-load drives it down with extra misses; a herd shows up as `coalesced` waiters that cost no extra
loader run. The number tells the whole story: a high hit rate means the loader is shielded, a low one means the cache
is barely earning its place.

The counters turn the read path into a measured hit rate — `hits / (hits + misses)` — read off the cache's own
`:counters`, with `coalesced` proving the herd cost one load.

## Hardened and measured on EchoCache

Take one read of the hottest instrument under load: many orders hit the most-traded instrument as its row expires.
The owner receives a herd of misses on one id, coalesces them onto a single flight, and replies to every waiter with the
one answer — the loader ran once. Every read, hot or not, bumps `hits` or `misses`, so the catalog cache reports its
own hit rate through `stats/1`. The gateway receives the instrument or `{:error, :unknown_instrument}`; the
single-flight and the counters live in the cache. The deeper functional-Elixir and OTP craft of the owner is
[`/elixir`](/elixir).

```elixir
# Harden by construction + measure — the owner coalesces a herd, the counters report.
# Inside the owner, on a herd of misses for one id (echo_cache/table.ex:265):
case Map.fetch(state.flights, id) do
  {:ok, {ref, waiters}} ->                 # a flight is in progress: coalesce onto it
    :counters.add(state.spec.counters, counter(:coalesced), 1)
    {:noreply, put_in(state.flights[id], {ref, [from | waiters]})}

  :error ->                                # the first miss: launch the one flight
    ref = launch_flight(state, id)
    {:noreply, put_in(state.flights[id], {ref, [from]})}
end

# The hit rate, off the cache's own counters:
%{hits: h, misses: m, coalesced: c, size: n} = EchoCache.Table.stats(:instruments)
# hit_rate = h / (h + m)
```

The single-flight confines a hot regeneration to one loader run; the jittered TTL stops the cohort from re-herding;
the counters make the cache's effect a measured number. How the owner monitors a flight and replies to a crashed one
is [`/elixir`](/elixir), not repeated here. With this stage the catalog cache is cached, consistent, hardened, and
measured — the workshop's read path is complete.

**The pattern → EchoCache.** Prevent a stampede and measure the result: coalesce a herd onto one fill, spread the
expiry so a cohort never re-herds, and count every read. On the Exchange Platform the hottest instrument's herd
coalesces onto one `launch_flight`, the jittered TTL spreads the cohort, and `stats/1` reports `hits / (hits + misses)`
with `coalesced` proving the herd cost one load. Harden by construction, measure every read, and the catalog cache is
done.

## Recap — the read path is complete

The workshop's four layers are in place. Stage 1 cached the catalog with `EchoCache.Table.fetch/3`; stage 2 kept it
consistent with `Coherence.broadcast`/`enqueue` and `newer?`; this stage hardened the hot instrument with the
single-flight `flights` map and the jittered TTL, and measured the cache with `EchoCache.Table.stats/1`. The catalog
cache now reads through EchoCache, tracks changes, survives a herd on its busiest instrument by construction, and
reports its own hit rate — built entirely from patterns taught in R1.01–R1.06. Return to the hub to see the whole read
path assembled.

Back to [R1.07 · the Caching workshop](/redis-patterns/caching/workshop) for the assembled read path, or to the
[Caching chapter](/redis-patterns/caching) to revisit a pattern.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — `SET … PX` writes the L2 row with its jittered expiry in one atomic command; the second-layer half of the no-synchronized-expiry rule.
- [Valkey — EXPIRE](https://valkey.io/commands/expire/) — the server's own reclamation, the L2-side counterpart of the sweeper that bounds memory.
- [Redis — INCR](https://redis.io/commands/incr) — the atomic-counter primitive behind a measured hit rate; EchoCache keeps its tallies in lock-free `:counters`.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry, atomic operations, and single-instance discipline.

### Related in this course
- [R1.07 · Caching workshop](/redis-patterns/caching/workshop) — the workshop hub and the assembled read path.
- [R1.07.2 · Keep it consistent](/redis-patterns/caching/workshop/keep-it-consistent) — the previous stage.
- [R1.05 · Cache stampede prevention](/redis-patterns/caching/cache-stampede-prevention) — the herd, the lock-on-miss, and early refresh in depth.
- [R1.01 · Cache-aside](/redis-patterns/caching/cache-aside) — the base pattern.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/bcs](/bcs/cache/cache-aside) — the EchoCache manuscript: single-flight, jitter, and the gate.
