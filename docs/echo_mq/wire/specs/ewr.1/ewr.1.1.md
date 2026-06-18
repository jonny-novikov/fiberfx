# EWR.1.1 · EchoWire.Pipe — the threaded pipeline (Movement I, the founding rung)

> **Status: SPECCED** — authored this run, built a later run. The first rung of the EchoWire client-core
> program ([`../../ewr.roadmap.md`](../../ewr.roadmap.md), Movement I). It builds, inside `echo/apps/echo_wire`,
> a new module **`EchoWire.Pipe`** (`lib/echo_wire/pipe.ex`, a directory that does not exist yet) giving
> idiomatic `|>` command-batch construction over the owned wire. A `%Pipe{conn, via, timeout, cmds}`
> accumulator threads through `|>`; a **comprehensive curated verb set across the six Valkey data families**
> appends one command-list each; `exec/1` flushes once through an **opaque conn-or-pool dispatch** into
> `EchoMQ.Connector.pipeline/3` (`echo/apps/echo_wire/lib/echo_mq/connector.ex:56`) or
> `EchoMQ.Pool.pipeline/3` (`echo/apps/echo_mq/lib/echo_mq/pool.ex:48`) without inspecting the reference, with
> `exec_txn/1` / `exec_noreply/1` variants over `transaction_pipeline/3` (:130) / `noreply_pipeline/3` (:125),
> and a generic `Pipe.command/2` escape hatch keeps the curated set from being a ceiling. The rung also
> delivers a **BDD story layer**: a set of `EchoMQ.Story` `:valkey` tests organized by redis-pattern that
> drive `EchoWire.Pipe` end-to-end and generate self-documenting `.stories.md` written back into the wire
> docs. The arm is **ruled** — Arm A of the design fork ([`../../design/ewr.design.md`](../../design/ewr.design.md)),
> carried with the curated-verbs + escape-hatch sub-fork; **conn-or-pool is first-class in this founding rung**
> (the Operator's ruling), not deferred. This rung adopts the rulings and does not re-litigate them. The change
> is **additive by construction**: `EchoMQ.Connector` / `RESP` / `Script` / `Pool` are frozen and reused; the
> `EchoWire` facade stays at its 11 verbs (`lib/echo_wire.ex:19-31`, pinned by `echo_wire_facade_test.exs`); no
> Lua enters the wire; the `echo_mq` 52-scenario conformance (`Conformance.run/2 → {:ok, 52}`,
> `echo/apps/echo_mq/test/conformance_run_test.exs:45`) stays byte-stable — the new layer (Pipe + story tests)
> lives *above* the conformance boundary.

## Goal

`ewr.1.1` builds the wire's **construction surface**: an Elixir-idiomatic way to assemble a Valkey command batch
with `|>` and flush it once, instead of hand-writing a nested `[[binary]]` literal whose positional flags the
caller keeps correct by eye. The connector already pipelines (`send_pipe/5`..`drain/1` interleave concurrent
callers on one socket), so this rung adds **no pipelining** — it adds the *noun* the connector consumes: a
threaded `%Pipe{}` accumulator whose `exec/1` is literally the connector's `pipeline/3` over the commands it
gathered. The reference is the valkey-go (rueidis) fluent builder (`B().Set().Key().Value().Build()`,
`go/valkey-go/internal/cmds/gen_string.go`) reimagined in functional Elixir: the builder's method chain becomes
a `|>` chain, and the connection-level auto-pipelining it pairs with is the connector EchoWire already owns.

## Rationale (5W)

- **Why** — above `Connector.pipeline/3` there is no way to *construct* a command or a batch beyond a
  hand-rolled nested list: `[["SET","user:1","alice","EX","60"], ["GET","user:1"]]`, with the `EX 60` adjacency
  the caller must keep correct by eye. The owned wire does the hard part (one socket, an in-flight FIFO, RESP3
  decode) but offers no assembly ergonomics. The valkey-go client's whole front half is exactly this assembly
  surface; EchoWire has none, and every caller — `echo_mq` internals, `echo_store`'s direct-Valkey paths, app
  code — re-derives the same nested-list discipline by hand.
- **What** — a new module `EchoWire.Pipe` carrying: a `%Pipe{conn, via, timeout, cmds}` struct +
  `new(conn, opts \\ [])` storing the conn **plus an opaque dispatch** (`via`) and a default `timeout`; a
  **comprehensive curated verb set across the six Valkey data families** (strings · keys/expiry · hashes ·
  lists · sets · sorted sets — the principal verbs of each, grounded in valkey-go's generated builders
  `go/valkey-go/internal/cmds/gen_*.go`, each appending one command-list via a private `add/2`, options
  rendered as trailing tokens); a generic **`command/2` escape hatch** (appends a raw command-list verbatim);
  and three **flush verbs** — `exec/1` → the opaque `via.pipeline/3` (a `Connector` *or* a `Pool`),
  `exec_txn/1` → `transaction_pipeline/3`, `exec_noreply/1` → `noreply_pipeline/3`. The rung **also** ships a
  **BDD story layer** (`EchoMQ.Story` `:valkey` tests organized by redis-pattern that drive `Pipe` end-to-end
  and generate `.stories.md`). The exact curated membership and the dispatch shape are finalized at the
  design-make (D1); the escape hatch makes the set's boundary non-binding.
- **Who** — every Elixir caller assembling Valkey batches. The immediate consumers are `echo_mq`'s own command
  sites and `echo_store`'s direct-Valkey paths; the deployment targets are the `EchoMQ.Connector` **and** the
  `EchoMQ.Pool`, and **both are first-class in this founding rung** (the Operator's ruling — conn-or-pool
  opacity is delivered now, not deferred): the same `%Pipe{}` flushes against either, the Pipe never inspecting
  the reference. No downstream rung gates by name on `ewr.1.1` — it is the program's floor; `ewr.1.2` (the
  command value) and `ewr.1.3` (the error split) layer onto it.
