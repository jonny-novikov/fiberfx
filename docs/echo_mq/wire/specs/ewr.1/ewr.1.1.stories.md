# EWR.1.1 · user stories

> Who wants the threaded pipeline, what they need, and how acceptance is known. Derived from
> [`ewr.1.1.md`](ewr.1.1.md) (**SPECCED** — the body is authoritative; this file and the brief may lag it, and
> when they disagree the body wins). The acceptance below is written forward-tense and runs at the build run,
> against the as-shipped `EchoWire.Pipe` surface.

## EWR.1.1-US1 — assemble and flush a batch with `|>`

As an **Elixir caller of the wire**, I want to build a Valkey command batch by threading a `%Pipe{}` through
`|>` and flush it once, so that I never hand-write a nested `[[binary]]` literal and keep positional flags
correct by eye.

Acceptance criteria:
- Given a connector `conn`, when I evaluate
  `conn |> EchoWire.Pipe.new() |> EchoWire.Pipe.set("user:1","alice", ex: 60) |> EchoWire.Pipe.get("user:1") |> EchoWire.Pipe.incr("hits") |> EchoWire.Pipe.exec()`,
  then the result is `{:ok, ["OK", "alice", 1]}` — one reply per appended command, in call order.
- Given each verb in the chain, when it runs, then it returns the threaded `%Pipe{}` (so the next `|>` stage
  receives a pipe, not a reply).
- Given the `ex: 60` option on `set`, when the command is assembled, then the flushed command-list is
  `["SET","user:1","alice","EX","60"]` (the option renders as trailing tokens).

INVEST — independent (the founding surface, depends on nothing downstream); testable offline (the accumulator)
and by a `:valkey` round-trip; encodes EWR.1.1-INV4, EWR.1.1-INV6. Priority: must · Size: 5 · Implements
deliverables: EWR.1.1-D2, EWR.1.1-D3, EWR.1.1-D5.

## EWR.1.1-US2 — flush as a transaction

As a **caller needing atomicity**, I want a transaction variant of the flush, so that a built batch runs inside
`MULTI`/`EXEC` and returns the `EXEC` array.

Acceptance criteria:
- Given a pipe built against a `Connector`, when I call `EchoWire.Pipe.exec_txn/1`, then the batch is flushed
  via `EchoMQ.Connector.transaction_pipeline/3` and the result is `{:ok, exec_replies}` (the `EXEC` array only).
- Given the same pipe, when I compare `exec_txn/1` to `exec/1`, then `exec_txn/1` adds the `MULTI`/`EXEC`
  wrapping and nothing else — the construction is identical.

INVEST — independent; testable by a `:valkey` suite; encodes EWR.1.1-INV5. Priority: must · Size: 3 ·
Implements deliverables: EWR.1.1-D5.

## EWR.1.1-US3 — flush with replies suppressed

As a **caller issuing fire-and-forget writes**, I want a no-reply variant, so that a built batch runs with its
replies suppressed wire-side and answers `:ok`.

Acceptance criteria:
- Given a pipe built against a `Connector`, when I call `EchoWire.Pipe.exec_noreply/1`, then the batch is
  flushed via `EchoMQ.Connector.noreply_pipeline/3` (`CLIENT REPLY OFF`..`ON`) and the result is `:ok`.

INVEST — independent; testable by a `:valkey` suite; encodes EWR.1.1-INV5. Priority: should · Size: 2 ·
Implements deliverables: EWR.1.1-D5.

## EWR.1.1-US4 — reach an un-modeled command via the escape hatch

As a **caller needing a verb the curated set does not model**, I want a generic `command/2`, so that the
curated verb set is convenience and never a ceiling.

Acceptance criteria:
- Given a pipe, when I call `EchoWire.Pipe.command(pipe, ["CLIENT","INFO"])`, then that raw command-list is
  appended verbatim and flushes like any curated verb.
- Given a batch built entirely through `command/2`, when I `exec`, then the replies equal those of the curated
  equivalents — the escape hatch is a complete substitute.

INVEST — independent; testable offline + `:valkey`; encodes EWR.1.1-INV6. Priority: must · Size: 3 ·
Implements deliverables: EWR.1.1-D4.

