# TRD.1 · The Gateway — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung TRD.1. The chapter ([`trd.1.md`](trd.1.md)) narrates it; the runbook
> ([`trd.1.llms.md`](trd.1.llms.md)) derives from it; the stories ([`trd.1.stories.md`](trd.1.stories.md)) are its
> acceptance gates. Feedback edits this file, not the implementation. **Status: PROPOSED.** Definition of done: a
> committed transcript at `runtimes/elixir/trd_1_check.out`, exit zero, every gate line green.

## Invariants

- **INV-1 — total parse.** `Exchange.Gateway` maps every input to either a typed command or one member of the closed
  error set. No exception escapes the parser; no partially-built command is ever returned; there is no third outcome.
- **INV-2 — typed money, never float.** Price is a `Quotation`-shaped `{units :: integer, nano :: integer}` from the
  first byte parsed. A value that does not parse to that pair is `{:error, :bad_price}`. No float appears in any
  Gateway type or reaches any downstream layer.
- **INV-3 — branded at acceptance.** A successful parse mints ids through `EchoData.Snowflake.next_branded/1` —
  `"CMD"` for the command, `"ORD"` for an order command — at the instant of acceptance. Mint order is the only
  sequence; the Gateway reads no clock and assigns no other ordinal.
- **INV-4 — opaque venue ids wrapped, not minted.** `instrument_id` and `account_id` are caller-supplied opaque
  strings (the venue's FIGI or instrument UID); the Gateway validates their presence and shape and carries them
  verbatim as future Keyspace hash tags. It does not brand them.
- **INV-5 — stateless boundary.** The Gateway owns no process state, no ETS, no store handle. It is a pure function
  plus a minting effect; the same input (modulo the minted id) parses identically every time.
- **INV-6 — idempotency seam preserved.** The minted command/order id is emitted in the field the external venue
  treats as its idempotency key (`PostOrderRequest.order_id`). The Gateway never discards or rewrites a caller-
  supplied idempotency token when one is presented for replay; it reconciles to the branded id.

## The command vocabulary (closed, grounded in the TInvest order contract)

```elixir
@type direction :: :buy | :sell                      # ORDER_DIRECTION_BUY | _SELL
@type order_type :: :limit | :market | :bestprice    # ORDER_TYPE_LIMIT | _MARKET | _BESTPRICE
@type money :: {units :: integer(), nano :: integer()}   # Quotation: never a float

@type command ::
        {:place, %{id: binary(), instrument: binary(), account: binary(),
                   direction: direction(), type: order_type(),
                   quantity: pos_integer(), price: money() | :market}}
      | {:cancel, %{id: binary(), instrument: binary(), order_ref: binary()}}
      | {:replace, %{id: binary(), instrument: binary(), order_ref: binary(),
                     quantity: pos_integer(), price: money()}}

@type error ::
        :unknown_instrument | :bad_direction | :bad_order_type
      | :nonpositive_quantity | :bad_price | :malformed
```

A market or best-price order carries `price: :market` (price ignored, per the venue contract); a limit or replace
carries a `money()`. Quantity is lots, strictly positive. The vocabulary is closed: a command kind outside
{place, cancel, replace} is `:malformed`.

## Surface, pinned

```elixir
Exchange.Gateway.parse_place(raw :: map())   :: {:ok, command()} | {:error, error()}
Exchange.Gateway.parse_cancel(raw :: map())  :: {:ok, command()} | {:error, error()}
Exchange.Gateway.parse_replace(raw :: map()) :: {:ok, command()} | {:error, error()}

# convenience: dispatch on a "kind" field, same return contract
Exchange.Gateway.parse(raw :: map())         :: {:ok, command()} | {:error, error()}
```

Every head returns the same tagged-tuple contract. The minting effect lives inside a successful parse; a rejection
mints nothing.

## Decomposition (the build order)

**Step one — the types and the money parser.** Define the command and error types; write `parse_money/1` first, the
sharpest edge (integer `units`/`nano` from string or integer-pair input, `:bad_price` otherwise), and the rest
composes over it. **Step two — the field parsers.** `parse_direction/1`, `parse_order_type/1`, `parse_quantity/1`,
each total into its slice of the error set; `parse_instrument/1` and `parse_account/1` for presence-and-shape of the
opaque ids (INV-4). **Step three — the command assemblers.** `parse_place/1` and its siblings compose the field
parsers with `with`, mint on success (INV-3), and return the closed contract; the idempotency reconciliation (INV-6)
lives here. **Step four — the gate script** `runtimes/elixir/trd_1_check.exs`: one line per gate below, nonzero exit
on any failure, transcript committed beside it; no Valkey needed, the Gateway is pure and the script is a
pure-ExUnit-shaped runner.

## Mars implementation notes

- Load order when the script loads the canon raw: `base62` → `native` → `snowflake` → `branded_id`, then the Gateway
  module. Settled; do not reorder.
- `with` + tagged tuples for assembly; the closed error set is the only failure channel — no `raise`, no `throw`, no
  `:error` bare atom. A clause that cannot classify an input returns `{:error, :malformed}`, never crashes.
- Money: parse to `{units, nano}` integers; reject anything else. Do not normalize, round, or scale here — the book
  and the workers share the raw `Quotation` shape, and scaling is their decision, not the door's.
- Mint exactly once per accepted command; never construct id strings by hand; never mint inside a rejection branch.
- The Gateway adds no dependency and no application-env config. It is one file plus its gate script.

## The cross-runtime contract (the Go-worker seam)

The Go workers (the external processor — TInvest Go SDK clients, drained as EchoMQ jobs, reading through EchoCache;
Go for numeric throughput and GPU-accelerated money-math) consume the *typed* command this rung emits, never raw
input. The shared contract this rung fixes:

- **Money is `{units, nano}` integers** on both runtimes — the venue's `Quotation`. No float crosses the boundary in
  either direction; the Go side binds the same two-integer shape.
- **The branded id is the job key and the idempotency key.** A pricing or risk job carries the command's branded id;
  a worker's result is keyed by it; a duplicate delivery collides on it (the at-least-once posture the bus and the
  lanes already gate). This is `PostOrderRequest.order_id` end to end.
