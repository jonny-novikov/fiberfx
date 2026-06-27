# cm.6 — The Revenue Ledger · LLM brief (compact)

> The one-screen brief for an agent picking up cm.6. The authoritative documents are [`cm.6.md`](./cm.6.md)
> (the ruled body — wins on any disagreement), [`cm.6.stories.md`](./cm.6.stories.md) (the acceptance face),
> the `cm-6` decision ledger (`D-1..D-7`), and the two designs ([`cm.6.design.a.md`](./cm.6.design.a.md) /
> [`cm.6.design.b.md`](./cm.6.design.b.md)) + the Director synthesis
> ([`cm.6.design.consolidation.md`](./cm.6.design.consolidation.md)). Venus-Postgres authors the relational
> design + migration ([`cm.6.postgres.design.md`](./cm.6.postgres.design.md)) to the `D-1`/`D-6` contract.

## The rung in one paragraph

cm.6 makes the Golden Room **revenue side** explicit balanced double-entry. cm.5 records the **player** side
(a `buy_in` debit + a `delta:0` membership marker) and the **pool** side (the `prize_pool` 💎 increment) but
leaves the **platform** cut *implicit* (derivable only by conservation: `keys_debited − keys_to_pool`). This
rung books every platform cut as a real signed row in a **new, dedicated `revenue_ledger` table** (`D-1`,
Arm 2) — RVL-branded (`D-6`), signed, **no non-negative CHECK**, designed **multi-source / multi-currency** so
the BNK bank and the cm.7 KeyShop plug into the same ledger. It is an **additive overlay** (`D-3`): cm.5's
buy-in shape stays byte-for-byte; cm.6 adds house rows in the same `Repo.transaction`. The ledger holds the
Golden cuts in **keys** (`D-2`, the unit the balance invariant is exact in); 💎/¢ is a pure read-time
conversion. It is the **first slice of the BNK bank** and the named follow-on to cm.5 (`D-15`). **Risk: HIGH**
(withdrawable money + a new schema surface + a balance invariant) → L2 Squad, Apollo mandatory, Venus-Postgres
on the relational redesign, the ≥100 determinism loop, the migration up/down.

## The five revenue movements (arm-invariant; keys; `ref=game`)

| Movement | cm.5 site (live `file:line`) | House `revenue_ledger` post (keys) | Same `Repo.transaction`? |
|---|---|---|---|
| `deposit_seed` | `Rooms.formation/3` golden seed `rooms.ex:171-178` (bare `Store.put_game` `rooms.ex:136`) | `−div(virtual_deposit, 10)` | SEAM-1 — **wrap** (`D-4`) |
| `deposit_recovery` (ord ≤ threshold) | `Wallet.buy_in/2` `:wrote` `wallet.ex:224-238` (debit `:226`) | `+entry_fee_keys` | YES (inside `buy_in`) |
| first-mover `revenue` (band) | same + `inc_pool!` `wallet.ex:237` | `+(entry_fee_keys − pool_keys)` | YES |
| full `revenue` (ord > band) | same `wallet.ex:224-238` | `+entry_fee_keys` | YES |
| `deposit_reclaim` (void) | `Rooms.close_void/2` `rooms.ex:462-472` (NX lock `:463`) | `+div(virtual_deposit, 10)` (seed-cancelling) | SEAM-2 — under the NX lock (`D-4`) |

`pool_keys = div(entry_fee_keys × (100 − rev%), 100)` (`economy.ex:47`, floored in keys). The house cut is
the **keys complement** `fee − pool_keys`; the pool 💎 is `pool_keys × 10` — both from the **one** floor
(expose `Economy.entry_fee_split_keys/5`, `D-7`/PF-3; do not re-floor, do not recompute from 💎).

## Deliverables

1. **`revenue_ledger`** table + schema + a **new additive** migration (Venus-Postgres authors the relational
   design to the `D-1`/`D-6` column contract: `{id (RVL), account/source, currency, delta signed bigint NO
   CHECK, reason, ref, inserted_at}`).
2. **`Wallet.house_post`** (or `book_house`) — the single signed-`revenue_ledger`-row primitive (the Arm-2
   analogue of the private `txn!` at `wallet.ex:380`; **NOT** `credit` `wallet.ex:305-320`, which locks a
   `players` row and would re-break the non-negative collision). Reachable from the buy-in sites (inside
   `Wallet`) and from `Rooms` (SEAM-1/SEAM-2, via the public boundary fn).
