# Codemojex · The Game-Engine Data Model (Design)

<show-structure depth="2"/>

> **The design-phase deliverable for the `codemojex-game-rename` rung — REDIRECTED + OPERATOR-RULED +
> BUILD-EXTENDED (Stage 2, 2026-06-24) + CONVERGED (Stage-2 convergence, 2026-06-25).** The Operator
> turned a token `round`→`game` rename into a from-scratch **model redesign** for a multi-game-type
> engine, ruled the design-intent forks (blind/sealed Golden **specified + built now**, tiers **removed
> entirely**, launch set **{classic, golden}** with a spec-driven rung ladder, §12), then **extended the
> build scope** (D-10): the blind-mode columns go **LIVE this rung** (V-6 → Arm B — no longer
> present-but-deferred), and **two additional brand re-bases** land beside `round`→`game`: room
> `RMM`→`ROM` and player `USR`→`PLR`. **Every open Arm is now RULED** (ledger D-15/D-16, 2026-06-25):
> this document folds those rulings — the schema, the mechanics, and the spec ladder are build-grade with
> **no surviving `[RULE]`-pending fork**. This document is the architectural design of the new Ecto model
> and the code surfaces it wires into. It is authored by Venus-PG (architect), grounded entirely on disk;
> it edits no production code. **The settled core (§3/§6/§8) AND the blind-mode flow (§3.8) are both in
> the build scope** — the founding rung (cm.1, §12) lands the schema + the three brand re-bases + classic
> mode; the blind-Golden rung (cm.3) lands the blind flow on the same schema.
>
> **Stage-2 convergence delta (what the D-15/D-16 rulings changed — read §0.3):** (1) the sealed payout is
> a **stored `payout_split` weight array** (`games.payout_split` / `rooms.payout_split`, default
> `[40,25,15,12,8]`) snapshotted to the game, with `games.top_k` defaulting **5** — *not* a computed
> rank-weight curve (§3.8.2); (2) the reduced set is a **room `cell_count` (N, nullable) + a per-game
> randomized `games.cell_codes` snapshot** (`Enum.take_random(room_codes, N)`), *not* a smaller `EMS` row
> (§3.8.4) — the EMS stays the full keyboard; (3) `status` is **CHECK-bounded** over the seven canon words,
> classic terminal `settled` (§3.8.5); (4) the commitment is **SHA-256(secret ‖ nonce) lowercase hex**, the
> reveal is **one fat `revealed` event**, scoring is **one linear function**, the wire words + FK columns
> **stay** — all folded from `[RULE]`-pending to RULED (§10.1). The **EMS seed is now grounded in the two
> real sprite sheets** measured on disk (§3.3.1): cell grid **`cols × rows × cell_size`** derived from the
> measured PNG dimensions.
>
> **Stage-2 extension delta (what changed from the first pass — read §0.2):** (1) three brand re-bases,
> not one (`RMM`→`ROM`, `USR`→`PLR` join `RND`→`GAM`); (2) the four blind columns are LIVE, not inert;
> (3) two **ground-truth corrections** the Stage-2 reconcile caught — the model stands up **SIX Postgres
> tables**, not seven (no `notifications` table exists in either migration; `NOT` is a Valkey bus lane),
> and the dev/test DB names are **`codemojex_dev`/`codemojex_test`** (`config/dev.exs:14` /
> `config/test.exs:19`), NOT `codemoji_game`. **The convergence (§0.3) adds the ruled payout/reduced-set
> columns** (`games.payout_split` / `games.cell_codes` / `rooms.payout_split` / `rooms.cell_count`) so the
> collapsed initial migration's `games`/`rooms` shape is final.
>
> **Framing discipline (propagate):** in this document and in any prose Mars writes — no gendered
> pronouns for agents; no perceptual or interior-state verbs (sees / wants / notices); no
> first-person narration. State surfaces as contracts.
>
> **Relation to the canon.** `codemojex.architecture.md` + `codemojex.roadmap.md` + `codemojex.specs.md`
> already frame Codemojex as **a generic Mastermind engine on BCS, with each room mode a configuration
> on the same branded entities** (`architecture.md`: *"a `GAM` holds … a mode, and four policies …
> No new entity types separate them"*). This model **realizes that frame in the schema** for the first
> time. The blind-mode mechanics in §3.8 are grounded line-by-line in that canon (cited); where a
> blind-mode promise depends on a system **not yet built** (the `BNK` bank, `RMP` membership), the gap
> is a **flagged grounding hole** (§3.8.6), designed-around — never invented. The one canon disagreement
> this model forces (the bonus-tier removal vs `roadmap.md` B7.4.2 / `game_rules.md`) is a **`[RECONCILE]`**
> the canon owes (§11), not an oversight here.

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
5. **THREE brand re-bases land (Stage-2, D-10):** `RND`→`GAM` (game), **`RMM`→`ROM`** (room),
   **`USR`→`PLR`** (player) — the code is brought into line with the forward canon. The remaining brands
   are **NOT renamed**: `EMS` (emoji set), `GES` (guess), `TXN`, `JOB`, `NOT`, `CMD`.

> **Stage-2 supersession.** The first pass kept the as-built code brands `RMM`/`USR` and deferred the
> `RMM`↔`ROM` / `USR`↔`PLR` reconcile. The Operator's Stage-2 ruling (D-10) **folds that reconcile into
> this rung**: the code re-bases `RMM`→`ROM` and `USR`→`PLR` at the mint sites + the entity drag. The
> acceptance widens to **0 `RND` + 0 `RMM` + 0 `USR`** across `lib` + `test`, and **0 `RMM` (+ `RND`)**
> across `docs/codemojex`. On a **fresh reinit** there is no stored-data rebrand — the renamed code mints
> the new brands (`GAM`/`ROM`/`PLR`) from zero. The brand string is the **only** rename target at the
> mint; the schema **module names** (`Codemojex.Schemas.Room`, `…Player`) are **not** brand-coupled and
> may stay (only the `round`→`game` entity module renames; §6.1).

### 0.1 The ruled forks (folded 2026-06-24 + 2026-06-25 — do not re-litigate)

The Operator + the Director ruled the design-intent forks (first pass, 2026-06-24) **and** the
blind-mechanic Arms the LIVE build forced (D-15/D-16, 2026-06-25). **All are now settled**; the design
realizes them. The first block is the design-intent set; the rows below the `Scoring.score/2` line are the
mechanic Arms D-15/D-16 closed (each cross-referenced to the §-local mechanic + the ledger V-number):

| Fork | Ruling | Effect in this model |
|---|---|---|
| **Golden depth** (V-3) | **Blind/sealed Golden — specify + build now** | §3.8: feedback `none`, settlement `sealed`, commit-reveal, reduced set, the richer state machine. The boost columns (`golden`/`gold_multiplier`) stay (a golden room may still seed + boost a pool), but the type's **defining** policies are `feedback="none"`, `settlement="sealed"`. |
| **Blind columns LIVE** (V-6) | **Arm B (Stage-2) — the four blind columns ship LIVE this rung** | §3.5/§3.8: `commitment`/`nonce`/`revealed_ms`/`top_k` are no longer "present-but-NULL for a future rung" — they are written + read by the cm.3 blind flow, which builds **this** scope. (First pass recommended Arm A boost-only; the Operator overruled to Arm B.) |
| **Brand re-bases** (Stage-2) | **`RND`→`GAM`, `RMM`→`ROM`, `USR`→`PLR`** | §0 / §4 / §6.1: three brands re-based at the mint sites + the entity drag; acceptance 0 `RND`+`RMM`+`USR` in lib+test. |
| **Tier display** (V-2) | **Remove ENTIRELY** — no column, no badge, no ladder | §3.6 + §5: no `guesses.tier`, no recompute-on-read badge; `scoring.ex` `tier/1` + the `:tier` return key removed; the leaderboard ranks **raw linear `points`** (best total). |
| **Type set** (L-2) | **{classic, golden}** + author the spec ladder | §1 two launch types; §12 the rung ladder + the founding-rung triad. |
| **Multi-type shape** (V-1) | **Arm A + the `games_type` CHECK** (Director-ratified) | §3.5: one `games` table + a `type` discriminator + typed policy columns; `type IN ('classic','golden')` CHECK ships. |
| **Migration** (V-4) | **Arm A** (Director-ratified) | §8: collapse the two migrations into one clean initial create. |
| **`Scoring.score/2` return** (§7) | **`percentage` computed-not-stored; `tier` fn + key removed** (Director-ratified) | §7: zero stored `percentage`; the live `pct` recomputed for the channel/lobby; `tier/1` gone. |
| **Scoring unification** (V-7) | **ONE linear scoring function, both modes** (Operator HARD constraint, D-16) | §3.8.2: blind settlement scores every `GES` with the same linear distance + ranks by best total; `architecture.md:59`'s "exact-match" rejected. |
| **State machine** (V-8) | **Full 7-word set, CHECK-bounded; classic terminal `settled`** (D-16) | §3.8.5: `status IN {scheduled,open,active,revealing,settling,settled,voided}` CHECK; classic `open→settled`; golden `open→revealing→settling→settled`; `voided` the abort. |
| **Commitment scheme** (V-14) | **SHA-256(secret ‖ nonce), lowercase hex** (D-16) | §3.8.3: commitment published at open; the preimage (`secret`+`nonce`) server-side until reveal; HMAC + per-cell rejected. |
| **Reveal event** (V-13) | **ONE fat `revealed` event** (D-16) | §3.8.1/§5.1/§6.6: `revealed` at close (secret+nonce+commitment+board+top-K+state); commitment on `game_view` from open; golden per-guess pushes suppressed in-flight. |
| **Top-K payout** (V-15) | **`top_k` DEFAULT 5 + a configurable `payout_split` weight array** (D-15) | §3.8.2: `games.payout_split` / `rooms.payout_split` (default `[40,25,15,12,8]`) snapshotted to the game; sealed settlement pays the top-5 each rank its weight share of `prize_pool`. |
| **Reduced set** (V-16a) | **room `cell_count` (N, nullable) + per-game randomized `games.cell_codes` snapshot** (D-15) | §3.8.4: at start the game snapshots `Enum.take_random(room_codes, N)` (null = the full set = classic); the secret draws its 6 from `games.cell_codes`. The EMS stays the full keyboard. |
| **Anonymized alias** (V-16b) | **DEFER to the `RMP` rung** (D-15) | §3.8.6: the board push carries `{player_id, score}`; the wire shape accepts `{alias, score}` for the later `RMP` rung; the reveal-gated privacy already secures the blind contest. |
| **Wire words / FK columns** (V-11/V-12) | **KEEP** (D-16) | §4/§6.7/§6.8: `/rooms` `/players` `player:` `:no_player`; `transactions.player` / `guesses.player` — the re-base moves the id VALUE, not the column/word NAME. |
| **Regulatory gating** (V-9) | **A config SEAM, a launch-gate decision — NOT schema-shaping** (D-16) | §10.2/Arm V-9: a join-time eligibility predicate + a permissive default; no `games` column; the policy values are a launch checklist item. |

**Every open Arm is now RULED (D-15/D-16, 2026-06-25) — there is no surviving `[RULE]`-pending fork.** The
schema columns the rulings introduce (`games.payout_split` / `games.cell_codes` / `rooms.payout_split` /
`rooms.cell_count`, and `games.top_k` defaulting `5`) are folded into §3.5/§3.4; the blind mechanics are
folded into §3.8 (the recommendation language replaced by the ruling). cm.1 (the settled core) and cm.3
(the blind flow) are both build-grade.

### 0.2 The Stage-2 ground-truth corrections (the reconcile caught these — design now agrees with disk)

The Stage-2 reconcile re-probed every load-bearing fact on disk. Two corrections to the first-pass model:

1. **SIX Postgres tables, not seven.** The first pass said "Seven tables" and flagged a presumed
   `notifications` 7th table (the `20260625…golden_rooms_and_notifications` migration name). **Disk:
   neither migration creates a `notifications` table** — `20260625` only *alters* `rooms`/`rounds`
   (adds `golden`/`gold_multiplier`) and `players` (adds `tg_chat_id`) + an index. `NOT` (notification)
   is a **Valkey bus lane** (`notifier.ex` / `notification_worker.ex`, the `:cm_notify` consumer), **not
   a Postgres table**. The collapsed initial migration stands up **six tables**: `players`,
   `transactions`, `emoji_sets`, `rooms`, `games`, `guesses`. (§2 / §8 corrected.)
2. **The DB names are `codemojex_dev` / `codemojex_test`.** `config/dev.exs:14`
   `database: "codemojex_dev"`; `config/test.exs:19` `database: "codemojex_test#{MIX_TEST_PARTITION}"`;
   `config/runtime.exs` reads `DATABASE_URL` for `:prod` (no literal DB name). The reinit (§8) targets
   `codemojex_dev` + `codemojex_test` **only**. No `*_snapshot` DB appears in any config — it is not a
   disk fact, so it is not named as a thing-to-avoid here (no such DB to untouch).

### 0.3 The Stage-2 convergence corrections (the D-15/D-16 rulings fold the open mechanics)

The Operator ruled the open Arms (ledger D-15 PRODUCT/SCOPE + D-16 ENGINEERING SLATE, 2026-06-25). Three
rulings **refine the mechanism** beyond the architect's recommendation and so add or change schema columns;
the rest match the recommendation and only flip `[RULE]`-pending → RULED. The corrections to the model:

1. **The sealed payout is a stored weight array, not a computed curve (V-15).** The first pass recommended
   a *derived* monotone rank-weight split (`w_i = (K-i+1)/Σ`). The Operator ruled **`games.top_k` DEFAULT
   `5`** + a **configurable `payout_split`** — an ordered integer weight array on the room policy
   (`rooms.payout_split`, default `[40,25,15,12,8]` summing 100) **snapshotted to the game**
   (`games.payout_split`). The sealed settlement ranks every guess linearly + pays the top-`top_k`, each
   rank `i` its weight share `payout_split[i] / Σ payout_split` of the game's own `prize_pool`. **NEW
   columns:** `games.top_k` (default `5`, was nullable), `games.payout_split` (`int[]`),
   `rooms.payout_split` (`int[]` policy default). (§3.4 / §3.5 / §3.8.2.)
2. **The reduced set is a room `cell_count` + a per-game randomized snapshot, not a smaller `EMS` row
   (V-16a).** The first pass recommended *a 24-cell `EMS` row* (the reduction on the `EMS`). The Operator's
   ruling **supersedes** it: a room config **`cell_count`** (`N`, nullable; `null` = the full room cell set
   = classic today) + at game start the game snapshots a **randomized `N`-cell subset** of the room's
   `codes` (`Enum.take_random(room_codes, N)`) stored on the game as **`games.cell_codes`**; the secret
   draws its six from **that** subset (`EmojiSet.secret` over the game keyboard). The `EMS` stays the
   **full** room keyboard; the narrowing moves to the per-game snapshot. **NEW columns:** `rooms.cell_count`
   (`int`, nullable), `games.cell_codes` (`text[]`). (§3.4 / §3.5 / §3.8.4.) The EMS seed is grounded in
   the two real sprite sheets (§3.3.1).
3. **`status` is CHECK-bounded; classic terminal `settled` (V-8).** The full seven canon words
   `{scheduled, open, active, revealing, settling, settled, voided}` ship as a **CHECK-bounded** column;
   classic `open → settled` (the as-built `closed` maps to `settled`); golden `open → revealing → settling
   → settled`; `voided` the abort. (§3.5 / §3.8.5.)

The rulings that **match the recommendation** (folded `[RULE]`-pending → RULED, no schema change): V-14
SHA-256(secret ‖ nonce) lowercase hex commit-reveal (§3.8.3); V-13 one fat `revealed` event (§3.8.1/§5.1);
V-7 one linear scoring function for both modes (§3.8.2); V-16b defer the anonymized alias to `RMP`
(§3.8.6); V-11 keep the room/player wire words; V-12 keep the FK column names (§4/§6).

> **Note on the V-numbering.** §10.2 labels the new blind-mechanic Arms by their §-local description; the
> **ledger V-number is the authority** (the design's own footnote). The map: the commitment-scheme Arm =
> **ledger V-14**; the payout-curve Arm = **ledger V-15**; the reduced-set Arm = **ledger V-16(a)**; the
> anonymized-alias Arm = **ledger V-16(b)**; scoring unification = **V-7**; the state machine = **V-8**.
> This document now cites the ledger V-numbers.

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
| `classic` | `score` — live per-guess 0–600 | `live` (perfect crack or timer) | linear distance | per-guess fee, winner-take-all pool | the whole as-built game |
| `golden` | **`none`** — no per-guess signal until reveal | **`sealed`** — one batch at close, pay top-K | linear distance (V-7) | per-guess fee (all-pay), boosted pool (`gold_multiplier`), top-K split | `architecture.md` "Data flow — a Golden Room" + "Provably-fair secret"; `specs.md:46–56`; `golden-rooms.md`, `economy.ex` |

> **Golden is the canon's BLIND/SEALED mode (Operator-ruled, §0.1).** The boost columns
> (`golden`/`gold_multiplier`) remain — a golden room may still seed + boost its pool — but the type's
> **defining** policies are `feedback="none"` + `settlement="sealed"`. The mechanics are specified in
> §3.8 (each cited to the canon), and the `games` schema delta is §3.5. The question the Operator's
> "Existing linear score" constraint forced — does blind rank by **linear distance** or **exact-match**
> (`architecture.md:59`) — is **ruled (V-7, D-16): one linear function for both modes**; the difference is
> feedback + settlement, not the scoring math. The type discriminator + the nullable type-specific columns
> keep the engine **one `GAM` identity** across both modes.

---

## 2. The new schema at a glance — what changed from the round-based model

**Six Postgres tables** (§0.2 — `notifications` is a Valkey bus lane, not a table), each keyed by a
branded id, each carrying its own status word as text. The delta from the as-built model
(`codemojex.design.md` §"The data model"):

| Table | Brand | Change from round-based model |
|---|---|---|
| `players` | **`PLR`** (was `USR`) | **brand re-based** `USR`→`PLR` at the mint (`wallet.ex:21`); columns **unchanged** (incl. the `tg_chat_id` add + the non-negative CHECK; see §3.7 on `bonus_diamonds`) |
| `transactions` | `TXN` | **unchanged** (append-only ledger; the `player` FK now references a `PLR` id) |
| `emoji_sets` | `EMS` | **unchanged** |
| `rooms` | **`ROM`** (was `RMM`) | **brand re-based** `RMM`→`ROM` at the mint (`rooms.ex:18`); `round` FK column → **`game`**; `golden` + `gold_multiplier` folded into the initial create; **+ `type`** (the room's default game type); **+ `payout_split`** (the sealed-split policy, V-15) + **`cell_count`** (the reduced-set policy, V-16a) |
| **`games`** | **`GAM`** (was `RND`) | **was `rounds`/`RND`** — renamed table + brand; **+ `type`** discriminator + the four **policy** columns; `golden` + `gold_multiplier` folded in; **+ the four blind columns LIVE** (`commitment`/`nonce`/`revealed_ms`/`top_k`, `top_k` default `5`); **+ `payout_split`** (the snapshotted split, V-15) + **`cell_codes`** (the snapshotted reduced keyboard, V-16a); the `secret` + `nonce` stay server-side |
| `guesses` | `GES` | `round` FK column → **`game`** (references a `GAM` id); **`tier` REMOVED**; **`percentage` REMOVED** (linear `points` only) |

The Valkey keyspace for a classic game changes only by the **removal** of the bonus layer (§5); the
blind (golden) keyspace is the same minus the live board push (§5.1, §3.8.1).

---

## 3. The tables (types / null / defaults / CHECKs / indexes / relationships)

All ids are `:string` primary keys (the 14-char branded snowflake; no autogenerate — minted by
`EchoData.BrandedId`). All timestamps `:utc_datetime_usec`. Grounded in the as-built schemas under
`lib/codemojex/schemas/` and the two migrations.

### 3.1 `players` (`PLR`, was `USR`) — brand re-based, columns unchanged

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
**Brand:** `USR`→`PLR` at `wallet.ex:21` `generate!("PLR")` (+ the `USR`→`PLR` doc-prose at `wallet.ex:19`
/ `game.ex:6`). The schema module `Codemojex.Schemas.Player` is **not** brand-coupled — it stays.

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

#### 3.3.1 The EMS seed — grounded in the two real sprite sheets (measured on disk)

The reduced-set ruling (V-16a, §3.8.4) supplies **two real sprite sheets** under
`docs/codemojex/emoji-sets/` (`01-emoji-set.png`, `02-emoji-set.png`, + `@2x` retina variants). **No
manifest exists** — the grid is derived from the **measured PNG dimensions**, per the no-invent rule. An
`EmojiSet` addresses a cell `XXYY` at `(-x·cell_size, -y·cell_size)` (`emoji_set.ex:5,52`), so
`cols = width ÷ cell_size` and `rows = height ÷ cell_size`, **both integers**.

**Measured (sips):** `01` is `720 × 1080` (base) / `1440 × 2160` (`@2x` — exactly 2× base, no extra rows);
`02` is `720 × 1512` / `1440 × 3024`. The code default `cell_size = 144` (`emoji_set.ex:39`) gives
**non-integer** rows (`01`: `5 × 7.5`; `02`: `5 × 10.5`) — it does **not** fit these assets. The only cell
size dividing **both** sheets' width **and** height into integers is **`cell_size = 72`** (`01`: `10 × 15`
= 150 cells; `02`: `10 × 21` = 210 cells; `120` fits `01` but not `02`, `360` fits neither's height). **The
seed states `cell_size = 72`** — the measured-true divisor, not the blind `144` default:

| EMS | name | cols | rows | cell_size | sprite_url | codes |
|---|---|---|---|---|---|---|
| EMS-1 | `emoji-set-01` | `10` | `15` | `72` | `/emoji-sets/01-emoji-set.png` (`@2x` via retina srcset) | `all_cells(10,15)` = **150** row-major `XXYY` cells |
| EMS-2 | `emoji-set-02` | `10` | `21` | `72` | `/emoji-sets/02-emoji-set.png` | `all_cells(10,21)` = **210** cells |

`codes` is the **full** keyboard (every cell) — the room exposes the whole set, and the per-game
`cell_count` snapshot (§3.4 / §3.8.4) does the narrowing, **not** a smaller `EMS.codes`. The `secret` is
six distinct codes drawn from the game's snapshot (`EmojiSet.secret`, `emoji_set.ex:64`).

> **`cell_size` is a surfaced fork (the only one in this convergence).** The code default is `144`; the
> two measured assets demand `72` for an integer grid. The seed states **`72`** (the measured-true value);
> if the Operator intends a different grid (e.g. the assets are to be re-exported at a `144` cell), that is
> a one-line ruling that changes only these two seed rows — the mechanism (`cell_count` + `cell_codes`) is
> unaffected. Flagged for the Director, recommending `72`.

### 3.4 `rooms` (`ROM`, was `RMM`) — the brand re-base + the FK rename + the type default

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
payout_split  {array,integer}  not null  default [40,25,15,12,8]  -- NEW (V-15): the sealed-split policy, snapshotted to the game
cell_count    integer  nullable                       -- NEW (V-16a): the reduced-set size N; null = the full EMS set (classic)
timestamps
```

Relationship: `rooms.game` → `games.id` (the at-most-one active game; nullable when waiting). The room
is a **template**; a game snapshots it at start (`rooms.ex` `start_game`).

> **`payout_split` (V-15, D-15)** — an ordered integer **weight array** (the default `[40,25,15,12,8]`
> sums 100); the sealed settlement pays rank `i` of the top-`top_k` its share `payout_split[i] / Σ
> payout_split` of the game's `prize_pool` (§3.8.2). It is a **room policy** snapshotted onto the game at
> start (`games.payout_split`) so a game settles by the split it was created under, even if the room's
> policy later changes. Default `[40,25,15,12,8]` (five weights, matching the default `top_k = 5`); a room
> with a different breadth sets its own array.
>
> **`cell_count` (V-16a, D-15)** — the **reduced-set size** `N` (nullable; `null` = the full `EMS` cell
> set = classic today). At `start_game` the game snapshots `Enum.take_random(EMS.codes, N)` into
> `games.cell_codes` when `cell_count = N`, else the full `EMS.codes` when `null` (§3.4 → §3.5 / §3.8.4).
> A golden room sets `cell_count` (e.g. `24`); a classic room leaves it `null`. The narrowing is a
> per-game randomized snapshot, **not** a smaller `EMS` row (the EMS stays the full keyboard).

> **`type` vs `golden`.** `type` is the engine discriminator (`classic` | `golden`); `golden` +
> `gold_multiplier` are the **boost economy** the `golden` type carries. They are consistent by
> construction — a `golden`-type room defaults `golden: true`, `gold_multiplier: 3` (the as-built
> default, `rooms.ex:33`). Modeled as both a discriminator and explicit boost columns so the boost is
> queryable and CHECK-able, not buried in a config bag (§10/V-1, Arm A).

Source: `schemas/room.ex`, migrations `20260618000000` + `20260625000000`.
**Brand:** `RMM`→`ROM` at `rooms.ex:18` `generate!("ROM")` (+ the `RMM`→`ROM` doc-prose at
`rooms.ex:14`). The schema module `Codemojex.Schemas.Room` is **not** brand-coupled — it stays;
`rooms.game` references a `GAM` id.

### 3.5 `games` (`GAM`) — the redesigned per-play entity (was `rounds`/`RND`)

```
id            string   PK                              -- GAM (was RND)
room          string   nullable                        -- FK → rooms.id
emojiset      string   nullable                        -- FK → emoji_sets.id (snapshot; a reduced set for golden, §3.8.4)
type          string   not null  default "classic"     -- NEW: the engine discriminator (classic | golden)
feedback      string   not null  default "score"        -- NEW policy: "score" (classic) | "none" (golden)
scoring       string   not null  default "linear"       -- NEW policy: "linear" (the only value today; V-7)
settlement    string   not null  default "live"         -- NEW policy: "live" (classic) | "sealed" (golden)
economy       string   not null  default "winner_take_all" -- NEW policy: the payout-curve DESCRIPTOR (stored, NOT read for control flow — `do_close` dispatches on `settlement` "sealed"→top_k_split / else→winner_take_all, rooms.ex; golden carries economy="winner_take_all" as a label, the sealed split is selected by settlement, §3.8.2)
secret        {array,string}  not null                  -- server-side; no player-facing query selects it
cell_codes    {array,string}  not null                  -- NEW (V-16a): the game's snapshotted keyboard (take_random N of the room codes, or the full set); the secret draws from THIS
commitment    string   nullable                         -- NEW (blind): hash over secret+nonce, set at open (§3.8.3)
nonce         string   nullable                         -- NEW (blind): server-side, sealed; revealed at close (§3.8.3)
revealed_ms   bigint   nullable                         -- NEW (blind): when secret+nonce were revealed (null until close)
top_k         integer  not null  default 5               -- NEW (blind): sealed payout breadth — pay the top K (§3.8.2 / V-15)
payout_split  {array,integer}  not null  default [40,25,15,12,8]  -- NEW (V-15): the snapshotted split weights; rank i takes split[i]/Σsplit of prize_pool
started_ms    bigint   not null
ends_ms       bigint   not null
prize_pool    bigint   not null  default 0              -- diamonds, seeded from the room
guess_fee     integer  not null  default 1
free          boolean  not null  default false
clip_cost     integer  not null  default 1
status        string   not null  default "open"          -- the state machine (§3.8.5 / V-8) — CHECK-bounded to the 7 canon words
golden        boolean  not null  default false
gold_multiplier integer not null default 1
timestamps
INDEX (room)
```

- **CHECK `games_type` (ships — V-1 Arm A, Director-ratified):** `type IN ('classic','golden')` —
  bounds the launch type set so an unknown type cannot be written (the queryability the money-adjacent
  floor wants).
- **CHECK `games_status` (ships — V-8, D-16):** `status IN ('scheduled','open','active','revealing',
  'settling','settled','voided')` — the full seven canon words (`specs.md:36`); classic uses
  `open → settled`, golden `open → revealing → settling → settled`, `voided` the abort (§3.8.5).
- The **four policy columns** (`feedback`, `scoring`, `settlement`, `economy`) realize the canon's
  *"four policies"* (`architecture.md`/`roadmap.md`). They are **snapshotted from the room's type at
  game start** and immutable for the game's life — the same snapshot discipline `golden`/`gold_multiplier`
  already follow (`rooms.ex` `start_game`). For the two launch types they are derivable from `type`
  alone, so they are **defaulted** and the type→policy mapping lives in code (a small lookup); storing
  them explicitly keeps a game self-describing for settlement and for replay, and leaves the seam for a
  type whose policies are not a pure function of its name.
- **The four blind-mode columns** (`commitment`, `nonce`, `revealed_ms`, `top_k`) are **nullable —
  `NULL` for classic, WRITTEN for golden** (the type-specific seam from V-1 Arm A). They ship **LIVE this
  scope** (V-6 → Arm B, §0.1): a golden game writes `commitment` at open, `nonce` + `revealed_ms` at
  reveal, and `top_k` at start (snapshotted from the room). Their mechanics + grounding are §3.8.
  `nonce` is held **server-side like `secret`** — no player-facing query selects it until reveal
  (§3.8.3). When each column is written:

  | Column | Type / null | Written | Read |
  |---|---|---|---|
  | `cell_codes` | `text[]`, not null | at start — `Enum.take_random(room_codes, cell_count)` (or the full set when `cell_count` null) | the keyboard the player taps; the source the `secret` is drawn from (§3.8.4) |
  | `commitment` | `string`, null | at open (`start_game`, golden) — SHA-256(`secret ‖ nonce`), lowercase hex | exposable at open (the player records it); re-checked at reveal |
  | `nonce` | `string`, null | at open, **server-side sealed** | exposed only at reveal (`revealed_ms` set) |
  | `revealed_ms` | `bigint`, null | at close (`revealing` transition) | the privacy gate — `points` withheld from reads until this is set (§3.8.1) |
  | `top_k` | `integer`, default `5` | at start, snapshotted from the room (the sealed payout breadth) | the settlement pass pays the top `top_k` (§3.8.2) |
  | `payout_split` | `int[]`, default `[40,25,15,12,8]` | at start, snapshotted from `rooms.payout_split` | the settlement pass pays rank `i` its share `split[i]/Σsplit` (§3.8.2) |
- `secret` stays a server-side column, selected by **no** player-facing query (`schemas/round.ex`,
  `view.ex` — the privacy invariant).
- The `GAM` id doubles as the cache version + the idempotency token (immutable for the game's life;
  `tables.ex`, `cache` coherence `:none`). **The `secret`/`nonce`/`commitment` are immutable for the
  game's life** — the cache version story is unchanged.

> **The state machine (§3.8.5 / V-8, RULED D-16).** `specs.md:36` names `scheduled, open, active,
> revealing, settling, settled, voided`; the as-built code uses `open | closed`. This model adopts the
> **full canon set, CHECK-bounded** (the `games_status` CHECK above), each type traversing the subset it
> needs: **classic** `open → settled` (the as-built `closed` maps to **`settled`** — the ruled terminal
> word); **golden** `open → revealing → settling → settled`; `voided` is the abort path for both
> (§3.8.5). The founding rung (cm.1) writes the classic subset (`open`, `settled`); the blind rung (cm.3)
> writes `revealing`, `settling` — both within the one CHECK, no migration between rungs.

Source: `schemas/round.ex`, migrations `20260618000000` + `20260625000000`; the type/policy columns +
the four blind-mode columns are the NEW design realizing `architecture.md` "Provably-fair secret" +
"Data flow — a Golden Room" and `specs.md:46–56`.

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

`points` — the raw linear total — **stands** and is the sole stored score, for **both** game types. The
leaderboard ranks by the player's **best `points`** — live for classic, computed once at the sealed pass
for golden (§3.8.1, V-7). No `tier`, no `percentage`, no bonus.

Source: `schemas/guess.ex`, migration `20260618000000`; the column removals are the NEW design per the
Operator constraint.

### 3.7 A naming hazard to NOT over-remove — `players.bonus_diamonds`

`players.bonus_diamonds` (`schemas/player.ex`, `01-currency-model.md`) is a **wallet bucket** — a
promotional-diamond balance granted on redemption — **not** a game bonus tier. The Operator's "no bonus
tiers" targets the **scoring** bonus economy, not the wallet. **Keep `bonus_diamonds`.** Mars must not
remove it. (The word "bonus" is overloaded; this is the wallet sense.)

### 3.8 The blind-mode mechanics (Golden) — each grounded in the canon

The Operator ruled Golden = the canon's **blind/sealed** mode, **built LIVE this scope** (§0.1, V-6 Arm
B). The mechanics below are specified **only** from what the canon states on disk; each carries its
citation. Where a promise depends on a system **not yet built**, the gap is **flagged (§3.8.6)** — never
invented; where the canon leaves a *mechanic* genuinely open (the commitment hash, the top-K split, the
reduced-set size, the anonymized alias), it is **framed as an Arm (V-10/V-11/V-12)** for the Director to
rule with the Operator — an open mechanic is a fork to rule, not surface to invent. The schema delta is
the four `games` columns from §3.5; the flow uses them without adding the bank or membership systems.
**The cm.3 triad (§12.3) is the blind-Golden spec body** — `cm.3.md` carries these contracts as
deliverables + the Given/When/Then acceptance.

#### 3.8.1 Feedback `none` + the privacy rule

A golden game gives **no per-guess signal**. `architecture.md` "Data flow — a Golden Room": *"the channel
carries the timer and state only, with no results"*; `roadmap.md` B7.1.3: *"in blind mode not even a
score leaks until reveal."* Contract:
- **Precondition:** `feedback="none"`. **Postcondition of a scored guess:** the `GES` is **stored**
  (charged, enqueued, persisted) but **nothing** about its score is broadcast or returned — no `scored`
  PubSub push, no channel result, no `my_history` score until reveal. The channel carries `status` +
  timer only.
- **Invariant:** the privacy boundary already in `view.ex` widens for golden — the per-guess `points` is
  withheld from every player-facing read until `revealed_ms` is set. (Classic's `view.ex` returns the
  player's own `points` immediately; golden withholds it until reveal — a policy branch on `feedback`,
  not a new view.)
- **Scoring still runs** (the worker scores + stores `points`); only the **emission** is suppressed. This
  keeps the sealed pass cheap (the scores already exist at close) and is why `points` is stored for both
  types (§3.6).

#### 3.8.2 Settlement `sealed` — one batch at close, pay top-K

`architecture.md` "Data flow — a Golden Room": *"One settlement pass scores every `GES` against the
revealed secret, ranks players, pays the top K … records the rake; the game moves to settled."*
`specs.md:47`: *"Close on the timer; run one settlement pass over all guesses; pay the top K."* Contract:
- **Trigger:** the timer expires (golden does **not** close on a perfect crack — there is no per-guess
  signal, so no early close; `ends_ms` is the sole trigger).
- **The pass (at `revealing`→`settling`, §3.8.5):** reveal the secret+nonce; for each player take their
  **best linear `points`** (V-7); rank players by best `points` desc; pay the **top `top_k`** by rank
  from the game's `prize_pool` (boosted by `gold_multiplier` if `golden`, via `Economy.effective_pool/3`),
  **each rank `i` taking its share `payout_split[i] / Σ payout_split`** of the effective pool; deposit each
  prize as a `TXN` through the wallet inside the one-shot close (`cm:{game}:closed` `SET NX`, as-built
  `rooms.ex`).
- **Idempotency invariant:** the pass is **pure + guarded** — a re-run pays identically (the `SET NX`
  lock + the pure ranking, the as-built exactly-once close discipline extended to the top-K split).
- **The payout split is a STORED weight array (V-15, RULED D-15).** `games.top_k` defaults **`5`**; the
  split is the ordered integer array `games.payout_split` (default `[40,25,15,12,8]`, snapshotted from
  `rooms.payout_split` at start, §3.4/§3.5). The settlement ranks every guess linearly and pays rank `i`
  of the top-`top_k` its **weight share** `payout_split[i] / Σ payout_split` of `Economy.effective_pool/3`.
  This is a **new pure `economy.ex` function** (as-built `top_k_split/3` over the pool, the ranked best
  `points` board, + the stored split array) — the seam beside the as-built `winner_take_all/2` (K=1) +
  `proportional/2`. The split is **not** a computed monotone curve (the first-pass recommendation) — it is
  the Operator-configured array, so a room sets its own prize distribution and a game settles by the split
  it was created under. When fewer than `top_k` players guessed, only the present ranks are paid (the share
  normalizes over the weights actually assigned). **The integer-division remainder (the rounding dust) is
  added to rank 1 (the top scorer) so the WHOLE pool is distributed — none is stranded** (as-built
  `add_dust/2`; a boosted golden pool must not strand boosted diamonds, vs the `winner_take_all/2`
  even-split floor convention). Purity preserved (the dust assignment is deterministic, so a re-run pays
  identically). Grounded in `specs.md:47`'s "pay the top K".

#### 3.8.3 Commit-reveal — the provably-fair secret

`architecture.md` "Provably-fair secret": a hash commitment over the secret + a nonce gives **hiding**
(no secret leaks before reveal) + **binding** (the server cannot open to a different secret after open).
`specs.md:53–56`. Contract:
- **At open** (`start_game` for a golden game): draw the `secret` (six distinct codes from the game's
  snapshotted keyboard `cell_codes`, §3.8.4), draw a `nonce`, compute `commitment = SHA-256(secret ‖
  nonce)`, store all three on the `GAM`; `secret` + `nonce` are **server-side, sealed** (no player-facing
  query selects them); `commitment` MAY be exposed at open (the player can record it).
- **At close** (`revealing`): set `revealed_ms`; **expose** `secret`, `nonce`, `commitment` so any player
  recomputes `SHA-256(secret ‖ nonce)` and checks it equals the stored `commitment` (`specs.md:55`). The
  commitment **binds** the server to the secret it fixed at open.
- **The hash + encoding are RULED (V-14, D-16): SHA-256(secret ‖ nonce), lowercase hex.** `architecture.md`
  calls a hash-based commitment "the lean instantiation" but left the exact scheme an open question; the
  Operator ruled it **SHA-256 over a canonical UTF-8 encoding of the six secret codes joined by a record
  separator then `‖ nonce`, emitted as lowercase hex** (`:crypto.hash(:sha256, …)`, zero new dependency).
  HMAC (a keyed secret cannot be published for the player to recompute → breaks verifiability) and a
  per-cell commitment (leaks the secret's structure) were rejected. The `games.commitment` column is a
  `string`. **The encoding is byte-pinned + documented** so a client in any language recomputes it
  identically — that pinning is the deliverable; `cm.3.md` G2 carries the exact byte layout.

#### 3.8.4 The reduced symbol set — a room `cell_count` + a per-game randomized snapshot (RULED V-16a)

`specs.md:46`: *"Use a reduced emoji set (for example 18 or 24 cells) to keep the space tractable without
hints"*; `architecture.md:14`: *"over a reduced symbol set."* **The Operator ruled the mechanism (V-16a,
D-15) — superseding the first-pass "a smaller `EMS` row":** the reduction is a **room config + a per-game
randomized snapshot**, not a property of the `EMS`. Contract:
- **`rooms.cell_count`** (`N`, nullable; §3.4) is the reduced-set size. **`null` = the full room cell set**
  (= classic today); a golden room sets `N` (e.g. `24`).
- **At `start_game`** the game snapshots its keyboard into **`games.cell_codes`** (§3.5): when
  `cell_count = N`, `cell_codes = Enum.take_random(EMS.codes, N)` — a **randomized** `N`-cell subset of the
  room's full keyboard; when `cell_count` is `null`, `cell_codes = EMS.codes` (the full set). The snapshot
  is **immutable for the game's life** (the cache-version story, §3.5).
- **The secret draws its six from `games.cell_codes`** — `EmojiSet.secret` over the game's snapshot, not
  the room's full `EMS` (`emoji_set.ex:64`; the keyboard the player taps and the secret they chase index
  the **same** snapshot). The `EMS` row stays the **full** keyboard (§3.3.1) — the narrowing is the
  per-game `cell_codes`, **not** a smaller `EMS.codes`.
- **Why a snapshot, not a smaller `EMS`:** one `EMS` row (the full 150- or 210-cell sheet, §3.3.1) serves
  **both** classic (`cell_count` null → the whole keyboard) and golden (`cell_count` `N` → a fresh random
  `N`-subset per game), so the reduced contest varies game to game without a separate reduced `EMS` row per
  difficulty. The size `N` is the room policy (`cell_count`); the six-of-`N` space sets the difficulty.
  **NEW columns:** `rooms.cell_count`, `games.cell_codes` (§3.4 / §3.5).

#### 3.8.5 The state machine (V-8, RULED D-16)

`specs.md:36`: `scheduled → open → active → revealing → settling → settled → voided`. The model adopts
the full set as **text words bounded by the `games_status` CHECK** (§3.5), each type a subset:
- **classic:** `open → settled` (the as-built `closed` terminal maps to **`settled`** — the ruled
  terminal word, D-16). A perfect crack or the timer triggers the close.
- **golden:** `open → revealing → settling → settled`. The timer triggers `revealing` (reveal
  secret+nonce, set `revealed_ms`, score the sealed batch) → `settling` (pay top-K) → `settled` (expose
  for verification).
- **both:** `voided` is the abort path (an admin void / an unrecoverable settlement failure).
- `scheduled` + `active` are **canon states the launch types do not yet use** (`scheduled` = a future
  pre-open state; `active` = a future open-with-players refinement). The CHECK admits them; the launch
  types do not write them. **The founding rung (cm.1) writes the classic subset** (`open`, `settled`);
  **the blind rung (cm.3) writes** `revealing`, `settling`. The CHECK is **one** column constraint
  shipped in cm.1's initial create — both rungs write within it, no migration between them.

#### 3.8.6 The grounding GAPS — designed-around, NOT invented (flagged)

Three blind-mode promises in the canon depend on systems **out of this model's scope**. The schema
supports the blind **flow** without them; they land with their systems (the roadmap's later chapters):
- **The `BNK` bank + the rake.** `architecture.md` says the sealed pass *"pays the top K from the
  bank … records the rake."* There is **no bank table** as-built; the as-built close pays from the
  **game's own `prize_pool`** (`rooms.ex` `do_close`). **This model's top-K pays from `prize_pool`** (the
  grounded path); **no rake column** (a `BNK` concern). When the bank system is built, the pool's escrow
  + the rake move to it — additive. **GAP flagged, not invented.**
- **The anonymized leaderboard (DEFER to `RMP` — RULED V-16b, D-15).** `architecture.md` "Anonymization"
  + `specs.md:49`: a per-game alias on the **`RMP` membership**. There is **no membership table** as-built
  (the leaderboard keys on `PLR` directly, the re-based player brand). **This model does not add the
  alias** — the Operator ruled it **deferred to the `RMP` rung**: until then a golden leaderboard ranks by
  `PLR` like classic, and the reveal-gated privacy (no score until reveal, §3.8.1) already secures the
  blind contest without the alias. **The board push carries `{player_id, score}`** now; the wire shape is
  authored to **accept `{alias, score}`** later (the `RMP` rung supplies the alias without a wire break).
  **GAP flagged, not invented.**
- **The `SES` session / verified `initData`.** Out of scope (the as-built reads the player id from the
  request; `codemojex.design.md` names verified `initData` "the one explicit gap before launch"). Not a
  blind-mode-specific gap, but it bears on the regulatory seam (§ Arm V-9).

> **Why these are gaps, not blockers.** The blind FLOW — commit → seal → no-feedback → reveal → sealed
> linear score → top-K pay-from-pool by the stored split — is **fully realizable** on the as-built
> nine-brand floor with the new `games` columns (the four blind columns + `cell_codes` + `payout_split`).
> The bank, membership-alias, and session systems are **enhancements** the roadmap already schedules;
> designing around them keeps this model grounded + NO-INVENT, and leaves a clean additive seam for each.

---

## 4. The branded-id contract

`games` mints **`GAM`** (was `RND`) — at the key builder (`rooms.ex` `EchoData.BrandedId.generate!`,
`tables.ex` `kind:`). **Unchanged** brands:

| Brand | Entity | Lives in |
|---|---|---|
| `GAM` | game (was `RND`) | Postgres `games`, EchoStore `:cm_games` |
| `ROM` | room (was `RMM`) | Postgres `rooms` |
| `PLR` | player (was `USR`) | Postgres `players`, Valkey lanes/board |
| `EMS` | emoji set | Postgres `emoji_sets`, EchoStore `:cm_emojisets` |
| `GES` | guess | Postgres `guesses` |
| `TXN` | wallet transaction | Postgres `transactions` |
| `JOB` | bus work | Valkey queues |
| `NOT` | notification | Valkey notify lane |
| `CMD` | bot command | Valkey commands lane |

The id is the only value that crosses a boundary; it keys the Postgres row, the Valkey entry, the bus
job, and the announce message. The 14-byte shape (`<<_::binary-14>>`) and the `ts(41)|node(10)|seq(12)`
snowflake are **unchanged** — **three** namespace strings re-base at the mint (`RND`→`GAM`, `RMM`→`ROM`,
`USR`→`PLR`); the rest are byte-unchanged.

> The forward roadmap's remaining namespace set (`RMP`/`BNK`/`RSC`/`SES`/`PKG`/`ORD`/`OTX`/`WHK`/`SHR`/
> `AEV`) is the **target** for systems not yet built (commerce, growth, analytics). This model now holds
> the nine brands `GAM`/`ROM`/`PLR`/`EMS`/`GES`/`TXN`/`JOB`/`NOT`/`CMD` (the three re-bases done); the
> rest land with their systems. Out of scope here.

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

### 5.1 The blind (golden) keyspace — same keys, the live push suppressed

A golden game uses the **same** `cm:{game}:` keys as classic, with two policy differences driven by
`feedback="none"` + `settlement="sealed"` (§3.8.1/§3.8.2):

| Key | Classic | Golden |
|---|---|---|
| `cm:{game}:base` (hash) | written + the player's score **pushed** to the channel | written (the score exists server-side at close, cheap to settle) but **not pushed** — no `scored` event leaks |
| `cm:{game}:board` (ZSET) | updated live; the leaderboard reads it live | updated server-side; **not read by any player-facing view until `revealed_ms`** (the privacy gate) |
| `cm:{game}:players` / `:attempts` | live | live (the channel may carry the player + attempt counts — they leak no score) |
| `cm:{game}:closed` (lock) | the exactly-once close `SET NX` | the **same** lock guards the one-shot sealed settlement pass (§3.8.2) |

> The golden flow **scores and stores into the same Valkey + Postgres keys** — only the **emission**
> (the `scored` PubSub push) and the **player-facing read** of the board are gated on `feedback`/
> `revealed_ms`. This is why the board layer is shared (not forked) across modes: the difference is a
> policy branch on `feedback`, not a separate keyspace. No blind-specific Valkey key is added.

---

## 6. How the model wires into the code surfaces (cite-grounded; Mars builds these)

The schema change drives a code change at every surface the `GAM` identity and the removed columns
travel. **Each surface is named with its file; Mars cites the line.** This is the build map, not new
behavior beyond the model.

### 6.1 Schemas (`lib/codemojex/schemas/`)
- **Rename** `round.ex` → `game.ex`; `Codemojex.Schemas.Round` → `Codemojex.Schemas.Game`;
  `schema "rounds"` → `schema "games"`; **add** `type`, `feedback`, `scoring`, `settlement`, `economy`,
  **the four blind columns** `commitment`, `nonce`, `revealed_ms`, `top_k`, **and** `cell_codes` +
  `payout_split` to the schema + the `cast` list (the blind columns ship LIVE — §3.5; `top_k` defaults
  `5`, `payout_split` defaults `[40,25,15,12,8]`).
- `room.ex`: `field :round` → `field :game` (+ the `cast` list); **add** `type`, `payout_split`,
  `cell_count`. The module `Codemojex.Schemas.Room` **stays** (not brand-coupled); the `ROM` re-base is at
  the mint (§6.3), not the module name.
- `guess.ex`: `field :round` → `field :game` (+ `cast`/`validate_required`); **remove** `field :tier`
  and `field :percentage` from the schema + the `cast` list.
- `player.ex`: the module `Codemojex.Schemas.Player` **stays**; the `PLR` re-base is at the mint
  (`wallet.ex`, §6.8), not the schema. No column change.

> **The three brand re-bases are at the MINT, not the schema module.** `EchoData.BrandedId.generate!`
> validates by **shape**, not a registry — the brand string at `generate!("…")` (+ the `kind:` cache
> string + any doc-prose brand token) is the entire rename surface. The schema module names
> (`Room`/`Player`) and table names (`rooms`/`players`) are **not** brand strings, so only the entity
> (`round`→`game`) renames its module + table; `ROM`/`PLR` re-base their `generate!` string alone.

### 6.2 Store + cache + tables
- `store.ex`: `alias … {…, Round, …}` → `{…, Game, …}`; `put_round`/`round` → `put_game`/`game`
  (`Repo.get(Game, …)`); `guesses_for/3` `g.round` → `g.game`; the `Codemojex.Cache` `@cache :cm_rounds`
  → `:cm_games`, `fetch_round`/`put_round` → `fetch_game`/`put_game`.
- `tables.ex`: `@rounds :cm_rounds` → `@games :cm_games`; `rounds_table/0` → `games_table/0`;
  `kind: "RND"` → `"GAM"`; `&load_round/1` → `&load_game/1`; `:rounds_cache_ttl_ms` →
  `:games_cache_ttl_ms`; the moduledoc bullet `:cm_rounds (RND)` → `:cm_games (GAM)`.

### 6.3 The game lifecycle (`rooms.ex`)
- **Room mint (`ROM`):** `generate!("RMM")` → `generate!("ROM")` (`rooms.ex:18`) + the `RMM`→`ROM`
  doc-prose (`rooms.ex:14`).
- **Game mint + entity rename:** `start_round/3` → `start_game/3`; `generate!("RND")` →
  `generate!("GAM")` (`rooms.ex:60`); **snapshot the type + the four policies + `payout_split` + `top_k`**
  onto the game at start (from the room's `type`/`payout_split`, via the type→policy lookup); **snapshot
  the keyboard** into `cell_codes` (`Enum.take_random(EMS.codes, room.cell_count)` when `cell_count` set,
  else the full `EMS.codes`, §3.8.4) and **draw the `secret` from `cell_codes`** (`EmojiSet.secret`, six
  distinct, `emoji_set.ex:64`); `close_round/1` → `close_game/1`; `close_if_expired/1`; `:no_round` →
  `:no_game`.
- **The blind open branch (golden, LIVE):** when the started game's `type="golden"`, also draw a
  `nonce`, compute `commitment = SHA-256(secret ‖ nonce)` (lowercase hex, the byte-pinned encoding,
  §3.8.3 / V-14), and write the blind columns at start. `secret` + `nonce` stay server-side; the snapshot
  + `secret` already happened in the common mint above (the secret is six distinct of `cell_codes`).
- **The close path branches on `settlement`:** classic (`settlement="live"`) keeps the as-built
  `effective_pool`/`winner_take_all` path **unchanged** (the Golden boost stays); golden
  (`settlement="sealed"`) runs the sealed pass (§3.8.2) inside the **same** `cm:{game}:closed` `SET NX`
  one-shot — reveal (`set revealed_ms`, expose secret+nonce), rank by best linear `points`, pay the top
  `top_k` from `effective_pool` **each rank by its `payout_split` weight share** (the new pure
  `economy.ex` `top_k_split/2`, §3.8.2 / V-15), emit the **one fat `revealed` event** (V-13, §6.6), then
  `settled`. The exactly-once discipline is the same lock.

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
- **The blind privacy widening (LIVE):** for a golden game (`feedback="none"`) **before** `revealed_ms`
  is set, the player-facing reads **withhold the score** — `my_history/3` returns `emojis` + `at_ms` but
  **not `points`**; `game_view/1`'s `totals.best`/`best_pct` and the leaderboard return **no score** (the
  channel carries `status` + timer only) — but `game_view/1` **does** carry the `commitment` from open (so
  the player records it for later verification, V-13). After `revealed_ms`, the golden reads return the
  score like classic (the contest is over; §3.8.1). This is a **policy branch on `feedback`/`revealed_ms`**
  inside the existing `view.ex` privacy module — not a new view. The `secret`/`nonce` are never selected by
  any player-facing read at any time until reveal exposes them for verification.
- **The reveal emission (V-13, LIVE):** at close the golden path emits **one fat `revealed` event** (not a
  stream of per-guess pushes) carrying the `secret` + `nonce` + `commitment` + the final board + the top-K
  payouts + the terminal `status` — the first and only results the blind client receives. The per-guess
  `scored` push is **suppressed in-flight** (§3.8.1); the `revealed` event is the single broadcast at the
  `revealing` transition.

### 6.7 The external wire (the cutover surface)
- HTTP routes `/rounds/:id…` → `/games/:id…`; PubSub topic `"round:" <> …` → `"game:" <> …`; channel
  `"round:*"` → `"game:*"`; the `round:` JSON/event keys → `game:`; `:no_round` → `:no_game`. (Sites
  enumerated in the Venus-1 brief §4.4–4.5 — the wire flips with the model.)

### 6.8 Settlement, notifier, scoring, economy, wallet, tests, demo
- **Player mint (`PLR`):** `wallet.ex`: `generate!("USR")` → `generate!("PLR")` (`wallet.ex:21`) + the
  `USR`→`PLR` doc-prose (`wallet.ex:19`). The `transactions.player` + `guesses.player` columns reference
  the new `PLR` id (no column rename — the value's brand changes, the column name stays).
- The `USR`→`PLR` doc-prose in `game.ex:6` (the moduledoc naming the player's lane by its `USR`) → `PLR`.
- `game.ex` `Codemojex.Settle`: `close_round` → `close_game`, the `round` bindings → `game`; **the sealed
  top-K pass** (§3.8.2) is the golden branch (`settlement="sealed"`) — a new pure `economy.ex`
  `top_k_split/2` over the ranked best `points` + the stored `games.payout_split` weights (V-15), paid
  inside the `cm:{game}:closed` one-shot; the `revealed` event (V-13) is emitted from the same close.
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

## 7. `Scoring.score/2`'s return + the `pct` on the wire (RULED — `percentage` computed-not-stored)

The as-built `Scoring.score/2` returns `%{total, max, percentage, tier, breakdown}` (`scoring.ex`).
`percentage` and `tier` were stored on `guesses` (now removed). **Director ruling:** `percentage` stays
**computed-not-stored** + the `tier` function and the `:tier` return key are **removed**:

- `score/2` still **returns** `percentage` — the live `pct` for the channel + the lobby progress bar —
  but **nothing writes it to a column** (zero stored `percentage`). The display sites read the computed
  value (the `scored` event's `pct`; `Economy.progress_pct/1` already does `best/600*100` for the lobby).
- `score/2` **drops** `tier` from the return; the `tier/1` function is **removed** from `scoring.ex`.

The model (the columns) carries **zero stored `percentage`/`tier`** either way; this ruling fixes the
in-memory return shape so the live `pct` survives without a stored column.

---

## 8. The from-scratch reinitialization strategy (fresh machine — collapse to one initial schema)

The machine is fresh and carries no prod data (Operator constraint #1), so the model ships as **one
clean initial create-migration**, not a rename + the two existing creates.

### 8.1 The migration (SIX tables — §0.2)
- **Collapse** `priv/repo/migrations/20260618000000_create_codemoji.exs` +
  `20260625000000_golden_rooms_and_notifications.exs` into **one** `create`-only migration standing up
  the **six** tables directly (no `notifications` table — §0.2): `create table(:players)` (with
  `tg_chat_id` + the non-negative CHECK) · `create table(:transactions)` · `create table(:emoji_sets)` ·
  `create table(:rooms)` (with `game` not `round`, `type`, `golden`/`gold_multiplier`, **`payout_split`
  default `[40,25,15,12,8]`**, **`cell_count` nullable**) · `create table(:games)` (with `type` + the four
  policy columns + **the four blind columns LIVE** (`commitment`/`nonce`/`revealed_ms`/`top_k` default
  `5`) + **`payout_split` default `[40,25,15,12,8]`** + **`cell_codes`** + `golden`/`gold_multiplier` +
  `secret` + the timer/fee props) · `create table(:guesses)` **without** `tier`/`percentage`. Indexes:
  `games(room)`, `guesses(game, player)`, `transactions(player, inserted_at)`, `players(tg_chat_id)`. **Two
  CHECKs ship in this create:** `games_type` (`type IN ('classic','golden')`) and **`games_status`**
  (`status IN ('scheduled','open','active','revealing','settling','settled','voided')`, V-8).
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

- **Story R-1 — the three brand re-bases (`GAM`/`ROM`/`PLR`).**
  *As the engine, the per-play entity is a `game`, the room a `ROM`, the player a `PLR` so the identities
  match the canon.*
  *Given* the renamed schema + the three mint sites; *When* a room is created, joined, and a game starts
  for a player; *Then* `generate!("ROM")` mints the room, `generate!("PLR")` mints the player,
  `generate!("GAM")` mints the game, `Codemojex.Schemas.Game` maps `schema "games"`, and the compile gate
  is clean.
  *Invariant INV-1:* exactly three brands change (`RND`→`GAM`, `RMM`→`ROM`, `USR`→`PLR`); the residual
  grep shows **0** `RND`/`RMM`/`USR` in `lib`+`test`; every remaining brand (`EMS`/`GES`/`JOB`/`NOT`/
  `CMD`/`TXN`) is byte-unchanged; `Kernel.round/1` + English "round" survive.

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

- **Story R-4 — Golden is the blind/sealed type, settled exactly once.** *(cm.3)*
  *As the platform, a Golden game runs blind and pays its boosted pool to the top scorers at the sealed
  close so the contest is provably fair and the promotion draws play.*
  *Given* `games.type="golden"`, `feedback="none"`, `settlement="sealed"`, `golden`/`gold_multiplier`,
  `top_k` (default 5), `payout_split`; *When* a golden game closes on the timer (golden never closes early
  — no per-guess signal); *Then* the sealed pass reveals secret+nonce (sets `revealed_ms`), ranks players
  by best linear `points`, `Economy.effective_pool/3` boosts the pool by `gold_multiplier`, the
  **top-`top_k`** split (V-15) pays rank `i` its weight share `payout_split[i]/Σ` inside the one-shot
  `SET NX` close, the **one fat `revealed` event** (V-13) is emitted, and a re-run pays identically.
  *Invariant INV-5:* settlement is applied once, at close, over the boosted pool; the close lock
  (`cm:{game}:closed`) makes the sealed pass exactly-once; the payout is a pure function of the ranked
  best `points` (idempotent).

- **Story R-7 — Golden is blind until reveal (commit-reveal + privacy).** *(cm.3)*
  *As a player in a Golden game, I get a commitment at the start and can verify the secret was fixed,
  while no score leaks until the reveal.*
  *Given* `games.type="golden"`, the four blind columns; *When* the game opens, a player guesses, and the
  game closes; *Then* at open `commitment = SHA-256(secret ‖ nonce)` (lowercase hex, V-14) is stored +
  exposable while `secret`/`nonce` stay server-side; **before `revealed_ms` no player-facing read returns
  any score** (no `scored` push, no `points` in `my_history`, no leaderboard score — `status`+timer only);
  at close `revealed_ms` is set and `secret`/`nonce`/`commitment` are exposed so the player recomputes
  `SHA-256(secret ‖ nonce)` == `commitment`.
  *Invariant INV-9:* `secret` + `nonce` are selected by **no** player-facing query until reveal; the
  commitment **binds** the server (the revealed secret recomputes to the stored commitment); the privacy
  gate is `feedback`/`revealed_ms`, not a per-call opt-in.

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

**Coverage:** the three brand re-bases (§0/§4/§6.1/§6.3/§6.8) → R-1; §3.5 `games` type/policy columns →
R-1, R-2; §3.6 `guesses` removals + §5 bonus-layer removal → R-3; §3.8.2 sealed top-K + `economy.ex` →
R-4 *(cm.3)*; §8 reinitialization → R-5; §6.7 wire → R-6; §3.8.1/§3.8.3 commit-reveal + privacy → R-7
*(cm.3)*. **The rung split:** R-1, R-2, R-3, R-5, R-6 are **cm.1** (the settled core + the three
re-bases + the schema with the blind columns present); R-4 + R-7 are **cm.3** (the blind flow on that
schema). Every deliverable maps to a story; completion is provable from the text.

---

## 10. The design Arms

Full four-part records (Rationale / 5W / Steelman / Steward) are in the ledger
`codemojex-game-rename.progress.md`.

### 10.1 RULED (folded into the design — do not re-litigate)

The first-pass forks, settled by the Operator + the Director (2026-06-24):

- **V-1 multi-type shape → Arm A + the `games_type` CHECK** (Director-ratified). One `games` table + a
  `type` discriminator + typed policy columns; `type IN ('classic','golden')` ships. (V-4 in the ledger.)
- **V-2 tier removal → Arm A, the strict reading: removed ENTIRELY** (Operator-ruled). No column, no
  recompute-on-read badge, no ladder. The `roadmap.md` B7.4.2 / B7.3 / `game_rules.md` tier text is
  `[RECONCILE]` (§11). (V-5 in the ledger.)
- **V-3 Golden depth → BLIND/SEALED, specified + built now** (Operator-ruled). §3.8 + §4 (the wire). (V-6 in the
  ledger.)
- **V-4 migration → Arm A: one clean initial create** (Director-ratified). §8. (V-4 ledger entry shares
  the slug; the migration arm.)
- **§7 `Scoring.score/2` → `percentage` computed-not-stored; `tier` fn + key removed** (Director-ratified).

### 10.2 RULED — the blind-mechanic Arms (D-15/D-16, 2026-06-25 — folded, do not re-litigate)

> The blind flow ships LIVE this scope (V-6 Arm B). The Operator ruled every open mechanic (ledger D-15
> PRODUCT/SCOPE + D-16 ENGINEERING SLATE). The rulings below are folded into §3.5/§3.8; the four-part
> records (Rationale / 5W / Steelman / Steward) are in the ledger under the cited V-n. **Where a ruling
> refined the mechanism beyond the architect's recommendation it is marked SUPERSEDES.** Nothing here is
> open; cm.3's contracts are fixed.

- **V-7 — scoring unification → RULED: ONE linear scoring function, both modes** (D-16, the Operator's
  HARD constraint). Blind settlement scores every `GES` with the same linear distance + ranks by best
  total; `architecture.md:59`'s "exact-match" is the rejected arm. The difference between modes is
  **feedback + settlement, not the scoring math.** (§3.8.2.)

- **V-8 — the state-machine shape → RULED: the full canon set, CHECK-bounded; classic terminal `settled`**
  (D-16). The `games_status` CHECK over the seven words ships (§3.5); classic `open → settled` (the
  as-built `closed` maps to `settled`), golden `open → revealing → settling → settled`, `voided` the
  abort (§3.8.5). The two sub-rulings are both closed: yes, bound with a CHECK; classic terminal is
  `settled`.

- **V-9 — the regulatory / age / region gating → RULED: a config SEAM, a launch-gate decision (NOT
  schema-shaping)** (D-16). A thin **eligibility predicate** consulted at join for a paid blind room (a
  region allowlist / age floor), the gating **data as room/app config, NOT a `games` column**, a
  permissive default so the engine builds + runs now. Recorded for the launch checklist; it does **not**
  gate the schema build. (`architecture.md:58`'s own framing.)

- **V-10 (specs-home) — RULED: mirror the emq pattern** — `docs/codemojex/specs/<rung>.{md,stories.md,
  llms.md}` + `specs/progress/` + `.registry.json` + a rollup dashboard; the rung-slug scheme is **`cm.N`**
  (this run uses the flat `codemojex-game-rename` scope ledger; §12 assumes `cm.N` for the spec triads).

- **V-14 (commitment scheme) — RULED: SHA-256(secret ‖ nonce), lowercase hex** (D-16). SHA-256 over a
  canonical UTF-8 encoding of the six secret codes joined by a record separator, then `‖ nonce`, emitted
  as lowercase hex (`:crypto.hash(:sha256, …)`, zero new dependency). A per-cell commitment (leaks the
  secret's structure) and an HMAC with a server key (the keyed secret cannot be published for the player
  to recompute — breaks verifiability) are the rejected arms. **The byte-pinned encoding is the
  deliverable** (so a client recomputes identically); `games.commitment` is a `string`. (§3.8.3.)

- **V-15 (sealed top-K payout) — RULED: `top_k` DEFAULT 5 + a configurable `payout_split` weight array**
  (D-15). **SUPERSEDES** the first-pass recommendation of a *computed* monotone rank-weight curve. The
  split is the ordered integer array `rooms.payout_split` (default `[40,25,15,12,8]`) **snapshotted to
  the game** (`games.payout_split`); the sealed settlement ranks every guess linearly and pays rank `i` of
  the top-`top_k` its share `payout_split[i] / Σ payout_split` of `Economy.effective_pool/3`. A new pure
  `economy.ex` `top_k_split/2` (the seam beside `winner_take_all/2` + `proportional/2`). Winner-take-all
  (makes `top_k` vestigial) and a fraction-of-field `top_k` (couples the prize to turnout) are the
  rejected arms. **NEW columns** `games.top_k` (default `5`), `games.payout_split`, `rooms.payout_split`.
  (§3.4 / §3.5 / §3.8.2.)

- **V-16a (reduced set) — RULED: room `cell_count` (N, nullable) + a per-game randomized `games.cell_codes`
  snapshot** (D-15). **SUPERSEDES** the first-pass recommendation of a fixed 24-cell `EMS` row. `null`
  `cell_count` = the full room cell set (= classic today); at `start_game` the game snapshots
  `Enum.take_random(EMS.codes, N)` into `games.cell_codes`, and the secret draws its six from **that**
  snapshot. The `EMS` row stays the **full** keyboard (the seed §3.3.1). A smaller `EMS` row and a per-game
  `games.symbols` subset column are both superseded. **NEW columns** `rooms.cell_count`, `games.cell_codes`.
  (§3.4 / §3.5 / §3.8.4.)

- **V-16b (anonymized leaderboard) — RULED: DEFER to the `RMP` rung** (D-15). The board push carries
  `{player_id, score}` now; the wire shape is authored to accept `{alias, score}` later (the `RMP` rung
  supplies the alias without a wire break). The reveal-gated privacy (no score until reveal, §3.8.1)
  already secures the blind contest. (§3.8.6.)

### 10.3 The "as described" grounding for blind-mode (what is on disk vs what is flagged)

- **Specified on disk (grounded, cited in §3.8):** feedback `none` + the no-leak privacy rule
  (`architecture.md` / `roadmap.md` B7.1.3); sealed settlement, one pass, top-K (`architecture.md` /
  `specs.md:47`); commit-reveal over secret+nonce, hiding + binding, verify at close (`architecture.md`
  "Provably-fair secret" / `specs.md:53–56`); the reduced set (`specs.md:46` / `architecture.md:14`); the
  state machine (`specs.md:36`).
- **Flagged grounding GAPS (designed-around, NOT invented — §3.8.6):** the `BNK` bank + the rake (top-K
  pays from `prize_pool` as-built; no bank/rake column); the anonymized leaderboard alias (deferred to
  `RMP`, V-16b; ranks by `PLR` until built — the reveal-gated privacy already secures the blind contest);
  the `SES` session / verified `initData` (out of scope, bears on V-9).
- **The open questions the canon left — now RULED (D-15/D-16):** scoring unification (V-7, linear);
  the commitment scheme (V-14, SHA-256 lowercase hex); the top-K payout (V-15, `top_k` 5 + a stored
  `payout_split` array); the reduced set (V-16a, room `cell_count` + per-game `cell_codes` snapshot); the
  anonymized alias (V-16b, deferred to `RMP`); the state machine (V-8, CHECK-bounded, classic terminal
  `settled`). No mechanic remains a build-time guess.

---

## 11. Boundary + the one `[RECONCILE]` the canon owes

- **Edits production code: none.** This is the design; Mars builds it after the rulings.
- **Brands re-based (Stage-2):** `RND`→`GAM`, `RMM`→`ROM`, `USR`→`PLR`. **Brands not renamed:**
  `EMS`/`GES`/`TXN`/`JOB`/`NOT`/`CMD`. The acceptance is the residual grep to **0** `RND`+`RMM`+`USR` in
  `lib`+`test` (and 0 `RMM`+`RND` in `docs/codemojex`).
- **Systems not modeled here** (their brands + tables land with them, per the roadmap): the bank
  (`BNK`), membership (`RMP`), sessions (`SES`), commerce (`PKG`/`ORD`/`OTX`/`WHK`), growth (`SHR`),
  analytics (`AEV`), the reified resource (`RSC`). This model is the **game-engine core** (games +
  guesses + the type/policy abstraction + the linear-only scoring + the blind-mode commit-reveal/sealed
  flow), on the as-built brand floor (now `GAM`/`ROM`/`PLR`/`EMS`/`GES`/`TXN`/`JOB`/`NOT`/`CMD`). The
  blind mode's bank/membership/session dependencies are **flagged grounding gaps** (§3.8.6),
  designed-around — the flow runs without them.
- **`[RECONCILE]` the canon owes (a follow-up rung, not built here):** `roadmap.md` B7.4.2 ("the uniform
  twenty-point gaps form thirty tiers, the live leaderboard's ladder") + B7.3 ("tier claims") +
  `game_rules.md` ("Future Game Extension: Tiers", the whole §) still TEACH the removed bonus-tier
  mechanic. After the build, a canon reconcile aligns them to the linear-only model. Recorded so the
  drift is a tracked debt, not an oversight.
- **Out of bounds entirely:** `docs/codemojex/codemoji-updated/` + the zip (stale extract); the
  Operator's pre-staged `docs/echo/bcs/bcs.progress.md`.

---

## 12. The spec-driven rung ladder + the founding-rung triad

The Operator ruled the build **spec-driven** ("bootstrap with a specs for the upfront rungs"). This
section proposes the **codemojex specs home** (Arm V-10 → mirror emq), reconciles the roadmap's B7.1–B7.6
into a **build-ready rung ladder**, and authors the **founding rung's triad** (the settled core, buildable
first). The later rung triads fan out afterward — the structure is recommended here, not every triad
authored.

### 12.1 The specs home (Arm V-10 → Arm A)

```
docs/codemojex/specs/
  cm.1.md  cm.1.stories.md  cm.1.llms.md      -- the founding rung: schema + 3 brand re-bases + classic
  cm.3.md  cm.3.stories.md  cm.3.llms.md       -- blind Golden (body authored §12.4; all mechanics RULED, D-15/D-16)
  progress/
    cm.1.progress.md  cm.1.registry.json       -- per-rung aaw ledgers (or the flat scope ledger for this run)
    …
```

> **This run's scope ships BOTH cm.1 and cm.3** (D-10: the blind flow is LIVE). cm.2 (a classic-hardening
> split) is no longer a separate planned rung — it folds into cm.1. The two authored bodies are cm.1
> (settled core + the three re-bases) and cm.3 (the blind flow); the cm.3 contracts are now fixed — every
> §10.2 Arm is RULED (D-15/D-16).

The rollup dashboard is `docs/codemojex/codemojex.specs-progress.md` (or the existing
`codemojex.progress.md` reused as the rollup — a Director call). The single rung ladder stays
`codemojex.roadmap.md`. **Slug scheme `cm.N`** (V-10 sub-ruling — a clean spec-rung namespace distinct
from the course chapter `B7.x`, which teaches the built game).

### 12.2 The rung ladder (reconciled from roadmap B7.1–B7.6)

Each rung is scoped, gated, sequenced. The gate ladder is the codemojex app gate: `TMPDIR=/tmp mix
compile --warnings-as-errors` + `TMPDIR=/tmp mix test` (+ `--include valkey` for the bus/wire rungs, with
`valkey-cli -p 6390 ping` → `PONG` and Postgres up), plus the fresh-schema reinitialization (§8) on the
rung that lands the schema.

| Rung | Scope | Builds on | Gates on | Status |
|---|---|---|---|---|
| **cm.1 — the founding core** | the fresh six-table schema (§3) **with the four blind columns + `cell_codes` + `payout_split` present** + `GAM`/`ROM`/`PLR` (the **three** brand re-bases) + the type/policy discriminator + the `games_type` + `games_status` CHECKs + **linear scoring, tier removed** + the round→game rename (code + wire) + the **reinitialization** (§8). **Classic live mode end-to-end.** | the as-built floor | compile + `--include valkey` green on the fresh schema; the residual-grep proof (0 `RND`/`RMM`/`USR`/`tier`/`percentage`); both CHECKs exercised | **body authored (§12.3); BUILD-GRADE — the settled core depends on no open fork** |
| **cm.3 — blind Golden** | feedback `none` + privacy withholding (§3.8.1); the commit-reveal columns + flow, SHA-256(secret‖nonce) lowercase hex (§3.8.3 / V-14); sealed top-K settlement from `prize_pool` by the stored `payout_split`, `top_k` 5 (§3.8.2 / V-15); the room `cell_count` + per-game `cell_codes` reduced-set wiring (§3.8.4 / V-16a); the one fat `revealed` event (§6.6 / V-13); the `revealing`/`settling` states (§3.8.5 / V-8). | cm.1 | the cm.1 gate + the blind-flow stories (R-4, R-7) + the privacy/fairness/idempotency probes | **body authored (§12.4); all mechanics RULED (D-15/D-16); builds this scope** |
| **cm.4+ — the deferred systems** | the `BNK` bank + rake, `RMP` membership + the anonymized leaderboard, `SES` sessions / verified `initData`, commerce, growth, analytics (roadmap B7.5/B7.6 + beyond). | cm.1–cm.3 | per-system gates | out of this design's scope; named in the roadmap |

> **Why cm.1 is the settled core and cm.3 is the flow on it.** cm.1's scope is **entirely the settled
> core** (§10.1) — the fresh schema (with the blind columns + `cell_codes` + `payout_split` *present*,
> inert for classic), the three brand re-bases, the tier removal, classic live mode. cm.3 is the blind
> **flow** on that same schema: it writes the blind columns + `cell_codes` and runs the sealed pass, and
> its contracts (SHA-256 commit-reveal, the stored `payout_split`, the `cell_count` snapshot, the state
> words) are now **all RULED** (§10.2, D-15/D-16) — no `[RULE]`-pending fork remains. Both ship this scope
> (D-10); the spec ladder is the sequencing.

### 12.3 The founding-rung triad — cm.1 (authored; Stage-2 widens it to three brands)

The triad's three files live under `docs/codemojex/specs/` (authored the first pass, **extended this run**
to bring `RMM`→`ROM` + `USR`→`PLR` IN and the blind columns LIVE-but-inert-for-classic). Their contracts
(the body authoritative; stories + brief derive):

**`cm.1.md` — the spec body.** Deliverables: D1 the fresh **six-table** schema (§3, all columns incl. the
four blind-mode columns + `cell_codes` + `payout_split`, **`NULL`/inert for classic** — golden writes the
blind columns in cm.3; `cell_codes` snapshots the full set + `payout_split`/`top_k` default for a classic
game) via one clean initial create (§8) with **both** the `games_type` and `games_status` CHECKs; D2 the
**three brand re-bases** (`round`→`game`/`RND`→`GAM` across code + wire per §6 + the Venus-1 brief §4;
`RMM`→`ROM` at `rooms.ex:18`; `USR`→`PLR` at `wallet.ex:21` — §6.1/§6.3/§6.8); D3 the type/policy
discriminator + the `games_type` CHECK (classic defaults); D4 linear scoring as the sole score + rank,
**tier + percentage removed** (§3.6, §5, §7); D5 the reinitialization (drop+recreate `codemojex_dev` +
`codemojex_test`, §8). Invariants: INV-1 exactly three brands change, residual grep 0 `RND`/`RMM`/`USR`;
INV-2 the `games_type` CHECK rejects an unknown type; INV-3 `Scoring.score/2` stays linear, purity
preserved; INV-4 `players.bonus_diamonds` kept; INV-6 no data migration / no rebrand step; INV-7 no caller
left at the old name + the privacy invariant holds; INV-8 the four blind columns exist and are `NULL` for a
created classic game. Every public call cites a real module or a canon §; no invented surface.

**`cm.1.stories.md` — acceptance.** The Given/When/Then for D1–D5, derived from §9's stories R-1 (the
three re-bases), R-2 (type/policy, classic exercised), R-3 (linear-only), R-5 (reinit), R-6 (wire); R-4 +
R-7 (the blind flow) are cm.3. Each story names its INV; a Coverage line maps every deliverable → its
story. A gate specifies its own liveness (the residual-grep MUST run and show zero `RND`/`RMM`/`USR`/
`tier`/`percentage`; the `--include valkey` suite MUST exercise the renamed wire end-to-end; the
`games_type` CHECK MUST be exercised by a rejected insert).

**`cm.1.llms.md` — the build brief.** References (this design §3/§6/§8 + the Venus-1 brief §4 for the
token-class rename map + the real module surface); Requirements (numbered, each traced to a story +
forward to an INV); Execution topology (the build-order DAG: schema rename + columns → store/cache/tables
→ lifecycle (the 3 mints) → score authority + board + view → wire → the one clean migration → reinitialize
→ gate) + the exact files touched (§6); Agent stories (Directive + Acceptance gate, contract form). The
brief leaves no decision the spec has not fixed — the settled core has no open fork.

### 12.4 The blind-Golden triad — cm.3 (body authored §12.4 ⇒ `cm.3.md`)

The blind flow ships LIVE (D-10), so its body is authored this run as `docs/codemojex/specs/cm.3.md`
(VenusPG owns it per the Stage-2 charter). Its contracts derive from §3.8 and are **fixed — every §10.2
Arm is RULED (D-15/D-16)**; the body now states each mechanic as a contract, not a `[RULE]`-pending default:

**`cm.3.md` — the spec body.** Deliverables: G1 feedback `none` + the privacy withholding (§3.8.1 — no
score leaks before `revealed_ms`; the `view.ex` policy branch) + the one fat `revealed` event at close
(§6.6, V-13); G2 commit-reveal — `commitment` at open, `secret`+`nonce` sealed, reveal+verify at close
(§3.8.3; the scheme = **SHA-256(secret‖nonce) lowercase hex**, V-14); G3 sealed top-K settlement from
`prize_pool` inside the one-shot close (§3.8.2; the split = the **stored `payout_split` weight array**,
`top_k` 5, V-15); G4 the reduced-set wiring (§3.8.4; the mechanism = **room `cell_count` + the per-game
randomized `games.cell_codes` snapshot**, V-16a); G5 the `revealing`/`settling` states (§3.8.5; the
state-machine shape = **the CHECK-bounded 7 words, classic terminal `settled`**, V-8). Invariants: INV-5
the sealed pass is exactly-once + idempotent (the `cm:{game}:closed` `SET NX` + the pure ranked split);
INV-9 `secret`+`nonce` selected by no player-facing query until reveal, the commitment binds the server.
Grounding: every mechanic cites §3.8 → the canon line; the three flagged gaps (`BNK`/`RMP`/`SES`, §3.8.6)
are designed-around, never invented.

**`cm.3.stories.md` / `cm.3.llms.md`** derive from §9's R-4 + R-7 and this body — the
scoring/scheme/split/reduced-set/state contracts are now fixed by the rulings, so the derived files are
authored without a guess. (The body is the authoritative contract; the stories + brief follow it.)

> The spec ladder: **cm.1 is the settled core**; **cm.3's body is authored with every mechanic RULED**
> (§10.2, D-15/D-16) — the cm.3 stories + brief derive directly, then cm.3 builds. Both rungs ship this
> scope (D-10). No `[RULE]`-pending fork remains in either body.

---

*Authored by Venus-PG (architect), Stage-2 extension + Stage-2 convergence (2026-06-25). The model is
grounded entirely on disk — every table, column, brand, policy word, blind-mode rule, and rung scope cites
a real schema, migration, or canon doc; the EMS seed is measured from the two real sprite sheets (§3.3.1);
the three flagged grounding gaps (§3.8.6) are designed-around, never invented. The convergence folded the
D-15/D-16 rulings (the stored `payout_split` + `top_k` 5; the room `cell_count` + per-game `cell_codes`
snapshot; the CHECK-bounded `status`; SHA-256 commit-reveal; the one fat `revealed` event; one linear
scoring fn; kept wire words + FK columns; deferred alias) — **no `[RULE]`-pending fork remains**. The
Stage-2 reconcile corrected two facts to disk (six Postgres tables, not seven; `codemojex_dev`/
`codemojex_test`, not `codemoji_game`). No production code was edited. cm.1 (the settled core + the three
brand re-bases)
builds from §3/§6/§8/§12.3; cm.3 (the blind flow) builds from §3.8/§12.4 once the §10.2 Arms are ruled.
The Director ratifies; the Operator accepts.*
