# EWR.1.1 · the x-mode orchestration runbook — the threaded pipeline (the client core opens)

> **Status: SPECCED — the runbook for the `ewr.1.1` build run (a later session).** The Flat-L2 lead-team binds
> the laws; its inputs are this rung's triad ([`ewr.1.1.md`](ewr.1.1.md) authoritative, plus
> [`ewr.1.1.stories.md`](ewr.1.1.stories.md) and [`ewr.1.1.llms.md`](ewr.1.1.llms.md)) and the ruled fork
> [`../../design/ewr.design.md`](../../design/ewr.design.md). The app is `echo_wire`; the canon is
> [`../../ewr.roadmap.md`](../../ewr.roadmap.md).

## The rung in one paragraph

Build `EchoWire.Pipe` — a new pure-data module in `echo/apps/echo_wire/lib/echo_wire/pipe.ex` — giving idiomatic
`|>` command-batch construction over the owned wire: a `%Pipe{conn, cmds}` accumulator, a curated verb set, a
`command/2` escape hatch, and `exec`/`exec_txn`/`exec_noreply` flushing to the `Connector.pipeline/3` family.
Purely additive: the frozen connector/RESP/Script/Pool are reused, the 11-verb facade is untouched, no Lua
enters the wire, and the 52-scenario conformance stays byte-stable.

## Mode

**Flat-L2**, the five-stage shape: **Mars-1** (design-make + build) → **Director** solo review (independent gate
re-run on Valkey 6390 + an adversarial probe + a net-zero mutation spot-check) → **Mars-2** (remediate + harden
+ test) → **Venus** (post-build specs reconcile, body → as-built) → **Director** (closure + one ratifying LAW-4
pathspec commit). **Risk tier LOW** — a new pure-data module above the wire: no process, no lease, no state
transition, no auth/deploy/network surface, no frozen-line edit. **No Apollo charter** in the per-rung pipeline
(the solo Director review + Venus's independent reconcile are the rigor floor); Apollo mentors out of band.
Scope slug: **`ewr-1-1`** (dashed, no dots — the aaw scope slug constraint). Operator: `jonny`. Workspace:
`echo/apps/echo_wire`. Ledger: [`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md).

## The pre-Stage-1 gate (the surfaced fork — already ruled)

There is **no open Operator fork** — the Stage-1 gate is reachable. The arm fork (A `Pipe` / B `Cmd` / C
`Query`) is **RULED: Arm A**, and the sub-fork (curated-verbs + `command/2` escape hatch vs a full per-command
surface) is **RULED: curated + escape** ([`../../design/ewr.design.md`](../../design/ewr.design.md); ledger D-1,
D-2). Mars **adopts** both and does not re-litigate them.

## The design-make — the relocated gate (what Mars-1 rules, not re-litigates)

These are the implementor's to settle and log as `tool_x_decision`s at the top of the build, **before** any
artifact:
1. **The conn-or-pool dispatch mechanism** — how `exec` calls `pipeline/3` on an opaque conn-or-pool without
   inspecting it. Recommended: `new(conn, opts \\ [])` stores `conn` + a `via` dispatch module (default the
   connector/facade path; `EchoMQ.Pool` for a pool) + a default `timeout`, and `exec` does
   `via.pipeline(conn, cmds, timeout)`. The reference is never pattern-matched (INV3).
2. **The curated verb membership** — which core string/key verbs ship in `1.1` (the body names the floor:
   `set`/`get`/`del`/`incr`/`incrby`/`decr`/`expire`/`ttl`/`exists`/`mget`); the escape hatch makes the
   boundary non-binding.
3. **The internal `cmds` representation** — append vs prepend-then-reverse-at-`exec`; the only requirement is
   that the flushed order equals the call order (D6).
4. **Placement** — `lib/echo_wire/pipe.ex` (a new `lib/echo_wire/` tree), test at `test/echo_wire/pipe_test.exs`.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

- `connector.ex:56` `pipeline/3` · `:130` `transaction_pipeline/3` · `:125` `noreply_pipeline/3` · `:47`
  `command/3` · `:63` `eval/5`.
- `echo_mq/.../pool.ex:48` `EchoMQ.Pool.pipeline/3` (no txn/noreply on the pool — INV5).
- `resp.ex:30` the `reply()` type (`{:error_reply, _}` in-band at `:47`).
- `lib/echo_wire.ex:19-31` the 11 frozen verbs; `test/echo_wire_facade_test.exs` the freeze.
- `echo_mq/test/conformance_run_test.exs:45` `Conformance.run/2 → {:ok, 52}`.

## The pipeline — five stages, Director-in-loop

1. **Stage 1 — Mars-1 (design-make + build).** Re-probe the floor; log the design-make decisions; build
   `EchoWire.Pipe` to D2–D6; write the construction + `:valkey` suites; run the Stage-1 gate (compile +
   smoke). Report to the ledger `{ewr-1-1-report}` (a `Y-n`).
2. **Stage 2 — Director solo review.** Independent gate re-run on 6390; an adversarial probe (the headline
   risk: does `exec` smuggle any pipelining/retry of its own? does a pool-targeted `exec_txn` silently
   round-robin? is the facade still 11?); a net-zero mutation spot-check. Findings as `F-n`.
3. **Stage 3 — Mars-2 (remediate + harden).** Fold any `F-n`; run the full gate ladder to completion (compile,
   construction suite, `:valkey` suite, facade-freeze, conformance `{:ok, 52}`, multi-seed sweep). The
   determinism posture is the multi-seed sweep + the statement (no id-mint/process/lease).
4. **Stage 4 — Venus (post-build reconcile).** Differ the as-built `EchoWire.Pipe` against the triad; flip the
   frame SPECCED → BUILT; sync the design-make rulings + any realization-over-literal deviations into the body;
   re-pin the arities.
5. **Stage 5 — Director (closure).** Ratify; one LAW-4 pathspec commit (the new `pipe.ex` + `pipe_test.exs`
   only); re-verify `git diff --cached --name-only` is purely the rung before committing.

---

Body: [`ewr.1.1.md`](ewr.1.1.md) · Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Brief:
[`ewr.1.1.llms.md`](ewr.1.1.llms.md) · Design: [`../../design/ewr.design.md`](../../design/ewr.design.md) ·
Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md)