- **When** — Movement I, rung 1, now: the design fork is ruled (Arm A) and the floor is as-built and frozen.
  It precedes `ewr.1.2`/`1.3` because both extend the surface this rung founds (B's flags enrich the
  accumulator; the error split wraps `exec`'s return).
- **Where** — the **module + pure tests live in `echo_wire`**: `echo/apps/echo_wire/lib/echo_wire/pipe.ex` (a
  **new** module; `lib/echo_wire/` does not exist yet) + a new `test/echo_wire/pipe_test.exs`. The **BDD story
  tests live in `echo_mq`** (`echo_mq` depends on `echo_wire` — `echo/apps/echo_mq/mix.exs:31`
  `{:echo_wire, in_umbrella: true}` — so a story test can drive `EchoWire.Pipe`, where the reverse would invert
  the dependency): `echo/apps/echo_mq/test/stories/*_story_test.exs`, registered by the existing
  `echo_mq/test/stories/` glob that `mix echo_mq.stories` reads. The generated `.stories.md` land in the wire
  docs (`docs/echo_mq/wire/stories/`). The frozen `lib/echo_mq/` connector and the `lib/echo_wire.ex` facade
  are untouched. `apps/echo_store` is not edited; `apps/echo_mq` is touched **only** under `test/stories/`
  (test-only, no lib edit, conformance byte-stable).

## Scope

- **In** — the `EchoWire.Pipe` module: the struct, `new/2`, the **comprehensive curated verb set across the
  six data families**, `command/2`, and `exec`/`exec_txn`/`exec_noreply`; the **conn-or-pool first-class
  dispatch** (delivered now); order preservation; the empty-pipe guard; the construction (offline) suite in
  `echo_wire`; the **BDD story layer** in `echo_mq/test/stories/` (the `:valkey` round-trip proof, organized by
  redis-pattern) + the generated `.stories.md` written to `docs/echo_mq/wire/stories/`; the byte-stable re-pin
  of the facade-freeze and the conformance count.
- **Out** — the immutable command value + the `cf`-flag model (→ `ewr.1.2`); the two-tier error split (→
  `ewr.1.3`); client-side caching / CLIENT TRACKING (→ Movement II); the data-family verbs beyond Valkey's six
  core type families (streams, pub/sub, geo, bitmap, HLL, scripting-admin — reachable via `command/2`, not
  curated this rung); any edit to the connector, RESP, Script, Pool, or the facade; any `echo_mq` **lib** edit;
  any new Lua; cluster slot-routing.

## Deliverables

- **`EWR.1.1-D1` — the design-make gate (FIRST).** Before any artifact, re-probe the as-built floor (the lag-1
  law) and rule the decisions that are the implementor's, not the Operator's: (a) confirm the seam anchors
  `Connector.pipeline/3` (:56) / `transaction_pipeline/3` (:130) / `noreply_pipeline/3` (:125) and the pool's
  `EchoMQ.Pool.pipeline/3` (`echo/apps/echo_mq/lib/echo_mq/pool.ex:48`); (b) **realize the conn-or-pool
  dispatch mechanism — FIRST-CLASS in this rung, not deferred** (the Operator's ruling): how `exec` calls
  `pipeline/3` on an opaque conn-or-pool *without inspecting it*. The recommended shape: `new(conn, opts \\ [])`
  stores `conn` plus a **dispatch** (`via`) — defaulting to the connector/facade `pipeline/3` path, set to the
  pool path for an `EchoMQ.Pool` — and a default `timeout`, and `exec` does `via.pipeline(conn, cmds, timeout)`.
  The exact dispatch SHAPE is the implementor's design-make detail (a `via:` module option, or a `{mod, server}`
  tag, or a default-connector/explicit-pool convention); the **binding contract** is that `exec` dispatches
  WITHOUT pattern-matching the reference and the SAME `%Pipe{}` flushes against a `Connector` or an
  `EchoMQ.Pool` (INV3). (c) finalize the curated verb membership across the six families (D3); (d) place the
  module at `lib/echo_wire/pipe.ex` and the story tests at `echo_mq/test/stories/`. No `.ex`/test artifact
  predates this ledger entry.
- **`EWR.1.1-D2` — the accumulator.** `defstruct [:conn, :via, :timeout, cmds: []]` (or the minimal subset D1
  rules — `via`/`timeout` are load-bearing because conn-or-pool is first-class this rung) + `new(conn, opts \\ [])`
  seeding an empty `%Pipe{}`, reading `:via` and `:timeout` from `opts` with sensible defaults (the connector
  path; `5_000`). `new` accepts conn-or-pool and **never inspects** the reference's module or internals — the
  dispatch is carried, not detected (INV3).
- **`EWR.1.1-D3` — the comprehensive curated verb set (the six data families).** Each verb appends exactly one
  command-list onto `cmds` via a private `add/2`; options render as trailing tokens; every verb returns the
  threaded `%Pipe{}`. The vocabulary is grounded in valkey-go's generated builders
  (`go/valkey-go/internal/cmds/gen_*.go`) and spans the **six core Valkey data families** — name the families
  and their principal verbs (the implementor need not curate every option; the long tail rides `command/2`,
  INV6):
  - **strings** (`gen_string.go`): `set/3..4` (`ex:`/`px:`/`nx:`/`xx:`/`get:` options → trailing tokens — the
    rueidis `SetCondition*`/`ExSeconds`/`PxMilliseconds`/`Get` chain), `get/2`, `getset/3`, `getdel/2`,
    `mset/2`, `mget/2`, `append/3`, `strlen/2`, `incr/2`, `incrby/3`, `decr/2`, `decrby/3`, `incrbyfloat/3`,
    `setex/4`, `setnx/3`, `getrange/4`, `setrange/4`.
  - **keys / generic + expiry** (`gen_generic.go`): `del/2` (variadic), `unlink/2`, `exists/2` (variadic),
    `expire/3`, `pexpire/3`, `expireat/3` (and `pexpireat/3`), `ttl/2`, `pttl/2`, `persist/2`, `type/2`,
    `rename/3`, `renamenx/3`, `scan/2..3` (cursor — the `KEYS`-avoid path), `touch/2`, `copy/3`.
  - **hashes** (`gen_hash.go`): `hset/4` (and `hmset/3` — `Hmset` present though deprecated), `hget/3`,
    `hmget/3`, `hgetall/2`, `hdel/3`, `hexists/3`, `hincrby/4`, `hincrbyfloat/4`, `hkeys/2`, `hvals/2`,
    `hlen/2`, `hsetnx/4`, `hscan/3`.
  - **lists** (`gen_list.go`): `lpush/3`, `rpush/3`, `lpop/2..3`, `rpop/2..3`, `lrange/4`, `llen/2`,
    `lindex/3`, `lset/4`, `lrem/4`, `linsert/5`, `ltrim/4`, `rpoplpush/3` (and `lmove/5`).
  - **sets** (`gen_set.go`): `sadd/3`, `srem/3`, `smembers/2`, `sismember/3`, `scard/2`, `spop/2..3`,
    `srandmember/2..3`, `sunion/2`, `sinter/2`, `sdiff/2`, `smismember/3`, `sscan/3`.
  - **sorted sets** (`gen_sorted_set.go`): `zadd/4..` (`nx:`/`xx:`/`gt:`/`lt:`/`ch:` options → trailing tokens
    — the rueidis `ZaddCondition*`/`ZaddComparison*`/`Ch` chain), `zrem/3`, `zrange/4..`, `zrangebyscore/4..`,
    `zrevrange/4..`, `zscore/3`, `zcard/2`, `zrank/3`, `zrevrank/3`, `zincrby/4`, `zpopmin/2..3`,
    `zpopmax/2..3`, `zcount/4`, `zscan/3`.

  The arities are the implementor's design-make (the body names the verb + family + reference, not a frozen
  `{fun, arity}` table — `EchoWire.Pipe` is **not** the facade and is **not** arity-frozen; INV1). The curated
  set is **comprehensive across the six families but never a ceiling** — `command/2` (D4) covers every
  un-curated verb and family (INV6).
