# EWR.1.1 · EchoWire.Pipe — the threaded pipeline (Movement I, the founding rung)

> **Status: BUILT** — shipped green, Director-verified. The founding rung of the EchoWire client-core
> ([`../../ewr.roadmap.md`](../../ewr.roadmap.md), Movement I; design Arm A). It builds, in `echo/apps/echo_wire`,
> a new module **`EchoWire.Pipe`** (`lib/echo_wire/pipe.ex`) — idiomatic `|>` command-batch construction over the
> owned wire, so a caller never hand-writes a nested `[[binary]]` literal with positional flags kept correct by
> eye. The connector already auto-pipelines; this rung adds the *construction* noun it consumes, not a second
> pipelining mechanism. Additive by construction: the frozen wire (`Connector`/`RESP`/`Script`/`Pool`) is reused,
> the `EchoWire` facade stays at 11 verbs, no Lua enters the wire, and the `echo_mq` conformance is byte-stable.

## The surface

- **`%Pipe{conn, via, timeout, cmds}`** + `new(conn, opts \\ [])` — the accumulator threaded by `|>`. `via` is an
  **opaque conn-or-pool dispatch** (default `EchoMQ.Connector`, `EchoMQ.Pool` via `opts[:via]`), carried, never
  inspected — first-class this rung (the Operator's ruling), so the same `%Pipe{}` flushes against either.
- **A curated verb set across the six Valkey data families** (strings · keys/expiry · hashes · lists · sets ·
  sorted sets), grounded in valkey-go's `gen_*.go` builders. `EchoWire.Pipe` is **not** the facade and is **not**
  arity-frozen — the per-verb arities are the implementor's; the verb list lives in `pipe.ex`, not this spec.
- **`command/2`** — the escape hatch: any `[[binary]]`-expressible command is reachable, so the curated set is
  never a ceiling.
- **`exec/1`** flushes once through `via.pipeline/3` → `{:ok, [reply]}`, one reply per appended command in call
  order; **`exec_txn/1`** / **`exec_noreply/1`** flush through `Connector` directly (Connector-only — a pool pins
  no connection across a transaction). An empty pipe answers `{:error, :empty_pipeline}`.
- **A BDD story layer** — `EchoMQ.Story` `:valkey` tests by redis-pattern (cache-aside · lock · queue · counter ·
  leaderboard · set-membership · hash) drive `Pipe` end-to-end and generate `docs/echo_mq/wire/stories/`.

## Invariants

- **Frozen floor.** `Connector`/`RESP`/`Script`/`Pool` untouched; the `EchoWire` facade stays at **11 verbs**
  (`EchoWire.Pipe` is a new module, not a 12th verb); no new Lua (`grep redis.call` = `0`); conformance
  byte-stable (the count is emq-owned, not the wire's to pin).
- **Opacity.** `exec` carries the dispatch in `via` with no `is_struct`/`is_atom`/module guard.
- **Order.** Replies map 1:1 to appended commands (prepend-then-reverse-at-flush); the standing net-zero proof is
  the order-theorem mutation — reverse the accumulator and a story dies.
- **Stories proven, not prose.** Every generated story has a passing `:valkey` test behind it; the regen is
  idempotent (`mix echo_mq.stories --match wire_pipe`); the hand-authored user stories and the generated proof
  name the same pattern set.

**Gate (green):** `echo_wire` **44/0** (facade still 11), the wire `:valkey` story suite **9/0** (9 scenarios / 8
features), conformance `{:ok, 52}` byte-stable, the order-theorem mutation **KILLED**. Touch-set: `pipe.ex` +
`pipe_test.exs` + the `wire_pipe_*` story tests + the generated stories + one sanctioned additive
`echo_mq.stories.ex` `--match` filter (build tooling, default byte-identical).

---

Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Brief: [`ewr.1.1.llms.md`](ewr.1.1.llms.md) · Runbook:
[`ewr.1.1.prompt.md`](ewr.1.1.prompt.md) · Design: [`../../design/ewr.design.md`](../../design/ewr.design.md) ·
Ledger: [`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md) · Roadmap:
[`../../ewr.roadmap.md`](../../ewr.roadmap.md)
