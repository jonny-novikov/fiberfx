# trd-1-1 — AAW scope ledger

## {trd-1-1-thinking} Thinking

### T-1 — UNDERSTAND/EXPAND: ship trd.1.1 (the Exchange Gateway MVP) · mode Flat-L2 · risk NORMAL (no Apollo)

INPUTS. The build-grade TRD.1 quad (docs/trading/trd.1.{md,specs.md,stories.md,llms.md}, PROPOSED): a total parse-don't-validate boundary — untrusted map → typed command {place|cancel|replace} OR one of a closed 6-atom error set; branded CMD/ORD minted at acceptance; Quotation {units,nano} integer money (never float); stateless (INV-1..6). Operator answers settled the open forks (resolved decision matrix, below).

5W. Why: align the /bcs B8 capstone (which teaches a PROPOSED Exchange.* with no code) to reality — scaffold the engine's door for real + rename the platform "Exchange". What: a new lib-only umbrella app echo/apps/exchange holding Exchange.Gateway (place limit+market + cancel) + the rename docs/trading→docs/exchange (trading*→exchange*, trd.* rung codenames KEPT) + BCS references in docs/echo/bcs/bcs*.md. Where: echo/apps/exchange + echo/rungs/exchange/trd_1_1_check.exs + docs/exchange. When: first rung of milestone A; stands on the echo_data canon alone (no unbuilt dep). Who: Exchange.Gateway (new), the canon EchoData.* (reused).

