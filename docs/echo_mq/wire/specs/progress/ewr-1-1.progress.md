# ewr-1-1 — AAW scope ledger

The scope ledger for the founding wire rung. Seeded at program-open with the ruled design fork (the `D-n`
decisions and the `V-n` chosen-against arms); the `T-n` / `L-n` / `Y-n` / `Z-n` channels are filled by the
build run. There is **no** `ewr-1-1.registry.json` — the rung is additive above the conformance boundary, so
no conformance scenario is probe-registered.

## {ewr-1-1-thinking} Thinking

### T-1 — SPECCED at program-open; awaiting the build run

The triad ([`../ewr.1/ewr.1.1.md`](../ewr.1/ewr.1.1.md) + stories + brief) is authored forward-tense and
build-grade. The design fork is ruled (Arm A + curated/escape; D-1, D-2 below), so the Stage-1 gate is reachable
with no open Operator fork. The remaining decisions are the implementor's **design-make** (the conn-or-pool
dispatch mechanism, the curated membership, the internal `cmds` representation, placement) — logged here as
`D-n` at the top of the build, before any `.ex`/test artifact. This channel carries the build run's
UNDERSTAND/EXPAND / re-probe / build / gate / reconcile narrative.

## {ewr-1-1-decisions} Decisions

### D-1 — RULED: Arm A (`EchoWire.Pipe`), the threaded pipeline

The API surface fork (Arm A `Pipe` / B `Cmd` / C `Query`) is settled by the Operator as **Arm A** (this
session, recorded against [`../../design/ewr.design.md`](../../design/ewr.design.md) §4). The threaded `%Pipe{}`
accumulator threads through `|>` and `exec/1` is literally `Connector.pipeline/3` over the gathered commands —
the mental model is identical to the connector's own. Decisive reason: A is the **base that keeps both other
arms available** while committing to neither B's speculative flag vocabulary nor C's metaprogramming today (B's
command value layers on as `ewr.1.2`; C's block can later expand to A's functions — not the reverse). Both
review lenses converged (developer-experience A>C>B; spec-steward A≻B≻C). The alternatives keep their best case
in `{ewr-1-1-alternatives}` (V-1, V-2).

### D-2 — RULED: a curated verb set + a generic `Pipe.command/2` escape hatch

The sub-fork inside Arm A (a curated verb set + an escape hatch **vs** a full per-command surface mirroring the
rueidis `gen_*` tree) is settled as **curated + escape**. RULED: a curated set gives discoverability and
idiomatic option handling for the common string/key family, while `command/2` appends any raw `[[binary]]`
command verbatim — so the curated set is convenience and **never a ceiling** (INV6). The full per-command
surface is a large freeze liability with no incremental benefit over curated + escape; it is not built. This is
the binding invariant the triad carries (body D3/D4, INV6).

### D-3 — design-make (FIRST, before any artifact): the conn-or-pool dispatch shape (first-class this rung)

Re-probed the as-built floor (lag-1): connector.ex pipeline/3 :56 · transaction_pipeline/3 :130 · noreply_pipeline/3 :125 · command/3 :47 · eval/5 :63; EchoMQ.Pool.pipeline/3 :48 (round-robin → Connector.pipeline; NO transaction_pipeline/noreply_pipeline — grep 0); resp.ex reply() :30, {:error_reply,_} in-band :47; EchoWire facade lib/echo_wire.ex:19-31 = 11 verbs; conformance_run_test.exs:45 {:ok,52}. All confirmed.

RULED dispatch: new(conn, opts \\ []) stores conn + via + timeout. `via` defaults to EchoMQ.Connector and is set to EchoMQ.Pool for a pool (opts[:via]). exec/1 = via.pipeline(conn, Enum.reverse(cmds), timeout) — dispatches through the module captured in `via`, and its body contains NO is_struct/is_atom/module-name guard on `conn` (INV3: opacity, conn is carried not detected). Both Connector.pipeline/3 (:56) and Pool.pipeline/3 (:48) are signature-identical, so the SAME %Pipe{} flushes against either by swapping `via`. exec_txn/1 → EchoMQ.Connector.transaction_pipeline/3 and exec_noreply/1 → EchoMQ.Connector.noreply_pipeline/3 are called on the Connector module DIRECTLY (not via `via`), because those seams exist only on the Connector and a pool round-robins per command (INV5 — Connector-only, out of contract for a pool).

