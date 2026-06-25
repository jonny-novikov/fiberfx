# cm.4 — the relational redesign · `players.tg_user_id` + resolve-or-create

> The **Venus-Postgres** half of the cm.4 dual-architect fan-out (§12 of the codemojex program). This is
> the authoritative **relational** spec: the column, the unique index, the second migration, the
> resolve-or-create transactional path, and the reinitialization. It is **disjoint** from the Venus triad
> (`cm.4.{md,stories.md,llms.md}`) — the verifier / `:auth` plug / controller cutover / socket auth surface
> is **Venus's lens**; this doc references it as "see `cm.4.md` (Venus)" and never authors it.
>
> NO-INVENT: every claim below is grounded in the as-built tree, probed on disk (the trace `T-2` in
> `specs/progress/cm-4.progress.md`). Citations are **method/file**, not line (lines churn each rung).
> Forward-tense ("cm.4 adds…") for everything unshipped.

## 0. The rung's relational job, in one paragraph

cm.4 binds a verified Telegram **user** to a player so the web surface stops trusting a client-supplied
player id. The relational change that makes "acting as another player" unrepresentable is a single new
column — `players.tg_user_id` — under a **unique** index, plus a **resolve-or-create** path that returns
exactly one `PLR` per Telegram user, **idempotent** under concurrency. Everything else (the HMAC verifier,
the `:auth` pipeline, the `require_player` cutover, the socket auth) sits *above* this floor and is Venus's
surface. This doc fixes the floor: the column, the constraint, the migration, the transactional resolve,
and the reinit.

## 1. The column — `players.tg_user_id`

### 1.1 Type, nullability, default

| Property | Decision | Grounding / why |
|---|---|---|
| **DDL type** | `:bigint` (migration) | A Telegram user id is a 64-bit integer (today ~10 digits, but the API documents it may exceed 32 bits). Matches the sibling `tg_chat_id`, which is `:bigint` in the migration (`20260618000000_create_codemojex.exs`, the `add :tg_chat_id, :bigint`). |
| **Schema-field type** | `field :tg_user_id, :integer` (schema) | The schema field is the Elixir cast target; Ecto maps an `:integer` field onto a `bigint` column. This is the **exact same split** the as-built `tg_chat_id` uses: `field :tg_chat_id, :integer` in `schemas/player.ex` over `add :tg_chat_id, :bigint` in the migration. Following the established idiom — do not introduce a new `:bigint` schema type for one field. |
| **Nullability** | **NULL-able** (no `null: false`) | **Load-bearing — settles F2.** The `create_player/2 → Wallet.create/2` path mints a `PLR` from a *name* with no Telegram user (dev, the 8 story suites, the deferred admin path). A `NOT NULL` column would fail every one of those `Player.create_changeset` inserts → the 41/0 suites go red, and would force a sentinel value for every name-created PLR — which re-introduces the very invalid state ("a PLR bound to a fake TG user") the rung removes. Nullable = "a real Telegram binding when present, absent otherwise." |
| **Default** | none (implicit `NULL`) | A default would mean "every PLR is bound to user 0", a fake binding. No default. |

### 1.2 The unique index — partial, "unique when present"

```elixir
# in the cm.4 migration (see §3)
create unique_index(:players, [:tg_user_id],
         where: "tg_user_id IS NOT NULL",
         name: :players_tg_user_id_index)
```

- **Partial** (`WHERE tg_user_id IS NOT NULL`) for two reasons. (1) It states the intent: uniqueness governs
  only *real* bindings — many name-created PLRs legitimately carry `NULL` and must coexist. (2) It is the
  Postgres idiom for "unique when present"; while standard SQL already treats `NULL`s as distinct under a
  plain `UNIQUE` (so multiple `NULL`s would be permitted regardless), the partial predicate makes the
  contract explicit and the index smaller.
