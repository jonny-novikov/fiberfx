# B4.3.2 · Occupancy and the Bound

> Dive 2 of B4.3 · route `/bcs/cache/single-writer-ring/occupancy-and-the-bound` · teaches
> `content/bcs4.3.md` §"Occupancy is the gauge" + §"The ring priced" + §"Full is a counted refusal" ·
> transcript lines `derive (throughput)`, `G3`, `derive (full)`, `G4` of `bcs_rung_4_3_check.out`.

The gauge reads 600 of 4096.

Occupancy is tail minus head, readable by anyone at any time — a dashboard that plots this number shows a
storm as a hill instead of inferring it from tail latencies. The committed gate: "mid-storm the gauge read
600 of 4096 and drained to exactly 0; priced, the ring moved 100000 items in 99 ms -- 1005116 items per
second end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped." And at
capacity the publish answers `:dropped` and a counter moves — never a block, never an overwrite: "64
accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release
drained all 64 and publish 201 landed and applied."

Source: `content/bcs4.3.md`, quoting `bcs_rung_4_3_check.out`; the module is committed at
`runtimes/elixir/lib/echo_cache/ring.ex`.

Interactive 1 (hero): the occupancy gauge — the G3 storm's three committed states (calm at 0, mid-storm at
600 of 4096, drained to exactly 0) drawn on one bar whose fill is computed live from the record's pair;
selecting a state reads its verbatim line.

## §1 The transcript

This dive reads the two derive lines and the gates they bound, G3 and G4 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`):

```
derive (throughput): a publish is one ETS insert and three atomics operations, near 0.5 to 1 us, and the apply side amortizes to nothing over batches -- so publish cost alone governs, and the end-to-end rate on one scheduler should land between 100,000 and 2,500,000 items per second, floor 80,000; mid-storm occupancy must sit strictly between zero and capacity and drain to exactly zero
G3 occupancy ok -- mid-storm the gauge read 600 of 4096 and drained to exactly 0; priced, the ring moved 100000 items in 99 ms -- 1005116 items per second end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped
derive (full): with capacity 64 and the applier held inside its first apply, exactly 64 publishes are accepted and 136 are refused and counted; releasing the applier drains the 64, and the next publish lands -- the ring under storm refuses, recovers, and keeps serving
G4 full ok -- the bound held its shape: 64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and applied: a storm bends the lane's at-most-once contract no further than the contract already bends
PASS 6/6
```

(The full record holds the header, G1–G2, and G5–G6; dive 1 and dive 3 read them, and the hub freezes the
record whole.)

## §2 The gauge, and the ring priced

Occupancy is tail minus head, readable by anyone at any time. The watching surface, verbatim from the
chapter's How:

```elixir
EchoCache.Ring.occupancy({:coh, :quotes})
# 0 in calm, a hill in a storm

EchoCache.Ring.stats({:coh, :quotes})
# %{published: ..., applied: ..., dropped: 0, wakes: ..., batches: ...,
#   max_batch: ..., occupancy: 0, capacity: 4096}
```

With application amortized over batches, publish cost governs — "a publish is one ETS insert and three
atomics operations, near 0.5 to 1 us" — and the derive line prices the whole pipe before measuring it: "the
end-to-end rate on one scheduler should land between 100,000 and 2,500,000 items per second, floor 80,000".
The committed line lands inside the band: "the ring moved 100000 items in 99 ms -- 1005116 items per second
end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped". The derivation
note is part of the record (D-B4.3): "the first band's ceiling undercounted exactly because it priced the
apply side that batching had already amortized away."

The boundary travels with the number: one scheduler, loopback-free, items of two names each — `1005116 items
per second` is this container's number; the shape of the curve travels, the magnitude does not.

Declare `ring_capacity` for the storm you expect, not the average you measure: capacity is the maximum burst
the lane may absorb before drops begin, and at 29 bytes of meaning per slot a 4096-slot ring is cheap
insurance. Watch occupancy, not only drops — a gauge that visits its ceiling is a storm survived; a dropped
counter that moves is a storm that exceeded the declaration, and the TTL floor under the loss is the same
floor 4.2 priced.

## §3 Full is a counted refusal

At capacity the publish answers `:dropped` and a counter moves — never a block, never an overwrite. The drill
holds the applier inside its first apply with capacity 64, then publishes past the bound: "exactly 64
publishes are accepted and 136 are refused and counted; releasing the applier drains the 64, and the next
publish lands". The committed gate: "the bound held its shape: 64 accepted, 136 refused with :dropped and
counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and
applied: a storm bends the lane's at-most-once contract no further than the contract already bends."

The policy is not a shrug; it is contract preservation. The broadcast lane this ring serves is at-most-once
by its substrate's own definition — 4.2's gate F4 priced the loss — so a counted drop under storm bends the
lane's contract no further than the contract already bends, where blocking would back the storm up into the
push receiver, and overwriting would lose an arbitrary message silently. Surfaces that cannot accept a drop
were never on this lane; "routing the job lane's at-least-once delivery through a dropping structure would
launder a guarantee away." A dropped message is a real loss bounded by the TTL exactly as 4.2 priced it; the
ring adds counting, not resurrection.

Interactive 2: full as a refusal, stepped — the G4 drill replayed phase by phase (hold the applier · publish
into the bound: 64 accepted, 136 refused with `:dropped` and counted · release: the 64 drain · publish 201
lands and applies), the counters computed live and the verbatim lines read at each step.

## References

Sources:

- Erlang/OTP — atomics — https://www.erlang.org/doc/apps/erts/atomics.html (the three atomics operations a
  publish pays; the mutual ordering the gauge's two sequences lean on)
- LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (the bounded
  ring of preallocated slots; batching as the consumer's catch-up effect — the amortization the derive line
  prices)
- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (the prior art's account of
  throughput on a single thread)

Related:

- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the module hub; the full rung in
  context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, where F4 priced the lane's loss
- /bcs/bus — B3 · The Bus, the push receiver blocking would back up into
- /redis-patterns — Redis Patterns Applied, the caching substrate patterns
- /echomq — EchoMQ, the bus protocol in rung-level depth

Pager: previous `/bcs/cache/single-writer-ring/two-sequences-one-table` · next
`/bcs/cache/single-writer-ring/the-storm-drill`.
