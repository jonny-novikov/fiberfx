# trd.9 — the agent guide (building investex)

> Derived from [`trd.9.specs.md`](trd.9.specs.md) (authoritative) and the chapter ([`trd.9.md`](trd.9.md)). Real
> arities only — every surface below is defined in the spec or exists in the tree at the cited path; every proto
> figure is quoted from the committed contracts. **Framing (propagate this clause):** third person for any agent; no
> gendered pronouns; no perceptual or interior-state verbs; no first-person narration. This guide founds a new
> umbrella app, `echo/apps/investex`, ON the as-built `echo_data` canon and the committed Tinkoff Invest contracts —
> it edits neither. **This is the spec rung's runbook; each build rung (9.1–9.5) is a separate, HIGH-risk x-mode run
> with its own Apollo and the secret-hygiene gate.**

## References (read first, in order)

- `docs/exchange/trd.9.specs.md` — this rung's authoritative spec: the invariants, the parity manifest (72 RPCs), the
  surface, the decomposition, the gates. **First.**
- `docs/exchange/exchange.specs.md` — the master invariant; money never float; the branded id spine
  (ORD/FIL/CMD/TXN/ACC/INS) minted at the edge and validated at every door.
- `docs/exchange/trd.progress.md` (the *Go worker tier* section) + `docs/exchange/trd.2.md` (the *Go pricing seam,
  named*) — the seat investex takes as the BEAM-native venue client, and the `PostOrderRequest.order_id`
  idempotency-key seam.
- `github.local/invest-api-go-sdk/proto/*.proto` — the 8 committed contracts (common, instruments, marketdata,
  operations, orders, sandbox, stoporders, users). The parity source: re-read the `service`/`rpc` definitions; quote
  no method absent from them.
- `github.local/invest-api-go-sdk/investgo/{client,config,orders,sandbox}.go` + the per-stream clients
  (`md_stream*.go`, `*_stream_client.go`, `portfolio_stream.go`, `positions_stream.go`, `trades_stream.go`) — the
  wrap pattern: the stateful client + TLS/bearer dial, the thin per-service wrappers, the resubscribe-on-reconnect
  stream clients.
- `github.local/investAPI/src/docs/grpc.md` + the per-service heads (`head-{instruments,marketdata,operations,orders,
  stoporders,users,sandbox}.md`) — endpoints, `Authorization: Bearer`, `x-app-name`, `x-tracking-id`, `x-ratelimit-*`.
- `github.local/invest-api-go-sdk/proto/common.proto` (lines 28-48, 72) — `MoneyValue`/`Quotation` = `{units, nano}`;
  `Ping` = the stream keepalive.
- `echo/apps/exchange/mix.exs` + `echo/apps/echo_data/mix.exs` — the lib-only umbrella-app shape (no `mod:`,
  `extra_applications: [:logger]`, `{:echo_data, in_umbrella: true}`); build ON `echo_data`'s branded-id surface,
  do not edit it.
- `echo/rungs/exchange/trd_2_1_check.exs` — the committed-transcript rung-gate precedent each build rung mirrors.

## The surface (exact, as the spec pins it)

- `Investex.Client.start_link(%Investex.Config{})` — the supervised channel owner (TLS, Bearer + `x-app-name`
  metadata, reconnect). `Investex.Client.channel(client)`, `Investex.Client.stop(client)`. Lib-only: started by the
  consumer, never by `:investex` (INV-5).
- The seven unary per-service modules — `Investex.{Instruments, MarketData, Operations, Orders, StopOrders, Users,
  Sandbox}` — one public function per unary RPC, `(client, typed_request) -> {:ok, response} | {:error,
  Investex.Error.t()}`. The exact 72-row mapping is the parity manifest in `trd.9.specs.md` (the names are frozen
  there; pin the per-argument shape against the proto request messages).
