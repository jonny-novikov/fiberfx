# trd.9.2.prompt.md — the x-mode runbook for TRD.9.2 (investex, the read services)

> The orchestration runbook the Director executes to BUILD the second investex sub-rung. Authoritative scope for
> this run. The deliverable is **code** (the read-service layer over the as-built 9.1 transport), not a spec.
> Authored by the Director in bootstrap from the committed TRD.9 chapter quad ([`trd.9.specs.md`](trd.9.specs.md)
> §"the parity manifest", §Decomposition, §Acceptance) and the as-built 9.1 surface
> ([`trd.9.1.specs.md`](trd.9.1.specs.md)). This is a **build-rung delta**: it carves only what 9.2 touches from the
> settled chapter spine — it does not re-decide F-1..F-11, and it re-opens **no** transport decision the shipped 9.1
> already fixed.

## The rung in one paragraph

TRD.9.2 builds the **read services** as a thin parity layer over the 9.1 transport, reused unchanged: three new
stateless modules — `Investex.Instruments` (27 RPCs) · `Investex.MarketData` (7) · `Investex.Operations` (7) = **41
read-only unary functions** — each a 1:1 pass-through that mirrors the as-built `Investex.Users`: it takes a typed
`%Proto.<Request>{}` and delegates to `Investex.Caller.unary(client, &…Service.Stub.<fun>/3, request)`, returning
`{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`. No transport module changes (`Client`, `Caller`,
`Retry`, `Config`, `Error`, `Money` are fixed); no order is placed (the branded-`ORD` seam stays 9.3); no stream
is built (9.5). The parity scaffold's `@implemented` map grows **7 → 48** (pending **65 → 24**), and
`Investex.Money` is finally **exercised against real venue data** — decoding the `Quotation`/`MoneyValue` fields a
live read returns. The rung is pure-gated (the grown parity scaffold + the Money property + a pass-through-fidelity
structural check + the committed `--no-start` rung gate, all network-free) AND live-verified on a representative
subset against the real sandbox endpoint. The trading services (9.3), the rest of SandboxService (9.4), and the
streams (9.5) are LATER rungs — 9.2 builds none of them.

## Mode

**Flat-L2, WITH a dedicated Apollo (HIGH risk — inherited from the chapter spec, not re-opened).** Venus (slice the
spec) → Mars-1 (build the 3 read modules + grow the parity scaffold + the Money exercise, Tier-1) → Director solo
review → Mars-2 (harden + the rung gate + the live representative-subset hard gate) → **Apollo (the §11.2 charter)**
→ Director ship (one LAW-4 pathspec commit).

> **Why HIGH risk → Apollo is mandatory.** [`trd.9.specs.md`](trd.9.specs.md) (lines 25, 301) pre-declares **every**
> sub-rung TRD.9.1–9.5 HIGH risk (real network I/O, a live secret, auth) and warrants a dedicated Apollo + the
> secret-hygiene gate (INV-9) at build time. 9.2 reuses the 9.1 transport unchanged, but its live read tier still
> sources `INVEST_TOKEN` and dials the venue, so the secret-hygiene gate is live and the live round-trip must be
> verified real (not stubbed-and-claimed). The Director does not unilaterally downgrade a settled chapter decision.

## The Operator decision (settled in bootstrap — the one open fork)

**Live read tier = RUN LIVE, HARD GATE (representative subset).** The Operator ruled (bootstrap `AskUserQuestion`,
2026-06-14): the live read tier is RUN this build, and a **documented representative subset** MUST dial the sandbox
and pass to ship. The subset is a real chain that also exercises `Investex.Money` twice on real venue data:

1. open a sandbox account (the 9.1 bootstrap, reused) →
2. **Instruments**: one read that returns data (recommended `Investex.Instruments.shares/2` with an
   `InstrumentsRequest` for the base list, or `find_instrument/2`) — proves an InstrumentsService read dials →
3. **MarketData**: `Investex.MarketData.get_last_prices/2` for one instrument id from step 2 → decode the
   `LastPrice.price` `Quotation` through `Investex.Money.from_quotation/1` to an integer `{units, nano}` →
4. **Operations**: `Investex.Operations.get_portfolio/2` for the sandbox account → decode a `MoneyValue` total
   through `Investex.Money.from_money_value/1` →
5. close the sandbox account.

