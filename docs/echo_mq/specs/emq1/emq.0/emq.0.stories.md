# EMQ.0 · user stories

> **Superseded — the Shadow subsystem is retired.** The stories below pin Movement 0 as imported, including
> the cache's pluggable `Shadow` behaviour and `Shadow.Copy`. That subsystem has since been retired
> ([`../../store/design/store.design.md`](../../../store/design/store.design.md) §2) — the app renamed `echo_store`,
> durable replicated state moved to the native `EchoStore.Graft` engine streamed to Tigris, and the Shadow
> modules and tests deleted. The shadow stories are import history, not the current acceptance surface.

## EMQ.0-US1 — the bus's pure surfaces pinned

As an umbrella developer consuming the 2.0 bus, I want the pure surfaces of the bus app's six `EchoMQ.*`
modules pinned by a per-app ExUnit suite, so that a regression in the grammar, a guard, or the scenario
registry fails a cheap wire-free gate before anything touches an engine.

Acceptance criteria
- Given `apps/echo_mq/test/`, when `TMPDIR=/tmp mix test` runs from that app, then the run is green with
  `:valkey` excluded, and the suite exercises per the §5 map: `Keyspace`'s grammar (`queue_key/2`,
  `job_key/2` raising `ArgumentError` on a non-branded id, `reserve/1`,
  `version_key/0 == "{emq}:version"`, `prefix_bytes/2`, the committed vector `slot("123456789") == 12_739`,
  one-queue family slot equality, `hashtag/1` braced/empty/no-brace cases); `Jobs`/`Lanes` argument guards
  (`claim` `lease_ms > 0`, `browse` `n > 0`, `lane_key!` refusal via any verb with a non-branded group);
  `Consumer.child_spec/1` map fields; `Conformance.scenarios/0` returning the 14 names in run order (the
  list pinned).
- Given the migrated floor, when the suite lands, then `keyspace_test.exs` is byte-unmodified and still
  green (the wire trio's floor file, `resp_test.exs`, lives in `apps/echo_wire/test/` after the relocation —
  EMQ.0-US7).

INVEST — independent of the wire; testable by a default per-app run; encodes EMQ.0-INV2, EMQ.0-INV5,
EMQ.0-INV8.
Priority: must · Size: 3 · Implements deliverables: EMQ.0-D5.

## EMQ.0-US2 — the cache and the stores pinned

As an umbrella developer, I want EchoStore's pure surfaces and the additive `EchoData.Bcs*` stores covered
in their own apps' test trees, so that the near-cache and the BCS stores do not ship to production untested
(the record's ratified Q3 ground).

Acceptance criteria
- Given `apps/echo_store/test/`, when the per-app pure run executes, then it covers per the §5 map:
  `Ring` (the best pure M2 suite — collecting `apply_fn`, `publish/2`, order across drains, `occupancy/1`,
  `:dropped` at capacity, edge-triggered wakes ≤ published, `stats/1` keys, `stop/1` erasing the
  persistent_term, init refusals `capacity < 2` / non-1-arity `apply_fn`); `EchoStore`/`Directory`
  (`tables/0 == []` before ensure, `spec/1 :error`, register-then-read, owner-death DOWN scrub,
  `unregister/1`); `Keyspace` (`key/2` shape, raise on invalid id); `Coherence`'s pure half
  (`payload/2`/`parse/1` round-trip + garbage `:error`, `newer?/2` mint order, `channel/1`/`queue/1`);
  `Journal`'s exqlite side (start refusing a non-branded group, `record/4` seq, `record_many/2` one
  transaction, `mark_enqueued/2`, `stats/1` keys, `last_applied/2` nil-when-unknown, persistence across
  reopen, `compact/1` no-op on an empty applied table); `Litestream.replica_url/2`'s exact shape pinned
  (`tigris://bucket/prefix/group?endpoint=…&region=…`).
- Given `apps/echo_data/test/bcs/` (new files only — no existing echo_data file edited), when the echo_data
  per-app run executes, then `Bcs` (`gate/2` ok/namespace/invalid, `gate!/2` raising `NamespaceError`
  naming both namespaces, `ArgumentError`), `PropertyStore` (gated put/get, `:not_found`, `page_desc/2`
  newest-first, `window/3` `[lo, hi)`, `placement/1`, `record_entity/2` silent gate), `Archetypes`
  (right-most-wins compose with `:extends` stripped, root-first `resolve/3`, `{:error, :cycle}`,
  `{:error, :depth}` at the 8-bundle ceiling, fetch error propagation), `EdgeStore`
  (link/unlink/props/from/to/degree, both ends gated, ascending with `limit`), and `Supervisor` (named
  PropertyStores from `{name, ns}` pairs; a killed child restarts under `:one_for_one`) are green, and the
  pre-existing echo_data suite stays green beside them.