### D-4 — design-make: the internal cmds representation = prepend-then-reverse-at-exec

cmds is stored newest-first (each private add/2 does %{pipe | cmds: [command_list | pipe.cmds]} — O(1) prepend). The three flush verbs reverse once at flush: Enum.reverse(pipe.cmds) is the call-order [[binary]] handed to the seam. This satisfies D6 (flushed order == call order) without an O(n) append per verb. The empty-pipe guard is `cmds == []` checked in each flush verb BEFORE any reverse/dispatch → {:error, :empty_pipeline} (D6; the connector's own guard already rejects [], but Pipe answers before calling it so the error is the Pipe's typed one, not a FunctionClauseError). command/2 (the escape hatch) prepends a raw flat command-list verbatim through the same add/2.

### D-5 — design-make: the curated verb membership across the six families (grounded in gen_*.go)

Verb names confirmed against go/valkey-go/internal/cmds/gen_{string,generic,hash,list,set,sorted_set}.go Builder entrypoints. Curated set (each a thin private add/2 of one command-list, options as trailing tokens, returning %Pipe{}):
- strings (gen_string.go): set/3,4 (ex:/px:/nx:/xx:/get:/keepttl: → trailing tokens), get/2, getset/3, getdel/2, mset/2, mget/2, append/3, strlen/2, incr/2, incrby/3, decr/2, decrby/3, incrbyfloat/3, setex/4, setnx/3, getrange/4, setrange/4.
- keys/generic+expiry (gen_generic.go): del/2 (variadic via list), unlink/2, exists/2, expire/3, pexpire/3, expireat/3, pexpireat/3, ttl/2, pttl/2, persist/2, type/2, rename/3, renamenx/3, scan/2,3, touch/2, copy/3.
- hashes (gen_hash.go): hset/4 (+ hset_all/3 for a kv map), hmset/3, hget/3, hmget/3, hgetall/2, hdel/3, hexists/3, hincrby/4, hincrbyfloat/4, hkeys/2, hvals/2, hlen/2, hsetnx/4, hscan/3.
- lists (gen_list.go): lpush/3 (variadic vals), rpush/3, lpop/2,3, rpop/2,3, lrange/4, llen/2, lindex/3, lset/4, lrem/4, linsert/5, ltrim/4, rpoplpush/3, lmove/5.
- sets (gen_set.go): sadd/3 (variadic), srem/3, smembers/2, sismember/3, scard/2, spop/2,3, srandmember/2,3, sunion/2, sinter/2, sdiff/2, smismember/3, sscan/3.
- sorted sets (gen_sorted_set.go): zadd/4 (+ keyword opts nx:/xx:/gt:/lt:/ch: → trailing tokens), zrem/3, zrange/4 (+ withscores:/rev:), zrangebyscore/4, zrevrange/4, zscore/3, zcard/2, zrank/3, zrevrank/3, zincrby/4, zpopmin/2,3, zpopmax/2,3, zcount/4, zscan/3.

DEVIATIONS-from-literal noted: (a) the body lists hset/4 for the single-field form; I add a companion hset_all/3 taking a kv list/map so multi-field HSET is idiomatic (still one command-list; both within the named hash family, escape-hatch makes the boundary non-binding INV6). (b) set's option set adds keepttl: alongside the body's ex:/px:/nx:/xx:/get: (KEEPTTL is a real rueidis SetCondition token; additive within the strings family). Neither grows the facade nor changes a frozen surface; EchoWire.Pipe is NOT arity-frozen (INV1) so per-verb arity is the implementor's design-make (body D3 names verb+family+reference, not a frozen {fun,arity} table).

## {ewr-1-1-alternatives} Alternatives

