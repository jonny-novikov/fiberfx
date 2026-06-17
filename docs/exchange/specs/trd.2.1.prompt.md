# trd.2.1.prompt.md — the X-MODE runbook (the pure matching core)

> The orchestration runbook for rung **TRD.2.1**, the first slice of TRD.2 ([`trd.2.specs.md`](trd.2.specs.md)).
> Authored by the Director at §0 bootstrap from the trd.2 quad + the Operator's settled forks. The skill
> ([`.claude/skills/x-mode/SKILL.md`](../../.claude/skills/x-mode/SKILL.md)) binds the laws
> ([`.claude/commands/x.md`](../../.claude/commands/x.md)); this file is the rung delta. **Status of TRD.2: PROPOSED.**

## The rung in one paragraph

TRD.2 is the matching engine — a bounded `EchoCache.Ring` drained by one `Exchange.Book` process (the single
writer) that consults a pure `Exchange.Decider` and folds its events into a pure `Exchange.OrderBook`. **TRD.2.1
carves out the pure heart of that engine and ships it standalone**: `Exchange.OrderBook` (the per-side `gb_trees`
price ladder, level-FIFO by branded mint order) and `Exchange.Decider` (`decide/2` + `evolve/2`, the matching rule
as a pure function over events). Two crossing orders fill at the maker's price; the remainder of a limit order
rests; price-time priority falls out of the id law; a same-account cross is **rejected at the aggressor**; no float
ever appears; every fill mints its own branded `FIL` id. The stateful shell — the `Exchange.Book` GenServer, the
Ring drain, admission-reconcile, cancel-against-the-book, the per-account `BrandedTree` index — is **deferred to
TRD.2.2**. The slice is exhaustively property-testable without starting a single process.

## Mode

**Flat-L2** — a build stream (Mars) + a gate (the rung script + the ExUnit/StreamData suite) + a verify (the
Director's Stage-3 solo review). Sequential, Director-in-loop, one ratifying commit.

## Risk tier: NORMAL — no Apollo

A pure functional core: no auth, no data store, no deploy, no secret, no irreversible migration. The verification
floor is the **Director's Stage-3 solo review** (fresh-gate reconcile + independent per-app re-run + an adversarial
matching probe + a mutation spot-check) plus **heavy StreamData properties** on every matching invariant. Apollo
does **not** spawn.

## Settled forks (the resolved matrix — no open Operator decision)

| # | Question | **Settled** |
|---|---|---|
| F-1 | TRD.2 slice for this rung | **TRD.2.1 — the pure matching core**: `Exchange.OrderBook` + `Exchange.Decider` only. Defer `Exchange.Book`, the Ring drain, admission-reconcile, cancel, the per-account index → **TRD.2.2**. |
| F-2 | Self-trade policy | **Reject the aggressor.** If the incoming order would cross a resting order of the **same account**, the Decider rejects the **incoming** order in full — `{:rejected, %{order: <taker id>, reason: :self_trade}}` — and the book is left unchanged (all-or-nothing; no partial fill against others ahead of the self-cross). The richer "fill non-self makers, reject only the self-crossing remainder" variant is recorded as a `tool_x_alternative` (V-n), deferred. |
| F-3 | Risk tier / evaluator | **NORMAL** — Director Stage-3 solo review + heavy properties; **no Apollo**. |
| F-4 | Command kinds matched | **`:place` only** (limit + market). `:cancel` matching pairs with the Book's order lifecycle + the `BrandedTree` index → **TRD.2.2**. A `:place` market order matches available liquidity at maker prices in price-time order and **never rests**; Venus locks the unfilled-market-remainder rule + its closed reason (candidate `:no_liquidity`). |
| F-5 | Minting inside `decide` | **Locked by spec** (`trd.2.specs.md` Mars notes): the `FIL` id is minted **inside `decide`** via `EchoData.Snowflake.next_branded("FIL")` — the canon. `decide` is therefore **pure modulo the mint** (the same id-effect the Gateway is granted at TRD.1.1); the forbidden-effect grep set is `GenServer · :ets · System.monotonic_time · System.os_time · Process.` and must be empty in `Exchange.Decider`. Properties never assert id-equality across two `decide` calls. |

