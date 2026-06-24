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
Blast radius (verified on disk, case-insensitive 'round' line-hits): 30 lib/test files carry "round"; `RND` literal = 6 occurrences (rooms.ex generate!, tables.ex kind, + 4); `GAM` in lib = 0 (confirms code lags). Other brands present and OUT OF SCOPE: ROM(1) EMS(2) GES(1) JOB(2) NOT(2) TXN(1) USR(1) CMD(1).
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
  • docs/codemojex/codemojex.design.md (27 round hits) — the AS-BUILT MIRROR, lags entirely at round/RND; Mars makes it truthful to the renamed code (entity "round"→"game", RND→GAM, table "rounds"→"games", :cm_rounds→:cm_games, /rounds→/games, round:→game: topic, round_view→game_view). NB design.md ALSO carries 2 stale facts OUT of rename scope but worth a 1-line flag to Director: health path is /health (fly.toml + router.ex) but design.md L174 says /api/health; and design.md uses ROM/USR while roadmap/architecture use ROM/PLR (the separate reconcile).
  • docs/codemojex/codemojex.architecture.md — ALREADY game/GAM (0 entity-round; 15 "game"; uses GAM/PLR/RMP). NO RENAME — verify only. Plan-map expectation it carries "round" was WRONG.
  • docs/codemojex/codemojex.specs.md — ALREADY game/GAM (uses GAM throughout, "per-game", "Games and guesses"). NO RENAME — verify only.
  • docs/codemojex/codemojex.roadmap.md — canon, already game/GAM (the only "round" is the line-2 prose "the running code"? no — it is 'round' 2-hit, both English/none-entity; verify). NO entity edit.
  • echo/apps/codemojex/docs/: game_rules.md (8: "A Round Begins", "Round Timer", "Round Ends", "every round", "the round's category" — ENTITY, → "game"/"A Game Begins"); golden-rooms.md (10: "the round is a snapshot", "Schemas.Round", "start_round", "round's PubSub topic", table-cite rows — ENTITY → game; the Schemas.Round/start_round become Schemas.Game/start_game to match code); 02-rooms-and-emoji-sets.md:5 "Round = game in a room" → reword "A game is one play in a room" (the line literally equates them); notifications.md (4 ENTITY: "a round result"×2, "When a round closes", "the live round topic" → game).
  • docs/codemojex/notifications/notifications.design.md — ONLY the entity template L124 `"...round {round} is live"` → `"...game {game} is live"`; the other 6 hits are English "round-trip(s)" → LEAVE. notifications.aaw.design.md / cmn.1.md / emq.throttle.md round hits are ALL English "(no-)round-trip" → LEAVE ENTIRELY.
Surface 3 — BCS docs/echo/bcs: bcs.2.md ONLY, the 6 entity sites L29/45/111/231/247/259 → "game"/"game ids"; the other 5 bcs.2.md hits + ALL ~30 across bcs.0/preface/research/8/toc/appendixes are English (around/round-trip) → LEAVE. Mars must NOT touch the surrounding ROM/PLR vocabulary in bcs.2.md (that grounding is the separate ROM↔ROM reconcile).
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
- As-built lagging: docs/codemojex/codemojex.design.md (6-table model, 9-namespace table with RND not GAM, ROM not ROM, USR not PLR).
- Live code: the 2 migrations; lib/codemojex/schemas/{round,room,guess,player,transaction,emoji_set}.ex; store.ex; scoring.ex (CONFIRMED linear: points(d)=100-20*d, total/600, tier=div(total,20)); rooms.ex; tables.ex; board.ex (the first-mover bonus economy — base/ptier/bonus/tierfirst hashes, eff=base+bonus); game.ex (Guesses/ScoreWorker/Settle/facade); view.ex; economy.ex.

