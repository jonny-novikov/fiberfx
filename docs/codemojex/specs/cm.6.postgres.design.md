# cm.6 · The Revenue Ledger — the relational redesign

> **Status — the build's Stage-1, authored from the LOCKED rulings (cm-6 ledger `D-1`..`D-6`).** This is the
> column-by-column schema design for the platform **revenue ledger**, the additive migration (up + down), the
> five insertion points keyed to the cm.5 as-built money sites, the reconciliation read, the balance-invariant
> proof, and the reinitialization plan — authored from the **relational lens** in parallel with Venus-Triad's
> triad, coordinated by the `D-1`/`D-6` contract (no sibling read). The forks are **RULED** (`D-1`..`D-6`):
> converge, do not re-debate. NO-INVENT: every column / index / type / site is grounded at a real
> `schemas/*.ex` · `lib/codemojex/*.ex` · `priv/repo/migrations/*.exs` `file:line`, the ledger `D-1`..`D-6`, or
> marked **(forward)** for the unbuilt cm.6 surface. Mars owns the production edits; this doc is the contract
> Mars builds to and the Operator/Apollo accept against.

Paths below are relative to `echo/apps/codemojex/` unless rooted. The boundary is the codemojex app: one new
schema file, one new migration, the Postgres I/O modules (`lib/codemojex/wallet.ex`, `lib/codemojex/rooms.ex`).

---

## §0 — The locked constraints (design around, not about — cm-6 ledger `D-1`..`D-6`, verbatim intent)

The lens of this design is the **relational shape under the rulings**: the forks are decided (`D-1`..`D-6`),
so this doc converges on the chosen arms and builds them out column-by-column — it does not re-argue them.
The constraints below are the **rulings** (the contract this design implements) and the **as-built money
surface** the ledger sits beside (verified at `file:line`, none re-derived).

### The rulings (cm-6 ledger `{cm-6-decisions}` — the contract)

- **`D-1` — A dedicated `revenue_ledger` table.** Not a sentinel `PLR` row. A signed table mirroring
  `transactions`, **NO non-negative CHECK**, designed **multi-source / multi-currency** from the start
  (an `account` source dimension + a `currency` field). Holds Golden Room cuts (keys) now; Stars/cents
  purchase revenue plugs in at cm.7. Balance = `SUM(delta)` over a table that holds **only** platform
  movements (no sentinel to filter out of player space). The reversibility seam
  (`Wallet.house_account/0` + `house_balance/0..1`) is kept regardless — the call sites bind to it.
- **`D-2` — Keys-unit is the Golden conservation unit; the ledger is multi-currency.** Keys is the unit the
  Golden Room balance invariant is proven in (`house_keys + pool_keys == entry_fee_keys`, exact integer,
  floored-in-keys **before** the ×10 — `economy.ex:42,47`). The `currency` field carries the multi-currency
  intent: golden-cut rows in `"keys"`; cm.7 purchase rows in `"stars"`/`"cents"`. The 💎/¢ figure finance
  wants is a **pure read-time conversion** (`Economy.diamonds_for_keys` / `to_cents`, `economy.ex:19,22`),
  never a per-write lossy step.
- **`D-3` — Additive overlay + a MANDATORY conservation-honesty statement.** cm.5's buy-in shape stays
  byte-for-byte — the `delta:0` `buy_in` marker (the exactly-once authority), the bare `keys -= fee` debit
  (`wallet.ex:226`), the `inc_pool!` games-column `+` (`wallet.ex:371`) are **UNTOUCHED**; cm.6 **ADDS**
  house `revenue_ledger` rows in the same `Repo.transaction`. The design must **state plainly that it
  balances by CONSERVATION** — the three-term keys identity over three observable quantities — **NOT** by
  `Σ all-ledger-rows = 0`, and must **name the entry-leg reconcile as the deferred bank rung** (§6, §10).
- **`D-4` — SEAM-1 wrap + SEAM-2 `+seed` only.** SEAM-1: the golden seed lands via a bare
  `Store.put_game(gid, game)` (`rooms.ex:136`), **not** a `Repo.transaction`; wrap the games-row seed write
  + the house `deposit_seed` debit in **ONE** `Repo.transaction` (the lone overlay exception touching a cm.5
  site — additive). SEAM-2: `close_void` (`rooms.ex:462-472`) moves no money today; the reclaim books
  **`+seed` ONLY** (the kept fees are already booked at buy-in — `Σ fees + seed` would double-count), under
  the existing NX close lock.
- **`D-5` — The cm.6 / cm.7 split.** cm.6 = the Golden-Room revenue ledger on the `D-1` substrate, **designed
  multi-source/multi-currency** so cm.7 plugs in with no ledger re-design. cm.7 = the KeyShop (a `packages`
  catalog table + the Telegram XTR invoice flow + a pure `KeyShop` pricing module + booking gross-Stars
  purchase revenue to the **same** `revenue_ledger`, `source="purchase"`, `currency="stars"`). **cm.6 does
  NOT build the catalog or the invoice flow** — only the ledger that receives them.
- **`D-6` — The `RVL` brand.** The `revenue_ledger` row id is a new 3-char branded namespace `RVL`
  (`EchoData.BrandedId.generate!("RVL")`), so revenue rows are type-distinguishable from player `TXN` rows at
  every boundary (the BCS law: the brand IS the type).

### The as-built money surface (the ledger sits beside it — verified, none re-derived)

- **A-1 — The existing ledger is `transactions`** (`schemas/transaction.ex:6-15`): `@primary_key
  {:id, :string, autogenerate: false}`; fields `{player, currency (string), delta (integer, signed), reason
  (string), ref (string)}` + `timestamps(type: :utc_datetime_usec, updated_at: false)` — append-only, no
  `updated_at`. The `revenue_ledger` **mirrors this row shape** (`D-1`), swapping `player → account`,
  widening `delta` to `:bigint`, and **omitting** the non-negative guard.
- **A-2 — The signed-row write primitive is `txn!/5`** (`wallet.ex:380-396`): mints
  `EchoData.BrandedId.generate!("TXN")`, inserts a `%Transaction{}` via `Transaction.changeset/2`, returns
  the id. The cm.6 `house_post/5` **mirrors `txn!` exactly** but mints `"RVL"` (`D-6`) and targets
  `revenue_ledger` — and, unlike `credit/5`/`debit/5`, it touches **no balance column** (F-3, §5).
- **A-3 — The buy-in `:wrote` branch** (`wallet.ex:224-238`): `fee = g.entry_fee_keys || 0`
  (`wallet.ex:218`); the bare debit `update!(p, %{keys: p.keys - fee})` (`wallet.ex:226`, the `delta:0`
  marker stays at `wallet.ex:347-366`); the pool 💎 `pool = Economy.entry_fee_split(ordinal, …, fee)`
  (`wallet.ex:228-235`); `inc_pool!(game, pool)` (`wallet.ex:237`). All inside `buy_in`'s single
  `Repo.transaction` (`wallet.ex:204`) under the games-row `FOR UPDATE` lock (`wallet.ex:205`,
  `lock_game/1` `wallet.ex:326`). The **ordinal** is `before + 1`, `before = buy_in_count(game)`
  (`wallet.ex:216-217`).
- **A-4 — The split math** (`Economy.entry_fee_split/5`, `economy.ex:45-52`): for the first-mover band
  (`ordinal ∈ [start_threshold+1, start_threshold+first_movers]`) it returns the **pool 💎** =
  `div(entry_fee_keys × (100 − revenue_pct), 100) × 10` (floored **in keys** before the ×10); outside the
  band it returns `0`. The **house keys complement** is `entry_fee_keys − div(pool, 10)` — **exact** because
  `pool = pool_keys × 10` (the inverse ×10 recovers `pool_keys` with no residue). `@diamonds_per_key 10`,
  `@cents_per_diamond 1.2` (`economy.ex:10-11`): **1 key = 10 💎 = 12¢**.
