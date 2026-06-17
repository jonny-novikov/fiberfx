# trd-9 — AAW scope ledger

## {trd-9-thinking} Thinking

### T-1 — UNDERSTAND/EXPAND: TRD.9 "Elixir TInvest Client" (investex) chapter quad

DELIVERABLE. The TRD.9 chapter quad — trd.9.md (narrative) + trd.9.specs.md (authoritative) + trd.9.stories.md (acceptance, both audiences) + trd.9.llms.md (agent runbook) — plus the roadmap row (extend the ladder past TRD.8) and a trd.progress.md TRD.9 section. SPEC ONLY; no code this run. The build rungs trd.9.1+ are separate future x-mode runs.

WHY. exchange.roadmap.md + trd.progress.md already name a "Go worker tier — the Tinkoff Invest gRPC client tier" with an OPEN Operator decision: dedicated quad vs distributed across consuming rungs. The Operator has answered by asking for investex — a BEAM-native TInvest client covering the FULL API "as go covers". TRD.9 is that subsystem; this run founds its chapter spec. investex is the Elixir-native venue client (the same seat the Go SDK holds for the Go workers), so the BEAM is never blocked on the Go tier for venue I/O.

GROUNDING (read-only, this turn). (a) The API surface — 10 gRPC services / ~75 RPCs, extracted from invest-api-go-sdk/proto/*.proto: InstrumentsService(~27) · MarketDataService(7) + MarketDataStreamService(2 bidi/server-stream) · OperationsService(7) + OperationsStreamService(2 stream) · OrdersService(5) + OrdersStreamService(1 stream) · StopOrdersService(3) · UsersService(4) · SandboxService(14). (b) The Go parity target investgo/ — a stateful Client{grpc.ClientConn, Config} dialing TLS + bearer-token per-RPC creds + x-app-name metadata + chained retry interceptors (linear 500ms on Unavailable/Internal, MaxRetries=3; a separate SILENT longer wait on ResourceExhausted honoring x-ratelimit-reset); per-service thin wrapper clients; auto-bootstraps a sandbox account when AccountId=="". (c) Transport (grpc.md) — prod invest-public-api.tinkoff.ru:443 / sandbox sandbox-invest-public-api.tinkoff.ru:443, both TLS; every request Authorization: Bearer <token>; responses carry x-tracking-id + x-ratelimit-{limit,remaining,reset} + message. (d) Money (proto/common.proto) — Quotation{units:int64,nano:int32} and MoneyValue{currency,units,nano} = EXACTLY the Exchange canon's {units,nano} integer pair, never float (exchange.specs.md). (e) The umbrella has NO gRPC/protobuf stack yet — finch/mint/castore/hpax (HTTP/2) are locked, no :grpc, no :protobuf → investex MUST add both (mint available as the grpc adapter). (f) echo/apps auto-discovers via apps_path; echo_data is the Ecto-free canon (mints branded ids, holds {units,nano}); investex depends on {:echo_data, in_umbrella: true}. (g) Test key — .env.test holds INVEST_TOKEN (a single sandbox bearer secret); never committed/logged/transcribed.

SOLUTION SPACE. (i) do-nothing — rejected, the Operator asked. (ii) single-Venus create branch + recorded alternatives + rigorous Director review — CHOSEN: the architecture is ecosystem-determined (elixir-grpc + protoc-gen-elixir; OTP supervised-stream-process; reuse {units,nano}; tagged sandbox tests), so the open points are decision-points not spine forks. (iii) dual-Venus §2b Design Phase — rejected for proportionality (marginal divergence value on a constrained design; the operator-approval ceremony exceeds the bounded "create the quad" ask). (iv) author it myself — rejected, V-SOLO violation of LAW-1.

INVARIANTS OF THIS RUN (checks). Coverage: all 10 services + ~75 methods appear in the spec's parity manifest. No-invent: every cited proto message/service/method/endpoint exists in contracts/*.proto (no fabricated names). Canon reuse: money is {units,nano} integer (spec forbids float, cites common.proto + exchange.specs.md); branded ids via echo_data (the PostOrderRequest.order_id idempotency-key seam). Secret hygiene: INVEST_TOKEN from env only, never committed/logged/transcribed; sandbox suite SKIPS (not fails) when the key is absent. Quad form matches the trd.2.* skeletons (Invariants/as-built-surface/vocabulary/Surface-pinned/Decomposition/Mars-notes/cross-runtime-seam/Acceptance-gates/Map). Roadmap consistency: TRD.9 row added, no dangling ref.

SMALLEST CHANGE THAT PRESERVES CORRECTNESS. One Venus authors the four quad files + the roadmap row + the progress section from a fixed brief (the trd.9.prompt.md runbook) that pre-frames every open architecture decision with its alternatives; the Director reconciles the result against the real proto/SDK surface and ships one pathspec commit. No code, no Mars, no Apollo (spec-only, NORMAL risk; the network/secret/auth risk is DESCRIBED here and flagged high-risk for the build rungs).

### T-2 — Parity manifest re-derived from the proto service definitions (no invention)

Extracted every `service`/`rpc` line from the eight committed contracts under `github.local/invest-api-go-sdk/proto/*.proto`. The 10 services and their EXACT RPC counts (re-derived, not transcribed):

- InstrumentsService — 27: TradingSchedules, BondBy, Bonds, GetBondCoupons, CurrencyBy, Currencies, EtfBy, Etfs, FutureBy, Futures, OptionBy, Options, OptionsBy, ShareBy, Shares, GetAccruedInterests, GetFuturesMargin, GetInstrumentBy, GetDividends, GetAssetBy, GetAssets, GetFavorites, EditFavorites, GetCountries, FindInstrument, GetBrands, GetBrandBy (instruments.proto:21-101)
- MarketDataService — 7: GetCandles, GetLastPrices, GetOrderBook, GetTradingStatus, GetTradingStatuses, GetLastTrades, GetClosePrices (marketdata.proto:18-36)
- MarketDataStreamService — 2: MarketDataStream (bidi), MarketDataServerSideStream (marketdata.proto:41-44)
- OperationsService — 7: GetOperations, GetPortfolio, GetPositions, GetWithdrawLimits, GetBrokerReport, GetDividendsForeignIssuer, GetOperationsByCursor (operations.proto:20-39)
- OperationsStreamService — 2: PortfolioStream, PositionsStream (operations.proto:44-47)
- OrdersService — 5: PostOrder, CancelOrder, GetOrderState, GetOrders, ReplaceOrder (orders.proto:24-36)
- OrdersStreamService — 1: TradesStream (orders.proto:17)
- StopOrdersService — 3: PostStopOrder, GetStopOrders, CancelStopOrder (stoporders.proto:19-25)
- UsersService — 4: GetAccounts, GetMarginAttributes, GetUserTariff, GetInfo (users.proto:19-28)
- SandboxService — 14: OpenSandboxAccount, GetSandboxAccounts, CloseSandboxAccount, PostSandboxOrder, ReplaceSandboxOrder, GetSandboxOrders, CancelSandboxOrder, GetSandboxOrderState, GetSandboxPositions, GetSandboxOperations, GetSandboxOperationsByCursor, GetSandboxPortfolio, SandboxPayIn, GetSandboxWithdrawLimits (sandbox.proto:20-59)

TOTAL = 27+7+2+7+2+5+1+3+4+14 = 72 RPCs across 10 services. The runbook's "~75" prose estimate resolves to an exact 72 (recorded as a learning). Two RPCs the runbook prose collapsed as "GetTradingStatus(es)" are DISTINCT in the proto (GetTradingStatus + GetTradingStatuses) — both carried, each → its own Investex function.

### T-3 — The Go wrap pattern + transport + canon, read and reconciled to investex

Go SDK (investgo/, read in full): `Client{conn *grpc.ClientConn, Config, Logger, ctx}` (client.go:26-31). `NewClient` (client.go:34-114): setDefaultConfig → context bearer + `x-app-name` via metadata.AppendToOutgoingContext → `grpc.Dial(EndPoint, TLS, perRPC oauth StaticTokenSource, ChainUnaryInterceptor, ChainStreamInterceptor)` → auto-bootstrap a sandbox account when AccountId=="" (GetSandboxAccounts → OpenSandboxAccount-if-none → else first ACCOUNT_STATUS_OPEN). 10 per-service `New<Svc>Client(c.conn)` constructors (client.go:137-268), each a thin stateless wrapper holding the shared conn + ctx. Per-RPC wrappers (orders.go, sandbox.go): build the proto request struct, call `pbClient.<Rpc>(ctx, req, grpc.Header, grpc.Trailer)`, return resp + header. `Stop()` = conn.Close (client.go:271-274).

Config (config.go): EndPoint, Token (yaml APIToken), AppName, AccountId, DisableResourceExhaustedRetry, DisableAllRetry, MaxRetries. Defaults (client.go:116-128): AppName="invest-api-go-sdk", EndPoint="sandbox-invest-public-api.tinkoff.ru:443", MaxRetries=3 (DisableAllRetry→0).

Retry (client.go:19-70): WAIT_BETWEEN=500ms; unary interceptor WithCodes(Unavailable, Internal) + BackoffLinear(500ms) + WithMax(MaxRetries); a SEPARATE exhaustedOpts interceptor WithCodes(ResourceExhausted) that waits silently (OnRetryCallback logs only), attached unless DisableResourceExhaustedRetry. Stream interceptor = the same retry on the stream client.

Transport (grpc.md): prod invest-public-api.tinkoff.ru:443 / sandbox sandbox-invest-public-api.tinkoff.ru:443, both TLS. Per-request `Authorization: Bearer <token>` metadata; `x-app-name` header (recommended format <GitHub-nick>.<repo>). Response headers: `x-tracking-id` (uuid per unary req; in streams passed explicitly), `message` (full error text), `x-ratelimit-limit`/`-remaining`/`-reset` (reset = seconds to counter zero). helpers.go: MessageFromHeader, RemainingLimitFromHeader(x-ratelimit-remaining).

Money (common.proto:28-48): `MoneyValue{currency string, units int64, nano int32}`, `Quotation{units int64, nano int32}`. converters.go BILLION=1_000_000_000; `FloatToQuotation` uses `Quotation.ToFloat()` — the float bridge the runbook says NOT to mirror. `Ping{time Timestamp}` (common.proto:72) = the stream keepalive.

The seam triangulated: exchange.specs.md:54 names `ORD` a spine id "validated at every door"; trd.progress.md "Go worker tier" names `PostOrderRequest.order_id` "the venue idempotency key"; orders.go:28/sandbox.go:69 pass `OrderId` to the proto. PostOrder fields (orders.go:22-29): Quantity, Price, Direction, AccountId, OrderType, OrderId, InstrumentId. ReplaceOrder (orders.go:130-139) maps NewOrderId → proto IdempotencyKey.

Streams (md_stream.go, portfolio_stream.go): each owns a `pb.<Svc>_<Rpc>Client`, a subscription set (per-type maps), Subscribe*/UnSubscribe* sending SubscriptionAction requests, a `Listen()` Recv loop dispatching by payload type to typed channels, `Stop()`=cancel(), UnSubscribeAll(), restart() on reconnect. README:106-109: "переподключается и переподписывает стрим на все подписки" — resubscribe-on-reconnect, the F-5 ground.

