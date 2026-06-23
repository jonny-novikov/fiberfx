# emq3-6 — AAW scope ledger

## {emq3-6-thinking} Thinking

### T-1 — emq3.6 §0 derivation: time-travel (additive read window) + Table hydration (stream-tail fold) — the S3-memory closer

PIPELINE: Flat-L2, Director-supervised (/echo-mq-ship). Provisional Trio (see D-1). Engine: Valkey 6390 (PONG). Toolchain re-probe per-app at build.

5W
- Who: bus stream readers wanting a mint-time window (backtest/audit/debug) + store Table loaders wanting changelog-from-tail (config/positions/hydration). Downstream: emq3.6 CLOSES S3 (the memory) → the echomq:3.0.0 MAJOR cutover becomes declarable (the tier whole).
- What: (a) TIME-TRAVEL — an additive EchoMQ.Stream read window: DateTime [t0,t1] → XRANGE bounds via Snowflake.min_for/1, a window read == the id-filtered truth; (b) HYDRATION — fold a stream tail into an EchoStore.Table (newer-wins by mint order), then the staleness fence keeps it fresh (hydrate-then-fence == loader truth).
- Where: echo_mq (time-travel read) + echo_store (Table hydration) — the TWO-APP boundary (the emq3.5 D-1 precedent: echo_store depends on echo_mq, so the store reads the bus stream; the bus cannot call the store).
- When: now; after emq3.5 the archive SHIPPED (e2d73e23). Stands on the staleness fence (BCS 4.2) + Tables (4.1) — both BUILT.
- Why: the tier's last unanswered demand (emq.streams.md:73). Closing it makes the stream tier whole.

RECONCILE FLAG (Director grounding; Venus classifies AUTHORITATIVELY at the lag-1): MUCH substrate is ALREADY ON DISK.
- EchoMQ.Stream.read/3..6 (stream.ex:270) = the XRANGE read-back — SHIPPED (STRING from/to bounds "-"/"+"/explicit ms-seq).
- The min_for→"<ms>-0" bound conversion (stream.ex:64-68,230-240) — SHIPPED, but ONLY inside trim/4 (emq3.4 write-side MINID floor); it is NOT a read-window.
- => TIME-TRAVEL = MISSING as a read surface, but the bound-math precedent EXISTS — a small ADDITIVE read wrapper (read_window/read_since over read/6 + min_for). LOW risk; likely ZERO new Lua (XRANGE already shipped, bounds host-computed).
- EchoStore.Table (table.ex): put/4 versioned (:97), apply_newer_wins/3 (:513 the changelog semantic), :tracking staleness fence (:256), apply_coherence/4 (:115) — the hydration TARGET is FULLY BUILT.
- EchoStore.StreamArchive (emq3.5, just shipped) — the archive + merge-read present.
- => HYDRATION = wire the stream-tail read INTO Table.apply_newer_wins; the MECHANISM (one-shot fn vs supervised process) is the tier-setting fork.

SOLUTION SPACE (incl. do-nothing)
- Baseline (do-nothing): callers hand-compute XRANGE bounds + hand-fold a tail into a Table. REJECTED — re-litigates Appendix F (branded-id-IS-position) + the newer-wins law at every call site; these read-path conveniences are the tier's stated promise.
- A — one rung, two-app, ONE-SHOT hydration (likely; matches "no compactor"+"hydrate-then-fence"): read_window/3 (echo_mq) + Table.hydrate_from_stream/2 (one-shot fold→newer-wins→then the fence, echo_store). NORMAL.
- B — one rung, two-app, SUPERVISED hydrator process (a continuous tailer, the emq3.5 .Driver shape): HIGH (new process/lease). "no compactor" argues against a standing tailer.
- C — SPLIT (emq3.6a time-travel LOW / emq3.6b hydration NORMAL|HIGH): clean risk isolation, two ledgers/commits. The roadmap PAIRS them (one row) → default one rung; split is the fallback iff hydration proves heavy.