- **A-5 — The seed + the void.** Golden `formation/3` (`rooms.ex:173-178`) sets `prize_pool =
  virtual_deposit || seed_pool` 💎; the seed write is the bare `Store.put_game(gid, game)` at
  `rooms.ex:136`. `close_void/2` (`rooms.ex:462-472`) runs under `SET cm:<game>:closed NX`
  (`rooms.ex:463`), transitions `:gathering → :voided` in the `{:ok, "OK"}` branch (`rooms.ex:464-467`),
  and moves **no money** today (`void_if_stale/1` `rooms.ex:447-457` is the sweep caller).
- **A-6 — `Store.put_game` is a bare upsert** (`store.ex:15` → `upsert/3` `store.ex:110-120`): a single
  `Repo.insert(on_conflict: {:replace_all_except, [:id, :inserted_at]}, conflict_target: :id)` — **not**
  inside a `Repo.transaction`. So SEAM-1's wrap is real (`D-4`): the seed write + the house debit join one
  new `Repo.transaction`.
- **A-7 — The non-negative CHECK that the house must NOT inherit** (`player.ex:43-47`, `guard/1`):
  `validate_number(>= 0)` on all five balances + `check_constraint :players_non_negative`. **Every player
  row is non-negative by DB CHECK.** The house must legitimately swing **negative** on the seed debit
  (`−div(virtual_deposit, 10)` keys before recoveries land) — so the `revenue_ledger` carries **no** such
  CHECK (`D-1`); this is the deliberate difference, the schema reason the house is a different account kind.
- **A-8 — FROZEN at-rest surface.** The three shipped migrations are **byte-frozen**:
  `20260618000000_create_codemojex.exs`, `20260625145121_add_player_tg_user_id.exs`,
  `20260626120000_golden_rooms.exs`. cm.6 adds a **NEW 4th** migration; it edits none. Boundary ⊆
  `echo/apps/codemojex/**` + the rung docs; `mix.lock` untouched.

## §1 — The reinitialization target (surfaced FIRST, before any reinit)

The codemojex Ecto Repo (`Codemojex.Repo`) is configured in the **umbrella** config tree (`echo/config/`),
NOT in an app-local `config/` (the app has no `config/` directory — cm.5 §1, unchanged):

| MIX_ENV | DB name | Config site |
|---|---|---|
| `test` | **`codemojex_test`** + `#{MIX_TEST_PARTITION}` suffix | `echo/config/test.exs:19` (pool `Ecto.Adapters.SQL.Sandbox`) |
| `dev` | **`codemojex_dev`** | `echo/config/dev.exs:14` |
| `prod` | `System.get_env("DATABASE_URL")` | `echo/config/runtime.exs` (the Operator's deploy; out of this rung's reinit) |

**No `*_snapshot` database exists** in the echo umbrella config (cm.5 §1 verified it). The only Postgres DBs
are `codemojex_test`(+partition) and `codemojex_dev` — there is nothing to leave untouched.

**Surface the DB target FIRST, then reinit** (from the app dir, per the per-app gate ladder + `TMPDIR=/tmp`):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
MIX_ENV=test TMPDIR=/tmp mix ecto.drop      # drops codemojex_test (+ the active MIX_TEST_PARTITION suffix)
MIX_ENV=test TMPDIR=/tmp mix ecto.create
MIX_ENV=test TMPDIR=/tmp mix ecto.migrate   # replays the 3 shipped migrations + the NEW cm.6 revenue_ledger migration
```

Notes (cm.5 §1, unchanged): (a) the `Ecto.Adapters.SQL.Sandbox` pool runs the suite in transactions, so the
reinit is a one-time schema rebuild before the suite, not per-test; (b) under `MIX_TEST_PARTITION=N`,
`ecto.drop`/`create`/`migrate` run under the **same** partition env so the suffixed DB is the one rebuilt;
(c) the dev DB reinitializes the same way with `MIX_ENV=dev`. `prod` is the Operator's deploy — and because
cm.6's migration `up` is **non-destructive** (a pure `create table`, §4), the prod cutover is a forward
`mix ecto.migrate` with **no destructive at-rest op** (unlike cm.5's `gold_multiplier` `DROP COLUMN`).

## §2 — `revenue_ledger` (NEW table `revenue_ledger`, `schemas/revenue_ledger.ex`)

The platform's revenue **balance** lives here — one signed row per platform movement, append-only, summed to
a balance (`D-1`). The row **mirrors the proven `transactions` shape** (A-1) so the schema is a known
quantity, with three deliberate departures: `account` replaces `player` (the source dimension, `D-1`/`D-5`),
`delta` is `:bigint` and **signed with no non-negative CHECK** (the seed-debit-admitting difference from
`players`, A-7/`D-1`), and the id brand is `RVL` (`D-6`).

| Column | Type · null · default | Why · ground |
|---|---|---|
| `id` | `:string`, **PK**, `autogenerate: false` | the branded `RVL` id (`D-6`), minted `EchoData.BrandedId.generate!("RVL")` (A-2, `branded_id.ex:93`); a 14-byte branded snowflake, **time-ordered** so the ledger sorts by creation. Mirrors `transactions.id` (A-1). |
| `account` | `:string`, `null: false` | the **source / counterparty dimension** (`D-1`/`D-5`). `"platform"` is the sole value this rung (the Golden-Room house). The seam the BNK bank + cm.7 widen — a rake credits `account="platform"`; a withdrawal debits it; cm.7 purchases also book to `"platform"`. Present-but-singular now → **no second table** later. |
| `currency` | `:string`, `null: false` | the entry unit (`D-2`). `"keys"` for every golden-cut row this rung; the multi-currency seam — cm.7 books `"stars"`/`"cents"` rows to the **same** table (`D-5`). The 💎/¢ figure is read-time (`economy.ex:19,22`), never a stored row. Mirrors `transactions.currency` (free-text, A-1). |
| `delta` | `:bigint`, `null: false` | **SIGNED** — a debit (the seed) is negative, a credit (revenue) is positive. **NO non-negative CHECK** — the deliberate difference from `players` (A-7): the house legitimately swings negative on the seed before recoveries land (`D-1`/`D-4`). `:bigint` (not `transactions`' `:integer`) because revenue accrues unbounded over the platform's life and a withdrawal-scale figure must not overflow `int4`; the schema field casts it as `:integer` (Elixir has no width split — the `:bigint` is the migration-side width, mirroring `games.virtual_deposit` `migration:32`). |
| `reason` | `:string`, `null: false` | the movement kind: `"deposit_seed"` (the seed debit) · `"deposit_recovery"` (members `1..start_threshold`) · `"revenue"` (first-mover share + full revenue) · `"deposit_reclaim"` (the void). Free-text like `transactions.reason` (A-1) — **no enum migration** for a new reason (cm.7 adds `"purchase"`/`"refund"` with zero DDL). |
| `ref` | `:string`, **nullable** | the `GAM` game id — the per-game reconciliation key (§7). Nullable, mirroring `transactions.ref` (A-1): a future non-game-scoped platform movement (a manual adjustment, a cm.7 purchase keyed on the Telegram charge id) carries a different `ref` or none. |
| `inserted_at` | `:utc_datetime_usec`, **append-only** | `timestamps(type: :utc_datetime_usec, updated_at: false)` — **no `updated_at`** (A-1): a balance is a sum of immutable rows, never an in-place mutation. Mirrors `transactions` exactly. |

**Why a dedicated table, not a sentinel `players` row (the `D-1` schema reason restated at the column level):**
the house must hold a **negative** balance on the `"deposit_seed"` debit (A-5/A-7); `players` forbids that by
CHECK. A table with **no non-negative CHECK** admits the seed **by construction** — the balance is
`SUM(delta) WHERE account = "platform"`, exactly the `transactions` pattern (A-1), on a table that holds
**only** platform movements (clean reconciliation, no sentinel to exclude from player space, §7).

**The Ecto schema module** (`schemas/revenue_ledger.ex` — NEW; forward-tense; mirrors `transaction.ex:1-28`):

```elixir
defmodule Codemojex.Schemas.RevenueLedger do
  @moduledoc "An append-only platform-revenue row: one signed entry per platform movement (the seed debit, the per-buy-in revenue/recovery credits, the void reclaim). The balance is the sum of rows — never an in-place mutation. Holds ONLY platform movements (account-scoped), so the platform-revenue balance is a clean aggregate with no player rows to exclude. cm.6 (D-1)."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "revenue_ledger" do
    field :account, :string
    field :currency, :string
    field :delta, :integer            # the :bigint column; signed, no non-negative guard (D-1)
    field :reason, :string
    field :ref, :string
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(row, attrs) do
    row
    |> cast(attrs, [:id, :account, :currency, :delta, :reason, :ref])
    |> validate_required([:id, :account, :currency, :delta, :reason])
  end
