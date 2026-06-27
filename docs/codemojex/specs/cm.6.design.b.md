# cm.6.design.b — The Revenue Ledger · Bank-Architect / Finance lens

> One of two independent architect designs (the dual-architect debate). Forward-tense, NO-INVENT. Surfaces forks; the Operator rules.

## §0 — Locked constraints (the as-built money surface this designs around)

The lens of this design is the **bank-architect**: what substrate does a real double-entry bank deserve
*now*, so the BNK rake + the withdrawal + a queryable platform-revenue balance build on a first-class account
abstraction rather than a residue derived by conservation? It leans toward first-class accounts and clean
reconciliation, and it pays the Steward cost of that lean honestly. These constraints are the money surface
cm.5 shipped — every fork is argued against them, none re-derived.

- **L-1 — The ledger is `transactions`** (`schemas/transaction.ex`): append-only `{id (TXN brand), player,
  currency (string), delta (signed int), reason (free-text), ref (free-text, nullable)}`, `inserted_at` only.
  No CHECK on `reason`/`ref` — a new `reason` value needs **no migration**. `changeset/2` requires
  `[:id, :player, :currency, :delta, :reason]` — `player` is **required**, so any house counterparty reusing
  this table must supply a `player` value.
- **L-2 — Exactly-once is the partial unique index** `(player, ref) WHERE reason='buy_in'` — the membership
  authority. The `buy_in` row is written with **`delta: 0`** (`insert_buy_in`, wallet.ex:347-366): a
  membership/idempotency MARKER, not a debit.
- **L-3 — Balances are `players`** (`schemas/player.ex`): `[:keys, :clips, :diamonds, :bonus_diamonds,
  :locked_diamonds]` int default 0; `guard/1` (player.ex:43-47) applies `validate_number(>=0)` to **all** +
  `check_constraint :players_non_negative`. **Every player row is non-negative by DB CHECK** — a sentinel
  house PLR debited below zero for the seed VIOLATES the constraint.
- **L-4 — The buy-in debit is a BARE balance update.** On `:wrote`, `buy_in` does
  `update!(p, %{keys: p.keys - fee})` (wallet.ex:226) — **no signed TXN row** for the debit. The pool side is
  `inc_pool!` (wallet.ex:371): `update_all(inc: [prize_pool: 💎])` on the games **column** — an atomic SQL
  `+`, **not a ledger account**. So the entry path moves money in **three places** (player column, games
  column, marker row) and ledgers **none of it as a signed entry**.
- **L-5 — The GUESS path already ledgers its debit** but the BUY-IN path does not. `charge_guess_golden`
  (wallet.ex:122-139) = `update!(keys -= fee)` + `txn!(-fee, "guess", ref)` (a **real signed row**) +
  `inc_pool!(fee×10)`. The asymmetry cm.6 closes is *within the same module*.
- **L-6 — The DISTRIBUTION is already double-entry; the REVENUE is not.** `distribute_pool` (wallet.ex:252-268)
  credits prizes (`deposit_prize` 💎 "prize") + consolations (clips "consolation") as real signed rows, nested
  txns joining the parent → atomic. Finish is balanced; entry is not.
- **L-7 — The existing signed-entry helpers** `credit/5` (wallet.ex:305-318) and `debit/5` (wallet.ex:285-303)
  already do `lock → update! → txn!` for an arbitrary player+currency+reason+ref. They are the reusable
  primitive for ANY house counterparty that is a `players` row — **but** `credit/5` updates a balance column,
  so it re-imposes the `players_non_negative` CHECK on the house row.
- **L-8 — The split math** (`entry_fee_split`, economy.ex:45-52): for the first-mover band the **pool** portion
  is `pool_keys = floor(entry_fee_keys × (100 − revenue_pct) / 100)`, then `× @diamonds_per_key (10)` 💎. The
  **platform** portion is the implicit complement `entry_fee_keys − pool_keys` keys. Outside the band the pool
  portion is `0` → the whole fee is platform revenue. `@diamonds_per_key 10`, `@cents_per_diamond 1.2`
  (economy.ex:10-11): **1 key = 10 💎 = 12¢**.
- **L-9 — The SEED + VOID.** Golden `start_game` seeds `prize_pool = virtual_deposit` 💎 (cm.5
  `rooms.ex`); `close_void` → status `:voided` + reclaim the unpaid deposit, **NO REFUND** (cm.5 D-7).
- **L-10 — FROZEN at-rest surface.** The 2 shipped migrations + the cm.5 `golden_rooms` migration are
  **byte-frozen**; cm.6's house representation is a **NEW additive migration**. Boundary ⊆ `echo/apps/codemojex/**`
  + the rung docs; `mix.lock` untouched.
- **L-11 — The serialization point is the games-row `FOR UPDATE` lock** (`lock_game`, wallet.ex:326; cm.5
  RULING 1). Any house credit cm.6 adds rides the **same `Repo.transaction`** → it inherits the per-game
  ordinal serialization with **no new lock and no new race**.

## §1 — F1 The house representation

The question: where does the platform's revenue **balance** live? Two arms — reuse `transactions` + a
sentinel `players` row (Arm 1), or stand up a dedicated `revenue_ledger`/accounts substrate (Arm 2). This is
the fork the bank-architect lens cares about most: the house account is the abstraction the entire BNK bank
(rake, payouts, withdrawal) will operate on, so its shape outlives this rung.

### Arm 1 — A reserved SYSTEM `PLR` (sentinel house player; reuse `transactions` + `players`)

- **Rationale.** A single reserved branded `PLR` id (e.g. minted once, `name: "__house__"`) is the credit
  counterparty for every platform cut. Reuse the existing ledger and the existing helpers: the house balance
  is `Σ delta WHERE player = house_id` over `transactions`. Nothing new at the schema level except the seed
  row that mints the house player.
- **5W.** *Why* — smallest correct increment; the ledger already balances per `player`, so a sentinel player
  *is* an account. *What* — one seeded `players` row + house-credit `txn!` rows reusing `reason`/`ref`. *Who* —
  Mars wires the credits at the cm.5 sites; no Venus-Postgres redesign needed. *When* — ships this rung with
  the least freeze. *Where* — `wallet.ex` (the credit sites) + a tiny seed migration/seed-call for the house
  `PLR`.
- **Steelman.** The ledger's exactly-once + signed-delta machinery is *already* the bank primitive; a
  separate accounts table would duplicate `{player, currency, delta, reason, ref}` semantics the
  `transactions` row already has. The reconciliation read is one `group_by reason` over rows the house
  player owns — no join. cm.5 stays maximally green: zero change to player/pool figures.
