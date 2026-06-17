# TRD.2 · The Book — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung TRD.2. The chapter ([`trd.2.md`](trd.2.md)) narrates it; the runbook
> ([`trd.2.llms.md`](trd.2.llms.md)) derives from it; the stories ([`trd.2.stories.md`](trd.2.stories.md)) are its
> acceptance gates. Feedback edits this file, not the implementation. **Status: PROPOSED.** Definition of done: a
> committed transcript at `runtimes/elixir/trd_2_check.out`, exit zero, every gate line green. Stands on TRD.1 and
> `EchoCache.Ring`.

## Invariants

- **INV-1 — single writer per instrument.** Exactly one `Exchange.Book` process drains a given instrument's Ring;
  that process is the only mutator of that instrument's state. No second process matches against the same book.
- **INV-2 — admission reconciles.** Over any run, the Ring's accepted count equals the Book's applied count plus the
  Ring's `:dropped` count. Every command is matched, rested, or dropped-and-counted; none is silently lost.
- **INV-3 — pure decision.** `Exchange.Decider.decide/2` and `evolve/2` are side-effect-free: no process, no store,
  no clock, no IO. `decide` returns events; `evolve` folds one event into state. Matching rules live only here.
- **INV-4 — fold is state.** The book's state equals the fold of `evolve` over the events the Decider has emitted, in
  mint order. There is no state reachable except through the fold (the replay property TRD.3 will gate end to end).
