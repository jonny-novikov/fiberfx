# EMQ.0 · Movement 0 complete — the BCS migration imported whole and proven on this machine
> The AAW triad port of `docs/echo/migration/echo2-migration.md` (the Movement-0 contract-turned-record),
> EXTENDED at the Stage-1b checkpoint: the drop's CHANGELOG declares "Movement 0. NOT COMPLETED" — the
> pending delta (the echo_wire wire-layer extraction + the cache's pluggable shadow) imports first, then the
> §5 test/coverage pass closes the movement, under the program
> "EchoMQ in Three Movements" ([`../emq.roadmap.md`](../../emq.roadmap.md)).
>
> **Superseded — the Shadow subsystem is retired.** This record is the as-imported account of Movement 0,
> which imported the cache's pluggable `Shadow` behaviour (`shadow.ex`, `shadow/copy.ex`, the shadow rung)
> intact. That subsystem has since been **retired** ([`../../store/design/store.design.md`](../../store/design/store.design.md) §2):
> the app was renamed `echo_store`, durable replicated state moved to the native `EchoStore.Graft` engine
> streamed to Tigris, and `shadow.ex`/`shadow/copy.ex` and their tests were deleted. The Shadow details below
> stand as the import history, not the current shape.

## Goal

The drop's pending Movement-0 delta lands in production exactly as the drop shapes it — the new
`echo/apps/echo_wire` app (`EchoMQ.{RESP, Connector, Script}` relocated, names frozen, the `EchoWire` facade
in front), the cache's pluggable shadow (`EchoStore.Shadow` + `Shadow.Copy`, `Litestream` conforming), the
new shadow rung, and the dual-path loader re-adaptation — and then every public module of the as-landed
shape (`echo_wire`: 3 modules + the facade; `echo_mq`: 6 modules; `echo_store`: 9 files + the nested
`Directory`; `EchoData.Bcs*`: 5 files) is exercised by per-app ExUnit suites: pure surfaces in the default
run, wire-bound surfaces behind the `:valkey` tag against Valkey on 6390; per-module coverage is reported
honestly; the full gate ladder (compiles → suites → rung gates 3_1..3_5 + 4_1..4_4 + the shadow rung)
re-runs green; the record's §5 status flips to COMPLETE and `echo/rungs/` enters tracking at the Director's
pathspec commit.

## Rationale (5W)

- **Why** — Movement 0's first pass landed measured, rung-gated code (gates 3_1..3_5 PASS
  5/5·5/5·6/6·8/8·6/6 and 4_1..4_4 PASS 6/6 each, recorded 2026-06-12), but the drop then moved again: its
  CHANGELOG declares the movement NOT COMPLETED, and the Operator ruled the pending code MUST be imported.
  The delta is also exactly the inventory the program's worked consumer stands on — codemojex draws its work
  surface from "the wire (`EchoMQ.Connector` over `EchoWire`)" and a pluggable shadow (`EchoStore.Shadow`
  with the Litestream and Copy implementations) behind the bus it enqueues on. And only three migrated test files guard the tree
  (the floor, not the suite): untested public surface cannot anchor Movement I, and the additive BCS stores
  would otherwise ship untested (the ratified Q3 ground).
- **What** — two halves. The IMPORT: the file-by-file manifest in the agent brief — the echo_wire app (the
  three relocated wire modules, byte-identical; the facade; the dependency-free `mix.exs`), the echo_mq
  re-shape (three lib files + `resp_test.exs` move out; `mix.exs` gains `{:echo_wire, in_umbrella: true}`
  and drops `:crypto`), the cache shadow (`shadow.ex` + `shadow/copy.ex` new; `litestream.ex`'s additive
  behaviour delta), the new shadow rung script, and the 9 self-loading rung scripts re-adapted to the drop's
  dual-path echo_wire-first loader. The PROOF: the record's §5 test-writer brief executed over the as-landed
  shape — pure suites per the §5 lifecycle map AS EXTENDED by this triad (the facade, the connector's three
  added verbs, the shadow subsystem), `:valkey`-tagged integration suites, the ratified Q1 stand-in
  (`EchoMQ.Conformance.run/2 → {:ok, 14}`), per-module coverage with honest partials, and the closure
  surfaces (the §5 status flip; `echo/rungs/` tracked).