- The five stream processes — `Investex.MarketDataStream` (bidi + server-side), `Investex.TradesStream`,
  `Investex.PortfolioStream`, `Investex.PositionsStream` — each a supervised GenServer owning the stream, the
  subscription set, and `Ping`; resubscribes the full set on reconnect (INV-7). The raw gRPC stream stays internal.
- `Investex.Money.from_quotation/1` · `to_quotation/1` · `from_money_value/1` — integer `{units, nano}` only; no float
  (INV-3). `Investex.Config` — `endpoint`/`token`/`app_name`/`account_id`/the three retry knobs (defaults: endpoint
  sandbox, app_name `jonnify.investex`, `max_retries` 3). `Investex.Retry.decide(status, attempt, headers) ::
  {:retry, wait_ms} | :give_up` — pure (INV-6).
- The generated message modules `Investex.Proto.*` are protoc-gen-elixir output, **committed**, with a regen task
  (INV / D-3). Proto figures (quote, do not invent): `Quotation{units:int64, nano:int32}`, `MoneyValue{currency,
  units, nano}`, `Ping{time}`, `PostOrderRequest.order_id` (the branded `ORD` seam).

## Requirements pattern (each traces to an invariant)

- **R-parity** (INV-1, INV-2). All 10 services / 72 RPCs map to named functions; a parity-check test enumerates the
  proto and asserts each mapping. One function per unary RPC; one supervised process per streaming RPC.
- **R-money** (INV-3). `Quotation`/`MoneyValue` decode to integer `{units, nano}` through `Investex.Money`; no float
  in any value; the Go float bridge is not ported.
- **R-seam** (INV-4). `post_order`/`replace_order`/`Sandbox.post_order` accept a branded `ORD` id and validate it at
  the edge (through the as-built `echo_data` surface) before building the request; a malformed id is refused at the
  door.
- **R-client** (INV-5). A supervised `Investex.Client` owns the channel + config; the per-service modules are
  stateless given a handle; lib-only (no `mod:`).
- **R-retry** (INV-6). The retry decision is a pure function (status/attempt/headers → `{:retry, wait_ms} |
  :give_up`); linear 500 ms on `Unavailable`/`Internal`, a longer silent wait on `ResourceExhausted` honoring
  `x-ratelimit-reset`; the impure interceptor is only the shell.
- **R-stream** (INV-7). Each streaming RPC is a supervised GenServer owning the subscription set and `Ping`;
  resubscribes the full set on reconnect; the raw stream is not exposed.
- **R-tiers** (INV-8). A pure default suite (network-free, the rung gate) plus a `@tag :sandbox` suite excluded by
  default that skips (not fails) when `INVEST_TOKEN` is absent and round-trips the sandbox when it is present.
- **R-secret** (INV-9). `INVEST_TOKEN` from the environment only; no token value in any file, log, fixture, or
  transcript.
- **R-prove**. A gate script in the rung pattern — one printed line per gate (G1–G7), exit nonzero on failure, output
  committed beside it at `echo/rungs/exchange/trd_9_N_check.out`.

## Execution topology

`echo/apps/investex` is a new lib-only umbrella app (auto-discovered via the umbrella `apps_path`; no `mod:`). Its
`mix.exs` declares `{:echo_data, in_umbrella: true}`, `{:grpc, "~> 0.9"}`, `{:protobuf, "~> 0.13"}`, and
`{:stream_data, "~> 1.0", only: :test}` — the grpc/protobuf pair is new to the umbrella (the HTTP/2 stack mint +
castore + hpax is already locked, so the transport adds no new substrate; the codegen pair is new). The build order is
the 9.1–9.5 ladder in `trd.9.specs.md` §Decomposition: 9.1 the transport spine (config, codegen, client, retry,
UsersService, the sandbox bootstrap trio, the two-tier harness) → 9.2 the read services → 9.3 the trading services +
the branded seam + the sandbox order lifecycle → 9.4 the full SandboxService → 9.5 the streams. Runtime shape:
`Investex.Client` is one supervised process started by the *consumer*; the per-service modules and `Investex.Money`/
`Investex.Retry` are pure-ish call sites the consumer reaches with a client handle; the five stream GenServers are
supervised by the consumer when a stream is needed. Nothing in `:investex` boots at app start. No external service is
required for the pure tier; the sandbox tier needs `INVEST_TOKEN` and the sandbox endpoint.