SOLUTION SPACE (alternatives ruled out). (A) full app + supervision tree — REJECTED, the Gateway is stateless (INV-5), a tree is over-scope (TRD.2's Exchange.Book is the first process). (B) lib-only app (the echo_data shape) depending only on {:echo_data, in_umbrella: true} — CHOSEN, reductive-minimal, matches AS-5 (one stateless file, no dep beyond the canon, no app-env). (C) fold into an existing app — REJECTED (distinct bounded context; the Operator wants a new app). (D) do-nothing baseline — REJECTED (the ask is to ship). Pipeline named: x-mode Flat-L2 (Venus reconcile → Mars-1 → Director solo review → Mars-2 → Director ship).

INVARIANTS AS RUNNABLE CHECKS (the rung gate). G1 valid place mints two distinct ids; G2 six malformed inputs → six exact error atoms, no crash; G3 a float price → :bad_price, no float in any output (structural); G4 market → price: :market; G5 opaque instrument/account carried verbatim, unbranded; + cancel parses; + a StreamData totality property (every input → typed command | one error atom, never a crash/float); + AS-5 grep empty (no use GenServer / :ets / Application.get_env). NO-INVENT verified: EchoData.Snowflake.next_branded/1 is real (snowflake.ex:103); BrandedId.{valid?/1:95, namespace/1:97} real; the kind-gate pattern is EchoCache.Table.gate/2 (table.ex:495). Scaffold: umbrella auto-discovers apps (echo/mix.exs:6 apps_path); template echo/apps/echo_data/mix.exs; rung-gate template echo/rungs/cache/bcs_rung_4_1_check.exs.

SMALLEST CHANGE. One lib-only app + one stateless module Exchange.Gateway (the @types + parse_money/1 + field parsers + parse_place/1 limit+market + parse_cancel/1 + minting) + its test + echo/rungs/exchange/trd_1_1_check.exs + the docs rename + the BCS refs. Idempotency seam (INV-6/G6), replace, bestprice DEFERRED to trd.1.2 (the subtle/broad pieces kept out of the MVP). Counter-examples covered: integer-pair vs string money edge; double-mint distinctness; rejection mints nothing.

RESOLVED DECISION MATRIX (Operator). DM-1 scope = place(limit+market)+cancel; DM-2 idempotency = defer 1.2; DM-3 app = echo/apps/exchange, modules Exchange.*; DM-3b rename docs/trading→docs/exchange (trading*→exchange*, trd.* kept); DM-3c BCS refs in bcs*.md; DM-4 types inside the Gateway; DM-5 mint via Snowflake.next_branded/1; DM-6 Flat-L2; DM-7 defer Go doc.

RISK TIER = NORMAL → no Apollo; the Director's Stage-3 solo review (fresh-gate reconcile + independent gate re-run + adversarial probe + mutation spot-check) + the Stage-5 solo ship-gate are the verification floor. A bundling watch for Stage 5: docs/echo/bcs/bcs*.md carry prior uncommitted B8 work — the LAW-4 pathspec commit isolates trd-1-1 paths; resolve overlap at ship.

### T-2 — RECONCILE (the differ): the greenfield trd.1.1 slice vs the as-built tree

Every spec/AS claim probed against the real code. Verdicts:

MINTING (INV-3 / AS-3) — MATCH.
- `EchoData.Snowflake.next_branded/1` REAL — snowflake.ex:104 (`EchoData.BrandedId.encode!(ns, next())`). The spec's pinned mint call exists at the cited shape. RECOMMENDED for spec fidelity.
- `EchoData.BrandedId.generate!/1` REAL — branded_id.ex:93 (`encode!(ns, EchoData.Snowflake.next())`). The equivalent house idiom; behaviourally identical (both encode!(ns, Snowflake.next())). Equivalence RECORDED; Mars uses next_branded/1.
- `EchoData.Snowflake.next/0` REAL — snowflake.ex:62. `start/1` REAL — snowflake.ex:40 (idempotent; node defaults to phash2(node()); accepts 0..1023). The rung-gate calls `Snowflake.start(N)` once before the first parse.

BRANDED-ID SURFACE (INV-4 / G5 / AS-4) — MATCH.
- `BrandedId.valid?/1` :95, `namespace/1` :97, `encode!/2` :85 — all REAL. The kind-gate idiom, if referenced, is `EchoCache.Table.gate/2` (table.ex:495): is_binary + byte_size==14 + binary_part(id,0,3)==kind + BrandedId.valid?/1. Verbatim-citable pattern for "branded, refused at the wrong door."

IN-UMBRELLA DEP (the AS-5 reconcile note) — MATCH, with the disambiguation MANDATED.
- The `{:echo_data, in_umbrella: true}` edge is REQUIRED by INV-3 (minting calls EchoData.*). It is NOT the dep AS-5 forbids: AS-5 forbids a new EXTERNAL dep + app-env config. The one in-umbrella canon edge is the minting prerequisite, not a new dependency. RECORDED so Mars is not blocked by a literal AS-5 reading. Template: echo/apps/echo_data/mix.exs (shared build_path/config_path/deps_path/lockfile, elixir "~> 1.18"). The umbrella auto-discovers the app: echo/mix.exs:6 `apps_path: "apps"`.

STATELESS BOUNDARY (INV-5 / AS-5) — MATCH (holds for a pure parser).
- `echo/apps/exchange` does NOT exist — Mars scaffolds it (confirmed: apps/ holds echo_bot, echo_cache, echo_data, echo_mq, echo_wire, echomq, live_svelte, mercury_cms, mercury_live_admin, portal, portal_web). The AS-5 grep (no `use GenServer`, no `:ets`, no `Application.get_env`) will be empty on a one-file pure module.

RUNG GATE — MATCH (template confirmed).
- echo/rungs/ holds bus, cache, journal. Mars adds exchange/. Template: rungs/cache/bcs_rung_4_1_check.exs — `Code.require_file` the canon raw (base62→native→snowflake→branded_id), `mix run --no-start`, one `tag ok/FAIL -- detail` line per gate, transcript committed beside it. trd.1.1's script is SIMPLER (the Gateway is pure, no Valkey/Connector) — load the four canon files + the Gateway, `Snowflake.start(N)`, run G1–G5+cancel+totality.

DEFERRED to trd.1.2 (explicit, [RECONCILE]-marked in the slice): parse_replace/1; the parse/1 kind-dispatcher; :bestprice (the third order_type); the INV-6/G6 idempotency seam (replay-token reconciliation + the venue order_id outward position). These are the subtle/broad pieces kept out of the MVP per DM-1/DM-2.

VERDICT: BUILD-GRADE for the trd.1.1 MVP slice. Zero INVENTED / STALE / MISSING. Every surface Mars calls is cited at file:line; the deferred set is marked, not silently dropped.

### T-3 — canon + scaffold confirmed before build

Reconcile of the real surface against the brief, NO-INVENT, all paths confirmed present:
- Mint: EchoData.Snowflake.next_branded/1 (snowflake.ex:104) = next/0 (snowflake.ex:63) then BrandedId.encode!/2; requires Snowflake.start/1 (snowflake.ex:40, idempotent via :persistent_term). Used inside the {:ok,…} branch only (INV-3).
- Assertions: BrandedId.valid?/1 (branded_id.ex:95), namespace/1 (branded_id.ex:97), parse/1 (branded_id.ex:27) — branded id = 3x[A-Z] ++ base62(snowflake) padded to 11 = 14 bytes.
- Scaffold template: echo/apps/echo_data/mix.exs project/0 — shared build_path ../../_build, config_path ../../config/config.exs, deps_path ../../deps, lockfile ../../mix.lock, elixir ~> 1.18. echo/apps/exchange does NOT exist yet; umbrella auto-discovers via apps_path: "apps" (echo/mix.exs). No root edit.
- Toolchain: Elixir 1.18.4 / OTP 28.5.0.1 (asdf, echo/.tool-versions).
Build order = the 4-step decomposition: (1) @types wide + parse_money/1; (2) field parsers; (3) parse_place/1 + parse_cancel/1 with `with` + mint; (4) test file (NOT the rung-gate script — that is Stage 4). Diff confined to echo/apps/exchange/.

### T-4 — Stage-4 harden derivation (rung gate + transcript + format + determinism)

Director Stage-3 verdict (Y-3) = BUILD-FAITHFUL, no correctness defect → no code fix to the Gateway. Stage-4 = the assigned hardening only.
R1 — rung gate echo/rungs/exchange/trd_1_1_check.exs written from the cache template (rungs/cache/bcs_rung_4_1_check.exs): Code.require_file the canon raw (base62→native→snowflake→branded_id) + the Gateway, Snowflake.start(11), one E.line per gate. SIMPLER than the cache template — pure, no Valkey/Connector/Table. Gates printed: G1 place-mints (branded ORD/14/valid? + {units,nano} integers + two-distinct-ids), G2 errors-exact (6 atoms one each), G3 no-float (float/extra-dot/sci → :bad_price + structural no_float? scan), G4 market-ignores-price (parseable/float/absent → :market), G5 opaque-verbatim (instrument/account unchanged + BrandedId.parse → :error), cancel (CMD/14 + verbatim order_ref/instrument + missing-ref :malformed), totality (a self-contained seeded :rand generator — NO StreamData dep so --no-start-safe — 2000 place + 2000 cancel inputs each {:ok,command}|{:error,closed-atom}, try/rescue catches any crash, + non-map→:malformed), AS-5 stateless. Final Enum.all? → PASS 8/8 | FAIL+System.halt(1).
R3 — mix format found drift in TWO files the Stage-2 build never formatted: the test (check all → check all(...)) and the new gate (g2results/m5 wraps). Applied mix format; re-check clean. Re-ran the gate post-format; regenerated the transcript so the committed .out mirrors the formatted source.
DoD artifact — committed transcript echo/rungs/exchange/trd_1_1_check.out (stdout of the gate, exit 0, PASS 8/8; a provenance header documents the produce-command + that the stderr module-redefinition warnings are elided). NOTE: no other rungs/**/*.out exists in the tree — this is the first committed rung transcript; the brief mandates it as the DoD.
R2 — the determinism loop (100× per-app mix test from apps/exchange) running (minting-suite discipline, echo CLAUDE.md §4 — the same-ms mint-collision hazard only surfaces across many independent runs).
Toolchain note carried from Stage 2: a bare `mix compile`/`mix test` runs from the thread's reset cwd (echo/apps/exchange) and scopes to the app; the umbrella-ROOT `mix compile`/`mix test apps/exchange` swallows output (a sibling app's aggregate stalls). Per-app from the app dir is the reliable path.