- **Name pinned** `:players_tg_user_id_index` — the Ecto default name for `unique_index(:players,
  [:tg_user_id])` would be `players_tg_user_id_index` already, but it is pinned **explicitly** because the
  partial predicate makes the resolve-or-create `conflict_target` need to reference *this exact index* (see
  §2.3 — a partial index cannot be matched by a bare column-list `conflict_target`).
- **Distinct from the existing `tg_chat_id` index.** The migration already creates `create index(:players,
  [:tg_chat_id])` — a **non-unique** index on a different column. No collision; the new index is unique on
  `tg_user_id`. (The two ids differ: a *chat* id addresses a notification target; a *user* id is the identity
  `initData` proves.)

### 1.3 The schema-module change (`schemas/player.ex`)

The schema gains the field, the cast, and a uniqueness validation. **The `players_non_negative` CHECK is
untouched** — it governs only the five balance columns and does not interact with `tg_user_id`; the new
field is simply added alongside.

```elixir
# schema "players" do … add beside tg_chat_id:
field :tg_user_id, :integer

# create_changeset/2 — add :tg_user_id to the cast list (NOT to validate_required: it stays optional):
|> cast(attrs, [:id, :name, :tg_chat_id, :tg_user_id | @balances])
|> validate_required([:id, :name])
|> unique_constraint(:tg_user_id, name: :players_tg_user_id_index)   # the DB-error → changeset-error bridge
|> guard()
```

