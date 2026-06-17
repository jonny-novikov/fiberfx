# B4.3.3 · The Storm Drill

> Dive 3 of B4.3 · route `/bcs/cache/single-writer-ring/the-storm-drill` · teaches `content/bcs4.3.md`
> §"The storm, with the owner decoupled" + §"Convergence is order-independent" · transcript lines
> `derive (storm)`, `G5`, `derive (convergence)`, `G6` of `bcs_rung_4_3_check.out`.

A fill fired mid-storm completed in 0 ms.

Five hundred invalidations published on the real wire — push frames into the owner, which now only parses
and publishes; the ring's applier does the applying. The committed gate: "500 invalidations crossed the wire
and the ring in 25 ms with nothing dropped; every stormed row left L1, the one name whose writer placed a new
value answers px=109.00 from the shared L2, and a fill fired mid-storm completed in 0 ms -- the owner parses
and publishes while the applier applies, and neither waits for the other." That zero is the chapter's reason
to exist. And the race underneath is gated adversarially: 500 shuffled messages converging on exactly
`100 applied and 400 stale` — "arrival order changed nothing, because every application is the same
comparison."

Source: `content/bcs4.3.md`, quoting `bcs_rung_4_3_check.out`; the module is committed at
`runtimes/elixir/lib/echo_cache/ring.ex`, the grown `lib/echo_cache/table.ex`.

Interactive 1 (hero): the decoupled owner — the Why's coupled counterfactual (an owner that applies inline
queues its fills behind the storm) against the committed shape (the owner parses and publishes while the
applier applies, and a fill fired mid-storm completed in 0 ms), each side reading its line.

## §1 The transcript

This dive reads the two derive lines and the gates they bound, G5 and G6 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`):

```
derive (storm): 500 invalidations published on the wire ride push frames at the committed 72 us median into the owner, which only parses and publishes -- application happens on the ring's applier, so a fetch fired mid-storm answers without queueing behind 500 applies; expect the storm applied within two seconds and the mid-storm fill well under 50 ms
G5 storm ok -- 500 invalidations crossed the wire and the ring in 25 ms with nothing dropped; every stormed row left L1, the one name whose writer placed a new value answers px=109.00 from the shared L2, and a fill fired mid-storm completed in 0 ms -- the owner parses and publishes while the applier applies, and neither waits for the other
derive (convergence): for each of 200 names holding version v2, a shuffled stream delivers either v1,v3,v1 or v1,v1 -- whatever the arrival order, a row is dropped if and only if a version newer than v2 appeared, and the per-name verdict counts are invariant under permutation: exactly 100 applied and 400 stale
G6 convergence ok -- 500 shuffled messages converged: the 100 names that saw a newer version lost their rows, the 100 that saw only older versions still answer :hit, and the verdict counters landed exactly on 100 applied and 400 stale -- arrival order changed nothing, because every application is the same comparison
PASS 6/6
```

(The full record holds the header, G1–G2, and G3–G4; dive 1 and dive 2 read them, and the hub freezes the
record whole.)

## §2 The storm, with the owner decoupled

In 4.2 the table's owner did two jobs: it served fills and puts, and it applied every coherence push inline.
At 72 microseconds a message that coupling is invisible — until the storm: a halted market segment, a bulk
reprice, a reconnect replay, thousands of invalidations in one burst. An owner that applies inline queues its
fills behind them; an owner that spawns per message buys unbounded process churn for work that is one ETS
comparison each.

The drill runs the storm on the real wire: "500 invalidations published on the wire ride push frames at the
committed 72 us median into the owner, which only parses and publishes -- application happens on the ring's
applier, so a fetch fired mid-storm answers without queueing behind 500 applies". The derive line bounds the
outcome — "expect the storm applied within two seconds and the mid-storm fill well under 50 ms" — and the
committed line lands far inside it: 25 ms for the whole storm, nothing dropped, every stormed row out of L1,
the one rewritten name answering `px=109.00` from the shared L2, and the mid-storm fill at 0 ms. The push
handler is reduced to parse-and-publish; the `:broadcast` init starts the ring before the subscription that
feeds it; the terminate stops the ring with the table.

## §3 Convergence is order-independent

The applier races the owner's fills with no coordination, and the proof that this is safe is 4.2's own
theorem run adversarially: for each of 200 names holding version v2, a shuffled stream delivers either
v1,v3,v1 or v1,v1 — "whatever the arrival order, a row is dropped if and only if a version newer than v2
appeared, and the per-name verdict counts are invariant under permutation: exactly 100 applied and 400
stale". The committed gate: 500 shuffled messages converged — the 100 names where a newer version arrived
lost their rows, the 100 where only older versions arrived still answer `:hit`, "and the verdict counters
landed exactly on 100 applied and 400 stale -- arrival order changed nothing, because every application is
the same comparison."

The ring preserves arrival order as a courtesy to observability, not as a correctness requirement. And the
lanes stay separate: the broadcast lane rides receipt-to-ring-to-applier end to end, while the job lane
deliberately does not — its consumer still applies through the owner's `apply_coherence`, because a lane sold
as at-least-once cannot pass through a structure licensed to drop. The table's owner returns to its 4.1 job
description: fills, puts, and nothing else.

Interactive 2: the convergence comparator — the G6 dataset (200 names at v2; 100 names receive v1,v3,v1 and
100 receive v1,v1 — 500 messages) shuffled by fixed deterministic permutations and applied through the one
comparison; whichever permutation runs, the computed verdicts land on applied 100, stale 400, rows lost 100,
still `:hit` 100.

The module hands forward: **B4.4 · The Lane That Remembers** — the journal writer is the next single-writer
candidate; one owner draining ordered work is about to become a habit.

## References

Sources:

- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (receipt decoupled from
  application: the single-threaded processor fed by a ring)
- LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (one consumer
  draining batches in order while producers keep publishing)
- Erlang/OTP — atomics — https://www.erlang.org/doc/apps/erts/atomics.html (the mutual ordering that keeps
  the applier's reads safe against the producer's writes)

Related:

- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the module hub; the full rung in
  context
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the theorem the drill runs adversarially
- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the owner's job description restored
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus — B3 · The Bus, the wire the storm rides
- /echomq — EchoMQ, the bus protocol in rung-level depth

Pager: previous `/bcs/cache/single-writer-ring/occupancy-and-the-bound` · next
`/bcs/cache/single-writer-ring` (back to the hub).
