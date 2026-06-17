# TRD.1.1 · The Gateway MVP — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung **TRD.1.1** — the first shippable slice of the Exchange Gateway ([`trd.1.specs.md`](trd.1.specs.md)
> is the full rung; this file is the MVP carve-out the build delivers now). The chapter ([`trd.1.1.md`](trd.1.1.md))
> narrates it. **Status: PROPOSED.** Definition of done: a committed transcript at
> `echo/rungs/exchange/trd_1_1_check.out`, exit zero, every gate line green — the same rung-gate pattern the BCS
> substrate rungs ship (`echo/rungs/cache/bcs_rung_4_1_check.exs` is the template). Feedback edits this file, not the
> implementation. **Framing (propagate this clause): third person for any agent; no gendered pronouns; no perceptual or
> interior-state verbs; no first-person narration.**

## What TRD.1.1 is — and is not

TRD.1.1 makes the Gateway real for the first time: a new lib-only umbrella app `echo/apps/exchange` holding one
stateless module `Exchange.Gateway`, parsing untrusted input into the two most load-bearing command kinds — **place**
(limit and market) and **cancel** — or one member of the closed six-atom error set, minting branded `CMD`/`ORD` ids at
acceptance through the canon. It is the thinnest vertical slice that proves the parse-don't-validate architecture end to
end and gives the `/bcs` B8 capstone a real `Exchange.*` door to stand on, where today it teaches a PROPOSED consumer
with no code.

**In TRD.1.1 (this slice):**

- the lib-only app `echo/apps/exchange` (the `echo_data` app shape: no supervision tree, no process, depends only on
  `{:echo_data, in_umbrella: true}`);
- `Exchange.Gateway` — the @types (`command`, `direction`, `order_type`, `money`, the closed `error`), `parse_money/1`,
  the field parsers (`parse_direction/1`, `parse_order_type/1`, `parse_quantity/1`, `parse_instrument/1`,
  `parse_account/1`), `parse_place/1` (limit **and** market), `parse_cancel/1`, and minting via
  `EchoData.Snowflake.next_branded/1`;
- gates **G1–G5 + cancel** and the totality property;
- the rung gate `echo/rungs/exchange/trd_1_1_check.exs` + its committed transcript.

**Deferred to TRD.1.2 (NOT built here — [RECONCILE]-marked, the full rung [`trd.1.specs.md`](trd.1.specs.md) carries
them):**

- `parse_replace/1` (the third command kind — a two-field overwrite of an open order);
- the `parse/1` kind-dispatcher (dispatch on a `kind` field across place/cancel/replace);
- `:bestprice` (the third `order_type`; the MVP `order_type` is `:limit | :market` only);
- the **INV-6 / G6 idempotency seam** — replay-token reconciliation and the venue `order_id` outward position. This
  carries a genuine design decision (how a caller presents a replay token, where the branded id sits in the outward
  command shape) and is given its own rung rather than guessed here.

The `order_type` and `command` @types are authored **wide** (they name `:bestprice` and `{:replace, …}` so the type is
the full vocabulary the platform speaks), but the **parsers** in this slice produce only the in-scope subset; a
`{:replace, …}` request or a `:bestprice` order_type resolves to `{:error, :malformed}` / `{:error, :bad_order_type}`
until TRD.1.2 wires its parser. This keeps the type stable across the 1.1→1.2 boundary while the parser surface grows.

## Invariants (the subset this slice gates)

Inherited verbatim from [`trd.1.specs.md`](trd.1.specs.md); the four this slice builds and gates:

- **INV-1 — total parse.** `Exchange.Gateway` maps every input to either a typed command or one member of the closed
  error set. No exception escapes the parser; no partially-built command is ever returned; there is no third outcome. A
  clause that cannot classify an input returns `{:error, :malformed}` — it never crashes.
- **INV-2 — typed money, never float.** Price is a `Quotation`-shaped `{units :: integer, nano :: integer}` from the
  first byte parsed. A value that does not parse to that integer pair is `{:error, :bad_price}`. No float appears in any
  Gateway type or any Gateway output.
