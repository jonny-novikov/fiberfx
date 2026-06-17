# trd.1 — the agent guide (building the Gateway)

> Derived from [`trd.1.specs.md`](trd.1.specs.md) (authoritative) and the chapter ([`trd.1.md`](trd.1.md)). Real
> arities only — every surface below is defined in the spec at the cited shape. **Framing (propagate this clause):**
> third person for any agent; no gendered pronouns; no perceptual or interior-state verbs; no first-person narration.
> This guide builds a NEW boundary module on the canon — it does not edit the canon.

## References (read first, in order)

- `contract/contract.md` — the identity canon: branded ids, the order theorem, the kind law. **First.**
- `docs/bcs/exchange.specs.md` — the system the Gateway is the door of; the master invariant.
- `docs/bcs/trd.1.md` + `docs/bcs/trd.1.specs.md` — this rung's chapter and its authoritative spec.
- `runtimes/elixir/lib/echo_data/snowflake.ex` · `branded_id.ex` — the minting and parse surface to build ON, not to edit.
- The TInvest order contract (the cloned `investAPI` repo, `src/docs/contracts/orders.proto` and `common.proto`) — the source of the command vocabulary and the `Quotation` money type. Ground the verb set against it; invent no field.

## The surface (exact, as the spec pins it)

- `Exchange.Gateway.parse_place(raw) :: {:ok, {:place, map}} | {:error, error}` — and `parse_cancel/1`,
  `parse_replace/1`, plus `parse/1` dispatching on a kind field, all the same tagged-tuple contract.
- `error` is the closed set `:unknown_instrument | :bad_direction | :bad_order_type | :nonpositive_quantity |
  :bad_price | :malformed`. Nothing outside it; no exception path.
- Money is `{units :: integer, nano :: integer}` — the venue `Quotation`. A market/best-price order carries
  `price: :market`. No float in any output.
- Minting: `EchoData.Snowflake.start(node_id \\ nil)` once per runtime, then `Snowflake.next_branded("CMD")` and
  `"ORD"` inside the success branch only. Never build id strings by hand; never mint in a rejection.

## Requirements pattern (each traces to an invariant)

- **R-total** (INV-1). Every input maps to a typed command or one error atom. The classify-failure fallback is
  `{:error, :malformed}` — never a crash, never a partial command.
- **R-money** (INV-2). `parse_money/1` is written first and returns `{units, nano}` integers or `:bad_price`. No
  rounding, scaling, or normalization at the door.
- **R-mint** (INV-3). Mint once, at acceptance, via the canon. Mint order is the only sequence; read no clock.
- **R-opaque** (INV-4). Instrument and account strings are carried verbatim, never branded, never rewritten.
- **R-pure** (INV-5). One module, no process, no ETS, no store handle, no app-env, no new dependency.
- **R-idem** (INV-6). A caller replay token reconciles to the branded id; that id rides the venue's `order_id`
  position outward.
- **R-prove**. A gate script in the rung pattern — one printed line per gate (G1–G6), exit nonzero on failure, output
  committed beside it.

## Execution topology

The Gateway is a pure boundary, not a supervised child — it starts nothing. The only runtime prerequisite is
`Snowflake.start/1` once per node before the first parse (the same boot step every BCS runtime takes). The Gateway's
output is handed to the instrument Ring built in TRD.2; its rejections return to the caller. No store, no bus, no
Valkey is touched by this rung.

## The Go-worker boundary (do not build here; honor its contract)

The external processor is a Go worker fleet (TInvest Go SDK clients, drained as EchoMQ jobs, reading through
EchoCache; Go for numeric throughput and GPU-accelerated math). This rung does not build it. This rung fixes the two
invariants that boundary honors: money is `{units, nano}` integers on both runtimes, and the branded id is the job
key and the venue idempotency key. A worker consumes the typed command — it never parses raw input. The job payload
schema is a later rung's; do not invent it here.

## Do NOT

- Do not edit the canon (`snowflake.ex`, `branded_id.ex`, `base62`, `native`) or any committed check output — this
  rung is additive.
- Do not write a second parser, hash, clock, or money type — the canon and the venue `Quotation` are single-source.
- Do not let a float enter any Gateway type or output; do not round or scale money at the door.
- Do not mint inside a rejection branch; do not construct id strings by hand.
- Do not start a process, open ETS, read app-env, or add a dependency in this rung.
- Do not print exclamation marks or forbidden-voice words in check output lines a chapter may later quote.

## Agent stories (Directive + Acceptance gate)

- **AS-1 — the money parser first.** *Directive:* write `parse_money/1`; property-test that every output is a
  two-integer pair or `:bad_price`, never a float. *Gate:* the property holds, the line prints green, exit zero.
- **AS-2 — every error reachable.** *Directive:* six inputs to six atoms, plus a totality property. *Gate:* G2 shows
  six exact matches; no input crashes or returns unclassified; exit zero.
- (AS-3…AS-6 in [`trd.1.stories.md`](trd.1.stories.md) — mint-once, opaque-ids, stateless, idempotency-seam — carry
  the same gate-and-exit contract.)

## Map

Spec: [`trd.1.specs.md`](trd.1.specs.md). Chapter: [`trd.1.md`](trd.1.md). Stories:
[`trd.1.stories.md`](trd.1.stories.md). Next rung: [`trd.2.llms.md`](trd.2.llms.md).
