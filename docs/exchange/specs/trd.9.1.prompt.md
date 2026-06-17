# trd.9.1.prompt.md — the x-mode runbook for TRD.9.1 (investex, the transport spine)

> The orchestration runbook the Director executes to BUILD the first investex sub-rung. Authoritative scope for
> this run. The deliverable is **code** (the first real `echo/apps/investex` slice), not a spec. Authored by the
> Director in bootstrap from the committed TRD.9 chapter quad ([`trd.9.specs.md`](trd.9.specs.md) §Decomposition,
> §Surface, §Acceptance; [`trd.9.stories.md`](trd.9.stories.md) AS-1/AS-5/AS-6/AS-7; [`trd.9.llms.md`](trd.9.llms.md)).
> This is a **build-rung delta**: it carves only what 9.1 touches from the settled chapter spine — it does not
> re-decide F-1..F-11.

## The rung in one paragraph

TRD.9.1 founds `echo/apps/investex` and proves the whole venue-client vertical end to end on the smallest possible
surface: `Investex.Config` (auth + endpoint + retry knobs, defaults) → the protoc-gen-elixir codegen of the 8
committed contracts into committed generated message modules + a regen task → a supervised `Investex.Client` owning
the TLS `GRPC.Channel` and per-RPC `Bearer` + `x-app-name` metadata → the pure `Investex.Retry.decide/3` →
**UsersService end-to-end** (4 functions; `get_accounts/1` the canonical sandbox smoke) → the **minimal sandbox
bootstrap** (`Investex.Sandbox.{open_account/1, get_accounts/1, close_account/2}`) → the **two-tier test harness**.
The vertical is proven both ways: a pure default suite (the committed `--no-start` rung gate, network-free,
deterministic) AND a live sandbox round-trip (`open_account → get_accounts → close_account`) against the real
sandbox endpoint with `INVEST_TOKEN`. The read services (9.2), the trading + branded-`ORD` seam (9.3), the full
SandboxService (9.4), and the streams (9.5) are LATER rungs — 9.1 builds none of them.

## Mode

**Flat-L2, WITH a dedicated Apollo (HIGH risk).** Venus (slice the spec) → Mars-1 (build + Tier-1 tests) →
Director solo review → Mars-2 (harden + the rung gate + the live sandbox hard gate) → **Apollo (the §11.2 charter
— this rung carries real network I/O, a live secret, and auth)** → Director ship (one LAW-4 pathspec commit).

> **Why HIGH risk → Apollo is mandatory.** The build dials a real external endpoint over TLS, reads a live secret
> (the sandbox `INVEST_TOKEN`), opens and closes a real (sandbox, play-money) brokerage account, and authenticates
> with a bearer token. Apollo verifies the live round-trip actually happened (not stubbed-and-claimed), the secret
> leaked into nothing, and the harness is sound — then resolves any residual ambiguity with the Operator before the
> Director ships.

## The Operator decision (settled in bootstrap — the one venue-facing fork)

**Sandbox tier = RUN LIVE, HARD GATE.** The Operator ruled (bootstrap `AskUserQuestion`, 2026-06-13): the live
sandbox round-trip is RUN this build (Mars-2 sources `INVEST_TOKEN` into the shell env and runs
`mix test --include sandbox`), and it MUST PASS to ship 9.1. If the venue is unreachable or the token is rejected,
**9.1 BLOCKS** — it does not ship on the pure tier alone. The pure Tier 1 remains the committed, deterministic rung
gate `.out` in every case; the live Tier 2 is a hard ship precondition Apollo verifies. The token VALUE is written
into nothing — not a file, a log, a fixture, the gate `.out`, or the ledger (INV-9).

## Scope — what 9.1 builds, and what it explicitly defers

**In 9.1 (the transport spine):**

