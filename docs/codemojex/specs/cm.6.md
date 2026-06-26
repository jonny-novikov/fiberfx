# cm.6 — The Revenue Ledger (explicit house-account double-entry)

> **The first slice of the BNK bank** (the roadmap `cm.6+` bucket) and the named follow-on to **cm.5**. cm.5
> ships the Golden Room revenue ledger **implicitly** — the platform's cut is recorded *by conservation* (the
> entry fee leaves the player + the pool is not incremented = the platform's), with no explicit house-account
> row (`cm-5` ledger `D-15`, the Operator's "ship implicit now"). This rung makes the revenue side **explicit
> balanced double-entry**: a house account that receives the platform's cut as its own `TXN` rows, so platform
> revenue is a first-class, queryable, reconcilable balance. Grounded NO-INVENT in the cm.5 as-built money
> paths (`Codemojex.Wallet` / `Economy.entry_fee_split` / the `transactions` ledger); **forward-tense** for the
> unbuilt house-account surface. This is a **design brief**, not yet a build — Venus/VenusPG refine it at
> `/codemojex-ship cm.6`.

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
real credit `TXN` to a house account, so (a) **Σ all `TXN`s balances to zero** per currency at the entry unit
(the double-entry invariant), (b) platform revenue is a **single queryable balance**, and (c) finance/audit
reconcile the books without re-deriving by conservation. It is also the **foundation the BNK bank builds on** —
a rake debits the pool and credits this house account; a withdrawal debits it.

## 5W

- **WHO** — a new **house/platform account** is the credit counterparty for every platform cut; the team that
  builds it is the L2 Squad (Director + Venus + Venus-Postgres + Mars + Apollo — a money + schema rung).
- **WHAT** — an explicit house account + a **paired platform-credit `TXN`** for every revenue movement cm.5
  records implicitly (the virtual-deposit seed, the deposit-recovery, the first-mover platform share, the
  full-revenue tiers, the void deposit-reclaim), each in the **same `Repo.transaction`** as the player debit, so
  the revenue side is **atomic balanced double-entry**.
- **WHY** — auditability + reconciliation + the *complete* best-practices ledger (the Operator's intent); a
  queryable platform-revenue balance; the BNK bank's foundation (rake / payouts / withdrawal credit/debit this
  account).
- **WHERE** — `echo/apps/codemojex` only: `Codemojex.Wallet` (the `TXN` authority), `schemas/transaction.ex`
  (+ the house-account representation), the `buy_in` (`wallet.ex:203`) + `close_void` (`rooms.ex`, cm.5) + the
  `start_game` golden-seed (`rooms.ex:68`, cm.5) paths (the credit/debit insertion points), and a new
  reconciliation read in `Wallet`/`Store`. No sibling umbrella app; `mix.lock` excluded.
- **WHEN** — after cm.5 ships (it depends on cm.5's waterfall + the `transactions` ledger); **before** the BNK
  rake/withdrawal (which operate on the house account this rung defines).

## Scope In

1. **The house account** — a reserved system actor that holds platform revenue. *Build-time fork (framed, ruled
   at the rung's Stage 1):* a **reserved system `PLR` id** (lightest — reuse the `transactions` ledger + the
   `players` non-negative discipline, a sentinel house player) **vs** a dedicated **`revenue_ledger` table**
   (cleaner separation, more schema). Venus-Postgres frames the relational shape.
2. **The virtual-deposit SEED as a house debit** — at golden `start_game`, the platform funds `prize_pool =
   virtual_deposit` (diamonds); record the funding as a **house debit** of `virtual_deposit / 10` keys-equiv
   (reason `"deposit_seed"`, ref=game) paired with the pool credit, so the seed is a real platform outlay (not
   a free pool).
3. **The paired platform-credit `TXN`** at each cm.5 revenue movement, in the **same `Repo.transaction`** as the
   player debit (atomic double-entry), keyed `ref=game`:
   - **deposit-recovery** (members `1..start_threshold`) → credit the house the full `entry_fee_keys` (reason
     `"deposit_recovery"`);
   - **first-mover share** (members `start_threshold+1 .. +first_movers`) → credit the house
     `entry_fee_keys − floor(entry_fee_keys × (100−revenue%)/100)` keys (reason `"revenue"`) — the **complement
     of the pool portion** `Economy.entry_fee_split` already computes;
   - **full revenue** (members beyond) → credit the house the full `entry_fee_keys` (reason `"revenue"`);
   - **void deposit-reclaim** (`close_void`) → credit the house the kept fees + the reclaimed-but-unpaid seed
     (reason `"deposit_reclaim"`).
4. **The keys-unit balance invariant** — at each entry, `entry_fee_keys = house_credit_keys + pool_portion_keys`
   (the pool's keys→💎 ×10 is an explicit *conversion/minting* entry at the pool boundary, not a leak). Σ over
   the game: `Σ player debits = Σ house credits + Σ pool conversions` at the keys unit; the seed debit cancels
   the recovery credits (the zero-loss, now explicit).
5. **A reconciliation read** — a `Wallet`/`Store` query returning the house balance + a per-game revenue
   breakdown (seed / deposit-recovery / first-mover / full-revenue / reclaim), so revenue is **queried**, not
   re-derived.
6. **The migration + schema** for the house representation; the gate ladder. The credit rides the buy-in's
   existing **games-row-`FOR UPDATE`-locked** transaction (cm.5 `RULING 1`), so it inherits the G1 ordinal
   serialization — no new lock, no new race.

## Scope Out

- **The BNK rake / fee model** (a platform cut *of the pool*) — a later BNK slice; this rung *records* revenue,
  it introduces **no new fee** and changes **no cm.5 amount**.
- **Withdrawal / cash-out** of the house balance (the platform's real-money settlement) — a later BNK slice.
- **Non-golden room economics** — cm.5's guess→pool is golden-only and non-golden rooms keep their shipped
  charge; this rung's scope is the **Golden Room** revenue tiers + the seed + the void reclaim (the
  cm.5-introduced flows). A platform-wide revenue ledger over *all* sources is the BNK vision, not this slice.
- **Retroactive backfill** of pre-cm.6 implicit revenue into explicit rows — **forward-only**; the house account
  starts at cm.6 (the discontinuity is noted for finance).
- **Any cm.5-resolved surface** (`gold_multiplier`, the no-refund void, the pool denomination, the
  distribution double-entry) — untouched; cm.6 is purely additive on the revenue side.

## Acceptance

- **The double-entry BALANCE invariant proven:** for any sequence of buy-ins + a close, `Σ keys (player debits)
  = Σ keys (house credits) + Σ keys (pool conversions)` at the entry unit; the house balance equals the sum of
  the platform cuts; **no key minted or lost** (the ×10 conversion is the one accounted minting boundary).
- **Atomicity:** the platform-credit `TXN` is in the **same `Repo.transaction`** as the player debit + the pool
  increment — a partial double-entry is impossible; it inherits the games-row lock → no mis-credit under
  concurrency.
- **Equivalence to cm.5:** the reconciliation read's house figure **equals the conservation figure cm.5 leaves
  implicit** — cm.6 makes the *same* number explicit, never a different one (proven by a property test against a
  cm.5-only computation).
- **The migration up/down clean** (+ the destructive gate if a column/table is dropped); fresh reinit on
  `codemojex_test` (surface the DB target first); both shipped migrations **and** the cm.5 `golden_rooms`
  migration **byte-frozen**.
- `mix test --include valkey` green incl. the new revenue-ledger stories; **the cm.5 suite stays green
  untouched** (the house credit is additive — the pool/player figures are unchanged); the **≥100 determinism
  loop** (reinit-per-iter) clean; the boundary ⊆ `echo/apps/codemojex/**` + the rung docs; `mix.lock` untouched.
- **Apollo BUILD-GRADE** (money-critical): the §11.2 charter — the balance-invariant table at `file:line`, ≥1
  un-prompted finding, ≥1 attack-that-held, a mutation kill-rate.

## Given / When / Then

- **S-SEED — the virtual deposit is a real platform outlay.** *As finance, I want the seeded pool booked as a
  platform cost, not free money.* **Given** a Golden Room (`virtual_deposit` V💎), **When** the golden game
  forms, **Then** the house holds a `"deposit_seed"` debit of `V/10` keys-equiv (ref=game) and the pool holds
  `V` 💎 — paired and atomic.
- **S-DEPOSIT-RECOVERY — the first-10 fees are recorded revenue.** **Given** a Golden Room (`entry_fee_keys` 8,
  `start_threshold` 10), **When** members 1..10 each buy in, **Then** the house gains `+8` keys per member
  (reason `"deposit_recovery"`), the pool is unchanged (still V), `player.keys` fell by 8 each — and the house's
  *net* after 10 recoveries equals `Σ recovery − seed` (≈ 0, the zero-loss made explicit).
- **S-FIRSTMOVER-REVENUE — the split is fully booked on both sides.** **Given** the first-mover band
  (`first_movers` 2, `entry_fee_revenue_percentage` p), **When** members 11..12 buy in, **Then** per first-mover
  the house gains `8 − floor(8×(100−p)/100)` keys (reason `"revenue"`) AND the pool rose by
  `floor(8×(100−p)/100)×10` 💎 — the two summing (in keys) to the 8-key fee, exactly.
- **S-FULL-REVENUE.** **Given** a member beyond the band (ordinal > `start_threshold+first_movers`), **When**
  they buy in, **Then** the house gains `+8` keys (reason `"revenue"`) and the pool is unchanged.
- **S-DOUBLE-ENTRY-BALANCE — the headline.** **Given** any sequence of N buy-ins + the seed, **When** they
  complete, **Then** `Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)` — the
  ledger balances to zero keys at the entry unit; no key minted or lost.
- **S-VOID-RECLAIM.** **Given** a never-fills Golden Room past `room_deadline`, **When** `close_void` fires,
  **Then** the house holds a `"deposit_reclaim"` credit covering the kept fees + the unpaid seed, **no player is
  refunded** (cm.5 `D-7`), and the books balance to zero.
- **S-ATOMIC-DOUBLE-ENTRY.** **Given** a buy-in, **When** the transaction commits, **Then** the player debit AND
  the house credit AND the pool increment are **all present or all absent** (a crash leaves no half-entry — one
  `Repo.transaction` under the games-row lock).
- **S-RECONCILE — explicit equals implicit.** **Given** a closed Golden Room, **When** finance reads the
  reconciliation query, **Then** the house balance for the game equals `seed_debit + deposit-recovery +
  first-mover-revenue + full-revenue + reclaim`, and **matches the conservation figure cm.5 derives implicitly**
  (the same number, now a row).
- **S-EXISTING-GREEN — additive, not a money change.** **Given** the shipped cm.5 build, **When** cm.6's credits
  are added, **Then** the cm.5 stories (the pool figures — S-FIRSTMOVER, S-SPLIT, S-VIRTUALDEPOSIT) **stay green
  untouched**: the house credit makes the implicit explicit; it does not move money differently.

## The rung (placement + risk)

- **cm.6 — the revenue ledger** = the first slice of the **BNK bank** (the roadmap `cm.6+` bucket). Successor to
  cm.5; predecessor to the BNK **rake** + **withdrawal** (which operate on the house account this rung defines).
- **Risk: HIGH** — real (withdrawable) money + a new schema surface (the house account) + a balance invariant →
  **L2 Squad, Apollo mandatory, Venus-Postgres** on the relational/house-account redesign, the **≥100
  determinism loop**, the **migration up/down** + fresh reinit. A data-model rung (the house representation).
- **Build via** `/codemojex-ship cm.6` when scheduled. The two open build-time forks (the house representation —
  a system `PLR` vs a `revenue_ledger` table; the keys-unit vs a normalized-currency ledger) are framed for the
  Stage-1 dual-architect ruling, not decided here.
