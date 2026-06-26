# Codemojex · The Golden Room Economy — the decision surface

> The aaw **architect's-approach** fork-surface doc ([`docs/aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md)).
> The locked tournament model is fixed by the Operator (ledger `D-11`); the OPEN decisions below are surfaced
> as **arms** for the multi-architect fan-out (Venus-A ∥ Venus-B) to argue in four parts and the Operator to
> rule. NO-INVENT: every named surface is grounded in `echo/apps/codemojex` at a real `file:line`, or marked
> forward-tense. This doc **stages** the debate; it does not decide it (the agent surfaces forks, the Operator
> rules).

## 1. The locked model (Operator-ruled — `D-11`; NOT re-litigated)

- The **Golden Room** is `type:"classic"` + `golden:true` — a **tournament-room marker**, NOT a "boost class".
- **Live-proportional payout** among the top finishers — a new `settlement:"live_split"` + `economy:"proportional"`
  reusing `Economy.top_k_split` (`rooms.ex:189` dispatch · `economy.ex:62`). Winner-take-all stays for ordinary
  non-golden paid rooms; the blind `type:"golden"` mode keeps its sealed top-K.
- **Both** a one-time **buy-in** (USD or Keys) AND a **per-guess fee**.
- **Buy-ins fund the pool**; per-guess fees are **platform revenue**.
- **Hard 10-player floor** (gather-gated start, the ratified `:gathering` design); never-fills **refunds the
  buy-ins** exactly-once (`close_void` + the partial unique index).
- **Launch:** a free warm-up room **"Бокс для разминки"** (`type:classic`, free, 1 clip/guess, no buy-in) + one
  **Golden Room**.

## 2. RECONCILE — `gold_multiplier` is REMOVED (Operator-ruled, this turn)

The Operator has ruled `gold_multiplier` is **not a Codemoji game mechanic**. It is **drift** that propagated
into the backend AND the canon but never existed in the real product:

| Surface | Carries `gold_multiplier`? |
|---|---|
| Elixir backend | **YES** — `schemas/room.ex:21`, `schemas/game.ex:35`, `migration:67,100` (`null:false default:1`), `rooms.ex:40,108,198,225`, `economy.ex effective_pool/3`, `golden_blind_story_test.exs:24`, `docs/golden-rooms.md:13,30,35,62` |
| Design canon | **YES** — `node/codemoji-design/gameplay/03-rooms.md`, `README.md:123` |
| **Real frontend (`node/codemoji-app` — the product)** | **NO** (grep-confirmed absent) |

→ **Consequence.** The tournament pool has **no boost multiplier**. `golden:true` marks a tournament room
(buy-in + gather-10 + proportional payout), not a "boost class". `gold_multiplier`, `effective_pool/3`'s
`× mult`, and the `golden_blind` test's multiplier are scheduled for **removal in the build rung** (a
reconcile-out, additive to the calibration). This **strikes the "× boost" arms** from the pool-composition
options below — the corrected arms are buy-in / seed / rake only. It also supersedes the `× boost` pool options
in `codemojex-golden-calibration.economy.design.md §4`.

## 3. Decision 1 — Pool composition (the three options, corrected)

**Context.** Buy-ins fund the pool (`D-11`). Open: does the platform also **seed** the pool, and is a
**published rake** taken? (No boost — `gold_multiplier` removed.) The arms:

| Arm | Pool formula | One-line |
|---|---|---|
| **A — Buy-ins only** | `Σ buy_ins` | a pure peer-funded tournament; the prize is exactly what players staked; lowest platform cost / exposure |
| **B — Seed + buy-ins** | `seed + Σ buy_ins` | a platform-seeded floor guarantees a real prize even with a thin (but ≥10) field; promotional cost scales with seed, not the field |
| **C — (Seed + buy-ins) − rake** | `(seed + Σ buy_ins) − rake` | a **published** platform rake (the roadmap `BNK` model, forward) funds a transparent, sustainable margin; the remainder pays the board |

(Four-part arms — Rationale · 5W · Steelman · Steward — argued by the fan-out in §6.)

## 4. Decision 2 — The USD rail

| Arm | Mechanism | Cost |
|---|---|---|
| **A — Keys priced in USD** (launch-ready) | USD is the pricing unit; charge in Keys (a pure `keys_for_usd/1` reusing the Stars→keys path, `wallet.ex:108`) | no new commerce system |
| **B — Direct Stars invoice at join** | a real Telegram Stars payment at join | needs the forward `PKG/ORD/OTX/WHK` commerce build — defers the Golden launch behind commerce |

