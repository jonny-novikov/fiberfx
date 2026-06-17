# EMQ.0 · agent brief (llms)
> Implementation brief for the build agent (Mars: the delta importer + the test-writer seat). References,
> traced requirements, the import manifest, the execution topology, and a paste-ready prompt. Pairs with the
> spec [`./emq.0.md`](emq.0.md) (deliverables D1–D11, invariants INV1–INV9) and the stories
> [`./emq.0.stories.md`](emq.0.stories.md). Framing clause (propagates into every derived prompt):
> third person for any agent reference; no gendered pronouns for agents; no perceptual or interior-state
> verbs for agents or software; components read, compute, refuse, return — never observe, want, or notice.

## References

- [`./emq.0.md`](emq.0.md) — the contract (D1–D4 recorded · D9–D11 the import · D5–D8 the proof; INV1–INV9).
- [`./emq.0.stories.md`](emq.0.stories.md) — acceptance (US1–US8, incl. the standing EMQ.0-US-GATE).
- As-built production trees (derive every assertion from these — the no-invent law): after the import,
  `echo/apps/echo_wire/lib/` (`echo_mq/{resp,script,connector}.ex` + `echo_wire.ex`),
  `echo/apps/echo_mq/lib/echo_mq/` (6 modules), `echo/apps/echo_cache/lib/echo_cache/` (9 files;
  `Directory` nested at `echo_cache.ex:41`), `echo/apps/echo_data/lib/echo_data/bcs.ex` + `bcs/`.
- [`../emq.design.md`](../../emq.design.md) §6 (the grammar, for Keyspace expectations) · §1 S-4 (honest-row
  reporting). [`../emq.roadmap.md`](../../emq.roadmap.md) — the movement frame; the Exchange platform
  (`docs/exchange/exchange.roadmap.md` §Where-this-starts) lists EchoWire + the pluggable Shadow in its
  as-built starting inventory — this import completes that inventory.
- Existing test floor: `resp_test.exs` (relocates to `apps/echo_wire/test/`), `keyspace_test.exs`
  (stays in `apps/echo_mq/test/`), `coherence_test.exs` (stays in `apps/echo_cache/test/`) — all three
  byte-unmodified and green; helpers read `ExUnit.start(exclude: [:valkey])` (the new echo_wire helper is
  ADAPTED to the same line — the drop's is bare `ExUnit.start()`).

## The import manifest (EMQ.0-D9/D10/D11 — execute FIRST, before any test authoring)

Modes per the record's §3/§4 style: "byte-identical" = copy/move with no edit; "ADAPTED" = exactly the named
delta. `DROP = /Users/jonny/dev/jonnify/docs/echo/code/src/echo`, `ECHO = /Users/jonny/dev/jonnify/echo`.
Verified this stage: the drop's three wire modules + `resp_test.exs` are byte-identical to production's
current copies, so the production action is a FILE MOVE (filesystem `mv` — no git command; the Director's
pathspec commit records the rename).

**E. The wire app (new dir `ECHO/apps/echo_wire/` — EMQ.0-D9):**

| Source | Destination (ECHO) | Mode |
|---|---|---|
| `ECHO/apps/echo_mq/lib/echo_mq/resp.ex` | `apps/echo_wire/lib/echo_mq/resp.ex` | MOVED (byte-identical == `DROP/apps/echo_wire/lib/echo_mq/resp.ex`) |
| `ECHO/apps/echo_mq/lib/echo_mq/script.ex` | `apps/echo_wire/lib/echo_mq/script.ex` | MOVED (byte-identical == drop) |
| `ECHO/apps/echo_mq/lib/echo_mq/connector.ex` | `apps/echo_wire/lib/echo_mq/connector.ex` | MOVED (byte-identical == drop — the enhanced connector is ALREADY this file: `noreply_pipeline/3` :110, `transaction_pipeline/3` :115, `subscribe/2` :104) |
| `ECHO/apps/echo_mq/test/resp_test.exs` | `apps/echo_wire/test/resp_test.exs` | MOVED (byte-identical == drop) |
| `DROP/apps/echo_wire/lib/echo_wire.ex` | `apps/echo_wire/lib/echo_wire.ex` | byte-identical (the facade: defdelegate `start_link/1`, `command/3`, `pipeline/3`, `noreply_pipeline/3`, `transaction_pipeline/3`, `eval/5`, `push_command/3`, `subscribe/2`, `stats/1` → `EchoMQ.Connector`; `script/2` → `EchoMQ.Script.new/2`) |
| `DROP/apps/echo_wire/mix.exs` | `apps/echo_wire/mix.exs` | byte-identical (`EchoWire.MixProject`; `app: :echo_wire`; version `"2.0.0"`; umbrella keys already correct; `extra_applications: [:logger, :crypto]`; **`deps: []` — dependency-free, zero lock implication**) |
| `DROP/apps/echo_wire/test/test_helper.exs` | `apps/echo_wire/test/test_helper.exs` | ADAPTED: the drop's bare `ExUnit.start()` becomes `ExUnit.start(exclude: [:valkey])` (the record's D13) |