### V-1 — Arm B: `EchoWire.Cmd`, the command builder (steelmanned, chosen-against)

The alternative the design fork names as B: an immutable `%Cmd{parts, flags}` value built fluently
(`set("k") |> value("v") |> ex(60) |> build()`) and run via `EchoWire.Cmd.run/2` — the faithful Elixir port of
rueidis's `Completed` (`go/valkey-go/internal/cmds/cmds.go:117`) with its bit-packed `cf` flags (cmds.go:5-23).

STEELMAN (real): B makes the **`cf`-flag command model first-class now** — the immutable command value carries
the readonly/block/pipe metadata the connector is missing (it fails in-flight callers `:disconnected` without
replay because it cannot know what is idempotent). For a future retry or cluster-routing layer, that flag
vocabulary is exactly the knowledge needed, and building it into the command value from the start avoids a later
migration.

CHOSEN-AGAINST: the flags have **no consumer yet** — there is no retry/cluster-routing rung — so the flag
vocabulary is speculative surface frozen ahead of need; and B's draft `run/2` would be a 12th verb on the
11-frozen `EchoWire` facade unless rehomed to `EchoWire.Cmd.run/2`. B's *value* is preserved, not discarded: the
immutable command + `cf` model is scheduled as **`ewr.1.2`**, layered onto A's accumulator when a consumer makes
the flags load-bearing (roadmap seam 4).

### V-2 — Arm C: `EchoWire.Query`, the query block (steelmanned, chosen-against)

The alternative the design fork names as C: a `query conn do set "k","v"; get "k" end` macro compiling to one
`Connector.pipeline/3`, with a `transaction conn do … end` companion.

STEELMAN (real): C reads **cleanest for a long linear sequence** — no `|>`, no `new/1`, no `build/1`, no prefix;
the block is the batch. For a reader scanning a ten-command sequence, the macro is the most legible of the three.

CHOSEN-AGAINST: the cost is **metaprogramming** — a macro is harder to ground (NO-INVENT), harder to freeze and
debug, and the readability gain over A's `|>` is marginal for the BCS audience already fluent in pipes. C's block
can later **expand to A's functions** (a macro over `EchoWire.Pipe`), so it stays available as sugar on top of A
without being the foundation. Layerable onto A, not the reverse — the same asymmetry that carried D-1.

## {ewr-1-1-learnings} Learnings

> Consolidated by the Director for Apollo (the Mentor, out of the per-rung pipeline — PROPOSE-ONLY). Each
> guardrail is aimed at the peer whose CONTRACT the finding implicates.

### L-1 — [Venus] a spec that reuses a shared generator must name the tool's scoping semantics

F-1: D8/INV7 directed `mix echo_mq.stories --out docs/echo_mq/wire/stories`, but the task's fixed glob
(`test/stories/*_story_test.exs`) harvests ALL features into one `--out` — so a per-program output dir was not
reproducible by a single command (the as-built tool had no per-program filter). The contract implicated is the
SPEC's. GUARDRAIL (propose to Venus): *when a deliverable reuses an existing generator/script, name its scoping
semantics in the deliverable — if the as-built tool cannot produce the deliverable's claimed artifact from one
command, the tool enhancement is in-scope for the rung, not a silent post-step.* Resolved by the Operator-ruled
`--match` filter (Y-2).

### L-2 — [Mars] a committed generated artifact must reproduce from one command; flag, don't hand-prune

Mars-1 hand-pruned the over-produced bus features out of the wire stories dir, leaving a non-idempotent
artifact (re-gen re-pollutes) — a gate-invisible reproducibility hole the Director caught in Stage-2 (F-1).
GUARDRAIL (propose to Mars): *a committed generated artifact must equal a single documented command's output
byte-for-byte; if you are editing generator output by hand, that is a finding to surface, not a step to
absorb.* Mars-2 then did it right (the `--match` filter → a pure generator output, twice-identical).

### L-3 — [Mars · affirm] the conn-or-pool opacity contract → a carried dispatch module, not a type check

