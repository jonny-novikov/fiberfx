# Codemojex · The Game-Engine Data Model (Design)

<show-structure depth="2"/>

> **The design-phase deliverable for the `codemojex-game-rename` rung — REDIRECTED scope.** The
> Operator turned a token `round`→`game` rename into a from-scratch **model redesign** for a
> multi-game-type engine. This document is the architectural design of the new Ecto model and the
> code surfaces it wires into. It is authored solo by Venus-PG (architect), grounded entirely on disk
> this session; it edits no production code. **Mars builds from this after Operator approval of the
> Arms in §10; the Director ratifies; the Operator accepts.**
>
> **Framing discipline (propagate):** in this document and in any prose Mars writes — no gendered
> pronouns for agents; no perceptual or interior-state verbs (sees / wants / notices); no
> first-person narration. State surfaces as contracts.
>
> **Relation to the canon.** `codemojex.architecture.md` + `codemojex.roadmap.md` + `codemojex.specs.md`
> already frame Codemojex as **a generic Mastermind engine on BCS, with each room mode a configuration
> on the same branded entities** (`architecture.md`: *"a `GAM` holds … a mode, and four policies …
> No new entity types separate them"*). This model **realizes that frame in the schema** for the first
> time. Where this model and the forward canon disagree, the disagreement is a **flagged `[RECONCILE]`**
> (chiefly the bonus-tier removal, §10/V-2, and Golden's blind-mode depth, §10/V-3) — a follow-up the
> canon owes, not an oversight here.

---

## 0. The locked Operator decisions (verbatim intent — design AROUND these, not about them)

The Operator directive, decoded into HARD constraints the model honors without re-litigation:

1. **Fresh machine, no prod data.** Reinitialize the schema **from scratch** — no rename migration,
   no data migration. The two existing create-migrations are **collapsed into one clean initial
   schema** reflecting the new model (a fresh machine permits it). Local dev `codemojex_dev` is
   **dropped and recreated** at build time when the model is ready.
2. **Multiple types of games** (extensible), with **Golden** as the new mechanic/type.
3. **Linear scoring only. NO bonus tiers.** The `guesses.tier` + `guesses.percentage` columns and the
   entire first-mover tier-bonus economy are **removed**; the linear `points` score stands as the sole
   score and the sole leaderboard rank.
4. The per-play **entity is `game` / brand `GAM`** (formerly `round` / `RND`).
5. Other brands are **NOT renamed**: `RMM` (room), `USR` (player), `EMS` (emoji set), `GES` (guess),
   `TXN`, `JOB`, `NOT`, `CMD`.

> The `RMM`↔`ROM` / `USR`↔`PLR` drift between the code (`RMM`/`USR`) and the forward canon
> (`ROM`/`PLR`) is a **separate reconcile, explicitly out of scope** for this model (Operator
> directive). This model keeps the **as-built code brands** (`RMM`/`USR`).

---

## 1. The engine, as the canon frames it (the model's shape follows from this)

The Game system is a **Mastermind engine**. The family is defined by two things only — a **code
space** (positions, a symbol set, duplicate rule) and a **feedback function** (what a guess reveals)
— and **everything else is policy** (`architecture.md`). A `GAM` is one play: it holds the secret, the
timer, the state, a **type**, and the policies the type selects. The secret, the guess, and the
distance math are **one code path shared by every type**; the type branches only the edges.

This is why the model is **one `games` table with a type discriminator**, not a table per type:
in BCS the 14-byte brand **is** the entity's type, and the only value that crosses a boundary is that
identity — a per-type table would fork the one `GAM` identity that travels from Postgres to the cache
to the bus to the channel. **No new entity types separate the modes** (`architecture.md`, verbatim).

The **two launch types** grounded on disk (`specs.md`: *"Two modes at launch: classic (live feedback)
and golden (blind)"*):

| Type | Feedback | Settlement | Scoring | Economy | Grounded in |
|---|---|---|---|---|---|
| `classic` | live (per-guess score 0–600) | live (perfect crack or timer) | linear distance | per-guess fee, winner-take-all pool | the whole as-built game |
| `golden` | (as-built: live) | live | linear distance | per-guess fee, **boosted** winner-take-all (`gold_multiplier`) | `golden-rooms.md`, `economy.ex` `effective_pool/3` |

> **Golden's depth in THIS model is the as-built boost-only Golden (§10/V-3).** The forward canon's
> *blind* Golden (feedback `none`, settlement `sealed` top-K, a reduced set, commit-reveal, anonymized)
> has its core mechanics as **explicit open questions** in `architecture.md` — it is **PROPOSED, not
> shipped**, and modeling its schema now would violate NO-INVENT. The model is built **extensible** (the
> type discriminator + a nullable type-specific seam, §3.6) so the blind-mode depth lands **additively
> later** without a rename or a re-found identity.

---

## 2. The new schema at a glance — what changed from the round-based model

Seven tables, each keyed by a branded id, each carrying its own status word as text. The delta from
the as-built six-table model (`codemojex.design.md` §"The data model"):

| Table | Brand | Change from round-based model |
|---|---|---|
| `players` | `USR` | **unchanged** (incl. the `tg_chat_id` add + the non-negative CHECK; see §3.7 on `bonus_diamonds`) |
| `transactions` | `TXN` | **unchanged** (append-only ledger) |
| `emoji_sets` | `EMS` | **unchanged** |
| `rooms` | `RMM` | `round` FK column → **`game`**; `golden` + `gold_multiplier` folded into the initial create; **+ `type`** (the room's default game type) |
| **`games`** | **`GAM`** | **was `rounds`/`RND`** — renamed table + brand; **+ `type`** discriminator + the four **policy** columns; `golden` + `gold_multiplier` folded in; the `secret` stays server-side |
| `guesses` | `GES` | `round` FK column → **`game`**; **`tier` REMOVED**; **`percentage` REMOVED** (linear `points` only) |

The Valkey keyspace for one game changes only by the **removal** of the bonus layer (§5).

---

## 3. The tables (types / null / defaults / CHECKs / indexes / relationships)

All ids are `:string` primary keys (the 14-char branded snowflake; no autogenerate — minted by
`EchoData.BrandedId`). All timestamps `:utc_datetime_usec`. Grounded in the as-built schemas under
`lib/codemojex/schemas/` and the two migrations.

### 3.1 `players` (`USR`) — unchanged

```
id              string   PK
name            string   not null
tg_chat_id      bigint   nullable          -- notifications address (echo_bot)
keys            bigint   not null  default 0
clips           bigint   not null  default 0
diamonds        bigint   not null  default 0
bonus_diamonds  bigint   not null  default 0   -- see §3.7 (a wallet bucket, NOT a game bonus tier)
locked_diamonds bigint   not null  default 0
timestamps
CHECK players_non_negative:
  keys >= 0 AND clips >= 0 AND diamonds >= 0 AND bonus_diamonds >= 0 AND locked_diamonds >= 0
```

Source: `schemas/player.ex`, migration `20260618000000` + the `tg_chat_id` add from `20260625000000`.

### 3.2 `transactions` (`TXN`) — unchanged

```
id        string   PK
player    string   not null
currency  string   not null
delta     bigint   not null
reason    string   not null
ref       string   nullable
inserted_at  (timestamps, no updated_at)
INDEX (player, inserted_at)
```

Source: `schemas/transaction.ex`, migration `20260618000000`. Append-only.

### 3.3 `emoji_sets` (`EMS`) — unchanged

```
id         string   PK
name       string   not null
cols       integer  not null
rows       integer  not null
cell_size  integer  not null
sprite_url string   nullable
codes      {array,string}  not null  default []
timestamps
```

Source: `schemas/emoji_set.ex`, migration `20260618000000`.

### 3.4 `rooms` (`RMM`) — the FK rename + the type default

```
id            string   PK
name          string   not null
emojiset      string   not null
type          string   not null  default "classic"   -- NEW: the room's default game type
duration_ms   bigint   not null
seed_pool     bigint   not null  default 0
guess_fee     integer  not null  default 1
free          boolean  not null  default false
clip_cost     integer  not null  default 1
status        string   not null  default "waiting"
game          string   nullable                       -- WAS `round`: the at-most-one active game
golden        boolean  not null  default false
gold_multiplier integer not null default 1
timestamps
```

Relationship: `rooms.game` → `games.id` (the at-most-one active game; nullable when waiting). The room
is a **template**; a game snapshots it at start (`rooms.ex` `start_game`).

> **`type` vs `golden`.** `type` is the engine discriminator (`classic` | `golden`); `golden` +
> `gold_multiplier` are the **boost economy** the `golden` type carries. They are consistent by
> construction — a `golden`-type room defaults `golden: true`, `gold_multiplier: 3` (the as-built
> default, `rooms.ex:33`). Modeled as both a discriminator and explicit boost columns so the boost is
> queryable and CHECK-able, not buried in a config bag (§10/V-1, Arm A).

Source: `schemas/room.ex`, migrations `20260618000000` + `20260625000000`.

### 3.5 `games` (`GAM`) — the redesigned per-play entity (was `rounds`/`RND`)

```
id            string   PK                              -- GAM (was RND)
room          string   nullable                        -- FK → rooms.id
emojiset      string   nullable                        -- FK → emoji_sets.id (snapshot)
type          string   not null  default "classic"     -- NEW: the engine discriminator
feedback      string   not null  default "score"        -- NEW policy: "score" | "none"
scoring       string   not null  default "linear"       -- NEW policy: "linear" (the only value today)
settlement    string   not null  default "live"         -- NEW policy: "live" | "sealed"
economy       string   not null  default "winner_take_all" -- NEW policy: the payout curve word
secret        {array,string}  not null                  -- server-side; no player-facing query selects it
started_ms    bigint   not null
ends_ms       bigint   not null
prize_pool    bigint   not null  default 0              -- diamonds, seeded from the room
guess_fee     integer  not null  default 1
free          boolean  not null  default false
clip_cost     integer  not null  default 1
status        string   not null  default "open"
golden        boolean  not null  default false
gold_multiplier integer not null default 1
timestamps
INDEX (room)
```

- **CHECK `games_type` (recommended):** `type IN ('classic','golden')` — bounds the launch type set so
  an unknown type cannot be written (the queryability the money-adjacent floor wants; §10/V-1). The
  Operator rules whether to ship the CHECK or leave `type` open for faster iteration.
- The **four policy columns** (`feedback`, `scoring`, `settlement`, `economy`) realize the canon's
  *"four policies"* (`architecture.md`/`roadmap.md`). They are **snapshotted from the room's type at
  game start** and immutable for the game's life — the same snapshot discipline `golden`/`gold_multiplier`
  already follow (`rooms.ex` `start_game`). For the two launch types they are derivable from `type`
  alone, so they are **defaulted** and the type→policy mapping lives in code (a small lookup); storing
  them explicitly keeps a game self-describing for settlement and for replay, and leaves the seam for a
  type whose policies are not a pure function of its name.
- `secret` stays a server-side column, selected by **no** player-facing query (`schemas/round.ex`,
  `view.ex` — the privacy invariant).
- The `GAM` id doubles as the cache version + the idempotency token (immutable for the game's life;
  `tables.ex`, `cache` coherence `:none`).

> **The state machine.** `specs.md` names a richer machine — `scheduled, open, active, revealing,
> settling, settled, voided`. The as-built code uses `open | closed` (`rooms.ex`, `schemas/round.ex`
> default `"open"`). This model keeps the **as-built `open | closed`** status set (NO-INVENT — the
> richer machine is PROPOSED and its transitions are not yet built). The `status` column is a free text
> word, so the richer set lands additively when the blind/sealed flow is built. **Flagged** as a canon
> lag, not modeled here.

Source: `schemas/round.ex`, migrations `20260618000000` + `20260625000000`; the policy/type columns are
the NEW design realizing `architecture.md`/`roadmap.md`.

### 3.6 `guesses` (`GES`) — the FK rename + the bonus-tier REMOVAL

```
id      string   PK
game    string   not null                  -- WAS `round`
player  string   not null
emojis  {array,string}  not null
points  integer  not null                  -- the LINEAR score (sum of 100-20*d, out of 600)
at_ms   bigint   nullable
inserted_at  (timestamps, no updated_at)
INDEX (game, player)
```

**Removed from the as-built `guesses` (the HARD linear-only constraint, D-5 / §10/V-2):**
- `tier` (was `div(total, 20)`, 0..30) — **DROP**.
- `percentage` (was `round(total / 600 * 100)`) — **DROP** (a derived display value; recomputable on
  read if ever surfaced; not stored).

`points` — the raw linear total — **stands** and is the sole stored score. The leaderboard ranks by the
player's **best `points`** (§5).

Source: `schemas/guess.ex`, migration `20260618000000`; the column removals are the NEW design per the
Operator constraint.

### 3.7 A naming hazard to NOT over-remove — `players.bonus_diamonds`

`players.bonus_diamonds` (`schemas/player.ex`, `01-currency-model.md`) is a **wallet bucket** — a
promotional-diamond balance granted on redemption — **not** a game bonus tier. The Operator's "no bonus
tiers" targets the **scoring** bonus economy, not the wallet. **Keep `bonus_diamonds`.** Mars must not
remove it. (The word "bonus" is overloaded; this is the wallet sense.)

---

## 4. The branded-id contract

`games` mints **`GAM`** (was `RND`) — at the key builder (`rooms.ex` `EchoData.BrandedId.generate!`,
`tables.ex` `kind:`). **Unchanged** brands:

| Brand | Entity | Lives in |
|---|---|---|
| `GAM` | game (was `RND`) | Postgres `games`, EchoStore `:cm_games` |
| `RMM` | room | Postgres `rooms` |
| `USR` | player | Postgres `players`, Valkey lanes/board |
| `EMS` | emoji set | Postgres `emoji_sets`, EchoStore `:cm_emojisets` |
| `GES` | guess | Postgres `guesses` |
| `TXN` | wallet transaction | Postgres `transactions` |
| `JOB` | bus work | Valkey queues |
| `NOT` | notification | Valkey notify lane |
| `CMD` | bot command | Valkey commands lane |

The id is the only value that crosses a boundary; it keys the Postgres row, the Valkey entry, the bus
job, and the announce message. The 14-byte shape (`<<_::binary-14>>`) and the `ts(41)|node(10)|seq(12)`
snowflake are **unchanged** — only the `RND` namespace string becomes `GAM`.

> The forward roadmap's larger namespace set (`ROM`/`RMP`/`BNK`/`PLR`/`RSC`/`SES`/`PKG`/`ORD`/`OTX`/
> `WHK`/`SHR`/`AEV`) is the **target** for systems not yet built (commerce, growth, analytics). This
> model keeps the **nine as-built brands**; the rest land with their systems. Out of scope here.

---

## 5. The Valkey competitive state — the bonus layer removed

The as-built keyspace for one game is `cm:{game}:` — `board` (ZSET), `base`/`ptier`/`bonus`/`tierfirst`
(the first-mover hashes), `players` (set), `attempts` (counter), `closed` (the one-shot close lock),
plus the global `cm:total_won` (`board.ex`, `rooms.ex`, `game.ex`).

**The new model removes the bonus layer (D-5):**

| Key | Disposition |
|---|---|
| `cm:{game}:board` (ZSET) | **KEEP** — but scored by the player's **best linear `points`** (was `eff = base + bonus`) |
| `cm:{game}:base` (hash) | **KEEP** — the player's best linear total; feeds the ZSET directly |
| `cm:{game}:ptier` (hash) | **REMOVE** — the previous-tier tracker for first-mover claims |
| `cm:{game}:bonus` (hash) | **REMOVE** — the accumulated first-mover bonus |
| `cm:{game}:tierfirst` (hash) | **REMOVE** — the `HSETNX` tier-claim race |
| `cm:{game}:players` (set) | **KEEP** |
| `cm:{game}:attempts` (counter) | **KEEP** |
| `cm:{game}:closed` (lock) | **KEEP** — the exactly-once close `SET NX` |
| `cm:total_won` | **KEEP** |

`Board.record/4` collapses to: update the player's best `base`, write `base` to the `board` ZSET. The
tier-claim arm (`claim_tier`, the `(prev+1)..tier` loop, `hincrby bonus`), `Board.firsts/2`, and the
`eff = new_base + bonus` line are **removed**. The leaderboard ranks by the raw linear best — which is
exactly "the existing linear score" the Operator preserves.

---

## 6. How the model wires into the code surfaces (cite-grounded; Mars builds these)

The schema change drives a code change at every surface the `GAM` identity and the removed columns
travel. **Each surface is named with its file; Mars cites the line.** This is the build map, not new
behavior beyond the model.

### 6.1 Schemas (`lib/codemojex/schemas/`)
- **Rename** `round.ex` → `game.ex`; `Codemojex.Schemas.Round` → `Codemojex.Schemas.Game`;
  `schema "rounds"` → `schema "games"`; **add** `type`, `feedback`, `scoring`, `settlement`, `economy`
  to the schema + the `cast` list.
- `room.ex`: `field :round` → `field :game` (+ the `cast` list); **add** `type`.
- `guess.ex`: `field :round` → `field :game` (+ `cast`/`validate_required`); **remove** `field :tier`
  and `field :percentage` from the schema + the `cast` list.

### 6.2 Store + cache + tables
- `store.ex`: `alias … {…, Round, …}` → `{…, Game, …}`; `put_round`/`round` → `put_game`/`game`
  (`Repo.get(Game, …)`); `guesses_for/3` `g.round` → `g.game`; the `Codemojex.Cache` `@cache :cm_rounds`
  → `:cm_games`, `fetch_round`/`put_round` → `fetch_game`/`put_game`.
- `tables.ex`: `@rounds :cm_rounds` → `@games :cm_games`; `rounds_table/0` → `games_table/0`;
  `kind: "RND"` → `"GAM"`; `&load_round/1` → `&load_game/1`; `:rounds_cache_ttl_ms` →
  `:games_cache_ttl_ms`; the moduledoc bullet `:cm_rounds (RND)` → `:cm_games (GAM)`.

### 6.3 The game lifecycle (`rooms.ex`)
- `start_round/3` → `start_game/3`; `generate!("RND")` → `generate!("GAM")`; **snapshot the type +
  the four policies** onto the game at start (from the room's `type`, via the type→policy lookup);
  `close_round/1` → `close_game/1`; `close_if_expired/1`; `:no_round` → `:no_game`; the
  `effective_pool`/`winner_take_all` close path is **unchanged** (the Golden boost stays).

### 6.4 The scoring authority (`game.ex` — `Codemojex.ScoreWorker`)
- `Cache.fetch_round` → `Cache.fetch_game`; `Store.put_guess` map: **drop the `percentage:` and
  `tier:` keys** (write only `game`, `player`, `emojis`, `points`, `at_ms`).
- `Board.record(game, player, s.total, s.tier)` → `Board.record(game, player, s.total)` (the `tier`
  arg is gone — Board no longer claims tiers).
- The `scored` `Events.publish` + the PubSub broadcast: **drop the `tier:` and `first:` fields** (keep
  `game`/`player`/`pct`/`eff`; `pct` is recomputed inline from `s.total`, not read from a column — see
  §7). `Rooms.close_round` → `Rooms.close_game`.

### 6.5 The board (`board.ex`)
- `record/4` → `record/3` (drop `tier`); remove `claim_tier/4`, the tier-claim loop, the `ptier`/`bonus`
  hashes, and `eff = new_base + bonus` (the ZSET takes `new_base`); **remove `firsts/2`**.

### 6.6 The facade + views (`game.ex` `Codemojex`, `view.ex`)
- Facade: `round_view` → `game_view`; the play delegations' `round` params → `game`; `close_now` →
  `close_game`; **remove the `firsts/2` delegate**.
- `view.ex`: `round_view/1` → `game_view/1`; `Store.round` → `Store.game`; `my_history/3` `Map.take`
  **drops `:percentage` and `:tier`** (returns `emojis`, `points`, `at_ms`); the `round:` map key →
  `game:`.

### 6.7 The external wire (the cutover surface)
- HTTP routes `/rounds/:id…` → `/games/:id…`; PubSub topic `"round:" <> …` → `"game:" <> …`; channel
  `"round:*"` → `"game:*"`; the `round:` JSON/event keys → `game:`; `:no_round` → `:no_game`. (Sites
  enumerated in the Venus-1 brief §4.4–4.5 — the wire flips with the model.)

### 6.8 Settlement, notifier, scoring, economy, tests, demo
- `game.ex` `Codemojex.Settle`: `close_round` → `close_game`, the `round` bindings → `game`.
- `notifier.ex`: `round_result/3` → `game_result/3`, `golden_win/4`'s `round_id` → `game_id`.
- `scoring.ex`: **remove the `tier/1` function and the `tier:` key** from `score/2`'s return; drop
  `percentage` from the return map if the Operator confirms it is unused (or keep it computed-not-stored
  — see §7). `economy.ex` `effective_pool/3` is **unchanged** (Golden's boost).
- Tests: rename `test/stories/rooms_and_rounds_story_test.exs` → `…rooms_and_games_…`; update every
  story exercising `tier`/`percentage`/`firsts` to the linear-only shape; the entity bindings + the
  `round_view`/`close_*` call sites → game.
- Demo: `priv/round.exs` → `priv/game.exs`.

> The full token-class enumeration (which `round` is the entity vs `Kernel.round/1` vs English) is in
> the Venus-1 brief `codemojex-game-rename.brief.md` §4 — it still applies for the rename half; **this
> model adds the column removals + the type/policy additions on top.**

---

## 7. One contract to RULE in §10 — `Scoring.score/2`'s return + the `pct` on the wire

The as-built `Scoring.score/2` returns `%{total, max, percentage, tier, breakdown}` (`scoring.ex`).
`percentage` and `tier` were stored on `guesses` (now removed) and `percentage` is also published on the
`scored` event (`pct`) and shown in `my_history`. Two clean options for the **return shape** (the
column removal is settled; this is only about the in-memory map + the wire):

- **Keep `percentage` computed-not-stored** — `score/2` still returns `percentage` (the live `pct` for
  the channel + the lobby progress bar), but **nothing writes it to a column**. Remove only `tier` from
  the return. **(Recommended — least churn, preserves the live `pct` the surface shows.)**
- **Drop `percentage` from the return too** — and recompute it at the one display site
  (`Economy.progress_pct/1` already does `best/600*100` for the lobby). Cleaner return, one extra
  recompute on the publish path.

Both keep **zero stored `percentage`/`tier`**. The Operator/Director rules which return shape; the model
(the columns) is unaffected either way. The `tier` function in `scoring.ex` is **removed** in both.

---

## 8. The from-scratch reinitialization strategy (fresh machine — collapse to one initial schema)

The machine is fresh and carries no prod data (Operator constraint #1), so the model ships as **one
clean initial create-migration**, not a rename + the two existing creates.

### 8.1 The migration
- **Collapse** `priv/repo/migrations/20260618000000_create_codemoji.exs` +
  `20260625000000_golden_rooms_and_notifications.exs` into **one** `create`-only migration reflecting
  the new model directly: `create table(:games)` (with `type` + the four policy columns + `golden`/
  `gold_multiplier` + `secret` + the timer/fee props), `rooms.game` (not `round`), `guesses` **without**
  `tier`/`percentage`, `players` **with** `tg_chat_id`, and the indexes (`games(room)`,
  `guesses(game, player)`, `transactions(player, inserted_at)`, `players(tg_chat_id)`).
- The Operator chooses the mechanism (§10/V-4): **(A)** rewrite the two existing migration files into
  one clean initial create (a fresh machine permits editing migration history that has never run on a
  live DB), or **(B)** keep the two files and add a third that drops `tier`/`percentage` + renames the
  FKs (more files, no clean slate). **A is recommended** on a fresh machine — it is the literal
  "reinitialized, from scratch, not migrations" the Operator asked for.

### 8.2 The dev-DB reset (Mars runs at build time, when the model is ready)
The dev DB is `codemojex_dev` (`config/dev.exs:14`); the test DB is
`codemojex_test#{MIX_TEST_PARTITION}` (`config/test.exs:19`). When the new schema + the renamed code
compile clean:

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
TMPDIR=/tmp mix ecto.drop      # drops codemojex_dev (Operator authorized: drop + recreate)
TMPDIR=/tmp mix ecto.create
TMPDIR=/tmp mix ecto.migrate   # the one fresh initial schema
```

The **test DB** is reset by the suite the same way (`mix test` re-creates from the migrations; the
`--include valkey` integration stories need Postgres up + `valkey-cli -p 6390 ping` → `PONG`). No data
migration, no `RND`→`GAM` rebrand — a fresh DB mints `GAM` ids from the renamed code.

> **Operator authorization recorded:** "drop 5432 postgres `codemojex_dev` database and recreate when
> Ecto model is ready." Mars runs the drop **only** when the model + code are ready and the Director
> relays the go. Postgres `5432` is the local dev server (distinct from the bus's Valkey `:6390`).

---

## 9. Agent stories (Given/When/Then — the build is accepted against these)

Each story is a Directive + an Acceptance gate, contract form. The invariants are named (INV-n). The
build is the eventual Mars rung after Operator approval of §10.

- **Story R-1 — the game entity is `games`/`GAM`.**
  *As the engine, the per-play entity is a `game` so its identity matches the canon.*
  *Given* the renamed schema + key builder; *When* a room is joined and a game starts; *Then*
  `EchoData.BrandedId.generate!("GAM")` mints a `GAM…` id, `Codemojex.Schemas.Game` maps
  `schema "games"`, and the compile gate is clean.
  *Invariant INV-1:* every other brand (`RMM`/`USR`/`EMS`/`GES`/`JOB`/`NOT`/`CMD`/`TXN`) is
  byte-unchanged.

- **Story R-2 — the engine carries a type + four policies.**
  *As the engine, a game declares its type and policies so a new mode is configuration, not new code.*
  *Given* the `games.type` + `feedback`/`scoring`/`settlement`/`economy` columns; *When* a `classic`
  room and a `golden` room each start a game; *Then* the `classic` game records `type="classic"`,
  `feedback="score"`, `settlement="live"`, and the `golden` game records `type="golden"` with
  `golden=true`, `gold_multiplier` ≥ 1, snapshotted from the room and immutable for the game's life.
  *Invariant INV-2:* an unknown `type` is rejected (the `games_type` CHECK, if shipped); the type set is
  `{classic, golden}` until a new type is specified + approved.

- **Story R-3 — linear scoring is the sole score; no bonus tiers.**
  *As a player, the leaderboard ranks me by my best linear score so there is no hidden tier bonus.*
  *Given* the removed `guesses.tier`/`percentage` columns + the removed Valkey bonus layer; *When* a
  guess scores total `T` and reaches the board; *Then* `guesses` stores only `points = T` (no `tier`,
  no `percentage`), the `cm:{game}:board` ZSET ranks the player at their best `T` (not `T + bonus`),
  and `cm:{game}:ptier`/`bonus`/`tierfirst` do not exist.
  *Invariant INV-3:* `Scoring.score/2` stays the linear engine (`points(d)=100-20*d`, summed to 600); a
  re-delivered guess re-scores identically (purity, unchanged).
  *Invariant INV-4:* `players.bonus_diamonds` (the wallet bucket) is **kept** — the removal touches only
  the scoring bonus economy, never the wallet.

- **Story R-4 — Golden is the boost type, settled exactly once.**
  *As the platform, a Golden game pays its boosted pool to the top scorer so the promotion draws play.*
  *Given* `games.type="golden"` + `golden`/`gold_multiplier`; *When* a golden game closes on a perfect
  crack or the timer; *Then* `Economy.effective_pool/3` multiplies the seeded pool by `gold_multiplier`,
  the winner-take-all split pays the top scorer (evenly on a tie) inside the one-shot `SET NX` close, and
  a re-run pays identically.
  *Invariant INV-5:* the boost is applied once, at close, over the seeded pool; the close lock
  (`cm:{game}:closed`) makes a perfect-crack close and a timer close mutually exclusive.

- **Story R-5 — the store reinitializes from scratch.**
  *As an operator, a fresh machine comes up on the new schema with no migration archaeology.*
  *Given* the one clean initial create-migration (§8); *When* `mix ecto.drop && mix ecto.create &&
  mix ecto.migrate` runs against `codemojex_dev`; *Then* the DB comes up with `games` (type + policy
  columns), `rooms.game`, `guesses` without `tier`/`percentage`, `players.tg_chat_id`, and the
  `--include valkey` suite is green against it.
  *Invariant INV-6:* no data migration + no `RND`→`GAM` rebrand step exists (a fresh DB mints `GAM` from
  the code); the dev-DB drop runs only when the model is ready.

- **Story R-6 — the wire flips with the model.**
  *As a client, I reach a game at `/games/:id` and on the `game:` topic.*
  *Given* the renamed routes/topic/channel/keys; *When* `GET /games/:id` is called and a client joins
  `game:<id>`; *Then* the view returns (never the secret), a `scored` push arrives carrying
  `game`/`player`/`pct`/`eff` (no `tier`, no `first`), and the `--include valkey` stories exercise the
  renamed wire end to end.
  *Invariant INV-7:* no caller of a renamed symbol is left at the old name (the compile gate proves it);
  the privacy invariant holds (no view selects `secret`, no view returns another player's guesses).

**Coverage:** §3.5 `games` type/policy columns → R-1, R-2; §3.6 `guesses` removals + §5 bonus-layer
removal → R-3; §1/§3.4–3.5 Golden boost + `economy.ex` → R-4; §8 reinitialization → R-5; §6.7 wire →
R-6. Every deliverable maps to a story; completion is provable from the text.

---

## 10. The design Arms — Operator approval required before the build

Surfaced, not decided. Each carries a recommendation. Full four-part records (Rationale / 5W / Steelman
/ Steward) are in the ledger `codemojex-game-rename.progress.md` (V-4, V-5, V-6).

- **Arm V-1 — the multi-type modeling shape. RECOMMEND Arm A:** a `games.type` discriminator + explicit
  typed **policy columns** (+ `golden`/`gold_multiplier`), bounded by a `type` CHECK — the canon's own
  shape, the minimal delta over the as-built snapshot, the entity stays one `GAM` id. (Alternatives: B
  single-table-inheritance with per-type nullable columns; C an open `jsonb` config bag — rejected as
  STI-smell / gold-plating respectively.) **Sub-ruling:** ship the `games_type` CHECK, or leave `type`
  open for iteration?

- **Arm V-2 — bonus-tier removal vs forward-canon drift. RECOMMEND Arm A:** remove the tier+bonus
  economy from the model now (the HARD constraint), and **flag** the forward canon (`roadmap.md` B7.4.2
  "the thirty tiers"; B7.3 "tier claims"; `game_rules.md` "Future Game Extension: Tiers") `[RECONCILE]`
  for a separate follow-up. **Sub-ruling:** if the leaderboard should still SHOW a tier *badge* as pure
  linear-score display (no bonus), that is **Arm B** — a recompute-on-read `div(total,20)` with **zero
  stored column and zero bonus**. Default A (remove entirely).

- **Arm V-3 — Golden's depth in this model. RECOMMEND Arm A:** ship the **as-built boost-only Golden**
  (real on disk: `golden`/`gold_multiplier`, `effective_pool`, live feedback) as the second type now;
  model the type discriminator + a nullable type-specific seam so the forward **blind-mode** Golden
  (feedback `none`, sealed top-K, reduced set, commit-reveal, anonymized) lands **additively later**.
  Building the blind-mode schema now would **violate NO-INVENT** — its core mechanics are explicit open
  questions in `architecture.md`. **Sub-ruling:** is boost-only Golden sufficient for this model, or
  must the blind-mode mechanics be specified + included now?

- **Arm V-4 — the migration mechanism (fresh machine). RECOMMEND Arm A:** collapse the two existing
  create-migrations into **one clean initial create** reflecting the new model (the literal
  "reinitialized, from scratch, not migrations"). (Alternative B: keep the two + add a third drop/rename
  migration — more files, no clean slate.) Default A.

**The "as described" gap (L-2, recorded):** "multiple type of games as described" grounds to a **two-type
launch set** (`classic` + `golden`) — the only types described on disk (`specs.md`). No third type is
described anywhere; the engine is built **extensible** (the discriminator) but only the two grounded
types are modeled. The **description of Golden is itself split** (the as-built boost-only vs the forward
blind-mode), which Arm V-3 resolves. If the Operator means more than these two types, the new types' rules
must be specified before they can be modeled — they will not be invented.

---

## 11. Boundary + what this model does NOT touch

- **Edits production code: none.** This is the design; Mars builds it after Operator approval.
- **Brands not renamed:** `RMM`/`USR`/`EMS`/`GES`/`TXN`/`JOB`/`NOT`/`CMD` (only `RND`→`GAM`). The
  `RMM`↔`ROM` / `USR`↔`PLR` canon drift is a **separate reconcile**, out of scope.
- **Systems not modeled here** (their brands + tables land with them, per the roadmap): the bank
  (`BNK`), membership (`RMP`), sessions (`SES`), commerce (`PKG`/`ORD`/`OTX`/`WHK`), growth (`SHR`),
  analytics (`AEV`), the reified resource (`RSC`). This model is the **game-engine core** (games +
  guesses + the type abstraction + the linear-only scoring), on the as-built nine-brand floor.
- **The blind-mode Golden depth** (sealed settlement, commit-reveal, reduced set, anonymized
  leaderboard, the richer `scheduled→…→voided` state machine) is **PROPOSED**, deferred behind the
  type/policy seam (Arm V-3).
- **Out of bounds entirely:** `docs/codemojex/codemoji-updated/` + the zip (stale extract); the
  Operator's pre-staged `docs/echo/bcs/bcs.progress.md`.

---

*Authored by Venus-PG (architect). The model is grounded entirely on disk this session — every table,
column, brand, policy word, and Golden rule cites a real schema, migration, or canon doc. No production
code was edited. Mars builds from §3/§6/§8/§9 after the Operator rules §10; the Director ratifies; the
Operator accepts.*