## Grounding (real, verified `file:line` — NO-INVENT)

- **The canon (mint + id law).** `EchoData.Snowflake.next_branded/1` (`echo/apps/echo_data/lib/echo_data/snowflake.ex:104`
  ≡ `BrandedId.encode!(ns, next())`); requires `EchoData.Snowflake.start/1` (`snowflake.ex:40`) once before any mint.
  `EchoData.BrandedId.{valid?/1 :95, namespace/1 :97, parse/1 :27, encode!/2 :85}`. Mint `FIL` through this; never
  construct an id by hand.
- **The price-time law (Appendix F).** A branded id sorts lexically in mint order (`ts|node|seq`, big-endian
  Base62); the level-FIFO needs no clock and no comparator beyond the id's byte order.
- **The command vocabulary this rung consumes** (TRD.1.1, as-built): `Exchange.Gateway`'s `{:place, %{id,
  instrument, account, direction, type, quantity, price}}` (`echo/apps/exchange/lib/exchange/gateway.ex:47`),
  `money :: {units :: integer(), nano :: integer()}` (`gateway.ex:41`), `direction :: :buy | :sell`,
  `type :: :limit | :market | :bestprice`, `price :: money() | :market`.
- **The deferred substrate (TRD.2.2, named only).** `EchoCache.Ring.{publish/2 :38, occupancy/1 :62, stats/1 :68,
  start_link/1 :85}` (`echo/apps/echo_cache/lib/echo_cache/ring.ex`) and `EchoData.BrandedTree.{new/0 :16, first/2
  :59, last/2 :71, page_after/4 :83}` — consumed by the Book in TRD.2.2; **not** built or edited this rung.
- **Style anchor.** `echo/apps/exchange/lib/exchange/gateway.ex` (the moduledoc-cites-spec, wide-type, `@typedoc`,
  INV-citation-inline house style Mars mirrors). **Rung-gate template.**
  `echo/rungs/exchange/trd_1_1_check.exs` (`mix run --no-start`; `Code.require_file` the canon raw
  `base62 → native → snowflake → branded_id` then the rung modules; `Snowflake.start(N)`; a `G.line/3` helper;
  one printed line per gate; `Enum.all? → "PASS k/k" | "FAIL" + System.halt(1)`; committed `.out`).

## The contract TRD.2.1 ships (Venus pins it build-grade in `trd.2.1.specs.md`)

```elixir
# Pure ladder ─────────────────────────────────────────────────────────────────
Exchange.OrderBook.new() :: book_state()
Exchange.OrderBook.best(book_state(), :buy | :sell) :: {money(), [resting]} | :empty
#   per-side gb_trees keyed by price; each level a FIFO by branded mint order.
#   A resting entry carries at least {id, account, side, price, quantity} — account
#   is REQUIRED (self-trade detection, F-2). The BrandedTree per-account index is
#   TRD.2.2 (cancel/queries), NOT this rung.

# Pure decider (pure modulo the FIL mint, F-5) ─────────────────────────────────
Exchange.Decider.decide(command(), book_state()) :: [event()]
Exchange.Decider.evolve(book_state(), event())   :: book_state()
#   decide handles {:place, …} (limit + market). cross / partial-fill / rest(limit)
#   / reject. evolve folds ONE event into state; book state == fold of evolve over
#   emitted events in mint order (INV-4). No state reachable except through the fold.

@type event ::
        {:fill,    %{taker: binary(), maker: binary(), instrument: binary(),
                     price: money(), quantity: pos_integer(), id: binary()}}
      | {:rested,  %{order: binary(), instrument: binary(),
                     side: :buy | :sell, price: money(), quantity: pos_integer()}}
      | {:rejected, %{order: binary(), reason: atom()}}     # closed reason set, Venus locks