end
```

- **`validate_required` mirrors `transactions`** (A-1, `transaction.ex:20`): `[:id, :account, :currency,
  :delta, :reason]` — `ref` is **not** required (nullable, like a non-game movement). `account` IS required
  (unlike a free-text optional) — every row must declare its source.
- **NO `guard`, NO `check_constraint`, NO `unique_constraint`.** This is the deliberate inverse of
  `player.ex:43-47` (A-7): the signed `delta` carries no non-negative validation (the seed debit is a legal
  negative row), and there is no exactly-once index on the house side (each house post is a distinct accrual —
  unlike the `buy_in` marker's `(player, ref)` uniqueness, A-3). The id's uniqueness is the `RVL` PK alone.
- **The id mint shape** (`D-6`, A-2): `EchoData.BrandedId.generate!("RVL")` — a fixed-shape call mirroring the
  `GAM`/`ROM`/`PLR`/`TXN` mints (`rooms.ex:90`, `wallet.ex:21,58,348,381`). Mars confirms `"RVL"` parses
  (any 3-letter uppercase namespace is valid, `branded_id.ex` encode contract); no namespace registry edit is
  owed (branded ids are coordination-free).

## §3 — The indexes

Two non-unique indexes, each backing one read shape (§7). No partial index, no unique index (the `RVL` PK is
the sole uniqueness — A-2/§2).

| Index | Backs | Read shape · ground |
|---|---|---|
| `(account)` | `house_balance/0..1` | `SUM(delta) WHERE account = $account [GROUP BY currency]` (§7). The platform-revenue balance aggregate — the single query the rung exists to answer. With one `account` value this rung the selectivity is low, but the index is the seam: as the BNK bank adds `account` values (per-pot, escrow), `WHERE account = …` stays sargable without a rewrite. |
| `(ref)` | `revenue_breakdown/1` | `… WHERE ref = $game [GROUP BY reason]` (§7). A game's whole revenue story (seed / recovery / first-mover / full / reclaim) read by its `GAM` id. Mirrors cm.5's `(ref, reason)` member-set read intent (`transactions_ref_reason_index`, `migration:79`) — a per-game lookup over an append-only ledger. |

- **Why `(account)` not `(account, currency)`:** `house_balance` groups by `currency` in the SELECT, but the
  filter is `account` alone; a composite would not improve the `GROUP BY` and adds width. Keep it single; the
  multi-currency split is a `GROUP BY` over the filtered rows (cheap — one `account`'s rows).
- **Why `(ref)` not `(ref, reason)`:** `revenue_breakdown` filters on `ref` and groups by `reason` in the
  SELECT (like `house_balance`); the single-column `(ref)` index serves the filter and the `GROUP BY reason`
  is over one game's handful of rows. (cm.5's `transactions_ref_reason_index` is `(ref, reason)` because its
  read filters on **both** `ref` AND `reason` — `WHERE ref=$game AND reason='buy_in'`, A-3/`store.ex:25-27`;
  the revenue read filters on `ref` only, so the second column would be dead weight.) **Flag for Mars:** if a
  `WHERE ref=$game AND reason=$r` point-read emerges (e.g. "the seed row for this game"), widen to
  `(ref, reason)`; this rung's reads do not need it.
- **No index on `inserted_at`.** The ledger is summed, not time-sliced, this rung; a finance "revenue since
  date" read (the cm.6.md discontinuity note, §7) is a `WHERE inserted_at >= …` that a later rung indexes if
  it becomes hot. Not provisioned speculatively (the `D-5` discipline: bound the forward-provision to the
  `account`/`currency` dimensions the ruling named).

## §4 — The additive migration (the 4th cm.6 migration; up + down)

**Strategy (decided):** ONE new migration
(`priv/repo/migrations/20260627NNNNNN_create_revenue_ledger.exs`) **creates** the `revenue_ledger` table +
its two indexes. The three shipped migrations stay **byte-frozen** (A-8 — never edit a shipped migration; the
cm.4/cm.5 additive precedent). `up`/`down` are a clean `create table` / `drop table` — **no `change/0`
ambiguity** here (a plain create infers its own down, but explicit up/down matches the cm.5 idiom and makes
the `drop` legible), idiom mirrored from `20260626120000_golden_rooms.exs` (`:bigint` for money,
`timestamps(type: :utc_datetime_usec, updated_at: false)`).

```elixir
defmodule Codemojex.Repo.Migrations.CreateRevenueLedger do
  use Ecto.Migration

  # cm.6 — the platform revenue ledger (cm-6 D-1). A dedicated signed table mirroring
  # `transactions`, designed multi-source (`account`) / multi-currency (`currency`).
  # NO non-negative CHECK — the deliberate difference from `players`: the house
  # legitimately swings negative on the `deposit_seed` debit (D-1/D-4). Additive onto
  # the THREE shipped migrations (all byte-frozen) — cm.6 creates, never edits.
  def up do
    create table(:revenue_ledger, primary_key: false) do
      add :id, :string, primary_key: true     # the branded RVL id (D-6)
      add :account, :string, null: false      # "platform" this rung; the BNK/cm.7 source seam (D-5)
      add :currency, :string, null: false      # "keys" this rung; "stars"/"cents" forward (D-2/D-5)
      add :delta, :bigint, null: false         # SIGNED — no non-negative CHECK (the whole point vs players, D-1)
      add :reason, :string, null: false
      add :ref, :string                         # the GAM id, nullable (mirrors transactions.ref)
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:revenue_ledger, [:account])   # house_balance() aggregate (§7)
    create index(:revenue_ledger, [:ref])        # revenue_breakdown(game) by ref (§7)
  end

  def down do
    drop table(:revenue_ledger)
  end