## {trd-1-1-decisions} Decisions

### D-1 — the Exchange-Platform rename: docs/trading/ → docs/exchange/

Per DM-3b. The FIVE system docs renamed: trading.md→exchange.md, trading.specs.md→exchange.specs.md, trading.roadmap.md→exchange.roadmap.md, trading.patterns.md→exchange.patterns.md, trading.strategies.md→exchange.strategies.md. The rung quads MOVED UNCHANGED in name (the `trd` codename is KEPT): trd.1.*, trd.2.*, trd.progress.md. All via plain `mv` (NO git) — left UNSTAGED for the Director. Intra-folder links to a renamed system doc relinked (label + target) across all 14 moved files. Platform-identity prose updated to "the Exchange Platform" in the system docs (exchange.md title + front-door + AAW line; exchange.strategies.md closing sentence) — generic category prose ("a trading platform has four jobs") and pronominal back-references ("this platform") LEFT INTACT (trading remains the domain; an exchange is where trading happens — not a reflow). docs/trading/ removed (rmdir after rm .DS_Store). The aaw ledger docs/exchange/trd-1-1.progress.md + trd-1-1.registry.json UNTOUCHED. Verify: grep 'trading\.(md|specs|roadmap|patterns|strategies)\b' docs/exchange/ → CLEAN; ls docs/trading → gone.

SCOPE NOTE: the Director scoped my BCS edits to exactly three files (bcs.toc.md, bcs.roadmap.md, bcs.content-map.md). The OTHER docs/trading references found in the BCS tree — specs/bcs.8.specs.md and the markdown/trading/ page tree (both carrying prior uncommitted B8 work) — are OUT of my scope and NOT touched. Those stale docs/trading paths are flagged for the Director (L-1).

### D-2 — the minting call: EchoData.Snowflake.next_branded/1

Per DM-5. Mars mints via `EchoData.Snowflake.next_branded/1` ("CMD" for the command, "ORD" for an order command), inside the success branch only, after one `EchoData.Snowflake.start/1` per runtime. REAL at snowflake.ex:104. The equivalent house idiom `EchoData.BrandedId.generate!/1` (branded_id.ex:93) is behaviourally identical (both encode!(ns, Snowflake.next())) — RECORDED so Mars knows the two are interchangeable, but the spec pins next_branded/1 for fidelity. Mint exactly once per accepted command; never construct id strings by hand; never mint in a rejection branch (INV-3, AS-3).