INVEST — independent of the wire; testable by two per-app runs; encodes EMQ.0-INV2, EMQ.0-INV5,
EMQ.0-INV8.
Priority: must · Size: 5 · Implements deliverables: EMQ.0-D5, EMQ.0-D3 (proves the stores).

## EMQ.0-US3 — the wire-bound surfaces behind the tag

As the Director accepting Movement 0, I want every wire-bound surface in the extended map exercised by
`:valkey`-tagged suites that the default run excludes, so that wire behavior is provable on demand without
making the default suite engine-dependent.

Acceptance criteria
- Given Valkey live on 6390 (`redis-cli -p 6390 ping` → `PONG`), when
  `TMPDIR=/tmp mix test --include valkey` runs per app, then the tagged suites are green per the extended
  map — in `apps/echo_wire/test/`: `Connector` (the fence claimed-or-verified — `{emq}:version` =
  `echomq:2.0.0`, fatal mismatch; `command/pipeline` ordering; `eval/5` EVALSHA-first incl. the cold-cache
  `SCRIPT FLUSH`-then-eval load-and-retry; `push_command/2` → `{:error, :requires_resp3}` on a
  `protocol: 2` connection; `stats/1` counter names; `wire_version/0`; PLUS the three added verbs —
  `noreply_pipeline/3` answering `:ok` with replies suppressed wire-side, `transaction_pipeline/3`
  answering `{:ok, exec_replies}` under MULTI/EXEC, `subscribe/2` on a RESP3 connection) and the `EchoWire`
  facade proven live (one command and one pipeline through the facade); in `apps/echo_mq/test/`: `Jobs`
  (enqueue/duplicate/`{:error, :kind}` EMQKIND; claim token mint; complete `:ok`/`{:error, :gone}`/
  `{:error, :stale}`; retry `:scheduled`/`:dead` + `last_error`; promote; reap; browse newest-first;
  `pending_size`; `enqueue_many/3` verdicts in input order); `Lanes` (grouped enqueue, strict ring
  rotation, pause/resume, `limit/4` ceiling parks + complete reopens, `depth/3`); `Consumer` end-to-end
  (handler `:ok` completes; a raising handler → typed retry survives the loop; `stop/2` drains and answers
  after DOWN); `Pool` (`size/1`; round-robin distribution asserted via per-member `stats/1` counters); in
  `apps/echo_store/test/`: `Coherence`'s wire half (`drop_l2/4` newer-deletes/stale-keeps/
  short-frame-deletes; `broadcast/4` receiver count; `enqueue/5` rides Lanes); `Table` (fetch
  `:hit`/`:l2`/`:fill` + counters; the single-flight herd — N concurrent fetches, loader called once,
  `coalesced` counted; `{:error, :kind}`; `put/3`+`put/4`; `apply_coherence/4` `:applied`/`:stale`
  idempotence; `invalidate/3`; sweep reclaims; full-table pass-through `full_skips`;
  `coherence: :broadcast` end-to-end across two table instances; `stats/1`); `Journal`'s wire half
  (`intend_and_enqueue/4`; `replay/2` `%{replayed: _, deduplicated: _}`; `apply_and_remember/4`
  `:remembered_stale` vs newer-passes-through; `handler/2` over a Consumer).
- Given any wire test, when it runs, then it uses a per-test sub-queue name and the baseline purge idiom
  (the `Conformance` purge pattern), and the shared `{emq}:version` mutation test runs `async: false` with
  snapshot/restore in `on_exit`.

*As-built (Stage-4 sync, the D-10-ratified placement deviation):* the Connector suite and the facade-live
test listed above under `apps/echo_wire/test/` LIVE IN `apps/echo_mq/test/` (`connector_test.exs`,
`echo_wire_live_test.exs`) — the dependency-free wire app's own run cannot resolve
`EchoMQ.Keyspace.version_key/0` at fence time, so no connection is reachable from echo_wire's suite;
every assertion named above ships unchanged, placement only. Consequently `apps/echo_wire/test/` carries
ZERO `:valkey`-tagged tests and its `--include valkey` run is tag-vacuous (see the EMQ.0-AS3 vacuity note
in the agent brief).

INVEST — independent per surface; testable by the tagged per-app runs; encodes EMQ.0-INV3, EMQ.0-INV2.
Priority: must · Size: 8 · Implements deliverables: EMQ.0-D6.

## EMQ.0-US4 · EMQ.0-US-GATE — the Valkey gate, specification by example

As the Operator, I want the ratified Q1 stand-in — `EchoMQ.Conformance.run/2 → {:ok, 14}` as a
`:valkey`-tagged test — plus honest-row reporting, so that the migration's hard gate closes without the
deferred rival rig and every engine claim stays phrased against the truth row.