- **INV-3 — branded at acceptance.** A successful parse mints ids through `EchoData.Snowflake.next_branded/1` — `"CMD"`
  for the command, `"ORD"` for an order command — at the instant of acceptance. Mint order is the only sequence; the
  Gateway reads no clock and assigns no other ordinal. A rejection mints nothing.
- **INV-4 — opaque venue ids wrapped, not minted.** `instrument` and `account` are caller-supplied opaque strings; the
  Gateway validates their presence and shape and carries them verbatim. It does not brand them.
- **INV-5 — stateless boundary.** The Gateway owns no process state, no ETS, no store handle, no application-env config,
  and adds no external dependency. It is a pure function plus a minting effect; the same input (modulo the minted id)
  parses identically every time.

**INV-6 (idempotency seam) is DEFERRED to TRD.1.2** and is the one parent-rung invariant this slice does not realize.
Recorded here so its absence is a decision, not an omission.

### The in-umbrella dep is a minting prerequisite, not the dependency AS-5 forbids

`{:echo_data, in_umbrella: true}` in `echo/apps/exchange/mix.exs` is **mandated by INV-3** — the Gateway mints through
`EchoData.Snowflake.*` / `EchoData.BrandedId.*`, so the edge is the minting prerequisite. The AS-5 prohibition is on a
**new external dependency + application-env config**; the single in-umbrella canon edge is neither. This reconcile note
is binding so a literal reading of AS-5 does not block the build.

## The command vocabulary (closed; the type is wide, the 1.1 parsers are the subset)

```elixir
@type direction :: :buy | :sell                      # ORDER_DIRECTION_BUY | _SELL
@type order_type :: :limit | :market | :bestprice    # ORDER_TYPE_LIMIT | _MARKET | _BESTPRICE
                                                      #   1.1 parsers: :limit | :market only
@type money :: {units :: integer(), nano :: integer()}   # Quotation: never a float

@type command ::
        {:place, %{id: binary(), instrument: binary(), account: binary(),
                   direction: direction(), type: order_type(),
                   quantity: pos_integer(), price: money() | :market}}
      | {:cancel, %{id: binary(), instrument: binary(), order_ref: binary()}}
      | {:replace, %{id: binary(), instrument: binary(), order_ref: binary(),
                     quantity: pos_integer(), price: money()}}   # type wide; parser is TRD.1.2

@type error ::
        :unknown_instrument | :bad_direction | :bad_order_type
      | :nonpositive_quantity | :bad_price | :malformed
```

A market order carries `price: :market` (price ignored, per the venue `PostOrderRequest` contract); a limit order
carries a `money()`. Quantity is lots, strictly positive. The vocabulary is closed: a command kind outside
{place, cancel} in this slice is `{:error, :malformed}` (the `{:replace, …}` constructor exists in the type but has no
1.1 parser).

## The surface Mars builds (exact — cite a line per call)

```elixir
# Public command parsers (TRD.1.1) — same tagged-tuple contract:
Exchange.Gateway.parse_place(raw :: map())   :: {:ok, command()} | {:error, error()}
Exchange.Gateway.parse_cancel(raw :: map())  :: {:ok, command()} | {:error, error()}

# Field parsers (public or private — Mars's call; cited by the gate either way):
Exchange.Gateway.parse_money(term())         :: {:ok, money()} | {:error, :bad_price}
Exchange.Gateway.parse_direction(term())     :: {:ok, direction()} | {:error, :bad_direction}
Exchange.Gateway.parse_order_type(term())    :: {:ok, order_type()} | {:error, :bad_order_type}
Exchange.Gateway.parse_quantity(term())      :: {:ok, pos_integer()} | {:error, :nonpositive_quantity}
Exchange.Gateway.parse_instrument(term())    :: {:ok, binary()} | {:error, :unknown_instrument}
Exchange.Gateway.parse_account(term())       :: {:ok, binary()} | {:error, :malformed}
```