| # | Deliverable | Grounds in |
|---|---|---|
| 1 | `Investex.Config` — struct + `new/1`/`resolve/1` (reads `INVEST_TOKEN` from env); defaults: endpoint `sandbox-invest-public-api.tinkoff.ru:443`, `app_name` `jonnify.investex`, `max_retries` 3, both disable flags false, `account_id` nil | trd.9.specs.md §"Config & auth"; investgo/config.go, client.go:116-128 |
| 2 | Codegen of the 8 contracts → **committed** generated modules + a documented regen task | trd.9.specs.md §Decomposition (F-3); the proto `package tinkoff.public.invest.api.contract.v1` |
| 3 | `Investex.Client` — supervised, owns the TLS `GRPC.Channel` + resolved Config; `start_link/1`, `channel/1`, `stop/1`; per-RPC `Bearer` + `x-app-name` metadata; **lib-only (no `mod:`)** | trd.9.specs.md §Surface (INV-5); investgo/client.go:26-31,72-78,271-274 |
| 4 | `Investex.Retry.decide/3` — **pure** `(status, attempt, headers) -> {:retry, wait_ms} \| :give_up`; linear 500 ms on `Unavailable`/`Internal` under the cap; longer silent wait on `ResourceExhausted` honoring `x-ratelimit-reset`; `:give_up` past `max_retries` | trd.9.specs.md INV-6/G4; investgo/client.go:19-70 |
| 5 | UsersService (4): `Investex.Users.get_accounts/1`, `get_margin_attributes/2`, `get_user_tariff/1`, `get_info/1` | trd.9.specs.md §"UsersService — 4"; users.proto:19-28 |
| 6 | Sandbox bootstrap (3): `Investex.Sandbox.{open_account/1, get_accounts/1, close_account/2}` | trd.9.specs.md §"SandboxService" rows tagged 9.1; sandbox.proto |
| 7 | `Investex.Error` — the typed `{:error, reason}` value the per-service functions return | trd.9.specs.md §Surface ("`Investex.Error.t()`") |
| 8 | The parity-check test (G1) **scaffold** — enumerates the proto service defs; asserts the 9.1 subset (the 7 implemented RPCs) maps; designed to grow toward the full 72 as 9.2–9.5 land | trd.9.specs.md INV-1/G1; trd.9.stories.md AS-2 |
| 9 | The two-tier test harness: Tier 1 (pure, default, the rung gate) + Tier 2 (`@tag :sandbox`, excluded by default, skips keyless, runs live with the key) | trd.9.specs.md INV-8/G5/G6; trd.9.stories.md AS-6 |
| 10 | The rung gate `echo/rungs/exchange/trd_9_1_check.{exs,out}` — Tier-1 pure gates, one printed line each, nonzero exit on fail, committed `.out`, **network-free** | the `trd_2_1_check.exs` precedent |

**Deferred — do NOT build in 9.1:**

- **The branded `ORD` edge-validation seam (INV-4 / G3).** 9.1 places no order. `post_order`/`replace_order` and the
  `EchoData` ORD validation are **9.3**. (`{:echo_data, in_umbrella: true}` is still declared in `mix.exs` as the
  canon dep, but 9.1 does not exercise the branded seam.)
- **Full 72-RPC parity (G1 complete).** Accumulates across 9.2–9.5; 9.1 ships the harness + the 7-RPC subset.
- Instruments/MarketData/Operations (9.2); Orders/StopOrders + the sandbox order lifecycle (9.3); the rest of
  SandboxService (9.4); the 5 streams (9.5).

## Settled forks (the chapter spine, narrowed to 9.1 — Venus locks each touched one as a D-n, the alternative a V-n)

The chapter quad already fixed F-1..F-11. 9.1 inherits them; these are the ones 9.1 *exercises*, plus the two new
**realization** questions the chapter spec could not foresee. Venus may refine shape, not re-open the spine; a
genuine re-opening escalates to the Director.