- **Who** — the Director accepts against the gate ladder; the Operator ratifies Movement 0 closed; codemojex
  (the program's worked consumer — `echo/apps/codemojex`) gains the exact wire + shadow inventory
  its work surface stands on; Movement I's authors gain a proven baseline.
- **When** — the program's first rung: first build pass 2026-06-12; the drop's CHANGELOG delta and this
  scope expansion 2026-06-13 (the Stage-1b checkpoint); emq.1 (Movement I, ratified: the scheduler + retry
  vocabulary) follows it.
- **Where** — the import touches `echo/apps/echo_wire` (new), `echo/apps/echo_mq` (three lib files +
  `resp_test.exs` move out; `mix.exs`), `echo/apps/echo_store` (two new lib files; `litestream.ex`;
  `mix.exs`), and `echo/rungs/` (one new script; 9 re-adapted loaders). The proof touches test trees only:
  `echo/apps/echo_wire/test/`, `echo/apps/echo_mq/test/`, `echo/apps/echo_store/test/`,
  `echo/apps/echo_data/test/bcs/` (new files, D15), plus at most the new apps' `mix.exs`
  `test_coverage: [summary: [threshold: 0]]` keys, the record's one-line §5 flip, and the `echo/rungs/`
  tracking at commit time. `echo/apps/echomq` (the frozen v1 line) untouched entirely; `echo_data/lib`
  untouched.

## Scope

- **In** — the CHANGELOG delta import per the agent brief's manifest (modes byte-identical vs ADAPTED, the
  record's §3/§4 style; the landing shape mirrors the drop — a new umbrella app `echo/apps/echo_wire`);
  pure ExUnit suites per the record's §5 lifecycle map as extended here; `:valkey`-tagged wire suites
  (per-test sub-queues, the baseline purge idiom); the Q1 stand-in conformance test; coverage runs + the
  per-module report; re-running the full gate ladder including the new shadow rung; the §5 status flip; the
  rungs-tracking closure note.
- **Out** — everything the record §7 defers (the lab app — its new `echo_wire` dep edge is recorded, not
  imported, per D6; the Litestream runtime drill — only `replica_url/2` + the behaviour conformance are
  testable; the referee env; the oban rival rig and therefore rung 3_6's own gate; the drop's vendored
  packages; sibling runtimes); the drop rungs OUTSIDE the CHANGELOG delta
  (`rungs/bus/bcs_rung_busobjects_check.*`, `rungs/canon/bcs_rung_serialization_check.*`, the referee
  family — observed in the drop, surfaced to the Operator, not imported); any edit to `apps/echomq`; any
  new capability (Movement I, emq.1+); any mix.lock movement beyond the recorded exqlite-only delta.

## Deliverables

Recorded by the first build pass (COMPLETE 2026-06-12 — the import's input state, re-shaped by D9–D11 and
re-proven by this rung):

- **EMQ.0-D1** — `echo/apps/echo_mq`: OTP `:echo_mq`, the drop's bus modules byte-identical, adapted
  `mix.exs` (`EchoMq.MixProject` — the §3.6 collision exception), helper `ExUnit.start(exclude: [:valkey])`.
- **EMQ.0-D2** — `echo/apps/echo_store`: OTP `:echo_store`, the drop's cache modules byte-identical
  (+ nested `EchoStore.Directory`, `echo_store.ex:41`), deps `{:echo_data, in_umbrella}` +
  `{:echo_mq, in_umbrella}` + `{:exqlite, "0.23.0"}`; lock delta exqlite-only (one insertion).
- **EMQ.0-D3** — the additive `EchoData.Bcs*` subtree: `lib/echo_data/bcs.ex` +
  `bcs/{property_store,archetypes,edge_store,supervisor}.ex`, no existing `echo_data` file edited.
- **EMQ.0-D4** — `echo/rungs/{bus,cache,journal}`: the 10 first-pass rung-gate scripts; gates 3_1..3_5 +
  4_1..4_4 PASS on this machine (3_6 copied, gate conditional per ratified Q1).

Open — the Stage-1c import (the CHANGELOG delta, all of it):

- **EMQ.0-D9** — `echo/apps/echo_wire` (new app, mirroring the drop): `lib/echo_mq/{resp,script,connector}.ex`
  relocated from `apps/echo_mq` (byte-identical — the drop's copies and production's are verified identical,
  so the production action is a file move), `lib/echo_wire.ex` (the facade: nine delegated connector verbs +
  `script/2`), `mix.exs` byte-identical (`EchoWire.MixProject`; `extra_applications: [:logger, :crypto]`;
  `deps: []` — dependency-free by design), `test/resp_test.exs` relocated, `test/test_helper.exs` ADAPTED to
  `ExUnit.start(exclude: [:valkey])` (D13). `apps/echo_mq/mix.exs` ADAPTED: deps gain
  `{:echo_wire, in_umbrella: true}`, `extra_applications` drops `:crypto` (it travels with `Script`); the
  project module stays `EchoMq.MixProject`.
  *As-built (Stage-4 sync; two D-10-ratified deviations — the drop's "NOT COMPLETED" state never
  strict-compiled the extracted app):* (a) the echo_wire `mix.exs` additionally carries
  `elixirc_options: [no_warn_undefined: [EchoMQ.Keyspace]]` (`mix.exs:18` — the connector's version fence
  reads `EchoMQ.Keyspace.version_key/0` at runtime, `connector.ex:417`, while `deps` stay `[]`; in-drop
  precedent `echo_data/snowflake.ex:2`) plus the permitted `test_coverage: [summary: [threshold: 0]]` key;
  (b) `connector.ex` lands with ONE delta from the drop text — the `defp send_pipe/5` block relocated
  verbatim below the last `handle_call` clause (pure definition reordering; the ungrouped-clauses warning
  made byte-identity and the strict compile jointly unsatisfiable; Stage-4 verified the relocation is the
  only diff, 16 lines, clause order otherwise preserved). `resp.ex`, `script.ex`, `echo_wire.ex`, and
  `resp_test.exs` are byte-identical to the drop as specified.
- **EMQ.0-D10** — the cache's pluggable shadow: `lib/echo_store/shadow.ex` + `lib/echo_store/shadow/copy.ex`
  byte-identical; `lib/echo_store/litestream.ex` replaced with the drop copy (verified additive-only:
  `@behaviour EchoStore.Shadow` + four `@impl` lines); `apps/echo_store/mix.exs` ADAPTED: deps gain
  `{:echo_wire, in_umbrella: true}` (the drop's stale `{:echomq, in_umbrella}` dep atom is a drop source
  defect — no `:echomq` app exists in the drop — production's `{:echo_mq, in_umbrella}` stands);
  `rungs/journal/bcs_rung_shadow_check.exs` byte-identical (a compiled-module rung like 4_4; its `.out`
  stays frozen in the drop, D5).
- **EMQ.0-D11** — the 9 self-loading rung scripts (6 bus + 3 cache) re-adapted to the drop's dual-path
  wire loader (`Enum.find` over the echo_wire path first), with ONE permitted delta from the drop text: the
  fallback arm's app-dir segment re-spelled `apps/echomq/` → `apps/echo_mq/` so no production rung script
  names the frozen v1 app's directory (the drop's spelling is a vestige of its own pre-rename tree; in
  production it would alias the v1 app dir). `bcs_rung_4_4_check.exs` stays byte-identical.

Open — the proof (the record's §5 pass over the as-landed shape):

- **EMQ.0-D5** — pure-surface ExUnit suites for every public module per the record's §5 lifecycle map AS
  EXTENDED by the agent brief (the `EchoWire` facade; the connector's `noreply_pipeline/3` +
  `transaction_pipeline/3` + `subscribe/2`; `EchoStore.Shadow`; `EchoStore.Shadow.Copy`; the Litestream
  behaviour conformance), in the four test trees; the three migrated test files stay byte-identical and
  green (the floor), `resp_test.exs` now living in `apps/echo_wire/test/`.
- **EMQ.0-D6** — `:valkey`-tagged integration suites for every wire-bound surface in the extended map,
  excluded by default, green under `--include valkey` against 6390 — including the ratified Q1 stand-in:
  `EchoMQ.Conformance.run/2 → {:ok, 14}` with the pinned 14-name scenario list.
  *As-built (Stage-4 sync, the third D-10-ratified deviation):* the Connector wire suite and the
  facade-live test live in `apps/echo_mq/test/` (`connector_test.exs`, `echo_wire_live_test.exs`), NOT in
  `apps/echo_wire/test/` — the dependency-free wire app's per-app run cannot resolve
  `EchoMQ.Keyspace.version_key/0` at runtime, so a connection is unreachable from echo_wire's own suite
  (probed: 13/22 `UndefinedFunctionError`); assertions unchanged, placement only. The echo_wire test tree
  also gains `resp_extend_test.exs` (AUTHORED by the Stage-3 harden pass, ratified: pins the full RESP2/3
  type surface the floor left uncovered, lifting RESP coverage 42.37 → 93.22 and the echo_wire pure suite
  8 → 18 tests).
- **EMQ.0-D7** — the per-module coverage report from per-app `TMPDIR=/tmp mix test --cover` runs
  (`--include valkey` where the app has wire suites): every public function's happy path AND each named
  refusal/guard path exercised; partial coverage reported with the reason (Litestream's runtime demands the
  deferred binary — `replica_url/2` + the behaviour exports are the reachable surface); the new apps'
  `mix.exs` MAY add `test_coverage: [summary: [threshold: 0]]`.
- **EMQ.0-D8** — closure: the record's §5 status flips PENDING → COMPLETE (the record is touched no
  further); `echo/rungs/` (untracked today) enters tracking at the Director's pathspec commit — agents run
  no git.
  *As-built (Stage-4 sync):* the "untracked today" premise was OVERTAKEN mid-run — the 10 first-pass rung
  scripts entered tracking via the operator's out-of-band commit `6a7d3655`, so the Stage-5 pathspec ships
  the 9 re-adapted loaders as MODIFICATIONS plus ONE new file (`rungs/journal/bcs_rung_shadow_check.exs`),
  not a first whole-dir add; `4_4` rides unmodified. The record's §5 flip landed as the one Status sentence
  with the P-7 tallies, and the Status block's role parenthetical was amended `(PENDING)` →
  `(SHIPPED 2026-06-13)` by the Stage-4 ruling (it sits in the record's living Status block, which the
  flip itself already edits — an internal contradiction, not a frozen-account line).

## Invariants

- **EMQ.0-INV1** — strict compiles hold: `mix compile --warnings-as-errors` exits 0 per app (echo_wire,
  echo_mq, echo_store, echo_data) and the umbrella `mix compile` stays clean (the root compile is viable —
  the mercury_cms phantom dep is fixed, Stage-1c).
- **EMQ.0-INV2** — the D7 hard law + the toolchain law: umbrella-wide `mix test` is NEVER run (the frozen
  v1 suite hangs); every test/coverage command is per-app-scoped and `TMPDIR=/tmp`-prefixed; the toolchain
  is RE-PROBED before the first gate (`asdf current erlang` — the pinned `28.5.0.1` is installed as of
  Stage-1c) instead of hardcoding a version prefix, and a toolchain switch implies a full rebuild before
  any gate.
- **EMQ.0-INV3** — suite duality: the default per-app run is wire-free and green (helpers exclude
  `:valkey`); the `--include valkey` run is green against 6390 with the probed precondition
  `redis-cli -p 6390 ping` → `PONG`; wire tests use per-test sub-queue names + the baseline purge idiom
  (the `Conformance` purge pattern, `conformance.ex:271-275`).
- **EMQ.0-INV4** — the rung gates re-PASS on the as-landed tree: 3_1..3_5 and 4_1..4_4 each end `PASS n/n`
  and the NEW shadow rung ends `PASS 4/4`, via `mix run --no-compile --no-deps-check --no-start rungs/...`
  from the echo root, compile gates first (the record's D9 + §3.6 as-built flags stand); 3_6 stays
  conditional — its stand-in is EMQ.0-D6's `{:ok, 14}` test (ratified Q1).
- **EMQ.0-INV5** — the diff fence: the rung's writes are EXACTLY the D9–D11 import manifest (the echo_wire
  app; the three moved lib files + `resp_test.exs` leaving echo_mq; the two shadow files + the litestream
  behaviour delta; the two `mix.exs` adaptations + the new app's `mix.exs`; the 9 re-adapted loaders + the
  new shadow rung) plus the four test trees, the optional coverage keys, and the record's §5 line. Zero
  OTHER production-lib edits; `apps/echomq` untouched entirely; `apps/echo_data/lib` untouched; no other
  umbrella app touched.
- **EMQ.0-INV6** — the lock fence: `echo/mix.lock`'s delta stays the recorded exqlite-only insertion —
  re-checked under the new app (`echo_wire`'s `deps: []` adds no hex edge); any further movement is a
  STOP-and-report fork (the record's D10/Q2 ruling).
- **EMQ.0-INV7** — process law: no agent runs a git mutation (the record's D8); the Director commits by
  pathspec (one commit, full pivot — the Stage-1b F-PKG ruling); the Operator commits out-of-band (watch
  for `AM`-status files).
- **EMQ.0-INV8** — assertion honesty: every assertion derives from the as-built source (no-invent); no
  fake-100% — a module whose refusal paths are unreachable without deferred runtime is reported partially
  covered with the reason.
- **EMQ.0-INV9** — the namespace law: `EchoMQ.RESP`, `EchoMQ.Connector`, `EchoMQ.Script` keep their module
  names under `apps/echo_wire/lib/echo_mq/` (committed records and articles cite them — the drop's frozen
  rule), `EchoWire` is the facade and the only `EchoWire*` module, and ZERO call sites change anywhere in
  the umbrella (the relocation moves files, never renames modules — `echo_mq`'s and `echo_store`'s
  `alias EchoMQ.{...}` lines compile unchanged through the new dep edge).

## Definition of Done

- [ ] EMQ.0-D9/D10/D11 imported exactly per the manifest; `mix compile --warnings-as-errors` green in all
      four apps + the umbrella root; the INV5 read-only diff check shows only the manifest's paths.
- [ ] EMQ.0-D5/D6 suites on disk in the four test trees; the three floor files byte-unmodified and green
      (`resp_test.exs` relocated, content unchanged).
- [ ] EMQ.0-INV1..INV4 ladder run end-to-end with outputs reported: per-app strict compiles + umbrella
      compile, per-app pure suites, per-app `--include valkey` suites (incl. `{:ok, 14}`), rung gates
      3_1..3_5 + 4_1..4_4 + the shadow rung all `PASS n/n`.
- [ ] EMQ.0-D7 coverage report delivered per module, partials reasoned (Litestream named).
- [ ] EMQ.0-INV5/INV6/INV9 verified on the tree (read-only `git status`/`git diff`; lock delta unchanged;
      zero call-site renames).
- [ ] EMQ.0-D8: the record's §5 status flipped; `echo/rungs/` tracking noted for the Director's pathspec
      commit.
- [ ] Platform runnable: the umbrella compiles clean; the portal release surface untouched.

Carried forward (Stage-4, for the next Mars pass — production code sits outside the evaluator's edit
fence): a doc-comment on `EchoStore.Ring.stats/1` recording that the stats snapshot is assembled from
independent reads (counters → occupancy → the synchronizing `:max_batch` call), so a quiescence poll over
it must predicate on the SETTLED COUNTER values the assertions need, never on the occupancy gauge alone —
the gauge and the counters are not one atomic read (the L-3/P-7 torn-snapshot mechanism; the library
semantics — monotonic counters, eventually-consistent snapshot — stand as acceptable for an observability
surface).

Stories: [`./emq.0.stories.md`](emq.0.stories.md) · Agent brief: [`./emq.0.llms.md`](emq.0.llms.md) ·
Roadmap: [`../emq.roadmap.md`](../../emq.roadmap.md) · Design: [`../emq.design.md`](../../emq.design.md) ·
Approach: [`../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md)