**Contract, every public head:** precondition — `raw` is a map (any other input → `{:error, :malformed}`, never a
crash); postcondition — exactly one of `{:ok, command()}` or `{:error, error()}`; invariant — the minting effect lives
inside the `{:ok, …}` branch only, a rejection mints nothing. The field parsers each return `{:ok, slice}` or one error
atom of their slice; `parse_place/1` and `parse_cancel/1` compose them with a `with` chain and mint on success.

**Pinned details:**

- `parse_money/1` accepts an integer-pair `{units, nano}` (both integers) **or** a string the venue would send for a
  `Quotation` (Mars chooses the exact string grammar — at minimum a `"units.nano"`-style decimal string that parses to
  two integers); anything else, including any float-bearing input, is `{:error, :bad_price}`. No rounding, scaling, or
  normalization at the door — the book and the workers share the raw `Quotation` shape.
- `parse_order_type/1` maps `:limit`/`:market` (and the venue's `ORDER_TYPE_LIMIT`/`_MARKET` string forms Mars elects)
  to the atom; `:bestprice` / any unknown → `{:error, :bad_order_type}` in this slice.
- A market order returns `price: :market` regardless of any price field present (G4); a limit order requires a parsed
  `money()`.
- `parse_account/1`'s failure folds into `:malformed` (the closed set has no dedicated account atom — INV-4 presence
  failure is a malformed command, not a distinct error class).
- Minting: `EchoData.Snowflake.start(node_id \\ nil)` once per runtime (the gate script calls
  `EchoData.Snowflake.start(N)`), then `EchoData.Snowflake.next_branded("CMD")` and `…("ORD")` inside the success branch
  only. Never construct id strings by hand. The equivalent idiom `EchoData.BrandedId.generate!/1` exists; the spec pins
  `next_branded/1`.

## Decomposition (the build order)

**Step one — the types and the money parser.** Define the @types above (wide); write `parse_money/1` first — the
sharpest edge — `{:ok, {units, nano}}` from integer-pair or integer-string input, `{:error, :bad_price}` otherwise. The
rest composes over it.

**Step two — the field parsers.** `parse_direction/1`, `parse_order_type/1` (`:limit | :market` in scope),
`parse_quantity/1` (strictly positive lots), each total into its slice of the error set; `parse_instrument/1` and
`parse_account/1` for presence-and-shape of the opaque ids (INV-4).

**Step three — the command assemblers.** `parse_place/1` (limit **and** market) and `parse_cancel/1` compose the field
parsers with `with`, mint `CMD`/`ORD` on success (INV-3), and return the closed contract. No `parse_replace/1`, no
`parse/1` dispatcher in this slice.

**Step four — the gate script** `echo/rungs/exchange/trd_1_1_check.exs`: one printed line per gate below, nonzero exit
on any failure, transcript committed to `echo/rungs/exchange/trd_1_1_check.out`. The Gateway is pure and touches no
Valkey, so the script is a `mix run --no-start` runner that `Code.require_file`s the canon raw
(`base62 → native → snowflake → branded_id`) then the Gateway module, calls `EchoData.Snowflake.start(N)`, and runs the
gates. (Contrast the cache rung-gate template, which boots a `Connector` on 6390 — this slice needs none.)

## Mars implementation notes (binding)

- **Scaffold the app the `echo_data` way.** `echo/apps/exchange/mix.exs` mirrors `echo/apps/echo_data/mix.exs` (shared
  `build_path: "../../_build"`, `config_path`, `deps_path: "../../deps"`, `lockfile: "../../mix.lock"`,
  `elixir: "~> 1.18"`), `app: :exchange`, `deps: [{:echo_data, in_umbrella: true}]`, and a minimal
  `application/0` (`extra_applications: [:logger]`, **no `mod:`** — the Gateway starts nothing). The umbrella
  auto-discovers it via `apps_path: "apps"` (`echo/mix.exs`). Module root `Exchange.*`. A test file under
  `echo/apps/exchange/test/`.