- **Steward objection (this lens pre-empts it).** **The `players_non_negative` CHECK (L-3) is the hard
  blocker.** If the house credit lands on a balance **column** (`credit/5` → `update! keys += …`), then the
  SEED house **debit** (`V/10` keys, S-SEED) drives the house `keys` column **negative** before any recovery
  credit arrives → the DB CHECK raises mid-transaction and the buy-in path breaks. Two escapes, both ugly:
  (a) seed the house with a large positive opening float so it never goes negative — an **invented magic
  number** that pollutes every balance read and the reconciliation arithmetic; or (b) write the house side as
  **`txn!`-only** (a signed `transactions` row) and **never touch a balance column** — but then the house
  "account" is `transactions`-derived only, the `players` row is a dead stub whose columns lie, and the
  sentinel buys nothing over Arm 2's dedicated row except sharing a table that was not shaped for it. Also: a
  sentinel id in `players` means every `players` aggregate (counts, leaderboards, "how many players") must
  now special-case the house — a gate-invisible foot-gun the bank will trip repeatedly.

### Arm 2 — A dedicated `revenue_ledger` / accounts substrate

- **Rationale.** A first-class house-account table (or a thin `accounts` row + `revenue_ledger` entries) that
  is **designed to go signed in both directions** — no non-negative CHECK, an explicit `account` dimension —
  so the seed debit, the recovery/revenue credits, the void reclaim, and (next rung) the rake and the
  withdrawal all post against one purpose-built balance. The bank's foundation is a real account, not a
  player wearing a disguise.
- **5W.** *Why* — reconciliation rigor + separation of concerns: platform revenue is a distinct ledger from
  player balances, queried without filtering a sentinel out of player space. *What* — a new additive
  migration (`revenue_ledger` rows, or `house_accounts` + entries) with a signed-balance invariant and an
  index on `(ref)` / `(reason)` for the reconciliation read. *Who* — Venus-Postgres frames the relational
  shape; Mars wires both sides. *When* — this rung, accepting the new frozen schema surface. *Where* — a new
  schema module + migration + the `wallet.ex` credit sites + a `Store`/`Wallet` reconciliation read.
- **Steelman.** This is what a bank's general ledger looks like: the house is an **account**, not an actor in
  the player set. It sidesteps the `players_non_negative` collision *by construction* (the new table has no
  such CHECK), so the seed-debit-then-recovery-credit sequence (the zero-loss made explicit, S-DEPOSIT-RECOVERY)
  is a natural debit→credit swing, not a CHECK-dodging hack. The reconciliation read (cm.6.md S-RECONCILE)
  is a clean `group_by reason` over a table that holds **only** platform movements — no player rows to
  exclude, no balance columns that mean different things for the house vs a player. And it is the right
  surface for BNK: a rake `debits pool, credits revenue_ledger`; a withdrawal `debits revenue_ledger` — both
  against a balance the table was built to hold.
- **Steward objection (this lens pre-empts it).** **A new table is frozen surface the bank will re-shape
  anyway, and it over-builds ahead of the rake.** cm.6's *only* job this rung is to record revenue explicitly
  and prove the balance invariant; the BNK withdrawal/rake design (the consumer that justifies a rich account
  shape) is **Scope Out** (cm.6.md) and unspecified — so any columns added for it now are speculative and
  will likely be migrated again when BNK is actually designed. The smallest correct increment that proves the
  invariant ships sooner with less freeze risk. **Rebuttal:** the over-build risk is real but bounded — the
  honest minimum here is **not** a full accounts table but a single dedicated **`revenue_ledger` entry table**
  shaped exactly like the proven `transactions` row (`id`/`account`/`currency`/`delta`/`reason`/`ref`,
  signed, no non-negative CHECK), nothing speculative for BNK. That is one frozen table, mirroring a schema
  already trusted, that *correctly* admits the seed debit — strictly less risk than Arm 1's CHECK-dodge,
  because Arm 1's "escape (b)" lands in `transactions` (a frozen-adjacent shared table) the same revenue rows
  Arm 2 isolates, but tangled into player-balance space and constrained by a `player`-required changeset.

### Ranked recommendation (ADVICE — the Operator rules)

1. **Arm 2 (dedicated `revenue_ledger`), at its honest minimum** — *recommended from this lens.* The one
   reason that carries it: **L-3's `players_non_negative` CHECK makes the house a fundamentally different kind
   of account than a player** (it must legitimately swing negative on the seed debit), so modelling it as a
   player is modelling against the grain — a dedicated signed table admits the seed by construction and gives
   BNK a real account to build on, at the cost of exactly one additive table that mirrors a schema already
   proven.
2. **Arm 1 (sentinel `PLR`), `txn!`-only variant** — the smallest-diff fallback if the Operator wants cm.6 to
   stay maximally additive and defer all bank substrate. Acceptable only as the **`txn!`-only** form (house
   side never touches a balance column, so the CHECK is never hit); the opening-float form is rejected (an
   invented magic number).

**The opposing-lens (Steward) objection, pre-empted:** *"a new table is surface the bank will re-shape, and
the smallest correct increment ships sooner with less freeze risk."* Granted in principle — but the smallest
**correct** increment is not Arm 1: Arm 1 is correct only via a CHECK-dodge that either invents a float or
demotes the `players` row to a lying stub, and either way writes the platform's revenue into the shared
`transactions`/`players` space the bank will have to *untangle* from player balances later. Arm 2's honest
minimum (one signed `revenue_ledger` table mirroring `transactions`) is **less** total freeze risk than
shipping revenue into player space and reshaping it twice.

## §2 — F2 The ledger unit

The question: in what unit do the books balance? The entry fee is in **keys**; the pool is in **diamonds**
(💎); revenue settles to **cents** eventually (L-8: 1 key = 10 💎 = 12¢). A double-entry ledger must balance
in **one** canonical unit, and the `×10` keys→💎 conversion at the pool boundary is the one place a value
changes denomination.

### Arm 1 — Keys-unit ledger (the entry unit; the pool's ×10 is an explicit conversion entry)