### T-4 — Dep-graph + quad-form + seam reconcile (the as-built facts the spec stands on)

Dep graph (F-2 / F-1 discharge — read the consuming surfaces, not mix.lock alone): `echo/mix.exs` is `apps_path: "apps"`, NO umbrella-root deps (deps/0 == []) — every app declares its own edges. `mix.lock` grep: `mint` 1.9.0, `castore` 1.0.19, `hpax` 1.0.3 PRESENT; `grpc` + `protobuf` ABSENT (0 hits). So `:grpc` over the Mint adapter adds NO new TRANSPORT dep (mint+castore+hpax already locked), but `:grpc` + `:protobuf` THEMSELVES are new hex deps investex's own `apps/investex/mix.exs` must declare. Lib-only precedent: `apps/exchange/mix.exs` has `application/0` with extra_applications:[:logger] and NO `mod:`, deps `[{:echo_data, in_umbrella: true}, {:stream_data, "~> 1.0", only: :test}]`; `apps/echo_data/mix.exs` same lib-only shape. investex copies it, adding `{:grpc, ...}` + `{:protobuf, ...}`.

Quad FORM (trd.2.* skeletons, the match target): `.md` = title + `<show-structure depth="2"/>` + status blockquote + Overview · Rationale · Design · The five W's · [named seam section] · Map · References. `.specs.md` = title + blockquote (authoritative + DoD: committed gate transcript) + Invariants (INV-n) · the as-built surface consumed (pinned, not rebuilt) · the vocabulary · Surface pinned · Decomposition (build order) · Mars notes · the cross-runtime seam · Acceptance gates (G-n) · Map. `.stories.md` = Developer stories (Connextra + Acceptance) · Agent stories (Directive + Gate, third-person framing) · Map. `.llms.md` = References (read first, ordered) · The surface (exact) · Requirements pattern (each → an invariant) · Execution topology · the boundary (do not build here) · Do NOT · Agent stories · Map. PATH NOTE: trd.2.* References cite `docs/bcs/...` (pre-rename); the dir is now `docs/exchange/` (ls confirms exchange.*.md + trd.*). The trd.9 quad uses CURRENT `docs/exchange/...` relative paths.

