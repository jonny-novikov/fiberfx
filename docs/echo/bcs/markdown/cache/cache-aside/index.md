# B4.1 · Cache-Aside at ETS Speed

> Module hub · route `/bcs/cache/cache-aside` · teaches `content/bcs4.1.md` · rung record
> `bcs_rung_4_1_check.out`, `PASS 6/6` (E1–E6, with the header and the derive lines kept — they are part of
> the record).

The cache is declared, not discovered.

EchoCache opens with its floor: a declared L1 of ETS tables in front of the L2 Valkey the systems already
share, read at memory speed and filled under discipline. Three production modules land — the directory
(`EchoCache`), the keyspace (`EchoCache.Keyspace`), and the table (`EchoCache.Table`) — and the rung's
committed record gates the part's first two laws plus the machinery around them: the cache is declared, not
discovered; one fill per herd; jittered expiry; the sweeper; and a size bound that degrades to pass-through,
never to failure. The headline is the chapter's title made a number: `1311621 hit reads per second (762 ns
each)` against `31 us per L2 GET` on the same wire — the L1 hit is `40 times cheaper` than the round trip it
replaces.

Source: `content/bcs4.1.md`; the rung behind it is `bcs_rung_4_1_check.exs`, its committed transcript closes
`PASS 6/6` under the header `Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1`.

Interactive (hero): the six gates, mapped to the dives — E1 declared and E2 sources are dive 1's, E3 herd and
E4 speed are dive 2's, E5 jitter and E6 bound are dive 3's; selecting a gate reads its verbatim line and the
dive that teaches it.

## §1 Why a local copy must answer three questions

A trading read path is asymmetric in the extreme: a quote or a reference row is read thousands of times
between writes, and every read that crosses the wire pays the loopback floor — around 31 microseconds here,
multiplied by however many services ask. The first answer is the one this series has always given: put the
data behind its owner and read it locally. But a local copy raises the three questions every cache must answer
or be a liability — who knows this cache exists, what happens when a thousand readers miss at once, and when
do stale rows leave. This chapter answers all three with gates: a directory that makes every cache enumerable,
a single-flight fill that survives the herd by construction, and a jittered clock plus a sweeper that bound
both staleness and memory by declaration. Coherence sharper than TTL is Chapter 4.2's business; this chapter
builds the surface 4.2 will invalidate.

The decisions, from the chapter:

- **Declared, not discovered.** The directory is a monitored registry, not a convention: a table registers its
  full specification at start, and a crash removes it. Enumeration is the operator's right, and the negative
  is gated — an undeclared name answers `:error`.
- **The hit path never enters the owner.** Public ETS with `read_concurrency`, caller-side gate, atomic
  counters — the owner serializes only fills, puts, and invalidations. This is what makes 762 ns a hit (always
  beside its pair: 31 µs per L2 GET), and it is why stats ride `:counters` instead of `GenServer.call`.
- **Flights are processes, not owner code.** A slow loader blocks its own flight, never the owner. A crashed
  flight is a monitored event: every waiter gets a typed error, nobody hangs.
- **Values are binaries.** The L2 layer stores bytes; the L1 stores the same bytes. Term encoding is the
  application's decision at the edge, not the cache's opinion in the middle.
- **Full degrades to pass-through.** When the bound is reached and nothing has expired, a fill serves its
  caller and skips the insert. No eviction cleverness in this chapter: an LRU would tax every read with
  touch-tracking, and the read path's purity is the product.
- **Two clocks, again.** L1 expiry runs on the BEAM's monotonic clock; L2 expiry runs on the server's clock
  via `PX`. Each layer is sovereign over its own staleness — the series' two-clocks law, now in the cache.

## §2 The proof

The full committed record, verbatim — the header, six gates, three derive lines (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_1_check.out`):