| # | Decision for 9.1 | Locked | Grounding |
|---|---|---|---|
| F-1 (9.1) | lib-only `echo/apps/investex` (`:investex`, `Investex.*`), **no `mod:`**; deps `{:echo_data, in_umbrella: true}` + `{:grpc, "~> 0.9"}` + `{:protobuf, "~> 0.13"}` + `{:stream_data, "~> 1.0", only: :test}` — **verify the exact current minors against hex at build, pin them in `mix.exs`/`mix.lock`** | echo/apps/exchange/mix.exs (the lib-only precedent); echo/mix.exs `apps_path`; mix.lock (mint/castore/hpax present, grpc/protobuf absent) |
| F-2/F-7 (9.1) | `:grpc` over the Mint adapter; TLS dial; per-RPC `Bearer` + `x-app-name`; Config defaults as above | investgo/client.go:72-78,116-128; grpc.md |
| F-8 (9.1) | the pure `Investex.Retry.decide/3` — the whole retry decision lands in 9.1 (the interceptor shell that *applies* it may be thin here and harden in later rungs) | investgo/client.go:19-70 |
| **R-1 (new — codegen namespace)** | protoc-gen-elixir derives the module namespace from the proto `package` → it emits `Tinkoff.Public.Invest.Api.Contract.V1.*`, **not** the literal `Investex.Proto.*` the chapter spec names. **Recommended:** accept the generated names and alias them (`alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto` inside investex modules) — no fragile rename; record as a realization-over-literal (L-n). Alternative (record V-n): a `package_prefix` codegen opt. Venus settles in the slice; Mars realizes | proto `package tinkoff.public.invest.api.contract.v1` (common.proto:3); elixir-protobuf codegen |
| **R-2 (new — `Investex.Money` placement)** | the chapter §Surface lists `Investex.Money`, but the 9.1 decomposition bullet does not name it, and UsersService/sandbox-bootstrap responses carry no `Quotation`/`MoneyValue`. **Recommended:** land `Investex.Money` (+ its pure G2 property) in 9.1 as a foundational, network-free helper — it is cheap, the generated `Quotation`/`MoneyValue` structs exist after the 9.1 codegen, and it de-risks 9.2. Alternative (record V-n): defer to 9.2 where money is first exercised. Venus settles + records | trd.9.specs.md §"money vocabulary"; common.proto:28-48 |
| **R-3 (new — G1 at 9.1)** | the parity test is built in 9.1 but cannot assert all 72 (only 7 RPCs exist). **Locked:** the test enumerates the proto and asserts the *implemented* set maps, with the unimplemented RPCs carried as an explicit pending list (so a 9.2+ function that lands un-mapped fails the growing gate). The "count prints 72" full assertion completes at 9.5 | trd.9.specs.md INV-1/G1; the decomposition is a ladder |

## Grounding (real, cited — Venus + Mars read before building; quote nothing unopened)

- **The 8 committed contracts** — `github.local/invest-api-go-sdk/proto/{common,instruments,marketdata,operations,
  orders,sandbox,stoporders,users}.proto`. 9.1 needs `common.proto` (Quotation/MoneyValue/Ping), `users.proto`
  (UsersService), `sandbox.proto` (Open/Get/Close). Imports are bare (`import "common.proto"`,
  `import "google/protobuf/timestamp.proto"`) → codegen runs `-I proto/` and relies on protoc's bundled well-known
  types; elixir-protobuf ships `Google.Protobuf.*`.
- **The Go SDK wrap pattern** — `investgo/client.go` (the stateful `Client{conn, Config}` + the TLS/bearer dial +
  the retry interceptor + the sandbox auto-bootstrap at client.go:90-111), `investgo/config.go`,
  `investgo/sandbox.go` (Open/Get/Close lifecycle).
- **Transport** — `github.local/investAPI/src/docs/grpc.md` (endpoints, `Authorization: Bearer`, `x-app-name`,
  `x-tracking-id`, `x-ratelimit-*`); the per-service heads `head-{users,sandbox}.md`.
- **The canon (declared dep, not exercised in 9.1)** — `echo/apps/echo_data`: `EchoData.Snowflake.next_branded/1`
  (snowflake.ex:104), `EchoData.BrandedId.namespace/1` (branded_id.ex:97), `decode/1`/`decode!/1` (:55/:59). The
  branded-`ORD` seam they serve is **9.3**, not 9.1.
- **The umbrella shape** — `echo/apps/exchange/mix.exs` (lib-only: `def application, do: [extra_applications:
  [:logger]]`, no `mod:`; `{:echo_data, in_umbrella: true}`); `echo/mix.exs` `apps_path: "apps"` (auto-discovery).
