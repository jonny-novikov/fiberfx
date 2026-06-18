# EWR.1.1 · EchoWire.Pipe — the threaded pipeline (Movement I, the founding rung)

> **Status: SPECCED** — authored this run, built a later run. The first rung of the EchoWire client-core
> program ([`../../ewr.roadmap.md`](../../ewr.roadmap.md), Movement I). It builds, inside `echo/apps/echo_wire`,
> a new module **`EchoWire.Pipe`** (`lib/echo_wire/pipe.ex`, a directory that does not exist yet) giving
> idiomatic `|>` command-batch construction over the owned wire. A `%Pipe{conn, cmds}` accumulator threads
> through `|>`; a curated verb set appends one command-list each; `exec/1` flushes once into
> `EchoMQ.Connector.pipeline/3` (`echo/apps/echo_wire/lib/echo_mq/connector.ex:56`), with `exec_txn/1` /
> `exec_noreply/1` variants over `transaction_pipeline/3` (:130) / `noreply_pipeline/3` (:125), and a generic
> `Pipe.command/2` escape hatch keeps the curated set from being a ceiling. The arm is **ruled** — Arm A of the
> design fork ([`../../design/ewr.design.md`](../../design/ewr.design.md)), carried with the curated-verbs +
> escape-hatch sub-fork; this rung adopts the ruling and does not re-litigate it. The change is **additive by
> construction**: `EchoMQ.Connector` / `RESP` / `Script` / `Pool` are frozen and reused; the `EchoWire` facade
> stays at its 11 verbs (`lib/echo_wire.ex:19-31`, pinned by `echo_wire_facade_test.exs`); no Lua enters the
> wire; the `echo_mq` 52-scenario conformance (`Conformance.run/2 → {:ok, 52}`,
> `echo/apps/echo_mq/test/conformance_run_test.exs:45`) stays byte-stable — the new layer lives *above* the
> conformance boundary.

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
- **What** — a new module `EchoWire.Pipe` carrying: a `%Pipe{conn, cmds}` struct + `new/1`; a **curated verb
  set** (the core string/key family — `set` / `get` / `del` / `incr` / `incrby` / `decr` / `expire` / `ttl` /
  `exists` / `mget`, each appending one command-list); a generic **`command/2` escape hatch** (appends a raw
  command-list verbatim); and three **flush verbs** — `exec/1` → `pipeline/3`, `exec_txn/1` →
  `transaction_pipeline/3`, `exec_noreply/1` → `noreply_pipeline/3`. The exact curated membership is finalized
  at the design-make (D1); the escape hatch makes the set's boundary non-binding.
- **Who** — every Elixir caller assembling Valkey batches. The immediate consumers are `echo_mq`'s own command
  sites and `echo_store`'s direct-Valkey paths; the deployment targets are the `EchoMQ.Connector` and the
  `EchoMQ.Pool` (both of which the Pipe must accept opaquely). No downstream rung gates by name on `ewr.1.1` —
  it is the program's floor; `ewr.1.2` (the command value) and `ewr.1.3` (the error split) layer onto it.
