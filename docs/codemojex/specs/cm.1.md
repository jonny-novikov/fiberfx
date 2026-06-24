# cm.1 — The Founding Core: fresh schema · the `GAM` game entity · linear-only scoring

> **The founding rung of the Codemojex game-engine build.** The settled core: a from-scratch Ecto
> schema, the **three brand re-bases** (`round`/`RND`→`game`/`GAM`, room `RMM`→`ROM`, player `USR`→`PLR`),
> the type/policy discriminator (with classic exercised), linear scoring as the sole score (the bonus-tier
> economy removed), and the reinitialization of the dev + test DBs. **This rung depends on no open fork —
> it is build-grade now.** The four blind columns ship **present-but-inert** on the schema (golden writes
> them in cm.3); the blind/golden **flow** is rung **cm.3** (its mechanics ride Arms V-7/V-8/V-10/V-11/V-12).
>
> **Stage-2 (2026-06-24):** the Operator folded the `RMM`→`ROM` + `USR`→`PLR` re-bases INTO this rung
> (were OUT in the first pass) and ruled the blind flow LIVE this scope. This body reflects both.
>
> **Source of truth:** this body is authoritative; `cm.1.stories.md` (acceptance) and `cm.1.llms.md`
> (the build brief) derive from it. When a derived file disagrees, this body wins.
>
> **Design canon:** `docs/codemojex/codemojex.game-model.design.md` (the model — §3 schema, §6 code
> wiring, §8 reinitialization, §12 the rung ladder). The token-class rename map is the Venus-1 brief
> `docs/codemojex/codemojex-game-rename.brief.md` §4. The forward product canon is
> `codemojex.architecture.md` / `codemojex.roadmap.md` / `codemojex.specs.md`.
>
> **Framing discipline (propagate):** no gendered pronouns for agents; no perceptual or interior-state
> verbs (sees / wants / notices); no first-person narration. State surfaces as contracts.

---

## 1. The goal (one paragraph)

Codemojex's per-play entity is **a game** (`GAM`) — the canon says so; the live code, the Postgres floor,
the cache, and the wire still say `round`/`RND`. This rung makes the running system agree with its canon
**and** lands the new model's settled core: a fresh schema with a **type/policy discriminator** (so a new
game mode is configuration, not new code), **linear scoring as the sole score and leaderboard rank** (the
first-mover bonus-tier economy removed), and a **from-scratch reinitialization** of the dev DB (the
machine is fresh — no rename migration, no data migration). Classic live mode plays end-to-end on the new
model; blind Golden (cm.3) lands additively on the same schema.

---

## 2. Scope — IN and OUT

**IN (this rung):**
- The fresh Ecto schema (design §3): the **six** Postgres tables (design §0.2 — no `notifications`
  table; `NOT` is a Valkey lane), `rounds`→`games`/`GAM`, the type/policy columns, the four blind-mode
  columns **present-but-nullable** (LIVE-but-inert for classic, so cm.3 needs no migration), `guesses`
  **without** `tier`/`percentage`, `players` with `tg_chat_id`. One clean initial create-migration
  (design §8).
- **The three brand re-bases** (design §0/§6): `round`→`game`/`RND`→`GAM` across code + the external wire
  (design §6 + Venus-1 brief §4); room `RMM`→`ROM` at the mint (`rooms.ex:18`); player `USR`→`PLR` at the
  mint (`wallet.ex:21`). The brand string at `generate!` + the cache `kind:` + the doc-prose tokens are
  the rename surface; the schema **module** names (`Room`/`Player`) are not brand-coupled and stay.
- The `games_type` CHECK (`type IN ('classic','golden')`); classic policy defaults snapshotted at start.
- Linear scoring as the sole score + rank; the bonus-tier economy removed (design §3.6, §5, §7).
- The dev + test DB reinitialization (drop + recreate `codemojex_dev` + `codemojex_test`; design §8).
- Classic live mode end-to-end (the as-built live flow on the renamed model).

**OUT (later rungs):**
- The blind/golden mode **flow** (feedback `none`, commit-reveal, sealed top-K, reduced set, the
  `revealing`/`settling` states) — **cm.3** (the blind columns ship here *present*; the *flow* that writes
  them is cm.3). cm.3 ships this scope (D-10); its mechanics ride Arms V-7/V-8/V-10/V-11/V-12.
- The `BNK` bank + rake, `RMP` membership + anonymized leaderboard, `SES` sessions / verified `initData`,
  commerce, growth, analytics — cm.4+ (named in the roadmap).
