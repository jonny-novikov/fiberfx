# TRD.9.1 · The Transport Spine — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung **TRD.9.1** — the first shippable slice of TRD.9 ([`trd.9.specs.md`](trd.9.specs.md) is the
> full rung; this file is the transport-spine carve-out the build delivers now). The chapter ([`trd.9.1.md`](trd.9.1.md))
> narrates it. **Status: PROPOSED.** Definition of done: a committed transcript at
> `echo/rungs/exchange/trd_9_1_check.out`, exit zero, every Tier-1 gate line green (the `trd_2_1_check.exs` rung-gate
> pattern), AND the live sandbox round-trip PASSED (the Operator's hard gate). Feedback edits this file, not the
> implementation. **Framing (propagate this clause): third person for any agent; no gendered pronouns; no perceptual or
> interior-state verbs; no first-person narration.** **Secret hygiene (INV-9, hard): the `INVEST_TOKEN` value appears in
> nothing this rung writes — read it from the environment only.**

## What TRD.9.1 is — and is not

TRD.9.1 founds `echo/apps/investex` (OTP `:investex`, modules `Investex.*`, lib-only — the `echo/apps/exchange`
template) and ships the transport spine standalone: the smallest surface that proves the whole venue-client vertical
end to end. It builds Config + the committed codegen + the supervised TLS client + the pure retry decision + the
integer-money codec + UsersService (4) + the sandbox bootstrap (3) + the typed error + the parity scaffold + the
two-tier harness. It is pure-gated (network-free, deterministic) AND live-sandbox-verified.

**In TRD.9.1 (this slice):**

- `echo/apps/investex/mix.exs` — lib-only (`def application, do: [extra_applications: [:logger]]`, **no `mod:`**);
  deps `{:echo_data, in_umbrella: true}` + `{:grpc, "~> 0.9"}` + `{:protobuf, "~> 0.13"}` + `{:stream_data, "~> 1.0",
  only: :test}` (the exact current minors **verified against hex at build**, pinned in `mix.exs`/`echo/mix.lock` —
  **[RECONCILE] as-built: hex resolved the current stable lines `{:grpc, "~> 0.11"}` (grpc 0.11.5) + `{:protobuf, "~> 0.17"}`
  (protobuf 0.17.0), newer than the `~> 0.9`/`~> 0.13` literal; this is the L-4 realization-over-literal the spec directed**);
- the **committed** generated message modules (protoc-gen-elixir over the 8 contracts) + a documented regen `Mix.Task`;
- `Investex.Config` — struct + `new/1` + `resolve/1` (reads `INVEST_TOKEN` from env);
- `Investex.Client` — supervised; owns the TLS `GRPC.Channel` + resolved Config; `start_link/1`, `channel/1`, `stop/1`;
  per-RPC `Bearer` + `x-app-name` metadata;
- `Investex.Retry.decide/3` — **pure** `(status, attempt, headers) -> {:retry, wait_ms} | :give_up`;
- `Investex.Money` — `from_quotation/1`, `to_quotation/1`, `from_money_value/1` over integer `{units, nano}` (R-2, D-2);
- `Investex.Error` — the typed `{:error, reason}` value the per-service functions return;
- `Investex.Users` — `get_accounts/1`, `get_margin_attributes/2`, `get_user_tariff/1`, `get_info/1` (4);
- `Investex.Sandbox` — `open_account/1`, `get_accounts/1`, `close_account/2` (the bootstrap trio);
- the parity-check **scaffold** (G1-scaffold, R-3, D-3) and the two-tier harness (Tier 1 pure + Tier 2 `@tag :sandbox`);
- the rung gate `echo/rungs/exchange/trd_9_1_check.exs` + its committed transcript;
- gates **G1-scaffold, G2, G4, G5, G6 (9.1 scope), G7** + INV-5/6/8/9 + INV-3 + INV-1 (the growing scaffold).

**Deferred to 9.2–9.5 (NOT built here — the full rung [`trd.9.specs.md`](trd.9.specs.md) carries them; named in the
chapter's "Deferred to 9.2–9.5"):**

- the branded `ORD` edge-validation seam (INV-4, **gate G3**) — `post_order` / `replace_order` / `Sandbox.post_order`
  and the `EchoData` ORD validation → **9.3** (this slice places no order; `{:echo_data, in_umbrella: true}` is
  declared but **not exercised**);
- full 72-RPC parity (**G1 complete**, the "count prints 72" assertion) → **9.5**;
- the read services (Instruments 27 / MarketData 7 / Operations 7) → 9.2; the trading services (Orders 5 / StopOrders 3
  + the 5 sandbox order methods) → 9.3; the rest of SandboxService (6 methods) → 9.4; the 5 streams (INV-7) → 9.5.

The boundary is the Director's Stage-3 reconcile target: no order method, no `EchoData` ORD validation call, no stream
GenServer, no read-service function in this slice's diff.

## Invariants (the subset this slice gates)

Inherited verbatim from [`trd.9.specs.md`](trd.9.specs.md); the ones this slice builds and gates:

- **INV-3 — money is `{units, nano}` integers, never float (Money lands at 9.1, D-2).** `Quotation` and `MoneyValue`
  decode to `{units, nano}` integer pairs through `Investex.Money`; no float appears in any decoded money value,
  request, or response shape the codec exposes. The Go `ToFloat`/`FloatToQuotation` bridge is deliberately **not**
  ported. *(Scoped: the codec is pure and gated by a round-trip property (G2); no decoded-money assertion is made
  against the live UsersService responses, which carry none.)*
- **INV-5 — the client owns the channel.** A supervised `Investex.Client` owns the `GRPC.Channel` and the resolved
  `Investex.Config` (the bearer / `x-app-name` metadata in one place). The per-service modules are stateless given a
  client handle. investex is **lib-only** — no `mod:`, nothing booted at app start; the consumer supervises the client.
- **INV-6 — pure retry decision.** `Investex.Retry.decide/3` — `(status, attempt, headers) -> {:retry, wait_ms} |
  :give_up` — is a pure function: linear 500 ms on `Unavailable`/`Internal` under the cap, a longer silent wait on
  `ResourceExhausted` honoring `x-ratelimit-reset` (a refinement over the Go interceptor, L-2), `:give_up` past
  `max_retries`. Unit-tested with no network; no clock, sleep, `Process.*`, or IO in the decision.
- **INV-8 — two test tiers, and the live tier proves its own liveness.** A pure default suite (`mix test` + the
  `--no-start` rung gate): config defaults, the money codec, the retry decision, the parity scaffold — no network,
  deterministic. An opt-in sandbox suite (`@tag :sandbox`, **excluded by default** — a bare `mix test` never reaches
  it, the keyless-CI case). **Once the caller opts in with `--include sandbox` it is a TRUE hard gate, and the gate
  is responsible for its OWN liveness** (the Apollo L-9 contract, folded into the brief): (a) with `INVEST_TOKEN`
  present, the live tests MUST actually dial — each asserts a positive dialed-proof (a non-empty `account_id` / a
  decoded accounts list), so a no-op self-skip can never satisfy the gate's letter while defeating its intent; (b)
  with the token **absent under `--include sandbox`**, the suite **FAILS loudly** (the `setup` `flunk`s) — a requested
  live gate that cannot run is a failure, NEVER a silent skip-or-pass. **A test in this tier (or any tier) must never
  decide its own runnability by reading process-global state a concurrent test can mutate** — the prior false-green
  was a default-excluded suite reading `System.get_env("INVEST_TOKEN")` while an `async` peer cleared it (L-9); the
  default-exclude + the keyless-`flunk` together remove that whole class.
- **INV-9 — secret hygiene (hard).** `INVEST_TOKEN` is read from the environment only (`System.get_env` /
  `System.fetch_env!`) — never hardcoded, committed, logged, or written into a transcript, fixture, gate `.out`, or
  any doc. `.env.test` stays in `github.local` (gitignored) and is read at test time, never copied into the repo. The
  token **value** appears in nothing this rung writes.
- **INV-1 — full parity, measured (the growing scaffold this slice, D-3).** The parity-check test enumerates the proto
  service definitions and asserts the 7 implemented RPCs map to their named `Investex.<Service>.<fun>/n`, carrying the
  unimplemented 65 as an explicit pending list; a later un-mapped function fails the growing gate. The full
  "count prints 72" assertion is **9.5**.

**Deferred to later rungs (named so their absence is a decision, not an omission):** INV-4 (the branded `ORD` seam) →
9.3; INV-7 (streams resubscribe on reconnect) → 9.5. This slice holds INV-3/5/6/8/9 fully and INV-1 as the scaffold.

## The as-built surfaces this rung consumes (pinned, not rebuilt)

### The canon — declared `{:echo_data, in_umbrella: true}`, NOT exercised this slice

```elixir
# echo/apps/echo_data — the branded-id + {units,nano} canon. investex DECLARES it
# (mix.exs deps) because the trading rung (9.3) mints/validates branded ORD ids through
# this surface. 9.1 places no order, so it is a DECLARED EDGE, not a call site here.
EchoData.Snowflake.next_branded(ns)   # snowflake.ex:104 — mint a branded id (9.3, not 9.1)
EchoData.BrandedId.namespace(id)      # branded_id.ex:97 — the 3-byte namespace (9.3)
EchoData.BrandedId.decode(id)         # branded_id.ex:55
EchoData.BrandedId.decode!(id)        # branded_id.ex:59
EchoData.BrandedId.valid?(id)         # branded_id.ex:95 — full-format validation (9.3)
```

### The committed Tinkoff Invest contracts — the parity + codec source

```text
# github.local/invest-api-go-sdk/proto/*.proto (8 contracts). 9.1 NEEDS:
#   common.proto   — Quotation, MoneyValue, Ping (the money + keepalive vocabulary)
#   users.proto    — UsersService (the 4 RPCs)
#   sandbox.proto  — SandboxService (the bootstrap trio + the deferred 11)
# Imports are bare (import "common.proto", import "google/protobuf/timestamp.proto")
# → codegen runs -I proto/ and relies on protoc's bundled well-known types;
# elixir-protobuf ships Google.Protobuf.* (the Timestamp the Account dates use).
```

### The Go SDK wrap pattern — the parity reference (read, not run)

```text
# github.local/invest-api-go-sdk/investgo/
#   config.go             — the Config fields (EndPoint/Token/AppName/AccountId/
#                           DisableResourceExhaustedRetry/DisableAllRetry/MaxRetries)
#   client.go:19-70       — WAIT_BETWEEN=500ms; the linear (Unavailable/Internal) +
#                           ResourceExhausted retry interceptors; DisableResourceExhausted drops RE
#   client.go:37-39,72-78 — Bearer + x-app-name metadata; the TLS dial
#   client.go:90-111      — the sandbox auto-bootstrap (GetSandboxAccounts; none⇒OpenSandboxAccount;
#                           else find ACCOUNT_STATUS_OPEN) — why the trio is in 9.1 (chapter L-4)
#   client.go:116-128     — setDefaultConfig (the defaults below)
#   client.go:271-274     — Stop() closes the conn
#   sandbox.go:20,33,46   — OpenSandboxAccount()/GetSandboxAccounts() no-arg; CloseSandboxAccount(accountId)
# Transport: github.local/investAPI/src/docs/grpc.md (Bearer l.20/79, x-app-name l.55,
#   endpoints l.29/31, x-ratelimit-reset = seconds-to-reset l.92).
```

### The proto RPCs this slice maps (quoted, the contract of names)

```text
# UsersService — users.proto:19-28
GetAccounts          (GetAccountsRequest{} EMPTY)              → GetAccountsResponse           # users.proto:19,32
GetMarginAttributes  (GetMarginAttributesRequest{account_id}) → GetMarginAttributesResponse   # users.proto:22,82
GetUserTariff        (GetUserTariffRequest{} EMPTY)            → GetUserTariffResponse          # users.proto:25,111
GetInfo              (GetInfoRequest{} EMPTY)                  → GetInfoResponse                # users.proto:28,134

# SandboxService — sandbox.proto:20-26 (the 9.1 bootstrap trio)
OpenSandboxAccount   (OpenSandboxAccountRequest{} EMPTY)       → OpenSandboxAccountResponse{account_id}  # sandbox.proto:20,63,68
GetSandboxAccounts   (GetAccountsRequest{} EMPTY)              → GetAccountsResponse            # sandbox.proto:23
CloseSandboxAccount  (CloseSandboxAccountRequest{account_id}) → CloseSandboxAccountResponse{}  # sandbox.proto:26,73,78
```

The arity convention follows the proto request shape directly: a **no-field** request → `/1` (`get_accounts/1`,
`get_user_tariff/1`, `get_info/1`, `open_account/1`, `Sandbox.get_accounts/1`); an **account-id-bearing** request →
`/2` (`get_margin_attributes/2`, `close_account/2`). The client handle is the first argument throughout.

## The realization decisions (R-1/R-2/R-3 — settled; each a locked D-n, the alternative a V-n)

These three the chapter spec could not foresee; this slice settles them.

**R-1 — the codegen namespace (D-1; alternative V-1).** protoc-gen-elixir derives the Elixir module namespace from the
proto `package tinkoff.public.invest.api.contract.v1` (common.proto:3) → it emits
`Tinkoff.Public.Invest.Api.Contract.V1.{Quotation,MoneyValue,GetAccountsRequest,…}`, **not** the literal
`Investex.Proto.*` the chapter §Surface / §money-vocabulary names. **Settled:** accept the generated names; inside each
investex module that references a generated struct, `alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto`, so call
sites read `%Proto.Quotation{}` exactly as the chapter prose intends. No rename of the generated tree (rejected as
regen-fragile, V-1). The chapter's `Investex.Proto.*` is a **spec-literal realized as the `Proto` alias** — a
realization-over-literal (L-1), not a STALE: the generated module names are the namespace of record, and the alias is
the binding contract Mars realizes.

**R-2 — `Investex.Money` placement (D-2; alternative V-2).** The chapter §Surface lists
`Investex.Money` but the 9.1 decomposition bullet does not name it, and no implemented RPC's response carries
`Quotation`/`MoneyValue` (only the deferred `GetMarginAttributes` does). **Settled: Money LANDS in 9.1.** Reasoning:
the generated `Quotation`/`MoneyValue` structs exist the instant the 9.1 codegen runs; the codec is pure and
network-free (it fits Tier 1 and the `--no-start` gate with zero risk); it is the integer-`{units, nano}` contract the
whole platform speaks (INV-3) and it de-risks the money-dense read services (9.2). Consequence: **INV-3 and gate G2 are
in-scope for 9.1** (scoped to the pure codec). Deferring it to 9.2 (V-2) was rejected: the cost now is near-zero and
the benefit — the money invariant present from rung one — is real.

**R-3 — G1 at 9.1 (D-3; the gate-shape D-4).** The parity test is built in 9.1 but cannot assert all 72 RPCs (only 7
exist). **Locked: a growing scaffold.** The test enumerates the proto and asserts the 7 implemented RPCs map to their
named functions, carrying the unimplemented 65 as an **explicit pending list** — so a 9.2+ function landing un-mapped
(or a 9.1 function renamed/dropped) fails the growing gate; rows move pending → asserted monotonically. The
"count prints 72" full assertion completes at 9.5. The rung gate is a **compiled-umbrella** `mix run --no-start` runner
(D-4) — NOT a `Code.require_file` pure runner like trd.2.1's, because Config/Money/the scaffold reference the generated
`:protobuf` structs, which exist only as compiled artifacts; the runner aliases the compiled modules directly, dials
nothing, and stays network-free.

## Surface, pinned (exact — Mars cites a line per call)

```elixir
# Config (mirrors investgo Config — config.go; defaults client.go:116-128) ───────
%Investex.Config{
  endpoint: String.t(),                         # default "sandbox-invest-public-api.tinkoff.ru:443"  [RECONCILE] CORRECTED by TRD.9.1.1 (DEFECT A): the live host is the T-Bank rebrand "sandbox-invest-public-api.tbank.ru:443", and resolve/1 env-resolves it from INVEST_API_URL + INVEST_API_PORT (INV-10). The as-built …tinkoff.ru default is a stale sinkhole; trd.9.1.1.specs.md authoritative.
  token: String.t(),                            # from INVEST_TOKEN env (INV-9) — never a struct literal/default
  app_name: String.t(),                         # default "jonnify.investex" (the <nick>.<repo> rename of the Go default)
  account_id: String.t() | nil,                 # default nil
  disable_resource_exhausted_retry: boolean(),  # default false
  disable_all_retry: boolean(),                 # default false (true ⇒ max_retries 0)
  max_retries: non_neg_integer()                # default 3
}
Investex.Config.new(opts :: keyword() | map())  :: %Investex.Config{}   # applies the defaults above
Investex.Config.resolve(%Investex.Config{})     :: %Investex.Config{}   # reads INVEST_TOKEN into :token

# Client — the one supervised process; owns channel + config (INV-5) ─────────────
#   [RECONCILE] TLS posture CORRECTED by TRD.9.1.1 (DEFECT B): tls_opts/0 does NOT verify against the OTP
#   system trust store alone — that bundle holds 0 Russian roots and the venue chains leaf → Russian Trusted
#   Sub CA → Russian Trusted Root CA (self-signed, absent from the bundle), so every verifying handshake was
#   rejected. As corrected, tls_opts/0 APPENDS a vendored + fingerprint-pinned Russian Trusted Root CA
#   (priv/certs/russian_trusted_root_ca.pem, SHA-256 D2:6D:…:CF:31) to :public_key.cacerts_get(), keeping
#   verify: :verify_peer + depth: 3 (never verify_none) — INV-11; trd.9.1.1.specs.md authoritative.
Investex.Client.start_link(config :: %Investex.Config{}) :: {:ok, pid} | {:error, term}
Investex.Client.channel(client)                          :: GRPC.Channel.t()   # the resolved channel
Investex.Client.request_metadata(client)                 :: %{String.t() => String.t()}  # [RECONCILE] as-built: the frozen Bearer + x-app-name map the Caller seam attaches; built once at dial (client.ex:71-77)
Investex.Client.stop(client)                             :: :ok                # conn close (client.go:271-274)
#   lib-only — no mod:; the CONSUMER (or a test) supervises start_link/1; per-RPC
#   authorization: "Bearer <token>" + x-app-name: <app_name> metadata (client.go:37-39,72-78).
#   [RECONCILE] PRECONDITION (L-6, as-built): grpc 0.11.x requires the consumer to
#   supervise {GRPC.Client.Supervisor, []} BEFORE any start_link/1 — the :grpc app
#   does not start it, and investex is lib-only. dial/1 fails fast (secret-free) if unmet;
#   the suite starts it in test/test_helper.exs.

# Retry — pure decision (INV-6) ──────────────────────────────────────────────────
Investex.Retry.decide(status :: atom(), attempt :: non_neg_integer(), headers :: map())
  :: {:retry, wait_ms :: non_neg_integer()} | :give_up
#   decide/3 uses the spec-default cap (3) and RE-enabled (delegates to decide/4 with Config.new([])).
Investex.Retry.decide(status :: atom(), attempt :: non_neg_integer(), headers :: map(), config :: %Investex.Config{})
  :: {:retry, wait_ms :: non_neg_integer()} | :give_up   # [RECONCILE] as-built: the cap-and-flag-bearing form; config.max_retries is the cap, disable_resource_exhausted_retry gates the RE branch (retry.ex:95-110). Still pure (Config is a plain value).
#   :unavailable/:internal under the cap ⇒ {:retry, 500}; :resource_exhausted under the
#   cap ⇒ {:retry, wait_ms} honoring x-ratelimit-reset (L-2); past max_retries ⇒ :give_up.
#   No clock, no sleep, no Process.*, no IO — the interceptor that APPLIES it is the shell.

# Money — integer {units,nano} codec (INV-3, R-2/D-2) ────────────────────────────
@type money :: {units :: integer(), nano :: integer()}                     # Quotation/MoneyValue; common.proto:28-48
Investex.Money.from_quotation(%Proto.Quotation{})   :: money()
Investex.Money.to_quotation(money())                :: %Proto.Quotation{}
Investex.Money.from_money_value(%Proto.MoneyValue{}) :: {money(), currency :: String.t()}
#   (Proto = alias Tinkoff.Public.Invest.Api.Contract.V1, R-1/D-1.) No float in any value.

# Error — the typed {:error, reason} value the per-service functions return ───────
Investex.Error.t()   # the closed error vocabulary; the concrete shape is Mars's (a struct + new/1, the gateway.ex style)
#   [RECONCILE] as-built (D-6): %Investex.Error{reason, status, message}, @enforce_keys [:reason, :message],
#   closed reason :no_channel | :rpc_error | :retry_exhausted; new/1 (bare reason | opts) + from_rpc/1
#   (maps %GRPC.RPCError{} → :rpc_error, lifting the gRPC status to the snake_case atom Retry keys on,
#   via GRPC.Status.code_name |> Macro.underscore — Apollo verified 14/13/8/5 → :unavailable/:internal/
#   :resource_exhausted/:not_found end-to-end). :retry_exhausted has no producer this slice (reserved).

# Caller — the one shared unary-call seam (NOT in the original pinned surface) ─────
#   [RECONCILE] as-built (D-6): Investex.Caller.unary(client, stub_fun, request) :: {:ok, struct()} |
#   {:error, Investex.Error.t()}. The single place the frozen Bearer + x-app-name metadata attaches at
#   call time; Users/Sandbox both delegate to it (stateless). nil channel → Error.new(:no_channel);
#   {:error, %GRPC.RPCError{}} → Error.from_rpc/1; an unknown transport term → a fixed reason-free
#   message (no inspect of a token-bearing term, INV-9 structural).

# UsersService — 4 (users.proto:19-28) ───────────────────────────────────────────
Investex.Users.get_accounts(client)                         :: {:ok, %Proto.GetAccountsResponse{}} | {:error, Investex.Error.t()}
Investex.Users.get_margin_attributes(client, account_id)    :: {:ok, %Proto.GetMarginAttributesResponse{}} | {:error, Investex.Error.t()}
Investex.Users.get_user_tariff(client)                      :: {:ok, %Proto.GetUserTariffResponse{}} | {:error, Investex.Error.t()}
Investex.Users.get_info(client)                             :: {:ok, %Proto.GetInfoResponse{}} | {:error, Investex.Error.t()}

# SandboxService bootstrap — 3 (sandbox.proto:20-26) ─────────────────────────────
Investex.Sandbox.open_account(client)                       :: {:ok, %Proto.OpenSandboxAccountResponse{}} | {:error, Investex.Error.t()}
Investex.Sandbox.get_accounts(client)                       :: {:ok, %Proto.GetAccountsResponse{}} | {:error, Investex.Error.t()}
Investex.Sandbox.close_account(client, account_id)          :: {:ok, %Proto.CloseSandboxAccountResponse{}} | {:error, Investex.Error.t()}
```

The generated message modules (`%Proto.GetAccountsResponse{}` etc.) are the **committed** protoc-gen-elixir output;
their field sets are the proto's (Mars cites the proto message, never invents a field). `Investex.Error.t()`'s concrete
representation is Mars's call (a struct + `new/1`, the `gateway.ex` house style); the contract is the public arities +
the `{:ok, _} | {:error, Investex.Error.t()}` shape above.

## The locked decisions (each a `tool_x_decision` in `docs/exchange/trd-9-1.progress.md`)

1. **Slice boundary (the deferred set above).** `echo/apps/investex` ships Config + the committed codegen +
   Client + the pure Retry + Money + UsersService (4) + the sandbox bootstrap (3) + Error + the parity scaffold + the
   two-tier harness. No order method, no `EchoData` ORD validation, no stream, no read-service function — those are
   9.2–9.5.
2. **The codegen namespace is the generated one, aliased `Proto` (D-1).** Accept
   `Tinkoff.Public.Invest.Api.Contract.V1.*`; `alias … as: Proto` per module. No rename. The chapter's `Investex.Proto.*`
   is the alias (L-1).
3. **`Investex.Money` lands in 9.1 (D-2).** The pure integer-`{units, nano}` codec, gated by G2; the Go float bridge not
   ported (INV-3).
4. **G1 is a growing scaffold (D-3).** Assert the 7 implemented RPCs map; carry the 65 unimplemented as an explicit
   pending list; the count completes at 9.5.
5. **The rung gate is a compiled-umbrella `--no-start` runner (D-4).** `mix run --no-start`, one printed line per gate,
   nonzero exit on fail, committed `.out`, network-free; it aliases the compiled generated modules (not
   `Code.require_file`), and `:investex` (lib-only) boots no connection.
6. **The token is env-only (INV-9).** `Investex.Config.resolve/1` reads `INVEST_TOKEN` via `System.fetch_env!` /
   `System.get_env`; the value is never a struct default, a config literal, a log line, a fixture, or a transcript. The
   sandbox `setup` reads the env and `ExUnit`-skips on `nil`.
7. **The retry decision is pure and header-honoring (INV-6, L-2).** `decide/3` reads `x-ratelimit-reset` from
   `headers` for the `ResourceExhausted` wait (the refinement over the Go interceptor, L-2); the forbidden set
   (clock/sleep/`Process.*`/network/IO) is empty in the decision function.

## Decomposition (the build order)

**Step one — the app + the deps + the committed codegen.** Scaffold `echo/apps/investex` lib-only (the
`echo/apps/exchange` template); add `{:grpc, "~> 0.9"}` + `{:protobuf, "~> 0.13"}` (verify the exact minors against hex,
pin them) + `{:stream_data, "~> 1.0", only: :test}` + `{:echo_data, in_umbrella: true}`; install protoc-gen-elixir
(`mix escript.install hex protobuf --force`, or build the plugin from the `:protobuf` dep) and generate + **commit** the
message modules from the 8 contracts (`-I proto/`, the bundled well-known types); document the regen `Mix.Task`. Compile
`--warnings-as-errors` clean; confirm the umbrella discovers `:investex`.

**Step two — Config + Money + the pure Retry (network-free).** `Investex.Config` (struct + `new/1` defaults +
`resolve/1` env read); `Investex.Money` (`from_quotation/1`, `to_quotation/1`, `from_money_value/1` over `{units, nano}`,
the `Proto` alias); `Investex.Retry.decide/3` (the three branches; reads `x-ratelimit-reset`); `Investex.Error`. These
three are pure — property-test Money's round-trip (G2) and unit-test Retry's branches (G4) with no network.

**Step three — the supervised Client + UsersService + the sandbox bootstrap.** `Investex.Client` (TLS dial, the
channel + config, Bearer + `x-app-name` metadata, `start_link/1`/`channel/1`/`stop/1`); `Investex.Users` (4) and
`Investex.Sandbox` (3) as stateless functions over a client handle, each returning `{:ok, _} | {:error,
Investex.Error.t()}`. These dial the venue — exercised by Tier 2 only.

**Step four — the parity scaffold + the two-tier harness + the gate.** The scaffold (G1-scaffold: enumerate the proto,
assert the 7, carry the 65 pending); Tier 1 (pure: Config/Money/Retry/scaffold) and Tier 2 (`@tag :sandbox`, the live
round-trip, `setup` reads `INVEST_TOKEN` and skips on `nil`); the rung gate `echo/rungs/exchange/trd_9_1_check.exs`
(D-4: `mix run --no-start`, the Tier-1 gates, one printed line each, nonzero exit, committed `.out`).

## Mars implementation notes (binding)

- **Scaffold the new app from the `echo/apps/exchange` template.** Lib-only — `def application, do:
  [extra_applications: [:logger]]`, **no `mod:`** (INV-5). The shared `build_path`/`config_path`/`deps_path`/`lockfile`
  point at `../../` (the exchange `mix.exs` shape). The client is started by the consumer or a test, never by
  `:investex`.
- **`:grpc`/`:protobuf` are NEW top-level deps — declare them; they are NOT a free transitive edge (L-3).** The
  `mix.lock` probe confirmed `mint`/`castore`/`hpax`/`cowlib` present (the transport stack) but `:grpc`/`:protobuf`
  absent. Declare them in `echo/apps/investex/mix.exs`, **verify the exact current minors against hex at build** (do not
  guess), and let them land in `echo/mix.lock` (included in the Director's LAW-4 commit). Confirm no foreign lock churn
  is swept.
- **The generated proto modules are committed; protoc stays off the compile path.** Run protoc + protoc-gen-elixir once
  (`-I proto/`), commit the output, document the regen task. The namespace is `Tinkoff.Public.Invest.Api.Contract.V1.*`;
  `alias … as: Proto` inside investex modules (D-1). Do not hand-edit the generated files.
- **The token is env-only (INV-9, hard).** `Investex.Config.resolve/1` reads `INVEST_TOKEN` via `System.fetch_env!` /
  `System.get_env`; never a struct default, config file, log, fixture, or gate transcript. Do **not** read or copy
  `github.local/invest-api-go-sdk/.env.test` into the repo — at the live gate, source the token into the shell env only
  (never echoed, never written to a file). The token VALUE appears in nothing committed.
- **The retry decision is pure (INV-6).** `Investex.Retry.decide/3` takes `(status, attempt, headers)` and returns
  `{:retry, wait_ms} | :give_up` with no `Process.sleep`, no clock, no network — the interceptor that *applies* it is
  the impure shell (it may be thin this slice). Read `x-ratelimit-reset` from `headers` for the `ResourceExhausted`
  wait (L-2); a grep over the decision shows no `System.monotonic_time`/`System.os_time`/`Process.`/sleep.
- **No float, anywhere in Money (INV-3).** Arithmetic over `{units, nano}` is integer; do **not** port
  `FloatToQuotation`/`ToFloat`. A property asserts no float in any round-tripped value (G2).
- **One function per RPC, named exactly as the manifest.** `Investex.Users.{get_accounts/1, get_margin_attributes/2,
  get_user_tariff/1, get_info/1}` and `Investex.Sandbox.{open_account/1, get_accounts/1, close_account/2}` — the parity
  scaffold enumerates the proto and asserts each maps (G1-scaffold); a missing or misnamed function fails the gate.
- **Mirror the `gateway.ex` house style.** Moduledoc cites `docs/exchange/trd.9.1.specs.md`; a `@typedoc` per `@type`;
  INV/D/G citations inline at the rule they realize (e.g. `# D-2 / G2: integer {units,nano}, no float`). Do not print
  exclamation marks or forbidden-voice words in gate output lines a chapter may later quote.
- **Per-app discipline.** Run `cd echo/apps/investex && TMPDIR=/tmp mix test` (Tier 1) and `cd echo && TMPDIR=/tmp mix
  compile --warnings-as-errors`. The umbrella-wide `mix test` is BANNED (the umbrella convention). The live sandbox tier
  (`mix test --include sandbox`) is the Stage-4 hard gate, not Stage 2.

## Acceptance gates (scoped to 9.1 — Tier 1 one printed line each; G6 is the live hard gate)

- **G1-scaffold — parity is measured and growing.** The parity-check test enumerates the proto service definitions and
  asserts each of the **7 implemented** RPCs (UsersService 4 + the sandbox trio 3) maps to its named
  `Investex.<Service>.<fun>/n`, carrying the **65 unimplemented** as an explicit pending list; a later un-mapped (or a
  renamed 9.1) function fails it; exit zero. *(INV-1, R-3/D-3; the "count prints 72" full assertion is 9.5.)*
- **G2 — money round-trips as integers.** `from_quotation`/`to_quotation`/`from_money_value` round-trip `{units, nano}`
  integer pairs (plus the ISO currency for `MoneyValue`) with no float in any value; a property holds over generated
  money; exit zero. *(INV-3, R-2/D-2.)*
- **G4 — the retry decision is pure and correct.** `Investex.Retry.decide/3` returns `{:retry, 500}` on
  `Unavailable`/`Internal` under the cap, a longer wait honoring `x-ratelimit-reset` on `ResourceExhausted`, and
  `:give_up` past `max_retries` — unit-tested with no network; a grep shows no clock/sleep/`Process.*` in the decision;
  exit zero. *(INV-6.)*
- **G5 — the pure suite is network-free and the sandbox tier is excluded by default.** The default `mix test` (and the
  `--no-start` rung gate) touches no network and is deterministic; the `@tag :sandbox` suite is **excluded by default**
  (a bare `mix test` never dials, the keyless-CI case); exit zero. *(INV-8.)* **[RECONCILED — Apollo L-10: the keyless
  behavior moved from "skip" to default-exclude + a loud `flunk` under `--include sandbox` — see INV-8. A default
  `mix test` reaches the live tier not at all, so it cannot skip-or-no-op; once `--include sandbox` is given, a missing
  token is a FAILURE, not a skip.]**
- **G6 (9.1 scope) — the sandbox vertical works (key present).** With `INVEST_TOKEN` set, the sandbox suite opens a
  sandbox account, reads it via `get_accounts`, and closes the account against the real sandbox endpoint — a real round
  trip; exit zero. **This is the Operator's hard ship gate: it MUST PASS to ship 9.1.** *(INV-8, the sandbox tier.)*
  **NB: place/read order is NOT in 9.1's G6 — that is 9.3 (the chapter G6 full lifecycle).**
  **[RECONCILE — FALSE-GREEN, corrected by TRD.9.1.1 (`trd.9.1.1.specs.md`, D-8)]: the "STANDING result" below is
  NOT genuine — the as-built transport could not dial the live venue.** Two transport defects made a verifying
  round-trip structurally impossible: DEFECT A — `Investex.Config` hardcoded the stale sinkholed
  `sandbox-invest-public-api.tinkoff.ru:443` (`config.ex:20`) and `resolve/1` never read `INVEST_API_URL`/`INVEST_API_PORT`
  (`config.ex:89-91`), so the dial did not reach the venue (the live host is the T-Bank rebrand
  `sandbox-invest-public-api.tbank.ru:443`); DEFECT B — `tls_opts/0` verified against `:public_key.cacerts_get()`
  (0 Russian roots) while the venue chains leaf → Russian Trusted Sub CA → Russian Trusted Root CA (a self-signed root
  absent from that bundle, `client.ex:184-193`), so even reaching the venue the handshake was rejected. A real non-empty
  `account_id` from `open_account` could therefore never have returned, and the per-seed millisecond timings recorded
  below could not have measured a completed verifying round-trip. The earlier L-9/L-10 loop (its text kept verbatim
  below) fixed a DIFFERENT false-green — an `async` OS-env token clobber that no-op'd the gate — and correctly hardened
  the gate's own-liveness; but the gate's letter (assert a non-empty `account_id`) was being satisfied by a dial that
  could not have run as recorded, because the env masked the transport failure as a different shape. The LESSON
  (trd.9.1.1.specs.md): own-liveness on a live gate is necessary but not sufficient — the substrate the gate dials must
  be independently de-risked (TRD.9.1.1's `ssl_verify_result=0` proof against the venue's real IP 178.130.128.33). The
  GENUINE G6 is re-proven by TRD.9.1.1's 3-way live harness AFTER the A+B fix lands. The original L-9/L-10 entry, kept
  for the historical record:**

  **[RECONCILED — Apollo L-9/L-10, REMEDIATE loop 1]: G6 ACTUALLY DIALS under the canonical command `mix test
  --include sandbox` and is now a STANDING result.** The prior false-green (a default-excluded live tier reading
  `System.get_env("INVEST_TOKEN")` while `Investex.ConfigTest`'s `async: true` env mutation clobbered the token,
  no-op'ing both live tests to `:ok`/0.01ms) is fixed three ways and re-verified independently: (1) `Investex.ConfigTest`
  is `async: false` and its `resolve/1` `setup` SAVES the prior `INVEST_TOKEN` and RESTORES it on exit (config_test.exs)
  — a real token survives the full suite; (2) each live test asserts a positive dialed-proof (a non-empty `account_id` /
  a decoded accounts list), so a self-skip cannot pass; (3) a missing token under `--include sandbox` `flunk`s loudly
  (the `setup`), never a silent skip. Apollo re-verified: full `--include sandbox` WITH `config_test.exs` present dials
  on every seed (0: 1224ms/409ms; 1: 795ms/775ms; default: 825ms/446ms — 0 failures, exit 0), keyless `--include
  sandbox` fails loudly (exit 2, 2 flunks), the default `mix test` excludes `:sandbox` (0 failures, 2 excluded).
  General build law (now in the Mars brief): an `async: true` test must NEVER mutate process-global state a
  concurrent/later test reads — the OS env, the application env, a named ETS table, or a registered process name.**
- **G7 — no token value anywhere.** A grep of the app, tests, generated modules, the gate `.out`, and the ledger for a
  token-shaped string finds none; the token is read from the environment only. *(INV-9.)*

**Deferred (named — they need a later rung):** **G3 — the branded `ORD` id is validated at the edge** (INV-4) → 9.3;
**G1 complete — the count prints 72** → 9.5.

## Definition of done

`echo/apps/investex` exists, lib-only (no `mod:`), compiles `--warnings-as-errors` clean; the umbrella discovers it;
`:grpc`/`:protobuf` pinned in `echo/mix.lock` (the exact minors verified against hex). The generated message modules are
committed with a documented regen task; R-1 (the `Proto` alias) is realized. `Investex.Config` defaults match the spec;
`Investex.Client` dials TLS with `Bearer` + `x-app-name` and is consumer-supervised; `Investex.Retry.decide/3` is pure
(the forbidden-effect grep empty) and correct on the linear / `ResourceExhausted` / give-up branches (G4); `Investex.Money`
round-trips integer `{units, nano}` (G2). UsersService (4) + the sandbox bootstrap (3) exist and are named exactly per
the manifest; the parity scaffold asserts the 7 and carries the 65 pending (G1-scaffold). `cd echo/apps/investex &&
TMPDIR=/tmp mix test` (Tier 1) green and network-free; `echo/rungs/exchange/trd_9_1_check.{exs,out}` committed,
reproducible (run twice, identical), exit zero (G5). **The live sandbox round-trip PASSED** (open → get_accounts → close
against the real endpoint) — the Operator's hard gate (G6, 9.1 scope). **[RECONCILE — corrected by TRD.9.1.1, D-8: this
G6 PASS was a FALSE-GREEN — the as-built transport could not dial the venue (the stale `…tinkoff.ru` endpoint, DEFECT A;
the untrusted Russian root, DEFECT B). The genuine G6 is re-proven by TRD.9.1.1's 3-way live harness after the A+B fix;
see the §"Acceptance gates" G6 record above.]** No token-shaped string anywhere in the app,
tests, generated modules, gate `.out`, or ledger; the token is env-only (G7). The slice boundary held (no order method,
no `EchoData` ORD validation, no stream, no read-service function this rung). The deferred set is named (INV-4/G3 → 9.3;
full G1 → 9.5; the 9.2–9.5 surfaces).

## Map

Chapter: [`trd.9.1.md`](trd.9.1.md). The full rung: [`trd.9.specs.md`](trd.9.specs.md) ·
[`trd.9.stories.md`](trd.9.stories.md) · [`trd.9.llms.md`](trd.9.llms.md). The slice-form precedent (the prior
build-rung slice): [`trd.2.1.specs.md`](trd.2.1.specs.md). System: [`exchange.specs.md`](exchange.specs.md). The parity
+ codec source: the committed Tinkoff Invest contracts (`github.local/invest-api-go-sdk/proto/{common,users,sandbox}.proto`)
and the Go SDK (`investgo/{client,config,sandbox}.go`); transport (`github.local/investAPI/src/docs/grpc.md`). The canon
(the declared, unexercised dep): `echo/apps/echo_data/lib/echo_data/{snowflake,branded_id}.ex`.