- **When** — Movement I, rung 1, now: the design fork is ruled (Arm A) and the floor is as-built and frozen.
  It precedes `ewr.1.2`/`1.3` because both extend the surface this rung founds (B's flags enrich the
  accumulator; the error split wraps `exec`'s return).
- **Where** — `echo/apps/echo_wire/lib/echo_wire/pipe.ex` (a **new** module; `lib/echo_wire/` does not exist
  yet) + a new `test/echo_wire/pipe_test.exs`. The frozen `lib/echo_mq/` connector and the `lib/echo_wire.ex`
  facade are untouched. `apps/echo_mq` and `apps/echo_store` are not edited.

## Scope

- **In** — the `EchoWire.Pipe` module: the struct, `new/1`, the curated verb set, `command/2`, and
  `exec`/`exec_txn`/`exec_noreply`; the conn-or-pool contract; order preservation; the empty-pipe guard; the
  construction + `:valkey` round-trip suites; the byte-stable re-pin of the facade-freeze and the conformance
  count.
- **Out** — the immutable command value + the `cf`-flag model (→ `ewr.1.2`); the two-tier error split (→
  `ewr.1.3`); client-side caching / CLIENT TRACKING (→ Movement II); any edit to the connector, RESP, Script,
  Pool, or the facade; any new Lua; cluster slot-routing.

## Deliverables

- **`EWR.1.1-D1` — the design-make gate (FIRST).** Before any artifact, re-probe the as-built floor (the lag-1
  law) and rule the decisions that are the implementor's, not the Operator's: (a) confirm the seam anchors
  `Connector.pipeline/3` (:56) / `transaction_pipeline/3` (:130) / `noreply_pipeline/3` (:125) and the pool's
  `EchoMQ.Pool.pipeline/3` (`echo/apps/echo_mq/lib/echo_mq/pool.ex:48`); (b) **rule the conn-or-pool dispatch
  mechanism** — how `exec` calls `pipeline/3` on an opaque conn-or-pool *without inspecting it*. The
  recommended shape: `new(conn, opts \\ [])` stores `conn` plus an optional `via` dispatch module (default the
  connector/facade path; `EchoMQ.Pool` for a pool) and a default `timeout`, and `exec` does
  `via.pipeline(conn, cmds, timeout)` — the caller declares the dispatch, the Pipe never pattern-matches the
  reference. (c) finalize the curated verb membership; (d) place the module at `lib/echo_wire/pipe.ex`. No
  `.ex`/test artifact predates this ledger entry.
- **`EWR.1.1-D2` — the accumulator.** `defstruct [:conn, :via, :timeout, cmds: []]` (or the minimal subset D1
  rules) + `new/1` (and `new/2`) seeding an empty `%Pipe{}`. `new` accepts conn-or-pool and never inspects it.
- **`EWR.1.1-D3` — the curated verb set.** Each verb appends exactly one command-list onto `cmds` via a private
  `add/2`: the core string/key family grounded in valkey-go `gen_string` / `gen_generic` — `set/3..4` (with
  `ex:` / `px:` / `nx:` / `xx:` options rendered as trailing tokens), `get/2`, `del/2`, `incr/2`, `incrby/3`,
  `decr/2`, `expire/3`, `ttl/2`, `exists/2`, `mget/2`. Every verb returns the threaded `%Pipe{}`.
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
- **`EWR.1.1-D7` — the gate.** The per-app ladder green from inside `echo/apps/echo_wire/`:
  `mix compile --warnings-as-errors`; the construction unit suite (offline); the `@tag :valkey` round-trip
  suite on `6390`; the facade-freeze test still green (11 verbs); `Conformance.run/2 → {:ok, 52}` byte-stable;
  a multi-seed sweep + the determinism-posture statement (no id-mint/process/lease → no ≥100 loop).

## Invariants

- **`EWR.1.1-INV1` — the facade stays at 11 verbs.** `EchoWire.Pipe` is a **new module**, never a `defdelegate`
  on `EchoWire`. `echo_wire_facade_test.exs` is unchanged and still asserts exactly the 11 verbs
  (`lib/echo_wire.ex:19-31`). *Check:* the facade test's exported-function list is byte-identical to HEAD.
- **`EWR.1.1-INV2` — additive; the frozen wire is untouched.** No edit to `EchoMQ.Connector` / `RESP` /
  `Script` / `Pool`; no new Lua (`grep redis.call` on the lib diff is `0`); the `echo_mq` 52-scenario
  conformance stays byte-stable (`{:ok, 52}`) — the layer is *above* the conformance boundary, so the
  additive-minor *registration* law is **not engaged** (no scenario registered, no `registry.json`). *Check:*
  `git diff` touches only new files under `echo/apps/echo_wire/lib/echo_wire/` + `test/echo_wire/`.
- **`EWR.1.1-INV3` — conn-or-pool opacity.** `new/1` stores the server reference opaquely and never inspects
  its module or internals; `exec/1`'s flush is valid against both an `EchoMQ.Connector` and an `EchoMQ.Pool`
  (both expose a signature-identical `pipeline/3`). *Check:* a single `%Pipe{}` value, flushed with `exec/1`,
  round-trips identically whether `conn` is a connector name or a pool name.
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

**The closed error set.** The Pipe introduces no transport error — it reuses the connector's vocabulary:
`{:error, :disconnected}` (socket loss; in-flight callers are failed, never replayed), `{:error, :overloaded}`
(the `max_pending` backpressure), `{:error, {:version_fence, got}}` (the boot fence), and `{:error, term}` for a
typed failure; a successful flush may carry a server error in-band as the value `{:error_reply, msg}`
(`resp.ex:47`), which `ewr.1.3` later classifies. The **one** new error this rung owns is
`{:error, :empty_pipeline}` on `exec` of an empty accumulator. No other new error is introduced.

## Definition of Done

- [ ] `EWR.1.1-D1` — the design-make is ruled and ledgered (the dispatch mechanism, the curated membership,
      the placement) *before* any `.ex`/test artifact exists.
- [ ] `EWR.1.1-D2`/`D3`/`D4` — `EchoWire.Pipe` ships the struct + `new`, the curated verb set, and `command/2`,
      each appending one command-list; the threaded `%Pipe{}` is returned everywhere.
- [ ] `EWR.1.1-D5`/`D6` — `exec`/`exec_txn`/`exec_noreply` flush to the three connector seams; order is 1:1;
      the empty pipe answers `{:error, :empty_pipeline}`.
- [ ] `EWR.1.1-INV1`/`INV2` — the facade is still 11 verbs; no frozen-module edit; no new Lua; conformance
      `{:ok, 52}` byte-stable.
- [ ] `EWR.1.1-INV3`/`INV4`/`INV5` — conn-or-pool opacity proven both ways for `exec/1`; `exec` is a thin
      pass-through; `exec_txn`/`exec_noreply` proven against a `Connector` and documented out-of-contract for a
      pool.
- [ ] `EWR.1.1-INV6` — the escape hatch reaches any `[[binary]]`; reply order is positional.
- [ ] `EWR.1.1-D7` — the per-app gate ladder is green; the multi-seed sweep passes; the determinism posture is
      stated.

---

Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Agent brief: [`ewr.1.1.llms.md`](ewr.1.1.llms.md) ·
Runbook: [`ewr.1.1.prompt.md`](ewr.1.1.prompt.md) · Ledger:
[`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md) · Design:
[`../../design/ewr.design.md`](../../design/ewr.design.md) · Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md) ·
Method: [`../../../../aaw/aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md)