- **Claims, not objects, on the bus** (Appendix G law): a worker that needs an instrument's reference data resolves a
  claim through the store; the command payload carries the id, not the object.

The job payload schema, the worker's idempotent-handler contract, and the result topic are specified at the trading
roadmap's worker rung; this rung fixes only the two invariants that boundary must honor — typed money and the
id-as-key — so the Go tier can be built against a frozen contract.

## Acceptance gates (folded; the stories expand them)

- **G1 — valid place parses and mints.** A well-formed limit buy yields `{:ok, {:place, m}}` with `m.id` a branded
  `ORD`/`CMD` id and `m.price` a `{units, nano}` pair. The same input twice yields two distinct ids (mint order).
- **G2 — each error is reachable and exact.** Six malformed inputs yield exactly the six error atoms, one each; no
  input yields a crash or an unclassified result.
- **G3 — no float survives.** A price given as a float-bearing input is `{:error, :bad_price}`; no Gateway output
  contains a float (asserted structurally over the parsed command).
- **G4 — market order ignores price.** A market order parses with `price: :market` regardless of any price field
  present, per the venue contract.
- **G5 — opaque ids carried verbatim.** Instrument and account strings appear in the command unchanged and unbranded
  (INV-4).
- **G6 — idempotency seam.** A caller-supplied replay token reconciles to the branded id rather than minting a second
  identity (INV-6).

## Map

Chapter: [`trd.1.md`](trd.1.md). Stories: [`trd.1.stories.md`](trd.1.stories.md). Runbook:
[`trd.1.llms.md`](trd.1.llms.md). Next rung: [`trd.2.specs.md`](trd.2.specs.md). System:
[`exchange.specs.md`](exchange.specs.md). The money/id canon: Appendix F in `bcs.toc.md`.
