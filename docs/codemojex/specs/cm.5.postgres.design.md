# cm.5 · The Golden Room tournament — the relational redesign

> **Status — REVISED to the Operator-locked economy (cm-5 ledger `D-7`).** This is the column-by-column schema
> redesign, the migration (up + down), and the reinitialization plan for the Golden Room tournament engine,
> authored from the **relational lens** in parallel with Venus's code/brief surface, coordinated by
> **constraint** (no sibling read). The economy is now LOCKED (`D-7` — the virtual-deposit revenue model, the
> tiered entry-fee allocation, guesses-fund-the-pool, **NO REFUND**, `room_deadline`, the unconditional
> `gold_multiplier` drop). The three earlier forks (F-1/F-2/F-3) are **RESOLVED** by `D-7` and recorded as
> decisions (§9); the ONE call `D-7` delegated to this author — `room_deadline`'s physical type — is **pinned**
> here (§3, flagged for the Director/Venus). NO-INVENT: every column / index / CHECK / op is grounded at a real
> `schemas/*.ex` · `priv/repo/migrations/*.exs` · `lib/codemojex/*.ex` `file:line`, the ledger `D-7`, or marked
> **(forward)** for the unbuilt cm.5 surface. Mars owns the production edits; this doc is the contract Mars
> builds to and the Operator/Apollo accept against.

Paths below are relative to `echo/apps/codemojex/` unless rooted. The boundary is the codemojex app: four
schema files, one migration, the Postgres I/O modules (`lib/codemojex/store.ex`, `lib/codemojex/wallet.ex`).

---

## §0 — The locked constraints (design around, not about — cm-5 ledger `D-7`, verbatim intent)

1. A Golden Room is **`type:"classic"` + `golden:true`** — a tournament marker, NOT a game type (`games_type`
   CHECK `migration:108` UNCHANGED).
2. **Membership = the entry-fee buy-in.** Paying the configurable **`entry_fee_keys`** (8 keys = 80💎 at
   launch) makes the PLR a member for the room's life; the member set = PLRs with a `buy_in` TXN for the game.
3. A new **`:gathering`** state: accepts buy-ins + guesses, the timer not started (`ends_ms` nil); the
   `start_threshold`-th paid member transitions `:gathering → :open`.
4. **`start_threshold`** — the paid-member gather count, nullable (nil = legacy first-join), default 10 for
   Golden Rooms, snapshotted room→game.
5. **The virtual-deposit revenue model (`D-7`).** The platform seeds the pool with a **`virtual_deposit`**
   (~$10 in 💎); the **first `start_threshold` entry fees flow to the PLATFORM** (recovering the deposit →
   near-zero loss). The **N `first_movers`** (members `start_threshold+1 .. start_threshold+first_movers`)
   **split** their entry fee: `entry_fee × revenue%/100 →` platform, `entry_fee × (100−revenue%)/100 →` pool.
   Members beyond that → **100% platform revenue**. **Every guess** adds its **full fee ×10 → 💎** to the pool.
6. **`prize_pool` is ONE running 💎 holding record** — transferred to no one until FINISH, where it is
   distributed (top-K via `Economy.top_k_split/3` + consolation clips to the rest) as **ONE best-practice
   ledger transaction** (room, game, `prize_pool`, splits).
7. **`Wallet.buy_in`** is the cross-entity op: debit `entry_fee_keys` + (tiered) increment `prize_pool` by the
   pool portion via an atomic SQL `+` (never an app-side RMW), all-or-nothing, **exactly-once via the `buy_in`
   partial unique index**.
8. **NO REFUND (final, `D-7`).** Golden Room entries are non-refundable. `close_void` simply transitions
   `:gathering → :voided` + reclaims the unpaid virtual deposit — **no refund TXNs, no `buy_in_refund` index,
   no per-`(player, ref)` refund idempotency**.
