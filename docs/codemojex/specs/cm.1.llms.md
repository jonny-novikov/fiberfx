# cm.1 — Build brief (the file Mars builds from)

> Mars builds the founding rung **from this brief**; the Director and the Operator accept **against it**.
> Derived from `cm.1.md` (authoritative) + `cm.1.stories.md` (acceptance). Every site cites a real
> module/line or the design doc; invent no symbol, route, field, table, or policy. The settled core has
> **no open fork** — every decision the build needs is fixed here.
>
> **Framing discipline (propagate into any prose Mars writes):** no gendered pronouns for agents; no
> perceptual / interior-state verbs (sees / wants / notices); no first-person narration. State surfaces
> as contracts.

---

## 1. References — read these first (paths first)

- **The model design** `docs/codemojex/specs/progress/codemojex-game-rename.game-model.design.md` — §3
  (the schema, every column type/null/default/CHECK), §6 (the code-wiring map, file by file), §7 (the
  `Scoring.score/2` return), §8 (the reinitialization). **This is the primary reference.** (The as-built
  design is `docs/codemojex/codemojex.design.md`.)
- **The token-class rename map** `docs/codemojex/specs/progress/codemojex-game-rename.brief.md` §4 — the exact `file:line`
  for every `round`→`game` site, classified by token class (entity / api / wire / BIF-English). Use it
  for the rename half; **the column removals + the type/policy additions are this rung's addition on top.**
- **The spec body** `cm.1.md` (the deliverables + the invariants) and **the stories** `cm.1.stories.md`
  (the acceptance gates).
- **The real module surface:** `echo/apps/codemojex/lib/codemojex/` — `schemas/*.ex`, `store.ex`,
  `tables.ex`, `rooms.ex`, `game.ex`, `view.ex`, `board.ex`, `scoring.ex`, `economy.ex`, `notifier.ex`;
  `priv/repo/migrations/`; `test/stories/`; `config/dev.exs` / `config/test.exs`.

---

## 2. Requirements (numbered; each traced to a story + an invariant)

- **R1 (D1 → S-1, INV-6/INV-8).** Author **one clean initial create-migration** (collapse the two
  existing migrations) reflecting design §3: `create table(:games)` with the type/policy columns + the
  four blind-mode columns **nullable** (`top_k` default `5`) + `cell_codes` (`text[]`) + `payout_split`
  (`int[]`, default `[40,25,15,12,8]`) + `secret` + the timer/fee/golden props; `rooms` with `game` (not
  `round`) + `type` + `cell_count` (nullable) + `payout_split` (default `[40,25,15,12,8]`); `guesses`
  **without** `tier`/`percentage`; `players` with `tg_chat_id`; the four indexes; **both** the `games_type`
  and `games_status` CHECKs (design §3.5/§3.8.5). Per design §8 the Operator authorized rewriting the two
  migration files into one (a fresh machine permits it).
- **R2 (D2 → S-2/S-3, INV-1/INV-7).** Rename `round`→`game` / `RND`→`GAM` across the code surfaces
  (design §6) and the external wire (routes `/games`, topic/channel `game:`, the `game:` keys,
  `:no_game`). Honor the token classes (Venus-1 brief §4): rename entity/api/wire tokens; **leave**
  `Kernel.round/1`, `Math.round`, English "round". Compile-gate after the API rename to catch a missed
  caller early.
- **R3 (D3 → S-4, INV-2).** Add `games.type` + `rooms.type` + the four policy columns
  (`feedback`/`scoring`/`settlement`/`economy`) + `payout_split` + `top_k` (games) + `payout_split` +
  `cell_count` (rooms); snapshot the policies + `payout_split` + `top_k` onto the game at `start_game` from
  the room, **and snapshot `cell_codes`** (`Enum.take_random(EMS.codes, room.cell_count)`, or the full set
  when null) with the secret drawn from `cell_codes` (a type→policy lookup in code; classic defaults per
  `cm.1.md` §3 D3); add the `games_type` CHECK (`type IN ('classic','golden')`) **and** the `games_status`
  CHECK (the seven canon words).
- **R4 (D4 → S-5, INV-3/INV-4/INV-5).** Remove the bonus-tier economy: drop `guesses.tier` +
  `guesses.percentage` (schema + `cast`); `Board.record/4`→`record/3` (drop `tier`); remove
  `claim_tier`, the tier-claim loop, the `ptier`/`bonus`/`tierfirst` hashes, `firsts/2`, and
  `eff = new_base + bonus` (the ZSET takes `new_base`); `ScoreWorker` `put_guess` drops the
  `percentage`/`tier` keys; the `scored` event + PubSub drop `tier`/`first`; `view.ex` `my_history` drops
  `:percentage`/`:tier`; the `Codemojex.firsts/2` delegate removed; `scoring.ex` removes `tier/1` + the
  `:tier` return key, keeps `percentage` **computed-not-stored** (design §7). **Keep
  `players.bonus_diamonds`** (a wallet bucket — do not remove).
