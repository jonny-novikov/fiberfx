# cm.1 — Stories (acceptance, Given/When/Then)

> The Operator's acceptance face of `cm.1.md`. Each Deliverable (D1–D5) becomes a user story
> (Connextra form) with concrete Given/When/Then criteria; each names the invariant(s) it exercises; a
> Coverage line maps every Deliverable → its story. Derived from `cm.1.md` (the body authoritative) and
> the design doc §9 (the classic-mode subset of stories R-1..R-6). When this disagrees with the body,
> the body wins.
>
> **Framing discipline:** no gendered pronouns for agents; no perceptual / interior-state verbs; no
> first-person narration. State surfaces as contracts.

---

## Story S-1 — the fresh schema lands from scratch (D1, D5)

*As an operator, a fresh machine comes up on the new schema with no migration archaeology, so the model
is reinitialized cleanly rather than migrated.*

- **Given** the one clean initial create-migration (design §8) and a fresh `codemojex_dev`.
- **When** `TMPDIR=/tmp mix ecto.drop && mix ecto.create && mix ecto.migrate` runs.
- **Then** the DB comes up with: `games` (the type/policy columns + the four **nullable** blind-mode
  columns + `secret`), `rooms.game` (not `round`) + `rooms.type`, `guesses` **without** `tier`/`percentage`,
  `players.tg_chat_id`, and the indexes `games(room)` / `guesses(game, player)` /
  `transactions(player, inserted_at)` / `players(tg_chat_id)`.
- **And** the `--include valkey` suite is green against the fresh schema.
- **Invariants:** INV-6 (no data migration / no rebrand step); INV-8 (the blind columns exist, `NULL` for
  classic).

---

## Story S-2 — the per-play entity is `games`/`GAM` (D2)

*As the engine, the per-play entity is a `game` so its identity matches the canon at every boundary.*

- **Given** the renamed schema + key builder.
- **When** a room is joined and a game starts.
- **Then** `EchoData.BrandedId.generate!("GAM")` mints a `GAM…` id; `Codemojex.Schemas.Game` maps
  `schema "games"`; `Repo.get(Game, id)` resolves; the compile gate is clean.
- **And** the residual-grep shows **zero** `RND` / `round_view` / `:cm_rounds` / `Schemas.Round` in
  `lib` + `test`, while `Kernel.round`/`round(` survives in `scoring.ex`/`economy.ex`.
- **Invariants:** INV-1 (every other brand byte-unchanged); INV-7 (no caller left at the old name — the
  compile gate proves it).

---

## Story S-3 — the wire flips with the model (D2)

*As a client, a game is reached at `/games/:id` and on the `game:` topic, so the external surface speaks
the entity's name.*

- **Given** the renamed routes / topic / channel / keys.
- **When** `GET /games/:id` is called and a client joins `game:<id>`.
- **Then** the view returns (never the secret); for a classic game a `scored` push arrives carrying
  `game`/`player`/`pct`/`eff` (**no `tier`, no `first`**); the `--include valkey` stories exercise the
  renamed wire end-to-end.
