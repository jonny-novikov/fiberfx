# emq3-4 — AAW scope ledger

## {emq3-4-thinking} Thinking

### T-1 — emq3.4 derivation: retention as policy (EchoMQ.Stream.trim/_ + a declared per-stream window)

**5W.** WHAT — a dedicated public `EchoMQ.Stream.trim/_` verb over `XTRIM` (`MAXLEN ~` approx default, exact opt-in; mint-instant `MINID` via the REAL `EchoData.Snowflake.min_for/1`, snowflake.ex:116) + a DECLARED per-stream retention policy (declared, not a per-call default). WHY — the stream tier's "bounded retention as policy" need: the compliance window + memory truth (emq.streams.md §The needs). WHERE — additive on the emq3.2 writer `EchoMQ.Stream`, which PRE-DECLARES the slot at stream.ex:50 ("Retention (MAXLEN/MINID) is emq3.4; append/_ does not trim"); boundary echo/apps/echo_mq; rides the Connector generic command path — NO new Lua (the emq3.3 pattern). WHEN — emq3.4, stands on emq3.2 (the writer law); gated on emq.0 (met).

**Solution space (incl. do-nothing).** (0) do-nothing — streams grow unbounded, no compliance window, memory truth violated -> REJECTED (the stated need). (1) trim-on-append as default — REJECTED by BOTH architect lenses (mutates the FROZEN emq3.2 append/4). (2) a dedicated public trim/_ verb + a declared policy — the CONVERGED choice (synthesis §2). Open axes: the CADENCE that drives the trim (F3.4-A, the one diverged fork) + the policy STORAGE (F3.4-B sub-call).

**Invariants (as runnable checks).** INV1 trim honors the window — post-trim, entries below the window are gone, at/above remain. INV2 a read inside the window never misses — XRANGE over the retained span == the truth. INV3 outside the window the read answers truthfully — a trimmed range returns what survives, never a lie. INV4 the DESTRUCTIVE blast-radius is bounded by the DECLARED policy — a trim can never delete INSIDE the declared window (the blast-radius mutation battery proves over-deletion is caught). INV5 additive law — append/4 + every frozen @-script byte-unchanged (grep redis.call on the lib diff == 0). INV6 the MINID floor == Snowflake.min_for(dt) exactly (the mint-instant mapping).

**Smallest change preserving correctness.** Additive trim/_ + a declared-policy carrier; no new Lua; append/4 + the @-scripts byte-frozen; conformance +1 scenario (stream_retention, additive-minor — prior byte-unchanged, re-pin both pinning tests, 76 -> 77); within-family label climb (echomq:2.6.2 -> 2.6.3); @wire_version FROZEN echomq:2.4.2.

**Topology triage (the L2 router).** HIGH-risk — XTRIM is a DESTRUCTIVE at-rest op (the emq.4.1 drain class: permanent entry removal). BUT the design-space is NARROW + PRE-EXPLORED — the emq3.3 Squad's dual-architect debate already designed emq3.4-3.6 and banked it (kb/streams-tier/; 9 of 10 forks converged). => TRIO (Venus author/reconcile · Mars build+blue-harden · Apollo MANDATORY for the destructive op · Director verify/ship). NOT a Squad: the second architect's work is banked; adding one is the ewr.4.1 over-ceremony footgun. HIGH-risk is absorbed by Apollo-mandatory + the Director's BLAST-RADIUS mutation battery — NOT the >=100 determinism loop (emq3.4 mints no ids, opens no lease => the loop would forge load the rung doesn't introduce; a multi-seed sweep + an honest determinism-posture statement instead).

**Open forks to rule BEFORE the build (AskUserQuestion now).** F3.4-A the trim cadence (Lens A consumer-beat vs Lens B named/opt-in) · F3.4-B the policy storage (keyspace key vs BEAM-side ETS) · the formation confirm (TRIO). Stage-1 gate is otherwise reachable: the triad is absent (Venus authors it), and no OTHER fork is open.

## {emq3-4-decisions} Decisions

### D-1 — Formation: TRIO (Operator-confirmed via AskUserQuestion)

