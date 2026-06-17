# BCS · Chapter 4.1 — Cache-Aside at ETS Speed

<show-structure depth="2"/>

EchoCache opens with its floor: a declared L1 of ETS tables in front of the L2 Valkey the systems already share, read at memory speed and filled under discipline. Three production modules land — the directory (`EchoCache`), the keyspace (`EchoCache.Keyspace`), and the table (`EchoCache.Table`) — and the rung's committed record (`bcs_rung_4_1_check.out`, `PASS 6/6`) gates the part's first two laws plus the machinery around them: the cache is declared, not discovered; one fill per herd; jittered expiry; the sweeper; and a size bound that degrades to pass-through, never to failure. The headline is the chapter's title made a number: `1311621 hit reads per second (762 ns each)` against `31 us per L2 GET` on the same wire — the L1 hit is `40 times cheaper` than the round trip it replaces.

## Why

A trading read path is asymmetric in the extreme: a quote or a reference row is read thousands of times between writes, and every read that crosses the wire pays the loopback floor — around 31 microseconds here, multiplied by however many services ask. The first answer is the one this series has always given: put the data behind its owner and read it locally. But a local copy raises the three questions every cache must answer or be a liability — who knows this cache exists, what happens when a thousand readers miss at once, and when do stale rows leave. The comparison set's answers are partial; Part IV's preface named the gap. This chapter answers all three with gates: a directory that makes every cache enumerable, a single-flight fill that survives the herd by construction, and a jittered clock plus a sweeper that bound both staleness and memory by declaration. Coherence sharper than TTL is Chapter 4.2's business; this chapter builds the surface 4.2 will invalidate.

## What

**The declaration.** A cache comes into existence by declaring itself: name, kind, TTL, jitter, size bound, sweep interval, and coherence mode, registered in the node's directory the moment the table starts and removed the moment it stops or crashes — the directory monitors its tables, so the roster is true even after a failure. The committed gate: `two caches enumerable with their full declarations -- kind, ttl, coherence -- an undeclared name answers :error`. The kind law stands at the door exactly as it stands at every door in this series: `a wrong-kind id is refused at the door: zero loader runs, zero keys on the wire`.

**Three sources of one answer.** A read resolves from L1, L2, or the declared loader, in that order, and the record walks one name through all three: `a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1 drop falls back to L2 -- the loader still ran once`. The L2 row carries the declared TTL on the server's own clock — `PTTL 300 ms of 300` — written with `SET ... PX` so the second layer expires itself even if every node forgets [2].

**One fill per herd.** Misses route through the table's owner, and concurrent misses on one key coalesce onto a single flight — the first caller's flight checks L2, falls through to the loader, writes both layers, and the owner replies to every waiter with the one answer. The drill is the gate: `200 concurrent cold readers, loader runs 1, coalesced waiters 199, every reader holding the one answer`. The pattern has a name in the Go world — singleflight, "a duplicate function call suppression mechanism" [4] — and Chapter 4.5's referee will hold the comparison set to this drill.

**Hits at ETS speed.** The read path never enters the owner's process: a hit is a caller-side lookup against a public, read-concurrency ETS table [1], plus the kind gate and one atomic counter bump. Derived first — between 250,000 and 1,500,000 reads per second on this core — then measured: `1311621 hit reads per second (762 ns each) against 31 us per L2 GET on the same wire -- the L1 hit is 40 times cheaper than the round trip it replaces, inside the derived band`. The owner is consulted only when there is owner's work to do; that is the whole architecture.

**The jittered clock and the sweeper.** Rows filled together must not expire together, or the TTL itself schedules the next herd. Every insert draws its expiry from `ttl ± ttl·jitter`, and the committed drill shows the spread doing its work: `400 rows filled in 24 ms expire 138 ms apart at jitter 0.2 -- no synchronized re-herd`, while the zero-jitter cohort spreads only its own fill walltime — jitter added nothing there, which is the control that proves the treatment. The sweeper then reclaims on its tick — `swept 400, table size 0` — so dead rows leave whether or not anyone reads them again; Valkey does the same on its side with on-access and active expiration [3], two layers each keeping their own house.

**The bound.** A full cache is a stat, never an error. With `max_size 100` declared and nothing expired to reclaim, the record shows `size capped at 100 of 100, 101 fills served their callers and skipped the insert` — every caller got its value, the table held its declaration, and the overflow is visible in `full_skips` rather than in anyone's latency alarm.

## Who

Readers, who get memory-speed quotes and reference data without knowing the cache exists — `fetch/2` is the whole surface, and the source tag (`:hit | :l2 | :fill`) is observability, not ceremony. Operators, for whom `EchoCache.tables/0` is the law made callable: every cache on the node, with its full declaration, and nothing else — a cache absent from the directory does not exist. Chapter 4.2, which inherits `invalidate/2` as the hook its coherence messages will pull, and the declared `coherence:` mode it will wire. And the herd itself: two hundred simultaneous cold readers at the open are the normal case in this domain, and the gate says they cost one load.

## When

