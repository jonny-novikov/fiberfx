# cm.6 — Stories (the acceptance face)

> The Operator's verifiable acceptance for cm.6, derived from [`cm.6.md`](./cm.6.md) (the body wins on any
> disagreement) and the locked rulings (`cm-6` ledger `D-1..D-7`). The model is the **ruled** dedicated
> `revenue_ledger` table (`D-1`, Arm 2): a signed, multi-source/multi-currency platform-revenue ledger with
> **no non-negative CHECK**, holding the Golden Room cuts in **keys** (`D-2`) as an **additive overlay** on
> cm.5's byte-frozen buy-in path (`D-3`). Each story is Connextra + Given/When/Then; each names the
> invariant(s) it exercises and the surface that closes it. A gate must **exercise** its outcome — a no-op
> must not satisfy a story's letter.
>
> Framing: third person; no first-person-agent narration; no perceptual / interior-state verbs; **forward-tense**
> for the unbuilt house-account surface (`Wallet.house_post` / `house_balance` / the `revenue_ledger` table).

## Roles

- **Finance** — reads the platform's books: wants every platform cut to be a real, queryable, reconcilable
  row, not a number re-derived by conservation. Accepts the conservation-honesty statement (`D-3`).
- **The Operator** — accepts the rung; signs off the balance invariant, the explicit==implicit equivalence,
  the byte-unchanged cm.5 suite, and the migration up/down.
- **A concurrent buyer** — two players buying into the same Golden Room at the same instant; the games-row
  `FOR UPDATE` lock (cm.5 `RULING 1`) serializes them, and cm.6's house row rides that same lock.
- **The BNK bank** — a forward-vision consumer (the rake · the withdrawal) that binds to the
  `revenue_ledger` `account="platform"` balance this rung founds. **Named** so the ledger's multi-source
  shape is sufficient; the bank is **not** built this rung (`D-5`).
- **The KeyShop (cm.7)** — the sibling rung that books Stars/cents **purchase** revenue into the *same*
  `revenue_ledger` (`source="purchase"`, `currency="stars"`). Named so the multi-currency design is
  exercised in shape; **not** built this rung (`D-5`).

---

## S1 — The virtual deposit is a real platform outlay (the seed debit)

*As Finance, I want the seeded Golden Room pool booked as a platform cost, not free money, so that the
platform's exposure is a visible negative balance until the recoveries land.*

**Exercises:** the seed movement (`deposit_seed`); SEAM-1 (the wrap, `D-4`); the signed (negative-admitting)
ledger (`D-1`). **Surface:** `Rooms.formation/3` golden seed (`rooms.ex:171-178`, the bare
`Store.put_game(gid, game)` at `rooms.ex:136`) → a public `Wallet.book_house`/`house_post` (`D-7`) booking a
`revenue_ledger` row, wrapped per SEAM-1.

- **Given** a Golden Room with `virtual_deposit` = V💎
- **When** the golden game forms (the seed write)
- **Then** the house holds a `"deposit_seed"` **debit** of `−div(V, 10)` keys in `revenue_ledger`
  (`account="platform"`, `currency="keys"`, `ref=game`), and the pool holds `V` 💎,
- **And** the house balance for the game is **negative** at this instant (the seed precedes any recovery) —
  the `revenue_ledger` admits it because it carries **no** non-negative CHECK (`D-1`), where a `players` row
  could not (`players_non_negative`, `player.ex:43-47`),
- **And** the seed games-row write and the `deposit_seed` debit are wrapped in **one** `Repo.transaction`
  (SEAM-1, `D-4`) — the lone overlay exception that touches a cm.5 path; the determinism posture for the
  cross-store pool field (Valkey) vs the Postgres row is stated, not claimed as ACID across stores.

## S2 — The first-ten fees are recorded revenue (deposit-recovery)

*As Finance, I want each deposit-recovery-band buy-in to credit the house its full fee, so that the seed is
recovered as explicit rows and the house climbs back toward zero.*