### D-3 — the TRD.1.1 MVP boundary

Per DM-1/DM-2. IN trd.1.1: place(limit+market) + cancel; the @types (direction, order_type, money, the closed 6-atom error); parse_money/1 + the field parsers (parse_direction/1, parse_order_type/1, parse_quantity/1, parse_instrument/1, parse_account/1); parse_place/1 + parse_cancel/1; minting via Snowflake.next_branded/1; gates G1–G5 + cancel + the StreamData totality property + the AS-5 statelessness grep. DEFERRED to trd.1.2 ([RECONCILE]-marked in trd.1.1.specs.md): parse_replace/1; the parse/1 kind-dispatcher; :bestprice; the INV-6/G6 idempotency seam (replay-token reconciliation + the venue order_id outward position). Rationale: replace + the seam carry genuine design decisions (order-ref semantics; how a replay token is presented; where the branded id sits outward) that deserve their own rung over a guess. The @type is authored WIDE (names :bestprice + {:replace,…}) so it is stable across the 1.1→1.2 boundary; only the PARSERS grow.

### D-4 — the app and the pinned Exchange.Gateway surface Mars builds

Per DM-3/DM-4. App: echo/apps/exchange, lib-only (the echo_data shape — no supervision tree, no `mod:`, app: :exchange, deps: [{:echo_data, in_umbrella: true}]); module root Exchange.*; auto-discovered by echo/mix.exs apps_path. Types live INSIDE Exchange.Gateway (DM-4). The PINNED surface (Mars cites a spec line per call, trd.1.1.specs.md §"The surface Mars builds"):
- parse_place(raw::map) :: {:ok, command} | {:error, error}
- parse_cancel(raw::map) :: {:ok, command} | {:error, error}
- parse_money(term) :: {:ok, {units::integer, nano::integer}} | {:error, :bad_price}
- parse_direction(term) :: {:ok, :buy|:sell} | {:error, :bad_direction}
- parse_order_type(term) :: {:ok, :limit|:market} | {:error, :bad_order_type}   (:bestprice → bad_order_type in 1.1)
- parse_quantity(term) :: {:ok, pos_integer} | {:error, :nonpositive_quantity}
- parse_instrument(term) :: {:ok, binary} | {:error, :unknown_instrument}
- parse_account(term) :: {:ok, binary} | {:error, :malformed}   (no dedicated account atom; presence failure folds to :malformed)
Contract per public head: precond raw is a map (else :malformed, never crash); postcond exactly {:ok, command} | {:error, error}; invariant minting inside the {:ok,…} branch only. @types: direction :: :buy|:sell; order_type :: :limit|:market|:bestprice (1.1 parsers :limit|:market); money :: {integer,integer} Quotation never float; command :: {:place,m}|{:cancel,m}|{:replace,m} (replace wide, parser deferred); error :: the closed 6-atom set. Rung gate: echo/rungs/exchange/trd_1_1_check.exs, `mix run --no-start`, Code.require_file the canon (base62→native→snowflake→branded_id)+the Gateway, Snowflake.start(N), one line/gate, transcript echo/rungs/exchange/trd_1_1_check.out.

### D-5 — money string grammar chosen (spec-delegated, not a divergence)

trd.1.1.specs.md §124-128 delegates the exact string grammar to the implementor ("Mars chooses … at minimum a 'units.nano'-style decimal string"). Chosen grammar in Exchange.Gateway.parse_money/1:
- integer-pair {units, nano} (both integers) — accepted verbatim, no normalization;
- "units" → {units, 0}; "units.nano" → {units, nano_padded_to_9_billionths}, nano capped at 9 digits;
- the nano fraction inherits the UNITS sign so a sub-unit negative Quotation is representable ("-0.5" → {0, -500_000_000}), matching how a Quotation carries a sub-unit negative (sign on the non-zero field). money() @type is {integer, integer} (NOT non_neg), so signed nano is in-contract.
- Integer.parse/1 remainder must be "" (rejects a "12abc" prefix); a float ("1.45"), an extra-dot string ("1.4.5"), scientific notation ("1.5e3"), and any non-digit fraction → {:error, :bad_price}. No float survives the door (INV-2 / G3).
This is a spec-delegated choice, NOT a realization-over-literal deviation — the spec asked the implementor to pick it. No place where the spec said X and the canon required X′ was hit; the canon (Snowflake.next_branded/1, BrandedId.valid?/namespace/parse) matched the brief exactly.

## {trd-1-1-learnings} Learnings

### L-1 — out-of-scope stale docs/trading paths the rename leaves behind (flagged for the Director)

