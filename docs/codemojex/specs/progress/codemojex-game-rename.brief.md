# Codemojex — the game rename + three brand re-bases + blind-mode wire · authoritative build brief

> The single source of truth for the `codemojex-game-rename` rung. Mars builds **from this brief**;
> the Director and the Operator accept **against it**. Every citation below was re-found on disk this
> session (the live tree, not a pre-baked list). Where the original plan map drifted, the drift is
> called out inline. Ground every edit in a cited site; invent no symbol, route, field, or table.
>
> **Framing discipline (propagate):** in this brief and in any prose Mars writes — no gendered
> pronouns for agents; no perceptual or interior-state verbs (sees / wants / notices); no
> first-person narration. State surfaces as contracts.

> **SCOPE EXTENSION (T-12 / D-10).** This brief now covers **three brand re-bases**, not one:
> `RND`→`GAM` (round→game, §§1–9 below, the original axis) **plus** `RMM`→`ROM` (room) and
> `USR`→`PLR` (player), specified in **§10**; **plus** the **blind/sealed Golden wire/code surface**
> (V-6 Arm B, Operator-ruled LIVE), specified in **§11**. The migration fork in §3 is **superseded
> by D-3** — a fresh from-scratch single collapsed migration, **no data migration** (VenusPG owns the
> relational shape). Read §3 for the historical record; build to D-3. Read §§1–9 for round→game, then
> §§10–12 for the room/player re-bases, the blind wire, and the unified acceptance.
>
> **The brand-vs-word law (load-bearing — read before §10).** A brand in BCS is the 14-byte id's
> **3-letter uppercase prefix**, validated by *shape*. Re-basing a brand changes the
> `generate!("…")` mint string (and its docstrings) — it changes the id **value** that travels
> through every boundary, but it does **not** rename the entity's English word. `round`→`game` is the
> exception: there the lowercase word **is** the entity word *and* the wire vocabulary the Operator
> ruled flipped, so it drags the schema/table/FK/cache/route/topic/JSON. `RMM`→`ROM` and `USR`→`PLR`
> are **pure brand swaps** — the words `room`/`player` are the canon's own entity words and **stay
> everywhere** (schema modules, tables, columns, routes, JSON keys, error atoms); only the id-prefix
> moves. The acceptance grep therefore targets the **3-letter token** (`\bRMM\b`, `\bUSR\b`), never
> the word `room`/`player` (§12).

---

## 0. The one-paragraph goal

Codemojex's per-play entity is **a game** (`GAM`) — the roadmap, the architecture draft, and the
feature list already say so; the **live code, the Postgres floor, the cache, and the external wire
still say `round`/`RND`**. In BCS the 14-byte brand **is** the entity's type ("what is checked at
every boundary"), so a true rename re-bases `RND` → `GAM` everywhere the identity travels. The
Operator ruled a **FULL cutover including the wire, with the stored-data migration**. This rung
makes the running system agree with its own canon.

---

## 1. The three-register naming discipline (resolve every bare noun against this)

| Register | Term | In this rung |
|---|---|---|
| **Engine** | "the Game system" (capital-G) | the Mastermind engine; **not yet a code module** — do not invent one |
| **Entity** | "a game" / `GAM` | **THE rename target** — the per-play instance with a secret, timer, state |
| **Product** | "Codemojex" / "the game" | the app as a whole |

Test of a sentence: *"a game of Codemojex"* = product; *"the game's secret"* = entity; *"the Game
system scores it"* = engine. When a prose line is ambiguous, prefer the entity reading only where it
names the per-play instance; leave product/engine phrasing intact.

---

## 2. References — read these first (links/paths first)

- The charter for the rename's discipline: this brief + the dashboard
  [`codemojex.progress.md`](./codemojex.progress.md).
- The canon that already says `game`/`GAM`: [`codemojex.roadmap.md`](./codemojex.roadmap.md) (chapter
  B7) · the as-built draft [`codemojex.architecture.md`](./codemojex.architecture.md) · the feature
  list [`codemojex.specs.md`](./codemojex.specs.md). **Read these to copy the target vocabulary** —
  they are the shape the code must match. **Do not edit them** (verify-only; see §7).
- The as-built mirror that **lags** and must be reconciled:
  [`codemojex.design.md`](./codemojex.design.md).
