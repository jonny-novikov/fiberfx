# Codemojex · The Golden Room Economy — Venus-B (the player-value / growth lens)

> The **player half** of the architect-approach multi-architect debate
> ([`docs/aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) §"The multi-architect debate").
> The decision surface + the locked model are `docs/codemojex/specs/economy.md`; this doc argues the **same
> arms** from a divergent lens, ranks them, and pre-empts the opposing (platform-sustainability) lens so the
> Director's synthesis inherits a rebuttal already on the page. Venus-A argues the maintainer/sustainability
> view; this is the consumer's view. The Director stages the divergence; the Operator rules.
>
> **The lens — player value / growth.** Every arm is weighed by: the player's *perceived* prize value (does
> the number on the scoreboard feel big and real?), trust + fairness (is the economy candid, or does it feel
> like the house is taking a cut they can't see?), the all-pay psychology (every guess is a sunk fee — does
> the structure make that feel like competition or like a slot machine?), virality + retention (does a win
> generate a shareable moment and a reason to return?), and whether the prize feels *worth the buy-in*.
>
> **NO-INVENT.** Every named surface is grounded at a real `file:line` in `echo/apps/codemojex`, or written
> forward-tense for surface not yet built. An arm resting on an invented module is disqualified before it is
> argued. **Framing:** no first person, no perceptual or interior-state verbs applied to software, no
> gendered pronouns.

---

## 0. The binding reconcile this doc argues under (NOT re-litigated)

`gold_multiplier` is **REMOVED** (`economy.md` §2, ledger `D-11`). The `× mult` in `Economy.effective_pool/3`
(`economy.ex:34-36`) is drift — it propagated into the backend + the canon but is **absent from the real
product** (`node/codemoji-app`, grep-confirmed, `economy.md:32`). The tournament pool has **no boost
multiplier**; `golden:true` marks a tournament room (a one-time **buy-in** + a **hard 10-player gather-gated
start** + a **live-proportional payout** among the top finishers via `settlement:"live_split"` /
`economy:"proportional"`, reusing `Economy.top_k_split/3` `economy.ex:62`). The **× boost arms are struck**
from every decision below. Buy-ins fund the pool; per-guess fees are platform revenue.

**The player-lens consequence of the reconcile (stated once, up front).** Removing the multiplier removes the
*one* thing that made the prize look bigger than the sum of what players staked. A boosted pool reads to a
player as *"the house is adding to my prize"* — generous, low-suspicion. A pure buy-in pool reads as *"I am
playing my neighbors for the pot"* — honest, but the headline number is now bounded by the field. **So the
player-value burden shifts entirely onto pool composition (Decision 1): with no boost, the seed is the only
remaining lever that makes the prize feel bigger than the buy-ins.** This is the through-line of the ranking
below.

---

## A. Decision 1 — Pool composition (the player-value core)

**Context.** Buy-ins fund the pool (`D-11`). Open: does the platform also **seed** the pool, and is a
**published rake** taken? No boost (`gold_multiplier` removed). The three corrected arms — pool formula in
`economy.md:48-50`:

- **A — Buy-ins only:** `pool = Σ buy_ins`.
- **B — Seed + buy-ins:** `pool = seed + Σ buy_ins`.
- **C — (Seed + buy-ins) − rake:** `pool = (seed + Σ buy_ins) − rake` (a published rake, the roadmap `BNK`
  model, forward).

### Arm A — Buy-ins only

- **Rationale.** A pure peer-funded tournament: the prize is exactly what the field staked, the platform
  funds nothing into the pool, and the economy is maximally legible (`pool = Σ buy_ins`, a player can compute
  the prize from the player count and the buy-in). It answers the candor need at the lowest platform cost.
- **5W.**
  - **Why** — the most honest possible pool: no house money, no house cut; what you see staked is what is
    paid out.
  - **What** — `pool = Σ buy_ins`; at the 10-player floor with a buy-in of *b*, the prize is exactly `10·b`.
  - **Who** — the player funds it entirely; the platform's only revenue is the per-guess fee (`charge_guess`
    debiting `:keys`, `wallet.ex:98-105`).
  - **When** — launch-ready; needs only the buy-in debit (reusing the `Wallet` debit path, `wallet.ex:158`)
    and the proportional split (`Economy.top_k_split/3`, `economy.ex:62`), both extant.
  - **Where** — the pool accumulates as buy-ins are charged at join/gather; settled by the live-proportional
    rule at close.
- **Steelman (player-value).** The prize is *self-evidently fair* — a player who distrusts "house odds" can
  verify the pot is exactly the staked sum, which is the strongest possible answer to the all-pay suspicion
  ("am I feeding a machine that pays back less than it takes?"). Because per-guess fees are *revenue, not
  pool*, the all-pay structure is honestly framed: the buy-in buys a seat at a peer pot, the per-guess fee
  buys attempts — two separable purchases, neither hidden. For a community/Telegram audience that prizes
  candor, "you are playing each other, we just run the table" is a *more* shareable story than "we boosted
  your prize" once the boost is gone.
- **Steward.** Honors **One authority** and **Thin but robust** best of the three — zero seed accounting,
  zero rake config, the smallest money surface to freeze and test. Its long-game player cost: at a thin field
  (exactly 10), the prize is small, so the *headline* prize a new player sees in the lobby is small, which is
  the weakest possible acquisition hook. With the multiplier gone, Arm A has **no lever at all** to make the
  prize look bigger than the field — the very problem the reconcile created lands hardest here.

### Arm B — Seed + buy-ins

- **Rationale.** A platform-seeded floor guarantees a real, advertisable prize even when the field is thin
  (but ≥10). It answers the *acquisition* need the reconcile sharpened: with the boost gone, the seed is the
  only remaining way to put a number on the lobby card that exceeds the staked sum.
- **5W.**
  - **Why** — a guaranteed prize floor draws the crowd a tournament needs; the seed is the promotional spend
    that replaces the (removed) multiplier as the "platform adds value" signal.
  - **What** — `pool = seed + Σ buy_ins`; the prize is never smaller than `seed`, and grows with the field.
  - **Who** — the platform funds the seed (a promotional cost, bounded by the seed, not the field); players
    add the buy-ins.
  - **When** — launch-ready; the `seed_pool` prop already exists on the room/game (`rooms.ex:33,97`) — the
    seed is *already* how the pool is funded today, so this arm is the smallest change from the shipped base.
  - **Where** — `seed_pool` snapshotted onto the game at start (`rooms.ex:97`), the buy-ins added as they are
    charged.
- **Steelman (player-value).** This is the arm the player lens *prefers*, and the reason is the reconcile:
  **the seed is the last surviving mechanism that makes the prize feel bigger than the buy-ins.** A lobby
  card reading "Prize pool: $50 guaranteed, growing" is a real acquisition hook; "$10 if exactly ten play" is
  not. The seed reads to the player exactly as the boost used to — *"the platform is putting real money on the
  table"* — but it is **candid in a way the multiplier never was**: a seed is a stated, fixed floor (a number
  the room advertises up front), whereas the multiplier was an opaque "×3 at close" the real product never even
  showed. So Arm B *recovers the boost's acquisition value while improving its honesty*. It also de-risks the
  cold-start: a brand-new Golden Room with a seed has a prize worth gathering 10 people for; a buy-ins-only
  room is a chicken-and-egg (no one buys in until the pot is big, the pot is not big until people buy in). The
  seed breaks that deadlock — directly serving virality + retention (a seeded room is worth sharing on day
  one).
- **Steward.** Honors **Grounded** — `seed_pool` is the *current* funding model (`rooms.ex:33,97`), so Arm B
  adds the least new surface (no rake math). Its honest long-game cost is the one Venus-A will press: the seed
  is a recurring, unbounded-in-aggregate promotional outflow with **no offsetting pool revenue** (per-guess
  fees are revenue, but they do not refill the seed). The platform funds every seeded pool's floor out of
  pocket, every game, forever. The player lens accepts this cost as the *price of the acquisition hook the
  reconcile otherwise removed* — but it is a real liability the Operator must price, not wave away.

### Arm C — (Seed + buy-ins) − rake

- **Rationale.** A published platform rake funds a transparent, sustainable margin while still seeding a floor
  — the roadmap `BNK` model (forward). It answers *both* the acquisition need (the seed) and the
  sustainability need (the rake), at the cost of taking a visible cut of the prize.
- **5W.**
  - **Why** — a sustainable margin so the seed is not a pure outflow; the rake is the platform's cut, stated
    up front.
  - **What** — `pool = (seed + Σ buy_ins) − rake`; the board is paid the remainder.
  - **Who** — the platform funds the seed and takes the rake; the player funds the buy-ins and *bears* the
    rake (the prize is smaller by the rake than the staked + seeded sum).
  - **When** — forward — the rake needs the `BNK` bank model (`economy.md:50`, roadmap), so this arm **defers
    the Golden launch** behind a revenue-accounting build not yet present.
  - **Where** — a rake deduction at settlement, before the proportional split (`Economy.top_k_split/3`,
    `economy.ex:62`), with the rake recorded against the forward `BNK`.
- **Steelman (player-value).** A *published* rake is the candid form of a house cut: the player sees "platform
  fee: X%" up front, the same way every poker room and every regulated betting product states its rake. Candor
  is the player-trust win here — a stated rake is *more* trustworthy than the silent margin a buy-ins-only +
  per-guess-fee model already takes (where the "fee" revenue is real but never framed as a cut of the player's
  spend). For a player who has played real-money skill games, a stated rake is *expected* and its absence can
  even read as "what's the catch?".
- **Steward.** Honors **Grounded** weakest of the three *for launch* — it rests on the forward `BNK` model
  (`economy.md:50`), so a Steelman that assumes the rake accounting exists is reaching past the shipped
  surface; for the launch rung this arm is forward-tense. Its player long-game cost is the sharpest: a rake
  **directly shrinks the prize the player competes for**, on top of the per-guess fees they already sink, on
  top of a buy-in. Three extractions stacked (buy-in + per-guess fee + rake) against one prize is the
  structure most likely to read as "the house always wins" — the exact all-pay suspicion the player lens most
  wants to avoid. A rake is the right *sustainability* answer and the wrong *first-impression* answer.

### Decision 1 — the fork surface (player-value ranking)

| arm | perceived prize value | trust / candor | all-pay psychology | virality / retention | launch-ready? |
|---|---|---|---|---|---|
| **B — Seed + buy-ins** | **highest** (seed floor + growth) | high (stated floor, no hidden cut) | honest (seat + attempts, plus a guaranteed floor) | **highest** (a day-one shareable prize; breaks cold-start) | **yes** (`seed_pool` extant `rooms.ex:33,97`) |
| **A — Buy-ins only** | lowest at a thin field | **highest** (pot == staked sum, verifiable) | honest (two separable purchases) | low (small headline prize; cold-start deadlock) | yes |
| **C — (Seed+buy-ins) − rake** | medium (seed up, rake down) | high IF published; risk of "what's the catch" | **worst** (buy-in + fee + rake stacked) | medium | **no** (forward `BNK`) |

**Venus-B recommendation: Arm B (Seed + buy-ins).** The one reason that carries it: **with the multiplier
removed, the seed is the only surviving lever that makes the prize feel bigger than the buy-ins — and it
recovers that acquisition value more honestly than the boost ever did** (a stated floor vs an opaque ×3). It is
also the smallest change from the shipped base (`seed_pool` is the current model, `rooms.ex:33,97`). Arm A is
the candor purist's choice but loses the cold-start; Arm C is the sustainability choice but stacks a third
extraction against the prize and is forward-tense for launch. (Recommendation, not a ruling — the Operator
rules.)

---

## B. Decision 2 — The USD rail

**Context.** Buy-ins may be denominated/charged in USD or Keys. The two arms — `economy.md:57-59`:

- **A — Keys priced in USD** (launch-ready): USD is the *pricing unit*, the charge is in Keys — a pure
  `keys_for_usd/1` (forward) reusing the existing pricing arithmetic + the Stars→keys path.
- **B — Direct Stars invoice at join**: a real Telegram Stars payment at the join boundary.

### Arm A — Keys priced in USD

- **Rationale.** The player already holds Keys (bought with Stars via `Wallet.purchase_keys/3`, `wallet.ex:108`)
  and already reads prices in USD in the lobby (`Economy.to_usd/1`, `economy.ex:24-27`). Pricing the buy-in in
  USD and charging it in Keys reuses both — no new commerce system, no new payment round-trip at the most
  fragile moment (the join).
- **5W.**
  - **Why** — collect the buy-in with the rail the player already funded, at the pricing unit they already
    read.
  - **What** — a forward pure `keys_for_usd/1` mapping the USD buy-in to a Key amount via the fixed rate
    (`1 key = $0.12`, `@cents_per_diamond 1.2` × `@diamonds_per_key 10`, `economy.ex:10-11`); the buy-in is a
    Key debit (`Wallet` debit path, `wallet.ex:158`).
  - **Who** — the player spends pre-funded Keys; the platform takes no new payment dependency at join.
  - **When** — launch-ready; the pricing arithmetic (`to_cents/1`, `to_usd/1`) + the Stars→keys credit
    (`purchase_keys/3`) both exist today.
  - **Where** — `keys_for_usd/1` in `Codemojex.Economy` (beside `to_usd/1`); the debit in `Wallet`.
- **Steelman (player-value).** This arm protects the **conversion funnel at the join** — the single most
  retention-critical moment. A player who has decided to enter a tournament and is then bounced into a
  Telegram Stars invoice (Arm B) faces a payment modal, a possible top-up, a possible failure — every step a
  drop-off. Charging pre-funded Keys is a one-tap join: the friction was paid earlier, when the player chose to
  buy Keys at their leisure, not at the high-intent instant of entering a gathering room. Fewer steps at join =
  more players reaching the 10-floor = more tournaments actually starting = the whole Golden Room loop
  *functions*. For growth, the launch-ready rail is not just cheaper to build — it is the one that does not
  leak players at the gather gate.
- **Steward.** Honors **Thin but robust** and **Grounded** — it adds one pure function over arithmetic that
  already ships, and a debit over a path that already ships. Its honest player cost: it puts a layer of
  abstraction between the player's money and the prize ("I'm staking Keys, which I bought with Stars, which
  cost USD") — a buy-in denominated in a soft currency can feel less "real" than a direct cash stake, which
  marginally dampens the high-stakes feel. The player lens accepts this: a slightly-softer stake that everyone
  can actually complete beats a hard cash stake half the field abandons at the modal.

### Arm B — Direct Stars invoice at join

- **Rationale.** A real Stars payment at join makes the buy-in unambiguously *cash* — the stake feels real,
  and the platform captures the commerce event directly (no pre-funded float to reconcile).
- **5W.**
  - **Why** — a direct, cash-real buy-in; the prize is staked in money the player feels leave their wallet now.
  - **What** — a Telegram Stars invoice raised at the join boundary, settled before the seat is granted.
  - **Who** — the player pays Stars at join; the platform operates the forward commerce surface.
  - **When** — **forward** — needs the `PKG/ORD/OTX/WHK` commerce build (`economy.md:59`), so this arm
    **defers the Golden launch** behind a payment system not yet present.
  - **Where** — the forward commerce modules + the Stars webhook; the join path gated on payment success.
- **Steelman (player-value).** The cash-real stake is the *strongest* high-stakes feel: money visibly leaves
  the wallet to enter the pot, which is the most potent version of the all-pay tension done *right* — the
  player is unmistakably competing for real money they just committed. For the segment that finds soft-currency
  buy-ins toy-like, this is the arm that makes a Golden Room feel like a real-stakes event worth bragging about
  — a stronger share ("I put $5 into the Friday tournament") than "I staked some Keys".
- **Steward.** Honors **Grounded** weakest — it is entirely forward (`PKG/ORD/OTX/WHK`, `economy.md:59`), so
  any Steelman assuming it is launch-ready overreaches. Its decisive player cost is the funnel: a payment modal
  at the highest-intent moment is the classic conversion killer, *and* it gates the entire Golden launch behind
  a commerce build — i.e. it trades a real near-term growth loop (a tournament players can actually enter
  today) for a better-feeling stake that ships later. For a launch, that is the wrong trade from the growth
  lens.

### Decision 2 — the fork surface (player-value ranking)

| arm | join-funnel friction | stake "realness" | launch-ready? | growth-loop impact |
|---|---|---|---|---|
| **A — Keys priced in USD** | **lowest** (one-tap, pre-funded) | medium (soft-currency stake) | **yes** (`to_usd/1` + `purchase_keys/3` extant) | **enables** the gather loop now |
| **B — Direct Stars invoice** | **highest** (payment modal at join) | **highest** (cash-real) | **no** (forward `PKG/ORD/OTX/WHK`) | defers the launch; leaks at the modal |

**Venus-B recommendation: Arm A (Keys priced in USD).** The one reason: **it protects the conversion funnel at
the gather gate** — a one-tap, pre-funded join is what lets a room actually reach its 10-player floor, which is
the precondition for *any* Golden Room economics to exist at all. The cash-real feel of Arm B is the better
stake but the worse funnel, and it defers the whole launch behind a commerce build. Ship the loop that works
now; Arm B is the natural Movement-II upgrade once the commerce surface lands. (Recommendation, not a ruling.)

---

## C. Decision 3 — Refund scope (never-fills) + Decision 4 (confirm)

**Context (D3).** A hard 10-player floor means a Golden Room can fail to gather (the never-fills case), at
which point it voids (`close_void`, forward) and refunds — exactly-once. Open: what is refunded?
`economy.md:63-64`:

- **A — buy-ins only:** the tournament never began; the per-guess fees bought a *delivered service* (the
  player did guess, was scored, saw the board), so the fee is earned revenue and is not refunded.
- **B — buy-ins + gathering per-guess fees:** maximal fairness — refund everything the player spent in a room
  that never became a tournament.

### Arm A — Refund buy-ins only

- **Rationale.** The buy-in bought *entry to a tournament that did not happen* → it must come back. The
  per-guess fee bought *attempts that were delivered* (validated, charged, scored, recorded — the full
  `submit → ScoreWorker` path, `game.ex:21-43` → `:103-152`) → it is earned. Refunding exactly the unfulfilled
  promise is the principled scope.
- **5W.**
  - **Why** — return the unfulfilled stake (the buy-in); keep the fee for the service rendered (the scored
    guesses).
  - **What** — on void, credit each participant their buy-in (a `Wallet` credit, mirroring `deposit_prize/3`'s
    shape, `wallet.ex:111`); per-guess fees stay.
  - **Who** — the platform returns the buy-ins; the player keeps the value of the attempts they used.
  - **When** — launch (the void/refund path is part of the locked gather-gated design, `economy.md:21`).
  - **Where** — `close_void` (forward) reading the buy-in TXNs; an exactly-once guard (the `SET … NX` close
    pattern, `rooms.ex:181`, + the partial unique refund index, `economy.md:21`).
- **Steelman (player-value).** This is **defensible and explainable**, which is what fairness actually requires
  at the player surface: a player can be told, in one sentence, *"your buy-in is back because the tournament
  didn't run; your guess fees paid for the guesses you made."* That maps to lived intuition (a cancelled event
  refunds the ticket, not the drinks you bought at the bar). It avoids the moral hazard Arm B invites —
  free-rolling a gathering room (guess cheaply, get fully refunded if it never fills) — which would let a savvy
  player extract scored practice at zero cost and is exactly the kind of exploit the all-pay structure exists to
  prevent (`design.md:188`: "the all-pay structure gives blind farming a negative expected value"). A
  buy-ins-only refund keeps that property: gathering guesses still cost.
- **Steward.** Honors **Thin but robust** — one refund class (buy-ins), one TXN reason, a smaller void path to
  test. Honest player cost: a player who guessed several times in a room that then failed to gather has *paid
  fees for a tournament that never paid out* — from their seat that can feel like a loss they didn't sign up
  for, even if the service was technically delivered. The candor mitigation (a clear up-front "guess fees are
  non-refundable; buy-ins are refunded if the room doesn't fill") makes this honest rather than a surprise.

### Arm B — Refund buy-ins + gathering per-guess fees

- **Rationale.** A room that never became a tournament should leave the player *whole* — refund every credit
  they spent in it, buy-in and fees alike. It answers the strongest fairness reading: no one should be out any
  money for a tournament that did not occur.
- **5W.**
  - **Why** — maximal player fairness; zero out-of-pocket for a failed gather.
  - **What** — on void, refund the buy-in *and* each gathering-phase per-guess fee.
  - **Who** — the platform absorbs the full cost of a failed gather (buy-ins + the foregone fee revenue).
  - **When** — launch (same void path), with a wider refund set.
  - **Where** — `close_void` reading both the buy-in TXNs and the gathering-phase `guess`-reason TXNs
    (`wallet.ex:104` writes the `"guess"` reason), refunding both.
- **Steelman (player-value).** The strongest trust signal there is: *"if the room doesn't fill, you lose
  nothing."* That removes all downside from *trying* a Golden Room, which is precisely the friction a new
  player feels at a gather-gated room ("what if I pay in and it never starts?"). Zero-downside-to-try is a
  powerful acquisition + virality lever — it makes "just try the tournament" a no-risk invite a player will
  forward. For the launch's growth goal, the fullest refund is the boldest "we've got your back" message.
- **Steward.** Honors **Do no harm** to the player most generously, but its long-game cost is the moral hazard
  the player lens must itself flag: a full refund on never-fills turns a gathering room into a **free practice
  range** — a player can guess, learn the scoring feel, and pay nothing if the room fails to fill, which
  *inverts* the all-pay anti-farming property (`design.md:188`). At scale this invites coordinated under-filling
  to harvest free scored guesses. It also makes the platform's exposure on a failed gather unbounded in the fee
  dimension, not just the buy-in. The fairness is real; so is the exploit surface.

### Decision 3 — the fork surface (player-value ranking)

| arm | fairness feel | exploit surface (all-pay anti-farming) | platform exposure on void | explainability |
|---|---|---|---|---|
| **A — buy-ins only** | high (defensible: ticket back, drinks kept) | **low** (gathering guesses still cost) | bounded (buy-ins only) | **highest** (one-sentence rule) |
| **B — buy-ins + fees** | **highest** (lose nothing) | **high** (free practice range; inverts anti-farming) | wider (buy-ins + foregone fees) | medium |

**Venus-B recommendation: Arm A (buy-ins only) — and this is where the player lens *agrees* with Apollo +
Venus-A, not against them.** The one reason: **the fuller refund (B) is more generous but it breaks the
all-pay anti-farming property the game's fairness rests on** (`design.md:188`) — and a player-trust win bought
by opening an exploit is a false economy, because the exploit degrades the contest for *every* honest player.
Arm A is the more *explainable* fairness ("buy-in back, fees for service rendered"), and explainability is the
real player-trust currency. The growth upside of B (zero-downside-to-try) is better captured *honestly* by the
**seed (Decision 1 Arm B)** — a seeded room is worth entering because the prize is real and guaranteed, which
is a cleaner acquisition hook than a refund-the-fees backstop that doubles as an exploit. (Recommendation, not a
ruling.)

### Decision 4 — `buy_in ⇒ not free` (confirm)

- **The rule.** A buy-in (real money, via Decision 2) cannot fund a pool denominated in **clips**, because
  clips *carry no economic value and are excluded from the available balance* (`01-currency-model.md:37,97`).
  Enforce `buy_in ⇒ not free` as a changeset rule (Apollo's un-prompted finding, `economy.md:66`).
- **Player-lens verdict: CONFIRM.** From the player surface this is not merely a data-integrity guard — it is a
  *trust* guard. A "free" room whose prize was funded by real buy-ins would be a category error the player would
  feel as a bait-and-switch ("this said free, but I paid to win valueless clips?"). Keeping buy-in rooms
  strictly paid (Keys) keeps the two economies the currency model already separates (`01-currency-model.md:97`,
  "the two paths never cross") legible at the player surface: free rooms are clips-only, low-stakes, no buy-in;
  Golden/tournament rooms are Keys + buy-in, real-stakes. The launch warm-up room "Бокс для разминки"
  (`type:classic`, free, 1 clip/guess, no buy-in, `economy.md:21`) is the correct free on-ramp; the Golden Room
  is the correct paid tournament. Confirm the rule.

---

## D. The cross-decision player-value through-line (the synthesis input)

The three recommendations cohere into one player-facing story, and the coherence is the point:

- **Seed + buy-ins (D1-B)** gives the player a prize that *feels bigger than the field* — the acquisition hook
  the removed multiplier otherwise took with it, recovered more honestly (a stated floor, not an opaque ×3).
- **Keys priced in USD (D2-A)** lets the player *actually reach the gather gate* — a one-tap join that doesn't
  leak the field at a payment modal, so the seeded prize is reachable.
- **Buy-ins-only refund (D3-A)** keeps the never-fills case *explainable and exploit-free* — the trust win
  comes from a one-sentence rule, not from a fee-refund that doubles as a farming exploit.
- **`buy_in ⇒ not free` (D4)** keeps the two economies *legible* — free is clips/low-stakes, Golden is
  Keys/real-stakes, no category error at the surface.

The net player experience: a tournament with a real, guaranteed, growing prize; a one-tap entry; a candid
"buy-in back if it doesn't fill, fees for guesses you made" promise; and a clean line between the free warm-up
and the paid contest. That is a loop a player will *enter, complete, and share*.

---

## E. Pre-empting Venus-A (the platform-sustainability lens)

The architect-approach requires each architect to pre-empt the opposing lens so the synthesis inherits the
rebuttal (`aaw.architect-approach.md` §"The multi-architect debate"). The strongest objections Venus-A will
raise, and the player-lens answer:

| Venus-A objection (sustainability) | Venus-B answer (player value / growth) |
|---|---|
| **The seed (D1-B) is an unbounded promotional outflow with no offsetting pool revenue** — every seeded pool's floor is funded out of pocket, every game, forever. | Conceded as a real cost — but the reconcile *removed the only other acquisition lever* (the multiplier), so with no seed there is **no remaining mechanism** to make the prize look bigger than the field, and a tournament whose headline prize is "$10 if exactly ten play" will not gather 10 players in the first place. The seed is not a giveaway; it is the **cost of the loop existing**. It is also *bounded per game* (by the seed, not the field) and *controllable* (the Operator sets the seed per promotion) — and Decision 1 Arm C (a published rake) is the sustainability *upgrade path* the player lens does not oppose **once the field is thick enough that the rake doesn't visibly gut a thin pool**. Seed to acquire; rake to sustain — in that order. |
| **Arm C (the rake) is the sustainable choice and Venus-B ranked it last** — the platform needs a margin, not just a per-guess fee. | The player lens ranked C last *for launch*, on two grounds it will defend: (1) it is **forward** (`BNK`, `economy.md:50`) — not launch-ready, so ranking it first would defer the loop; (2) a rake *stacked on* a buy-in *and* per-guess fees is **three extractions against one prize**, the structure most likely to read as "the house always wins" and suppress the very participation the margin is computed on. The player lens does **not** reject the rake — it sequences it: a rake on a *thick, seeded* pool is candid and fine; a rake on a *thin launch* pool is self-defeating. Adopt C *after* the seed has built liquidity, not instead of it. |
| **The full refund (D3-B) is a player giveaway; buy-ins-only (D3-A) is the cheaper scope** — Venus-A and Venus-B agree here. | Agreement, stated to the synthesis: both lenses land on **D3-A**. The player lens reaches it not on cost but on **exploit-integrity** (`design.md:188` anti-farming) and **explainability** — which means the recommendation is robust across both lenses (a convergence, the strongest signal the Operator can get, `aaw.architect-approach.md` §multi-architect debate). |
| **Keys-priced-in-USD (D2-A) leaves money on the table vs a direct Stars cut at join** — the platform forgoes the cleaner commerce capture. | The direct-Stars capture (D2-B) is **forward** (`PKG/ORD/OTX/WHK`) and **leaks the field at the join modal** — a commerce capture on a tournament that never gathered 10 players captures nothing. D2-A captures the commerce *earlier* (at the leisurely Keys purchase via `purchase_keys/3`, `wallet.ex:108`) where the funnel is not under high-intent pressure, then spends pre-funded Keys at a one-tap join. The platform still gets the Stars revenue; it just decouples it from the fragile join moment. D2-B is the right *upgrade* once the commerce surface ships — not the right launch rail. |

**The convergence to flag for the Director:** both lenses land on **D3-A (buy-ins-only refund)** and on **D4
(confirm `buy_in ⇒ not free`)**. The genuine divergence is **Decision 1** (the player lens leads **B/seed** for
the acquisition hook; the sustainability lens will likely lead **A/buy-ins-only** or **C/rake** for cost
control) and, secondarily, the *sequencing* of the rake (C). That divergence is the useful signal — it is a
**seed-now-vs-rake-now** trade the Operator should rule directly, not a synthesis to average.

---

## F. Reconcile delta table (surfaces probed against disk)

| claim an arm rests on | source | disk | verdict |
|---|---|---|---|
| `Economy.to_usd/1` + `to_cents/1` exist (the USD pricing rail, D2-A) | `economy.md:58` | `economy.ex:21-27` (`@cents_per_diamond 1.2`) | **MATCH** |
| `Wallet.purchase_keys/3` = the Stars→keys credit path (D2-A) | `economy.md:58` | `wallet.ex:108` `credit(:keys, …, "purchase", ref)` | **MATCH** |
| `Economy.top_k_split/3` = the proportional split machinery (locked payout) | `economy.md:15` | `economy.ex:62-77` (weight share + dust→rank1) | **MATCH** |
| `Economy.proportional/2` exists (an alternative share-by-score) | (locked `economy:proportional`) | `economy.ex:85-91` | **MATCH** |
| `effective_pool/3` carries `× mult` (the drift being removed) | `economy.md:30` | `economy.ex:34-36` `pool * mult` | **MATCH** (confirmed drift) |
| `Wallet.charge_guess/3` debits keys (paid) / clips (free) — per-guess fee = revenue | `economy.md:15` | `wallet.ex:98-105` | **MATCH** |
| `Wallet.deposit_prize/3` = the prize/refund credit shape (D3 buy-in refund) | (refund path) | `wallet.ex:111` | **MATCH** |
| atomic two-TXN pattern a refund mirrors | (D3 exactly-once) | `convert_to_keys` `wallet.ex:118-141` | **MATCH** |
| `seed_pool` is the current pool-funding prop (D1-B grounding) | `economy.md:49` | `rooms.ex:33,97` | **MATCH** |
| exactly-once close guard (the void/refund pattern) | `economy.md:21` | `SET … NX` `rooms.ex:181` | **MATCH** |
| clips carry no value / excluded from available (D4 grounding) | `economy.md:21` | `01-currency-model.md:37,97`; `wallet.ex:153` (`available_*` omits clips) | **MATCH** |
| all-pay anti-farming property (D3 exploit argument) | `economy.md` (all-pay) | `design.md:188` ("negative expected value" for blind farming) | **MATCH** |
| `keys_for_usd/1` (the D2-A conversion) | `economy.md:58` | **not on disk** | **FORWARD** (declared forward-tense, reuses `to_cents/1` arithmetic) |
| `close_void` + the partial unique refund index (D3 path) | `economy.md:21,64` | **not on disk** | **FORWARD** (locked design, not yet built) |
| the `BNK` rake/bank model (D1-C) | `economy.md:50` | **not on disk** | **FORWARD** (roadmap) |

**No INVENTED surface.** Every launch-ready arm rests on extant `file:line`; every forward arm (D1-C rake,
D2-B Stars-invoice, the `keys_for_usd/1` / `close_void` / `BNK` surfaces) is marked forward-tense, and the
ranking explicitly down-weights forward arms *as not launch-ready* rather than treating them as available.

---

## G. Summary — the player-value recommendations (advice, never a ruling)

| decision | Venus-B (player-value) leads | the one reason |
|---|---|---|
| **D1 — pool composition** | **B — Seed + buy-ins** | the seed is the only surviving lever (post-multiplier) that makes the prize feel bigger than the field, recovered more honestly than the boost; smallest change from the shipped `seed_pool` base |
| **D2 — USD rail** | **A — Keys priced in USD** | protects the conversion funnel at the gather gate (one-tap pre-funded join); launch-ready; D2-B defers the launch + leaks at the modal |
| **D3 — refund scope** | **A — buy-ins only** | the fuller refund breaks the all-pay anti-farming property; "buy-in back, fees for service rendered" is the more *explainable* fairness — and both lenses converge here |
| **D4 — `buy_in ⇒ not free`** | **confirm** | keeps the free (clips) and paid (Keys + buy-in) economies legible at the player surface; a free room with a real-money pool is a bait-and-switch |

The genuine divergence from the sustainability lens is **Decision 1 (seed-now vs rake-now)**; the convergences
are **D3-A** and **D4**. Both are surfaced for the Director's synthesis; the Operator rules.
