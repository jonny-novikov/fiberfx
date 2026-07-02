# Codemojex · Golden Rooms Calibration — Venus-A economy design (the tournament economic model)

> **Status:** DESIGN-PHASE deliverable, economic-model EXTENSION (Venus-A). No production code is written
> here; this is a spec + ADR set for the Director to ratify and the Operator to rule. Every claim is grounded
> in a real `file:line` or design §; forward-tense surfaces are marked.
> **Boundary:** this file only. It does **not** revisit the ratified start-mechanic design
> (`codemojex-golden-calibration.venus-a.design.md` — the `:gathering` spine, the members-by-guess set, the
> `start_threshold` prop), which **stands**. This builds the tournament economy *on top of* it.
>
> **Lens.** Venus-A leads from the as-built wallet/economy/store: the transactional wallet (`wallet.ex`), the
> pure payout math (`economy.ex`), the pool as a `games` column, the `:cm_games` cache coherence contract, and
> the `SET NX` exactly-once discipline.

---

## 0. The Operator's locked economic model (verbatim, design around it)

1. The launch Golden Room is `type:"classic"` + `golden:true` and pays a **LIVE PROPORTIONAL SPLIT** among the
   top finishers — NOT winner-take-all. WTA is now **only** for ordinary non-golden paid classic rooms; the
   blind `type:"golden"` mode keeps its sealed top-K. The Golden Room is a **new policy: live (classic)
   feedback + proportional payout**.
2. A Golden Room charges BOTH a one-time **BUY-IN** (to enter) AND a **per-guess fee**. The buy-in is
   configurable in **USD or Keys**.
3. **BUY-INS FUND THE PRIZE POOL** (tournament-style — the pool grows with the field). Per-guess fees stay
   **platform revenue** (the platform-seeded ruling holds for per-guess fees only).
4. **HARD 10-player floor** (the ratified `:gathering` gate). Buy-ins are REAL money in the pool → a
   never-fills game MUST refund the buy-ins.
5. Launch config: a FREE warm-up room **"Бокс для разминки"** (`type:classic`, free, 1 clip/guess, no buy-in)
   + one **Golden Room** (buy-in + per-guess + 10-gather + proportional).
6. Keep `type:"golden"` for the blind mode (Operator-ruled); the pool stays platform-seeded for per-guess fees
   (Operator-ruled); strike the "every attempt adds to the pool" copy.

---

## 1. The model in one paragraph

The Golden Room becomes a **buy-in tournament**: a one-time buy-in (charged once at join) funds a pool that
**grows with the field**, the round starts only when 10 distinct players have each guessed (the ratified
gather gate), and at close the pool is split **proportionally** among the top finishers — live feedback
throughout, like a classic room, but paid by weight (`[40,25,15,12,8]`) rather than winner-take-all. The
three policy columns become `feedback:"score"` / `settlement:"live_split"` / `economy:"proportional"`, and the
settlement reuses the **already-built, already-tested** `Economy.top_k_split/3`. Two new wallet primitives
carry the real money: `Wallet.buy_in/3` (a two-sided `Ecto.Multi` that debits the player and increments the
game pool atomically) and the refund inside `close_void` (ledger-authoritative, per-player idempotent, so a
crash mid-refund is resumable). The pool is a Postgres-read everywhere it matters, so the growing pool does
**not** break the immutable `:cm_games` cache.

---

## 2. The settlement path — live feedback + a proportional split

### 2.1 The third policy

| Room | `type` | `golden` | `feedback` | `settlement` | `economy` | payer |
|---|---|---|---|---|---|---|
| ordinary paid classic | `classic` | `false` | `score` | `live` | `winner_take_all` | `Economy.winner_take_all` (`economy.ex:43`) |
| **Golden Room (launch)** | **`classic`** | **`true`** | **`score`** | **`live_split`** *(new)* | **`proportional`** *(new)* | **`Economy.top_k_split`** (`economy.ex:62`) |
| blind mode | `golden` | `false`¹ | `none` | `sealed` | `winner_take_all`² | `Economy.top_k_split` (`economy.ex:62`) |

