# Caching workshop — cache codemojex's emoji set

> Route: `/redis-patterns/caching/workshop` · Module R1.07 (the chapter capstone) · Source: none — this is a
> **capstone** that synthesizes the chapter's patterns (cache-aside R1.01 + write-through R1.02 +
> cache-stampede-prevention R1.05, applied) over codemojex's emoji set, so it has no single
> `content/…md.txt` author source. · Grounding: EchoStore in front of the codemojex consumer
> (`echo/apps/echo_store`, `echo/apps/codemojex`).

The chapter capstone: take the six patterns and put EchoStore in front of one real consumer read — codemojex's
emoji set. The earlier modules each taught one move; this workshop assembles them. Across three stages it caches the
emoji set `Codemojex.Guesses.submit/3` checks every guess against, keeps that cache consistent when a room's set
changes, then hardens the set every guess touches against a stampede and reads the hit rate off the cache's own
counters. The grounding is the real as-built `EchoStore.Table` in front of `Codemojex.Cache` — the engine is Valkey,
the consumer is `echo/apps/codemojex`. The deeper functional-Elixir and OTP craft behind the echo data layer is
[`/elixir`](/elixir).

This workshop assumes the chapter so far — **R1.01–R1.06**: cache-aside, write-through, write-behind, client-side
caching, stampede prevention, and sessions. It reuses only patterns taught there; nothing new is introduced.

## The consumer — what the cache reads

codemojex validates every guess against the round's emoji set. `Codemojex.Guesses.submit/3`
(`echo/apps/codemojex/lib/codemojex/game.ex`) turns an untrusted guess into a branded `JOB` on the player's lane or
one closed error, and one of the first checks is the keyboard: it calls `Codemojex.Cache.fetch_set(set_id)` and runs
`EmojiSet.valid_guess?/2`, answering `{:error, :bad_guess}` for a code the round's keyboard does not expose. That
emoji set is reference data — read on every guess, immutable for the round's life — which is exactly the read-heavy,
write-light shape cache-aside is built for. Fronting it with `EchoStore.Table` is the workshop.

The cache read path stacks four layers, each adding one move taught earlier in the chapter, and each leaving the
read correct on its own:

- The base layer is a **cache-aside read**: `EchoStore.Table.fetch/3` checks L1 ETS, then on a miss runs a
  single-flight fill — `GET ecc:{cm_emojisets}:<id>`, the loader, then `SET … PX`. `fetch/3` returns
  `{:ok, value, source}` with source `:hit | :l2 | :fill`.
- The next layer keeps the cache **consistent**: a room's emoji set changing runs coherence — `Coherence.broadcast/4`
  on the fast lane, `Coherence.enqueue/5` on the at-least-once job lane — and `Coherence.newer?/2` resolves a late
  message newer-wins.
- The third layer **hardens** the set every guess touches. EchoStore already does this by construction: the
  single-flight `flights` map coalesces a herd onto one fill, and a jittered TTL (`ttl ± ttl·jitter`) keeps a cohort
  from expiring together.
- The fourth layer **measures**: `EchoStore.Table.stats/1` returns the counter snapshot — `hits, misses, fills,
  l2_hits, coalesced, swept, full_skips, sweeps, coh_applied, coh_stale` plus live `size`. The hit rate is a number,
  not a guess.

Nothing here is new. Each layer is a pattern from R1.01–R1.06, applied to one real surface. The work of the workshop
is the assembly — the order the layers stack, and the choices each one forces.

The cache read path is cache-aside at the base, with three layers stacked on top: keep it consistent on a change,
let the single-flight and jitter absorb a herd, and read the hit rate off the counters. Each layer is one move from
earlier in the chapter.

## The three stages

The workshop is three dives. Each takes one layer and builds it on the real consumer surface, ending with the read
path one step closer to production. Take them in order: the cache must exist before it can be kept consistent, and it
must be consistent before its hit rate means anything.

