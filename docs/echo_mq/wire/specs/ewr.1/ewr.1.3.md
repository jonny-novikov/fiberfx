# EWR.1.3 · EchoWire.Result — the two-tier error split (transport vs server) (Movement I, the ergonomic core closes)

> **Status: BUILT** — shipped green and Director-verified (the partition mutation independently re-killed). The
> RULED arm (Arm 1) of the design fork ([`ewr.1.3.design.md`](ewr.1.3.design.md); the Operator ruled Arm 1,
> 2026-06-18 — Venus's recommendation). The third and final Movement-I rung of the EchoWire client-core program
> ([`../../ewr.roadmap.md`](../../ewr.roadmap.md), Movement I). It builds, inside `echo/apps/echo_wire`, a new
> **pure** module **`EchoWire.Result`** (`lib/echo_wire/result.ex`) that brings the two-tier error distinction
> rueidis draws — `NonValkeyError()` vs `Error()` (`go/valkey-go/message.go:149`/`:154`) — into idiomatic Elixir
> as a **classifier over `EchoWire.Pipe.exec/1`'s already-decoded return**. The split **already exists in the
> data** (`ewr.1.1`, The closed error set): a transport failure is `exec`'s `{:error, term}` whole-call branch;
> a server error is the in-band value `{:error_reply, binary()}` (`resp.ex:47`) carried inside `{:ok, [reply]}`.
> `ewr.1.3` does not invent the split — it NAMES it through **four accessors** over `exec`'s return: `classify/1`
> (the transport-vs-server partition), `non_valkey_error/1` (the transport-tier question, `NonValkeyError()`),
> `error/1` (the transport-or-server question, `Error()`), and `server_errors/1` (a per-reply lens finding the
> `{:error_reply, _}` slots in a reply list). **The four accessors + the partition are the frozen contract; the
> internal representation of `classify/1`'s return is Mars's design-make** (the Director's call, per the
> "contract-to-specify, shape-to-leave-to-Mars" rule) — realized as a **tagged tuple** (below), runnable-checked
> through the accessors, never pinned as a literal. The classifier is **pure** — it reads a value `exec` produced;
> it touches no socket and calls nothing on the connector. The change
> is **additive by construction**: `EchoWire.Pipe.exec/1`'s shipped `{:ok, [reply]} | {:error, term}` contract is
> **frozen and byte-unchanged**; `EchoMQ.Connector` / `RESP` / `Script` / `Pool` are frozen and reused; the
> `EchoWire` facade stays at its 11 verbs (`lib/echo_wire.ex:19-31`, pinned by `echo_wire_facade_test.exs`); no
> Lua enters the wire; the `echo_mq` conformance stays **byte-stable** — the wire registers no scenario and writes
> no `registry.json`, so the count is **emq-owned, not the wire's to pin** (it has drifted 52→53→54 within this
> program's life, out of band) — the new layer (Result + story tests) lives *above* the conformance boundary. The
> `{:error, :empty_pipeline}` this rung's predecessor owns becomes a named member of the transport tier.
>
> **As-built reconcile (BUILT, Director-verified).** The shipped `EchoWire.Result`
> (`echo/apps/echo_wire/lib/echo_wire/result.ex`) realizes the four-accessor contract with `classify/1`'s internal
> representation a **tagged tuple** (Mars's design-make, as specified): `{:ok, replies}` (clean) ·
> `{:transport_error, term}` · `{:server_error, oks, [{index, {:error_reply, msg}}]}`, where **`oks` is the FULL
> reply list** so the indices stay valid against it (`result.ex:104-111`). `server_errors/1` is the building block
> (`Enum.with_index |> flat_map`, 0-based ascending — `result.ex:87-94`) that `classify/1` and `error/1` reuse;
> `non_valkey_error/1` answers `nil` for an `{:ok, _}` even when it carries server errors (`result.ex:122-123`);
> `error/1` returns the transport `{:error, term}` on the `{:error, _}` clause, else the first `{:error_reply, _}`
> (`result.ex:134-141`). `{:error, {:server, _}}` is `eval/5`-exclusive (`connector.ex:76-77`) and unreachable
> through `Pipe` — recorded, not classified (the moduledoc says so; no `result.ex` clause emits a `{:server, _}`).
> **The honest INV6 reality (as-built, not an order-theorem):** transport-before-server ordering is **structurally
> enforced by the disjoint tuple shapes** — `error/1`'s two clauses match disjoint inputs (`{:error, _}` vs
> `{:ok, _}`), so **no single `exec` return exercises both branches** and there is **no order-mutation to kill**
> (unlike `ewr.1.1`'s positional accumulator, where reversal was a live mutation). The real net-zero proof is the
> **partition misclassify** mutation — blind `server_errors/1` (drop the `{:error_reply, _}` match) and the real
> `WRONGTYPE` `:valkey` story **dies** (`{:server_error, …}` collapses to `{:ok, …}`); the Director re-killed this
> independently. The gate is green: `echo_wire` offline partition suite passing (purity grep `0`,
> facade-freeze still **11**); the wire `:valkey` story suite green on `6390` (the real `WRONGTYPE` server-error
> split + the transport-tier path); the `echo_mq` conformance byte-stable (emq-owned count, currently 54); the
> partition misclassify mutation **KILLED**. The touch-set is the three create-locations
> (`result.ex` · `result_test.exs` · the `wire_pipe_error_*_story_test.exs` story tests) + the regenerated
> `docs/echo_mq/wire/stories/` — **no `pipe.ex` edit, no frozen-runtime edit, no Mix-task edit, `echo/mix.lock`
> unchanged**.

## Goal

`ewr.1.3` builds the wire's **error-discrimination surface**: an Elixir-idiomatic way to ask "did the transport
break, or did the server reject one or more commands?" of a `EchoWire.Pipe.exec/1` result, instead of every
caller re-deriving the discipline by hand — a `case` on `{:error, _}` for the transport tier *and* a separate
walk of the reply list for `{:error_reply, _}` slots, repeated at every call site. The wire already returns
everything needed: `ewr.1.1`'s closed error set established that the transport tier is `exec`'s `{:error, term}`
branch and the server tier is the in-band `{:error_reply, binary()}` value (`resp.ex:47`). So this rung adds
**no error handling to the wire** — it adds the *reader* that partitions a return `exec` already produces. The
reference is the valkey-go (rueidis) two-method discriminator on the result value
(`ValkeyResult.NonValkeyError()` `go/valkey-go/message.go:149-151` — the transport error only;
`ValkeyResult.Error()` `:154-161` — the transport error or the folded-in server error;
`(*ValkeyMessage).Error()` `:740-751` — a RESP error frame → a `*ValkeyError`), ported as functions over
`exec`'s return: `non_valkey_error/1` mirrors `NonValkeyError()`, `error/1` mirrors `Error()`.

## Rationale (5W)

- **Why** — the two-tier split is **already present in the as-built return** but **unnamed**: a caller who
  needs to branch on which tier broke must today re-parse `exec`'s return by hand — `{:error, :disconnected}` /
  `{:error, :overloaded}` / `{:error, {:version_fence, _}}` / `{:error, :empty_pipeline}` are the transport tier,
  while a successful `{:ok, [reply]}` may still carry a server rejection as an `{:error_reply, _}` slot buried in
  the reply list (e.g. a `WRONGTYPE`). The distinction is load-bearing — a transport failure on an idempotent
  batch is retryable; a server `WRONGTYPE` never is — yet there is no named vocabulary for it, so every consumer
  (`echo_mq` command sites, `echo_store`'s direct-Valkey paths, a future retry layer) re-derives the same two-
  part discrimination. rueidis answers exactly this with two methods on its result value; EchoWire has none.
- **What** — a new **pure** module `EchoWire.Result` carrying four **accessors** over `EchoWire.Pipe.exec/1`'s
  return (`{:ok, [reply]} | {:error, term}`). The accessors + the partition behaviour are the **frozen contract**;
  the wire format each returns is described by behaviour, not pinned as a literal:
  - **`classify/1`** — the **transport-vs-server partition**: it answers one of three outcomes — *clean* (the
    flush succeeded and no reply is a server error) · *transport-error* (the whole call failed — `exec`'s
    `{:error, term}` branch, carrying that term) · *server-error* (the flush succeeded but ≥1 reply is a server
    rejection, carrying the `:ok` replies and the indexed `[{index, {:error_reply, msg}}]` server-error slots).
    The **internal representation** of this three-way result — a tagged tuple (e.g. `{:ok, replies}` /
    `{:transport_error, term}` / `{:server_error, oks, server_errors}`) or a `%EchoWire.Result{}` struct — is
    **Mars's design-make**; the spec fixes the three outcomes and what each carries, never the tuple shape.
  - **`non_valkey_error/1`** — the **transport-tier question** (rueidis `NonValkeyError()`): `{:error, term}`
    when `exec` returned a transport failure, else `nil`. It reports a transport error *only* — a successful
    flush carrying server errors answers `nil` (a server error is not a transport error).
  - **`error/1`** — the **transport-or-server question** (rueidis `Error()`): the transport `{:error, term}` if
    present, else the **first** server `{:error_reply, msg}` if any, else `nil`. The single "did anything go
    wrong, of either tier?" question.
  - **`server_errors/1`** — the **per-reply lens**: maps a reply list (the `replies` of an `{:ok, replies}`) to
    `[{index, {:error_reply, msg}}]` — the server-error slots and their positions, `[]` when every reply is
    clean.
  The binding contract is the **four accessors + the partition behaviour** (and their runnable checks — asserted
  *through* the accessors, never against a literal return shape); the representation of `classify/1`'s result is
  delegated ([`ewr.1.3.design.md`](ewr.1.3.design.md), §3). The rung **also** ships a **BDD `:valkey` story
  layer** proving the classifier against a *real* server error.
- **Who** — every caller of `EchoWire.Pipe.exec/1` / `exec_txn/1` that needs to distinguish the tiers: the
  immediate consumers are `echo_mq`'s command sites and `echo_store`'s direct-Valkey paths; the headline forward
  consumer is a **retry layer** (transport-tier + idempotent ⇒ replayable; server-tier ⇒ never), which pairs
  this rung's discrimination with `ewr.1.2`'s `%Cmd{}` advisory `:readonly` flag. No downstream rung gates by
  name on `ewr.1.3` — it closes the Movement-I ergonomic core.
- **When** — Movement I, rung 3, the **last** ergonomic-core rung: after `ewr.1.1` (the `%Pipe{}` accumulator +
  `exec`) and `ewr.1.2` (the immutable command value). It depends only on `exec`'s frozen return, so it layers
  cleanly on the as-built floor and re-litigates neither predecessor. It is the **error half** of the core, as
  `ewr.1.2` is the command half.
- **Where** — the **module + pure tests live in `echo_wire`**: `echo/apps/echo_wire/lib/echo_wire/result.ex` (a
  **new** module beside the shipped `lib/echo_wire/pipe.ex`) + a new `test/echo_wire/result_test.exs` (the
  offline partition suite). The **BDD story tests live in `echo_mq`** (`echo_mq` depends on `echo_wire` —
  `echo/apps/echo_mq/mix.exs:31` `{:echo_wire, in_umbrella: true}` — so a story test can drive `EchoWire.Pipe` +
  `EchoWire.Result` together, where the reverse would invert the dependency):
  `echo/apps/echo_mq/test/stories/wire_pipe_error_*_story_test.exs`, harvested by the existing
  `echo_mq/test/stories/` glob that `mix echo_mq.stories` reads. The generated `.stories.md` land in the wire
  docs (`docs/echo_mq/wire/stories/`). The frozen `lib/echo_mq/` connector and the `lib/echo_wire.ex` facade are
  untouched; `lib/echo_wire/pipe.ex` is **not edited** (the classifier reads `exec`'s return, it does not change
  `exec`).

## Scope

- **In** — the `EchoWire.Result` module: `classify/1`, `non_valkey_error/1`, `error/1`, `server_errors/1`
  (the four-accessor contract over `exec`'s return); the transport-vs-server partition (its internal
  representation Mars's design-make); the per-reply index lens;
  the **purity** guarantee (no socket, no connector call — a function over a value); the offline partition suite
  in `echo_wire`; the **BDD story layer** in `echo_mq/test/stories/wire_pipe_error_*` (the `:valkey` proof: a
  real `WRONGTYPE` server error split from `:ok` replies, plus a transport-tier path) + the generated
  `.stories.md` written to `docs/echo_mq/wire/stories/`; the byte-stable re-pin of the facade-freeze and the
  conformance count.
- **Out** — any edit to `EchoWire.Pipe` (incl. `exec/1` — frozen this rung; the classifier wraps its return,
  never changes it); new `exec` variants / a bang flush (that is Arm 2, not the recommended arm); a transport-
  -tier-only or server-tier-only surface (those are Arms 3); an `eval/5`-aware classifier (the `{:error,
  {:server, _}}` term is `eval`-only — `connector.ex:76-77` — and unreachable through the Pipe surface);
  cluster-redirect sub-classification (`MOVED`/`ASK` as a finer sub-tag — the deferred seam, opened when a
  cluster-routing consumer exists); retry/replay behaviour itself (a later consumer of this discrimination, not
  this rung); any edit to the connector, RESP, Script, Pool, or the facade; any `echo_mq` **lib** edit; any new
  Lua.

## Deliverables

- **`EWR.1.3-D1` — the design-make gate (FIRST).** Before any artifact, re-probe the as-built floor (the lag-1
  law) and rule the decisions that are the implementor's, not the Operator's: (a) **confirm the verified server-
  -error shape** — that `EchoWire.Pipe.exec/1` (→ `via.pipeline/3`, `pipe.ex:503-504`) returns a server error
  ONLY as the in-band value `{:error_reply, binary()}` inside `{:ok, [reply]}`, NEVER `{:error, {:server, _}}`
  (which is `eval/5`-exclusive — `connector.ex:76-77`, `map_script_reply/1` `:87` — and unreachable through the
  Pipe); confirm `pipe_reply(:plain, replies) = {:ok, replies}` (`connector.ex:560`) and that `fill/5` pushes
  `{:error_reply, msg}` verbatim into the reply list (`connector.ex:573` → `resp.ex:47`); confirm
  `EchoMQ.Pool.pipeline/3` (`pool.ex:48`) is a pure pass-through (no re-map). (b) **the internal representation
  of `classify/1`'s return (DELEGATED to Mars's design-make).** The **frozen contract** is the four accessors +
  the partition behaviour (D2–D5); the representation `classify/1` returns — a tagged tuple (e.g. `{:ok, replies}`
  / `{:transport_error, term}` / `{:server_error, oks, server_errors}`) **or** a `%EchoWire.Result{}` struct — is
  the implementor's, and the gate checks run **through the accessors**, never against a pinned literal (the
  `ewr.1.1` precedent: the `%Pipe{via}` dispatch field was Mars's, the conn-or-pool *contract* was checked). The
  Director may rule the representation or leave it open. (c) the exact `oks` content in the *server-error* outcome
  — the reply list with the error slots elided, or the full list (the implementor's design-make; the indexed
  `server_errors` carries the errors either way). (d) place the module at `lib/echo_wire/result.ex` and the story
  tests at `echo_mq/test/stories/wire_pipe_error_*`. No `.ex`/test artifact predates this ledger entry.
- **`EWR.1.3-D2` — `classify/1`, the transport-vs-server partition.** `classify(exec_return)` over `{:ok,
  [reply]} | {:error, term}` answers exactly one of three outcomes: **clean** (no reply is an `{:error_reply,
  _}`; carries the reply list) · **transport-error** (the input was `{:error, term}` — the whole-call failure;
  carries that term) · **server-error** (the input was `{:ok, replies}` and ≥1 reply is `{:error_reply, _}`;
  carries the `:ok` replies and the indexed server-error slots `[{index, {:error_reply, msg}}]` in ascending
  index order). The function is **total** over `exec`'s return type and **pure** (no side effect); it does **not**
  call `exec`, the connector, or any socket — it reads the value it is given. **The wire format of the three-way
  result (a tagged tuple vs a `%EchoWire.Result{}` struct) is Mars's design-make (D1b)** — the spec fixes the
  three outcomes and what each carries, and the checks assert them through the accessors (e.g. via
  `non_valkey_error/1` / `server_errors/1` on the classified value, or by pattern-matching whichever
  representation ships), never a literal tuple.
- **`EWR.1.3-D3` — `non_valkey_error/1`, the transport tier (`NonValkeyError()`).** `non_valkey_error(exec_return)`
  answers `{:error, term}` when the input is `exec`'s transport branch (`{:error, term}`), else `nil` — INCLUDING
  `nil` for a successful flush that carries server errors (a server error is **not** a transport error; this is
  the rueidis `NonValkeyError()` semantics — `message.go:149-151` returns only `r.err`). The named members of the
  transport tier are the connector's vocabulary plus the Pipe's own: `:disconnected`, `:overloaded`,
  `{:version_fence, got}`, `:empty_pipeline` — and any other `{:error, term}` `exec` may surface.
- **`EWR.1.3-D4` — `error/1`, transport-or-server (`Error()`).** `error(exec_return)` answers the transport
  `{:error, term}` if present; else the **first** server error as `{:error_reply, msg}` (the lowest-index
  `{:error_reply, _}` in the reply list) if any; else `nil`. This is the single "did anything go wrong, of either
  tier?" question, the faithful port of rueidis `Error()` (`message.go:154-161`: `r.err` if non-nil, else
  `r.val.Error()`). Transport precedence over server is intrinsic — a transport failure means there is no reply
  list to inspect.
- **`EWR.1.3-D5` — `server_errors/1`, the per-reply lens.** `server_errors(reply_list)` maps a reply list (a
  bare `[RESP.reply()]`, as carried by `{:ok, replies}`) to `[{index, {:error_reply, msg}}]` — the `{:error_reply,
  _}` slots and their 0-based positions in ascending order, `[]` when every reply is clean. It is the building
  block `classify/1` uses for the `:server_error` case and a standalone tool for a caller holding a reply list.
  Pure; total over a list.
- **`EWR.1.3-D6` — purity + the frozen `exec/1`.** `EchoWire.Result` performs **no** I/O: no `Connector`/`Pool`
  call, no socket, no process. Every function is a deterministic transform of its argument. `EchoWire.Pipe.exec/1`
  (and `exec_txn`/`exec_noreply`) are **not edited** — the classifier reads their return; `pipe.ex` is unchanged
  by this rung. *Check:* `grep -E "Connector|Pool|gen_tcp|GenServer|pipeline\(" result.ex` is `0`; `git diff`
  shows no `pipe.ex` change.
- **`EWR.1.3-D7` — the gate.** The per-app ladder green from inside `echo/apps/echo_wire/`: `mix compile
  --warnings-as-errors`; the offline partition suite (`result_test.exs` — the three partition outcomes asserted
  **through the accessors** over hand-built `exec`-shaped returns, the transport/server/clean cases, the index
  lens, the `nil` answers); the facade-freeze test still green (11 verbs). **Then from `echo/apps/echo_mq/`** the `@tag :valkey` story suite on `6390` (the
  BDD round-trip proof) + `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` regenerating
  the `.stories.md` **idempotently** (the `--match wire_pipe` filter the program owns — the story files are named
  `wire_pipe_error_*` so `--match wire_pipe` scopes them; a regen rewrites only the wire features, never the
  sibling `docs/echo_mq/stories/`, AND the default no-`--match` path still emits all bus features and leaves
  `docs/echo_mq/stories/` git-clean — the shared-tool no-harm assertion); `Conformance.run/2` **byte-stable** (the
  run's count unchanged across the rung — emq-owned, currently 54, never a number the wire pins); a multi-seed
  sweep + the determinism-posture statement (no id-mint/process/lease → no ≥100 loop). The two-app ladder is
  intrinsic to the dep direction (the module in `echo_wire`, the story tests in `echo_mq` above it).

## Invariants

- **`EWR.1.3-INV1` — `exec/1` is frozen; the classifier is purely additive over its return.** `EchoWire.Pipe`
  is **not edited** this rung — `exec/1`'s `{:ok, [reply]} | {:error, term}` contract (`pipe.ex:500`) is
  byte-unchanged, and `EchoWire.Result` is a **new module** that READS that return, never a variant that changes
  it and never a `defdelegate` on the facade. *Check:* `git diff` touches no `lib/echo_wire/pipe.ex`; the
  `EchoWire` facade still exports exactly its 11 verbs (`echo_wire_facade_test.exs` unchanged, byte-identical to
  HEAD); `EchoWire.Result` is a standalone module, not referenced by `EchoWire` or `EchoWire.Pipe`.
- **`EWR.1.3-INV2` — additive; the frozen runtime is untouched; `echo_mq` is test-only.** No edit to
  `EchoMQ.Connector` / `RESP` / `Script` / `Pool`; no new Lua (`grep redis.call` on the lib diff is `0`); the
  `echo_mq` conformance stays **byte-stable** — the layer is *above* the conformance boundary, so the
  additive-minor *registration* law is **not engaged**: the wire registers **no scenario** and writes **no
  `registry.json`** (the ledger header records the absence). The **count is emq-owned, not the wire's to pin** —
  it has drifted 52→53→54 within this program's life (out of band), so the gate asserts byte-stability (the run's
  count unchanged across the rung — currently 54), never a pinned number. The `echo_mq` touch is **test-only**
  under
  `echo_mq/test/stories/` — and unlike `ewr.1.1`, **no** `echo_mq.stories.ex` Mix-task edit is needed (the
  `--match` filter already shipped). *Check:* `git diff` touches only new files under
  `echo/apps/echo_wire/lib/echo_wire/result.ex` + `echo/apps/echo_wire/test/echo_wire/result_test.exs` +
  `echo/apps/echo_mq/test/stories/wire_pipe_error_*_story_test.exs` + the regenerated
  `docs/echo_mq/wire/stories/`; **no** frozen-runtime `lib/` file of either app, **no** `pipe.ex`, the facade
  unchanged, `echo/mix.lock` unchanged.
- **`EWR.1.3-INV3` — the classifier is pure (a function over a value, never a wire call).** `EchoWire.Result`
  reads `exec`'s already-decoded return; it opens no socket, calls no `Connector`/`Pool` function, starts no
  process, and performs no round-trip. *Check:* `grep -E "Connector|Pool|:gen_tcp|GenServer\.|\.pipeline\("
  result.ex` is `0`; every function is referentially transparent (the same input gives the same output — the
  offline suite asserts this by feeding hand-built returns with no Valkey).
- **`EWR.1.3-INV4` — the partition is total and exhaustive over `exec`'s return.** `classify/1` answers exactly
  one of the three outcomes — **clean** / **transport-error** / **server-error** — for **every** value `exec/1`
  can return: no input falls through, no input matches two outcomes. A transport input (`{:error, term}`) →
  transport-error; an `{:ok, replies}` with zero `{:error_reply, _}` → clean; an `{:ok, replies}` with ≥1
  `{:error_reply, _}` → server-error. *Check (through the accessors, never a literal):* a property/coverage test
  feeds each return shape (a clean `{:ok, [...]}`, an `{:ok, [...]}` with one and with several `{:error_reply, _}`
  slots, each transport `{:error, term}` member) and asserts the outcome via the accessor pair — `non_valkey_error/1`
  is non-`nil` **iff** transport-error, `server_errors/1` on the classified replies is non-`[]` **iff**
  server-error, both `nil`/`[]` **iff** clean — so the check binds the partition behaviour, not whichever tuple or
  struct `classify/1` returns; a fall-through input is impossible by construction.
- **`EWR.1.3-INV5` — the two tiers are exactly the as-built shapes; the server tier is in-band only.** The
  **transport tier** is exactly `exec`'s `{:error, term}` branch (`:disconnected` / `:overloaded` /
  `{:version_fence, _}` / `:empty_pipeline` / any `{:error, term}`); the **server tier** is exactly the in-band
  `{:error_reply, binary()}` value (`resp.ex:47`) in a reply slot. The classifier introduces **no** new error
  term and does **not** synthesize `{:error, {:server, _}}` (that term is `eval/5`-exclusive — `connector.ex:76-77`
  — and unreachable through `EchoWire.Pipe`, which never flushes through `eval`). *Check:* `non_valkey_error/1`
  on a successful-flush-with-server-errors input answers `nil` (the server tier is not transport);
  `server_errors/1` finds the `{:error_reply, _}` slots and nothing else; no `result.ex` clause produces a
  `{:server, _}` tuple.
- **`EWR.1.3-INV6` — `error/1` orders transport before server (structurally), and `classify`/`error`/`non_valkey_error`
  agree.** `error/1` returns the transport `{:error, term}` when present (a transport failure means no reply list
  exists), else the first `{:error_reply, _}`, else `nil`. The three functions are **consistent**: when
  `classify/1` is transport-error, `non_valkey_error/1` returns that same `{:error, term}` and `error/1` returns
  it too; when `classify/1` is server-error, `non_valkey_error/1` returns `nil` and `error/1` returns the first
  `{:error_reply, _}`; when `classify/1` is clean, both `error/1` and `non_valkey_error/1` return `nil`.
  **As-built (the honest reconcile):** the transport-before-server ordering is **structurally enforced by the
  disjoint tuple shapes** — `error/1`'s two clauses match disjoint inputs (`{:error, _}` vs `{:ok, _}`,
  `result.ex:134-141`), so **no single `exec` return exercises both branches** and there is **no order-mutation
  to kill** (this is the delta from `ewr.1.1`, where the positional accumulator made reversal a live mutation).
  *Check:* a cross-consistency test asserts the three accessors agree on each return shape; and the standing
  net-zero proof for this rung is the **partition misclassify** mutation, not an order theorem — blind
  `server_errors/1` (drop the `{:error_reply, _}` match) and a test feeding a real server-error reply **KILLS**
  it (`{:server_error, …}` collapses to `{:ok, …}` and the `WRONGTYPE` story dies). The Director re-killed this
  mutation independently.
