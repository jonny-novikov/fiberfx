# TRD.9 · Stories — investex

<show-structure depth="2"/>

> Acceptance stories for rung TRD.9, two audiences. **Developer stories** for a human engineer; **Agent stories** for
> a Claude agent under the house loop — third person, no gendered pronouns, no perceptual or interior-state verbs, no
> first-person narration. Both trace to the invariants and gates in [`trd.9.specs.md`](trd.9.specs.md). **Status:
> PROPOSED.** This rung delivers the specification; the stories are the acceptance face the build rungs (9.1–9.5)
> close against.

## Developer stories

**DS-1 — the BEAM places a venue order.** As an engineer on the platform, I call one Elixir function to place a
Tinkoff Invest order from the BEAM — passing the branded `ORD` id the Gateway minted as the venue idempotency key —
without dropping into a Go process or parsing a float. *Acceptance:* `Investex.Orders.post_order/2` accepts a typed
request whose `order_id` is a branded `ORD` id validated at the edge; money on the order is `{units, nano}` integers;
the request crosses the wire over the supervised client (INV-4, INV-5; G3).

**DS-2 — full parity, provably.** As a maintainer, I trust the claim "investex covers the same surface the Go SDK
covers" because a test proves it — every one of the 10 services and 72 RPCs is mapped, and a missing method turns the
gate red. *Acceptance:* the parity-check test enumerates the proto service definitions and asserts each of the 72 RPCs
has its named `Investex.<Service>.<fun>/n`; the count prints 72 (INV-1; G1).

**DS-3 — money stays integer end to end.** As a correctness owner, I need venue money to be the same `{units, nano}`
integer pair the matching core and the ledger speak, with no float conversion anywhere in the client. *Acceptance:*
`Investex.Money` round-trips `Quotation`/`MoneyValue` as integer `{units, nano}` (plus the ISO currency for
`MoneyValue`); a property shows no float in any decoded value; the Go float bridge is not ported (INV-3; G2).

**DS-4 — the venue's rate limit does not surface as a crash.** As an operator, when the venue throttles or a call
fails transiently, I want the client to retry the way the Go SDK does — linear on transient codes, a silent longer
wait on resource exhaustion — and I want that policy testable without a live endpoint. *Acceptance:* the pure
`Investex.Retry.decide/3` returns `{:retry, 500}` on `Unavailable`/`Internal` under the cap, a longer wait honoring
`x-ratelimit-reset` on `ResourceExhausted`, and `:give_up` past `max_retries`; it is unit-tested with no network
(INV-6; G4).

**DS-5 — a stream that heals itself.** As an engineer consuming market data, I subscribe to candles or an order book
once and rely on the stream to resubscribe my whole set when the connection drops, answer the venue's `Ping`, and keep
delivering decoded messages — under supervision, not a raw stream I must babysit. *Acceptance:* each streaming RPC is a
supervised GenServer owning the subscription set; on reconnect it resubscribes the full set and handles `Ping`; the raw
gRPC stream is not exposed (INV-7; the 9.5 gates).

**DS-6 — the test key is never at risk.** As a security owner, I need the sandbox token read from the environment only,
present in no file, log, fixture, or transcript, and I need the keyless CI run to skip the sandbox suite rather than
fail it. *Acceptance:* `INVEST_TOKEN` is read via `System.get_env`/`System.fetch_env!`; the default suite is
network-free; the `@tag :sandbox` suite skips when the key is absent; a repo grep for a token-shaped string finds
nothing (INV-8, INV-9; G5, G7).

**DS-7 — real proof against the sandbox.** As the Operator, when the sandbox key is present I want investex to open a
sandbox account, read it, place and read a sandbox order, and close it — a real round trip proving the client trades,
not only compiles. *Acceptance:* with `INVEST_TOKEN` set, the sandbox suite opens an account, calls `get_accounts`,
places and reads a sandbox order, and closes the account against the real sandbox endpoint (INV-8; G6).