¹ `golden` (boost flag) is orthogonal to the blind type — a blind room *may* also be boosted. ² the blind
row's `economy` is the existing `"winner_take_all"` string snapshotted by `policies_for("golden")`
(`rooms.ex:128`), but it pays via `top_k_split` in `close_sealed` (`rooms.ex:236`) — a pre-existing naming
quirk the calibration can tidy (the `economy` value is descriptive, not a dispatch key; `do_close` dispatches
on `settlement`, `rooms.ex:189`).

The Golden Room policy is a **clean composition**, not new math: `feedback:"score"` reuses the classic live
path (`game.ex:126-145`), and `settlement:"live_split"` reuses `top_k_split` — what changes versus the blind
path is *when* it runs (the live close, not a blind-only timer close) and *whether feedback leaks* (it does).

### 2.2 The new close path — `close_split`

`do_close` (`rooms.ex:188-193`) today is a two-way branch on `settlement`: `"sealed"` → `close_sealed` (blind),
else → `close_live` (WTA). It gains a **third** branch:

```
do_close(game, r):
  settlement == "sealed"     -> close_sealed(game, r)   # blind reveal + top-K           (rooms.ex:223)
  settlement == "live_split" -> close_split(game, r)    # NEW: live proportional top-K
  _                          -> close_live(game, r)     # WTA                            (rooms.ex:196)
```

`close_split/2` (forward — Mars builds it) mirrors `close_live` but pays by weight:

- runs under the **same** one-shot `SET cm:<game>:closed NX` lock (`rooms.ex:181`) — exactly-once, so a
  perfect-600 crack close and a timer/sweep close never both pay;
- triggers are the **classic** set — a perfect 600 (`game.ex:144`), the timer, or the sweep — NOT the
  blind-only timer close (the Golden Room is `classic`-typed, live, so an early crack is possible);
- reads the board top-`top_k` (`Board.top(game, top_k)`, `board.ex:26`);
- pays `Economy.top_k_split(pool, board, payout_split)` where `pool` is the **buy-in-funded** pool (§3);
- deposits each share through `Wallet.deposit_prize` (`wallet.ex:111`), bumps `cm:total_won`, marks the game
  `settled`, returns the room to waiting, and fans out the live moment (`{:golden_win, …}` PubSub +
  `golden_win/4`, exactly as `close_live` does for a boosted room, `rooms.ex:207-213`).

### 2.3 The weights/breadth recommendation

**Keep `top_k = 5` + `payout_split = [40,25,15,12,8]`** — the snapshotted props already on `games`
(`schemas/game.ex:24-26`, `migration:90-91`). They are tournament-shaped (top-5 proportional) and **already
tested** for exactly this payer (`economy_story_test.exs:66-121`: top-K, configurable weights,
normalize-when-short, drain-the-whole-pool, dust-to-rank-1). The Golden Room snapshots them at start the same
way the blind room does. No new economy math, no new property — `close_split` is a thin dispatch onto the pure
function that already exists and passes its suite.

> **Engine principle.** This is the design's "one function, the policy branches the edges" discipline
> (`design.md:11`) applied to *settlement*: the proportional payer is one pure function; live-vs-blind is
> *when it runs* and *whether feedback leaks*, not a second payer.

---

## 3. The buy-in — the two-sided wallet op that funds the pool

### 3.1 `Wallet.buy_in/3` — debit the player, credit the game pool, atomically

Every existing wallet op touches only the `players` row (+ a `transactions` row). The buy-in is the **first
two-sided, cross-entity** op: it debits a `players` row **and** credits a `games` row (the pool) in one
transaction. Forward shape (Mars builds it):