INV3 ("accept conn-or-pool, never inspect it") was realized as `%Pipe{via}` carrying the dispatch module
(default `EchoMQ.Connector`; `EchoMQ.Pool` via opts), `exec = via.pipeline(...)`, with no `is_struct`/`is_atom`
guard. This is the correct Elixir idiom for an opacity contract — carry the behaviour, do not detect the type.
AFFIRM to Mars: propagate this to `ewr.1.2`/`1.3` and any future conn-or-pool surface.

### L-4 — [convention] the "order theorem" mutation proves a positional-reply invariant is not vacuous

INV6's positional-order claim was proven by a net-zero mutation (reverse the accumulator → the cache-aside
story dies, `[-2, nil, "OK"]` vs `["OK","alice",ttl]`), re-run independently by the Director. CONVENTION: for
any "replies map 1:1 in order" invariant, the order-theorem mutation (reverse/drop the accumulator, prove a
test kills it) is the standing proof — carry it forward.

## {ewr-1-1-report} Report

*Awaiting the build run — the stage-by-stage audit record lands here as `Y-n` (Mars build/harden, Director
review gates).*

### Y-1 — Mars-1 Stage-1 build report (ewr.1.1 · EchoWire.Pipe)

DELIVERED to the DoD:
- D1 design-make ledgered FIRST (D-3 dispatch shape, D-4 cmds=prepend-then-reverse, D-5 six-family membership) before any artifact.
- D2/D3/D4: %EchoWire.Pipe{conn, via, timeout, cmds} + new/2; comprehensive curated verbs across the six families (strings/keys+expiry/hashes/lists/sets/sorted-sets) each one add/2 command-list; command/2 escape hatch.
- D5/D6: exec/1 via the opaque via.pipeline/3; exec_txn/1 -> Connector.transaction_pipeline/3; exec_noreply/1 -> Connector.noreply_pipeline/3; positional order (reverse-at-flush); empty pipe -> {:error, :empty_pipeline}.
- D8: 8 EchoMQ.Story :valkey test files by redis-pattern (cache-aside, distributed-lock, reliable-queue, counter, leaderboard, set-membership, hash-object, + conn-or-pool dispatch) each its own setup; mix echo_mq.stories --out docs/echo_mq/wire/stories regenerated.
- INV1 facade=11 verbs (unchanged). INV2 additive: no frozen-lib edit, no echo_mq lib edit, 0 redis.call in lib diff, conformance {:ok,52} byte-stable, mix.lock unchanged. INV3 conn-or-pool opacity proven both ways (StubVia offline + same %Pipe{} flushed against Connector AND Pool on valkey, identical replies; exec body has no reference guard). INV4 exec = one pipeline/3 call. INV5 exec_txn/exec_noreply Connector-only (pool grep 0; proven against Connector). INV6 escape-hatch completeness + positional order. INV7 every generated story has a passing :valkey test (9==9 one-for-one). INV8 the user-stories and generated-stories name the same redis-pattern set, neither forks the body.

GATE: echo_wire compile clean + 44 tests 0 fail (26 construction); echo_mq compile clean + 355 tests 4 doctests 0 fail (--include valkey) + conformance {:ok,52}; order-theorem killed; mutation kill-rate 5/5; multi-seed sweep 5/5 both suites; determinism posture = pure-data, no ≥100 loop.

Handing to the Director for Stage-2 solo review (independent two-app gate re-run on 6390 + adversarial probe + net-zero mutation spot-check). Valkey on 6390 was started by this run for the gate; a spawned agent's node is reaped at turn-end, so the Director should re-confirm 6390 is up (or start: /usr/local/bin/valkey-server --port 6390 --save "" --appendonly no) before the re-run.

### Y-2 — Mars-2 Stage-3 harden: F-1 remediation (wire dir + generator filter)

F-1 (Operator-ruled "wire dir + a generator filter") remediated.

