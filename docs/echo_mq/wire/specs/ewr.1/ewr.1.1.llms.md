# EWR.1.1 · the agent brief (LLM build brief)

> The build-grade brief `ewr.1.1` is built from and the verifier accepts against. Derived from
> [`ewr.1.1.md`](ewr.1.1.md) (the spec body — **authoritative**; this brief and the stories may lag it, and when
> they disagree the body wins). **Status: SPECCED.** The arm is ruled — Arm A of
> [`../../design/ewr.design.md`](../../design/ewr.design.md), with the curated-verbs + `command/2` escape-hatch
> sub-fork; this rung **adopts** the ruling and does not re-open it.

## References (read first, in order)

1. **The ruled design** — [`../../design/ewr.design.md`](../../design/ewr.design.md): Arm A (`EchoWire.Pipe`),
   the seam (every arm terminates in `Connector.pipeline/3`), the conn-or-pool contract, the curated-verbs +
   escape-hatch invariant. Adopt; do not re-litigate.
2. **The body** — [`ewr.1.1.md`](ewr.1.1.md): the authoritative D1–D7, INV1–INV6, the closed error set, the
   Definition of Done.
3. **The as-built floor — RE-PROBE every anchor against the as-landed tree (the lag-1 law) before any decision
   or artifact:**
   - `EchoMQ.Connector.pipeline/3` — `echo/apps/echo_wire/lib/echo_mq/connector.ex:56` (list-of-commands →
     `{:ok, [reply]}`); `transaction_pipeline/3` :130 (`{:ok, exec_replies}`); `noreply_pipeline/3` :125
     (`:ok`); `command/3` :47; `eval/5` :63. The connector **already auto-pipelines** (`send_pipe/5`..`drain/1`).
   - `EchoMQ.Pool.pipeline/3` — `echo/apps/echo_mq/lib/echo_mq/pool.ex:48` (round-robin → `Connector.pipeline`);
     `command/3` :45, `eval/5` :51, `stats/1` :55. **No** `transaction_pipeline`/`noreply_pipeline` on the pool
     (grep returns 0) — this forces INV5.
   - `EchoMQ.RESP.reply()` — `resp.ex:30` (the 13 RESP3 terms; a server error is the in-band value
     `{:error_reply, binary()}` at :47, not a transport failure).
   - `EchoWire` facade — `lib/echo_wire.ex:19-31` (11 verbs), pinned by `test/echo_wire_facade_test.exs`
     (`function_exported?` assertion). Do not grow it.
   - Conformance — `echo/apps/echo_mq/test/conformance_run_test.exs:45` (`Conformance.run/2 → {:ok, 52}`),
     pinned also by `conformance_scenarios_test.exs`. Leave byte-stable.
   - The new module home: `echo/apps/echo_wire/lib/echo_wire/` — **does not exist yet** (`pipe.ex` is genuinely
     new), beside the frozen `lib/echo_mq/` and the `lib/echo_wire.ex` facade.
4. **The valkey-go reference** — `go/valkey-go` (read-only, cited never copied): the fluent builders
   `internal/cmds/gen_*.go` — the six data-family files this rung curates from:
   `gen_string.go` (Set/Get/Getset/Getdel/Mset/Mget/Append/Strlen/Incr/Incrby/Decr/Decrby/Incrbyfloat/Setex/Setnx/Getrange/Setrange),
   `gen_generic.go` (Del/Unlink/Exists/Expire/Pexpire/Expireat/Pexpireat/Ttl/Pttl/Persist/Type/Rename/Renamenx/Scan/Touch/Copy),
   `gen_hash.go` (Hset/Hmset/Hget/Hmget/Hgetall/Hdel/Hexists/Hincrby/Hincrbyfloat/Hkeys/Hvals/Hlen/Hsetnx/Hscan),
   `gen_list.go` (Lpush/Rpush/Lpop/Rpop/Lrange/Llen/Lindex/Lset/Lrem/Linsert/Ltrim/Rpoplpush/Lmove),
   `gen_set.go` (Sadd/Srem/Smembers/Sismember/Scard/Spop/Srandmember/Sunion/Sinter/Sdiff/Smismember/Sscan),
   `gen_sorted_set.go` (Zadd/Zrem/Zrange/Zrangebyscore/Zrevrange/Zscore/Zcard/Zrank/Zrevrank/Zincrby/Zpopmin/Zpopmax/Zcount/Zscan);
   the option chains render as trailing tokens (`SetCondition*`/`ExSeconds`/`PxMilliseconds`/`Get`;
   `ZaddCondition*`/`ZaddComparison*`/`Ch`). Also the immutable command + `cf` flags
   `internal/cmds/cmds.go:5-23,117` (forward context for `ewr.1.2`), `DoMulti` auto-pipelining `pipe.go:1097`
   (the capability the connector already owns). The verb-chain shape is ported to `|>`, never copied.