Declare a cache when a surface is read-heavy and tolerant of bounded staleness — quotes on a human-facing screen, reference data, anything where the TTL is a product decision rather than a correctness hazard. Read the store directly when a stale answer costs money; Chapter 4.2 narrows that category, but TTL-only caching never serves it. Size the jitter to the herd you fear: 0.1–0.2 spreads a cohort across a fifth of its TTL, which is enough to turn a synchronized re-fill into a trickle. And do not cache what the loader cannot reproduce — a loader error is returned, not stored, so a broken upstream surfaces immediately instead of being memorized.

## Where

The system lives in its own directory beside the bus: `runtimes/elixir/lib/echo_cache/echo_cache.ex` (the facade and the monitored directory), `lib/echo_cache/keyspace.ex`, and `lib/echo_cache/table.ex`. Its keyspace is its own — `ecc:{<table>}:<id>`, a fresh prefix beside `emq:`, never inside it, hashtagged on the table name for the clustered day — and its wire is the Appendix B production connector, reused untouched. The rung and its committed record sit with the others: `bcs_rung_4_1_check.exs`, `bcs_rung_4_1_check.out`.

## How — declaring and reading

**A quote cache, declared:**

```elixir
{:ok, _} =
  EchoCache.Table.start_link(
    name: :quotes,
    kind: "AST",
    ttl_ms: 300,
    jitter: 0.2,
    sweep_ms: 100,
    coherence: :none,          # wired by Chapter 4.2
    loader: &PriceFeed.load/1,
    connector: [port: 6390]
  )
```

**The read path, and the roster:**

```elixir
{:ok, quote, :hit} = EchoCache.Table.fetch(:quotes, "AST0NuE6bV7FoH")

EchoCache.tables()
# [{:quotes, %{kind: "AST", ttl_ms: 300, jitter: 0.2, coherence: :none, ...}}, ...]
```

**Go.** The port's fill discipline already has its idiom — `golang.org/x/sync/singleflight` is one-fill-per-herd as a library [4] — and the L1 is a map behind a `sync.RWMutex` or a sharded store; the contract that travels is the same as everywhere in this series: the `ecc:` key shapes, the kind gate, and the drill list of this rung's six gates.

## Decisions

**Declared, not discovered.** The directory is a monitored registry, not a convention: a table registers its full specification at start, and a crash removes it. Enumeration is the operator's right, and the negative is gated — an undeclared name answers `:error`.

**The hit path never enters the owner.** Public ETS with `read_concurrency`, caller-side gate, atomic counters — the owner serializes only fills, puts, and invalidations. This is what makes 762 ns a hit, and it is why stats ride `:counters` instead of `GenServer.call`.

**Flights are processes, not owner code.** A slow loader blocks its own flight, never the owner — other keys keep filling, puts keep landing. A crashed flight is a monitored event: every waiter gets a typed error, nobody hangs.

**Values are binaries.** The L2 layer stores bytes; the L1 stores the same bytes. Term encoding is the application's decision at the edge, not the cache's opinion in the middle.

**Full degrades to pass-through.** When the bound is reached and nothing has expired, a fill serves its caller and skips the insert. No eviction cleverness in this chapter: an LRU would tax every read with touch-tracking, and the read path's purity is the product. Smarter eviction, if ever wanted, is a follow-up knob under its own gate.

**Two clocks, again.** L1 expiry runs on the BEAM's monotonic clock; L2 expiry runs on the server's clock via `PX`. Each layer is sovereign over its own staleness, and neither trusts the other's watch — the series' two-clocks law, now in the cache.

## Boundaries

This chapter's staleness bound is the TTL and nothing sharper: a write elsewhere becomes visible here only when the clock says so, and surfaces that cannot accept that wait for Chapter 4.2's versioned invalidation. The L1 is per-node by design — two nodes warm independently, and cross-node agreement is exactly the coherence problem this chapter does not claim to solve. Values are binaries, loader errors are not cached (a hammered broken upstream is visible, not memorized — negative caching is a deliberate omission, revisitable under its own gate), and the speed figures carry the usual header: one core, loopback, this container — the ratios travel, the absolutes describe this machine.

## Companion files

`runtimes/elixir/lib/echo_cache/echo_cache.ex`, `lib/echo_cache/keyspace.ex`, `lib/echo_cache/table.ex`; the rung `bcs_rung_4_1_check.exs` and its committed record `bcs_rung_4_1_check.out`.

## References

1. Erlang/OTP documentation — `ets` (public tables, `read_concurrency`, and `select_delete` match-specification deletion — the L1's storage and the sweeper's one-pass reclaim): [erlang.org/doc/apps/stdlib/ets.html](https://www.erlang.org/doc/apps/stdlib/ets.html)
2. Valkey documentation — `SET` (the `PX` option: the L2 row written with its expiry in one command): [valkey.io/commands/set](https://valkey.io/commands/set/)
3. Valkey documentation — `EXPIRE` (expiration semantics and the server's two reclamation paths, on-access and active cycles — the L2-side counterpart of the sweeper): [valkey.io/commands/expire](https://valkey.io/commands/expire/)
4. Go `x/sync` — `singleflight` (duplicate function call suppression: the named prior art for one fill per herd, and the Go port's idiom for it): [pkg.go.dev/golang.org/x/sync/singleflight](https://pkg.go.dev/golang.org/x/sync/singleflight)