- **The rung-gate precedent** — `echo/rungs/exchange/trd_2_1_check.exs`: a printed-line-per-gate runner, nonzero
  exit on fail, committed `.out`. (9.1's pure gate must stay network-free — a `mix run` runner that exercises
  Config/Retry/Money/the parity-scaffold over the compiled umbrella, with `:investex` never booting a connection
  because it is `mod:`-less.)
- **The slice form** — `trd.2.1.md` + `trd.2.1.specs.md` (the build-rung slice: `.md` narrative + `.specs.md`
  authoritative; the chapter `.stories.md`/`.llms.md` are not re-authored per sub-rung).
- **The secret** — `github.local/invest-api-go-sdk/.env.test` holds `INVEST_TOKEN=` (confirmed by key name only;
  value never read). `github.local` is git-ignored. Read the token from the env at test time; never copy `.env.test`
  into the repo.

## The deliverables (the team leaves all in the working tree for the Director)

**Venus (Stage 1):**
1. `docs/exchange/trd.9.1.md` — the build-rung narrative slice (what 9.1 builds, the vertical, what it defers,
   the seam to 9.2–9.5). PROPOSED.
2. `docs/exchange/trd.9.1.specs.md` — authoritative for 9.1: the 9.1 surface (Config, Client, Retry, Users(4),
   Sandbox bootstrap(3), Error, the harness, optionally Money), the in-scope invariants (INV-5/6/8/9 fully; INV-1
   as the growing scaffold; INV-3 if Money lands in 9.1), the deferred set (INV-4/G3 → 9.3; full G1 → 9.5), the
   acceptance gates scoped to 9.1 (G1-scaffold, G2 if Money, G4, G5, G6-open/get/close, G7), and the two
   realization decisions R-1/R-2/R-3 settled with reasoning. Mirrors the `trd.2.1.specs.md` shape.

**Mars (Stages 2 + 4):** `echo/apps/investex/**` (`mix.exs`, `lib/investex/*.ex`, the committed generated modules,
the regen task, `test/**`, `test/test_helper.exs`), and `echo/rungs/exchange/trd_9_1_check.{exs,out}`.

**Director (Stage 5):** the ledger `docs/exchange/trd-9-1.progress.md` + `trd-9-1.registry.json`, the
`trd.progress.md` 9.1 status line, and this `trd.9.1.prompt.md`; the single LAW-4 commit.

## Stage prompts

**Stage 1 · Venus (architect — slice the spec).** Adopt `.claude/agents/venus.md`. Read the chapter quad
(`trd.9.specs.md` §Decomposition/§Surface/§Acceptance, `trd.9.stories.md` AS-1/AS-2/AS-5/AS-6/AS-7, `trd.9.llms.md`)
and the grounding above (open every file before quoting it). Author `trd.9.1.md` + `trd.9.1.specs.md` as the 9.1
slice: pin the exact 9.1 surface, scope the invariants/gates to 9.1, name the deferred set, and **settle R-1
(codegen namespace), R-2 (Money placement), R-3 (G1-at-9.1) with reasoning** — lock each as a D-n, record the
alternative as a V-n, surprises as L-n. Reconcile the slice against the real tree: confirm `echo/apps/exchange`'s
lib-only shape is the template, the umbrella auto-discovers a new app, `:grpc`/`:protobuf` are absent from the lock
(the new deps), and the proto package is `tinkoff.public.invest.api.contract.v1`. **Invent no method name, endpoint,
or message field** — quote from the proto. Honor F-11/INV-9: the token value appears nowhere. **Do not write code;
do not run git.** Report via `SendMessage(to: "director", …)` with the settled R-1/R-2/R-3 and any open question.

