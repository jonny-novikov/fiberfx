---
name: exchange-platform
description: "The Exchange Platform — the REAL-code implementation of the BCS B8 trading capstone, in echo/apps/exchange (Exchange.* modules); specced under docs/exchange/ (RENAMED from docs/trading/ 2026-06-13, system docs exchange*.md, rung quads keep the `trd` codename); built rung-by-rung via the trd.1–8 ladder through x-mode Flat-L2; trd.1.1 (the Gateway MVP) + trd.2.1 (the pure matching core — Exchange.OrderBook + Exchange.Decider) SHIPPED; TRD.9 (investex — the BEAM-native Tinkoff Invest client, echo/apps/investex, full parity 10 services/72 RPCs) chapter quad SPECCED (0aab3766); TRD.9.1 (the transport spine) SHIPPED a107586a via x-mode Flat-L2 + Apollo (HIGH risk; Apollo BLOCKED a false-green G6, remediated 1 loop, re-verified BUILD-GRADE); next TRD.9.2 (the read services) OR TRD.2.2 (the Book)"
metadata: 
  node_type: memory
  type: project
  originSessionId: e62df350-cb8a-4f62-86c0-6ecd21b8807a
---

The **Exchange Platform** is the real-code build of the `/bcs` **B8 capstone** (the trading system). Where B8
teaches a *PROPOSED* `Exchange.*` consumer standing on the as-built echo substrate (EchoCache.Ring/Journal,
EchoMQ lanes, the canon), the Exchange Platform makes it real, **one rung at a time**.

**The rename (2026-06-13).** `docs/trading/` → **`docs/exchange/`**; the five system docs `trading*.md` →
`exchange*.md` (`exchange.md` · `.specs.md` · `.roadmap.md` · `.patterns.md` · `.strategies.md`); the **rung
quads KEEP the `trd` codename** (`trd.1.*`, `trd.2.*`, `trd.progress.md`). So a future session looking for
`docs/trading` will NOT find it — it is `docs/exchange`. The /bcs `bcs*.md` docs (bcs.toc/roadmap/content-map)
were repointed to `docs/exchange` + given Exchange-Platform reference pointers. STALE follow-up (L-1): some
out-of-scope files (other docs, the `html/bcs/trading/**` course pages) still say `docs/trading` — a later
course↔code sync.

**The code.** App **`echo/apps/exchange`** (OTP `:exchange`, modules `Exchange.*`), a lib-only umbrella app
depending only on `{:echo_data, in_umbrella: true}` (the canon — mints via `EchoData.Snowflake.next_branded/1`).
The trd ladder: TRD.1 Gateway · TRD.2 Book (the Disruptor seat on EchoCache.Ring) · TRD.3 ledger/journal/
settlement · TRD.4 market-data claims · TRD.5 projections · TRD.6 stream log + polyglot Go risk consumer ·
TRD.7 placement · TRD.8 sharding. Milestones A (TRD.1–5) · B (TRD.6) · C (TRD.7–8). Grounded in the Tinkoff
Invest order contract (Quotation `{units,nano}` integer money, `PostOrderRequest.order_id` = the branded id).

**SHIPPED: trd.1.1 — the Gateway MVP** (2026-06-13, commit `39cc2baa`, via **x-mode Flat-L2**: Venus reconcile/
rename/slice → Mars-1 build → Director solo review → Mars-2 harden → Director ship; no Apollo, risk NORMAL).
`Exchange.Gateway` (one stateless module, `echo/apps/exchange/lib/exchange/gateway.ex`): parse-don't-validate —
untrusted `map` → `{:ok, command}` | one of a closed 6-atom error set (`:unknown_instrument`/`:bad_direction`/
`:bad_order_type`/`:nonpositive_quantity`/`:bad_price`/`:malformed`); `parse_place/1` (limit+market) +
`parse_cancel/1`; branded `CMD`/`ORD` minted at acceptance; `{units,nano}` money, **never a float**; the type is
authored **wide** (names `:bestprice`/`{:replace}`) while the 1.1 parsers are the subset (the 1.1→1.2 stability
seam). Gate `echo/rungs/exchange/trd_1_1_check.exs` → **PASS 8/8**; 16 tests + 3 StreamData properties.
**Deferred to trd.1.2:** `parse_replace/1`, `:bestprice`, the **INV-6/G6 idempotency seam** (replay-token →
branded-id reconciliation + the venue `order_id` outward position).

