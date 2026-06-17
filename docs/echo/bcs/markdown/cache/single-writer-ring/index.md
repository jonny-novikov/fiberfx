# B4.3 · The Single Writer and the Ring

> Module hub · route `/bcs/cache/single-writer-ring` · teaches `content/bcs4.3.md` · rung record
> `bcs_rung_4_3_check.out`, `PASS 6/6` (G1–G6, with the header and the derive lines kept — they are part of
> the record, D-B4.3).

The single writer applies the stream.

Chapter 4.2 gated coherence's semantics; this chapter changes nothing about them and everything about the
engine underneath. Application moves out of the table's owner and onto a bounded ring drained by one applier —
the part's fifth law, the single writer applies the stream, as a data structure. One production module lands
(`EchoCache.Ring`: two atomic sequences, preallocated ETS slots, edge-triggered wakes, batched drains,
occupancy as a gauge, drop-on-full as a counted refusal), and the committed record carries the shape in
numbers: `1000 items crossed the ring in publish order exactly` through `2 batches (largest 801) on 1 wakes`;
`1005116 items per second` end to end on one scheduler; a 500-invalidation storm over the real wire applied
`in 25 ms with nothing dropped` while `a fill fired mid-storm completed in 0 ms`; and 500 adversarially
shuffled messages converging on exactly `100 applied and 400 stale`.

Source: `content/bcs4.3.md`; the rung behind it is `bcs_rung_4_3_check.exs`, its committed transcript closes
`PASS 6/6` under the header `Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1`.

Interactive (hero): the six gates, mapped to the dives — G1 surface and G2 order are dive 1's, G3 occupancy
and G4 full are dive 2's, G5 storm and G6 convergence are dive 3's; selecting a gate reads its verbatim line
and the dive that teaches it.

## §1 Why the owner stops applying

In 4.2 the table's owner did two jobs: it served fills and puts, and it applied every coherence push inline.
At 72 microseconds a message that coupling is invisible — until the storm. A halted market segment, a bulk
reprice, a reconnect replay: thousands of invalidations arrive in one burst, and an owner that applies inline
queues its fills behind them, while an owner that spawns per message buys unbounded process churn for work
that is one ETS comparison each. The mature answer has a name and a pedigree: LMAX built a retail exchange
whose business logic ran on a single thread — "6 million orders per second on a single thread" — fed by the
Disruptor, a bounded ring of preallocated slots with sequence counters. This chapter translates that shape
onto the BEAM with the primitives the runtime ships for it, and reads it beside the bus's own park-don't-poll:
both replace discovery with arrival, and both wake exactly once per busy period.

The decisions, from the chapter:

- **The ring serves the broadcast lane only.** Drop-on-full preserves at-most-once; "routing the job lane's
  at-least-once delivery through a dropping structure would launder a guarantee away." Two lanes, two engines,
  one comparison making their races safe.
- **Drop, never block, never overwrite.** Blocking turns a full ring into owner backpressure and mailbox
  growth; overwriting loses a message silently and unpredictably. A counted refusal is the only full-policy
  that keeps both the lane's contract and the operator's visibility.
- **Single producer, structurally.** The publish path is lock-free because exactly one process calls it — the
  owner, where pushes already serialize. The simplicity is bought with a rule, and the rule is stated in the
  module doc.
- **The applier applies caller-side.** `apply_batch/2` touches public ETS and the spec's counters, never the
  owner — the whole point of the decoupling — and every interleaving with concurrent fills converges because
  newer-wins is a comparison.
- **Runtime in `persistent_term`.** The producer must reach sequences and slots without a process hop; one
  `persistent_term` read per publish is the BEAM's cheapest shared-read path, written once at ring start and
  erased at stop. A brutal kill skips terminate and leaks one entry until the name is reused — "a stated cost
  of kill-9 truthfulness."
- **Occupancy is the gauge.** Tail minus head, readable by anyone at any time. A dashboard that plots this
  number shows a storm as a hill instead of inferring it from tail latencies.

## §2 The proof