5. **The BDD story pipeline (ground it — do not re-invent):**
   - The DSL **`EchoMQ.Story`** — `echo/apps/echo_mq/test/support/echo_mq/story.ex`: `use EchoMQ.Story, feature:
     "...", async: false` emits `use ExUnit.Case` + `scenario/2,3` + `given_/when_/then_/and_/but_/2` + the
     `__stories__/0` registration; it does **NOT** inject `setup` — the test module writes its own (see the
     working precedent `echo/apps/echo_mq/test/stories/groups_story_test.exs:23-28`:
     `Connector.start_link(port: 6390)` + a unique key via `System.unique_integer/1` + `on_exit` purge, plus a
     `setup_all` to start the snowflake if a scenario mints a branded id). `@moduletag :valkey`.
   - The generator **`mix echo_mq.stories --out DIR`** — `echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex`:
     reads `__stories__/0` over the fixed glob `echo_mq/test/stories/*_story_test.exs` (offline — no Valkey to
     generate) and writes `<feature>.stories.md` + a README catalogue (default out `docs/echo_mq/stories`; this
     rung directs it to `docs/echo_mq/wire/stories`).
   - The placement is forced by the dep direction: `echo_mq` depends on `echo_wire`
     (`echo/apps/echo_mq/mix.exs:31`), so a wire story test in `echo_mq/test/stories/` can drive
     `EchoWire.Pipe`; the reverse would invert the dependency. The MODULE + pure construction tests stay in
     `echo_wire`.