The Director scoped Venus's BCS edits to exactly three files (bcs.toc.md, bcs.roadmap.md, bcs.content-map.md). But the docs/trading→docs/exchange rename leaves stale `docs/trading` / `trading.*` references in TWO out-of-scope locations:
(1) docs/echo/bcs/specs/bcs.8.specs.md — references the trading corpus;
(2) the whole docs/echo/bcs/markdown/trading/ page tree (index.md + engine/*.md + log-and-ledger/*.md, ~8 files) — carries `docs/trading` / trading.* links.
Both carry prior UNCOMMITTED B8 work (per the Director's Stage-5 bundling watch). I did NOT touch them (scope). The b8 markdown tree path itself (markdown/trading/) was NOT renamed — only the design corpus docs/trading/ moved. The Director should decide whether to (a) leave the b8 page tree at markdown/trading/ with relinked corpus pointers, or (b) defer that to a follow-up. Recorded so the stale paths are a decision, not a silent drift. Also: trd.1.llms.md:11 and trd.2.llms.md:11-13 carry a pre-relocation `docs/bcs/` prefix (e.g. docs/bcs/exchange.specs.md) — I relinked the FILENAME (trading→exchange) as instructed but left the stale docs/bcs/ directory prefix as-is (out of the rename's stated scope, which was the filename rename only).

### L-2 — a substring grep for an AS-5 token false-FAILs on prose; assert structure, strip comments

The first rung-gate run went RED on AS-5 only — a gate-script defect, not a Gateway defect. Two crude-match causes:
(1) `not String.contains?(mix_src, "mod:")` matched the mix.exs COMMENT `# no \`mod:\`, no supervision tree` — the real application/0 has no :mod key, but the word "mod:" appears in prose.
(2) the lib :ets / use GenServer / Application.get_env substring scans were clean (grep confirmed none) — but the same class of false-positive (a moduledoc saying "no ETS") was one comment away.
FIX (the harden pattern): the grep is over CODE, not prose. (a) strip line comments (Regex.replace(~r/#.*/) per line) BEFORE the lib substring scan — honoring the spec's "grep over lib/" intent on source, not documentation; (b) check the dependency surface STRUCTURALLY via the loaded Mix project — `not Keyword.has_key?(Exchange.MixProject.application(), :mod)` and `Enum.sort(deps) == [...]` — immune to comments and the real truth of whether a boot module / extra dep is declared. Exchange.MixProject IS loadable under `mix run --no-start` (verified). After the fix: PASS 8/8.
WHY it matters: a gate that a comment can flip would also PASS a real `mod:` someone later comments out, or FAIL a clean app whose docs mention the word — exactly the inert/wrong-witness class Mars's charter warns against ("a check counts only if it RUNS — and checks the right thing"). The subject was always correct; the witness was textual where it should have been structural.

### L-3 — the Mars harden-pass resume re-ran the aaw ceremony, creating a second identity (Mars-2)

OBSERVED. The registry closed with FOUR agents: director, Venus, Mars (ccl-3, Stage-2 build), Mars-2 (ccl-4, Stage-4 harden). The skill's intent is ONE Mars identity, two passes ("Resume the Stage-2 Mars … one Mars identity … avoids a FAKE-N smell"). On the SendMessage-resume for Stage 4, the Mars context re-ran mcp__aaw__aaw_spawn + agent_register under the name "Mars-2".

NOT A VIOLATION. Mars-2 is backed by a real subagent context (the resumed Mars), so LAW-1 holds (the identity is backed by a real execution context, not role-play); the server raised no fake_n_signal. The build + harden work is real and Director-verified. It is a registry-tidiness blemish, not a fabricated identity.

MENTORING DIFF (for the x-mode Stage-4 resume brief / mars.md charter — apply only under an explicit Operator grant). The resume message should instruct: "This is a RESUME of your existing Mars identity — do NOT call aaw_spawn/agent_register again; continue as Mars and write your harden tool_x_report under the same identity." One line in the Stage-4 SendMessage template closes it. Recorded for the retrospective; no re-work needed for trd.1.1.

## {trd-1-1-report} Report

### Y-1 — Stage 1 (Venus) COMPLETE · verdict BUILD-GRADE · the brief Mars builds from

RECONCILE (T-2): BUILD-GRADE. Zero INVENTED/STALE/MISSING. next_branded/1 (snowflake.ex:104), generate!/1 (branded_id.ex:93, equivalent), next/0 (:62), start/1 (:40), BrandedId.{valid?/1:95, namespace/1:97, encode!/2:85}, the kind-gate EchoCache.Table.gate/2 (table.ex:495) — all MATCH. The {:echo_data, in_umbrella: true} edge is the INV-3 minting prerequisite, NOT the AS-5-forbidden external dep (binding reconcile note in trd.1.1.specs.md). echo/apps/exchange absent (Mars scaffolds). DEFERRED→1.2: parse_replace/1, parse/1 dispatcher, :bestprice, INV-6/G6 seam — [RECONCILE]-marked.