- **R5 (D5 → S-1, INV-6).** Reinitialize the dev/test DB: `TMPDIR=/tmp mix ecto.drop && mix ecto.create
  && mix ecto.migrate` against `codemojex_dev` (`config/dev.exs:14`); the test DB
  (`config/test.exs:19`) re-creates via the suite. **No data migration, no rebrand.** Run the drop **only**
  when the model + code are ready and the Director relays the go.

> **R6–R8 are the T-12 extension axis** — the two additional brand re-bases + the live blind-mode wire.
> The exact `file:line` map + the four blind wire rules live in `codemojex-game-rename.brief.md` §§10–13
> (the primary reference for this axis). The blind COLUMNS are VenusPG's `cm.1.md`/model-design surface;
> R8 here is the WIRE/CODE half only.

- **R6 (D6 → S-7, INV-1).** Re-base the **room** brand `RMM`→`ROM` (brief §10.1): `rooms.ex:18`
  `generate!("RMM")`→`generate!("ROM")` + the docstring `rooms.ex:14`. **Brand-only** — leave the word
  `room` byte-exact (schema module `Schemas.Room`, table `"rooms"`, the `Store` alias `Room`, routes
  `/rooms`, JSON key `room:`, `:no_room`, `RoomChannel`). No cache `kind: "RMM"` exists. **5-line axis
  total with R7.**
- **R7 (D7 → S-8, INV-1).** Re-base the **player** brand `USR`→`PLR` (brief §10.2): `wallet.ex:21`
  `generate!("USR")`→`generate!("PLR")` + the docstrings `wallet.ex:19` + `game.ex:6`. **Brand-only** —
  leave the word `player` byte-exact (schema module `Schemas.Player`, table `"players"`, the columns
  `transactions.player` + `guesses.player` [V-12 Arm A — the column NAME stays], route `/players`, JSON
  key `player:`, inbound `params["player"]`, `:no_player`). No cache `kind: "USR"`.