- **And** the residual-grep shows **zero** `"round:"` / `/rounds` / `:no_round` in `lib` + `test`.
- **Invariants:** INV-7 (no broken caller; the privacy invariant holds — no view selects `secret`, no
  view returns another player's guesses).

---

## Story S-4 — the engine carries a type + four policies (D3)

*As the engine, a game declares its type and policies so a new mode is configuration, not new code.*

- **Given** the `games.type` + `feedback`/`scoring`/`settlement`/`economy` columns + the `games_type`
  CHECK.
- **When** a classic room starts a game.
- **Then** the game records `type="classic"`, `feedback="score"`, `scoring="linear"`,
  `settlement="live"`, `economy="winner_take_all"`, snapshotted from the room at start and immutable for
  the game's life.
- **And** an attempt to write a `type` outside `{classic, golden}` is **rejected** by the CHECK (a LOUD
  failure, exercised by a rejected-insert).
- **Invariants:** INV-2 (the CHECK rejects an unknown type).

---

## Story S-5 — linear scoring is the sole score; no bonus tiers (D4)

*As a player, the leaderboard ranks by the best linear score, so there is no hidden tier bonus.*

- **Given** the removed `guesses.tier`/`percentage` columns + the removed Valkey bonus layer.
- **When** a guess scores total `T` and reaches the board (classic mode).
- **Then** `guesses` stores only `points = T` (no `tier`, no `percentage`); the `cm:{game}:board` ZSET
  ranks the player at their best `T` (**not** `T + bonus`); `cm:{game}:ptier`/`bonus`/`tierfirst` do not
  exist; `Board.firsts/2` is gone; the `scored` event carries no `tier`/`first`.
- **And** `Scoring.score/2` returns the linear total (`points(d)=100-20*d` summed to 600); a re-delivered
  guess re-scores identically; `percentage` is computed-not-stored (the live `pct`) and the `tier/1`
  function is removed.
- **And** `players.bonus_diamonds` is **unchanged** (a wallet bucket, not a game tier).
- **Invariants:** INV-3 (linear purity); INV-4 (the wallet bucket kept); INV-5 (no stored
  tier/percentage; the board ranks raw best).

---

## Story S-6 — the blind columns are present and LIVE for golden (D1)

> **RECONCILED (T-12 / V-6 Arm B).** The Operator overruled the prior "inert until cm.3" plan: the
> blind/sealed Golden mode ships **live this rung**. For a **classic** game the four columns are `NULL`;
> for a **golden** game they are populated and drive the blind flow (S-9). VenusPG owns the columns; the
> blind WIRE behavior is S-9.

*As the engine, the blind-mode columns exist on `games` and are populated for a golden game, so the
sealed mode runs from this rung — `NULL` for classic, set for golden.*

- **Given** the fresh schema with `commitment`, `nonce`, `revealed_ms`, `top_k` on `games` (nullable).
- **When** a **classic** game is created / a **golden** game is created.
- **Then** classic: all four columns `NULL`, no classic path reads them. Golden: `commitment` + `nonce`
  set at open (`revealed_ms` null until close, `top_k` set from the room's policy).
- **Invariants:** INV-8 (the blind columns exist, `NULL` for classic, set for golden).

---

## Story S-7 — the room brand re-bases to `ROM` (brand-only) (extension axis, brief §10.1)

*As the room system, the room brand is `ROM` so its identity matches the canon — a pure brand swap at the
mint site, the word `room` unchanged everywhere.*

- **Given** the as-built room mint `EchoData.BrandedId.generate!("RMM")` (`rooms.ex:18`).
- **When** a room is created.
- **Then** `generate!("ROM")` mints a `ROM…` id; `/usr/bin/grep -rnoE '\bRMM\b' lib test` → **0**; the
  compile gate is clean; the `--include valkey` `rooms_and_games` story is green with the `ROM`-minting
  room.
- **And** the word `room` is **byte-unchanged**: `Codemojex.Schemas.Room`, `schema "rooms"`, the routes
  `/rooms` + `/rooms/:id/join`, the JSON key `room:`, the `:no_room` atom, `CodemojexWeb.RoomChannel`. No
  `kind: "RMM"` cache literal exists (rooms are Postgres-only).
- **Invariants:** INV-1 (every other brand byte-unchanged); the brand-vs-word law (brief §10) — the grep
  is over the 3-letter token `\bRMM\b`, never the word `room`.

---

## Story S-8 — the player brand re-bases to `PLR` (brand-only) (extension axis, brief §10.2)

*As the player system, the player brand is `PLR` so its identity matches the canon — a pure brand swap at
the mint site, the word `player` unchanged everywhere.*

- **Given** the as-built player mint `EchoData.BrandedId.generate!("USR")` (`wallet.ex:21`).
- **When** a player is created.
- **Then** `generate!("PLR")` mints a `PLR…` id; `/usr/bin/grep -rnoE '\bUSR\b' lib test` → **0**; the
  compile gate is clean; `--include valkey` green.
- **And** the word `player` is **byte-unchanged**: `Codemojex.Schemas.Player`, `schema "players"`, the FK
  columns `transactions.player` + `guesses.player` (V-12 Arm A — the column NAME stays; the id VALUE flips
  `USR…`→`PLR…`), the route `/players`, the JSON key `player:`, the inbound `params["player"]`, the
  `:no_player` atom. No `kind: "USR"` cache literal exists.
- **Invariants:** INV-1; the brand-vs-word law — the grep is over `\bUSR\b`, never the word `player`.

> **NOTE on the `docs` grep:** `codemojex.specs.md` legitimately names `USR` as a **distinct** entity (the
> auth account vs the `PLR` persona — specs.md:9–11). So the docs acceptance is `\bRMM\b|\bRND\b` → 0 in
> `docs/codemojex` (player rows in the design.md mirror flip to `PLR`); a residual account-sense `USR` in
> specs.md is **correct**, not a miss.

---

## Story S-9 — the blind/sealed Golden wire flow (V-6 Arm B, brief §11)

*As a blind-room player, a golden game shows state and the timer only until the sealed reveal at close, so
no per-guess signal leaks and the result is provably fair.*

- **Given** a golden game (`feedback="none"`, `settlement="sealed"`) with a `commitment` published at
  open and the `secret`/`nonce` sealed server-side.
- **When** a player joins / refreshes / reads history on the **open** golden game, then submits a guess,
  then the game closes on the timer.
- **Then (in-flight):** the view carries `:commitment` + `:state` but **never** `:secret` or `:nonce`; the
  per-guess `"scored"` push **does not fire** (the `ScoreWorker` suppresses it for `feedback="none"`); the
  channel carries state + timer only.
- **And (at reveal):** **one** sealed push (e.g. `"revealed"`, shape per the V-13 ruling) exposes the
  `secret`+`nonce`+`commitment`+the final board+the top-K payouts+the terminal state — the **first and
  only** results the blind client receives; the exposed commitment recomputes (`hash(secret,nonce) ==
  commitment`).
- **Invariants:** INV-9 (the privacy line — the `secret` AND the commitment **preimage** never cross the
  wire pre-reveal; the commitment **hash** may); INV-8 (the blind columns drive the flow).

> **Ownership:** VenusPG owns the blind COLUMNS + the sealed-settlement DATA path (`top_k` payout); this
> story owns the WIRE behavior (suppression, the view fields, the reveal push). The two meet at the
> `games.feedback`/`settlement` policy fields. The GAPS held out (top-K pays from the game's `prize_pool`;
> the anonymized alias needs `RMP` membership — out of scope) are flagged in brief §11.4, not invented.

---

## Coverage

| Deliverable | Story | Invariants |
|---|---|---|
| D1 fresh schema (one create) | S-1, S-6 | INV-6, INV-8 |
| D2 the `GAM` entity (rename) | S-2, S-3 | INV-1, INV-7 |
| D3 type/policy + CHECK | S-4 | INV-2 |
| D4 linear-only, bonus removed | S-5 | INV-3, INV-4, INV-5 |
| D5 reinitialization | S-1 | INV-6 |
| D6 room re-base `RMM`→`ROM` (brief §10.1) | S-7 | INV-1 |
| D7 player re-base `USR`→`PLR` (brief §10.2) | S-8 | INV-1 |
| D8 blind/sealed Golden wire (V-6 Arm B, brief §11) | S-9, S-6 | INV-8, INV-9 |

> **D6–D8 are the T-12 extension axis** (the two brand re-bases + the live blind wire). They derive from
> `codemojex-game-rename.brief.md` §§10–13 (Venus, the identity/wire lens) + the expanded `cm.1.md` body
> (VenusPG, the model lens). D8's COLUMNS are VenusPG's; D8's WIRE is Venus's (S-9).

**Liveness:** S-1 requires the migration to actually run and the `--include valkey` suite to exercise the
fresh schema (not a skip); S-2/S-3 require the residual-grep to RUN and show zero (a present token is a
LOUD failure); S-4 requires the CHECK to be exercised by a rejected-insert; S-5 requires a scored guess to
reach the board and the bonus keys to be ABSENT (verified, not assumed); **S-7/S-8 require the brand grep
(`\bRMM\b`/`\bUSR\b`) to RUN over `lib`+`test` and show zero (a present brand token is a LOUD failure)**;
**S-9 requires a PRESENT golden game to EXERCISE the suppression + the reveal — the in-flight no-secret/
no-push and the at-reveal commitment-binding are asserted positively, never skipped** (a golden game
absent under the test's opt-in is a LOUD failure, not a silent pass). No gate is satisfied by a no-op.

---

*Derived from `cm.1.md`. The body is authoritative; feedback edits the body and the stories re-derive.*