Rung gate precedent: `echo/rungs/exchange/trd_2_1_check.exs` (+ .out) — the committed-transcript gate the spec's DoD points at; the build rung writes `trd_9_N_check.exs`. Money/id canon (exchange.specs.md:54-56): ids = ORD/FIL/CMD/TXN/ACC/INS, "minted at the edge, validated at every door, byte-ordered by mint time"; money never float. echo_data is the Ecto-free canon (echo/CLAUDE.md §5): Portal.ID-style branded ids, BrandedId.hash32. NOTE for the spec: the actual branded-id mint API in echo_data is to be cited by the BUILD rung against the as-built echo_data surface (Snowflake/BrandedId); the spec names the seam (a branded ORD validated at the edge) without inventing the exact mint arity.

## {trd-9-decisions} Decisions

### D-1 — F-1 · App & deps: lib-only umbrella app `echo/apps/investex`

LOCKED. `:investex`, modules `Investex.*`, a LIBRARY app — `application/0` carries `extra_applications: [:logger]` and NO `mod:` (the consumer supervises a `Investex.Client`; nothing boots a venue connection at app start). Deps: `{:echo_data, in_umbrella: true}` (the {units,nano} + branded-id canon), `{:grpc, "~> 0.9"}` (a new hex dep), `{:protobuf, "~> 0.13"}` (a new hex dep), `{:stream_data, "~> 1.0", only: :test}`. (Build rung pins exact minors against hex.pm at build time.) Grounding: `echo/mix.exs` apps_path; `echo/apps/exchange/mix.exs` (the lib-only `{:echo_data, in_umbrella: true}` precedent, no `mod:`); `echo/apps/echo_data/mix.exs`. Alternative recorded V-1.

### D-2 — F-2 · gRPC transport: `:grpc` (elixir-grpc) over the Mint adapter + `:protobuf`

LOCKED. Transport = elixir-grpc over its Mint adapter (mint + castore + hpax already locked in `mix.lock` → NO new transport dep) + elixir-protobuf for the message codec. TLS + per-RPC metadata `authorization: "Bearer <token>"` and `x-app-name`, mirroring the Go dial (client.go:72-78: TLS creds + oauth StaticTokenSource per-RPC + x-app-name via metadata.AppendToOutgoingContext). Grounding: `mix.lock` (mint 1.9.0/castore 1.0.19/hpax 1.0.3 present; grpc/protobuf absent — 0 hits); client.go:37-39,72-78. Alternative recorded V-2.

### D-3 — F-3 · Codegen: protoc + protoc-gen-elixir from the committed contracts, generated modules COMMITTED

LOCKED. The 8 committed `.proto` contracts (common, instruments, marketdata, operations, orders, sandbox, stoporders, users) are compiled by `protoc` + `protoc-gen-elixir` into `Investex.Proto.*` message modules that are COMMITTED to the repo (reproducible build — no protoc at compile time, mirroring the Go SDK committing its `.pb.go`); a documented `mix investex.gen.proto`-style regen task records how to refresh them. Grounding: `github.local/invest-api-go-sdk/proto/*.proto` (the 8 source contracts); the committed `*.pb.go` precedent. Alternative recorded V-3.

### D-4 — F-4 · Client state: a supervised `Investex.Client` + stateless per-service modules

LOCKED. `Investex.Client` is a process owning the `GRPC.Channel` + the resolved `Investex.Config` (reconnect + the metadata interceptors in one place — the Go `Client{conn, Config}`, client.go:26-31). The seven unary per-service modules `Investex.{Instruments, MarketData, Operations, Orders, StopOrders, Users, Sandbox}` are STATELESS given a client handle — each public function takes the client + a typed request and returns `{:ok, response} | {:error, term}` (the Go thin per-service wrappers, orders.go/sandbox.go). One Elixir function per RPC. Grounding: client.go:26-31,137-268; orders.go. Alternative recorded V-4.

### D-5 — F-5 · Streaming: one supervised GenServer per streaming RPC, resubscribe-on-reconnect

LOCKED. Each of the 5 streaming RPCs (MarketDataStream bidi, MarketDataServerSideStream, TradesStream, PortfolioStream, PositionsStream) → a supervised GenServer owning the gRPC stream: it manages the subscription set, RESUBSCRIBES the full set on reconnect, answers `Ping` keepalives, and delivers decoded messages to a subscriber process. The raw gRPC stream is NOT exposed (it would lose resubscribe + subscription management — the Go SDK explicitly does not expose it). This is the hardest surface → it lands LAST, at trd.9.5. Grounding: md_stream.go (the subscription-set + Listen-loop + restart pattern), portfolio_stream.go; README:106-109 (resubscribe-on-reconnect); common.proto:72 (Ping). Alternative recorded V-5.

### D-6 — F-6 · Money & ids: {units,nano} integers via Investex.Money; the branded ORD seam