## The Go-worker boundary (do not build here; honor its contract)

The Go worker tier (TInvest Go SDK clients, drained as EchoMQ jobs, reading through EchoCache; Go for numeric
throughput and GPU-accelerated money-math) is **not** replaced by investex and **not** built here. investex is the
BEAM-native venue client alongside it: the Go tier keeps the heavy money-math (mark-to-market, margin, risk, analytics
over fills), fed by the data the BEAM produces, consuming the same `{units, nano}` integer money investex decodes. The
seam investex fixes is the branded `ORD` id: the Gateway's `ORD` id is the venue idempotency key investex passes to
`PostOrder` (INV-4) and the same id the platform uses as the job key. The Go tier's job payload schema and
idempotent-handler contract are its own rungs; do not invent them here.

## Do NOT

- Do not edit the committed contracts (`github.local/.../proto/*.proto`), the Go SDK, or the `echo_data` canon — this
  rung builds ON them; it is additive.
- Do not invent a method name, an endpoint, or a message field — quote every RPC from the proto `service`/`rpc`
  definitions; the parity manifest is the frozen list of 72.
- Do not use a float for money; do not port `FloatToQuotation`/`ToFloat` (converters.go). Money is integer `{units,
  nano}` through `Investex.Money`, always (INV-3).
- Do not put a clock, sleep, network, or `Process.*` inside `Investex.Retry.decide/3` — the decision is pure or it is
  wrong (INV-6); the interceptor that applies it is the impure shell.
- Do not hardcode, commit, log, or transcribe the token. `INVEST_TOKEN` is read from the environment only; the value
  appears in nothing — not a struct default, a config, a fixture, a log line, or a gate `.out` (INV-9).
- Do not make the sandbox suite a default gate (it is non-deterministic); do not make it FAIL when the key is absent —
  it SKIPS (INV-8).
- Do not boot `Investex.Client` from `:investex`'s own app (no `mod:`); the consumer supervises it (INV-5).
- Do not expose the raw gRPC stream to the caller; the stream GenServer owns the subscription set, the resubscribe,
  and `Ping` (INV-7).
- Do not construct a branded `ORD` id by hand; mint/validate through the as-built `echo_data` surface, cited at build
  time (INV-4).
- Do not print exclamation marks or forbidden-voice words in check output lines a chapter may later quote.

## Agent stories (Directive + Acceptance gate)

- **AS-1 — the transport spine first (9.1).** *Directive:* build `Investex.Config`, the committed `Investex.Proto.*`
  + regen task, `Investex.Client`, the pure `Investex.Retry.decide/3`, UsersService (4), the sandbox bootstrap trio,
  the two-tier harness. *Gate:* the pure suite is network-free and green; with a key `Investex.Users.get_accounts/1`
  returns against the sandbox; line prints, exit zero.
- **AS-2 — parity is measured.** *Directive:* write the parity-check test enumerating the proto, asserting each of the
  72 RPCs maps. *Gate:* the test passes, count prints 72, a missing function fails it; exit zero.
- (AS-3…AS-8 in [`trd.9.stories.md`](trd.9.stories.md) — integer money, the branded seam, the pure retry, the two
  tiers, no token value, the resubscribing streams — carry the same gate-and-exit contract.)

## Map

Spec: [`trd.9.specs.md`](trd.9.specs.md). Chapter: [`trd.9.md`](trd.9.md). Stories: [`trd.9.stories.md`](trd.9.stories.md).
System: [`exchange.specs.md`](exchange.specs.md). The seam: the *Go worker tier* of [`trd.progress.md`](trd.progress.md).