**The hard floor:** the subset MUST prove (a) at least one InstrumentsService read dialed and returned data, AND
(b) at least one **Money decode from a real money-dense response** succeeded (the `get_last_prices` Quotation OR the
`get_portfolio` MoneyValue — whichever the sandbox serves). A read the sandbox genuinely does not serve is a **named,
loud SKIP** (INV-8 liveness — never a silent pass). If the venue is unreachable, or **neither** money-dense read is
served by the sandbox (so Money is never exercised live), **9.2 BLOCKS** — Apollo escalates to the Operator via
`AskUserQuestion` rather than shipping a hollow live gate. The pure Tier-1 remains the committed deterministic rung
gate `.out` in every case. The token VALUE is written into nothing — not a file, a log, a fixture, the gate `.out`,
or the ledger (INV-9); sandbox account ids and instrument ids are not dumped raw into the ledger.

## Scope — what 9.2 builds, and what it explicitly defers

**In 9.2 (the read services — 41 unary functions over the fixed transport):**

| # | Deliverable | Grounds in |
|---|---|---|
| 1 | `Investex.Instruments` — **27** functions, each `(client, %Proto.<Request>{}) -> {:ok, %Proto.<Response>{}} \| {:error, Investex.Error.t()}` via `Caller.unary(client, &InstrumentsService.Stub.<fun>/3, request)` | trd.9.specs.md §"InstrumentsService — 27" (instruments.proto:21-101); instruments.pb.ex:1870-1981 (Service, 27 rpc) + :1986 (Stub) |
| 2 | `Investex.MarketData` — **7** functions (the 7 unary `MarketDataService` RPCs; the 2 `MarketDataStreamService` RPCs are 9.5) | trd.9.specs.md §"MarketDataService — 7" (marketdata.proto:18-36); marketdata.pb.ex:901 (Service) + :937 (Stub) |
| 3 | `Investex.Operations` — **7** functions (the 7 unary `OperationsService` RPCs; the 2 `OperationsStreamService` RPCs are 9.5) | trd.9.specs.md §"OperationsService — 7" (operations.proto:20-39); operations.pb.ex:1040 (Service) + :1076 (Stub) |
| 4 | The parity scaffold grows: `@implemented` **7 → 48**; the count assertions update (pending **65 → 24**; the "touched services" assertion → exactly `{Users, Sandbox, Instruments, MarketData, Operations}`) | trd.9.1.specs.md G1-scaffold/D-3; test/parity_test.exs (the as-built scaffold) |
| 5 | The **Money exercise** — `Investex.Money` decodes real money-dense response fields: a pure test over constructed `Quotation`/`MoneyValue` field shapes the read responses carry, AND the live subset decodes real data (step 3/4 above) | trd.9.specs.md INV-3/G2; marketdata.pb.ex (GetLastPricesResponse/LastPrice/Order — Quotation), operations.pb.ex (PortfolioResponse/PortfolioPosition — MoneyValue) |
| 6 | The **pass-through-fidelity** check (NEW, 9.2) — a network-free structural assertion that each read function delegates to its **identically-named** `Stub` function (snake(RPC) == fun name == stub fun name), killing copy-paste wrong-stub errors across all 41 | the house pass-through shape (users.ex:27-54 — `def get_accounts` → `&Stub.get_accounts/3`) |
| 7 | The rung gate `echo/rungs/exchange/trd_9_2_check.{exs,out}` — the Tier-1 gates (the grown scaffold, the Money property, the fidelity check), one printed line each, nonzero exit on fail, committed `.out`, **network-free**, reproducible | the as-built `echo/rungs/exchange/trd_9_1_check.exs` (D-4: compiled-umbrella `mix run --no-start`) |
| 8 | The two-tier harness extended: the live read tier (the representative subset above), `@tag :sandbox`, excluded by default, flunks loud keyless under `--include sandbox` | trd.9.1.specs.md INV-8 (the as-built sandbox_live_test.exs liveness contract) |

**Deferred — do NOT build in 9.2:**

- **The branded `ORD` edge-validation seam (INV-4 / G3).** 9.2 places no order — every read is read-only. `post_order` /
  `replace_order` / `Sandbox.post_order` and the `EchoData` ORD validation are **9.3**. (`{:echo_data, in_umbrella:
  true}` stays declared but unexercised, exactly as in 9.1.)