- **`EWR.1.1-D4` — the `command/2` escape hatch.** `command(pipe, parts)` appends a raw command-list (a flat
  `[binary | integer | atom]`) verbatim, so any un-modeled verb (e.g. `["CLIENT","INFO"]`, a `SCRIPT` admin
  call) is reachable without a curated wrapper. The curated set is convenience; this guarantees completeness.
- **`EWR.1.1-D5` — the flush verbs.** `exec/1` flushes once into the plain pipeline seam and answers
  `{:ok, [reply]}` with one reply per appended command, in order; `exec_txn/1` flushes into
  `transaction_pipeline/3` and answers `{:ok, exec_replies}`; `exec_noreply/1` flushes into
  `noreply_pipeline/3` and answers `:ok`. `exec/1` is valid against conn-or-pool; `exec_txn/1` / `exec_noreply/1`
  require a single `Connector` (D-INV5).
- **`EWR.1.1-D6` — ordering + the empty pipe.** Commands accumulate in `|>` order (whatever internal
  representation D1 picks, the flushed order equals the call order); `exec` on an empty pipe (`cmds == []`)
  answers `{:error, :empty_pipeline}` rather than calling the connector (whose guard already rejects `[]`).
- **`EWR.1.1-D8` — the BDD story layer (written back to specs).** A set of `EchoMQ.Story` `:valkey` tests under
  `echo/apps/echo_mq/test/stories/` (e.g. `wire_pipe_<pattern>_story_test.exs`, or one file per pattern)
  **organized by redis-pattern**, each driving `EchoWire.Pipe` end-to-end against Valkey on `6390` in the
  pattern the verbs exist for, AND the source of a generated story. Ground the DSL in the **real** pattern — do
  not re-invent it:
  - The DSL is **`EchoMQ.Story`** (`echo/apps/echo_mq/test/support/echo_mq/story.ex`): `use EchoMQ.Story,
    feature: "Wire — Pipe", async: false` + `@moduletag :valkey`. The `__using__` macro emits `use ExUnit.Case`
    + the step macros + scenario registration; it does **NOT** inject a `setup` — **the story test module
    writes its own** `setup` providing `%{conn, q}` exactly as `groups_story_test.exs:23-28` does
    (`Connector.start_link(port: 6390)` + a unique key/queue via `System.unique_integer/1` + `on_exit` purge);
    a `setup_all` may start the snowflake if a scenario mints a branded id. Each `scenario "...", %{conn: conn,
    q: q} do given_/when_/then_/and_ "..." do ... end end` is a **real `:valkey` ExUnit test** driving the live
    surface AND the harvested source of a generated story.
  - **`mix echo_mq.stories --out docs/echo_mq/wire/stories`** (`echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex`)
    reads each module's `__stories__/0` (offline — no Valkey to *generate*) over the fixed glob
    `echo_mq/test/stories/*_story_test.exs` and writes `<feature>.stories.md` + a README catalogue into the
    out dir (default `docs/echo_mq/stories`; this rung directs it to the **wire** stories dir).
  - **The spec contract:** a generated story exists **only because** a real `:valkey` test compiled and passed
    — the `.stories.md` is the proof-from-the-as-built-tests, never hand-prose. The scenarios are organized one
    per redis-pattern (cache-aside, distributed-lock, reliable-queue, counter, leaderboard, set-membership, a
    hash object round-trip — §the pattern map in the stories file), each proving the relevant `Pipe` verbs in
    the pattern they exist for.