- `unique_constraint(:tg_user_id, name: :players_tg_user_id_index)` is the **changeset bridge**: it turns a
  Postgres unique-violation (23505) on that named index into a changeset error rather than a raised
  `Ecto.ConstraintError`. It must name the **same** index as §1.2 (the partial index's pinned name). This is
  the **first** `unique_constraint` in the codebase (probe `T-2`: zero exist today) — its shape is grounded in
  the existing `Repo.insert(on_conflict:, conflict_target:)` idiom in `store.ex` and the standard Ecto
  contract, not invented behaviour.
- `:tg_user_id` is added to the **cast** but **not** to `validate_required` — a name-created PLR (the
  `create_player` path) inserts with no `tg_user_id`, and that must remain valid.
- `balance_changeset/2` is **unchanged** — balance mutations never touch `tg_user_id`.

## 2. The resolve-or-create transactional path

### 2.1 The contract (the new public surface)

Two new functions, each grounded in the existing layering (the `PLR` mint lives in `Wallet`; the facade
delegates):

| Layer | New function | Contract |
|---|---|---|
| **Wallet** (`lib/codemojex/wallet.ex`) | `resolve_by_tg(tg_user_id, opts \\ [])` | **Precondition:** `tg_user_id` is an integer (the verified Telegram user id; the verifier — Venus — supplies it). **Postcondition:** `{:ok, plr}` where `plr` is the **single** `PLR` bound to that `tg_user_id` — the existing row if one exists, else a freshly minted+inserted one. **Invariant:** idempotent — calling it twice (or concurrently) for the same `tg_user_id` yields the **same** `PLR` and leaves **exactly one** row. |
| **Facade** (`Codemojex`, in `game.ex`) | `resolve_player_by_tg(tg_user_id, opts \\ [])` | `defdelegate … to: Wallet, as: :resolve_by_tg` (or a thin `def` in the "players & wallet" block beside `create_player/2`). The web layer (Venus) calls **this**. |

`opts` carries `:name` (a display name for a first-touch create; the verifier can pass the Telegram
`first_name`/`username`, else a default) and optionally `:tg_chat_id` if the connect context also carries the
chat. The mint reuses the **exact** `Wallet.create/2` shape (the `@empty` merge + `Player.create_changeset` +
`Repo.insert`) so a resolve-created `PLR` is byte-identical in structure to a name-created one, plus the
`tg_user_id`.

### 2.2 The happy paths

- **Already bound:** `Repo.get_by(Player, tg_user_id: tg_user_id)` returns the row → `{:ok, row.id}`. One
  SELECT, no write. (This is the *common* case after first touch — every subsequent request for a returning
  player.)
- **First touch:** no row → mint `PLR`, insert with `tg_user_id` set → `{:ok, plr}`.

### 2.3 The race — two concurrent first-touches, exactly one row

The hazard: two requests for the **same** new `tg_user_id` arrive together, both see "no row" on the SELECT,
both mint a (distinct) `PLR`, both attempt INSERT. The unique index guarantees **one** INSERT wins; the
contract must turn the loser into "return the winner's row", not an error and not a second row.

**Two patterns, weighed:**

#### Pattern A — `on_conflict: :nothing` + re-fetch *(RECOMMENDED)*

```elixir
def resolve_by_tg(tg_user_id, opts \\ []) do
  case Repo.get_by(Player, tg_user_id: tg_user_id) do
    %Player{id: id} ->
      {:ok, id}

    nil ->
      uid  = EchoData.BrandedId.generate!("PLR")
      attrs = Map.merge(@empty, %{id: uid, name: name_of(opts), tg_user_id: tg_user_id,
                                  tg_chat_id: Keyword.get(opts, :tg_chat_id)})

      {:ok, %Player{}} =
        %Player{}
        |> Player.create_changeset(attrs)
        |> Repo.insert(
             on_conflict: :nothing,
             conflict_target: {:unsafe_fragment, "(tg_user_id) WHERE tg_user_id IS NOT NULL"}
           )

      # Re-fetch the winner UNCONDITIONALLY by tg_user_id: the row the partial unique
      # index guards is the single source of truth, never the in-memory struct. A real
      # insert wrote uid's row; a conflict (:nothing) wrote nothing and the loser's minted
      # uid is discarded — either way the one indexed row is THE answer for every caller.
      {:ok, Repo.get_by!(Player, tg_user_id: tg_user_id).id}
  end
end
```

> **CORRECTION (as-built, D-6 — the `:loaded`-state heuristic this design first sketched is UNSOUND on
> Ecto 3.x / Postgrex).** An earlier draft guarded the winner with
> `%Player{id: ^uid, __meta__: %{state: :loaded}} -> {:ok, uid}`, on the stated premise that `:loaded`
> distinguishes a real insert from a conflict no-op. The cm.4 concurrency probe disproved it:
> `Repo.insert(on_conflict: :nothing)` returns the struct with `__meta__.state == :loaded` **even when the
> conflict suppressed the write**, so every *loser* matched the winner-branch and was handed back its own
> *discarded* `uid` — 16 racers produced **5 distinct PLRs** while the DB correctly held **one** row. The
> shipped `resolve_by_tg/2` therefore re-fetches **unconditionally** by `tg_user_id` (the index read is the
> authoritative answer); this keeps Pattern A's "the loser writes nothing" while replacing the brittle
> struct-state check. The standing proof is the A9/S4 concurrency test (≥16 racers → 1 distinct PLR, 1 row).
> Re-verified at 32 racers in Apollo's high-risk evaluation (T-16).

- **Why A wins.** The loser's freshly-minted `PLR` is **discarded** (no row written under `:nothing`); the
  re-fetch returns the winner. No orphan row, no second PLR, the unique index is the sole enforcer, and the
  code is idempotent **by construction**. It is the lowest-ceremony path and reuses the repo's existing
  `Repo.insert(on_conflict:, conflict_target:)` idiom (`store.ex`).
- **The sharp edge (called out, not hidden).** A **partial** unique index cannot be matched by a bare
  `conflict_target: :tg_user_id` (Ecto/Postgres requires the conflict arbiter to match the partial index's
  predicate). The `conflict_target` must therefore name the index's columns **and** predicate — the
  `{:unsafe_fragment, "(tg_user_id) WHERE tg_user_id IS NOT NULL"}` form above. **Mars must verify this exact
  fragment matches the migration's `where:` byte-for-byte** (a mismatch → Postgres raises "there is no unique
  or exclusion constraint matching the ON CONFLICT specification"). This is the one place the partial-index
  choice (§1.2) costs a line of care; the acceptance gate is the concurrent-first-touch test (§2.4).
  **Resolution contract (as-built, D-6):** the post-conflict branch does **not** try to tell "real insert"
  from "conflict no-op" from the in-memory struct at all (the `:loaded`-state heuristic is unsound — see the
  CORRECTION above); it re-fetches the winner **unconditionally** by `tg_user_id`, the indexed row being the
  single source of truth for every concurrent caller.

#### Pattern B — unique-violation rescue + re-fetch *(the alternative)*

```elixir
def resolve_by_tg(tg_user_id, opts \\ []) do
  case Repo.get_by(Player, tg_user_id: tg_user_id) do
    %Player{id: id} -> {:ok, id}
    nil ->
      uid = EchoData.BrandedId.generate!("PLR")
      cs  = Player.create_changeset(%Player{}, attrs_with(uid, tg_user_id, opts))
      case Repo.insert(cs) do
        {:ok, %Player{id: ^uid}}            -> {:ok, uid}
        {:error, %Ecto.Changeset{} = bad}   ->
          # the unique_constraint (§1.3) surfaced 23505 as a changeset error → re-fetch the winner
          if unique_violation?(bad, :tg_user_id),
            do: {:ok, Repo.get_by!(Player, tg_user_id: tg_user_id).id},
            else: {:error, bad}
      end
  end
end
```

- **Pro:** does not depend on the `on_conflict` partial-index arbiter matching — the plain `Repo.insert`
  raises/returns the constraint error, and the `unique_constraint` in the changeset (§1.3) turns it into a
  clean `{:error, changeset}` to rescue. The dependency is on the **named** index matching the
  `unique_constraint` name, which is simpler than matching a partial-index predicate.
- **Con:** the loser's INSERT actually **hits** the DB and is rejected (a wasted round-trip + a logged
  constraint error in some setups), then a second SELECT re-fetches. Two extra round-trips on the (rare)
  losing path. Slightly more code (the `unique_violation?` predicate).

