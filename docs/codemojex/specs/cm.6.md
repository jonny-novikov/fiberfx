# cm.6 — The Revenue Ledger (explicit house-account double-entry)

> **The first slice of the BNK bank** (the roadmap `cm.6+` bucket) and the named follow-on to **cm.5**. cm.5
> ships the Golden Room revenue ledger **implicitly** — the platform's cut is recorded *by conservation* (the
> entry fee leaves the player + the pool is not incremented = the platform's), with no explicit house-account
> row (`cm-5` ledger `D-15`, the Operator's "ship implicit now"). This rung makes the revenue side **explicit
> balanced double-entry**: a dedicated **`revenue_ledger`** that receives the platform's cut as its own signed
> rows, so platform revenue is a first-class, queryable, reconcilable balance. Grounded NO-INVENT in the cm.5
> as-built money paths (`Codemojex.Wallet` / `Economy.entry_fee_split` / the `transactions` ledger);
> **forward-tense** for the unbuilt house-account surface.
>
> **RULED (`cm-6` ledger `D-1..D-7`).** The design phase is closed — the dual-architect forks are decided (see
> [§ Rulings](#rulings-cm-6-d-1d-7-locked) below); the two designs ([`cm.6.design.a.md`](./cm.6.design.a.md) /
> [`cm.6.design.b.md`](./cm.6.design.b.md)) + the Director synthesis
> ([`cm.6.design.consolidation.md`](./cm.6.design.consolidation.md)) are the argued background. The house is a
> **dedicated `revenue_ledger` table** (`D-1`), RVL-branded (`D-6`), **keys**-denominated for the Golden cuts
> (`D-2`) and **multi-source / multi-currency** for the BNK bank + the cm.7 KeyShop. This is a **ruled build
> brief**; the build runs via `/codemojex-ship cm.6` (L2 Squad). The acceptance face is
> [`cm.6.stories.md`](./cm.6.stories.md); the compact brief is [`cm.6.llms.md`](./cm.6.llms.md).

## Rationale

cm.5's `D-7` economy moves **real, withdrawable** money: each Golden Room entry fee splits between the platform
(deposit-recovery → first-mover share → full revenue) and the diamond prize pool. cm.5 records the **player**
side (a `buy_in` debit `TXN`, `wallet.ex:203-242`) and the **pool** side (the `prize_pool` atomic increment,
`Economy.entry_fee_split` `economy.ex:45-52`), but the **platform** side is left *implicit* — derivable only by
conservation (`keys_debited − keys_to_pool = the platform's`).

Implicit revenue is auditable but **not balanced**: there is no single account whose balance *is* platform
revenue, no row to reconcile against, and the "best-practices ledger" the Operator named is only half-realized
(the cm.5 *distribution* at finish is explicit double-entry — real prize/consolation `TXN`s `ref=game`,
`distribute_pool/3` — but the *revenue* is not). This rung closes that asymmetry: every platform cut becomes a
real signed row in a dedicated `revenue_ledger`, so (a) the books **balance by conservation** at the entry
(keys) unit — the three-term identity `Σ player_key_debits == Σ house_key_credits + Σ pool_key_portions` (the
honest shape of the as-built money surface; see [§ Rulings](#rulings-cm-6-d-1d-7-locked) `D-3` — *not*
`Σ all-rows = 0`), (b) platform revenue is a **single queryable balance**, and (c) finance/audit reconcile the
books without re-deriving by conservation. It is also the **foundation the BNK bank builds on** — a rake
debits the pool and credits this `revenue_ledger`; a withdrawal debits it — and it is shaped **multi-source /
multi-currency** so the cm.7 KeyShop's Stars purchases book into the *same* ledger.

## 5W

- **WHO** — a new **house/platform account** (a dedicated `revenue_ledger`, `account="platform"`) is the
  credit counterparty for every platform cut; the team that builds it is the L2 Squad (Director + Venus +
  Venus-Postgres + Mars + Apollo — a money + schema rung).
- **WHAT** — an explicit house account + a **paired platform-credit `TXN`** for every revenue movement cm.5
  records implicitly (the virtual-deposit seed, the deposit-recovery, the first-mover platform share, the
  full-revenue tiers, the void deposit-reclaim), each in the **same `Repo.transaction`** as the player debit, so
  the revenue side is **atomic balanced double-entry**.
- **WHY** — auditability + reconciliation + the *complete* best-practices ledger (the Operator's intent); a
  queryable platform-revenue balance; the BNK bank's foundation (rake / payouts / withdrawal credit/debit this
  account).
- **WHERE** — `echo/apps/codemojex` only: `Codemojex.Wallet` (the ledger authority — a new `house_post`
  primitive over the `revenue_ledger`), a new `schemas/revenue_ledger.ex` (+ its additive migration), the
  `buy_in` (`wallet.ex:203-242`) + `close_void` (`rooms.ex:462-472`, cm.5) + the golden-seed `formation`
  (`rooms.ex:171-178`, cm.5) paths (the credit/debit insertion points), and a new reconciliation read in
  `Wallet`/`Store`. No sibling umbrella app; `mix.lock` excluded.
- **WHEN** — after cm.5 ships (it depends on cm.5's waterfall + the `transactions` ledger); **before** the BNK
  rake/withdrawal (which operate on the house account this rung defines).

## Scope In

1. **The house account — a dedicated `revenue_ledger` table** (`D-1`, Arm 2; the fork is *ruled*, not framed).
   A signed entry table mirroring `transactions`, **no non-negative CHECK** (so the house legitimately swings
   negative on the seed), RVL-branded (`D-6`), designed **multi-source / multi-currency** from the start:
   `{id (RVL), account/source, currency, delta (signed bigint), reason, ref, inserted_at}`. Holds the Golden
   Room cuts in `currency="keys"` now; the cm.7 KeyShop's Stars purchases plug in at `source="purchase"`,
   `currency="stars"` (`D-5`). Venus-Postgres authors the relational shape + the migration
   ([`cm.6.postgres.design.md`](./cm.6.postgres.design.md)) to this column contract.
2. **The virtual-deposit SEED as a house debit** — at golden `formation` (`rooms.ex:171-178`), the platform
   funds `prize_pool = virtual_deposit` (diamonds); record the funding as a **house debit** of
   `−div(virtual_deposit, 10)` keys (reason `"deposit_seed"`, `ref=game`) paired with the pool seed, so the
   seed is a real platform outlay (not a free pool). **SEAM-1 (`D-4`):** the seed lands via a *bare*
   `Store.put_game` (`rooms.ex:136`), **not** a `Repo.transaction` — so Mars **wraps** the games-row seed
   write + the `deposit_seed` debit in **one** `Repo.transaction` (the lone overlay exception that touches a
   cm.5 path).
3. **The paired platform-credit** at each cm.5 revenue movement, a signed `revenue_ledger` row in the **same
   `Repo.transaction`** as the player debit (atomic double-entry), keyed `ref=game`:
   - **deposit-recovery** (members `1..start_threshold`) → credit the house the full `entry_fee_keys` (reason
     `"deposit_recovery"`);
   - **first-mover share** (members `start_threshold+1 .. +first_movers`) → credit the house
     `entry_fee_keys − pool_keys` keys, where `pool_keys = div(entry_fee_keys × (100−revenue%), 100)`
     (`economy.ex:47`, floored in keys) — the exact-integer **complement of the pool portion**
     `Economy.entry_fee_split` already computes (reason `"revenue"`); expose `Economy.entry_fee_split_keys/5`
     so the house cut and the pool 💎 (`×10`) derive from the *one* floor;
   - **full revenue** (members beyond) → credit the house the full `entry_fee_keys` (reason `"revenue"`);
   - **void deposit-reclaim** (`close_void`) → credit the house **`+div(virtual_deposit, 10)`** (the
     *seed-cancelling* amount, reason `"deposit_reclaim"`) — **NOT** `Σ kept fees + seed` (the kept fees are
     already booked at buy-in; `Σ fees + seed` double-counts — `D-4`/PF-4, money-critical). The house net for
     a voided game is then `Σ kept fees`.
4. **The keys-unit balance invariant** — at each entry, `entry_fee_keys = house_credit_keys + pool_portion_keys`
   (the pool's keys→💎 ×10 is an explicit *conversion/minting* entry at the pool boundary, not a leak). Σ over
   the game: `Σ player debits = Σ house credits + Σ pool conversions` at the keys unit; the seed debit cancels
   the recovery credits (the zero-loss, now explicit). **The balance holds by CONSERVATION over three
   observable columns, NOT `Σ all-ledger-rows = 0` (`D-3`, mandatory — see Acceptance).**
5. **A reconciliation read** — a `Wallet.house_balance/0..1` query (`SUM(delta) FROM revenue_ledger WHERE
   account=house [AND ref=game] GROUP BY currency[, reason]`) returning the house balance + a per-game revenue
   breakdown (seed / deposit-recovery / revenue / reclaim), so revenue is **queried**, not re-derived; the
   `GROUP BY currency` is the multi-currency seam (cm.7's `"stars"` rows sum into their own bucket with no
   read change).
6. **The migration + schema** for the `revenue_ledger`; the gate ladder. The buy-in credits ride the buy-in's
   existing **games-row-`FOR UPDATE`-locked** transaction (cm.5 `RULING 1`), so they inherit the G1 ordinal
   serialization — no new lock, no new race.
7. **The conservation-honesty statement** (`D-3`, a mandatory acceptance item) — the spec states plainly the
   ledger balances by conservation (the three-term keys identity), **not** by a zero row-sum, and **names**
   "reconcile the entry legs into signed rows + a pool account" (the deferred F3-Arm2 reshape) as the explicit
   next bank rung. *Without this statement the rung ships a ledger that looks complete and is not.*

## Scope Out

- **The BNK rake / fee model** (a platform cut *of the pool*) — a later BNK slice; this rung *records* revenue,
  it introduces **no new fee** and changes **no cm.5 amount**.
- **Withdrawal / cash-out** of the house balance (the platform's real-money settlement) — a later BNK slice.
- **cm.7 — the KeyShop** (`D-5`): the `packages` catalog table (stored in the DB so the shop is editable
  without a deploy) + the Telegram XTR invoice flow (invoice → `pre_checkout_query` → `successful_payment`,
  keyed exactly-once on the Telegram charge id) + the pure `KeyShop` pricing module (store-fee + a live TON
  rate) + booking gross-Stars **purchase** revenue into the *same* `revenue_ledger` (`source="purchase"`,
  `currency="stars"`). cm.6's ledger is **shaped** multi-source/multi-currency for it; the packages surface is
  **not** built this rung (folding it in would balloon the money rung's blast radius — the Arm-2 ledger makes
  the split free).
- **Non-golden room economics** — cm.5's guess→pool is golden-only and non-golden rooms keep their shipped
  charge; this rung's scope is the **Golden Room** revenue tiers + the seed + the void reclaim (the
  cm.5-introduced flows). The ledger is *designed* to hold all platform-revenue sources; this slice **books**
  only the Golden Room cuts (purchases are cm.7).
- **Retroactive backfill** of pre-cm.6 implicit revenue into explicit rows — **forward-only**; the house account
  starts at cm.6 (the discontinuity is noted for finance).
- **Any cm.5-resolved surface** (`gold_multiplier`, the no-refund void, the pool denomination, the
  distribution double-entry) — untouched; cm.6 is purely additive on the revenue side.

## Acceptance

- **The double-entry BALANCE invariant proven (by CONSERVATION, `D-3`):** for any sequence of buy-ins + a
  close, the three-term keys identity `Σ keys (player debits) = Σ keys (house credits) + Σ keys (pool
  conversions)` holds at the entry unit, proven over **three observable columns** (the `players.keys` deltas,
  the `revenue_ledger` credits, `games.prize_pool` 💎 ÷ 10) — **NOT** `Σ all-ledger-rows = 0` (the player
  debit is a bare `keys` column delta + the pool is a `games` column); the house balance equals the sum of
  the platform cuts; **no key minted or lost** (the ×10 conversion is the one accounted minting boundary). The
  spec **states this conservation framing plainly** and **names** the entry-leg reconcile as the deferred bank
  rung (`D-3`, mandatory).
- **Atomicity:** the platform-credit row is in the **same `Repo.transaction`** as the player debit + the pool
  increment — a partial double-entry is impossible; it inherits the games-row lock → no mis-credit under
  concurrency.
- **Equivalence to cm.5:** the reconciliation read's house figure **equals the conservation figure cm.5 leaves
  implicit** — cm.6 makes the *same* number explicit, never a different one (proven by a property test against a
  cm.5-only computation).
- **The migration up/down clean** — cm.6 adds a **new additive** migration creating the `revenue_ledger`
  table (`down: drop table`, non-destructive on shipped data); fresh reinit on `codemojex_test` (read the DB
  name from `config/test.exs`, surface the target first); the **three** shipped migrations
  (`20260618000000_create_codemojex.exs` · `20260625145121_add_player_tg_user_id.exs` ·
  `20260626120000_golden_rooms.exs`) **byte-frozen**.
- `mix test --include valkey` green incl. the new revenue-ledger stories; **the cm.5 suite stays green
  untouched** (the house credit is additive — the pool/player figures are unchanged); the **≥100 determinism
  loop** (reinit-per-iter) clean; the boundary ⊆ `echo/apps/codemojex/**` + the rung docs; `mix.lock` untouched.
- **Apollo BUILD-GRADE** (money-critical): the §11.2 charter — the balance-invariant table at `file:line`, ≥1
  un-prompted finding, ≥1 attack-that-held, a mutation kill-rate.

## Given / When / Then

- **S-SEED — the virtual deposit is a real platform outlay.** *As finance, I want the seeded pool booked as a
  platform cost, not free money.* **Given** a Golden Room (`virtual_deposit` V💎), **When** the golden game
  forms, **Then** the house holds a `"deposit_seed"` debit of `−V/10` keys in `revenue_ledger` (ref=game) and
  the pool holds `V` 💎 — and the games-row seed write + the debit are **wrapped in one `Repo.transaction`**
  (SEAM-1, `D-4`; the seed today is a bare `Store.put_game`, `rooms.ex:136`). The house balance is **negative**
  at this instant — the `revenue_ledger` admits it (no non-negative CHECK, `D-1`).
- **S-DEPOSIT-RECOVERY — the first-10 fees are recorded revenue.** **Given** a Golden Room (`entry_fee_keys` 8,
  `start_threshold` 10), **When** members 1..10 each buy in, **Then** the house gains `+8` keys per member
  (reason `"deposit_recovery"`), the pool is unchanged (still V), `player.keys` fell by 8 each — and the house's
  *net* after 10 recoveries equals `Σ recovery − seed` (≈ 0, the zero-loss made explicit).
- **S-FIRSTMOVER-REVENUE — the split is fully booked on both sides.** **Given** the first-mover band
  (`first_movers` 2, `entry_fee_revenue_percentage` p), **When** members 11..12 buy in, **Then** per first-mover
  the house gains `8 − pool_keys` keys (reason `"revenue"`) AND the pool rose by `pool_keys × 10` 💎, where
  `pool_keys = div(8×(100−p), 100)` (`economy.ex:47`, floored in keys) is the **one** value both sides derive
  from (PF-3) — the two summing (in keys) to the 8-key fee, exactly.
- **S-FULL-REVENUE.** **Given** a member beyond the band (ordinal > `start_threshold+first_movers`), **When**
  they buy in, **Then** the house gains `+8` keys (reason `"revenue"`) and the pool is unchanged.
- **S-DOUBLE-ENTRY-BALANCE — the headline.** **Given** any sequence of N buy-ins + the seed, **When** they
  complete, **Then** `Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)` — the
  three-term conservation identity over **three observable columns** (the `players.keys` deltas, the
  `revenue_ledger` credits, `games.prize_pool` 💎 ÷ 10); the books balance by **conservation** at the entry
  unit (explicitly **not** `Σ all-ledger-rows = 0`, `D-3`); no key minted or lost (the ×10 is the one
  accounted minting boundary). Proven by a property test.
- **S-VOID-RECLAIM.** **Given** a never-fills Golden Room past `room_deadline`, **When** `close_void` fires (and
  re-fires on a second tick), **Then** the house holds **exactly one** `"deposit_reclaim"` credit of
  **`+V/10`** keys (the *seed-cancelling* amount — **NOT** `Σ kept fees + seed`, which double-counts the
  already-booked fees; `D-4`/PF-4), so the house net is `Σ kept fees`; **no player is refunded** (cm.5 `D-7`);
  the reclaim is **idempotent** under the existing `SET cm:<game>:closed NX` close lock; the books balance by
  conservation.
- **S-ATOMIC-DOUBLE-ENTRY.** **Given** a buy-in, **When** the transaction commits, **Then** the player debit AND
  the house `revenue_ledger` credit AND the pool increment are **all present or all absent** (a crash leaves no
  half-entry — one `Repo.transaction` under the games-row lock; no new lock, no new race). The buy-in now mints
  **two** ids per call (the `TXN` `delta:0` marker + the `RVL` revenue row, PF-6) → the ≥100 determinism loop
  is the guard for the new same-ms contention.
- **S-RECONCILE — explicit equals implicit.** **Given** a closed Golden Room, **When** finance reads the
  reconciliation query (`Wallet.house_balance(game)`, grouped by reason), **Then** the house balance for the
  game equals the five-way breakdown `seed_debit + deposit-recovery + first-mover-revenue + full-revenue +
  reclaim`, and **matches the conservation figure cm.5 derives implicitly** (`Σ fee_i − Σ pool_💎_i / 10`) —
  the same number, now a row; proven by a property test against a **cm.5-only computation** (the player debits
  + pool 💎 the shipped build already produces, untouched under the overlay).
- **S-EXISTING-GREEN — additive, not a money change.** **Given** the shipped cm.5 build, **When** cm.6's credits
  are added, **Then** the cm.5 stories (the pool figures — S-FIRSTMOVER, S-SPLIT, S-VIRTUALDEPOSIT) **stay green
  untouched**: the house credit makes the implicit explicit; it does not move money differently.

## The rung (placement + risk)

- **cm.6 — the revenue ledger** = the first slice of the **BNK bank** (the roadmap `cm.6+` bucket). Successor to
  cm.5; predecessor to the BNK **rake** + **withdrawal** (which operate on the house account this rung defines).
- **Risk: HIGH** — real (withdrawable) money + a new schema surface (the house account) + a balance invariant →
  **L2 Squad, Apollo mandatory, Venus-Postgres** on the relational/house-account redesign, the **≥100
  determinism loop**, the **migration up/down** + fresh reinit. A data-model rung (the house representation).
- **Build via** `/codemojex-ship cm.6`. The build-time forks are **ruled** (the design phase is closed): the
  house representation is a dedicated `revenue_ledger` table (`D-1`, over the row-less sentinel `PLR`), the
  unit is keys (`D-2`, over a normalized-currency ledger), the entry side is an additive overlay (`D-3`, over
  reconciling the buy-in path). See [§ Rulings](#rulings-cm-6-d-1d-7-locked).

---

## Forward: the multi-currency ledger (cm.7 pay-in · cm.8 withdrawal)

> **A forward-compat DESIGN NOTE — cm.6's code stays BYTE-FROZEN.** The Operator broadened the economy after
> cm.6's build (TON, USDT, RUB as real-money rails — `cm-7` ledger `D-1`/`D-2`). This section records that the
> as-built `revenue_ledger` **already** receives those rails and the forward withdrawal debits **with zero
> DDL** — it changes **no** schema, **no** booking call, **no** `revenue_ledger.ex` / the migration /
> `wallet.ex` / `rooms.ex` line. It is a pointer for the cm.7 author and finance, not a re-opening of `D-1`.
> The relational + minor-unit detail is the cm.7 triad ([`cm.7.md`](./cm.7.md)).

cm.6 founded the `revenue_ledger` as a **signed, multi-source / multi-currency** house ledger precisely so the
next rungs plug in without a re-design (`D-5`, S11). Three facts make the broadened economy land into the
shipped schema unchanged:

1. **The `currency` string is free, and `house_balance` already groups by it.** `Wallet.house_balance/1`
   (`wallet.ex:325`) is `SUM(delta) GROUP BY currency` — a `currency="ton"` purchase row sums into its **own
   bucket** with **no read change** (the multi-currency seam, exactly as S11 forecast). The Golden cuts are
   `currency="keys"` today; cm.7 adds `"stars"` / `"ton"` / `"usdt"` / `"rub"` purchase rows
   (`account="platform"`, `reason="purchase"` — the house account, so `house_balance`'s `WHERE account="platform"`
   filter sees them; **not** `account="purchase"`, which it would hide — cm.7 `D-3`); cm.8 adds withdrawal
   **debits** in the rail currency. The read returns
   `%{"keys" => …, "stars" => …, "ton" => …, …}` — one exact bucket per currency, the same query.

2. **The minor-unit convention per currency (the `:bigint` `delta` carries the native smallest unit).** The
   `delta` is a **signed `:bigint`** (the Ecto `:integer` in `revenue_ledger.ex` over the migration's `bigint`,
   widened in `cm-6` `D-8b` for withdrawal scale). Every rail books its **gross amount in its own native minor
   unit, integer-exact** — no normalization at write (the `D-2` discipline: store exact, convert at read; a
   per-write currency normalization is exactly the lossy step `D-2` forbids):

   | Rail / currency | `currency` string | minor unit | 1 major = N minor | decimals |
   |---|---|---|---:|---:|
   | Telegram Stars (XTR) | `"stars"` | star | 1 | 0 |
   | Toncoin | `"ton"` | nanoTON | 1 000 000 000 | 9 |
   | Tether USD | `"usdt"` | micro-USDT | 1 000 000 | 6 |
   | Russian rouble | `"rub"` | kopeck | 100 | 2 |
   | (internal) keys | `"keys"` | key | 1 | 0 |
   | (internal) USD cents | `"cents"` | cent | 1 | 0 (read-time roll-up only) |

   The `:bigint` holds every rail with comfortable headroom (a ~130-TON top-bundle whale = `1.3 × 10¹¹`
   nanoTON, far under the `~9.2 × 10¹⁸` `:bigint` ceiling). The single-number USD revenue view finance wants is
   a **read-time roll-up** (each bucket × its rate), computed in the cm.7 pure `KeyShop` module — **never** a
   stored, rate-baked total (that would destroy the audit: the received amount must stay reproducible).

3. **The withdrawal-debit seam (cm.8) — NAMED, not built.** A cash-out is the house **paying out**: a
   **negative** `revenue_ledger.delta` in the **rail currency** (`account="payout"`/`"withdrawal"`,
   `reason="cash_out"`, `ref=` the withdrawal id), booked through the **same** `Wallet.house_post/5`
   (`wallet.ex:482`) — the exact primitive the seed debit (SEAM-1) already uses, no new ledger verb. The house
   legitimately swings **negative** on a payout, which the ledger admits because it carries **no** non-negative
   CHECK (`D-1`) — the same property the `deposit_seed` debit relies on. The floating diamonds→rail conversion
   rate is **pinned on the withdrawal record at request time** (the rate-at-time discipline, shared with the
   cm.7 order rate-pin) so a booked payout is reproducible. cm.8 is the rung that builds this (with KYC/AML, the
   21-day hold, the rates surface); cm.6's ledger is the floor it debits.

**Net:** the broadened economy is **additive booking into the shipped `revenue_ledger`** — new `currency`
strings, new `account` values, signed `delta`s in native minor units. cm.6 is byte-frozen; cm.7 books the
pay-in rows; cm.8 books the withdrawal debits. The seam `D-5`/S11 promised is exactly the seam they use.

---

## Rulings (cm-6 D-1..D-7, locked)

The dual-architect debate (the **minimal-ledger steward** lens, [`cm.6.design.a.md`](./cm.6.design.a.md), vs
the **bank-architect / finance** lens, [`cm.6.design.b.md`](./cm.6.design.b.md), staged in
[`cm.6.design.consolidation.md`](./cm.6.design.consolidation.md)) is closed. The Operator ruled; the
build converges on these — it does **not** re-debate them. The argued background remains in the design docs;
this section is authoritative for the build.

- **`D-1` · F1 the house representation → a dedicated `revenue_ledger` table** (Arm 2, over the row-less
  sentinel `PLR`). A signed table mirroring `transactions` with **no non-negative CHECK** (the house
  legitimately swings negative on the seed — proven at the void: a voided room holds `−seed + Σ recovery`,
  `Σ recovery < seed`), designed **multi-source / multi-currency** from the start:
  `{id (RVL), account/source, currency, delta (signed bigint), reason, ref, inserted_at}`. *Chosen against the
  sentinel `PLR`:* the actor-conflation footgun compounds across ≥2 revenue sources (the cm.7 packages input)
  and commingles platform revenue in the player ledger the bank must later untangle. The reversibility seam
  (`Wallet.house_post` / `house_balance`) is kept regardless — the call sites bind to it.
- **`D-2` · F2 the ledger unit → keys** (the Golden conservation unit); the ledger is **multi-currency** via
  its `currency` field (golden cuts in `"keys"`; cm.7 purchases in `"stars"`/`"cents"`). Keys is the unit the
  balance invariant is exact in — the split floors in keys **before** the ×10 (`economy.ex:42,47`), so
  `house_keys + pool_keys == entry_fee_keys` with zero residue; 💎/¢ is a **pure read-time** conversion
  (`Economy.diamonds_for_keys` / `to_cents`, `economy.ex:19-22`), never a per-write lossy step. *Chosen
  against* normalizing every row to one unit (would re-denominate the cm.5 keys debit + spread the conversion
  to every row).
- **`D-3` · F3 the entry side → an additive overlay + a MANDATORY conservation-honesty statement.** cm.5's
  buy-in shape stays **byte-for-byte** — the `delta:0` `buy_in` marker (the exactly-once authority), the bare
  `keys -= fee` debit (`wallet.ex:226`), the `inc_pool!` games-column `+` (`wallet.ex:371`); cm.6 ADDS house
  `revenue_ledger` rows in the same `Repo.transaction`. **The mandatory item:** the spec **states plainly** it
  balances by CONSERVATION — `Σ player_key_debits == Σ house_key_credits + Σ pool_key_portions` over three
  observable columns — **NOT** by `Σ all-ledger-rows = 0`, and **names** "reconcile the entry legs into signed
  rows + a pool account" as the explicit **deferred** bank rung. *Chosen against* reconciling the buy-in path
  now (edits the exactly-once marker + the prize_pool column every cm.5 finish/void reads — money-critical
  regression, Scope-Out, `S-EXISTING-GREEN` forbids).
- **`D-4` · the seams.** **SEAM-1 (the seed) → WRAP:** the golden seed lands via a bare `Store.put_game`
  (`rooms.ex:136`), not a `Repo.transaction`; Mars wraps the games-row seed write + the `deposit_seed` debit
  in **one** `Repo.transaction` (the lone overlay exception that touches a cm.5 site). **SEAM-2 (the void) →
  `+seed` ONLY:** `close_void` (`rooms.ex:462-472`) moves no money today; a voided room only took
  deposit-recovery-band buy-ins whose fees are already booked — so the reclaim books `+div(V,10)` (cancelling
  the seed), house net = `Σ kept fees`, under the existing NX close lock. *Chosen against* `Σ fees + seed` (a
  double-count of the already-booked fees — PF-4, money-critical).
- **`D-5` · scope → the cm.6 / cm.7 split.** cm.6 = the Golden-Room revenue ledger on the Arm-2 substrate,
  *designed* multi-source/multi-currency so the next rung plugs in with no ledger re-design. **cm.7 = the
  KeyShop:** a `packages` catalog table + the Telegram XTR invoice flow (exactly-once on the charge id) + a
  pure `KeyShop` pricing module + booking gross-Stars purchase revenue into the *same* `revenue_ledger`
  (`source="purchase"`, `currency="stars"`). *Chosen against* folding packages into cm.6 (balloons the money
  rung's blast radius; the Arm-2 ledger makes the split free).
- **`D-6` · brand → `RVL`.** The `revenue_ledger` row id is a new 3-char branded namespace `RVL`
  (`EchoData.BrandedId.generate!("RVL")`), so revenue rows are type-distinguishable from player `TXN` rows at
  every boundary (the BCS law: the brand IS the type). *Chosen against* reusing the `TXN` brand.
- **`D-7` · the build-grade seam contract** (Venus-Triad — derived from the rulings, not a re-decided fork).
  The five credit sites + the reconciliation read bind to `Wallet.house_post(account, currency, delta_keys,
  reason, ref)` — the Arm-2 analogue of the private `txn!` (`wallet.ex:380`): insert one signed
  `revenue_ledger` row (`generate!("RVL")`), no balance column, **not** the players-row `credit`
  (`wallet.ex:305-320`). Plus `Economy.entry_fee_split_keys/5` (a new pure fn returning the keys pool portion
  so the house cut + the pool 💎 derive from the one floor) and `Wallet.house_balance/0..1` (the reconciliation
  read). See the Build brief.

---

## Build brief (the agent stories + the file:line map + the build order)

> For Mars. Forward-tense, NO-INVENT — every public call grounds in a real module/site (live-verified this
> session) or is marked forward. Venus-Postgres authors the relational design + migration
> ([`cm.6.postgres.design.md`](./cm.6.postgres.design.md)) to the `D-1`/`D-6` column contract; Mars wires the
> Elixir side to the same contract (coordinate by constraint).

### The five insertion sites (live `file:line`, re-grounded this session)

| Movement | Site | House `revenue_ledger` post (keys) | In `Repo.transaction`? |
|---|---|---|---|
| `deposit_seed` | `Rooms.formation/3` golden seed `rooms.ex:171-178` (bare `Store.put_game(gid, game)` `rooms.ex:136`) | `−div(virtual_deposit, 10)` | **SEAM-1 — wrap** (`D-4`) |
| `deposit_recovery` (ord ≤ threshold) | `Wallet.buy_in/2` `:wrote` branch `wallet.ex:224-238` (bare debit `:226`) | `+entry_fee_keys` | YES — inside `buy_in` (`wallet.ex:204`) |
| first-mover `revenue` (band) | same branch + `inc_pool!` `wallet.ex:237` | `+(entry_fee_keys − pool_keys)` | YES |
| full `revenue` (ord > band) | same branch `wallet.ex:224-238` | `+entry_fee_keys` | YES |
| `deposit_reclaim` (void) | `Rooms.close_void/2` `rooms.ex:462-472` (NX lock `:463`) | `+div(virtual_deposit, 10)` (seed-cancelling) | **SEAM-2 — under the NX lock** (`D-4`) |

The three buy-in credits add **one** `house_post(...)` call on the `:wrote` branch (the reason + the keys
amount switch on the `entry_fee_split` band — all three in one branch addition), computing the cut from the
`ordinal` / `entry_fee_split` inputs already in scope. `pool_keys = div(entry_fee_keys × (100−rev%), 100)`
(`economy.ex:47`); the house cut is the exact-integer complement `entry_fee_keys − pool_keys`; the pool 💎 is
`pool_keys × 10` — both from the **one** floor (expose `Economy.entry_fee_split_keys/5`; `entry_fee_split/5`,
the 💎 fn at `economy.ex:45-52`, stays byte-unchanged).

### Build-precision flags (NO-INVENT — confirm each against the as-built before wiring)

- **PF-1 (translated to Arm 2) · the house credit is a `revenue_ledger` insert, not a `players` credit.**
  `Wallet.house_post` inserts a signed `revenue_ledger` row (id `generate!("RVL")`, `D-6`) — the Arm-2
  analogue of the private `txn!` (`wallet.ex:380`, "insert a signed row, touch no balance column"), landing in
  `revenue_ledger`, **not** `transactions`, and **not** the players-row `credit` (`wallet.ex:305-320`, which
  locks + `update!`s a `players` row → would require a house row + re-break the non-negative collision). **The
  single most important wiring fact.**
- **PF-3 · the first-mover house cut is `entry_fee_keys − pool_keys`** (exact integer subtraction, NOT a
  re-floor and NOT recomputed from 💎 — recomputing `entry_fee_split/10` risks a ÷ rounding mismatch).
- **PF-4 · SEAM-2 reclaim books `+seed`, not `Σ fees + seed`** (the kept fees are already booked at buy-in;
  `Σ fees + seed` double-counts — money-critical).
- **PF-5 · SEAM-1 is cross-store** (the Valkey pool field + the Postgres house row). The wrap (`D-4`) brings
  the games-row seed write + the house debit into one `Repo.transaction`; state the determinism posture for
  the pool field (do **not** claim ACID across the two stores). Build-time: spot-read `Store.put_game`'s
  Postgres composition to confirm the wrap point.
- **PF-6 · two id mints per buy-in now** (the `TXN` `delta:0` marker `wallet.ex:348` + the `RVL` revenue row)
  → the new same-ms contention surface; the **≥100 determinism loop is mandatory** and its posture statement
  must name this.
- **PF-7 · the reconciliation read is a pure `SUM`** — `SUM(delta) FROM revenue_ledger WHERE account=house
  [AND ref=game] GROUP BY currency[, reason]`, reusing the `from t in …` shape of `buy_in_count`
  (`wallet.ex:330`); no schema, no cross-store read.

### The seam (the representation-reversible interface — `D-7`)

- `Wallet.house_post(account, currency, delta_keys, reason, ref)` — the single house signed-row primitive;
  reachable from the buy-in sites (inside `Wallet`) and from `Rooms` (SEAM-1/SEAM-2, via a public
  `Wallet.book_house` boundary fn — keeps the primitive single, behind `Wallet`).
- `Wallet.house_balance/0..1` — the reconciliation read (`house_balance()` → per-currency total;
  `house_balance(game)` → per-game, grouped by reason).
- `Economy.entry_fee_split_keys/5` — the pure keys-pool-portion fn.
- The house account constant (`account="platform"`); confirm the `revenue_ledger` schema + the `RVL` mint
  shape against `EchoData.BrandedId` (a fixed-shape `generate!("RVL")`, mirroring the existing
  GAM/ROM/PLR/TXN/GES mints).

### The smallest-change build order

1. **Venus-Postgres** authors `cm.6.postgres.design.md` + the additive migration creating `revenue_ledger`
   (`down: drop table`); `schemas/revenue_ledger.ex` (the changeset; signed `delta`, no non-negative CHECK).
2. **`Economy.entry_fee_split_keys/5`** (pure; the keys pool portion) — `entry_fee_split/5` byte-unchanged.
3. **`Wallet.house_post` + `house_balance/0..1`** (+ the public `book_house` boundary fn for `Rooms`).
4. **The three buy-in credits** — one `house_post` call on the `:wrote` branch (`wallet.ex:224-238`), inside
   the existing `Repo.transaction`.
5. **SEAM-1** — wrap the golden-seed write (`rooms.ex:136` / `formation` `rooms.ex:171-178`) + the
   `deposit_seed` debit in one `Repo.transaction`.
6. **SEAM-2** — the `deposit_reclaim` `+seed` credit in `close_void` (`rooms.ex:462-472`), under the NX lock,
   idempotent.
7. **The stories** (`test/stories/`) + the conservation-honesty statement (`D-3`); `mix codemojex.stories`
   regenerates the per-feature faces.

### The gate ladder (from `echo/apps/codemojex`, NEVER umbrella-wide)

`asdf current` (re-probe; Elixir 1.18.4 / Erlang 28.5.0.1) · `valkey-cli -p 6390 ping` → `PONG` ·
`pg_isready` · `TMPDIR=/tmp mix compile --warnings-as-errors` · `TMPDIR=/tmp mix test --include valkey`
(boots the full tree — **both** Valkey 6390 **and** Postgres) · the schema reinit
`MIX_ENV=test mix ecto.drop && ecto.create && ecto.migrate` scoped to the **`config/test.exs`** DB
(`codemojex_test`, read it — never assume; surface the target before the drop) + the migration up/down proof ·
the **≥100** determinism loop (`for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break;
done`) · the cm.5 story suites byte-unchanged (`git diff --stat`) + the three shipped migrations byte-frozen ·
the privacy line holds · boundary ⊆ `echo/apps/codemojex/**` + the rung docs · `mix.lock` untouched.