```
Wallet.buy_in(player, game, amount):           # one Repo.transaction / Ecto.Multi, both tables Postgres
  lock(player) FOR UPDATE                       # wallet.ex:195 discipline
  non-negative CHECK (refuse if short)          # players_non_negative, migration:23
  debit :keys by amount                          # the buy-in currency (§5 USD rail)
  txn!(player, :keys, -amount, "buy_in", game)   # a real TXN, ref = game  (free-text reason, transaction.ex:9)
  UPDATE games SET prize_pool = prize_pool + amount WHERE id = game   # ATOMIC increment, not RMW
  # commit both, or neither
```

The `prize_pool` increment is an **atomic SQL `+`**, never a read-modify-write in app code — N concurrent
buy-ins into one pool would lose updates otherwise. (`Ecto` `update_all` with an `inc:`/fragment.)

### 3.2 When it is charged — once, at join, exactly-once

- The buy-in is charged at **JOIN**, the first time a player enters a gathering Golden Room — in
  `rooms.ex` `join_room` (the entry path, `rooms.ex:54`), not per-guess (`charge_guess` stays unchanged,
  `game.ex:33`).
- **Exactly-once entry guard.** A Telegram client reconnects/re-joins; the buy-in must be charged **once** per
  player per game. Guard with a Valkey `SET cm:<game>:paid:<player> NX` (or a `SADD cm:<game>:paid` whose
  `1`-return marks the first add) checked **before** `buy_in/3`; only a first-time payer is charged + pooled.
- This **paid set is distinct from the members set** (the ratified D-4 gather gate, keyed on a *guess*). The
  paid set is keyed on the *join*. A player who pays the buy-in but never guesses is in the **paid** set (they
  funded the pool) but **not** the **members** set (they do not count toward the 10-gather) — which is correct:
  the gather is participation-gated.

### 3.3 The cache-coherence question — narrower than it looks

The brief flags that a growing pool breaks the `:cm_games` `coherence:none` / immutable-for-life contract
(`design.md:119`). **Verified: nothing on the hot path or the settlement path trusts the cached pool.**

| read site | source | needs the pool? |
|---|---|---|
| hot score path (`game.ex:106` `Cache.fetch_game`) | **cache** | **no** — matches `%{secret: secret}` only (`game.ex:107`); never reads `prize_pool` |
| game view (`view.ex:50` `Store.game` → `:61`) | **Postgres** | yes — reads the live pool |
| settlement (`do_close`/`close_*` on `r = Store.game`, `rooms.ex:171,199,226`) | **Postgres** | yes — reads the live pool |

So the `coherence:none` invariant is about the fields the *hot path* needs — the secret and the keyboard —
both still immutable for the game's life. A mutable `prize_pool` does **not** violate it **as long as the pool
is never served from the immutable cache**. **The rule:** `buy_in/3` writes `games.prize_pool` in **Postgres
only** and does **not** call `Cache.put_game` — the cached blob keeps the start pool (harmless, nothing trusts
it), and the live pool is always a Postgres read, as it already is in the view and at settlement. This is
"coherence is a property of the data, not the store": the cache stays valid for what it actually caches.

> If the surface ever needs a *very-hot* live pool counter (e.g. a ticking pool on a busy room), the
> idiomatic move is a Valkey `cm:<game>:pool` counter `INCRBY`'d by `buy_in` and read by the view — the same
> shape the leaderboard already uses (a Valkey ZSET, not the cache). Not required for launch; noted as the
> scaling lever.

---

## 4. Pool composition — an Operator sub-fork (surfaced, not decided)