- **`EWR.1.1-D7` — the gate.** The per-app ladder green from inside `echo/apps/echo_wire/`:
  `mix compile --warnings-as-errors`; the construction unit suite (offline); **then from
  `echo/apps/echo_mq/`** the `@tag :valkey` story suite on `6390` (the BDD round-trip proof) +
  `mix echo_mq.stories --out docs/echo_mq/wire/stories` regenerating the `.stories.md`; the facade-freeze test
  still green (11 verbs); `Conformance.run/2 → {:ok, 52}` byte-stable; a multi-seed sweep + the
  determinism-posture statement (no id-mint/process/lease → no ≥100 loop). The two-app ladder is intrinsic to
  the dep direction (the module in `echo_wire`, the story tests in `echo_mq` above it).

## Invariants

- **`EWR.1.1-INV1` — the facade stays at 11 verbs.** `EchoWire.Pipe` is a **new module**, never a `defdelegate`
  on `EchoWire`. `echo_wire_facade_test.exs` is unchanged and still asserts exactly the 11 verbs
  (`lib/echo_wire.ex:19-31`). *Check:* the facade test's exported-function list is byte-identical to HEAD.
- **`EWR.1.1-INV2` — additive; the frozen wire is untouched; `echo_mq` is touched test-only.** No edit to
  `EchoMQ.Connector` / `RESP` / `Script` / `Pool`; no new Lua (`grep redis.call` on the lib diff is `0`); the
  `echo_mq` 52-scenario conformance stays byte-stable (`{:ok, 52}`) — the layer is *above* the conformance
  boundary, so the additive-minor *registration* law is **not engaged** (no scenario registered, no
  `registry.json`). The story tests are **test-only** additions under `echo_mq/test/stories/` — no `echo_mq`
  **lib** file changes. *Check:* `git diff` touches only new files under `echo/apps/echo_wire/lib/echo_wire/` +
  `echo/apps/echo_wire/test/echo_wire/` + `echo/apps/echo_mq/test/stories/` + the generated
  `docs/echo_mq/wire/stories/`; **no** file under any `lib/` of either app, and `echo/mix.lock` unchanged.
