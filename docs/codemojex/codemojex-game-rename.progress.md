# codemojex-game-rename — AAW scope ledger

## {codemojex-game-rename-thinking} Thinking

### T-1 — UNDERSTAND: codemojex round→game full cutover (RND→GAM)

5W:
- WHO: Director (claude-opus-4-8) + Venus (architect/reconcile) + Mars (implementor, two passes) + Apollo (evaluator — this rung carries an irreversible-migration + external-wire-break dimension → HIGH-RISK → Apollo mandatory per /x-mode §11).
- WHAT: rename the per-play entity "round"→"game" across three surfaces. (1) CODE echo/apps/codemojex: brand RND→GAM (mint rooms.ex:60, cache kind tables.ex:59), Postgres rounds→games + FK columns rooms.round/guesses.round, schema Round→Game (schemas/round.ex→game.ex), internal API (store/tables/rooms/view/notifier/board/locks + the game.ex facade), external WIRE — /rounds→/games routes + round:→game: PubSub/WS topic + event-payload keys, error atoms :no_round→:no_game, tests + priv/round.exs→game.exs. (2) DOCS: docs/codemojex/*.md (design + the UNTRACKED architecture/roadmap/specs) + echo/apps/codemojex/docs/*.md app docs + NEW codemojex.progress.md dashboard. (3) BCS: source bcs.2.md 6 entity-round tokens + NEW bcs.todo.md for the rendered html.
- WHY: in BCS the 14-byte brand IS the entity's type (CLAUDE.md, "what is checked at every boundary"); the codemojex roadmap already canonized the entity as game/GAM with zero "round", but the live code lags entirely at RND/"round" (verified this turn: 0 GAM in lib/, 295 round line-hits). A true entity rename = re-basing the brand RND→GAM everywhere — code, storage, AND wire (Operator ruled FULL cutover incl. wire).
- WHERE: boundary = echo/apps/codemojex/** + docs/codemojex/** + docs/echo/bcs/{bcs*.md,bcs.todo.md}. OUTSIDE the echo_mq boundary → generic /x-mode; codemojex's OWN gate binds (NOT the v2 master invariant / echo_mq gate ladder).
- WHEN: now. The PROD data migration + Mini-App client cutover are Operator-run (team verifies migration up/down on a TEST DB only; never touches prod).

Environment (probed this turn): elixir 1.18.4 / erlang 28.5.0.1 (echo/.tool-versions); Valkey :6390 PONG; Postgres :5432 up; baseline 295 round line-hits lib+test, 0 GAM in lib; code tree clean at HEAD; docs/codemojex/{architecture,design,roadmap,specs}.md UNTRACKED (new, out-of-band); Operator PRE-STAGED `D docs/echo/bcs/bcs.progress.md` (EXCLUDE from every rename commit); codemoji-updated.zip/ extract IGNORED.

Solution space:
- (a) do-nothing baseline — code stays RND, roadmap says GAM → permanent code↔canon drift; the BCS brand-is-the-type law stays violated. REJECTED.
- (b) docs-only reconcile (bend docs back to round) — inverts the Operator's canon (the roadmap deliberately leads with GAM). REJECTED.
- (c) code rename but keep the wire (round: topic, /rounds routes) — a half-cutover, external contract keeps the old vocabulary; Operator explicitly ruled FULL incl. wire. REJECTED.
- (d) FULL cutover incl. wire (brand+storage+routes+topic) + the stored-data migration. CHOSEN (Operator ruling Q1).

Invariants as runnable checks (the gate):
- INV-1 completeness: grep entity-sense round|Round|RND|rounds|:no_round|round: in lib/+test/ → 0; GAM present at mint (rooms.ex) + cache kind (tables.ex).
- INV-2 gate green (in echo/apps/codemojex): asdf current; valkey 6390 PONG; TMPDIR=/tmp mix compile --warnings-as-errors; TMPDIR=/tmp mix test; ecto.migrate + ecto.rollback clean on the test DB.
- INV-3 boundary: git status --short touches ONLY the 3 surfaces; html/bcs/** unedited; the BCS English-word round (round-trip/around/rounds-away) untouched; codemoji-updated/ ignored; the Operator pre-staged bcs.progress.md deletion NOT swept into any rename commit.
- INV-4 data safety: prod migration + client cutover Operator-run; team proves up/down on a test DB; in-flight rounds drained before any prod cutover.

Smallest change that preserves correctness: a systematic, boundary-local token rename introducing NO new behavior and NO new public surface beyond the renamed names; the migration is a mechanical table/column/id-brand rename. The one genuine fork is the migration SHAPE — Path A (pre-launch/DB-resettable → edit the create migrations in place, no data migration) vs Path B (live data → a new rename+re-brand migration + drain). Venus resolves it by recon on disk and surfaces it as an Arm IF Path B (live data) is found.

Mode: Flat-L2. Formation: Venus → (Director rules any Arm) → Mars-1 → Director verify → Mars-2 harden → Apollo (HIGH-risk evaluator) → Director ship. No commit unless the Operator asks.

### T-2 — Director independent prior on the Path A/B migration fork (read-only diligence, pre-Venus-report)

Facts established on disk this turn:
1. The create migration 20260618000000_create_codemoji.exs builds table(:rounds) (L62) with FK columns rooms.round (L57) + guesses.round (L81) + index :rounds[:room] (L77) + :guesses[:round,:player] (L91) — matches the plan inventory exactly. The 20260625 migration alters :rounds.
2. BOTH migrations are COMMITTED (git ls-files lists them; git log: ac8b8842 "[codemojex] app update", 98d8dfd3 "[echo_mq] [codemojex] rename").
3. No app-root deploy config (no fly/docker/release); codemojex has NO app-local config/ dir (umbrella-level config) and no priv/repo/seeds.exs — so NO in-repo prod-DB signal.

Director prior: Path B (add a NEW rename+re-brand migration; leave the committed create-migration as history) is the canonically-safe Ecto move — editing a COMMITTED create-migration in place changes its checksum and silently no-ops on any already-migrated DB (the table would stay `rounds`). The absence of in-repo deploy config does NOT rule out live data: the Operator manages deploy out-of-band (the jonnify.fly.dev pattern), and the Operator's Q1 ruling "with the stored-data migration" anticipates data. The decisive facts — does a live DB hold `rounds` rows; Mini-App client cutover constraints — are the Operator's to confirm. On Venus's Arm the Director rules via AskUserQuestion, reconciling Venus's recon against this prior. Gate held for Venus.

### T-3 — Ground truth established (recon phase 1)

Codemojex = live Telegram emoji game at echo/apps/codemojex, OUTSIDE the echo_mq boundary (its own gate binds, not the v2 invariant). Roadmap docs/codemojex/codemojex.roadmap.md ALREADY canonized the per-play entity as "game"/`GAM` (zero "round"); live code lags ENTIRELY at `RND`/"round".
Blast radius (verified on disk, case-insensitive 'round' line-hits): 30 lib/test files carry "round"; `RND` literal = 6 occurrences (rooms.ex generate!, tables.ex kind, + 4); `GAM` in lib = 0 (confirms code lags). Other brands present and OUT OF SCOPE: RMM(1) EMS(2) GES(1) JOB(2) NOT(2) TXN(1) USR(1) CMD(1).
design.md is the as-built MIRROR and lags (still "round"/`RND` at lines 10/35/50/113-114 etc) — Mars makes it truthful post-rename. roadmap.md is canon and already game/GAM (no edit needed beyond verification).
Toolchain probed: app config lives in UMBRELLA config/ (not app-local). dev DB codemojex_dev, test DB codemojex_test (Sandbox) — both local Postgres, resettable.

### T-4 — Migration fork: decisive evidence (Path A vs B)

PROD IS CONFIGURED: echo/fly.toml app="codemoji-phoenix" (primary_region fra, [deploy] rolling, auto_rollback, min_machines_running 1, [env] DATABASE_URL-via-runtime, ECTO_IPV6); echo/config/runtime.exs reads DATABASE_URL at boot in :prod. So a deploy TARGET exists.
BUT LAUNCH-STATE = OPERATOR KNOWLEDGE, not disk-verifiable: fly.toml header says "The Operator creates the app + machines and pushes to deploy — never `fly deploy` locally"; design.md says the app is "parse-verified in the sandbox" and player identity from Telegram initData is "the one explicit gap before launch" (→ pre-launch signals). I CANNOT verify from disk whether prod has rows.
DEV/TEST = fully resettable: config/dev.exs → local Postgres `codemojex_dev`; config/test.exs → `codemojex_test` (Ecto.Adapters.SQL.Sandbox). Migrations ARE committed (git: ac8b8842, 98d8dfd3) — they are history, not scratch.
Migration shapes: 20260618000000_create_codemoji.exs creates table(:rounds) + FK columns rooms.round / guesses.round + index(:rounds,[:room]) + index(:guesses,[:round,:player]); 20260625000000 alters table(:rounds) (adds golden, gold_multiplier). Stored RND ids: an 11-char Base62 snowflake body; a prefix-swap RND→GAM preserves the body → sort order UNCHANGED.
VERDICT: this is the Operator's call (it touches prod data). Framed as a 4-part Arm (V-1/V-2 + recommendation V-3) for the Director to rule via AskUserQuestion. Recommendation: Path A (edit create-migrations in place + reset dev/test) IF the Operator confirms NO live prod rows; Path B (new rename+rebrand migration, history preserved, verified up/down on a TEST DB, Operator runs on prod) IF prod data exists.

### T-5 — Full surface inventory locked (round→game), classified by token-type

Surface 1 CODE (echo/apps/codemojex), 4 token classes — Mars must NOT blind-sed:
  (a) ENTITY-TYPE (the rename target): brand RND→GAM at rooms.ex:60 generate!("RND"), tables.ex:59 kind:"RND" (+4 RND literals: tables.ex load_round guard binary-14 is the SHAPE not "RND" — only the kind string + generate! are literals); schema schemas/round.ex→game.ex (module Codemojex.Schemas.Round→.Game, schema "rounds"→"games"); FK field :round in room.ex/guess.ex/round(self).
  (b) PUBLIC API SYMBOL (load-bearing names, change atomically with callers): round_view→game_view (view.ex def + Codemojex facade defdelegate game.ex:210 + game_controller.ex:32/37 + room_channel.ex:13); store.ex put_round/round/fetch_round + Round alias; tables.ex rounds_table/@rounds/load_round/:cm_rounds/:cm_rounds_table; rooms.ex start_round/close_round/close_if_expired (close_round delegated by Codemojex.close_now game.ex:197); notifier.ex round_result/3→game_result/3 (+ @spec + text); error atom :no_round→:no_game (game.ex:26, rooms.ex:103, game_controller.ex:38, fallback_controller.ex:20 + the "round not found" string).
  (c) EXTERNAL WIRE (hard-pinned, exact sites): topic literal "round:"→"game:" 3× (room_channel.ex:12, game.ex:132, rooms.ex:157); channel route "round:*"→"game:*" user_socket.ex:4; HTTP /rounds/:id* → /games/:id* router.ex:17-20 (4 routes: GET :id, POST guess, GET history, GET leaderboard); JSON/event map key round:→game: 6× (game_controller.ex:32, game.ex:106/121/133, rooms.ex:158, view.ex:53).
  (d) LANGUAGE/IDENTIFIER — LEAVE: Elixir round/1 BIF (scoring.ex:55 round(total/...), economy.ex Float.round, priv/scoring.exs:33); local var name `round`/`round_map`/`round_id` (board.ex/locks.ex k(round,..)=id INFIX no literal, view.ex, wallet.ex) — rename for consistency is OPTIONAL/cosmetic, gate-neutral; config key :rounds_cache_ttl_ms→:games_cache_ttl_ms (tables.ex:45 + NB the key is read with a DEFAULT so an un-renamed config still works — but rename both the read and any config/*.exs setter together).
  Tests+demo: rooms_and_rounds_story_test.exs→rooms_and_games_story_test.exs (+ feature: "Rooms and rounds"→"Rooms and games"); round tokens in settlement(16)/privacy(16)/wallet(9) story tests; test/README.md (lines 17/50/51); priv/round.exs→priv/game.exs (vars + IO.puts). DB table cm key family cm:<id>:* uses the id INFIX — NO literal "round" in Valkey keys → untouched.
  Application.ex consumer ids :cm_score/:cm_settle use "cm" not "round" → untouched (moduledoc prose "rounds + emoji sets" → "games").

### T-6 — Docs surfaces (2 + 3) locked

Surface 2 — codemojex docs:
  • docs/codemojex/codemojex.design.md (27 round hits) — the AS-BUILT MIRROR, lags entirely at round/RND; Mars makes it truthful to the renamed code (entity "round"→"game", RND→GAM, table "rounds"→"games", :cm_rounds→:cm_games, /rounds→/games, round:→game: topic, round_view→game_view). NB design.md ALSO carries 2 stale facts OUT of rename scope but worth a 1-line flag to Director: health path is /health (fly.toml + router.ex) but design.md L174 says /api/health; and design.md uses RMM/USR while roadmap/architecture use ROM/PLR (the separate reconcile).
  • docs/codemojex/codemojex.architecture.md — ALREADY game/GAM (0 entity-round; 15 "game"; uses GAM/PLR/RMP). NO RENAME — verify only. Plan-map expectation it carries "round" was WRONG.
  • docs/codemojex/codemojex.specs.md — ALREADY game/GAM (uses GAM throughout, "per-game", "Games and guesses"). NO RENAME — verify only.
  • docs/codemojex/codemojex.roadmap.md — canon, already game/GAM (the only "round" is the line-2 prose "the running code"? no — it is 'round' 2-hit, both English/none-entity; verify). NO entity edit.
  • echo/apps/codemojex/docs/: game_rules.md (8: "A Round Begins", "Round Timer", "Round Ends", "every round", "the round's category" — ENTITY, → "game"/"A Game Begins"); golden-rooms.md (10: "the round is a snapshot", "Schemas.Round", "start_round", "round's PubSub topic", table-cite rows — ENTITY → game; the Schemas.Round/start_round become Schemas.Game/start_game to match code); 02-rooms-and-emoji-sets.md:5 "Round = game in a room" → reword "A game is one play in a room" (the line literally equates them); notifications.md (4 ENTITY: "a round result"×2, "When a round closes", "the live round topic" → game).
  • docs/codemojex/notifications/notifications.design.md — ONLY the entity template L124 `"...round {round} is live"` → `"...game {game} is live"`; the other 6 hits are English "round-trip(s)" → LEAVE. notifications.aaw.design.md / cmn.1.md / emq.throttle.md round hits are ALL English "(no-)round-trip" → LEAVE ENTIRELY.
Surface 3 — BCS docs/echo/bcs: bcs.2.md ONLY, the 6 entity sites L29/45/111/231/247/259 → "game"/"game ids"; the other 5 bcs.2.md hits + ALL ~30 across bcs.0/preface/research/8/toc/appendixes are English (around/round-trip) → LEAVE. Mars must NOT touch the surrounding ROM/PLR vocabulary in bcs.2.md (that grounding is the separate RMM↔ROM reconcile).
  bcs.todo.md (Mars writes from THIS enum; Operator hand-edits html/bcs, team touches NO html): 8 entity-round sites across 7 files — html/bcs/codemojex/index.html (3: data-seg="round" <g> L258 + data-seg="round" <button> L264 + JS caption key `round:` L411 — the "the play" route segment; these 3 are a FIGURE-INTERNAL segment key, rename all 3 atomically to "game" or leave as a unit — JUDGMENT noted for Operator), html/bcs/codemojex/rooms-and-modes/template-and-mode.html:274 ("the bounded round"), html/bcs/elixir-core/otp-application/existence-not-data.html:274, the-property-store.html:281, property-stores/the-only-key.html:274, property-stores/ttl-as-structure.html:275, the-champ-database/structural-sharing.html:274. NB the-only-key.html:274 says "a room's under a ROM id, a round's under its own" — change "round"→"game" but LEAVE "ROM" (separate reconcile).

### T-7 — Director independent read of the game-model canon (pre-VenusPG-report); a material source conflict VenusPG must reconcile

Found a conflict in the on-disk source material that bears directly on the Operator's constraints:
1. TWO definitions of "Golden":
   (a) CANON — architecture.md / specs.md / roadmap.md (game/GAM, "for Chief Architect review"): Golden is a BLIND MODE of a generic Mastermind engine — feedback `none`, settlement `sealed`, exact-match ranking, top-K payout; "a new mode is a new set of policy values on the same entities, not new code." Two modes at launch = classic(live feedback `score`, settlement `live`, linear distance) + golden(blind).
   (b) golden-rooms.md (OLDER, round-based, app doc): Golden is a PRIZE-MULTIPLIER boost — `golden` bool + `gold_multiplier` (3x/5x), live linear scoring, winner-take-all, AND "the same first-mover tiers." Models Golden as an economic boost on a live room, not a blind mode.
   These conflict on what Golden IS.
2. TIERS: golden-rooms.md cites "first-mover tiers"; architecture.md/roadmap.md cite "tier claims" (EchoMQ layer); the existing `guesses` table has a `tier` column. The Operator (D-3) ruled BONUS TIERS MUST NOT EXIST + linear score → the new model STRIPS all tier mechanics, directly rejecting golden-rooms.md's tier language + guesses.tier.

Director reading of Operator intent: "Golden is the new mechanics" = Golden as the CANON's blind/sealed MODE (architecture.md is the Operator's forward design); golden-rooms.md (multiplier+tiers, round-based) is the superseded description whose first-mover tiers are now forbidden. "Existing linear score" = keep the linear distance score with NO tier bonus on top. Residual fork: the blind-mode scoring policy — exact-match ranking (canon) vs the same linear distance — needs an Operator ruling.

Gate posture: VenusPG has BOTH conflicting sources in its read list. The Director will VERIFY VenusPG's report reconciles the golden-rooms.md↔canon conflict + the tier-removal ripple; if it does not, send it back (SendMessage) before bringing the Golden-semantics + scoring-policy forks to the Operator. Gate held for VenusPG.

### T-8 — Model-redesign derivation (round→games + multi-type engine + linear-only)

The Operator redirected from Venus-1's TOKEN RENAME (round→game) to a from-scratch MODEL REDESIGN. Derivation grounded entirely on disk this session.

Inputs read (all cited):
- Forward canon (untracked, already game/GAM): docs/codemojex/codemojex.architecture.md (the "generic Mastermind engine on BCS, Golden a mode not a product"; GAM carries mode + four policies feedback/scoring/settlement/economy), codemojex.roadmap.md (B7 chapter; 17-namespace table incl. ROM/RMP/BNK/RSC), codemojex.specs.md (the feature list; "two modes at launch: classic + golden").
- Mechanics: echo/apps/codemojex/docs/golden-rooms.md (golden + gold_multiplier snapshot onto round; effective_pool/3; winner-take-all over boosted pool), codemojex.game_rules.md (THE decisive doc — explicit "30 natural scoring tiers… reserve space for future mechanics" + a whole "Future Game Extension: Tiers" section with first-mover tier badges), 01-currency-model.md, 02-rooms-and-emoji-sets.md.
- As-built lagging: docs/codemojex/codemojex.design.md (6-table model, 9-namespace table with RND not GAM, RMM not ROM, USR not PLR).
- Live code: the 2 migrations; lib/codemojex/schemas/{round,room,guess,player,transaction,emoji_set}.ex; store.ex; scoring.ex (CONFIRMED linear: points(d)=100-20*d, total/600, tier=div(total,20)); rooms.ex; tables.ex; board.ex (the first-mover bonus economy — base/ptier/bonus/tierfirst hashes, eff=base+bonus); game.ex (Guesses/ScoreWorker/Settle/facade); view.ex; economy.ex.

Key finding: the codebase carries a FULLY-BUILT tier-bonus economy (Board.record/4 ranks the leaderboard by base+first-mover-bonus via HSETNX tier claims; guesses.tier + guesses.percentage columns; the scored event's tier/first fields; Board.firsts/2; Codemojex.firsts/2). This is exactly the "BONUS TIERS" the Operator removes. Linear points total stands and becomes the sole leaderboard rank key.

The redesign: rounds→games table; a games.type discriminator + typed config for the multi-type engine (classic + golden as the two launch types, Golden modeled from golden-rooms.md); guesses.tier + guesses.percentage REMOVED (linear points only); the first-mover bonus economy removed; fresh-from-scratch schema (machine is fresh — collapse the 2 migrations into one clean initial create, drop+recreate codemojex_dev at build time); GAM/RMM/USR/EMS/GES/TXN/JOB brands UNCHANGED.

## {codemojex-game-rename-learnings} Learnings

### L-1 — Plan-map drift found (counts + the ROM/RMM grounding split)

(a) bcs.2.md carries 11 "round" hits, NOT the ~6 the plan-map estimated. The entity-token subset (→ "game") is at lines 29, 45, 111, 231, 247, 259 (6 sites: "naming a player and a round", "the round, the scores", "keyed by player and round ids", "a round's under its own", "a finished round's ephemeral state", "a round preserved for replay"). The other 5 are English ("around"/"round-trip"-class) — LEAVE.
(b) GROUNDING SPLIT confirmed: BCS prose already uses the roadmap's namespace vocabulary — bcs.2.md:231 says "a room's under a `ROM` id", and the roadmap uses ROM/RMP/PLR — while the as-built CODE + design.md use RMM(room)/USR(player). So the BCS corpus is grounded in the aspirational roadmap, not as-built. This is exactly the RMM↔ROM drift the Director flagged OUT OF SCOPE. CONSEQUENCE for THIS rename: changing "round"→"game" in bcs.2.md is safe (GAM is canon in BOTH roadmap and the target), but Mars must NOT "fix" the surrounding ROM/PLR to match code — that is the separate reconcile. Hold the rename to the round→game token only.
(c) codemojex.architecture.md + codemojex.specs.md are UNTRACKED and were NOT in the plan-map's per-file list under Surface 2 (only design.md + the 3 untracked were named). architecture.md uses "round"/`RND` heavily (it is the as-built draft); specs.md TBD. Both need scanning — surface is wider than the pre-baked list, exactly as warned.

### L-2 — "multiple type of games as described" resolves to a TWO-type launch set (classic + golden), but "as described" is split across two non-aligned descriptions

The Operator's "multiple type of games as described" has one concrete on-disk grounding: specs.md "Two modes at launch: classic (live feedback) and golden (blind)". That fixes the launch type SET = {classic, golden}. But the DESCRIPTION of golden is split: the as-built golden-rooms.md describes a boost-only LIVE golden (same linear scoring, same feedback), while the forward architecture.md/specs.md describe a BLIND golden (feedback none, sealed settlement, commit-reveal, anonymized, reduced set). The model can only NO-INVENT-ground the boost-only golden (real code); the blind-mode golden is PROPOSED with its core mechanics as explicit OPEN QUESTIONS. Flagged as Arm V-6. No third game type is "described" anywhere on disk — the engine is built extensible (the type discriminator) but only two types are grounded. Recorded so the gap is the Operator's to close, not Mars's to invent.

## {codemojex-game-rename-decisions} Decisions

### D-1 — Boundary + the 3-register naming discipline (locked)

BOUNDARY: edits land ONLY in echo/apps/codemojex (code + tests + priv + app docs/) + docs/codemojex/codemojex.{design,progress}.md + docs/echo/bcs/bcs.2.md + docs/echo/bcs/bcs.todo.md (NEW). The team touches NO rendered html/bcs/** (Operator hand-edits from bcs.todo.md). Architect (Venus) edits ONLY docs/specs (this rung: codemojex.progress.md NEW + the brief artifacts); Mars executes the mechanical rename across code+docs from the brief. Do NOT touch: the Operator's pre-staged D docs/echo/bcs/bcs.progress.md deletion; codemoji-updated/ + codemoji-updated.zip (stale extract, IGNORE); any echo_mq/echo_store/echo_wire/echo_data app (codemojex is OUTSIDE that boundary — its own per-app gate binds, NOT the v2 invariant).
3-REGISTER NAMING (state in the brief, avoid bare-noun ambiguity): the ENGINE = "the Game system" (capital-G Mastermind engine; not yet a code module); the per-play ENTITY = "a game"/`GAM` (THE rename target); the PRODUCT = "Codemojex"/"the game". A sentence like "a game of Codemojex" = product; "the game's secret" = entity; "the Game system scores it" = engine.
OUT OF SCOPE (flag only, do NOT fix): the RMM↔ROM + RMP room/membership namespace drift between design.md (RMM room / USR player) and roadmap+architecture+bcs.2.md (ROM room / PLR player) — a SEPARATE reconcile. Mars changes round→game tokens only and leaves the surrounding ROM/PLR/RMM/USR vocabulary exactly as found.

### D-2 — The rename is a token-CLASS operation, not a string replace (locked craft)

Mars must classify every "round" hit into one of 4 classes and act per class (NO blind sed — a `s/round/game/g` corrupts Kernel.round/1 arithmetic, Float.round, html Math.round/linecap:round, and English "around/round-trip"):
  (1) ENTITY-TYPE → rename: the RND brand string + "rounds" table + Schemas.Round + :round FK + :cm_rounds cache + entity prose "a round".
  (2) PUBLIC-API SYMBOL → rename atomically with ALL callers: round_view, put_round/round/fetch_round, start_round/close_round/close_if_expired, rounds_table/load_round, round_result/3, :no_round.
  (3) EXTERNAL-WIRE → rename (the FULL-cutover Operator ruling): "round:" topic, "round:*" channel, /rounds route, round: JSON key.
  (4) LANGUAGE/IDENTIFIER → LEAVE (round/1 BIF, Math.round, linecap:round, English round-trip/around) OR cosmetic-only (local var `round`, which is a correctness-neutral consistency rename).
The gate is the proof the classes were honored: TMPDIR=/tmp mix compile --warnings-as-errors (an over-rename of a BIF or a missed caller fails to compile) + TMPDIR=/tmp mix test --include valkey (Valkey 6390 + Postgres up; the rooms_and_games/settlement/privacy stories exercise the renamed wire end-to-end) + a residual-grep proof: after the rename, /usr/bin/grep -rniE '\b(RND|round_view|:cm_rounds|"round:"|/rounds|:no_round)\b' echo/apps/codemojex/lib must be 0 (entity/api/wire fully migrated), while Kernel.round( and English round-trip remain.

### D-3 — Operator pivot ruling on the migration Arm: NO RENAME; reinitialize schema from scratch; redesign the game-engine model

The Operator ruled the migration Arm (supersedes T-2 + Venus's V-1/V-2/V-3 Path-A/B/drain alternatives):
1. codemoji-phoenix is a FRESH machine — NO prod data. So NO rename migration (neither Path A in-place edit nor Path B rename-migration) and NO data migration.
2. "YOU MUST NOT RENAME." The schema + migrations are REINITIALIZED FROM SCRATCH (a fresh from-scratch schema), not incremental rename migrations ("not migrations").
3. Local dev: DROP the :5432 postgres `codemojex_dev` database and RECREATE it once the new Ecto model is ready (a build-time action Mars performs; destructive on the LOCAL dev DB only — Operator-instructed).
4. SCOPE EXPANDS: a dedicated Venus-Postgres architect designs a NEW game-engine data model supporting MULTIPLE TYPES OF GAMES (Golden = the new mechanic), with LINEAR scoring and NO BONUS TIERS — "BONUS TIERS MUST NOT EXISTS. There are no such mechanics. Existing linear score." The existing guesses.tier/percentage bonus modeling is REMOVED; linear `points` stands.
5. The per-play entity remains `game`/GAM.
6. This is now a DESIGN-FIRST rung: no production code before the Operator-approved model. Venus-1's Stage-1 entity/public-API/external-wire/docs/bcs inventory remains valid build input; its migration-rename section is superseded by this from-scratch redesign.

### D-4 — Entity = games / brand GAM (the per-play instance)

The rounds table → games; the per-play entity brand RND → GAM at the key builder (rooms.ex generate!, tables.ex kind). The Operator named the entity game/GAM and the roadmap+architecture already canonize it. All OTHER brands UNCHANGED: RMM (room), USR (player), EMS (emoji set), GES (guess), TXN (transaction), JOB (bus job), NOT (notification), CMD (command). The design.md drift RMM↔ROM / USR↔PLR (forward canon uses ROM/PLR; code uses RMM/USR) is a SEPARATE reconcile, explicitly out of this model design's scope per the Operator directive.

### D-5 — BONUS TIERS removed; linear points is the sole score and rank

HARD Operator constraint: "BONUS TIERS MUST NOT EXISTS. There are no such mechanics. Existing linear score." Removed from the model:
(a) guesses.tier column (was div(total,20)) — DROP.
(b) guesses.percentage column (was total/600*100) — DROP (a derived display value, recomputable on read if ever surfaced; not stored).
(c) the entire first-mover tier-bonus economy: Board.record/4's tier-claim arm + the Valkey hashes cm:{game}:ptier / :bonus / :tierfirst, Board.firsts/2, Board.claim_tier, the Codemojex.firsts/2 facade delegate, and the scored event's tier/first fields.
KEPT: the linear scoring engine Scoring.score/2 (points(d)=100-20*d summed to 600); the leaderboard now ranks by the player's BEST LINEAR points total (cm:{game}:board ZSET scored by the raw best total, not base+bonus). guesses.points stands. The cm:{game}:base hash (the player's best total) is retained as the ZSET feed; only the bonus layer is removed.
NOTE the canon-drift this creates (flagged as Arm V-2): the forward roadmap B7.4.2 ("the thirty tiers, the live leaderboard's ladder") + B7.3 ("tier claims") + game_rules.md "Future Game Extension: Tiers" still describe the removed mechanic — a follow-up canon reconcile is owed.

## {codemojex-game-rename-alternatives} Alternatives

### V-1 — Migration Path A: edit create-migrations in place (NO live prod data)

RATIONALE: if no deployed prod DB carries rows, the migrations are just the recipe for a fresh schema — edit them so a fresh DB comes up as `games` directly; no data to preserve, no rebrand of stored ids needed.
5W: WHO Mars edits the 2 committed migrations + the test_helper/dev reset; WHAT 20260618000000_create_codemoji.exs table(:rounds)→table(:games), FK rooms.round→rooms.game, guesses.round→guesses.game, index(:rounds,[:room])→index(:games,[:room]), index(:guesses,[:round,:player])→index(:guesses,[:game,:player]); 20260625000000 alter table(:rounds)→table(:games); WHEN in the build rung; WHERE echo/apps/codemojex/priv/repo/migrations/; WHY simplest, leaves a clean single-history fresh DB matching the renamed schema.
STEELMAN: pre-launch is the documented state (design.md "parse-verified in the sandbox", "the one explicit gap before launch"); editing committed-but-pre-launch migrations is normal when the schema has never shipped to a DB with users; the create-migration is the source of truth for a fresh `mix ecto.create && mix ecto.migrate`, and dev/test are SQL-Sandbox/resettable. No rebrand migration to verify.
STEWARD (what it forecloses / risk): if ANY prod DB has real RND rows, Path A SILENTLY leaves them stranded under the old table — a `mix ecto.migrate` on prod would try to CREATE `games` (the create-migration already ran as `rounds`, so the new edited version's checksum mismatches Ecto's schema_migrations → migration-integrity error, or worse a divergent schema). Path A is SAFE ONLY under an explicit Operator confirmation of NO live data. Verification: drop+recreate dev/test, mix ecto.migrate, run the --include valkey suite green.

### V-2 — Migration Path B: NEW rename+rebrand migration (live prod data exists)

RATIONALE: if a deployed DB carries real RND rows, history is sacred — keep the create-migrations byte-unchanged and add a forward migration that renames the table and re-brands the stored ids, so prod migrates in place with sort order and FKs intact.
5W: WHO Mars authors a NEW migration (e.g. 20260626000000_rename_rounds_to_games.exs); WHAT in `up`: rename table rounds→games; rename rooms.round→rooms.game + guesses.round→guesses.game; rebrand stored ids RND…→GAM… via an UPDATE that swaps the 3-char prefix preserving the 11-char Base62 body (UPDATE games SET id = 'GAM' || substr(id,4); UPDATE rooms SET game = 'GAM' || substr(game,4) WHERE game IS NOT NULL; UPDATE guesses SET game = 'GAM' || substr(game,4)); rename the indexes; in `down`: the exact inverse (GAM→RND, games→rounds); WHEN build rung authors+verifies up/down on a TEST DB, OPERATOR runs on prod; WHERE migrations/ as new history; WHY zero data loss, sort order unchanged (prefix swap keeps the time-ordered body), FKs stay referentially consistent because both ends are rebranded in one transaction.
STEELMAN: the Operator's phrase "with the stored-data migration" anticipates data; a prod app (fly.toml codemoji-phoenix, rolling deploy, auto_rollback, min_machines_running 1) is configured to run; a reversible, transactional, in-place migration is the standard safe path and is independently testable (up→assert GAM rows + FK integrity → down→assert RND restored).
STEWARD (forecloses / risk): heavier — Mars must verify up AND down on a populated TEST DB (seed RND rows, migrate up, assert game table + GAM ids + FK joins resolve, migrate down, assert byte-restored); the cache `kind:"RND"`→"GAM" and the L2 ecc: frame change means any WARM L2/L1 cache entry under the old RND version is cold-missed post-cutover (harmless: coherence :none, immutable, re-fills from the now-GAM Postgres row) — state this so it is not mistaken for data loss; the Operator owns the prod run + the rollback window. The in-flight-round drain (an open RND round mid-play at cutover) is a sub-decision: simplest is a maintenance-window cutover (no open games), else the down-path is the safety net.

### V-3 — RECOMMENDATION (the fork is the Operator's; Director rules via AskUserQuestion)

The single deciding fact is NOT on disk: does the deployed codemoji-phoenix prod DB carry real RND rows? Disk says prod is CONFIGURED (fly.toml + runtime.exs DATABASE_URL) but DOCUMENTED pre-launch (design.md "parse-verified in the sandbox" / "the one explicit gap before launch"; fly.toml "the Operator creates the app + machines and pushes to deploy"). The Operator's phrase "with the stored-data migration" leans toward data existing.
RECOMMENDATION for the Director's AskUserQuestion to the Operator — a single question with two answers:
  • "Pre-launch — no live prod rows yet (dev/test resettable)" → PATH A: edit the create-migrations in place; reset dev/test; simplest, one clean history. (V-1)
  • "Live data exists in the deployed prod DB" → PATH B: keep create-migrations as history; add the reversible rename+rebrand migration; team verifies up/down on a TEST DB; OPERATOR runs it on prod. (V-2)
DEFAULT IF UNREACHABLE: Path B (the conservative arm — it is safe whether or not data exists: on an empty DB the rename+rebrand UPDATEs are no-ops, and history stays clean; the only cost is the extra migration file + the up/down test). Path A is UNSAFE if data exists (silent stranding / checksum mismatch), so when uncertain, B dominates. Sub-fork (only under B + a live, always-on deploy): the in-flight-round drain — recommend a maintenance-window cutover (settle/close open games first) so no open RND round is mid-play during the prefix swap; the down-path is the fallback. Surface this sub-fork only if the Operator picks B AND declines a maintenance window.

### V-4 — The multi-game-type modeling shape (RECOMMEND Arm A)

Rationale: the model must represent multiple game types extensibly, with Golden as one type, without gold-plating. Three shapes considered.

Arm A — discriminator + typed config on one games table (RECOMMENDED). A games.type text column ("classic" | "golden", CHECK-constrained to the launch set) + the engine policies as explicit typed columns already snapshotted onto the game (feedback, scoring, settlement, economy as text policy words, defaulted per type) + the golden boost columns (golden bool, gold_multiplier int) folded in. One table, one row per play, the type selects behavior in code (a policy lookup keyed by type). 5W: WHO=Mars builds one Game schema; WHAT=a single games table with a type discriminator; WHEN=at game start the type+policies snapshot from the room; WHERE=Postgres games + the EchoStore :cm_games cache; WHY=BCS keeps the entity ONE branded id (GAM) across every tier — a per-type table would fork the identity. Steelman: matches the canon VERBATIM (architecture.md: "a GAM holds… a mode, and four policies"; "No new entity types separate them"); the existing rooms/round already snapshot golden+gold_multiplier this way, so it is the minimal delta; immutable-for-life so the cache/coherence:none story is unchanged. Steward: the future-type cost is one new type word + its policy defaults + a code branch, never a migration; Postgres CHECK bounds the type set so an unknown type cannot be written.

Arm B — single-table-inheritance with per-type nullable columns. One games table but every type's distinct fields as nullable columns (e.g. a golden-only commitment/nonce nullable, a classic-only field nullable). Steelman: no JSON, fully typed+queryable per field. Against: column sprawl as types grow; nullable-per-type is the STI smell the BCS "data not behaviour" discipline avoids; the canon already frames the variation as POLICY (a small fixed enum) not as distinct field sets.

Arm C — a games.config jsonb bag for type-specific knobs. Type discriminator + an opaque jsonb config. Steelman: maximally extensible, zero migration per type. Against: loses the CHECK-constraint + queryability the money-adjacent floor wants; the canon's four policies are a FIXED small vocabulary (feedback score|none, settlement live|sealed, …), not an open bag — a typed column set models them honestly and a jsonb bag overshoots. RIGHT-SIZE violation (gold-plating for types not yet specified).

Recommendation: Arm A. It is the canon's own shape, the minimal delta over the as-built snapshot, keeps the entity one branded id, and bounds the type set by CHECK. Golden's commitment/nonce (provably-fair, from specs.md/architecture.md) is the one genuinely type-specific pair — model it as nullable columns on games (null for classic), which is a bounded A+B blend, NOT an open jsonb. The Operator rules the type set + whether commitment/nonce ships in this model or defers.

### V-5 — The tier-removal vs forward-canon drift (RECOMMEND Arm A: remove now, reconcile canon as a flagged follow-up)

Rationale: D-5 removes the bonus-tier economy per the HARD Operator constraint, but the forward canon (roadmap.md B7.4.2 "the uniform twenty-point gaps form thirty tiers, the live leaderboard's ladder"; B7.3 "tier claims"; game_rules.md whole "Future Game Extension: Tiers" section) still teaches it. A model that removes tiers leaves the canon describing a mechanic the code no longer has.

Arm A — remove the mechanic from the model now; FLAG the canon docs for a separate reconcile (RECOMMENDED). 5W: WHO=Mars removes the bonus economy from code+schema; the canon-doc reconcile is a follow-up rung (Venus). WHAT=guesses.tier/percentage dropped, Board bonus layer gone, leaderboard ranks raw linear best; roadmap/game_rules tier sections marked [RECONCILE] owed. WHEN=now for the model, canon reconcile next. WHERE=schema+Board+game_rules.md+roadmap.md. WHY=the Operator's constraint is HARD and present-tense ("There are no such mechanics"); the canon is forward/aspirational and lags, exactly the lag this rung exists to close. Steelman: honors the Operator verbatim; keeps the model honest (no stored column for a removed mechanic); the linear score — the thing the Operator says "stands" — is untouched; the drift is a documentation debt, not a code risk. Steward: the canon reconcile is one bounded follow-up; until then a [RECONCILE] marker in the design doc records the gap so it is not mistaken for an oversight.

Arm B — keep tier as a derived DISPLAY value (recompute div(total,20) on read), remove only the BONUS (first-mover) economy. Steelman: preserves the roadmap's "thirty tiers" ladder as a pure view of the linear score (no stored column, no bonus) so the canon stays partly true; a tier badge could still render without any bonus mechanic. Against: the Operator said "BONUS TIERS MUST NOT EXISTS" AND "There are no such mechanics" — the safer literal reading removes the tier concept from the model surface entirely, not just the bonus; a derived tier invites the bonus back. Surface it, but A is the literal-constraint reading.

Arm C — keep the bonus economy (reject the constraint). Listed only as the do-nothing baseline; CONTRADICTS the HARD Operator constraint — not viable.

Recommendation: Arm A. Remove the tier+bonus economy from the model per the literal HARD constraint; mark the forward-canon tier sections [RECONCILE] as a flagged follow-up (not built here). If the Operator wants the leaderboard to still SHOW a tier badge as pure linear-score display (no bonus), that is Arm B — a one-line Operator ruling that keeps a recompute-on-read tier with zero stored column and zero bonus.

### V-6 — Golden's depth in THIS model: boost-only vs full blind-mode (RECOMMEND Arm A: ship the as-built boost-only Golden; defer the blind/sealed/commit-reveal depth as flagged scope)

Rationale: "Golden is the new mechanics" but the canon describes TWO different Goldens. (1) The AS-BUILT golden-rooms.md: a platform-boosted room class — golden bool + gold_multiplier, winner-take-all over the boosted pool, otherwise an ORDINARY live game with the same six-emoji secret, same linear scoring, same live feedback. (2) The FORWARD architecture.md/specs.md Golden: a BLIND mode — feedback none, settlement sealed (one batch at close, top-K), a reduced emoji set, all-pay economy, a commit-reveal provably-fair secret (commitment+nonce columns), an anonymized leaderboard. These are materially different data models.

Arm A — model Golden as the AS-BUILT boost-only type now; DEFER the blind/sealed/commit-reveal depth as flagged future scope (RECOMMENDED). 5W: WHO=Mars adds golden+gold_multiplier (already present on rooms/round) to the new games model + the type discriminator; the commitment/nonce/sealed-settlement/reduced-set columns are NOT added yet. WHAT=games.type="golden" selects the boost economy (effective_pool) over an otherwise-classic live game. WHEN=now; the blind-mode depth is a later rung when its mechanics are specified+approved. WHERE=games table (type + golden + gold_multiplier), Economy.effective_pool/3 unchanged. WHY=the as-built golden is REAL on disk (golden-rooms.md, economy.ex, rooms.ex) and NO-INVENT-grounded; the forward blind-mode is PROPOSED (architecture.md is "a draft for review" with open questions on commitment scheme, settlement atomicity, anonymization) — inventing its schema now violates NO-INVENT and over-builds. Steelman: the model stays grounded in shipped code; the type discriminator + nullable type-specific columns (V-1) leave a clean seam to add feedback=none/settlement=sealed/commitment/nonce later WITHOUT a rename or a re-found identity; the Operator gets a working two-type engine (classic live + golden boost) now. Steward: adding the blind depth later is additive columns on games (nullable commitment/nonce, the policy words flip per type) — bounded, no identity churn.

Arm B — model the full forward blind-mode Golden now (feedback none, sealed settlement, reduced set, commitment+nonce, anonymized leaderboard). Steelman: matches the roadmap/specs target; one build instead of two. Against: VIOLATES NO-INVENT — the commitment scheme, the sealed top-K payout curve, the anonymization mapping, and the reduced-set sizing are all explicit OPEN QUESTIONS in architecture.md "for the Chief Architect and legal review", not specified mechanics; building a schema for unspecified mechanics is invention; it is also the gold-plating the right-size precept forbids.

Recommendation: Arm A. Ship the as-built boost-only Golden as the second game type now (it is real + grounded); model the type discriminator + nullable type-specific seam so the blind-mode depth lands additively later; FLAG the forward blind-mode mechanics as a recorded "as described" gap the Operator must specify before they can be modeled. The Operator rules whether boost-only Golden suffices for this model or the blind-mode depth must be specified+included now.

## {codemojex-game-rename-report} Report

### Y-1 — Stage-1 reconcile + brief: BUILD-GRADE (1 Operator fork to rule first)

VERDICT: build-grade — every cited symbol/route/field re-found on disk; the only unfixed item is the migration fork (§3), which is the Operator's call by design (touches prod data) and must be ruled before Mars touches a migration.
DELIVERABLES (docs only — no production code edited):
 • docs/codemojex/codemojex.progress.md (NEW dashboard — rolls up B7.1–B7.6 PLANNED, opens the rename rung HIGH, records the RMM↔ROM out-of-scope follow-up; house voice of emq.progress.md).
 • docs/codemojex/codemojex-game-rename.brief.md (NEW — the authoritative brief: the 3-register naming discipline, the 4-token-class rename law, surface-by-surface file:line inventory across code/docs/BCS, the migration Path A/B fork, the gates, the build DAG, 4 agent stories R-1..R-4).
 • the aaw ledger docs/codemojex/codemojex-game-rename.progress.md (T-1..T-6, D-1/D-2, V-1/V-2/V-3, L-1, this Y-1).
KEY PLAN-MAP DRIFT CORRECTED: (1) codemojex.architecture.md + codemojex.specs.md are ALREADY game/GAM — VERIFY-ONLY, not edit targets (the plan map expected "round"). (2) bcs.2.md has 11 round hits not ~6 (only 6 are entity). (3) html/bcs entity-round = exactly 8 sites / 7 files, enumerated for bcs.todo.md, with the html/bcs/codemojex/index.html data-seg="round" trio flagged as a figure-internal-segment JUDGMENT call (rename all 3 or none). (4) NO-INVENT line drawn: leave Kernel.round/1 (scoring.ex:55), Float.round, Math.round, English round-trip, and the ROM/RMM/PLR/USR vocabulary (the separate reconcile).
TWO STALE design.md facts flagged OUT of rename scope: health path is /health (fly.toml+router) but design.md L174 says /api/health; design.md keys room at RMM/player at USR while the canon uses ROM/PLR. Neither is part of round→game.
THE FORK FOR THE OPERATOR (Director → AskUserQuestion): does the deployed codemoji-phoenix prod DB carry real RND rows? → Path A (edit create-migrations in place, reset dev/test) if pre-launch; Path B (NEW reversible rename+rebrand migration, history preserved, team proves up/down on a test DB, Operator runs prod) if live data. DEFAULT-IF-UNREACHABLE = Path B (safe either way; A is unsafe if data exists). Disk says prod is CONFIGURED but documented PRE-LAUNCH; the Operator's "with the stored-data migration" leans toward data.

### Y-2 — Game-engine model design COMPLETE (BUILD-GRADE pending Operator approval of the §10 Arms)

Deliverable: docs/codemojex/codemojex.game-model.design.md — the from-scratch model redesign for a multi-game-type engine. Grounded entirely on disk this session; no production code edited.

The new schema (7 tables): players(USR)/transactions(TXN)/emoji_sets(EMS) UNCHANGED; rooms(RMM) gets round→game FK + a type column; games(GAM, was rounds/RND) gets a type discriminator + the four policy columns (feedback/scoring/settlement/economy) + golden/gold_multiplier folded in; guesses(GES) gets round→game FK and DROPS tier + percentage (linear points only). Valkey: the bonus layer (cm:{game}:ptier/bonus/tierfirst) REMOVED; the board ZSET ranks raw best linear points.

Game-type abstraction (Arm V-1=A): one games table + a type CHECK ('classic'|'golden') + explicit typed policy columns snapshotted from the room at start — the canon's own "GAM holds a mode + four policies, no new entity types" shape, the minimal delta, keeps the entity one GAM id. Golden modeled (Arm V-3=A) as the AS-BUILT boost-only type (golden/gold_multiplier + effective_pool, live feedback); the forward blind-mode Golden is PROPOSED (its commit-reveal/sealed/anonymized mechanics are explicit open questions in architecture.md) — deferred behind the type/policy seam, additive later, NO-INVENT.

Bonus tiers (Arm V-2=A, HARD constraint): guesses.tier + percentage dropped; Board.record/4→record/3 (tier-claim arm + firsts/2 removed); the scored event drops tier/first. Linear Scoring.score/2 stands as the sole score + rank. NOTE: players.bonus_diamonds is a WALLET bucket, NOT a game tier — KEPT (do-not-over-remove flag).

Reinitialization (Arm V-4=A): collapse the 2 migrations into one clean initial create; Mars runs mix ecto.drop/create/migrate on codemojex_dev (config/dev.exs:14) when the model is ready (Operator-authorized).

Four Arms need Operator approval (V-1..V-4, recommendations each); one "as described" gap recorded (L-2: the launch type set is {classic,golden} — the only types described on disk; Golden's description is itself split between as-built boost-only and forward blind-mode). Canon-drift [RECONCILE] flagged: roadmap B7.4.2/B7.3 + game_rules.md still teach the removed tiers — a follow-up canon reconcile owed.

Stories R-1..R-6 (Given/When/Then, INV-1..INV-7) are the build's acceptance. Ledger: T-8, D-4/D-5, V-4/V-5/V-6, L-2.