(1) ONE Mix-task edit — echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex: added a `--match <substring>` option. ADDITIVE + backward-compatible: OptionParser strict gains match: :string; load_stories/1 filters the harvested FILE SET by Path.basename containing the substring (matches?/2: nil = all, the default → byte-identical to today); match_note/1 annotates the empty-set message. NO change to write_feature/write_catalogue/render_* — the .stories.md + README FORMAT is byte-identical, only the file set narrows. grep redis.call = 0; the task is build tooling under lib/mix/tasks/, not a runtime/conformance file.

(2) Idempotent wire regen: cleared docs/echo_mq/wire/stories/ and ran `mix echo_mq.stories --match wire_pipe --out <abs docs/echo_mq/wire/stories>` — now a PURE generator output (8 wire-pipe-*.stories.md + a generator-produced README, 9 scenarios / 8 features; no hand-prune). Ran TWICE → byte-identical (diff -r clean): idempotent.

(3) No-regression: `mix echo_mq.stories --out /tmp/stories_check` (no --match) still emits ALL 11 features (21 scenarios) incl. flows/groups/flow-failure — default path unchanged. Each wire-pipe-*.stories.md from --match is byte-identical to the same file from the default full run (only the README feature-set differs, by design). Canonical docs/echo_mq/stories/ byte-unchanged (git status exit 0).

(4) Gate re-run (valkey 6390 PONG): echo_mq compile --warnings-as-errors clean; wire :valkey story suite 9 tests 0 failures; conformance CONFORMANCE 52/52 ({:ok,52}, 3 pin tests 0 fail). echo_wire compile clean; facade-freeze + construction suite 28 tests 0 failures (still 11 verbs). No new id-mint/process → no ≥100 loop (multi-seed posture from Y-1 holds).

Touch-set now: NEW pipe.ex + pipe_test.exs + 8 wire story tests + generated docs/echo_mq/wire/stories/ + the ONE Mix-task edit (echo_mq.stories.ex). mix.lock unchanged; no lib/echo_mq/ runtime edit; no facade edit; frozen lib/echo_mq/ (connector/resp/script) unchanged.

FLAG for the Director's LAW-4 pathspec commit: `echo/README.md` is staged in the index (M , an Operator out-of-band pre-stage — a docs rewrite of the umbrella README, mtime 02:28, unrelated to this rung). It is NOT mine and NOT part of ewr.1.1 — split it out (commit only the rung's pathspec, never git add -A).

## {ewr-1-1-complete} Complete

### Z-1 — ewr.1.1 (EchoWire.Pipe) SHIPPED — the EchoWire client-core program's founding rung, build-grade through the recalibrated Flat-L2 pipeline.

WHAT SHIPPED: **`EchoWire.Pipe`** (`echo/apps/echo_wire/lib/echo_wire/pipe.ex`) — the threaded `|>` pipeline over
the owned wire: a `%Pipe{conn, via, timeout, cmds}` accumulator; a comprehensive curated verb set across the six
Valkey data families (strings · keys/expiry · hashes · lists · sets · sorted sets, grounded in valkey-go
`gen_*.go`); a `command/2` escape hatch; `exec`/`exec_txn`/`exec_noreply` over the `Connector.pipeline/3` family.
Conn-or-pool first-class (dispatch carried opaquely in `via`, never inspected; `exec_txn`/`exec_noreply`
Connector-only). Plus the program canon (`ewr.{roadmap,progress,features,testing,references}.md`), the founding
triad (`ewr.1.1.{md,stories,llms,prompt}`, reconciled SPECCED→BUILT), and a BDD story layer — **9 `EchoMQ.Story`
`:valkey` scenarios** (one per redis-pattern: cache-aside · distributed-lock · reliable-queue · counter ·
leaderboard · set-membership · hash-object · conn-or-pool dispatch) driving the Pipe end-to-end, generated
idempotently to `docs/echo_mq/wire/stories/` via the F-1 `--match wire_pipe` filter.

