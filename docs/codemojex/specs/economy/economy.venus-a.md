# Codemojex · The Golden Room Economy — Venus-A arms (the platform-sustainability lens)

> The **platform-sustainability** half of the architect's-approach multi-architect debate
> ([`docs/aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) §The multi-architect debate),
> staged against Venus-B (the player-value / growth lens). The fork surface is
> [`economy.md`](economy.md); the locked model is `D-11` and is **not** re-litigated. Each open decision's
> arms are argued in the four ordered parts (**Rationale · 5W · Steelman · Steward**), then **ranked from this
> lens**, with the strongest growth-lens objection **pre-empted**. This doc **surfaces**; it does not decide
> (the agent surfaces forks, the Operator rules).
>
> **Binding reconcile honored.** `gold_multiplier` is removed (verified `T-9`: present in the backend
> `schemas/room.ex:21`/`game.ex:35`/`migration:67,100`/`economy.ex:35`, **absent** from the real product
> `node/codemoji-app/src` — grep exit 1). The pool has **no ×boost**; the ×boost pool arms from
> `codemojex-golden-calibration.economy.design.md §4` are **superseded** and argued by no one. `golden:true` is
> a tournament marker.
>
> **The lens in one sentence.** A real-money pari-mutuel tournament is sustainable only if the platform's
> per-round expected outflow is bounded and its margin is structural — so this lens reads every arm by its
> **exposure** (capital the platform can lose), its **margin** (the only durable revenue in a peer-funded
> pool), and its **multi-year freeze cost** (a money surface, once public, is the most expensive kind to keep).

---

## The sustainability frame (what this lens optimizes, before the arms)

Three quantities decide whether a Golden Room is a business or a liability:

1. **Exposure** — the platform capital at risk in one round. Buy-ins are *player* money (pass-through, zero
   platform exposure); a **seed** is *platform* money paid into the pool whether or not the round profits.
   With `gold_multiplier` removed, the seed is now the **only** platform-funded pool input — so the seed is the
   entire exposure question.
2. **Margin** — the platform's structural take. Per-guess fees are already platform revenue (`D-11`), but they
   are a *volume* lever (they scale with tapping, not with the stake). The **rake** is the only lever that
   scales with the **pool** — the pari-mutuel house edge. Without it the Golden Room's only margin is the
   per-guess fee, which a thin-but-fast field can make trivial relative to the prize.
3. **Freeze cost** — every money path, once shipped, is a multi-year liability: it must be frozen, tested,
   reconciled, and reasoned about under partition and retry. The `Do no harm` / `Thin but robust` values
   ([aaw.framework.md], Values) price a new money invariant high. A seed adds a payout-accounting invariant; a
   rake adds a margin-accounting invariant **and** a disclosure obligation.

The leaderboard already lives in Valkey (`board.ex`), settlement is already exactly-once under
`SET cm:<game>:closed NX` (`rooms.ex:181`), and the pool is already a `games` column read from Postgres
(`rooms.ex:199`, `view.ex:61`) — so each arm below is priced as a *delta* on a substrate that already exists,
not a greenfield build.

---

## Decision 1 — Pool composition

Buy-ins fund the pool (`D-11`). Open: does the platform also **seed**, and is a **published rake** taken?
(No boost.) Three arms: **A** `Σ buy_ins` · **B** `seed + Σ buy_ins` · **C** `(seed + Σ buy_ins) − rake`.

### Arm A — Buy-ins only (`pool = Σ buy_ins`)

**Rationale.** A pure peer-funded tournament: the prize is exactly what the field staked, so the platform's
pool exposure is **zero** by construction. It answers the sustainability need at its root — the platform cannot
lose money on a round it does not fund — while keeping a real, growing prize (the buy-ins) that the hard-10
floor guarantees is non-trivial (≥10 stakes).

- **Why** — to make the Golden Room a business with no downside tail: the platform never pays more out of the
  pool than players paid in.
- **What** — a pool that is the sum of the buy-ins charged at join, funded entirely by `Wallet.buy_in/3`
  crediting `games.prize_pool` (forward; the ratified two-sided op).
- **Who** — the platform (carries no pool exposure); the field (funds its own prize); the top finishers (paid
  the proportional split, `economy.ex:62` `top_k_split`).
- **When** — launch. It is the lowest-substrate arm: `seed_pool` defaults to 0 for a Golden Room, and no rake
  path is built (the `BNK` bank stays forward, `roadmap.md:248`).
- **Where** — `games.prize_pool` (`migration:94`), incremented by the buy-in; `effective_pool/3` collapses to
  the identity once `gold_multiplier` is removed (`economy.ex:36` already returns `pool` for the non-boost
  clause), so the close path reads the raw sum.

**Steelman.** Zero pool exposure is the single most valuable property a real-money launch can have. The hard-10
floor (the ratified `:gathering` gate) already guarantees the prize is the sum of **at least ten** real stakes,
so "the prize is too small" is bounded away — a 10-player room at a 50-key buy-in is a 500-key prize with the
platform risking nothing. Margin still exists without a rake: the **per-guess fee is platform revenue**
(`D-11`) and an all-pay tournament is guess-intensive by design (players re-submit to climb the live board,
`game.ex` re-enqueues each guess), so volume margin accrues precisely because the format rewards more attempts.
The never-fills refund is **cleanest here** — refund `Σ buy_ins`, no seed to claw back, no rake already taken
to reconcile (`close_void`, the partial unique index, `T-9`). And the regulatory surface is the **smallest**:
a pool that is exactly the players' stakes, paid back to players, with a disclosed per-guess fee, is the most
defensible shape under the paid-entry-prize-pool classification the design already flags
(`design.md:250`).

**Steward.** What it costs to keep is **the least of the three** — it adds **no** new pool-funding invariant
(the pool is just the buy-in sum) and **no** disclosure obligation beyond the buy-in and the fee. It honors
`Thin but robust` (one money input, the buy-in) and `One authority` (the pool is the buy-in ledger, nothing
else). The multi-year liability is a single accounting identity: `pool == Σ(buy_in TXN for this game) −
Σ(buy_in_refund TXN)`, reconcilable against the `transactions` table (`transaction.ex`) with no seed or rake
term. The honest weakness: with **no rake**, the only margin is the per-guess fee, so if a future product
decision makes guesses cheap or capped, the Golden Room's margin can thin to near-zero — but that is a *future*
lever the Operator still holds (the fee is a room prop, `guess_fee`, `schemas/room.ex`), not a debt baked in
now.

### Arm B — Seed + buy-ins (`pool = seed + Σ buy_ins`)

**Rationale.** A platform-seeded floor guarantees a headline prize even when the field is exactly at the floor,
making the room marketable before it fills. It answers a *growth* need (a visible, guaranteed prize draws the
crowd) at a *sustainability* cost (the seed is platform capital at risk every round).

- **Why** — to advertise a guaranteed minimum prize that does not depend on the field's size.
- **What** — a pool seeded at room creation (`seed_pool`, already a prop, `schemas/room.ex`, `rooms.ex:33`)
  plus the buy-ins.
- **Who** — the platform (funds the seed, carries the exposure); the field (adds to it).
- **When** — launch, if a guaranteed headline number is a launch requirement.
- **Where** — `seed_pool` snapshot onto `games.prize_pool` at start (`rooms.ex:97` already seeds the pool from
  `room.seed_pool`), then buy-ins increment it.

**Steelman.** The seed is the lever that lets the room be *advertised* — "win 1000 keys" reads on the lobby card
(`03-rooms.md` the Golden Room screen) regardless of whether 10 or 100 players join, and the platform-seeded
pool is already the **shipped** behavior for every room (`rooms.ex:97`), so this arm is the **lowest-code**
change (buy-ins simply add to a pool that is already seeded). For a launch trying to bootstrap a cold field,
the guaranteed floor is the difference between a room that fills and one that stalls at 9.

**Steward.** The cost to keep is a **standing platform liability per round**: the seed is paid into the pool and
distributed whether or not the per-guess volume covers it, so every Golden Room is a small negative-EV bet for
the platform unless the fee volume exceeds the seed. With `gold_multiplier` removed the seed is now the
*entire* exposure (no multiplier amplifies it, but none caps the count of rooms either) — so the multi-year
risk is **unbounded room count × seed**, governed only by operational discipline (how many seeded rooms run).
It adds one new invariant the refund must honor: on never-fills, the seed is **not** refunded to players (it
returns to the platform), so `close_void` must distinguish seed from buy-ins in the pool — a more complex
refund than Arm A's single sum. `Do no harm`: a seeded pool that pays out to a thin colluding field (10
accounts splitting a platform-seeded prize) is an anti-abuse hole the seed *funds*. Defensible, but the
steward prices the seed as recurring exposure, not a one-time cost.

### Arm C — (Seed + buy-ins) − rake (`pool = (seed + Σ buy_ins) − rake`)

**Rationale.** A **published** platform rake — the pari-mutuel house edge — is the only pool input/output that
gives the platform a margin **scaling with the stake**, not just guess volume. It answers the sustainability
need directly: a transparent rake is the structural margin that makes a real-money tournament a durable
business, and `design.md:249` already names "a published rake" as the recommended transparent margin lever.

- **Why** — to take a disclosed, pool-proportional margin so the platform's revenue scales with the prize, not
  only with tapping.
- **What** — a rake (a published % or fixed cut) deducted from the pool at settlement before the proportional
  split; the remainder pays the board.
- **Who** — the platform (takes the rake as margin); the field (funds the gross pool); the top finishers (split
  the net).
- **When** — `cm.5+`, with the `BNK` bank — this is the **forward** treasury system (`roadmap.md:123,248-249`,
  `roadmap.md:282` the LiveAdmin treasury), **not** a launch-ready surface.
- **Where** — forward: a `BNK` escrow (`roadmap.md:59`) holds the gross pool, the rake is taken at the close
  before `top_k_split`, and the remainder is the `pool` argument to `economy.ex:62`. Today the pool lives on
  `games.prize_pool` (`roadmap.md:248`) with no rake term.

**Steelman.** The rake is the **only** arm that makes the Golden Room's margin a function of the money at stake.
A pari-mutuel pool with no house edge is a charity tournament — the platform's entire upside is the per-guess
fee, which a careful player minimizes (fewer, better guesses) exactly when the prize is largest. A published
rake (say 5–10%, the Operator's number) is transparent by construction (`design.md:249` "transparent margin
levers" — disclosed, not hidden house players), scales with the field, and is the model the roadmap **already
schedules** (`B7.5.3`: "a published platform rake is taken and the remainder pays the board",
`roadmap.md:123`). It also *bounds* the seed risk of Arm B: a rake on a seeded pool recoups the seed as the
field grows, turning Arm B's standing liability into a self-funding floor.

**Steward.** The cost to keep is the **highest** of the three, and it is the reason this lens still does not rank
it first **for launch**: a rake is a new money invariant (`net = gross − rake`, audited), a new ledger reason
and accounting line, **and** a disclosure/regulatory obligation (a published rake is a stated term the
classification review must bless, `design.md:250`). Critically, it depends on the **forward `BNK` bank**
(`roadmap.md:248` "today the pool lives on the game's own `prize_pool`") — so shipping the rake at launch means
building the treasury system first, which **defers the Golden Room behind a `cm.5+` epic**. `Thin but robust`
and `Do no harm` both argue against launching a half-built treasury for a margin the per-guess fee can carry at
first. The rake is the **right multi-year answer** and the wrong launch dependency: it is where sustainability
ultimately lives, but it is earned *after* the room ships, not as its gate.

### Decision 1 — ranking (platform-sustainability lens) + growth-lens pre-emption

| Rank | Arm | Pool exposure | Structural margin | Freeze cost | Launch-ready |
|---|---|---|---|---|---|
| **1** | **A — buy-ins only** | **zero** | per-guess fee only | **lowest** | **yes** |
| **2** | **C — minus rake** | seed (if any) | **rake (pool-scaling)** | highest | **no** (forward `BNK`) |
| **3** | **B — seed + buy-ins** | **seed, every round** | per-guess fee only | medium | yes |

**Ranked recommendation (advice, not a decision):** **A for launch, C as the scheduled successor, B only if a
guaranteed headline prize is a hard launch requirement.** A gives the platform a real-money room it cannot lose
money on, with the smallest regulatory and freeze surface; C is where durable margin lives but it is a
forward-`BNK` dependency that should not gate the launch; B buys a marketing number at a standing per-round
exposure that, **without a rake (C) to recoup it**, is pure cost. The sequence **A → (A+C) → optionally +B**
lets the room ship safe, then add the pool-scaling margin, then add a seed only once the rake can fund it.

**Pre-empting the growth lens (Venus-B).** Venus-B will argue **B** (or B-without-rake): a seeded, guaranteed,
boost-feeling prize is the strongest crowd-draw, and a cold launch needs a headline number to fill the first
rooms — a buy-ins-only pool at launch can look small until the field grows, which is exactly when growth is
most fragile. The rebuttal from this lens: the **hard-10 floor already guarantees the pool is ten real stakes**
(the prize is never "empty"), so the marketable number is the **buy-in × 10** floor, not zero; the platform can
advertise "from N keys" honestly without funding a seed. And the growth case for a seed is *strongest* paired
with the rake (C) that recoups it — so the growth lens's own argument points at **C over bare B**, converging
with this lens on "a seed is only sustainable with a rake." If the Operator wants the guaranteed-prize draw,
the sustainable form is **A now, B+C together later** — never a seed without the rake to fund it.

---

## Decision 2 — The USD rail

How is a "USD-configured" buy-in collected? **A** keys priced in USD (charge keys) · **B** a direct Telegram
Stars invoice at join.

### Arm A — Keys priced in USD (`buy_in_usd` resolves to a keys debit)

**Rationale.** USD is the *pricing/display* unit; the buy-in is *collected in keys* at the fixed key↔USD rate
(`economy.ex:11` `@cents_per_diamond`, the existing peg). It answers the "configurable in USD or Keys" need
with **no new payment rail** — the player already buys keys with Stars (`wallet.ex:108` `purchase_keys`), so the
buy-in is a keys debit the wallet already supports.

- **Why** — to price a buy-in in USD for operators/marketing while collecting in the currency the wallet
  already moves.
- **What** — a pure `Economy.keys_for_usd/1` (forward) converting a USD-configured buy-in to a keys amount;
  `Wallet.buy_in/3` debits `:keys`.
- **Who** — the platform (configures in USD or keys); the player (pays keys they already hold or top up via the
  existing Stars→keys path).
- **When** — launch. It reuses the entire shipped purchase path; the only new surface is one pure conversion
  function.
- **Where** — `economy.ex` (the pure converter, beside `keys_from_diamonds/1` at `economy.ex:16`); the buy-in
  props `buy_in_usd`/`buy_in_keys` on `rooms`/`games` (forward).

**Steelman.** This arm ships the Golden Room **now** with no commerce dependency. The Stars→keys rail is shipped
and tested (`wallet.ex:108`), the key↔USD peg is shipped (`economy.ex:11`), and the buy-in becomes a keys debit
inside the already-ratified two-sided `Wallet.buy_in/3` — so the USD configurability is a *display* concern, not
a payment-integration concern. From the sustainability lens this is decisive: it adds **zero** new external
failure surface (no payment webhook to make idempotent, no `OTX`/`WHK` to freeze), and the money path stays
inside the one wallet whose transactional discipline (`SELECT FOR UPDATE` + paired `TXN`, `wallet.ex:158-217`)
is already proven. The freeze cost is one pure function.

**Steward.** The cost to keep is **minimal** — a pure converter has no state, no partition behavior, and one
obvious test (the peg). It honors `Thin but robust` (no new rail) and `One authority` (keys remain the single
spend currency). The honest weakness: it couples the buy-in's real-world price to the **fixed** key↔USD peg
(`economy.ex:11` is a compile-time constant), so a USD-priced buy-in drifts from true USD if the peg is ever
re-set — but that is a known property of the existing economy (every USD figure in the game is pegged the same
way, `economy.ex:22` `to_usd`), not a new debt. Multi-year, it ages exactly as the rest of the keys economy
ages.

### Arm B — Direct Stars invoice at join

**Rationale.** A "USD" buy-in is a **real** Telegram Stars charge at join, settled outside the keys wallet — the
buy-in is genuine money, not pre-purchased keys. It answers the need for a true fiat-denominated entry.

- **Why** — to charge real money per entry rather than spend pre-bought keys.
- **What** — a Stars invoice raised at join, confirmed by the payment webhook before the player is admitted.
- **Who** — the platform (operates the commerce system); the player (pays Stars at the door).
- **When** — `cm.5+` — it needs the forward commerce build.
- **Where** — the forward `PKG`/`ORD`/`OTX`/`WHK` brands (`roadmap.md:254-257`), all 📋 unbuilt: an order, a
  payment-transaction ledger, and an idempotent webhook.

**Steelman.** A direct invoice is the *honest* fiat rail — the buy-in is exactly the money it claims, with no
peg drift, and it produces a clean `OTX` payment record per entry. For a high-stakes tournament where the
buy-in is the headline, charging real money at the door (rather than abstracting through keys) is the model a
mature commerce platform converges on.

**Steward.** The cost to keep is **large and external**: a payment webhook is the hardest kind of money surface
to make correct — it must be idempotent under Telegram's at-least-once delivery (`WHK` "idempotent, processed
once", `roadmap.md:257`), reconciled against `ORD`/`OTX`, and recovered on partial failure. From the
sustainability lens this is the **worst launch choice**: it puts a brand-new, externally-driven, money-critical
surface on the Golden Room's *entry* path, and it **defers the launch behind the entire commerce epic**
(`roadmap.md:254-257`). It is the right rail for a commerce-mature product and the wrong rail to gate a launch
on.

### Decision 2 — ranking + growth-lens pre-emption

| Rank | Arm | New external surface | Launch-ready | Freeze cost |
|---|---|---|---|---|
| **1** | **A — keys priced in USD** | **none** | **yes** | one pure function |
| **2** | **B — direct Stars invoice** | a payment webhook + `OTX`/`WHK` | **no** (forward commerce) | high (idempotent webhook) |

**Ranked recommendation:** **A for launch, B as the forward commerce successor.** A reuses the shipped Stars→keys
rail and adds one pure converter; B is the honest fiat rail but is a `cm.5+` commerce dependency that should not
gate the Golden Room.

**Pre-empting the growth lens.** Venus-B may favor **B** for a frictionless "pay at the door" entry (no
pre-buying keys is a smoother funnel, and a real-money buy-in feels weightier — a growth signal). The rebuttal:
the smoother funnel is illusory at launch because **B does not exist** (`roadmap.md:254-257` all 📋), so
choosing it *delays* every player behind the commerce build — the opposite of growth. Arm A's "top up keys, then
enter" is one extra step on a **shipped** path; the right growth sequence is **A now** (ship the room, grow the
field) **→ B later** (smooth the funnel once commerce exists). Both lenses converge on A-for-launch; they differ
only on how soon B is worth building, which is a scheduling question for the Operator, not a launch fork.

---

## Decision 3 — Refund scope (never-fills) + Decision 4 (confirm)

On never-fills (the hard-10 floor never met), what is refunded? **A** buy-ins only · **B** buy-ins + gathering
per-guess fees. Plus **D4**: enforce `buy_in ⇒ not free`.

### Arm A — Refund buy-ins only

**Rationale.** A tournament that never legally began owes back the **entry stake** (the buy-in), but the
per-guess fees bought a **delivered service** (a scored guess, live feedback, a board position during
gathering) and are platform revenue (`D-11`). It answers the never-fills obligation precisely: refund the
money that bought nothing (entry), keep the money that bought something (each scored guess).

- **Why** — to refund the stake for a contest that never ran, while keeping revenue for services rendered.
- **What** — `close_void` credits back each `buy_in` TXN for `ref = game`, exactly-once + resumable (the
  partial unique index on `transactions(player, ref) WHERE reason = 'buy_in_refund'`, ratified `T-9`).
- **Who** — the platform (refunds stakes, retains fees); the players (get their buy-in back).
- **When** — launch (it is the ratified never-fills design).
- **Where** — `close_void` (forward, ratified) reading the `buy_in` TXN rows (`transaction.ex`), the ledger as
  authority.

**Steelman.** Refund-buy-ins-only is the **cleanest, most defensible** never-fills rule and the **cheapest to
make correct**. The buy-in is unambiguously owed (the tournament never began); the per-guess fee is
unambiguously earned (the guess was scored, the player saw the live board, `game.ex` published the `scored`
event). Refunding only the buy-ins keeps `close_void` to **one** refund class (one reason, one idempotency
index), which is the difference between a resumable-exactly-once refund Apollo can verify and a two-class refund
that doubles the failure surface. From the sustainability lens it also **preserves the volume margin**: the
per-guess fees collected during a long gather are retained, so a room that gathered to 9 and timed out is not a
total platform loss — the fees for every guess made still accrued.

**Steward.** The cost to keep is the **lower** of the two: one refund reason, one partial unique index, one
ledger-authoritative loop. It honors `Do no harm` (refund what is owed, no more) and `Thin but robust` (one
refund class). The honest weakness: a player who paid the buy-in **and** made many guesses in a room that never
started gets only the buy-in back — which is *correct* by the delivered-service principle but may *feel* unfair
to a heavy gatherer. That is a product-communication issue (state the rule up front), not a correctness debt.

### Arm B — Refund buy-ins + gathering per-guess fees

**Rationale.** Maximal fairness: a room that never started should leave **no** player out of pocket, so refund
both the entry stake and every per-guess fee charged during gathering. It answers a fairness intuition (nobody
pays for a tournament that did not happen).

- **Why** — to make a never-fills room financially harmless to every participant.
- **What** — `close_void` refunds the `buy_in` TXNs **and** the gathering `guess` TXNs for `ref = game`.
- **Who** — the platform (refunds both, retaining nothing); the players (made whole).
- **When** — launch, if maximal fairness is the chosen rule.
- **Where** — `close_void` with **two** refund classes (a `buy_in_refund` and a `guess_refund`), each
  exactly-once.

**Steelman.** Refunding everything is the most generous, most goodwill-preserving rule — a player who funded a
room that never ran walks away whole, which is the strongest retention message after a failed gather. It removes
any "I paid to tap in a room that never started" complaint entirely.

**Steward.** The cost to keep is **higher and the value-leak is real**. It contradicts `D-11`'s ruling that
**per-guess fees are platform revenue** (the fee bought a scored guess — a delivered service — whether or not
the round later started), so it re-opens a locked decision. It **doubles** the refund machinery: two reasons,
two idempotency indices, two resumable loops in the most money-critical path (`close_void`), which is exactly
where Apollo's exactly-once-and-resumable gate is hardest. And it creates an **anti-abuse hole**: a bot can join
a deliberately-thin room, farm scored guesses (which during gathering are a free service if refundable), and
get every fee back when it never fills — turning the all-pay anti-abuse property (`design.md:188`, blind farming
has negative EV) into a *zero-cost* farm during gathering. From the sustainability lens this is the decisive
mark against B: it converts a revenue stream into a refundable liability **and** opens a farming vector.

### Decision 3 — ranking + growth-lens pre-emption

| Rank | Arm | Refund classes | Honors `D-11` | Anti-abuse | Freeze cost |
|---|---|---|---|---|---|
| **1** | **A — buy-ins only** | one | **yes** | preserves all-pay edge | **lower** |
| **2** | **B — buy-ins + fees** | two | **no** (re-opens `D-11`) | opens a gathering farm | higher |

**Ranked recommendation:** **A — refund buy-ins only.** It is the only arm consistent with the locked
per-guess-revenue ruling, it keeps `close_void` to one verifiable refund class, and it preserves the all-pay
anti-abuse property during gathering. B's extra goodwill is real but is bought with a re-opened decision, a
doubled money surface, and a farming hole.

**Pre-empting the growth lens.** Venus-B may argue **B** for retention — a player burned by a failed gather is a
player who churns, and a full refund is the strongest "we made it right" signal. The rebuttal: the retention
win is **bounded** (gathering fees on a never-filled room are small — a room that never reached 10 saw limited
play) while the cost is **structural** (a re-opened ruling, a doubled refund surface, and a farming vector that
*scales*). The growth-safe way to address the burned-gatherer is **product communication** (state "per-guess
fees are non-refundable; your buy-in is fully refunded if the room does not fill" up front) and the **buy-in
refund itself** (Arm A already makes the stake whole) — not converting revenue into a refundable, farmable
liability. The two lenses converge once the farming vector is priced: a refundable gathering fee is a feature
bots exploit faster than humans appreciate.

### Decision 4 — `buy_in ⇒ not free` (confirm)

**Recommendation: confirm and enforce** as a changeset rule (the `Codemojex.Schemas.Room` changeset,
`schemas/room.ex:29`). A buy-in is real money; a free room charges **clips**, which carry **no economic value**
and are excluded from the available balance (`design.md:127`, `01-currency-model.md`). A buy-in funding a pool
that pays out **clips** would be real money in, worthless currency out — an incoherent and likely
non-compliant economy. The launch config already sidesteps it (the warm-up "Бокс для разминки" is free **and**
has no buy-in; the Golden Room is paid **and** has a buy-in), so enforcing `buy_in ⇒ not free` is a guardrail
that codifies the intended pairing with no launch impact. This is the sustainability lens at its simplest: do
not let real money flow into a valueless-payout pool. (Apollo's un-prompted finding; this lens concurs without
reservation.)

---

## Summary — the platform-sustainability ranking across all decisions

| Decision | Rank 1 (this lens) | Rank 2 | Rank 3 | The one reason for Rank 1 |
|---|---|---|---|---|
| **D1 — pool** | **A buy-ins-only** | C minus-rake | B seed+buy-ins | zero pool exposure; smallest regulatory + freeze surface; the hard-10 floor already guarantees a real prize |
| **D2 — USD rail** | **A keys-in-USD** | B direct Stars | — | no new external money surface; reuses the shipped Stars→keys path |
| **D3 — refund** | **A buy-ins-only** | B + fees | — | the only arm consistent with `D-11`; one verifiable refund class; preserves the all-pay edge |
| **D4 — free rule** | **confirm `buy_in ⇒ not free`** | — | — | real money must not fund a valueless-payout pool |

**The through-line.** This lens favors the **lowest-exposure, lowest-freeze-cost, launch-ready** arm in every
decision, and schedules the **margin-bearing** surface (the rake, C) and the **honest-fiat** surface (the
direct invoice, B) as **forward `cm.5+` successors** rather than launch gates. The sustainable launch shape is:
**buy-ins-only pool, keys-priced-in-USD entry, buy-in-only refund, no free buy-in rooms** — a Golden Room the
platform cannot lose money on, on a money surface small enough to freeze and verify — with the rake (where
durable margin ultimately lives) added once the room has shipped and the `BNK` treasury is built.

**Where this lens and the growth lens converge (a gift to the synthesis):** both rank **A** for the USD rail
(B does not exist yet), and both — once the rake is priced — point at **C over bare B** for the pool (a seed is
sustainable only with a rake to recoup it). The genuine divergence the Operator must rule is **D1 launch pool**
(this lens: A buy-ins-only, zero exposure; the growth lens will likely press B's guaranteed headline prize) and
**D3** (this lens: A, revenue-preserving; the growth lens may press B's full-refund goodwill). Those two are the
real forks; the rest is scheduling.

---

## Grounding ledger (every named surface — verified or forward)

- `gold_multiplier` removed: backend present (`schemas/room.ex:21`, `game.ex:35`, `migration:67,100`,
  `rooms.ex:40,108,198,225`, `economy.ex:35`), **product absent** (`node/codemoji-app/src`, grep exit 1) — `T-9`.
- `Economy.top_k_split` (the proportional payer) — `economy.ex:62`, tested `economy_story_test.exs:66-121`.
- `effective_pool/3` collapses to identity without boost — `economy.ex:36`.
- The pool is a `games` column, Postgres-read — `migration:94`, `rooms.ex:199`, `view.ex:61`.
- The Stars→keys rail + the key↔USD peg — `wallet.ex:108`, `economy.ex:11`/`:22`.
- The transactional wallet (the buy-in's discipline) — `wallet.ex:158-217`.
- The exactly-once close lock — `rooms.ex:181`.
- Free-room clips carry no value — `design.md:127`.
- The published rake / `BNK` bank (forward) — `roadmap.md:123,248-249,282`; the transparent-margin recommendation
  `design.md:249`.
- The forward commerce brands (`PKG`/`ORD`/`OTX`/`WHK`) — `roadmap.md:254-257`.
- Forward (Mars builds): `Wallet.buy_in/3`, `Economy.keys_for_usd/1`, `close_void`, the `buy_in`/`buy_in_refund`
  TXN reasons + the partial unique index, the `buy_in_usd`/`buy_in_keys` props — all per the ratified
  `economy.design.md` + `economy.md`.
