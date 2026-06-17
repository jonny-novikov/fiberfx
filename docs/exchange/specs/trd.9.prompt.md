# trd.9.prompt.md — the x-mode runbook for TRD.9 (investex, the Elixir TInvest client)

> The orchestration runbook the Director executes to author the **TRD.9 chapter quad**. Authoritative scope for
> this run. The deliverable is the **spec**, not code; the pipeline truncates to its spec-authoring core. Authored
> by the Director in bootstrap (the grounded brief Venus builds from); it doubles as the durable
> architecture-decisions record the future build rungs (trd.9.1+) stand on.

## The rung in one paragraph

TRD.9 founds **investex** — `echo/apps/investex`, OTP `:investex`, modules `Investex.*` — the **BEAM-native Tinkoff
Invest API client**, covering the same surface the Go SDK (`invest-api-go-sdk`) covers: 10 gRPC services / ~75 RPCs.
The roadmap already named a "Go worker tier — the Tinkoff Invest gRPC client tier" with an open decision on whether
to give it a dedicated quad; the Operator has answered by asking for a first-class Elixir client, so the BEAM is never
blocked on the Go tier for venue I/O. investex is the Elixir-side equivalent of the Go SDK's venue-client seat: a
gRPC transport over TLS with bearer-token auth, protoc-generated message modules, one Elixir function per RPC across
per-service modules, supervised processes for the bidirectional streams, money decoded to the Exchange canon's
`{units, nano}` integer pair (never a float), and a two-tier test strategy — a pure default suite plus an opt-in
sandbox-keyed integration suite. **This run authors the chapter quad only** (the spec + the sub-rung ladder); each
build rung trd.9.1+ is a separate, later x-mode run.

## Mode

**Flat-L2, the spec-authoring (create) variant.** Stage 1 — one real **Venus** authors the four quad files + the
roadmap row + the progress section from this runbook, recording ≥2 alternatives per open decision. Stage 3 — the
**Director** solo-reviews by reconciling the quad against the real `contracts/*.proto` + `investgo/` surface
(coverage completeness, method-name accuracy, money/id/secret discipline, quad-form fidelity). Stage 5 — the Director
ships one LAW-4 pathspec commit. **No Mars** (no code this rung). **No Apollo** (spec-only, NORMAL risk).

> **Risk note carried into the spec.** The *spec* is NORMAL risk (a design doc). The *build* rungs trd.9.1+ are
> HIGH risk — real network I/O, a live secret (the sandbox token), and auth. The spec must flag that each build rung,
> when shipped via x-mode, warrants a dedicated **Apollo** evaluator and the secret-hygiene gate below.

## Settled architecture (the pre-framed decisions — Venus locks each as a D-n, records the alternative as a V-n)

Every decision is grounded in a real artifact (cited). Venus may refine the *shape* but not re-open the *spine*; any
genuine re-opening is escalated to the Director, not decided silently.