**SHIPPED: trd.2.1 — the pure matching core** (2026-06-13, commit `10957286`, via **x-mode Flat-L2**: Venus carve+
lock D-1..D-8 → Mars-1 build → Director solo review → Mars-2 harden → Director ship; no Apollo, risk NORMAL). Two
PURE modules, no process: **`Exchange.OrderBook`** (`order_book.ex` — per-side `:gb_trees` price ladder keyed by
`{units,nano}` term-order, each level a FIFO by branded mint order; `new/0`+`best/2`; buy-best=largest key,
sell-best=smallest) and **`Exchange.Decider`** (`decider.ex` — `decide/2`+`evolve/2`, **pure modulo the single FIL
mint**). Matching rule: a crossing order fills at the **MAKER's** price, one `:fill` per maker (each minting its own
`FIL` via `EchoData.Snowflake.next_branded("FIL")` inside `decide`); a **limit** remainder rests, a **market**
remainder rejects `:no_liquidity`; a **same-account cross rejects the aggressor in full** (`:self_trade`, book
byte-unchanged, all-or-nothing); price-time priority falls out of the id byte order (no clock); no float anywhere.
Events `{:fill,…}` / `{:rested,…}` (carries `account` — **D-8** widening, the fold needs it for self-trade) /
`{:rejected, %{reason}}` (closed set `:self_trade | :no_liquidity`). Gate `echo/rungs/exchange/trd_2_1_check.exs` →
**PASS 6/6** (G1 maker-price · G2 price-time · G5 no-float · G6 self-trade · AS-2 pure-grep · AS-7 fill-key);
34 tests / 10 properties; the AS-2 forbidden-effect grep (`GenServer · :ets · System.monotonic_time ·
System.os_time · Process.`) is empty in `decider.ex`. **Deferred to TRD.2.2:** the **`Exchange.Book` GenServer**
(the single writer), the **`EchoCache.Ring` drain + admission-reconcile** (INV-1/2/7, G3/G4), **cancel-against-the-
book** matching, the per-account **`EchoData.BrandedTree` index**. Gotcha (L-1, for the Book): `evolve/2` assumes
events are folded in emitted (mint) order — the single-writer Book must preserve it. Gotcha (Mars L-1): the AS-2
pure-grep strips `#` comments but NOT the `@moduledoc` heredoc (a string), so the moduledoc must paraphrase the
forbidden tokens, never spell them.

**SPECCED: TRD.9 — investex (the BEAM-native Tinkoff Invest client)** (2026-06-13, commit `0aab3766`, via **x-mode
Flat-L2 spec-authoring variant** — the deliverable IS the spec: Venus authored the chapter quad from a Director-
grounded runbook → Director Stage-3 solo review → ship; no Mars, no Apollo, risk NORMAL). **New umbrella app
`echo/apps/investex`** (OTP `:investex`, `Investex.*`, **lib-only, no `mod:`** — the consumer supervises
`Investex.Client`, nothing boots a venue connection at app start), the Elixir equivalent of `invest-api-go-sdk` at
**full parity: 10 gRPC services / 72 RPCs** (re-derived EXACT from
`github.local/invest-api-go-sdk/proto/*.proto` — the brief's loose "~75" resolved to 72; the two `GetTradingStatus(es)`
RPCs the prose collapsed are distinct), each → a named `Investex.<Service>.<fun>/n` in an exhaustive parity manifest
+ a parity-check test. Spine (D-1..D-11 = F-1..F-11): **elixir-grpc over the Mint adapter + elixir-protobuf**, the
generated `Investex.Proto.*` **committed** (no new transport stack — mint/castore/hpax already locked; `:grpc` +
`:protobuf` are the only new deps); a supervised `Investex.Client` owning the `GRPC.Channel` + `Config`, stateless
per-service modules, one fn per RPC; **one supervised GenServer per stream, resubscribe-on-reconnect** (+ `Ping`);
money `{units, nano}` integers via `Investex.Money`, **never float** (the Go `.ToFloat()` bridge deliberately NOT
mirrored); the **branded `ORD`** id validated at the edge = the venue `order_id` idempotency key (the seam to the
Exchange platform — triangulated across exchange.specs.md + the roadmap Go-worker-tier + orders.go, discovered not
invented); a **pure** `Investex.Retry.decide/3` (linear 500ms on Unavailable/Internal; silent longer wait on
ResourceExhausted honoring `x-ratelimit-reset`); a **two-tier test strategy** — a pure default `--no-start` gate +
an opt-in `@tag :sandbox` suite hitting the real sandbox with **`INVEST_TOKEN` (env-only, value in nothing — INV-9),
that SKIPS (not fails) keyless**. Decomposition **TRD.9.1–9.5** (9.1 transport spine: Config + codegen + Client +
retry + UsersService + the sandbox bootstrap trio + the two-tier harness · 9.2 read svcs Instruments/MarketData/
Operations · 9.3 trading Orders/StopOrders + the ORD seam · 9.4 full SandboxService · 9.5 the 5 streams;
SandboxService SPLIT 9.1/9.3/9.4 — D-12, because the Go client auto-bootstraps a sandbox account in its constructor).
**The build rungs are HIGH risk** (network / live secret / auth) → each warrants a dedicated **Apollo** + the
secret-hygiene gate. Resolves the roadmap's open *"Go worker tier: dedicated quad vs distributed"* → investex IS the
dedicated venue-client subsystem; the Go money-math fleet stays distributed (TRD.3/4/6). The ladder now extends to
**TRD.9** (the roadmap was TRD.1–8). Quad `docs/exchange/trd.9.{md,specs.md,stories.md,llms.md}` + the
`trd.9.prompt.md` runbook; ledger `docs/exchange/trd-9.progress.md`. **Next on investex: build TRD.9.2** (the read services).