- **`EWR.1.3-INV7` — a generated story exists only because a real `:valkey` test passed, and the wire stories
  regenerate idempotently (the gate specifies its own liveness).** Each scenario in
  `docs/echo_mq/wire/stories/*.stories.md` for this rung is harvested from a real `EchoMQ.Story` `:valkey`
  ExUnit test under `echo_mq/test/stories/wire_pipe_error_*_story_test.exs` that drives `EchoWire.Pipe` +
  `EchoWire.Result` against Valkey on `6390` and asserts the observable split — and the **server-error story
  must provoke a REAL server error** (the `WRONGTYPE` provocation: `set(k, "v")` then `lpush(k, "x")` in one
  pipe, so Valkey itself returns `{:error_reply, "WRONGTYPE ..."}` in the second slot), then prove
  `classify/exec_return` returns `{:server_error, _, [{1, {:error_reply, "WRONGTYPE" <> _}}]}` and
  `non_valkey_error/1` returns `nil` — a no-op or a story that hand-builds the error without provoking it does
  **not** satisfy this letter. A transport-tier story proves the transport path (e.g. an empty pipe → `exec`
  returns `{:error, :empty_pipeline}` → `classify` returns `{:transport_error, :empty_pipeline}` and
  `non_valkey_error/1` returns `{:error, :empty_pipeline}`). *Check:* `mix echo_mq.stories --match wire_pipe
  --out docs/echo_mq/wire/stories` regenerates the wire `.stories.md` from `__stories__/0` **idempotently** (the
  committed dir equals a fresh `--match wire_pipe` generation **byte-for-byte**), the generated scenario set
  equals the `wire_pipe_error_*` test set one-for-one, and the default no-`--match` generation still emits all
  bus features leaving `docs/echo_mq/stories/` git-clean (the shared-tool no-harm assertion); the `:valkey`
  story suite is green from `echo/apps/echo_mq/`.