- **OrdersService (5) / StopOrdersService (3) / the 5 sandbox order methods** → 9.3.
- **The rest of SandboxService (6 methods: pay_in + positions/operations/operations-by-cursor/portfolio/withdraw-limits
  mirror)** → 9.4. *(9.2 builds the non-sandbox `Operations.get_portfolio/2` etc.; the `Sandbox.*` mirrors of those are
  9.4.)*
- **The 5 streams (MarketDataStream, MarketDataServerSideStream, TradesStream, PortfolioStream, PositionsStream; INV-7)** → 9.5.
- **Full 72-RPC parity (G1 complete, the "count prints 72 implemented" assertion)** → 9.5. 9.2 grows the scaffold to 48
  implemented / 24 pending.
- **No transport change.** `Client`, `Caller`, `Retry`, `Config`, `Error`, `Money` (the public surfaces) are reused
  unchanged; `Money` gains tests, not new functions. `echo/mix.lock` is **not** touched — no new dep (grpc/protobuf/
  stream_data/echo_data all already locked).

The boundary is the Director's Stage-3 reconcile target: no order method, no `EchoData` ORD validation call, no stream
GenServer, no edit to a transport module's public surface in this slice's diff.

## Settled forks (the chapter spine, narrowed to 9.2 — Venus locks each as a D-n, the alternative a V-n)

The chapter quad fixed F-1..F-11; 9.1 fixed the transport realizations R-1/R-2/R-3 (the `Proto` alias, Money-at-9.1,
the growing scaffold). 9.2 inherits all of them and re-opens none. These are the 9.2-specific realization questions:

| # | Decision for 9.2 | Locked | Grounding |
|---|---|---|---|
| **RQ-1 (the pass-through pattern)** | each read function takes a **pre-built typed `%Proto.<Request>{}`** as its single argument and forwards it — NO request-builder/constructor layer this rung (the proto struct IS the typed request). Exactly mirrors `Investex.Users`. **Locked: pass-through.** Alternative (V-n): typed request builders — rejected as scope-widening gold-plating; defer any ergonomics to a consumer rung. Arity is uniform `/2` (client + request) for all 41 | users.ex:27-54 (the as-built pass-through); trd.9.specs.md §"the per-argument shape is the build rung's to realize" |
| **RQ-2 (the scaffold transition)** | grow `@implemented` by the 41 read RPCs (each `{Proto.<Service>.Service, :<RPC>} => {Investex.<Mod>, :<fun>, 2}`), update the pending assertion `65 → 24`, the implemented count `7 → 48`, and generalize the "touched services" test to assert exactly `{Users, Sandbox, Instruments, MarketData, Operations}`. **Locked.** The "count prints 72 implemented" full assertion stays 9.5 (24 pending: Orders 5 + OrdersStream 1 + StopOrders 3 + MarketDataStream 2 + OperationsStream 2 + the 11 remaining Sandbox = 24) | test/parity_test.exs (the as-built `@implemented`/`all_rpcs`/pending tests); trd.9.specs.md the manifest |
| **RQ-3 (the live gate posture)** | **Live, HARD, representative subset** (the Operator decision above) — the chain open→Instruments read→Money-decode(last-prices)→Money-decode(portfolio)→close; the hard floor = ≥1 Instruments read dialed AND ≥1 Money decode from a real money-dense response; sandbox-unserved reads are named loud SKIPs; venue-unreachable or no live Money exercise → BLOCK | the Operator ruling; trd.9.1.specs.md INV-8 (the liveness contract) |
| **RQ-4 (the Money exercise shape)** | `Investex.Money` is **exercised, not extended** — no new public function. The pure G2 property is extended to cover the field shapes the read responses carry (a `Quotation` with negative `nano`, zero, large `units`; a `MoneyValue` with its currency), and the live subset decodes real `LastPrice.price` / a `MoneyValue` total. **Locked.** Alternative (V-n): a money-mapping helper over a whole response — rejected (the caller decodes the fields it needs; investex returns raw `%Proto.<Response>{}`, the established 9.1 contract) | money.ex (the as-built codec); trd.9.specs.md INV-3 |

Venus may refine shape, not re-open the spine; a genuine re-opening escalates to the Director.

## Grounding (real, cited — Venus + Mars read before building; quote nothing unopened)