end
```

- **`up` is NON-DESTRUCTIVE — it only creates.** No cm.5/cm.4 column, index, or CHECK is touched. So the
  **destructive gate** (cm.6.md Acceptance "+ the destructive gate **if** a column/table is dropped") is a
  **no-op on `up`** — flagged so the Director knows cm.6's forward migration drops nothing and the prod
  cutover carries no at-rest data risk (contrast cm.5's `gold_multiplier` `DROP COLUMN`, `golden_rooms:62-68`).
- **`down` is `drop table` — a clean reverse.** The table is new and nothing depends on it (no FK, no view),
  so the drop is total and reversible; on `codemojex_test`/`codemojex_dev` the reinit is create/drop clean
  (§1). On shipped data `down` **would** drop the accrued revenue rows — that is the dev-reset inverse, not a
  live rollback over data (the same posture cm.5's `down` states, `golden_rooms:86-87`); a live rollback would
  be its own runbook. Note for the Director: `down` IS a destructive op (it drops a table) — but it is the
  **reverse** path, never run on `up`, so the forward gate stays a no-op.
- **No CHECK is the deliberate difference from `players`** (`D-1`/A-7): the bank model **requires** the signed,
  unconstrained `delta` — it is what admits the seed debit. The append-only discipline (`updated_at: false`)
  matches `transactions` (A-1): a balance is a sum of immutable rows.
- **Frozen-migration verification (the gate):** `git diff` on the three shipped migrations
  (`20260618000000_create_codemojex.exs`, `20260625145121_add_player_tg_user_id.exs`,
  `20260626120000_golden_rooms.exs`) must be **empty** — cm.6 only adds the new file. State this as a pre-ship
  check; the migration count goes 3 → 4.

## §5 — The five insertion points (keyed to wallet.ex / rooms.ex sites)

Every house-side `revenue_ledger` row rides the **same `Repo.transaction`** as the cm.5 movement it pairs
with (atomic — S-ATOMIC-DOUBLE-ENTRY — inheriting the games-row lock where one exists, A-3). Two new surfaces:

### `house_post/5` — the write helper (the seam, `D-1`)

A new private `Wallet` function inserting one signed `revenue_ledger` row. It **mirrors `txn!`**
(`wallet.ex:380-396`, A-2) structurally but targets the new table and **touches no balance column** (F-3):

```elixir
# A signed platform-revenue row (cm.6 D-1). Mirrors txn! (wallet.ex:380) but targets
# revenue_ledger and touches NO balance column — so it never hits players_non_negative
# (A-7) and needs no player lock. The balance is the SUM of these rows (§7).
defp house_post(account, currency, delta, reason, ref) do
  rid = EchoData.BrandedId.generate!("RVL")           # D-6

  {:ok, _} =
    %RevenueLedger{}
    |> RevenueLedger.changeset(%{
      id: rid,
      account: account,
      currency: to_string(currency),
      delta: delta,
      reason: reason,
      ref: ref
    })
    |> Repo.insert()

  rid
end
```

Plus the reversibility seam (`D-1`, ships regardless — both architect designs converged on it):

```elixir
@house "platform"
def house_account, do: @house                          # the source value the 5 sites + the read bind to
```

> **Why a private `house_post`, NOT `credit/5`** (the cm.5-design `PF-1` carried forward): `credit/5`
> (`wallet.ex:305-318`) updates a balance **column** and re-imposes `players_non_negative` (A-7) — using it
> for the house re-breaks the collision the dedicated table exists to dissolve. `house_post` is the
> column-free analogue: insert a signed row, sum it later. (`Codemojex.Schemas.RevenueLedger` is added to the
> `alias` line `wallet.ex:14`.)

### The five sites (arm-invariant movements, `D-1` substrate)

| # | Site (cm.5) | Anchor | The paired house post (forward-tense) | reason | Same txn? |
|---|---|---|---|---|---|
| 1 | **Deposit SEED** | golden `formation/3` seeds `prize_pool = virtual_deposit` 💎 (`rooms.ex:173-178`); the seed write is `Store.put_game(gid, game)` (`rooms.ex:136`) | a house **debit** `house_post("platform", "keys", -div(virtual_deposit, 10), "deposit_seed", game)` | `"deposit_seed"` | **SEAM-1 — wrap** (`D-4`) |
| 2 | **Deposit-recovery** | `buy_in` `:wrote`, `ordinal ≤ start_threshold` → `entry_fee_split` returns 0 (`economy.ex:51`, `wallet.ex:237`) | a house **credit** `+entry_fee_keys` keys | `"deposit_recovery"` | YES (buy_in's txn) |
| 3 | **First-mover share** | `buy_in` `:wrote`, ordinal in the band → `inc_pool!(game, pool)` runs (`wallet.ex:237`; `pool = entry_fee_split(...)`, the 💎 portion) | a house **credit** `+(entry_fee_keys − div(pool, 10))` keys — the **complement** (A-4) | `"revenue"` | YES |
| 4 | **Full revenue** | `buy_in` `:wrote`, ordinal > band → `entry_fee_split` returns 0, no pool inc | a house **credit** `+entry_fee_keys` keys | `"revenue"` | YES |
| 5 | **Void deposit-reclaim** | `close_void` (`rooms.ex:462-472`) → `:voided`, no money today (A-5) | a house **credit** `+div(virtual_deposit, 10)` keys (seed-cancelling, `D-4`) | `"deposit_reclaim"` | **SEAM-2 — NX-locked branch** (`D-4`) |

### Sites 2/3/4 collapse to ONE insertion point (the NO-INVENT complement)

All three live in `buy_in`'s `:wrote` branch (`wallet.ex:224-238`), keyed on the `ordinal` already computed
(`wallet.ex:217`) and the `pool` already returned by `entry_fee_split` (`wallet.ex:228-235`). The house credit
is a **pure function of the same inputs** — `house_keys = entry_fee_keys − div(pool, 10)` (A-4: exact, the
inverse ×10) — so a single post placed **right after `inc_pool!`** (`wallet.ex:237`) covers all three:

```elixir
# (inside buy_in's :wrote branch, after `if pool > 0, do: inc_pool!(game, pool)`)
house_post(
  house_account(),
  "keys",
  fee - div(pool, 10),                                  # the keys complement (A-4); div(pool,10)=0 when pool=0
  if(ordinal <= (g.start_threshold || 0), do: "deposit_recovery", else: "revenue"),
  game
)
```

- `pool` is `0` for sites 2 and 4 (outside the band, `economy.ex:51`) → `div(pool, 10) = 0` → the post is the
  **full `fee`**; for site 3 (in the band) `pool > 0` → the post is the **complement**. The one expression
  yields all three — **no waterfall re-derivation** (the NO-INVENT pin, `D-3`/cm.6.md Scope-In 3: reuse
  `entry_fee_split`'s output, never re-implement the band boundaries).
- The `reason` is `"deposit_recovery"` for the deposit-recovery band (`ordinal ≤ start_threshold`) else
  `"revenue"` — distinguishing the deposit-recovery rows (which net against the seed, §6) from the
  profit-revenue rows. Both first-mover and full-revenue carry `"revenue"` (cm.6.md Scope-In 3).
- It rides `buy_in`'s **existing** `Repo.transaction` (`wallet.ex:204`) under the games-row lock
  (`wallet.ex:205`) — **no new transaction, no new lock** (S-ATOMIC-DOUBLE-ENTRY, A-3).

### SEAM-1 — the seed write wrap (`D-4`, the lone overlay exception touching a cm.5 site)

The seed write `Store.put_game(gid, game)` (`rooms.ex:136`) is a **bare `Repo.insert`** (A-6,
`store.ex:110-120`), **not** a `Repo.transaction`. To make the seed a real platform outlay atomically (S-SEED
"paired and atomic"), wrap the seed write + the house debit in **one** `Repo.transaction` (forward-tense):

```elixir
# (rooms.ex start_game, replacing the bare `:ok = Store.put_game(gid, game)` at :136)
{:ok, :ok} =
  Repo.transaction(fn ->
    :ok = Store.put_game(gid, game)                     # the games-row seed (A-6 upsert)
    if Map.get(game, :golden, false) and is_integer(game[:virtual_deposit]) do
      Wallet.house_post(Wallet.house_account(), "keys",
        -div(game[:virtual_deposit], 10), "deposit_seed", gid)
    end
    :ok
  end)
