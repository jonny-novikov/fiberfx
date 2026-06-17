# TRD.1 · Stories — the Gateway

<show-structure depth="2"/>

> Acceptance stories for rung TRD.1, two audiences. **Developer stories** are written for a human engineer reading
> the platform. **Agent stories** are written for a Claude agent building under the house loop — third person, no
> gendered pronouns, no perceptual or interior-state verbs, no first-person narration. Both trace to the invariants
> and gates in [`trd.1.specs.md`](trd.1.specs.md). **Status: PROPOSED.**

## Developer stories

**DS-1 — a desk submits a limit order.** As a trading-desk client, I submit a limit buy for an instrument with a
quantity and a price, and I receive back a typed command carrying a branded order id I can track end to end — or, if
my order is malformed, a single named reason I can correct, never a stack trace and never a silent acceptance that
fails later. *Acceptance:* a well-formed order returns `{:ok, {:place, _}}` with a branded id and `{units, nano}`
price (G1); each way to malform it returns exactly one of the six error atoms (G2).

**DS-2 — prices are money, not floats.** As a risk owner, I need the guarantee that no order in the system carries a
floating-point price, because float drift in money-math is a defect I cannot audit away. *Acceptance:* a float-bearing
price is refused as `:bad_price` at the door, and no command anywhere in the system contains a float (G3).

**DS-3 — a market order needs no price.** As a desk, I submit a market order without a price and it is accepted with
the price slot marked market, matching how the venue itself treats market orders. *Acceptance:* a market order parses
with `price: :market` regardless of any price field (G4).

**DS-4 — a retry does not double-fill.** As an API client on a flaky connection, I resubmit an order with the same
idempotency token I sent before, and the platform reconciles it to the original identity rather than creating a
second order. *Acceptance:* a replay token maps to the branded id, minting no second identity (G6); the venue's
`order_id` carries that id outward.

**DS-5 — the Go worker trusts the type.** As an engineer on the pricing tier, I consume a command that is already
typed and whose money is already two integers, so my Go worker never parses a raw order and never sees a float.
*Acceptance:* the cross-runtime contract fixes `{units, nano}` money and the branded id as the job key
([`trd.1.specs.md`](trd.1.specs.md) §cross-runtime); a worker handed a typed command needs no parser.

## Agent stories (Directive + Acceptance gate)

**AS-1 — build the money parser first.** *Directive:* the agent writes `parse_money/1` returning `{:ok, {units,
nano}}` for integer-pair or integer-string input and `{:error, :bad_price}` otherwise, before any command assembler.
*Gate:* a property over generated inputs shows every output is either a two-integer pair or `:bad_price`, and no
output is a float; the gate line prints green and the script exits zero.

**AS-2 — make every error reachable.** *Directive:* the agent constructs six inputs, one per error atom, and asserts
each returns exactly its atom; the agent adds a generated-input property asserting no input crashes or returns an
unclassified value. *Gate:* G2 prints six exact matches and the totality property holds; exit zero.

**AS-3 — mint exactly once at acceptance.** *Directive:* the agent mints `CMD`/`ORD` ids inside the success branch
only, via `Snowflake.next_branded/1`, and asserts a rejection mints nothing. *Gate:* the same valid input twice
yields two distinct branded ids (G1); a rejected input is shown to mint no id (an instrumented counter or a
mint-call assertion); exit zero.

**AS-4 — carry opaque venue ids verbatim.** *Directive:* the agent threads `instrument` and `account` strings through
the parser unchanged and asserts they are neither branded nor rewritten. *Gate:* G5 shows the strings identical in
input and output and `BrandedId.parse/1` is never called on them; exit zero.

**AS-5 — keep the boundary stateless and dependency-free.** *Directive:* the agent implements the Gateway as one
module with no process, no ETS, no store handle, no application-env config, and no new dependency. *Gate:* the module
compiles and passes its gates with no supervised child started; a grep shows no `use GenServer`, no `:ets`, no
`Application.get_env`, no new `mix.exs` dep introduced by this rung.

**AS-6 — preserve the idempotency seam.** *Directive:* the agent implements replay-token reconciliation so a caller-
supplied token maps to the branded id (INV-6) and emits that id in the venue's `order_id` position in the command's
outward shape. *Gate:* G6 shows a replayed token reconciling to one identity, not two; the outward command carries
the branded id as `order_id`; exit zero.

## Map

Spec: [`trd.1.specs.md`](trd.1.specs.md). Chapter: [`trd.1.md`](trd.1.md). Runbook: [`trd.1.llms.md`](trd.1.llms.md).
Next rung: [`trd.2.stories.md`](trd.2.stories.md).