- **Rationale.** Book the house side in **keys**, the unit the player actually pays. The invariant
  (cm.6.md §4, S-DOUBLE-ENTRY-BALANCE) reads `entry_fee_keys = house_credit_keys + pool_portion_keys` per
  buy-in; the pool's `pool_keys × 10` 💎 is treated as a **conversion/minting entry** at the pool boundary —
  the one accounted place keys become diamonds. The house credits are whole keys (`entry_fee_keys` or
  `entry_fee_keys − pool_keys`, both integers from L-8's `div`).
- **5W.** *Why* — keys is the unit the fee is denominated in and the unit the platform-portion math
  (`entry_fee_keys − pool_keys`) is exact in; no division, no rounding introduced by cm.6. *What* — house
  `delta` rows in `currency: "keys"`. *Who* — Mars; the conversion entry is the pool side, already
  diamonds. *When* — this rung. *Where* — the credit sites + the invariant proof.
- **Steelman.** The split math is **defined in keys** (`pool_keys = div(entry_fee_keys × …, 100)`,
  economy.ex:47) and floored in keys **before** the ×10 (the cm.5 rounding pin, economy.ex:42) — so keys is
  the unit in which `house + pool == fee` holds with **zero residue**. Book in any other unit and cm.6 must
  re-introduce the same floor and risk a units mismatch the invariant would then have to absorb. The pool's
  ×10 is genuinely a minting boundary (keys are spent, diamonds are created in the pool), so naming it an
  explicit conversion entry is *more* honest than hiding it, and it matches how `txn!` already records the
  guess path (signed keys out, pool diamonds in, wallet.ex:122-139).
- **Steward objection (this lens pre-empts it).** A keys-denominated revenue balance is **not** directly the
  number finance wants — platform revenue is ultimately cents/diamonds, so a keys ledger needs a conversion
  at *read* time (`×10` → 💎, `×1.2` → ¢) for any revenue report, and mixing a keys house balance with a
  diamonds pool means the reconciliation read spans two units. **Rebuttal:** the read-time conversion is
  pure and exact (`Economy.diamonds_for_keys`/`to_cents` already exist, economy.ex:19-22) and is a
  *presentation* concern, not a ledger one; keeping the **ledger** in the unit the invariant is exact in, and
  converting for the report, is the correct separation — the alternative pushes a lossy conversion into every
  write.

### Arm 2 — Normalized-currency ledger (one canonical unit — 💎, or cents)

- **Rationale.** Pick a single denomination for **all** money — most naturally 💎 (the pool's unit, and one
  step from cents) — and convert the keys fee to it on the way in (`entry_fee_keys × 10` 💎). The house
  balance, the pool, and (eventually) the rake/withdrawal all read in one unit; reconciliation never spans
  denominations.
- **5W.** *Why* — a single-unit general ledger is the bank-textbook shape; revenue reporting is a column read,
  not a conversion. *What* — house `delta` rows in `currency: "diamonds"`; the keys fee enters as `fee × 10`.
  *Who* — Venus-Postgres confirms the canonical unit; Mars converts at the boundary. *When* — this rung.
  *Where* — the credit sites convert keys→💎 once at ingress.
- **Steelman.** Diamonds is the unit the **pool** already balances in and the unit closest to the real-money
  figure (💎 → ¢ is a fixed `×1.2`). A 💎-normalized ledger means the platform-revenue balance, the pool, and
  the prize distribution (already 💎, L-6) are all one currency — the reconciliation read (S-RECONCILE) is a
  single-unit sum, and the BNK withdrawal (which cashes out in real money) reads the house balance in the
  unit nearest cents with no keys hop.
- **Steward objection (this lens pre-empts it).** **Normalizing to 💎 RE-INTRODUCES a rounding boundary cm.5
  deliberately pinned away.** The platform portion is `entry_fee_keys − pool_keys` **keys** (L-8); in keys it
  is exact. Convert the *whole fee* to 💎 at ingress and the platform portion becomes `fee×10 − pool_keys×10`
  💎 — still exact here because both are ×10 of integers, **but** any future fee math that is not a clean
  multiple of 10 (a fractional-key fee, a percentage rake on a keys amount) would strand sub-diamond dust the
  keys ledger never had. Choosing 💎 now bets the bank never denominates a fee in sub-10-💎 units — a bet the
  rake (a percentage of a pool) is likely to lose. **Rebuttal:** cm.6's *current* amounts are all ×10-clean,
  so Arm 2 is correct **today**; the objection is forward-risk, not a present bug.

### Ranked recommendation (ADVICE — the Operator rules)

1. **Arm 1 (keys-unit ledger)** — *recommended from this lens.* The one reason that carries it: **the split
   math is exact in keys and floored in keys before the ×10 (economy.ex:42,47)**, so booking the house side in
   keys means cm.6 inherits cm.5's rounding pin for free and the invariant `house + pool == fee` holds with
   zero residue at the unit it is defined in — the conversion to 💎/¢ is a pure, exact *read-time* concern
   (`Economy.diamonds_for_keys`/`to_cents`), not a per-write lossy step.
2. **Arm 2 (💎-normalized)** — defensible and closer to the real-money number, but it imports a denomination
   conversion into every write to buy a property (single-unit reads) that a pure read-time conversion already
   delivers; prefer it only if the Operator wants the stored house balance to *be* the near-cents figure with
   no read-time hop, accepting the forward sub-diamond-dust risk on non-×10 fees.

**The opposing-lens (Steward) objection, pre-empted:** *"finance wants cents, so store the unit nearest
money."* The reconciliation read can *present* cents from a keys ledger exactly (the conversion functions are
pure and shipped); storing in keys keeps the **invariant** in the unit it is provably exact in and defers the
denomination choice to the report, which is where presentation belongs.

> **F1×F2 interaction (flagged for Mars):** the unit lives in the ledger row's `currency` field either way, so
> F2's keys-vs-💎 choice is **orthogonal** to F1's table choice — a `revenue_ledger` row (F1 Arm 2) and a
> sentinel `txn!` row (F1 Arm 1) both carry a `currency` string. The recommended pairing is **F1 Arm 2 ×
> F2 Arm 1**: a dedicated signed `revenue_ledger` table, denominated in keys, with the reconciliation read
> converting to 💎/¢ for finance.

## §3 — F3 The entry-side representation

The question: does cm.6 **leave** cm.5's entry path exactly as-is and ADD house rows beside it (Arm 1), or
**reconcile** the entry path so the player debit and the pool become real ledger entries too (Arm 2)? This is
where the bank-architect lens (ledger purity — *every* movement is a signed entry) collides with Acceptance
(cm.5 stays green untouched, cm.6.md S-EXISTING-GREEN).

### Arm 1 — ADDITIVE OVERLAY (leave cm.5's buy_in exactly as-is; ADD house-credit rows)