## EWR.1.1-US5 — the same pipe runs against a connector or a pool

As a **caller deploying against either a single connector or a pool**, I want `new/1` to accept conn-or-pool
opaquely, so that the same `%Pipe{}` flushes through whichever the deployment provides without my code
branching.

Acceptance criteria:
- Given a `%Pipe{}` built once, when I `exec/1` it with `conn` = a `Connector` name and then with `conn` =
  an `EchoMQ.Pool` name, then both round-trip identically (both expose a signature-identical `pipeline/3`).
- Given `new/1`, when it stores the reference, then it never inspects the reference's module or internals.
- Given `exec_txn/1` / `exec_noreply/1`, when the target is a pool, then the spec declares them out of contract
  (a pool pins no connection across a transaction) — they are exercised only against a `Connector`.

INVEST — independent; testable by a `:valkey` suite with both targets; encodes EWR.1.1-INV3, EWR.1.1-INV5.
Priority: must · Size: 3 · Implements deliverables: EWR.1.1-D2.

## EWR.1.1-US6 — order is positional and the empty pipe is guarded

As a **caller reading the result list**, I want replies aligned 1:1 to my calls and an empty flush to fail
cleanly, so that I can index the result by position and never silently send nothing.

Acceptance criteria:
- Given a pipe with N appended commands in some order, when I `exec`, then the reply list has N entries in the
  same order.
- Given a freshly `new`'d pipe with no verbs, when I `exec`, then the result is `{:error, :empty_pipeline}` —
  the connector is not called with `[]`.

INVEST — independent; testable offline + `:valkey`; encodes EWR.1.1-INV6, EWR.1.1-D6. Priority: must · Size: 2 ·
Implements deliverables: EWR.1.1-D6.

## EWR.1.1-US7 — the additive guarantee holds (the frozen floor)

As the **wire's steward**, I want this rung to leave the frozen wire and its truth row untouched, so that a
brand-new surface costs nothing in conformance or facade surface.

Acceptance criteria:
- Given the build, when the facade-freeze test runs, then `EchoWire` still exports exactly its 11 verbs
  (`echo_wire_facade_test.exs` unchanged).
- Given the build, when conformance runs, then `EchoMQ.Conformance.run/2 → {:ok, 52}`, byte-stable.
- Given the lib diff, when `grep redis.call` runs, then the count is `0`, and no file under `lib/echo_mq/` is
  edited.

INVEST — independent; testable by the standing suites; encodes EWR.1.1-INV1, EWR.1.1-INV2. Priority: must ·
Size: 1 · Implements deliverables: EWR.1.1-D7.

## EWR.1.1-US8 · EWR.1.1-US-GATE — the Valkey gate, specification by example

As the **Operator/verifier**, I want one end-to-end example proven against Valkey on `6390`, so that acceptance
is a runnable artifact, not a description.

Acceptance criteria:
- Given Valkey up on `6390` (`valkey-cli -p 6390 ping → PONG`), when the `@tag :valkey` suite runs from
  `echo/apps/echo_wire/`, then: US1's batch returns `{:ok, ["OK","alice",1]}`; `exec_txn` returns the `EXEC`
  array; `exec_noreply` returns `:ok`; the escape-hatch batch matches the curated batch; the same pipe
  round-trips against both a `Connector` and a `Pool`; the empty pipe returns `{:error, :empty_pipeline}`.
- Given the full ladder, when it completes, then compile is warnings-clean, the facade is 11 verbs, conformance
  is `{:ok, 52}`, and the multi-seed sweep passes.

INVEST — the standing gate; encodes every INV. Priority: must · Size: 3 · Implements deliverables: EWR.1.1-D7.

---

Coverage: D1→US-GATE (the design-make precedes all) · D2→US1/US5 · D3→US1 · D4→US4 · D5→US1/US2/US3 ·
D6→US6 · D7→US7/US-GATE · INV1/INV2→US7 · INV3→US5 · INV4→US1 · INV5→US2/US3/US5 · INV6→US4/US6.

Body: [`ewr.1.1.md`](ewr.1.1.md) · Brief: [`ewr.1.1.llms.md`](ewr.1.1.llms.md) · Testing:
[`../../ewr.testing.md`](../../ewr.testing.md)