| # | Decision | Locked | Alternative (record as V-n) | Grounding |
|---|---|---|---|---|
| F-1 | App & deps | lib-only umbrella app `echo/apps/investex` (`:investex`, `Investex.*`); deps `{:echo_data, in_umbrella: true}` (the `{units,nano}` + branded-id canon), `{:grpc, ...}`, `{:protobuf, ...}`, `{:stream_data, only: :test}`; **no `mod:`** — a library the consumer supervises, never a venue connection booted at app start | fold into `exchange` (rejected — exchange stays pure, no network); standalone non-umbrella (rejected — loses echo_data) | `echo/mix.exs` `apps_path`; `echo/apps/echo_data/mix.exs`; `echo/apps/exchange/mix.exs` (the `{:echo_data, in_umbrella: true}` precedent) |
| F-2 | gRPC transport | `:grpc` (elixir-grpc) over the **Mint adapter** (`:mint` already locked → no new transport dep) + `:protobuf` (elixir-protobuf); TLS + bearer-token per-RPC metadata + `x-app-name`, mirroring the Go dial | hand-roll over Finch/Mint (rejected — 75 methods, no codegen); the gun adapter (rejected — adds `:gun`; mint is present) | `investgo/client.go:72-78` (grpc.Dial TLS + oauth creds + x-app-name); umbrella `mix.lock` (mint/castore/hpax present, no `:grpc`/`:protobuf`) |
| F-3 | Codegen | `protoc` + `protoc-gen-elixir` from the committed contracts; the generated `.pb.ex` modules **committed** (reproducible build, no protoc at compile time — the Go SDK commits its `.pb.go` likewise); a documented regen task | generate-at-build (rejected — protoc on every CI build); hand-write structs (rejected — scale) | `github.local/investAPI/src/docs/contracts/*.proto` (8 files: common, instruments, marketdata, operations, orders, sandbox, stoporders, users); `invest-api-go-sdk/proto/*.pb.go` (the committed-codegen precedent) |
| F-4 | Client state | a supervised **`Investex.Client`** owning the `GRPC.Channel` + resolved `Investex.Config` (reconnect + interceptors in one place); per-service modules (`Investex.{Instruments,MarketData,Operations,Orders,StopOrders,Users,Sandbox}`) stateless given a client handle, one Elixir function per RPC | stateless funcs taking an explicit `%GRPC.Channel{}` (record — simpler, but scatters reconnect) | `investgo/client.go:26-31` (stateful `Client{conn, Config}`), `investgo/orders.go` (thin per-service wrappers) |
| F-5 | Streaming | each streaming RPC → a supervised GenServer owning the stream, managing the subscription set, **resubscribing on reconnect**, handling `Ping` keepalives, delivering decoded messages to a subscriber; the hardest rung, **lands last (9.5)** | expose the raw `GRPC` Elixir `Stream` (rejected — loses resubscribe-on-reconnect + subscription mgmt; the Go SDK explicitly does not) | `invest-api-go-sdk/README.md:106-109` ("переподключается и переподписывает стрим"); `proto/common.proto:72` (`Ping`); the 5 stream RPCs (MarketDataStream bidi, MarketDataServerSideStream, TradesStream, PortfolioStream, PositionsStream) |
| F-6 | Money & ids | Quotation/MoneyValue decode to `{units, nano}` integers via an `Investex.Money` helper (`from_quotation/1`, `to_quotation/1`, `from_money_value/1`) — **never a float**; the `.ToFloat()` of the Go SDK is deliberately NOT mirrored. The `order_id` (PostOrder idempotency key) accepts a branded `ORD` id from `EchoData` and validates it at the edge — **the seam to the Exchange platform** | Decimal (rejected — the canon is integer `{units,nano}`) | `proto/common.proto:28-48` (MoneyValue/Quotation = `{units,nano}`); `exchange.specs.md` (money never float); exchange-platform: `PostOrderRequest.order_id` = the branded id |
| F-7 | Config & auth | `Investex.Config` mirroring `investgo` Config: `endpoint` (default sandbox `sandbox-invest-public-api.tinkoff.ru:443`), `token` (from `INVEST_TOKEN` env), `app_name` (default `jonnify.investex`), `account_id`, retry knobs (`disable_resource_exhausted_retry`, `disable_all_retry`, `max_retries` default 3); auth = `Authorization: Bearer <token>` + `x-app-name` per-RPC metadata | app-env-only config (rejected — the Go SDK takes explicit config; env is the test-key path) | `investgo/config.go`; `investgo/client.go:37-39,116-128`; `grpc.md:14-33,53-57` |
| F-8 | Retry / rate-limit | a retry policy mirroring the Go interceptor: linear **500 ms** backoff on `Unavailable`/`Internal` up to `max_retries`; a **separate, longer, silent** wait on `ResourceExhausted` honoring `x-ratelimit-reset`. The retry-DECISION (status + attempt → `{:retry, wait_ms}` \| `:give_up`) is a **pure function**, unit-tested with no network | no retry (rejected — parity; the venue rate-limits) | `investgo/client.go:19-70` (WAIT_BETWEEN 500ms, codes, the RE branch); `grpc.md:88-92` (x-ratelimit-* headers) |
| F-9 | Test strategy | **TWO tiers.** Tier 1 (default `mix test` + the `--no-start` rung gate): codegen round-trip, money codec, config defaults, request builders, branded-id validation, the retry-decision function — **no network, deterministic, CI-safe**. Tier 2 (`@tag :sandbox`, EXCLUDED by default; `mix test --include sandbox`): real sandbox endpoint with `INVEST_TOKEN` — open a sandbox account, GetAccounts, place + read a sandbox order, etc. **Skips (not fails) when the key is absent.** | only-sandbox (rejected — non-deterministic gate); only-pure (rejected — the Operator wants real sandbox proof) | `.env.test` (`INVEST_TOKEN`); `investgo/sandbox.go` (the sandbox lifecycle); the `exchange` rung-gate precedent `echo/rungs/exchange/trd_2_1_check.exs` |
| F-10 | Parity definition | a **parity manifest** in the spec — the 10 services × their ~75 methods, each → `Investex.<Service>.<fun>/n` — and a parity CHECK (a test enumerating the proto service definitions, asserting each Go-SDK-covered method has an investex function). The Go SDK's exported `investgo` methods are the reference set | informal "we covered it" (rejected — "all api as go covers" must be measurable) | `proto/*_grpc.pb.go` service defs; `investgo/*.go` exported methods |
| F-11 | Secret hygiene | `INVEST_TOKEN` is read from the environment only (`System.get_env`/`System.fetch_env!`), **never hardcoded, never committed, never logged, never written into a transcript or any doc**; `.env.test` stays in `github.local` (a gitignored external repo) and is read at test time, never copied into the repo; the token VALUE never appears in the spec, the ledger, or a gate `.out` | — (a hard rule, no alternative) | `.env.test` is a real sandbox secret; the standing repo secret-handling discipline |