The full committed record, verbatim — the header, six gates, and four derive lines (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`):

```
header: Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1
G1 surface ok -- the ring's surface is whole -- publish, occupancy, stats, stop, a generic one-batch apply function -- and the declaration tells the truth: the broadcast table carries its ring name and capacity 512 in the directory, the :none table carries nil, and a fresh ring stands at occupancy 0
derive (order): the applier drains everything between head and tail in one pass, so concatenating the batches must reproduce publish order exactly; wakes are edge-triggered on the empty-to-nonempty transition, so 1000 items published into a draining ring should cost a handful of wakes -- well under fifty -- and more than one batch proves the batching is real
G2 order ok -- 1000 items crossed the ring in publish order exactly -- the concatenated batches reproduce the sequence -- through 2 batches (largest 801) on 1 wakes: one message per busy period, not one per item
derive (throughput): a publish is one ETS insert and three atomics operations, near 0.5 to 1 us, and the apply side amortizes to nothing over batches -- so publish cost alone governs, and the end-to-end rate on one scheduler should land between 100,000 and 2,500,000 items per second, floor 80,000; mid-storm occupancy must sit strictly between zero and capacity and drain to exactly zero
G3 occupancy ok -- mid-storm the gauge read 600 of 4096 and drained to exactly 0; priced, the ring moved 100000 items in 99 ms -- 1005116 items per second end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped
derive (full): with capacity 64 and the applier held inside its first apply, exactly 64 publishes are accepted and 136 are refused and counted; releasing the applier drains the 64, and the next publish lands -- the ring under storm refuses, recovers, and keeps serving
G4 full ok -- the bound held its shape: 64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and applied: a storm bends the lane's at-most-once contract no further than the contract already bends
derive (storm): 500 invalidations published on the wire ride push frames at the committed 72 us median into the owner, which only parses and publishes -- application happens on the ring's applier, so a fetch fired mid-storm answers without queueing behind 500 applies; expect the storm applied within two seconds and the mid-storm fill well under 50 ms
G5 storm ok -- 500 invalidations crossed the wire and the ring in 25 ms with nothing dropped; every stormed row left L1, the one name whose writer placed a new value answers px=109.00 from the shared L2, and a fill fired mid-storm completed in 0 ms -- the owner parses and publishes while the applier applies, and neither waits for the other
derive (convergence): for each of 200 names holding version v2, a shuffled stream delivers either v1,v3,v1 or v1,v1 -- whatever the arrival order, a row is dropped if and only if a version newer than v2 appeared, and the per-name verdict counts are invariant under permutation: exactly 100 applied and 400 stale
G6 convergence ok -- 500 shuffled messages converged: the 100 names that saw a newer version lost their rows, the 100 that saw only older versions still answer :hit, and the verdict counters landed exactly on 100 applied and 400 stale -- arrival order changed nothing, because every application is the same comparison
PASS 6/6
```

The derive lines are part of the record: each measurement is bounded before it is taken, and the committed
line then lands inside its own band. The derivation note rides with them (D-B4.3): "the first band's ceiling
undercounted exactly because it priced the apply side that batching had already amortized away."

A storm-rated table, declared (source: `content/bcs4.3.md` · How):

```elixir
{:ok, _} =
  EchoCache.Table.start_link(
    name: :quotes,
    kind: "AST",
    coherence: :broadcast,
    ring_capacity: 4_096,
    ttl_ms: 5_000,
    loader: &PriceFeed.load/1,
    connector: [port: 6390]
  )
```

The ring lives at `runtimes/elixir/lib/echo_cache/ring.ex`; the table's growth at `lib/echo_cache/table.ex`
(`apply_batch/2` running caller-side against public ETS and the spec's counters, the `:broadcast` init
starting the ring before the subscription that feeds it, the push handler reduced to parse-and-publish, the
spec carrying `ring` and `ring_capacity`, the terminate stopping the ring with the table).

## §3 The dives

- **B4.3.1 · Two Sequences, One Table** (`two-sequences-one-table`) — G1: the surface and the truthful
  declaration — "the broadcast table carries its ring name and capacity 512 in the directory". G2: order
  through batches — "1000 items crossed the ring in publish order exactly … through 2 batches (largest 801)
  on 1 wakes"; the atomics ordering sentence; the Disruptor correspondence.
- **B4.3.2 · Occupancy and the Bound** (`occupancy-and-the-bound`) — G3: the gauge — "mid-storm the gauge
  read 600 of 4096 and drained to exactly 0", `1005116 items per second`. G4: full as a counted refusal —
  "64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten".
- **B4.3.3 · The Storm Drill** (`the-storm-drill`) — G5: "500 invalidations crossed the wire and the ring in
  25 ms with nothing dropped … a fill fired mid-storm completed in 0 ms". G6: convergence — "exactly on 100
  applied and 400 stale -- arrival order changed nothing".

The module hands forward: **B4.4 · The Lane That Remembers** — the journal writer is the next single-writer
candidate; one owner draining ordered work is about to become a habit. And the manuscript plans the referee
chapter — **B4.5 · The Cache Referee** — to hold the comparison set to this module's drills.

## References

Sources:

- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (the single-threaded business
  logic processor and the ring that feeds it: the prior art this chapter translates)
- LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (sequences over
  preallocated slots; batching as the consumer's catch-up effect)
- Erlang/OTP — atomics — https://www.erlang.org/doc/apps/erts/atomics.html (the sequences' visibility
  guarantee: "all atomic operations are mutually ordered")

Related:

- /bcs/cache — B4 · EchoCache, the chapter landing; Part IV's arc
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the semantics this ring now applies
- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the owner returned to its job description
- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the journal beside the consumer this ring feeds
- /bcs/bus — B3 · The Bus, the wire the storm rides
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the stores behind the cache
- /redis-patterns — Redis Patterns Applied, the caching substrate patterns
- /echomq — EchoMQ, the bus protocol in rung-level depth
- /elixir — Functional Programming in Elixir, the umbrella the runtimes live in

Pager: previous `/bcs/cache` · next `/bcs/cache/single-writer-ring/two-sequences-one-table`.