*As-built (Stage-4 sync — manifest E executed with two D-10-ratified deviations, both forced by the
drop's never-strict-compiled state):* the `connector.ex` row landed with the `defp send_pipe/5` block
relocated below the last `handle_call` clause (the only diff vs the drop, 16 lines, pure reordering); the
`mix.exs` row landed with `elixirc_options: [no_warn_undefined: [EchoMQ.Keyspace]]` (`mix.exs:18`) plus
the permitted `test_coverage: [summary: [threshold: 0]]` key beside the stated properties. The echo_wire
test tree additionally carries `resp_extend_test.exs` — AUTHORED by the Stage-3 harden pass (not an
import): the §5 RESP row's full RESP2/3 surface pinned, coverage 42.37 → 93.22, the pure suite 8 → 18.

**F. The bus app re-shape (`ECHO/apps/echo_mq/` — EMQ.0-D9):**

| File | Mode |
|---|---|
| `lib/echo_mq/{resp,script,connector}.ex` + `test/resp_test.exs` | REMOVED by the moves above — `lib/echo_mq/` keeps exactly `{conformance,consumer,jobs,keyspace,lanes,pool}.ex` (all six byte-identical to the drop's post-move `DROP/apps/echo_mq/lib/echo_mq/`, verified) |
| `mix.exs` | ADAPTED: deps become `[{:echo_data, in_umbrella: true}, {:echo_wire, in_umbrella: true}]`; `extra_applications` drops `:crypto` → `[:logger]` (the `:crypto` need lives in `Script`, which moves — the drop's post-move echo_mq says `[:logger]`, echo_wire carries `[:logger, :crypto]`). **The project module stays `EchoMq.MixProject`** — the record §3.6 collision exception SURVIVES: the drop's renamed `EchoMQ.MixProject` still collides with the frozen v1 `apps/echomq/mix.exs` module in production |

**G. The cache shadow (`ECHO/apps/echo_cache/` — EMQ.0-D10):**

| Source (DROP) | Destination (ECHO) | Mode |
|---|---|---|
| `apps/echo_cache/lib/echo_cache/shadow.ex` | same rel. path | byte-identical (the behaviour: callbacks `start_link/1`, `restore/1` — RESTORE-IF-MISSING by law, `status/1`, `stop/1`; the pure dispatcher: `start_link(:none)` → `:ignore`, `restore(:none)` → `{:ok, :no_replica}`, `child_spec/1` both arms) |
| `apps/echo_cache/lib/echo_cache/shadow/copy.ex` | same | byte-identical (the laptop shadow: `VACUUM INTO` snapshots via `Exqlite.Sqlite3` — NO wire, NO sidecar binary, NO credentials; `sync/1`, `status/1`, module-level `restore/1`, `replica_path/2`, periodic `:tick` re-arm, tmp-then-rename) |
| `apps/echo_cache/lib/echo_cache/litestream.ex` | same | REPLACED with the drop copy — verified ADDITIVE-ONLY delta: `@behaviour EchoCache.Shadow` + four `@impl EchoCache.Shadow` lines; zero functional change |
| `apps/echo_cache/mix.exs` | same | ADAPTED: deps gain `{:echo_wire, in_umbrella: true}`. **Do NOT copy the drop's dep list**: its `{:echomq, in_umbrella: true}` atom is a recorded drop SOURCE DEFECT (no `:echomq` app exists in the drop anymore); production's `{:echo_data}` + `{:echo_mq}` + `{:exqlite, "0.23.0"}` stand |
| `rungs/journal/bcs_rung_shadow_check.exs` | `ECHO/rungs/journal/bcs_rung_shadow_check.exs` | byte-identical (a compiled-module rung like 4_4 — aliases only, no self-loading; gates SH1..SH4; needs NO Valkey, NO credentials; its frozen `.out` stays in the drop per D5 — expected tail `PASS 4/4`) |

**H. The dual-path loaders (`ECHO/rungs/` — EMQ.0-D11):**

The 9 self-loading rungs (bus 3_1..3_6, cache 4_1..4_3) re-adapt their wire-file loader to the drop's
dual-path form — echo_wire FIRST:

```text
for f <- ~w(resp script keyspace connector) do            # (the cache rungs' file lists vary; keep each drop list)
  Code.require_file(Enum.find([
    Path.expand("../../apps/echo_wire/lib/echo_mq/#{f}.ex", __DIR__),
    Path.expand("../../apps/echo_mq/lib/echo_mq/#{f}.ex", __DIR__)   # ← the ONE delta from the drop text:
  ], &File.exists?/1))                                               #   fallback re-spelled apps/echomq/ → apps/echo_mq/
end
```

The drop's fallback arm spells `apps/echomq/` — a vestige of its own pre-rename tree; in production that
literal would name the FROZEN v1 app's directory (probed: v1 has no `lib/echo_mq/`, so the arm is dead
today, but production rung scripts must not name the v1 dir at all). Note `keyspace.ex` lives in echo_mq
and resolves through the FALLBACK arm by design — the `Enum.find` runs per file. Every assertion,
derivation string, and gate line stays byte-identical to the drop's current rung text; the loader line(s)
and the stale header comment are the only deltas (the record's D12 discipline, extended).
`bcs_rung_4_4_check.exs` stays byte-identical (no loader; already identical to the drop).
NOT imported (out of scope, surfaced): `DROP/rungs/bus/bcs_rung_busobjects_check.*`,
`DROP/rungs/canon/bcs_rung_serialization_check.*`, the referee family, `DROP/apps/lab` (its new
`echo_wire` dep edge is recorded; D6 deferral stands).

**Lock check after the import:** `cd ECHO && mix deps.get` — echo_wire's `deps: []` adds no hex edge; the
`mix.lock` delta stays the recorded exqlite-only insertion (INV6). Any movement = STOP and report.

## Requirements

- **EMQ.0-R9** — the import manifest E + F executed exactly; per-app strict compiles green afterward
  (echo_wire, echo_mq, echo_cache, echo_data + the umbrella root); zero call-site edits anywhere
  (INV9 — the moves never rename modules). [US: EMQ.0-US7]
- **EMQ.0-R10** — the import manifest G executed exactly; the shadow rung lands; the litestream delta is
  the verified additive behaviour conformance and nothing else. [US: EMQ.0-US8]
- **EMQ.0-R11** — the import manifest H executed exactly: 9 loaders re-adapted (echo_wire-first; the
  fallback re-spell), 4_4 untouched; rungs 3_1..3_5 + 4_1..4_3 still PASS after the re-adaptation.
  [US: EMQ.0-US6]
- **EMQ.0-R1** — pure ExUnit suites in `apps/echo_mq/test/` covering the pure column of the six bus-module
  rows in the lifecycle map; `keyspace_test.exs` unmodified. [US: EMQ.0-US1]
- **EMQ.0-R2** — pure suites in `apps/echo_cache/test/` covering the pure column of every cache row
  INCLUDING the extension rows (the Shadow dispatcher; the Copy suite; the Litestream behaviour
  conformance beside the `replica_url/2` pin). [US: EMQ.0-US2, EMQ.0-US8]
- **EMQ.0-R3** — NEW files only under `apps/echo_data/test/bcs/` covering the five `EchoData.Bcs*` rows;
  no existing echo_data file edited; the pre-existing echo_data suite stays green. [US: EMQ.0-US2]
- **EMQ.0-R12** — pure suites in `apps/echo_wire/test/` covering the wire-trio pure column (the relocated
  `resp_test.exs` floor; `Script.new/2`; the facade's delegated surface via `function_exported?/3` +
  `EchoWire.script/2` ≡ `Script.new/2`). [US: EMQ.0-US7]
- **EMQ.0-R4** — `:valkey`-tagged suites covering the wire column of every row — the Connector suite
  (incl. the three Stage-1c verbs: `noreply_pipeline/3` → `:ok` replies-suppressed,
  `transaction_pipeline/3` → `{:ok, exec_replies}`, `subscribe/2` on RESP3) and one facade-live test in
  `apps/echo_wire/test/`; Jobs/Lanes/Consumer/Pool in `apps/echo_mq/test/`; Coherence-wire/Table/
  Journal-wire in `apps/echo_cache/test/`; per-test sub-queue names; the baseline purge idiom
  (`KEYS emq:{<q>}:*` → `DEL`, the `Conformance.purge/2` pattern, `conformance.ex:271-275`); the
  `{emq}:version` mutation test `async: false` with snapshot/restore in `on_exit`. [US: EMQ.0-US3]
- **EMQ.0-R5** — the standing gate test: `:valkey`-tagged `EchoMQ.Conformance.run/2 → {:ok, 14}` on a
  sub-queue family, plus the pure pin of `scenarios/0`'s 14 names in run order. [US: EMQ.0-US4]
- **EMQ.0-R6** — per-app `--cover` runs (`--include valkey` where wire suites exist); per-module numbers
  in the report; partials reasoned (Litestream); MAY add `test_coverage: [summary: [threshold: 0]]` to the
  new apps' `mix.exs` only. [US: EMQ.0-US5]
- **EMQ.0-R7** — the gate ladder re-run end-to-end (the command block in the prompt — the record's §6
  EXTENDED by the echo_wire gates and the shadow rung); the record's §5 status flipped PENDING → COMPLETE
  (one line; the record otherwise untouched); the report notes `echo/rungs/` for the Director's pathspec
  commit. [US: EMQ.0-US6]
- **EMQ.0-R8** — standing laws over every step: per-app test commands only (umbrella `mix test` BANNED —
  D7); `TMPDIR=/tmp` on every test command; the TOOLCHAIN RE-PROBE opens the run (`asdf current erlang` —
  the pinned `28.5.0.1` is installed as of Stage-1c; do NOT hardcode a version prefix; a toolchain switch
  since the last build implies a full rebuild before any gate); Valkey precondition
  `redis-cli -p 6390 ping` → `PONG` before any wire step; the INV5 diff fence (the manifest + test trees +
  the optional keys + the record's one line — nothing else); `apps/echomq` untouched; lock delta
  exqlite-only (INV6); no git mutation (INV7). [US: all]

## Execution topology

Runtime (from the record §3.4/§4.4 + the Stage-1c delta — drive tests accordingly):

```text
No supervision tree in any new app (library-only, no mod:).
echo_wire:  RESP/Script = pure modules; Connector = caller-started GenServer (start_link/1; named only when
            :name passed); EchoWire = pure delegation facade over Connector + Script.
echo_mq:    Consumer = caller-started spawn_link loop, NOT a GenServer (child_spec/1 map; control at settle points)
            Pool = caller-started Supervisor over N Connectors (:persistent_term + :atomics dispatch)
            Keyspace/Jobs/Lanes/Conformance = pure modules (Jobs/Lanes/Conformance compose Connector calls)
echo_cache: Table = GenServer; init STARTS ITS OWN Connector (table.ex:207) → init refusals testable only with a live wire
            Directory = lazily-ensured NAMED singleton (monitors owners; DOWN scrubs) → async: false where touched
            Ring = GenServer applier + :persistent_term; single-producer BY STRUCTURE (publish from one process)
            Journal = GenServer per group; exqlite WAL under :dir (fresh System.tmp_dir!() subdir, removed in on_exit)
            Shadow = behaviour + PURE dispatcher (no process of its own; :none starts nothing)
            Shadow.Copy = caller-started GenServer (Exqlite VACUUM INTO; NO wire, NO binary; module-level restore/1
            needs no process); Litestream = deferred runtime; replica_url/2 + the behaviour exports reachable
echo_data:  Bcs pure; PropertyStore/EdgeStore = caller-started GenServers (private ETS); Bcs.Supervisor caller-started
Snowflake bootstrap: per-app `mix test` starts :echo_data whose Application runs Snowflake.start();
            start/1 is idempotent — a setup_all `EchoData.Snowflake.start(4)` is safe either way.
Hazards bank: GenServers that raise in init (Ring refusals; Journal non-branded group) exit the caller —
            trap exits + assert, never bare-match start_link; named singletons (EchoCache.Directory,
            EchoData.Bcs.Supervisor children) force async: false; the fence-mismatch test MUTATES shared
            {emq}:version — async: false + snapshot/restore in on_exit; Copy's periodic :tick is timing —
            drive determinism through forced sync/1, never timer waits (init KeyError on missing :db/:dir);
            the IMPORT precedes every gate — after the move both loader fallback arms are dead, so a rung
            run before the echo_wire dir exists raises on Code.require_file(nil).
```

Tasks (each step leaves every app compiling; compile gates precede any rung gate):

```text
T0 toolchain re-probe + preconditions → T1 AS6 (the import: manifests E+F+G+H + deps.get lock check)
→ T2 AS1 (echo_mq pure) → T3 AS2 (cache pure + bcs) → T4 AS7 (echo_wire pure) → T5 AS8 (shadow suites)
→ T6 AS3 (:valkey suites + the stand-in) → T7 AS4 (coverage + report)
→ T8 AS5 (the full gate ladder + the §5 flip + the closure note)
```

Touched files (the complete set — anything else is an INV5 violation): the manifest E/F/G/H paths;
`apps/echo_wire/test/*_test.exs` + `apps/echo_mq/test/*_test.exs` + `apps/echo_cache/test/*_test.exs` +
`apps/echo_data/test/bcs/*_test.exs` (new); optionally the `test_coverage:` key in the new apps' `mix.exs`;
and ONE line of `docs/echo/migration/echo2-migration.md` (the §5 status flip).

## The lifecycle map (echo2-migration.md §5, ported verbatim — the assertion source; cite that section per module)

NOTE the Stage-1c placements: the `RESP`/`Script`/`Connector` rows now test in `apps/echo_wire/test/`;
everything else as placed in the topology above.
*As-built (Stage-4 sync, D-10):* the `Connector` row's WIRE column tests in `apps/echo_mq/test/connector_test.exs`
(with the facade-live test `echo_wire_live_test.exs` beside it) — echo_wire's own run cannot reach the
wire (`EchoMQ.Keyspace` unresolvable at fence time from a `deps: []` app); the `Connector` row's pure
guard-level column and the `RESP`/`Script` rows test in `apps/echo_wire/test/` as stated.

| Module | Shape | Pure-surface testable | Wire-bound (`:valkey`) |
|---|---|---|---|
| `EchoMQ.RESP` | pure codec | encode iodata shape; parse every RESP2/3 type incl. `{:error_reply, _}`, `{:push, _}`, map/set/double (`inf`/`-inf`/`nan`)/bignum/verbatim/bool/null; `:incomplete` continuation on split frames; `{:error, :bad_resp}` on unknown lead; `nil` for `$-1`/`*-1` | — |
| `EchoMQ.Script` | pure struct | `new/2` lowercase-hex SHA1 of source; field set | — |
| `EchoMQ.Keyspace` | pure | `queue_key/2` grammar; `job_key/2` raises `ArgumentError` on non-branded id and composes on valid; `reserve/1`; `version_key/0 == "{emq}:version"`; `prefix_bytes/2`; `slot("123456789") == 12_739` (the committed vector, `keyspace.ex:41`); one-queue family slot equality; `hashtag/1` braced/empty/no-brace cases | — |
| `EchoMQ.Connector` | caller-started GenServer | guard-level only | fence claimed-or-verified (`{emq}:version` = `echomq:2.0.0`, fatal mismatch); `command/pipeline` ordering; `eval/5` EVALSHA-first incl. cold-cache (`SCRIPT FLUSH` then eval — the load-and-retry mapping, `connector.ex:84-88`); `push_command/2` → `{:error, :requires_resp3}` on a `protocol: 2` connection; `stats/1` counter names; `wire_version/0` |
| `EchoMQ.Jobs` | pure over conn | argument guards (`claim` `lease_ms > 0`, `browse` `n > 0`) | enqueue/duplicate/`{:error, :kind}` (EMQKIND); claim token mint; complete `:ok`/`{:error, :gone}`/`{:error, :stale}`; retry `:scheduled`/`:dead` + `last_error`; promote; reap; browse newest-first; `pending_size`; `enqueue_many/3` verdicts in input order |
| `EchoMQ.Lanes` | pure over conn | `lane_key!` refusal via any verb with a non-branded group → `ArgumentError` | grouped enqueue; strict ring rotation; pause/resume; `limit/4` ceiling parks + complete reopens; `depth/3` |
| `EchoMQ.Consumer` | caller-started loop (NOT a GenServer) | `child_spec/1` map fields | end-to-end: handler `:ok` completes; raising handler → typed retry survives the loop; `stop/2` drains and answers after DOWN |
| `EchoMQ.Pool` | caller-started Supervisor | — | `size/1`; round-robin `command/3` distributing across members (assert via per-member `stats/1` commands counters) |
| `EchoMQ.Conformance` | pure + wire | `scenarios/0` returns the 14 names in run order (pin the list) | `run/2` → `{:ok, 14}` against 6390 — **the strongest single integration test; mirrors rung 3_6's C2 without the rival** |
| `EchoCache` / `.Directory` | module + lazy GenServer | `tables/0 == []` before ensure; `spec/1 :error`; `Directory.register/3` then `tables/0`/`spec/1`; owner-death DOWN scrubs the entry; `unregister/1` | — |
| `EchoCache.Keyspace` | pure | `key/2` shape; raise on invalid id | — |
| `EchoCache.Coherence` | pure + wire | `payload/2`/`parse/1` round-trip + garbage `:error`; `newer?/2` mint-order across namespaces; `channel/1`/`queue/1` shapes | `drop_l2/4` newer-deletes/stale-keeps/short-frame-deletes; `broadcast/4` receiver count; `enqueue/5` rides Lanes |
| `EchoCache.Ring` | caller-started GenServer + persistent_term | **the best pure M2 suite, no wire:** `start_link` with a collecting `apply_fn`; `publish/2` `:ok`; order preserved across drains; `occupancy/1`; `:dropped` + counted at capacity; edge-triggered wake (stats `wakes` ≤ `published`); `stats/1` keys incl. `max_batch`/`capacity`; `stop/1` erases the persistent_term; init refusals (`capacity < 2`, non-1-arity `apply_fn`) | — |
| `EchoCache.Table` | caller-started GenServer (starts its own Connector in `init` — `table.ex:207`) | init refusals are testable ONLY with a live wire (init connects first) — so: none pure | `fetch/3` `:hit`/`:l2`/`:fill` sources + counters; single-flight herd (N concurrent fetches, loader called once — `coalesced` counter); `{:error, :kind}` wrong-namespace; `put/3` (mints version of table kind) and `put/4`; `apply_coherence/4` `:applied`/`:stale` idempotence; `invalidate/3`; sweep reclaims expired; full table degrades to pass-through (`full_skips`); `coherence: :broadcast` end-to-end (a second table instance drops its L1 row on a `Coherence.broadcast`); `stats/1` |
| `EchoCache.Journal` | caller-started GenServer (exqlite, NO wire needed for the intents side) | start refuses non-branded `group` (`ArgumentError`); `record/4` returns seq; `record_many/2` one transaction, seq list; `mark_enqueued/2`; `stats/1` (`intents`/`pending_enqueue`/`remembered`/`path`); `last_applied/2` nil when unknown; persistence across stop + reopen of the same dir/group; `compact/1` retires nothing with an empty applied table | `intend_and_enqueue/4` outbox verb; `replay/2` `%{replayed: _, deduplicated: _}` counts; `apply_and_remember/4` `:remembered_stale` without touching the table vs newer passes through (needs a live Table); `handler/2` over a Consumer |
| `EchoCache.Litestream` | deferred runtime (record §7) | `replica_url/2` exact shape (`s3://bucket/prefix/group?endpoint=…&region=…`) — pure, pin it; nothing else (init demands the binary) | — |
| `EchoData.Bcs` | pure | `gate/2` `{:ok, snow}`/`{:error, :namespace}`/`{:error, :invalid}`; `gate!/2` raises `NamespaceError` (message names both namespaces) and `ArgumentError` | — |
| `EchoData.Bcs.PropertyStore` | caller-started GenServer (private ordered_set ETS) | `put/get` gated both ways; `get` `:not_found`; `page_desc/2` newest-first walk; `window/3` `[lo, hi)` with gated bounds; `placement/1` `{:ok, hash32}`/`{:error, :invalid}`; `record_entity/2` cast gated silently | — |
| `EchoData.Bcs.Archetypes` | pure | `compose/2` right-most-wins + `:extends` stripped; `resolve/3` root-first chain through a fetch fun; `{:error, :cycle}`; `{:error, :depth}` at the 8-bundle ceiling; fetch error propagation | — |
| `EchoData.Bcs.EdgeStore` | caller-started GenServer (fwd+rev ETS) | `link/unlink/props/from/to/degree`; both ends gated; `unlink`/`props` `:not_found`; `from`/`to` ascending with `limit` | — |
| `EchoData.Bcs.Supervisor` | caller-started Supervisor | starts named PropertyStores from `{name, ns}` pairs; a killed child restarts (`:one_for_one`) | — |

**THE EXTENSION ROWS (Stage-1c — derived from the deep diff; same map discipline, same no-invent law):**

| Module | Shape | Pure-surface testable | Wire-bound (`:valkey`) |
|---|---|---|---|
| `EchoWire` (facade) | pure delegation module | the delegated surface present — `function_exported?/3` true for `command/3`, `pipeline/3`, `noreply_pipeline/3`, `transaction_pipeline/3`, `eval/5`, `push_command/3`, `subscribe/2`, `stats/1`, `start_link/1`; `EchoWire.script/2` returns the same `%EchoMQ.Script{}` as `Script.new/2` | one happy-path `command/3` and one `pipeline/3` THROUGH the facade against 6390 (delegation proven live) |
| `EchoMQ.Connector` — the Stage-1c verbs (EXTENDS the row above) | — | — | `noreply_pipeline/3` answers `:ok` with replies suppressed wire-side (`CLIENT REPLY OFF .. ON` — `connector.ex:110`, doc line :109); `transaction_pipeline/3` answers `{:ok, exec_replies}` under MULTI/EXEC (`:115`); `subscribe/2` `:ok` on a RESP3 connection (`:104`; rides the push path — `{:error, :requires_resp3}` on `protocol: 2`) |
| `EchoCache.Shadow` | behaviour + PURE dispatcher | `start_link(:none)` → `:ignore`; `restore(:none)` → `{:ok, :no_replica}`; `child_spec(:none)` = the transient self-start map vs `child_spec({mod, opts})` = the permanent worker `{mod, :start_link, [opts]}`; dispatch `start_link/1` + `restore/1` through a test stub module implementing the behaviour | — |
| `EchoCache.Shadow.Copy` | caller-started GenServer (Exqlite `VACUUM INTO`; NO wire, NO binary) | module-level `restore/1` three arms (live-file-exists → `{:ok, :no_replica}`; replica-missing → `{:ok, :no_replica}`; copy-back → `{:ok, :restored}`, never overwriting a live file); `replica_path/2` = `Path.join(dir, Path.basename(db))`; `start_link(db:, dir:, every_ms:)` + forced `sync/1` (the `syncs` counter moves); `status/1` keys `db`/`dir`/`every_ms`/`syncs`/`last_error`; the SH2 cycle — rows written, one forced sync, the live file deleted, restore answers `:restored`, the row count survives exactly; the SH3 law — restore over a live file answers `:no_replica` and leaves it byte-identical, restore with nothing behind answers `:no_replica` and writes nothing; the SH4 follow — a second sync after more rows carries them; snapshot is a no-op when the live file is absent; `init` raises `KeyError` on missing `:db`/`:dir` | — |
| `EchoCache.Litestream` — the behaviour (EXTENDS the row above) | + `@behaviour EchoCache.Shadow` | behaviour conformance: `function_exported?/3` true for `start_link/1`, `restore/1`, `status/1`, `stop/1` (the SH1 shape — `Code.ensure_loaded!/1` first) | — |

**Coverage expectation** (record §5, verbatim in substance): every public function exercised on its happy
path AND each refusal/guard path named above; per-module numbers from
`cd ECHO/apps/<app> && TMPDIR=/tmp mix test --cover` (`--include valkey` where wire suites exist); a
pure-only `--cover` run legitimately undershoots on `Connector`/`Table` — report it, never pad; a module
whose refusal paths are unreachable without the deferred runtime (Litestream) is reported partially covered
with the reason.

## Agent stories

- **EMQ.0-AS6** [implements EMQ.0-US7, EMQ.0-US8 — the import halves] — Directive: execute the import
  manifest E + F + G + H in order, then `mix deps.get` from ECHO. Acceptance gate: per-app
  `mix compile --warnings-as-errors` exits 0 in echo_wire, echo_mq, echo_cache, echo_data AND the umbrella
  root compiles clean; the lock delta is still exqlite-only; read-only `git status` shows exactly the
  manifest's paths; zero `EchoMQ.`-alias call-site edits anywhere (INV9).
- **EMQ.0-AS1** [implements EMQ.0-US1] — Directive: author the pure echo_mq suites per the map (Keyspace,
  Jobs/Lanes guards, `Consumer.child_spec/1`, the `scenarios/0` pin); leave `keyspace_test.exs` untouched.
  Acceptance gate: `cd echo/apps/echo_mq && TMPDIR=/tmp mix test` green, 0 failures, `:valkey` excluded.
- **EMQ.0-AS2** [implements EMQ.0-US2] — Directive: author the pure cache suites (Ring, Directory,
  Keyspace, Coherence-pure, Journal-pure, the `replica_url/2` pin) and the NEW `apps/echo_data/test/bcs/`
  suites (Bcs, PropertyStore, Archetypes, EdgeStore, Supervisor). Acceptance gate: per-app
  `TMPDIR=/tmp mix test` green in echo_cache AND echo_data (existing echo_data suite still green);
  read-only `git status` on `apps/echo_data` shows only new `test/bcs/` paths.
- **EMQ.0-AS7** [implements EMQ.0-US7] — Directive: author the echo_wire pure suites (the relocated
  `resp_test.exs` untouched as the floor; `script_test.exs`; `echo_wire_facade_test.exs` per the extension
  row). Acceptance gate: `cd echo/apps/echo_wire && TMPDIR=/tmp mix test` green, `resp_test.exs`
  byte-unmodified.
- **EMQ.0-AS8** [implements EMQ.0-US8] — Directive: author the shadow suites per the extension rows
  (`shadow_test.exs` — the dispatcher + a stub impl; `shadow_copy_test.exs` — the full Copy surface;
  the Litestream behaviour-conformance assertions beside the URL pin). Acceptance gate: the echo_cache
  pure run green; then (post-compile) the shadow rung:
  `mix run --no-compile --no-deps-check --no-start rungs/journal/bcs_rung_shadow_check.exs` ends `PASS 4/4`.
- **EMQ.0-AS3** [implements EMQ.0-US3, EMQ.0-US4] — Directive: author the `:valkey`-tagged suites per the
  map's wire column — Connector (incl. the three Stage-1c verbs) + the facade-live test in
  `apps/echo_wire/test/`; Jobs, Lanes, Consumer, Pool in `apps/echo_mq/test/`; Coherence-wire, Table,
  Journal-wire in `apps/echo_cache/test/`; plus the standing gate test `Conformance.run/2 → {:ok, 14}`;
  per-test sub-queues + the purge idiom; the fence-mutation test `async: false` + snapshot/restore.
  Acceptance gate: with `redis-cli -p 6390 ping` → `PONG`, per-app `TMPDIR=/tmp mix test --include valkey`
  green in echo_wire, echo_mq, and echo_cache.
  *As-built VACUITY NOTE (Stage-4, D-10):* with the Connector suite and the facade-live test placed in
  `apps/echo_mq/test/` (the ratified deviation — echo_wire's own run cannot reach the wire),
  `apps/echo_wire/test/` carries ZERO `:valkey`-tagged tests, so this gate's "green in echo_wire" clause
  is VACUOUSLY satisfied — the echo_wire `--include valkey` run exercises no wire assertion (it re-runs
  the 18 pure tests). The clause was flagged pre-build and confirmed as-built; the wire proof for the
  Connector and the facade is the echo_mq tagged run. A future re-balance (inlining the `"{emq}:version"`
  constant beside `@wire_version`, or moving `version_key/0` into echo_wire) is the SEAM carried to
  emq.1's design gate (ledger D-10).
- **EMQ.0-AS4** [implements EMQ.0-US5] — Directive: run the per-app cover commands; assemble the
  per-module coverage table; reason every partial; optionally add the `test_coverage:` keys. Acceptance
  gate: the report carries per-module numbers for all four apps; Litestream named partial with the reason;
  no number padded.
- **EMQ.0-AS5** [implements EMQ.0-US6] — Directive: re-run the gate ladder end-to-end (the prompt's
  command block, in order); flip the record's §5 status line PENDING → COMPLETE; note `echo/rungs/` for
  the Director's pathspec commit. Acceptance gate: rungs 3_1..3_5 end `PASS 5/5·5/5·6/6·8/8·6/6`,
  4_1..4_4 end `PASS 6/6` each, the shadow rung ends `PASS 4/4`; read-only `git status` shows only the
  permitted paths changed; no git mutation was run.

## Execution plan — first two stories

1. **EMQ.0-AS6 — the import.** Toolchain re-probe (`asdf current erlang`); execute manifests E → F → G → H
   (filesystem moves + copies + the named `mix.exs` edits); `mix deps.get` from ECHO; gate: four per-app
   strict compiles + the umbrella compile + the exqlite-only lock check + the read-only tree check.
2. **EMQ.0-AS1 — echo_mq pure.** Read each remaining lib module before asserting on it; author
   `test/{jobs_guards_test,lanes_guards_test,consumer_spec_test,conformance_scenarios_test}.exs`; gate:
   the per-app pure run green with `keyspace_test.exs` untouched.

## Comprehensive implementation prompt

```text
ROLE: Mars, the importer + test-writer seat of rung emq.0 (Movement 0 completion, scope expanded at the
Stage-1b checkpoint). Build ONLY what docs/echo_mq/specs/emq.0.md defines (D9–D11 the import; D5–D8 the
proof) — the spec body is authoritative; this brief derives from it.
FRAMING: third person for agents; no gendered pronouns for agents; no perceptual/interior-state verbs for
agents or software; components read, compute, refuse, return.

LAWS (inviolable, from the record's §2 + §9 and the spec's INV1–INV9):
- TOOLCHAIN: open with `asdf current erlang` (+ `asdf current elixir`). The pinned erlang 28.5.0.1 is
  INSTALLED as of Stage-1c — do NOT hardcode any ASDF_ERLANG_VERSION prefix. If the resolved toolchain
  differs from the last build's, run a full rebuild (per-app `mix deps.compile` + `mix compile`) BEFORE
  any gate; a stale _build under a switched toolchain produces phantom failures.
- NEVER run umbrella-wide `mix test` from the echo root (D7 — the frozen v1 suite hangs). Per-app only;
  every test command carries TMPDIR=/tmp.
- Wire precondition before any :valkey step: `redis-cli -p 6390 ping` → PONG
  (if down: `valkey-server --port 6390 --daemonize yes --save ''`; never pkill — exact pids only).
- NO git mutation of any kind (D8). Read-only `git status` / `git diff` are permitted for the INV checks.
  File moves are filesystem mv — the Director's pathspec commit records them.
- Touch ONLY: the import manifest E/F/G/H paths (this brief); new test files under apps/echo_wire/test/,
  apps/echo_mq/test/, apps/echo_cache/test/, apps/echo_data/test/bcs/; optionally the one test_coverage:
  key in the new apps' mix.exs; ONE status line in docs/echo/migration/echo2-migration.md
  (§5 PENDING → COMPLETE, last step). Anything else = STOP.
- apps/echomq is FROZEN — read nothing into assertions from it, edit nothing in it, and no rung loader
  names its directory (the manifest-H fallback re-spell).
- mix.lock must not move (echo_wire is dependency-free; exqlite is already recorded). Any resolver
  movement = STOP and report.
- NAMESPACE LAW (INV9): the moves relocate FILES, never rename MODULES — EchoMQ.RESP/Connector/Script
  keep their names under apps/echo_wire/lib/echo_mq/; zero alias/call-site edits anywhere; EchoWire is
  the only new module name.
- Derive every assertion from the as-built source files (no-invent). The assertion source per module is
  this brief's lifecycle map + THE EXTENSION ROWS (echo2-migration.md §5, ported verbatim, extended at
  Stage-1c from the deep diff). Read the module before testing it.
- No fake coverage: report partials with reasons (Litestream: the runtime demands the deferred binary;
  replica_url/2 + the behaviour exports are the reachable surface). A FAIL rung line is reported
  verbatim, never band-tuned.

HAZARDS (banked — design tests around them):
- The IMPORT precedes everything: until manifest E lands, the re-adapted loaders' echo_wire arm does not
  exist and Code.require_file(Enum.find(...)) would receive nil — import first, compile, only then rungs.
- The fence-mismatch test mutates the SHARED {emq}:version key: async: false, snapshot in setup, restore
  in on_exit.
- GenServers that raise in init (Ring's capacity < 2 / non-1-arity apply_fn; Journal's non-branded group;
  Copy's missing :db/:dir KeyError) exit the caller: trap exits and assert, never bare-match start_link.
- Named singletons (EchoCache.Directory; EchoData.Bcs.Supervisor's named PropertyStores) force
  async: false in any suite that touches them.
- Copy's periodic :tick is timing-dependent — drive every snapshot through the forced sync/1; never
  assert on timer-fired ticks. Copy's restore/1 is module-level (no process needed). Use a fresh
  System.tmp_dir!() subdir per test, removed in on_exit (the Journal discipline).
- Wire tests: per-test sub-queue names + the baseline purge idiom (KEYS emq:{<q>}:* → DEL — the
  Conformance.purge/2 pattern, conformance.ex:271-275).
- Table init connects first: its refusal paths are wire-only; no pure Table test exists.
- Snowflake: a setup_all `EchoData.Snowflake.start(4)` is safe (idempotent canon start).
- Consumer is NOT a GenServer (spawn_link loop; control at settle points) — drive it via its public verbs.

TASK ORDER (each step leaves every app compiling):
T0  Toolchain re-probe; 6390 PONG probe.
T1  AS6 THE IMPORT — manifest E (the echo_wire app: 4 file moves + 2 copies + the adapted helper),
    F (echo_mq mix.exs: + {:echo_wire, in_umbrella: true}, extra_applications → [:logger]; module name
    EchoMq.MixProject UNCHANGED), G (shadow.ex + shadow/copy.ex copies; litestream.ex replaced —
    additive behaviour delta only; echo_cache mix.exs + {:echo_wire}; the shadow rung script copied),
    H (9 loaders re-adapted dual-path, fallback re-spelled apps/echo_mq/; 4_4 untouched);
    then `cd ECHO && mix deps.get` + the exqlite-only lock check + four per-app strict compiles + the
    umbrella compile + the read-only tree check.
T2  AS1 echo_mq pure suites (Keyspace, Jobs/Lanes guards, Consumer.child_spec/1, the scenarios/0 pin:
    fence, mint, duplicate, kind, order, claim, stale, complete, retry, dead, reap, rotate, pause, limit).
T3  AS2 echo_cache pure suites + apps/echo_data/test/bcs/ suites (NEW files only).
T4  AS7 echo_wire pure suites (resp_test floor untouched; script_test; the facade delegation suite).
T5  AS8 the shadow suites (Shadow dispatcher + stub; the full Copy surface; the Litestream behaviour
    conformance beside the replica_url/2 pin).
T6  AS3 :valkey-tagged suites (the wire columns + the three Stage-1c connector verbs + the facade-live
    test) + the standing gate test: @tag :valkey Conformance.run/2 → {:ok, 14}.
T7  AS4 coverage runs + the per-module report (optionally add the test_coverage: keys).
T8  AS5 the full gate ladder (below) + the record's §5 one-line flip + the closure note (echo/rungs/ is
    tracked at the Director's pathspec commit, not by this agent).

THE GATE LADDER (the record §6, extended by Stage-1c: + echo_wire gates, + the shadow rung; run in this
order, compile gates strictly first; commands are copy-pasteable from a clean shell after the T0 probe):

  # compile gates
  cd /Users/jonny/dev/jonnify/echo/apps/echo_wire  && mix compile --warnings-as-errors
  cd /Users/jonny/dev/jonnify/echo/apps/echo_mq    && mix compile --warnings-as-errors
  cd /Users/jonny/dev/jonnify/echo/apps/echo_data  && mix compile --warnings-as-errors
  cd /Users/jonny/dev/jonnify/echo/apps/echo_cache && mix compile --warnings-as-errors
  cd /Users/jonny/dev/jonnify/echo                 && mix compile   # umbrella root stays clean (mercury fixed)

  # unit gates (per-app — NEVER umbrella-wide, D7)
  cd /Users/jonny/dev/jonnify/echo/apps/echo_wire  && TMPDIR=/tmp mix test
  cd /Users/jonny/dev/jonnify/echo/apps/echo_mq    && TMPDIR=/tmp mix test
  cd /Users/jonny/dev/jonnify/echo/apps/echo_cache && TMPDIR=/tmp mix test
  cd /Users/jonny/dev/jonnify/echo/apps/echo_data  && TMPDIR=/tmp mix test

  # integration gates (Valkey on 6390 probed first)
  cd /Users/jonny/dev/jonnify/echo/apps/echo_wire  && TMPDIR=/tmp mix test --include valkey
  cd /Users/jonny/dev/jonnify/echo/apps/echo_mq    && TMPDIR=/tmp mix test --include valkey
  cd /Users/jonny/dev/jonnify/echo/apps/echo_cache && TMPDIR=/tmp mix test --include valkey

  # coverage (report-only; the gate is suites-green)
  cd /Users/jonny/dev/jonnify/echo/apps/echo_wire  && TMPDIR=/tmp mix test --cover --include valkey
  cd /Users/jonny/dev/jonnify/echo/apps/echo_mq    && TMPDIR=/tmp mix test --cover --include valkey
  cd /Users/jonny/dev/jonnify/echo/apps/echo_cache && TMPDIR=/tmp mix test --cover --include valkey
  cd /Users/jonny/dev/jonnify/echo/apps/echo_data  && TMPDIR=/tmp mix test --cover

  # rung gates (D9 + §3.6 as-built flags; dev env; the compile gates above must have run)
  cd /Users/jonny/dev/jonnify/echo
  mix run --no-compile --no-deps-check --no-start rungs/bus/bcs_rung_3_1_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/bus/bcs_rung_3_2_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/bus/bcs_rung_3_3_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/bus/bcs_rung_3_4_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/bus/bcs_rung_3_5_check.exs
  # 3_6: CONDITIONAL — needs the deferred rigs/oban_bench + PostgreSQL (ratified Q1); its stand-in is the
  # :valkey Conformance.run/2 → {:ok, 14} test, which T6 ships and the integration gate above runs.
  mix run --no-compile --no-deps-check --no-start rungs/cache/bcs_rung_4_1_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/cache/bcs_rung_4_2_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/cache/bcs_rung_4_3_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/journal/bcs_rung_4_4_check.exs
  mix run --no-compile --no-deps-check --no-start rungs/journal/bcs_rung_shadow_check.exs   # NEW (Stage-1c)

  Expected tails: 3_1 PASS 5/5 · 3_2 PASS 5/5 · 3_3 PASS 6/6 · 3_4 PASS 8/8 · 3_5 PASS 6/6 ·
  4_1..4_4 PASS 6/6 each · shadow PASS 4/4 (the drop's frozen .out shows SH1 contract · SH2 copy cycle ·
  SH3 the law · SH4 follow — no Valkey, no credentials). Figures inside detail lines are THIS machine's,
  gated by each rung's printed derived bands; a re-run's stdout is NOT committed as a record (records
  freeze in the drop — D5/D8).

REPORT: the import's tree check (the manifest paths, exactly); per-app suite tallies (pure and
--include valkey); the per-module coverage table with reasoned partials; every rung-gate tail line; the
INV5/INV6/INV9 read-only checks; the §5 flip confirmation; and any STOP fork encountered. Completion claim
only when every DoD box in emq.0.md is checkable from the outputs.
```
