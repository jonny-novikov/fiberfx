# cm.6 — The Revenue Ledger · Director Consolidation (the staged disagreement)

> The Director's synthesis of the two independent architect designs — `cm.6.design.a.md` (the **minimal-ledger
> steward** lens, Venus-A) and `cm.6.design.b.md` (the **bank-architect / finance** lens, Venus-B) — authored
> blind from one locked-constraints brief (the dual-architect debate, `aaw.architect-approach.md` §"The
> multi-architect debate"). The three judgments stay separate: **the architects argued, the Director
> synthesizes here, the Operator rules.** Nothing below is a decision; F2/F3 are *recommend-lock* (both lenses +
> the Director converge), F1 is *the real fork* (a genuine divergence), surfaced for the ruling.

---

## 1 — Convergence / divergence map

| Fork | Venus-A (steward) | Venus-B (bank) | Status | Director |
|---|---|---|---|---|
| **F1 — house representation** | **Arm 1** — a *row-less* reserved `PLR` id; balance = `SUM(delta)` over `transactions`; **zero migration** | **Arm 2** — a dedicated signed `revenue_ledger` table (`account` dim); **one additive table** | **DIVERGE — the real decision** | lean **Arm 2** (below), with the genuine Arm-1 counter |
| **F2 — ledger unit** | **Arm 1** keys-unit | **Arm 1** keys-unit | **CONVERGE** (identical reasoning) | **recommend-lock Arm 1** |
| **F3 — entry-side** | **Arm 1** additive overlay + honesty caveat | **Arm 1** additive overlay + honesty caveat | **CONVERGE** (identical, same caveat) | **recommend-lock Arm 1 + the mandatory honesty statement** |

The whole decision reduces to **F1**. F2 and F3 are settled by agreement; the build can proceed on them the
moment F1 is ruled. Both designs independently propose the **same seam** (`Wallet.house_account/0` +
`house_balance/0..1`) that the five credit sites bind to — so **the F1 representation is reversible behind one
accessor**, which lowers the stakes of the ruling (ship one arm now, migrate later by re-pointing two functions).

---

## 2 — F2 (ledger unit) — CONVERGED → keys-unit

Both lenses rank **keys-unit** first for the *same* reason, verified at source: the split is floored **in keys
before the ×10** (`entry_fee_split`, `economy.ex:42,47`), so `house_keys + pool_keys == entry_fee_keys` holds
with **zero residue at the unit it is defined in**; the 💎/¢ figure finance wants is a **pure, exact read-time
conversion** (`Economy.diamonds_for_keys` / `to_cents`, `economy.ex:19-22`), never a per-write lossy step.
Venus-B adds the forward-risk: normalizing to 💎 now bets the BNK rake never denominates a sub-10-💎 fee — a bet
a percentage-of-pool rake is likely to lose. **Recommend-lock: keys-unit; conversion is a reporting view.**

## 3 — F3 (entry-side) — CONVERGED → additive overlay + a mandatory honesty statement

Both lenses rank **additive overlay** first for the *same* reason: reconciling the entry path (Arm 2) means
editing the **`delta:0` buy_in marker that IS the exactly-once authority** (the `(player, ref) WHERE
reason='buy_in'` partial unique index) and the **`prize_pool` column every cm.5 finish/void reads** — a
money-critical regression surface that cm.6.md S-EXISTING-GREEN forbids, and which is explicitly Scope Out (the
pool denomination + the distribution double-entry are cm.5-resolved). The overlay adds house rows in the same
`Repo.transaction`; cm.5's player/pool sites stay byte-for-byte.

**The non-negotiable both lenses attach (recommend-lock as a hard acceptance item):** cm.6 must **state plainly
that its ledger balances by CONSERVATION** — the three-term keys identity `Σ player_key_debits ==
Σ house_key_credits + Σ pool_key_portions`, proven over three *observable* quantities (the `players.keys`
deltas, the house `TXN`/`revenue_ledger` credits, the `games.prize_pool` 💎 ÷10) — **NOT** by `Σ all-ledger-rows
= 0`, because the player debit and the pool credit are balance *columns*, not signed rows. And cm.6 must **name
"reconcile the entry legs into signed rows + a pool account" as the explicit deferred bank rung** (F3-Arm2), so
the half-balanced ledger is a *known, deferred* debt — not a silent one. **Without this statement the rung ships
a ledger that looks complete and is not.**

---

## 4 — F1 (house representation) — THE FORK (staged disagreement)

Both architects **agree on the crux**: the house is a *fundamentally different account kind* than a player — it
must legitimately swing **negative** on the `deposit_seed` debit (the Director confirmed this at `rooms.ex`: a
voided room holds `−seed + Σ recovery`, with `Σ recovery < seed`, genuinely negative until the reclaim). The
`players_non_negative` CHECK (`player.ex:43-47`, applied to *every* player row by `guard/1`) fights this. The
two arms are two ways to escape the CHECK:

### Arm 1 — the row-less sentinel id (Venus-A)
The house has **no `players` row** — it is a reserved `PLR` *id*, and its balance is `SUM(delta) WHERE
player=house_id` over `transactions`. The CHECK constrains *columns* the house does not have, so the seed debit
is just a negative `TXN` row (`transactions.delta` has no CHECK). **Cost: zero new schema, zero migration.**
- **Liability (C-2, actor-conflation):** the house id shares the `PLR` namespace and the `transactions` table
  with real players — so **every** aggregate over `players`/`transactions` (a leaderboard, a keys-in-circulation
  audit, "sum all debits") must remember a `player != house_id` exclusion predicate. A permanent, gate-invisible
  footgun on withdrawable money.

### Arm 2 — the dedicated `revenue_ledger` table (Venus-B), at its *honest minimum*
One new additive table mirroring the proven `transactions` row, signed, **no non-negative CHECK**, plus a single
`account` string (the BNK seam — a rake credits `account="platform"`, a withdrawal debits it). The seed debit is
*expected* by construction; the reconciliation read is a clean aggregate over a table holding **only** platform
movements — **no sentinel to filter out of player space.** **Cost: one frozen table; a clean `down: drop table`
(non-destructive on shipped data); a fresh `codemojex_test` reinit.**

### The decisive question (both architects converged on it)
> **Is the BNK account lifecycle (rake · withdrawal) specified enough to justify building its table now?**
> Venus-A: if *no* → Arm 1 + seam (don't build speculative surface). Venus-B: even without the full spec, the
> *honest-minimum* table is bounded (one `account` column, nothing speculative) and is **less** total freeze
> risk than writing revenue into the player ledger and untangling it later.

### Director recommendation — **Arm 2 (dedicated `revenue_ledger`, honest minimum)**, surfaced for the ruling
Three reasons carry it: **(1)** the Operator's stated intent — cm.6.md frames this rung as "the foundation the
BNK bank builds on" + "a queryable platform-revenue balance"; a dedicated table delivers that with no
sentinel-exclusion caveat. **(2)** The conflation footgun (C-2) is a *recurring, gate-invisible* risk on
withdrawable money — a dedicated table eliminates it by construction, where Arm 1 carries it forever. **(3)** The
house genuinely **is** a different account kind (both lenses agree; the void analysis proves the negative
balance), so modelling it as a player is against the grain — and Venus-B's minimum table is *bounded* (mirrors a
trusted schema, one seam column, a clean drop).

**The genuine Arm-1 counter (do not discount):** Arm 1 is the lightest possible cm.6 — *zero* migration, *one*
source of truth (no duplicated-state table), and **reversible behind the seam** (if BNK later needs the table,
re-point `house_account/0` + migrate the house's `ref`-keyed `TXN`s). If the Operator wants the absolute
smallest diff now and accepts the exclusion-predicate discipline, Arm 1 ships sooner and is not a trap. **The
ruling turns on: build the clean bank substrate now (Arm 2), or defer it behind the seam and carry the
conflation discipline (Arm 1).** The Director leans Arm 2 on a money system meant to grow into a bank; the
Operator rules.

*Sub-fork under Arm 2 (minor, Operator/Mars):* the `revenue_ledger` id brand — mint a new `RVL` namespace (the
BCS "brand IS the type" discipline; a first-class account deserves a first-class brand) **vs** reuse the `TXN`
brand (no new namespace; the table is the type boundary either way). Director lean: **`RVL`** (cheap, and it
keeps revenue rows type-distinguishable at every boundary).

---

## 5 — Shared findings (high-signal — two blind architects surfaced each independently)

1. **The seam** `Wallet.house_account/0` + `house_balance/0..1` — the arm-invariant interface the five credit
   sites + the reconciliation read bind to; makes the F1 ruling reversible. **Ships regardless of F1.**
2. **The complement computation** — the house keys cut is `entry_fee_keys − div(pool, 10)` where `pool` is
   `entry_fee_split`'s return; **reuse that output, never re-implement the waterfall bands** (a NO-INVENT pin).
   Expose the floored keys portion once so both the pool 💎 (×10) and the house cut derive from the *one* floor.
3. **SEAM-1 / SEAM-2** — the seed and the void are not where cm.6.md's atomicity language assumes (§6 below).

## 6 — Director factual resolutions (grounded at `rooms.ex` this session — refine cm.6.md)

- **SEAM-1 (the seed) → cm.6.md S-SEED is not free.** The golden seed lands via a **bare `Store.put_game(gid,
  game)`** (`rooms.ex:136`) in `formation/3` (`rooms.ex:173-178`) — *not* an explicit `Repo.transaction`. To
  honor S-SEED "paired and atomic," Mars wraps the games-row seed write + the house `deposit_seed` debit in one
  Postgres `Repo.transaction` (one additive edit to the seed path — the lone F3-Arm1 exception that touches a
  cm.5 site), OR the Operator accepts cross-store coupling and S-SEED is restated as a *settlement* property, not
  a per-instant one. **Director lean: wrap it** (atomicity is worth one additive edit on a money rung) — pending
  a build-time spot-read of `Store.put_game`'s internals. **This refines cm.6.md S-SEED.**
- **SEAM-2 (the void) → cm.6.md S-VOID-RECLAIM = `+seed` ONLY.** `close_void` (`rooms.ex:462-472`) moves **no
  money** today (Valkey `SET …:closed NX`, no per-player loop). A voided room only ever took deposit-recovery-band
  buy-ins (it never reached `start_threshold`), so those fees are **already booked** at buy-in under the overlay.
  The reclaim books **`+seed`** (cancelling the formation seed debit) → house net = **Σ kept fees**. Booking
  `Σ fees + seed` (Venus-B's site-5 framing) **double-counts** — the Director locks **Venus-A's reading**. cm.6
  adds the reclaim credit under the *existing* NX close lock (the exactly-once guard). **This refines cm.6.md
  S-VOID-RECLAIM.**

## 7 — What ships regardless of the F1 ruling (so the build proceeds on the ruling alone)

The five economic movements + their keys amounts are **arm-invariant** — only *where the credit lands* (a
sentinel `TXN` vs a `revenue_ledger` row) changes:

| Movement | cm.5 site | House keys post | Same `Repo.transaction`? |
|---|---|---|---|
| deposit_seed | `start_game`/`formation` seed (`rooms.ex:136,173-178`) | `−div(virtual_deposit,10)` | SEAM-1 — wrap (lean) |
| deposit_recovery (ord ≤ threshold) | `buy_in` `:wrote` (`wallet.ex:224-238`) | `+entry_fee_keys` | YES (buy_in txn) |
| first-mover (band) | same, with `inc_pool!` | `+(entry_fee_keys − div(pool,10))` | YES |
| full revenue (ord > band) | same | `+entry_fee_keys` | YES |
| void reclaim | `close_void` (`rooms.ex:462`) | `+div(virtual_deposit,10)` (seed-cancelling) | SEAM-2 — under the NX lock |

Plus: the keys-unit balance invariant (the conservation property test against a cm.5-only computation,
S-RECONCILE) · the seam + reconciliation read (`SUM(delta) … GROUP BY reason`) · the ≥100 determinism loop
(cm.6 adds a *second* `TXN`/`RVL` id mint per buy-in → new same-ms contention; the loop, not the lock, is its
guard) · boundary ⊆ `echo/apps/codemojex/**` · `mix.lock` untouched · the three shipped migrations byte-frozen.

## 8 — Open questions for the Operator (the ruling)

1. **F1 — the house representation:** Arm 2 dedicated `revenue_ledger` (Director lean) **vs** Arm 1 row-less
   sentinel id. (F2 keys-unit + F3 additive-overlay+honesty are recommend-lock by convergence.)
2. **SEAM-1 — the seed:** wrap the seed write for true atomicity (one additive cm.5-path edit, Director lean)
   **vs** accept cross-store coupling and restate S-SEED.
3. **Sub-fork (only if F1=Arm2):** `RVL` brand (lean) vs reuse `TXN`.
4. **Calibration (Mars-confirm, not a ruling):** `virtual_deposit` vs `start_threshold × entry_fee_keys` — the
   exact zero-loss residual is a cm.5 config fact to confirm at the seed site.

**On the ruling, the Director locks the F1/F2/F3 decisions (`D-n`), derives the cm.6 triad from the chosen arms,
and the build proceeds via `/codemojex-ship cm.6` (L2 Squad — Venus + Venus-Postgres + Mars + Apollo).**