```

- **Only the golden seed posts** — a non-golden game has no `virtual_deposit` (the guard) and posts nothing;
  the wrap is a no-op transaction for ordinary rooms (a single `Store.put_game` inside `Repo.transaction`,
  same write, now transactional).
- **`house_post` must become callable from `rooms.ex`.** It is `defp` in `Wallet` today; SEAM-1 (and SEAM-2)
  call it from `rooms.ex`, so cm.6 promotes it to a **public** `Wallet.house_post/5` (or adds a thin public
  `Wallet.post_seed/2` / `Wallet.post_reclaim/2` wrapper if Mars prefers to keep the arity private). **Flag
  for Mars (F-2):** choose `def house_post/5` public vs two named public wrappers; the design's content is the
  same either way (one signed row per site). `Codemojex.Repo` is aliased in `rooms.ex` (confirm at build — it
  is not aliased today; `rooms.ex` uses `Store`/`Cache`/`Cmd`/`Wire`/`Bus`, so SEAM-1 adds the
  `Codemojex.Repo` alias + the `Codemojex.Wallet` call).
- **Build-time spot-read confirmed (A-6):** `Store.put_game → upsert → Repo.insert` is a single statement, so
  it nests inside `Repo.transaction` cleanly (Ecto runs it on the transaction's connection). No `Ecto.Multi`
  (the cm.5 idiom, `L-13`).

### SEAM-2 — the void reclaim (`D-4`, `+seed` ONLY)

`close_void` (`rooms.ex:462-472`) books a single reclaim credit **inside the existing NX-lock branch** — the
`{:ok, "OK"}` arm (`rooms.ex:464-467`) that already guards exactly-once via `SET cm:<game>:closed NX`
(`rooms.ex:463`):

```elixir
# (rooms.ex close_void, the {:ok, "OK"} branch, beside `Store.put_game(... :voided)`)
{:ok, "OK"} ->
  Repo.transaction(fn ->
    :ok = Store.put_game(game, Map.put(r, :status, :voided))
    if Map.get(r, :golden, false) and is_integer(r[:virtual_deposit]) do
      Wallet.house_post(Wallet.house_account(), "keys",
        div(r[:virtual_deposit], 10), "deposit_reclaim", game)
    end
    :ok
  end)
  reset_room(r)
  {:ok, :voided}
```

- **The reclaim books `+seed` ONLY** (`D-4` — `+div(virtual_deposit, 10)` keys, **cancelling** the
  `deposit_seed` debit). The kept fees are **already booked** at each buy-in (sites 2/3/4) under the overlay,
  so `Σ fees + seed` would **double-count** (the cm.5-design `PF-4`, the Director's SEAM-2 lock). After the
  void the house net = `Σ kept fees` (the recovery-band fees the voided room collected, never reaching
  `start_threshold`). The void analysis is the proof the house genuinely goes **negative** mid-void
  (`−seed + Σ recovery`, `Σ recovery < seed`) — the strongest input to `D-1` (a signed balance is required).
- **The NX lock is the exactly-once guard** (A-5) — no per-`(game)` reclaim idempotency index is owed; the
  `SET … NX` already makes the close-and-reclaim fire once. The reclaim joins a `Repo.transaction` so the
  status write + the credit are atomic; `reset_room` stays outside (it is a Valkey/room write, not money).
- **`ref = game` on all five posts** (F-5) — so `revenue_breakdown(game)` (§7) returns the whole story
  (`deposit_seed` / `deposit_recovery` / `revenue` / `deposit_reclaim`) under one `ref`.

## §6 — The balance-invariant proof sketch (at the keys unit) + the conservation-honesty statement

The headline invariant (cm.6.md S-DOUBLE-ENTRY-BALANCE): for any sequence of N buy-ins + the seed + an
optional close, **`Σ(player key debits) == Σ(house key credits) + Σ(pool key-equivalent portions)`** at the
keys unit — no key minted or lost, the ×10 the one accounted minting boundary.

**Per buy-in (the unit of the proof).** Let `f = entry_fee_keys`, `pk = pool_keys` (= `div(pool, 10)`, 0
outside the first-mover band). The three legs:

- **player debit** = `f` keys (the bare `update! keys -= fee`, A-3/`wallet.ex:226` — a `players.keys` column
  move, **not** a signed row).
- **pool conversion** = `pk` keys → `pk × 10` 💎 (the minting boundary; `inc_pool!`, A-3/`wallet.ex:237` — a
  `games.prize_pool` column move, **not** a signed row). In **keys units** the pool absorbs `pk`.
- **house credit** = `f − pk` keys (§5: `house_post(.., f − div(pool, 10), ..)` — a signed `revenue_ledger`
  row).

Then per buy-in: `house_credit + pool_keys = (f − pk) + pk = f = player_debit`. ∎ — an **exact integer
identity, no rounding**: `pk = div(entry_fee_keys × (100 − revenue_pct), 100)` is an integer, `f − pk` is
therefore an integer, and the ×10 applies only at the pool boundary and is reversed exactly by `div(pool, 10)`
(A-4: `pool = pk × 10`, so `div(pool, 10) = pk` with zero residue — cm.5's rounding pin floors **in keys
before** the ×10, `economy.ex:42,47`).

**The seed (S-SEED).** At formation the house **debits** `s = div(virtual_deposit, 10)` keys (§5 site 1) and
the pool gains `s × 10 = virtual_deposit` 💎. In keys: the house holds `−s`, the pool holds `+s` — a closed
keys-conserving move (the platform funds the pool from its own account; nothing minted). The seed-as-outlay
made explicit.

**Over a settled game (S-DEPOSIT-RECOVERY zero-loss).** After the seed (`−s` house) and the first
`start_threshold` recoveries (`+f` house each, pool unchanged), the house net is `−s + start_threshold × f`.
With cm.5's seed sizing (`virtual_deposit ≈ start_threshold × entry_fee_keys × 10`, the seed sized to the
first-band recoveries — confirm the exact relation at the seed site, F-4), `s ≈ start_threshold × f`, so the
house net **≈ 0** after the recovery band — the zero-loss, now an explicit `Σ delta` over `revenue_ledger`,
not a conservation argument. First-mover + full-revenue buy-ins then accrue the platform's profit as positive
`"revenue"` rows.

**The void (S-VOID-RECLAIM).** On `close_void`, no player is refunded (cm.5 `D-7`); the house holds its
accrued recovery rows + a `"deposit_reclaim"` `+s` credit cancelling the seed debit. Net = `Σ kept fees`
(`D-4` — the reclaim is `+seed` only; the fees were booked at buy-in). Keys conserve: every key a player spent
is in a house credit or a pool conversion; the reclaimed seed cancels the seed debit.

**The property test (forward-tense, S-DOUBLE-ENTRY-BALANCE + S-RECONCILE).** A generated sequence of buy-ins
(varied `start_threshold`, `first_movers`, `revenue_pct`, `entry_fee_keys`) + an optional close → assert, for
every game:

```
house_Σdelta_revenue(game) == Σ_buyins(entry_fee_keys) − Σ_buyins(div(pool, 10))   # the recovery+revenue split
pool_💎(game)               == Σ_buyins(div(pool,10)) × 10 + virtual_deposit − distributed_💎
```

— recomputing `f`/`pk` from the game's parameters and the buy-in sequence (the **cm.5-only** quantities) and
asserting the house `Σ delta` equals `Σ f − Σ pk`. Run under the **≥100 determinism loop** (reinit-per-iter,
§9) — the same-ms branded-id mint hazard applies to the new `RVL` mints.

### The MANDATORY conservation-honesty statement (`D-3` — a hard acceptance item)

> **cm.6's ledger balances by CONSERVATION, not by `Σ all-ledger-rows = 0`.** The invariant proven is the
> three-term keys identity — `Σ player_key_debits == Σ house_key_credits + Σ pool_key_portions` — over **three
> observable quantities**: the `players.keys` deltas (a column move, A-3), the `revenue_ledger` house credits
> (signed rows, §2), and the `games.prize_pool` 💎 ÷10 (a column move, A-3). It is **NOT**
> `Σ transactions.delta + Σ revenue_ledger.delta = 0` across the whole system, because under the additive
> overlay (`D-3`) the player debit and the pool credit are **balance columns, not signed rows**. The invariant
> holds and is provable; it balances *computed conservation quantities against the revenue rows*, not *all
> ledger rows against zero*.
>
> **The deferred bank rung (named, not silent):** "reconcile the entry legs into signed rows + a pool account"
> — turn the buy-in debit into a real signed row and promote `prize_pool` to a ledger account, so
> `Σ delta = 0` holds on the rows. That rung re-opens the `delta:0` `buy_in` marker (the exactly-once
> authority, A-3) and the `prize_pool` column every cm.5 finish/void reads — a money-critical regression
> surface `D-3`/S-EXISTING-GREEN forbids touching this rung. It is the BNK bank's proper end-state, carried on
> the roadmap with its own risk budget, **not** abandoned. **Without this statement the rung ships a ledger
> that looks complete and is not** — finance must not read the bare `Σ revenue_ledger.delta` as the whole
> system's balance.

## §7 — The reconciliation read + the explicit==implicit equivalence (S-RECONCILE)

Two new `Wallet` reads (the rung's queryable payoff, cm.6.md Scope-In 5), each a clean aggregate over a table
holding **only** platform movements (`D-1` — no sentinel to exclude from player space):

```elixir
@doc "The platform-revenue balance, per currency (cm.6 D-1/D-2). `account` defaults to the house."
def house_balance(account \\ @house) do
  Repo.all(
    from r in RevenueLedger,
      where: r.account == ^account,
      group_by: r.currency,
      select: {r.currency, sum(r.delta)}
  )
  |> Map.new()
  # => %{"keys" => <Σ keys>}  this rung; %{"keys" => …, "stars" => …} once cm.7 books purchases (D-5)