Key finding: the codebase carries a FULLY-BUILT tier-bonus economy (Board.record/4 ranks the leaderboard by base+first-mover-bonus via HSETNX tier claims; guesses.tier + guesses.percentage columns; the scored event's tier/first fields; Board.firsts/2; Codemojex.firsts/2). This is exactly the "BONUS TIERS" the Operator removes. Linear points total stands and becomes the sole leaderboard rank key.

The redesign: rounds→games table; a games.type discriminator + typed config for the multi-type engine (classic + golden as the two launch types, Golden modeled from golden-rooms.md); guesses.tier + guesses.percentage REMOVED (linear points only); the first-mover bonus economy removed; fresh-from-scratch schema (machine is fresh — collapse the 2 migrations into one clean initial create, drop+recreate codemojex_dev at build time); GAM/ROM/USR/EMS/GES/TXN/JOB brands UNCHANGED.

### T-9

T — Director verification of VenusPG's game-model design (design-phase verify, pre-Operator-approval)

Read docs/codemojex/codemojex.game-model.design.md in full + spot-checked the load-bearing as-built grounding on disk:
- economy.ex:34-36 effective_pool/3 (pool*mult when golden) — the Golden boost is AS-BUILT → V-3 Arm A ships real code, not invented mechanics.
- scoring.ex:17 points(d)=100-20*d (summed to 600) is the existing linear score; scoring.ex:32 tier(total)=div(total,20) + a percentage — confirms tier/percentage are real and removable.
- board.ex:5-30 the first-mover tier-bonus layer (record/4, claim_tier, ptier/bonus/tierfirst hashes, +30/round) is real — exactly what D-3 removes.
- guess.ex:13-14 fields :percentage + :tier are in the cast list but NOT in validate_required(L22) — clean to drop.

VERDICT: the design is real, internally consistent, fully grounded (every table/column/policy/Golden rule cites a real schema/migration/canon doc), honors all 5 HARD constraints (§0), reconciles the T-7 source conflict (Golden boost-only-now / blind-deferred-behind-the-seam; tiers stripped), and is BCS-faithful (one `games` table + a `type` discriminator, NOT per-type tables — a per-type table forks the GAM identity). Right-sized: two grounded types {classic, golden} + an extensible policy seam, no gold-plating.

NIT for Mars (non-blocking): §2 says "Seven tables" but the delta table lists six (players/transactions/emoji_sets/rooms/games/guesses); the 7th is presumably `notifications` (the 20260625 golden_rooms_and_notifications migration). The collapsed single initial-create must account for it.

Director ratifies the directive-literal / BCS-mandated / implementation Arms in a separate D-n (V-1 Arm A + the games_type CHECK; V-4 Arm A collapse-to-one-create; §7 keep percentage computed-not-stored). The THREE genuine design-INTENT forks go to the Operator via AskUserQuestion this turn: (1) V-3 Golden depth boost-only-vs-blind; (2) V-2 tier-display none-vs-ladder; (3) L-2 type-set {classic,golden}-vs-more. Mars does not build until these are ruled.

### T-10 — Operator-ruled continuation: blind-mode Golden + tier removed entirely + spec ladder

The Operator ruled the three intent forks: (1) V-3 → SPECIFY+BUILD blind/sealed Golden NOW (not boost-only); (2) V-2 → tier REMOVED ENTIRELY (no column, no badge, no display ladder; leaderboard ranks raw linear points); (3) L-2 → CLASSIC+GOLDEN launch set + author the upfront spec-driven rung decomposition. Director ratified: V-1 Arm A + games_type CHECK; V-4 Arm A (one clean initial create); §7 percentage computed-not-stored (tier fn + key removed).

Blind-mode grounding re-pulled on disk (NO-INVENT, cite the line):
- commit-reveal: architecture.md "Provably-fair secret" §; specs.md:53-56 (publish a commitment over secret+nonce on the GAM at open; keep secret+nonce server-side sealed; at close reveal + expose so a player recomputes+verifies; binding). → commitment + nonce columns on games.
- sealed settlement: architecture.md "Data flow — a Golden Room" (one pass scores every GES vs revealed secret, ranks, pays top K from the bank as TXN, records rake → settled); specs.md:47 (close on timer, one pass, pay top K).
- feedback none + privacy: architecture.md "Data flow — a Golden Room" (channel carries timer+state only, no results until reveal); roadmap.md B7.1.3 (not even a score leaks until reveal).
- reduced set: specs.md:46 (reduced emoji set, e.g. 18 or 24 cells); architecture.md:14 (reduced symbol set).
- state machine: specs.md:36 (scheduled→open→active→revealing→settling→settled→voided) vs as-built open|closed (rooms.ex/schemas).
- anonymized leaderboard: architecture.md "Anonymization" + specs.md:49 — depends on RMP membership (a per-game alias on the membership). RMP is OUT OF SCOPE (no membership table as-built). GAP flagged.

THREE genuine grounding GAPS found (flag, do not invent): (a) blind settlement pays "top K from the BANK" + "records the rake" — but BNK bank is out-of-scope (no bank table; as-built pays winner-take-all from the game's own prize_pool). (b) the anonymized leaderboard needs RMP membership — out of scope. (c) scoring-unification: architecture.md:59 calls blind an "exact-match RANKING" while the Operator's HARD #3 is "Existing linear score" + roadmap.md B7.4.1 scores blind GES on the SAME linear distance scale → a real fork (V-7).

Continuation deliverables: (A) expand game-model.design.md to blind-mode; (B) author the rung ladder + a codemojex specs home (mirror emq: docs/codemojex/specs/<rung>.{md,stories.md,llms.md} + a progress dashboard) + the FOUNDING rung triad (the settled core, buildable first); (C) fold the rulings. New Arms: V-7 scoring-unification, V-8 state-machine shape, V-9 regulatory/age gating seam (if schema-shaping), V-10 specs-home structure.

### T-11

T — Director pre-read of the blind-mode spec; the verification criteria for VenusPG's expanded design

Read codemojex.specs.md in full. KEY: the blind mode is SPECIFIED on disk (specs.md §43-56), NOT merely an "open question" — VenusPG can ground the schema (NO-INVENT). What is spec'd: feedback none (§45); reduced emoji set 18/24 (§46); close-on-timer + one sealed settlement, top-K from the bank (§47); all-pay attempt economy (§48); anonymized leaderboard, neutral names (§49); commit-reveal — commitment over secret+nonce at open, sealed server-side, reveal+verify at close, settle against revealed secret (§51-56); the GAM state machine scheduled/open/active/revealing/settling/settled/voided (§36). Only the ECONOMIC/REGULATORY levers (house participation, pool balancing, jurisdiction/age gating — §106 + architecture.md:58) are genuinely open → config/launch-gate, NOT schema-blocking.

The verification criteria for VenusPG's report (the gate I will hold):
1. Blind-mode schema grounds in specs.md §43-56 + architecture.md (commit-reveal columns, sealed top-K, reduced set, anonymized leaderboard, the state machine) — every mechanic cited, none invented.
2. The scoring-unification fork (architecture.md:59) ruled or Arm'd: prefer UNIFY on linear distance (the Operator's "existing linear score"), with settlement (live vs sealed top-K) the only difference — no new exact-match ranker invented.
3. The state machine (scheduled→…→voided) modeled; classic mapped onto the same machine.
4. The economic/regulatory levers DEFERRED as config/launch-gate, not invented.
5. The FOUNDING rung stays on the AS-BUILT brands (USR/ROM/GAM/GES/EMS/TXN) — it must NOT smuggle in the forward PLR/ROM/RMP/BNK (the deferred reconcile, out of scope).
6. The rung ladder right-sized: engine core + the two modes upfront; commerce/growth/analytics/LiveAdmin (BNK/PKG/ORD/SHR/AEV) deferred with their systems.
Gate held for VenusPG's expanded design + the upfront-rung specs.

### T-12 — UNDERSTAND/EXPAND: the codemojex-game-rename EXTENSION run (Operator codemojex-ship Stage 2)

5W — WHO: the L2 Squad (Director · Venus · VenusPG · Mars-1/-2 · Apollo), continuing scope codemojex-game-rename (registry ccl-1..3; +Mars/Apollo this run). WHAT: extend the build-grade design (Y-1 brief + Y-2 model) on TWO axes the prior run deferred, then BUILD + ship to one LAW-4 commit — (a) Operator OVERRULES V-6 to Arm B = the FULL blind/sealed/commit-reveal Golden mode (the as-built had no blind depth); (b) Operator rules IN two ADDITIONAL brand re-bases beyond round→game: room RMM→ROM and player USR→PLR, aligning code to the forward canon. WHY: the Operator's two-stage directive — Stage 1 authored .claude/skills/codemojex-ship; Stage 2 = this rename+redesign. WHERE: boundary echo/apps/codemojex + docs/codemojex. WHEN: 2026-06-24.

Solution space — (i) do-nothing (REJECT, Operator directed the build); (ii) token rename only (REJECT, Q2=complete redesign); (iii) cm.1 classic core only (REJECT, Q2=+golden/blind); (iv) CHOSEN = cm.1 founding core ∪ cm.3 golden/blind ∪ 3 brand re-bases, one collapsed migration (D-3 fresh reinit, no data migration).

Invariants as runnable gates — G1 residual-grep \bRND\b/\bRMM\b/\bUSR\b over lib+test → 0 (carved to spare Kernel.round/1, Math.round, English round-trip); G2 docs \bRMM\b → 0 (+ RND per acceptance); G3 mix compile --warnings-as-errors clean; G4 mix test --include valkey green on Valkey 6390 + Postgres; G5 fresh-schema reinit (ecto.drop+create+migrate scoped to codemoji_game/_test ONLY, *_snapshot untouched) comes up clean from zero; G6 the PRIVACY line — the game secret AND the blind commitment never cross the wire pre-reveal; G7 ≥100 determinism loop on the mint/process suite (same-ms branded-id hazard); G8 boundary grep — only echo/apps/codemojex + docs/codemojex changed, every sibling umbrella app untouched.

Smallest change preserving correctness — re-base the 3 brands at the mint sites + the entity drag (table/schema/FK/cache/wire) + the from-scratch 7-table+blind model as ONE collapsed initial migration + the blind mechanics behind the type/policy switch (V-7/8/9 ruled before Mars builds Golden). Risk tier: HIGH → L2 Squad, Apollo MANDATORY, Venus-Postgres fan-out. Verification posture: independent gate re-run + the ≥100 loop + migration up/down + adversarial privacy/fairness probes + net-zero mutation spot-check.

### T-13 — Ground truth: the THREE mint brands as-built (resolves the RMM/ROM contradiction)

Venus re-found the three mint sites on disk this turn. The T-12 directive is CORRECT; the prior Y-1 brief + design.md mirror are STALE on the room brand.
- ROUND/GAME: `lib/codemojex/rooms.ex:60` mints `EchoData.BrandedId.generate!("RND")` (the per-play entity). Target GAM. [prior brief already covered]
- ROOM: `lib/codemojex/rooms.ex:18` mints `EchoData.BrandedId.generate!("RMM")` — the room brand IS `RMM` on disk; `/usr/bin/grep -rnoE '"ROM"' lib test` = 0 occurrences. Target ROM. NOTE: the prior Y-1 brief (§4.1) + codemojex.design.md + the codemojex-ship facts all say "ROM (room)" — that is the FORWARD CANON (architecture.md/roadmap.md/bcs.2.md), NOT as-built. As-built is RMM.
- PLAYER: `lib/codemojex/wallet.ex:21` mints `EchoData.BrandedId.generate!("USR")` — `/usr/bin/grep -rnoE '"PLR"' lib test` = 0. Target PLR.
- UNCHANGED brands (verified, leave byte-exact): JOB (game.ex:35,162), GES (game.ex:102), NOT (notifier.ex:25, notification_worker.ex:85), EMS (emoji_set.ex:35), CMD (echo_bot.ex:65), TXN (wallet.ex:144).

CONSEQUENCE: the D-4 "ROM↔ROM / USR↔PLR drift is a SEPARATE reconcile, OUT OF SCOPE" note from the prior run is SUPERSEDED by T-12 — the Operator ruled both re-bases IN. So these two re-bases bring the CODE into alignment with the canon (which already says ROM/PLR), and the design.md forward-reconcile to GAM/ROM/PLR is now coherent (no surviving code↔canon brand drift after this rung). Mars must STILL not touch the surrounding non-brand vocabulary beyond what the three re-bases require.

The cache `kind:` for the room/player is NOT minted with a brand string the way the round is — verify: tables.ex declares only :cm_rounds + :cm_emojisets caches (round + emoji set); rooms/players are Postgres-only with no EchoStore L1 cache, so there is NO `kind: "RMM"`/`kind: "USR"` cache literal to re-base (unlike the round's `kind: "RND"` at tables.ex:59). To be confirmed against tables.ex this turn.

### T-14 — The room/player re-base is BRAND-ONLY, far narrower than round→game (token-class derivation)

Venus classified the RMM→ROM + USR→PLR surfaces against the 4-token-class law on disk. CRITICAL distinction from round→game: for room/player, the brand string is the ONLY ENTITY-TYPE (class 1) token; every other "room"/"player" hit is a LANGUAGE/IDENTIFIER (class 4 — English entity word) that is NOT the brand and stays. Contrast round→game, where "round" is BOTH the entity word AND the wire vocabulary the Operator ruled flipped.

RMM→ROM — class 1 (rename), exhaustive:
- rooms.ex:18 `generate!("RMM")` → `generate!("ROM")` (THE mint site).
- rooms.ex:14 docstring "Create a room (`RMM`)" → "(`ROM`)".
- NO cache kind literal (tables.ex declares only :cm_rounds kind "RND" + :cm_emojisets kind "EMS"; rooms are Postgres-only via Store, no EchoStore L1 → no `kind: "RMM"`).
LEAVE (class 4 — English, NOT the brand): schema module `Codemojex.Schemas.Room` (room.ex:1), table `schema "rooms"` (room.ex:8), the Store alias `Room` (store.ex:12), HTTP routes `/rooms` + `/rooms/:id/join` (router.ex:14-15), JSON key `rooms:`/`room:` (game_controller.ex:27, view.ex:28/54), the `:no_room` error atom (game_controller.ex, fallback_controller.ex:21), `RoomChannel`/room_channel.ex, every `room`/`room_id` var. Re-basing RMM→ROM changes only the id-VALUE prefix that travels inside those keys (a `ROM…` string now appears where an `RMM…` did).

USR→PLR — class 1 (rename), exhaustive:
- wallet.ex:21 `generate!("USR")` → `generate!("PLR")` (THE mint site).
- wallet.ex:19 docstring "Create a player (`USR`)" → "(`PLR`)".
- game.ex:6 moduledoc "named by the player's `USR`" → "`PLR`".
LEAVE (class 4): schema module `Codemojex.Schemas.Player`, table `schema "players"`, the Store alias `Player`, the columns `transactions.player` (transaction.ex:9) + `guesses.player` (guess.ex:10), HTTP route `/players` (router.ex:12), JSON key `player:` (game_controller.ex:23/80, view.ex), inbound `params["player"]` identity (game_controller.ex:77), `:no_player` (game_controller.ex:78, fallback_controller.ex:19), `create_player`/`require_player`/every `player` var. NO cache kind (players Postgres-only).

CONSEQUENCE: room/player re-base = 5 line-edits total (2 RMM + 3 USR sites) vs round→game's ~80-site drag. The acceptance grep G1 (0 RMM + 0 USR in lib+test) is satisfied by editing exactly those 5 lines — but the grep is over the BRAND TOKEN \bRMM\b/\bUSR\b (which appears ONLY at those 5 sites, confirmed: `/usr/bin/grep -rnoE '\bRMM\b' lib test` = 2 [rooms.ex:14,18]; `\bUSR\b` = 3 [game.ex:6, wallet.ex:19,21]), NOT over the word "room"/"player" (175 player + 95 room hits, all class-4, untouched).

### T-15 — VenusPG extension derivation (data-model lens; the Stage-2 build extension)

CONTINUATION, not re-delivery: this extends the Y-2 build-grade model (codemojex.game-model.design.md) + the prior-pass cm.1 triad (docs/codemojex/specs/cm.1.*, authored by VenusPG, untracked `?? specs/`) on the TWO axes D-10 fixed: (a) V-6 → Arm B = the FULL blind/sealed/commit-reveal Golden ships LIVE this rung (the prior model had the 4 blind columns present-but-NULL "for cm.3"; now they go live + their flow specs); (b) two ADDITIONAL brand re-bases beyond RND→GAM: RMM→ROM (room) + USR→PLR (player).

GROUND-TRUTH re-probe on disk this turn (NO-INVENT, every claim re-found):
- Mint sites (the brand IS the type — re-base at generate!): rooms.ex:18 generate!("RMM"), rooms.ex:60 generate!("RND"), wallet.ex:21 generate!("USR"), tables.ex:59 kind:"RND". Counts lib+test: RND=6, RMM=2, USR=3; GAM=ROM=PLR=0 (code lags entirely). USR also in doc prose game.ex:6 + wallet.ex:19; RMM in rooms.ex:14 doc.
- Entity drag: room.ex schema "rooms" field :round (→ :game) + module Codemojex.Schemas.Room (brand string is at the mint, the module name is NOT brand-coupled — Room/Player module names need NOT change; only the generate! string + any "USR"/"RMM" literal/doc + the cache kind). player.ex schema "players"; guess.ex schema "guesses".
- DB names — a PROMPT CLAIM FALSIFIED BY DISK: the prompt asserted the DB is `codemoji_game` (not the design's `codemojex_dev`). DISK: config/dev.exs:14 database:"codemojex_dev"; config/test.exs:19 database:"codemojex_test#{MIX_TEST_PARTITION}"; config/runtime.exs reads DATABASE_URL (NO literal DB name in :prod). So the design's `codemojex_dev`/`codemojex_test` is CORRECT; `codemoji_game` is NOT on disk. Flag to Director — the reinit command targets codemojex_dev + codemojex_test ONLY; *_snapshot untouched (no *_snapshot DB found in config either — that is a prompt assumption, not disk).
- Migrations (the collapse target): 20260618000000_create_codemoji.exs creates players(+CHECK)/transactions/emoji_sets/rooms(.round)/rounds(.secret)/guesses(.round,.percentage,.tier) + indexes; 20260625000000 alters rooms+rounds (golden,gold_multiplier) + players(tg_chat_id) + index. SEVEN tables total counting notifications — but NO notifications table is in EITHER migration on disk (the 20260625 name says "AndNotifications" but adds only columns+index). The "7th table" the prior NIT (T-9) flagged is NOT in the migrations → notifications is a Valkey/NOT-lane concern, NOT a Postgres table. The collapsed migration is SIX Postgres tables (players/transactions/emoji_sets/rooms/games/guesses). CORRECTING the design's "Seven tables" → SIX Postgres tables (notifications = the NOT bus lane, not a table).
- Privacy boundary (view.ex): round_view/1 returns NO secret; my_history Map.take [:emojis,:points,:percentage,:tier,:at_ms] (→ drop :percentage,:tier; for blind: withhold :points until revealed_ms). leaderboard = max scores. The blind privacy widening rides this same module (a feedback-policy branch, not a new view).
- Lifecycle (rooms.ex): start_round draws secret=EmojiSet.secret(set), snapshots golden/gold_multiplier; close_round = SET NX cm:{round}:closed → do_close → Economy.effective_pool + winner_take_all over Board.top. The blind path branches do_close on settlement="sealed" (reveal+seal already-stored points, rank, pay top_k) — additive, the SET-NX exactly-once discipline extended.

Solution space for the extension: (i) re-author the design from scratch — REJECT (the Y-2 model is build-grade + ratified; surgical extension preserves the frozen rulings). (ii) keep blind in cm.3-deferred, only do the 3 brand re-bases now — REJECT (D-10/the prompt's locked constraint #3: V-6=Arm B ships FULL blind LIVE this rung). (iii) CHOSEN = surgically extend game-model.design.md (blind columns LIVE + the 3-brand re-base reflected in §3/§4/§6/§8 + the SIX-table + DB-name corrections) + extend the cm.1 body to bring RMM→ROM/USR→PLR IN + author cm.3.md (the blind-Golden spec body) since the blind depth warrants its own triad (§3.8 is a full sub-system: feedback-none privacy, commit-reveal, sealed top-K, reduced set, state machine).

The genuine OPEN forks the blind LIVE build forces (cannot be invented — FRAMED as Arms for the Director→Operator): the COMMITMENT SCHEME (hash+encoding); the SEALED TOP-K PAYOUT CURVE (K fixed/% + split); the REDUCED EMOJI-SET sizing; the ANONYMIZED leaderboard given RMP deferred; the V-8 status CHECK/terminal sub-rulings; and V-7 (scoring unification) is RE-RAISED as live (was deferred). Smallest-correct: re-base 3 brands at the mint+drag, land the blind columns LIVE behind the type/policy switch, one collapsed SIX-table initial migration, the blind flow specced in cm.3 with the open mechanics as Arms.

### T-16 — The wire flip: round→game flips wire vocabulary; room/player flips NOTHING on the wire (only the id-prefix)

Venus mapped the external wire on disk (lib/codemojex_web/** + view.ex). Two distinct wire postures:

ROUND→GAME — FULL wire cutover (Operator-ruled), because "round" IS the wire vocabulary. Exact sites (extends the prior Y-1 brief §4.4, re-verified this turn):
- HTTP routes router.ex:17-20: `/rounds/:id`, `/rounds/:id/guess`, `/rounds/:id/history`, `/rounds/:id/leaderboard` → `/games/:id…` (4 routes; the action atoms `:round`→`:game` etc).
- Channel topic literal "round:" 3×: room_channel.ex:12 `join("round:" <> round`, game.ex:132 `"round:" <> round` broadcast, rooms.ex:157 `"round:" <> round` golden broadcast → "game:".
- Channel route user_socket.ex:4 `channel "round:*"` → `channel "game:*"`.
- JSON/event map key `round:` 6×: game_controller.ex:32 `%{round: round, view:…}`, game.ex:106 (guess row), game.ex:121 (Events.publish), game.ex:133 (PubSub payload), rooms.ex:158 (golden payload), view.ex:53 (round_view map) → `game:`.
- `round_view`→`game_view`, `:no_round`→`:no_game` (the prior brief §4.3/4.5 sites).

ROOM/PLAYER — NO wire-vocabulary flip; the brand re-base changes only the id-VALUE prefix inside the wire keys. The wire never carries the brand string `USR`/`RMM`/`PLR`/`ROM` — it carries the English words. Sites that STAY as-is (only the value travelling through them changes prefix):
- HTTP `/players` (router.ex:12), `/rooms` + `/rooms/:id/join` (router.ex:14-15) — STAY.
- JSON keys `%{player: uid}` (game_controller.ex:23), `%{rooms: …}` (27), `%{player: p, score: s}` (80 + room_channel.ex:28), inbound `params["player"]` (77) — STAY.
- Error atoms `:no_player` (78, fallback:19), `:no_room` (game_controller.ex:29-path → fallback:21) — STAY.
- `RoomChannel` module + `room:`-NONE (there is no `room:` topic; the topic is `round:`→`game:`) — STAY.

So the wire-cutover atomic order is the round→game flip ONLY (no caller left on an old symbol → the compile gate + `--include valkey` stories prove it). The room/player re-bases are wire-INVISIBLE (a `PLR…`/`ROM…` id is the same 14-byte shape a client already treats opaquely; the Mini-App client reads ids as opaque tokens, not by prefix). This generates a real Arm: does the Operator ALSO want the room/player wire WORDS (`/players`, `/rooms`, `player:`, `:no_player`) flipped — there is no canon word to flip them TO (the canon keeps "player"/"room" as the English entity words; only the BRAND moves USR→PLR/RMM→ROM). RECOMMEND: keep the wire words; flip only the brand id-prefix (the T-12 directive says "brand re-bases", not "wire cutovers", for room/player). Framed as V-11.

### T-17 — The blind-mode WIRE/CODE surface (the sealed Golden client flow), grounded in the as-built channel + specs.md §43-90

Venus grounded the blind client-protocol against the as-built ScoreWorker/Channel/View + the canon (specs.md, NO-INVENT). The blind mode is the DIFFERENCE between two wire behaviors on the SAME channel + view surface; VenusPG owns the data-model columns (commitment/nonce/revealed_ms/top_k per D-9) — Venus owns how they appear (or do NOT) on the wire.

AS-BUILT classic flow (the baseline blind departs from):
- ScoreWorker (game.ex:130-134) broadcasts `{:scored, %{round, player, pct, tier, eff, first}}` on the per-game PubSub topic after EVERY guess → the channel (room_channel.ex:17-18) `push(socket, "scored", payload)` to the client. PER-GUESS live feedback.
- round_view/1 (view.ex:43-70) returns keyboard/timer/pool/totals, NEVER :secret (the privacy line, as-built).
- close → winner-take-all + `{:golden_win,…}` broadcast (rooms.ex:152-159).

BLIND (golden) DELTA — the four wire rules (each cited):
1. FEEDBACK NONE (specs.md:40 "blind mode stores the guess and reveals nothing"; :45 "no per-guess feedback for the room's life"; :90 "a channel that carries state and timer only, no results until reveal"). The ScoreWorker MUST NOT emit the per-guess `:scored` PubSub push for a golden game — it stores the GES + counts the attempt, but suppresses the live broadcast. Branch on the game's feedback policy (feedback="none" → no broadcast). The channel still serves state+timer on join/refresh.
2. COMMITMENT PUBLISHED, PREIMAGE SEALED (specs.md:53-54; the PRIVACY line, Operator-locked). The game_view of a golden game MAY carry `:commitment` (public by design — it binds the server) but MUST NOT carry `:secret` OR `:nonce` until reveal. Extend round_view to include `:commitment` for a golden game (and `:state`), and a hard invariant: no view selects :secret or :nonce while revealed_ms is null.
3. SEALED SETTLEMENT PUSH AT REVEAL (specs.md:47 "close on the timer; one settlement pass; pay top K"; :55 reveal secret+nonce, expose for verify; :89-90 state changes on the channel). At close→reveal→settle, ONE push carries the sealed result: the revealed secret+nonce (so the client recomputes+verifies the commitment), the final anonymized board, the top-K payouts, and the terminal state. Modeled as a NEW PubSub event on the same per-game topic, e.g. `{:revealed, %{secret, nonce, commitment, board, payouts, state}}` → a new channel push "revealed". This is the FIRST and ONLY results the blind client receives.
4. STATE/TIMER ONLY IN-FLIGHT (specs.md:36 state machine scheduled→open→active→revealing→settling→settled→voided; :89-90). The channel carries state transitions + the timer for a golden game, no scores. join returns the game_view (state+timer+commitment, no secret/nonce/results).

PRIVACY LINE ENFORCEMENT (the gate G6): a sealed test asserts (a) during an open golden game, a client join/refresh/history NEVER contains :secret or :nonce (commitment allowed); (b) the per-guess "scored" push does NOT fire for a golden game; (c) ONLY after reveal does the "revealed" push expose secret+nonce, and the exposed commitment recomputes (hash(secret,nonce)==commitment). This is the liveness the gate must EXERCISE (a present golden game must RUN the suppression + the reveal, not skip).

GROUNDING GAPS held out (flagged, NOT invented — consistent with D-9): top-K pays from the game's prize_pool as-built (BNK bank out of scope); the anonymized leaderboard needs RMP membership (out of scope) — so the blind board push uses the as-built {player_id, score} rows, and the "anonymized neutral names" is a config/launch concern deferred with RMP (the wire SHAPE supports it: the board push is a list of {alias, score}; the alias defaults to the player id until RMP lands). These are VenusPG's schema concern; Venus's wire surface is shaped to accept either.

The CLIENT-PROTOCOL forks (Venus surfaces, does NOT decide): (a) the reveal event NAME/shape — one fat "revealed" event vs separate "reveal"+"settled" events; (b) whether the commitment rides the game_view from open or a separate "committed" push on transition to open; (c) the blind board push membership shape (id vs alias) pending RMP. Framed as V-13.

### T-18

SYNTHESIS: both architects landed; consolidating the Arm slate for the Operator ruling

Both Stage-1 architects reported BUILD-GRADE; the dual-architect boundary held (disjoint files, no sibling reads). Venus (identity/token/wire, Y-3): brief +§10/11/12/13, design.md reconciled forward to GAM/ROM/PLR, cm.1.stories/llms extended; Arms V-11/12/13. VenusPG (relational/fairness, Y-4): game-model.design.md extended (blind columns LIVE + the 3 brand re-bases), cm.1.md extended to the 3 brands, cm.3.md NEW (224 lines, the blind-Golden body); Arms V-14/15/16 + re-raised V-7/V-8.

TWO disk-grounded corrections to fold (both falsify earlier assumptions — VenusPG verified against the migrations + config, L-5):
- SIX Postgres tables, not seven: NO notifications table (NOT is a Valkey lane). The collapsed create = players/transactions/emoji_sets/rooms/games/guesses + the games_type CHECK. A Mars building a 7th notifications table would invent surface. [Corrects the Director T-12 7th-table note.]
- DB names: config/dev.exs → codemojex_dev, config/test.exs → codemojex_test; runtime.exs reads DATABASE_URL. The codemoji_game name (Director psql -l) is NOT the Ecto config target. SAFETY: ecto.drop/reinit targets codemojex_dev + codemojex_test ONLY; Mars resolves the EFFECTIVE config; the Director confirms the exact drop target with the Operator before the destructive op. A pre-existing codemoji_game DB is NOT dropped.

GROUND TRUTH confirmed (Venus T-13): the room/player re-base is BRAND-ONLY (rooms.ex:18 mints RMM, wallet.ex:21 mints USR; zero ROM/PLR in code). ~5 line edits; the WORDS room/player survive (95+175 identifier hits). Acceptance grep is over the 3-letter TOKEN (\bRMM\b/\bUSR\b), not the word.

CONSOLIDATED 8-ARM SLATE for the Operator AskUserQuestion:
- PRODUCT/MONEY (Operator-shaping): V-15 sealed top-K payout (K + curve); V-16a reduced emoji-set size; V-16b anonymized leaderboard ship-now vs defer.
- ENGINEERING (architect-converged, strong RECOMMENDs, bundled as a slate): V-7 linear scoring both modes (already the Operator HARD constraint); V-14 commitment SHA-256(secret‖nonce) hex; V-13 one fat reveal event; V-8 full canon status words + CHECK + classic terminal; V-11 keep room/player wire words; V-12 keep FK column names.
- V-9 (regulatory seam): stays Arm A — a non-blocking launch-gate seam; does not shape the schema; recorded, not a build fork. V-6 already ruled B (full blind) by the Operator.

cm.1 settled core is build-grade NOW, depends on NONE of the Arms; the Arms gate ONLY the cm.3 blind flow — ruling all now so Mars builds cm.1+cm.3 in one pass.

FLAGGED for Director-verify: the DERIVED cm.1 triad (stories/llms, Venus) vs the authoritative cm.1.md body (VenusPG) were authored independently (no sibling reads) — cross-check for drift before/at the Mars build (Mars builds from cm.1.llms.md, which must match cm.1.md).

### T-19

T-CV1 — EMS seed grounded in the MEASURED sprite sheets (V-16a)
sips on the two real assets under docs/codemojex/emoji-sets/ (base + @2x retina, 2x = exactly 2× base, no extra rows):
- 01-emoji-set.png: 720 × 1080 (base) / 1440 × 2160 (@2x). cell_size 144 (EmojiSet default, emoji_set.ex:39) → cols = 720÷144 = 5, rows = 1080÷144 = 7.5 → NOT integer.
- 02-emoji-set.png: 720 × 1512 (base) / 1440 × 3024 (@2x). cols = 720÷144 = 5, rows = 1512÷144 = 10.5 → NOT integer.
FINDING (F-CV1): at cell_size 144 the height is NOT an integer multiple — the sheets are NOT a 144px grid. 720÷5 = 144 (cols clean at 5). For integer rows the cell must divide BOTH dims: gcd(720,1080)=360, gcd(720,1512)=72. cell_size 120 → 01: 6×9=54 cells; 02: 6×12.6 no. cell_size 72 → 01: 10×15=150; 02: 10×21=210 (both integer). cell_size 360 → 01: 2×3=6; 02: 2×4.2 no.
ONLY cell_size 72 yields integer rows for BOTH sheets (01: cols 10 rows 15; 02: cols 10 rows 21). cell_size 144 is the code DEFAULT but does NOT fit these specific assets. Per the no-invent + "specify the grid from the MEASURED dims" instruction, the EMS seed MUST state cell_size 72 (the measured-true divisor), NOT blindly 144. codes = all_cells(cols, rows) (every cell, the full room keyboard; cell_count null = classic). This is a real surface fork to surface, not decide: cell_size 72-vs-144 changes the cell count 10×15 vs 5×7.5. Recommending cell_size 72 (the only value consistent with BOTH measured sheets); flagging for Director/Operator ratification.

### T-20

T-CV2 — Convergence ground truth: the rulings to fold (D-15/D-16) + the supersession deltas vs the pre-ruling design
The Operator rulings D-15 (PRODUCT/SCOPE) + D-16 (ENGINEERING SLATE) are read from the ledger tail. The design files (codemojex.game-model.design.md, cm.1.md, cm.3.md) were authored against the V-14/V-15/V-16 RECOMMENDED Arms; three rulings DIVERGE from those recommendations and must be folded as supersessions, not echoes:
1. V-15 PAYOUT — design assumed "a graduated decreasing share, w_i=(K-i+1)/sum" (a DERIVED curve). RULING: top_k DEFAULT 5 + a CONFIGURABLE payout_split = an ordered integer weight array on the room policy, DEFAULT [40,25,15,12,8] (sums 100), SNAPSHOTTED to the game at start. So the split is a STORED ARRAY (games.payout_split + rooms.payout_split), not a computed formula. New columns: games.top_k (int, default 5), games.payout_split (int[]), rooms.payout_split (int[] policy default).
2. V-16a REDUCED SET — design assumed "a 24-cell EMS row, mechanism = a smaller EMS, NOT a games.symbols column". RULING SUPERSEDES (explicitly "supersedes the architect's fixed-24-cell recommendation"): mechanism = a room config cell_count (N, nullable; null = full room cell set = classic) + the game snapshots a RANDOMIZED N-cell subset of the room's codes (Enum.take_random(room_codes, N)) STORED ON THE GAME. So NEW columns: rooms.cell_count (int, nullable) + games.cell_codes (text[], the snapshotted keyboard). The EMS stays the FULL room keyboard; the narrowing moves to the game snapshot. The secret draws its 6 from the game's snapshotted subset (EmojiSet.secret over the game keyboard).
3. V-8 STATE TERMINAL — sub-ruling resolved: full 7-word set {scheduled,open,active,revealing,settling,settled,voided} CHECK-bounded; classic terminal = "settled" (unified, the as-built "closed"→"settled"); golden {open→revealing→settling→settled}; voided = abort.
Folded as-is (matched the recommendation): V-14 SHA-256(secret‖nonce) lowercase hex; V-7 one linear fn; V-13 one fat revealed event; V-11 keep wire words; V-12 keep FK columns; V-16b defer alias (board push {player_id,score}, wire accepts {alias,score} later).
COUNT CONFIRMED: SIX Postgres tables (players/transactions/emoji_sets/rooms/games/guesses) — NO notifications table (NOT is a Valkey lane), per L-4/Y-4. The collapsed initial migration carries all six + the games_type CHECK + the new columns.

### T-21

T-Mars-1 — Build entry: scope + boundary fixed before any edit. Three brand re-bases (RND→GAM with full entity drag; RMM→ROM brand-only; USR→PLR brand-only) + six-table collapsed initial migration + tier removal (linear-only) + blind/Golden wire (cm.3, V-6 Arm B, LIVE this scope) + EMS seed (F-CV1, cell_size=72). Boundary = echo/apps/codemojex/** ONLY (lib + lib/codemojex_web + priv/repo/migrations + test + mix/tasks). The brief §§5-7 (docs reconcile: design.md, bcs.2.md, bcs.todo.md) are OUTSIDE Mars's prompt boundary — Director's concern; will flag, not touch. Authoritative sources: cm.1.md (body) + cm.1.llms.md (brief) + codemojex.game-model.design.md §3/§6/§8 + codemojex-game-rename.brief.md §§4/10/11/13. Rulings honored: D-3 (fresh reinit, one migration), D-5 (tier removal), V-7 (one linear fn both modes), V-8 (7-word status CHECK, classic terminal "settled"), V-11 (keep wire words /rooms /players player: :no_player), V-12 (keep FK columns transactions.player/guesses.player), V-13 (one fat "revealed" event), V-14 (SHA-256(secret‖nonce) lowercase hex), V-15 (top_k=5 + stored payout_split [40,25,15,12,8]), V-16a (rooms.cell_count + games.cell_codes per-game snapshot), F-CV1 (EMS seed cell_size=72). Build-order DAG per brief §13.2: round→game → room/player re-bases → schema+migration → blind wire → full gate → (docs = Director).

### T-22

T-Mars-2 — Surface fully grounded on disk (line numbers diffed against CURRENT source, not the brief's cited lines). Gate prereqs GREEN: elixir 1.18.4 / erlang 28.5.0.1 (umbrella .tool-versions), valkey-cli -p 6390 → PONG, pg_isready → /tmp:5432 accepting, DATABASE_URL UNSET (config is the target: dev=codemojex_dev, test=codemojex_test<PARTITION>, localhost:5432 postgres/postgres). Residual brand map CONFIRMED: \bRND\b = 6 sites (rooms.ex 7/42/60, tables.ex 10/33/59), \bRMM\b = 2 (rooms.ex 14/18), \bUSR\b = 3 (game.ex 6, wallet.ex 19/21). Token classification (entity vs BIF/English): ENTITY-prose round → telegram.ex:10, repo.ex:4, scoring.ex:7. BIF (LEAVE) → economy.ex:22/61 (round/Float.round), scoring.ex:55 (round/@max). ENGLISH (LEAVE) → economy_story_test:10 ("round up"), emoji_codes_story_test:5 ("round-trips"), priv/scoring.exs:15 ("dogs round")/:33 (round BIF). Test surface: rooms_and_rounds_story_test.exs (rename file+module+feature string "Rooms and rounds"→"Rooms and games"); settlement/wallet/privacy story tests carry entity round bindings (rename); economy_story_test fixtures ALREADY use PLR ids (forward); scoring_story_test 0 round (skip); Story DSL 0 round (no edit). Config is UMBRELLA-level (echo/config/{dev,test}.exs) = OUT OF BOUNDS (read-only; no TTL-key edit needed per brief — :rounds_cache_ttl_ms read with default in tables.ex only). Migrations: 20260618 creates 6 tables (NO notifications), 20260625 alters rooms/rounds (golden/gold_multiplier)+players (tg_chat_id). cm.3 body confirms blind flow is its own rung BUT D-10/R8/A-6 fold the blind WIRE+FLOW into this scope (golden runs blind end-to-end this rung). Build starting: schemas → store/cache/tables → lifecycle (3 mints + snapshots + blind open) → compile-gate → score/board/view (tier removal + blind privacy) → wire → settlement/notifier/scoring (top_k_split + reveal) → one migration → reinit → tests/demo → gate.

## {codemojex-game-rename-learnings} Learnings

### L-1 — Plan-map drift found (counts + the ROM/ROM grounding split)

(a) bcs.2.md carries 11 "round" hits, NOT the ~6 the plan-map estimated. The entity-token subset (→ "game") is at lines 29, 45, 111, 231, 247, 259 (6 sites: "naming a player and a round", "the round, the scores", "keyed by player and round ids", "a round's under its own", "a finished round's ephemeral state", "a round preserved for replay"). The other 5 are English ("around"/"round-trip"-class) — LEAVE.
(b) GROUNDING SPLIT confirmed: BCS prose already uses the roadmap's namespace vocabulary — bcs.2.md:231 says "a room's under a `ROM` id", and the roadmap uses ROM/RMP/PLR — while the as-built CODE + design.md use ROM(room)/USR(player). So the BCS corpus is grounded in the aspirational roadmap, not as-built. This is exactly the ROM↔ROM drift the Director flagged OUT OF SCOPE. CONSEQUENCE for THIS rename: changing "round"→"game" in bcs.2.md is safe (GAM is canon in BOTH roadmap and the target), but Mars must NOT "fix" the surrounding ROM/PLR to match code — that is the separate reconcile. Hold the rename to the round→game token only.
(c) codemojex.architecture.md + codemojex.specs.md are UNTRACKED and were NOT in the plan-map's per-file list under Surface 2 (only design.md + the 3 untracked were named). architecture.md uses "round"/`RND` heavily (it is the as-built draft); specs.md TBD. Both need scanning — surface is wider than the pre-baked list, exactly as warned.

### L-2 — "multiple type of games as described" resolves to a TWO-type launch set (classic + golden), but "as described" is split across two non-aligned descriptions

The Operator's "multiple type of games as described" has one concrete on-disk grounding: specs.md "Two modes at launch: classic (live feedback) and golden (blind)". That fixes the launch type SET = {classic, golden}. But the DESCRIPTION of golden is split: the as-built golden-rooms.md describes a boost-only LIVE golden (same linear scoring, same feedback), while the forward architecture.md/specs.md describe a BLIND golden (feedback none, sealed settlement, commit-reveal, anonymized, reduced set). The model can only NO-INVENT-ground the boost-only golden (real code); the blind-mode golden is PROPOSED with its core mechanics as explicit OPEN QUESTIONS. Flagged as Arm V-6. No third game type is "described" anywhere on disk — the engine is built extensible (the type discriminator) but only two types are grounded. Recorded so the gap is the Operator's to close, not Mars's to invent.

### L-3

L — A resume of a COMPLETED agent with new scope was misread as a task re-delivery; the idle-decline trap

VenusPG, resumed via SendMessage with the continuation brief (the Operator's Arm rulings + the blind-mode expansion + the rung-spec decomposition), read it as "task #7 re-delivered … the assignment carried no new content" and declined to re-run, going idle still "awaiting the four Operator Arms" — unaware the Operator had RULED them (V-3 → blind-mode, against VenusPG's recommendation A). The substantial new work (expand the model to blind-mode, author the upfront-rung specs) did NOT happen.

Cause: a SendMessage that resumes a just-completed agent can be pattern-matched as a re-assignment of the completed task, especially when a Task (#8) is also (re-)surfaced; the "what changed / new work" was not framed unmistakably at the TOP of the brief — it led with the rulings list + deliverables rather than "this OVERTURNS your V-3; the model must expand."

Fix (this turn): a self-contained corrective SendMessage headed "CORRECTION: NOT a re-delivery — NEW work from the Operator's rulings; V-3 = build blind-mode now," leading with the single fact that creates the work (the V-3 reversal), then the deliverables.

Mentoring note (resume pattern, for Apollo to fold forward): when resuming a COMPLETED agent with expanded scope, LEAD with the decision that creates the new work and state plainly "do not decline as already-complete"; do not open with a deliverables list that reads like the prior assignment.

### L-4 — "Brand re-base" ≠ "entity-word rename": the room/player axis re-bases the BRAND ONLY, so the acceptance grep is over the 3-letter token, not the English word

The T-12 directive folded in "two additional brand re-bases beyond round→game: room RMM→ROM and player USR→PLR." A naive reading equates this with the round→game rename (which dragged the schema module, the table, the FK field, the cache, AND the wire word). On disk the two are NOT symmetric:
- round→game: "round" is the entity word AND the wire vocabulary the Operator ruled flipped → ~80-site drag across schema/table/FK/cache/routes/topics/JSON.
- room RMM→ROM / player USR→PLR: the BRAND STRING is the only class-1 token (5 sites total: rooms.ex:14,18 + game.ex:6, wallet.ex:19,21). The words "room"/"player" are the canon's English entity words and STAY EVERYWHERE — schema modules Schemas.{Room,Player}, tables "rooms"/"players", columns transactions.player/guesses.player, routes /rooms//players, JSON keys player:/rooms:, atoms :no_room/:no_player. The brand re-base changes only the id-VALUE prefix travelling through those unchanged keys.

Why: a brand in BCS is the 14-byte id's 3-letter prefix (validated by SHAPE), so "re-base the brand" = change the generate!("…") string + its docstrings. It is NOT "rename the entity" — the entity is already called room/player in the canon; only its BRAND was the legacy RMM/USR. The acceptance is therefore `/usr/bin/grep -rnoE '\bRMM\b|\bUSR\b' lib test` → 0 (the brand TOKEN, which exists only at those 5 sites), explicitly NOT a grep over "room"/"player" (175+95 class-4 hits that must survive). A grep over the word would be a false-RED demanding corruption of correct code.

How to apply: when a directive says "brand re-base X→Y," FIRST grep the 3-letter token `\bX\b` to bound the true class-1 surface, and SEPARATELY confirm whether the lowercase entity word is ALSO the wire/canon vocabulary (round: yes; room/player: no). Only round→game's word is a rename; RMM/USR are pure brand swaps. Carry both greps into the acceptance, distinct. Links: [[T-13]] (the mint-site ground truth), [[T-14]] (the class breakdown), [[T-15]] (the wire posture).

### L-5 — Two Stage-2 ground-truth corrections the reconcile caught (a prompt claim + a prior-pass NIT, both falsified by disk)

The architect's reconcile duty (a config/serving fact is a claim discharged by READING the real file, never assumed) caught two facts wrong in the inputs:

(1) THE DB NAME. The VenusPG prompt asserted "the actual DB name is `codemoji_game`, not the design's earlier `codemojex_dev`; re-confirm from config/runtime.exs." DISK SAYS OTHERWISE: config/dev.exs:14 database:"codemojex_dev"; config/test.exs:19 database:"codemojex_test#{MIX_TEST_PARTITION}"; config/runtime.exs reads DATABASE_URL (NO literal DB name for :prod). So the design's `codemojex_dev`/`codemojex_test` was CORRECT all along; `codemoji_game` is NOT on disk anywhere. The prompt also assumed `codemoji_*_snapshot` DBs to untouch — no *_snapshot DB appears in any config (not a disk fact). The design now names codemojex_dev + codemojex_test as the reinit targets and flags codemoji_game as a falsified claim.
CONSEQUENCE: the reinit command + the gate target codemojex_dev/codemojex_test ONLY. Mars must NOT drop a `codemoji_game` DB (it does not exist) — that would be a no-op at best or a wrong-DB action.

(2) SIX POSTGRES TABLES, NOT SEVEN. The first pass said "Seven tables" and the T-9 NIT presumed a `notifications` 7th table (from the migration name 20260625000000_golden_rooms_and_notifications.exs). DISK: that migration only ALTERS rooms/rounds (golden,gold_multiplier) + players (tg_chat_id) + an index — it creates NO notifications table. `NOT` (notification) is a Valkey bus lane (notifier.ex / notification_worker.ex / the :cm_notify consumer), NOT a Postgres table. The collapsed initial migration stands up SIX tables: players, transactions, emoji_sets, rooms, games, guesses.
CONSEQUENCE: the one clean initial create is SIX create table() blocks; a Mars who builds a seventh `notifications` table from the design's old "seven" would invent a table with no schema module + no usage.

WHY THIS MATTERS (the craft note): a brief/prompt fact about a DB name, a table count, or a serving surface is a CLAIM, and the architect discharges it by reading the real config/migration on disk — not by trusting the upstream brief. Both corrections were one grep away; both would have mis-directed the build (a wrong DROP target, an invented table). The mechanism-word/config-key reconcile rule (venus charter) generalizes to "a named DB / a table count is a claim — probe it."

MENTORING NOTE (for Apollo to fold forward): when a continuation prompt RESTATES a fact ("the DB is X, re-confirm from Y"), treat the restatement as a claim to verify against Y, not as the answer — the prompt can carry a stale fact the disk contradicts.

### L-6

L-CV1 — Two convergence surprises (one fork surfaced, one ruling-vs-recommendation divergence pattern)
(a) THE cell_size FORK (F-CV1, surfaced not decided): the two real sprite sheets do NOT fit the code's default cell_size 144 — 720×1080 ÷ 144 = 5 × 7.5 (non-integer rows); 720×1512 ÷ 144 = 5 × 10.5. Only cell_size 72 yields integer rows for BOTH (01: 10×15=150; 02: 10×21=210). The EMS seed (§3.3.1) states cell_size 72 (the measured-true divisor) with the 72-vs-144 fork flagged for the Director — the assets demand 72, but the code default is 144 (so either the seed uses 72, or the Operator intends a re-export at 144). This is a real surface fork the "measure the assets" directive uncovered; recommending 72.
(b) THE RULING-REFINES-MECHANISM PATTERN: 3 of the 6 blind Arms the Operator ruled DIVERGED from the architect's recommendation by REFINING the mechanism, which added schema columns the pre-ruling design did not carry: V-15 (a STORED payout_split array, not a computed w_i=(K-i+1)/Σ curve → +games.payout_split +rooms.payout_split) and V-16a (a room cell_count + per-game games.cell_codes randomized snapshot, not a smaller EMS row → +rooms.cell_count +games.cell_codes; the EMS stays the full keyboard). The convergence had to mark these SUPERSEDES, not echo, and correct the §3.8.6 "no new games column" line (false now — cell_codes IS the new column). LESSON for the architect charter: when surfacing an Arm, the steelman should flag whether the alternative arm CHANGES THE SCHEMA SHAPE (a stored-config arm vs a computed-fn arm have different column footprints) — the Operator's "configurable X" rulings tend to pick the stored-config arm, so the schema delta is part of the fork, not a consequence to discover at convergence.
Also folded: the design's INTERNAL §10.2 Arm labels (V-7..V-12) aliased the LEDGER V-numbers (V-14/15/16); the fold re-cited the ledger numbers (the design's own footnote names them the authority) to kill the dual-numbering ambiguity.

### L-7

L-Mars-1 — Realizations-over-literal (each flagged with its reason):
(1) scoring_story_test.exs was the GAP the brand-grep missed. The brief §2 said "update every story exercising tier/percentage/firsts" but the round-token grep showed scoring_story_test.exs with 0 round hits, so it wasn't on the rename list — yet it carried 4 `assert result.tier == N` assertions that the tier-removal (D-5) invalidates. Caught only by the running suite (40 tests, 4 failures), exactly the "a check counts only if it RUNS" class. Fixed by dropping the tier asserts (total/percentage assertions stay — linear scoring unchanged). Lesson: a residual grep keyed on ONE token (round) cannot find a test that breaks on a DIFFERENT removed surface (tier). The compile gate did not catch it (the test compiled — `result.tier` is a runtime KeyError, not a compile error: the map just lacks the key). The full suite is the only gate that catches a removed-key assertion.
(2) `\.percentage` grep is a FALSE-POSITIVE surface. The cm.1.md §6 entity grep and the brief §12 grep both target the round→game entity symbols, NOT `\.percentage`. game.ex:132/140 carry `s.percentage` — the COMPUTED value `Scoring.score/2` returns (kept per the §7 ruling "percentage computed-not-stored"). The COLUMN is gone (guess.ex schema + Store.put_guess write nothing). A blind `\.percentage` grep flags the kept computed accessor. The correct acceptance is column-write absence (guesses schema + put_guess), which is clean.
(3) valid_guess? now checks cell_codes FIRST (realization). The secret is drawn from the game's snapshotted cell_codes (V-16a), so a guess must validate against the SAME snapshot. For a classic game cell_codes = the full EMS set → behavior identical; for a reduced golden game it correctly narrows. The brief said "validate against the game's keyboard" — the keyboard IS now cell_codes.
(4) The channel gained :golden_win + :revealed handlers (robustness the blind wire makes load-bearing). The original room_channel had NO handle_info for :golden_win even though rooms.ex broadcast it on the classic golden close — an unmatched message would crash the channel. With golden LIVE this scope (B-3/B-4) both :revealed and :golden_win must be handled. Added all three (scored/revealed/golden_win).
(5) The blind suppression branch wraps the perfect-crack close. A golden game has no per-guess signal (design §3.8.2: "golden does not close on a perfect crack — there is no per-guess signal, so no early close"). Putting `if s.total == 600` INSIDE the `feedback == "score"` branch enforces this precisely — golden closes on the timer only.
(6) State terminal changed `:closed`→`:settled` (V-8 ruling). The as-built close set status `:closed`; the ruled terminal is `:settled`. The close_game guard now matches `%{status: :settled}` and the settlement story's `{:ok, :already_closed}` re-close assertion still holds (the SET NX lock is the exactly-once guard, independent of the status word).

## {codemojex-game-rename-decisions} Decisions

### D-1 — Boundary + the 3-register naming discipline (locked)

BOUNDARY: edits land ONLY in echo/apps/codemojex (code + tests + priv + app docs/) + docs/codemojex/codemojex.{design,progress}.md + docs/echo/bcs/bcs.2.md + docs/echo/bcs/bcs.todo.md (NEW). The team touches NO rendered html/bcs/** (Operator hand-edits from bcs.todo.md). Architect (Venus) edits ONLY docs/specs (this rung: codemojex.progress.md NEW + the brief artifacts); Mars executes the mechanical rename across code+docs from the brief. Do NOT touch: the Operator's pre-staged D docs/echo/bcs/bcs.progress.md deletion; codemoji-updated/ + codemoji-updated.zip (stale extract, IGNORE); any echo_mq/echo_store/echo_wire/echo_data app (codemojex is OUTSIDE that boundary — its own per-app gate binds, NOT the v2 invariant).
3-REGISTER NAMING (state in the brief, avoid bare-noun ambiguity): the ENGINE = "the Game system" (capital-G Mastermind engine; not yet a code module); the per-play ENTITY = "a game"/`GAM` (THE rename target); the PRODUCT = "Codemojex"/"the game". A sentence like "a game of Codemojex" = product; "the game's secret" = entity; "the Game system scores it" = engine.
OUT OF SCOPE (flag only, do NOT fix): the ROM↔ROM + RMP room/membership namespace drift between design.md (ROM room / USR player) and roadmap+architecture+bcs.2.md (ROM room / PLR player) — a SEPARATE reconcile. Mars changes round→game tokens only and leaves the surrounding ROM/PLR/ROM/USR vocabulary exactly as found.

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

The rounds table → games; the per-play entity brand RND → GAM at the key builder (rooms.ex generate!, tables.ex kind). The Operator named the entity game/GAM and the roadmap+architecture already canonize it. All OTHER brands UNCHANGED: ROM (room), USR (player), EMS (emoji set), GES (guess), TXN (transaction), JOB (bus job), NOT (notification), CMD (command). The design.md drift ROM↔ROM / USR↔PLR (forward canon uses ROM/PLR; code uses ROM/USR) is a SEPARATE reconcile, explicitly out of this model design's scope per the Operator directive.

### D-5 — BONUS TIERS removed; linear points is the sole score and rank

HARD Operator constraint: "BONUS TIERS MUST NOT EXISTS. There are no such mechanics. Existing linear score." Removed from the model:
(a) guesses.tier column (was div(total,20)) — DROP.
(b) guesses.percentage column (was total/600*100) — DROP (a derived display value, recomputable on read if ever surfaced; not stored).
(c) the entire first-mover tier-bonus economy: Board.record/4's tier-claim arm + the Valkey hashes cm:{game}:ptier / :bonus / :tierfirst, Board.firsts/2, Board.claim_tier, the Codemojex.firsts/2 facade delegate, and the scored event's tier/first fields.
KEPT: the linear scoring engine Scoring.score/2 (points(d)=100-20*d summed to 600); the leaderboard now ranks by the player's BEST LINEAR points total (cm:{game}:board ZSET scored by the raw best total, not base+bonus). guesses.points stands. The cm:{game}:base hash (the player's best total) is retained as the ZSET feed; only the bonus layer is removed.
NOTE the canon-drift this creates (flagged as Arm V-2): the forward roadmap B7.4.2 ("the thirty tiers, the live leaderboard's ladder") + B7.3 ("tier claims") + game_rules.md "Future Game Extension: Tiers" still describe the removed mechanic — a follow-up canon reconcile is owed.

### D-6

D — Director ratification of the Director-rulable model Arms (pending the Operator's 3 intent rulings)

Ratified now (BCS-mandated / directive-literal / pure implementation — not re-asked of the Operator):
- V-1 Arm A: one `games` table + a `type` discriminator + explicit typed policy columns (feedback/scoring/settlement/economy) + golden/gold_multiplier, bounded by a `games_type` CHECK IN ('classic','golden'). Reason: BCS one-entity (a per-type table forks the GAM identity the law forbids); canon-aligned ("no new entity types separate them"); the minimal delta over the as-built snapshot; the CHECK gives the money-adjacent floor queryable, write-bounded types (ALTER to add a type later).
- V-4 Arm A: collapse the two existing create-migrations into ONE clean initial create reflecting the new model — the literal D-3 "reinitialized from scratch, not migrations" (a fresh machine with no prod data permits editing never-run migration history).
- §7: Scoring.score/2 keeps `percentage` COMPUTED-not-stored (the live pct the channel + lobby progress bar show); the `tier/1` function + the tier key are removed; zero `percentage`/`tier` COLUMNS either way. Reason: least churn, preserves the surface behavior, honors the zero-stored constraint.

Pending the Operator (AskUserQuestion this turn): V-3 Golden depth; V-2 tier-display sub-ruling; the L-2 type-set scope. Mars does NOT build until these three are ruled.

### D-7

D — Operator rulings on the 3 design-intent forks (post-AskUserQuestion)

1. V-3 Golden depth: SPECIFY + BUILD BLIND-MODE NOW (NOT boost-only). VenusPG expands the model to the canon's blind/sealed Golden — feedback `none`, settlement `sealed` (one batch at close, top-K), commit-reveal (hash over secret+nonce, revealed+verifiable at close), reduced symbol set, anonymized leaderboard (no score leaks until reveal), and the richer state machine (scheduled→open→active→revealing→settling→settled→voided) — resolving the architecture.md open questions by design, grounded in the canon (NO-INVENT). The design-heavy path.
2. V-2 tier display: REMOVE ENTIRELY — no column, no badge, no display ladder; the leaderboard ranks raw linear `points`.
3. L-2 type set: CLASSIC + GOLDEN, "bootstrap with a specs for the upfront rungs" — the two types are the launch scope; ALSO author the spec-driven rung decomposition (the upfront rungs) + the founding rung triad so the build is spec-driven.

Effect: the rung expands into a DESIGN PHASE → a multi-rung build program. No production code until the expanded blind-mode design + the upfront-rung specs are Operator-approved. The FOUNDING rung (fresh schema + game entity GAM + type/policy discriminator + linear scoring + tier removed + classic live mode + reinitialization) is the settled core that can build first; blind Golden is a later rung pending its design forks (scoring unification, the state machine, regulatory gating). Director ratifications from D-6 (V-1 A+CHECK, V-4 A, §7) stand and fold in.

### D-8 — Operator-ruled: blind/sealed Golden is IN; tier removed entirely; classic+golden + a spec ladder

Folds the Operator's rulings + the Director's ratifications into the design (not re-litigated):
- Golden depth = the canon's BLIND/SEALED mode (feedback none, sealed top-K settlement, commit-reveal, reduced set, richer state machine) — NOT boost-only. The boost-only golden/gold_multiplier columns REMAIN (a golden room may still seed+boost a pool), but the type's defining policies are feedback=none, settlement=sealed.
- Tier removed ENTIRELY: no guesses.tier column, no recompute-on-read badge, no display ladder. The scoring.ex tier/1 function + the :tier return key removed. The leaderboard ranks raw linear points (best total). [V-2 → the stricter reading of Arm A, no Arm-B badge.]
- Type set = {classic, golden}; games_type CHECK ships [V-1 Arm A + CHECK, Director-ratified]. The engine stays one games table + type/policy discriminator.
- Migration = one clean initial create [V-4 Arm A, Director-ratified].
- §7 = percentage stays COMPUTED-not-stored (live pct for the channel/lobby via Economy.progress_pct or score/2's return); zero stored percentage; tier fn + key removed [Director-ratified].
- The build is spec-driven: a codemojex specs home + a rung ladder, the FOUNDING rung (settled core) buildable first while the blind-Golden rung waits on its forks (V-7/V-8/V-9).

### D-9 — Blind-mode schema delta on `games` (BCS-faithful: one table + type/policy discriminator + nullable type-specific columns)

Added to the games table for blind mode (all nullable → null for classic, the type/policy seam from V-1 Arm A):
- commitment : string, nullable — the hash commitment over secret+nonce, written at open (specs.md:53; architecture.md "Provably-fair secret"). Hiding+binding.
- nonce : string, nullable — the server-side nonce, sealed for the game's life, revealed at close (specs.md:54-55). KEPT server-side like `secret` (no player-facing query selects nonce until reveal).
- revealed_ms : bigint, nullable — when the secret+nonce were revealed (the reveal timestamp; null until close). After reveal, secret/nonce/commitment are exposed for verification (specs.md:55).
- top_k : integer, nullable — the sealed settlement's payout breadth (pay the top K; specs.md:47). Null for classic (winner-take-all = K of 1 effectively).
The status set widens (D-8/V-8) to include the blind states. The four policy columns already carry feedback/settlement: a golden game records feedback="none", settlement="sealed".
The reduced symbol set is NOT a new column on games — it is the emojiset the golden room points at (a smaller EMS codes array); modeled as room/game config (the room picks a reduced EMS), no schema change (architecture.md:14 "over a reduced symbol set" = the set the game draws from). CONFIRM with the Operator that "reduced set" = pick a smaller EMS, not a per-game subset column (flagged in the design doc, not Arm'd — low-consequence).
GAPS held out of the schema (flagged, NOT invented): the BNK bank (top-K pays from the game's prize_pool as-built, NOT a bank — bank is out of scope) and the rake (no rake column — out of scope, a BNK concern); the anonymized leaderboard alias (needs RMP membership — out of scope). The schema supports the blind FLOW (commit→seal→reveal→sealed-score→top-K-pay-from-pool) without the bank/membership systems, which land later.

### D-10 — Formation + scope extension for the build run (continues Y-1/Y-2; D-1..D-9 + V-1..V-10 FROZEN)

Formation: L2 Squad — Director + Venus + VenusPG (data-model fan-out) + Mars(-1/-2) + Apollo (MANDATORY, HIGH-risk). Rigor constant; the Squad ceremony is set by the risk tier (destructive at-rest reinit + schema redesign + 3 brand re-bases + new blind-mode surface + external-wire cutover).

Scope EXTENSION beyond the prior build-grade deliverables, per Operator rulings this turn:
- V-6 → Arm B: the FULL blind/sealed/commit-reveal Golden mode (overrules the prior RECOMMEND Arm A boost-only). The blind columns (commitment/nonce/revealed_ms/top_k) go LIVE; V-7/V-8/V-9 become live forks to rule before the Golden build.
- + Room brand RMM→ROM and Player brand USR→PLR (beyond round→game RND→GAM). Acceptance widens to 0 RMM + 0 USR + 0 RND across lib+test, and 0 RMM (+ RND) across docs/codemojex.
- DB treatment: D-3 fresh reinit (one clean collapsed initial migration, no data migration; ecto.drop scoped to codemoji_game/_test, *_snapshot untouched).
- Commit posture (Operator Q4): ONE scoped pathspec commit (echo/apps/codemojex/** + docs/codemojex rename docs/specs + ledger/registry), excluding the operator's staged infra/* + the redis-patterns docs.
- Tooling: Stage 1 of the request authored .claude/skills/codemojex-ship/SKILL.md (graft-ship precedent — self-contained, generic venus/mars/apollo charters + the Venus-Postgres fan-out + topology router).

Harness note: no TeamCreate tool in this harness (single implicit team). The team is the Agent-spawned named teammates + the AAW registry; broadcasting/messaging via SendMessage + mcp__aaw__agent_send.

### D-11 — The brand-vs-word law (the binding rename contract for the room/player axis)

LOCKED (grounds the acceptance + bounds Mars's edit):
- A brand re-base changes the `generate!("…")` mint string + its docstrings ONLY — it moves the id-VALUE prefix that travels through every boundary; it does NOT rename the entity's English word.
- ROUND→GAME is the EXCEPTION: "round" is the entity word AND the wire vocabulary the Operator ruled flipped → it drags schema/table/FK/cache/route/topic/JSON (~80 sites, brief §§4-9).
- RMM→ROM + USR→PLR are PURE BRAND SWAPS: the words room/player are the canon's own entity words and STAY everywhere (schema modules Schemas.{Room,Player}, tables "rooms"/"players", columns transactions.player/guesses.player, routes /rooms//players, JSON keys room:/player:, atoms :no_room/:no_player, RoomChannel). 5 line-edits total (rooms.ex:14,18 + game.ex:6, wallet.ex:19,21). No cache `kind` literal (rooms/players are Postgres-only).
- ACCEPTANCE: `/usr/bin/grep -rnoE '\bRMM\b|\bUSR\b' lib test` → 0 (the 3-letter TOKEN, which lives ONLY at those 5 sites), explicitly NOT a grep over the word room/player (175 player + 95 room class-4 hits that MUST survive). Docs: `\bRMM\b|\bRND\b` → 0 in docs/codemojex (player rows in design.md flip to PLR; a residual account-sense USR in specs.md is CORRECT — specs.md:9-11 names USR the auth account distinct from the PLR persona).
- This CLOSES the D-4 "ROM↔ROM / USR↔PLR drift is out of scope" note: T-12 brought it into scope; after this rung there is NO surviving code↔canon brand drift.
Cited: T-13 (mint ground truth), T-14 (the class breakdown), T-15 (the wire posture), L-4 (the surprise). The three Arms the Director rules: V-11 (wire words — RECOMMEND keep), V-12 (FK column name — RECOMMEND keep `player`), V-13 (the blind reveal-event shape — RECOMMEND one fat "revealed").

### D-12 — VenusPG Stage-2 data-model extension folded into the design + the cm.1/cm.3 spec bodies (continues Y-2; D-1..D-10 + V-1..V-10 FROZEN, append-only)

The Y-2 build-grade model + the prior-pass cm.1 triad are EXTENDED on the two D-10 axes, plus two ground-truth corrections (L-4). Folded (the design body is authoritative; the spec bodies derive):

A. BLIND COLUMNS LIVE (V-6 → Arm B). The four games columns (commitment/nonce/revealed_ms/top_k) ship WRITTEN by the golden flow, not "present-but-NULL for a future rung". design §3.5 carries a written-when/read-when table; §3.8 reframed "this scope ships them"; §5.1 NEW (the blind keyspace — same cm:{game}:* keys, the live push suppressed by feedback=none, the board read withheld until revealed_ms). The blind flow is cm.3 (the columns ship present in cm.1).

B. THREE BRAND RE-BASES (was one). RND→GAM + RMM→ROM + USR→PLR, all at the MINT (the brand string at generate! + the cache kind: + the doc-prose tokens — the schema MODULE names Room/Player are NOT brand-coupled and stay). Mint sites on disk: rooms.ex:18 RMM→ROM, rooms.ex:60 RND→GAM, wallet.ex:21 USR→PLR, tables.ex:59 kind RND→GAM. Counts lib+test: RND=6, RMM=2, USR=3. Acceptance widens to 0 RND+RMM+USR in lib+test (+ 0 RMM+RND in docs/codemojex). design §0/§2/§3.1/§3.4/§4/§6.1/§6.3/§6.8/§11 + cm.1.md §2/§3/§5/§6/§7 all reflect it; INV-1 widened to "exactly three brands change".

C. SIX POSTGRES TABLES (was "seven"). No notifications table in either migration (NOT = a Valkey lane). design §0.2 + §2 + §8.1 corrected; cm.1.md D1 corrected. The collapsed initial create = players/transactions/emoji_sets/rooms/games/guesses + the games_type CHECK.

D. DB NAMES = codemojex_dev / codemojex_test (config/dev.exs:14 / config/test.exs:19); runtime.exs reads DATABASE_URL (no literal prod DB name). The prompt's `codemoji_game` is FALSIFIED by disk (L-4). The reinit targets codemojex_dev + codemojex_test ONLY; no *_snapshot DB exists in config.

E. FIVE OPEN BLIND-MECHANIC ARMS framed (V-14/V-15/V-16 this turn + V-7 scoring-unification + V-8 state-machine re-raised LIVE) — the commitment scheme (default byte-pinned SHA-256), the top-K split curve (default fixed top_k graduated), the reduced-set size + the anonymized alias (default 24-cell EMS, defer alias to RMP). Each is an OPEN MECHANIC the canon leaves to rule (cited), NOT invented surface. The Director rules them via AskUserQuestion before the cm.3 build leg; cm.3.md carries each [RULE]-marked with its cited-canon default.

F. cm.3.md AUTHORED (NEW). The blind-Golden spec body (G1 feedback-none+privacy, G2 commit-reveal, G3 sealed top-K, G4 revealing/settling states, G5 reduced set; INV-5 sealed-exactly-once-idempotent, INV-9 privacy+binding, INV-10 no-new-table, INV-11 wallet-floor). Its stories+brief derive once the §8 Arms are ruled.

BOUNDARY HELD: edits ONLY under docs/codemojex/ (game-model.design.md + specs/cm.1.md + specs/cm.3.md). No production code edited. No git. The disjoint-from-Venus boundary held: the brief + design.md + cm.1.stories.md/cm.1.llms.md were NOT edited by VenusPG (cm.1.md was VenusPG's own prior deliverable, not Venus's — confirmed by the "Authored by Venus-PG" provenance + the untracked `?? specs/` state). NOTE for the Director: cm.1.stories.md + cm.1.llms.md (the derived founding-rung triad) still reflect the ONE-brand scope — they need a re-derive to the three-brand body (a Venus or a follow-up VenusPG task; flagged, not done — the BODY is authoritative + extended, the derived files lag).

### D-13 — The blind/sealed Golden WIRE contract (Venus's surface; the privacy line as the hard invariant INV-9)

LOCKED (the wire half of V-6 Arm B; VenusPG owns the COLUMNS, Venus owns how they appear on the wire — they meet at games.feedback/settlement):
- B-1 NO per-guess feedback: ScoreWorker.handle/1 branches on the game's feedback policy; a golden game (feedback="none") stores the GES + counts the attempt but SUPPRESSES the :scored PubSub broadcast + the Events.publish "scored". Classic (feedback="score") unchanged. (specs.md:40/45/90)
- B-2 commitment PUBLISHED, preimage SEALED: game_view/1 carries :commitment + :state for a golden game, NEVER :secret/:nonce while revealed_ms is null. (specs.md:53-54)
- B-3 ONE sealed reveal push at close: a new PubSub event on the per-game topic (shape per the V-13 ruling — RECOMMEND one fat "revealed" carrying secret+nonce+commitment+board+top-K payouts+terminal state) → a new channel push; the FIRST and ONLY results a blind client gets; the exposed commitment recomputes hash(secret,nonce)==commitment. (specs.md:47/55/89-90)
- B-4 state+timer only in-flight: the channel carries state transitions + the timer for a golden game, no scores; join returns the game_view (state+timer+commitment, no secret/nonce/results). (specs.md:36/89-90)
- INV-9 THE PRIVACY LINE (Operator-locked): the secret AND the commitment PREIMAGE (secret+nonce) never cross the wire pre-reveal; the commitment HASH itself is public by design (it binds the server). The G6 gate must EXERCISE this: a present golden game RUNS the suppression + the reveal with a positive proof (in-flight no secret/nonce + no per-guess push; at-reveal the binding holds); a golden game absent under the test's opt-in is a LOUD failure, never a silent pass.
- GAPS held out (NOT invented, per D-9): top-K pays from the game's prize_pool (BNK bank out of scope); the anonymized leaderboard alias needs RMP membership (out of scope) — the board push uses {player_id, score}, the wire shape accepts {alias, score} with alias defaulting to the id. These land with their deferred systems.
Cited: T-16 (the as-built channel/view/ScoreWorker grounding), brief §11, the specs.md §43-90 clauses. The acceptance: brief §11.5 (the privacy story, exercised) + cm.1.stories.md S-9.

### D-14 — The four-file extension contract (what Venus authored + the dual-architect boundary held)

LOCKED (the disjoint Venus surface; VenusPG's NEW edits to cm.1.md + codemojex.game-model.design.md were NOT read — the dual-architect rule held):
1. codemojex-game-rename.brief.md — EXTENDED with §10 (the RMM→ROM + USR→PLR brand-only re-bases, every file:line, the V-11 wire-words Arm + V-12 FK-column Arm), §11 (the blind/sealed wire surface, the four B-1..B-4 rules each grounded, the V-13 reveal-shape Arm, the §11.5 exercised privacy acceptance), §12 (the unified residual-grep acceptance for all three brands + the docs), §13 (the extended stories R-5/R-6/R-7 + the full build-order DAG). The header now states the brand-vs-word law up front.
2. codemojex.design.md — RECONCILED forward to GAM/ROM/PLR (0 legacy brand tokens, 0 entity-round prose), with the D-5 tier-removal + the V-6 blind-mode reflected in the mirror prose and flagged with scoped [RECONCILE] markers that point the deep MODEL reconcile to VenusPG's codemojex.game-model.design.md + specs/cm.1.md (Venus reconciles the RENAME; VenusPG owns the MODEL).
3. specs/cm.1.stories.md — S-6 reconciled (blind columns inert→LIVE this rung); ADDED S-7 (room re-base), S-8 (player re-base + the docs-USR note), S-9 (the blind wire flow); Coverage + Liveness extended for D6/D7/D8 + INV-9.
4. specs/cm.1.llms.md — ADDED R6/R7 (the brand re-bases, brand-only), R8 (the blind wire B-1..B-4), A-5/A-6 agent stories, the unified §5 acceptance gate (the 3-brand grep + the privacy-line exercise + the ≥100 loop + the docs grep); the footer notes the Venus-PG(core)+Venus(axis) dual authorship + the three Director-ruled forks.

BOUNDARY HELD: edited ONLY under docs/codemojex/. Did NOT edit cm.1.md or codemojex.game-model.design.md (VenusPG's). Did NOT read VenusPG's new edits to those two files. No production code touched. No git. The FROZEN ledger history (T-1..T-12, D-1..D-10, V-1..V-10, Y-1..Y-2) untouched — appended only (T-13..T-17, L-4, V-11..V-13, D-11..D-13, Y-3 next).
FORKS FOR THE DIRECTOR (rule before the blind build via AskUserQuestion, all RECOMMEND Arm A): V-11 room/player wire words (keep), V-12 the FK column name transactions.player/guesses.player (keep `player`), V-13 the blind reveal-event shape (one fat "revealed").

### D-15

Operator Arm rulings — PRODUCT/SCOPE (AskUserQuestion answers, 2026-06-25)

- V-15 PAYOUT: games.top_k DEFAULT 5; a CONFIGURABLE payout_split (an ordered integer weight array on the room policy, default [40,25,15,12,8]=100, snapshotted to the game at start). Sealed settlement ranks every guess linearly (V-7) + pays the top-5 per the split from the game's OWN prize_pool (BNK deferred). [Operator: "Top-5, configurable split."]
- V-16a REDUCED SET (mechanism REFINED + REAL assets supplied — supersedes the architect's fixed-24-cell recommendation): add a room config cell_count (N, nullable; null = the full room cell set = classic today). At game start the game snapshots a RANDOMIZED N-cell subset of the room's `codes` (Enum.take_random(room_codes, N)) as its keyboard, stored on the game; the secret draws its 6 from THAT subset. Golden: N reduced (room-configured); classic: N null. Grounds on emoji_set.ex (codes = the room keyboard subset; EmojiSet.secret = take_random 6; cell_size default 144). Seed the EMS rows from the 2 REAL sprite sheets docs/codemojex/emoji-sets/{01,02}-emoji-set.png (+ @2x retina); grid cols/rows/cell_size MEASURED from the PNGs (no manifest exists). [Operator: "configurable cell set in room then randomized to game with N-cell set" + supplied the assets.]
- V-16b ANON BOARD: DEFER the anonymized alias to the RMP membership rung; the board push carries {player_id, score}; the wire shape accepts {alias, score} for later. [Operator: defer — recommended.]

### D-16

Operator Arm rulings — ENGINEERING SLATE ACCEPTED (AskUserQuestion "Accept all six", 2026-06-25)

- V-7: ONE linear scoring function both modes (the Operator HARD constraint; architecture.md:59 "exact-match" rejected).
- V-14: provably-fair commit-reveal = SHA-256(secret ‖ nonce), lowercase hex; the commitment published at game start; the preimage (secret + nonce) server-side until reveal (HMAC + per-cell rejected — unpublishable / leaks structure).
- V-13: ONE fat `revealed` event at close (secret + nonce + commitment + board + top-K + state) + the commitment on game_view from open + golden per-guess pushes suppressed in-flight.
- V-8: the full canon status set {scheduled, open, active, revealing, settling, settled, voided}, CHECK-bounded; classic {open→settled} terminal "settled"; golden {open→revealing→settling→settled}; voided = the abort path.
- V-11: KEEP the room/player WIRE words (/rooms, /players, player:, :no_player) — no canon word to flip to; flipping would be invention.
- V-12: KEEP the FK column names transactions.player / guesses.player — the re-base moves the id VALUE, not the column NAME; the D-3 fresh schema makes the keep zero-cost.

Unchanged: V-6 ruled B (the FULL blind/sealed/commit-reveal Golden, prior Operator ruling); V-9 stays Arm A (a non-blocking launch-gate config seam — does not shape the schema, not a build fork). All design Arms are now ruled; the cm.3 blind build is unblocked.

### D-17

D-CV1 — The convergence fold contract: the new schema delta + the supersessions (folds D-15/D-16 into the design + cm.1 + cm.3)
The Operator rulings introduce schema/mechanism changes the pre-ruling design did not carry. The fold lands these LOCKED contracts:

NEW/CHANGED COLUMNS (the six-table collapsed initial migration carries all):
- games.top_k integer NOT NULL DEFAULT 5 (was nullable; ruling fixes default 5). Classic: 5 (inert — no sealed pass reads it). Golden: snapshotted from rooms.top_k or the default.
- games.payout_split {array,integer} NOT NULL DEFAULT '{40,25,15,12,8}' — NEW. The ordered weight array snapshotted to the game at start; the sealed settlement pays rank i its weight share of prize_pool. Sums need not be 100 (the split normalizes over the present weights), but the default sums 100.
- rooms.payout_split {array,integer} NOT NULL DEFAULT '{40,25,15,12,8}' — NEW. The room policy default, snapshotted to the game.
- rooms.cell_count integer NULL — NEW. N = the game keyboard size; NULL = the full room cell set (= classic today). Golden rooms set N; classic rooms leave NULL.
- games.cell_codes {array,string} NOT NULL — NEW. The game's snapshotted keyboard: at start, Enum.take_random(room_codes, N) when rooms.cell_count=N, else the full EMS codes (room_codes) when NULL. The secret draws its 6 from games.cell_codes (NOT from the room EMS directly). This SUPERSEDES the design §3.8.4 "a smaller EMS row" mechanism entirely — the EMS stays the full room keyboard; the narrowing is a per-game randomized snapshot.

SUPERSESSIONS (the design files currently carry the pre-ruling recommendation; the fold overwrites):
1. §3.8.2 / §10.2 V-11-Arm / cm.3 G3: payout = the STORED payout_split array (NOT a computed monotone w_i=(K-i+1)/sum curve). economy.ex top_k_split/2 reads games.payout_split + the ranked best points, pays each rank its weight share of effective_pool.
2. §3.8.4 / §10.2 reduced-set Arm / cm.3 G5: the reduced set = rooms.cell_count + games.cell_codes (a randomized per-game N-cell snapshot of the room's codes), NOT a smaller EMS row. EmojiSet.secret draws from games.cell_codes. The EMS row stays the full keyboard. The §3.8.6 "no new games column" line is FALSE for the reduced set now (games.cell_codes IS the new column); corrected in the fold.
3. §3.8.5 / §10.2 V-8 / cm.3 G4: status CHECK-bounded over the full 7 words {scheduled,open,active,revealing,settling,settled,voided}; classic terminal = "settled" (the as-built "closed"→"settled"); golden {open→revealing→settling→settled}; voided = abort.
4. V-16b alias: board push carries {player_id, score}; the wire shape accepts {alias, score} for the later RMP rung. (Matches the prior defer recommendation; no schema change.)

FOLDED AS-IS (matched the recommendation — flip [RULE]-pending → RULED): V-14 SHA-256(secret‖nonce) lowercase hex commit-reveal; V-7 one linear scoring fn; V-13 ONE fat `revealed` event (secret+nonce+commitment+board+top-K+state) + commitment on game_view from open + golden per-guess pushes suppressed; V-11 keep wire words; V-12 keep FK columns.

NOTE the V-number aliasing the design uses INTERNALLY (§10.2: V-7..V-12) maps to the LEDGER V-numbers: design-internal "V-7 scoring"=ledger V-7; "V-8 state"=ledger V-8; "the commitment-scheme Arm"=ledger V-14; "the payout-curve Arm"=ledger V-15; "the reduced-set Arm"=ledger V-16(a). The fold cites the LEDGER V-numbers (the authority per the design's own footnote) and removes the [RULE]-pending framing (every Arm is ruled).

### D-18

D-CV2 — The EMS seed grounded in the MEASURED sprite sheets (folds V-16a's asset-grounding directive)
Two real assets under docs/codemojex/emoji-sets/ (base + @2x retina, measured via sips). @2x = exactly 2× base in BOTH dims (no extra rows on retina), so the grid is the base dims.
- 01-emoji-set.png: 720 × 1080 base / 1440 × 2160 @2x.
- 02-emoji-set.png: 720 × 1512 base / 1440 × 3024 @2x.
DERIVATION: EmojiSet addresses cells XXYY at (-x*cell_size, -y*cell_size); cols = width÷cell_size, rows = height÷cell_size; both MUST be integers. cell_size 144 (the emoji_set.ex:39 DEFAULT) gives 01: 5 × 7.5 and 02: 5 × 10.5 — NON-integer rows → 144 does NOT fit these assets. The only cell_size dividing BOTH sheets' width AND height into integers: cell_size 72 (gcd-consistent) → 01: cols 10, rows 15 (150 cells); 02: cols 10, rows 21 (210 cells). (120 fits 01 but not 02; 360 fits neither's height.)
THE EMS SEED (2 rows, grounded in the MEASURED dims, cell_size 72 — the measured-true divisor, NOT the blind code default 144):
- EMS-1: name "emoji-set-01", cols 10, rows 15, cell_size 72, sprite_url "/emoji-sets/01-emoji-set.png" (the served path; @2x via srcset/retina-2x), codes = all_cells(10,15) = 150 row-major XXYY cells (the full room keyboard).
- EMS-2: name "emoji-set-02", cols 10, rows 21, cell_size 72, sprite_url "/emoji-sets/02-emoji-set.png", codes = all_cells(10,21) = 210 cells.
The reduced set is NOT a smaller EMS (D-CV1 supersession 2) — these EMS rows are the FULL keyboards; rooms.cell_count + games.cell_codes do the per-game narrowing (e.g. a golden room with cell_count 24 snapshots Enum.take_random(150-or-210 codes, 24)). cell_size 72 is a SURFACE FORK surfaced to the Director (the code default is 144; the measured assets demand 72) — recommending 72 (the only value consistent with both sheets). If the Operator intends a different cell grid (e.g. the assets are to be re-exported at 144), that is a one-line ruling; the seed states the measured-true 72 with the fork flagged.

### D-19

F-CV1 RULED — EMS cell_size = 72 (Operator, 2026-06-25)

The 2 real sprite sheets measure 10 cols at 72px (01-emoji-set.png 720×1080 → 10×15 = 150 cells; 02-emoji-set.png 720×1512 → 10×21 = 210 cells; @2x = exactly 2× base). The code default 144 (emoji_set.ex:39) gives non-integer rows on these assets. The EMS seed uses cell_size 72 (measured-true); no asset re-export. Mars seeds 2 EMS rows: cols=10, cell_size=72, EMS-1 rows=15, EMS-2 rows=21, codes=all_cells, sprite_url → the respective assets. This closes the last open fork — the cm.1 + cm.3 design is fully build-grade; Mars-1 is released.

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

### V-7 — Scoring unification: does blind mode rank by LINEAR distance or EXACT-match? (RECOMMEND Arm A: one linear scoring function behind the policy switch)

The architecture.md:59 open question, made consequential by the Operator's HARD constraint #3. architecture.md:59 calls blind a "blind exact-match RANKING"; the Operator says "Existing linear score" and roadmap.md B7.4.1 scores blind GES on the SAME linear distance scale (100-80-60-40-20-0 → 600). These conflict.

Arm A — ONE linear scoring function, both modes, behind the scoring policy switch (RECOMMENDED). 5W: WHO=Scoring.score/2 stays the sole engine; the settlement reads it for sealed mode too. WHAT=blind settlement scores every GES with the same linear distance total, ranks by best total, pays top-K by rank. WHEN=at close (sealed) vs per-guess (live) — same function, different trigger. WHERE=scoring.ex (unchanged engine) + the sealed settlement pass. WHY=the Operator's HARD "Existing linear score" is unambiguous + roadmap.md B7.4.1 agrees; one pure function is the BCS "data not behaviour" win (the scoring policy="linear" for both types today). Steelman: honors the HARD constraint verbatim; the purity/idempotency story (a re-run settlement pays identically) extends to sealed for free; scoring="linear" is the only policy value, so no second implementation to maintain; architecture.md is "a draft for review" and its "exact-match" wording predates the Operator's linear ruling. Steward: a future genuinely-different blind scoring (if ever wanted) is a new scoring-policy value + a new function selected by the switch — the seam is already there (the scoring column), added without touching classic.

Arm B — a separate exact-match ranking for blind (architecture.md:59's literal wording). Steelman: matches architecture.md's exact phrasing; an exact-match count is a cleaner "how many positions exact" ranking for a no-feedback contest. Against: CONTRADICTS the Operator's HARD "Existing linear score"; adds a second scoring implementation the engine must select between (the thing BCS+the right-size precept resist); roadmap.md B7.4.1 already says linear for blind. Surface it only because architecture.md says it — but A is the constraint-honoring + canon-majority reading.

Recommendation: Arm A — one linear scoring function behind the scoring="linear" policy for both modes; the difference between modes is feedback (none vs score) + settlement (sealed vs live), NOT the scoring math. This is the only reading consistent with the Operator's HARD #3. The Director rules (with the Operator, since architecture.md genuinely says otherwise).

### V-8 — The game state-machine shape (RECOMMEND Arm A: the full canon machine as text words, classic uses a subset)

specs.md:36 names scheduled→open→active→revealing→settling→settled→voided; the as-built is open|closed (rooms.ex/schemas default "open", close sets "closed"). Blind mode needs the reveal+settle intermediate states; classic does not.

Arm A — adopt the FULL canon status set as text words; each type traverses the subset it needs (RECOMMENDED). 5W: WHO=Mars sets status words at the lifecycle transitions in rooms.ex (start/close/reveal/settle). WHAT=status is a free-text column over the set {scheduled, open, active, revealing, settling, settled, voided}; classic uses {open → settled} (mapping the as-built "closed"→"settled"); golden uses {open → revealing → settling → settled}; voided is the abort path for both. WHEN=blind adds revealing (secret/nonce revealed, scoring the sealed batch) + settling (paying top-K) between open and settled. WHERE=schema games.status (text, no CHECK initially, or a CHECK over the 7-word set if the Operator wants it bounded like games_type). WHY=one machine for both types (the canon's "classic maps onto the same machine"); a text column lands the richer set additively without a migration when blind is built. Steelman: honors specs.md:36 verbatim; classic's path is a strict subset so a single settlement/close code path branches on type; the as-built open|closed is a 2-state degenerate of this, so the founding rung can ship {open, settled} and the blind rung widens it — no rework. Steward: a new state (e.g. a "paused" admin state) is one more word; bounding it with a CHECK is the Operator's call (sub-ruling).

Arm B — keep two minimal per-type machines (classic open|closed; golden open|revealing|settling|settled). Steelman: each type's machine is exactly its states, nothing unused. Against: forks the status vocabulary by type (a query "all settling games" must know the type); the canon frames ONE machine; the right-size win of a shared machine is the single close/settle path.

Arm C — a strict ENUM/CHECK over the 7 states now. Steelman: DB-enforced valid states. Against: over-commits the founding rung to states (revealing/settling) it does not yet use; better to ship the words classic needs + widen with the blind rung (the founding rung CHECK-bounds games_type, which is settled; the status set is still settling — pun intended). Fold into A as a later sub-ruling.

Recommendation: Arm A — the full canon set as text words, classic a subset (open→settled), golden traversing revealing+settling; the founding rung ships {open, settled} (renaming the as-built "closed"→"settled" for the unified machine, OR keeping "closed" as classic's terminal — a tiny sub-ruling), and the blind rung adds revealing/settling. Sub-ruling for the Operator/Director: bound status with a CHECK over the 7 words, or leave it open like the as-built? And: classic terminal = "settled" (unified) or "closed" (as-built word kept)?

### V-9 — Regulatory / age / region gating for paid blind-outcome rooms (RECOMMEND Arm A: a config SEAM on the room, NOT a schema-shaping build blocker)

architecture.md:58 open question (paid-entry, prize-pool, blind-outcome may be regulated as gambling; "Where can paid rooms operate, under what licensing and age and region gating?"). The Director asked to design a config seam + flag it as a launch-gate/legal-review decision (architecture.md's own framing), NOT a build blocker; Arm it only if it shapes the schema.

Arm A — a thin config SEAM (an eligibility predicate over a room), no schema change to games (RECOMMENDED). 5W: WHO=an application-layer eligibility check (a Codemojex policy fn) consulted before a player joins a paid blind room; the gating DATA (allowed regions, min age) is room/app config, not a games column. WHAT=a seam: create_*_room accepts an optional eligibility policy (region allowlist / age floor); join consults it; absent → open (today's behavior). WHEN=at join, before charge; the founding+blind rungs ship the SEAM (the predicate hook) and a permissive default; the actual policy values + the enforcement are a launch-gate decision. WHERE=an app policy module (NOT the schema); if any gating value must persist, it lives on the room (a nullable region/age config), not on games. WHY=architecture.md frames this as legal-review-before-launch, not a build mechanic; a seam keeps the schema clean (no speculative regulatory columns) while leaving the hook so enforcement lands without a model change. Steelman: does NOT shape the games schema (the Director's bar for Arm'ing it) → it is a SEAM design, not a blocking fork; honors architecture.md's "decision + jurisdiction review needed" by making the seam explicit + the policy deferred; the permissive default means the engine builds + runs now. Steward: enforcement is wiring the predicate to a real policy + (if persisted) a nullable room config — additive, no games migration.

Arm B — add regulatory columns to the schema now (region, age_floor, license on games/rooms). Against: speculative — the actual fields are unknown pending legal review (architecture.md:58 is an open question, not a spec); building columns for an unspecified policy is invention + gold-plating; the Director explicitly said flag-not-block unless it shapes the schema — it does not.

Recommendation: Arm A — design the eligibility SEAM (a join-time predicate hook + a permissive default), keep it OFF the games schema, and FLAG the regulatory classification + the policy values as an explicit LAUNCH-GATE + legal-review decision (architecture.md's framing) that does not block the engine build. This is a SEAM, surfaced for the Operator's awareness; it does not shape the schema, so it is not a blocking Arm — recorded for completeness + the launch checklist.

### V-10 — The codemojex specs-home structure (RECOMMEND Arm A: mirror the emq pattern)

The Director asked to propose a codemojex specs home mirroring emq. On disk: docs/echo_mq/specs/<rung>.{md,stories.md,llms.md} + decomposition subdirs (emq1/emq2/emq3) + a progress dir (specs/progress/<scope>.progress.md + .registry.json) + the rollup docs/echo_mq/emq.progress.md. No docs/codemojex/specs/ exists yet.

Arm A — mirror emq exactly (RECOMMENDED). Structure: docs/codemojex/specs/<rung>.{md,stories.md,llms.md} for each rung triad; docs/codemojex/specs/progress/<rung>.progress.md + .registry.json per-rung ledgers; the rollup dashboard docs/codemojex/codemojex.specs-progress.md (or reuse the existing codemojex.progress.md as the rollup). The roadmap docs/codemojex/codemojex.roadmap.md stays the single rung ladder (reconciled/extended per deliverable B). Rung slugs: cm.1 (founding core), cm.2 (classic live mode), cm.3 (blind Golden) — or a B7.x mapping if the Operator prefers the roadmap's existing B7.1-B7.6 numbering. 5W: WHO=Venus authors triads here; Mars builds from <rung>.llms.md; the Director ratifies. WHY=the team already runs the emq spec-driven loop + the /echo-mq-ship-style flow; an identical home means zero new convention to learn + the aaw ledger pattern (registry.json) already fits. Steelman: proven structure, the team's muscle memory, the progress dashboard + registry pattern is already tooled (msh specs link-checks it); keeps codemojex specs beside its canon (architecture/specs/roadmap) under docs/codemojex/. Steward: a new rung is a new triad + a progress ledger — the established additive move.

Arm B — a flatter home (one specs/ dir, triads only, the existing codemojex.progress.md as the sole dashboard, no per-rung registry). Steelman: less ceremony for a smaller program (codemojex is one app, not the multi-movement emq). Against: loses the per-rung registry.json the aaw liveness/audit tooling uses; diverges from the team's one spec convention for marginal saving.

Recommendation: Arm A — mirror emq (docs/codemojex/specs/<rung>.{md,stories.md,llms.md} + specs/progress/ ledgers + a rollup). Sub-ruling for the Operator/Director: the rung slug scheme — cm.N (cm.1/cm.2/cm.3) vs the roadmap's B7.x numbering. I recommend cm.N (a clean spec-rung namespace distinct from the COURSE chapter B7, which teaches the built game) to avoid conflating the build ladder with the course chapter.

### V-11 — The room/player WIRE-WORD treatment (flip the wire vocabulary, or re-base the brand id-prefix only?)

RATIONALE: round→game is a FULL wire cutover because the Operator ruled it and "round" is the wire word. For room/player the T-12 directive says "brand re-bases" — and on disk the brand string never crosses the wire (only the id-value does). So the question the spec must NOT silently fix: does the Operator ALSO want the external wire WORDS for room/player changed? There is a subtlety — unlike round→game (which flips "round"→"game", a real vocabulary change), room/player have NO new word to flip TO: the canon keeps "player"/"room" as the English entity words; only the BRAND moves (USR→PLR / RMM→ROM). So a "wire flip" here would mean inventing new route/key names with no canon basis.

5W: WHO the Mini-App client + any REST consumer. WHAT whether `/players`/`/rooms`/`player:`/`rooms:`/`:no_player`/`:no_room` change. WHERE router.ex:12-15, game_controller.ex:23/27/77/80, view.ex:28/54, room_channel.ex:28, fallback_controller.ex:19/21. WHEN this rung. WHY alignment vs scope-minimalism + the no-invent law.

STEELMAN of each arm:
- ARM A (RECOMMENDED) — re-base the BRAND id-prefix ONLY; keep every wire WORD. The wire words player/room are the canon's own English entity vocabulary (specs.md uses "player"/"room" throughout while the brand is PLR/ROM); there is nothing to rename them to. The id values travelling through them flip USR→PLR/RMM→ROM automatically (the mint change). The client treats ids as opaque 14-byte tokens, so the prefix change is wire-transparent. Smallest change preserving correctness; honors NO-INVENT (no fabricated route/key); matches the directive's word "brand re-bases."
- ARM B — also flip the wire words for symmetry with round→game. But: no canon word exists to flip TO; it fabricates wire surface; it widens the diff with zero contract benefit; it breaks the Mini-App client's routes for a cosmetic prefix that is already opaque. REJECTED on no-invent + scope.
- ARM C — flip only SOME (e.g. error atoms :no_player→:no_player stays, but … ) — no coherent partition; the words are all the same class. Not coherent.

STEWARD: Venus RECOMMENDS Arm A — the room/player axis is a pure brand re-base at the 5 mint/docstring sites; the wire keeps player/room (the canon's words); only the id-prefix moves. The Director rules with the Operator (the wire is an external contract → the Operator's call). If the Operator wants GameChannel/RoomChannel-class cosmetic wire renames, that is a separate cosmetic rung.

### V-12 — The USR→PLR FK COLUMN-NAME treatment (transactions.player / guesses.player): keep the column name, or rename it?

RATIONALE: USR→PLR re-bases the player id-VALUE prefix. The relational model (VenusPG owns the schema; D-3 = one fresh-from-scratch collapsed migration, NO data migration) has two columns holding a player id: `transactions.player` (transaction.ex:9) and `guesses.player` (guess.ex:10). The column NAME `player` is an English entity word, not the brand. Because D-3 reinitializes from scratch, there is NO migration cost to either choice — the column is created once with whatever name is chosen. So the fork is purely a naming-coherence call, free of data-migration risk. (This is Venus's lens — the column NAME as a code/identity surface; VenusPG owns the column TYPE/null/FK and may also weigh in. Venus surfaces; the Director synthesizes both architects.)

5W: WHO the schema + Store.guesses_for/3 query (store.ex:27-35 `where: g.player == ^player`) + the changeset cast lists. WHAT whether the column stays `player` or becomes something. WHERE transaction.ex:9/19/20, guess.ex:10/21/22, store.ex:30. WHEN this rung (the single migration). WHY identity-coherence vs the canon's own vocabulary.

STEELMAN:
- ARM A (RECOMMENDED) — KEEP the column name `player`. The canon (specs.md) names the entity "player" (the English word) while branding it PLR; "player" is the correct column name for a column holding a player reference, exactly as `guesses.round`→`guesses.game` will hold a game reference (note: the round→game rename DOES change guesses.round→guesses.game because the ENTITY WORD changed; player's entity word did NOT change — only its brand). The id VALUE in the column flips USR→PLR via the mint change; the column name `player` stays semantically exact. Zero query/changeset churn beyond the value. Smallest change; canon-faithful; no-invent.
- ARM B — rename the column to match a brand-flavored name (e.g. `plr`). But: a 3-letter brand is not a column name (the schema speaks English entity words: player/round/room/currency); it would read `g.plr == ^plr` — opaque, inconsistent with `currency`/`reason`/`ref`; it churns the query + both changeset cast/validate lists for zero benefit; no canon basis (specs.md says "keyed by `USR`"/"by `PLR`" meaning the id-VALUE brand, not a column rename). REJECTED.
- ARM C — rename only for the round→game-adjacent column (guesses) for symmetry. Incoherent: guesses.round→guesses.game changes because the WORD round→game changed; guesses.player has no word change. Not symmetric. REJECTED.

STEWARD: Venus RECOMMENDS Arm A — keep `player` as the column name; the brand re-base lives at the mint site (the VALUE), not the schema column (the NAME). This is the BCS reading: the brand is the id's type checked at the boundary; the relational column is durability/query and speaks the entity's English word. VenusPG's schema design should create `transactions.player` / `guesses.player` unchanged (only the round→game rename touches a column name: guesses.round→guesses.game, rooms.round→rooms.game). The Director confirms against VenusPG's model (both architects converge here, or the Director surfaces the divergence).

### V-13 — The blind-mode CLIENT-PROTOCOL shape (the sealed reveal event), grounded in the as-built channel; Venus surfaces, Director rules

RATIONALE: V-6 Arm B (Operator-ruled, T-12/D-10) ships the FULL blind/sealed Golden mode LIVE. The schema columns (commitment/nonce/revealed_ms/top_k) are VenusPG's (D-9). HOW the blind flow appears on the wire is Venus's surface, and the canon (specs.md §43-90) fixes the SEMANTICS (feedback none in-flight; commitment public, secret+nonce sealed until reveal; one sealed settlement push at close exposing secret+nonce+board+payouts) but leaves the CONCRETE event SHAPE open. The privacy line (Operator-locked: secret AND commitment-preimage never cross pre-reveal) is the hard invariant either arm must satisfy — note "commitment-preimage" = secret+nonce; the commitment HASH itself is public by design (specs.md:53). Venus surfaces the shape; the Director rules (it is a client-facing wire contract).

5W: WHO the blind Mini-App client. WHAT the reveal/settlement event name(s) + payload shape + when the commitment first appears. WHERE a NEW PubSub event on the per-game topic (the as-built topic is room_channel.ex:12 / game.ex:132, flipping round:→game:) + a new channel push (room_channel.ex pattern) + game_view extension (view.ex:43). WHEN this rung (V-6 Arm B is live). WHY a clean, verifiable client protocol vs minimal surface.

STEELMAN:
- ARM A (RECOMMENDED) — ONE fat "revealed" event at close. On settle, broadcast `{:revealed, %{secret, nonce, commitment, board, payouts, state: :settled}}` → channel `push("revealed", …)`; it is the FIRST and ONLY results the blind client gets. The commitment rides the game_view from open (view.ex extended: a golden game's view carries :commitment + :state, never :secret/:nonce). In-flight the ScoreWorker suppresses the :scored push for a golden game (feedback="none" branch). One event = one atomic client transition (in-flight blind → revealed+verifiable+settled); the client recomputes hash(secret,nonce) and checks ==commitment in one step. Matches specs.md:55 ("reveal the secret and the nonce, expose them so a player can recompute the commitment and verify") + :47 (one settlement pass) + :90 (state+timer only until reveal). Minimal new surface (one event, one view field).
- ARM B — SEPARATE "reveal" (secret+nonce+commitment) then "settled" (board+payouts) events. More granular; lets a client verify the commitment before seeing payouts. But: two events to sequence, a transient state where the client has the secret but not the result; more channel surface; the canon describes ONE pass (specs.md:47/55). Defensible if the Operator wants verify-then-settle staging; heavier.
- ARM C — push nothing; the blind client POLLs game_view after close (the view exposes secret+nonce+board once revealed_ms is set). Simplest server; but it abandons the live channel the canon mandates (specs.md:89-90 "a live channel per game … carries state and timer … state changes") and makes reveal latency a client-poll concern. REJECTED (drops the mandated channel semantics).

STEWARD: Venus RECOMMENDS Arm A — one "revealed" event carrying secret+nonce+commitment+board+payouts+terminal state, the commitment on the game_view from open, the per-guess push suppressed in-flight. It is the smallest surface that satisfies every cited canon clause and the privacy line, and gives a single verifiable client transition. The Director rules the event name/shape with the Operator (external wire contract). Sub-forks folded in: (b) commitment-on-view-from-open is part of Arm A (vs a separate "committed" push — unnecessary, the view already carries state); (c) the board push uses {player_id, score} rows until RMP membership lands the anonymized alias (the wire shape accepts {alias, score}, alias defaults to id) — a deferred-system concern, not a blocker.

### V-14 — The COMMITMENT SCHEME for blind Golden (the exact hash + what is committed). RECOMMEND Arm A: byte-pinned SHA-256 over a canonical encoding of secret ‖ nonce.

RATIONALE: the blind flow ships LIVE (V-6 Arm B), so the provably-fair commitment is written + verified this scope. architecture.md "Provably-fair secret" names a hash commitment as "the lean instantiation" but leaves the exact scheme an OPEN QUESTION ("is a stronger scheme or a published per-room seed required"). Because a player must recompute H(secret‖nonce)==commitment at reveal, the scheme must be FIXED + the encoding byte-pinned + published — it cannot be left to build-time discretion (a mismatch silently breaks verification). This is a fork to rule, not invented surface (the canon names the mechanism; only the family is open).

Arm A (RECOMMENDED) — SHA-256 over a canonical UTF-8 encoding of the six secret codes joined by a record separator, then ‖ nonce, emitted as lowercase hex; the games.commitment column is a string. 5W: WHO=rooms.ex start_game (golden branch) computes it; WHAT=commitment=lowercase-hex(SHA256(join(secret, SEP) <> SEP <> nonce)); WHEN=at open, stored on the GAM; WHERE=a new pure Codemojex helper + games.commitment; WHY=SHA-256 is the canon's lean default, collision/preimage-resistant, and PUBLISHABLE so the client recomputes (the verifiable in provably-fair). STEELMAN: standard, auditable, zero new dependency (Erlang :crypto.hash(:sha256, ...) is in OTP); the encoding being byte-pinned + documented is the actual deliverable — a client in any language reproduces it. STEWARD: a stronger scheme later (a published per-room seed, a Merkle commitment per cell) is additive — the column stays a string; the only cost is a documented encoding version.

Arm B — per-cell / per-position commitment (a commitment per secret position). STEELMAN: allows partial reveals. AGAINST: leaks structure — a position-by-position commitment narrows the secret space (an attacker learns the per-cell distribution); the canon wants ONE hiding commitment over the whole secret; overshoots the blind contest.

Arm C — HMAC with a server-held key. STEELMAN: binds to a server secret. AGAINST: the keyed secret CANNOT be published for the player to recompute → breaks verifiability (the player can't check HMAC without the key); defeats provably-fair. REJECTED.

RECOMMENDATION: Arm A. The deliverable is the byte-pinned encoding (so the client verifies identically); the hash family is the Operator's ruling. Schema-neutral (string column either way). The Director rules with the Operator (architecture.md genuinely leaves it open).

### V-15 — The SEALED TOP-K PAYOUT CURVE (how the boosted pool divides across the K winners). RECOMMEND Arm A: a fixed top_k with a graduated decreasing share per rank.

RATIONALE: the sealed settlement ships LIVE; games.top_k is written but HOW the pool splits across the K is unspecified. specs.md:47 says "pay the top K" without a curve. economy.ex already has winner_take_all/2 (K=1) + proportional/2 — a top-K-by-rank curve is a new pure function. The schema carries only top_k; the split shape is an Operator-visible product decision (it sets the prize distribution), so it is a fork to rule, not a silent build choice.

Arm A (RECOMMENDED) — a fixed top_k (a number snapshotted from the room) + a graduated split: rank players by best linear points desc, pay ranks 1..K a decreasing share of effective_pool (a documented monotone weight, e.g. normalized rank weights w_i = (K-i+1)/sum). 5W: WHO=Codemojex.Settle golden branch calls a new economy.ex top_k_split/2; WHAT=split effective_pool across the K highest by a fixed monotone curve; WHEN=at the sealed pass inside the SET NX one-shot; WHERE=economy.ex (the pure function) + the games.top_k breadth; WHY=rewards a field (not just the single winner) which suits a no-feedback contest where many invested guesses, while keeping rank-1 the largest prize; PURE so the idempotency story holds. STEELMAN: matches "top K" literally; a documented curve is auditable + idempotent; the seam (economy.ex policy fn) already exists; a fixed K is a stable config the room sets. STEWARD: a different curve later is a new economy.ex function selected by the economy policy word — additive, no schema change.

Arm B — winner-take-all even in golden (top_k effectively 1). STEELMAN: simplest, reuses winner_take_all/2. AGAINST: makes games.top_k vestigial + contradicts the canon's "top K"; a no-feedback all-pay contest paying only one is a harsh economy.

Arm C — top_k as a FRACTION of the field (e.g. top 10% of players). STEELMAN: scales the prize breadth to turnout. AGAINST: couples the prize structure to turnout (an economic lever better left a fixed config); harder to communicate to players up front; the prize count becomes nondeterministic in the field size. Surface it; A is the stable default.

RECOMMENDATION: Arm A — a fixed top_k + a graduated split, a new pure economy.ex function. The curve shape is the Operator's product decision; the schema (top_k only) is unaffected. The Director rules with the Operator.

### V-16 — The REDUCED EMOJI-SET SIZE + the ANONYMIZED LEADERBOARD treatment (two sub-decisions, one Arm). RECOMMEND Arm A on each: a 24-cell EMS row + DEFER the anonymized alias to the RMP rung.

RATIONALE: blind Golden draws from a reduced set (specs.md:46 "18 or 24 cells", architecture.md:14 "a reduced symbol set") — a concrete launch size is needed since golden ships now. AND the canon's anonymized leaderboard (architecture.md "Anonymization", specs.md:49) needs a per-game alias on the RMP membership — but RMP is NOT built (the leaderboard keys on PLR directly). Both are real on-disk references with an open value.

Arm A (RECOMMENDED, both sub-decisions):
(a) SIZE = a 24-cell reduced EMS row (the larger of the canon's two examples; a six-of-24 space is tractable without hints). MECHANISM = a smaller EMS row (the as-built EmojiSet supports arbitrary codes arrays), NOT a per-game games.symbols subset column. 5W: WHO=an EMS row the golden room points at; WHAT=codes array of 24; WHEN=room creation picks the reduced EMS; WHERE=emoji_sets (an EMS row) + rooms.emojiset; WHY=no schema change (the EMS route is grounded), the secret is six distinct of 24.
(b) ANONYMIZED LEADERBOARD = DEFER to the RMP rung. Until RMP membership exists, a golden leaderboard ranks by PLR like classic. CRITICAL: the reveal-gated privacy (no score crosses the wire until revealed_ms, INV-9/G1) ALREADY delivers the blind contest's secrecy — the anonymized alias is a presentation refinement on TOP of an already-secret contest, not a correctness requirement. So deferring it does not weaken the blind guarantee.
STEELMAN: both honor NO-INVENT (the EMS route + the PLR-ranked leaderboard are real; building an alias without RMP invents the membership surface); the privacy gate carries the secrecy. STEWARD: the alias lands additively with RMP; a different set size is a different EMS row (no code change).

Arm B — build a per-game alias now WITHOUT RMP (a games-level or guess-level ephemeral alias). AGAINST: invents the membership surface the RMP rung owns; the privacy gate already secures the contest, so this is speculative.
Arm C — an 18-cell set (the harder space). The Operator's call if a tighter difficulty is wanted; A picks 24 as the more forgiving launch default.

RECOMMENDATION: Arm A on both — a 24-cell EMS row (mechanism: a smaller EMS, not a games.symbols column) + defer the anonymized alias to RMP (the reveal-gated privacy already secures the blind contest). The Director rules the size (24 vs 18) + confirms the defer with the Operator.

## {codemojex-game-rename-report} Report

### Y-1 — Stage-1 reconcile + brief: BUILD-GRADE (1 Operator fork to rule first)

VERDICT: build-grade — every cited symbol/route/field re-found on disk; the only unfixed item is the migration fork (§3), which is the Operator's call by design (touches prod data) and must be ruled before Mars touches a migration.
DELIVERABLES (docs only — no production code edited):
 • docs/codemojex/codemojex.progress.md (NEW dashboard — rolls up B7.1–B7.6 PLANNED, opens the rename rung HIGH, records the ROM↔ROM out-of-scope follow-up; house voice of emq.progress.md).
 • docs/codemojex/codemojex-game-rename.brief.md (NEW — the authoritative brief: the 3-register naming discipline, the 4-token-class rename law, surface-by-surface file:line inventory across code/docs/BCS, the migration Path A/B fork, the gates, the build DAG, 4 agent stories R-1..R-4).
 • the aaw ledger docs/codemojex/codemojex-game-rename.progress.md (T-1..T-6, D-1/D-2, V-1/V-2/V-3, L-1, this Y-1).
KEY PLAN-MAP DRIFT CORRECTED: (1) codemojex.architecture.md + codemojex.specs.md are ALREADY game/GAM — VERIFY-ONLY, not edit targets (the plan map expected "round"). (2) bcs.2.md has 11 round hits not ~6 (only 6 are entity). (3) html/bcs entity-round = exactly 8 sites / 7 files, enumerated for bcs.todo.md, with the html/bcs/codemojex/index.html data-seg="round" trio flagged as a figure-internal-segment JUDGMENT call (rename all 3 or none). (4) NO-INVENT line drawn: leave Kernel.round/1 (scoring.ex:55), Float.round, Math.round, English round-trip, and the ROM/ROM/PLR/USR vocabulary (the separate reconcile).
TWO STALE design.md facts flagged OUT of rename scope: health path is /health (fly.toml+router) but design.md L174 says /api/health; design.md keys room at ROM/player at USR while the canon uses ROM/PLR. Neither is part of round→game.
THE FORK FOR THE OPERATOR (Director → AskUserQuestion): does the deployed codemoji-phoenix prod DB carry real RND rows? → Path A (edit create-migrations in place, reset dev/test) if pre-launch; Path B (NEW reversible rename+rebrand migration, history preserved, team proves up/down on a test DB, Operator runs prod) if live data. DEFAULT-IF-UNREACHABLE = Path B (safe either way; A is unsafe if data exists). Disk says prod is CONFIGURED but documented PRE-LAUNCH; the Operator's "with the stored-data migration" leans toward data.

### Y-2 — Game-engine model design COMPLETE (BUILD-GRADE pending Operator approval of the §10 Arms)

Deliverable: docs/codemojex/codemojex.game-model.design.md — the from-scratch model redesign for a multi-game-type engine. Grounded entirely on disk this session; no production code edited.

The new schema (7 tables): players(USR)/transactions(TXN)/emoji_sets(EMS) UNCHANGED; rooms(ROM) gets round→game FK + a type column; games(GAM, was rounds/RND) gets a type discriminator + the four policy columns (feedback/scoring/settlement/economy) + golden/gold_multiplier folded in; guesses(GES) gets round→game FK and DROPS tier + percentage (linear points only). Valkey: the bonus layer (cm:{game}:ptier/bonus/tierfirst) REMOVED; the board ZSET ranks raw best linear points.

Game-type abstraction (Arm V-1=A): one games table + a type CHECK ('classic'|'golden') + explicit typed policy columns snapshotted from the room at start — the canon's own "GAM holds a mode + four policies, no new entity types" shape, the minimal delta, keeps the entity one GAM id. Golden modeled (Arm V-3=A) as the AS-BUILT boost-only type (golden/gold_multiplier + effective_pool, live feedback); the forward blind-mode Golden is PROPOSED (its commit-reveal/sealed/anonymized mechanics are explicit open questions in architecture.md) — deferred behind the type/policy seam, additive later, NO-INVENT.

Bonus tiers (Arm V-2=A, HARD constraint): guesses.tier + percentage dropped; Board.record/4→record/3 (tier-claim arm + firsts/2 removed); the scored event drops tier/first. Linear Scoring.score/2 stands as the sole score + rank. NOTE: players.bonus_diamonds is a WALLET bucket, NOT a game tier — KEPT (do-not-over-remove flag).

Reinitialization (Arm V-4=A): collapse the 2 migrations into one clean initial create; Mars runs mix ecto.drop/create/migrate on codemojex_dev (config/dev.exs:14) when the model is ready (Operator-authorized).

Four Arms need Operator approval (V-1..V-4, recommendations each); one "as described" gap recorded (L-2: the launch type set is {classic,golden} — the only types described on disk; Golden's description is itself split between as-built boost-only and forward blind-mode). Canon-drift [RECONCILE] flagged: roadmap B7.4.2/B7.3 + game_rules.md still teach the removed tiers — a follow-up canon reconcile owed.

Stories R-1..R-6 (Given/When/Then, INV-1..INV-7) are the build's acceptance. Ledger: T-8, D-4/D-5, V-4/V-5/V-6, L-2.

### Y-3 — Venus final report (the IDENTITY/TOKEN/WIRE/CODE-SURFACE axis), BUILD-GRADE pending 3 Director-ruled forks

VERDICT: the extension axis is BUILD-GRADE — every claim grounded to a real file:line or a specs.md § (re-found on disk this turn); three forks await the Director's AskUserQuestion before the blind build, all with a RECOMMENDED Arm.

FILES EXTENDED (4, all under docs/codemojex/, disjoint from VenusPG):
- codemojex-game-rename.brief.md — +§10 (RMM→ROM + USR→PLR, brand-only, every file:line) +§11 (blind/sealed wire, B-1..B-4) +§12 (unified residual grep) +§13 (extended stories + DAG). Header now states the brand-vs-word law.
- codemojex.design.md — reconciled forward to GAM/ROM/PLR (0 legacy brand tokens, 0 entity-round prose), D-5 tier-removal + V-6 blind reflected, deep MODEL reconcile flagged to VenusPG's docs via [RECONCILE].
- specs/cm.1.stories.md — S-6 reconciled inert→LIVE; +S-7/S-8/S-9; Coverage+Liveness for D6/D7/D8 + INV-9.
- specs/cm.1.llms.md — +R6/R7/R8 +A-5/A-6 + unified §5 gate (3-brand grep + privacy-line exercise + ≥100 loop + docs grep); footer notes dual authorship.

KEY GROUND TRUTH (T-13): the T-12 directive is CORRECT, the prior brief/design.md were STALE on the room brand. rooms.ex:18 mints "RMM" (0 "ROM" in code); wallet.ex:21 mints "USR" (0 "PLR"). The room/player re-base is BRAND-ONLY — 5 line-edits (rooms.ex:14,18 + game.ex:6, wallet.ex:19,21), the words room/player stay everywhere. This CLOSES the D-4 out-of-scope drift note.

ARMS FRAMED (3, all RECOMMEND Arm A):
- V-11 — room/player WIRE words: keep /players //rooms /player: /:no_player (no canon word to flip TO; flip only the brand id-prefix). Arm B (flip for symmetry) REJECTED on no-invent.
- V-12 — the FK COLUMN names transactions.player/guesses.player: keep `player` (the brand moves the id VALUE, not the column NAME; D-3 fresh schema = no migration cost either way). VenusPG also owns the column; expected convergence on keep.
- V-13 — the blind REVEAL-event shape: one fat "revealed" event (secret+nonce+commitment+board+top-K+state) at close + the commitment on game_view from open + the per-guess push suppressed in-flight. Arm B (separate reveal+settled) heavier; Arm C (poll) REJECTED (drops the mandated channel).

BLOCKING: none for the spec. The blind BUILD is blocked until the Director rules V-11/V-12/V-13 (the brief/stories/llms carry all three as RECOMMENDED Arms ready to ratify). The migration is D-3 (one fresh collapsed initial create, no data migration) — VenusPG's relational shape.

DUAL-ARCHITECT BOUNDARY HELD: did NOT read VenusPG's new cm.1.md / codemojex.game-model.design.md edits; did NOT edit them. No production code. No git. FROZEN history untouched.

### Y-4 — VenusPG Stage-2 data-model extension COMPLETE (BUILD-GRADE for cm.1; cm.3 contracts authored, 5 Arms to rule)

VERDICT: build-grade. The data model + the founding-rung body (cm.1) are build-ready and depend on no open fork; the blind-Golden body (cm.3) is authored with its 5 open mechanics framed as Arms (each cited, [RULE]-marked with a cited-canon default) for the Director to rule via AskUserQuestion before the cm.3 build leg. No production code edited; no git.

FILES (edited ONLY under docs/codemojex/ — disjoint from Venus):
• docs/codemojex/codemojex.game-model.design.md — EXTENDED: §0 (3 brand re-bases incl. RMM→ROM/USR→PLR), §0.1 (V-6 Arm B + the brand-rebase row), §0.2 NEW (the two ground-truth corrections), §2 (six tables, ROM/PLR rows), §3.1/§3.4 (brand headers + mint-site source), §3.5 (the four blind columns LIVE + a written-when/read-when table), §3.8 (this-scope-ships-blind + Arms V-10/11/12 reframe), §3.8.6 (USR→PLR), §4 (the brand-contract table → GAM/ROM/PLR + the 3-mint prose), §5 NEW §5.1 (the blind keyspace), §6.1/§6.3/§6.6/§6.8 (the 3 mints + the blind open/close branches + the privacy widening), §8.1 (six-table collapse), §9 (R-1 the 3 re-bases, R-4 blind/sealed, R-7 NEW commit-reveal+privacy, coverage + the cm.1/cm.3 split), §10.2 (V-7/V-8 LIVE + the 3 new blind-mechanic Arms), §10.3/§11 (boundary brands), §12 (the ladder: cm.1 3-brands + cm.3 builds-this-scope, cm.2 folded; §12.3 cm.1 extended; §12.4 NEW cm.3 triad).
• docs/codemojex/specs/cm.1.md — EXTENDED: the founding-rung body widened to the 3 brand re-bases + the six-table + the dev/test DB names + the two residual-greps (RND/RMM/USR + the entity/bonus tokens) + the migration up/down gate. (My own prior-pass deliverable, NOT Venus's — confirmed by the "Authored by Venus-PG" provenance + the untracked `?? specs/` state.)
• docs/codemojex/specs/cm.3.md — NEW (224 lines): the blind-Golden spec body. G1 feedback-none+privacy · G2 commit-reveal · G3 sealed top-K · G4 revealing/settling states · G5 reduced set; INV-5 sealed-exactly-once-idempotent · INV-9 privacy+binding · INV-10 no-new-table · INV-11 wallet-floor; the gate's privacy/fairness/idempotency probes (each self-liveness); §8 the 5 Arm-rulings table.

THE 5 ARMS THE DIRECTOR RULES (with the Operator) before the cm.3 build (ledger V-n is the authority):
1. COMMITMENT SCHEME (V-14) → RECOMMEND byte-pinned SHA-256 over a canonical encoding of secret‖nonce, lowercase hex (the deliverable is the pinned encoding so the client recomputes; HMAC rejected — unpublishable; per-cell rejected — leaks structure).
2. TOP-K SPLIT CURVE (V-15) → RECOMMEND a fixed top_k + a graduated decreasing share per rank (winner-take-all rejected — makes top_k vestigial; fraction-of-field rejected — couples prize to turnout).
3. REDUCED-SET SIZE + ANONYMIZED ALIAS (V-16) → RECOMMEND a 24-cell EMS row (mechanism: a smaller EMS, NOT a games.symbols column) + DEFER the anonymized alias to the RMP rung (the reveal-gated privacy already secures the blind contest).
4. SCORING UNIFICATION (V-7, re-raised LIVE) → RECOMMEND one linear function both modes (the Operator's HARD constraint + roadmap B7.4.1; architecture.md:59's "exact-match" is the rejected arm).
5. STATE-MACHINE SHAPE (V-8) → RECOMMEND the full canon set as text words; sub-rulings: CHECK-bound the 7 words? classic terminal = settled (unified) or closed (as-built)?

TWO GROUND-TRUTH CORRECTIONS (L-4 — the reconcile caught both):
(a) SIX Postgres tables, not seven — no notifications table in either migration (NOT = a Valkey lane); the collapsed create is players/transactions/emoji_sets/rooms/games/guesses.
(b) DB names = codemojex_dev / codemojex_test (config/dev.exs:14 / config/test.exs:19); runtime.exs reads DATABASE_URL — the prompt's `codemoji_game` is FALSIFIED by disk; no *_snapshot DB exists in config. The reinit targets codemojex_dev + codemojex_test ONLY.

ONE FLAGGED FOLLOW-UP (not a blocker, for the Director): cm.1.stories.md + cm.1.llms.md (the DERIVED founding-rung triad) still reflect the ONE-brand scope — they need a re-derive to the now-three-brand cm.1.md body. The BODY is authoritative + extended; the derived files lag (a Venus or a follow-up VenusPG task). cm.3.stories.md + cm.3.llms.md are intentionally NOT authored yet (they derive after the 5 Arms are ruled, so their contracts are fixed not guessed).

GROUNDING: every table/column/policy/blind-mechanic cites a real schema/migration/canon-line; the mint sites re-found on disk (rooms.ex:18/60, wallet.ex:21, tables.ex:59); the three flagged gaps (BNK/RMP/SES) designed-around, never invented; the five open mechanics are Arms to rule, not surface invented. Ledger: T-15, V-14/V-15/V-16, L-5, D-12, this Y-3.

### Y-5 — Stage-2 CONVERGENCE COMPLETE: the D-15/D-16 rulings folded, cm.1 + cm.3 build-grade

VERDICT: BUILD-GRADE. Every Operator ruling (D-15 PRODUCT/SCOPE + D-16 ENGINEERING SLATE) is folded into the data-model spec; the cm.1 + cm.3 triads are reconciled to consistency; no `[RULE]`-pending fork remains in any body. ONE residual fork surfaced (cell_size, below) — recommending 72, the Director rules.

FILES FOLDED (7, all under docs/codemojex/):
1. codemojex.game-model.design.md — the convergence pass: §0.1 ruled-Arms table (added the 7 mechanic rulings), §0.3 NEW (the 3 mechanism corrections + the V-number aliasing note), §2/§3.4/§3.5 (the new columns games.payout_split/cell_codes + rooms.payout_split/cell_count, top_k default 5, the games_status CHECK), §3.3.1 NEW (the EMS seed measured from the 2 real sprite sheets), §3.8.2 (the stored payout_split split, SUPERSEDES the computed curve), §3.8.3 (SHA-256 ruled), §3.8.4 (room cell_count + per-game cell_codes snapshot, SUPERSEDES the smaller-EMS row), §3.8.5 (CHECK-bounded status, classic terminal settled), §3.8.6 (the alias defer + the gap-count fix), §6.1/§6.3/§6.6/§6.8 (the cast list + the snapshot + the one fat reveal + top_k_split/2), §8.1 (the migration's new columns + both CHECKs), §9 R-4/R-7 (the stored split + SHA-256), §10.2 (RULED — was OPEN), §12 (the ladder + the cm.1/cm.3 body summaries).
2. specs/cm.1.md — D1/D3 (the new columns + both CHECKs), INV-8 (the inert state per column), §6 gate (the games_status CHECK), the header + scope.
3. specs/cm.1.stories.md — S-1/S-4/S-6 (the new columns), S-9 (the one fat `revealed` event + SHA-256, was "shape per the V-13 ruling").
4. specs/cm.1.llms.md — R1/R3 (the new columns + the snapshot), the DAG steps 1/3, A-1/A-6 (the ruled reveal), §5 gate (the games_status CHECK + the migration up/down 4').
5. specs/cm.3.md — the header (all mechanics RULED), §2 IN/OUT, G1-G5 (every [RULE] marker → a ruled contract), §4 grounding, §5 INV, §6 fairness probe (SHA-256), §8 (the Arm table → RULED).
6. specs/cm.3.stories.md — NEWLY AUTHORED (was deferred until the Arms ruled): G-1..G-5 Given/When/Then + Coverage + Liveness.
7. specs/cm.3.llms.md — NEWLY AUTHORED: R1-R6 + the pinned commitment byte layout + the DAG + B-1..B-3 + the gate.

THE MEASURED EMS GRID (the V-16a asset grounding, §3.3.1): both sheets are cols=10, cell_size=72 (NOT the code default 144, which gives non-integer rows). EMS-1 (01-emoji-set.png): 720×1080 → 10×15 = 150 cells. EMS-2 (02-emoji-set.png): 720×1512 → 10×21 = 210 cells. @2x retina = exactly 2× base (no extra rows). codes = the FULL keyboard (the reduced set is the per-game cell_count snapshot, not a smaller EMS).

THE TRIAD-RECONCILE RESULT (Task B): the cm.1 DERIVED files (stories + llms) were ALREADY aligned to the three-brand body by Venus's Y-3 (S-7/S-8/S-9, R6/R7/R8, the Coverage). The convergence's reconcile of them was the UNRULED-Arm lag only: the V-13 reveal-event was "shape per the V-13 ruling the Director relays" (pending) → now "one fat `revealed`" (ruled), plus the new columns added to S-1/S-4/S-6/R1/R3/A-1. cm.3's stories + llms did NOT exist (deferred until ruled, per Y-4) — newly authored this pass. Content aligned; Venus's story/requirement STRUCTURE + numbering preserved.

GATE/ACCEPTANCE COVERAGE (Task C — confirmed across the triad): the configurable-split sealed-settlement test (cm.3 G-3 + the idempotency probe), the N-cell-subset secret-draw test (cm.3 G-5 + cm.1 S-6), the 3-brand residual greps (cm.1 §6/§5 — RND/RMM/USR → 0, BIF-sparing), the migration up/down proof (cm.1 §6 4' + cm.1.llms §5 4'), the privacy-line exercise (a PRESENT golden game RUNS suppression + reveal — cm.1 S-9 + cm.3 G-1/§6). Grounding re-verified on disk: EmojiSet.secret/1 = Enum.take_random(codes, 6) (emoji_set.ex:64); Wallet.deposit_prize/3 (wallet.ex:53); economy.ex effective_pool/3 + winner_take_all/2 + proportional/2 (top_k_split/2 is the NEW seam beside them).

THE ONE RESIDUAL FORK (cell_size, F-CV1 — Director rules with the Operator): the 2 real sprite sheets fit cell_size 72 (integer grid), NOT the code default 144 (non-integer rows). The seed states 72 (the measured-true value); the Operator confirms 72 OR intends a 144 re-export. A one-line ruling that changes only the 2 EMS seed rows; the cell_count/cell_codes mechanism is unaffected. NOT a build blocker — Mars seeds the EMS from the ruled value.

CONVERGENCE INVARIANTS HELD: edited ONLY under docs/codemojex/; no production code touched; no git; the FROZEN ledger history (T-1..T-18, D-1..D-16, V-1..V-16, L-1..L-5, Y-1..Y-4) untouched — appended only (T-19/T-20, D-17/D-18, L-6, this Y-5). Framing rules enforced (0 gendered pronouns / first-person agent narration; the only sees/wants/notices hits are the propagation-clause text itself). Ledger: T-CV1/T-CV2 (=T-19/T-20), D-CV1/D-CV2 (=D-17/D-18), L-CV1 (=L-6), this Y-5.

### Y-6

Y-Mars-1 — Mars-1 build COMPLETE + full gate GREEN. All work in the working tree (no git; Director commits).

GATE RESULTS (run from echo/apps/codemojex, TMPDIR=/tmp):
- asdf re-probe (app dir): elixir 1.18.4 / erlang 28.5.0.1 (umbrella .tool-versions). PASS.
- valkey-cli -p 6390 ping → PONG. pg_isready → /tmp:5432 accepting. PASS.
- mix compile --warnings-as-errors → Generated codemojex app CLEAN (the only warnings are pre-existing echo_data/champ_view.ex Graft-undefined, a sibling app, untouched). PASS.
- Resolved DB target (config/test.exs, DATABASE_URL UNSET): codemojex_test<PARTITION> @ localhost:5432 postgres/postgres. TEST DB reinitialized: MIX_ENV=test mix ecto.drop && ecto.create && ecto.migrate → the ONE collapsed migration (20260618000000_create_codemojex.exs) comes up clean from zero: 6 tables (players/transactions/emoji_sets/rooms/games/guesses), both indexes, players_non_negative CHECK + games_type CHECK + games_status CHECK. PASS.
- Migration up/down proof (HIGH-risk gate): ecto.rollback drops all cleanly, ecto.migrate re-applies clean. PASS.
- mix test --include valkey → 40 tests, 0 failures (full tree on Valkey 6390 + Postgres). mix test (pure) → 40 tests, 0 failures, 18 excluded. PASS.
- ≥100 determinism loop (150 iters, --include valkey): 150 passed, 0 failed (same-ms GAM/ROM/PLR mint hazard clean). PASS.
- mix codemojex.stories regenerated → 8 feature files / 40 scenarios + README in docs/codemojex/stories (rooms-and-games + golden-blind present, NO stale rooms-and-rounds).

RESIDUAL-GREP PROOF (the unified acceptance, brief §12 / cm.1.md §6):
- /usr/bin/grep -rnoE '\b(RND|RMM|USR)\b' lib test → 0 (all three brands re-based). PASS.
- /usr/bin/grep -rniE '\b(round_view|:cm_rounds|"round:"|/rounds|:no_round|Schemas\.Round|guesses?\.tier|tierfirst|claim_tier|firsts)\b' lib test → 0 (round→game entity/api/wire + bonus tokens gone). PASS.
- BIF SURVIVES: round( present in scoring.ex:52 (Kernel.round) + economy.ex (Float.round/round); English "round-trips"/"round up"/"dogs round" left untouched. PASS.
- New brands minted: generate!("GAM") rooms.ex, generate!("ROM") rooms.ex, generate!("PLR") wallet.ex; kind:"GAM" tables.ex. PASS.
- NOTE for Director: a blind `\.percentage` grep would flag game.ex:132/140 — those are `s.percentage`, the COMPUTED value Scoring.score/2 returns (kept per §7 "percentage computed-not-stored"); the COLUMN is gone (guess.ex schema + Store.put_guess write nothing). Not a residual.

BOUNDARY: all code changes under echo/apps/codemojex/** (lib + lib/codemojex_web + priv/repo/migrations + test). Zero sibling umbrella apps touched (echo_mq/echo_store/echo_data/echo_wire/echo_bot). mix.lock untouched. The docs/codemojex/ changes (game-model.design.md, cm.1.llms.md M; cm.3.llms.md ??; stories/ regen) are Venus/generator artifacts — NOT Mars code edits — for the Director's docs concern.

PRIVACY LINE (INV-9/G6, EXERCISED): view.ex NEVER selects :secret/:nonce (grep clean); golden game_view carries :commitment from open, withholds score/points/leaderboard pre-reveal; the golden_blind story RUNS suppression (refute_received {:scored,_}, history withholds points, leaderboard []) + reveal (assert_receive {:revealed,...}, Rooms.commit(secret,nonce)==commitment recomputes SHA-256) + idempotency (second close → {:ok, :already_closed}).

WHAT IS GREEN vs WHAT REMAINS FOR HARDEN: everything specced is built + green. Open items for the harden/Director pass (none blocking): (a) the dev DB (codemojex_dev) drop is the Director's go-call — NOT run (only the ephemeral test DB reinitialized for the gate); (b) the Surface 2/3 docs reconcile (design.md mirror, bcs.2.md, bcs.todo.md authoring) is OUTSIDE Mars's prompt boundary (echo/apps/codemojex/** only) — flagged for the Director; (c) the live dev-node liveness check (mix phx.server + curl :4000) is a non-ephemeral-context task — the Director/Operator boots it, a spawned agent's node is reaped at turn-end.

## {codemojex-game-rename-progress} Progress

### P-1

P-Mars-1 — Lib+web surface BUILT + compiles clean (--warnings-as-errors, codemojex Generated clean; only pre-existing echo_data/champ_view.ex Graft warnings remain, sibling app untouched). Done: (1) THREE brand re-bases — RND→GAM (rooms.ex generate!("GAM") + tables.ex kind:"GAM" + full entity drag: Schemas.Round→Game [round.ex deleted, game.ex created], schema "rounds"→"games", :round FK→:game in room.ex/guess.ex, Store round CRUD→game, @cache :cm_rounds→:cm_games, fetch_round/put_round→fetch_game/put_game, @rounds→@games, :rounds_cache_ttl_ms→:games_cache_ttl_ms, load_round→load_game, rooms.game field, View round_view→game_view, facade game_view+close_now→close_game, wire /games + "game:" topic+channel + :no_game + game: keys); RMM→ROM (rooms.ex generate!("ROM") + docstring, word "room" byte-exact); USR→PLR (wallet.ex generate!("PLR") + docstrings, word "player" byte-exact incl. transactions.player/guesses.player columns V-12). (2) Six-table schema: Game schema + 4 policy cols + 4 blind cols (commitment/nonce/revealed_ms/top_k default 5) + cell_codes + payout_split default [40,25,15,12,8]; rooms +type +payout_split +cell_count; guesses DROP tier+percentage. (3) Tier removal: Board.record/4→record/3, removed claim_tier/firsts/ptier/bonus/tierfirst/eff=base+bonus; ZSET takes raw new_base; scoring.ex tier/1 + :tier key REMOVED (percentage kept computed per §7); ScoreWorker put_guess drops percentage/tier; scored event+PubSub drop tier/first. (4) Blind/Golden wire (D-10 LIVE this scope): B-1 ScoreWorker branches on feedback=="score" (golden suppresses scored push + perfect-crack close); B-2 game_view carries :commitment from open, withholds score+points+leaderboard pre-reveal (revealed?/feedback branch); B-3 close_sealed emits ONE fat :revealed event (secret+nonce+commitment+board+top-K+state); B-4 channel handles :scored/:revealed/:golden_win, state+timer in-flight. commit-reveal V-14: SHA-256(code₀‖…‖code₅‖nonce) RS=0x1e lowercase hex via Rooms.commit/2; secret drawn from cell_codes (V-16a) via EmojiSet.secret_from/1; top_k_split V-15 new pure Economy.top_k_split/3 (rank i takes split[i]/Σsplit_used, normalizes when <K present). (5) One collapsed migration 20260618000000_create_codemojex.exs (6 tables, both CHECKs games_type+games_status). (6) EMS seed priv/repo/seeds.exs (2 rows from real sprites, cell_size=72 measured-true: 01=10×15=150, 02=10×21=210). (7) Demo priv/round.exs→priv/game.exs. RESIDUAL-GREP lib: \b(RND|RMM|USR)\b → 0; entity/api/wire symbols → 0; BIF round( survives scoring.ex:52. NOTE: \.percentage grep hits s.percentage (the COMPUTED value, §7 kept) NOT a column — flagged for Director. Next: tests (rename rooms_and_rounds→rooms_and_games + linear-only + blind privacy story) + stories regen + DB reinit + full gate.