**Exercises:** the `deposit_recovery` movement; the keys unit (`D-2`); the additive overlay (`D-3`); atomic
double-entry. **Surface:** `Wallet.buy_in/2` `:wrote` branch (`wallet.ex:224-238`) → `house_post(house,
"keys", +fee, "deposit_recovery", game)` inside the existing `Repo.transaction` (`wallet.ex:204`).

- **Given** a Golden Room (`entry_fee_keys` 8, `start_threshold` 10)
- **When** members 1..10 each buy in
- **Then** the house gains a `+8` keys credit per member (reason `"deposit_recovery"`, `ref=game`) in
  `revenue_ledger`,
- **And** the pool is **unchanged** (still V — `entry_fee_split` returns 0 in this band, `economy.ex:51-52`),
- **And** `player.keys` fell by 8 for each member (the cm.5 bare debit, `wallet.ex:226`, **untouched**),
- **And** the house **net** after the 10 recoveries equals `Σ recovery − div(V,10)` (≈ 0, the zero-loss made
  explicit; the exact residual is whatever the seed/threshold configuration leaves — now a visible balance,
  not an implicit gap).

## S3 — The first-mover split is fully booked on both sides

*As Finance, I want each first-mover buy-in's fee split booked as a house credit **and** a pool conversion
that sum exactly to the fee, so that the platform share and the pool share are both explicit and conserve.*

**Exercises:** the first-mover `revenue` movement; the keys-unit exact partition (`D-2`); `pool_keys` reuse
(PF-3); atomic double-entry. **Surface:** `Wallet.buy_in/2` (`wallet.ex:228-237`) → `house_post(house,
"keys", +(fee − pool_keys), "revenue", game)` paired with the existing `inc_pool!` (`wallet.ex:237`), where
`pool_keys` comes from a new pure `Economy.entry_fee_split_keys/5` (`D-7`).

- **Given** the first-mover band (`first_movers` 2, `entry_fee_revenue_percentage` p)
- **When** members 11..12 buy in
- **Then** per first-mover the house gains `+(8 − pool_keys)` keys (reason `"revenue"`), where
  `pool_keys = div(8 × (100−p), 100)` (`economy.ex:47`, floored in keys),
- **And** the pool rose by `pool_keys × 10` 💎 (`economy.ex:48`) — the **same** floored `pool_keys` both
  sides derive from (no re-floor, no ÷ rounding mismatch; PF-3),
- **And** the house credit + the pool portion sum, **in keys**, to the 8-key fee **exactly**
  (`(8 − pool_keys) + pool_keys == 8`, integer, zero dust).

## S4 — Full-revenue tiers credit the whole fee

*As Finance, I want every buy-in beyond the first-mover band to credit the house its full fee with no pool
movement, so that steady-state revenue is fully explicit.*

**Exercises:** the full-`revenue` movement; the keys unit. **Surface:** `Wallet.buy_in/2`
(`wallet.ex:224-238`) → `house_post(house, "keys", +fee, "revenue", game)`.

- **Given** a member beyond the band (ordinal > `start_threshold + first_movers`)
- **When** they buy in
- **Then** the house gains `+8` keys (reason `"revenue"`, `ref=game`) in `revenue_ledger`,
- **And** the pool is **unchanged** (`entry_fee_split` returns 0 here, `economy.ex:51`).

## S5 — The double-entry balance invariant (THE headline)

*As the Operator, I want the books to balance to zero keys at the entry unit for any sequence of buy-ins, so
that the revenue side is provably conservative — no key minted or lost.*

**Exercises:** the keys-unit conservation invariant (`D-2`, `D-3`); the one accounted minting boundary.
**Surface:** a property test over `Wallet.buy_in/2` + `Wallet.house_balance/1` + `games.prize_pool`,
asserting the three-term identity.

- **Given** any sequence of N buy-ins (arbitrary `{fee, start_threshold, first_movers, rev%, N}`) **plus** the
  seed
- **When** they complete
- **Then** the **three-term keys identity** holds:
  `Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)`,
  computed over **three observable quantities** — the `players.keys` deltas, the `revenue_ledger` house
  credits, and the `games.prize_pool` 💎 ÷ 10 (`@diamonds_per_key` 10, `economy.ex:10`),