INVARIANTS as runnable checks (provisional — Venus authors the authoritative set)
- INV-TT: read_window [t0,t1] returns EXACTLY entries whose branded mint-instant ∈ [t0,t1] (≡ id-mint-filter over the full stream). Property: mint N across known instants, assert window==filtered every time.
- INV-BOUND: bounds via Snowflake.min_for/1 (the same floor trim/4 uses), never a hand-rolled instant; inclusive/exclusive edge tested at the exact ms.
- INV-HYDRATE: hydrate a tail of K entries / D keys → the Table holds per-key the NEWEST (max mint-id) value; then a newer admission (the fence) wins.
- INV-NOCOMPACTOR: hydration READS the tail + folds; NO background compaction; payloads claims-only.
- INV-BOUNDARY: diff ⊆ {echo_mq, echo_store}; engine internals (graft/*) untouched (INV8); no third app; mix.lock excluded.
- INV-ADDITIVE: any new bus scenario probe-registered + prior set byte-unchanged + count re-pinned BOTH tests; wire fence FROZEN echomq:2.4.2; label additive (echo_mq 2.6.4→2.6.5 IFF bus touched).
- the v2 master invariant binds UNCHANGED (braced keys; branded ids at the builder; declared Lua — likely none; server clock where a lease is touched — likely none).

SMALLEST CHANGE (Arm A): (1) ONE read fn on EchoMQ.Stream (DateTime→XRANGE bounds via min_for; zero new Lua) + (2) ONE hydration fn on EchoStore.Table (read the bus tail → fold newer-wins → the existing :tracking fence). + conformance scenario(s) + property tests. No new process, no new Lua, no wire change.

UNCERTAINTY + IMPACT: the hydration mechanism (one-shot vs process) is the live uncertainty; if a process → HIGH (Squad + ≥100 loop + on_exit braced-slot purge L-4) not NORMAL (Trio). Cost of wrong: under-staff a HIGH rung (skip mandatory Apollo) OR over-staff a NORMAL one (the ewr.4.1 tax). MITIGATION: provisional Trio, re-grade on Venus's mechanism reconcile/ruling. The Director's verify reads the two-phase-write error branches regardless (the emq3.5 R-1/L-6 class — IFF hydration advances a cursor after the Table write).

### T-2 — emq3.6 lag-1 reconcile (AUTHORITATIVE): every cited surface probed on disk. VERDICT = BUILD-GRADE.

CONFORMANCE COUNT (re-probed, authoritative): grep -c 'defp apply_scenario(' lib/echo_mq/conformance.ex = **78** (NOT the program-law digest's stale "18", NOT the in-code moduledoc comment's stale "77" at conformance.ex:214 — that comment LAGS by one). The 78th is :stream_archived (emq3.5 Arm 4). The two pins: conformance_run_test.exs:79 {:ok,78} + conformance_scenarios_test.exs @run_order (78 atoms). emq3.6 RE-PINS to 79 IFF a NEW bus-side scenario lands (Arm 5); else bus conformance FROZEN at 78.

TIME-TRAVEL substrate (echo_mq) — classify:
- EchoMQ.Stream.read/3..6 (stream.ex:270) = XRANGE read-back, STRING from/to bounds (default "-"/"+"), parses {branded, fields_map} in mint order via parse_entry/1 (:370). MATCH (SHIPPED, byte-frozen this rung if reused).
- EchoMQ.Stream.minid_floor/1 (stream.ex:239) = the LOWER-bound conversion DateTime→"<ms>-0" via Snowflake.unix_ms(min_for(dt)); but PUBLIC + lives in trim/4's MINID path (emq3.4 write-side). MATCH as a bound-math PRECEDENT; NOT a read-window.
- EchoData.Snowflake.min_for/1 (snowflake.ex:116) returns a RAW snowflake integer ((unix_ms-epoch)<<22), NOT an ms-seq string — F-1-class: a raw min_for int must NEVER go to the wire; convert via the minid_floor/1 / Stream.Id.xadd_id/1 path. MATCH (the math is real; the read wrapper is what's missing).
- Stream.Id.xadd_id/1 (id.ex:87) maps a branded EVT id → "<ms>-<tail22>"; kind/0 (:76)→"EVT"; evt?/1 (:102). MATCH.
- => TIME-TRAVEL READ-WINDOW = MISSING as a surface, the bound-math is PRESENT. A CLOSED-interval [t0,t1] read needs the UPPER bound conversion (t1→XRANGE inclusive `to`) which is NOT on disk (trim/4 uses only the lower MINID floor). The half-open [t0,∞) read_since needs only the existing minid_floor pattern. Both = a small additive read wrapper over read/6, ZERO new Lua (XRANGE shipped, bounds host-computed). LOW risk.

HYDRATION substrate (echo_store) — classify (T-1/D-1 assumed apply_newer_wins/3 PUBLIC; CORRECTED):
- EchoStore.Table.apply_newer_wins/3 is a PRIVATE defp (table.ex:513), reached only via handle_call({:coherence,...}) (:326). The PUBLIC newer-wins surface is: put/4 (:97, versioned write — SET L2 version<>value + ETS insert {id,value,exp,version}); apply_coherence/4 (:115, DROP-if-newer — it INVALIDATES the L1 row, "the writer already placed the newer value in L2", NOT a value-write); apply_batch/2 (:152, caller-side ordered fold of {id,version} drops). The semantic primitive: EchoStore.Coherence.newer?/2 (coherence.ex:52) = compare the 11-byte base62 payload (pa>pb), i.e. mint-id order over the branded version. MATCH but the public shape is put/apply_coherence/apply_batch, NOT a public apply_newer_wins. This SHARPENS Arm 4: there is NO public "write a fresh value iff newer" — hydration is either (a) put/4 each tail record (branded id AS version; the mint-ordered tail makes last-write-by-mint win) or (b) a NEW public fold fn. apply_coherence only DROPS (cache invalidation), so "fold via apply_coherence" is WRONG.
- :tracking fence (table.ex:256, arm_tracking/2 :564) = RESP3 server-assisted client-side caching (BCAST over the ecc:{table}: prefix); a write pushes an invalidation. MATCH (the staleness fence emq.streams.md:73 names).
- EchoStore.StreamArchive (emq3.5, stream_archive.ex) — merge_read/5 (:191) {:ok,[{branded,fields}]}, read_archive/2 (:161), archive_frontier/1 W reader (:144). MATCH — the merge-read is the deep-read SOURCE a hydrator could fold from (archive ∪ live-tail), or it folds from a plain Stream.read tail.
- => HYDRATION = wire a stream-tail read INTO a Table newer-wins write; the MECHANISM (one-shot Table.hydrate_from_stream fn vs a SUPERVISED continuous hydrator process, the emq3.5 .Driver shape) is the TIER-SETTING fork (Arm 3) — NORMAL vs HIGH.

TWO-APP DEP ARROW: echo_store/mix.exs:24-32 declares echo_data + echo_mq + echo_wire + exqlite (+cubdb). The arrow is echo_store→echo_mq (one-way); the bus has NO echo_store dep. So hydration (it reads the bus stream + writes a store Table) MUST live store-side; time-travel (a bus read) lives bus-side. CONFIRMS the emq3.5 D-1 two-app boundary {echo_mq, echo_store}. echo_store app version 2.0.0; echo_mq label 2.6.4 (frozen @wire_version echomq:2.4.2).

R-1/L-6 HAZARD (flagged): IFF the hydrator advances a cursor AFTER the Table write, the two-phase-write atomicity (the emq3.5 R-1 class: :arc_seq advanced only on a clean commit, one CubDB txn) re-fires — name it as an INV (cursor-after-write, idempotent-on-replay; newer-wins makes a re-applied tail harmless, mirroring journal.ex:14's "re-applied version harmless"). A one-shot hydrate sidesteps it (no standing cursor); a supervised hydrator must carry it.

### T-3 — emq3.6 triad AUTHORED (Stage 1 DONE) + the FIVE Arms carved for the Director. BUILD-GRADE.

TRIAD WRITTEN (4 files, docs/echo_mq/specs/emq3/): emq3.6.md (the body — §0 slice/two-app boundary · §1 time-travel INV-TT/INV-BOUND · §2 hydration INV-HYDRATE/INV-NOCOMPACTOR · §3 fence INV-FENCE/INV-CURSOR · §4 two-app posture INV-BOUNDARY/INV-ADDITIVE · §5 v2 master invariant · INV summary · closed error set · the Arms · DoD); emq3.6.stories.md (US1–US6 + EMQ3.6-US-GATE + Coverage map, the no-vacuous-pass liveness law per story); emq3.6.llms.md (Mars brief — References both apps · Requirements 1–8 · build-order DAG · AS-1..AS-6 + AS-GATE); emq3.6.prompt.md (the runbook — PROVISIONAL formation re-grading on the Arm-3 ruling, two gate ladders, the boundary, DoD).

msh specs echo_mq --severity error: ZERO emq3.6.* findings (my triad resolves clean at the real tree depth — from specs/emq3/ the canon is 2-up ../../emq.streams.md, matching the emq3.5 sibling; the progress ledger is ../progress/). The 100+ errors in the run are ALL PRE-EXISTING (emq.references.md's moved ../echo/bcs/content/ tree; emq4.phase2.design.md not-yet-authored; the [text](word)/[text](x) markdown-adjacency false positives in sibling progress ledgers — the bracket-then-paren hazard). Scoped all-clear: the four emq3.6 files ONLY.

THE FIVE ARMS (each Rationale · 5W · Steelman · Steward + Venus's ranked recommendation):

ARM 1 · SCOPE — one rung vs split.
- Rationale: time-travel (bus-side, LOW) + hydration (store-side, NORMAL|HIGH) differ in app AND risk tier; the roadmap PAIRS them (emq.streams.md:73, one row).
- 5W: WHO bus readers (backtest) + store loaders (config/positions); WHAT both S3-closer needs; WHERE echo_mq + echo_store; WHEN now; WHY closes the tier whole → the 3.0.0 cutover declarable.
- Steelman (split): clean risk isolation — emq3.6a time-travel ships single-app LOW with zero two-app machinery; emq3.6b hydration carries the tier-setting mechanism alone.
- Steward (multi-year): one rung = one ledger/commit/conformance bump; the two-app machinery is already paid (emq3.5). Split doubles the bookkeeping for two small surfaces.
- RANK: ONE RUNG. Split is the fallback IFF Arm 3 makes hydration heavy.

ARM 2 · THE TIME-TRAVEL READ SURFACE — closed [t0,t1] vs half-open [t0,∞).
- Rationale: the from reuses the SHIPPED minid_floor/1; the to is NEW math (trim/4 uses only the lower MINID floor — the upper bound does not exist on disk).
- 5W: WHAT a DateTime-window read on EchoMQ.Stream → XRANGE bounds → read/6; WHERE bus-side; WHY mint instants map to XRANGE bounds (emq.streams.md §needs).
- Steelman (half-open read_since/4): one bound, ZERO new math (only the shipped floor); the open-ended [t0,∞) is the common audit case.
- Steward: a closed read_window/5 is the general form; read_since is its nil-upper degenerate — ship read_window with read_since as a second arity, no future surface debt.
- RANK: CLOSED [t0,t1] read_window/5 (the DoD says "a mint-time WINDOW read" — two-sided), inclusive to-edge; read_since/4 as the nil-open arity. Additive, ZERO new Lua.

ARM 3 · THE HYDRATION MECHANISM (TIER-SETTING) — one-shot fn vs supervised process.
- Rationale: a one-shot Table.hydrate_from_stream/_ (a bounded tail fold, NORMAL) vs a SUPERVISED continuous hydrator (the emq3.5 .Driver shape, a standing tailer + a cursor, HIGH). THIS Arm sets the risk tier + whether INV-CURSOR binds + Apollo mandatory + the ≥100 loop.
- 5W: WHAT fold a stream tail into an EchoStore.Table by newer-wins; WHERE store-side; WHY "changelog semantics without a compactor" (emq.streams.md §needs).
- Steelman (supervised): a standing hydrator keeps a hot table continuously fresh from the stream without a caller; the .Driver shape is proven (emq3.5).
- Steward: "no compactor" + "hydrate-then-fence" argue the FENCE (not a tailer) keeps the table fresh — the hydrate is a WARM-START, the steady-state is the :tracking fence's. A standing tailer DUPLICATES the fence's job + adds a cursor + the two-phase-write hazard (the emq3.5 R-1/L-6 class). The supervised shape is a clean FUTURE additive optimization once the one-shot is proven.
- RANK: ONE-SHOT hydrate_from_stream/_ → NORMAL Trio. The supervised hydrator is the future opt. PRE-EMPTED OBJECTION: "a one-shot doesn't keep the table fresh" — correct, and intended: the :tracking fence does that (INV-FENCE); hydrate seeds, the fence maintains. RE-GRADE: if the Operator wants continuous hydration NOW → supervised → HIGH Squad + Apollo MANDATORY + ≥100 loop + INV-CURSOR.

ARM 4 · THE HYDRATION SOURCE — live tail vs merge-read deep.
- Rationale: the live tail (EchoMQ.Stream.read/6 — changelog-from-tail) vs the merge-read deep source (StreamArchive.merge_read/5 — archived ∪ live-tail, so a hydrate seeds from the FULL history incl. the archive).
- 5W: WHAT the source the hydrator folds; WHERE store-side; WHY a hydrate may want only-the-tail (recent config) or all-of-history (full positions).
- Steelman (merge-read deep): a hydrate that includes archived history gives a complete latest-value-per-key even for keys whose newest record was trimmed-then-archived.
- Steward: the live-tail is the simplest founding (needs no Volume/engine in the suite); the merge-read deep source is a clean FUTURE arity (hydrate_from_history over merge_read/5) once the tail-fold is proven. Pulling the engine into the hydration suite now adds setup cost for a need the founding may not have.
- RANK: LIVE TAIL for the founding; merge-read deep as a future arity. BUT if the Operator wants archived-history hydration NOW, the merge-read source is the call (it needs the engine started in setup — a setup-cost, not a risk-tier change).

ARM 5 · THE TWO-APP POSTURE + CONFORMANCE — bus scenario lands vs frozen.
- Rationale: confirm the bus-read + store-hydration split (emq3.5 precedent); a NEW store-side hydration suite (FORCED — echo_store has no conformance); whether a bus-side time-travel conformance scenario lands (78→79) or the bus conformance stays FROZEN at 78.
- 5W: WHAT the test/conformance posture; WHERE both apps; WHY a certified time-travel read vs a plain ExUnit-gated one.
- Steelman (frozen at 78): the time-travel read is gated by the bus's ExUnit stream suite; no conformance churn; the prior 78 untouched.
- Steward: the emq3.5 Arm-4 precedent LANDED a bus-pure scenario (the :archived cache, 77→78) — a time-travel scenario makes the read a first-class CERTIFIED surface a polyglot reader can rely on; the additive-minor cost is one scenario + both pins. The store-side hydration suite is forced regardless.
- RANK: LAND the bus-side time-travel scenario (78→79, both pins re-pinned, prior 78 byte-unchanged) — the read becomes certified; the store-side hydration suite is forced.

R-1/L-6 HAZARD FLAGGED (INV-CURSOR, conditional): IFF Arm 3 rules supervised + the hydrator advances a cursor AFTER the Table write, the two-phase-write atomicity re-fires (the emq3.5 R-1 class — write-before-cursor-advance, idempotent-on-replay via newer-wins, mirroring journal.ex:14). A one-shot SIDESTEPS it (no cursor). Named as INV-CURSOR (VACUOUS + dropped if one-shot); the Director's verify reads the cursor-advance branch IFF supervised.

VERDICT: BUILD-GRADE. Every cited surface MATCH or forward-tense; the two-app boundary explicit; the time-travel id-filter property + the hydration newer-wins property + the hydrate-then-fence composition are the spine; the determinism posture is Arm-3-keyed (≥100 loop iff supervised, else a sweep). The Director rules the 5 Arms with the Operator → the Arm-3 ruling re-grades the formation → Mars builds.

### T-4 — Director Stage-3 deepened verify: BUILD-GRADE, ZERO defects → Mars-2 collapses (the emq.5.1 precedent)

INDEPENDENT GATE RE-RUN (Valkey 6390): BUS echo_mq 18 doctests + 541 tests / 0 failures (--include valkey; Conformance.run = {:ok,79}); STORE echo_store 99 tests / 0 failures (the new hydration suite 10/10). Toolchain 1.18.4 / 28.5.0.1.

ADDITIVE-MINOR INTEGRITY (proven byte-for-byte): prior 78 verdict-bodies byte-unchanged (:stream_archived got ONLY a trailing comma to append the new entry — diff-modulo-comma IDENTICAL; 0 prior apply_scenario clauses changed; apply_scenario count HEAD 78 → now 79 = exactly +1); both pins re-pinned ({:ok,79} + @run_order +:stream_time_travel); the new scenario probe-registered + NON-VACUOUS (a STRADDLING window + exact-ms edges).

THE FOLD (reconcile correction honored): EchoStore.StreamHydrator.hydrate_from_stream/5 folds via Table.put/4 (the PUBLIC versioned write) versioned by the record's branded EVT id — NOT apply_coherence (drops only). Source READ-ONLY (no XADD/XTRIM — INV-NOCOMPACTOR). ONE-SHOT (no GenServer/Process/cursor → INV-CURSOR vacuous/dropped, the R-1 two-phase-write hazard sidestepped). Fail-closed (:halt on first write error; field! raises on a missing key/value field).

BYTE-FREEZE / BOUNDARY (INV-BOUNDARY/INV8): stream.ex additive-only (78 ins, 0 del — append/4·trim/4·read/6 byte-identical); echo_wire EMPTY-diff; 0 new redis.call on the bus diff; @wire_version frozen echomq:2.4.2; engine internals + Rust echo_graft + mix.lock + keyspace.ex EMPTY; diff purely {echo_mq, echo_store}; labels echo_mq 2.6.5 / echo_store 2.0.1.

THE [error] LOG (investigated, NOT a regression): the bus suite's "StreamConsumer XGROUP CREATE refused WRONGTYPE" is an EXPECTED negative test (stream_consumer_test.exs:370 "a start against a key holding a NON-stream type fails LOUD"); stream_consumer.ex/test UNTOUCHED by emq3.6; Mars's L-2 proved it pre-existing by stashing the whole diff + re-running at HEAD (identical log, 0 failures).

DETERMINISM POSTURE (honest, correct for one-shot NORMAL): multi-seed sweep (bus 5/5, store 5/5) + cross-VM purge 12/12 — the ≥100 loop correctly NOT forged (no process; assertions are window≡id-filter + newest-per-key, robust to same-ms by the deterministic min_for-mint, L-1 KEYSTONE).

DIRECTOR INDEPENDENT MUTATION SPOT-CHECK (LAW-1a, complementary to Mars's upper-bound + fold mutations): read_window lower bound minid_floor(t0) → "-" (unbounded) → CAUGHT: 2 failures (INV-TT straddle: 3 below-t0 records leaked; INV-BOUND lower edge: t0-1ms leaked). Reverted via inverse Edit (NOT git checkout); whole-file re-diff = 78 ins / 0 del, 0 mutant residue — NET-ZERO confirmed.

VERDICT: BUILD-GRADE. Zero defects. Mars-2 COLLAPSES (the emq.5.1 precedent — no remediation). Apollo OPTIONAL (NORMAL — the supervised-hydrator trigger did not fire; Apollo is NOT a ship precondition). READY TO SHIP pending the Operator's go-ahead on the LAW-4 pathspec commit (the Operator pre-stages out-of-band → re-verify git diff --cached is purely the rung before committing).

## {emq3-6-decisions} Decisions

### D-1 — Formation: provisional Trio (Director + Venus + Mars), re-gradable to Squad on the hydration-mechanism ruling

FORMATION (L2 Topology Router, risk × design-width): PROVISIONAL TRIO — Director + Venus + Mars. Apollo is an OPTIONAL fast-finisher on a NORMAL outcome; MANDATORY (→ Squad) IFF the hydration-mechanism ruling lands HIGH (a NEW supervised hydrator process / a durable at-rest two-phase write).

RATIONALE: emq3.6 RIDES shipped ground — read/6 (XRANGE) + the min_for bound math + EchoStore.Table.apply_newer_wins/3 + the :tracking fence + the emq3.5 archive are ALL on disk. This is additive wiring, not new ground. Contrast emq3.5 (a HIGH Squad) which INTRODUCED the at-rest engine write + a new fold process. Time-travel = LOW (an additive read wrapper over read/6 + min_for). Hydration = NORMAL most-likely (a one-shot fold; "no compactor" + "hydrate-then-fence" argue against a standing tailer).

RE-GRADE TRIGGER: Venus's mechanism reconcile/ruling. If hydration = a supervised process → HIGH → add Apollo (MANDATORY) + the ≥100 determinism loop (the suite mints EVT ids in setup → the same-ms hazard is live) + the on_exit braced-slot purge (L-4, the shared Valkey 6390 leak).

BOUNDARY: TWO-APP {echo_mq, echo_store} (the emq3.5 D-1 precedent: echo_store depends on echo_mq, so the store reads the bus stream). INV8 engine internals (graft/*) untouched — hydrate via the PUBLIC EchoStore.Table API. No third app; mix.lock excluded.

VERIFY FLOOR (regardless of tier): the Director's deepened verify reads the two-phase-write error branches (the emq3.5 R-1/L-6 class) IFF hydration advances a cursor after the Table write; the time-travel window property (read_window ≡ id-filter); the additive-minor conformance + the byte-freeze.

NOTE for Venus: the program-law conformance digest says "18" (STALE, frozen at emq.1); the LIVE count is ~78 post-emq3.5 — RE-PROBE at the reconcile. Wire fence FROZEN echomq:2.4.2; the rung label climbs additively (echo_mq 2.6.4 → 2.6.5) only if the bus side is touched.

### D-2 — The five Arms RULED (Director + Operator, AskUserQuestion); formation STAYS Trio (NORMAL)

- Arm 1 · SCOPE → ONE RUNG (time-travel bus-side + hydration store-side together; the roadmap pairing). Split was the fallback; not taken.
- Arm 2 · READ API → read_window/5 (CLOSED [t0,t1], INCLUSIVE to-edge — the NEW upper-bound math, the inverse of the shipped minid_floor/1) + read_since/4 (open [t0,∞), reuses the shipped floor). Additive EchoMQ.Stream surfaces; ZERO new Lua (XRANGE host-issued via read/6).
- Arm 3 · HYDRATION MECHANISM → ONE-SHOT EchoStore.Table.hydrate_from_stream/_ (a bounded tail fold; the :tracking fence maintains freshness — the hydrate is a warm-start). NORMAL. ⇒ FORMATION STAYS TRIO; the re-grade trigger (supervised) did NOT fire. Apollo = OPTIONAL fast-finisher (NOT a ship precondition). INV-CURSOR VACUOUS + dropped (no standing cursor).
- Arm 4 · SOURCE → LIVE TAIL (EchoMQ.Stream.read/6 — changelog-from-tail); merge-read deep = a future arity. No engine/Volume in the hydration suite.
- Arm 5 · CONFORMANCE → LAND the bus-side time-travel scenario (78→79; both pins re-pinned at conformance_run_test.exs:79 + conformance_scenarios_test.exs @run_order; prior 78 byte-unchanged). The store-side hydration suite is forced regardless. (Director-ruled in prose, Operator-confirmed — no objection.)

FORMATION: NORMAL Trio (Director + Venus + Mars). aaw_status(emq3-6) must show exactly these three. Apollo optional.

THE RECONCILE CORRECTION Mars MUST honor (T-2): hydration folds each tail record via EchoStore.Table.put/4 (the PUBLIC versioned write) with the branded EVT id AS the version — NOT via apply_coherence/4 (which only DROPS/invalidates an L1 row, never writes a value; apply_newer_wins/3 is a PRIVATE defp). Mint-ordered tail ⇒ last-write-per-key wins.

DETERMINISM POSTURE: the suites mint/derive EVT ids in setup. Design INV-TT/INV-HYDRATE as window-read ≡ id-filtered-full-read (robust to same-ms boundaries by construction). State the posture honestly — a multi-seed sweep + statement if the assertions are mint-instant-relative; the ≥100 loop + on_exit braced-slot purge (L-4, shared Valkey 6390) if live next_branded minting with count-sensitive setup. The Director's verify confirms it is not under-tested.

VERIFY FLOOR: read_window ≡ id-filter (a STRADDLING window that actually excludes); the bound edges (exact-ms lower, inclusive upper); hydrate → per-key-newest → fence (≥2 records/key); INV-NOCOMPACTOR (source READ-ONLY, no compaction loop, no XADD/XTRIM of the source); the two-app boundary {echo_mq, echo_store}; the byte-freeze (append/4·trim/4·put_archived/get_archived/clear_archived frozen; @wire_version echomq:2.4.2; grep -c redis.call on the bus lib diff = 0; engine internals + echo_graft + echo_wire + mix.lock EMPTY-diff).

LABEL: echo_mq 2.6.4 → 2.6.5 (the bus is touched by the read surface); echo_store 2.0.0 → 2.0.1 (a new public hydration surface).

## {emq3-6-learnings} Learnings

### L-1

L-1 (Mars, lag-1 reconcile confirmed) — Every cited surface re-probed on disk, all MATCH the T-2 reconcile:
- BUS: Stream.read/6 (stream.ex:270 XRANGE string bounds "-"/"+"); minid_floor/1 (:239 → "<ms>-0"); Stream.Id.xadd_id/1 (id.ex:87 → "<ms>-<tail22>", tail22=snow&&&0x3FFFFF, MAX seq=0x3FFFFF=4194303); Snowflake.unix_ms/1 (:107), min_for/1 (:116 RAW int), to_datetime/1 (:109). append/4·trim/4·put_archived/get_archived/clear_archived present (byte-freeze targets). Conformance=78 confirmed (run pin conformance_run_test.exs {:ok,78}; scenarios pin @run_order ends :stream_archived L137).
- STORE: Table.put/4 (table.ex:97, sig put(name,id,value,<<_::binary-14>>=version) — version is ANY 14-byte branded id, NOT kind-gated; only the ENTITY id is gated to the table kind via gate/2 :547); Table.fetch/3 (:63 → {:ok,value,:hit|:l2|:fill}); Coherence.newer?/2 (coherence.ex:52, pa>pb over 11-byte payload); :tracking lane (table.ex:255, arm_tracking/2 :564). table_test.exs:230 IS the fence-composition precedent (seed L1 directly, external SET evicts via tracking push).
KEYSTONE determinism key (conformance.ex stream_retention_append_at): a record at a CONTROLLED instant dt is minted via BrandedId.encode!("EVT", Snowflake.min_for(dt)) — snowflake = min_for(dt) (seq 0), so mint instant == dt EXACTLY, no next_branded live-clock hazard. The bus-side time-travel scenario + tests reuse this → window-read ≡ id-filter is exact by construction (D-2 sweep posture, not the ≥100 loop, for the bus side). Upper-bound inverse: to = "<ms(t1)>-4194303" (max 22-bit seq) — admits all seq at ms(t1), excludes ms(t1)+1. INCLUSIVE per Arm 2.

### L-2

L-2 (Mars, gate hazard caught) — TWO shared-Valkey-6390 hazards surfaced during the bus gate, BOTH benign-to-the-rung but instructive:
(1) The FULL bus suite (`mix test --include valkey`, 541 tests) intermittently shows `1 failure` = a `StreamConsumer: XGROUP CREATE refused WRONGTYPE` contention race between async:true stream suites and the async:false ConformanceRunTest sharing the box — PROVEN pre-existing by stashing my whole diff and re-running at HEAD (the identical RuntimeError prints, 0 failures at HEAD too; the error is a TOLERATED supervised-consumer crash-recovery LOG, not an assertion). A clean re-run = 541/0. The per-SUITE gate (the master-invariant per-app law) is the truth: conformance_run + all stream suites co-run = 44/0, CONFORMANCE 79/79. NOT introduced by the additive time-travel read (it issues only XRANGE/XADD on its own sub-queue, never XGROUP).
(2) `git stash push -u … / pop` (used to prove (1) at HEAD) PARTIALLY reverted ONE line of conformance_run_test.exs — the `{:ok, 78}`→`{:ok, 79}` assertion reset to HEAD while the moduledoc/test-name edits survived (the linter-touched-file note fired mid-turn). Caught by the co-run gate (`left: {:ok, 79}, right: {:ok, 78}`) + the byte-freeze-to-CLOSURE law (re-grep the WHOLE file, never the lines you touched). Re-applied. LESSON: after a stash/pop cycle, RE-VERIFY every edited line is intact (grep each pin), not just compile-green — a partial revert compiles fine and only the assertion bites.
FLUSHDB on 6390 is correctly BLOCKED by the harness (destroys sibling workloads) — targeted braced-slot purge only, which is what both new suites do on_exit (emq:{q}:* + ecc:{table}:*, 12/12 cross-VM clean).

## {emq3-6-report} Report

### Y-1

Y-1 (Mars) — emq3.6 TIME-TRAVEL + HYDRATION built to the D-2 RULED Arms. TWO-APP, additive, BOTH ladders green on Valkey 6390.

FILES (7 mod + 2 new):
BUS (echo_mq): stream.ex (+78 additive: @max_seq 0x3FFFFF, maxid_ceil/1 the inclusive upper inverse, read_window/5 CLOSED [t0,t1], read_since/4 open [t0,inf); append/trim/archive surface 0-del byte-frozen) · conformance.ex (+1 scenario :stream_time_travel + 4 helpers; prior 78 byte-unchanged, only :stream_archived got a trailing comma + doc-count fixes) · stream_test.exs (+156: INV-TT straddle, INV-BOUND edges, guards) · conformance_run_test.exs + conformance_scenarios_test.exs (both pins re-pinned 78->79) · mix.exs 2.6.4->2.6.5.
STORE (echo_store): NEW stream_hydrator.ex (one-shot hydrate_from_stream/5; reads LIVE tail via Stream.read/6, folds per key via Table.put/4 versioned by the record's EVT id, newer-wins; fail-closed on write err, raise on missing key/value field; NO compactor, source read-only) · NEW stream_hydrator_test.exs (10 tests: INV-HYDRATE/NOCOMPACTOR/FENCE) · mix.exs 2.0.0->2.0.1.

GATES: BUS — compile --warnings-as-errors clean; full suite 541 tests + 18 doctests 0 failures (--include valkey); Conformance.run/2 = {:ok, 79} (CONF stream_time_travel ok; prior 78 byte-unchanged, both pins). STORE — compile clean; full suite 99 tests 0 failures; new hydration suite 10/10.

DETERMINISM (one-shot/NORMAL, D-2): multi-seed sweep — bus 5/5 seeds, store 5/5 seeds; store cross-VM purge 12/12 separate-VM runs clean (on_exit purges emq:{q}:* + ecc:{table}:*). NOT the >=100 loop (Arm 3 one-shot, no process, no cursor; assertions are newest-value-per-key + window==id-filter, robust to same-ms by the deterministic min_for-mint).

BYTE-FREEZE / INV-BOUNDARY: grep -c redis.call on bus lib diff = 0; echo_wire EMPTY-diff; @wire_version echomq:2.4.2 FROZEN; keyspace.ex (both) EMPTY; mix.lock EMPTY; graft engine internals + Rust echo_graft EMPTY; stream.ex 0-del; no third app. Diff purely {echo_mq, echo_store}.

ADVERSARIAL (Mars=primary code-quality gate): mutation kill-rate 100% — (1) maxid_ceil -> "+" unbounded: stream_test 4 fails + CONF stream_time_travel FAIL {:time_travel_window,false}; (2) hydrator fold reversed (oldest-wins): 4 INV-HYDRATE fails. Both restored net-zero via inverse Edit (NOT git checkout); whole-file re-diff confirms 0 residue.

ARM rulings honored: Arm1 one rung · Arm2 read_window/5 + read_since/4 (inclusive to-edge) · Arm3 one-shot (AS-5/INV-CURSOR DROPPED, no process/cursor) · Arm4 live tail (NO engine in suite) · Arm5 conformance 78->79. T-2 correction honored: fold via Table.put/4 versioned by the EVT id (NOT apply_coherence). NO deviation from the brief.

## {emq3-6-complete} Complete

### Z-1 — emq3.6 SHIPPED: time-travel (read_window/5 + read_since/4) + Table hydration (EchoStore.StreamHydrator, one-shot fold). The Stream Tier is WHOLE.

PIPELINE COMPLETE (Flat-L2 NORMAL Trio, Director-supervised): Venus (reconcile + triad + 5 Arms, BUILD-GRADE; T-2/T-3) → Director ruled the Arms with the Operator (D-2, all 5 to Venus's recs) → Mars-1 (built both apps; L-1/L-2, Y-1) → Director deepened verify (T-4, BUILD-GRADE, ZERO defects; the independent lower-bound mutation caught + net-zero) → Mars-2 COLLAPSED (zero defects, the emq.5.1 precedent) → Director ship.

DELIVERED:
- BUS (echo_mq, label echomq:2.6.5): EchoMQ.Stream.read_window/5 (CLOSED [t0,t1], inclusive to via maxid_ceil/1 "<ms>-0x3FFFFF") + read_since/4 (open [t0,∞)) — additive over the byte-frozen read/6, ZERO new Lua. + the conformance scenario :stream_time_travel (78→79).
- STORE (echo_store, label 2.0.1): EchoStore.StreamHydrator.hydrate_from_stream/5 — a ONE-SHOT fold of a live stream tail into an EchoStore.Table via put/4 (versioned by the branded EVT id, newer-wins by mint order); no compactor, source read-only; the :tracking fence maintains freshness. + the store-side hydration suite.

GATES (independently re-run on Valkey 6390): BUS 18 doctests + 541 tests / 0 failures (Conformance.run = {:ok,79}); STORE 99 tests / 0 failures. Additive-minor PROVEN (prior 78 byte-unchanged, +1, both pins re-pinned). Byte-freeze: stream.ex additive-only (0 del), echo_wire empty, 0 new redis.call, @wire_version echomq:2.4.2 frozen, engine/echo_graft/mix.lock empty. Determinism: honest multi-seed sweep (one-shot NORMAL). Boundary {echo_mq, echo_store}.

STAGE-6 FOLD: emq.roadmap.md + emq.progress.md + emq.streams.md → emq3.6 SHIPPED, S3 the memory COMPLETE, the Stream Tier WHOLE (emq3.1–3.6) → the echomq:3.0.0 MAJOR cutover ratification is the next frontier (OR the parked 2.x runway emq.6/7/8, Operator-revisable).

D-2 (the Arm rulings) is the locked contract. Apollo OPTIONAL (NORMAL) — available as a post-ship calibration pass under an Operator grant. ONE LAW-4 pathspec commit (the 18 rung+fold files; the Operator's out-of-band redis-patterns/msh/bcs work EXCLUDED).