- **Rationale.** Touch nothing cm.5 ships: the `delta: 0` marker (L-2), the bare `keys -= fee` balance update
  (L-4), and the `inc_pool!` games-column `+` (L-4) all stay byte-for-byte. cm.6 **only adds** the house-side
  rows (seed debit, recovery/revenue/reclaim credits) inside the *same* `Repo.transaction` (wallet.ex:204), so
  the double-entry that cm.6 introduces is *complete on the revenue side* without re-deriving the player or
  pool sides.
- **5W.** *Why* — cm.5's pool/player figures are unchanged, so the entire cm.5 suite stays green untouched
  (the Acceptance bar). *What* — N new house rows per game, zero edits to existing writes. *Who* — Mars adds a
  call inside the existing `cond`. *When* — this rung, minimal blast radius. *Where* — one new credit/debit
  call between `update!(keys -= fee)` and the `inc_pool!`/`:member` return (wallet.ex:226-238).
- **Steelman.** This is the Acceptance-honoring move and the lower-risk one: cm.6 is purely **additive on the
  revenue side** (cm.6.md Scope Out: "any cm.5-resolved surface … untouched"), so there is no regression
  surface in the player/pool math, no re-pin of cm.5 stories, and the diff is reviewable as "new rows, same
  money." The bank still gets its first-class revenue account (under F1 Arm 2) — the overlay is about not
  *retro-fitting the player/pool sides*, not about skipping the house ledger.
- **Steward objection (this lens — the bank-architect — actually RAISES it).** **The overlay leaves the
  ledger half-balanced.** With Arm 1, the *player debit* is still a bare column update with **no signed row**
  (L-4) and the *pool credit* is still a games-column `+` with **no ledger entry** (L-4) — so `Σ all
  transactions.delta` does **not** sum to zero, because the player's `−fee` and the pool's `+pool` simply are
  not in `transactions`. The invariant cm.6.md states (`Σ player debits = Σ house credits + Σ pool
  conversions`, S-DOUBLE-ENTRY-BALANCE) is then proven **against computed quantities** (`fee`, `pool_keys`
  recomputed in the test), not against rows that exist — it is a *conservation proof*, the very thing cm.5
  already had, with house rows bolted on. A real bank's general ledger sums its own rows to zero; this one
  cannot, because two of the three legs of every entry live in balance columns, not the ledger. **Rebuttal
  (why the lens still does not demand Arm 2 unconditionally):** the player/pool legs ARE recorded — the player
  leg in the `players.keys` column + the `delta:0` marker row, the pool leg in `games.prize_pool` — they are
  *durable and correct*, just not *in `transactions` as signed rows*. The asymmetry is a ledger-purity defect,
  not a money defect.

### Arm 2 — RECONCILE the buy_in path (the debit becomes a real signed row; the pool becomes a ledger account)