- **And** the `×10` keys→💎 at the pool boundary is the **one** accounted minting step (floor-before-×10,
  conservative to whole diamonds); everything else is keys-conserving,
- **And** the invariant is proven by **conservation over these three columns**, explicitly **NOT** by
  `Σ all-ledger-rows = 0` (`D-3` — see S9; the player debit is a bare `keys` column delta and the pool is a
  `games` column, so a naive single-table `SUM == 0` does not apply and must not be asserted).

## S6 — The void books the seed-cancelling reclaim only

*As Finance, I want a voided Golden Room to reclaim the unpaid seed and nothing more, so that the platform's
void take is exactly the fees already kept — never double-counted.*

**Exercises:** the `deposit_reclaim` movement; SEAM-2 (`+seed` only, `D-4`); the money-critical
no-double-count flag (PF-4); no-refund (cm.5 `D-7`). **Surface:** `Rooms.close_void/2` (`rooms.ex:462-472`,
under the `SET cm:<game>:closed NX` lock at `rooms.ex:463`) → `house_post(house, "keys", +div(V,10),
"deposit_reclaim", game)`.

- **Given** a never-fills Golden Room past `room_deadline` that took some deposit-recovery-band buy-ins (it
  never reached `start_threshold`)
- **When** `close_void` fires (and re-fires on a second tick)
- **Then** the house holds **exactly one** `"deposit_reclaim"` credit of `+div(V, 10)` keys (the
  seed-cancelling amount — **not** `Σ kept fees + seed`, which would double-book fees already credited at
  buy-in; PF-4),