- **`EWR.1.3-INV8` — the two story layers are distinct and non-contradicting.** `specs/ewr.1/ewr.1.3.stories.md`
  is the **hand-authored USER stories** (the rung acceptance — Connextra, INVEST, Given/When/Then prose a person
  signs); `docs/echo_mq/wire/stories/*.stories.md` is the **GENERATED self-documenting proof** harvested from the
  as-built `_story_test.exs`. Neither is edited to fork from the body; the user-story scenarios name the same
  transport/server cases the generated stories prove. *Check:* the generated-stories directory and the
  user-stories file name the same two-tier case set; the body is the single authority both derive from.

**The closed error set (re-stated; this rung CLASSIFIES it, introduces nothing).** `EchoWire.Result` adds **no**
new error term. It partitions the set `ewr.1.1` closed:
- **Transport tier** (`exec`'s `{:error, term}` whole-call branch — rueidis `NonValkeyError()`):
  `{:error, :disconnected}` (socket loss; in-flight callers failed, never replayed — `connector.ex:197-198`/`:592`),
  `{:error, :overloaded}` (the `max_pending` backpressure — `connector.ex:234-237`), `{:error, {:version_fence,
  got}}` (the boot fence — `connector.ex:478`/`:483`), `{:error, :empty_pipeline}` (the Pipe's own empty-flush
  guard — `pipe.ex:501`/`:514`/`:527`), and any other `{:error, term}` `exec` surfaces.
- **Server tier** (the in-band value carried inside a successful `{:ok, [reply]}` — rueidis `Error()`'s
  folded-in `r.val.Error()`): `{:error_reply, binary()}` (`resp.ex:47`) in one or more reply slots — e.g.
  `WRONGTYPE`, `ERR`, a Lua-surfaced error.
- **Not reachable through the Pipe surface** (named for completeness, OUT of this rung): `{:error, {:server,
  msg}}` — the `eval/5`-exclusive server-error mapping (`connector.ex:76-77`), reached only via `EchoWire.script/2`
  → `Connector.eval/5`, never through `EchoWire.Pipe.exec`.

## Definition of Done

- [x] `EWR.1.3-D1` — the design-make was ruled and ledgered (the **verified server-error shape** confirmed at the
      as-built tree — in-band `{:error_reply, _}` only, never `{:error, {:server, _}}` on the Pipe path; the
      internal representation of `classify/1`'s return — Mars's design-make, realized as a **tagged tuple** with
      `oks` = the FULL reply list; the placement) *before* any `.ex`/test artifact existed.
- [x] `EWR.1.3-D2`/`D3`/`D4`/`D5` — `EchoWire.Result` ships `classify/1` (the total transport-vs-server
      partition — its internal representation a tagged tuple, Mars's design-make, checked through the accessors),
      `non_valkey_error/1` (transport only — `nil` for a server-error-carrying success), `error/1` (transport-or-
      -server, transport-first), and `server_errors/1` (the indexed per-reply lens), each pure and total
      (`result.ex:87-141`).
- [x] `EWR.1.3-D6` — purity holds (no `Connector`/`Pool`/socket/process — `grep` clean); `EchoWire.Pipe.exec/1`
      is **not edited** (`pipe.ex` byte-unchanged by this rung).
- [x] `EWR.1.3-INV1`/`INV2` — `exec/1` is frozen and the facade is still 11 verbs; no frozen-runtime edit; the
      `echo_mq` touch is **test-only** (no Mix-task edit needed — `--match` already shipped); no new Lua;
      conformance **byte-stable** (emq-owned count, never a number the wire pins — drifted 52→53→54 out of band);
      `echo/mix.lock` unchanged.
- [x] `EWR.1.3-INV3`/`INV4`/`INV5`/`INV6` — the classifier is pure; the partition is total + exhaustive over
      `exec`'s return; the two tiers are exactly the as-built shapes (server tier in-band only, no synthesized
      `{:server, _}`); `error/1` orders transport-before-server **structurally** (disjoint tuple clauses — no
      order-mutation exists) and the three accessors agree, with the **partition misclassify** mutation KILLED
      (the Director re-killed it independently).
- [x] `EWR.1.3-INV7`/`INV8` — every generated story has a passing `:valkey` test behind it, and the **server-
      error story provokes a REAL `WRONGTYPE`** (not a hand-built error); the wire stories regenerate
      idempotently and the bus stories dir stays git-clean (the shared-tool no-harm assertion); the user-story
      and generated-story layers name the same two-tier case set and neither forks the body.
- [x] `EWR.1.3-D7` — the two-app gate ladder is green (`echo_wire` compile warnings-clean + the offline
      partition suite + facade-still-11; from `echo_mq` the wire `:valkey` story suite + the idempotent `--match
      wire_pipe` regen + `Conformance.run/2` byte-stable (emq-owned count) + the partition misclassify mutation
      KILLED); the multi-seed sweep passes; the determinism posture is stated.

---

Stories: [`ewr.1.3.stories.md`](ewr.1.3.stories.md) · Agent brief: [`ewr.1.3.llms.md`](ewr.1.3.llms.md) ·
Runbook: [`ewr.1.3.prompt.md`](ewr.1.3.prompt.md) · Design (the fork — Operator rules):
[`ewr.1.3.design.md`](ewr.1.3.design.md) · Ledger: [`../progress/ewr-1-3.progress.md`](../progress/ewr-1-3.progress.md) ·
Predecessor: [`ewr.1.1.md`](ewr.1.1.md) (the closed error set) · Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md) ·
Method: [`../../../../aaw/aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md)