emq3.4 runs a Flat-L2 TRIO: Venus (author + lag-1 reconcile the triad) · Mars (build + blue-harden — the Mars-2 pass IS the BDD blue phase) · Apollo (MANDATORY post-build verify — the destructive XTRIM op) · Director-1 (rules the forks, independent verify + the blast-radius mutation battery, ship). Rationale: HIGH-risk (destructive at-rest XTRIM, the emq.4.1 drain class) demands Apollo-mandatory + the deepened verify; the design-space is NARROW + PRE-EXPLORED (the emq3.3 dual-architect KB banked emq3.4's forks, 9/10 converged) so NO second architect — a Squad would be redundant ceremony (the ewr.4.1 footgun). aaw_status(emq3-4) must show exactly {Director-1, Venus-1, Mars-1, Apollo-1}.

### D-2 — F3.4-A (the retention-trim cadence) = NAMED/OPT-IN (Operator-ruled; Lens B + the Director's reconciliation)

emq3.4 ships the converged public `EchoMQ.Stream.trim/_` verb over XTRIM + the declared per-stream policy. The cadence that DRIVES the trim is a separately-named opt-in (a Pump-style child or a manual operator call) — NOT coupled to consumer liveness. Retention is a property of the STREAM, not of whether a consumer runs: a stream nobody drains still trims. The fold-safety Lens A argued for is genuinely an emq3.5 fold-consumer property (already converged at F3.5-A) — honored THERE (fold-before-trim on the fold consumer's own beat), NOT forced into emq3.4 general retention. CONSEQUENCE for the build: trim/_ is the frozen mechanism; the general cadence is a named operational decision; emq3.4 does NOT couple the trim to the StreamConsumer beat (no edit to the frozen emq3.3 StreamConsumer loop).

### D-3 — F3.4-B (the policy storage) = BEAM-SIDE DECLARED CONFIG (Operator-ruled; Lens B default)

The declared per-stream retention policy is held BEAM-side (an ETS map or the trim-driver's config), re-applied at start — NO keyspace footprint, NO at-rest cleanup obligation on a destructive rung. Justified: the gate (trim honors the window; a read inside never misses; outside answers truthfully) requires NO reader-visible policy; a polyglot reader reads ENTRIES, it does not enforce retention. Keyspace visibility is an additive upgrade reachable later (a keyspace mirror) WITHOUT a wire break, if a cross-runtime retention-introspection need ever presents. CONSEQUENCE: no new emq:{q}: subkey for policy; the policy carrier is BEAM-internal; the braced-key surface stays exactly the stream key (+ no new Lua, so no new @-script keys).

### D-4 — emq3.4 SHIPPED (Operator-ratified): retention as policy, BUILD-GRADE

The Operator ratified the ship via AskUserQuestion: commit the 3 scoped LAW-4 commits (A rung / B Stage-6 fold / C BLUE docs) + apply Apollo's 2 mentoring folds as commit D. emq3.4 verified BUILD-GRADE across THREE independent attestations (Mars Y-2 3-mutation battery / Director Y-3 2-mutation battery [MAXLEN over-delete + MINID floor +1ms] / Apollo Y-6 production-floor corruption + 18/18 reconcile), gate green (Conformance {:ok,77} LIVE, 514 tests/18 doctests/0 failures, multi-seed sweep 0/1/7777/424242, byte-freeze: echo_wire/keyspace.ex/stream_consumer.ex EMPTY, grep redis.call=0, @wire_version echomq:2.4.2 frozen). Label echomq:2.6.3. The foreign dashboard.ex/echo_mq.dashboard.ex/dashboard_test.exs files EXCLUDED (pathspec discipline — the boundary is the rung's measured surface, not the app dir). Commit order A->B->C->D (B cites A's sha). Mentoring grant: Apollo's 2 folds (the destructive-op probe -> echo-mq-implementor; realization-over-literal body-sync -> echo-mq-architect) applied + committed as D under the Operator's explicit grant.

## {emq3-4-report} Report

### Y-1 — Venus: emq3.4 triad authored to the RULED design (BUILD-GRADE)

### Y-2 — Mars-1 build COMPLETE (emq3.4 retention as policy, RED→GREEN, all gates green)

### Y-3 — Director deepened verify (HIGH, destructive XTRIM): BUILD-GRADE, ZERO code defects

Independent verify of emq3.4 on Valkey 6390 (not a glance — a real pass):
- BYTE-FREEZE net-zero: echo_wire / keyspace.ex / stream_consumer.ex (D-2) diffs EMPTY; 0 added redis.call (no new Lua); the new retention files use Connector.command; mix.exs 2.6.3; @wire_version echomq:2.4.2 frozen; exactly the 5 allowed tracked files + 3 allowed new files changed. stream.ex diff (117 ins/3 del) = the moduledoc deferral rewrite + trim/4 + minid_floor/1 + approx_flag/xtrim helpers ADDED; every existing fn (append/4 …) byte-frozen, verified by reading the hunks (the "−3/all fns frozen" claim independently confirmed).
- COMPILE: independent mix compile --warnings-as-errors EXIT 0; emq3.4's own modules warnings-clean. TWO pre-existing/FOREIGN echo_data warnings (EchoData.ChampView -> EchoStore.Graft, committed 303f1653, clean working tree) — non-fatal, NOT emq3.4's; the umbrella-from-app-dir artifact (echo_store not in echo_mq's dep tree). Honest posture stated.
- GATE: independent re-run — CONFORMANCE 77/77, run/2 -> {:ok,77}, both pins correct (conformance_run_test.exs:74 + conformance_scenarios_test.exs @run_order ends :stream_group,:stream_retention); the prior 76 byte-unchanged.
- BLAST-RADIUS BATTERY (Director-independent — the destructive-op load-bearing gate): TWO mutations, each Edit-in -> test-CATCHES -> inverse-Edit revert -> net-zero verified: (A) MAXLEN over-delete (count -> count-1, deletes INSIDE the window) caught by 3 assertions incl "removed-count must be exact" + the in-window-survival check; (B) MINID floor +1ms skew (over-deletes the at-floor entry) caught by 4 assertions incl the half-open edge proof + the floor-ms UNIT check. Post-revert: zero residue, stream.ex diff = 117/3 (unchanged), suite GREEN (15 tests, 0 failures).
- CODE REVIEW: trim/4 correct (approx ~ the safe default — under-trim possible, over-trim impossible; the "<ms>-0" floor from min_for/1; WRONGTYPE surfaced not swallowed); StreamRetention.Core pure + exhaustive + disjoint (a malformed window RAISES, never a silent skip; a relative {:ago, ms} horizon resolved against the injected clock); the named/opt-in driver decoupled from the StreamConsumer (D-2, the empty diff).

REMEDIATE list: EMPTY (zero code defects) -> Mars-2 collapses on CODE (the emq.5.1 precedent); the verified lib is now byte-frozen.

OUTSTANDING (the BLUE phase, the user's explicit BDD ask): (1) the GWT story test/stories/stream_retention_story_test.exs is NOT authored; (2) the echo/docs retention developer guide. -> dispatched to Mars-1 BLUE (pass 2).
BODY-SYNC NOTE for Apollo (NOT a defect): the spec body says trim/4 "RAISES ArgumentError on a malformed name"; the code raises FunctionClauseError via the is_binary guard, matching append/4's precedent (the raise-before-any-wire behavior holds) — Apollo trues the body §1 wording.

Verdict: BUILD-GRADE.

### Y-4 — Mars-2 BLUE phase COMPLETE (docs + stories only; the verified lib stays sha-locked)

The Director's Stage-3 verify found ZERO defects (task #3 completed), so per the directive BLUE is docs+stories only — NO production-code change. Confirmed: the lib/ diff is byte-identical to the Stage-2 verified state (`conformance.ex` +111/−17, `stream.ex` +117/−3; `stream_retention.ex` + `core.ex` new-but-unchanged), `grep -c redis.call` on lib/ diff still 0. No remediation loops were needed.

### Y-5 — Mars-2 BLUE addendum: the echo/docs/echo_mq.md index link (closes the Director's BUILD-GRADE BLUE directive)

The Director's BUILD-GRADE verdict re-stated the BLUE deliverables and named one item my Y-3 had not yet placed: a one-line index link from `echo/docs/echo_mq.md`. Now done.

- EDIT `echo/docs/echo_mq.md` — added a "bounded retention" paragraph in the `## Consuming` section, right after the `EchoMQ.StreamConsumer`/`stream_consumer.md` paragraph (the sibling convention): names `EchoMQ.Stream.trim/4` (MAXLEN/MINID, the blast radius bounded so a trim can never delete inside the window) + the named/opt-in `EchoMQ.StreamRetention` driver decoupled from any consumer, linking [`echo_mq/stream_retention.md`](echo_mq/stream_retention.md). Link target verified present.

Re-confirmed unchanged from Y-3:
- lib/ STILL the sha-locked 117/3 surface (`conformance.ex` +111/−17, `stream.ex` +117/−3); `grep -c redis.call` on lib/ diff = 0. BLUE remains docs+stories only — ZERO production-code change.
- The story-test gate green: `mix test test/stories/stream_retention_story_test.exs --include valkey` = 4 tests, 0 failures.
- Catalog has all 17 features incl. "Stream retention" (4 scenarios).

The complete emq3.4 BLUE artifact set (all docs-tier, no lib):
- NEW test/stories/stream_retention_story_test.exs (4 GWT scenarios)
- NEW docs/echo_mq/stories/stream-retention.stories.md + EDIT docs/echo_mq/stories/README.md (regenerated)
- NEW echo/docs/echo_mq/stream_retention.md (the dev guide)
- EDIT echo/docs/echo_mq.md (the index link — this addendum)

No git. Task #4 already completed (Apollo #5 in progress). Nothing in lib/ touched — the verified production surface stays byte-frozen for the Director's ship.

### Y-6 — Apollo MANDATORY verify (HIGH, destructive XTRIM): BUILD-GRADE

## Verdict: BUILD-GRADE (the third independent attestation — the ship precondition met)

The as-built satisfies every promise of emq3.4.md. Post-build reconcile: 18 promises checked, 18 MATCH, 0 STALE / INVENTED / MISSING / DEFERRED-open. The HIGH-risk destructive op is bounded by construction and proven POSITIVELY; an independent over-deletion mutation was CAUGHT and reverted net-zero.

## Post-build delta table (promise -> as-built file:line -> verdict)
- D-1 TRIO / D-2 cadence NAMED-OPT-IN / D-3 policy BEAM-side -> the body authored to the ruling; `stream_consumer.ex` git-diff EMPTY (D-2), no keyspace subkey (D-3) -> MATCH
- `EchoMQ.Stream.trim/4` over XTRIM DIRECT (two window heads, ~ default / = opt-in, `{:ok, removed_count}|{:error, term}`) -> stream.ex:215 (`{:maxlen,count,approx?}`) + :222 (`{:minid,%DateTime{},approx?}`), `xtrim/2` :252 surfaces the int + passes `{:error_reply,_}` verbatim -> MATCH
- MINID floor derived from `Snowflake.min_for/1`, never raw int (INV6) -> `minid_floor/1` stream.ex:239 (`"#{unix_ms(min_for(dt))}-0"`); unit + `refute raw-int` proven stream_retention_test.exs:137-145 -> MATCH
- declared per-stream policy BEAM-side, re-applied at start (D-3) -> StreamRetention `:policy` opt + Core, no `emq:{q}:stream:<name>:policy` key -> MATCH
- named/opt-in transient driver, pure decision core (Pump shape) -> `EchoMQ.StreamRetention` (`:transient`, owner-started, no `mod:`) + pure `EchoMQ.StreamRetention.Core.decide/2`+`resolve/2` (exhaustive+disjoint, `:noop` on empty); ADDS a `{:minid,{:ago,ms},approx?}` relative horizon = a pure-clock SUPERSET of the spec's absolute form (build enrichment, not divergence) -> MATCH
- INV4 blast radius bounded POSITIVELY (real deletion + real survival, no-op is LOUD) -> `stream_retention` scenario conformance.ex:2868/2992/3016 (MAXLEN `=` removed==k-keep + survivors==in_window + below GONE; MINID `=` removed==below + at/above SURVIVE incl. the floor edge) -> MATCH
- INV5 no-new-script, append+@-scripts byte-frozen -> `grep -c redis.call` lib diff = 0; jobs.ex/lanes.ex ZERO diff; stream.ex removed-lines = only 3 moduledoc-slot lines (no fn body); no new `Script.new` -> MATCH
- INV7 echo_wire UNTOUCHED + `@wire_version` frozen -> `git diff echo_wire` = 0 lines; `@wire_version "echomq:2.4.2"` connector.ex:35 -> MATCH
- INV8 declared-keys VACUOUS + no subkey + keyspace.ex frozen -> keyspace.ex git-diff EMPTY; policy is ETS/config -> MATCH
- INV9 additive-minor conformance +1 (76->77) -> prior 76 byte-unchanged (`:stream_group` contract byte-identical bar the forced trailing comma); `:stream_retention` sole addition; both pins re-pinned (conformance_run_test.exs:74 `{:ok,77}`, conformance_scenarios_test.exs:129 `@run_order` tail) -> MATCH
- INV10 label `2.6.3` patch; wire frozen -> mix.exs:7 `version: "2.6.3"` -> MATCH

## §11.2 adversarial probes (live, Valkey 6390 — honest row)
(a) Over-deletion probe: trim CANNOT delete inside the window by construction — `~` keeps >=N (safe default, the test mla:92-110 proves approx never over-trims); `=` removes exactly to the edge; the MINID half-open `[dt,∞)` edge exact (dt-1ms trims, dt survives, stream_retention_test.exs:147-161 `survivors==[at_floor]`). The conformance scenario is a POSITIVE deletion+survival proof, never a no-op (removed==k-keep would fail a no-op).
INDEPENDENT MUTATION (my own hands, complementary to the Director's): `minid_floor` ms -> ms+1 (over-deletes the dt edge entry, inside-window). The suite BIT with 4 failures (the exact-accounting, the floor-ms unit, the half-open-edge, the spanning-read). Reverted net-zero by inverse Edit (NOT git checkout — the untracked driver files + L-3 footgun); re-ran GREEN (15 tests/2 doctests/0 failures). Direct-command path, no EVALSHA -> no SCRIPT FLUSH needed.
(b) MINID-floor-exactness probe: floor is `"<ms>-0"`, `ms==unix_ms(min_for(dt))==DateTime.to_unix(dt,:ms)`; raw 63-bit snowflake never on the wire (the `refute` at :144 proves it); tie at the floor ms survives (`-0` lowest tail). HOLDS.
(c) Byte-freeze probe: re-confirmed independently — echo_wire diff 0 lines, keyspace.ex/stream_consumer.ex git-diff EMPTY, jobs.ex/lanes.ex ZERO diff, `grep -c redis.call` lib diff = 0, every `@`-script byte-identical, `@wire_version` unchanged. HOLDS.

## Gate reproduced (independent, per-app, Valkey 6390 PONG)
- compile --warnings-as-errors EXIT 0 (emq3.4 clean; the 2 EchoData.ChampView->EchoStore.Graft warnings are FOREIGN/pre-existing `303f1653`, NON-FATAL, NOT this rung — the umbrella-from-app-dir artifact, not flagged as new)
- `mix test --include valkey` EXIT 0: 514 tests, 18 doctests, 0 failures (the loud `[error]` log lines are the deliberate crash-recovery/WRONGTYPE negative-path tests — 0 failures)
- `Conformance.run/2` -> `{:ok, 77}` LIVE, `scenarios/0` length 77, `CONF stream_retention ok`; both pin tests green
- determinism = MULTI-SEED sweep (seeds 0/1/7777/424242): retention 19 tests + 2 doctests, 0 failures every seed (NO >=100 loop — the rung mints no ids, opens no lease, per the testing posture; running it would forge a same-ms-mint load this rung does not introduce). Honest determinism statement: the only nondeterminism is the wire round-trip (covered by the shipped connector suites) and the host tick clock (the driver core is a pure fn of the injected clock; MINID-edge entries minted at CHOSEN ms via min_for/1, seed-independent — no sleep race).

## Story coverage (§0, the FAST job) — MET
`test/stories/stream_retention_story_test.exs` (4 BDD scenarios driving the REAL surface on 6390: MAXLEN, MINID, blast-radius bound, the D-2 decoupled driver) PASSES (4/0). `mix echo_mq.stories` regenerates clean (17 features/43 scenarios); `docs/echo_mq/stories/stream-retention.stories.md` present (untracked ??) + README.md (M) — both for the Director to commit.

## Spec sync (record what shipped — body authoritative post-build; canon untouched)
- emq3.4.md: title + Status note trued to AS-BUILT (BUILT+Apollo-VERIFIED, the realized surface map: `trim/4` two heads, public `minid_floor/1`, `EchoMQ.StreamRetention` + `.Core` with the additive `{:ago, ms}` horizon); the closed-error-set §ill-formed-name trued to the TWO realized raise paths (FunctionClauseError via `is_binary` guard for a non-binary name; ArgumentError via `Keyspace.queue_key/2` for out-of-charset); `trim/_` -> `trim/4` (21 occ).
- emq3.4.stories.md + emq3.4.llms.md: `trim/_` -> `trim/4`; the llms "Decide the arity" line trued to SETTLED (single `trim/4`, `minid_floor/1`) + the FunctionClauseError realization.
- emq.design.md / emq.streams.md: NOT touched (reconcile-only canon — a canon-sync is the Operator's call, flagged not applied; none needed — the tier contract is honored as written).

## Mentoring (PROPOSE-ONLY, Director-ratified — NOT self-applied to .claude/*)
Four folds from the consolidated findings; see the SendMessage to the Director for the exact proposed diffs:
1. echo-mq-implementor SKILL.md:160-162 (extend the existing destructive-op probe): the BLAST-RADIUS MUTATION BATTERY is the destructive-op gate (mutate the bound/flag/floor -> each a CAUGHT over-/under-deletion); the approx-vs-exact SAFETY ASYMMETRY (`~` the safe default — under-trims never over-trims); the FLOOR-FROM-min_for/1 discipline (a snowflake integer is NOT a stream id — derive `"<ms>-0"`, never hand the raw int to the wire). Cited emq3.4.
2. echo-mq-architect SKILL.md: a body-author calibration — "realization-over-literal" honesty (spec said ArgumentError, as-built raises FunctionClauseError via the guard; the body-author trues the § to the realized mechanism, the raise-before-wire intent preserved). Cited emq3.4.
These are NEW (not duplicates): the implementor line 160-162 is a general "gated behind a green precondition" only; neither skill carries the battery/asymmetry/floor craft, and the architect carries no realization-over-literal line.

## BLUE deliverables (the only files this pass touched)
- NEW `echo/apps/echo_mq/test/stories/stream_retention_story_test.exs` — the GWT acceptance in the `EchoMQ.Story` DSL (`use EchoMQ.Story, feature: "Stream retention"`), 4 scenarios, the brief's exact set:
  1. a MAXLEN trim keeps the newest + removes the older, never deleting inside the window (real deletion + real survival).
  2. a MINID trim removes entries below a mint instant, keeps those at/above it (the half-open [dt, ∞) edge, floor from Snowflake.min_for/1).
  3. the blast radius is bounded — an in-window entry survives a trim (over-deletion would be a LOUD failure).
  4. retention is a property of the stream — the opt-in driver sweeps the declared policy with NO StreamConsumer present (decoupled from consumer liveness, D-2).
  Every scenario is a real `:valkey` ExUnit test driving the live `EchoMQ.Stream`/`EchoMQ.StreamRetention` surface (a story that doesn't exercise the real code won't compile into the catalogue). MINID entries minted at CHOSEN ms via min_for/1 (not the live clock) — seed-independent.
- NEW `docs/echo_mq/stories/stream-retention.stories.md` + EDIT `docs/echo_mq/stories/README.md` — `mix echo_mq.stories` regenerated (17 feature files / 43 scenarios; "Stream retention" = 4).
- NEW `echo/docs/echo_mq/stream_retention.md` — the developer guide (the `EchoMQ.Stream.trim/4` verb + the window-form table, the approx-vs-exact safety asymmetry, the trim-honors-the-window table [MAXLEN | MINID × kept/removed/blast-radius/read-inside/read-of-trimmed], the MINID-floor-from-min_for/1 derivation incl. `minid_floor/1`, the named/opt-in `EchoMQ.StreamRetention` driver + its option table + child_spec/sweep, why-opt-in-and-decoupled [D-2], the BEAM-side policy [D-3, no keyspace subkey], the pure `EchoMQ.StreamRetention.Core` decision core). Modeled on the sibling `echo/docs/echo_mq/stream_consumer.md`. The `decide/2` doc example was VERIFIED accurate against the running code (`mix run` — keep-last-60s resolves to exactly 11:59:00).

## Full gate ladder (BLUE re-run, echo/apps/echo_mq, Valkey 6390)
- `TMPDIR=/tmp mix compile --warnings-as-errors` — CLEAN (echo_mq).
- `TMPDIR=/tmp mix test --include valkey` — **18 doctests, 514 tests, 0 failures** (510 + the 4 new GWT scenarios).
- `EchoMQ.Conformance.run/2` → **{:ok, 77}** (CONFORMANCE 77/77, unchanged).
- Multi-seed sweep on the new story test (seeds 0/7/99) — 4 tests, 0 failures each (seed-independent).

No git (the Director commits at the close). The full diff is now the RED lib + tests + the BLUE stories/docs — ready for Apollo's MANDATORY verify (the destructive-op reconcile + §11.2 adversarial verification). The blast-radius mutation battery (3/3 caught, net-zero reverted) is in Y-2 and reproducible.

## As-built surface (the two shapes settled — for the body §1/§3 sync)
- **`EchoMQ.Stream.trim/4`** — `trim(conn, queue, name, window)`, ONE public entry the driver + a manual caller share. `window` is a tagged tuple: `{:maxlen, count, approx?}` | `{:minid, %DateTime{}, approx?}` (exactly the declared-policy shape, so the driver passes its stored policy straight through). `approx?` true→`~` (safe default), false→`=` (exact opt-in). Returns `{:ok, removed_count}` | `{:error, term}`. (`stream.ex:215`/`:222`.)
- **`EchoMQ.Stream.minid_floor/1`** (NEW public helper, `stream.ex:239`) — the floor `"<ms>-0"`, `ms = Snowflake.unix_ms(Snowflake.min_for(dt))`. Public so the conformance probe + Apollo verify the INV6 derivation directly; never the raw snowflake integer to the wire.
- **Driver module = `EchoMQ.StreamRetention`** + **pure core `EchoMQ.StreamRetention.Core`** (the `EchoMQ.Pump`/`Pump.Core` shape exactly). Core: `decide/2` (policies × injected clock → `[trim_call]` | `:noop`, exhaustive+disjoint, raises on malformed) + `resolve/2` (one window, incl. a RELATIVE `{:minid, {:ago, ms}, approx?}` horizon resolved against the injected clock — a pure fn, the BatchShaper.Core precedent). Driver: a `:transient` opt-in owner-started child (`:policy`/`:tick_ms`/`:clock`/`:conn`|`:connector`), `sweep/1` exposed for direct-drive; decoupled from `StreamConsumer`.

## Realization-over-literal (one, flagged)
The brief's "malformed queue/stream name RAISES before any wire" — realized as the guard clauses (`is_binary(queue)`, `is_binary(name)`) + `stream_key/2` computed before the wire, NOT an invented name-validity check. `Keyspace.queue_key/2` (`keyspace.ex:14`) has only an `is_binary` guard (no raise on empty/odd strings), and the writer's `append/4` relies on the same guard discipline — so a non-binary name is a `FunctionClauseError` before any `XTRIM` (policy before existence). Tested (`stream_retention_test.exs` — the malformed-name case asserts the raise + the sibling stream key stays absent). No new surface invented.

## Files (NEW / EDIT — the brief's exact set, no third app)
- EDIT `lib/echo_mq/stream.ex` (+117/−3; the −3 = ONLY the `## NOT this rung` moduledoc deferral sentence rewritten into a `## Retention` note; `append/4`/`append_id/5`/`append_batch/4`/`read/3..6`/`stream_key/2` byte-frozen — verified by removed-line audit).
- NEW `lib/echo_mq/stream_retention.ex` (the driver).
- NEW `lib/echo_mq/stream_retention/core.ex` (the pure core).
- NEW `test/stream_retention_test.exs` (the `:valkey` proof + the pure-core unit tests + `doctest EchoMQ.StreamRetention.Core`).
- EDIT `lib/echo_mq/conformance.ex` (+111/−17: the `stream_retention` keyword pair + the `apply_scenario(:stream_retention,…)` clause [contiguous with the other clauses] + 2 helpers; the moduledoc + run/2 doc count 76→77 + narration. Removed lines audited = ONLY doc/count edits + the stream_group line extended by a comma — NO prior probe body reflowed; echo_mq has no .formatter.exs).
- EDIT `test/conformance_run_test.exs` (`{:ok, 76}`→`{:ok, 77}` + count/narration).
- EDIT `test/conformance_scenarios_test.exs` (`@run_order` gains `:stream_retention` + count/narration).
- EDIT `mix.exs` (`2.6.2`→`2.6.3`, within-family patch).

## Gate results (run from echo/apps/echo_mq, Valkey 6390, Erlang 28.5.0.1/Elixir 1.18.4)
- `TMPDIR=/tmp mix compile --warnings-as-errors --force` — CLEAN (echo_mq; the echo_data/EchoStore.Graft warnings are pre-existing, files I don't own).
- `TMPDIR=/tmp mix test --include valkey` — **18 doctests, 510 tests, 0 failures**.
- `EchoMQ.Conformance.run/2` → **{:ok, 77}** (`CONFORMANCE 77/77`; the prior 76 byte-unchanged + git-verified; the new `stream_retention` is a POSITIVE deletion+survival proof over BOTH MAXLEN and MINID).
- Multi-seed sweep (NOT the ≥100 loop): seeds 0,1,12345 — each `2 doctests, 17 tests, 0 failures`.

## Byte-freeze (INV5/INV7/INV8 — to closure over the whole file)
- INV5: `grep -c redis.call` on the lib/ diff = **0**; every shipped `@`-script byte-identical (0 `@`-script lines in the lib/ diff).
- INV7: `git diff echo_wire/` EMPTY; `@wire_version` `echomq:2.4.2` unchanged; `{emq}:version` on the wire = `echomq:2.4.2`; no new EMQ* wire class.
- INV8: `git diff keyspace.ex` EMPTY; `git diff stream_consumer.ex` EMPTY (D-2); NO `emq:{q}:stream:<name>:policy` key built (the grep hits for "policy" are comments/contract strings only — the policy is BEAM-side state). Declared-keys VACUOUS (no new script).
- INV10: `mix.exs` = `2.6.3`.

## Adversarial self-verify (§6 — the destructive-op gate; SCRIPT FLUSH between each)
Blast-radius mutation battery, kill-rate **3/3**, each reverted net-zero by INVERSE Edit (NOT git checkout), stream.ex byte-confirmed == pre-mutation:
1. MINID floor off-by-1ms (`min_for ms + 1`) → CAUGHT (4 tests: the half-open edge, the floor-ms unit, the MINID accounting, the spanning read).
2. MAXLEN bound (`count + 2`) → CAUGHT (3 tests: MAXLEN exact accounting, survival-set equality, driver sweep `trimmed`).
3. approx/exact flag (`=`→`~`) → CAUGHT (the exact-accounting tests; approx defers on a 1-macro-node stream).
Over-deletion probe: bounded by construction (the window IS the argument; approx under-trims, exact removes to the edge — neither over-deletes), proven positively over both forms. WRONGTYPE surfaced not swallowed (tested).

## Determinism posture (honest)
The rung mints NO branded ids in the trim path (the floor derives from a caller `DateTime`; the floor-edge entries are minted at CHOSEN milliseconds via `Snowflake.min_for/1`, NOT the live clock — seed-independent, no `Process.sleep` race) and opens NO lease. The same-ms mint hazard is ABSENT → the ≥100 loop is NOT run (it would forge a load the rung does not introduce). The posture = the multi-seed sweep + this statement + the driver decision core tested as a PURE fn of the injected clock.

No brief gap. The forks (D-1/D-2/D-3) were RULED pre-build and built to, not re-opened. Ready for the Director's deepened verify (the blast-radius battery is reproducible as above).

## Authored surface (4 files, spec triad only — no production code, no git)
- `docs/echo_mq/specs/emq3/emq3.4.md` — the authoritative body: the `EchoMQ.Stream.trim/_` contract (the two XTRIM window forms `MAXLEN [~|=] <count>` / `MINID [~|=] <floor>`, ~approx default + =exact opt-in), §2 the MINID-floor derivation, §3 the declared policy + the named/opt-in driver, the testing posture, INV1–INV10, the closed error set, the DoD.
- `docs/echo_mq/specs/emq3/emq3.4.stories.md` — US1–US5 + EMQ3.4-US-GATE + the Coverage map + the deep-proof manifest.
- `docs/echo_mq/specs/emq3/emq3.4.llms.md` — the Mars brief: References (14) · Requirements (8) · the topology DAG + the EXACT files touched · AS1–AS6.
- `docs/echo_mq/specs/emq3/emq3.4.prompt.md` — the run scope: risk tier HIGH (destructive XTRIM), the TRIO formation, the per-stage directive blocks (Mars build+blue / Director deepened verify / Mars-2 / Apollo MANDATORY / ship), the gate ladder (multi-seed sweep, NOT the ≥100 loop).

## Reconcile result (lag-1, every claim MATCH — no drift, no STALE/INVENTED/MISSING)
- `EchoMQ.Stream` (stream.ex): append/4 :77, append_id/5 :94, append_batch/4 :129, read/3..6 :156, stream_key/2 :173 — all present; the retention slot PRE-DECLARED at stream.ex:50 ("Retention (MAXLEN/MINID) is emq3.4; append/_ does not trim"). NO trim surface exists yet (verified — must not). The append + @-scripts are byte-frozen this rung.
- `EchoData.Snowflake`: min_for/1 :116 (= (DateTime.to_unix(dt,:ms) - @epoch_ms) <<< 22), unix_ms/1 :107, to_datetime/1 :110, epoch_ms/0 :122 (1_704_067_200_000) — all confirmed.
- `EchoMQ.Pump`/`Pump.Core` (pump.ex) — the opt-in :transient cadence + pure decision core, the driver shape.
- `EchoMQ.Connector.command/3` (connector.ex:49) — the generic path XTRIM rides; @wire_version "echomq:2.4.2".
- Conformance count re-probed LIVE = **76** (moduledoc "seventy-six" ×3; scenarios/0 :119-196 ends at :stream_group :195; conformance_run_test.exs:69 {:ok,76}; conformance_scenarios_test.exs:127 @run_order :66-123). mix.exs version "2.6.2".
- ONE reconcile FINDING (the rung's id-math): the MINID floor must be DERIVED from min_for/1 — the floor id is "<ms>-0" with ms = unix_ms(min_for(dt)) — NEVER min_for/1's raw 63-bit snowflake integer handed to the wire (XTRIM wants ms-seq). Named explicitly in body §2 + INV6 so Mars builds it right and Apollo verifies it positively.

## Locked decisions HONORED (authored to, NOT re-opened as Arms)
- D-1 TRIO formation. D-2 trim cadence = NAMED/OPT-IN (the StreamConsumer loop FROZEN — git diff stream_consumer.ex EMPTY). D-3 policy = BEAM-side declared config (NO keyspace subkey, NO at-rest cleanup obligation). All six pre-stated INVs bound BY NAME (INV1 window-honored, INV2 read-inside-never-misses, INV3 outside-answers-truthfully, INV4 the destructive blast-radius bounded [load-bearing, 11× in body], INV5 additive byte-freeze, INV6 the MINID floor == min_for(dt) exactly).

## Gate
- `msh specs echo_mq` (error severity) over the tree: **ZERO findings in any emq3.4.* file** — all cross-links resolve at the real ../../ depth (verified, the emq.5.1 L-2 defense). 4 pre-existing `](word)` false-positives in the sibling emq-5-4.progress.md (AM-status, the documented bracket-paren parser quirk) — NOT my rung, found-not-introduced, reported not blocked.
- Internal consistency: INV1–INV10 complete; count chain 76→77 + {:ok,77} + "seventy-seven" in all 4; label chain 2.6.2→2.6.3 in all 4; @wire_version echomq:2.4.2 frozen; determinism posture (multi-seed sweep, NOT the ≥100 loop) stated in all 4; D-2/D-3 cited across all 4.

## The one-paragraph brief Mars builds from
emq3.4 adds a public `EchoMQ.Stream.trim/_` over XTRIM (issued DIRECT on Connector.command/3 — no new Lua, append/4 + every @-script byte-frozen): the two window forms MAXLEN [~|=] <count> (keep newest-N) and MINID [~|=] <floor> (drop below a mint instant), ~approx the SAFE default (under-trims, never over-trims), =exact the opt-in; returns {:ok, removed_count} | {:error, term}. The MINID floor is derived from the SHIPPED Snowflake.min_for/1 ("<ms>-0", ms = unix_ms(min_for(dt))). A declared per-stream policy is held BEAM-side (ETS map or driver config — no keyspace subkey, D-3), re-applied by a named, opt-in, owner-started :transient trim driver (the EchoMQ.Pump shape — a pure tick/decision core + a thin process router, D-2), decoupled from consumer liveness (the frozen emq3.3 StreamConsumer loop untouched). The destructive blast radius is bounded by the declared window — a trim can NEVER delete inside it (INV4: the +1 stream_retention conformance scenario, 76→77, POSITIVELY proves in-window survival + below-window deletion + the removed-count over BOTH forms, never a no-op). Determinism posture: a multi-seed sweep + an honest statement (the rung mints no ids, opens no lease — the ≥100 loop is NOT run). Label echomq:2.6.3 (within-family); @wire_version frozen echomq:2.4.2. Risk HIGH (destructive XTRIM); Apollo MANDATORY.

VERDICT: BUILD-GRADE. The triad grounds every public call in a real module/§ (forward-tense for the unshipped trim/_ + driver); the locked decisions are honored; the gate is clean for the emq3.4 files. No fork surfaced (the two emq3.4 forks were RULED pre-author by the Operator).

## {emq3-4-learnings} Learnings

### L-1 — the destructive-op gate is a POSITIVE deletion+survival proof + a blast-radius mutation battery, never a no-op

A destructive at-rest verb (XTRIM here; the emq.4.1 drain/3 class) cannot be gate-proven by "it ran and removed something" — that is the TRD.9.1 false-green. The emq3.4 gate that BIT: the conformance/unit scenario appends entries BOTH inside AND below the window, trims, and asserts a real DELETION (below-window GONE) AND a real SURVIVAL (in-window receipts still read back) in the SAME verdict, the removed-count exact under `=`. Then the mutation battery: mutate the bound / the approx-exact flag / the derived floor — each mutation must surface as a CAUGHT over- or under-deletion. An independent over-deletion mutation (minid_floor ms -> ms+1) was caught by 4 tests and reverted net-zero by inverse Edit (NOT git checkout — the new driver files were untracked).

Two craft sub-lessons the rung earned:
- The approx-vs-exact SAFETY ASYMMETRY: `~` (whole-macro-node) is the safe default — it can UNDER-trim (keep extra) but NEVER OVER-trim (delete inside the window). A destructive op's safe error direction is toward KEEPING data; the exact `=` is the explicit opt-in for a hard cap. The test proves approx never removes inside the window (an impossibility under ~).
- The FLOOR-FROM-min_for/1 discipline: a 63-bit snowflake INTEGER is NOT a stream id. The MINID floor is `"<ms>-0"` where `ms = unix_ms(min_for(dt))` == `DateTime.to_unix(dt, :ms)` — derived from the shipped `Snowflake.min_for/1`, with the raw integer NEVER handed to the wire (a `refute floor == Integer.to_string(min_for(dt))` proves it). The half-open `[dt, ∞)` edge is then exact (dt-1ms trims, dt survives — `-0` is the lowest tail at the floor ms), seed-independent because the edge entries are minted at CHOSEN ms via min_for/1, not the live clock — no determinism loop needed (no mint, no lease).

Body-author calibration: realization-over-literal — the spec said `trim/_` raises ArgumentError on a malformed name; the as-built raises FunctionClauseError via the `is_binary` guard (matching append/4). The raise-before-any-wire INTENT holds; the body-author trues the § to the realized mechanism rather than forcing the code to the literal word.

## {emq3-4-complete} Complete

### Z-1 — emq3.4 COMPLETE: retention as policy (the trim verb + the declared window + the named/opt-in driver), S2 the readers part 2

Ships EchoMQ.Stream.trim/4 over XTRIM (the two window forms MAXLEN ~/= keep-newest-N + MINID ~/= via minid_floor/1 from Snowflake.min_for/1, the "<ms>-0" floor — the rung's one piece of real id-math, the snowflake-int NEVER on the wire) + the BEAM-side declared per-stream policy (D-3, no keyspace subkey) + the named/opt-in EchoMQ.StreamRetention driver + the pure EchoMQ.StreamRetention.Core (D-2, decoupled from the frozen StreamConsumer; a relative {:ago,ms} horizon the pure-clock superset). NO new Lua (XTRIM issued DIRECT), NO echo_wire edit; append/4 + every @-script byte-frozen. The destructive blast radius is bounded by the declared window (INV4, the load-bearing invariant) — the ~ approx the safe default (under-trims, never over-trims). Conformance 76->77 (+stream_retention, a POSITIVE deletion+survival proof, never a no-op). Label echomq:2.6.3; @wire_version echomq:2.4.2 frozen. Risk HIGH (destructive XTRIM, the emq.4.1 drain class) -> the blast-radius mutation battery (3 independent attestations) + Apollo MANDATORY, NOT the >=100 loop (the rung mints no ids, opens no lease). TRIO formation (D-1); forks ruled pre-build (D-2 named/opt-in cadence, D-3 BEAM-side policy). Shipped as 4 LAW-4 commits (A rung / B Stage-6 fold / C BLUE docs / D mentoring). NEXT: emq3.5 (the archive — fold trimmed segments into the native EchoStore.Graft engine, fold-before-trim per F3.5-A; re-confirm Graft readiness at the pre-build reconcile, likely HIGH-risk).
