# EWR.1.1 · the x-mode orchestration runbook — the threaded pipeline (the client core opens)

> **Status: BUILT — the runbook the `ewr.1.1` build run executed (shipped green, Director-verified).** The
> Flat-L2 lead-team bound the laws; its inputs were this rung's triad ([`ewr.1.1.md`](ewr.1.1.md) authoritative,
> plus [`ewr.1.1.stories.md`](ewr.1.1.stories.md)) and the ruled fork
> [`../../design/ewr.design.md`](../../design/ewr.design.md). The app is `echo_wire` (+ the `echo_mq` story
> tests, test-only, + the one sanctioned `echo_mq.stories.ex` Mix-task `--match` edit); the canon is
> [`../../ewr.roadmap.md`](../../ewr.roadmap.md). **Outcome:** `echo_wire` 44/0 (facade still 11), wire
> `:valkey` story suite 9/0, conformance `{:ok, 52}` byte-stable, order-theorem mutation KILLED; F-1 (the
> `--match wire_pipe` idempotent regen) remediated.

## The rung in one paragraph

Build `EchoWire.Pipe` — a new pure-data module in `echo/apps/echo_wire/lib/echo_wire/pipe.ex` — giving idiomatic
`|>` command-batch construction over the owned wire: a `%Pipe{conn, via, timeout, cmds}` accumulator, a
**comprehensive curated verb set across the six Valkey data families** (strings · keys/expiry · hashes · lists ·
sets · sorted sets, grounded in valkey-go's `gen_*.go` builders), a `command/2` escape hatch, and
`exec`/`exec_txn`/`exec_noreply` flushing through an **opaque conn-or-pool dispatch** to the
`Connector.pipeline/3` family or `EchoMQ.Pool.pipeline/3` — **conn-or-pool first-class in this founding rung**
(the Operator's ruling), not deferred. The rung **also** ships a **BDD story layer**: `EchoMQ.Story` `:valkey`
tests under `echo_mq/test/stories/` organized by redis-pattern (cache-aside, distributed-lock, reliable-queue,
counter, leaderboard, set-membership, hash object) drive `EchoWire.Pipe` end-to-end and generate
self-documenting `.stories.md` written back to `docs/echo_mq/wire/stories/`. Purely additive: the frozen
connector/RESP/Script/Pool are reused, the 11-verb facade is untouched, no Lua enters the wire, no `echo_mq`
**lib** is edited (story tests are test-only), and the 52-scenario conformance stays byte-stable.

## Mode

**Flat-L2**, the five-stage shape: **Mars-1** (design-make + build) → **Director** solo review (independent gate
re-run on Valkey 6390 + an adversarial probe + a net-zero mutation spot-check) → **Mars-2** (remediate + harden
+ test) → **Venus** (post-build specs reconcile, body → as-built) → **Director** (closure + one ratifying LAW-4
pathspec commit). **Risk tier LOW** — a new pure-data module above the wire: no process, no lease, no state
transition, no auth/deploy/network surface, no frozen-line edit. The conn-or-pool dispatch is first-class but
still pure data; the `echo_mq` touch is **test-only** (`test/stories/`, no lib). **No Apollo charter** in the
per-rung pipeline (the solo Director review + Venus's independent reconcile are the rigor floor); Apollo mentors
out of band. Scope slug: **`ewr-1-1`** (dashed, no dots — the aaw scope slug constraint). Operator: `jonny`.
Workspace: **`echo/apps/echo_wire` (the module) + `echo/apps/echo_mq` (the story tests, test-only)** — the
two-app boundary is Operator-sanctioned for this rung and intrinsic to the dep direction. Ledger:
[`../progress/ewr-1-1.progress.md`](../progress/ewr-1-1.progress.md).

## The pre-Stage-1 gate (the surfaced fork — already ruled)

There is **no open Operator fork** — the Stage-1 gate is reachable. The arm fork (A `Pipe` / B `Cmd` / C
`Query`) is **RULED: Arm A**, and the sub-fork (curated-verbs + `command/2` escape hatch vs a full per-command
surface) is **RULED: curated + escape** ([`../../design/ewr.design.md`](../../design/ewr.design.md); ledger D-1,
D-2). Mars **adopts** both and does not re-litigate them.

## The design-make — the relocated gate (what Mars-1 rules, not re-litigates)

These are the implementor's to settle and log as `tool_x_decision`s at the top of the build, **before** any
artifact:
1. **The conn-or-pool dispatch mechanism (FIRST-CLASS this rung — not deferred, the Operator's ruling)** — how
   `exec` calls `pipeline/3` on an opaque conn-or-pool without inspecting it. Recommended: `new(conn, opts \\ [])`
   stores `conn` + a `via` dispatch (default the connector/facade path; the pool path for an `EchoMQ.Pool`) + a
   default `timeout`, and `exec` does `via.pipeline(conn, cmds, timeout)`. The exact dispatch SHAPE (a `via:`
   module option, or a `{mod, server}` tag, or a default-connector/explicit-pool convention) is the
   implementor's design-make; the binding contract is `exec` never pattern-matches the reference and the same
   `%Pipe{}` flushes against a `Connector` or an `EchoMQ.Pool` (INV3). `exec_txn`/`exec_noreply` stay
   `Connector`-only (the pool carries neither — INV5).
2. **The curated verb membership across the six families** — strings · keys/expiry · hashes · lists · sets ·
   sorted sets (the body D3 names the principal verbs per `gen_*.go`); `EchoWire.Pipe` is NOT arity-frozen
   (it is not the facade), so the per-verb arities are the implementor's; the escape hatch makes the boundary
   non-binding.
3. **The internal `cmds` representation** — append vs prepend-then-reverse-at-`exec`; the only requirement is
   that the flushed order equals the call order (D6).
4. **Placement** — the module at `lib/echo_wire/pipe.ex` (a new `lib/echo_wire/` tree) + the offline
   construction test at `test/echo_wire/pipe_test.exs`; the **BDD story tests at `echo_mq/test/stories/`**
   (test-only, forced by the dep direction — `echo_mq` deps `echo_wire`), generated to
   `docs/echo_mq/wire/stories/` by `mix echo_mq.stories`.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

- `connector.ex:56` `pipeline/3` · `:130` `transaction_pipeline/3` · `:125` `noreply_pipeline/3` · `:47`
  `command/3` · `:63` `eval/5`.
- `echo_mq/.../pool.ex:48` `EchoMQ.Pool.pipeline/3` (no txn/noreply on the pool — INV5).
- `resp.ex:30` the `reply()` type (`{:error_reply, _}` in-band at `:47`).
- `lib/echo_wire.ex:19-31` the 11 frozen verbs; `test/echo_wire_facade_test.exs` the freeze.
- `echo_mq/test/conformance_run_test.exs:45` `Conformance.run/2 → {:ok, 52}`.
- `echo_mq/mix.exs:31` `{:echo_wire, in_umbrella: true}` (the dep direction that forces the story-test home).
- `echo_mq/test/support/echo_mq/story.ex` the `EchoMQ.Story` DSL (no auto-`setup` — the test writes its own,
  per `echo_mq/test/stories/groups_story_test.exs:23-28`); `echo_mq/lib/mix/tasks/echo_mq.stories.ex` the
  generator (glob `test/stories/*_story_test.exs`, `--out DIR`, default `docs/echo_mq/stories`).
- `go/valkey-go/internal/cmds/gen_{string,generic,hash,list,set,sorted_set}.go` the six family builders.

## The pipeline — five stages, Director-in-loop

1. **Stage 1 — Mars-1 (design-make + build).** Re-probe the floor (incl. the story DSL/task + the six
   `gen_*.go` families); log the design-make decisions (first-class dispatch, the six-family membership);
   build `EchoWire.Pipe` to D2–D6 with the comprehensive curated verbs; write the offline construction suite
   (`echo_wire`); write the **BDD story tests by redis-pattern** (`echo_mq/test/stories/wire_pipe_*`, each with
   its own `setup`) per D8 and run `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` (the
   `--match` filter scopes the regen to the wire features — idempotent); run the Stage-1 gate (compile + smoke,
   both apps). Report to the ledger `{ewr-1-1-report}` (a `Y-n`).
2. **Stage 2 — Director solo review.** Independent two-app gate re-run on 6390; an adversarial probe (the
   headline risks: does `exec` smuggle any pipelining/retry of its own? does `exec`'s body inspect the
   reference — is conn-or-pool opacity real both ways? does a pool-targeted `exec_txn` silently round-robin? is
   the facade still 11? does every generated story have a passing `:valkey` test behind it — INV7? is any
   `echo_mq` lib file touched?); a net-zero mutation spot-check. Findings as `F-n`.
3. **Stage 3 — Mars-2 (remediate + harden).** Fold any `F-n` (as-built: **F-1** — the story regen made
   idempotent via the `--match wire_pipe` filter on `echo_mq.stories.ex`, the one sanctioned `echo_mq` Mix-task
   edit); run the full two-app gate ladder to completion (compile + construction suite in `echo_wire`; the
   `:valkey` story suite + `mix echo_mq.stories --match wire_pipe` regen + conformance `{:ok, 52}` in `echo_mq`;
   facade-freeze; multi-seed sweep). The determinism posture is the multi-seed sweep + the statement (no
   id-mint/process/lease).
4. **Stage 4 — Venus (post-build reconcile).** Differ the as-built `EchoWire.Pipe` + the story tests against
   the triad; flip the frame SPECCED → BUILT; sync the design-make rulings (the realized dispatch shape, the
   final curated arities) + any realization-over-literal deviations into the body; re-pin the realized verb set;
   confirm the two story layers (hand-authored user stories vs the generated `.stories.md`) are non-contradicting
   (INV8).
5. **Stage 5 — Director (closure).** Ratify; one LAW-4 pathspec commit spanning **only** the rung's five
   create-locations + the one sanctioned Mix-task edit — `echo/apps/echo_wire/lib/echo_wire/pipe.ex` +
   `echo/apps/echo_wire/test/echo_wire/pipe_test.exs` + `echo/apps/echo_mq/test/stories/wire_pipe_*_story_test.exs`
   + the generated `docs/echo_mq/wire/stories/` + `echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex` (the
   additive `--match` filter — build tooling, default byte-identical) (and the triad doc edits) — re-verify
   `git diff --cached --name-only` is purely the rung (no frozen-runtime `lib/` of either app, `echo/mix.lock`
   unchanged) before committing.

---

Body: [`ewr.1.1.md`](ewr.1.1.md) · Stories: [`ewr.1.1.stories.md`](ewr.1.1.stories.md) · Design:
[`../../design/ewr.design.md`](../../design/ewr.design.md) ·
Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md)
