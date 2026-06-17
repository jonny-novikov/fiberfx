# B4.1.3 · The Jittered Clock

> Dive 3 of B4.1 · route `/bcs/cache/cache-aside/the-jittered-clock` · teaches `content/bcs4.1.md` §"The
> jittered clock and the sweeper" + §"The bound" · transcript lines `derive (jitter)`, `E5`, `derive (bound)`,
> `E6` of `bcs_rung_4_1_check.out`.

Rows filled together must not expire together.

If a cohort of rows expires at one instant, the TTL itself schedules the next herd. Every insert draws its
expiry from `ttl ± ttl·jitter`, and the committed drill shows the spread doing its work: "400 rows filled in
24 ms expire 138 ms apart at jitter 0.2 -- no synchronized re-herd", while the zero-jitter cohort spreads only
its own fill walltime — jitter added nothing there, which is the control that proves the treatment. The
sweeper then reclaims on its tick, and the size bound degrades to pass-through, never to failure: "a full
cache is a stat, never an error".

Source: `content/bcs4.1.md`, quoting `bcs_rung_4_1_check.out`; the module is committed at
`runtimes/elixir/lib/echo_cache/table.ex`.

Interactive 1 (hero): the jitter-spread visualizer — the two committed cohorts drawn to one scale: at jitter
0.2, 400 rows filled in 24 ms expire 138 ms apart; at jitter 0.0, the cohort spreads 5 ms across a 4 ms fill;
and the sweeper's tick reclaims the whole cohort (swept 400, table size 0) with not one read paying the
cleanup.

## §1 The transcript

This dive reads the two derive lines and the gates they bound, E5 and E6 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_1_check.out`):

```
derive (jitter): ttl 300 ms at jitter 0.2 spreads expiry uniformly across plus-minus 60 ms -- 400 rows filled in one fast pass should spread at least 70 ms beyond their fill walltime, approaching 120; a jitter 0.0 cohort's spread can never exceed its own fill walltime -- jitter adds nothing; the sweeper on a 100 ms tick then reclaims the whole cohort without a single read
E5 jitter ok -- 400 rows filled in 24 ms expire 138 ms apart at jitter 0.2 -- no synchronized re-herd -- while the jitter 0.0 cohort spreads 5 ms across a 4 ms fill: jitter added nothing there; the sweeper then reclaimed the whole cohort on its tick (swept 400, table size 0) with not one read paying the cleanup
derive (bound): refdata declares max_size 100 with a 60 s ttl, so nothing expires to reclaim -- 49 more fills fit beside the 51 live rows, then every further fill must serve its caller and skip the insert
E6 bound ok -- the declaration holds: size capped at 100 of 100, 101 fills served their callers and skipped the insert -- a full cache is a stat, never an error -- and the writer path lands one value in both layers
PASS 6/6
```

(The full record holds E1–E4 and their derive lines; dives 1 and 2 read them, and the hub freezes the record
whole.)

## §2 The sweeper, and two clocks

Dead rows leave whether or not anyone reads them again. The sweeper reclaims on its tick — the committed line:
"the sweeper then reclaimed the whole cohort on its tick (swept 400, table size 0) with not one read paying
the cleanup" — a one-pass `select_delete` over the table. Valkey does the same on its side with on-access and
active expiration — two layers each keeping their own house.

The decision is the series' two-clocks law, now in the cache: L1 expiry runs on the BEAM's monotonic clock; L2
expiry runs on the server's clock via `PX`. Each layer is sovereign over its own staleness, and neither trusts
the other's watch. From the chapter's When: size the jitter to the herd you fear — 0.1–0.2 spreads a cohort
across a fifth of its TTL, which is enough to turn a synchronized re-fill into a trickle.

## §3 The bound

A full cache is a stat, never an error. With `max_size 100` declared and nothing expired to reclaim, the
record shows "size capped at 100 of 100, 101 fills served their callers and skipped the insert" — every caller
got its value, the table held its declaration, and the overflow is visible in `full_skips` rather than in
anyone's latency alarm. No eviction cleverness in this chapter: an LRU would tax every read with
touch-tracking, and the read path's purity is the product. Smarter eviction, if ever wanted, is a follow-up
knob under its own gate.

The boundaries travel with the gate: this chapter's staleness bound is the TTL and nothing sharper — a write
elsewhere becomes visible here only when the clock says so, and surfaces that cannot accept that wait for the
versioned invalidation of **B4.2 · Coherence by Mint Time**. The L1 is per-node by design — two nodes warm
independently, and cross-node agreement is exactly the coherence problem this chapter does not claim to solve.

Interactive 2: the bound walk — four committed stations: the cohort (`max_size 100`, a 60 s ttl, 51 live
rows), filling to the bound (49 more fills fit — 51 + 49 computed live to 100), filling past it (101 fills
served their callers and skipped the insert), and the writer path (one value landed in both layers).

## References

Sources:

- Erlang/OTP — ets — https://www.erlang.org/doc/apps/stdlib/ets.html (`select_delete` match-specification
  deletion: the sweeper's one-pass reclaim)
- Valkey — EXPIRE — https://valkey.io/commands/expire/ (expiration semantics and the server's two reclamation
  paths, on-access and active cycles — the L2-side counterpart of the sweeper)
- Valkey — SET — https://valkey.io/commands/set/ (the `PX` option: the L2 row written with its expiry in one
  command)

Related:

- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus — B3 · The Bus, the volatile substrate beside the cache
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the owners the TTL shields
- /redis-patterns — Redis Patterns Applied, the caching substrate patterns
- /echomq — EchoMQ, the bus protocol in rung-level depth

Pager: previous `/bcs/cache/cache-aside/one-fill-per-herd` · next `/bcs/cache/cache-aside` (back to the hub).