LOCKED. `Quotation` and `MoneyValue` decode to `{units, nano}` integer pairs via an `Investex.Money` helper — `from_quotation/1`, `to_quotation/1`, `from_money_value/1` — and NEVER to a float; the Go SDK's `Quotation.ToFloat()` / `FloatToQuotation` (converters.go) is deliberately NOT mirrored. The `order_id` field of PostOrder/PostSandboxOrder (the venue idempotency key) ACCEPTS a branded `ORD` id from `EchoData` and VALIDATES it at the edge before the request crosses the wire — the single seam joining the Exchange platform to the venue (ReplaceOrder's fresh id → proto IdempotencyKey likewise). Grounding: common.proto:28-48 ({units,nano}); exchange.specs.md (money never float; ORD a spine id "validated at every door", :54); trd.progress.md "Go worker tier" (PostOrderRequest.order_id = the venue idempotency key); orders.go:28,135. Alternative recorded V-6.

### D-7 — F-7 · Config & auth: Investex.Config mirroring investgo Config; Bearer + x-app-name

LOCKED. `Investex.Config` mirrors the Go Config: `endpoint` (default sandbox `sandbox-invest-public-api.tinkoff.ru:443`), `token` (read from `INVEST_TOKEN` env), `app_name` (default `jonnify.investex` — the recommended <nick>.<repo> form), `account_id`, retry knobs `disable_resource_exhausted_retry` / `disable_all_retry` / `max_retries` (default 3). Auth = `authorization: "Bearer <token>"` + `x-app-name` as per-RPC metadata. Grounding: config.go (the field set); client.go:37-39,116-128 (the bearer/x-app-name + defaults: AppName, EndPoint, MaxRetries=3, DisableAllRetry→0); grpc.md (endpoints, Bearer, x-app-name). The default app_name is RENAMED from the Go "invest-api-go-sdk" to "jonnify.investex" (the recommended own-repo form). Alternative recorded V-7.

### D-8 — F-8 · Retry / rate-limit: a PURE retry-decision function mirroring the Go interceptor

LOCKED. The retry policy mirrors the Go interceptor: linear 500ms backoff on `Unavailable`/`Internal` up to `max_retries`; a SEPARATE, longer, SILENT wait on `ResourceExhausted` honoring `x-ratelimit-reset`. The retry DECISION is a PURE function `(status, attempt, headers) -> {:retry, wait_ms} | :give_up` — unit-tested with no network (the Tier-1 gate covers it). Grounding: client.go:19-70 (WAIT_BETWEEN=500ms, codes Unavailable/Internal, the separate ResourceExhausted branch silent via OnRetryCallback, MaxRetries); grpc.md (x-ratelimit-reset = seconds to reset). Alternative recorded V-8.

### D-9 — F-9 · Test strategy: TWO tiers — a pure default gate + an opt-in sandbox suite that SKIPS keyless

LOCKED. Tier 1 (default `mix test` + the `--no-start` rung gate): codegen round-trip, the money codec, config defaults, request builders, branded-id validation, the pure retry-decision function — NO network, deterministic, CI-safe. Tier 2 (`@tag :sandbox`, EXCLUDED by default; run via `mix test --include sandbox`): hits the real sandbox endpoint with `INVEST_TOKEN` — open a sandbox account, GetAccounts, place + read a sandbox order, etc. The sandbox tests SKIP (not FAIL) when the key is absent (a `setup` that reads `System.get_env("INVEST_TOKEN")` and skips on nil). Grounding: README:20 + .env.test (INVEST_TOKEN); sandbox.go (the lifecycle); `echo/rungs/exchange/trd_2_1_check.exs` (the committed-transcript rung-gate precedent). Alternative recorded V-9.

### D-10 — F-10 · Parity definition: an exhaustive parity manifest (72 RPCs) + a parity CHECK