**Recommendation: Pattern A** — the loser never writes (the conflict is resolved server-side in one
statement), it reuses the repo's existing `on_conflict` idiom, and idempotency is structural. The only cost
is the partial-index `conflict_target` fragment, which Mars pins against the migration. *(Carrying reason:
the loser discards its mint without a failed write; the unique index is the single enforcer.)* If the Director
prefers the simpler conflict-arbiter story, Pattern B is the fallback and changes only `resolve_by_tg/2`'s
body — the column, index, and migration are identical either way.

> **Not transactional in the `Repo.transaction` sense.** Neither pattern needs an explicit
> `Repo.transaction(fn -> … end)` wrapper: a single `Repo.insert` is atomic, and the unique index does the
> serialization the wallet's `SELECT … FOR UPDATE` does for balances. (Balance mutations stay in their
> existing `Wallet` transactions, untouched.) The "transactional path" here is *the unique-constraint-enforced
> atomic insert + idempotent re-fetch*, not a multi-statement transaction.

### 2.4 The acceptance the relational path owes (→ Venus's `.stories.md`, this lens)

- **Idempotency:** `resolve_player_by_tg(U)` twice → the **same** `PLR`; `SELECT count(*) FROM players WHERE
  tg_user_id = U` is **1**.
- **Concurrency (the race):** N tasks call `resolve_player_by_tg(U)` for the same fresh `U` concurrently →
  all return the **same** `PLR`, exactly **one** row exists. (This is the test that exercises the §2.3
  conflict path — it MUST actually spawn concurrent first-touches, not a sequential pair, to prove the
  arbiter; a sequential pair only proves the get-by branch.) **Sandbox note:** under
  `Ecto.Adapters.SQL.Sandbox` the concurrent tasks must share the test's connection (`allow/3` or
  `{:shared, self()}` mode) — flag for Mars so the concurrency test is real, not serialized by the sandbox.