- **R8 (D8 → S-9/S-6, INV-8/INV-9).** Build the **blind/sealed Golden wire** (brief §11, the four rules
  B-1..B-4) over VenusPG's blind schema (`feedback="none"`, `settlement="sealed"`, `commitment`/`nonce`/
  `revealed_ms`/`top_k`): **B-1** suppress the per-guess `:scored` PubSub + `Events.publish "scored"` for
  a golden game in `ScoreWorker.handle/1` (branch on the game's `feedback` policy); **B-2** extend
  `game_view/1` to carry `:commitment` + `:state` for a golden game and **never** `:secret`/`:nonce` while
  `revealed_ms` is null; **B-3** emit **one** sealed reveal push at close (the shape per the **V-13
  ruling** the Director relays) carrying the revealed `secret`+`nonce`+`commitment`+board+top-K
  payouts+terminal state; **B-4** the channel carries state+timer only in-flight. **The privacy line
  (INV-9):** the `secret` AND the commitment **preimage** never cross the wire pre-reveal; the commitment
  **hash** may. The GAPS (top-K from the game's `prize_pool`; the anonymized alias needs `RMP` — out of
  scope) are flagged in brief §11.4 — **NOT invented**.

---

## 3. Execution topology (the build-order DAG + the exact files)

> Build order is chosen so the compile gate catches a missed caller early and the migration lands after
> the code that mints `GAM`. Each step's files are design §6 (the rename map) + the migration + the
> schema.

1. **Schemas** (`lib/codemojex/schemas/`): rename `round.ex`→`game.ex` (`Schemas.Round`→`Schemas.Game`,
   `schema "rounds"`→`"games"`), **add** the type/policy + blind-mode columns + `cell_codes` +
   `payout_split` to `Game` + the `cast` list; `room.ex` `:round`→`:game` + `cast`, **add** `:type`,
   `:payout_split`, `:cell_count`; `guess.ex` `:round`→`:game` + `cast`/`validate_required`, **remove**
   `:tier`/`:percentage`.
2. **Store + cache + tables** (`store.ex`, `tables.ex`): the `Round`→`Game` alias + the round CRUD →
   game CRUD; `@cache :cm_rounds`→`:cm_games`, `fetch_round`/`put_round`→`fetch_game`/`put_game`;
   `@rounds`→`@games`, `kind: "RND"`→`"GAM"`, `&load_round/1`→`&load_game/1`, the TTL key
   `:rounds_cache_ttl_ms`→`:games_cache_ttl_ms`, the moduledoc bullet.
3. **The game lifecycle** (`rooms.ex`): `start_round/3`→`start_game/3`, `generate!("RND")`→`("GAM")`,
   **snapshot the type + the four policies + `payout_split` + `top_k` + `cell_codes`** at start (the
   secret drawn from `cell_codes`); `close_round/1`→`close_game/1`, `close_if_expired`,
   `:no_round`→`:no_game`; the `effective_pool`/`winner_take_all` close path **unchanged**.
4. **Compile-gate** (`TMPDIR=/tmp mix compile --warnings-as-errors`) — catch a missed caller.
5. **The score authority + board + view** (`game.ex`, `board.ex`, `view.ex`): R4's bonus-economy removal
   + the rename (design §6.4–6.6).
6. **The facade + the wire** (`game.ex` `Codemojex`, `router.ex`, `user_socket.ex`, `room_channel.ex`,
   `game_controller.ex`, `fallback_controller.ex`): the facade delegations (`game_view`, drop the
   `firsts` delegate); the routes/topic/channel/keys/error atom (design §6.7 + Venus-1 brief §4.4–4.5).
7. **Settlement, notifier, scoring, economy** (design §6.8): `Settle` `close_game`; `notifier.ex`
   `game_result`/`golden_win` id param; `scoring.ex` remove `tier/1` + the `:tier` key (keep
   `percentage`); `economy.ex` **unchanged**.
8. **The one clean migration** (`priv/repo/migrations/`): R1.
9. **Reinitialize** (R5) — when the Director relays the go.
10. **Tests + demo** (design §6.8): rename `rooms_and_rounds_story_test.exs`→`…rooms_and_games_…`; update
    every story exercising `tier`/`percentage`/`firsts` to the linear-only shape; `priv/round.exs`→
    `priv/game.exs`.

**Exact files touched:** the schemas (6, incl. the `round.ex`→`game.ex` rename); `store.ex`; `tables.ex`;
`rooms.ex`; `game.ex`; `view.ex`; `board.ex`; `scoring.ex`; `notifier.ex`; the web layer (`router.ex`,
`user_socket.ex`, `room_channel.ex`, `game_controller.ex`, `fallback_controller.ex`); one new migration
(+ the two old ones rewritten/collapsed per R1); the test stories + `test/README.md`; `priv/round.exs`→
`priv/game.exs`. **`economy.ex` is unchanged** (the Golden boost stays for cm.3). **`application.ex` prose
only** (the "rounds"→"games" moduledoc). **No `config/*.exs` edit** for the TTL key (it is only read with
a default in `tables.ex`).

---

## 4. Agent stories (Directive + Acceptance gate, contract form)

- **A-1 — the schema + the migration.** *Directive:* author the one clean initial create (R1) +
  rename/extend the schemas (R2 schema half + R3 columns + R4 column drops). *Acceptance:* `mix
  ecto.migrate` brings up `games`/`rooms.game`/`guesses`-without-tier/`players.tg_chat_id` + the new
  `cell_codes`/`payout_split`/`cell_count` columns + the indexes + **both** the `games_type` and
  `games_status` CHECKs; a created classic game has `commitment`/`nonce`/`revealed_ms` `NULL`, `top_k` `5`,
  `payout_split` `[40,25,15,12,8]`, `cell_codes` the full EMS set. *Invariant:* INV-2, INV-6, INV-8.
- **A-2 — the rename, atomically.** *Directive:* rename `round`→`game`/`RND`→`GAM` across code + wire
  (R2), snapshot the type/policies at start (R3). *Acceptance:* compile clean; `generate!("GAM")` mints a
  `GAM…` id; `GET /games/:id` returns the view; a client on `game:<id>` receives `scored`; the
  residual-grep shows zero entity/wire tokens. *Invariant:* INV-1, INV-7.
- **A-3 — the bonus economy removed.** *Directive:* R4. *Acceptance:* `guesses` stores only `points`; the
  board ranks raw best; `ptier`/`bonus`/`tierfirst`/`firsts`/`claim_tier`/`tier:`/`percentage:` are
  absent (the residual-grep); `players.bonus_diamonds` survives; `Scoring.score/2` is linear + pure.
  *Invariant:* INV-3, INV-4, INV-5.
- **A-4 — reinitialize + gate.** *Directive:* R5 + run the gate (`cm.1.md` §6). *Acceptance:* the fresh
  DB migrates; `--include valkey` green; the residual-grep zero for entity/bonus tokens (BIF survives);
  the CHECK exercised by a rejected-insert. *Invariant:* INV-6 + the full gate.
- **A-5 — the two brand re-bases (brand-only).** *Directive:* R6 + R7 — the 5 mint/docstring sites only.
  *Acceptance:* `generate!("ROM")` / `generate!("PLR")` mint `ROM…`/`PLR…` ids; `/usr/bin/grep -rnoE
  '\bRMM\b|\bUSR\b' lib test` → 0; compile clean; `--include valkey` green. *Invariant:* INV-1 (the words
  `room`/`player` byte-unchanged — schema modules/tables/columns/routes/keys/atoms).
- **A-6 — the blind/sealed Golden wire.** *Directive:* R8 (B-1..B-4) over VenusPG's blind schema, emitting
  the **one fat `revealed` event** at close (V-13, ruled — secret+nonce+commitment+board+top-K+state) and
  carrying the `commitment` on `game_view` from open. *Acceptance:* the privacy story (brief §11.5) is
  green and **exercises** all three checks (in-flight no `:secret`/`:nonce` + no per-guess push; at-reveal
  the commitment recomputes `SHA-256(secret ‖ nonce)`, V-14); `--include valkey` green. *Invariant:* INV-8,
  INV-9 (the privacy line — preimage sealed pre-reveal).

---

## 5. The acceptance gate (close the rung — `cm.1.md` §6 + the extension axis, brief §12)

1. `cd echo/apps/codemojex && TMPDIR=/tmp mix compile --warnings-as-errors` → clean.
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres up; reinitialized; `TMPDIR=/tmp mix test --include
   valkey` → green.
3. **The unified residual-grep** (brief §12): `/usr/bin/grep -rnoE '\bRND\b|\bRMM\b|\bUSR\b' lib test` →
   **0** (all three brands re-based); `/usr/bin/grep -rniE '\b(round_view|:cm_rounds|"round:"|/rounds|
   :no_round|Schemas\.Round)\b' lib test` → **0** (the round→game entity/api/wire); the BIF survives
   (`/usr/bin/grep -rn 'Kernel\.round\|round(' lib/codemojex/scoring.ex` non-empty); the bonus tokens
   (`ptier`/`bonus`/`tierfirst`/`firsts`/`claim_tier`/`tier:`/`percentage:`) absent.
4. The `games_type` **and** `games_status` CHECKs exercised by a rejected-insert (INV-2); the
   blind/golden columns in the right state for a classic game (`commitment`/`nonce`/`revealed_ms` `NULL`,
   `top_k` `5`, `payout_split` `[40,25,15,12,8]`, `cell_codes` the full EMS set) and **set** for a golden
   game (INV-8); the **privacy line** exercised by a present golden game (INV-9 — the §11.5 story RUNS the
   suppression + the reveal).
4'. **The migration up/down proof** (the HIGH-risk gate): `MIX_ENV=test mix ecto.drop && ecto.create &&
   ecto.migrate` comes up green from zero; the migration's `up` then `down` is proven on the test DB (the
   collapsed initial create + both CHECKs reverse cleanly).
5. **The ≥100 determinism loop** on the mint/process suite (the same-ms branded-id hazard now spans
   `GAM`/`ROM`/`PLR` mints): `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break;
   done`.
6. **Docs** (brief §12.4): `/usr/bin/grep -rnoE '\bRMM\b|\bRND\b' docs/codemojex` → 0 (the design.md
   mirror reconciled forward; a residual account-sense `USR` in `specs.md` is correct, not a miss).
7. **Run no `git`** — the Director commits by pathspec. `TMPDIR=/tmp` for all `mix`. Per-app only.

---

*Authored by Venus-PG (the classic core, R1–R5) + extended by Venus (the T-12 axis: R6/R7 brand re-bases
+ R8 the blind/sealed wire, deriving from `codemojex-game-rename.brief.md` §§10–13) + converged 2026-06-25
(the D-15/D-16 rulings folded — the `payout_split`/`cell_codes`/`cell_count` columns + the `games_status`
CHECK + the ruled blind mechanics). The settled core has no open fork; the extension axis's forks are now
all RULED (V-11 keep wire words, V-12 keep the FK column name, V-13 one fat `revealed` event — D-16). Mars
builds; the Director ratifies; the Operator accepts. No production code edited in authoring this brief.*
