# EWR.1.1 · user stories

> Who wants the threaded pipeline, what they need, and how acceptance is known. Derived from
> [`ewr.1.1.md`](ewr.1.1.md) (**BUILT** — the body is authoritative; this file and the brief may lag it, and
> when they disagree the body wins). The acceptance below ran at the build run against the as-shipped
> `EchoWire.Pipe` surface and is green (`echo_wire` **44/0**, wire `:valkey` story suite **9/0**).
>
> **Two story layers, kept distinct (INV8).** THIS file is the **hand-authored USER stories** — the rung
> acceptance a person signs (Connextra, INVEST, Given/When/Then prose). The **generated**
> `docs/echo_mq/wire/stories/*.stories.md` is the self-documenting proof harvested from the as-built
> `echo_mq/test/stories/*_story_test.exs` BDD tests ("the tests written back to specs"). Both name the same
> redis-pattern set; neither forks the body. The pattern coverage below (US9) is the acceptance face of the
> BDD layer the generated stories prove.

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

## EWR.1.1-US5 — the same pipe runs against a connector or a pool (first-class this rung)

As a **caller deploying against either a single connector or a pool**, I want `new/2` to accept conn-or-pool
opaquely **in this founding rung** (the Operator ruled pool first-class, not deferred), so that the same
`%Pipe{}` flushes through whichever the deployment provides without my code branching.

Acceptance criteria:
- Given a `%Pipe{}` built once, when I `exec/1` it with the target = a `Connector` and then with the target =
  an `EchoMQ.Pool`, then both round-trip identically (both expose a signature-identical `pipeline/3` — connector
  `:56`, pool `:48`), the dispatch carried in `via`.
- Given `new/2`, when it stores the reference, then it never inspects the reference's module or internals, and
  `exec`'s body contains no `is_struct`/`is_atom`/module-name guard on it.
- Given `exec_txn/1` / `exec_noreply/1`, when the target is a pool, then the spec declares them out of contract
  (a pool pins no connection across a transaction; the pool carries neither `transaction_pipeline` nor
  `noreply_pipeline`) — they are exercised only against a `Connector`.

INVEST — independent; testable by a `:valkey` story suite with both targets; encodes EWR.1.1-INV3,
EWR.1.1-INV5. Priority: must · Size: 3 · Implements deliverables: EWR.1.1-D1, EWR.1.1-D2.

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

## EWR.1.1-US9 — every verb proven in the redis-pattern it exists for

As a **caller learning the curated vocabulary**, I want each data family's principal verbs proven end-to-end in
the real redis-pattern they serve, so that the curated set is demonstrably comprehensive and the example is the
documentation. The patterns are named faithfully to the [`/redis-patterns`](../../../../redis-patterns/redis-patterns.toc.md)
taxonomy (cache-aside R1.01, distributed-locking R2.02, reliable-queue R3.01, atomic-updates/counter R2.01,
leaderboards R4.05, set-membership, hash object).

Acceptance criteria — each a `EchoMQ.Story` `:valkey` scenario driving `EchoWire.Pipe` (the pattern → the Pipe
verbs it exercises):
- **cache-aside (strings + expiry):** Given a cold key, when a `set(k, v, ex: 60)` then `get(k)` pipe flushes,
  then the reply is `["OK", v]` and `ttl(k)` is `> 0` — read-through with a bounded life.
- **distributed-lock (SET NX + DEL):** Given a lock key, when `set(lock, token, nx: true)` is flushed twice,
  then the first reply is `"OK"` and the second is `nil` (the lock is held); `del(lock)` releases it.
- **reliable-queue (lists):** Given a queue key, when `lpush(q, a)` / `lpush(q, b)` then `rpop(q)`, then the
  pop returns `a` (FIFO across the wait list — the RPOPLPUSH-family pattern's push/pop ends).
- **counter (atomic-updates):** Given a counter key, when `incr(c)` is flushed three times in one pipe, then
  the replies are `[1, 2, 3]` — a server-atomic tally with no read-modify-write race.
- **leaderboard (sorted sets):** Given a board key, when `zadd(b, 10, "a")` / `zadd(b, 20, "b")` then
  `zrevrange(b, 0, -1)`, then the order is `["b", "a"]` and `zrank`/`zscore` report the standing — rank computed
  on read, never stored. *(As-built RESP3: `zscore` returns a double, e.g. `250.0`; the story asserts that
  reality.)*
- **set-membership (sets):** Given a set key, when `sadd(s, x)` then `sismember(s, x)` and `sismember(s, y)`,
  then the replies are `1` (present) and `0` (absent) — O(1) membership.
- **hash object round-trip (hashes):** Given an entity key, when `hset_all(h, %{...})` (multi-field) or
  `hset(h, "name", "alice")` / `hincrby(h, "hits", 1)` then `hgetall(h)`, then the map carries
  `{"name" => "alice", "hits" => "1"}` — a compact object the wire round-trips field-wise.

INVEST — independent (each pattern is its own scenario); testable only by a `:valkey` suite (the proof is the
live round-trip — **9/0** as-built); encodes EWR.1.1-INV6, EWR.1.1-INV7, and exercises D3 across all six
families. Priority: must · Size: 5 · Implements deliverables: EWR.1.1-D3, EWR.1.1-D8.

## EWR.1.1-US10 — the stories are written back from the as-built tests (the proof, not prose)

As the **Operator/verifier reading the spec docs**, I want the wire's story documents generated from the
passing tests rather than hand-written, so that a story is true by construction — it exists only because a
`:valkey` test compiled and passed.

Acceptance criteria:
- Given the `echo_mq/test/stories/wire_pipe_*_story_test.exs` BDD suite green on `6390` (**9/0**), when I run
  `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories`, then `<feature>.stories.md` + a
  README catalogue are written, and the generated scenario set equals the test scenario set one-for-one (**9
  scenarios / 8 features**, every story has a live test behind it).
- Given the committed `docs/echo_mq/wire/stories/`, when a fresh `--match wire_pipe` generation runs, then the
  output equals it **byte-for-byte** (idempotent — the `--match` filter touches only the wire features, never
  the sibling `docs/echo_mq/stories/`).
- Given a story document, when it is inspected, then no scenario lacks a backing test — a no-op or a
  hand-authored story does not satisfy INV7.
- Given this (generated) layer and the hand-authored user-story layer (this file), when both are read, then
  they name the same redis-pattern set and neither contradicts the body (INV8).

INVEST — independent; testable by the generator + a diff of story-vs-test scenario sets; encodes EWR.1.1-INV7,
EWR.1.1-INV8. Priority: must · Size: 2 · Implements deliverables: EWR.1.1-D8.

---

Coverage: D1→US-GATE/US5 (the design-make precedes all; dispatch first-class) · D2→US1/US5 · D3→US1/US9 ·
D4→US4 · D5→US1/US2/US3 · D6→US6 · D7→US7/US-GATE · D8→US9/US10 · INV1/INV2→US7 · INV3→US5 · INV4→US1 ·
INV5→US2/US3/US5 · INV6→US4/US6/US9 · INV7→US9/US10 · INV8→US10.

Body: [`ewr.1.1.md`](ewr.1.1.md) · Brief: [`ewr.1.1.llms.md`](ewr.1.1.llms.md) · Testing:
[`../../ewr.testing.md`](../../ewr.testing.md)