- **R1.07.1 · Cache the catalog** — wire `EchoStore.Table.fetch/3` over the emoji set: an L1 ETS hit, else a
  single-flight fill (`GET ecc:{cm_emojisets}:<id>` → loader → `SET … PX`). The base read path.
- **R1.07.2 · Keep it consistent** — when a room's emoji set changes, drop the L1 row and resolve newer-wins:
  `Coherence.broadcast/4` (fast, at-most-once) or `Coherence.enqueue/5` (the job lane, at-least-once), with
  `Coherence.newer?/2` the comparison. Choose the lane each surface needs.
- **R1.07.3 · Harden and measure** — the single-flight `flights` map and the jittered TTL absorb a herd by
  construction, and `EchoStore.Table.stats/1` reads the hit rate off the counters.

## Walk the build

Pick a stage to see which `EchoStore` surface it adds to the read path and what the cache can do once it lands. The
surface grows as the stages stack; the readout names the new calls and the property the layer secures.

- **Stage 1 (cache the catalog)** — adds `fetch/3` (with `launch_flight`: `GET … → loader → SET … PX`). Surface so
  far: `fetch/3`. Gains a cache-aside read of the emoji set at ETS speed, returning `:hit | :l2 | :fill`.
- **Stage 2 (keep it consistent)** — adds `Coherence.broadcast/4` / `Coherence.enqueue/5` and `Coherence.newer?/2`.
  Surface so far: `fetch/3` + coherence. Gains version-safe invalidation on a change, on a fast or durable lane.
- **Stage 3 (harden and measure)** — adds `stats/1` over the single-flight and jittered TTL already in `fetch/3`.
  Surface so far: `fetch/3` + coherence + `stats/1`. Gains a herd-safe read path and a measured hit rate.

**The pattern → EchoStore.** The assembled read path — cache-aside at the base, coherence on a change, single-flight
and jitter under a herd, and counters reporting the hit rate — is `EchoStore.Table` in front of codemojex's emoji
set: `fetch` fills on a miss, `broadcast`/`enqueue` keep it consistent, the jittered TTL and single-flight absorb a
herd, and `stats` reports the hit rate. Three stages, four layers, one read path. The workshop turns the chapter's
patterns into a real consumer's reference cache — cached, consistent, hardened, and measured.

## A measured floor

The numbers the workshop reproduces are committed, from the EchoStore gate against live Valkey: an L1 ETS hit at
`762 ns` against a `31 us` L2 GET — `40 times cheaper` — and coherence priced lane by lane, the broadcast lane at
`72 us` against the job lane at `148 us`, `2.1 times` the latency for at-least-once delivery. Those are the figures
the assembled read path stands on; the dives reproduce them.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — `SET … PX` sets a value and its expiry in one atomic command; the L2 fill of every cache layer.
- [Valkey — Topics](https://valkey.io/topics/) — the engine the EchoStore gate is measured against, Valkey.
- [Redis — Documentation](https://redis.io/docs/) — strings, expiry, and counters — the command families the read path is built from.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry, atomic operations, and treating cached values as a disposable copy.
- [Answer.AI — The /llms.txt convention](https://llmstxt.org/) — the machine-readable map convention this course follows for agent readers.

### Related in this course
- [R1.07.1 · Cache the catalog](/redis-patterns/caching/workshop/cache-the-catalog) — the base read path.
- [R1.07.2 · Keep it consistent](/redis-patterns/caching/workshop/keep-it-consistent) — coherence and the lane choice.
- [R1.07.3 · Harden and measure](/redis-patterns/caching/workshop/harden-and-measure) — single-flight, jitter, and the counters.
- [R1.01 · Cache-aside](/redis-patterns/caching/cache-aside) — the base pattern.
- [R1.02 · Write-through](/redis-patterns/caching/write-through) — the consistency-first alternative.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq/cache](/echomq/cache) — the EchoStore near-cache, in depth.
- [/bcs](/bcs/cache) — the EchoStore manuscript, Part IV.