Acceptance criteria
- Given Valkey on 6390, when the tagged conformance test runs, then `Conformance.run/2` returns
  `{:ok, 14}` — the fourteen-scenario harness (rung 3_6's C1–C2 bus-only content, without the rival).
- Given the pinned `scenarios/0` list, when compared to the as-built module, then the 14 names match in
  run order (fence · mint · duplicate · kind · order · claim · stale · complete · retry · dead · reap ·
  rotate · pause · limit).
- Given a host without Valkey on 6390, when the wire suites are attempted, then the precondition probe
  fails loudly and the report names the missing engine — results on any substitute engine are reported as
  that row, never as the truth row.

INVEST — small and standing (the design §7 per-rung twin); testable by one tagged run;
encodes EMQ.0-INV3, EMQ.0-INV4.
Priority: must · Size: 2 · Implements deliverables: EMQ.0-D6.

## EMQ.0-US5 — coverage reported, never padded

As the Director, I want per-module coverage numbers from per-app `--cover` runs with partials reported and
reasoned, so that acceptance reads real numbers (the no-fake-100% law).

Acceptance criteria
- Given the suites green, when `TMPDIR=/tmp mix test --cover` runs per app (`--include valkey` where the
  app has wire suites), then the report lists per-module numbers; a pure-only undershoot on
  `Connector`/`Table` is reported as such, never padded.
- Given `EchoStore.Litestream`, when its coverage is reported, then it is named partially covered with the
  reason (the runtime demands the deferred binary; `replica_url/2` + the behaviour exports are the
  reachable surface — the record §7).
- Given the optional `test_coverage: [summary: [threshold: 0]]` keys, when added to the new apps'
  `mix.exs`, then `--cover` reports without gating at Mix's default 90 — the gate stays suites-green.

INVEST — independent of new test content; testable by the cover runs' output; encodes EMQ.0-INV8,
EMQ.0-INV2.
Priority: should · Size: 2 · Implements deliverables: EMQ.0-D7.

## EMQ.0-US6 — the ladder re-proven, the movement closed

As the Operator, I want the full gate ladder re-run green end-to-end over the as-landed tree and the
closure surfaces flipped, so that Movement 0 closes as a verifiable claim — deliverables D1–D4 re-proven
under the D9–D11 re-shape, the record flipped, the rungs tracked.

Acceptance criteria
- Given the import and the suites on disk, when the ladder runs in order (toolchain re-probe; per-app
  strict compiles for echo_wire, echo_mq, echo_data, echo_store + the umbrella compile; per-app pure
  suites; per-app `--include valkey` suites; then
  `mix run --no-compile --no-deps-check --no-start rungs/...` from the echo root), then rungs 3_1..3_5 end
  `PASS 5/5 · 5/5 · 6/6 · 8/8 · 6/6`, 4_1..4_4 end `PASS 6/6` each, the NEW shadow rung ends `PASS 4/4`,
  and a FAIL line is reported verbatim, never band-tuned (derive-before-measure).
- Given the re-adapted dual-path loaders, when the 9 self-loading rungs run, then each resolves the wire
  trio from `apps/echo_wire/lib/echo_mq/` (the first arm), and no rung script names the frozen v1 app's
  directory (EMQ.0-D11's re-spelled fallback).
- Given the run complete, when the tree is inspected read-only (`git status`/`git diff`), then only the
  D9–D11 manifest paths, the test trees, the optional `mix.exs` keys, and the record's §5 line changed
  (EMQ.0-INV5), `echo/mix.lock` carries no further movement (EMQ.0-INV6), and zero call sites renamed
  (EMQ.0-INV9).
- Given closure, when the record is read, then §5's status reads COMPLETE (the one-line flip, the record
  otherwise untouched) and the report notes `echo/rungs/` for the Director's pathspec commit — no agent
  ran git (EMQ.0-INV7).

INVEST — the closing story, dependent on US1–US5 + US7–US8; testable by the ladder's tails + a read-only
tree inspection; encodes EMQ.0-INV1, EMQ.0-INV4, EMQ.0-INV5, EMQ.0-INV6, EMQ.0-INV7.
Priority: must · Size: 3 · Implements deliverables: EMQ.0-D8, EMQ.0-D11 (re-proves EMQ.0-D1, EMQ.0-D2,
EMQ.0-D4).

## EMQ.0-US7 — the wire layer extracted, frozen names intact

As a worked consumer's author (codemojex's client surface is `EchoMQ.Connector` via `EchoWire`), I want the
wire layer landed as its own dependency-free app with the
`EchoWire` facade in front and the `EchoMQ.*` module names frozen, so that new consumers hold one front-door
name while every committed record's citation stays valid.