- **Coexistence:** `create_player(name)` (no `tg_user_id`) and `resolve_player_by_tg(U)` (a real `U`) both
  succeed; multiple name-created PLRs (all `tg_user_id = NULL`) coexist (the partial index permits it).
- **The 8 story suites stay byte-unchanged, 41/0** — they drive `create_player/2`, which is untouched (the
  cast list grows, but `create_player` passes no `tg_user_id`, so its behaviour is identical).
- **The ≥100 mint loop applies** — `resolve_by_tg` mints a `PLR` on first touch (the same-ms branded-id mint
  hazard); the determinism loop covers it (Director/Apollo run it).

## 3. The second migration

`priv/repo/migrations/<ts>_add_player_tg_user_id.exs` — additive onto the single existing create migration,
**reversible**.

```elixir
defmodule Codemojex.Repo.Migrations.AddPlayerTgUserId do
  use Ecto.Migration

  # cm.4: bind a verified Telegram USER to a player (the auth floor). Additive onto the single
  # initial create (20260618000000) — adds one nullable column + a partial unique index. Nullable
  # so name-created PLRs (no Telegram user) coexist; unique-when-present so one PLR per TG user.
  def change do
    alter table(:players) do
      add :tg_user_id, :bigint
    end

    create unique_index(:players, [:tg_user_id],
             where: "tg_user_id IS NOT NULL",
             name: :players_tg_user_id_index)
  end
end
```

- **`change/0`, not `up`/`down`.** Both `alter table … add` and `create unique_index` are **reversible by
  Ecto's auto-rollback** — `mix ecto.rollback` drops the index then the column, no hand-written `down`
  needed. (If the Director prefers an **explicit** `up`/`down` for an at-rest op's blast radius to be legible,
  the `down` is `drop unique_index(:players, name: :players_tg_user_id_index)` then `alter table(:players) do
  remove :tg_user_id end` — name it in the spec body so the reversal is on the page. Either form is correct;
  `change/0` is the smaller, idiomatic one and is the recommendation.)
- **Composes additively.** It only `alter`s an existing table and adds an index — it touches nothing the
  initial create owns, so a fresh DB comes up clean by running the two migrations in order (`20260618…`
  then `<new ts>`). The new `<ts>` must sort **after** `20260618000000` (use the real generated timestamp,
  e.g. `20260625…`).
- **Migration up/down gate (acceptance):** `mix ecto.migrate` adds the column + index; `mix ecto.rollback`
  removes both; a re-`migrate` re-adds them — round-trip clean. Run on `codemojex_test` (§4).

## 4. The reinitialization plan

The destructive op's blast radius, made explicit. **Target DBs (probed, `T-2`):**

- **dev:** `codemojex_dev` (`config/dev.exs`).
- **test:** `codemojex_test#{System.get_env("MIX_TEST_PARTITION")}` (`config/test.exs`) — **dynamic /
  partitioned**, NOT a flat `codemojex_test`. With `MIX_TEST_PARTITION` set, the real DB is
  `codemojex_test1`, `codemojex_test2`, … per partition.

