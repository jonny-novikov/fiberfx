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