LOCKED. The spec carries a PARITY MANIFEST — the 10 services × their 72 RPCs (re-derived exact, T-2), each → a named `Investex.<Service>.<fun>/n` — and a parity CHECK: a test enumerating the proto service definitions and asserting each has a corresponding investex function. Parity is MEASURABLE, not "we covered it". Counts: Instruments 27, MarketData 7, MarketDataStream 2, Operations 7, OperationsStream 2, Orders 5, OrdersStream 1, StopOrders 3, Users 4, Sandbox 14 = 72. Grounding: `proto/*.proto` service defs (T-2); investgo/*.go exported methods. Alternative recorded V-10.

### D-11 — F-11 · Secret hygiene (hard, no alternative)

LOCKED. `INVEST_TOKEN` is read from the environment ONLY (`System.get_env`/`System.fetch_env!`), never hardcoded, never committed, never logged, never written into a transcript or any doc; `.env.test` stays in `github.local` (a gitignored external repo) and is read at test time, never copied into the repo; the token VALUE appears in NOTHING — not the spec, not the ledger, not a gate `.out`. The rule is STATED in trd.9.specs.md as INV-9 and in trd.9.llms.md "Do NOT". Grounding: README:20 (.env.test holds INVEST_TOKEN); the standing repo secret-handling discipline. No alternative (a hard rule).

D-12 — Decomposition: SandboxService SPLIT 9.1 (minimal bootstrap) / 9.3 (order lifecycle) / 9.4 (the rest)

LOCKED (the runbook's record-don't-block open point). SandboxService's 14 methods are NOT one early rung. Reasoning: the Go SDK auto-bootstraps a sandbox account inside NewClient (client.go:90-111), so OpenSandboxAccount/GetSandboxAccounts/CloseSandboxAccount are needed AT 9.1 to make the two-tier harness testable at all (the canonical sandbox smoke is GetAccounts + open/close). The sandbox ORDER methods (PostSandboxOrder/ReplaceSandboxOrder/Get/Cancel/GetState) belong with 9.3's order lifecycle (they ARE how an order is exercised without real money). The remaining sandbox surface (SandboxPayIn + the sandbox positions/operations/operationsByCursor/portfolio/withdrawLimits mirror) completes at 9.4. So: 9.1 = 3 bootstrap methods, 9.3 = 5 order methods, 9.4 = 6 remaining = 14 total. Grounding: client.go:90-111 (the bootstrap dependency); sandbox.go (the method shapes). This is Venus's decision per the runbook ("Venus decides and records the reasoning; not an Operator fork").

### D-12 — Director ratification: the TRD.9 chapter quad SHIPS

The Stage-3 solo review (Y-2) returned BUILD-GRADE on an independent pass: coverage re-enumerated from the proto (10 services / 72 RPCs, membership cross-checked method-by-method — zero fabricated, zero missing); no-invent spot-checks real (InstrumentsService, ReplaceOrderRequest.idempotency_key=7, MarketDataStreamService); secret-clean (no token-shaped string in any of the 6 files or the ledger; INVEST_TOKEN only as the env-var name); canon held ({units,nano} no-float + the .ToFloat() non-mirror; the branded ORD seam triangulated across 3 records); quad-form matches+extends the trd.2.* skeletons; the roadmap row + progress §TRD.9 landed. The lone finding — 4 forbidden-voice tokens — was closed by Venus and the Director independently re-grepped the quad CLEAN (zero). The two-edit replacements in trd.9.md read coherently.

LAW-1a held: the Director authored no spec content; Venus owns every byte; the review stayed adversarial. SHIP: one pathspec commit of the 9 trd.9 paths; the operator's out-of-band [redis] commit (HEAD 08ba5e63) and every other in-flight working-tree path are excluded (index verified empty pre-add). Risk NORMAL (spec-only); the build rungs TRD.9.1–9.5 are flagged HIGH (network / live secret / auth) → each warrants a dedicated Apollo + the secret-hygiene gate at build time.

## {trd-9-alternatives} Alternatives

### V-1 — F-1 alternatives (app & deps)

(a) Fold investex into `apps/exchange` — REJECTED: exchange is lib-only and PURE (no network, no `mod:`, AS-5 forbids external deps; trd.1.1.specs.md §70); a gRPC/TLS client with a supervised connection process would break that purity and couple the matching core to venue I/O. (b) Standalone non-umbrella mix project — REJECTED: loses `{:echo_data, in_umbrella: true}` (the {units,nano} + branded-id canon investex must share with the platform) and the shared _build/config/mix.lock. CHOSEN: a new lib-only umbrella app — isolates the network surface, keeps the canon edge in-umbrella, leaves exchange pure.

### V-2 — F-2 alternatives (gRPC transport)

(a) Hand-roll gRPC over Finch/Mint — REJECTED: 72 methods across 10 services with no codegen is an unmaintainable transcription surface; HTTP/2 framing + length-prefixed protobuf + trailers by hand is a large, bug-prone substrate the ecosystem already provides. (b) elixir-grpc over the `gun` adapter — REJECTED: adds `:gun` to the tree when `:mint` (+ castore + hpax) is already locked; the Mint adapter reuses what is present. CHOSEN: elixir-grpc over the Mint adapter + elixir-protobuf — no new transport dep, codegen for the 72 methods.

### V-3 — F-3 alternatives (codegen)

(a) Generate the proto modules at build time (protoc on every CI build) — REJECTED: requires protoc + protoc-gen-elixir on every build host and in CI, a brittle non-Elixir toolchain dependency on the compile path; the Go SDK avoids it by committing `.pb.go`. (b) Hand-write the message structs — REJECTED: scale (the contracts are 74k+/36k+/33k+ bytes of instrument/operations/marketdata messages); hand-transcription would invent field shapes the no-invent rule forbids. CHOSEN: protoc + protoc-gen-elixir, the generated modules COMMITTED, with a documented regen task — reproducible build, no protoc at compile time.

### V-4 — F-4 alternatives (client state)

(a) Stateless per-service functions taking an explicit `%GRPC.Channel{}` — RECORDED, not chosen: simpler (no process), but scatters reconnect and the metadata-interceptor concern across every call site, and gives no single owner for the channel lifecycle. CHOSEN: a supervised `Investex.Client` owning the channel + config (reconnect + interceptors in one place), with stateless per-service modules given the client handle — the Go `Client{conn, Config}` shape (client.go:26-31), one place that knows how to reconnect.

### V-5 — F-5 alternatives (streaming)

(a) Expose the raw elixir-grpc `Stream` to the caller — REJECTED: loses resubscribe-on-reconnect AND subscription-set management AND Ping handling; the caller would re-implement them per stream, and the Go SDK explicitly does NOT do this (it wraps each stream in a client owning the subscription set, md_stream.go; README:106-109 makes resubscribe a headline feature). CHOSEN: one supervised GenServer per streaming RPC owning the stream, the subscription set, resubscribe, and Ping — the Go stream-client pattern translated to OTP.

### V-6 — F-6 alternatives (money)

(a) Decode money to `Decimal` — REJECTED: the Exchange canon is the integer `{units, nano}` pair (exchange.specs.md; common.proto:41-48 Quotation = int64 units + int32 nano), and the platform's matching/ledger arithmetic is integer carry between nano and units (trd.2.specs.md AS-5: "integer `{units, nano}` arithmetic with integer carry; no float"). A Decimal boundary would convert at the seam and re-introduce a float-shaped type the canon refuses. CHOSEN: `{units, nano}` integers via `Investex.Money`, the same pair the whole platform speaks; `.ToFloat()` deliberately not mirrored.

### V-7 — F-7 alternatives (config & auth)

(a) App-env-only config (`Application.get_env`) — REJECTED as the sole mechanism: the Go SDK takes EXPLICIT config (config.go: a passed Config struct), and the test path reads the key from the environment (`INVEST_TOKEN`), not a compiled app-env; an app-env-only design would bury the per-call endpoint/account selection and the env-sourced token. CHOSEN: an explicit `Investex.Config` struct (the Go shape) whose `token` is sourced from `INVEST_TOKEN` at construction — explicit, testable, env-fed for the secret. (App-env MAY supply defaults, but the struct is the contract.)

### V-8 — F-8 alternatives (retry / rate-limit)

(a) No retry — REJECTED: parity (the Go SDK retries by default, client.go:41-70) and the venue rate-limits (grpc.md x-ratelimit-*; a ResourceExhausted with no wait would surface transient venue throttling as a hard failure to the caller). CHOSEN: the Go retry policy mirrored — linear 500ms on Unavailable/Internal, a separate silent ResourceExhausted wait honoring x-ratelimit-reset — with the DECISION extracted as a pure function so it is unit-tested without a network.

### V-9 — F-9 alternatives (test strategy)

(a) Only-sandbox tests — REJECTED: a non-deterministic gate (depends on a live endpoint + a present secret + network), so the rung gate could not be CI-safe or reproducible. (b) Only-pure tests — REJECTED: the Operator wants real sandbox PROOF the client actually trades against the venue, which a pure suite cannot give. CHOSEN: TWO tiers — a pure default gate (CI-safe, deterministic) PLUS an opt-in `@tag :sandbox` suite that hits the real sandbox and SKIPS (not fails) keyless, so both "deterministic gate" and "real proof" are satisfied without one blocking the other.

V-10 — F-10 alternatives (parity definition)

(a) Informal "we covered it" parity — REJECTED: the Operator's ask ("all api as go covers") must be MEASURABLE; an informal claim cannot be verified or regression-gated, and a missing method would be invisible. CHOSEN: an exhaustive parity manifest (72 RPCs → named functions) plus a parity-check test enumerating the proto and asserting each method maps — parity becomes a green/red gate, not a claim.

V-12 — Decomposition alternative (SandboxService placement)

(a) SandboxService as ONE early rung (all 14 methods at 9.1, or its own 9.x before the read/trade services) — RECORDED, not chosen: it would front-load 14 methods before the read/trade vocabulary they mirror exists (the sandbox order methods take the SAME PostOrderRequest as OrdersService; the sandbox operations/portfolio mirror OperationsService), duplicating request-builder work and testing order semantics before the real Orders rung defines them. CHOSEN (D-12): split 9.1 (3 bootstrap, needed to test anything) / 9.3 (5 order methods, with the order lifecycle) / 9.4 (6 remaining) — each sandbox method lands beside the real service it mirrors.

## {trd-9-learnings} Learnings

### L-1 — The RPC count is exactly 72, not "~75"

The runbook prose carried "~75 RPCs" as an estimate. Re-deriving from the proto service definitions (T-2) gives an EXACT 72 (Instruments 27 + MarketData 7 + MDStream 2 + Operations 7 + OpsStream 2 + Orders 5 + OrdersStream 1 + StopOrders 3 + Users 4 + Sandbox 14). The "~75" came partly from the runbook collapsing `GetTradingStatus(es)` into one prose entry where the proto has TWO distinct RPCs (GetTradingStatus + GetTradingStatuses, marketdata.proto:27,30) — re-deriving exposes both. The spec states 72 as the parity-manifest count; the manifest carries the two trading-status RPCs as distinct functions. This is exactly the figure-re-derivation the no-invent rule demands: the manifest's count is computed from the proto, not transcribed from the brief.

### L-2 — The "no new transport dep" claim is a per-app dep-graph fact, discharged correctly

F-2 claims `:grpc` over Mint adds no new TRANSPORT dep. Verified the RIGHT way (per the venus reconcile discipline): `mix.lock` carries mint 1.9.0 + castore 1.0.19 + hpax 1.0.3 (the HTTP/2 stack the Mint gRPC adapter rides) and NO grpc/protobuf. BUT the claim is precise: mint is already present, so elixir-grpc-over-Mint needs no NEW transport substrate — yet `:grpc` and `:protobuf` THEMSELVES are new hex deps that investex's OWN `apps/investex/mix.exs` deps/0 must declare (an umbrella app does not inherit a transitive lock as a compile-visible edge — the echo/mix.exs root has deps/0 == [], every app declares its own). The spec states it this way: no new transport STACK, two new codegen/grpc deps. This avoids the F6.7-class trap (a transitively-locked module is NOT compile-visible without the declared edge).

### L-3 — The branded ORD seam is triangulated across three committed records (discovered, not invented)

The F-6 seam (PostOrder's order_id accepts a branded ORD) is grounded by THREE independent committed records that converge on one proto field: (1) exchange.specs.md:54 names ORD a first-class spine id "minted at the edge, validated at every door"; (2) trd.progress.md "Go worker tier" names `PostOrderRequest.order_id` "the branded id is the job key and the venue idempotency key"; (3) orders.go:28 + sandbox.go:69 show `OrderId` is the field carried into the proto request (and ReplaceOrder, orders.go:135, maps a fresh id → the proto IdempotencyKey). The seam is not a spec invention — it is the platform's own existing decision about where the Exchange id meets the venue. The spec cites all three so the build rung attaches the validation at exactly that field.

L-4 — The Go SDK auto-bootstraps a sandbox account inside NewClient — this drives the decomposition

client.go:90-111: when Config.AccountId is empty, NewClient itself calls GetSandboxAccounts, opens one if none exist, else picks the first ACCOUNT_STATUS_OPEN. This is why the SandboxService bootstrap trio (Open/Get/Close) cannot be deferred to a late "full sandbox" rung — the two-tier test harness at 9.1 needs them to obtain an account to test against at all. It is the concrete reason D-12 splits SandboxService (9.1 bootstrap / 9.3 orders / 9.4 the rest) rather than placing it as one block. (investex need not auto-bootstrap inside its Client — the runbook's lib-only, consumer-supervised posture means bootstrap is an explicit caller/test step — but the methods must exist by 9.1.)

### L-4 — Stage-3 REVISE closed: 4 forbidden-voice tokens fixed; the 3 residual "I want" are mandated Connextra form, NOT violations

The Director's Stage-3 reconcile (BUILD-GRADE) returned one finding: 4 forbidden-voice tokens (the house rule bans "just" + interior-state/perceptual verbs applied to a SOFTWARE COMPONENT). Fixed exactly, minimally:
1. trd.9.stories.md:50 "not just compiles" → "not only compiles" (dropped "just").
2. trd.9.md:51 "starts the client when it wants a venue connection" → "when a venue connection is needed" (a supervision tree does not "want").
3. trd.9.md:52 "the matching core stays pure and unaware of the network" → "stays pure, with no coupling to the network" (a core is not "aware").
4. trd.9.llms.md:90 "supervised by the consumer when a stream is wanted" → "when a stream is needed".

Independent re-grep (absolute paths — a relative-cwd glob silently mis-fired first and reported a FALSE "clean"; the thread resets cwd between bash calls, so verification MUST use absolute paths): "just" → 0 hits; every "!" is System.fetch_env! (a real Elixir bang fn, none prose); the 4 fixed phrases present.

DISTINCTION held, not over-corrected: 3 residual "I want" remain at trd.9.stories.md:30,31,48 — these are the CONNEXTRA user-story form the venus charter MANDATES ("As a <role>, I want <capability>, so that <benefit>"), spoken by a HUMAN role (an operator / the Operator), NOT an interior-state verb applied to a tool/module/agent. The forbidden-voice rule bans the latter only. The shipped, Director-ratified exemplars prove it: trd.2.stories.md:20 "As an operator, ... I want the system to refuse...", :12 "As a desk, I place ... I see", :16 "I trust", :25 "I need"; trd.1.stories.md:18 "As a risk owner, I need". Changing the 3 would strip the prescribed Specification-by-Example form. Left as-is by design. The quad's third-person AGENT-framing (no agent "wants"/"sees") is intact; the first-person is the role's, in the developer-story voice only.

## {trd-9-progress} Progress

### P-1 — The TRD.9 chapter quad authored; six deliverables on disk, build-grade, PROPOSED

Authored (Venus, this rung): (1) docs/exchange/trd.9.md — the chapter narrative (Overview/Rationale/Design/five-W's/"The Exchange seam, named"/Map/References). (2) docs/exchange/trd.9.specs.md — AUTHORITATIVE: 9 invariants (INV-1..INV-9), the as-built surface + the lib-only umbrella-app mix.exs, the money/config/surface pins, the EXHAUSTIVE parity manifest (10 services × 72 RPCs → named Investex.<Service>.<fun>/n, one table per service, every RPC quoted from the proto), the 9.1-9.5 decomposition with the D-12 SandboxService-split reasoning, Mars notes, the cross-runtime/Exchange seam, 7 acceptance gates (G1-G7). (3) docs/exchange/trd.9.stories.md — 7 developer stories (Connextra + Acceptance) + 8 agent stories (Directive + Gate, third-person). (4) docs/exchange/trd.9.llms.md — References-read-first / the exact surface / Requirements→invariants / Execution topology / the Go-worker boundary / Do NOT / Agent stories / Map. (5) exchange.roadmap.md — the TRD.9 row + a milestone note + the recorded dependency. (6) trd.progress.md — the ### TRD.9 section + the "Go worker tier" open-decision reconcile (RESOLVED: investex is the dedicated venue-client subsystem; the money-math fleet stays distributed).

Self-verification (independent, run before reporting): secret hygiene CLEAN (zero token-shaped strings across all 6 files + the ledger — no example token quoted from grpc.md); all internal (foo.md) links resolve; the quad section skeleton matches trd.2.*; the manifest row-counts re-counted from the files = 27/7/2/7/2/5/1/3/4/14 = 72 exactly (matches the proto-derived count); INV-1..INV-9 each cited in both stories and llms (traceability closure). PROPOSED throughout. No code written; no git run. Coverage: 10 services / 72 methods mapped.

## {trd-9-report} Report

### Y-1 — TRD.9 (investex) chapter quad: BUILD-GRADE, PROPOSED, ready for the Director's reconcile

VERDICT: BUILD-GRADE. The TRD.9 chapter quad founds investex (echo/apps/investex, :investex, Investex.*) — the BEAM-native Tinkoff Invest client, full parity with the Go SDK at 10 services / 72 RPCs. Spec only, no code, no git, no token value anywhere.

DELIVERABLES (6, all on disk): trd.9.md · trd.9.specs.md · trd.9.stories.md · trd.9.llms.md (the quad); exchange.roadmap.md (TRD.9 row + milestone note + recorded dependency); trd.progress.md (### TRD.9 section + the Go-worker-tier open-decision reconcile).

COVERAGE: 10 services / 72 RPCs, each → a named Investex.<Service>.<fun>/n in the parity manifest (Instruments 27, MarketData 7, MarketDataStream 2, Operations 7, OperationsStream 2, Orders 5, OrdersStream 1, StopOrders 3, Users 4, Sandbox 14). Re-derived exact from proto/*.proto (the runbook's "~75" → 72; the two trading-status RPCs the prose collapsed are carried distinct — L-1). Every RPC quoted from the committed contracts; no method invented.

ARCHITECTURE LOCKED: D-1..D-11 = F-1..F-11 (lib-only umbrella app no mod:; elixir-grpc over Mint + protobuf, no new transport stack; committed protoc-gen-elixir modules; supervised Client + stateless per-service modules; one GenServer per stream, resubscribe-on-reconnect; {units,nano} integer money via Investex.Money, the .ToFloat() bridge NOT mirrored; Config mirroring investgo, env-sourced token, jonnify.investex app-name; the pure Investex.Retry.decide/3; the two-tier test strategy; the exhaustive manifest + parity-check; INVEST_TOKEN env-only secret hygiene). D-12 = SandboxService split 9.1/9.3/9.4 (3+5+6=14), reasoning recorded (the Go SDK auto-bootstraps a sandbox account in its constructor → the bootstrap trio is needed at 9.1). Each considered alternative recorded V-1..V-12; surprises L-1..L-4.

THE SEAM (triangulated, discovered not invented — L-3): the branded ORD id is PostOrder's order_id (the venue idempotency key), grounded in exchange.specs.md:54 (ORD "validated at every door") + trd.progress.md Go-worker-tier (PostOrderRequest.order_id = the venue idempotency key) + orders.go:28. investex is ADJACENT to the Go worker tier, not its replacement: the Go tier keeps GPU money-math; the BEAM gets a supervised, branded venue client.

RISK: the spec is NORMAL (a design doc); the build rungs 9.1-9.5 are flagged HIGH (real network / live secret / auth) → each warrants a dedicated Apollo + the secret-hygiene gate. The two-tier test discipline (pure default gate + opt-in sandbox suite that SKIPS keyless) and INV-9 are written into the spec.

SELF-VERIFY (independent, pre-report): secret hygiene CLEAN (0 token-shaped strings across the 6 files + ledger); all internal links resolve; quad form matches trd.2.*; manifest re-counted from the files = 72; INV-1..INV-9 each traced in stories + llms.

OPEN POINTS for the Director: none blocking. One judgment call surfaced, not decided: the parity-manifest arities are frozen as NAMES with a principled convention (client first; request-bearing → /2; no-arg reads → /1), with the exact per-argument request shape left to the build rung to realize against the proto request messages (stated in the spec) — so the manifest is the frozen contract of names+mapping, not a guess at every signature. If the Director prefers the spec pin exact arities now, that is a refinement, not a re-open. No Operator fork. NEXT FRONTIER: build TRD.9.1 (the transport spine) via x-mode, Apollo-gated.

### Y-2 — Director Stage-3 solo review: BUILD-GRADE pending 4 voice tokens

An INDEPENDENT pass (not a glance at Y-1), against the real proto/SDK surface:

(a) COVERAGE. Re-enumerated the proto (grep service/rpc over proto/*.proto): ground truth = 10 services / 72 RPCs. Cross-checked the manifest membership method-by-method against the sorted proto RPC list — all 72 present, each in its correct service, zero fabricated, zero missing. The per-service counts (27/7/2/7/2/5/1/3/4/14) re-add to 72.

(b) NO-INVENT. Spot-checked cited proto: InstrumentsService real (instruments.proto:16); ReplaceOrderRequest.idempotency_key = 7 real (orders.proto:170) — grounds the spec's "the proto IdempotencyKey" claim; MarketDataStreamService real (marketdata.proto:39). Citations point to the rpc-block region (a few lines off the `service` keyword line) — real artifacts, no invention.

(c) SECRET (INV-9/G7 self-applied to this rung). Grep for token-shaped strings (`t.<...>`, `Bearer <literal>`, the grpc.md example `QtEo8ahk`) across all 6 authored files + the ledger: CLEAN — the example token was NOT copied. `INVEST_TOKEN` appears only as the env-var NAME (14×, all backticked code). INV-9 stated in specs + llms.

(d) CANON. Money is {units,nano} integer, never float (INV-3 + the deliberate .ToFloat() non-mirror); the branded ORD seam (INV-4) triangulated across 3 committed records (exchange.specs.md:54 + trd.progress.md Go-worker-tier + orders.go:28); the new grpc/protobuf deps named, lib-only no `mod:`.

(e) QUAD FORM. Matches and extends the trd.2.* skeletons; the roadmap TRD.9 row landed (5 refs) and the progress §TRD.9 section landed (line 203). All internal links resolve.

(f) The exclamation-mark grep hits (stories:44,89; specs:58,334) are all `System.fetch_env!` — a real Elixir bang function, NOT prose exclamations. Not violations.

FINDINGS — REVISE → Venus (4 voice tokens; the house forbidden-word + interior-state-verb rule):
  1. trd.9.stories.md:50 — "not just compiles" (forbidden "just").
  2. trd.9.md:51 — "when it wants a venue connection" ("wants" → "is needed").
  3. trd.9.md:52 — "pure and unaware of the network" ("unaware" → "with no coupling to" / "isolated from").
  4. trd.9.llms.md:90 — "when a stream is wanted" ("wanted" → "needed").

AFFIRMED (no change): Venus's arity judgment — freeze the manifest as NAMES + a principled convention (client first; request-bearing → /2; no-arg reads → /1), with exact per-argument request shapes left to the build rung to realize against the proto request messages. This is correct for a chapter spec; pinning exact arities now would risk inventing per-call shapes ahead of the build (against the no-invent rule). Not an Operator fork.

VERDICT: BUILD-GRADE once the 4 voice tokens close. LAW-1a held — the Director authored no spec content; the fixes route to Venus.

## {trd-9-complete} Complete

### Z-1 — TRD.9 (investex) chapter quad SHIPPED

The BEAM-native Tinkoff Invest client founded as a specification: echo/apps/investex, :investex, Investex.* — full parity with the Go SDK at 10 gRPC services / 72 RPCs, each mapped to a named Investex.<Service>.<fun>/n in an exhaustive parity manifest. Spec only; no code; no token value anywhere.

DELIVERABLES (one pathspec commit, 9 paths): the quad trd.9.{md,specs.md,stories.md,llms.md}; the trd.9.prompt.md runbook; the exchange.roadmap.md TRD.9 row; the trd.progress.md TRD.9 section (the Go-worker-tier open decision RESOLVED — investex is the dedicated venue-client subsystem, the money-math fleet stays distributed); the trd-9 ledger + registry. The operator's out-of-band [redis] commit (HEAD 08ba5e63) and every other in-flight working-tree path excluded.

RATIFICATION: the Director's Stage-3 solo review (Y-2) — coverage re-enumerated from the proto (72/72, membership method-by-method, zero fabricated), no-invent spot-checks real, secret-clean (no token-shaped string in any file or the ledger), canon held ({units,nano}/no-float, the ORD seam triangulated), quad-form matches trd.2.* — returned BUILD-GRADE; the lone finding (4 forbidden-voice tokens) was closed by Venus and independently re-grepped CLEAN. The Director ratification decision is locked in the ledger (the {trd-9-decisions} channel). LAW-1a held — the Director authored no spec content.

DECISIONS: the architecture spine F-1..F-11 + the SandboxService split (9.1/9.3/9.4) + the Director ratification (D-1..D-12). Alternatives V-1..V-12; learnings L-1..L-4 (incl. L-1 the exact 72-RPC count, L-3 the triangulated ORD seam, L-4 the sandbox-bootstrap-drives-decomposition). Reports Y-1 (Venus) + Y-2 (Director).

RISK: NORMAL (spec-only). The build rungs TRD.9.1-9.5 are HIGH risk (real network / live secret / auth) — each warrants a dedicated Apollo + the secret-hygiene gate.

NEXT FRONTIER: build TRD.9.1 — the transport spine (Investex.Config + the committed protoc-gen-elixir Investex.Proto.* + Investex.Client + the pure Investex.Retry.decide/3 + UsersService end-to-end + the sandbox bootstrap trio + the two-tier test harness) via x-mode, Apollo-gated.
