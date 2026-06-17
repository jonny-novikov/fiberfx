# TRD.2.1 · The Pure Matching Core — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung **TRD.2.1** — the first shippable slice of TRD.2 ([`trd.2.specs.md`](trd.2.specs.md) is the full
> rung; this file is the pure-core carve-out the build delivers now). The chapter ([`trd.2.1.md`](trd.2.1.md)) narrates
> it. **Status: PROPOSED.** Definition of done: a committed transcript at `echo/rungs/exchange/trd_2_1_check.out`, exit
> zero, every gate line green — the same rung-gate pattern TRD.1.1 ships (`echo/rungs/exchange/trd_1_1_check.exs` is the
> template). Feedback edits this file, not the implementation. **Framing (propagate this clause): third person for any
> agent; no gendered pronouns; no perceptual or interior-state verbs; no first-person narration.**

## What TRD.2.1 is — and is not

TRD.2.1 ships the pure heart of the matching engine standalone: two modules and no process. `Exchange.OrderBook` — the
per-side `gb_trees` price ladder, each level a FIFO by branded mint order, with the pure read verbs — and
`Exchange.Decider` — `decide/2` + `evolve/2`, the matching rule as a pure function over events. It matches the typed
`{:place, …}` command (limit and market) into fill / rest / reject events over `{units, nano}` money, minting a branded
`FIL` id at each fill. It is the thinnest slice that proves the matching rule correct and is exhaustively
property-testable without starting a single process.

**In TRD.2.1 (this slice):**

- `echo/apps/exchange/lib/exchange/order_book.ex` — `Exchange.OrderBook`: the `@type`s (`book_state`, `resting`, `side`,
  `money`), `new/0`, `best/2`; per-side `gb_trees` keyed by price; each price level a FIFO resolved by branded mint order;
  a resting entry carries at least `{id, account, side, price, quantity}` (`account` REQUIRED — self-trade detection);
- `echo/apps/exchange/lib/exchange/decider.ex` — `Exchange.Decider`: the `@type`s (`command`, `event`, `money`),
  `decide/2` (cross / partial-fill / rest-limit-remainder / reject), `evolve/2` (fold one event), minting `FIL` via the
  canon at each `:fill`;
- gates **G1, G2, G5, G6 + AS-2 (pure-grep) + AS-7 (fill-key freeze)** and the matching properties;
- the rung gate `echo/rungs/exchange/trd_2_1_check.exs` + its committed transcript.