- **The 3 read contracts** — `github.local/invest-api-go-sdk/proto/{instruments,marketdata,operations}.proto`. The RPC
  names + request/response message names are quoted in [`trd.9.specs.md`](trd.9.specs.md) §"the parity manifest" with
  per-service line cites; **confirm each against the committed generated module before mapping it** (do not invent a
  field).
- **The committed generated modules (the contract of names — already on disk, confirmed this bootstrap):**
  `echo/apps/investex/lib/investex/proto/tinkoff/public/invest/api/contract/v1/{instruments,marketdata,operations}.pb.ex`
  — `InstrumentsService.Service` declares 27 `rpc` (instruments.pb.ex:1870-1981) + `.Stub` (:1986);
  `MarketDataService.Service` (marketdata.pb.ex:901) + `.Stub` (:937); `OperationsService.Service` (operations.pb.ex:1040)
  + `.Stub` (:1076). The money-dense responses exist: `GetLastPricesResponse`/`LastPrice` (Quotation),
  `PortfolioResponse`/`PortfolioPosition` (MoneyValue), `GetOrderBookResponse`/`Order` (Quotation).
- **The as-built pass-through house style** — `echo/apps/investex/lib/investex/users.ex` (the exact shape to mirror:
  moduledoc cites the spec + the proto, `alias …V1, as: Proto`, `alias ….<Service>.Stub`, one `@doc` + `@spec` + `def`
  per RPC, `Caller.unary(client, &Stub.<fun>/3, %Proto.<Request>{…})`); `echo/apps/investex/lib/investex/caller.ex`
  (the seam — unchanged); `echo/apps/investex/lib/investex/money.ex` (the codec — unchanged, exercised).
- **The as-built parity scaffold** — `echo/apps/investex/test/parity_test.exs` (`@services`, `@implemented`, `all_rpcs/0`
  via `__rpc_calls__/0`, the count + touched-services tests — the file 9.2 grows).
- **The as-built live tier** — `echo/apps/investex/test/sandbox_live_test.exs` (the `@moduletag :sandbox`, `async: false`,
  the loud-keyless `setup` `flunk`, the dialed-proof assertions — the liveness contract the read subset extends);
  `echo/apps/investex/test/test_helper.exs` (`ExUnit.start(exclude: [:sandbox])`, the `GRPC.Client.Supervisor` start, L-6).
- **The Go SDK read references (read, not run)** — `github.local/invest-api-go-sdk/investgo/{instruments,marketdata,
  operations}.go` (the per-service wrap pattern); `github.local/investAPI/src/docs/grpc.md` + the per-service heads.