end

@doc "A game's whole revenue story, grouped by reason (cm.6 Scope-In 5)."
def revenue_breakdown(game) do
  Repo.all(
    from r in RevenueLedger,
      where: r.ref == ^game,
      group_by: r.reason,
      select: {r.reason, sum(r.delta)}
  )
  |> Map.new()
  # => %{"deposit_seed" => -s, "deposit_recovery" => …, "revenue" => …, "deposit_reclaim" => …}
end
```

- **`house_balance/0..1` is the single queryable platform-revenue balance** the rung exists to provide, backed
  by `index(:revenue_ledger, [:account])` (§3). It returns a **per-currency map** (`GROUP BY currency`) so the
  multi-currency shape is native: `"keys"` this rung, `"stars"`/`"cents"` once cm.7 plugs in (`D-5`) — **no
  read change** when the second source lands. For finance, convert the keys figure at read time:
  `Economy.diamonds_for_keys(bal)` 💎 and `Economy.to_cents(...)` / `to_usd(...)` ¢ (the pure, exact
  conversions, `economy.ex:19,22,25` — `D-2`). **No sentinel to filter out of player space** — the
  dedicated-table payoff over a `players` sentinel (`D-1`).
- **`revenue_breakdown/1` is the per-game story queried, not re-derived** (cm.6.md Scope-In 5), backed by
  `index(:revenue_ledger, [:ref])` (§3). A game's seed / recovery / first-mover+full / reclaim, each a
  `reason` group under one `ref`.

### The explicit == implicit equivalence (S-RECONCILE — the rung's central promise)

cm.5 leaves the platform's cut **implicit**: derivable only by conservation as `keys_debited − keys_to_pool`
per buy-in (`Σ_buyins(entry_fee_keys) − Σ_buyins(div(pool, 10))`). cm.6's `revenue_breakdown(game)` (the
**revenue + recovery** rows, **excluding** the seed/reclaim which net to the deposit) must equal that **same
number**:

```
Σ revenue_breakdown(game)[recovery + revenue rows]            # explicit: the revenue_ledger rows
  == Σ_buyins[ entry_fee_keys − div(pool_💎_contributed, 10) ]   # implicit: the cm.5 conservation figure
