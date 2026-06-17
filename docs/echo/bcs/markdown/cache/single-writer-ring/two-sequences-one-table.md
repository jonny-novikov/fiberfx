# B4.3.1 · Two Sequences, One Table

> Dive 1 of B4.3 · route `/bcs/cache/single-writer-ring/two-sequences-one-table` · teaches `content/bcs4.3.md`
> §"Two sequences and a slot table" + §"Order through batches" + the Disruptor correspondence · transcript
> lines `G1`, `derive (order)`, `G2` of `bcs_rung_4_3_check.out`.

Two sequences, one table.

The ring's runtime is an atomics pair — tail for the producer, head for the applier — and a public ETS table
whose rows are reused by `rem(seq, capacity)`: preallocation, BEAM-style. The correctness of the whole
structure leans on one documented sentence: "All atomic operations are mutually ordered" — the slot insert
happens before the tail advance, so an applier that reads the new tail finds the slot already written, with
no lock anywhere. The committed gate puts order on the record: `1000 items crossed the ring in publish order
exactly -- the concatenated batches reproduce the sequence -- through 2 batches (largest 801) on 1 wakes: one
message per busy period, not one per item`.

Source: `content/bcs4.3.md`, quoting `bcs_rung_4_3_check.out`; the module is committed at
`runtimes/elixir/lib/echo_cache/ring.ex`.

Interactive 1 (hero): the ring walk — a head/tail machine over the G1 ring's committed capacity 512, driven
by publish and drain steps; the readout computes `rem(seq, capacity)` for the producer's tail, the occupancy
as tail minus head, and shows the slot reuse live. A fresh ring stands at occupancy 0, as G1 declares.

## §1 The transcript

This dive reads the surface gate, the order derivation, and the gate it bounds (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`):

```
G1 surface ok -- the ring's surface is whole -- publish, occupancy, stats, stop, a generic one-batch apply function -- and the declaration tells the truth: the broadcast table carries its ring name and capacity 512 in the directory, the :none table carries nil, and a fresh ring stands at occupancy 0
derive (order): the applier drains everything between head and tail in one pass, so concatenating the batches must reproduce publish order exactly; wakes are edge-triggered on the empty-to-nonempty transition, so 1000 items published into a draining ring should cost a handful of wakes -- well under fifty -- and more than one batch proves the batching is real
G2 order ok -- 1000 items crossed the ring in publish order exactly -- the concatenated batches reproduce the sequence -- through 2 batches (largest 801) on 1 wakes: one message per busy period, not one per item
PASS 6/6
```

(The full record holds the header, G3–G4, and G5–G6; dive 2 and dive 3 read them, and the hub freezes the
record whole.)

## §2 Two sequences and a slot table

The ring's runtime is an atomics pair — tail for the producer, head for the applier — and a public ETS table
whose rows are reused by `rem(seq, capacity)`: preallocation, BEAM-style. The load-bearing sentence is
documented, not assumed: "All atomic operations are mutually ordered." The slot insert happens before the
tail advance, so an applier that reads the new tail finds the slot already written — no lock anywhere.

G1 gates the surface and the declaration's truthfulness: publish, occupancy, stats, stop, a generic one-batch
apply function — and "the broadcast table carries its ring name and capacity 512 in the directory, the :none
table carries nil, and a fresh ring stands at occupancy 0". A table that declares no coherence carries no
ring; the directory of 4.1 reports both, truthfully.

Two decisions hold the structure up. **Single producer, structurally:** the publish path is lock-free because
exactly one process calls it — the owner, where pushes already serialize. The simplicity is bought with a
rule, the rule is stated in the module doc, and the wake-race analysis in the drain's comment is sound only
under it; two producers race the tail and the structure's guarantees evaporate — a second producer needs a
second ring, not a clever interleave. **Runtime in `persistent_term`:** the producer must reach sequences and
slots without a process hop; one `persistent_term` read per publish is the BEAM's cheapest shared-read path,
written once at ring start and erased at stop. A brutal kill skips terminate and leaks one entry until the
name is reused — "a stated cost of kill-9 truthfulness."

## §3 Order through batches

The applier drains everything between head and tail in one pass, applies the batch in arrival order, advances
head, and re-checks the tail before parking. The committed gate: "1000 items crossed the ring in publish
order exactly -- the concatenated batches reproduce the sequence -- through 2 batches (largest 801) on 1
wakes: one message per busy period, not one per item."

That last clause is the wake economy: the producer sends `:wake` only on the empty-to-nonempty transition,
and the applier's re-check-before-park closes the race where a publish lands after the drain's tail read.
The derive line bounds it before the measurement: 1000 items published into a draining ring "should cost a
handful of wakes -- well under fifty -- and more than one batch proves the batching is real". The committed
line lands at 1.

Interactive 2: the concatenation, checked — the G2 drill's stream of 1000 items split into two batches with
the largest carrying 801 (the record fixes the count and the largest size, not which batch came first); the
check concatenates the batches in drain order and verifies element by element that the sequence 1…1000 is
reproduced, and the wake ledger reads the committed economy: 2 batches, 1 wake.

## §4 The prior art

LMAX built a retail exchange whose business logic ran on a single thread — "6 million orders per second on a
single thread" — fed by the Disruptor, a bounded ring of preallocated slots with sequence counters, where one
consumer drains batches in order and the batching happens by itself whenever the consumer falls behind. The
chapter translates that shape onto the BEAM, and the correspondence is exact: sequences are atomics; the
preallocated slots are ETS rows reused by index; the single business-logic thread is the applier process; the
batching effect — a lagging consumer drains everything available in one pass — is the drain loop; and the
wait strategy is the BEAM's own: park in the mailbox, wake on the edge. What does not translate is
busy-spinning, and nothing is lost in the omission — on this runtime the mailbox is the wait strategy.

That is why the chapter reads the Disruptor beside the bus's park-don't-poll rather than instead of it — the
discipline the manuscript's Part III gave the bus's parked consumers, planned for the course as
**B3.4 · Fair Lanes** — both replace discovery with arrival, and both wake exactly once per busy period: the
same edge-triggered discipline, in one process instead of across a wire.

## References

Sources:

- LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (sequences over
  preallocated slots, single-writer consumption, batching as the consumer's catch-up effect)
- Erlang/OTP — atomics — https://www.erlang.org/doc/apps/erts/atomics.html (hardware atomic operations
  without software locking, mutually ordered across an array — the visibility guarantee the publish-then-advance
  leans on)
- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (the expositional account of
  the single-threaded processor the ring feeds)

Related:

- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the module hub; the full rung in
  context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the messages the ring carries
- /bcs/bus — B3 · The Bus, where park-don't-poll wakes consumers across the wire
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the ETS discipline underneath
- /echomq — EchoMQ, the bus protocol in rung-level depth

Pager: previous `/bcs/cache/single-writer-ring` · next
`/bcs/cache/single-writer-ring/occupancy-and-the-bound`.