@type money :: {integer(), integer()}                       # Quotation; never a float (INV-6)
```

Locked rules (Venus records each as a `tool_x_decision`): **fill price = the maker's** (G1); **one `:fill` per maker
matched, each with its own `FIL` id**; **limit remainder rests, market remainder never rests** (F-4); **self-trade =
reject aggressor, book unchanged** (F-2); **closed `:rejected` reason set** (≥ `:self_trade`, + the market reason);
**no float in any event or book value** (INV-6).

## Invariants in scope (the rest defer with the Book)

**In TRD.2.1:** INV-3 (pure decision) · INV-4 (fold is state) · INV-5 (price-time from the id) · INV-6 (typed money,
never float) · the Go-seam freeze (every `:fill` carries a branded `FIL` id + integer money, so a downstream job is
keyable). **Deferred to TRD.2.2:** INV-1 (single writer) · INV-2 (admission reconciles) · INV-7 (overload is an
answer) — all three are properties of the Ring-draining Book, which this rung does not build.

## Acceptance gates (this slice)

- **G1 — two crossing orders fill.** A resting sell and a crossing buy at/through its price produce a `:fill` at the
  **maker's** price, the matched quantity, a branded `FIL` id; the limit remainder rests. (Property + the gate line.)
- **G2 — price-time priority holds** — a property over `decide`: among makers at one price the earlier mint order
  fills first; among prices the best fills first.
- **G5 — no float** — structural assertion over a matched run: no event or book-state value is a float.
- **G6 — self-trade prevented** — a property: two same-account crossing orders do not self-fill; the aggressor is
  rejected `:self_trade`, the book unchanged (F-2).
- **AS-2 pure-grep** — `Exchange.Decider` contains no `GenServer`, `:ets`, `System.monotonic_time`, `System.os_time`,
  or `Process.` (the FIL mint is the sole sanctioned effect, F-5).
- **AS-7 fill-key freeze** — every `:fill` carries a branded `FIL` id (namespace `"FIL"`, `valid?`) and `{units,
  nano}` integer money; no fill without an id.

(G3 single-writer and G4 admission-reconcile are **TRD.2.2** — they need the Book.)

## The stages (lift each into the per-spawn contract; §3 of the skill wraps it)

**Stage 1 · Venus (architect).** Reconcile the trd.2 quad against the greenfield tree (confirm `next_branded/1`,
`BrandedId`, the Gateway command shape, and the Ring's existence for the deferral note — all real, cited). Then
**carve the slice**: author `docs/exchange/trd.2.1.md` (narrates the pure core, the deferral to 2.2) and
`docs/exchange/trd.2.1.specs.md` (authoritative — the pinned surface above, INV-3/4/5/6 in scope, the locked rules,
G1/G2/G5/G6 + AS-2/AS-7, the explicit TRD.2.2 deferral list). Lock D-n: the slice boundary; self-trade = reject
aggressor (book unchanged); the closed `:rejected` reason set; the market-remainder rule; pure-modulo-the-mint;
fill-price = maker. Record the "fill-others-then-reject-remainder" self-trade variant as a V-n. **Gate:** the slice
is settled, internally consistent (no deliverable/invariant referenced-but-undefined), no open fork; every reconcile
claim MATCH or `[RECONCILE]`-DEFERRED.

**Stage 2 · Mars-1 (implementor).** Build to the slice spec: `echo/apps/exchange/lib/exchange/order_book.ex` (the
pure ladder) then `echo/apps/exchange/lib/exchange/decider.ex` (`decide`/`evolve`), mirroring the `gateway.ex` house
style (moduledoc cites `trd.2.1.specs.md`; `@type`/`@typedoc`; INV citations inline). Write the rung's own tests —
`echo/apps/exchange/test/exchange/order_book_test.exs` + `decider_test.exs` — ExUnit + StreamData properties for
G1/G2/G5/G6 + AS-7, and the AS-2 pure-grep as a test. Mint `FIL` **inside `decide`** via the canon; integer money
arithmetic with integer carry; never a float. **Cite the spec line for every public call; invent nothing.**
`cd echo && TMPDIR=/tmp mix compile --warnings-as-errors` clean; the diff stays inside `lib/exchange/{order_book,
decider}.ex` + `test/exchange/`. **Gate:** compiles clean; both modules + tests exist; the tests Mars wrote pass
(`cd echo/apps/exchange && TMPDIR=/tmp mix test`); report any realization-over-literal.

**Stage 3 · Director (solo review).** A real pass, not a glance: (a) fresh-gate reconcile of `trd.2.1.specs.md`
against the as-built `order_book.ex`/`decider.ex`; (b) independent **per-app** re-run of the suite
(`cd echo/apps/exchange && TMPDIR=/tmp mix test`); (c) an **adversarial matching probe** via ephemeral `mix run -e`
(not Mars's tests) — maker-price fill, a price-time tie broken by mint order, a partial fill consuming two makers, a
self-trade rejected with the book unchanged, a structural no-float scan over a matched run, a `FIL`-namespace check;
(d) a **mutation spot-check** — Edit-in one bug (e.g. fill at the taker's price, or reverse the level-FIFO order),
confirm a property **kills** it, then **revert net-zero** (`git diff` empty after). Consolidate findings into a
REMEDIATE list (`tool_x_report` + items as learnings/decisions). **The Director writes no production code (LAW-1a).**

**Stage 4 · Mars-2 (implementor, harden — resume the Stage-2 Mars, do NOT re-spawn/re-register).** Close the
REMEDIATE findings; write the rung gate `echo/rungs/exchange/trd_2_1_check.exs` (copy the `trd_1_1_check.exs`
pattern: `--no-start`, `require_file` the canon + `order_book.ex` + `decider.ex`, `Snowflake.start(N)`, one printed
`G.line` per gate G1/G2/G5/G6 + AS-2 pure-grep + AS-7; a self-contained deterministic generator, no StreamData dep
in the gate; `PASS k/k` | `FAIL`+halt 1) and commit its transcript `trd_2_1_check.out` (exit zero). Run the full gate
+ the **determinism loop** (the per-app suite 100×). **Gate:** every gate line green; REMEDIATE closed; tests green;
the determinism loop holds; the pure-grep over `decider.ex` is empty.

**Stage 5 · Director (solo ship).** Gate green → the §4 LAW-4 pathspec commit (below). `Z-n` + `D-n` present;
`git status --short` + `git diff --cached --name-only` reviewed; the foreign out-of-band paths excluded. **No Apollo.**

**Stage 6 · Director (fold forward).** Mark TRD.2.1 shipped in `docs/exchange/trd.progress.md`; record the next gap
(**TRD.2.2** — the `Exchange.Book` GenServer + Ring drain + admission-reconcile + cancel + the BrandedTree index, INV-1/2/7,
G3/G4, AS-3/AS-4). Update the `exchange-platform` memory. Surface the frontier. (No peer-def mentoring edit without an
explicit Operator grant.)

## LAW-4 commit pathspec (Director-only, exactly once at `tool_x_complete`)

```
git commit -F <msg> -- \
  echo/apps/exchange/lib/exchange/order_book.ex \
  echo/apps/exchange/lib/exchange/decider.ex \
  echo/apps/exchange/test/exchange/order_book_test.exs \
  echo/apps/exchange/test/exchange/decider_test.exs \
  echo/rungs/exchange/trd_2_1_check.exs \
  echo/rungs/exchange/trd_2_1_check.out \
  docs/exchange/trd.2.1.md \
  docs/exchange/trd.2.1.specs.md \
  docs/exchange/trd.progress.md \
  docs/exchange/trd-2-1.progress.md \
  docs/exchange/trd-2-1.registry.json
```

**EXCLUDE (operator out-of-band / foreign, never `git add -A`):** `.claude/agents/*.md`, `docs/echo_mq/**`,
`docs/mercury/**`, `docs/portal/**`, `docs/exchange/trd-1-1.progress.md`, and every untracked path outside the
pathspec. Message body cites the slug `trd-2-1`, the `Z-n`, the `D-n` decisions, and the `Y-n` report.

## Definition of done

`cd echo/apps/exchange && TMPDIR=/tmp mix test` green (per-app discipline; umbrella-wide `mix test` BANNED);
`cd echo && mix run --no-start rungs/exchange/trd_2_1_check.exs` → `PASS k/k`, exit 0, transcript committed;
G1/G2/G5/G6 + AS-2 pure-grep + AS-7 all green; the `decider.ex` forbidden-effect grep empty; no float anywhere in a
matched run; the slice boundary held (no `Exchange.Book`, no Ring code, no cancel matching this rung).