**Stage 2 · Mars-1 (implementor — build + Tier-1 tests).** Adopt `.claude/agents/mars.md`. Build the 9.1 slice to
`trd.9.1.specs.md`, citing the spec line for every public call: scaffold `echo/apps/investex` (lib-only, the
exchange precedent); install `protoc-gen-elixir` (`mix escript.install hex protobuf --force` or build the plugin
from the `:protobuf` dep) and generate + **commit** the message modules from the 8 contracts with a documented
regen task; build `Investex.Config`, `Investex.Client` (TLS channel, Bearer + `x-app-name`), the pure
`Investex.Retry.decide/3`, `Investex.Error`, UsersService (4), the sandbox bootstrap (3), and (per R-2) optionally
`Investex.Money`; write the parity-check scaffold (R-3) and the two-tier harness — Tier 1 pure + Tier 2
`@tag :sandbox` that reads `INVEST_TOKEN` in `setup` and `ExUnit`-skips on `nil`. Compile clean
(`cd echo && TMPDIR=/tmp mix compile --warnings-as-errors`); run Tier 1 (`cd echo/apps/investex && TMPDIR=/tmp mix
test`) green; keep the diff inside `echo/apps/investex/**`. Do **not** run the live sandbox tier yet (that is the
Stage-4 hard gate). Cite the real `echo_data`/proto arities; invent nothing. Report realization-over-literal
(especially R-1's generated namespace). Audit: T/D/V/L/Y. Do not run git. Report to the Director.

**Stage 3 · Director (solo review).** A real pass, not a glance: (a) fresh-gate reconcile of the as-built slice vs
`trd.9.1.specs.md`; (b) independent re-run — `mix compile --warnings-as-errors`, `mix test` (Tier 1), the parity
scaffold; (c) ≥1 adversarial probe (e.g. `Retry.decide/3` at the cap boundary and on `ResourceExhausted` with an
`x-ratelimit-reset` header → exact `{:retry, wait_ms}`/`:give_up`; a Config with no `INVEST_TOKEN` in env → the
documented behavior, not a crash with the token in the message); (d) a mutation spot-check (Edit-in a wrong retry
constant, confirm a Tier-1 test kills it, **revert net-zero**); (e) the secret scan — grep the whole new app + tests
+ any generated file for a token-shaped string (must be empty), and confirm the codegen committed no embedded
secret. Findings → `tool_x_report` + a REMEDIATE list to Mars. The Director writes **no** production code (LAW-1a).

**Stage 4 · Mars-2 (implementor — harden + the rung gate + the LIVE sandbox hard gate).** Resume the Stage-2 Mars
(`SendMessage`, preserving context). Close the REMEDIATE list. Write `echo/rungs/exchange/trd_9_1_check.exs` (the
Tier-1 pure gates, one printed line each, nonzero exit on fail) + commit its `.out` (network-free, reproducible —
run it twice, identical). Then the **live sandbox hard gate**: source the token from the env only —
`set -a; . github.local/invest-api-go-sdk/.env.test; set +a` (or `INVEST_TOKEN=$(grep '^INVEST_TOKEN=' … | cut -d= -f2-)`
into the shell, **never** echoed, **never** written to a file) — and run `cd echo/apps/investex && TMPDIR=/tmp mix
test --include sandbox`. The sandbox suite MUST open a sandbox account, call `get_accounts`, and close the account
against the real endpoint, and it MUST PASS (the Operator's hard gate). Report the sandbox result as a PASS/SKIP/FAIL
line in the ledger — **no raw dump** (it may carry sandbox account ids), and **no token value**. Determinism loop on
Tier 1 only. Boundary grep empty. Audit T/D/V/L/Y. Do not run git. Report to the Director.

**◇ Apollo (evaluator — HIGH risk, the §11.2 charter; between Stage 4 and Stage 5).** Adopt
`.claude/agents/apollo.md`. Run the prompted-checks table against `trd.9.1.specs.md` G1-scaffold/G2/G4/G5/G6/G7 +
INV-5/6/8/9; produce ≥1 un-prompted finding, ≥1 attack-that-held, and a mutation kill-rate. **Verify the live
round-trip is real** — that Tier 2 actually dialed the sandbox and opened/closed an account (not stubbed and
claimed): re-run `mix test --include sandbox` with the env token if reachable, or inspect the evidence Mars
recorded. **Verify the secret leaked into nothing** — grep the app, tests, generated modules, the gate `.out`, and
the ledger for a token-shaped string; confirm `.env.test` was not copied into the repo. Use `AskUserQuestion` to
resolve any residual ambiguity with the Operator (e.g. a survivor, a retry-posture edge) and keep the product
shippable. Verdict: **BUILD-GRADE / BLOCKED** + mentor diffs. Report to the Director.

**Stage 5 · Director (ship).** Gate green AND Apollo BUILD-GRADE AND the live sandbox round-trip PASSED → lock the
ratifying `tool_x_decision` + write `tool_x_complete` (Z-n) → **one LAW-4 pathspec commit** (below) → Stage-6 fold
(the exchange-platform memory + the roadmap/progress reconcile + the next frontier = TRD.9.2 the read services).

## Acceptance (9.1 is build-grade when)

- `echo/apps/investex` exists, lib-only (no `mod:`), compiles `--warnings-as-errors` clean; the umbrella discovers
  it; `:grpc`/`:protobuf` pinned in `mix.lock`.
- The generated message modules are committed with a documented regen task; R-1 (the namespace) is settled +
  recorded.
- `Investex.Config` defaults match the spec; `Investex.Client` dials TLS with `Bearer` + `x-app-name` and is
  consumer-supervised (lib-only); `Investex.Retry.decide/3` is pure (grep: no clock/sleep/`Process.*` in the
  decision) and correct on the linear / `ResourceExhausted` / give-up branches (G4).
- UsersService (4) + the sandbox bootstrap (3) exist and are named exactly per the manifest; the parity scaffold
  (G1) asserts the 7 implemented RPCs map and grows toward 72; (G2) money round-trips integer `{units, nano}` if
  Money landed in 9.1.
- Tier 1 is network-free and green; `trd_9_1_check.{exs,out}` committed, reproducible, exit zero (G5).
- **The live sandbox round-trip PASSED** (open → get_accounts → close against the real endpoint) — the Operator's
  hard gate (G6, 9.1 scope).
- (G7) no token-shaped string anywhere in the app, tests, generated modules, gate `.out`, or ledger; the token is
  read from the env only.
- Apollo's verdict is BUILD-GRADE; every `AskUserQuestion` resolved.
- The deferred set is named in the slice (INV-4/G3 → 9.3; full G1 → 9.5; 9.2–9.5 surfaces).

## LAW-4 — the single ratifying commit (Director only, at Z-n)

Pathspec (exactly these; **never `git add -A`, never a bare commit** — the working tree carries much foreign
in-flight work). Review `git status --short` + `git diff --cached --name-only` first; check `.git/rebase-merge`/
`rebase-apply`; exclude every path not listed:

```
git commit -F <msg> -- \
  echo/apps/investex \
  echo/rungs/exchange/trd_9_1_check.exs \
  echo/rungs/exchange/trd_9_1_check.out \
  echo/mix.lock \
  docs/exchange/trd.9.1.md \
  docs/exchange/trd.9.1.specs.md \
  docs/exchange/trd.9.1.prompt.md \
  docs/exchange/trd.progress.md \
  docs/exchange/trd-9-1.progress.md \
  docs/exchange/trd-9-1.registry.json
```

(`echo/mix.lock` is included because the new `:grpc`/`:protobuf` deps land there. Confirm no foreign lock churn is
swept — diff it before staging.) The message cites the slug `trd-9-1`, the Z-n, the D-n decisions, the Y-n reports,
and that the live sandbox round-trip passed (without any token value).

## Definition of done

`echo/apps/investex` ships its transport spine: Config + committed codegen + Client + the pure Retry + UsersService
+ the sandbox bootstrap + the two-tier harness, pure-gated (`trd_9_1_check`) AND live-sandbox-verified (the hard
gate). The slice spec `trd.9.1.{md,specs.md}` is on disk, PROPOSED, with R-1/R-2/R-3 settled. Apollo is BUILD-GRADE.
The ledger carries T/D/V/L/Y/Z; one Director pathspec commit ratifies it; the next frontier (TRD.9.2, the read
services) is recorded. No token value appears anywhere.