## 5. Decision 3 — Refund scope (never-fills) + Decision 4 (confirm)

- **D3 — refund scope.** Arm A: **buy-ins only** (a tournament that never began; per-guess fees bought a
  delivered service — Apollo + Venus-A lean). Arm B: **buy-ins + gathering per-guess fees** (maximal fairness).
- **D4 — the buy-in room is never free** (confirm + enforce). A buy-in (real money) cannot fund a pool with
  valueless clips → enforce `buy_in ⇒ not free` as a changeset rule (Apollo's un-prompted finding). Recommended:
  **confirm**.

## 6. The fan-out debate (staged by the Director)

Per the architect-approach multi-architect debate: **Venus-A** argued the platform-sustainability lens
([`economy.venus-a.md`](economy.venus-a.md)), **Venus-B** the player-value / growth lens
([`economy.venus-b.md`](economy.venus-b.md)) — the full four-part arms (Rationale · 5W · Steelman · Steward)
live in those files. This section stages the divergence and the convergence; the Operator rules.

### Rankings

| Decision | Venus-A · sustainability | Venus-B · player-value | Apollo | Status |
|---|---|---|---|---|
| **D1 pool** | **A** buy-ins-only ▸ C ▸ B | **B** seed+buy-ins | — | **GENUINE FORK** — A vs B (C agreed forward) |
| **D2 USD rail** | **A** keys-priced-USD | **A** keys-priced-USD | — | **CONVERGED → A** (B = forward commerce) |
| **D3 refund** | **A** buy-ins-only | **A** buy-ins-only | A · delivered-service | **CONVERGED → A** (independent reasoning; B opens a gathering-farm exploit) |
| **D4 free buy-in** | confirm not-free | confirm not-free | flagged | **CONVERGED → confirm** |

### The one genuine fork — D1, the launch pool

Both lenses agree the **rake (Arm C)** is where durable margin ultimately lives but is a **forward `BNK`
(cm.5+)** dependency, NOT a launch gate. So the launch decision is **A vs B**:

- **A — Buy-ins only** (sustainability lead, ranked 1st). Pool = `Σ buy_ins`; **zero platform exposure**; the
  hard-10 floor makes the prize ≥ `buy-in × 10` (the marketable headline). Smallest regulatory + freeze
  surface. Margin arrives later via the BNK rake.
- **B — Seed + buy-ins** (player-value lead). A platform-seeded floor makes the prize **feel bigger than the
  staked sum** — recovering the perceived value the removed `gold_multiplier` used to supply — and breaks the
  cold-start deadlock. A standing per-round platform cost until the BNK rake lands to recoup it.

The deep structure (Venus-A, pre-empting the growth lens): a seed (B) is sustainable **only with** a rake (C)
to recoup it — so B-at-launch is a deliberate **acquisition spend** until the rake lands; A-at-launch is
zero-exposure with the rake as its natural successor when margin matters.

> **Operator rules D1.** The convergent decisions (D2-A, D3-A, D4-confirm, C-rake-forward) stand unless
> overridden.

## 7. Rulings (Operator — Stage-4 close)

| Decision | Ruling |
|---|---|
| **D1 launch pool** | **A — Buy-ins only** (pool = `Σ buy_ins`; zero platform exposure; prize ≥ `buy-in × 10` via the hard-10 floor) |
| **D2 USD rail** | **A — Keys priced in USD** (reuse the Stars→keys path + a pure `keys_for_usd/1`) |
| **D3 refund scope** | **A — Buy-ins only** (per-guess = delivered-service revenue; B opens a gathering-farm exploit) |
| **D4 free buy-in** | **Confirm** — `buy_in ⇒ not free` (enforced as a changeset rule) |
| **Rake (Arm C)** | **Forward** — the `BNK` rake (cm.5+), not a launch gate |
| **`gold_multiplier`** | **Removed** (`D-16` — backend/canon drift, absent from the product) |

**The launch Golden Room:** a buy-in (keys priced in USD) + a per-guess fee → a **buy-ins-only** pool → gather
**10** distinct guessers → a live timed round → a **live-proportional** top-K payout; never-fills refunds the
buy-ins exactly-once. The design phase is complete; the canonical-spec reconcile + the engine build follow.