```

Provable **by construction**: §5's house credit IS exactly `entry_fee_keys − div(pool, 10)` per buy-in, so the
explicit row carries, by definition, the implicit conservation residue. The property test (cm.6.md Acceptance
"Equivalence to cm.5") computes the cm.5-only conservation figure from the **unmodified** cm.5 quantities
(`fee`, `entry_fee_split`'s pool output) over a buy-in sequence, and asserts it equals the cm.6
`revenue_breakdown` aggregate. **The same number, now a row** — cm.6 makes the implicit explicit, never a
different figure.

- **Seed/reclaim in the equivalence.** The seed debit (`−s`) and the void reclaim (`+s`) are the **deposit**
  legs, not the per-buy-in revenue; the equivalence above is stated over the **revenue/recovery** rows so it
  matches cm.5's per-buy-in conservation. The full `house_balance()` (including seed/reclaim) is the
  platform's **net** position — finance reads both: the per-game revenue (matches cm.5) and the net
  (revenue − seed-not-yet-recovered), the figure the BNK withdrawal eventually settles.
- **The discontinuity note (cm.6.md Scope-Out: forward-only).** `revenue_ledger` starts at cm.6 — **no
  retroactive backfill** of pre-cm.6 implicit revenue. `house_balance()` is the explicit revenue **from cm.6
  onward**; finance is told the start date so the explicit ledger is not mistaken for all-time revenue. (A
  later "revenue since date" read indexes `inserted_at` if it becomes hot, §3.)

## §8 — The keys-unit balance-invariant + the multi-currency provisioning

### Why keys is the exact unit (`D-2`)

The Golden-Room conservation is proven **in keys** because the split is computed and floored in keys **before**
the ×10 keys→💎 mint (`Economy.entry_fee_split`, `economy.ex:42,47`):

```
pool_keys = div(entry_fee_keys × (100 − revenue_pct), 100)     # integer, in KEYS
pool_💎    = pool_keys × @diamonds_per_key                       # the ×10 mint, AFTER the floor
house_keys = entry_fee_keys − pool_keys                         # the exact integer complement
```

So `house_keys + pool_keys == entry_fee_keys` holds with **zero residue** — the unit the invariant is *defined
in* (cm.6.md §4) is the unit it is *exact in*. Booking the house side in keys means cm.6 **inherits cm.5's
rounding pin for free**: `div(pool, 10)` recovers `pool_keys` exactly (A-4), so the §6 per-buy-in identity is a
closed integer subtraction. Any other ledger unit (💎, cents) would re-introduce a conversion on the revenue
side — and cents is not even integer-exact (×1.2). The 💎/¢ figure finance wants is a **read-time** view
(§7), not a write-path denomination.

### The multi-currency provisioning (`D-2`/`D-5` — the cm.7 seam)

The `currency` field is the multi-currency carrier (§2). This rung writes **only** `"keys"` rows (the Golden
conservation unit); the field is the seam cm.7 widens with **zero ledger re-design**:

| Source (`account`/`reason`) | `currency` | When | Ledger change |
|---|---|---|---|
| Golden-Room cuts (seed/recovery/revenue/reclaim) | `"keys"` | **cm.6 (this rung)** | the §5 sites |
| KeyShop purchases (gross Telegram Stars) | `"stars"` | cm.7 (`D-5`) | a new `house_post("platform", "stars", +gross, "purchase", charge_id)` — **same table, same helper**, a new `reason`/`currency`, **no DDL** (A-1: free-text reason, the `currency` field already present) |
| (optional) cents-denominated settlement | `"cents"` | a later BNK slice | same — a `currency` value, `house_balance` groups it |

- **`house_balance/0..1` already returns a per-currency map** (§7, `GROUP BY currency`) — so when cm.7 books
  `"stars"` rows the read returns `%{"keys" => …, "stars" => …}` with **no read change**. The multi-currency
  intent is satisfied by the **field + the grouped read**, not by a per-source table — exactly the bounded
  forward-provision `D-1`/`D-5` ruled (one `currency` column the bank populates, not a speculative schema).
- **keys is NOT the whole-ledger unit** (`D-2`): it is the **Golden conservation** unit. A cross-currency
  balance (keys + stars + cents in one number) is a **read-time** roll-up via the `economy.ex` converters
  applied per currency — never a stored normalized row (that would re-introduce the per-write conversion `D-2`
  ruled against). cm.6 does not build the cross-currency roll-up (no purchase rows exist yet); it is named for
  cm.7+.
- **Why this matters for `D-5`'s "no ledger re-design":** because the table is `account`/`currency`-dimensioned
  from the start and `house_post`/`house_balance` are currency-agnostic, cm.7's KeyShop is a pure **producer**
  (book a `"stars"` row) — it adds no column, no index intent beyond the shipped `(account)`/`(ref)`, no new
  read. The ledger rung (cm.6) and the shop rung (cm.7) compose at the `house_post` seam.

## §9 — cm.5-stays-green strategy + the ≥100 determinism + boundary posture

**cm.5 stays green — by topology, not by luck (the `D-1`×`D-3` composition).**

- **`D-1` (the dedicated table)** means the house side **never touches `players`** — no `players_non_negative`
  interaction (A-7), no balance-column read any cm.5 path depends on. A sentinel `PLR` (the rejected arm)
  would put a house row into `players` and risk cm.5 `players` aggregates; the dedicated table eliminates that
  surface **structurally**.
- **`D-3` (the overlay)** means the `delta:0` `buy_in` marker (the exactly-once authority, A-3), the bare
  `players.keys -= fee` debit (A-3/`wallet.ex:226`), and the `inc_pool!` games-column `+` (A-3/`wallet.ex:371`)
  all stay **byte-for-byte**. The cm.5 stories (S-FIRSTMOVER, S-SPLIT, S-VIRTUALDEPOSIT) read the same
  `prize_pool` and the same `players.keys` — cm.6 adds rows in a **new table**, moving no cm.5 figure
  (S-EXISTING-GREEN). `Store.paid_count`/`members` (A-3-adjacent, `store.ex:23-38`) count rows WHERE
  `reason='buy_in'` — untouched (cm.6 writes no `transactions` rows).
- **The lone cm.5-path edits to surface (SEAM-1 + SEAM-2):** site 1 wraps `Store.put_game` in a
  `Repo.transaction` (§5 SEAM-1) and site 5 wraps `close_void`'s status write + the reclaim (§5 SEAM-2). Both
  are **additive** (same writes, now transactional, plus a new house row) — the Director sees them explicitly
  as the two exceptions to "the overlay touches no cm.5 site." Neither changes a cm.5 amount.

**The ≥100 determinism loop (HIGH-risk — money + a NEW id mint per buy-in).** cm.6 mints a **second** branded
id per buy-in — `EchoData.BrandedId.generate!("RVL")` in `house_post` (§5) **alongside** the existing
`generate!("TXN")` in `insert_buy_in` (A-3/`wallet.ex:348`). Two same-millisecond mints on the hot buy-in path
**doubles the same-ms branded-id contention surface** (the BCS id hazard: a same-ms mint within a run can
collide if the snowflake seq exhausts). Ratify with the repeated full-suite loop, reinit-per-iter:

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done
```

A multi-seed sweep alone is **insufficient** (re-seeding does not reproduce same-ms mint contention) — the
loop is **mandatory** because cm.6 adds an id mint on the hot path (the cm.5-design `PF-6` carried forward,
now doubled per buy-in). The seed site (SEAM-1) and the void site (SEAM-2) each add one further `RVL` mint, but
those are off the per-buy-in hot path (once per game).

**Boundary posture.** The boundary is **⊆ `echo/apps/codemojex/**` + the rung docs**:

- `lib/codemojex/schemas/revenue_ledger.ex` (NEW — §2)
- `priv/repo/migrations/20260627NNNNNN_create_revenue_ledger.exs` (NEW — §4)
- `lib/codemojex/wallet.ex` (the `house_post` helper + `house_account/0` + the sites-2/3/4 post + `RevenueLedger` alias + the two reconciliation reads — §5/§7)
- `lib/codemojex/rooms.ex` (SEAM-1 the seed-txn wrap + SEAM-2 the void reclaim + the `Codemojex.Repo`/`Codemojex.Wallet` calls — §5)
- the rung's spec/story files (`docs/codemojex/specs/cm.6.{md,stories.md,llms.md}` — Venus-Triad)

No sibling umbrella app (the codemojex boundary law); **`mix.lock` untouched** (the new schema uses the
existing Ecto/`exqlite` stack — no new dep). Surface the DB target (`codemojex_test`) before the migration
runs (§1).

**The gate ladder (codemojex, from the app dir).** Re-probe `asdf current` / `.tool-versions` from
`echo/apps/codemojex` (do not hardcode the toolchain); `valkey-cli -p 6390 ping` → `PONG`; Postgres up +
`codemojex_test` reinit (§1); `TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include
valkey` (incl. the new revenue-ledger stories **and** the cm.5 suite green untouched); the migration up/down +
fresh reinit; the **≥100 determinism loop**; the frozen-migration `git diff` empty (the three shipped
migrations, §4).

## §10 — Build-precision flags + coordination note (the contracts Mars wires both sides of)

**Build-precision flags (Mars — the load-bearing details).**

- **F-1 — The house credit is the COMPLEMENT, computed from `entry_fee_split`'s output, never re-derived.**
  At sites 2/3/4 (§5) `house_keys = entry_fee_keys − div(pool, 10)`, where `pool` is `entry_fee_split`'s return
  (`wallet.ex:228-235`). **Do NOT re-implement the waterfall** (the band boundaries) in cm.6 — reuse the
  `pool` already computed. The inverse `div(pool, 10)` is exact because `pool = pool_keys × 10`
  (`economy.ex:48`, A-4). `div(pool, 10) = 0` when `pool = 0` (sites 2/4), so the one expression yields the
  full fee outside the band and the complement inside it.
- **F-2 — `house_post`'s visibility for the cross-module calls.** SEAM-1 (`rooms.ex` `start_game`) and SEAM-2
  (`rooms.ex` `close_void`) call `house_post` from `rooms.ex`; it is `defp` in `Wallet` today. Promote it to a
  **public** `Wallet.house_post/5` **or** add two named public wrappers (`Wallet.post_seed/2`,
  `Wallet.post_reclaim/2`) that call the private `house_post`. Mars chooses; the design content (one signed row
  per site) is identical. `house_account/0` is public regardless (the reversibility seam, §5).
- **F-3 — `house_post` touches NO balance column.** It inserts a `revenue_ledger` row only (the balance is the
  sum of rows, §7) — so it **never** hits `players_non_negative` (A-7) and needs **no player lock**. It mirrors
  `txn!` (`wallet.ex:380`) structurally but targets the new table. **Do NOT route the house through `credit/5`**
  (`wallet.ex:305-318`) — that updates a balance column and re-imposes the CHECK (the `PF-1` trap).