- The live code surface: `echo/apps/codemojex/lib/**`, `test/**`, `priv/**`, `docs/**` (per §4).
- The migration fork ruling (the Director's `AskUserQuestion` to the Operator) — see §3. **Do not
  build the migration until the arm is ruled.**

---

## 3. THE FORK — the Postgres migration (Operator-ruled before the build) ⛔

This is the one decision the spec has not fixed, because the deciding fact is not on disk: **does the
deployed `codemoji-phoenix` prod DB carry real `RND` rows?** Disk shows prod is **configured**
(`echo/fly.toml` app `codemoji-phoenix`, rolling deploy, `auto_rollback`, `min_machines_running 1`;
`echo/config/runtime.exs` reads `DATABASE_URL` at boot) but **documented pre-launch**
(`codemojex.design.md`: the app is "parse-verified in the sandbox", and verified Telegram `initData`
is "the one explicit gap before launch"; `fly.toml`: "the Operator creates the app + machines and
pushes to deploy"). The Operator's phrase **"with the stored-data migration"** leans toward data
existing.

**Director: rule this via `AskUserQuestion` to the Operator before Mars touches a migration.** One
question, two answers:

- **"Pre-launch — no live prod rows (dev/test resettable)"** → **Path A**.
- **"Live data exists in the deployed prod DB"** → **Path B**.

**Default if the Operator is unreachable: Path B** — it is safe whether or not data exists (on an
empty DB the rename + rebrand `UPDATE`s are no-ops, and history stays clean), whereas Path A is
**unsafe if data exists** (it silently strands old rows / mismatches Ecto's migration checksum). When
uncertain, B dominates.

---

## 4. Surface 1 — the code (`echo/apps/codemojex`)

**The rename is a token-CLASS operation, not a string replace.** A blind `s/round/game/g` corrupts
`Kernel.round/1` arithmetic, `Float.round`, the html `Math.round` / `linecap:round`, and English
"around / round-trip". Classify every hit and act per class:

- **(1) ENTITY-TYPE** → rename (the brand string, the table, the schema, the FK field, entity prose).
- **(2) PUBLIC-API SYMBOL** → rename **atomically with every caller** (a missed caller fails the
  compile gate).
- **(3) EXTERNAL-WIRE** → rename (the FULL-cutover ruling).
- **(4) LANGUAGE/IDENTIFIER** → **LEAVE** (`round/1` BIF, `Math.round`, English) **or** cosmetic-only
  (a local `round` variable — a correctness-neutral consistency rename; do it for readability, but it
  is not load-bearing).

### 4.1 Brand — the type (class 1)

| File:line | From | To |
|---|---|---|
| `lib/codemojex/rooms.ex:60` | `EchoData.BrandedId.generate!("RND")` | `…generate!("GAM")` |
| `lib/codemojex/tables.ex:59` | `kind: "RND"` | `kind: "GAM"` |

> **Leave** every other brand string alone: `ROM` (room), `EMS`, `GES`, `JOB`, `NOT`, `CMD`, `USR`,
> `TXN`. The `tables.ex:89` / `97` `<<_::binary-14>>` guards are the **id SHAPE**, not the `"RND"`
> literal — untouched.

### 4.2 Entity schema (class 1)

- **Rename the file** `lib/codemojex/schemas/round.ex` → `lib/codemojex/schemas/game.ex`.
- `Codemojex.Schemas.Round` → `Codemojex.Schemas.Game` (the `defmodule` + the moduledoc "A round: a
  game in a room" → "A game: one play in a room").
- `schema "rounds"` → `schema "games"`.
- FK fields on the **other** schemas: `lib/codemojex/schemas/room.ex:17` `field :round, :string` →
  `field :game, :string` (+ the `cast(... [:round] ...)` list at line 25); `lib/codemojex/schemas/
  guess.ex:9` `field :round, :string` → `field :game` (+ the `cast`/`validate_required` lists at
  lines 21/22, and the `(round, player)` query intent).

### 4.3 Internal API + facade (class 2 — rename with all callers)

`lib/codemojex/store.ex` (alias + the round CRUD):
- `alias Codemojex.Schemas.{Player, Round, Guess, Room, EmojiSet}` → `…{Player, Game, Guess, Room,
  EmojiSet}` (line 12).
- `put_round/2` → `put_game/2`, `round/1` → `game/1` (lines 15–16) — and `Repo.get(Round, id)` →
  `Repo.get(Game, id)`.
- `guesses_for/3` (lines 27–35): the `where: g.round == ^round` → `g.game == ^game` and the param.
- `@cache :cm_rounds` → `@cache :cm_games` (line 140, the `Codemojex.Cache` module) + `fetch_round/1`
  → `fetch_game/1` (line 144) + `put_round/2` → `put_game/2` (line 152) + `@cache` references.

`lib/codemojex/tables.ex` (the cache tier):
- `@rounds :cm_rounds` → `@games :cm_games` (line 30) + `rounds_table/0` → `games_table/0` (line 34) +
  the `@rounds` uses (lines 58); `id: :cm_rounds_table` → `id: :cm_games_table` (line 65);
  `&load_round/1` → `&load_game/1` (line 60); `load_round/1` → `load_game/1` (line 89, the `round_id`
  param → `game_id`); `:rounds_cache_ttl_ms` → `:games_cache_ttl_ms` (line 45) and `rounds_ttl` →
  `games_ttl`; the moduledoc bullet `* :cm_rounds (RND) — a round and its secret` → `* :cm_games
  (GAM) — a game and its secret`.

> **Config note:** `:rounds_cache_ttl_ms` is **only read with a default** in `tables.ex:45` — it is
> **not set** in any `config/*.exs` (verified: `echo/config/config.exs` sets only `valkey_port` +
> `ecto_repos`). So the rename is self-contained to `tables.ex`; no `config/` edit is required for
> the TTL key.

`lib/codemojex/rooms.ex` (the room/game lifecycle):
- `start_round/3` → `start_game/3` (lines 57, 53) + the `rid = …generate!("GAM")` (line 60); `close_
  round/1` → `close_game/1` (line 100, called by `Codemojex.close_now` — see facade) + `do_close/2`'s
  `round` params; `close_if_expired/1` (line 163); the `:no_round` atom (line 103 — see §4.5);
  `add_player/2` `round` param (line 92); the moduledoc "a round is a game in a room" → "a game is one
  play in a room", "an `RND` is minted" → "a `GAM` is minted".

`lib/codemojex/view.ex` (the reads):
- **`round_view/1` → `game_view/1`** (line 43) — **load-bearing**: delegated by the `Codemojex`
  facade and called by the controller + the channel (rename all three together, §4.4 + below).
- `my_history/3` (line 73) `round` param; `leaderboard/2` (line 80); `total_players/1` /
  `total_attempts/1` / `best_score/1` / the `round` params (lines 87–95); the `round: round` map key
  at line 53 is **class 3** (see §4.4).

`lib/codemojex/notifier.ex` (the user-facing notification API):
- `round_result/3` → `game_result/3` (line 39) + the `@spec` (line 37) + the `round_id` param + the
  text `"Round #{round_id} is done — you scored …"` → `"Game #{game_id} is done — …"`.
- `golden_win/4` (line 53): the `round_id` param → `game_id` + the text `"✨ GOLDEN ROOM #{round_id}
  …"` → `"✨ GOLDEN ROOM #{game_id} …"`. (The moduledoc line 12 "Game helpers (`round_result/3`, …)"
  → `game_result/3`.)

`lib/codemojex/game.ex` — **the hotspot (47 hits); a multi-module file.** It defines
`Codemojex.Guesses`, `Codemojex.ScoreWorker`, `Codemojex.Settle`, **and** the `Codemojex` facade. The
plan map's note "`game.ex` is the unrelated facade, NOT the entity" is **half right** — the file is
not the entity schema, but it carries the entity token `round` throughout. **Do not rename the file**
(it is `game.ex` already, the facade's home). Edit in place:
- `Codemojex.Guesses`: `submit/3` `round` param (lines 21, 46) + `Store.round(round)` → `Store.game`;
  `:no_round` (line 26, §4.5); `valid_guess?` `round` intent; `lock`/`unlock`/`locked` `round` params
  (lines 70–72); moduledoc "Rounds are opened by `Codemojex.Rooms`" → "Games are opened by …".
- `Codemojex.ScoreWorker.handle/1`: the `round` binding (line 97) + `Cache.fetch_round(round)` →
  `Cache.fetch_game(game)` (line 99); `Store.put_guess` `round:` map key (line 106, **class 3**); the
  `Events.publish(... round: round ...)` (line 121, **class 3**); the PubSub `"round:" <> round`
  topic (line 132, **class 3**) + the `%{round: round, …}` event map (line 133, **class 3**); the
  `Cmd.incr("cm:" <> round <> ":attempts")` (line 115 — the id is an **infix**, no literal "round" in
  the Valkey key, rename the variable only); `Rooms.close_round(round)` → `Rooms.close_game(game)`
  (line 137).
- `Codemojex.Settle`: `close/1` + `handle/1` `round` params (lines 161, 167); `{:settle, round}`
  binding; `Rooms.close_round(round)` → `Rooms.close_game(game)` (line 169); moduledoc "Round
  settlement", "Closing a round" → game.
- the **`Codemojex` facade**: the `# rooms & rounds` comment (line 192) → `# rooms & games`;
  `close/1`'s `round` param (line 196); `defdelegate close_now(round), to: Rooms, as: :close_round` →
  `as: :close_game` (line 197); the play delegations `submit`/`lock`/`unlock`/`locked` `round` params
  (lines 200–203); **`defdelegate round_view(round), to: View`** → `defdelegate game_view(game), to:
  View` (line 210); `my_history`/`leaderboard`/`firsts` `round` params (lines 211–213); the moduledoc
  "whose rooms template their rounds" → "whose rooms template their games".

`lib/codemojex/wallet.ex` (class 4 mostly — variable + prose):
- `charge_guess(player, round_map, ref)` (line 40): the `round_map` param → `game_map` (cosmetic) +
  the doc "for the round" → "for the game"; `deposit_prize` doc "for a round win" → "for a game win"
  (line 52). (The `ref` is the game id passed through — no symbol change.)

`lib/codemojex/board.ex` + `lib/codemojex/locks.ex` (class 4 — variable only, **gate-neutral**):
- Both use `k(round, …)` where `round` is the **id infix** in `"cm:" <> round <> ":" <> suffix`
  (`board.ex:13`, `locks.ex:13`) — **there is no literal "round" in the Valkey key**. Rename the
  `round` parameter to `game` for consistency across `record`/`top`/`firsts`/`claim_tier`
  (`board.ex`) and `lock`/`unlock`/`locked`/`merge`/`k` (`locks.ex`). This is cosmetic; the keyspace
  is unchanged. (`locks.ex` key is `cm:{game}:lock:{player}` — the id infix, untouched.)

`lib/codemojex/application.ex` (prose only): the moduledoc "caches for rounds and emoji sets" / "the
declared L1-over-L2 caches for rounds" → "games" (lines 8, 29). **Leave** the consumer ids
`:cm_score` / `:cm_settle` / `:cm_notify` / `:cm_commands` (they key on `"cm"`, not "round").

`lib/codemojex/scoring.ex` + `lib/codemojex/economy.ex` (prose + the BIF):
- `scoring.ex`: the moduledoc "is the round's percentage" / "the round's category" → "the game's …"
  (entity prose). **Leave `round(total / @max * 100)` at line 55 — that is `Kernel.round/1`.**
- `economy.ex`: the moduledoc "won from rooms" is fine; **leave `Float.round`** (line 61) and any
  `round(...)`.

`lib/codemojex/emoji_set.ex` (prose only): the moduledoc "A round draws its secret", "immutable for a
round's life", "under the round's own version" → "A game draws its secret", "for a game's life", "the
game's own version" (lines 6–9). No symbol change.

### 4.4 External wire — the hard-pinned cutover surface (class 3, exact sites)

| Concern | Site(s) | From → To |
|---|---|---|
| PubSub topic literal | `room_channel.ex:12`, `game.ex:132`, `rooms.ex:157` | `"round:" <> …` → `"game:" <> …` |
| Channel route | `user_socket.ex:4` | `channel "round:*"` → `channel "game:*"` |
| HTTP routes | `router.ex:17`–`20` | `/rounds/:id`, `/rounds/:id/guess`, `/rounds/:id/history`, `/rounds/:id/leaderboard` → `/games/:id…` |
| JSON / event map key | `game_controller.ex:32`, `game.ex:106`, `game.ex:121`, `game.ex:133`, `rooms.ex:158`, `view.ex:53` | `round: …` → `game: …` |

Controller actions + bindings (rename the action name + its `round` binding together):
- `game_controller.ex`: the `:round` action (router `router.ex:17`) → `:game`, with `def round(conn,
  %{"id" => round})` → `def game(conn, %{"id" => game})` (line 36) returning `{:error, :no_round}` →
  `{:error, :no_game}` (line 38, §4.5); the `join` action's `%{round: round, view:
  Codemojex.round_view(round)}` → `%{game: game, view: Codemojex.game_view(game)}` (line 32); every
  `Codemojex.round_view(round)` call → `Codemojex.game_view(game)` (lines 32, 37, 45) + the `round`
  bindings in `round`/`guess`/`history`.
- `room_channel.ex`: `def join("round:" <> round, …)` → `def join("game:" <> game, …)` (line 12) +
  `assign(socket, :round, round)` → `assign(socket, :game, game)` + `socket.assigns.round` → `.game`
  (line 24) + every `Codemojex.round_view(round)` → `Codemojex.game_view(game)` (lines 13, 27); rename
  the moduledoc "The live round. Joining `round:<id>`" → "The live game. Joining `game:<id>`".

> **Consider renaming `RoomChannel` itself?** **No** — leave `CodemojexWeb.RoomChannel` /
> `room_channel.ex` as-is. The channel is named for the *room* (the long-lived thing the topic is
> scoped under), and the topic prefix being `game:` does not force a module rename. A channel-module
> rename would widen the diff with no contract benefit. (If the Operator later wants `GameChannel`,
> that is a separate cosmetic rung.)

### 4.5 Error atom (class 2 — closed set, rename every site)

`:no_round` → `:no_game` at all four sites — they must move together or the fallback mis-maps:
`game.ex:26`, `rooms.ex:103`, `game_controller.ex:38`, and `fallback_controller.ex:20` (the
`render_error(:no_round)` clause + its `"round not found"` string → `:no_game` + `"game not found"`).

### 4.6 Tests + demo

- **Rename the file** `test/stories/rooms_and_rounds_story_test.exs` →
  `test/stories/rooms_and_games_story_test.exs`; the module
  `Codemojex.Stories.RoomsAndRoundsStoryTest` → `…RoomsAndGamesStoryTest`; the `use Codemojex.Story,
  feature: "Rooms and rounds"` → `feature: "Rooms and games"` (line 7) + the moduledoc "the
  room/round lifecycle" + every `round` binding/assertion + `Codemojex.round_view` → `game_view`.
- The `round` tokens across the other story tests that exercise the entity: `settlement_story_
  test.exs` (16), `privacy_story_test.exs` (16), `wallet_story_test.exs` (9), `economy_story_test.exs`
  (1), `emoji_codes_story_test.exs` (1) — rename the entity bindings + the `round_view`/`close_*`/
  `submit` call sites + any `round:` payload assertions. (`scoring_story_test.exs` has **0** — skip.)
- `test/support/codemojex/story.ex` — the Story DSL carries **0** "round" (verified); the feature
  string lives in the test, not the DSL — **no edit**.
- `test/README.md` — the entity lines 17 (`rooms_and_rounds_story_test.exs` → `rooms_and_games_…`),
  50–51 ("a … round and a later join", "the round view and history") → game.
- **Rename the demo** `priv/round.exs` → `priv/game.exs`; the header comment "A live round, end to
  end" + `mix run priv/round.exs` → `priv/game.exs` + every `round` binding + the `IO.puts` strings
  ("a live round on the bus", "round #{round}", "round view served to clients") → game +
  `Codemojex.round_view` → `game_view`.
- `priv/scoring.exs` — line 15 "the rules' dogs round" is **colloquial English** ("a round of the
  game"); leave it (or, if reworded for consistency, "the rules' dogs game"). **Leave line 33
  `round(pts / 600 * 100)` — that is `Kernel.round/1`.**

### 4.7 The acceptance gate (what closes Surface 1)

After the rename, the proof the token classes were honored:

1. `cd echo/apps/codemojex && TMPDIR=/tmp mix compile --warnings-as-errors` → clean (an over-rename
   of a BIF or a missed caller fails to compile).
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres up + the DB migrated (per the ruled migration path);
   `TMPDIR=/tmp mix test --include valkey` → green (the `rooms_and_games` / `settlement` / `privacy`
   stories exercise the renamed wire end-to-end).
3. **Residual-grep proof** (the entity/api/wire fully migrated, the BIF/English untouched):
   `/usr/bin/grep -rniE '\b(RND|round_view|:cm_rounds|"round:"|/rounds|:no_round|Schemas\.Round)\b'
   echo/apps/codemojex/lib echo/apps/codemojex/test` → **0**; while `/usr/bin/grep -rn 'Kernel.round\|
   round(' echo/apps/codemojex/lib/codemojex/scoring.ex` still shows the BIF.

---

## 5. Surface 2 — the Codemojex docs

| File | Round hits | Action |
|---|---|---|
| `docs/codemojex/codemojex.design.md` | 27 | **The as-built mirror — make it truthful to the renamed code.** Entity "round"→"game", `RND`→`GAM`, table `rounds`→`games`, `:cm_rounds`→`:cm_games`, `/rounds`→`/games`, `round:`→`game:` topic, `round_view`→`game_view`, the `RND` row in the namespace table → `GAM`. **Leave** the surrounding `ROM`/`USR` vocabulary (the separate reconcile). |
| `docs/codemojex/codemojex.architecture.md` | **0** | **VERIFY-ONLY — already `game`/`GAM`** (the plan map's expectation it carries "round" is wrong). Do not edit. |
| `docs/codemojex/codemojex.specs.md` | **0** entity | **VERIFY-ONLY — already `GAM`** ("Games and guesses", "per-game"). Do not edit. |
| `docs/codemojex/codemojex.roadmap.md` | 0 entity | **VERIFY-ONLY — fully `game`/`GAM`** (the "round" grep matched "Grounding"/"grounded"). Do not edit. |
| `echo/apps/codemojex/docs/codemojex.game_rules.md` | 8 (entity) | "A Round Begins"→"A Game Begins", "Round Timer", "Round Ends", "every round", "the round's category" → game. |
| `echo/apps/codemojex/docs/golden-rooms.md` | 10 (entity) | "the round is a snapshot"→"the game is a snapshot", "the round's PubSub topic"→"the game's …", and the code citations `Codemojex.Schemas.Round`→`.Schemas.Game`, `start_round`→`start_game` (to match the renamed code); the table-cite rows accordingly. |
| `echo/apps/codemojex/docs/02-rooms-and-emoji-sets.md:5` | 1 (the equation) | "Rooms acts as a template for a round. Round = game in a room." → reword: "A room is a template for a game. A game is one play in a room." (the line literally equates them — make it one-directional). |
| `echo/apps/codemojex/docs/notifications.md` | 4 (entity) | "a round result"×2, "When a round closes", "the live round topic" → game. |
| `docs/codemojex/notifications/notifications.design.md:124` | 1 (template) | **ONLY** the entity template `"Hi {first_name}, round {round} is live"` → `"…game {game} is live"`. **Leave** the other 6 hits — they are English "round-trip(s)". |
| `docs/codemojex/notifications/notifications.aaw.design.md`, `…/specs/cmn.1/cmn.1.md`, `…/specs/emq.throttle/emq.throttle.md` | English only | **LEAVE ENTIRELY** — every "round" hit is "(no-)round-trip". |

---

## 6. The acceptance gate (Surface 2 + the migration)

- **Docs truthfulness:** after the design.md edit, `/usr/bin/grep -niE '\b(round|RND)\b'
  docs/codemojex/codemojex.design.md` shows **only** any deliberately-kept English (none expected) —
  the entity/brand/table/route/topic tokens are all `game`/`GAM`/`games`. The three verify-only docs
  are byte-unchanged (`git diff --stat` shows no change to architecture.md / specs.md / roadmap.md).
- **Path-A migration gate:** `TMPDIR=/tmp mix ecto.drop && mix ecto.create && mix ecto.migrate`
  succeeds; the `--include valkey` suite is green against the fresh `games` schema.
- **Path-B migration gate (up AND down on a populated TEST DB):** seed a `RND` room + game + guesses;
  `mix ecto.migrate` (up) → assert the `games` table exists, the ids are `GAM…` with the **same
  Base62 body**, and a `guesses` ⋈ `games` join resolves (FK integrity); `mix ecto.rollback` (down) →
  assert the rows are byte-restored to `RND`/`rounds`. The Operator runs the migration on prod; the
  team only proves up/down on the test DB.

---

## 7. Surface 3 — the BCS course (`docs/echo/bcs`) + the html todo

### 7.1 `docs/echo/bcs/bcs.2.md` — the six entity tokens only

`bcs.2.md` carries **11** "round" hits (not the ~6 the plan map estimated). Rename **only the six
entity sites** → "game" / "game ids"; **leave the other five** (English "around" / "round-trip"):

| Line | Context (entity) | Action |
|---|---|---|
| 29 | "commands naming a player and a round" | → "…a player and a game" |
| 45 | "its durable state — the round, the scores, the wallet" | → "…the game, the scores, …" |
| 111 | "a property store keyed by player and round ids" | → "…player and game ids" |
| 231 | "a room's under a `ROM` id, a round's under its own" | → "…a game's under its own" (**keep `ROM`** — separate reconcile) |
| 247 | "a finished round's ephemeral state is dropped" | → "a finished game's …" |
| 259 | "a round preserved for replay" | → "a game preserved for replay" |

> **NO-INVENT guardrail:** `bcs.2.md` is grounded in the **roadmap vocabulary** (`ROM`/`PLR`), not the
> as-built code (`ROM`/`USR`). Change the `round`→`game` token **only**; do **not** "fix" the
> surrounding `ROM`/`PLR` to match the code — that is the separate `ROM`↔`ROM` reconcile. The other
> `bcs*.md` files (bcs.0, preface, research, bcs.8, toc, appendixes) carry ~30 English "round" hits
> and **0 entity** ones (bcs.7/bcs.8 already use `GAM`) — **leave them all**.

### 7.2 `docs/echo/bcs/bcs.todo.md` (NEW — Mars writes it from this enumeration)

The team touches **no** `html/bcs/**`. Mars authors `bcs.todo.md` as the Operator's hand-edit list,
verbatim from the enumeration below — **8 entity-`round` sites across 7 files** (the plan map's "~7
files ×6" was close):

| File | Line | Site | Note |
|---|---|---|---|
| `html/bcs/codemojex/index.html` | 258 | `<g data-seg="round">…the play…` | **figure-internal segment key** for the "the play" route segment |
| `html/bcs/codemojex/index.html` | 264 | `<button … data-seg="round" …>the play</button>` | the same segment's button |
| `html/bcs/codemojex/index.html` | 411 | JS caption map key `round: 'The play: …'` | the same segment's caption |
| `html/bcs/codemojex/rooms-and-modes/template-and-mode.html` | 274 | "the game is the bounded round with a secret" | entity prose |
| `html/bcs/elixir-core/otp-application/existence-not-data.html` | 274 | "its durable state — the round, the scores, …" | entity prose |
| `html/bcs/elixir-core/otp-application/the-property-store.html` | 281 | "keyed by player and round ids" | entity prose |
| `html/bcs/elixir-core/property-stores/the-only-key.html` | 274 | "a room's under a `ROM` id, a round's under its own" | entity prose (**keep `ROM`**) |
| `html/bcs/elixir-core/property-stores/ttl-as-structure.html` | 275 | "a finished round's ephemeral state" | entity prose |
| `html/bcs/elixir-core/the-champ-database/structural-sharing.html` | 274 | "a room for a spectator, a round preserved for replay" | entity prose |

> **The three `index.html` sites are a unit.** `data-seg="round"` is a **figure-internal segment id**
> (the route-tag nav's "the play" segment), not the `GAM` entity — the `<g>`, the `<button>`, and the
> JS caption key must change **together** to `"game"` (all three or none), or the interactive figure
> de-syncs. Flag this in `bcs.todo.md` as a **JUDGMENT call** for the Operator: either rename the
> segment id to `game` across all three lines, or leave the segment id as the internal token "round"
> (it is not visible as the entity). The other six are plain entity prose — a clean "round"→"game".
> **In all html prose, keep `ROM`** (the separate reconcile). **Leave** the saturated English
> "round trip(s)" across `html/bcs/cache/**` and the SVG `linecap:round` / `Math.round` everywhere.

---

## 8. Build order (the task DAG for Mars)

1. **Wait for the migration arm ruling** (§3) — do not touch a migration until the Director relays
   Path A or B.
2. **Surface 1 code** (§4): brand → schema (incl. the file rename) → internal API/facade → external
   wire → error atom → tests/demo. Compile-gate after the API rename (catch missed callers early).
3. **The migration** (§3, the ruled path).
4. **Surface 1 gate** (§4.7): compile-clean + `--include valkey` green + the residual grep.
5. **Surface 2 docs** (§5): reconcile `design.md` + the app docs + the one notifications template;
   **verify-only** the three already-`game` docs.
6. **Surface 3** (§7): `bcs.2.md` six tokens + author `bcs.todo.md`.
7. Report to the Director with the residual-grep output, the gate result, and the migration up/down
   proof (Path B) or the fresh-migrate proof (Path A). **Run no `git`** — the Director commits by
   pathspec.

---

## 9. Agent stories (Directive + Acceptance gate, contract form)

- **Story R-1 — the brand re-bases.** *Directive:* rename the minted brand `RND`→`GAM` (§4.1) and
  the entity schema (§4.2). *Acceptance:* `generate!("GAM")` mints a `GAM…` id; `Codemojex.Schemas.
  Game` maps `schema "games"`; the compile gate is clean. *Invariant:* every other brand
  (`ROM`/`EMS`/`GES`/`JOB`/`NOT`/`CMD`/`USR`/`TXN`) is byte-unchanged.
- **Story R-2 — the wire flips, atomically.** *Directive:* rename the `/rounds` routes, the
  `"round:"` topic + `"round:*"` channel, the `round:` JSON keys, `round_view`→`game_view`, and
  `:no_round`→`:no_game` (§4.3–4.5). *Acceptance:* `GET /games/:id` returns the view; a client joining
  `game:<id>` receives `scored` pushes; `--include valkey` stories green. *Invariant:* no caller of a
  renamed symbol is left pointing at the old name (the compile gate proves it).
- **Story R-3 — the store migrates per the ruling.** *Directive:* execute the ruled migration path
  (§3). *Acceptance (A):* a fresh DB comes up as `games` and the suite is green. *Acceptance (B):* up
  →`GAM`/`games` with FK integrity, down→byte-restored `RND`/`rounds`, both proven on a test DB.
  *Invariant:* the create-migrations stay byte-unchanged under Path B; the stored Base62 body is
  preserved on rebrand.
- **Story R-4 — the docs tell the truth.** *Directive:* reconcile `design.md` + the app docs + the
  notifications template; verify-only the three already-`game` docs; rename `bcs.2.md`'s six entity
  tokens; author `bcs.todo.md` (§5, §7). *Acceptance:* the design.md grep shows only `game`/`GAM`; the
  three verify-only docs are byte-unchanged; `bcs.2.md`'s English "round" survives; `bcs.todo.md` lists
  the 9 html lines with the `index.html` unit flagged. *Invariant:* no `ROM`/`ROM`/`PLR` vocabulary is
  touched; no English "round-trip" or `Kernel.round/1`/`Math.round` is touched.

---

---

## 10. Surface 1b — the two additional brand re-bases (`RMM`→`ROM`, `USR`→`PLR`)

> **The scope is narrow by construction** (T-13/T-14, the brand-vs-word law above). The room and
> player **brands** are re-based at their mint sites + docstrings; the **words** `room`/`player` —
> and everything that speaks them (schema modules, tables, columns, routes, JSON keys, error atoms) —
> **stay byte-exact**. This is **5 line-edits total** (2 for `RMM`, 3 for `USR`), verified on disk:
> `/usr/bin/grep -rnoE '\bRMM\b' lib test` → 2 sites; `\bUSR\b` → 3 sites. The whole point of the
> grep acceptance (§12) is that these tokens live at **exactly** these sites — nowhere else.

### 10.1 Room — `RMM` → `ROM` (class 1, the brand only)

| File:line | From | To |
|---|---|---|
| `lib/codemojex/rooms.ex:18` | `EchoData.BrandedId.generate!("RMM")` | `…generate!("ROM")` |
| `lib/codemojex/rooms.ex:14` | docstring `Create a room (\`RMM\`)…` | `…(\`ROM\`)…` |

> **LEAVE byte-exact (class 4 — the English word `room`, NOT the brand):** the schema module
> `Codemojex.Schemas.Room` (`schemas/room.ex:1`); the table `schema "rooms"` (`room.ex:8`); the
> `Store` alias `Room` (`store.ex:12`); the HTTP routes `/rooms`, `/rooms/:id/join`
> (`router.ex:14`–`15`); the JSON keys `rooms:` / `room:` (`game_controller.ex:27`, `view.ex:28`/`54`);
> the `:no_room` error atom (`game_controller.ex` join path → `fallback_controller.ex:21`); the
> `CodemojexWeb.RoomChannel` module + `room_channel.ex` filename; every `room` / `room_id` variable.
> The id **value** travelling through these flips `RMM…`→`ROM…` automatically via the mint change —
> no code at these sites changes. **There is NO `kind: "RMM"` cache literal** (`tables.ex` declares
> only `:cm_rounds` kind `"RND"` + `:cm_emojisets` kind `"EMS"`; rooms are Postgres-only via `Store`).

> **Note on `room.ex:17` `field :round, :string`:** that field is the **round→game** FK rename
> (`:round`→`:game`, §4.2), driven by the *round* axis, **not** the room re-base. The room re-base
> touches no field.

### 10.2 Player — `USR` → `PLR` (class 1, the brand only)

| File:line | From | To |
|---|---|---|
| `lib/codemojex/wallet.ex:21` | `EchoData.BrandedId.generate!("USR")` | `…generate!("PLR")` |
| `lib/codemojex/wallet.ex:19` | docstring `Create a player (\`USR\`)…` | `…(\`PLR\`)…` |
| `lib/codemojex/game.ex:6` | moduledoc `…named by the player's \`USR\`…` | `…by the player's \`PLR\`…` |

> **LEAVE byte-exact (class 4 — the English word `player`, NOT the brand):** the schema module
> `Codemojex.Schemas.Player` (`schemas/player.ex:1`); the table `schema "players"` (`player.ex:9`);
> the `Store` alias `Player` (`store.ex:12`); **the FK columns** `transactions.player`
> (`transaction.ex:9`) and `guesses.player` (`guess.ex:10`) — **see the V-12 Arm below**; the
> changeset cast/validate lists naming `:player` (`transaction.ex:19`–`20`, `guess.ex:21`–`22`); the
> query `where: g.player == ^player` (`store.ex:30`); the HTTP route `/players` (`router.ex:12`); the
> JSON key `player:` (`game_controller.ex:23`/`80`, `room_channel.ex:28`, `view.ex` lobby/leaderboard
> rows); the inbound identity `params["player"]` (`game_controller.ex:77`); the `:no_player` error
> atom (`game_controller.ex:78`, `fallback_controller.ex:19`); `create_player` / `require_player` /
> every `player` variable. **No `kind: "USR"` cache literal** (players are Postgres-only).

### 10.3 THE FORK — the FK column names (`transactions.player` / `guesses.player`) ⚖️ (V-12)

`USR`→`PLR` re-bases the player **id-value** prefix. Two columns hold a player id: `transactions.player`
and `guesses.player`. The column **name** `player` is the entity's English word, not the brand. Because
**D-3 reinitializes the schema from scratch** (one collapsed migration, no data migration), there is
**no migration cost** to either choice — the column is created once with whatever name is chosen.

- **Arm A (Venus RECOMMENDS) — KEEP the column name `player`.** The canon names the entity "player"
  (the English word) while branding its id `PLR`; "player" is the correct name for a column holding a
  player reference. The id **value** flips `USR…`→`PLR…` via the mint change; the column name stays
  semantically exact. Zero query / changeset churn. Contrast `guesses.round`→`guesses.game`, which
  *does* change — because the **word** round→game changed; the player word did not.
- **Arm B — rename the column to a brand-flavored name (e.g. `plr`).** A 3-letter brand is not a
  column name; the schema speaks English words (`player`/`currency`/`reason`/`ref`). Rejected on
  no-invent + churn.

> **This is also VenusPG's surface** (the column type/null/FK). Venus surfaces the **name**; the
> Director synthesizes both architects and rules the Arm. The two architects are expected to converge
> on Arm A (keep `player`); a divergence is the Director's to surface to the Operator. **Until ruled,
> Mars builds neither column rename** — the player re-base is the 3 mint/docstring sites in §10.2 only.

### 10.4 The room/player wire posture (V-11 — surfaced, ruled by the Director)

The room/player re-bases flip **nothing** on the wire (T-15): the wire never carries the brand
string; it carries the words `players`/`rooms`/`player`, and the id values flowing through them flip
prefix automatically. **Arm A (Venus RECOMMENDS): keep every wire word; re-base the brand id-prefix
only** — there is no canon word to flip `player`/`room` *to* (the canon keeps them as the English
entity words; only the brand moves). **Arm B (flip the wire words for symmetry with round→game) is
rejected on no-invent** — it would fabricate route/key names with no canon basis and break the client's
opaque-id contract for a cosmetic prefix. The Director rules with the Operator (the wire is an external
contract). **If Arm A: §10.1/§10.2 are the complete room/player surface** — no wire edit.

---

## 11. Surface 1c — the blind/sealed Golden wire/code surface (V-6 Arm B, Operator-ruled LIVE)

> **Ownership split.** VenusPG owns the **data model** of blind mode — the `games` columns
> `commitment` / `nonce` / `revealed_ms` / `top_k`, the `type`/`policy` discriminator, the widened
> status set (D-9). **This section owns the WIRE/CODE surface** — how the blind flow appears (or does
> **not** appear) on the channel + the controller + the view, and how the **privacy line** is
> enforced. Build the schema to VenusPG's `cm.1.md` + `codemojex.game-model.design.md`; build the wire
> to this section. The two meet at the `games` row's policy fields (`feedback` / `settlement`) and the
> blind columns.
>
> **The privacy line (Operator-locked, the hard invariant G6):** the game `secret` **AND** the blind
> `commitment`'s **preimage** (the `secret`+`nonce`) **never cross the wire to a client pre-reveal.**
> The commitment **hash itself** is public by design (it binds the server — specs.md:53); only its
> preimage is sealed. After reveal, `secret`+`nonce` are exposed so the client recomputes
> `hash(secret, nonce)` and verifies it `== commitment`.

### 11.1 The baseline the blind flow departs from (as-built, classic)

- **Per-guess live feedback.** `Codemojex.ScoreWorker.handle/1` (`game.ex:130`–`134`) broadcasts
  `{:scored, %{round, player, pct, tier, eff, first}}` on the per-game PubSub topic after **every**
  guess; the channel (`room_channel.ex:17`–`18`) `push(socket, "scored", payload)` to the client.
- **The view never leaks the secret.** `Codemojex.View.round_view/1` (`view.ex:43`–`70`) returns the
  keyboard, timer, pool, status, and totals — **never** `:secret`. (This is the privacy line,
  as-built, for classic.)
- **Close → winner-take-all + a golden broadcast** (`rooms.ex:152`–`159`).

> After the round→game rename (§4), the topic literal is `"game:" <> game`; this section is written
> against the **renamed** surface (`game_view/1`, `"game:" …`). Apply §4 first.

### 11.2 The four blind wire rules (each grounded; build to these)

| # | Rule | Grounding | Mechanism (build) |
|---|---|---|---|
| **B-1** | **No per-guess feedback** for a golden game's life. | specs.md:40 (“blind mode stores the guess and reveals nothing”), :45, :90 | In `ScoreWorker.handle/1`, **branch on the game's `feedback` policy**: a golden game (`feedback == "none"`) stores the `GES` + counts the attempt **but suppresses** the `:scored` PubSub broadcast (and the `Events.publish "scored"`). The classic path (`feedback == "score"`) is unchanged. |
| **B-2** | **Commitment published, preimage sealed.** | specs.md:53–54; the privacy line | Extend `game_view/1`: a golden game's view carries `:commitment` (+ `:state`), and **never** `:secret` or `:nonce` while `revealed_ms` is null. A hard invariant: **no view selects `:secret`/`:nonce` pre-reveal.** |
| **B-3** | **One sealed-settlement push at reveal.** | specs.md:47 (one pass, top K), :55 (reveal secret+nonce, expose for verify), :89–90 (state changes on the channel) | At close→reveal→settle, broadcast **one** event on the per-game topic carrying the **revealed** `secret`+`nonce`+`commitment`, the final board, the top-K payouts, and the terminal `:state`; the channel pushes it (**a new push, e.g. `"revealed"`**). This is the **first and only** results a blind client receives. **Shape = V-13 (ruled by the Director).** |
| **B-4** | **State + timer only in-flight.** | specs.md:36 (state machine), :89–90 | The channel carries **state transitions + the timer** for a golden game — no scores. `join` returns the `game_view` (state + timer + commitment, **no** secret/nonce/results). |

### 11.3 THE FORK — the blind client-protocol shape (V-13 — surfaced, ruled by the Director) ⚖️

The canon fixes the **semantics** (B-1..B-4); the concrete **event shape** is open. Venus surfaces;
the Director rules (an external wire contract).

- **Arm A (Venus RECOMMENDS) — ONE fat `"revealed"` event at close** carrying
  `%{secret, nonce, commitment, board, payouts, state: :settled}`; the commitment rides the
  `game_view` from open; the per-guess push is suppressed in-flight (B-1). One event = one atomic,
  verifiable client transition. Matches specs.md:47/:55/:90. Smallest new surface (one event + one
  view field).
- **Arm B — SEPARATE `"reveal"` (secret+nonce+commitment) then `"settled"` (board+payouts)** —
  granular, lets a client verify before seeing payouts; heavier (two events, a transient state), and
  the canon describes one pass.
- **Arm C — no push; the blind client polls `game_view` after close.** Rejected — it abandons the
  channel the canon mandates (specs.md:89–90).

> Sub-forks folded into Arm A: the commitment on the view from open (vs a separate `"committed"`
> push — unnecessary, the view already carries `:state`); the board push uses `{player_id, score}`
> rows **until RMP membership** lands the anonymized alias (the wire shape accepts `{alias, score}`,
> alias defaults to the id) — a **deferred-system** concern (RMP is out of scope), **not** a blocker.

### 11.4 The grounding GAPS held out of the wire (flagged, NOT invented — consistent with D-9)

- **Top-K pays from the game's `prize_pool`** as-built (the `BNK` bank is out of scope — no bank
  table). The blind settlement reuses the as-built payout path (`Economy.winner_take_all` widened to
  top-K, VenusPG's call) over the game's own pool.
- **The anonymized leaderboard needs `RMP` membership** (out of scope). The blind board push uses
  `{player_id, score}` rows; the "anonymized neutral names" is a config/launch concern that lands with
  `RMP`. The wire **shape** supports it (a list of `{alias, score}`; the alias defaults to the id).

### 11.5 The blind acceptance (the privacy line, exercised — G6 liveness)

A sealed story (`privacy_story_test.exs` extended, or a new `golden_blind_story_test.exs`) must
**exercise** the line, not skip it:

1. **(in-flight)** A client `join` / `refresh` / `history` on an **open golden game** returns a view
   that **never** contains `:secret` or `:nonce` (the `:commitment` **is** allowed). Assert positively.
2. **(in-flight)** The per-guess `"scored"` push **does not fire** for a golden game — submit a guess,
   assert no `:scored` is broadcast on the topic (a present golden game must **run** the suppression).
3. **(at reveal)** Only **after** close does the `"revealed"` push expose `secret`+`nonce`, and the
   exposed `commitment` recomputes: `hash(secret, nonce) == commitment`. Assert the binding holds.

> **G6 must EXERCISE its outcome** (the gate-liveness law): a present golden game **runs** the
> suppression + the reveal with a positive proof; an absent golden game under the test's opt-in is a
> LOUD failure, never a silent skip. (A gate whose letter a no-op satisfies proves nothing.)

---

## 12. The unified residual-grep acceptance (all three brands + the docs)

After the build, these external shell gates close the rename (`/usr/bin/grep`, the BIF/English spared):

1. **Code — brands to zero** (the three brand tokens live ONLY at the mint/docstring/cache sites; 0
   proves the re-base is complete):
   ```bash
   cd echo/apps/codemojex
   /usr/bin/grep -rnoE '\bRND\b|\bRMM\b|\bUSR\b' lib test    # → 0
   ```
2. **Code — the round→game entity/api/wire surface to zero** (extends §4.7):
   ```bash
   /usr/bin/grep -rniE '\b(round_view|:cm_rounds|"round:"|/rounds|:no_round|Schemas\.Round)\b' lib test   # → 0
   ```
3. **Code — the spared BIF/English SURVIVES** (a guard against over-rename / blind sed):
   ```bash
   /usr/bin/grep -rn 'Kernel\.round\|round(' lib/codemojex/scoring.ex   # → still shows the BIF (non-empty)
   ```
   `Kernel.round/1` (`scoring.ex:55`), `Float.round` (`economy.ex`), and any English "round-trip"
   remain untouched.
4. **Docs — `RMM` (and `RND`) to zero across `docs/codemojex`** (the design.md mirror reconciled to
   `GAM`/`ROM`/`PLR`; per the locked acceptance):
   ```bash
   /usr/bin/grep -rnoE '\bRMM\b|\bRND\b' docs/codemojex    # → 0
   ```
   `\bUSR\b` in `docs/codemojex` is **NOT** required to hit 0 here — `codemojex.specs.md` legitimately
   names `USR` as a **distinct entity** (the auth account, separate from the `PLR` persona; specs.md:9–11
   "bind a `USR` to a Telegram account; one persona (`PLR`) per account"). The design.md mirror's
   **player** rows flip `USR`→`PLR`; specs.md's account-`USR` stays. **Reconcile design.md; verify-only
   specs.md** (it is already forward canon). Confirm the design.md edit leaves no **player**-sense `USR`.
5. **Boundary (G8):** `git status --short` touches ONLY `echo/apps/codemojex/**` + `docs/codemojex/**`
   (+ the rung's `docs/echo/bcs` per §7); every sibling umbrella app untouched; `mix.lock` excluded.

> **The design.md mirror reconciles forward to all three brands.** `codemojex.design.md` currently
> leads the namespace table with `RND` (round), `ROM` (room — already the *target* spelling, but as the
> mirror of `RMM` code), and `USR` (player). After this rung the **code** says `GAM`/`ROM`/`PLR`, so the
> mirror's three rows reconcile to `GAM`/`ROM`/`PLR` and the prose (`a round`→`a game`, the player rows
> `USR`→`PLR`). The room row already reads `ROM` — confirm it now mirrors the **`ROM`-minting** code
> (post-re-base), not the legacy `RMM`. **This closes the D-4 "out-of-scope `ROM↔ROM`/`USR↔PLR` drift"
> note** — T-12 brought that reconcile into scope; after this rung there is **no surviving code↔canon
> brand drift.**

---

## 13. The extended stories + the build DAG

### 13.1 Agent stories (extends §9; R-5/R-6/R-7 new)

- **Story R-5 — the room brand re-bases (brand-only).** *Directive:* re-base `RMM`→`ROM` at
  `rooms.ex:18` (mint) + `rooms.ex:14` (docstring) only (§10.1). *Acceptance:* `generate!("ROM")` mints
  a `ROM…` id; `/usr/bin/grep -rnoE '\bRMM\b' lib test` → 0; the compile gate is clean; the
  `--include valkey` `rooms_and_games` story is green. *Invariant:* the word `room` is byte-unchanged
  everywhere — the schema module `Schemas.Room`, the table `"rooms"`, the routes `/rooms`, the JSON
  key `room:`, the `:no_room` atom, `RoomChannel`. No `kind: "RMM"` exists to touch.
- **Story R-6 — the player brand re-bases (brand-only).** *Directive:* re-base `USR`→`PLR` at
  `wallet.ex:21` (mint) + `wallet.ex:19` + `game.ex:6` (docstrings) only (§10.2). *Acceptance:*
  `generate!("PLR")` mints a `PLR…` id; `/usr/bin/grep -rnoE '\bUSR\b' lib test` → 0; the compile gate
  is clean; `--include valkey` green. *Invariant:* the word `player` is byte-unchanged — the schema
  module `Schemas.Player`, the table `"players"`, the columns `transactions.player`/`guesses.player`
  (V-12 Arm A, pending the ruling), the route `/players`, the JSON key `player:`, the inbound
  `params["player"]`, the `:no_player` atom. No `kind: "USR"`.
- **Story R-7 — the blind/sealed Golden wire flow.** *Directive:* build the four blind wire rules
  (§11.2 B-1..B-4) over VenusPG's blind schema — suppress the per-guess push for a golden game; carry
  `:commitment` (never `:secret`/`:nonce`) on the golden `game_view`; emit the one sealed
  `"revealed"` push at close (shape per V-13 ruling); the channel carries state+timer only in-flight.
  *Acceptance:* the §11.5 privacy story is green and **exercises** all three checks (in-flight no
  secret/nonce + no per-guess push; at-reveal the commitment recomputes); `--include valkey` green.
  *Invariant (G6, the privacy line):* the `secret` and the commitment **preimage** (`secret`+`nonce`)
  never cross the wire pre-reveal; the commitment **hash** may; reveal exposes the preimage and the
  binding `hash(secret,nonce)==commitment` holds.

### 13.2 The build-order DAG (smallest change preserving correctness)

> Extends §8. The migration step is **D-3** (one fresh collapsed initial create, no data migration),
> not §3's Path-A/B. The blind schema is **VenusPG's** `cm.1` build input.

1. **Round→game** (§4): brand → schema (file rename) → internal API/facade → external wire → error
   atom → tests/demo. **Compile-gate after the API rename** (catch missed callers early).
2. **Room/player brand re-bases** (§10): the 5 mint/docstring sites (`RMM`→`ROM`, `USR`→`PLR`). These
   are **independent** of step 1 (different files, different tokens) — order is free; do them after
   step 1's compile-gate is clean so a residual is unambiguous. **No wire/column edit** (V-11/V-12
   Arm A). Compile-gate.
3. **The schema + the migration** (D-3, VenusPG's model): the games `type`/policy discriminator +
   the blind columns (`commitment`/`nonce`/`revealed_ms`/`top_k`) + the widened status set + tier
   removed, as **one clean initial create**; `ecto.drop`+`create`+`migrate` scoped to the configured
   dev/test DB only (`*_snapshot` untouched). Built to VenusPG's `cm.1.md`.
4. **The blind wire/code** (§11): B-1 suppression → B-2 view → B-3 the reveal push → B-4 state/timer,
   over the step-3 schema, to the V-13-ruled event shape.
5. **The full code gate** (§12.1–§12.3 + §4.7): compile-clean + `--include valkey` green on Valkey
   6390 + Postgres + the three-brand residual grep → 0 + the spared BIF survives + the **≥100
   determinism loop** (the mint/process suite — the same-ms branded-id hazard now spans GAM/ROM/PLR
   mints).
6. **The docs** (§5 + §12.4): reconcile `design.md` forward to `GAM`/`ROM`/`PLR`; verify-only the
   already-forward docs (`architecture.md`/`specs.md`/`roadmap.md`); the docs residual grep
   (`\bRMM\b|\bRND\b` → 0 in `docs/codemojex`).
7. **Surface 3** (§7): `bcs.2.md` six round→game tokens + author `bcs.todo.md`.
8. Report to the Director with the residual greps, the gate result, the migration up-from-zero proof,
   and the privacy-story output. **Run no `git`** — the Director commits by pathspec.

---

*Authored by Venus (architect). Mars builds from this; the Director ratifies; the Operator accepts.
Every citation re-found on disk this session. No production code was edited in producing this brief.*