- The `roadmap.md` / `game_rules.md` tier-text `[RECONCILE]` (a follow-up after the build).

---

## 3. Deliverables (each traced to a story §`cm.1.stories.md` and an invariant §5)

- **D1 — the fresh schema, one clean initial create.** The **six** Postgres tables per design §3 (§0.2:
  no `notifications` table), collapsed from the two existing migrations into one `create`-only migration
  (design §8). The `games` table carries the type/policy columns + the four blind-mode columns
  **nullable** (LIVE-but-inert for classic). `guesses` has **no** `tier`/`percentage`. Indexes:
  `games(room)`, `guesses(game, player)`, `transactions(player, inserted_at)`, `players(tg_chat_id)`. The
  `games_type` CHECK ships in this create. → Story R-1, R-5.
- **D2 — the three brand re-bases.** (a) the `GAM` game entity: `round`→`game` / `RND`→`GAM` across the
  code surfaces (design §6) and the external wire (routes `/games`, topic/channel `game:`, the `game:`
  keys, `:no_game`). (b) room `RMM`→`ROM`: `generate!("ROM")` at `rooms.ex:18` + the doc-prose at
  `rooms.ex:14`. (c) player `USR`→`PLR`: `generate!("PLR")` at `wallet.ex:21` + the doc-prose at
  `wallet.ex:19` / `game.ex:6`. The token-class discipline (design §6 note + Venus-1 brief §4): rename
  only the entity/api/wire/brand tokens; leave `Kernel.round/1`, `Math.round`, and English "round". The
  schema module names (`Room`/`Player`) stay (not brand-coupled). → Story R-1, R-2, R-6.
- **D3 — the type/policy discriminator + the CHECK.** `games.type` (+ `rooms.type`) + the four policy
  columns (`feedback`/`scoring`/`settlement`/`economy`), snapshotted from the room's type at
  `start_game`; the `games_type` CHECK (`type IN ('classic','golden')`). Classic defaults:
  `type="classic"`, `feedback="score"`, `scoring="linear"`, `settlement="live"`,
  `economy="winner_take_all"`. → Story R-2.
- **D4 — linear scoring is the sole score; the bonus-tier economy removed.** Drop `guesses.tier` +
  `guesses.percentage`; remove the Valkey bonus layer (`cm:{game}:ptier`/`bonus`/`tierfirst`),
  `Board.record/4`→`record/3`, `Board.firsts/2`, the `scored` event's `tier`/`first` fields; the
  leaderboard ranks the player's **best linear `points`**. `Scoring.score/2` stays the linear engine; the
  `tier/1` function + the `:tier` return key removed; `percentage` **computed-not-stored** (design §7). →
  Story R-3.
- **D5 — the reinitialization.** Drop + recreate `codemojex_dev`, migrate the one clean initial schema
  (design §8). No data migration, no `RND`→`GAM` rebrand (a fresh DB mints `GAM` from the renamed code).
  → Story R-5.

---

## 4. Grounding (NO-INVENT — every claim cites a real artifact)

- The schema columns: design §3 (each grounded in `schemas/*.ex` + the two migrations).
- The rename sites: design §6 + the Venus-1 brief §4 (every `file:line` re-found on disk).
- The bonus-tier economy removed: `board.ex` (`record/4`, `claim_tier`, the `ptier`/`bonus`/`tierfirst`
  hashes, `firsts/2`), `game.ex` (`ScoreWorker` `put_guess` map + the `scored` event), `scoring.ex`
  (`tier/1`, the `:tier`/`:percentage` return keys), `schemas/guess.ex` (the `tier`/`percentage` fields).
- The reinitialization: `config/dev.exs:14` (`codemojex_dev`), `config/test.exs:19` (the test DB), design
  §8.
- Classic live mode: the as-built `rooms.ex` / `game.ex` / `view.ex` / `board.ex` flow (unchanged in
  behavior beyond the rename + the bonus removal).

**The master invariant:** the `GAM` brand is the entity's type, checked at every boundary; the rename
re-bases `RND`→`GAM` everywhere the identity travels (the key builder, the table, the cache `kind`, the
wire), and nowhere else. A blind `s/round/game/` is forbidden (it corrupts `Kernel.round/1` + English).

---

## 5. Invariants (the code-asserting contract Apollo + the Director verify)

- **INV-1 — brands.** Exactly **three** brands change (`RND`→`GAM`, `RMM`→`ROM`, `USR`→`PLR`); the
  residual grep shows **0** `RND`/`RMM`/`USR` in `lib`+`test`. Every remaining brand is **byte-unchanged**:
  `EMS`/`GES`/`TXN`/`JOB`/`NOT`/`CMD`. `Kernel.round/1` + English "round" survive.