## Grounding (real, cited — Venus reads before authoring; quotes nothing it has not opened)

- **The API surface (the parity target).** 10 services / ~75 RPCs — extracted from
  `github.local/invest-api-go-sdk/proto/*.proto`:
  InstrumentsService (~27: TradingSchedules, BondBy/Bonds, GetBondCoupons, CurrencyBy/Currencies, EtfBy/Etfs,
  FutureBy/Futures, OptionBy/Options/OptionsBy, ShareBy/Shares, GetAccruedInterests, GetFuturesMargin,
  GetInstrumentBy, GetDividends, GetAssetBy/GetAssets, GetFavorites/EditFavorites, GetCountries, FindInstrument,
  GetBrands/GetBrandBy) · MarketDataService (7: GetCandles, GetLastPrices, GetOrderBook, GetTradingStatus(es),
  GetLastTrades, GetClosePrices) · MarketDataStreamService (2: MarketDataStream bidi, MarketDataServerSideStream) ·
  OperationsService (7: GetOperations, GetPortfolio, GetPositions, GetWithdrawLimits, GetBrokerReport,
  GetDividendsForeignIssuer, GetOperationsByCursor) · OperationsStreamService (2: PortfolioStream, PositionsStream) ·
  OrdersService (5: PostOrder, CancelOrder, GetOrderState, GetOrders, ReplaceOrder) · OrdersStreamService (1:
  TradesStream) · StopOrdersService (3: PostStopOrder, GetStopOrders, CancelStopOrder) · UsersService (4:
  GetAccounts, GetMarginAttributes, GetUserTariff, GetInfo) · SandboxService (14: OpenSandboxAccount,
  GetSandboxAccounts, CloseSandboxAccount, PostSandboxOrder, ReplaceSandboxOrder, GetSandboxOrders,
  CancelSandboxOrder, GetSandboxOrderState, GetSandboxPositions, GetSandboxOperations,
  GetSandboxOperationsByCursor, GetSandboxPortfolio, SandboxPayIn, GetSandboxWithdrawLimits).
  **Re-derive the exact list from the proto before writing the manifest — quote no method not found there.**
- **The Go SDK (the wrap pattern).** `investgo/client.go` (the stateful Client + dial), `investgo/config.go` (Config),
  `investgo/orders.go` (the thin per-service wrapper + convenience `Buy`/`Sell`), `investgo/sandbox.go` (the sandbox
  lifecycle), the per-stream clients (`md_stream*.go`, `*_stream_client.go`, `portfolio_stream.go`,
  `positions_stream.go`, `trades_stream.go`).
- **Transport.** `github.local/investAPI/src/docs/grpc.md` (endpoints, Bearer auth, x-app-name, x-tracking-id,
  x-ratelimit-*); the per-service heads `head-{instruments,marketdata,operations,orders,stoporders,users,sandbox}.md`.