- **`EWR.1.1-INV3` — conn-or-pool opacity, first-class this rung.** `new(conn, opts)` stores the server
  reference opaquely and **never inspects** its module or internals; `exec/1`'s flush is valid against **both**
  an `EchoMQ.Connector` and an `EchoMQ.Pool` (both expose a signature-identical `pipeline/3` — connector :56,
  pool :48), the dispatch carried in `via`, never detected. This is delivered **now**, not deferred. *Check:* a
  single `%Pipe{}` value (modulo the `conn`/`via` it carries), flushed with `exec/1`, round-trips identically
  whether the target is a connector name or a pool name — both proven in the story `:valkey` suite; and `exec`'s
  body contains **no** `is_struct`/`is_atom`/module-name guard on the reference.
- **`EWR.1.1-INV4` — `exec` adds no pipelining.** The flush is a thin pass-through — `exec/1` is exactly the
  chosen `pipeline/3` over `pipe.cmds`; the Pipe contributes *construction*, never a second pipelining
  mechanism, and the connector remains the sole owner of the in-flight FIFO. *Check:* `exec/1`'s body reduces
  to one `pipeline/3` call; no buffering, batching, or retry lives in `EchoWire.Pipe`.
- **`EWR.1.1-INV5` — the transaction/noreply variants require a single `Connector`.** `exec_txn/1` /
  `exec_noreply/1` map to `transaction_pipeline/3` / `noreply_pipeline/3`, which are connection-stateful
  (`MULTI`/`EXEC`; `CLIENT REPLY OFF/ON`) and exist only on `Connector`, **not** `EchoMQ.Pool` — a pool
  round-robins per command and pins no connection across a transaction. The spec states this; against a pool
  these variants are out of contract. *Check:* `grep transaction_pipeline pool.ex` is `0`; the round-trip
  suite drives `exec_txn`/`exec_noreply` only against a `Connector`.
- **`EWR.1.1-INV6` — escape-hatch completeness + order.** Any command expressible as a `[[binary]]` list is
  reachable via `command/2` (the curated set is never a ceiling); and replies map 1:1 to appended commands, in
  append order. *Check:* a pipe built entirely through `command/2` produces the same replies as the curated
  equivalents; a mixed-order pipe returns replies positionally aligned to its calls.