RENAME (D-1): docs/trading→docs/exchange via plain mv (NO git). 5 system docs renamed (trading.*→exchange.*), the trd.* quads moved unchanged (codename kept), 14 files relinked, platform-identity prose → "the Exchange Platform" in the system docs. docs/trading gone. The aaw ledger untouched (the tool_x_* appends here are the sanctioned writes). Verify CLEAN.

SPEC SLICE (D-3/D-4): docs/exchange/trd.1.1.md (narrative) + trd.1.1.specs.md (authoritative) authored. Pinned surface: parse_place/1 (limit+market) + parse_cancel/1 + the field parsers + parse_money/1, minting via next_branded/1; @types wide, 1.1 parsers the subset; gates G1–G5 + cancel + StreamData totality + AS-5 grep; rung gate echo/rungs/exchange/trd_1_1_check.exs (mix run --no-start, transcript .out).

BCS REFS: 3 files (bcs.toc.md, bcs.roadmap.md, bcs.content-map.md) — docs/trading→docs/exchange paths updated, one tight delineated "Exchange Platform now being built real" pointer added each, relative links to ../../exchange/ + trd.1.1.specs.md resolve.

SCOPE: edited only docs/exchange/** + the 3 bcs*.md. Zero echo/** changes. Nothing staged. Out-of-scope stale docs/trading paths in bcs.8.specs.md + markdown/trading/ flagged (L-1) for the Director.

NEXT: Stage 2 — Mars-1 scaffolds echo/apps/exchange + Exchange.Gateway against the pinned surface (D-4) and the trd.1.1.specs.md gate list.

### Y-2 — Stage-2 build complete, gate green, diff confined

Files NEW (all under echo/apps/exchange/):
- mix.exs — app: :exchange, lib-only (application/0 = extra_applications: [:logger], no mod:), deps exactly {:echo_data, in_umbrella: true} + {:stream_data, "~> 1.0", only: :test}.
- lib/exchange/gateway.ex — Exchange.Gateway: wide @types (order_type names :bestprice; command names {:replace,…}); parse_money/1, parse_direction/1, parse_order_type/1, parse_quantity/1, parse_instrument/1, parse_account/1; parse_place/1 (limit+market) + parse_cancel/1 with `with`+tagged tuples, minting in the {:ok,…} branch only. Closed 6-atom error set the sole failure channel; no raise/throw/bare :error; no float anywhere. Stateless.
- test/exchange/gateway_test.exs — G1–G5 + cancel + AS-3-no-mint + 3 StreamData totality properties.
- test/test_helper.exs.
Cited trd.1.1.specs.md line per public function:
- parse_place/1 :: §107 (also §103-122, §181 G1, §188 G4); minting §136-139 / INV-3 §58.
- parse_cancel/1 :: §108 (cancel gate §191-192).
- parse_money/1 :: §111 (pinned §124-128, INV-2 §57, G3 §186).
- parse_direction/1 :: §112 (G2 §182-184).
- parse_order_type/1 :: §113 (§130, :bestprice→:bad_order_type this slice).
- parse_quantity/1 :: §114.
- parse_instrument/1 :: §115 (INV-4 §62-65, G5 §190).
- parse_account/1 :: §116 (folds to :malformed §133-135).
Gate: `mix compile --warnings-as-errors` CLEAN (umbrella auto-discovered exchange, 0 warnings). `mix test` from apps/exchange = 3 properties, 16 tests, 0 failures, EXIT 0; re-run green across seeds 0/1/42/312540/999999. AS-5 grep: no use GenServer, no :ets, no Application.get_env; deps exactly the two. (Note: `mix test apps/exchange` from the umbrella ROOT swallows output — a sibling app's aggregate suite stalls — so the per-app run is `cd apps/exchange && mix test`, the echo §3 per-app discipline.)
Realization-over-literal: NONE. One spec-delegated choice (D-1: the money string grammar incl. signed-nano), which the spec explicitly asked the implementor to pick.
Did NOT write echo/rungs/exchange/trd_1_1_check.exs (Stage 4). Diff confined to echo/apps/exchange/; nothing staged; no git run.

### Y-3 — Stage 3 (Director solo review) · verdict: BUILD-FAITHFUL, no correctness defect · advance to Stage-4 harden

PROMPTED CHECKS (all PASS). (1) Fresh-gate reconcile — the as-built echo/apps/exchange/lib/exchange/gateway.ex matches docs/exchange/trd.1.1.specs.md: every pinned public head present (parse_place/1, parse_cancel/1, parse_money/1, parse_direction/1, parse_order_type/1, parse_quantity/1, parse_instrument/1, parse_account/1) with the {:ok,command}|{:error,error} contract; the wide-type/narrow-parser rule realized (order_type names :bestprice; parse_order_type rejects it :bad_order_type in 1.1); mint via Snowflake.next_branded ORD(place)/CMD(cancel) inside the with-success branch only. (2) Independent gate re-run (per-app, from apps/exchange — umbrella-wide is BANNED): mix compile --warnings-as-errors clean; mix test → 16 tests + 3 properties, 0 failures. (3) AS-5 grep empty (no use GenServer / :ets / Application.get_env / persistent_term in lib/); mix.exs deps = exactly {:echo_data, in_umbrella:true} + {:stream_data, only: :test} — no external dep, no mod:.

UN-PROMPTED SWEEP (clean). Swept: money edge-cases (float term vs decimal string — the subtle one: 1.45 the float → :bad_price, "145.25" the string → {145,250_000_000}); nano overflow (>9 digits → :bad_price); signed negative nano ("-2.5" → {-2,-500_000_000}, both integers); a replace-shaped map to parse_place (→ {:error,_}, NOT a crash — the unbuilt 1.1 replace parser degrades safely); cancel error isolation. No defect. One minor note (not a finding): the test setup_all Snowflake.start(7) is a no-op because echo_data's app already booted the generator — harmless (minting is node-id-independent for the distinctness gate).

ATTACK THAT HELD. 20 independent adversarial probes (NOT Mars's tests) over the closed-error-set isolation, float/string discrimination, nano bounds, negatives, 100-mint distinctness (all ORD/14/valid), the replace-shaped non-crash, and cancel — every refutation attempt FAILED to surface a defect. The parser is total and the float boundary holds.

MUTATION KILL-RATE 1/1. Injected parse_quantity q>0 → q>=0 (a 0-qty order would wrongly parse); the suite FAILED at gateway_test.exs:95 (G2). Reverted net-zero; suite green again. The suite is not decorative.

REMEDIATE / Stage-4 (harden — no correctness fix needed; the assigned hardening): (R1) write the rung-gate echo/rungs/exchange/trd_1_1_check.exs (the cache-rung template; Code.require_file the canon + the Gateway; Snowflake.start(N); one printed line per gate G1/G2/G3/G4/G5/cancel/totality/AS-5; Enum.all? → PASS k/k | FAIL+halt 1) + commit the transcript trd_1_1_check.out (exit 0) — the DoD artifact. (R2) the determinism loop (100× per-app mix test, the minting-suite discipline). (R3) mix format --check-formatted clean. LAW-1a held: the Director authored no production code — the probe was ephemeral (mix run -e) and the mutation reverted net-zero.

### Y-4 — Stage-4 harden COMPLETE · rung gate PASS 8/8 · determinism 100/100 · format clean

Director Stage-3 verdict (Y-3) = BUILD-FAITHFUL, no correctness defect → the Gateway production code (gateway.ex) was NOT changed. Stage-4 = the assigned hardening only.

R1 — RUNG GATE + COMMITTED TRANSCRIPT (the DoD artifact).
- NEW echo/rungs/exchange/trd_1_1_check.exs — copies the cache template's shape (rungs/cache/bcs_rung_4_1_check.exs): mix run --no-start; Code.require_file the canon raw in load order (base62→native→snowflake→branded_id, ../../apps/echo_data/lib/echo_data/<f>.ex) then the Gateway (../../apps/exchange/lib/exchange/gateway.ex); EchoData.Snowflake.start(11); the E.line/3 helper ("<tag> ok|FAIL -- <detail>", returns bool); one printed line per gate G1/G2/G3/G4/G5/cancel/totality/AS-5; final Enum.all? → PASS 8/8 | (FAIL; System.halt(1)). PURE — no Connector/Valkey/6390 (dropped from the template). Gate output carries no "!" and no forbidden-voice words (a chapter may quote it). The totality gate uses a self-contained SEEDED :rand generator (NOT StreamData — so --no-start-safe and reproducible): 2000 place + 2000 cancel inputs (well-formed/wrong-typed/missing-key via random key-drop), each {:ok,command}|{:error,closed-atom}, a try/rescue catches any crash, + every non-map input → :malformed.
- NEW echo/rungs/exchange/trd_1_1_check.out — committed transcript, ends "PASS 8/8", exit 0.

R2 — DETERMINISM LOOP: 100/100 clean (cd echo/apps/exchange; 100× TMPDIR=/tmp mix test). pass=100 fail=0; last iter "3 properties, 16 tests, 0 failures". No mint-collision flake (the minting-suite discipline, echo CLAUDE.md §3/§4).

R3 — FORMAT: mix format --check-formatted flagged TWO files the Stage-2 build never formatted — the test (check all → check all(...)) and the new gate (g2results/m5 line-wraps). Applied mix format; re-check CLEAN. The gate was re-run post-format and the transcript regenerated so the committed .out mirrors the formatted source.

COMPILE: TMPDIR=/tmp mix compile --warnings-as-errors CLEAN (from the app dir).

REALIZATION-OVER-LITERAL (flagged): the transcript is captured from STDOUT ONLY (2>/dev/null) with a provenance header, NOT the Director's literal `| tee` of the combined stream. Reason: Code.require_file re-loads beams already compiled into _build → six `redefining module` warnings on STDERR; `tee` would bake that noise into the DoD artifact. Stdout-only yields the clean gate record (8 lines + PASS 8/8); the header documents the produce-command and that the stderr warnings are elided. Behavior-identical result (PASS 8/8, exit 0), cleaner artifact. Also (L-2): the first gate run went RED on AS-5 — a gate-SCRIPT defect (a substring grep for "mod:" matched a mix.exs comment); fixed by stripping comments before the lib grep + checking the dependency surface structurally via Exchange.MixProject.application()/project(). The Gateway itself was always correct.

SCOPE: diff inside echo/apps/exchange/** + echo/rungs/exchange/** only; nothing staged; no git run. NEW this stage: rungs/exchange/{trd_1_1_check.exs, trd_1_1_check.out}; EDIT: apps/exchange/test/exchange/gateway_test.exs (format only — check all parens), apps/exchange/lib/exchange/gateway.ex (format no-op, unchanged bytes) — gateway.ex production logic UNTOUCHED. The Director's Stage-3 minor note (setup_all Snowflake.start(7) is a harmless no-op when echo_data already booted the generator) left as-is — the existing comment documents the idempotent prerequisite; the Director called it not-a-finding.

## {trd-1-1-complete} Complete

### Z-1 — trd.1.1 SHIPPED · the Exchange Gateway MVP · x-mode Flat-L2, Director-ratified

WHAT SHIPPED. A new lib-only umbrella app echo/apps/exchange holding the stateless Exchange.Gateway (the parse-don't-validate door): the closed command vocabulary {place(limit|market), cancel} + the closed six-atom error set, branded CMD/ORD ids minted at acceptance via EchoData.Snowflake.next_branded/1, Quotation {units,nano} integer money (never a float), totally parsed; + the rung gate echo/rungs/exchange/trd_1_1_check.exs (PASS 8/8) and its committed transcript. The /bcs B8 capstone now has a real Exchange.* door (Stage-1, operator-committed: the docs/trading→docs/exchange rename, the trd.1.1 spec slice, the BCS references). Deferred to trd.1.2: replace, bestprice, the INV-6/G6 idempotency seam.

PIPELINE (Flat-L2, risk NORMAL → no Apollo). Stage 1 Venus (BUILD-GRADE, Y-1: reconcile + rename + trd.1.1 slice + BCS refs; D-1..D-4). Stage 2 Mars-1 (Y-2: scaffold + Exchange.Gateway + tests, compile clean, 16 tests + 3 properties 0 failures). Stage 3 Director solo review (Y-3: BUILD-FAITHFUL — independent gate green; 20/20 adversarial probes held incl. float-term-vs-decimal-string, nano overflow, signed nano, 100 distinct mints, replace-shaped non-crash; mutation kill-rate 1/1; AS-5 clean; LAW-1a held — ephemeral probe, net-zero mutation). Stage 4 Mars-2 (Y-4: rung gate PASS 8/8, transcript committed, determinism 100/100, format clean; the gate drew blood on a gate-script AS-5 bug, fixed — the Gateway was always correct; gateway.ex production logic byte-unchanged). Stage 5 Director ship (this Z-1).

VERIFICATION (Director-confirmed, not report-trusted): per-app mix compile --warnings-as-errors clean; mix test 16+3 0-fail; rung gate re-run PASS 8/8 exit 0; determinism 20-iter spot clean (+ Mars's 100/100); AS-5 grep empty; deps = exactly {:echo_data, in_umbrella} + {:stream_data, test}.

LAW-4 COMMIT (Director-only, pathspec-isolated): echo/apps/exchange + echo/rungs/exchange + the aaw run-ledger (docs/exchange/trd-1-1.{progress.md,registry.json}). EXCLUDED operator/other-session out-of-band (docs/echo_mq, docs/mercury/live_svelte +2 code, docs/portal) — never git add -A. The Stage-1 docs (rename/slice/refs) were operator-committed out-of-band at HEAD 8f07930f.

STAGE-6 FOLD-FORWARD (follow-ups, not blockers): next gap trd.1.2 (replace/bestprice + the idempotency seam); L-1 — stale docs/trading paths in out-of-scope files (other docs / html/bcs/trading course pages) need a later course↔code sync; a trivial echo/apps/exchange/.formatter.exs would match the per-app convention (code is formatted via the root formatter). Decisions locked: D-1 rename, D-2 next_branded/1, D-3 MVP boundary, D-4 app+pinned surface.