- **Money & the canon.** `proto/common.proto:28-48` (MoneyValue/Quotation); `exchange.specs.md` (money never float;
  branded ids the spine); `echo/apps/echo_data` (the minting + `{units,nano}` canon, Ecto-free).
- **The seam.** `trd.2.md` "The Go pricing seam, named" + `trd.progress.md` "The Go worker tier" (investex is the
  BEAM-native venue client at that named seat).
- **The quad form.** The `trd.2.*` skeletons: `.specs.md` = Invariants · the as-built surface consumed · the
  vocabulary · Surface pinned · Decomposition (build order) · Mars notes · the cross-runtime seam · Acceptance gates ·
  Map; `.md` = Overview · Rationale · Design · the five W's · [the seam] · Map · References; `.stories.md` = Developer
  stories · Agent stories (Directive + Acceptance gate) · Map; `.llms.md` = References (read first) · the Surface
  (exact) · Requirements pattern (each → an invariant) · Execution topology · the boundary (do not build here) · Do
  NOT · Agent stories · Map.

## The deliverable (Venus authors all; leaves them in the working tree for the Director)

1. **`docs/exchange/trd.9.md`** — the chapter narrative (Overview, Rationale, Design, the five W's, **"The Exchange
   seam, named"** — investex as the BEAM-native venue client vs the Go worker tier, Map, References). PROPOSED.
2. **`docs/exchange/trd.9.specs.md`** — authoritative: Invariants (INV-n) · the as-built surface consumed (echo_data,
   the new grpc/protobuf deps) · **the parity manifest** (10 services × ~75 methods → `Investex.*` functions) · Surface
   pinned (Config, Client, the per-service modules, Money, the stream processes) · **Decomposition** (the trd.9.1–9.5
   sub-rung ladder, build order) · Mars notes · the cross-runtime/Exchange seam · Acceptance gates (G-n) · Map.
3. **`docs/exchange/trd.9.stories.md`** — Developer stories + Agent stories (Directive + Acceptance gate) + Map.
4. **`docs/exchange/trd.9.llms.md`** — the agent runbook (References read-first · the exact surface · Requirements →
   invariants · Execution topology · the boundary · Do NOT · Agent stories · Map).
5. **`docs/exchange/exchange.roadmap.md`** — add the **TRD.9 row** to "The rungs" table (and a milestone note — TRD.9
   is the venue-client subsystem; relate it to the named Go worker tier) without disturbing TRD.1–8.
6. **`docs/exchange/trd.progress.md`** — add a **### TRD.9 — investex** section (Abstract, 5W, Decisions, Roadmap fit)
   and reconcile the "Go worker tier" open decision (investex is the BEAM-native venue client; the Go tier stays for
   GPU money-math, fed by investex's data).

## The recommended decomposition (the sub-rung ladder — Venus fixes it in `trd.9.specs.md` §Decomposition)

- **TRD.9.1 — the transport spine.** `Investex.Config` + the protoc-gen-elixir codegen of the contracts +
  `Investex.Client` (channel, TLS, Bearer + x-app-name metadata, endpoint select) + the retry/rate-limit policy
  (the pure decision fn) + **UsersService** end-to-end (4 methods; `GetAccounts` the canonical sandbox smoke) + the
  minimal **sandbox bootstrap** (Open/Get/Close, enough to test) + the two-tier test harness. Proves the whole
  vertical, pure-gated + sandbox-verified.
- **TRD.9.2 — the read services.** InstrumentsService (~27) + MarketDataService (7) + OperationsService (7) — unary,
  read-only. Parity manifest rows + pure request builders + sandbox reads.
- **TRD.9.3 — the trading services.** OrdersService (5) + StopOrdersService (3) — the write side, the branded
  `order_id` seam, the sandbox order lifecycle (via SandboxService's order methods).
- **TRD.9.4 — the full SandboxService.** The remaining sandbox surface (PayIn, the sandbox orders/operations/
  positions/portfolio mirror) — complete sandbox parity.
- **TRD.9.5 — the streaming services.** MarketDataStream (bidi) + MarketDataServerSideStream + OrdersStream
  (TradesStream) + OperationsStream (Portfolio/Positions) — the OTP stream-process model, resubscribe-on-reconnect,
  Ping. The hardest rung, last.

> Open, record-don't-block: the exact placement of SandboxService (split 9.1/9.4 vs one early rung). Venus decides
> and records the reasoning; not an Operator fork.

## Stage prompts

**Stage 1 · Venus (architect — authors the quad).** Adopt `.claude/agents/venus.md`. Read the grounding above (open
every file before quoting it). Author the six deliverables. Lock F-1…F-11 as D-n, each considered alternative as a
V-n; record surprises as L-n; the final summary as Y-n. Ground every figure (service/method/endpoint/type) in the
real proto/SDK/docs — **invent no method name, no endpoint, no message field**. Keep the parity manifest exhaustive
(all 10 services). Honor the secret-hygiene rule (F-11): the token value appears nowhere. **Do not run git; do not
write code** (this is a spec rung). Report via `SendMessage(to: "director", …)`.

**Stage 3 · Director (solo review).** Reconcile the quad against the real surface: (a) **coverage** — every one of the
10 services + its methods present in the manifest, count it; (b) **no-invent** — re-find a sample of cited
methods/messages/endpoints in `contracts/*.proto` + `grpc.md` (no fabrication); (c) **canon** — money is `{units,
nano}` (no float; cites common.proto + exchange.specs.md), the branded `order_id` seam present, the new deps named;
(d) **secret hygiene** — grep the quad + ledger for any token-shaped string; the rule is stated; (e) **quad form** —
the four files match the trd.2.* skeletons; the roadmap row + progress section landed, no dangling ref. Findings →
`tool_x_report` + a REVISE list back to Venus (SendMessage). The Director writes **no** spec content (LAW-1a — Venus
owns the quad).

**Stage 5 · Director (ship).** Gate green → lock the ratifying `tool_x_decision` (the run's settled shape) + write
`tool_x_complete` (Z-n) → **one LAW-4 pathspec commit** (below) → Stage-6 fold (the exchange-platform memory + the
roadmap reconcile + the next frontier = building trd.9.1 via x-mode with Apollo).

## Acceptance (the quad is build-grade when)

- All 10 services + ~75 methods enumerated in the parity manifest, each mapped to a named `Investex.*` function; no
  method cited that is absent from `contracts/*.proto`.
- The architecture spine F-1…F-11 each locked as a D-n with its V-n alternative; no open fork left for Mars to guess.
- The two-tier test strategy is explicit (the pure default gate vs the opt-in sandbox suite that skips keyless), and
  the secret-hygiene rule is stated in the spec.
- The decomposition names trd.9.1–9.5 with each rung's deliverables + its build dependency.
- The quad form matches the trd.2.* skeletons; the roadmap row + progress section consistent; every internal link
  resolves; PROPOSED status carried.
- The spec flags the build rungs as HIGH risk (network/secret/auth → Apollo at build time).

## LAW-4 — the single ratifying commit (Director only, at Z-n)

Pathspec (exactly these; **never `git add -A`, never a bare commit** — the working tree carries much foreign
in-flight work):

```
git commit -F <msg> -- \
  docs/exchange/trd.9.md \
  docs/exchange/trd.9.specs.md \
  docs/exchange/trd.9.stories.md \
  docs/exchange/trd.9.llms.md \
  docs/exchange/trd.9.prompt.md \
  docs/exchange/exchange.roadmap.md \
  docs/exchange/trd.progress.md \
  docs/exchange/trd-9.progress.md \
  docs/exchange/trd-9.registry.json
```

Review `git status --short` + `git diff --cached --name-only` first; check `.git/rebase-merge`/`rebase-apply`; exclude
every path not in the list. Message cites the slug `trd-9`, the Z-n, the D-n decisions, the Y-n report.

## Definition of done

The TRD.9 chapter quad is on disk, build-grade, PROPOSED; the roadmap ends at TRD.9; investex is decomposed into the
9.1–9.5 ladder with its architecture spine fixed and grounded; the secret-hygiene + two-tier-test discipline is
written into the spec; the ledger carries T/D/V/L/Y/Z; one Director pathspec commit ratifies it; the next frontier
(build trd.9.1, Apollo-gated) is recorded.