- **`EWR.1.1-INV7` — a generated story exists only because a real `:valkey` test passed (the gate specifies
  its own liveness).** Each scenario in `docs/echo_mq/wire/stories/*.stories.md` is harvested from a real
  `EchoMQ.Story` `:valkey` ExUnit test under `echo_mq/test/stories/` that drives `EchoWire.Pipe` against
  Valkey on `6390` and asserts the pattern's observable outcome (the cache returns the seeded value; the lock's
  second `SET NX` is refused; the queue pops the pushed item; the counter reads the incremented total; the
  leaderboard ranks by score; the set reports membership; the hash round-trips its fields) — a no-op or a
  story authored without a passing test does **not** satisfy this letter. *Check:* `mix echo_mq.stories`
  regenerates the `.stories.md` from `__stories__/0`, and the generated scenario set equals the
  `test/stories/*_story_test.exs` scenario set one-for-one (every story has a live test behind it); the
  `:valkey` story suite is green from `echo/apps/echo_mq/`.
- **`EWR.1.1-INV8` — the two story layers are distinct and non-contradicting.**
  `specs/ewr.1/ewr.1.1.stories.md` is the **hand-authored USER stories** (the rung acceptance — Connextra,
  INVEST, Given/When/Then prose a person signs); `docs/echo_mq/wire/stories/*.stories.md` is the **GENERATED
  self-documenting proof** harvested from the as-built `_story_test.exs` ("the tests written back to specs").
  The user stories are the acceptance face; the generated stories are the evidence — neither is edited to fork
  from the body, and the user-story pattern coverage names the same patterns the generated stories prove.
  *Check:* the generated-stories directory and the user-stories file name the same redis-pattern set; the body
  is the single authority both derive from.

**The closed error set.** The Pipe introduces no transport error — it reuses the connector's vocabulary:
`{:error, :disconnected}` (socket loss; in-flight callers are failed, never replayed), `{:error, :overloaded}`
(the `max_pending` backpressure), `{:error, {:version_fence, got}}` (the boot fence), and `{:error, term}` for a
typed failure; a successful flush may carry a server error in-band as the value `{:error_reply, msg}`
(`resp.ex:47`), which `ewr.1.3` later classifies. The **one** new error this rung owns is
`{:error, :empty_pipeline}` on `exec` of an empty accumulator. No other new error is introduced.

## Definition of Done

- [ ] `EWR.1.1-D1` — the design-make is ruled and ledgered (the **first-class** conn-or-pool dispatch
      mechanism, the curated membership across the six families, the placement) *before* any `.ex`/test
      artifact exists.
- [ ] `EWR.1.1-D2`/`D3`/`D4` — `EchoWire.Pipe` ships the struct + `new/2` (carrying `via`/`timeout`), the
      **comprehensive curated verb set across the six data families**, and `command/2`, each appending one
      command-list; the threaded `%Pipe{}` is returned everywhere.
- [ ] `EWR.1.1-D5`/`D6` — `exec`/`exec_txn`/`exec_noreply` flush to the three seams (`exec` via the opaque
      dispatch); order is 1:1; the empty pipe answers `{:error, :empty_pipeline}`.
- [ ] `EWR.1.1-D8` — the BDD story layer ships: `EchoMQ.Story` `:valkey` tests under `echo_mq/test/stories/`
      organized by redis-pattern drive `EchoWire.Pipe` end-to-end; `mix echo_mq.stories --out
      docs/echo_mq/wire/stories` regenerates the `.stories.md`.
- [ ] `EWR.1.1-INV1`/`INV2` — the facade is still 11 verbs; no frozen-module edit; no `echo_mq` **lib** edit
      (story tests are test-only); no new Lua; conformance `{:ok, 52}` byte-stable; `echo/mix.lock` unchanged.
- [ ] `EWR.1.1-INV3`/`INV4`/`INV5` — conn-or-pool opacity proven both ways for `exec/1` (**first-class this
      rung**); `exec` is a thin pass-through; `exec_txn`/`exec_noreply` proven against a `Connector` and
      documented out-of-contract for a pool.
- [ ] `EWR.1.1-INV6`/`INV7`/`INV8` — the escape hatch reaches any `[[binary]]`; reply order is positional;
      every generated story has a passing `:valkey` test behind it; the user-story and generated-story layers
      name the same patterns and neither forks the body.
- [ ] `EWR.1.1-D7` — the per-app (two-app) gate ladder is green; the multi-seed sweep passes; the determinism
      posture is stated.

---

Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Agent brief: [`ewr.1.1.llms.md`](ewr.1.1.llms.md) ·
Runbook: [`ewr.1.1.prompt.md`](ewr.1.1.prompt.md) · Ledger:
[`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md) · Design:
[`../../design/ewr.design.md`](../../design/ewr.design.md) · Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md) ·
Method: [`../../../../aaw/aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md)