- **INV-5 — price-time from the id.** Price priority is the ladder's key order; time priority within a level is
  branded mint order (the Gateway's stamp, TRD.1). The book holds no clock and no comparator beyond the id byte order.
- **INV-6 — typed money, never float.** Prices and fills carry `{units, nano}` integers (the venue `Quotation`). No
  float appears in any book type, event, or fold.
- **INV-7 — overload is an answer.** A full Ring answers `:dropped` at `publish/2`; the drop is counted and
  observable through `stats/1`. The book never grows an unbounded buffer of pending commands.

## The as-built surface this rung consumes (pinned, not rebuilt)

```elixir
EchoCache.Ring.start_link(name: term(), capacity: pos_integer())   # capacity >= 2
EchoCache.Ring.publish(name, item :: term()) :: :ok | :dropped     # :dropped counted on full
EchoCache.Ring.occupancy(name) :: non_neg_integer()                # tail - head
EchoCache.Ring.stats(name) :: %{dropped: ..., capacity: ..., ...}  # counters + largest batch
```

The Book is the Ring's single consumer; it reads accepted items in order, applies them, and advances. The drain
mechanism is the Ring's as-built consumer path — this rung does not add a second draining scheme.

## The event vocabulary (the Decider's output)

```elixir
@type event ::
        {:fill, %{taker: binary(), maker: binary(), instrument: binary(),
                  price: money(), quantity: pos_integer(), id: binary()}}
      | {:rested, %{order: binary(), instrument: binary(),
                    side: :buy | :sell, price: money(), quantity: pos_integer()}}
      | {:rejected, %{order: binary(), reason: atom()}}

@type money :: {integer(), integer()}   # Quotation; from TRD.1, never a float
```

A crossing order yields one or more `:fill` events (each with its own branded `FIL` id, minted at the fill) plus a
`:rested` for any remainder; a non-crossing limit order yields `:rested`; an order that cannot stand yields
`:rejected` with a closed reason. Fills carry both order ids (taker and maker) so the downstream log and the Go
workers can attribute both sides.

## Surface, pinned

```elixir
Exchange.Book.start_link(instrument :: binary(), opts :: keyword())
  # starts the instrument's Ring (or attaches), drains as the single writer

Exchange.Book.submit(instrument :: binary(), command())   # publishes to the Ring; :ok | :dropped
Exchange.Book.snapshot(instrument :: binary())            # the folded book state, for tests/projections

Exchange.Decider.decide(command(), book_state()) :: [event()]    # pure
Exchange.Decider.evolve(book_state(), event())      :: book_state()  # pure

Exchange.OrderBook.new() :: book_state()
Exchange.OrderBook.best(book_state(), :buy | :sell) :: {money(), [order]} | :empty   # pure reads
```

## Decomposition (the build order)

**Step one — `Exchange.OrderBook` (pure) first.** The price ladder per side (`gb_trees` keyed by price), level FIFOs
by mint order, and the read verbs (`best/2`, the account-order index over `EchoData.BrandedTree`); no matching yet,
the structure and its reads, property-tested for price-time ordering. **Step two — `Exchange.Decider` (pure).**
`decide/2` implementing the matching rule over an `OrderBook` state — cross, partial-fill, rest, reject — returning
events; `evolve/2` folding each event back; price-time priority, self-trade prevention, and fill arithmetic
property-tested over `decide` alone, no process. **Step three — `Exchange.Book` (the shell).** One GenServer per
instrument: start or attach the Ring, drain accepted items in order, `decide` then append then `evolve` then reply;
the single-writer and admission-reconcile properties live here. **Step four — the gate script**
`runtimes/elixir/trd_2_check.exs`: the gates below, one printed line each, nonzero exit on failure, transcript
committed; it uses `EchoCache.Ring`, a Valkey-independent in-BEAM buffer, so no external service is required unless a
later rung wires the log.

## Mars implementation notes

- The Decider is the heart and must stay pure: no `GenServer`, no `:ets`, no `System.monotonic_time`, no `Process.*`
  inside `decide`/`evolve`. A reviewer greps for these and they must be absent from the Decider module.
- Mint `FIL` ids at the fill, inside `decide`'s result construction via the canon; never construct ids by hand. Mint
  order is the only ordinal — do not read a clock to break ties; the maker's existing mint order already does.
- Money arithmetic is integer arithmetic over `{units, nano}`; normalize carry between `nano` and `units` with
  integer math, never float. A property asserts no float in any event.
- The Book replies to `submit` with the Ring's `:ok | :dropped` for admission, and surfaces fills/rests through the
  fold and `snapshot/1` (or a telemetry/event hook the log rung will consume). It does not block on downstream.
- One Lua script per multi-key Valkey transition is not in scope this rung — TRD.2 is in-BEAM matching; the log's
  atomicity is TRD.3. Keep the rung's surface BEAM-pure plus the Ring.

## The cross-runtime fill seam (the Go workers)

The Go workers (TInvest Go SDK clients, drained as EchoMQ jobs, reading through EchoCache; Go for numeric throughput
and GPU-accelerated money-math — mark-to-market, margin, risk, analytics) consume the *fills* this rung emits, not
the commands and not the book. The contract this rung fixes:

- **A fill is the unit of work handed outward.** A `:fill` event carries its own branded `FIL` id, both order ids,
  and `{units, nano}` money; downstream it becomes an EchoMQ job keyed by the `FIL` id (the at-least-once posture the
  lanes gate). The Decider emits the fact; the fact becomes the job — the Decider never calls a worker.
- **Integer money on both runtimes.** The Go side binds the same `{units, nano}` `Quotation`; no float crosses the
  boundary in either direction.
- **Claims, not objects** (Appendix G): a worker resolves instrument or account reference data through the store by
  id; the job carries the `FIL` id and the money, not the objects.

The job payload schema and the worker's idempotent-handler contract are the trading roadmap's worker rung; TRD.2
fixes only that fills are branded and money is integer, freezing the boundary the Go tier is built against.

## Acceptance gates (folded; the stories expand them)

- **G1 — two crossing orders fill.** A resting sell and a crossing buy at or through its price produce a `:fill` with
  the correct price (the maker's), the matched quantity, and a branded `FIL` id; the remainder rests.
- **G2 — price-time priority holds.** Among makers at one price, the earlier mint order fills first; among prices, the
  best fills first — asserted as a property over `decide`.
- **G3 — single writer.** Under concurrent `submit` from many processes, one Book applies all commands in a single
  order; no interleaved mutation is observable (a property over the fold).
- **G4 — admission reconciles.** After a flood that overflows the Ring, accepted == applied + `stats.dropped`,
  exactly; no command is silently lost.
- **G5 — no float.** No event or book-state value contains a float (structural assertion over a matched run).
- **G6 — self-trade prevented.** Two orders from the same account that would cross each other do not self-fill; the
  Decider's rule yields the closed-reason rejection or the configured prevention, asserted as a property.

## Map

Chapter: [`trd.2.md`](trd.2.md). Stories: [`trd.2.stories.md`](trd.2.stories.md). Runbook:
[`trd.2.llms.md`](trd.2.llms.md). Previous rung: [`trd.1.specs.md`](trd.1.specs.md). System:
[`exchange.specs.md`](exchange.specs.md). The Ring and the id law: Chapter 4.3 and Appendix F in
`bcs.toc.md`.
