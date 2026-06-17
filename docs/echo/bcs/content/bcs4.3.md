# BCS · Chapter 4.3 — The Single Writer and the Ring

<show-structure depth="2"/>

Chapter 4.2 gated coherence's semantics; this chapter changes nothing about them and everything about the engine underneath. Application moves out of the table's owner and onto a bounded ring drained by one applier: the part's fifth law — the single writer applies the stream — as a data structure. One production module lands (`EchoCache.Ring`: two atomic sequences, preallocated ETS slots, edge-triggered wakes, batched drains, occupancy as a gauge, drop-on-full as a counted refusal) and the table grows a caller-side batch applier the ring drives. The committed record (`bcs_rung_4_3_check.out`, `PASS 6/6`) carries the shape in numbers: `1000 items crossed the ring in publish order exactly` through `2 batches (largest 801) on 1 wakes`; `1005116 items per second` end to end on one scheduler; a 500-invalidation storm over the real wire applied `in 25 ms with nothing dropped` while `a fill fired mid-storm completed in 0 ms`; and 500 adversarially shuffled messages converging on exactly `100 applied and 400 stale`. LMAX and the Disruptor are read as prior art throughout — the same answer to the same question, standing beside Part III's park-don't-poll.

## Why

In 4.2 the table's owner did two jobs: it served fills and puts, and it applied every coherence push inline. At 72 microseconds a message that coupling is invisible — until the storm. A halted market segment, a bulk reprice, a reconnect replay: thousands of invalidations arrive in one burst, and an owner that applies inline queues its fills behind them, while an owner that spawns per message buys unbounded process churn for work that is one ETS comparison each. The mature answer has a name and a pedigree. LMAX built a retail exchange whose business logic ran on a single thread — "6 million orders per second on a single thread" [1] — fed by the Disruptor, a bounded ring of preallocated slots with sequence counters, where one consumer drains batches in order and the batching happens by itself whenever the consumer falls behind [2]. The shape solves exactly our problem: receipt decoupled from application, order preserved, allocation amortized, and backpressure visible as a number instead of as a mystery latency. This chapter translates that shape onto the BEAM with the primitives the runtime ships for it [3], and reads it beside the bus's own park-don't-poll: both replace discovery with arrival, and both wake exactly once per busy period.

## What

**Two sequences and a slot table.** The ring's runtime is an atomics pair — tail for the producer, head for the applier — and a public ETS table whose rows are reused by `rem(seq, capacity)`: preallocation, BEAM-style. The correctness of the whole structure leans on one documented sentence: "All atomic operations are mutually ordered" [3] — the slot insert happens before the tail advance, so an applier that sees the new tail sees the slot, with no lock anywhere.

**Order through batches.** The applier drains everything between head and tail in one pass, applies the batch in arrival order, advances head, and re-checks the tail before parking. The committed gate: `1000 items crossed the ring in publish order exactly -- the concatenated batches reproduce the sequence -- through 2 batches (largest 801) on 1 wakes: one message per busy period, not one per item`. That last clause is the wake economy: the producer sends `:wake` only on the empty-to-nonempty transition, and the applier's re-check-before-park closes the race where a publish lands after the drain's tail read — the same edge-triggered discipline the bus's parked consumers run, in one process instead of across a wire.

**Occupancy is the gauge.** Tail minus head, readable by anyone at any time: `mid-storm the gauge read 600 of 4096 and drained to exactly 0`. A dashboard that plots this number sees a storm as a hill instead of inferring it from tail latencies.

**The ring priced.** With application amortized over batches, publish cost governs — one ETS insert and three atomics operations — and the record prices the whole pipe: `the ring moved 100000 items in 99 ms -- 1005116 items per second end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped`. The derivation note in the rung is part of the record: the first band's ceiling undercounted exactly because it priced the apply side that batching had already amortized away.

**Full is a counted refusal.** At capacity the publish answers `:dropped` and a counter moves — never a block, never an overwrite: `64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and applied`. The policy is not a shrug; it is contract preservation. The broadcast lane this ring serves is at-most-once by its substrate's own definition (4.2's gate F4 priced the loss), so a counted drop under storm bends the lane's contract no further than the contract already bends — where blocking would back the storm up into the push receiver, and overwriting would lose an arbitrary message silently. Surfaces that cannot accept a drop were never on this lane.

**The storm, with the owner decoupled.** Five hundred invalidations published on the real wire — push frames into the owner, which now only parses and publishes; the ring's applier does the applying. The record: `500 invalidations crossed the wire and the ring in 25 ms with nothing dropped; every stormed row left L1, the one name whose writer placed a new value answers px=109.00 from the shared L2, and a fill fired mid-storm completed in 0 ms -- the owner parses and publishes while the applier applies, and neither waits for the other`. That zero is the chapter's reason to exist.

**Convergence is order-independent.** The applier races the owner's fills with no coordination, and the proof that this is safe is 4.2's own theorem run adversarially: 200 names, shuffled streams of older and newer versions, and the outcome — `the 100 names that saw a newer version lost their rows, the 100 that saw only older versions still answer :hit, and the verdict counters landed exactly on 100 applied and 400 stale -- arrival order changed nothing, because every application is the same comparison`. The per-name verdict counts are invariant under permutation; the ring preserves arrival order as a courtesy to observability, not as a correctness requirement.

## Who