- **The rung-gate precedent** — `echo/rungs/exchange/trd_9_1_check.exs` (compiled-umbrella `mix run --no-start`, one
  printed line per gate, nonzero exit, committed `.out`, network-free — the runner 9.2's gate copies and re-points).
- **The secret** — `github.local/invest-api-go-sdk/.env.test` holds `INVEST_TOKEN=` (key name only; value never read).
  `github.local` is git-ignored. Read the token from the env at test time; never copy `.env.test` into the repo.

## The deliverables (the team leaves all in the working tree for the Director)

**Venus (Stage 1):**
1. `docs/exchange/trd.9.2.md` — the build-rung narrative slice (what 9.2 builds: the read layer over the fixed
   transport, the parity growth, the Money exercise; the deferred set; the seam to 9.3–9.5). PROPOSED.
2. `docs/exchange/trd.9.2.specs.md` — authoritative for 9.2: the 41-function surface (the 3 modules, each function's
   `(client, %Proto.<Request>{}) -> {:ok, %Proto.<Response>{}} | {:error, …}` shape, named exactly per the manifest),
   the in-scope invariants (INV-1 the grown scaffold; INV-2 one-function-per-RPC; INV-3/G2 the Money exercise; INV-5/6
   reaffirmed-unchanged; INV-8/9 the live tier + secret hygiene), the deferred set (INV-4/G3 → 9.3; INV-7 → 9.5; the
   9.3/9.4/9.5 surfaces), the acceptance gates scoped to 9.2 (G1-scaffold@48, G2, the pass-through-fidelity check, G5,
   G6-subset, G7), and RQ-1/RQ-2/RQ-3/RQ-4 settled with reasoning. Mirrors the `trd.9.1.specs.md` shape.

**Mars (Stages 2 + 4):** `echo/apps/investex/lib/investex/{instruments,market_data,operations}.ex`, the grown
`echo/apps/investex/test/parity_test.exs`, the Money exercise test, the live read tier (extending or beside
`sandbox_live_test.exs`), any new pure test, and `echo/rungs/exchange/trd_9_2_check.{exs,out}`.

**Director (Stage 5):** the ledger `docs/exchange/trd-9-2.progress.md` + `trd-9-2.registry.json`, the
`trd.progress.md` 9.2 status line, and this `trd.9.2.prompt.md`; the single LAW-4 commit.

## Stage prompts

**Stage 1 · Venus (architect — slice the spec).** Adopt `.claude/agents/venus.md`. Read the chapter manifest
(`trd.9.specs.md` §"the parity manifest" — the 41 read RPCs with their request/response names + line cites; §Decomposition
TRD.9.2; §Acceptance) and the as-built 9.1 surface (`trd.9.1.specs.md`) and the grounding above (open every file before
quoting it — especially the 3 `*.pb.ex` Service/Stub modules and `users.ex`/`parity_test.exs`/`money.ex`). Author
`trd.9.2.md` + `trd.9.2.specs.md` as the 9.2 slice: pin the exact 41-function surface (cite the proto RPC + the generated
`Stub.<fun>` for every one — invent no field, no RPC, no response name), scope the invariants/gates to 9.2, name the
deferred set, and **settle RQ-1 (pass-through), RQ-2 (the scaffold transition 7→48 / 65→24), RQ-3 (the live subset hard
gate), RQ-4 (the Money exercise)** with reasoning — lock each as a D-n, the alternative a V-n, surprises L-n. **Reconcile
the slice against the real tree:** confirm the 3 Service modules declare 27/7/7 unary RPCs (the stream RPCs live in the
separate `*StreamService` modules → 9.5), the `Stub` modules exist, `Investex.Users`/`Caller` are the pass-through
template, `parity_test.exs`'s `@implemented` is the file to grow, and `Money` needs no new function. Honor F-11/INV-9: the
token value appears nowhere. **Do not write code; do not run git.** Report via `SendMessage(to: "director", …)` with the
settled RQ-1..RQ-4 and any open question.

**Stage 2 · Mars-1 (implementor — build the read layer + grow the scaffold, Tier-1).** Adopt `.claude/agents/mars.md`.
Build the 9.2 slice to `trd.9.2.specs.md`, citing the spec line + the proto RPC + the generated `Stub.<fun>` for every
public function: author `Investex.Instruments` (27), `Investex.MarketData` (7), `Investex.Operations` (7) — each function a
1:1 pass-through mirroring `users.ex` (`alias …V1, as: Proto`; `alias ….<Service>.Stub`; `@doc` citing the proto line +
`@spec`; `Caller.unary(client, &Stub.<fun>/3, request)`), arity uniform `/2`. Grow `parity_test.exs`: add the 41
`@implemented` rows, update the count assertions (65→24, 7→48), generalize the touched-services test to the 5 services.
Add the Money exercise (pure — extend the codec property to the read responses' `Quotation`/`MoneyValue` field shapes).
Compile clean (`cd echo && TMPDIR=/tmp mix compile --warnings-as-errors`); run Tier 1 (`cd echo/apps/investex &&
TMPDIR=/tmp mix test`) green; keep the diff inside `echo/apps/investex/**` and touch NO transport module's public surface.
Do **not** run the live sandbox tier yet (that is the Stage-4 hard gate). Invent nothing — every Stub function name and
message field is read from the generated `*.pb.ex`. Report realization-over-literal. Audit T/D/V/L/Y. Do not run git.
Report to the Director.

**Stage 3 · Director (solo review).** A real pass, not a glance: (a) fresh-gate reconcile of the as-built 3 modules vs
`trd.9.2.specs.md` and the manifest — every function name, RPC mapping, and arity matches; (b) independent re-run —
`mix compile --warnings-as-errors`, `mix test` (Tier 1), the grown parity scaffold (assert 48/24/72); (c) **the
pass-through-fidelity probe** — for each read module, confirm every `def <name>(` is paired with `&Stub.<name>/3` (the
copy-paste-wrong-stub killer): grep each module and diff the def-name set against the stub-fun-name set, both = snake(RPC);
(d) an adversarial probe (e.g. pick 3 functions across the 3 modules, confirm the cited proto RPC exists in the Service
module and the response struct exists); (e) a mutation spot-check (Edit-in a wrong stub fun — `shares` → `&Stub.bonds/3` —
confirm the fidelity check / parity scaffold kills it, **revert net-zero**); (f) the secret scan — grep the 3 new modules +
the new tests for a token-shaped string (empty). Findings → `tool_x_report` + a REMEDIATE list to Mars. The Director writes
**no** production code (LAW-1a).

**Stage 4 · Mars-2 (implementor — harden + the rung gate + the LIVE representative-subset hard gate).** Resume the Stage-2
Mars (`SendMessage`, preserving context). Close the REMEDIATE list. Write `echo/rungs/exchange/trd_9_2_check.exs` (copy
`trd_9_1_check.exs`'s compiled-umbrella `mix run --no-start` runner; the Tier-1 gates: the grown parity scaffold prints
48 implemented / 24 pending / 72 enumerated; the Money round-trip property; the pass-through-fidelity structural check
across all 41; one printed line each, nonzero exit on fail) + commit its `.out` (network-free, reproducible — run it twice,
identical). Then the **live representative-subset hard gate**: source the token from the env only —
`set -a; . github.local/invest-api-go-sdk/.env.test; set +a` (or read `INVEST_TOKEN` into a shell var; **never** echoed,
**never** written to a file) — and run `cd echo/apps/investex && TMPDIR=/tmp mix test --include sandbox`. The live read
subset MUST: open a sandbox account; call one `Investex.Instruments` read that returns data (assert non-empty);
`Investex.MarketData.get_last_prices/2` for an instrument id from that read and decode `LastPrice.price` through
`Investex.Money.from_quotation/1` to an integer `{units, nano}`; `Investex.Operations.get_portfolio/2` for the account and
decode a `MoneyValue` through `Investex.Money.from_money_value/1`; close the account — and it MUST PASS (the hard floor: ≥1
Instruments read dialed AND ≥1 live Money decode). A read the sandbox does not serve → a **named loud SKIP** with the
reason, never a silent pass; if neither money-dense read is served, STOP and report to the Director (do not ship a hollow
live gate). Report the sandbox result as a PASS/SKIP/FAIL line in the ledger — **no raw dump** (sandbox account/instrument
ids), and **no token value**. Determinism loop on Tier 1 only. Boundary grep empty (no transport-surface edit; no order
method; no stream). Audit T/D/V/L/Y. Do not run git. Report to the Director.

**◇ Apollo (evaluator — HIGH risk, the §11.2 charter; between Stage 4 and Stage 5).** Adopt `.claude/agents/apollo.md`.
Run the prompted-checks table against `trd.9.2.specs.md` G1-scaffold@48/G2/the-fidelity-check/G5/G6-subset/G7 + INV-1/2/3/8/9;
produce ≥1 un-prompted finding, ≥1 attack-that-held, and a mutation kill-rate. **Verify the read layer is real, not
hollow:** the 41 functions each map to their named Stub function (re-run the fidelity check independently; pick a random
function and trace `def` → `&Stub.<name>/3` → the proto RPC → the generated Service); the parity scaffold genuinely asserts
48/24/72 (mutate a row, confirm red). **Verify the live subset actually dialed** (not stubbed-and-claimed): re-run
`mix test --include sandbox` with the env token if reachable, or inspect Mars's recorded evidence, and **confirm Money was
decoded from REAL venue data** at least once (the hard floor). **Verify the secret leaked into nothing** — grep the 3 new
modules, the new tests, the gate `.out`, and the ledger for a token-shaped string; confirm `.env.test` was not copied in.
Use `AskUserQuestion` to resolve any residual ambiguity with the Operator (e.g. a sandbox-unserved money-dense read leaving
Money un-exercised live, a retry-posture edge) and keep the product shippable. Verdict: **BUILD-GRADE / BLOCKED** + mentor
diffs. Report to the Director.

**Stage 5 · Director (ship).** Gate green AND Apollo BUILD-GRADE AND the live representative-subset PASSED (the hard floor
met) → lock the ratifying `tool_x_decision` + write `tool_x_complete` (Z-n) → **one LAW-4 pathspec commit** (below) →
Stage-6 fold (the exchange-platform memory + the roadmap/progress reconcile + the next frontier = TRD.9.3 the trading
services + the branded-`ORD` seam).

## Acceptance (9.2 is build-grade when)

- `Investex.Instruments` (27) + `Investex.MarketData` (7) + `Investex.Operations` (7) exist, each function named **exactly**
  per the manifest, arity `/2`, a 1:1 pass-through to its identically-named `Stub` function; compiles
  `--warnings-as-errors` clean; the diff touches no transport module's public surface, no order method, no stream.
- The parity scaffold asserts **48 implemented / 24 pending / 72 enumerated**; the touched-services test = exactly
  `{Users, Sandbox, Instruments, MarketData, Operations}`; a mutated/dropped row fails it (INV-1/2; the "count prints 72"
  full assertion is still 9.5).
- **The pass-through-fidelity check passes** — every read function delegates to its identically-named `Stub` function
  (the copy-paste killer), network-free.
- `Investex.Money` round-trips integer `{units, nano}` over the read responses' `Quotation`/`MoneyValue` field shapes with
  no float (G2, exercised — no new function).
- Tier 1 is network-free and green; `trd_9_2_check.{exs,out}` committed, reproducible (run twice, identical), exit zero (G5).
- **The live representative subset PASSED** against the real sandbox endpoint — the hard floor (≥1 Instruments read dialed
  AND ≥1 Money decode from real money-dense data); unserved reads are named loud SKIPs (G6, 9.2 scope; INV-8).
- (G7) no token-shaped string anywhere in the 3 modules, tests, gate `.out`, or ledger; the token is read from the env only.
- Apollo's verdict is BUILD-GRADE; every `AskUserQuestion` resolved.
- The deferred set is named in the slice (INV-4/G3 → 9.3; INV-7 → 9.5; the 9.3/9.4/9.5 surfaces).

## LAW-4 — the single ratifying commit (Director only, at Z-n)

Pathspec (exactly these; **never `git add -A`, never a bare commit** — the working tree carries much foreign in-flight
work: `docs/echomq/**`, `html/echomq/**`, `docs/fsharp/**`, `html/fsharp/**`, `.claude/**`, `echo/apps/echo_mq/**`,
`docs/echo_mq/specs/emq-2-3.*`, `docs/portal/**`, and more — exclude every one). Review `git status --short` +
`git diff --cached --name-only` first; check `.git/rebase-merge`/`rebase-apply`:

```
git commit -F <msg> -- \
  echo/apps/investex \
  echo/rungs/exchange/trd_9_2_check.exs \
  echo/rungs/exchange/trd_9_2_check.out \
  docs/exchange/trd.9.2.md \
  docs/exchange/trd.9.2.specs.md \
  docs/exchange/trd.9.2.prompt.md \
  docs/exchange/trd.progress.md \
  docs/exchange/trd-9-2.progress.md \
  docs/exchange/trd-9-2.registry.json
```

(**`echo/mix.lock` is NOT in the pathspec** — 9.2 adds no dep. If a stray lock change appears, it is foreign churn — do
not sweep it. `echo/apps/investex` as a directory pathspec catches the 3 new `lib/` modules + the grown/new `test/` files
and nothing else — confirm `git status --short echo/apps/investex` shows only 9.2 work before staging.) The message cites
the slug `trd-9-2`, the Z-n, the D-n decisions, the Y-n reports, and that the live representative subset passed (without any
token value, account id, or instrument id).

## Definition of done

`echo/apps/investex` gains its read services: `Investex.Instruments` (27) + `Investex.MarketData` (7) +
`Investex.Operations` (7) = 41 read-only unary functions, each a 1:1 pass-through over the fixed 9.1 transport, named
exactly per the parity manifest. The parity scaffold grows to 48 implemented / 24 pending; `Investex.Money` is exercised
against real venue data; the pass-through-fidelity check guards all 41. Pure-gated (`trd_9_2_check`, network-free,
reproducible) AND live-verified on the representative subset (the hard floor met) against the real sandbox endpoint. The
slice spec `trd.9.2.{md,specs.md}` is on disk, PROPOSED, with RQ-1..RQ-4 settled. Apollo is BUILD-GRADE. The ledger carries
T/D/V/L/Y/Z; one Director pathspec commit ratifies it; the next frontier (TRD.9.3, the trading services + the branded-`ORD`
seam) is recorded. No token value appears anywhere.
