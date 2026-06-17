# trd.2 — the agent guide (building the Book)

> Derived from [`trd.2.specs.md`](trd.2.specs.md) (authoritative) and the chapter ([`trd.2.md`](trd.2.md)). Real
> arities only — every surface below is defined in the spec or exists in the tree at the cited path. **Framing
> (propagate this clause):** third person for any agent; no gendered pronouns; no perceptual or interior-state verbs;
> no first-person narration. This guide builds the matching core ON the as-built Ring and canon — it edits neither.

## References (read first, in order)

- `contract/contract.md` — the canon: branded ids, the order theorem (mint order == time priority). **First.**
- `docs/bcs/exchange.specs.md` + `docs/bcs/exchange.patterns.md` — the master invariant and the Decider/Disruptor argument.
- `docs/bcs/trd.2.md` + `docs/bcs/trd.2.specs.md` — this rung's chapter and authoritative spec.
- `docs/bcs/trd.1.specs.md` — the typed command vocabulary this rung consumes.
- `runtimes/elixir/lib/echo_cache/ring.ex` — the as-built Ring (`publish/2 :: :ok | :dropped`, `occupancy/1`, `stats/1`, `start_link(capacity:)`). Build ON it; do not rebuild it.
- `runtimes/elixir/lib/echo_data/branded_tree.ex` · `snowflake.ex` — the account-order index and minting; build ON, do not edit.

## The surface (exact, as the spec pins it)

- `Exchange.Book.start_link(instrument, opts)` — starts/attaches the instrument's Ring and drains it as the single
  writer. `Exchange.Book.submit(instrument, command) :: :ok | :dropped`. `Exchange.Book.snapshot(instrument)` — the
  folded state.
- `Exchange.Decider.decide(command, state) :: [event]` and `evolve(state, event) :: state` — both pure.
- `Exchange.OrderBook.new/0`, `best/2` — the pure ladder and its reads.
- Events: `{:fill, ...}` (branded `FIL` id, both order ids, `{units, nano}` money, quantity), `{:rested, ...}`,
  `{:rejected, %{reason: atom}}`. Money is `{units :: integer, nano :: integer}` — never a float.
- Ring: `EchoCache.Ring.publish(name, item) :: :ok | :dropped`; `stats(name)` carries `:dropped` and the largest
  batch drained. The Book is the Ring's single consumer.

## Requirements pattern (each traces to an invariant)

- **R-writer** (INV-1). One `Exchange.Book` per instrument is the sole drainer and sole mutator. No second matcher.
- **R-reconcile** (INV-2, INV-7). Accepted == applied + `stats.dropped`, always. Overload answers `:dropped` at the
  door; the book never grows an unbounded pending buffer.
- **R-pure** (INV-3). `decide`/`evolve` have no process, store, clock, or IO. Matching rules live only in the Decider.
- **R-fold** (INV-4). State is the fold of `evolve` over emitted events in mint order; nothing reachable except
  through the fold.
- **R-order** (INV-5). Price priority is the ladder key; time priority is branded mint order. No clock, no extra
  comparator.
- **R-money** (INV-6). Integer `{units, nano}` arithmetic with integer carry; no float in any event or state.
- **R-fill-key** (the Go seam). Every `:fill` carries a branded `FIL` id and integer money so a downstream job can be
  keyed by it.
- **R-prove**. A gate script in the rung pattern — one printed line per gate (G1–G6), exit nonzero on failure, output
  committed beside it.

## Execution topology

`Exchange.Book` is one supervised GenServer per instrument, the single drainer of that instrument's `EchoCache.Ring`.
Boot order per runtime: `Snowflake.start/1` once, then Books start (each attaches or starts its Ring). The Decider
and OrderBook are pure modules the Book calls — they start nothing. Restart semantics: a crashed Book rebuilds its
state by folding its events (the replay property TRD.3 gates end to end); this rung tolerates an in-memory book that a
later rung makes durable via the log. No Valkey is required for the matching gates — the Ring is an in-BEAM buffer.

## The Go-worker boundary (do not build here; honor its contract)

The external processor is a Go worker fleet (TInvest Go SDK clients, drained as EchoMQ jobs, reading through
EchoCache; Go for numeric throughput and GPU-accelerated money-math — mark-to-market, margin, risk, analytics). This
rung does not build it. The seam is the fill: a `:fill` event becomes a job keyed by its `FIL` id, carrying
`{units, nano}` money; the Decider emits the fact, the fact becomes the work, and the Decider never calls a worker.
Integer money on both runtimes; claims (not objects) for reference data. The job payload schema is a later rung's;
do not invent it here.

## Do NOT

- Do not edit `ring.ex`, the canon modules, or any committed check output — this rung is additive.
- Do not put a process, store, clock read, or IO inside `decide`/`evolve` — the Decider is pure or it is wrong.
- Do not add a second draining scheme beside the Ring's; do not let the Book grow an unbounded pending buffer.
- Do not use float for money; do not read a clock to break time priority — mint order already does.
- Do not construct `FIL` ids by hand; mint through the canon at the fill.
- Do not call a Go worker from the Decider or the Book hot path; emit a fact and let it become a job.
- Do not print exclamation marks or forbidden-voice words in check output lines a chapter may later quote.

## Agent stories (Directive + Acceptance gate)

- **AS-1 — the pure ladder first.** *Directive:* build `Exchange.OrderBook` (per-side `gb_trees`, mint-order FIFOs,
  pure reads) before matching. *Gate:* a price-time read property holds, no process, line green, exit zero.
- **AS-2 — matching as a pure decider.** *Directive:* write side-effect-free `decide`/`evolve` for cross, partial,
  rest, reject. *Gate:* G1, G2 hold over `decide`; a grep shows no process/store/clock in the Decider; exit zero.
- (AS-3…AS-7 in [`trd.2.stories.md`](trd.2.stories.md) — single-writer, admission-reconcile, no-float, self-trade,
  fill-key — carry the same gate-and-exit contract.)

## Map

Spec: [`trd.2.specs.md`](trd.2.specs.md). Chapter: [`trd.2.md`](trd.2.md). Stories:
[`trd.2.stories.md`](trd.2.stories.md). Previous rung: [`trd.1.llms.md`](trd.1.llms.md). The Ring: Chapter 4.3 in
`bcs.toc.md`.
