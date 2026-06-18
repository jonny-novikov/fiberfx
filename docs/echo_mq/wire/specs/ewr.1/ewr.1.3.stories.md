# EWR.1.3 · user stories

> Who wants the two-tier error split, what they need, and how acceptance is known. Derived from
> [`ewr.1.3.md`](ewr.1.3.md) (**BUILT** — the body is authoritative; this file and the brief derive from it, and
> when they disagree the body wins). The acceptance below ran at the build run against the as-shipped
> `EchoWire.Result` surface and is green (`echo_wire` offline partition suite passing; the wire `:valkey` story
> suite green on `6390`; the partition misclassify mutation Director-killed). **The design fork is RULED: Arm 1**
> (the Operator's ruling, 2026-06-18 — [`ewr.1.3.design.md`](ewr.1.3.design.md)); these stories are the pure
> `EchoWire.Result` classifier's acceptance. `classify/1`'s return is a **tagged tuple** (Mars's design-make), so
> the acceptance asserts the partition OUTCOME through the accessors, not a literal return shape.
>
> **Two story layers, kept distinct (INV8).** THIS file is the **hand-authored USER stories** — the rung
> acceptance a person signs (Connextra, INVEST, Given/When/Then prose). The **generated**
> `docs/echo_mq/wire/stories/*.stories.md` is the self-documenting proof harvested from the as-built
> `echo_mq/test/stories/wire_pipe_error_*_story_test.exs` BDD tests ("the tests written back to specs"). Both
> name the same two-tier case set; neither forks the body. The case coverage below (US7) is the acceptance face
> of the BDD layer the generated stories prove.

## EWR.1.3-US1 — partition an `exec` result into its two tiers

As an **Elixir caller of the wire**, I want to classify a `EchoWire.Pipe.exec/1` result into a clean / transport-
error / server-error outcome, so that I branch on **which tier broke** with one named function instead of
re-parsing the return by hand (a `case` on `{:error, _}` and a separate walk of the reply list for
`{:error_reply, _}`) at every call site.

Acceptance criteria (the OUTCOME is the contract; the wire format of `classify/1`'s return — a tagged tuple or a
`%EchoWire.Result{}` struct — is Mars's design-make, so acceptance is asserted through the accessors):
- Given a successful flush with every reply clean (`{:ok, ["OK", "alice", 1]}`), when I `classify/1` it, then the
  outcome is **clean** carrying `["OK", "alice", 1]` (`non_valkey_error/1` is `nil` and `server_errors/1` on the
  replies is `[]`). *(Illustrative tagged form: `{:ok, ["OK", "alice", 1]}`.)*
- Given a whole-call transport failure (`{:error, :disconnected}`), when I `classify/1` it, then the outcome is
  **transport-error** carrying `:disconnected` (`non_valkey_error/1` is `{:error, :disconnected}`). *(Illustrative:
  `{:transport_error, :disconnected}`.)*
- Given a successful flush carrying a server error
  (`{:ok, ["OK", {:error_reply, "WRONGTYPE Operation against a key ..."}, 1]}`), when I `classify/1` it, then the
  outcome is **server-error** carrying the `:ok` replies and the indexed slot `[{1, {:error_reply, "WRONGTYPE
  ..."}}]` — the rejection reported with its 0-based index `1`. *(Illustrative: `{:server_error, oks, [{1,
  {:error_reply, "WRONGTYPE ..."}}]}`.)*
- Given any value `exec/1` can return, when I `classify/1` it, then exactly one of the three outcomes is produced
  — no input falls through, none matches two (INV4).

INVEST — independent (depends only on `exec`'s frozen return); testable offline (hand-built returns, no Valkey)
and by a `:valkey` round-trip; encodes EWR.1.3-INV3, EWR.1.3-INV4, EWR.1.3-INV5. Priority: must · Size: 5 ·
Implements deliverables: EWR.1.3-D2.

## EWR.1.3-US2 — ask "did the transport break?" (`NonValkeyError()`)

As a **caller deciding whether a failure is retryable**, I want a transport-tier-only question, so that I learn
whether the *connection* failed (retryable on an idempotent batch) without a server rejection masquerading as a
transport error.

Acceptance criteria:
- Given a transport failure (`{:error, :overloaded}`), when I call `EchoWire.Result.non_valkey_error/1`, then it
  returns `{:error, :overloaded}`.
- Given a successful flush that carries a server error (`{:ok, [{:error_reply, "WRONGTYPE ..."}]}`), when I call
  `non_valkey_error/1`, then it returns `nil` — a server error is **not** a transport error (the rueidis
  `NonValkeyError()` semantics: it reports `r.err` only).
- Given a fully clean success (`{:ok, ["OK"]}`), when I call `non_valkey_error/1`, then it returns `nil`.

INVEST — independent; testable offline + `:valkey`; encodes EWR.1.3-INV5 (the transport tier is exactly
`exec`'s `{:error, term}`). Priority: must · Size: 2 · Implements deliverables: EWR.1.3-D3.

## EWR.1.3-US3 — ask "did anything go wrong, either tier?" (`Error()`)

As a **caller that wants one go/no-go answer**, I want a transport-or-server question that returns the first
error of either tier, so that I can short-circuit on any failure without two checks.

Acceptance criteria:
- Given a transport failure (`{:error, {:version_fence, "echomq:1.9.9"}}`), when I call `EchoWire.Result.error/1`,
  then it returns `{:error, {:version_fence, "echomq:1.9.9"}}` (transport takes precedence — there is no reply
  list to inspect).
- Given a successful flush whose 2nd reply is a server error (`{:ok, ["OK", {:error_reply, "WRONGTYPE ..."}]}`),
  when I call `error/1`, then it returns `{:error_reply, "WRONGTYPE ..."}` (the **first** server error, lowest
  index).
- Given a fully clean success, when I call `error/1`, then it returns `nil`.
- Given the same input, when I compare `classify/1`, `non_valkey_error/1`, and `error/1`, then they **agree**:
  `:transport_error` ⇒ both report the `{:error, term}`; `:server_error` ⇒ `non_valkey_error/1` is `nil` and
  `error/1` is the first `{:error_reply, _}`; `:ok` ⇒ both are `nil` (INV6).

INVEST — independent; testable offline + `:valkey`; encodes EWR.1.3-INV6 (transport-before-server ordering +
cross-consistency). Priority: must · Size: 3 · Implements deliverables: EWR.1.3-D4.

## EWR.1.3-US4 — find the server-error slots in a reply list (the per-reply lens)

As a **caller holding a `{:ok, replies}` reply list**, I want a function that returns the `{:error_reply, _}`
slots with their positions, so that I know **which** commands in my batch the server rejected (not just that one
did).

Acceptance criteria:
- Given a reply list `["OK", {:error_reply, "WRONGTYPE ..."}, 1, {:error_reply, "ERR ..."}]`, when I call
  `EchoWire.Result.server_errors/1` on it, then it returns `[{1, {:error_reply, "WRONGTYPE ..."}}, {3,
  {:error_reply, "ERR ..."}}]` — the error slots and their 0-based indices, in ascending order.
- Given a reply list with no errors (`["OK", "alice", 1]`), when I call `server_errors/1`, then it returns `[]`.

INVEST — independent; testable offline; encodes EWR.1.3-INV5 (the server tier is exactly the in-band
`{:error_reply, _}` value). Priority: must · Size: 2 · Implements deliverables: EWR.1.3-D5.

## EWR.1.3-US5 — the classifier is pure (a reader, never a wire call)

As the **wire's steward**, I want the classifier to be a pure function over `exec`'s return — touching no socket,
calling nothing on the connector — so that classification adds no second I/O path and the offline suite proves it
without Valkey.

Acceptance criteria:
- Given `EchoWire.Result`, when its source is inspected, then it makes **no** `Connector`/`Pool` call, opens no
  socket, starts no process (`grep -E "Connector|Pool|:gen_tcp|GenServer\.|\.pipeline\(" result.ex` is `0`).
- Given any classifier function, when it is called twice with the same argument, then it returns the same value
  (referential transparency — the offline suite feeds hand-built returns with no Valkey running).

INVEST — independent; testable offline (the whole point — no Valkey); encodes EWR.1.3-INV3, EWR.1.3-D6.
Priority: must · Size: 2 · Implements deliverables: EWR.1.3-D6.

## EWR.1.3-US6 — the additive guarantee holds (`exec/1` frozen, the frozen floor)

As the **wire's steward**, I want this rung to leave `EchoWire.Pipe.exec/1` and the frozen wire untouched, so
that the error split costs nothing in the founding rung's contract, the facade surface, or conformance.

Acceptance criteria:
- Given the build, when the diff is inspected, then `lib/echo_wire/pipe.ex` is **not edited** — `exec/1`'s
  `{:ok, [reply]} | {:error, term}` contract is byte-unchanged (INV1).
- Given the build, when the facade-freeze test runs, then `EchoWire` still exports exactly its 11 verbs
  (`echo_wire_facade_test.exs` unchanged), and `EchoWire.Result` is a standalone module, not a facade delegate.
- Given the build, when conformance runs, then `EchoMQ.Conformance.run/2` is **byte-stable** (the run's count
  unchanged across the rung — emq-owned, not a number the wire pins); `grep redis.call` on the lib diff is `0`;
  no file under `lib/echo_mq/` is edited; `echo/mix.lock` is unchanged; the `echo_mq` touch is test-only (no
  Mix-task edit — `--match` already shipped).

INVEST — independent; testable by the standing suites + the diff; encodes EWR.1.3-INV1, EWR.1.3-INV2. Priority:
must · Size: 1 · Implements deliverables: EWR.1.3-D6, EWR.1.3-D7.

## EWR.1.3-US7 — each tier proven against a REAL outcome on Valkey

As a **caller learning the split**, I want the server tier proven by a **real** server error from Valkey (not a
hand-built one) and the transport tier proven by a real transport outcome, so that the example is the
documentation and the gate exercises its own liveness (INV7).

Acceptance criteria — each a `EchoMQ.Story` `:valkey` scenario driving `EchoWire.Pipe` + `EchoWire.Result`:
- **server tier — a real `WRONGTYPE` (strings vs lists):** Given a key set to a string, when a `set(k, "v")`
  then `lpush(k, "x")` pipe flushes (so Valkey itself rejects the second command), then `exec` returns
  `{:ok, ["OK", {:error_reply, "WRONGTYPE" <> _}]}`, `classify/1` returns `{:server_error, _, [{1, {:error_reply,
  "WRONGTYPE" <> _}}]}`, `non_valkey_error/1` returns `nil`, and `error/1` returns the `{:error_reply, "WRONGTYPE"
  <> _}`. The error is provoked from the live server, never constructed in the test.
- **server tier — a partial batch:** Given a pipe whose 1st and 3rd commands are valid and 2nd is a `WRONGTYPE`,
  when it flushes, then `server_errors(replies)` reports exactly the 2nd slot's index and the `:ok` replies are
  intact at their positions — a single command's rejection does not fail the batch.
- **transport tier — the empty pipe:** Given a freshly `new`'d pipe with no verbs, when I `exec` then `classify`,
  then `exec` returns `{:error, :empty_pipeline}`, `classify/1` returns `{:transport_error, :empty_pipeline}`,
  and `non_valkey_error/1` returns `{:error, :empty_pipeline}` (the empty-pipe guard is a named transport-tier
  member — `pipe.ex:501`).

INVEST — independent (each case is its own scenario); testable only by a `:valkey` suite for the server tier
(the proof is the live `WRONGTYPE`); encodes EWR.1.3-INV5, EWR.1.3-INV7. Priority: must · Size: 5 · Implements
deliverables: EWR.1.3-D2, EWR.1.3-D3, EWR.1.3-D4, EWR.1.3-D5.

## EWR.1.3-US8 · EWR.1.3-US-GATE — the gate, specification by example

As the **Operator/verifier**, I want the split proven end-to-end so that acceptance is a runnable artifact, not
a description.

Acceptance criteria:
- Given Valkey up on `6390` (`valkey-cli -p 6390 ping → PONG`), when the offline partition suite runs from
  `echo/apps/echo_wire/`, then the three partition outcomes (clean / transport-error / server-error, asserted
  through the accessors), the index lens, and the `nil` answers all pass with no Valkey (purity), and the
  **partition misclassify** mutation is **KILLED** (transport-vs-server ordering is structural — disjoint tuple
  clauses — so there is no order-mutation; the misclassify is the real net-zero proof).
- Given the `@tag :valkey` story suite run from `echo/apps/echo_mq/`, then the real-`WRONGTYPE` server-tier
  split, the partial-batch lens, and the empty-pipe transport case all pass against `6390`.
- Given `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories`, when it runs twice, then the
  wire `.stories.md` is byte-identical between runs (idempotent), the generated scenario set equals the
  `wire_pipe_error_*` test set one-for-one, and the default no-`--match` generation leaves `docs/echo_mq/stories/`
  git-clean (the shared-tool no-harm assertion).
- Given the full ladder, when it completes, then compile is warnings-clean, `lib/echo_wire/pipe.ex` is untouched,
  the facade is 11 verbs, conformance is **byte-stable** (the run's count unchanged — emq-owned, not a number the
  wire pins), and the multi-seed sweep passes.

INVEST — the standing gate; encodes every INV. Priority: must · Size: 3 · Implements deliverables: EWR.1.3-D7.

## EWR.1.3-US9 — the stories are written back from the as-built tests (the proof, not prose)

As the **Operator/verifier reading the spec docs**, I want the wire's error-split story documents generated from
the passing tests rather than hand-written, so that a story is true by construction — it exists only because a
`:valkey` test compiled and passed and a real server error was provoked.

Acceptance criteria:
- Given the `echo_mq/test/stories/wire_pipe_error_*_story_test.exs` BDD suite green on `6390`, when I run `mix
  echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories`, then `<feature>.stories.md` + the README
  catalogue are written, and the generated scenario set equals the test scenario set one-for-one (every story
  has a live test behind it).
- Given the committed `docs/echo_mq/wire/stories/`, when a fresh `--match wire_pipe` generation runs, then the
  output equals it **byte-for-byte** (idempotent — the `--match` filter touches only the wire features), and a
  default no-`--match` generation still emits all bus features leaving `docs/echo_mq/stories/` git-clean.
- Given a story document, when it is inspected, then no scenario lacks a backing test, and the server-error
  scenario provokes a **real** `WRONGTYPE` (a hand-built error does not satisfy INV7).
- Given this (generated) layer and the hand-authored user-story layer (this file), when both are read, then they
  name the same two-tier case set and neither contradicts the body (INV8).

INVEST — independent; testable by the generator + a diff of story-vs-test scenario sets; encodes EWR.1.3-INV7,
EWR.1.3-INV8. Priority: must · Size: 2 · Implements deliverables: EWR.1.3-D7.

---

Coverage: D1→US-GATE/US1 (the design-make precedes all; the verified shape) · D2→US1/US7 · D3→US2/US7 ·
D4→US3/US7 · D5→US4/US7 · D6→US5/US6 · D7→US6/US-GATE/US9 · INV1/INV2→US6 · INV3→US5 · INV4→US1 · INV5→US2/US4/US7 ·
INV6→US3 · INV7→US7/US9 · INV8→US9.

Body: [`ewr.1.3.md`](ewr.1.3.md) · Design (the fork — Operator
rules): [`ewr.1.3.design.md`](ewr.1.3.design.md) · Testing: [`../../ewr.testing.md`](../../ewr.testing.md)