- **F-4 — The seed magnitude is `div(virtual_deposit, 10)` keys.** The pool is seeded in 💎
  (`virtual_deposit`), the house debit is in keys — convert with `div(virtual_deposit, 10)` (the inverse ×10).
  **Confirm `virtual_deposit` is a multiple of 10** (cm.5's seed sizing) so the keys conversion is exact; if
  not, flag the sub-diamond residue to the Director (a cm.5 fact, not a cm.6 choice). Also confirm the seed
  sizing relation `virtual_deposit ≈ start_threshold × entry_fee_keys × 10` at the seed site before pinning the
  §6 "house net ≈ 0 after recovery" figure (a cm.5 config fact, not quoted in the as-built).
- **F-5 — `ref = game` on all five posts** (the per-game reconciliation key, §7). The seed/reclaim are also
  `ref = game` so `revenue_breakdown(game)` returns the whole story.
- **F-6 — Every house post rides the cm.5 movement's `Repo.transaction`** (S-ATOMIC-DOUBLE-ENTRY): sites 2/3/4
  inside `buy_in`'s txn (`wallet.ex:204`, no new txn/lock — A-3); site 1 inside the **new** SEAM-1 wrap
  (§5); site 5 inside the **new** SEAM-2 wrap under the existing NX lock (§5). Never open a free-standing
  transaction that breaks atomicity or the games-row-lock inheritance.
- **F-7 — The `RVL` mint is fixed-shape** (`D-6`, A-2): `EchoData.BrandedId.generate!("RVL")`, mirroring the
  `TXN` mint (`wallet.ex:348,381`). Confirm `"RVL"` parses at build (any 3-letter uppercase namespace is valid;
  no registry edit — branded ids are coordination-free).

**The contracts Mars wires both sides of (the Venus-Triad coordination note).** This relational design and
Venus-Triad's triad (`cm.6.{md,stories.md,llms.md}`) are authored in parallel from the same rulings
(`D-1`..`D-6`); they meet at these contracts (Mars wires both sides identically):

1. **The `revenue_ledger` column set + the `RVL` brand** (§2/`D-1`/`D-6`) — `{id (RVL), account, currency,
   delta (bigint signed, NO CHECK), reason, ref (nullable), inserted_at}`. The triad's schema references must
   name these columns; the changeset requires `[:id, :account, :currency, :delta, :reason]`.
2. **The `house_post`/`house_account` seam** (§5) — the five sites + the two reads bind to it; the triad's
   stories assert on `house_balance`/`revenue_breakdown`, not on raw `revenue_ledger` rows.
3. **The five movements + the keys amounts** (§5) — `deposit_seed −div(virtual_deposit,10)` · recovery
   `+entry_fee_keys` · first-mover `+(entry_fee_keys − div(pool,10))` · full `+entry_fee_keys` · reclaim
   `+div(virtual_deposit,10)`. Both sides read the same `entry_fee_split` output; neither re-derives the
   waterfall.
4. **SEAM-1 (the seed wrap) + SEAM-2 (the void reclaim, `+seed` only)** (§5/`D-4`) — the two cm.5-path edits;
   the triad's S-SEED/S-VOID-RECLAIM stories assert atomicity (S-SEED) and `+seed`-only (S-VOID-RECLAIM). The
   reclaim row keyed `ref = game` so `revenue_breakdown(game)` returns the whole story under one `ref`.
5. **The conservation-honesty statement** (§6/`D-3`) — the triad must carry it verbatim (balances by
   conservation, not Σ-rows=0; the entry-leg reconcile named as the deferred bank rung). **Without it the
   rung ships a ledger that looks complete and is not.**
6. **The multi-currency provisioning** (§8/`D-2`/`D-5`) — `currency` carries `"keys"` now, `"stars"`/`"cents"`
   at cm.7; `house_balance` returns a per-currency map. cm.6 builds **no** purchase row (that is cm.7).

**Constraints this design could NOT ground (surfaced, not invented):**

- **The exact `virtual_deposit` value / its relation to `start_threshold × entry_fee_keys`** — §6's "house net
  ≈ 0 after the recovery band" assumes the seed is sized to the first-band recoveries (cm.5's design intent).
  The exact sizing is a cm.5 config fact (`rooms.ex`/the room create); Mars confirms it at the seed site before
  pinning the zero-loss figure (F-4).
- **`virtual_deposit`'s divisibility by 10** — the keys conversion `div(virtual_deposit, 10)` is exact only if
  `virtual_deposit` is a multiple of 10; the as-built does not assert it (F-4). A cm.5 fact, flagged.
- **The `Codemojex.Repo` alias in `rooms.ex`** — `rooms.ex` does not alias `Repo` today (it uses
  `Store`/`Cache`/`Cmd`/`Wire`/`Bus`); SEAM-1/SEAM-2 add `alias Codemojex.{Repo, Wallet}`. A trivial build
  detail, named so the boundary list (§9) is complete.

## References (grounding)

- **The rulings (the contract):** cm-6 ledger `{cm-6-decisions}` `D-1`..`D-6`
  (`docs/codemojex/specs/progress/cm-6.progress.md`) — the dedicated `revenue_ledger` table, keys-unit +
  multi-currency, the additive overlay + the conservation-honesty statement, SEAM-1 wrap / SEAM-2 `+seed`,
  the cm.6/cm.7 split, the `RVL` brand.
- **The design inputs:** `docs/codemojex/specs/cm.6.design.consolidation.md` (the Director synthesis — §6 the
  SEAM resolutions, §7 the arm-invariant movement table); `docs/codemojex/specs/cm.6.design.b.md` (the
  bank-lens design — §4 schema sketch, §5 the five sites, §8 migration shape); `docs/codemojex/specs/cm.6.md`
  (the rung brief — the S-* stories, Scope-In/Out, Acceptance).
- **The cm.5 template:** `docs/codemojex/specs/cm.5.postgres.design.md` (the relational-design structure, the
  byte-frozen-migration discipline §8, the reinit plan §1).
- **As-built schema:** `lib/codemojex/schemas/transaction.ex` (`:6-15` the row shape to mirror; `:17-27` the
  changeset); `lib/codemojex/schemas/player.ex` (`:43-47` `guard/1` — the non-negative CHECK the ledger does
  NOT inherit); `lib/codemojex/schemas/game.ex` (`:40-45` the snapshotted tournament levers).
- **As-built Postgres I/O:** `lib/codemojex/wallet.ex` (`txn!:380-396` the primitive to mirror;
  `buy_in:203-242` + the `:wrote` branch `:224-238`; `inc_pool!:371-374`; `credit:305-318`/`debit:285-303`
  the column-touching helpers to AVOID for the house; `lock_game:326`); `lib/codemojex/economy.ex`
  (`entry_fee_split:45-52`; `diamonds_for_keys:19`/`to_cents:22`/`to_usd:25` the read-time converters;
  `@diamonds_per_key:10`/`@cents_per_diamond:11`); `lib/codemojex/rooms.ex` (`start_game:87-149` +
  `formation:173-178` the seed; `close_void:462-472` the void; `void_if_stale:447-457` the sweep caller);
  `lib/codemojex/store.ex` (`put_game:15` → `upsert:110-120` the bare `Repo.insert` — SEAM-1's wrap target;
  `paid_count:23-29`/`members:31-38` the buy_in-count reads).
- **The id mint:** `echo/apps/echo_data/lib/echo_data/branded_id.ex:93` (`generate!(ns)` — the `RVL` mint
  shape, `D-6`).
- **The byte-frozen migrations:** `priv/repo/migrations/20260618000000_create_codemojex.exs`,
  `…/20260625145121_add_player_tg_user_id.exs`, `…/20260626120000_golden_rooms.exs` (the idiom + the
  3 → 4 freeze gate, §4).
- **Config:** `echo/config/test.exs:19` (`codemojex_test`), `echo/config/dev.exs:14` (`codemojex_dev`),
  `echo/config/runtime.exs` (`prod`, the Operator's deploy).