6. **The redis-pattern taxonomy** — [`docs/redis-patterns/redis-patterns.toc.md`](../../../../redis-patterns/redis-patterns.toc.md):
   name the BDD scenarios faithfully (cache-aside R1.01 · distributed-locking R2.02 · reliable-queue R3.01 ·
   atomic-updates/counter R2.01 · leaderboards R4.05 · set-membership · hash object), grounded in what the BCS
   stack actually uses.

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | Rule the design-make FIRST: the **first-class** conn-or-pool dispatch mechanism (recommended `new(conn, opts)` + a `via` dispatch + default timeout, `exec` = `via.pipeline(conn, cmds, timeout)`; the exact shape — `via:` module option or `{mod, server}` tag — is the implementor's design-make), the curated membership across the six families, the placement `lib/echo_wire/pipe.ex` + the story-test home `echo_mq/test/stories/` — ledgered before any artifact | US-GATE, US5 | D1 (no artifact predates the ruling) |
| R2 | `%EchoWire.Pipe{conn, via, timeout, cmds}` struct + `new(conn, opts \\ [])`, conn stored **opaquely** (never inspected), `via`/`timeout` from opts with defaults | US1, US5 | D2, INV3 |
| R3 | The **comprehensive curated verb set across the six data families** (strings · keys/expiry · hashes · lists · sets · sorted sets — the principal verbs per `gen_*.go`), each appending one command-list via a private `add/2`, options as trailing tokens, returning the `%Pipe{}` | US1, US9 | D3, INV4, INV6 |
| R4 | `command/2` appends a raw command-list verbatim — the curated set is never a ceiling (the un-curated families/verbs ride this) | US4, US9 | D4, INV6 |
| R5 | `exec/1`→ the opaque `via.pipeline/3` (Connector or Pool); `exec_txn/1`→`transaction_pipeline/3`; `exec_noreply/1`→`noreply_pipeline/3`; `exec` adds no pipelining | US1, US2, US3 | D5, INV4 |
| R6 | conn-or-pool **first-class this rung**: `exec/1` valid both ways (proven against a `Connector` AND an `EchoMQ.Pool`); `exec_txn`/`exec_noreply` require a `Connector` (out of contract for a pool — the pool carries neither) | US5 | INV3, INV5 |
| R7 | Order is positional; empty pipe → `{:error, :empty_pipeline}`; no other new error (reuse the connector's vocabulary) | US6 | D6, INV6, the closed error set |
| R8 | The gate: compile warnings-clean; construction (offline) + the `:valkey` story suites; facade still 11 verbs; conformance `{:ok, 52}` byte-stable; multi-seed sweep + posture | US7, US-GATE | D7, INV1, INV2 |
| R9 | The **BDD story layer**: `EchoMQ.Story` `:valkey` tests under `echo_mq/test/stories/` organized by redis-pattern drive `EchoWire.Pipe` end-to-end (each module writes its own `setup`); `mix echo_mq.stories --out docs/echo_mq/wire/stories` regenerates the `.stories.md`; a generated story exists only because a passing test backs it; the generated layer and the hand-authored user-story layer name the same patterns and neither forks the body | US9, US10 | D8, INV7, INV8 |

## Execution topology

**Runtime shape.** `EchoWire.Pipe` is a pure data module — no process, no `GenServer`, no supervised child. A
`%Pipe{}` is an immutable accumulator; the only effect is the single `pipeline/3` call inside `exec` (dispatched
opaquely through `via`). So the `echo_wire` construction suite is offline and deterministic (assert the
accumulated `cmds`, the `add/2` token rendering, the empty-pipe guard, the no-inspect dispatch); the **`:valkey`
band is the BDD story layer in `echo_mq`** — it proves the round-trip against the live connector AND the pool,
organized by redis-pattern, and doubles as the generated `.stories.md`.

**Files (expected touch-set — four create-locations, no lib edit outside the new module).**
- NEW `echo/apps/echo_wire/lib/echo_wire/pipe.ex` (the module; `lib/echo_wire/` is new).
- NEW `echo/apps/echo_wire/test/echo_wire/pipe_test.exs` (the offline construction suite).
- NEW `echo/apps/echo_mq/test/stories/wire_pipe_*_story_test.exs` (the BDD `:valkey` story tests — one per
  pattern, or grouped; test-only, no `echo_mq` lib touched).
- GENERATED `docs/echo_mq/wire/stories/*.stories.md` + its README (by `mix echo_mq.stories`).

Nothing else — no edit under either app's `lib/`, no edit to `lib/echo_wire.ex` or `lib/echo_mq/`, no
`apps/echo_store` change, `echo/mix.lock` unchanged.

**The gate ladder (two-app, intrinsic to the dep direction).** From `echo/apps/echo_wire/`: re-probe
`.tool-versions`; `valkey-cli -p 6390 ping → PONG`; `TMPDIR=/tmp mix compile --warnings-as-errors`;
`TMPDIR=/tmp mix test` (the offline construction suite). Then from `echo/apps/echo_mq/`:
`TMPDIR=/tmp mix test --include valkey` (the BDD story suite drives `EchoWire.Pipe` against `6390`);
`TMPDIR=/tmp mix echo_mq.stories --out docs/echo_mq/wire/stories` (regenerate the `.stories.md` — offline);
the facade-freeze test green (`echo_wire`); `Conformance.run/2 → {:ok, 52}` byte-stable (`echo_mq`); a
multi-seed sweep (`0 1 42 312540 999999`). **Determinism posture:** no id-mint/process/lease is introduced →
the ≥100-iteration loop is NOT run; the multi-seed sweep + this statement is the honest floor (see
[`../../ewr.testing.md`](../../ewr.testing.md)). (A story scenario that mints a branded id via `setup_all`
remains a single deterministic mint per scenario, not the same-ms contention the loop guards.)

---

Body: [`ewr.1.1.md`](ewr.1.1.md) · Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Runbook:
[`ewr.1.1.prompt.md`](ewr.1.1.prompt.md) · Ledger: [`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md)
