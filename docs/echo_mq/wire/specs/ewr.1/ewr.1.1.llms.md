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
4. **The valkey-go reference** — `go/valkey-go` (read-only, cited never copied): the fluent builder
   `internal/cmds/gen_string.go` (the verb-chain shape ported to `|>`), the immutable command + `cf` flags
   `internal/cmds/cmds.go:5-23,117` (forward context for `ewr.1.2`), `DoMulti` auto-pipelining `pipe.go:1097`
   (the capability the connector already owns).

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | Rule the design-make FIRST: the conn-or-pool dispatch mechanism (recommended `new(conn, opts)` + a `via` module + default timeout, `exec` = `via.pipeline(conn, cmds, timeout)`), the curated membership, the placement `lib/echo_wire/pipe.ex` — ledgered before any artifact | US-GATE | D1, INV7-equiv (no artifact predates the ruling) |
| R2 | `%EchoWire.Pipe{}` struct + `new/1`/`new/2`, conn stored opaquely | US1, US5 | D2, INV3 |
| R3 | The curated verb set (`set`/`get`/`del`/`incr`/`incrby`/`decr`/`expire`/`ttl`/`exists`/`mget`), each appending one command-list, returning the `%Pipe{}` | US1 | D3, INV4 |
| R4 | `command/2` appends a raw command-list verbatim | US4 | D4, INV6 |
| R5 | `exec/1`→`pipeline/3`; `exec_txn/1`→`transaction_pipeline/3`; `exec_noreply/1`→`noreply_pipeline/3`; `exec` adds no pipelining | US1, US2, US3 | D5, INV4 |
| R6 | conn-or-pool: `exec/1` valid both ways; `exec_txn`/`exec_noreply` require a `Connector` (out of contract for a pool) | US5 | INV3, INV5 |
| R7 | Order is positional; empty pipe → `{:error, :empty_pipeline}`; no other new error (reuse the connector's vocabulary) | US6 | D6, INV6, the closed error set |
| R8 | The gate: compile warnings-clean; construction + `:valkey` suites; facade still 11 verbs; conformance `{:ok, 52}` byte-stable; multi-seed sweep + posture | US7, US-GATE | D7, INV1, INV2 |

## Execution topology

**Runtime shape.** `EchoWire.Pipe` is a pure data module — no process, no `GenServer`, no supervised child. A
`%Pipe{}` is an immutable accumulator; the only effect is the single `pipeline/3` call inside `exec`. So most of
the suite is offline and deterministic (assert the accumulated `cmds`); the `:valkey` band proves the
round-trip against the live connector and pool.

**Files (expected touch-set).** NEW `echo/apps/echo_wire/lib/echo_wire/pipe.ex` + NEW
`echo/apps/echo_wire/test/echo_wire/pipe_test.exs`. Nothing else — no edit under `lib/echo_mq/`, no edit to
`lib/echo_wire.ex`, no `apps/echo_mq` or `apps/echo_store` change, `echo/mix.lock` unchanged.

**The gate ladder** (from inside `echo/apps/echo_wire/`): re-probe `.tool-versions`;
`valkey-cli -p 6390 ping → PONG`; `TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test`
(+ `--include valkey`); the facade-freeze test green; `Conformance.run/2 → {:ok, 52}`; a multi-seed sweep
(`0 1 42 312540 999999`). **Determinism posture:** no id-mint/process/lease is introduced → the ≥100-iteration
loop is NOT run; the multi-seed sweep + this statement is the honest floor (see
[`../../ewr.testing.md`](../../ewr.testing.md)).

---

Body: [`ewr.1.1.md`](ewr.1.1.md) · Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Runbook:
[`ewr.1.1.prompt.md`](ewr.1.1.prompt.md) · Ledger: [`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md)