**SHIPPED: TRD.9.1 — the investex transport spine** (2026-06-14, commit `a107586a`, via **x-mode Flat-L2 + a dedicated
Apollo** — HIGH risk: network / live secret / auth). `echo/apps/investex` (lib-only, no `mod:`, INV-5): `Investex.Config`
(env-only token, INV-9) · supervised `Investex.Client` (TLS verify_peer + Bearer/x-app-name + a QUIET supervised stop) ·
the pure `Investex.Retry.decide/3` (x-ratelimit-reset-honoring) · `Investex.Money` (`{units,nano}`, no float) ·
`Investex.Error` + the `Caller` metadata seam · UsersService (4) + the SandboxService bootstrap (3) · the **committed**
protoc-gen-elixir `Tinkoff.Public.Invest.Api.Contract.V1.*` modules (the proto-package namespace, aliased `Proto` — R-1)
+ the `mix investex.gen_proto` regen task · the parity scaffold (7 mapped / 65 pending / 72 enumerated from the real
services) · the two-tier harness. Gate `echo/rungs/exchange/trd_9_1_check.exs` → **PASS 5/5** (Tier 1, network-free,
reproducible) + the **live sandbox round-trip** (`open→get_accounts→close`) a **standing result across seeds** vs the
real sandbox endpoint (the Operator's HARD gate, run-live-or-block). `:grpc 0.11.5` + `:protobuf 0.17.0` the only new
umbrella deps. **The Apollo escalation earned its place** (the durable lesson): four prior self-reported greens missed
a **false-green G6** — an `async` OS-env clobber in `ConfigTest` (`System.delete_env("INVEST_TOKEN")` under
`async: true`) that silently no-op'd the live hard gate under the canonical `mix test --include sandbox`; only an
independent isolation re-run caught it. Remediated 1 loop: ConfigTest `async: false` + SAVE/RESTORE the prior token; the
live gate ASSERTS its own liveness (dialed-proof) + FAILS LOUDLY keyless; a quiet supervised stop replacing grpc
0.11.5's crashing `GRPC.Stub.disconnect` (it raises in the CALLEE connection process — a caller try/rescue can't catch
it). Three live-only bugs (the grpc supervisor precondition L-6, the skip-return L-7, the disconnect L-8) surfaced ONLY
at the live tier. **Two laws for future rungs:** (1) an async test never mutates global state (OS env, app env, ETS,
registered names) a concurrent/later test reads; (2) a HARD gate must specify its OWN liveness — a present key MUST
exercise it, a missing key under the opt-in is a loud failure, never a silent no-op-PASS. Slice `trd.9.1.{md,specs.md}`;
runbook `trd.9.1.prompt.md`; ledger `trd-9-1.progress.md` (D-1..D-11, L-1..L-9, Y-1..Y-7, Z-1).

**Build conventions (echo umbrella).** Per-app testing only — `cd echo/apps/exchange && TMPDIR=/tmp mix test`
(umbrella-wide `mix test` is BANNED); the rung gate is `mix run --no-start rungs/exchange/trd_1_1_check.exs`.
The aaw run-ledger is per-rung (`docs/exchange/trd-1-1.progress.md`, `docs/exchange/trd-2-1.progress.md`). Each
rung's `<rung>.prompt.md` is the committed x-mode runbook. **Next: TRD.2.2** — the `Exchange.Book` GenServer (single
writer) + `EchoCache.Ring` drain + admission-reconcile (INV-1/2/7, G3/G4) + cancel + the BrandedTree index; or
trd.1.2 (replace/`:bestprice`/idempotency); **or build TRD.9.1** — the investex transport spine (Config + protoc-gen-
elixir codegen + `Investex.Client` + the pure `Investex.Retry.decide/3` + UsersService + the sandbox bootstrap + the
two-tier harness), HIGH risk → Apollo-gated, the spec quad is committed at `docs/exchange/trd.9.*`.

Related: [[bcs-course]] (the B8 capstone this implements), [[x-mode-cclin-leadteam]] (the build protocol),
[[echo-data-unify]] (the canon it mints through), [[local-valkey-replaces-redis]].