```
header: Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1
E1 declared ok -- two caches enumerable with their full declarations -- kind, ttl, coherence -- an undeclared name answers :error, and a wrong-kind id is refused at the door: zero loader runs, zero keys on the wire
E2 sources ok -- one name, three sources in order: a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1 drop falls back to L2 -- the loader still ran once; the L2 row carries the declared TTL (PTTL 300 ms of 300)
derive (herd): 200 concurrent cold readers without single-flight run 200 loads; the law demands the misses coalesce onto one flight -- expect loader runs 1 and 199 coalesced waiters
E3 herd ok -- the thundering herd survived with one fill: 200 concurrent cold readers, loader runs 1, coalesced waiters 199, every reader holding the one answer
derive (speed): a hit is a caller-side lookup on a public read-concurrency set plus the kind gate and a counter bump -- expect 250,000 to 1,500,000 hit reads per second on this core; an L2 GET pays a loopback round trip, and Appendix A committed 29,456 sequential round trips per second, near 34 us each -- expect the L1 hit at least 10 times cheaper than the wire
E4 speed ok -- measured: 1311621 hit reads per second (762 ns each) against 31 us per L2 GET on the same wire -- the L1 hit is 40 times cheaper than the round trip it replaces, inside the derived band
derive (jitter): ttl 300 ms at jitter 0.2 spreads expiry uniformly across plus-minus 60 ms -- 400 rows filled in one fast pass should spread at least 70 ms beyond their fill walltime, approaching 120; a jitter 0.0 cohort's spread can never exceed its own fill walltime -- jitter adds nothing; the sweeper on a 100 ms tick then reclaims the whole cohort without a single read
E5 jitter ok -- 400 rows filled in 24 ms expire 138 ms apart at jitter 0.2 -- no synchronized re-herd -- while the jitter 0.0 cohort spreads 5 ms across a 4 ms fill: jitter added nothing there; the sweeper then reclaimed the whole cohort on its tick (swept 400, table size 0) with not one read paying the cleanup
derive (bound): refdata declares max_size 100 with a 60 s ttl, so nothing expires to reclaim -- 49 more fills fit beside the 51 live rows, then every further fill must serve its caller and skip the insert
E6 bound ok -- the declaration holds: size capped at 100 of 100, 101 fills served their callers and skipped the insert -- a full cache is a stat, never an error -- and the writer path lands one value in both layers
PASS 6/6
```

The record's derive lines are part of the discipline: each measurement is bounded before it is taken, and the
committed line then lands inside its own band. The system lives in its own directory beside the bus:
`runtimes/elixir/lib/echo_cache/echo_cache.ex`, `lib/echo_cache/keyspace.ex`, `lib/echo_cache/table.ex`. Its
keyspace is its own — `ecc:{<table>}:<id>`, "a fresh prefix beside `emq:`, never inside it" — and its wire is
the production connector, "reused untouched"; the manuscript plans the connector's prose appendix.

## §3 The dives

- **B4.1.1 · Declared, Not Discovered** (`declared-not-discovered`) — E1: the monitored directory, "two caches
  enumerable with their full declarations -- kind, ttl, coherence"; the wrong-kind refusal at the door. E2:
  three sources of one answer — L1, L2 with `PTTL 300 ms of 300`, the loader once.
- **B4.1.2 · One Fill per Herd** (`one-fill-per-herd`) — E3: the herd drill, "200 concurrent cold readers,
  loader runs 1, coalesced waiters 199"; singleflight as the named prior art. E4: the speed — `1311621 hit
  reads per second (762 ns each)` against `31 us per L2 GET`, "40 times cheaper".
- **B4.1.3 · The Jittered Clock** (`the-jittered-clock`) — E5: "400 rows filled in 24 ms expire 138 ms apart
  at jitter 0.2", the zero-jitter control, the sweeper's `swept 400, table size 0`. E6: the bound — "size
  capped at 100 of 100, 101 fills served their callers and skipped the insert".

The module hands forward: **B4.2 · Coherence by Mint Time** inherits `invalidate/2` as the hook its coherence
messages will pull, and the declared `coherence:` mode it will wire. And the manuscript plans the referee
chapter — **B4.5 · The Cache Referee** — to hold the comparison set to this module's drills.

## References

Sources:

- Erlang/OTP — ets — https://www.erlang.org/doc/apps/stdlib/ets.html (public `read_concurrency` tables for
  caller-side hits; `select_delete` as the sweeper's one-pass reclaim)
- Valkey — SET — https://valkey.io/commands/set/ (the `PX` option: the L2 row written with its expiry in one
  command)
- Valkey — EXPIRE — https://valkey.io/commands/expire/ (expiration semantics and the server's two reclamation
  paths, on-access and active cycles — the L2-side counterpart of the sweeper)
- Go x/sync — singleflight — https://pkg.go.dev/golang.org/x/sync/singleflight (duplicate function call
  suppression: the named prior art for one fill per herd)

Related:

- /bcs/cache — B4 · EchoCache, the chapter landing; Part IV's arc
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, which wires this module's `coherence: :none`
- /bcs/bus — B3 · The Bus, the bus beside which the cache lives
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the keyspace discipline `ecc:` sits beside
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the stores being cached
- /redis-patterns — Redis Patterns Applied, the caching substrate patterns
- /echomq — EchoMQ, the bus protocol in rung-level depth
- /elixir — Functional Programming in Elixir, the umbrella the runtimes live in

Pager: previous `/bcs/cache` · next `/bcs/cache/cache-aside/declared-not-discovered`.