- **And** the house **net** for the game is `Σ kept fees` (the platform's actual void take): the
  `+deposit_reclaim` cancels the `−deposit_seed`, leaving the buy-in recovery credits,
- **And** **no player is refunded** (cm.5 `D-7`), and a second tick books **no** further row (the `NX` close
  lock is the exactly-once guard — the credit is idempotent under it).

## S7 — Explicit equals implicit (the reconciliation read)

*As Finance, I want the reconciliation query's house figure to equal the conservation figure cm.5 leaves
implicit, so that cm.6 makes the **same** number explicit — never a different one.*

**Exercises:** the equivalence acceptance (the explicit==implicit property test); the reconciliation read; the
multi-currency-ready read (`D-2`). **Surface:** `Wallet.house_balance/0..1` (`D-7`) — a `SUM(delta) FROM
revenue_ledger WHERE account=house [AND ref=game] GROUP BY currency[, reason]`, reusing the `from t in …`
shape of `buy_in_count` (`wallet.ex:330`) re-aimed at the ledger table.

- **Given** a closed Golden Room (any sequence of buy-ins + the seed + an optional void)
- **When** Finance reads the per-game reconciliation query
- **Then** the house balance for the game equals the **five-way breakdown** by reason
  (`deposit_seed` / `deposit_recovery` / `revenue` / `deposit_reclaim`), so revenue is **queried**, not
  re-derived,
- **And** that house balance (in keys) **equals the conservation figure cm.5 derives implicitly** —
  `implicit_platform_keys = Σ fee_i − (Σ pool_💎_i / 10)` — proven by a property test against a
  **cm.5-only computation** (the player debits and pool 💎 the shipped cm.5 build already produces,
  untouched under the overlay): the same number, now a row,
- **And** the read groups by `currency` (it returns "keys" for golden cuts now), so a cm.7 `"stars"` purchase
  row would sum into its own currency bucket without a read change (the multi-currency shape is exercised).

## S8 — Atomic double-entry (all present or all absent)

*As the Operator, I want a buy-in's player debit, pool increment, and house credit to be all-or-nothing, so
that a crash can never leave a half-entry that mis-states revenue.*

**Exercises:** atomicity; the inherited games-row lock (cm.5 `RULING 1`); concurrency safety. **Surface:** the
single `Repo.transaction` in `Wallet.buy_in/2` (`wallet.ex:204`) under `lock_game` (`wallet.ex:205`); the
house credit is one more write inside it.

- **Given** a buy-in
- **When** the transaction commits
- **Then** the player `keys` debit **AND** the `prize_pool` increment **AND** the `revenue_ledger` house
  credit are **all present or all absent** (a rollback leaves no row, no column change),
- **And** two concurrent buyers into the same room never mis-credit the house — the house write rides the
  **same** games-row `FOR UPDATE` lock that serializes the buy-in (no new lock, no new race; cm.6.md Scope
  §6),
- **And** under the **≥100 determinism loop** (reinit-per-iter) the buy-in — now minting **two** ids per
  call (the `TXN` `delta:0` marker **and** the `RVL` revenue row, PF-6) — never forks a row or mis-counts a
  member. **Posture (VERIFIED, cm-6 `D-9` / Apollo): the `RVL` mint is COLLISION-FREE** — the
  `EchoData.Snowflake` atomics-CAS generator (a lock-free `:atomics` cell + `compare_exchange`, strictly
  monotonic: a same-ms burst increments the sequence, 4096/ms carries into the timestamp) yields a unique id
  per call. Independently re-proven by Apollo: a **200,000-mint burst in the exact dual-mint pattern (100k
  `TXN` + 100k `RVL`, `max_concurrency` 100) → 0 collisions**; sequential `RVL` ids sort by creation (the BCS
  order theorem). The two-mints-per-buy-in (PF-6) is therefore **not** a same-ms collision hazard, and the
  build needs **no** in-boundary retry (a `house_post` retry would be dead code). The full-suite `--include
  valkey` loop's only residual catch is the pre-existing **L-5** debt: the `:valkey` integration stories boot
  the full supervision tree and bypass the Ecto SQL `Sandbox` (`config/test.exs` declares it; the integration
  path commits real rows), so rows accumulate across runs and ~60 boot/teardown cycles churn the connection
  pool — a transient `42P01 undefined_table` on the cm.1 `emoji_sets` table (which cm.6 never touches,
  self-healing, never a `revenue_ledger` assertion) can surface under that load. It is a **test-hygiene debt,
  named forward, not a cm.6 mint hazard** (the misdiagnosed "same-ms RVL collision" framing is struck). The
  PF-6 hazard is correctly isolated by the dual-mint burst above, which is clean.

## S9 — The conservation-honesty statement (the mandatory acceptance item)

*As the Operator, I want the spec and the reconciliation read to state plainly that the ledger balances by
**conservation**, not by a zero-sum row total, and to name the entry-leg reconcile as a deferred rung, so
that the half-balanced state is a known debt — not a ledger that looks complete and is not.*

**Exercises:** the `D-3` mandatory honesty statement (the non-negotiable both architect lenses attached).
**Surface:** the spec body (cm.6.md Acceptance) + a documented note on the reconciliation read.

- **Given** the as-built cm.5 buy-in shape — the `delta:0` `buy_in` marker (the exactly-once authority), the
  **bare** `keys -= fee` debit (`wallet.ex:226`), and the `prize_pool` **column** (`inc_pool!`,
  `wallet.ex:371`) — all left **byte-for-byte** by cm.6 (`D-3`)
- **When** cm.6's balance and reconciliation are described
- **Then** the spec **states plainly** the ledger balances by the three-term **conservation** identity (S5),
  proven over three observable columns, and is **NOT** `Σ all-ledger-rows = 0` (the player debit is a column
  delta, the pool is a column — a naive single-table `SUM == 0` would mislead),
- **And** the spec **names** "reconcile the entry legs into signed rows + a pool account" (the F3-Arm2
  reshape) as the **explicit deferred bank rung** — the half-balanced ledger is a documented, deferred debt,
- **And** the reconciliation read's documentation notes the unledgered buy-in debit + the pool column, so a
  reader is not misled into expecting a zero row-sum.

## S10 — The existing cm.5 suite stays byte-unchanged and green (additive, not a money change)

*As the Operator, I want the shipped cm.5 stories unchanged and passing after cm.6, so that making revenue
explicit adds rows without moving any money differently.*

**Exercises:** the additive overlay (`D-3`); cm.5 byte-frozen; no money-figure change. **Surface:** the cm.6
credits are **disjoint** writes to a new table for a new actor; the cm.5 player/pool figures are untouched.

- **Given** the shipped cm.5 story suites (the golden-economy / golden-tournament / wallet / settlement faces
  — the pool figures S-FIRSTMOVER, S-SPLIT, S-VIRTUALDEPOSIT)
- **When** cm.6's house credits are added and `mix test --include valkey` runs (Valkey 6390 + Postgres)
- **Then** the cm.5 scenarios pass **byte-unchanged** — the house credit makes the implicit explicit; it does
  **not** move money differently,
- **And** `git diff --stat` over the cm.5 story files is **empty** (no cm.5 story file edited),
- **And** the three shipped migrations stay **byte-frozen** (`20260618000000_create_codemojex.exs` ·
  `20260625145121_add_player_tg_user_id.exs` · `20260626120000_golden_rooms.exs`); cm.6 adds a **new**
  additive migration for the `revenue_ledger` table, proven up/down clean from a fresh `codemojex_test`
  reinit (the DB name read from `config/test.exs`, surfaced before the drop).

## S11 — The ledger is multi-source / multi-currency ready (the BNK + KeyShop foundation)

*As the BNK bank and the KeyShop, I want the revenue_ledger shaped from the start to hold multiple sources and
currencies, so that the rake, the withdrawal, and the Stars purchase plug in with no ledger re-design.*

**Exercises:** the multi-source/multi-currency `D-1`/`D-2` shape; the cm.6/cm.7 split (`D-5`); the
reversibility seam. **Surface:** the `revenue_ledger` columns (`account`/`source`, `currency`) +
`Wallet.house_balance` grouping by `currency`.

- **Given** the `revenue_ledger` table founded this rung
- **When** its shape is inspected (a schema/structure check, not a new behaviour)
- **Then** it carries an `account`/`source` dimension (`"platform"` for the Golden cuts now) and a `currency`
  dimension (`"keys"` now) with a **signed** `delta` and **no** non-negative CHECK (`D-1`),
- **And** a cm.7 purchase row (`source="purchase"`, `currency="stars"`) would insert and reconcile with **no**
  ledger change (the split is free — `D-5`),
- **And** the BNK rake (credit `account="platform"`) and withdrawal (debit it) bind to the **same** balance
  this rung founds — the call sites + the reconciliation read bind to the `Wallet.house_post` /
  `house_balance` seam (`D-7`), so the representation is reversible behind one accessor.

---

## Coverage (every body Deliverable → its story → its invariant)

| Deliverable (cm.6.md) | Story | Invariant / ruling |
|---|---|---|
| The `revenue_ledger` table (RVL, signed, no CHECK, multi-source/currency) — Venus-Postgres | S1, S11 | `D-1`, `D-6` |
| `Wallet.house_post` / `book_house` (the single signed-row primitive) | S1–S4, S6 | `D-7`, PF-1→Arm2 |
| The `deposit_seed` debit + SEAM-1 wrap | S1 | seed movement, `D-4` |
| The `deposit_recovery` credit (band 1..threshold) | S2 | recovery movement, `D-2` |
| The first-mover `revenue` credit `fee − pool_keys` + `Economy.entry_fee_split_keys/5` | S3 | PF-3, `D-2` |
| The full-`revenue` credit (beyond the band) | S4 | revenue movement |
| The keys-unit balance invariant (three-term conservation) | S5 | `D-2`, `D-3` |
| The `deposit_reclaim` credit (`+seed` only) + SEAM-2 | S6 | `D-4`, PF-4 |
| `Wallet.house_balance/0..1` (the reconciliation read) | S7 | the read; multi-currency `D-2` |
| Explicit == implicit (the property test) | S7 | the equivalence acceptance |
| Atomic double-entry under the games-row lock + the ≥100 loop | S8 | atomicity, PF-6 |
| **The conservation-honesty statement** + the deferred-rung naming | S9 | **`D-3` (mandatory)** |
| cm.5 suite byte-unchanged + green; migrations byte-frozen; new migration up/down | S10 | `D-3`, the migration gate |
| The cm.7 split (packages out; the ledger multi-source-ready) | S11 | `D-5` |