Acceptance criteria
- Given the import, when `apps/echo_wire` is inspected, then it carries `lib/echo_mq/{resp,script,connector}.ex`
  byte-identical to the files that left `apps/echo_mq`, `lib/echo_wire.ex`, the dependency-free `mix.exs`
  (`deps: []`; `extra_applications: [:logger, :crypto]`), and the relocated `resp_test.exs` — and
  `apps/echo_mq/lib/echo_mq/` no longer contains the three files (EMQ.0-INV9: a move, never a rename).
- Given `apps/echo_wire/test/`, when the pure suite runs, then it covers: the RESP codec floor
  (`resp_test.exs` byte-unmodified, green); `Script.new/2`'s lowercase-hex SHA1 + field set; the facade's
  delegated surface (`function_exported?/3` true for `command/3`, `pipeline/3`, `noreply_pipeline/3`,
  `transaction_pipeline/3`, `eval/5`, `push_command/3`, `subscribe/2`, `stats/1`, `start_link/1`) and
  `EchoWire.script/2` returning the same `%EchoMQ.Script{}` as `Script.new/2`.
- Given the umbrella, when `mix compile --warnings-as-errors` runs per app, then `echo_mq` and `echo_store`
  compile unchanged through their new `{:echo_wire, in_umbrella: true}` edges (zero call-site edits), and
  `mix deps.get` produces NO lock movement (EMQ.0-INV6 — the wire app is dependency-free).

*As-built (Stage-4 sync, the D-10-ratified deviations — see the spec body's EMQ.0-D9 note):*
`connector.ex` lands with the `defp send_pipe/5` block relocated below the last `handle_call` clause
(the one strict-compile-forced delta; `resp.ex`/`script.ex`/`resp_test.exs` byte-identical as stated),
and the `mix.exs` carries `elixirc_options: [no_warn_undefined: [EchoMQ.Keyspace]]` + the permitted
coverage key beside the stated `deps: []` and `extra_applications`. The pure suite additionally carries
the Stage-3-authored `resp_extend_test.exs` (RESP 42.37 → 93.22; the echo_wire pure run is 18 tests).

INVEST — independent of the cache; testable by the per-app compile + pure run + a read-only tree check;
encodes EMQ.0-INV9, EMQ.0-INV6, EMQ.0-INV1.
Priority: must · Size: 5 · Implements deliverables: EMQ.0-D9, EMQ.0-D5 (the wire app's suites).

## EMQ.0-US8 — the journal's shadow, pluggable and proven

As a cache-layer author (the cache's durable edge is `EchoStore.Journal` under a pluggable
`EchoStore.Shadow`), I want the shadow subsystem imported and its
contract proven — the behaviour, the laptop `Copy` implementation, `Litestream` conforming — so that the
journal's box-loss posture runs on a development machine with zero binaries and zero credentials.

Acceptance criteria
- Given `apps/echo_store/test/`, when the pure suite runs, then it covers `EchoStore.Shadow` (the
  dispatcher: `start_link(:none)` → `:ignore`; `restore(:none)` → `{:ok, :no_replica}`; `child_spec/1`
  both arms — the `:none` transient self-start map vs the `{mod, opts}` permanent worker; dispatch through
  a test stub implementing the behaviour) and `EchoStore.Shadow.Copy` (SQLite-bound, wire-free:
  `restore/1`'s three arms — live-file-exists → `{:ok, :no_replica}`, replica-missing →
  `{:ok, :no_replica}`, copy-back → `{:ok, :restored}`; `replica_path/2`'s shape; `start_link` +
  forced `sync/1` with `syncs` counting; `status/1` keys `db`/`dir`/`every_ms`/`syncs`/`last_error`; the
  cycle — rows written, one sync, the live file deleted, restore answers `:restored`, the row count
  survives exactly; the restore-if-missing law both directions; a second sync follows new rows; snapshot
  no-op when the live file is absent), plus the Litestream behaviour conformance (`function_exported?/3`
  for `start_link/1`, `restore/1`, `status/1`, `stop/1`) beside the `replica_url/2` pin.
- Given the compiled umbrella, when
  `mix run --no-compile --no-deps-check --no-start rungs/journal/bcs_rung_shadow_check.exs` runs from the
  echo root, then it ends `PASS 4/4` (SH1 contract · SH2 copy cycle · SH3 the law · SH4 follow) with no
  Valkey and no credentials.

INVEST — independent of the wire suites; testable by one pure run + one rung gate;
encodes EMQ.0-INV4, EMQ.0-INV5, EMQ.0-INV8.
Priority: must · Size: 5 · Implements deliverables: EMQ.0-D10, EMQ.0-D5 (the shadow suites).

---
Coverage: D1→US6 · D2→US6 · D3→US2 · D4→US6 · D5→US1, US2, US7, US8 · D6→US3, US4 · D7→US5 · D8→US6 ·
D9→US7 · D10→US8 · D11→US6.
Spec: [`./emq.0.md`](emq.0.md).