3. **`Economy.entry_fee_split_keys/5`** — a new pure fn returning the keys pool portion (`entry_fee_split/5`,
   the 💎 fn, stays byte-unchanged).
4. The **five paired credits** at the cm.5 sites (the buy-in three inside `buy_in`'s `Repo.transaction`;
   SEAM-1 the seed wrap; SEAM-2 the void reclaim under the NX lock).
5. **`Wallet.house_balance/0..1`** — the reconciliation read (`SUM(delta) FROM revenue_ledger WHERE
   account=house [AND ref=game] GROUP BY currency[, reason]`); a pure read, the `buy_in_count` shape
   (`wallet.ex:330`) re-aimed at the ledger.
6. The **stories** + the **conservation-honesty statement** in the body (`D-3`, mandatory).

## Invariants as gates (what closes the rung)

- **Balance (THE headline):** the three-term keys identity
  `Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)`, over **three observable
  columns** (the `players.keys` deltas, the `revenue_ledger` credits, `games.prize_pool` 💎 ÷ 10) — proven by
  a **property test**. The `×10` is the one accounted minting boundary (floor-before-×10, conservative).
- **Conservation, not zero-sum (`D-3`, mandatory):** the spec **states plainly** it balances by conservation,
  **NOT** `Σ all-ledger-rows = 0` (the player debit is a bare column delta + the pool is a column), and
  **names** the entry-leg reconcile (signed buy-in debit + a pool account) as the explicit **deferred** bank
  rung. *Without this statement the rung ships a ledger that looks complete and is not.*
- **Explicit == implicit:** `house_balance(game)` (keys) equals the conservation figure cm.5 leaves implicit
  (`Σ fee_i − Σ pool_💎_i / 10`) — the same number, now a row; a property test against a cm.5-only
  computation.
- **Atomicity:** the house credit is one more write in `buy_in`'s `Repo.transaction` (`wallet.ex:204`) under
  the games-row `FOR UPDATE` lock (cm.5 `RULING 1`) — all-or-nothing, no new lock, no new race.
- **`+seed`-only reclaim (PF-4, money-critical):** the void books `+div(V,10)` (seed-cancelling), **not**
  `Σ fees + seed` (the fees are already booked at buy-in — `Σ fees + seed` double-counts). Idempotent under
  the NX close lock.
- **cm.5 stays green (`D-3`):** the cm.5 story suites pass **byte-unchanged**; `git diff --stat` over the
  cm.5 story files is empty; the **three** shipped migrations stay **byte-frozen**.
- **The ≥100 determinism loop (PF-6):** buy-in now mints **two** ids (the `TXN` marker + the `RVL` row) — the
  new same-ms contention surface; the loop is mandatory and its posture names it.
- **Boundary:** ⊆ `echo/apps/codemojex/**` + the rung docs; `mix.lock` untouched.

## The gate ladder (run from `echo/apps/codemojex`, NEVER umbrella-wide)

`asdf current` (re-probe; Elixir 1.18.4 / Erlang 28.5.0.1) · `valkey-cli -p 6390 ping` → `PONG` ·
`pg_isready` · `TMPDIR=/tmp mix compile --warnings-as-errors` · `TMPDIR=/tmp mix test --include valkey`
(boots the full tree — needs **both** Valkey 6390 **and** Postgres) · the schema reinit
`MIX_ENV=test mix ecto.drop && ecto.create && ecto.migrate` scoped to the **`config/test.exs`** DB
(`codemojex_test`, read it — never assume; surface it before the drop) + the migration up/down proof · the
**≥100** loop (`for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done`) · the
privacy line holds · `mix codemojex.stories` regenerates the per-feature faces.

## Scope out (do not build this rung)

- The BNK **rake** / fee model + **withdrawal** (later BNK slices on this house account).
- **cm.7 the KeyShop** (`D-5`): the `packages` catalog table + the Telegram XTR invoice flow
  (invoice → pre_checkout → successful_payment, exactly-once on the charge id) + the pure `KeyShop` pricing
  module + booking gross-Stars purchase revenue into the **same** `revenue_ledger` (`source="purchase"`,
  `currency="stars"`). cm.6's ledger is **shaped** for it; it is **not** built here.
- Any cm.5-resolved surface (`gold_multiplier`, the no-refund void, the pool denomination, the distribution
  double-entry) — untouched; cm.6 is purely additive on the revenue side.
- Retroactive backfill — **forward-only**; the house balance begins at cm.6 (the discontinuity is noted for
  finance).