**Deferred to TRD.2.2 (NOT built here — the full rung [`trd.2.specs.md`](trd.2.specs.md) carries them; named in the
chapter's "Deferred to TRD.2.2"):**

- `Exchange.Book` — the GenServer single writer that drains the `EchoCache.Ring` (INV-1, gate G3, story AS-3);
- the `EchoCache.Ring` drain + admission-reconcile (INV-2, INV-7, gate G4, story AS-4);
- cancel-against-the-book matching (`:cancel` pairs with the Book's order lifecycle + the per-account index);
- the per-account `EchoData.BrandedTree` index (`first/2`, `last/2`, `page_after/4` — cancel/queries);
- `Exchange.OrderBook.snapshot`/`Exchange.Book.submit`/`Exchange.Book.start_link` — the stateful surface in
  [`trd.2.specs.md`](trd.2.specs.md) "Surface, pinned" is not built this rung.

The boundary is the Director's Stage-3 reconcile target: no `Exchange.Book`, no Ring code, no cancel matching, no
`BrandedTree` index in this rung's diff.

## Invariants (the subset this slice gates)

Inherited verbatim from [`trd.2.specs.md`](trd.2.specs.md); the four this slice builds and gates:

- **INV-3 — pure decision.** `Exchange.Decider.decide/2` and `evolve/2` are side-effect-free, modulo the single sanctioned
  `FIL` mint inside `decide` (the same id-effect the Gateway is granted at TRD.1.1). No process, no store, no clock the
  Decider itself reads, no IO. A grep over `decider.ex` for `GenServer`, `:ets`, `System.monotonic_time`,
  `System.os_time`, `Process.` is empty (AS-2). `decide` returns events; `evolve` folds one event into state. Matching
  rules live only here.
- **INV-4 — fold is state.** The book's state equals the fold of `evolve` over the events `decide` has emitted, in mint
  order. There is no state reachable except through the fold. (The end-to-end replay property is TRD.3's to gate; this
  rung gates it over `decide` directly.)
- **INV-5 — price-time from the id.** Price priority is the ladder's key order; time priority within a level is branded
  mint order (the Gateway's `ORD` stamp, TRD.1.1). The book holds no clock and no comparator beyond the id byte order
  (Appendix F).
- **INV-6 — typed money, never float.** Prices and fills carry `{units, nano}` integers (the venue `Quotation`). No float
  appears in any book type, event, or fold (structural assertion over a matched run, G5).

**Deferred to TRD.2.2 (named so their absence is a decision, not an omission):** INV-1 (single writer per instrument),
INV-2 (admission reconciles), INV-7 (overload is an answer) — all three are properties of the Ring-draining Book, which
this rung does not build.

### The Go-seam freeze (the contract this slice fixes, not a numbered INV)

Every `:fill` event carries a branded `FIL` id (namespace `"FIL"`, `BrandedId.valid?/1` true) and `{units, nano}` integer
money, so a downstream job is keyable by the fill id and no float crosses the boundary (story AS-7). The Decider emits the
fact; the fact becomes the job (the schema is a later rung's). This is the boundary the Go pricing/risk tier is built
against.

## The command this rung consumes (TRD.1.1, as-built — pinned, not rebuilt)

```elixir
# Exchange.Gateway, echo/apps/exchange/lib/exchange/gateway.ex (TRD.1.1, as-built):
@type money :: {units :: integer(), nano :: integer()}     # gateway.ex:41 — never a float
@type direction :: :buy | :sell                            # gateway.ex:31
@type order_type :: :limit | :market | :bestprice          # gateway.ex:38 (parsers emit :limit | :market)

{:place, %{id: binary(), instrument: binary(), account: binary(),
           direction: direction(), type: order_type(),
           quantity: pos_integer(), price: money() | :market}}   # gateway.ex:47-57
```

`Exchange.Decider.decide/2` consumes the `{:place, …}` command. A **limit** place arrives with `price: {units, nano}`; a
**market** place arrives with `price: :market` (the atom). `direction: :buy` is an order to buy (it lifts the sell side /
asks); `direction: :sell` is an order to sell (it hits the buy side / bids). `account` is the self-trade key. The id is
the aggressor's branded `ORD` id (minted at the Gateway), and it is the time component of price-time priority. This rung
matches `:place` only; `:cancel` and `:replace` are TRD.1.2 / TRD.2.2.

## The event vocabulary (the Decider's output — authoritative)

```elixir
@type money :: {integer(), integer()}                       # Quotation; from TRD.1.1, never a float (INV-6)

@type event ::
        {:fill,    %{taker: binary(), maker: binary(), instrument: binary(),
                     price: money(), quantity: pos_integer(), id: binary()}}
      | {:rested,  %{order: binary(), account: binary(), instrument: binary(),
                     side: :buy | :sell, price: money(), quantity: pos_integer()}}
      | {:rejected, %{order: binary(), reason: reject_reason()}}

@type reject_reason :: :self_trade | :no_liquidity          # CLOSED — no other reason atom this rung
```

- A `:fill` carries **both** order ids — `taker` (the aggressor's `ORD` id) and `maker` (the resting order's id) — so the
  downstream log and the Go workers attribute both sides; `price` is the **maker's** resting price; `id` is the `FIL` id
  minted at the fill.
- A `:rested` is the unfilled remainder of a **limit** order, at its limit price; `order` is the resting order's id and
  `account` its placing account. The `account` rides the event because the book is the EXTERNAL fold of `evolve` over the
  emitted events (INV-4) and the resting `t:resting/0` tuple MUST carry `account` for self-trade detection (D-2) — a value
  the fold cannot recover from the `order` id alone (D-8). This widens the original literal (which omitted `account`);
  the frozen Go-seam contract (AS-7) is on `:fill` only, so a `:rested` field breaks no frozen surface.
- A `:rejected` carries one member of the closed `reject_reason()` set: `:self_trade` (D-2) or `:no_liquidity` (D-4). No
  other reason atom is emitted this rung.

## Surface, pinned (exact — Mars cites a line per call)

```elixir
# Pure ladder ─────────────────────────────────────────────────────────────────
Exchange.OrderBook.new()                              :: book_state()
Exchange.OrderBook.best(book_state(), :buy | :sell)   :: {money(), [resting()]} | :empty
#   per-side gb_trees keyed by price; each level a FIFO by branded mint order.
#   best/2 reads the top of a side: the best price + its level's FIFO (price-time
#   ordered), or :empty. A resting() entry carries at least
#   {id, account, side, price, quantity} — account REQUIRED (self-trade, INV-6/G6).
#   The BrandedTree per-account index (cancel/queries) is TRD.2.2, NOT this rung.

# Pure decider (pure modulo the FIL mint, INV-3) ───────────────────────────────
Exchange.Decider.decide(command(), book_state())     :: [event()]
Exchange.Decider.evolve(book_state(), event())       :: book_state()
#   decide/2 handles {:place, …} (limit + market): cross / partial-fill /
#   rest(limit remainder) / reject(self-trade | market-no-liquidity).
#   evolve/2 folds ONE event into state; book state == fold of evolve over the
#   emitted events in mint order (INV-4). No state reachable except through the fold.
```

`book_state()`, `resting()`, `command()`, `event()`, `money()`, `reject_reason()` are Mars's `@type`s (their concrete
representation is Mars's call — `book_state()` is a struct or a two-`gb_trees` map, `resting()` a tuple or a small struct;
the contract is the public arities + the event/money shapes above, not the internal representation). `best/2` and any
ladder read are **pure reads** — no mint, no effect.

## The matching rule (locked — Venus records each as a `tool_x_decision`)

Each rule below is a locked D-n in `docs/exchange/trd-2-1.progress.md`; Mars implements them, the gates verify them.

1. **Slice boundary (D-1).** `Exchange.OrderBook` + `Exchange.Decider` (pure) only; the Book / Ring drain / admission /
   cancel / `BrandedTree` index defer to TRD.2.2.
2. **Fill price = the maker's; one `:fill` per maker (D-6).** An aggressor crossing N makers emits N `:fill` events, each
   at that maker's resting price and each with its own branded `FIL` id, in price-time order of the makers consumed (best
   price first; within a price, earliest mint order first). `quantity` per fill is `min(maker remaining, taker remaining)`.
3. **Limit remainder rests; market remainder never rests (D-4).** A **limit** place crosses all opposite-side liquidity at
   or through its limit price; any unfilled remainder RESTS as `{:rested, …}` at its limit price (becoming a maker). A
   **market** place crosses available liquidity at maker prices in price-time order and NEVER rests; if quantity remains,
   the remainder yields `{:rejected, %{order, reason: :no_liquidity}}` (a market order is unpriced — a resting market entry
   has no ladder key).
4. **Self-trade = reject the aggressor, book unchanged (D-2).** A place that would cross a resting order of the SAME
   `account` is rejected in full — `[{:rejected, %{order: <taker id>, reason: :self_trade}}]`, NO `:fill`, NO `:rested`,
   the book byte-unchanged (all-or-nothing; no partial fill against others ahead of the self-cross). Detection needs the
   maker's `account`, which the resting entry carries.
5. **Closed `:rejected` reason set (D-3).** `reject_reason()` is exactly `:self_trade | :no_liquidity`; `decide/2` emits no
   other reason atom. A limit order with no cross does NOT reject — it rests.
6. **Pure modulo the mint (D-5).** The `FIL` id is minted INSIDE `decide` via `EchoData.Snowflake.next_branded("FIL")`
   (snowflake.ex:104) at the instant a `:fill` is constructed — the sole sanctioned effect. `evolve` mints nothing. The
   forbidden-effect set (`GenServer`, `:ets`, `System.monotonic_time`, `System.os_time`, `Process.`) is empty in
   `decider.ex`. Properties never assert id-equality across two `decide` calls.
7. **No float (INV-6).** No event field and no book-state value is a float; money arithmetic is integer over `{units,
   nano}` with integer carry between `nano` and `units`.

## Decomposition (the build order)

**Step one — `Exchange.OrderBook` (pure) first.** The price ladder per side (`gb_trees` keyed by price), the level FIFOs
by mint order, the `@type`s, and the read verbs (`new/0`, `best/2`). No matching yet — the structure and its reads,
property-tested for price-time ordering (a generated set of resting orders reads back best-price-first, earliest-mint-first
within a price). A resting entry carries `{id, account, side, price, quantity}`. **Step two — `Exchange.Decider` (pure).**
`decide/2` implementing the matching rule over an `OrderBook` state — cross, partial-fill, rest a limit remainder, reject
(self-trade, market-no-liquidity) — returning events; `evolve/2` folding each event back. Price-time priority, self-trade
prevention, the maker-price rule, and fill arithmetic property-tested over `decide` alone, no process. Mint `FIL` inside
`decide`. **Step three — the gate script** `echo/rungs/exchange/trd_2_1_check.exs`: the gates below, one printed line each,
nonzero exit on failure, transcript committed; a self-contained deterministic generator (no StreamData dep in the gate —
the `trd_1_1_check.exs` pattern: `mix run --no-start`, `Code.require_file` the canon raw then `order_book.ex` +
`decider.ex`, `Snowflake.start(N)`, a `G.line/3` helper, the `G.no_float?/1` structural scanner).

## Mars implementation notes (binding)

- **Scaffold nothing new.** Both modules go in the existing `echo/apps/exchange` app (the TRD.1.1 app), module root
  `Exchange.*`. No new app, no new dependency, no `mod:` boot module — these are pure modules the (future) Book calls.
  Tests under `echo/apps/exchange/test/exchange/` (`order_book_test.exs`, `decider_test.exs`).
- **Mirror the `gateway.ex` house style.** Moduledoc cites `docs/exchange/trd.2.1.specs.md`; a `@typedoc` per `@type`;
  INV/D citations inline at the rule they realize (e.g. `# D-6 / G1: fill at the maker's price`).
- **Integer money carry.** Arithmetic over `{units, nano}` is integer arithmetic; normalize carry between `nano` (0..10^9)
  and `units` with integer math (`div`/`rem`), never float. A property asserts no float in any event or book value (G5).
  This rung's matching does not itself add money (a fill carries the maker's price verbatim), but any comparison or
  arithmetic over `{units, nano}` stays integer.
- **Compare prices as the ordered key.** Price comparison for crossing and for ladder order is over the `{units, nano}`
  pair (lexicographic on `units` then `nano`, both integers) — never a float conversion. `gb_trees` orders by Erlang term
  order, which already orders `{units, nano}` tuples correctly for non-negative prices; document the comparison.
- **Mint the FIL inside `decide`'s result construction.** `EchoData.Snowflake.next_branded("FIL")` at the moment each
  `:fill` map is built; never construct an id by hand; never read a clock to break a tie — the maker's existing mint order
  (its `ORD` id byte order) already breaks it.
- **The forbidden-effect set is empty in `decider.ex`.** No `use GenServer`, no `:ets`, no `System.monotonic_time`, no
  `System.os_time`, no `Process.` — the FIL mint is the sole effect (AS-2). `order_book.ex` is fully pure (no mint).
- **`decide` is total over `:place`.** Every `{:place, …}` command yields a non-empty `[event()]` — a list of `:fill`s,
  optionally a `:rested`, or a single `:rejected`. It never crashes and never returns a partial/un-tagged result.
- Do not print exclamation marks or forbidden-voice words in gate output lines a chapter may later quote.

## Acceptance gates (the rung gate — one printed line each)

- **G1 — two crossing orders fill at the maker's price.** A resting sell and a crossing buy at or through its price produce
  a `:fill` with the **maker's** price, the matched quantity, and a branded `FIL` id; the limit remainder of the larger
  order rests. *(INV-4, INV-5, INV-6, the Go-seam freeze)* — a property + the gate line.
- **G2 — price-time priority holds.** A property over `decide`: among makers at one price, the earlier mint order
  (`ORD`-id byte order) fills first; among prices, the best fills first. *(INV-5)*
- **G5 — no float.** A structural assertion over a matched run: no event field and no book-state value is a float
  (`G.no_float?/1` over the events and the folded book). *(INV-6)*
- **G6 — self-trade prevented.** A property: two same-account crossing orders do not self-fill; the aggressor is rejected
  `{:rejected, %{reason: :self_trade}}`, the book unchanged (the fold of `evolve` over the emitted events leaves the input
  book). *(INV-6, D-2)*
- **AS-2 — pure-grep.** A grep over `decider.ex` (code, comments stripped — the `trd_1_1_check.exs:250` `strip_comments`
  idiom) shows no `GenServer`, `:ets`, `System.monotonic_time`, `System.os_time`, or `Process.`; the FIL mint
  (`next_branded`) is the sole sanctioned effect. *(INV-3, D-5)*
- **AS-7 — fill-key freeze.** Every `:fill` event carries a branded `FIL` id (`BrandedId.namespace(id) == "FIL"`,
  `BrandedId.valid?(id)`, 14 bytes) and `{units, nano}` integer money; no `:fill` is emitted without an id. *(the Go-seam
  freeze)*

**Deferred to TRD.2.2 (named — they need the Book):** **G3 — single writer** (one Book applies all commands in one order
under concurrent submits, no interleaving) and **G4 — admission reconciles** (after a Ring flood, accepted == applied +
`stats.dropped`, exactly).

## The cross-runtime contract (named, not built here)

This slice fixes the part of the Go-worker boundary a pure function can fix: a `:fill` carries a branded `FIL` id and
integer `{units, nano}` money (AS-7), so downstream it becomes an EchoMQ job keyed by the `FIL` id, carrying the money
verbatim — the Decider emits the fact, the fact becomes the job, the Decider never calls a worker. Integer money on both
runtimes; claims (not objects) for reference data (Appendix G). The job payload schema, the worker's idempotent-handler
contract, and the result topic are a later rung's; do not invent them here.

## Definition of done

`cd echo/apps/exchange && TMPDIR=/tmp mix test` green (per-app discipline; umbrella-wide `mix test` BANNED);
`cd echo && mix run --no-start rungs/exchange/trd_2_1_check.exs` → `PASS k/k`, exit 0, transcript committed to
`echo/rungs/exchange/trd_2_1_check.out`; G1/G2/G5/G6 + AS-2 pure-grep + AS-7 all green; the `decider.ex` forbidden-effect
grep empty; no float anywhere in a matched run; the slice boundary held (no `Exchange.Book`, no Ring code, no cancel
matching, no `BrandedTree` index this rung). `cd echo && TMPDIR=/tmp mix compile --warnings-as-errors` clean.

## Map

Chapter: [`trd.2.1.md`](trd.2.1.md). The full rung: [`trd.2.specs.md`](trd.2.specs.md) · [`trd.2.stories.md`](trd.2.stories.md)
· [`trd.2.llms.md`](trd.2.llms.md). Previous rung (the command this slice consumes): [`trd.1.1.specs.md`](trd.1.1.specs.md).
System: [`exchange.specs.md`](exchange.specs.md). The order theorem and the Ring: Appendix F and Chapter 4.3 in
`bcs.toc.md`. The canon (the `FIL` mint): `echo/apps/echo_data/lib/echo_data/snowflake.ex:104`.