## Agent stories (Directive + Acceptance gate)

**AS-1 — the transport spine first (9.1).** *Directive:* the agent builds `Investex.Config`, the committed
protoc-gen-elixir `Investex.Proto.*` modules with a regen task, `Investex.Client` (TLS channel, Bearer + `x-app-name`
metadata, endpoint select), the pure `Investex.Retry.decide/3`, UsersService end-to-end (4 functions), and the
sandbox bootstrap trio (`open_account/1` · `get_accounts/1` · `close_account/2`) plus the two-tier test harness.
*Gate:* the pure suite is network-free and green; with a key, `Investex.Users.get_accounts/1` returns against the
sandbox; the line prints, exit zero (INV-5, INV-6, INV-8).

**AS-2 — parity is measured, not asserted.** *Directive:* the agent writes the parity-check test that enumerates the
10 proto service definitions and asserts each of the 72 RPCs maps to its named `Investex.<Service>.<fun>/n`. *Gate:*
the test passes with the count printing 72; a missing or misnamed function fails it; exit zero (INV-1, INV-2; G1).

**AS-3 — money is integer, the float bridge omitted.** *Directive:* the agent implements `Investex.Money`
(`from_quotation/1` · `to_quotation/1` · `from_money_value/1`) over integer `{units, nano}` and does **not** port
`FloatToQuotation`/`ToFloat`. *Gate:* a property shows `{units, nano}` round-trips with no float in any value; a grep
shows no float conversion in the money module; exit zero (INV-3; G2).

**AS-4 — the branded `ORD` id is validated at the edge.** *Directive:* the agent makes `post_order` / `replace_order`
(and `Sandbox.post_order`) accept a branded `ORD` id, validating it through the as-built `echo_data` surface before
building the proto request, and refusing an unbranded or wrong-namespace id at the door. *Gate:* a branded id is
accepted and a malformed one refused, asserted without a network; exit zero (INV-4; G3).

**AS-5 — the retry decision is pure.** *Directive:* the agent extracts the retry decision as
`Investex.Retry.decide/3` — status, attempt, headers in; `{:retry, wait_ms} | :give_up` out — with the impure
interceptor only the shell that applies it. *Gate:* unit tests cover the linear, the `ResourceExhausted`, and the
give-up branches with no network; a grep shows no clock/sleep/`Process.*` in the decision function; exit zero (INV-6;
G4).

**AS-6 — two tiers, the sandbox suite skips keyless.** *Directive:* the agent splits the suite — a pure default tier
(network-free, the rung gate) and a `@tag :sandbox` tier excluded by default whose `setup` reads `INVEST_TOKEN` and
`ExUnit`-skips on `nil`. *Gate:* the default run touches no network; the keyless run skips (does not fail) the sandbox
tests; with a key the sandbox vertical round-trips; exit zero (INV-8; G5, G6).

**AS-7 — no token value, anywhere.** *Directive:* the agent reads `INVEST_TOKEN` from the environment only and writes
no token literal into any struct default, config, log, fixture, or gate transcript. *Gate:* a repo grep for a
token-shaped string finds none; the token is sourced via `System.get_env`/`System.fetch_env!`; exit zero (INV-9; G7).

**AS-8 — the streams resubscribe (9.5).** *Directive:* the agent builds each of the 5 streaming RPCs as a supervised
GenServer owning the stream, the subscription set, and the `Ping` keepalive, resubscribing the full set on reconnect
and delivering decoded messages to a subscriber; the raw stream stays internal. *Gate:* a reconnect resubscribes the
recorded set and `Ping` is answered; the raw gRPC stream is not exposed; exit zero (INV-7).

## Map

Spec: [`trd.9.specs.md`](trd.9.specs.md). Chapter: [`trd.9.md`](trd.9.md). Runbook: [`trd.9.llms.md`](trd.9.llms.md).
System: [`exchange.specs.md`](exchange.specs.md). The seam: the *Go worker tier* of [`trd.progress.md`](trd.progress.md).