- **Rationale.** Make the entry path a true double-entry: the player debit becomes a real
  `txn!(-fee, "buy_in_debit", game)` signed row (or the `buy_in` marker's `delta` carries the `-fee`), and the
  pool credit becomes a real ledger entry against a **pool account** (the pool ceases to be a bare games
  column and becomes a balance the ledger sums to). Then `Σ transactions.delta = 0` across player + pool +
  house — the bank's general ledger balances against its **own rows**, the property the bank-architect lens
  prizes.
- **5W.** *Why* — ledger purity + reconciliation rigor: the books balance against rows, not against a
  re-computation, and every money movement is one signed entry — the substrate the BNK bank deserves. *What* —
  change the buy_in marker to carry the debit (or add a debit row), and represent the pool as a ledger
  account (a `pool` party, or a `revenue_ledger`-sibling row) alongside the games column. *Who* — Venus-Postgres
  reframes whether the pool stays a column + gains a mirror entry, or moves; Mars wires it. *When* — this rung,
  if the Operator accepts touching the cm.5 entry path. *Where* — `insert_buy_in` (wallet.ex:347) +
  `inc_pool!` (wallet.ex:371) + the invariant proof.
- **Steelman.** This is the *complete* ledger the Operator's "best-practices ledger" intent points at: the
  distribution is already double-entry (L-6), the guess path already ledgers its debit (L-5), so reconciling
  the **buy-in** path makes the ledger uniformly signed — no path special-cased, `Σ delta = 0` provable on the
  rows. It is the foundation a real bank wants: the pool as an account the rake can debit *as a ledger entry*,
  the player debit as a row finance can audit without knowing the buy_in marker's `delta:0` is a special case.
- **Steward objection (this lens pre-empts it).** **It breaks the Acceptance bar and re-opens cm.5-resolved
  surface.** cm.6.md Scope Out names "the pool denomination, the distribution double-entry … untouched" and
  S-EXISTING-GREEN requires the cm.5 pool/player stories stay green untouched — reconciling the debit changes
  the `delta:0` marker (the exactly-once authority, L-2!) and reconciling the pool changes how `prize_pool` is
  read by *every* cm.5 finish/void path. That is a large regression surface on the **money-critical** exactly-once
  index and the pool the distribution reads, for a property (rows-sum-to-zero) that the conservation proof
  already establishes numerically. The risk/benefit is wrong for a HIGH-risk money rung whose stated job is to
  add the *revenue* leg, not re-plumb the entry. **Rebuttal:** the purity gain is real and is the bank's
  proper end-state — but it is a **separate, larger rung** (touching the exactly-once index demands its own
  risk budget + determinism loop), not a rider on cm.6.

### Ranked recommendation (ADVICE — the Operator rules)

1. **Arm 1 (additive overlay)** — *recommended from this lens, with a caveat.* The one reason that carries it:
   **reconciling the entry path means editing the `delta:0` buy_in marker that IS the exactly-once authority
   (L-2) and the `prize_pool` column every cm.5 finish/void reads (L-4) — a money-critical regression surface
   that S-EXISTING-GREEN forbids touching** — so the disciplined move is to ship the revenue leg additively
   now and book the full-double-entry reconcile of the player/pool legs as its own rung. *The bank-architect
   caveat:* state plainly in cm.6 that the invariant is proven by **conservation** (computed `fee`/`pool_keys`
   vs house rows), **not** by `Σ transactions.delta = 0` — and record "reconcile the entry legs into signed
   rows + a pool account" as the explicit next bank rung, so the half-balanced state is a **known, deferred
   debt**, not a silent one.
2. **Arm 2 (reconcile the entry path)** — the bank's correct end-state and the *purest* ledger, but
   out-of-budget for cm.6: it re-opens the exactly-once marker and the pool column under a HIGH-risk money
   rung. Defer to a dedicated rung with its own risk budget.

**The opposing-lens (Steward/Acceptance) objection, pre-empted:** *"cm.5 must stay green — do not touch the
entry path."* Fully granted, and it is exactly why the recommendation is Arm 1. The bank-architect lens does
**not** trade Acceptance for purity here; it extracts the one thing purity demands that costs nothing — an
**honest statement** that the cm.6 ledger balances by conservation, not by summing its own rows — and names
the reconcile as the next rung. That keeps cm.5 green now and keeps the bank's end-state on the roadmap
rather than quietly abandoned.

## §4 — The house-account schema/representation shape (under the recommended arms)

**Recommended composition: F1 Arm 2 × F2 Arm 1 × F3 Arm 1** — a dedicated signed `revenue_ledger` table,
denominated in keys, written as an additive overlay (cm.5's player/pool sites untouched). This composition is
internally coherent: the dedicated table is exactly what lets the overlay stay additive (the house side never
touches `players`, so the `players_non_negative` CHECK is never in the path and no cm.5 player/pool figure
moves), and keys keeps cm.5's rounding pin.

**The `revenue_ledger` schema** (forward-tense; mirrors the proven `transactions` row, L-1):

```
revenue_ledger
  id          string   PK   — a branded RVL id (a new 3-char namespace), or reuse TXN brand
  account     string        — the house party; one canonical value this rung ("platform"/"house")
  currency    string        — "keys" (F2 Arm 1); the conversion to 💎/¢ is read-time
  delta       integer       — SIGNED; debit (seed) negative, credit (revenue) positive. NO non-negative CHECK.
  reason      string        — "deposit_seed" | "deposit_recovery" | "revenue" | "deposit_reclaim"
  ref         string        — the GAM game id (nullable, like transactions.ref)
  inserted_at utc_datetime_usec   — append-only, inserted_at only (no updated_at)
```

- **Why a dedicated table, not a sentinel `players` row (F1):** the house must legitimately go **negative**
  on the `"deposit_seed"` debit before recoveries arrive (L-9, S-SEED → S-DEPOSIT-RECOVERY); `players` forbids
  that (L-3). A table with **no non-negative CHECK** admits the seed by construction. The balance is
  `Σ delta WHERE account = "platform"` — exactly the `transactions` pattern (L-1), on a table that holds
  **only** platform movements (clean reconciliation, no sentinel to filter out of player space).
- **The `account` dimension** is present-but-singular this rung (one house party) — it is the seam the BNK
  bank widens (a rake credits `account="platform"`; a withdrawal debits it; a future multi-pot bank adds
  `account` values) **without** another table. This is the *bounded* forward-provision the lens defends: one
  column that the bank will populate, not a speculative schema.
- **The id brand.** Following the BCS contract (the brand IS the type), a `revenue_ledger` row deserves its
  own 3-char namespace (e.g. an `RVL` brand) so revenue rows are type-distinguishable from player `TXN` rows
  at every boundary. *Flagged for the Stage-1 ruling:* mint a new `RVL` brand (cleanest, one more namespace)
  **vs** reuse the `TXN` brand (no new namespace, but revenue rows and player ledger rows share a type). The
  lens leans `RVL` — a first-class account deserves a first-class brand — but notes reuse is acceptable since
  the table itself, not the id, is the type boundary here.
- **The pool's ×10 conversion (F2 Arm 1).** The pool side stays cm.5's `games.prize_pool` 💎 column (F3 Arm 1,
  untouched). The keys→💎 minting at the pool boundary is **named in the invariant proof** (§6), not stored as
  a `revenue_ledger` row — the pool is not a revenue account, it is the prize liability, and cm.6 does not
  reconcile it (that is F3 Arm 2, deferred). So the `revenue_ledger` holds **only** the house side; the
  player side stays the `players.keys` column + the `delta:0` `transactions` marker (L-2, L-4, untouched).

**Net:** one new additive table, signed, mirroring a trusted schema, that correctly admits the seed debit and
gives the bank a real revenue account — at the honest cost named in §3 (the *whole* ledger does not sum to
zero on its own rows yet, because the player/pool legs are not reconciled; that is the deferred bank rung).

## §5 — The paired-credit insertion points (keyed to wallet.ex sites)

Under the recommended composition, every house-side `revenue_ledger` row rides the **same `Repo.transaction`**
as the cm.5 movement it pairs with (so it is atomic, S-ATOMIC-DOUBLE-ENTRY, and inherits the games-row lock,
L-11). A new `Wallet` helper — `house_post(account, currency, delta, reason, ref)` — inserts one signed
`revenue_ledger` row; it mirrors `txn!` (wallet.ex:380) but targets the new table and does **not** touch a
balance column (so no CHECK, no lock on a player). The five sites:

| # | Site (cm.5) | wallet.ex / rooms.ex anchor | The paired house post (forward-tense) | reason |
|---|---|---|---|---|
| 1 | **Deposit SEED** | golden `start_game` seeds `prize_pool = virtual_deposit` 💎 (cm.5 `rooms.ex`, L-9) | a house **debit** `delta = -(virtual_deposit / 10)` keys, `ref = game`, in the **same txn** as the seed | `"deposit_seed"` |
| 2 | **Deposit-recovery** | `buy_in` ordinal ∈ `[1, start_threshold]` → `entry_fee_split` returns 0, no pool inc (economy.ex:51, wallet.ex:237) | a house **credit** `delta = +entry_fee_keys`, `ref = game`, inside `buy_in`'s txn | `"deposit_recovery"` |
| 3 | **First-mover share** | `buy_in` ordinal ∈ first-mover band → `inc_pool!(pool)` runs (wallet.ex:237; `pool_keys = div(fee×(100−rev%),100)`, economy.ex:47) | a house **credit** `delta = +(entry_fee_keys − pool_keys)` keys — the **complement** `entry_fee_split` leaves implicit (L-8) — same txn as the pool inc | `"revenue"` |
| 4 | **Full revenue** | `buy_in` ordinal > band → `entry_fee_split` returns 0, no pool inc | a house **credit** `delta = +entry_fee_keys`, same txn | `"revenue"` |
| 5 | **Void deposit-reclaim** | `close_void` → `:voided`, reclaim the unpaid deposit, no refund (cm.5 D-7, L-9) | a house **credit** covering the kept fees + the reclaimed-but-unpaid seed, `ref = game`, in `close_void`'s txn | `"deposit_reclaim"` |

- **The single computation seam (sites 2/3/4).** All three live inside `buy_in`'s `:wrote` branch
  (wallet.ex:224-238), keyed on the `ordinal` already computed there (wallet.ex:217) and the `pool` already
  computed by `entry_fee_split` (wallet.ex:228-235). The house credit is a **pure function of the same
  inputs**: `house_keys = entry_fee_keys − pool_keys`, where `pool_keys = pool / 10` (the inverse of the ×10,
  exact because `pool` is `pool_keys × 10`). So sites 2/3/4 collapse to **one** insertion point —
  `house_post("platform", "keys", entry_fee_keys − div(pool, 10), reason_for(ordinal), game)` — placed right
  after `inc_pool!` (wallet.ex:237), where `reason` is `"deposit_recovery"` for the first band else `"revenue"`.
  This avoids re-deriving the band boundaries in cm.6 (NO-INVENT: reuse `entry_fee_split`'s output, do not
  re-implement the waterfall).
- **Site 1 (seed)** lives wherever cm.5's `start_game` seeds `prize_pool` (golden room formation, `rooms.ex`);
  the debit must be in the **same** `Repo.transaction` as the seed so the seed-as-outlay (S-SEED) is atomic.
  *Flag for Mars:* confirm `start_game`'s seed is inside a `Repo.transaction` that the house debit can join;
  if the seed is a bare `inc`/`update`, wrap it (an additive change to a cm.5 site — surface it to the
  Director as the one cm.5-path edit the seed requires, since F3 Arm 1 otherwise touches nothing).
- **Site 5 (void)** lives in `close_void` (`rooms.ex`, cm.5); the reclaim credit joins `close_void`'s txn.
  The amount = the sum of fees already credited as revenue for this game + the seed magnitude (so the net
  house position after a void = the kept fees, the seed having been debited at site 1 and reclaimed here).
- **All five posts are keyed `ref = game`** — so the reconciliation read (§7) groups a game's whole revenue
  story by `ref`, and the per-game breakdown (seed / recovery / first-mover / full / reclaim) is a
  `group_by reason WHERE ref = game`.

## §6 — The balance-invariant proof sketch (at the recommended unit — keys)

The headline invariant (cm.6.md S-DOUBLE-ENTRY-BALANCE): for any sequence of N buy-ins + the seed + an
optional close, **`Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)`** at the
keys unit — no key minted or lost, the ×10 the one accounted minting boundary.

**Per buy-in (the unit of the proof).** Let `f = entry_fee_keys`, `pk = pool_keys` (from `entry_fee_split`,
0 outside the first-mover band). The three legs:

- **player debit** = `f` keys (`update! keys -= fee`, wallet.ex:226).
- **pool conversion** = `pk` keys → `pk × 10` 💎 (the minting boundary; `inc_pool!`, wallet.ex:237). In **keys
  units** the pool absorbs `pk`.
- **house credit** = `f − pk` keys (§5, sites 2/3/4: `house_post(.., f − div(pool,10), ..)`).

Then per buy-in: `house_credit + pool_keys = (f − pk) + pk = f = player_debit`. ∎ (exact integer identity, no
rounding — `pk` is `div(f×(100−rev%),100)`, an integer, and `f − pk` is therefore an integer; the ×10 applies
only at the pool boundary and is reversed exactly by `div(pool,10)`).

**The seed (S-SEED).** At formation the house **debits** `s = virtual_deposit/10` keys (§5 site 1) and the
pool gains `s × 10 = virtual_deposit` 💎. In keys: the house holds `−s`, the pool holds `+s` — a closed
keys-conserving move (the platform funds the pool from its own account; nothing minted). This is the
seed-as-outlay made explicit.

**Over a settled game (S-DEPOSIT-RECOVERY zero-loss).** After the seed (`−s` house) and the first
`start_threshold` recoveries (`+f` house each, pool unchanged), the house net is
`−s + start_threshold × f`. With cm.5's design `virtual_deposit ≈ start_threshold × entry_fee_keys × 10` (the
seed sized to the first-band recoveries), `s ≈ start_threshold × f`, so the house net **≈ 0** after the
recovery band — the zero-loss, now an explicit `Σ delta` over `revenue_ledger`, not a conservation argument.
First-mover + full-revenue buy-ins then accrue the platform's actual profit as positive `revenue` rows.

**The void (S-VOID-RECLAIM).** On `close_void`, no player is refunded (D-7); the house holds its accrued
revenue + a `deposit_reclaim` credit for the unpaid seed, and the pool's seeded-but-undistributed 💎 is
reclaimed. Keys conserve: every key a player spent is in a house credit or a pool conversion; the reclaimed
seed cancels the seed debit. `Σ delta` over the game's `revenue_ledger` rows = the platform's net keep.

**What this proof IS and IS NOT (the bank-architect's honest statement, per §3 Arm 1).** This is a
**conservation proof at the keys unit** — the test recomputes `f`/`pk` from the game's parameters and the
buy-in sequence and asserts the house `Σ delta` equals `Σ f − Σ pk`. It is **not** `Σ transactions.delta +
Σ revenue_ledger.delta = 0` across the whole system, because the player debit (a `players.keys` column move)
and the pool credit (a `games.prize_pool` column move) are **not** signed rows under F3 Arm 1 — they live in
balance columns. The invariant holds and is provable; it just balances *computed conservation quantities
against the revenue rows*, not *all ledger rows against zero*. The full rows-sum-to-zero property is F3 Arm 2,
deferred. cm.6 must say this plainly so finance does not assume the bare `Σ revenue_ledger.delta` is the
whole system's balance.

**The property test (forward-tense).** A generated sequence of buy-ins (varied `start_threshold`,
`first_movers`, `revenue_pct`, `entry_fee_keys`) + optional close → assert, for every game:
`house_Σdelta(game) == Σ_buyins(entry_fee_keys) − Σ_buyins(pool_keys)` (the recovery/revenue/full split) and
`pool_💎(game) == Σ_buyins(pool_keys) × 10 + seed_💎 − distributed_💎`. Run it under the **≥100 determinism
loop** (reinit-per-iter) — the same-ms branded-id mint hazard applies to the new `revenue_ledger` id mints.

## §7 — The reconciliation read + the explicit==implicit equivalence (cm.6.md S-RECONCILE)

**The read (forward-tense).** A new `Wallet.house_balance/0` + `Wallet.revenue_breakdown/1` (per game):

- `house_balance()` → `Σ delta WHERE account = "platform"` over `revenue_ledger`, in keys — the single
  queryable platform-revenue balance the rung exists to provide. For finance, convert at read time:
  `Economy.diamonds_for_keys(bal)` 💎 and `Economy.to_cents(...)` ¢ (the pure, exact conversions,
  economy.ex:19-22). Because the table holds **only** house movements (F1 Arm 2), this is a clean aggregate
  with **no sentinel to filter out of player space** — the bank-architect payoff over a `players` sentinel.
- `revenue_breakdown(game)` → `group_by reason WHERE ref = game` → `%{deposit_seed: −s, deposit_recovery: …,
  revenue: …, deposit_reclaim: …}`, so a game's whole revenue story is **queried**, not re-derived (cm.6.md
  Scope-In 5).

**The explicit == implicit equivalence (S-RECONCILE — the load-bearing equivalence).** cm.5 leaves the
platform's cut *implicit*: derivable only by conservation as `keys_debited − keys_to_pool` per buy-in
(`Σ_buyins(entry_fee_keys) − Σ_buyins(pool_keys)`, where `pool_keys = pool/10`). cm.6's
`house_balance(game)` (the sum of the `revenue_ledger` rows for that game, **excluding** the seed/reclaim
which net to the deposit) must equal that **same number**:

```
house_revenue(game)                              # explicit: Σ revenue_ledger.delta for revenue+recovery rows
  == Σ_buyins[ entry_fee_keys − (pool_💎_contributed / 10) ]   # implicit: cm.5 conservation
```

This is provable because §5's house credit is **constructed** as exactly `entry_fee_keys − div(pool, 10)` per
buy-in — so the explicit row carries, by definition, the implicit conservation residue. The property test
(cm.6.md Acceptance "Equivalence to cm.5") computes the cm.5-only conservation figure from the *unmodified*
cm.5 quantities (`fee`, `entry_fee_split`'s pool output) over a buy-in sequence, and asserts it equals the
cm.6 `house_balance` aggregate. **The same number, now a row** — cm.6 makes the implicit explicit, never a
different figure (the rung's central promise).

- **Seed/reclaim handling in the equivalence.** The seed debit (`−s`) and, on void, the reclaim credit are
  the *deposit* legs, not the per-buy-in revenue; the equivalence above is stated over the
  **revenue/recovery** rows so it matches cm.5's per-buy-in conservation. The full `house_balance()`
  (including seed/reclaim) is the platform's **net** position; finance reads both — the per-game revenue
  (matches cm.5) and the net (revenue − seed-not-yet-recovered), which is the figure the BNK withdrawal
  eventually settles.
- **The discontinuity note (cm.6.md Scope Out: forward-only).** The `revenue_ledger` starts at cm.6 — no
  retroactive backfill of pre-cm.6 implicit revenue. `house_balance()` is the explicit revenue **from cm.6
  onward**; finance is told the start date so the explicit ledger is not mistaken for all-time revenue.

## §8 — The migration up/down shape (additive; shipped migrations byte-frozen)

**One NEW additive migration** creates `revenue_ledger` (L-10: the 2 shipped migrations + the cm.5
`golden_rooms` migration are **byte-frozen** — cm.6 adds, never edits). Forward-tense shape:

```elixir
def up do
  create table(:revenue_ledger, primary_key: false) do
    add :id,       :string, primary_key: true     # branded RVL (or TXN) id
    add :account,  :string, null: false           # "platform" this rung; the BNK seam
    add :currency, :string, null: false           # "keys"
    add :delta,    :bigint,  null: false           # SIGNED — no non-negative CHECK (the whole point vs players)
    add :reason,   :string, null: false
    add :ref,      :string                         # the GAM id, nullable (mirrors transactions.ref)
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  create index(:revenue_ledger, [:account])        # house_balance() aggregate
  create index(:revenue_ledger, [:ref])            # revenue_breakdown(game) by ref
end

def down do
  drop table(:revenue_ledger)
end
```

- **Reversible by construction.** `down` is `drop table` — a clean reverse (the table is new, nothing
  depends on it). Because the table is **additive** and no cm.5 column/index is touched, there is **no
  destructive at-rest op** on shipped data: `up`/`down` is create/drop, fresh reinit on `codemojex_test` is
  clean (surface the DB target first, cm.6.md Acceptance).
- **No CHECK is the deliberate difference from `players`.** The bank-architect lens *wants* the signed,
  unconstrained `delta` — it is what admits the seed debit (L-3 is the constraint cm.6 must NOT inherit on
  the house). The append-only discipline (no `updated_at`) matches `transactions` (L-1): a balance is a sum
  of immutable rows, never an in-place mutation.
- **The destructive gate** (cm.6.md Acceptance "+ the destructive gate if a column/table is dropped") is
  **not triggered** by this migration's `up` (it only *creates*). It would apply only if a later rung drops
  `revenue_ledger`; flagged so the Director knows cm.6's `up` is non-destructive and the gate is a no-op here.
- **Frozen-migration verification** (the gate): `git diff` on the two shipped migrations + the cm.5
  `golden_rooms` migration must be **empty** — cm.6 only adds the new file. State this as a pre-ship check.

## §9 — cm.5-stays-green strategy + the ≥100-determinism + boundary posture

**cm.5 stays green — by the additive composition (F3 Arm 1), not by luck.** The recommended arms make
"cm.5 untouched" structural rather than aspirational:

- **F1 Arm 2 (dedicated table)** means the house side **never touches `players`** — no `players_non_negative`
  interaction, no balance-column read any cm.5 path depends on. The sentinel-`PLR` arm (F1 Arm 1) would put a
  house row into `players` and risk cm.5 `players` aggregates; the dedicated table eliminates that surface.
- **F3 Arm 1 (overlay)** means the `delta:0` buy_in marker (L-2, the exactly-once authority), the
  `players.keys -= fee` debit (L-4), and the `inc_pool!` games-column `+` (L-4) all stay **byte-for-byte**.
  The cm.5 pool/player stories (S-FIRSTMOVER, S-SPLIT, S-VIRTUALDEPOSIT) read the same `prize_pool` and the
  same `players.keys` — cm.6 adds rows in a **new table**, moving no cm.5 figure (S-EXISTING-GREEN).
- **The one cm.5-path edit to surface:** site 1 (seed) requires the seed to be inside a `Repo.transaction` the
  house debit can join (§5 flag). If `start_game`'s seed is already transactional, the house debit joins with
  zero edit; if it is a bare `inc`, wrapping it is an **additive** change (same figures, now atomic with the
  debit) that the Director must see explicitly as the lone exception to "F3 Arm 1 touches nothing."

**The ≥100 determinism loop (HIGH-risk, money + new id mints).** cm.6 mints new `revenue_ledger` ids inside
`buy_in`/`start_game`/`close_void` — the **same-millisecond branded-id mint hazard** applies (the BCS id
contract: a same-ms mint within a run can collide if seq exhausts). Ratify with the repeated full-suite loop,
reinit-per-iter:

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done
```

A multi-seed sweep alone is **insufficient** here (re-seeding does not reproduce same-ms mint contention) —
the loop is mandatory because cm.6 adds id mints on the hot buy-in path.

**Boundary posture.** The boundary is **⊆ `echo/apps/codemojex/**` + the rung docs**:
`schemas/revenue_ledger.ex` (new), `priv/repo/migrations/<ts>_create_revenue_ledger.exs` (new),
`lib/codemojex/wallet.ex` (the `house_post` helper + the 5 site calls + the 2 reconciliation reads),
possibly `lib/codemojex/rooms.ex` (site 1 seed-txn wrap, site 5 reclaim), and the rung's spec/story files. No
sibling umbrella app (the codemojex boundary law); **`mix.lock` untouched** (no new dep — the new schema uses
the existing Ecto/`exqlite` stack). Surface the DB target (`codemojex_test`) before the migration runs
(cm.6.md Acceptance).

**The gate ladder** (codemojex, from the app dir): re-probe `asdf current` / `.tool-versions` from
`echo/apps/codemojex`; `valkey-cli -p 6390 ping` → `PONG`; Postgres up + `codemojex_test` reinit;
`TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include valkey` (incl. the new
revenue-ledger stories + the cm.5 suite green untouched); the migration up/down + fresh reinit; the ≥100
determinism loop; the frozen-migration `git diff` empty.

## §10 — Build-precision flags + coordination note (the contracts Mars wires both sides of)

**Build-precision flags (Mars — the load-bearing details).**

- **F-1 — The house credit is the COMPLEMENT, computed from `entry_fee_split`'s output, never re-derived.**
  At sites 2/3/4 (§5) the house keys = `entry_fee_keys − div(pool, 10)`, where `pool` is `entry_fee_split`'s
  return (wallet.ex:228). **Do NOT re-implement the waterfall** (the band boundaries) in cm.6 — reuse the
  `pool` already computed. The inverse `div(pool, 10)` is exact because `pool = pool_keys × 10` (economy.ex:48).
- **F-2 — The seed magnitude is `virtual_deposit / 10` keys.** The pool is seeded in 💎 (`virtual_deposit`),
  the house debit is in keys — convert with `div(virtual_deposit, 10)` (the inverse ×10). Confirm
  `virtual_deposit` is a multiple of 10 (cm.5's seed sizing) so the keys conversion is exact; if not, flag the
  sub-diamond residue to the Director (a cm.5 fact, not a cm.6 choice).
- **F-3 — `house_post` does NOT touch a balance column.** It inserts a `revenue_ledger` row only (the balance
  is the sum of rows, L-1 pattern) — so it never hits `players_non_negative` and needs no player lock. It
  mirrors `txn!` (wallet.ex:380) structurally but targets the new table.
- **F-4 — Every house post rides the cm.5 movement's existing `Repo.transaction`** (S-ATOMIC-DOUBLE-ENTRY) —
  sites 2/3/4 inside `buy_in`'s txn (wallet.ex:204), site 1 inside the seed txn, site 5 inside `close_void`'s
  txn. Never open a new transaction (that would break atomicity and the games-row lock inheritance, L-11).
- **F-5 — `ref = game` on all five posts** (the per-game reconciliation key, §7). The seed/reclaim are also
  `ref = game` so `revenue_breakdown(game)` sees the whole story.
- **F-6 — The id brand** (the one open sub-fork in §4): `RVL` (new namespace) vs reuse `TXN`. Mars uses
  whichever the Stage-1 ruling sets; the table is the type boundary either way.

**The contracts Mars wires both sides of (the dual-architect coordination note).** This design (the
bank-architect lens) and the steward-lens design (`cm.6.design.a.md`) will differ chiefly on **F1** (this lens
ranks the dedicated `revenue_ledger` table first; the steward lens is expected to rank the sentinel `PLR` /
smallest-diff first) and on **F3 framing** (both should land on the additive overlay for Acceptance, but this
lens attaches the explicit "balances by conservation, not Σ-rows-to-zero" honesty statement + names the
deferred reconcile rung). The Operator rules F1/F2/F3; **Mars then wires whichever arms win on BOTH sides of
each paired entry** — the player/pool legs (cm.5, untouched under F3 Arm 1) and the house leg (the new rows).
The contract Mars must hold regardless of the ruling:

1. **Every revenue movement is paired and atomic** — a house post in the same txn as its cm.5 movement.
2. **The amounts are unchanged from cm.5** — cm.6 records, it does not re-price (Scope Out: no new fee, no
   moved figure).
3. **The invariant is proven** — at the keys unit, by the property test (§6), under the determinism loop.
4. **The honesty statement ships in the rung** (this lens's one non-negotiable): cm.6's ledger balances by
   **conservation**, not by `Σ all-ledger-rows = 0`, until the entry-leg reconcile (F3 Arm 2) is its own rung.

**Constraints this design could NOT ground (surfaced, not invented):**

- **The `virtual_deposit` exact value / its relation to `start_threshold × entry_fee_keys`** — §6's
  "house net ≈ 0 after the recovery band" assumes the seed is sized to the first-band recoveries (cm.5's
  design intent). The *exact* sizing is a cm.5 fact in `rooms.ex`/economy config not quoted in the as-built
  block; Mars/Venus-Postgres should confirm it at the seed site before pinning the zero-loss figure.
- **`start_game`'s seed transaction boundary** — whether the cm.5 seed is already inside a `Repo.transaction`
  (site 1 joins free) or a bare `inc` (needs an additive wrap). Flagged in §5/§9; a spot-read of `rooms.ex`
  `start_game` at build time resolves it. Not invented here — the as-built block gives the seed *amount* and
  *site* but not its txn shape.
- **The void reclaim's exact amount composition** — §5 site 5 states "kept fees + unpaid seed"; the precise
  `close_void` arithmetic (which fees are "kept", how the unpaid-seed remainder is computed) is a cm.5
  `close_void` detail; Mars confirms at the site.