9. **`room_deadline`** — a per-room deadline (drives bot engagement notifications); unfilled-by-deadline →
   void. It **IS the game-end** (the Director's lean: a fixed promotional-event end), so `ends_ms` aligns to
   it. **This author pins the physical type** (§3).
10. Wire the sweep (`close_if_expired` `rooms.ex:298` has ZERO callers, `I-9`) — it fires the timer-close AND
    the never-fills void at `room_deadline`.
11. **`gold_multiplier` removed — UNCONDITIONAL DROP** on rooms+games (`D-7`/`D-16`; the Operator deploys the
    destructive prod migration).
12. **`buy_in ⇒ not free`** — a real-money buy-in room cannot carry `free:true` (changeset rule).
13. **Launch config:** a free warm-up room "Бокс для разминки" (free, no buy-in) + one Golden Room. The gate
    ladder includes the **migration up/down** + a **fresh reinit** of the test DB.

---

## §1 — The reinitialization target (surfaced FIRST, before any reinit)

The codemojex Ecto Repo (`Codemojex.Repo`) is configured in the **umbrella** config tree (`echo/config/`),
NOT in an app-local `config/` (the app has no `config/` directory — verified):

| MIX_ENV | DB name | Config site |
|---|---|---|
| `test` | **`codemojex_test`** + `#{MIX_TEST_PARTITION}` suffix | `echo/config/test.exs:19` (pool `Ecto.Adapters.SQL.Sandbox`, `:20`) |
| `dev` | **`codemojex_dev`** | `echo/config/dev.exs:14` |
| `prod` | `System.get_env("DATABASE_URL")` | `echo/config/runtime.exs` (Operator's deploy; out of this rung's reinit) |

**No `*_snapshot` database exists** in the echo umbrella config — a `grep snapshot` over `echo/config/` + the
app returns only game/emoji-set "snapshot" code, no DB. There is nothing to leave untouched on that front; the
only Postgres DBs are `codemojex_test`(+partition) and `codemojex_dev`.

**The reinit (run from the app dir, per the per-app gate ladder + `TMPDIR=/tmp`):**

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
MIX_ENV=test TMPDIR=/tmp mix ecto.drop      # drops codemojex_test (+ the active MIX_TEST_PARTITION suffix)
MIX_ENV=test TMPDIR=/tmp mix ecto.create
MIX_ENV=test TMPDIR=/tmp mix ecto.migrate   # replays both shipped migrations + the new cm.5 migration
```

Notes: (a) the `Ecto.Adapters.SQL.Sandbox` pool means the suite runs in transactions, so the reinit is a
one-time schema rebuild before the suite, not per-test; (b) under `MIX_TEST_PARTITION=N`,
`ecto.drop`/`create`/`migrate` must run under the SAME partition env so the suffixed DB is the one rebuilt;
(c) the dev DB is reinitialized the same way with `MIX_ENV=dev`. `prod` is the Operator's deploy (the §9 F-3
destructive-DROP note applies on the live `codemojex` DB).

---

## §2 — `games` (table `games`, `schemas/game.ex`, `migration:76-113`)

The pool, the gather props, the economy levers, the settlement policy, and the gathering relaxation all land
here. Physical types track the shipped idiom: a count/fee is `:bigint`/`:integer` in the migration and
`:integer` in the schema (the `tg_user_id` precedent, `player.ex:14`); a 💎 figure is `:bigint`.

| Column | Today | cm.5 target | Why · ground |
|---|---|---|---|
| `status` | `games_status` CHECK = 7 words (`migration:110-113`) | **CHECK gains `'gathering'`** → 8 words; `'voided'` already present | the `:gathering` state is a writable status (`D-4`/`D-7`). PG has no ALTER CONSTRAINT — drop + recreate (§8). |
| `ends_ms` | `:bigint null:false` (`migration:93`), in `validate_required` (`game.ex:67`) | **`null:true`** + **drop `:ends_ms` from `validate_required`** → `[:id, :secret, :started_ms]` | a gathering game holds `ends_ms` nil until gather completes; at `:gathering → :open`, `ends_ms = DateTime.to_unix(room_deadline, :millisecond)` (§3 pin, `I-10`). |
| `started_ms` | `:bigint null:false` (`migration:92`), required | **UNCHANGED — stays `null:false` + required** | a gathering game is stamped at formation (`started_ms = now`, mirroring `start_game` `rooms.ex:94`); `ends_ms` nil until open. |
| `start_threshold` | absent | **ADD `:integer`, nullable** — snapshotted from the room | the paid-member gather count; nil = legacy first-join; Golden = 10 (`D-4`/`D-5`). |
| `entry_fee_keys` | absent | **ADD `:integer`, nullable** — snapshotted | the configurable buy-in (keys); nil = no buy-in; Golden = 8 (`D-7`). |
| `virtual_deposit` | absent | **ADD `:bigint`, nullable** — snapshotted (💎) | the platform-seeded starting pool (~$10 in 💎); `prize_pool` initializes to it at formation (`D-7`). |
| `first_movers` | absent | **ADD `:integer`, nullable** — snapshotted | the N early-bird count whose entry fee splits to the pool (`D-7`). |
| `entry_fee_revenue_percentage` | absent | **ADD `:integer`, nullable** + a **CHECK `0..100`** (nullable-aware) | the platform's revenue share of a first-mover's entry fee (`D-7`); a money-config column → a DB CHECK backstop (the `players_non_negative` philosophy). |
| `room_deadline` | absent | **ADD `:utc_datetime`, nullable** (§3 pin) | the promotional-event end = the game-end + the void trigger; drives bot notifications (`D-7`). |
| `gold_multiplier` | `:integer null:false default:1` (`migration:100`, `game.ex:35`) | **DROP COLUMN** (+ remove the field + cast + `effective_pool/3`'s `×mult`) | removed drift — **UNCONDITIONAL** (`D-7`/`D-16`). |
| `prize_pool` | `:bigint null:false default:0` (`migration:94`), "the prize pool is diamonds" (`rooms.ex:96`) | **physical type UNCHANGED (`:bigint`, 💎)**; now a **running holding record** seeded at `virtual_deposit`, incremented by two atomic-`+` paths, distributed at finish | F-1 RESOLVED → 💎 (§9); the formation write sets `prize_pool = (golden? virtual_deposit : seed_pool)`. |
| `settlement` | `:string null:false default:"live"`, **NO CHECK** (`migration:83`) | **value `"live_split"` — ZERO DDL** | free-text; only `games_type`/`games_status` carry CHECKs. |
| `economy` | `:string null:false default:"winner_take_all"`, **NO CHECK** (`migration:84`) | **value `"proportional"` — ZERO DDL** | free-text. Naming hazard `L-11`: `"proportional"` LABELS `top_k_split` (rank-weighted), NOT `Economy.proportional/2` (score-weighted) — the build names the mapping. |
| `top_k`, `payout_split` | shipped (`migration:90-91`, `5` / `[40,25,15,12,8]`) | **UNCHANGED** — snapshotted, tournament-shaped | the live tournament reuses the breadth. |

**Schema-side (`schemas/game.ex`, Mars edits):** add `field`s `:start_threshold :integer`, `:entry_fee_keys
:integer`, `:virtual_deposit :integer` (the `:bigint` col), `:first_movers :integer`,
`:entry_fee_revenue_percentage :integer`, `:room_deadline :utc_datetime`; **remove** `field :gold_multiplier`;
update `cast/2` (`game.ex:41-66`) for the adds + the removal; **relax `validate_required`** (`game.ex:67`) to
`[:id, :secret, :started_ms]`. (A `validate_inclusion`/`validate_number 0..100` on
`entry_fee_revenue_percentage` mirrors the DB CHECK app-side — the dual guard, like `player.ex:43-47`.)

---

## §3 — `rooms` (table `rooms`, `schemas/room.ex`, `migration:54-71`) + the `room_deadline` type pin

The room is the template; the game snapshots it. All economy levers live on both ends.

| Column | Today | cm.5 target | Why · ground |
|---|---|---|---|
| `start_threshold` | absent | **ADD `:integer`, nullable** | the gather count; `create_golden_room/3` defaults it to 10 (`D-5`). |
| `entry_fee_keys` | absent | **ADD `:integer`, nullable** | the configurable buy-in (Golden = 8) (`D-7`). |
| `virtual_deposit` | absent | **ADD `:bigint`, nullable** (💎) | the platform seed (~$10) (`D-7`). |
| `first_movers` | absent | **ADD `:integer`, nullable** | the early-bird count (e.g. 2) (`D-7`). |
| `entry_fee_revenue_percentage` | absent | **ADD `:integer`, nullable** + a **CHECK `0..100`** (nullable-aware) | the platform's first-mover revenue share (`D-7`). |
| `room_deadline` | absent | **ADD `:utc_datetime`, nullable** (pin below) | the promotional-event deadline (`D-7`). |
| `gold_multiplier` | `:integer null:false default:1` (`migration:67`, `room.ex:21`/`:40`) | **DROP COLUMN** (+ remove the field + cast + the `if(golden, do: 3...)` default `rooms.ex:40`) | removed — **UNCONDITIONAL** (`D-7`/`D-16`). |
| `seed_pool` | `:bigint null:false default:0` (`migration:60`) | **UNCHANGED** | the ordinary-room 💎 seed; a Golden Room uses `virtual_deposit` instead, `seed_pool` stays 0. |

**Schema-side (`schemas/room.ex`, Mars edits):** add the six `field`s (as §2); **remove** `field
:gold_multiplier`; update `cast/2` (`room.ex:31-46`). `validate_required` (`room.ex:48`) UNCHANGED.

### The `room_deadline` physical-type pin (`D-7` delegated this call to this author)

**PINNED: `room_deadline` is `:utc_datetime` (nullable), and it IS the game-end (the Director's lean).**

- *Type — `:utc_datetime`, not a `_ms` bigint.* `D-7` names it "DATETIME" and its **primary consumer is bot
  engagement notifications** — a human-facing wall-clock instant a `:utc_datetime` renders natively (Calendar
  formatting), where a raw epoch-ms integer needs a `DateTime.from_unix` first. `:utc_datetime` is already
  native in this schema (`timestamps()` use `:utc_datetime_usec`), so it is not an alien type; second
  precision suffices for a promotional deadline.
- *It IS the game-end (the Director's lean: a fixed promotional-event end).* At `:gathering → :open`,
  `ends_ms = DateTime.to_unix(room_deadline, :millisecond)` — ONE well-contained conversion at ONE transition,
  so the entire downstream game-logic millisecond model (`started_ms`/`ends_ms` integer comparisons, the
  `System.system_time(:millisecond)` clock `rooms.ex:72`) is untouched. The sweep's never-fills void compares
  `DateTime.utc_now()` ≤ `room_deadline` (a clean `DateTime` comparison) while `status = :gathering`.
- *The alternative (a `room_deadline_ms` `:bigint` epoch) is recorded + not taken:* it would make
  `ends_ms = room_deadline_ms` a direct assignment (no conversion) and keep the time model uniform, but it
  loses the datetime/bot ergonomics `D-7` named and forces the bot to format epochs. Flagged for the
  Director/Venus to align — if engine-uniformity is preferred over the bot ergonomics, switch to
  `room_deadline_ms :bigint` and drop the `to_unix` conversion. Coordinate by constraint with Venus's brief.

---

## §4 — `transactions` (table `transactions`, `schemas/transaction.ex`, `migration:31-41`)

The append-only ledger is the **exactly-once authority** for the buy-in (`L-10` — the ledger, not the Valkey
paid-set, is the source of truth across a Valkey flush). `reason`/`ref` are free-text (`transaction.ex:9-13`,
no CHECK) — **`buy_in` needs NO enum migration**. **NO REFUND (`D-7`) removes the refund index + bridge.**

| Index | Today | cm.5 target | Why · ground |
|---|---|---|---|
| `(player, inserted_at)` | shipped (`migration:41`) | **UNCHANGED** — the per-player statement read | `Store`/statement queries. |
| `(player, ref) WHERE reason='buy_in'` | absent | **ADD partial UNIQUE** `:transactions_buy_in_once_index` | the forward **double-charge guard** — buy-in exactly-once IN Postgres (`D-7` "the FORWARD buy_in exactly-once index STAYS"); mirrors `players_tg_user_id_index` (`migration2:18-21`). |
| ~~`(player, ref) WHERE reason='buy_in_refund'`~~ | — | **REMOVED from the plan** | NO REFUND (`D-7`) — no refund TXNs, so no refund index. |
| `(ref, reason)` | absent | **ADD non-unique** `:transactions_ref_reason_index` | serves the close-time member-set read (`WHERE ref=$game AND reason='buy_in'`) for `close_split`'s split + clip-grant loops; a perf-additive. |

**The partial-index predicate is the SOLE source of truth for the `on_conflict` `conflict_target` fragment**
in `Wallet.buy_in` — byte-matched (`"(player, ref) WHERE reason = 'buy_in'"`), the `migration2:11-12` ↔
`wallet.ex:73-76` lockstep. A drift is gate-invisible on a single writer; only a concurrent/crash test catches
it.

**Changeset bridge (`schemas/transaction.ex`, Mars edits):** add ONLY
`unique_constraint(:ref, name: :transactions_buy_in_once_index)` (mirroring `player.ex:33`) so a stray buy_in
index violation surfaces as a changeset error, not a raised `ConstraintError`. (The buy-in INSERT uses Pattern
A `on_conflict: :nothing` directly — §6 — so this is defense-in-depth.) **No `buy_in_refund` bridge** (NO
REFUND).

---

## §5 — `players` (table `players`, `schemas/player.ex`, `migration:11-28`) — UNCHANGED

No column change. The shipped surface is what the economy ops reuse:

- the **non-negative CHECK** `players_non_negative` (`migration:23-26`, `player.ex:43-47`) is the buy-in /
  guess-fee short-balance backstop — an overdraw is refused by the same `FOR UPDATE` + CHECK discipline
  (`wallet.ex:158-176`);
- the key/💎/clip balances (`player.ex:7`) are the entry-fee + guess-fee **debit (keys)**, the prize **credit
  (💎)** (`deposit_prize` `wallet.ex:111`), and the consolation **grant (clips)** (`Wallet.grant/4`
  `wallet.ex:114`, reason a free-text string) targets;
- `convert_to_keys` (`wallet.ex:118`) is the **10:1 💎↔keys rate** — `Economy.diamonds_for_keys/1`
  (`economy.ex:19`, `k×10`) is the keys→💎 arithmetic the pool increments use.

---

## §6 — `Wallet.buy_in` — the tiered two-sided op (forward)

The cross-entity op: `players` (debit `entry_fee_keys`) + `games` (tiered pool increment), both Postgres, in
ONE `Repo.transaction` (the `convert_to_keys` idiom `wallet.ex:118-141`, **NOT `Ecto.Multi`** — `L-13`). The
tier is a function of the member ordinal (`D-7`). The contract (relational; the build pins the exact
arithmetic):

```
Wallet.buy_in(player, game)  →  ONE Repo.transaction:
  1. lock the GAMES row FOR UPDATE (from g in Game, where: g.id==^game, lock: "FOR UPDATE")
     # serializes per-game buy-ins → a CONSISTENT member ordinal + a consistent gather count, AND serializes
     # the :gathering→:open start trigger (subsumes the L-7 cross-store start race). This is the key NEW lock.
  2. lock(player) FOR UPDATE (wallet.ex:195)                 # the player balance
  3. ordinal = (count of buy_in TXNs WHERE ref=game) + 1     # under the game-row lock, so it is exact
  4. insert the buy_in TXN with Pattern A:
       on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(player, ref) WHERE reason = 'buy_in'"}
     → if SUPPRESSED (already a member): return {:ok, :already_member}, MUTATE NOTHING (the double-charge gate)
  5. if WROTE: debit entry_fee_keys (keys); refuse on insufficient (the players_non_negative CHECK backstop);
     then the TIERED pool portion (D-7):
       ordinal ≤ start_threshold                          → entry fee → PLATFORM (deposit recovery); pool += 0
       start_threshold < ordinal ≤ start_threshold+first_movers
                                                          → pool += (entry_fee_keys × (100−revenue%) / 100) × 10  (💎)
       ordinal > start_threshold + first_movers           → entry fee → PLATFORM (100% revenue); pool += 0
     the pool portion (when > 0) via the atomic SQL `+`:
       from(g in Game, where: g.id==^game) |> Repo.update_all(inc: [prize_pool: <pool_portion_diamonds>])
       # never an app-side RMW (the lost-update guard, D-13); the game-row lock already serializes, so the
       # inc: is belt-and-suspenders + the canonical idiom.
  6. all legs commit or neither.
  Cache: buy_in writes Postgres ONLY (no Cache.put_game; nothing trusts the cached pool — the hot path reads
  only %{secret} game.ex:106-107, view + settlement read Store.game). Coherence stays :none (L-8).
```

**Exactly-once is the ledger, not Valkey (`L-10`).** A Valkey `SET cm:<game>:paid NX` is a fast-path HINT only;
the partial unique index puts the exactly-once guard IN the same store as the debit + pool `+`, crash-safe by
construction. **The platform side** (the entry fee that goes to platform on the deposit-recovery / revenue
tiers) is reflected by the player's `buy_in` debit TXN + the pool NOT being incremented; whether a paired
platform-account credit row is written (full double-entry) is a Venus-coordination/build detail (revenue
realizes at game START, `D-7`). `buy_in ⇒ not free` is a changeset rule (constraint 12), not a column.

---

## §6a — The guess→pool path (forward) — the SECOND cross-entity write

`D-7`: **every guess adds its full fee ×10 → 💎 to the pool** (supersedes per-guess-fees-=-revenue). So for a
**golden (paid) game** the guess charge becomes two-sided. The contract:

```
charge_guess(player, golden_game, ref=game):              # extends wallet.ex:98 for a golden game
  ONE Repo.transaction:
    lock(player) FOR UPDATE → debit guess_fee (keys), refuse on insufficient
    pool += guess_fee × 10  (💎) via the atomic SQL `+`:
      from(g in Game, where: g.id==^game) |> Repo.update_all(inc: [prize_pool: guess_fee*10])
    # a LOCKLESS atomic increment — additive, no ordinal, no dedup index (each guess is a distinct charge).
```

A **free** room charges valueless clips and funds no 💎 pool, so the guess→pool leg applies to golden paid
games only. Coordinate with Venus on the SITE (extend `charge_guess`, or a golden-game wrapper) — the fee is
debited at submit (`game.ex:33`, before enqueue), so the pool increment co-locates with the debit there.

---

## §7 — `close_split` (FINISH) + `close_void` (NO-REFUND) (forward)

### `close_split` — ONE ledger transaction (best-practice double-entry, `D-7`)

The pool (💎 = `virtual_deposit` + first-mover portions + guess increments) is distributed at finish as **ONE
`Repo.transaction`** (room, game, `prize_pool`, splits). Mirrors `close_live`'s SHAPE (Store-only settle, the
`{:golden_win}` fan-out — **NOT** `close_sealed`'s double cache-write + `{:revealed}`, `L-9`), but wrapped in
one transaction for ledger atomicity:

```
close_split(game, r):                                       # under SET cm:<game>:closed NX (rooms.ex:181)
  ONE Repo.transaction:
    pool   = r.prize_pool                                   # Postgres (Store.game), the holding 💎 figure
    board  = Board.top(game, top_k)
    members = from t in Transaction, where: t.ref==^game and t.reason=="buy_in", select: t.player   # (ref,reason) index
    Enum.each(Economy.top_k_split(pool, board, payout_split), fn {p, d} -> d>0 && Wallet.deposit_prize(p, d, game) end)  # 💎 credits
    # consolation: every member NOT in the top-K split → Wallet.grant(p, :clips, max_score/10) (wallet.ex:114)
    Store.put_game(game, %{r | status: :settled})           # Store only (no Cache double-write)
    # zero/settle the pool record (distributed); reset the room
  announce_golden (the {:golden_win} broadcast); NO {:revealed}.
```

`deposit_prize`/`grant` each open a `Repo.transaction` (`wallet.ex:179`/`:118`) — **nested inside** the
`close_split` transaction they JOIN the parent (Ecto savepoints), so the whole finish commits atomically (the
double-entry `D-7` requires). The 💎→keys 10:1-on-win mechanic (`convert_to_keys`) is unchanged.

### `close_void` — NO REFUND (`D-7`): status→`:voided` + deposit reclaim

```
close_void(game, r):                                        # under SET cm:<game>:closed NX (rooms.ex:181)
  ONE Repo.transaction:
    Store.put_game(game, %{r | status: :voided})            # the canon abort state, in the CHECK (migration:112)
    reclaim the unpaid virtual deposit: zero games.prize_pool (a single deposit_reclaim ledger record to the
    platform account)                                       # NO per-player refund, NO buy_in_refund TXNs
```

The SET `:closed` NX lock alone is the exactly-once guard — there is **no per-player loop, so no
per-`(player, ref)` idempotency index is owed**. The platform keeps the collected fees + reclaims the unpaid
virtual deposit (Golden Room entries are non-refundable). The platform-account representation (a system PLR or
a revenue-ledger row for the reclaim) is a Venus-coordination/build detail.

---

## §8 — The migration (additive single cm.5 migration; up + down)

**Strategy (decided, recommended):** ONE new migration
(`priv/repo/migrations/20260626NNNNNN_golden_rooms.exs`) ALTERs the existing tables; the two shipped
migrations stay **byte-frozen** (never edit a shipped migration; the cm.4 additive precedent). `up`/`down` are
explicit (not `change/0`) because a CHECK constraint cannot be ALTERed in place — it is dropped + recreated.
(Re-collapsing into one clean initial create rewrites shipped history → rejected for Ecto discipline, recorded
for the Director, not an Operator fork.)

```elixir
defmodule Codemojex.Repo.Migrations.GoldenRooms do
  use Ecto.Migration

  # cm.5 — the Golden Room tournament (locked economy, cm-5 D-7). Additive onto the two
  # shipped migrations (both byte-frozen). NO fork-gated steps remain — F-1/F-2/F-3 are resolved.
  def up do
    # 1. :gathering — admit it to the games_status CHECK (no ALTER CONSTRAINT in PG; drop + recreate).
    drop constraint(:games, :games_status)

    create constraint(:games, :games_status,
             check:
               "status IN ('gathering', 'scheduled', 'open', 'active', 'revealing', 'settling', 'settled', 'voided')"
           )

    # 2. ends_ms holds nil during gathering. Relax null:false (migration:93); started_ms STAYS null:false.
    alter table(:games) do
      modify :ends_ms, :bigint, null: true
    end

    # 3. The gather + economy levers, snapshotted room→game (rooms first, then games).
    alter table(:rooms) do
      add :start_threshold, :integer
      add :entry_fee_keys, :integer
      add :virtual_deposit, :bigint
      add :first_movers, :integer
      add :entry_fee_revenue_percentage, :integer
      add :room_deadline, :utc_datetime          # PINNED type (§3); the promotional-event end = the game-end
    end

    alter table(:games) do
      add :start_threshold, :integer
      add :entry_fee_keys, :integer
      add :virtual_deposit, :bigint
      add :first_movers, :integer
      add :entry_fee_revenue_percentage, :integer
      add :room_deadline, :utc_datetime
    end

    # 4. The revenue-% domain guard (a money config; the players_non_negative philosophy). Nullable-aware.
    create constraint(:rooms, :rooms_revenue_pct_range,
             check:
               "entry_fee_revenue_percentage IS NULL OR (entry_fee_revenue_percentage >= 0 AND entry_fee_revenue_percentage <= 100)"
           )

    create constraint(:games, :games_revenue_pct_range,
             check:
               "entry_fee_revenue_percentage IS NULL OR (entry_fee_revenue_percentage >= 0 AND entry_fee_revenue_percentage <= 100)"
           )

    # 5. gold_multiplier removed — UNCONDITIONAL DROP (D-7/D-16) on rooms + games.
    alter table(:rooms) do
      remove :gold_multiplier
    end

    alter table(:games) do
      remove :gold_multiplier
    end

    # 6. The buy-in exactly-once / double-charge guard (KEEP). The `where:` predicate is the SOLE source of
    #    truth for the Wallet.buy_in on_conflict conflict_target fragment (byte-match). NO refund index (NO REFUND).
    create unique_index(:transactions, [:player, :ref],
             where: "reason = 'buy_in'",
             name: :transactions_buy_in_once_index
           )

    # 7. The close-time member-set read index (close_split's split + clip-grant loops; close_void's reclaim).
    create index(:transactions, [:ref, :reason], name: :transactions_ref_reason_index)
  end

  def down do
    drop index(:transactions, [:ref, :reason], name: :transactions_ref_reason_index)
    drop index(:transactions, [:player, :ref], name: :transactions_buy_in_once_index)

    # gold_multiplier re-add (data-loss note: original 1-or-3 values not restored — derivable golden?->3:1).
    alter table(:games) do
      add :gold_multiplier, :integer, null: false, default: 1
    end

    alter table(:rooms) do
      add :gold_multiplier, :integer, null: false, default: 1
    end

    drop constraint(:games, :games_revenue_pct_range)
    drop constraint(:rooms, :rooms_revenue_pct_range)

    alter table(:games) do
      remove :start_threshold
      remove :entry_fee_keys
      remove :virtual_deposit
      remove :first_movers
      remove :entry_fee_revenue_percentage
      remove :room_deadline
    end

    alter table(:rooms) do
      remove :start_threshold
      remove :entry_fee_keys
      remove :virtual_deposit
      remove :first_movers
      remove :entry_fee_revenue_percentage
      remove :room_deadline
    end

    # NOTE: re-asserting null:false on ends_ms FAILS over any nil-ends_ms gathering row — the down is the
    # dev-reset inverse, not a live rollback over data.
    alter table(:games) do
      modify :ends_ms, :bigint, null: false
    end

    drop constraint(:games, :games_status)

    create constraint(:games, :games_status,
             check:
               "status IN ('scheduled', 'open', 'active', 'revealing', 'settling', 'settled', 'voided')"
           )
  end
end
```

---

## §9 — The forks, RESOLVED by the Operator (`D-7`) — recorded as decisions

| Fork | Resolution (`D-7`) | Schema consequence |
|---|---|---|
| **F-1 — pool denomination** | **DIAMONDS**; convert keys→💎 (×10) at the **increment side** (the first-mover entry-fee portion + every guess fee). | `prize_pool` stays `:bigint` 💎; `Wallet.buy_in` + the guess path do the ×10; `close_split`'s `top_k_split`/`deposit_prize` are unchanged-denominated. |
| **F-2 — gather deadline** | **`room_deadline`** (a per-room deadline that drives bot notifications + IS the game-end), **NOT** `gather_deadline_ms`. | the old `gather_deadline_ms` column is **dropped from the plan**; `room_deadline` `:utc_datetime` added on rooms+games (§3 pin); the void fires at it. |
| **F-3 — gold_multiplier** | **DROP COLUMN, UNCONDITIONAL** (the Operator deploys the destructive prod migration). | migration step 5 is unconditional; the field + `effective_pool/3`'s `×mult` removed. |

The ONE call `D-7` delegated to this author — `room_deadline`'s physical type — is **pinned `:utc_datetime`**
(§3), with the `:bigint` alternative recorded and flagged for the Director/Venus.

---

## §10 — Locked schema decisions (this rung)

The `'gathering'` CHECK add; `ends_ms` relax + `validate_required` relax; `started_ms` stays NOT NULL; the
five economy columns + `room_deadline` (`:utc_datetime`) snapshotted on rooms+games; the revenue-% CHECK
(0..100, nullable-aware) on both; `gold_multiplier` UNCONDITIONAL DROP; the `buy_in` partial unique index
KEPT (double-charge guard) + the `(ref, reason)` read index; **the `buy_in_refund` index + the refund bridge
+ `close_void`'s refund REMOVED** (NO REFUND); `settlement`/`economy` widen by value with ZERO DDL;
`Wallet.buy_in` = ONE `Repo.transaction`, **games-row `FOR UPDATE`** (ordinal + start serialization) + tiered
atomic `update_all(inc:)`, Pattern-A idempotency, NO `Ecto.Multi`; the guess→pool atomic `+`; `close_split` =
ONE `Repo.transaction` (nested credits/grants) for double-entry; `close_void` = status→`:voided` + reclaim,
the SET-NX lock the sole exactly-once guard; `players` UNCHANGED; the additive single cm.5 migration, shipped
migrations byte-frozen.

---

## §11 — Build-precision flags

- **G1 — `buy_in` ordinal under concurrency (NEW, the headline money hazard this model adds).** The tier
  (deposit-recovery / first-mover-split / pure-revenue) and the gather count both depend on the member
  ordinal. The **games-row `FOR UPDATE` lock** (§6) makes the ordinal exact under concurrent buy-ins AND
  serializes the `:gathering → :open` start trigger; prove it under the ≥100 loop on Valkey 6390 + Postgres
  (concurrent buy-ins must not mis-tier or double-start).
- **G2 — atomic pool `+`, never an app-side RMW** on BOTH increment paths (the buy-in first-mover portion §6,
  every guess §6a) — the lost-update guard for concurrent funders.
- **G3 — `close_split` is ONE transaction** (nested `deposit_prize`/`grant` join the parent) — the finish is
  double-entry atomic (`D-7`); a partial-pay crash must not split the pool twice (the SET-NX lock guards
  entry, the single transaction guards the body).
- **The byte-matched `conflict_target` fragment** must equal the `buy_in` index `where:` predicate exactly
  (§4) — the `migration2:11-12` ↔ `wallet.ex:73-76` lockstep.
- **The keys→💎 ×10 rounding** (`D-7`): the first-mover pool portion `(entry_fee_keys × (100−revenue%)/100) ×
  10` and the guess `guess_fee × 10` are integer arithmetic — pin the rounding order (e.g. floor the keys
  portion before ×10) and prove the pool conserves.
- **The positional tie-break** (`L-12`): `top_k_split` pays ties POSITIONALLY at paid-rank boundaries (weight
  40 vs 25 by `Board.top` order) — real-money settlement; the build/Operator confirm positional vs even-split.
- **No-refund retires** the prior refund-idempotency gate (`D-7`) — no per-`(player, ref)` resumable-refund
  proof is owed.

---

## §12 — Coordination with Venus (by constraint, not by reading)

This doc and Venus's brief are authored in parallel from §0 (`D-7`); they meet at these contracts (Mars wires
both sides identically):

- the `games`/`rooms` column set (§2/§3) — `start_threshold` + the five economy levers (`entry_fee_keys`,
  `virtual_deposit`, `first_movers`, `entry_fee_revenue_percentage`, `room_deadline`) snapshotted room→game;
  `gold_multiplier` removed;
- **the `room_deadline` physical type — `:utc_datetime` (this author's pin)** + `ends_ms = to_unix(room_deadline)`
  at open: Venus's brief must match the type + the alignment (or the Director rules the `:bigint` alternative);
- the `transactions` `buy_in` partial-index name + predicate (§4) as the SOLE source of truth for the wallet
  `conflict_target` fragment; **no refund index/bridge** on either side;
- `Wallet.buy_in`'s games-row `FOR UPDATE` + the tiered allocation (§6), the guess→pool atomic `+` (§6a),
  `close_split`'s ONE transaction (§7), and `close_void`'s no-refund reclaim (§7);
- the member ordinal / tier boundaries (`start_threshold`, `first_movers`, `revenue%`) — both sides read the
  same `buy_in`-TXN count and the same tier arithmetic.

---

## References (grounding)

- **Locked economy:** cm-5 ledger `D-7` (`docs/codemojex/specs/progress/cm-5.progress.md`) — the virtual-deposit
  revenue model, the tiered entry-fee allocation, guesses-fund-the-pool, NO REFUND, `room_deadline`, the
  unconditional `gold_multiplier` drop, F-1/F-2/F-3 resolutions.
- **Design surface:** `echo/apps/codemojex/docs/golden-rooms.md` (@`5360d7a6`); `docs/codemojex/specs/economy/economy.md`
  §8; the calibration ledger `…/codemojex-golden-calibration.progress.md` (`D-12`/`D-16`/`L-8`/`L-10`/`L-11`/`L-12`/`L-13`/`L-14`/`I-9`/`I-10`).
- **As-built schema:** `lib/codemojex/schemas/{game,room,transaction,player}.ex`;
  `priv/repo/migrations/20260618000000_create_codemojex.exs`, `…/20260625145121_add_player_tg_user_id.exs`.
- **Postgres I/O:** `lib/codemojex/wallet.ex` (`convert_to_keys:118`, `resolve_by_tg:52-88`, `lock:195`,
  `txn!:201-217`, `deposit_prize:111`, `grant:114`, `charge_guess:98`); `lib/codemojex/economy.ex`
  (`top_k_split:62`, `effective_pool:34-36`, `diamonds_for_keys:19`); `lib/codemojex/rooms.ex`
  (`close_game:170`, `do_close:188`, `close_live:196`, `close_sealed:223`, `start_game:68`, `close_if_expired:298`,
  the `prize_pool=room.seed_pool` formation `rooms.ex:97`).
- **Config:** `echo/config/test.exs:19` (`codemojex_test`), `echo/config/dev.exs:14` (`codemojex_dev`).