The broadcast lane, which now rides receipt-to-ring-to-applier end to end. The job lane, which deliberately does not: its consumer still applies through the owner's `apply_coherence`, because a lane sold as at-least-once cannot pass through a structure licensed to drop — the guarantee stays with the machinery that owns it, and the races between the two appliers are comparisons. The table's owner, returned to its 4.1 job description: fills, puts, and nothing else. Chapter 4.4, whose journal writer is the next single-writer candidate — one owner draining ordered work is about to become a habit. And the Go port, for which the Disruptor is home turf: the contract that travels is the drill list — order through batches, wake economy, occupancy, counted drops, the storm with a decoupled reader.

## When

Declare `ring_capacity` for the storm you expect, not the average you measure: capacity is the maximum burst the lane may absorb before drops begin, and at 29 bytes of meaning per slot a 4096-slot ring is cheap insurance. Watch occupancy, not only drops — a gauge that visits its ceiling is a storm survived; a dropped counter that moves is a storm that exceeded the declaration, and the TTL floor under the loss is the same floor 4.2 priced. And honor the structural requirement: publish is single-producer by design, which the table satisfies for free because pushes already serialize through the owner — a second producer needs a second ring, not a clever interleave.

## Where

The ring in `runtimes/elixir/lib/echo_cache/ring.ex`; the table's growth in `lib/echo_cache/table.ex` (`apply_batch/2` running caller-side against public ETS and the spec's counters, the `:broadcast` init starting the ring before the subscription that feeds it, the push handler reduced to parse-and-publish, the spec carrying `ring` and `ring_capacity`, the terminate stopping the ring with the table). The rung and its committed record: `bcs_rung_4_3_check.exs`, `bcs_rung_4_3_check.out`. The loader lines of the 4.1 and 4.2 rungs were amended to load the ring before the table — the fixture policy's lightest possible touch, with both frozen records untouched and both rungs re-run green.

## How — declaring, watching, porting

**A storm-rated table:**

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

**The gauge and the ledger:**

```elixir
EchoCache.Ring.occupancy({:coh, :quotes})
# 0 in calm, a hill in a storm

EchoCache.Ring.stats({:coh, :quotes})
# %{published: ..., applied: ..., dropped: 0, wakes: ..., batches: ...,
#   max_batch: ..., occupancy: 0, capacity: 4096}
```

**The Disruptor correspondence, in one paragraph.** Sequences are atomics; the preallocated slots are ETS rows reused by index; the single business-logic thread is the applier process; the batching effect — a lagging consumer drains everything available in one pass — is the drain loop; and the wait strategy is the BEAM's own: park in the mailbox, wake on the edge. What does not translate is busy-spinning, and nothing is lost in the omission — on this runtime the mailbox is the wait strategy, which is why the chapter reads the Disruptor beside park-don't-poll rather than instead of it.

## Decisions

**The ring serves the broadcast lane only.** Drop-on-full preserves at-most-once; routing the job lane's at-least-once delivery through a dropping structure would launder a guarantee away. Two lanes, two engines, one comparison making their races safe.

**Drop, never block, never overwrite.** Blocking turns a full ring into owner backpressure and mailbox growth; overwriting loses a message silently and unpredictably. A counted refusal is the only full-policy that keeps both the lane's contract and the operator's visibility.

**Single producer, structurally.** The publish path is lock-free because exactly one process calls it — the owner, where pushes already serialize. The simplicity is bought with a rule, the rule is stated in the module doc, and the wake-race analysis in the drain's comment is sound only under it.

**The applier applies caller-side.** `apply_batch/2` touches public ETS and the spec's counters, never the owner — the whole point of the decoupling — and every interleaving with concurrent fills converges because newer-wins is a comparison, which gate G6 runs adversarially rather than asserts politely.

**Runtime in `persistent_term`.** The producer must reach sequences and slots without a process hop; one `persistent_term` read per publish is the BEAM's cheapest shared-read path, written once at ring start and erased at stop.

## Boundaries

The single-producer requirement is a hard precondition, not a tunable — two producers race the tail and the structure's guarantees evaporate; the table satisfies it by construction, and any other rider must too. A dropped message is a real loss bounded by the TTL exactly as 4.2 priced it; the ring adds counting, not resurrection. A brutal kill of the table skips terminate and leaks one `persistent_term` entry until the name is reused — supervision restarts re-register cleanly, and the leak is a stated cost of kill-9 truthfulness rather than a cleanup we pretend always runs. And the throughput figure carries its header: one scheduler, loopback-free, items of two names each — `1005116 items per second` is this container's number; the shape of the curve travels, the magnitude does not.

## Companion files

`runtimes/elixir/lib/echo_cache/ring.ex`, the grown `lib/echo_cache/table.ex`; the rung `bcs_rung_4_3_check.exs` and its committed record `bcs_rung_4_3_check.out`; the loader-amended `bcs_rung_4_1_check.exs` and `bcs_rung_4_2_check.exs` (frozen records untouched).

## References

1. Fowler, M. — The LMAX Architecture (the expositional account: a single-threaded business logic processor fed by ring-buffer Disruptors, event-sourced and in-memory — the prior art this chapter translates): [martinfowler.com/articles/lmax.html](https://martinfowler.com/articles/lmax.html)
2. Thompson, M., Farley, D., Barker, M., Gee, P., Stewart, A. — Disruptor: High performance alternative to bounded queues for exchanging data between concurrent threads, LMAX technical paper, 2011 (sequences over preallocated slots, single-writer consumption, batching as the consumer's catch-up effect): [lmax-exchange.github.io/disruptor/disruptor.html](https://lmax-exchange.github.io/disruptor/disruptor.html)
3. Erlang/OTP documentation — `atomics`, erts (hardware atomic operations without software locking, mutually ordered across an array — the visibility guarantee the ring's publish-then-advance leans on): [erlang.org/doc/apps/erts/atomics.html](https://www.erlang.org/doc/apps/erts/atomics.html)