Buy-ins fund the pool (constraint #3) **and** `golden:true` keeps the `gold_multiplier` boost (constraint #1).
How they combine is an **economic cost** decision:

- **(a) `seed_pool × gold_multiplier + Σ buy_ins`** — the platform seeds a floor, boosts the *seed*, and the
  field's buy-ins stack on top. Most generous; highest platform cost. Needs `effective_pool` to boost the
  *seed only*, separately from `Σ buy_ins`.
- **(b) `Σ buy_ins` only** — pure tournament; `seed_pool = 0` for a Golden Room, `gold_multiplier` unused; the
  platform funds nothing, the field funds itself.
- **(c) `(seed_pool + Σ buy_ins) × gold_multiplier`** — the boost multiplies the *combined* pot; the platform
  matches the field N:1. This is what the **current** `effective_pool(prize_pool, golden, mult)` (`economy.ex:35`,
  `pool × mult`) produces **as-is** if `prize_pool` is the running `seed + Σ buy_ins`.

**Engine note:** reading (c) is free (existing `effective_pool`). Reading (a) requires `effective_pool` to take
the seed and the buy-in sum separately (boost the seed, add the buy-ins un-boosted). Reading (b) is `seed=0`
+ skip the boost. **The code shape depends on the ruling — this is an Operator decision (how much the platform
funds).** RECOMMEND surfacing all three; (c) is the lowest-code default, (b) the lowest-cost, (a) the most
promotional.

---

## 5. The USD rail — an Operator sub-fork (surfaced, not decided)

"Configurable in USD or Keys." The existing real-money rail is **Telegram Stars → keys** (`wallet.ex:108`
`purchase_keys`, `design.md:275`). Two readings:

- **(a) Keys-priced-in-USD (buildable now).** The buy-in is *configured* in USD **or** keys (`buy_in_usd` /
  `buy_in_keys` props) but **collected as keys** at the fixed key↔USD rate (1 key = 10 diamonds = 12¢,
  `economy.ex:11` `@cents_per_diamond`). `buy_in/3` debits `:keys`; the USD is the display/config unit. **No
  new payment rail.** A new pure `Economy.keys_for_usd/1` (forward) resolves a USD buy-in to a keys amount.
- **(b) Direct Stars invoice at join.** "USD" = a real-money Telegram Stars charge *outside* the keys wallet,
  settled via the payment webhook. This is the **forward commerce system** (`ORD`/`OTX`/`WHK`,
  `roadmap.md:254-257`, all 📋 unbuilt) — a much larger build (a payment ledger + idempotent webhooks).

**RECOMMEND (a) for launch:** it reuses the keys wallet, prices the buy-in in USD for config/display, and needs
no new payment rail or webhook — the Stars→keys purchase already exists, so a player tops up keys (existing
path) then the buy-in debits keys. (b) is the forward commerce build. **Surface both; (a) is the
buildable-now reading of "configurable in USD or Keys."** → **Operator** rules whether launch needs the
direct-Stars rail.

---

## 6. The never-fills buy-in refund — `close_void`

This extends the ratified F-D `close_void` (the gather-deadline abort) with the **real-money** refund the
buy-ins demand (constraint #4).

### 6.1 The refund design

- `close_void` runs under the **same** `SET cm:<game>:closed NX` one-shot (`rooms.ex:181`) — a double-void
  cannot double-*enter* the refund loop.
- **The refund set is ledger-authoritative.** Read the players to refund from the **`buy_in` TXN rows** for
  `ref = game` (the durable source of truth; survives a Valkey flush) — **not** the volatile `cm:<game>:paid`
  set. Money reconciles against the ledger, not a cache.
- For each paid player, in one `Ecto.Multi`: credit back the buy-in amount (`txn!` reason `"buy_in_refund"`,
  `ref = game`) **and** decrement `games.prize_pool` by that amount.
- The game transitions `gathering → voided` (the canon abort state, `design.md:136`).

### 6.2 Crash-safety — exactly-once AND resumable (Apollo's requirement)

The close lock guards **entry**, but a crash mid-loop (player 4 of 10 refunded) must not double-refund players
1–3 on a retry. **Per-player idempotency:** a refund is applied only if no `"buy_in_refund"` TXN for that
`(player, ref = game)` already exists — a check-and-insert in the same transaction, or a **unique partial
index** on `transactions (player, ref) WHERE reason = 'buy_in_refund'`. So the refund loop is **resumable**:
re-running skips already-refunded players and completes the rest. (The `convert`-style paired-TXN discipline,
`wallet.ex:135-136`, is the template; the new index is the idempotency guard.)

### 6.3 Refund scope — buy-ins only

Refund the **buy-ins only**, NOT the gathering per-guess fees. Operator-ruled, per-guess fees are platform
revenue (constraint #3), and a guess that scored bought real leaderboard standing + live feedback — a
*delivered service*. Only the buy-in (which bought entry into a tournament that never legally began) is owed
back. (Surfaced for the Operator to confirm in §9; the recommendation is buy-ins-only.)

---

## 7. Schema / keyspace / TXN deltas (the substrate)

| Delta | Where | Shape |
|---|---|---|
| `buy_in_keys` (room + game) | `schemas/room.ex`, `schemas/game.ex`, migration | nullable int; the buy-in in keys (null/0 = no buy-in) |
| `buy_in_usd` (room + game) | same | nullable int (cents); the buy-in in USD — resolves to keys via `Economy.keys_for_usd/1` (§5a); a room sets one of the two |
| `settlement = "live_split"` | the `games` `settlement` column (already free text, `migration:83`) | a new value; no CHECK on `settlement` today, so additive |
| `economy = "proportional"` | the `games` `economy` column (free text, `migration:84`) | a new value; descriptive, not a dispatch key |
| `prize_pool` becomes mutable | `games.prize_pool` (exists, `migration:94`) | written by `buy_in/3` (Postgres only) + refunded by `close_void`; read from Postgres everywhere |
| TXN reasons `buy_in`, `buy_in_refund` | `transactions.reason` (free text, `transaction.ex:9`) | **no migration** — new string values |
| idempotency index | `transactions` | a unique **partial** index `(player, ref) WHERE reason = 'buy_in_refund'` (§6.2) |
| Valkey paid-guard | runtime keyspace | `cm:<game>:paid` (set) or `cm:<game>:paid:<player>` (SET NX) — the entry exactly-once guard (§3.2) |
| `start_threshold`, `gather_deadline_ms` | already in the ratified start-mechanic design | **unchanged** — referenced, not re-specified here |
| the live-pool read path | `view.ex` + `close_*` | already Postgres (`Store.game`) — **no change** needed; documented as the rule (§3.3) |

**No `games_type` change:** the Golden Room is `classic`-typed, so the `games_type` CHECK (`'classic','golden'`,
`migration:108`) is untouched by the economy model (the blind-type rename remains the *start-mechanic* design's
F-A sub-fork, separate from this).

---

## 8. Where each delta lands — engine specs vs design canon

| Delta | `docs/codemojex/**` (engine specs) | `node/codemoji-design/**` (design canon) | Engine code (forward — Mars) |
|---|---|---|---|
| live-proportional settlement | `codemojex.design.md` §modes + §core-flows (the `live_split`/`proportional` policy + `close_split`) | `03-rooms.md` (the Golden Room pays a top-5 proportional split, not WTA) | `rooms.ex` `do_close` + `close_split`; `policies_for` 3rd clause |
| the buy-in op | `codemojex.design.md` §economy + §systems Money (`Wallet.buy_in`, the two-sided Multi) | `03-rooms.md` (a buy-in to enter) + `01-onboarding.md`/wallet screens | `wallet.ex` `buy_in/3`; `rooms.ex` `join_room` call site |
| buy-ins fund the pool | `codemojex.design.md` §economy + §storage (pool mutable, Postgres-read; cache rule) | `screens/game/README.md:112-116` (replace "fees grow the pool" — it's now **buy-ins** grow the pool) | `wallet.ex` (the atomic increment) |
| **strike "every attempt adds to the pool"** | `codemojex.design.md:26` + `roadmap.md:248` | `screens/game/README.md:177` (the rules-card copy) + the in-app rules string | (copy only) |
| the USD rail (§5a) | `codemojex.design.md` §economy (`buy_in_usd` resolves to keys; `keys_for_usd`) | `03-rooms.md` (buy-in configurable USD/Keys) | `economy.ex` `keys_for_usd/1`; `schemas/*` props |
| pool composition (§4) | `codemojex.design.md` §open-questions (the seed×boost+Σ ruling) | — | `economy.ex` `effective_pool` shape (per ruling) |
| the never-fills refund | `codemojex.design.md` §core-flows (`close_void` refund) + §open-questions | — | `rooms.ex` `close_void`; the partial index migration |
| launch config (2 rooms) | `codemojex.design.md` / a seed doc (the warm-up + the Golden Room) | the lobby screens (`03-rooms.md`) show both | a seed/config (forward) |
| schema deltas (§7) | `codemojex.design.md` §data-model (`rooms`/`games` props) | — | `schemas/{room,game}.ex` + migration |

---

## 9. Open items surfaced to the Operator (not decided here)

1. **Pool composition (§4):** `seed×boost + Σbuy_ins` (a) vs `Σbuy_ins` only (b) vs `(seed+Σbuy_ins)×boost`
   (c). An economic-cost ruling; (c) is lowest-code, (b) lowest-cost, (a) most promotional.
2. **The USD rail (§5):** keys-priced-in-USD (a, buildable now, no new rail) vs a direct Stars invoice at join
   (b, the forward `ORD`/`OTX`/`WHK` commerce build).
3. **Refund scope (§6.3):** buy-ins-only (recommended) vs also refunding the gathering per-guess fees.
4. **Buy-in currency default:** keys (recommended, reuses the wallet) — confirm a Golden Room cannot be a
   *free* room (a free room takes clips, which carry no value, so a clips buy-in funds a worthless pool —
   the launch warm-up is free **and** has no buy-in, which sidesteps this; confirm the rule "a buy-in room is
   never free").

---

## 10. Risk posture + handoff (money-critical)

- **MONEY-CRITICAL, HIGH-RISK rung → Apollo mandatory.** Three real-money surfaces: the buy-in debit + pool
  credit (two-sided atomicity), the proportional payout at close, and the never-fills refund (resumable
  exactly-once).
- **Two exactly-once + atomicity sites beyond the existing close lock:** (1) `buy_in/3` — the player debit and
  the pool increment must be one `Ecto.Multi` (a partial commit that debits but doesn't pool, or pools but
  doesn't debit, is a money bug), plus the `SET NX` paid-guard so a re-join doesn't double-charge; (2)
  `close_void` — ledger-authoritative refunds with the per-`(player, ref)` partial-index idempotency so a
  crash mid-refund is resumable.
- **The atomic SQL `+` for the pool** (never an app-side read-modify-write) — N concurrent buy-ins into one
  pool lose updates otherwise. This is the single most likely correctness defect; call it out in the brief.
- **`Economy.top_k_split` is reused verbatim** — its suite (`economy_story_test.exs:66-121`) is the existing
  proof of the proportional math; the new tests pin `close_split` *wiring* (live trigger, the buy-in-funded
  pool), not the math.
- **Test blast radius:** `settlement_story_test.exs` (WTA) is **preserved** — ordinary classic rooms keep WTA;
  a **new** Golden-Room story is owed (buy-in → gather → live play → proportional close), plus a never-fills
  refund story and a buy-in exactly-once story. The economy unit suite gains `keys_for_usd` + (if pool
  composition (a)) the seed/boost-separation case.
- **No third app, no `games_type` change.** Every delta is inside `echo/apps/codemojex` (lib + schemas +
  migration + tests) and the two doc trees.
- **Composes cleanly with the ratified start-mechanic design:** the buy-in's paid-set is *distinct* from the
  gather members-set; `close_void` is the *one* close path that does both the gather-abort (ratified) and the
  buy-in refund (this design); the `:gathering` state is where the buy-in is collected and the never-fills
  refund fires.