- **`with` + tagged tuples for assembly;** the closed error set is the only failure channel — no `raise`, no `throw`, no
  bare `:error` atom. A clause that cannot classify returns `{:error, :malformed}`, never crashes.
- **Mint exactly once** per accepted command; never inside a rejection branch; never build id strings by hand.
- **No float** in any Gateway type or output; do not round or scale money at the door.
- **No process, no ETS, no app-env, no new external dependency** introduced by this rung (the lone `{:echo_data,
  in_umbrella: true}` edge is the sanctioned minting prerequisite, above).
- Do not print exclamation marks or forbidden-voice words in gate output lines a chapter may later quote.

## Acceptance gates (the rung gate — one printed line each)

- **G1 — valid place parses and mints.** A well-formed limit buy yields `{:ok, {:place, m}}` with `m.id` a branded id
  (`CMD`/`ORD` namespace, 14 bytes, `BrandedId.valid?/1` true) and `m.price` a `{units, nano}` integer pair. The same
  input twice yields **two distinct ids** (mint order). *(INV-1, INV-2, INV-3)*
- **G2 — each error is reachable and exact.** Six malformed inputs yield exactly the six error atoms
  (`:unknown_instrument`, `:bad_direction`, `:bad_order_type`, `:nonpositive_quantity`, `:bad_price`, `:malformed`),
  one each; no input yields a crash or an unclassified result. *(INV-1)*
- **G3 — no float survives.** A price given as a float-bearing input is `{:error, :bad_price}`; no Gateway output
  contains a float (asserted structurally over the parsed command term). *(INV-2)*
- **G4 — market order ignores price.** A market order parses with `price: :market` regardless of any price field
  present, per the venue contract. *(INV-1)*
- **G5 — opaque ids carried verbatim.** Instrument and account strings appear in the command unchanged and unbranded
  (`BrandedId.parse/1` is never called on them). *(INV-4)*
- **cancel — `parse_cancel/1` parses.** A well-formed cancel yields `{:ok, {:cancel, m}}` with a branded `m.id` and the
  opaque `order_ref` and `instrument` carried verbatim. *(INV-1, INV-3, INV-4)*
- **totality property (StreamData).** Over generated inputs (well-formed and malformed maps, wrong-typed fields,
  missing keys), every `parse_place/1` and `parse_cancel/1` output is either `{:ok, command()}` or `{:error, error()}`
  with the error atom in the closed set — never a crash, never a float, never a partial command. *(INV-1, INV-2, INV-5)*
- **AS-5 statelessness grep.** A grep over `echo/apps/exchange/lib/` shows no `use GenServer`, no `:ets`, no
  `Application.get_env`, and `echo/apps/exchange/mix.exs` `deps/0` lists exactly `{:echo_data, in_umbrella: true}` —
  no new external dependency. *(INV-5)*

G6 (idempotency seam) is **DEFERRED to TRD.1.2** — not a gate of this slice.

## The cross-runtime contract (named, not built here)

This slice fixes the two invariants the later Go-worker boundary honors — money is `{units, nano}` integers on both
runtimes, and the branded id is the job key and the venue idempotency key (`PostOrderRequest.order_id`) — by realizing
INV-2 and INV-3 in the door. The job payload schema, the worker's idempotent-handler contract, and the result topic are
a later rung's ([`exchange.roadmap.md`](exchange.roadmap.md)); do not invent them here. The idempotency *seam* itself
(INV-6) lands at TRD.1.2.

## Map

Chapter: [`trd.1.1.md`](trd.1.1.md). The full rung: [`trd.1.specs.md`](trd.1.specs.md) ·
[`trd.1.stories.md`](trd.1.stories.md) · [`trd.1.llms.md`](trd.1.llms.md). The next rung (the Ring and the book):
[`trd.2.specs.md`](trd.2.specs.md). System: [`exchange.specs.md`](exchange.specs.md). The money/id canon: Appendix F in
`bcs.toc.md`. The capstone this slice grounds: `/bcs` B8 (`docs/echo/bcs/bcs.toc.md`).
