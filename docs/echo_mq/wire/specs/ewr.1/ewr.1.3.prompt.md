# EWR.1.3 · the x-mode orchestration runbook — the two-tier error split (the ergonomic core closes)

> **Status: BUILT — the runbook the `ewr.1.3` build run executed (shipped green, Director-verified).** The
> Flat-L2 lead-team bound the laws; its inputs were this rung's triad ([`ewr.1.3.md`](ewr.1.3.md) authoritative,
> plus [`ewr.1.3.stories.md`](ewr.1.3.stories.md)) and the ruled fork
> [`ewr.1.3.design.md`](ewr.1.3.design.md). The app is `echo_wire` (+ the `echo_mq` story tests, test-only — and
> **no** Mix-task edit this rung); the canon is [`../../ewr.roadmap.md`](../../ewr.roadmap.md). **The design fork
> was RULED: Arm 1** (the Operator's ruling, 2026-06-18). **Outcome:** `EchoWire.Result` shipped with `classify/1`'s
> internal representation a **tagged tuple** (Mars's design-make; `oks` = the full reply list), the four accessors
> the frozen contract; the offline partition suite passing, the wire `:valkey` story suite green on `6390` (the
> real `WRONGTYPE` split), conformance byte-stable (emq-owned count), the **partition misclassify mutation KILLED**
> (Director re-killed independently). The honest INV6 reconcile: transport-before-server ordering is **structural**
> (disjoint tuple clauses) — there is no order-mutation, so the partition misclassify is the standing proof.

## The rung in one paragraph

Build `EchoWire.Result` — a new **pure** module in `echo/apps/echo_wire/lib/echo_wire/result.ex` — bringing the
two-tier error distinction rueidis draws (`NonValkeyError()` vs `Error()`, `go/valkey-go/message.go:149`/`:154`)
into idiomatic Elixir as a **classifier over `EchoWire.Pipe.exec/1`'s already-decoded return**. The split
already exists in the data (`ewr.1.1`, The closed error set): the transport tier is `exec`'s `{:error, term}`
whole-call branch; the server tier is the in-band value `{:error_reply, binary()}` (`resp.ex:47`) carried inside
`{:ok, [reply]}`. `EchoWire.Result` ships four pure accessors — `classify/1` (the transport-vs-server partition;
its internal representation Mars's design-make), `non_valkey_error/1` (the transport tier, `NonValkeyError()`),
`error/1` (transport-or-server, `Error()`), and
`server_errors/1` (a per-reply lens finding the `{:error_reply, _}` slots) — over `exec`'s return. The rung
**also** ships a **BDD `:valkey` story layer** that provokes a **real** server error (the `WRONGTYPE`
provocation: `set` a string then `lpush` it) and proves the classifier splits it from the `:ok` replies, plus a
transport-tier path. Purely additive: `EchoWire.Pipe.exec/1` is **frozen and byte-unchanged** (the classifier
reads its return), the frozen connector/RESP/Script/Pool are reused, the 11-verb facade is untouched, no Lua
enters the wire, no `echo_mq` **lib** is edited (story tests are test-only; no Mix-task edit — the `--match`
filter already shipped), and the `echo_mq` conformance stays **byte-stable** (emq-owned count, not a number the
wire pins — drifted 52→53→54 out of band).

## Mode

**Flat-L2**, the five-stage shape: **Mars-1** (design-make + build) → **Director** solo review (independent gate
re-run on Valkey 6390 + an adversarial probe + a net-zero mutation spot-check) → **Mars-2** (remediate + harden +
test) → **Venus** (post-build specs reconcile, body → as-built) → **Director** (closure + one ratifying LAW-4
pathspec commit). **Risk tier LOW** — a new **pure-data** module above the wire: no process, no lease, no state
transition, no auth/deploy/network surface, no frozen-line edit (the classifier reads a value; `exec` is not
touched). The `echo_mq` touch is **test-only** (`test/stories/`, no lib). **No Apollo charter** in the per-rung
pipeline (the solo Director review + Venus's independent reconcile are the rigor floor); Apollo mentors out of
band. Scope slug: **`ewr-1-3`** (dashed, no dots — the aaw scope slug constraint). Operator: `jonny`. Workspace:
**`echo/apps/echo_wire` (the module) + `echo/apps/echo_mq` (the story tests, test-only)** — the two-app boundary
is Operator-sanctioned for this rung and intrinsic to the dep direction. Ledger:
[`../progress/ewr-1-3.progress.md`](../progress/ewr-1-3.progress.md).

## The pre-Stage-1 gate (the surfaced fork — RULED: Arm 1)

**The placement fork is RULED — Stage 1 is reachable.** Venus surfaced it in four arms
([`ewr.1.3.design.md`](ewr.1.3.design.md)); the Operator **RULED Arm 1** (2026-06-18 — Venus's recommendation):

- **Arm 1 — RULED** — a pure `EchoWire.Result` classifier over `exec`'s return (least frozen, faithful rueidis
  port, `exec/1` untouched, offline-testable).
- **Arm 2** (chosen-against) — new exec variants `exec_split/1` / `exec!/1` on `Pipe` (split at the flush — but
  grows the `Pipe` surface, mixes classify into construct, bakes a raise policy).
- **Arm 3** (chosen-against) — a per-reply lens only (`server_errors/1`; no transport-tier surface — but an
  incomplete port, transport tier stays folklore).
- **Arm 4** (chosen-against) — defer the rung (fold into `ewr.1.2` — but the split's shape is already determined,
  so nothing to defer; un-rules a ruled rung).

This triad is authored for **Arm 1**. The **result-shape sub-question** (the internal representation of
`classify/1`'s return — a tagged tuple or a `%EchoWire.Result{}` struct) is **delegated to Mars's design-make**
(the Director's call, per the "contract-to-specify, shape-to-leave-to-Mars" rule,
[`../../program/ewr.venus.md`](../../program/ewr.venus.md)): the **four accessors + the partition contract** are
fixed by the triad; the **internal representation** is the implementor's, runnable-checked through the accessors
(never against a literal return shape). Record the ruling in the ledger decisions channel (`D-n`, `RULED:`) and
the chosen-against arms' `CHOSEN-AGAINST:` in the alternatives channel.

## The design-make — the relocated gate (what Mars-1 rules, not re-litigates; assuming Arm 1)

These are the implementor's to settle and log as `tool_x_decision`s at the top of the build, **before** any
artifact:
1. **Confirm the verified server-error shape (FIRST — the classifier rests on it).** Re-probe that
   `EchoWire.Pipe.exec/1` (→ `via.pipeline/3`) returns a server error ONLY as the in-band value `{:error_reply,
   binary()}` inside `{:ok, [reply]}`, NEVER `{:error, {:server, _}}` (which is `eval/5`-exclusive —
   `connector.ex:76-77`, `map_script_reply/1` `:87` — and unreachable through the Pipe). Confirm
   `pipe_reply(:plain, replies) = {:ok, replies}` (`connector.ex:560`) and `fill/5` pushes `{:error_reply, msg}`
   verbatim (`connector.ex:573` → `resp.ex:47`); confirm `EchoMQ.Pool.pipeline/3` (`pool.ex:48`) is a pure
   pass-through. **If the re-probe finds otherwise, STOP and surface it to the Director** — the classifier's
   server tier depends on this fact.
2. **The internal representation of `classify/1`'s return (delegated to Mars).** The **frozen contract** is the
   four accessors (`classify/1`, `non_valkey_error/1`, `error/1`, `server_errors/1`) + the partition behaviour
   (D2–D5). The **representation** `classify/1` returns is the implementor's design-make — a tagged tuple (e.g.
   `{:ok, replies}` / `{:transport_error, term}` / `{:server_error, oks, server_errors}`) **or** a
   `%EchoWire.Result{}` struct. Whichever ships realizes the same accessor contract; the gate checks run **through
   the accessors** (assert what `classify`/`error`/`non_valkey_error`/`server_errors` answer), never against a
   pinned literal — exactly as `ewr.1.1` left the `%Pipe{via}` dispatch field to Mars and checked the conn-or-pool
   *contract*. The Director may rule the representation or leave it open.
3. **The `oks` content in the `:server_error` case** — the reply list with the `{:error_reply, _}` slots elided,
   or the full list (the implementor's design-make; `server_errors` carries the indexed errors either way).
4. **Placement** — the module at `lib/echo_wire/result.ex` (beside the shipped `pipe.ex`) + the offline partition
   test at `test/echo_wire/result_test.exs`; the **BDD story tests at `echo_mq/test/stories/wire_pipe_error_*`**
   (test-only, forced by the dep direction — `echo_mq` deps `echo_wire`), generated to `docs/echo_mq/wire/stories/`
   by `mix echo_mq.stories --match wire_pipe`.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

- `pipe.ex:500-505` `exec/1` (`{:ok, [reply]} | {:error, term}`; `{:error, :empty_pipeline}` at :501; FROZEN this
  rung); `:513-518` `exec_txn/1`; `:526-531` `exec_noreply/1`.
- `connector.ex:56` `pipeline/3` → `:239` `send_pipe(:plain)` → `:560` `pipe_reply(:plain, replies) = {:ok,
  replies}`; `:564-584` `fill/5` (pushes `{:error_reply, msg}` verbatim at :573).
- `connector.ex:76-77` + `:87` `map_script_reply` — the `{:error, {:server, _}}` mapping, **`eval/5`-exclusive**,
  unreachable via the Pipe.
- `pool.ex:48` `EchoMQ.Pool.pipeline/3` — a pure pass-through to `Connector.pipeline` (no re-map).
- `resp.ex:47` the server-error decode (`{:error_reply, &1}`); `resp.ex:30-43` the `reply()` type.
- `lib/echo_wire.ex:19-31` the 11 frozen verbs; `test/echo_wire_facade_test.exs` the freeze.
- `echo_mq/test/conformance_run_test.exs` `Conformance.run/2 → {:ok, n}` — **byte-stable, emq-owned count** (not
  a number the wire pins; drifted 52→53→54 out of band).
- `echo_mq/mix.exs:31` `{:echo_wire, in_umbrella: true}` (the dep direction that forces the story-test home).
- `echo_mq/test/support/echo_mq/story.ex` the `EchoMQ.Story` DSL (no auto-`setup` — the test writes its own, per
  `echo_mq/test/stories/groups_story_test.exs:23-28`); `echo_mq/lib/mix/tasks/echo_mq.stories.ex` the generator
  (glob `test/stories/*_story_test.exs`, the `--match <substr>` FILE-SET filter `:35-101`, `--out DIR`) —
  **already carries `--match`; no edit this rung**.
- `go/valkey-go/message.go:149-151` `NonValkeyError()`, `:154-161` `Error()`, `:740-751` `(*ValkeyMessage).Error()`,
  `:53`/`:76-92` `ValkeyError`/`IsMoved`/`IsAsk` (forward context for the deferred redirect seam — do not build).

## The pipeline — five stages, Director-in-loop

1. **Stage 0 — the fork (Director + Operator).** Rule the placement fork via `AskUserQuestion` (Arm 1/2/3/4 +
   the result-shape sub-question). Record `D-n RULED:` + the losing arms' `CHOSEN-AGAINST:`. **If an arm other
   than 1 is ruled, Venus re-authors the triad first.** Stage 1 is unreachable until the fork is ruled.
2. **Stage 1 — Mars-1 (design-make + build; Arm 1 ruled).** Re-probe the floor (the verified server-error
   shape FIRST; the story DSL/task; the `message.go` anchors); log the design-make decisions (the confirmed
   server-error shape, **the chosen internal representation of `classify/1`'s return**, the `oks` content); build
   `EchoWire.Result` to D2–D6 (`server_errors/1` first, then `classify/1` reusing it, `non_valkey_error/1`,
   `error/1`); write the **offline** partition suite (`echo_wire` — no Valkey: the three partition outcomes
   asserted through the accessors, the tiers, the index lens, the `nil` answers, the cross-consistency, the purity
   grep); write the **BDD story tests** (`echo_mq/test/stories/wire_pipe_error_*`, each with its own
   `setup`) per D7 — the server-tier story provoking a **REAL `WRONGTYPE`** — and run `mix echo_mq.stories
   --match wire_pipe --out docs/echo_mq/wire/stories`; run the Stage-1 gate (compile + smoke, both apps). Report
   to the ledger `{ewr-1-3-report}` (a `Y-n`).
3. **Stage 2 — Director solo review.** Independent two-app gate re-run on 6390; an adversarial probe (the
   headline risks: does `EchoWire.Result` call the wire / open a socket — is it really pure (INV3)? is `pipe.ex`
   /`exec/1` untouched (INV1)? is `classify/1` total + exhaustive over `exec`'s return, no fall-through (INV4)?
   does any clause synthesize `{:server, _}` (INV5 — it must not, that term cannot arrive via the Pipe)? does
   `error/1` order transport-before-server (INV6 — note: structural, via disjoint `{:error,_}`/`{:ok,_}` clauses,
   so there is no order-mutation to probe)? does the server-error story provoke a REAL `WRONGTYPE` or hand-build
   it (INV7)? is the facade still 11? is any `echo_mq` lib file touched?); a net-zero mutation spot-check (the
   **partition misclassify** — blind `server_errors/1`, confirm the real `WRONGTYPE` story dies). Findings as
   `F-n`.
4. **Stage 3 — Mars-2 (remediate + harden).** Fold any `F-n`; run the full two-app gate ladder to completion
   (compile + the offline partition suite in `echo_wire`; the `:valkey` story suite + the idempotent `--match
   wire_pipe` regen + the bus-stories-git-clean no-harm assertion + conformance **byte-stable** (emq-owned count)
   in `echo_mq`; facade-freeze; the **partition misclassify** mutation KILLED; multi-seed sweep). The determinism
   posture is the multi-seed sweep + the statement (no id-mint/process/lease).
5. **Stage 4 — Venus (post-build reconcile, DONE).** Differed the as-built `EchoWire.Result` + the story tests
   against the triad; flipped the frame SPECCED → BUILT; synced the design-make realization (the tagged-tuple
   representation, `oks` = the full reply list) + the honest INV6 reconcile (structural ordering, no order-mutation
   — the partition misclassify is the proof) + the value-free conformance framing into the body; confirmed the two
   story layers (hand-authored user stories vs the generated `.stories.md`) are non-contradicting (INV8). The
   floor-doc sync + the ledger `Z-1` + the commit are the Director's.
6. **Stage 5 — Director (closure).** Ratify; one LAW-4 pathspec commit spanning **only** the rung's three
   create-locations + the regenerated stories — `echo/apps/echo_wire/lib/echo_wire/result.ex` +
   `echo/apps/echo_wire/test/echo_wire/result_test.exs` +
   `echo/apps/echo_mq/test/stories/wire_pipe_error_*_story_test.exs` + the regenerated
   `docs/echo_mq/wire/stories/` (and the triad doc edits) — re-verify `git diff --cached --name-only` is purely
   the rung (**no** `pipe.ex` edit, no frozen-runtime `lib/` of either app, no `echo_mq.stories.ex` edit,
   `echo/mix.lock` unchanged) before committing.

---

Body: [`ewr.1.3.md`](ewr.1.3.md) · Stories: [`ewr.1.3.stories.md`](ewr.1.3.stories.md) · Design:
[`ewr.1.3.design.md`](ewr.1.3.design.md) · Roadmap:
[`../../ewr.roadmap.md`](../../ewr.roadmap.md)