**The reinit (test, the rung's gate):**

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
TMPDIR=/tmp MIX_ENV=test mix ecto.drop      # drops the partition DB(s) Ecto itself resolves
TMPDIR=/tmp MIX_ENV=test mix ecto.create
TMPDIR=/tmp MIX_ENV=test mix ecto.migrate    # runs BOTH migrations from zero → clean fresh schema
```

- **Use `MIX_ENV=test mix ecto.*` — never a hardcoded DB literal.** The Mix task resolves the **partition**
  suffix from `MIX_TEST_PARTITION` itself; a hand-typed `dropdb codemojex_test` would miss the partition the
  suite actually runs against (correction #1 from the probe). This is *why* the reinit is expressed as the
  Mix invocation, not raw SQL.
- **dev reinit** (`MIX_ENV=dev mix ecto.drop && ecto.create && ecto.migrate`, DB `codemojex_dev`) only when
  the **Operator rules it** — dev may hold local state worth keeping; the rung's gate needs only the test
  reinit. Surface both; the test one is the gate, the dev one is Operator-gated.
- **Blast radius stated:** these commands **destroy and recreate** the named DB(s). On `codemojex_test*` that
  is the disposable test schema (no durable data). On `codemojex_dev` it is the developer's local game data —
  hence Operator-gated.

## 5. Fork F2 — the binding *(surface, do not decide)*

> The four-part Arm. F2 is two coupled decisions: **the column nullability** and **the resolve-or-create
> contract** (including the race pattern). Recorded as `V-…` in `specs/progress/cm-4.progress.md`.

### Arm — `players.tg_user_id` NULL-able + the partial unique index + resolve-or-create (Pattern A)

**Rationale.** This is the only path that (a) keeps the 41/0 story suites green (the `create_player` path
mints PLRs with no Telegram user — a `NOT NULL` column reds them all), (b) makes "one PLR per TG user"
a **database** guarantee (the unique index, not application discipline), and (c) discards the losing racer's
mint without a failed write (`on_conflict: :nothing`). It is grounded entirely in the as-built tree — the
`tg_chat_id` `:integer`-over-`:bigint` split, the `Wallet.create/2` mint shape, the `store.ex` `on_conflict`
idiom — inventing no new mechanism.

**5W.** **Why:** the rung's invariant is "valid `initData` → the correct `PLR`, idempotent, one row under
concurrency"; the unique-when-present index is what enforces it. **What:** one nullable `bigint` column +
one partial unique index + `resolve_by_tg/2` (Wallet) + `resolve_player_by_tg/2` (facade). **Who consumes
it:** the verifier / `:auth` plug (Venus's surface) calls `resolve_player_by_tg/2` once per verified request
to assign `conn.assigns.player`; the consumer today is **codemojex** (the web layer + socket), **echo_bot**
planned (a future bot-side resolve on the same column). **When:** cm.4, the auth floor — the smallest
relational change that makes acting-as-another unrepresentable; the `SES` session token (an optimization) is
deferred. **Where:** `schemas/player.ex` (field + cast + `unique_constraint`), `wallet.ex` (`resolve_by_tg`),
`game.ex` (the facade delegate), `priv/repo/migrations/<ts>_add_player_tg_user_id.exs`.

**Steelman (the strongest case *for*).** Nullable + partial-unique is the textbook "optional natural key"
shape: the synthetic key (the branded `PLR`) stays the identity and the FK target everywhere; the natural key
(the TG user id) is a *unique secondary* that may be absent. Making it `NOT NULL` would conflate "is a player"
with "was created via Telegram", breaking the dev/test/admin create paths and forcing a fake sentinel — the
exact anti-pattern. Pattern A's `on_conflict: :nothing` is the idiomatic Postgres single-statement race
resolution: the index arbitrates, the loser writes nothing, the re-fetch is the only follow-up — strictly
less work than the rescue path, and it reuses an idiom already in `store.ex`. The partial index documents the
contract ("unique when present") in the schema itself.

**Steward (the long-game cost).** **Freeze/test burden:** one new column (cheap to carry), one new index
(cheap), and `resolve_by_tg/2` — the **first** non-PK `conflict_target` and the **first** `unique_constraint`
in the app, so the codebase grows a new idiom whose *one* sharp edge is the partial-index conflict_target
fragment (it must stay byte-matched to the migration `where:`; a refactor that edits one must edit both — a
small, localizable coupling, guarded by the concurrency test). **Aging:** the column ages well — a future
`SES` rung reads `tg_user_id` to mint a session; a future `USR` account entity (the roadmap's forward
account, distinct from `PLR`) could relate to it without reshaping. **Composition with the frozen surface:**
zero interaction with the `players_non_negative` CHECK or the wallet's balance transactions; the resolve
mint reuses `Wallet.create/2`'s shape, so a resolve-created PLR is structurally identical to a name-created
one. The only durable cost is the partial-index/`conflict_target` coupling — accepted in exchange for
keeping the name-created paths valid (nullable) and the contract self-documenting (partial).

**REC.** Adopt the Arm: **nullable `bigint` `tg_user_id`, partial unique index `players_tg_user_id_index`
(`WHERE tg_user_id IS NOT NULL`), resolve-or-create via Pattern A** (`on_conflict: :nothing` + re-fetch).
*One carrying reason:* it is the only shape that keeps the 41/0 suites green **and** makes one-PLR-per-TG-user
a DB-enforced guarantee, with the losing racer discarding its mint without a failed write.

**The sub-fork the Director may still split (inside the Arm):**
- **Race pattern A vs B** — A (recommended) vs B (rescue; simpler conflict-arbiter story, two extra
  round-trips on the losing path). Body-only change; column/index/migration identical.
- **Migration `change/0` vs explicit `up`/`down`** — `change/0` (recommended, idiomatic, auto-reversible) vs
  explicit `up`/`down` (the reversal legible on the page for an at-rest op). Both correct.

`CHOSEN-AGAINST:` *(to be written after the Director rules — the rejected arm(s): `NOT NULL` + backfill,
and/or Pattern B, and/or explicit up/down — with the one reason each lost.)*

## 6. Coverage / traceability (the relational claims → their gate)

| Relational deliverable | Gate (acceptance) |
|---|---|
| `tg_user_id` nullable `bigint` column | the migration `up` adds it; `create_player` (no `tg_user_id`) still inserts (41/0 green) |
| partial unique index `players_tg_user_id_index` | the migration `up` creates it; two real-binding inserts of the same id → one rejected (the race test) |
| schema cast + `unique_constraint` | `create_changeset` casts `:tg_user_id`; a duplicate surfaces as a changeset error, not a raised `ConstraintError` |
| `Wallet.resolve_by_tg/2` + facade `resolve_player_by_tg/2` | idempotency test (same `PLR`, count = 1) + concurrency test (N tasks, one row) |
| the second migration up/down | `ecto.migrate` adds; `ecto.rollback` removes; re-migrate re-adds — round-trip clean on `codemojex_test*` |
| reinit | `MIX_ENV=test mix ecto.drop/create/migrate` comes up clean from zero (both migrations) |
| ≥100 mint loop | the first-touch mint is covered by the determinism loop (Director/Apollo) |

## 7. Boundary & disjointness (what this lens does NOT author)

- **Authored here:** `schemas/player.ex` (the relational change), `wallet.ex` (`resolve_by_tg`), the facade
  delegate in `game.ex`, the migration, the reinit. (These land in Venus's `cm.4.md` build brief as the
  relational requirements; this doc is their authoritative source.)
- **NOT authored here (Venus's lens — "see `cm.4.md`"):** the HMAC `initData` verifier, the `:auth`
  pipeline/plug, the `require_player → conn.assigns.player` cutover, the `UserSocket.connect/3` auth, the
  dev/test trust-supplied posture, the freshness window. This doc only fixes the contract the verifier
  *calls into* (`resolve_player_by_tg/2`).
- **Out of bounds:** every sibling umbrella app; `mix.lock` (no new dep — `:crypto` is OTP, Ecto is already a
  dep); a frozen ledger's history.

---

*Venus-Postgres, cm.4. Disjoint from `cm.4.{md,stories.md,llms.md}` (Venus). Grounded on the as-built tree,
trace `T-2` / this doc. The F2 Arm is surfaced, not decided — the Director rules with the Operator.*