- **INV-2 — the type CHECK.** The `games_type` CHECK rejects an `INSERT`/`UPDATE` with a `type` outside
  `{classic, golden}`.
- **INV-3 — linear purity.** `Scoring.score/2` stays the linear engine (`points(d)=100-20*d` summed to
  600); a re-delivered guess re-scores identically (purity).
- **INV-4 — the wallet bucket.** `players.bonus_diamonds` is **kept** (a wallet bucket, not a game tier;
  design §3.7).
- **INV-5 — no stored tier/percentage.** `guesses` has no `tier`/`percentage` column; the leaderboard
  ZSET ranks raw best `points` (no `base + bonus`); `cm:{game}:ptier`/`bonus`/`tierfirst` do not exist.
- **INV-6 — fresh reinitialization.** No data migration + no `RND`→`GAM`/`RMM`→`ROM`/`USR`→`PLR` rebrand
  step exists (a fresh DB mints the new brands from the renamed code); the dev + test DB drop
  (`codemojex_dev`/`codemojex_test`, design §8) runs only when the model is ready.
- **INV-7 — no broken caller + privacy.** No caller of a renamed symbol is left at the old name (the
  compile gate proves it); no player-facing view selects `secret`; no view returns another player's
  guesses.
- **INV-8 — blind columns present, inert.** The four blind-mode columns (`commitment`, `nonce`,
  `revealed_ms`, `top_k`) exist on `games` and are **`NULL` for every classic game** — present so cm.3
  needs no migration, inert until cm.3 wires them.

---

## 6. The gate (what closes this rung)

1. `cd echo/apps/codemojex && TMPDIR=/tmp mix compile --warnings-as-errors` → clean (an over-rename of a
   BIF or a missed caller fails to compile).
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres up; the dev/test DB reinitialized (design §8);
   `TMPDIR=/tmp mix test --include valkey` → green (the renamed `rooms_and_games` / `settlement` /
   `privacy` stories exercise the renamed wire end-to-end on the fresh schema).
3. **Residual-grep proof** (the three brands + the entity/api/wire migrated; the bonus economy gone; the
   BIF/English untouched). Two greps:
   - the three brands: `/usr/bin/grep -rnoE '\b(RND|RMM|USR)\b' echo/apps/codemojex/lib echo/apps/codemojex/test` → **0**.
   - the entity/api/wire/bonus tokens: `/usr/bin/grep -rniE '\b(round_view|:cm_rounds|"round:"|/rounds|:no_round|Schemas\.Round|guesses?\.tier|\.percentage|tierfirst|claim_tier|firsts)\b' echo/apps/codemojex/lib echo/apps/codemojex/test` → **0**.
   - while `Kernel.round`/`round(` survives in `scoring.ex`/`economy.ex` (the BIF) — the grep is carved to
     spare it (the brand grep is word-boundaried `\bRND\b`, not a substring; the entity grep targets the
     symbols, not `round(`).
4. The `games_type` CHECK is present (a migration assertion or a rejected-insert test exercises INV-2).
5. The four blind-mode columns exist and are `NULL` for a created classic game (INV-8).

4'. The dev + test DBs are reinitialized clean from the one migration (design §8) — `MIX_ENV=test mix
   ecto.drop && ecto.create && ecto.migrate` comes up green; the migration's `up` then `down` is proven
   on the test DB (the HIGH-risk migration up/down gate).

> A gate specifies its own liveness: both residual-greps MUST run and show zero; the `--include valkey`
> suite MUST exercise the renamed wire (not a no-op skip); the CHECK MUST be exercised by a
> rejected-insert (a present `type` outside the set is a LOUD failure); the migration up/down MUST run on
> the test DB (a present DB, not a skip).

---

## 7. Out-of-scope guardrails (do not touch)

- No blind/golden **flow** (cm.3). The four blind columns land **present but inert** (nullable, written by
  no classic path); cm.3 wires them.
- No `BNK`/`RMP`/`SES`/commerce/growth/analytics systems.
- No edit to `roadmap.md` / `game_rules.md` tier text (the `[RECONCILE]` follow-up).
- No `git`; the Director commits by pathspec. Per-app testing only (the codemojex app dir).
- `TMPDIR=/tmp` for all `mix`.

---

*Authored by Venus-PG (architect). The body is authoritative; the stories + brief derive. Mars builds
from `cm.1.llms.md`; the Director ratifies; the Operator accepts. Grounded entirely on disk; no production
code edited in authoring this triad.*