VERIFICATION (Director-independent, valkey 6390): echo_wire `compile --warnings-as-errors` clean + **44 tests 0
failures** (facade-freeze still **11 verbs**); echo_mq wire `:valkey` story suite **9/0**; conformance
**`{:ok, 52}`** byte-stable; the order-theorem mutation re-KILLED then reverted net-zero; F-1 idempotence
re-proven (committed wire dir == a fresh `--match` gen, byte-for-byte; default path still emits all 11 features).
Frozen-floor: no `lib/echo_mq/` runtime edit, no facade edit, `echo/mix.lock` unchanged, `grep redis.call` = 0.

RULINGS (Operator, via the mandatory `AskUserQuestion` gate): **Arm A** (`EchoWire.Pipe`) [prior session];
**conn-or-pool FIRST-CLASS** this rung; **complete valkey-go-core + redis-patterns via BDD stories**; **F-1 =
wire dir + a generator filter**. Recorded `D-1`..`D-5` + the F-1 ruling; alternatives (arms B/C) keep their
chosen-against case (`V-1`/`V-2`).

LAW-4: one scoped Director pathspec commit — the rung's create-locations (`pipe.ex` + `pipe_test.exs` + the 8
`wire_pipe_*_story_test.exs` + `docs/echo_mq/wire/` {canon · `specs/ewr.1` triad · `specs/progress` ledger ·
generated `stories/`}) + the ONE sanctioned `echo_mq` Mix-task edit (`lib/mix/tasks/echo_mq.stories.ex`).
EXCLUDED as Operator out-of-band pre-stage (NOT this rung): `echo/README.md`, the staged `emq.*` spec edits, and
`memory/`. Pathspec only, never `git add -A`.

## {ewr-1-1-progress} Progress

### P-1 — Stage 1 build complete; full two-app gate battery green

Built EchoWire.Pipe (lib/echo_wire/pipe.ex) to D2-D6 + the offline construction suite (test/echo_wire/pipe_test.exs) + 8 BDD :valkey story files (echo_mq/test/stories/wire_pipe_*) by redis-pattern + the generated docs/echo_mq/wire/stories/ (9 wire-pipe .stories.md + a wire-scoped README).

GATE (TMPDIR=/tmp, Elixir 1.18.4/Erlang 28.5.0.1 re-probed per app, valkey 6390 PONG):
- echo_wire: compile --warnings-as-errors clean (force-recompile too); offline construction suite 26 tests 0 failures; full echo_wire suite 44 tests 0 failures (facade-freeze still 11 verbs, 2 tests green).
- echo_mq: compile --warnings-as-errors clean; full suite --include valkey = 4 doctests, 355 tests, 0 failures; the 9 wire story scenarios green; conformance {:ok,52} byte-stable (CONFORMANCE 52/52, pin tests green).
- INV7 one-for-one: 9 generated wire scenario headings == 9 test-declared scenarios.
- Adversarial battery: order-theorem mutation KILLED (3 failures on reversed accumulator); module mutation kill-rate 5/5 (empty-guard, wrong-token, drop-reverse offline; exec_txn-misroute on valkey; +order). Frozen-floor: grep redis.call on lib diff = 0; no lib/echo_mq or lib/echo_wire.ex edit; mix.lock unchanged; echo_store untouched. INV3 (no conn inspection in exec) + INV4 (exec = one via.pipeline/3 call) + INV5 (pool has 0 transaction_pipeline/noreply_pipeline; exec_txn/exec_noreply call Connector.* directly) structurally verified.
- Determinism posture: NO id-mint/process/lease introduced (Pipe is pure data; story tests open fresh conns/pools but mint no branded ids — key isolation via System.unique_integer). Multi-seed sweep 0/1/42/312540/999999 PASS both suites; ≥100 loop correctly NOT run.

Three realization-over-literal deviations (all within a named family, escape-hatch makes the boundary non-binding INV6, none grows the facade or touches a frozen surface): (1) added hset_all/3 companion for multi-field HSET; (2) added set keepttl: option; (3) wire stories dir pruned to wire-pipe-only + README rewritten because mix echo_mq.stories' fixed glob also harvests the bus features (flows/groups/flow-failure) into one --out — those belong in docs/echo_mq/stories/ and were removed from the wire dir to keep INV2's touch-set wire-scoped.
