# EWR.1.3 · the agent brief (LLM build brief)

> The build-grade brief Mars builds from and the verifier accepts against. Derived from [`ewr.1.3.md`](ewr.1.3.md)
> (the spec body — **authoritative**; this brief and the stories derive from it, and when they disagree the body
> wins). **Status: BUILT** — shipped green and Director-verified (the partition mutation independently re-killed).
> The **RULED Arm 1** (a pure `EchoWire.Result` classifier over `exec`'s return; the Operator ruled Arm 1,
> 2026-06-18 — [`ewr.1.3.design.md`](ewr.1.3.design.md)). The four accessors + the partition are the frozen
> contract; the internal representation of `classify/1`'s return was Mars's design-make, realized as a **tagged
> tuple** (`{:ok, replies}` / `{:transport_error, term}` / `{:server_error, oks, [{index, err}]}`, `oks` the full
> reply list — `result.ex:104-111`), checked through the accessors. The propagation clause for any brief authored
> from this: no gendered pronouns for agents; no perceptual/interior-state verbs; no first-person narration.

## References (read first, in order)

1. **The ruled design** — [`ewr.1.3.design.md`](ewr.1.3.design.md): **RULED Arm 1** (`EchoWire.Result`), the seam
   (the classifier reads `exec`'s already-decoded return), the **verified server-error shape** (§1), the frozen-
   surface constraints, and the **contract-vs-shape split** (§3 — the four accessors + the partition are the
   frozen contract; the internal representation of `classify/1`'s return is your design-make, checked through the
   accessors). Adopt the ruled arm; do not re-litigate.
2. **The body** — [`ewr.1.3.md`](ewr.1.3.md): the authoritative D1–D7, INV1–INV8, the closed error set this rung
   classifies, the Definition of Done.
3. **The predecessor's closed error set** — [`ewr.1.1.md`](ewr.1.1.md) (The closed error set): the transport
   tier is `exec`'s `{:error, term}` branch; the server tier is the in-band `{:error_reply, _}` value; the one
   new `ewr.1.1` error `{:error, :empty_pipeline}`. This rung **partitions** that set, adding nothing.
4. **The as-built floor — RE-PROBE every anchor against the as-landed tree (the lag-1 law) before any decision
   or artifact. The classifier's correctness rests on the server-error shape — verify it FIRST:**
   - **`EchoWire.Pipe.exec/1`** — `echo/apps/echo_wire/lib/echo_wire/pipe.ex:500-505`: spec `@spec exec(t()) ::
     {:ok, [EchoMQ.RESP.reply()]} | {:error, term()}`; `exec(%{cmds: []})` → `{:error, :empty_pipeline}` (:501);
     else `via.pipeline(conn, Enum.reverse(cmds), timeout)` (:503-504). **This is FROZEN this rung — read it, do
     not edit it.** `exec_txn/1` (:513-518) → `{:ok, exec_replies}`; `exec_noreply/1` (:526-531) → `:ok`.
   - **`EchoMQ.Connector.pipeline/3`** — `echo/apps/echo_wire/lib/echo_mq/connector.ex:56` →
     `GenServer.call(conn, {:pipeline, cmds})` → `send_pipe(..., :plain)` (:239) → on drain,
     **`pipe_reply(:plain, replies) = {:ok, replies}`** (:560). The `replies` list is raw decoded `RESP.reply()`
     values — `fill/5` (:564-584) pushes whatever `RESP.parse` returns, **including `{:error_reply, msg}`
     verbatim** (:573). **So a server error on the `pipeline/3` path is the in-band value `{:error_reply, _}`
     inside `{:ok, [reply]}` — NEVER `{:error, {:server, _}}`.**
   - **The `{:error, {:server, _}}` term is `eval/5`-EXCLUSIVE** — `connector.ex:76-77` (`{:ok, {:error_reply,
     msg}} -> {:error, {:server, msg}}`) and `map_script_reply/1` (:87), both reached **only** from the EVALSHA
     path in `eval/5` (:63-82). `EchoWire.Pipe` never flushes through `eval`, so this term is **unreachable** via
     the Pipe surface. Do NOT classify it (it cannot arrive); name it OUT of scope (the closed error set).
   - **`EchoMQ.Pool.pipeline/3`** — `echo/apps/echo_mq/lib/echo_mq/pool.ex:48`: `Connector.pipeline(next(name),
     cmds, timeout)` — a **pure pass-through**, no re-map. The server-error shape is identical against a connector
     or a pool.
   - **`EchoMQ.RESP.reply()`** — `resp.ex:30-43` (the union); a server error decodes to the in-band value
     `{:error_reply, binary()}` at **`resp.ex:47`** (`parse(<<?-, rest::binary>>)` → `{:error_reply, &1}`). This
     is the **only** form of a server error in a reply slot.
   - **`EchoWire` facade** — `lib/echo_wire.ex:19-31` (11 verbs), pinned by `test/echo_wire_facade_test.exs`
     (`function_exported?`). Do not grow it; `EchoWire.Result` is a standalone module, not a facade delegate.
   - **Conformance** — `echo/apps/echo_mq/test/conformance_run_test.exs` (`Conformance.run/2 → {:ok, n}`), pinned
     also by `conformance_scenarios_test.exs`. **Leave byte-stable; the count is emq-owned, not a number the wire
     pins** — it has drifted 52→53→54 within this program's life (out of band), so assert the run's count is
     unchanged across the rung, never a literal.
   - The new module home: `echo/apps/echo_wire/lib/echo_wire/result.ex` — **does not exist yet** (genuinely new),
     beside the shipped `lib/echo_wire/pipe.ex` and the frozen `lib/echo_mq/`.
5. **The valkey-go reference** — `go/valkey-go/message.go` (read-only, cited never copied): the two-method
   discriminator on the result value this rung ports —
   - **`ValkeyResult.NonValkeyError()`** (`:149-151`): `return r.err` — the **transport error only**. Ported as
     `non_valkey_error/1` (transport tier only; `nil` for a server-error-carrying success).
   - **`ValkeyResult.Error()`** (`:154-161`): `if r.err != nil { err = r.err } else { err = r.val.Error() }` —
     the transport error **or** the folded-in server error. Ported as `error/1` (transport first, else the first
     `{:error_reply, _}`).
   - **`(*ValkeyMessage).Error()`** (`:740-751`): a RESP simple/blob error frame (`typeSimpleErr`/`typeBlobErr`
     → our `{:error_reply, _}`) → a `*ValkeyError`; a null → `Nil`; else `nil`. The per-reply server-error test
     this rung's `server_errors/1` realizes over a list.
   - The `ValkeyError` sub-cases (`:53`, `:76-92` — `IsMoved`/`IsAsk`/`IsRedirect`) are **forward context only**
     (the deferred cluster-redirect seam); do NOT build sub-classification this rung.
   The discriminator is ported as functions over `exec`'s return; the Go shape (two methods on a result) is the
   model, never copied.
6. **The BDD story pipeline (ground it — do not re-invent):**
   - The DSL **`EchoMQ.Story`** — `echo/apps/echo_mq/test/support/echo_mq/story.ex`: `use EchoMQ.Story, feature:
     "Wire — Error split", async: false` emits `use ExUnit.Case` + `scenario/2,3` + `given_/when_/then_/and_/2` +
     `__stories__/0`; it does **NOT** inject `setup` — the test module writes its own (the working precedent
     `echo/apps/echo_mq/test/stories/groups_story_test.exs:23-28`: `Connector.start_link(port: 6390)` + a unique
     key via `System.unique_integer/1` + `on_exit` purge). `@moduletag :valkey`.
   - The generator **`mix echo_mq.stories --match <substr> --out DIR`** —
     `echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex`: reads `__stories__/0` over the fixed glob
     `echo_mq/test/stories/*_story_test.exs` (offline — no Valkey to generate), filters the FILE SET by
     `Path.basename` containing `<substr>` (`:35-101`, the `ewr.1.1` F-1 `--match` filter — **already shipped, no
     Mix-task edit needed this rung**), writes `<feature>.stories.md` + a README. Name the story files
     **`wire_pipe_error_*_story_test.exs`** so `--match wire_pipe` scopes them (alongside the `ewr.1.1`
     `wire_pipe_*` files).
   - Placement is forced by the dep direction: `echo_mq` depends on `echo_wire` (`echo/apps/echo_mq/mix.exs:31`),
     so a wire story test in `echo_mq/test/stories/` can drive `EchoWire.Pipe` + `EchoWire.Result`; the reverse
     would invert the dependency. The MODULE + pure partition tests stay in `echo_wire`.

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | Rule the design-make FIRST: **confirm the verified server-error shape** (in-band `{:error_reply, _}` only on the Pipe path, never `{:error, {:server, _}}` — `eval`-exclusive, unreachable), **the internal representation of `classify/1`'s return (your design-make — a tagged tuple or a `%EchoWire.Result{}` struct; the accessors + partition are the fixed contract)**, the `oks` content, the placement `lib/echo_wire/result.ex` + the story home `echo_mq/test/stories/wire_pipe_error_*` — ledgered before any artifact | US-GATE, US1 | D1 (no artifact predates the ruling) |
| R2 | `classify/1` — the **total** transport-vs-server partition over `exec`'s return: three outcomes — clean (carries replies) / transport-error (carries the `{:error, term}`) / server-error (carries the `:ok` replies + indexed `[{index, {:error_reply, msg}}]`, ascending) — total + pure; **the wire format of the result is your design-make** (a tagged tuple e.g. `{:ok, replies}` / `{:transport_error, term}` / `{:server_error, oks, server_errors}`, or a struct), checked through the accessors | US1, US7 | D2, INV3, INV4, INV5 |
| R3 | `non_valkey_error/1` — the transport tier (`NonValkeyError()`): `{:error, term}` for a transport failure, `nil` for a server-error-carrying success or a clean success | US2, US7 | D3, INV5 |
| R4 | `error/1` — transport-or-server (`Error()`): the transport `{:error, term}` if present, else the first `{:error_reply, msg}`, else `nil`; transport precedes server | US3, US7 | D4, INV6 |
| R5 | `server_errors/1` — the per-reply lens: a reply list → `[{index, {:error_reply, msg}}]` (the error slots + 0-based positions, ascending), `[]` if clean | US4, US7 | D5, INV5 |
| R6 | The classifier is **pure** (no `Connector`/`Pool`/socket/process call) AND `EchoWire.Pipe.exec/1` is **NOT edited** (`pipe.ex` byte-unchanged) | US5, US6 | D6, INV1, INV3 |
| R7 | `classify`/`error`/`non_valkey_error` are **consistent** on every return shape; transport-before-server ordering is **structural** (`error/1`'s disjoint `{:error,_}` vs `{:ok,_}` clauses — no order-mutation exists), so the standing net-zero proof is the **partition misclassify** mutation (blind `server_errors/1` → the real `WRONGTYPE` story dies), Director-killed | US3 | INV6 |
| R8 | The gate: compile warnings-clean; the offline partition suite (no Valkey); facade still 11 verbs; conformance **byte-stable** (emq-owned count, never a number the wire pins); `pipe.ex` untouched; multi-seed sweep + posture | US6, US-GATE | D7, INV1, INV2 |
| R9 | The **BDD story layer**: `EchoMQ.Story` `:valkey` tests under `echo_mq/test/stories/wire_pipe_error_*` drive `EchoWire.Pipe` + `EchoWire.Result`, the server-tier story provoking a **REAL `WRONGTYPE`** (`set` a string then `lpush` it); `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` regenerates idempotently AND the default path leaves `docs/echo_mq/stories/` git-clean (the shared-tool no-harm assertion); a generated story exists only because a passing test backs it; the generated and hand-authored layers name the same two-tier case set and neither forks the body | US7, US9 | D7, INV7, INV8 |

## Execution topology

**Runtime shape.** `EchoWire.Result` is a **pure data module** — no process, no `GenServer`, no supervised
child, no socket. Every function is a deterministic transform of its argument (`exec`'s return, or a reply list).
The module reads a value `EchoWire.Pipe.exec/1` already produced — it does **not** call `exec`, the connector, or
the pool. So the `echo_wire` partition suite is **fully offline and deterministic** (feed hand-built `exec`-shaped
returns: a clean `{:ok, [...]}`, an `{:ok, [...]}` with one and with several `{:error_reply, _}` slots, each
transport `{:error, term}` member; assert the tag, the index lens, the `nil` answers, the cross-consistency); the
**`:valkey` band is the BDD story layer in `echo_mq`** — it provokes a **real** server error from the live
connector (the `WRONGTYPE` provocation), drives `EchoWire.Pipe` + `EchoWire.Result` together, and doubles as the
generated `.stories.md`.

**Build-order task DAG.**
1. D1 — re-probe + ledger the design-make (the verified shape FIRST; then the result shape, the `oks` content,
   the placement). No artifact before this.
2. D2–D5 — `EchoWire.Result` (`classify/1`, `non_valkey_error/1`, `error/1`, `server_errors/1`) — `server_errors/1`
   is the building block `classify/1`'s `:server_error` case reuses; author it first within the module.
3. The offline partition suite (`result_test.exs`) — the three partition outcomes through the accessors, the
   tiers, the index lens, the cross-consistency check, the purity grep, the partition misclassify mutation.
4. The BDD `:valkey` story tests (`echo_mq/test/stories/wire_pipe_error_*`) — the real-`WRONGTYPE` server tier,
   the partial-batch lens, the empty-pipe transport case; each with its own `setup`.
5. The gate ladder (two-app) + the idempotent `--match wire_pipe` regen.

**Files (expected touch-set — three create-locations + the regenerated stories; NO Mix-task edit, NO `pipe.ex`
edit).**
- NEW `echo/apps/echo_wire/lib/echo_wire/result.ex` (the module).
- NEW `echo/apps/echo_wire/test/echo_wire/result_test.exs` (the offline partition suite).
- NEW `echo/apps/echo_mq/test/stories/wire_pipe_error_*_story_test.exs` (the BDD `:valkey` story tests;
  test-only, no `echo_mq` runtime touched).
- REGENERATED `docs/echo_mq/wire/stories/*.stories.md` + its README (by `mix echo_mq.stories --match wire_pipe` —
  the wire features re-emit; the new error feature joins the existing `wire_pipe_*` ones).

Nothing else — **no** `echo/apps/echo_wire/lib/echo_wire/pipe.ex` edit (the classifier reads `exec`'s return,
`exec` is frozen), **no** frozen-runtime `lib/` edit (`Connector`/`RESP`/`Script`/`Pool`), **no**
`lib/echo_wire.ex` facade edit, **no** `echo_mq.stories.ex` Mix-task edit (the `--match` filter already shipped),
**no** `apps/echo_store` change, `echo/mix.lock` unchanged.

**The gate ladder (two-app, intrinsic to the dep direction).** From `echo/apps/echo_wire/`: re-probe
`.tool-versions`; `valkey-cli -p 6390 ping → PONG` (only needed for the `echo_mq` band); `TMPDIR=/tmp mix compile
--warnings-as-errors`; `TMPDIR=/tmp mix test` (the **offline** partition suite — pure, runs with no Valkey; the
facade-freeze still 11). Then from `echo/apps/echo_mq/`: `TMPDIR=/tmp mix test --include valkey` (the BDD story
suite drives `EchoWire.Pipe` + `EchoWire.Result` against `6390`, provoking the real `WRONGTYPE`); `TMPDIR=/tmp
mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` (regenerate the wire `.stories.md`
**idempotently** — run twice, `diff -r` clean — and verify a default no-`--match` generation leaves
`docs/echo_mq/stories/` git-clean: the shared-tool no-harm assertion); the facade-freeze test green (`echo_wire`);
`Conformance.run/2` byte-stable (`echo_mq` — the run's count unchanged across the rung, emq-owned, never a
literal the wire pins); a multi-seed sweep (`0 1 42 312540 999999`). **Determinism posture:** no
id-mint/process/lease is introduced → the ≥100-iteration loop is NOT run; the multi-seed sweep + this statement
is the honest floor (see [`../../ewr.testing.md`](../../ewr.testing.md)). The classifier is synchronous pure
functions; the `:valkey` round-trips are deterministic request/reply.

**The net-zero mutation proof (as-built — NOT an order theorem; the `ewr.1.1` `L-4` honest delta).** Unlike
`ewr.1.1`'s positional accumulator (where reversal was a live mutation), `error/1`'s transport-before-server
ordering is **structurally enforced**: its two clauses match **disjoint** inputs (`{:error, _}` vs `{:ok, _}`,
`result.ex:134-141`), so no single `exec` return exercises both branches and **there is no order-mutation to
kill** — a "swap the branches" mutation is unreachable. The standing net-zero proof for this rung is therefore
the **partition misclassify** mutation: blind `server_errors/1` (drop the `{:error_reply, _}` match, `result.ex:91`)
and the real `WRONGTYPE` `:valkey` story **KILLS** it — `classify/1` collapses `{:server_error, …}` to
`{:ok, …}` and the story's `non_valkey_error/1`-is-`nil` + server-error assertions fail. The Director re-killed
this independently. Declare the Lua-specific battery items (declared-keys grep, `SCRIPT FLUSH` kill-rate) **N/A**
— this rung adds no Lua — and run the battery that applies (the partition misclassify mutation + the cross-
consistency check + the purity grep + the frozen-floor proof: `pipe.ex` untouched, facade 11, conformance
byte-stable, `grep redis.call` 0).

---

Body: [`ewr.1.3.md`](ewr.1.3.md) · Stories: [`ewr.1.3.stories.md`](ewr.1.3.stories.md) · Runbook:
[`ewr.1.3.prompt.md`](ewr.1.3.prompt.md) · Design (the fork — Operator rules): [`ewr.1.3.design.md`](ewr.1.3.design.md) ·
Ledger: [`../progress/ewr-1-3.progress.md`](../progress/ewr-1-3.progress.md)
