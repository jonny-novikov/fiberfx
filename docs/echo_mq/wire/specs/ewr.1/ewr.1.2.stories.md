# EWR.1.2 · user stories

> Who wants the fluent builder + the immutable command value + the full `cf` vocabulary, what they need, and how
> acceptance is known. Derived from [`ewr.1.2.md`](ewr.1.2.md) (**BUILT** — the body is authoritative; this file
> and the brief may lag it, and when they disagree the body wins). The acceptance below is the contract for the
> **ruled arm** (Arm 3 + full-cf, the Operator's ruling `2026-06-18`: [`ewr.1.2.design.md`](ewr.1.2.design.md)
> §4); it ran green at the build (`echo_wire` **109/0** facade-still-11 / `EchoWire.run` absent; the wire
> `:valkey` command stories **8/0**; conformance byte-stable; byte-equivalence proven; INV3 + INV4 mutations
> KILLED).
>
> **Two story layers, kept distinct (INV9).** THIS file is the **hand-authored USER stories** — the rung
> acceptance a person signs (Connextra, INVEST, Given/When/Then prose). The **generated**
> `docs/echo_mq/wire/stories/wire-pipe-command-*.stories.md` is the self-documenting proof harvested from the
> as-built `echo_mq/test/stories/wire_pipe_command_*_story_test.exs` BDD tests ("the tests written back to
> specs"). Both name the same command-core behaviour set; neither forks the body.
>
> **The load-bearing proof of an advisory-flag rung is byte-equivalence.** Because nothing in the wire reads the
> flags (seam 4), "the value is sound" is proven by the round-trip being **unchanged** — a built+flagged command
> (run via `EchoWire.Cmd.run/2` or via `Pipe.command/2`) runs byte-identically to its bare verb. Several stories
> below name that observable directly.

## EWR.1.2-US1 — build a command with the fluent builder, as an inspectable flag-bearing value

As an **Elixir caller of the wire**, I want a fluent `set |> value |> ex |> build` builder that mints a single
immutable command value carrying its own flags + key-slot, so that I assemble one command the rueidis way and
get a value I (or a future retry/routing layer) can inspect without re-parsing its tokens.

Acceptance criteria:
- Given the chain `EchoWire.Cmd.get("user:1") |> EchoWire.Cmd.build()`, when I evaluate it, then the result is a
  `%EchoWire.Command{}` whose `parts/1` is `["GET", "user:1"]`, whose `readonly?/1` is `true`, and whose `slot/1`
  is the CRC16 slot of `"user:1"`.
- Given the chain `EchoWire.Cmd.set("user:1") |> EchoWire.Cmd.value("alice") |> EchoWire.Cmd.ex(60) |>
  EchoWire.Cmd.build()`, when I evaluate it, then `parts/1` is `["SET","user:1","alice","EX","60"]` (the setters
  render as trailing tokens, the same rendering `Pipe` uses) and `write?/1` is `true`.
- Given an **un-built** builder value (the chain without the closing `build/1`), when I inspect it, then it is a
  distinct intermediate — not a `%Command{}` — and passing it to `run/2` / `Pipe.command/2` is a caller error (a
  forgotten `build/1` fails at the boundary, the runtime cost of the type-state token).
- Given any built `%Command{}`, when I inspect it, then it is pure immutable data — building it started no
  process and performed no I/O.

INVEST — independent (the founding command-core surface); testable offline (the builder-chain + parts/flags/slot
pins). Priority: must · Size: 5 · Implements deliverables: EWR.1.2-D2, EWR.1.2-D3, EWR.1.2-D5.

## EWR.1.2-US2 — the flag is the verb's static property, never parsed from the tokens

As a **future retry/routing consumer of the value**, I want a command's flags decided by the verb at build time,
not inferred by inspecting its assembled tokens, so that the flag is a trustworthy property and not a fragile
string-match.

Acceptance criteria:
- Given `EchoWire.Cmd.get(k) |> build()` for any key `k`, when I read `readonly?/1`, then it is `true` because
  the *verb* is `GET` (the rueidis per-verb stamp, `gen_string.go:231`) — not because `"GET"` was matched out of
  the parts.
- Given `EchoWire.Cmd.set(k) |> value(v) |> build()` for any key/value, when I read `write?/1`, then it is `true`
  — regardless of the key or value bytes.
- Given the builder's implementation, when it derives a flag, then it consults the static per-verb table, not a
  pattern-match on the `parts` list (INV3).

INVEST — independent; testable offline (the predicate truth table across verbs/keys). Priority: must · Size: 3 ·
Implements deliverables: EWR.1.2-D3. Encodes EWR.1.2-INV3.

## EWR.1.2-US3 — the full `cf` vocabulary, with the rueidis bit-inclusion

As a **consumer provisioning for the complete command core**, I want the whole rueidis `cf` flag set on the
value with its bit-inclusion preserved, so that every routing/retry/caching distinction rueidis encodes is
available to read — and the composite tags answer correctly.

Acceptance criteria:
- Given a built command, when I read its predicates, then the full set answers: `readonly?/1` · `write?/1` ·
  `block?/1` · `pipe?/1` · `noreply?/1` · `static_ttl?/1` · `retryable?/1` · `opt_in?/1` · `mt_get?/1` ·
  `unsub?/1` · `scr_ro?/1` (mirroring the rueidis accessors, `cmds.go:147-210`).
- Given a `readonly?`-true command, when I read `retryable?/1`, then it is **also** `true` — the rueidis
  bit-inclusion (`readonly = 1<<13 | retryableTag`, `cmds.go:8`); a read is retryable.
- Given a `noreply?`-true command (an `UNSUBSCRIBE`-family / `noRetTag` command), when I read `readonly?/1` and
  `pipe?/1`, then both are `true` (`noRetTag = 1<<12 | readonly | pipeTag`, `cmds.go:9`).
- Given the `InitSlot`/`NoSlot` sentinels, when the value is built, then they live on the `slot` field (the `ks`),
  **not** as a `cf` flag (`cmds.go:20-22`).

INVEST — independent; testable offline (the bit-inclusion truth table). Priority: must · Size: 3 · Implements
deliverables: EWR.1.2-D2, EWR.1.2-D5. Encodes EWR.1.2-INV3.

## EWR.1.2-US4 — the key-slot is computed from the key (the cluster-routing seam)

As a **future cluster-routing consumer**, I want the command value to carry the CRC16 key-slot of its key, so
that a later router can decide a node from the value without re-deriving the slot.

Acceptance criteria:
- Given a command on key `"user:1"`, when I read `slot/1`, then it is `crc16("user:1") & 16_383` (the rueidis
  `slot(key)`, `slot.go:5`).
- Given two keys sharing a `{hashtag}` — `"{user}:1"` and `"{user}:2"` — when I read `slot/1` of each, then the
  two slots are **equal** (the hashtag rule routes them to one slot).
- Given a keyless command (e.g. `EchoWire.Command.raw(["PING"])`), when I read `slot/1`, then it is `nil` (no key
  to hash).

INVEST — independent; testable offline against known CRC16 vectors. Priority: should · Size: 3 · Implements
deliverables: EWR.1.2-D2, EWR.1.2-D3, EWR.1.2-D4. Encodes EWR.1.2-INV3.

## EWR.1.2-US5 — run a built command against a connector or a pool (`EchoWire.Cmd.run/2`)

As a **caller running one command (or a list) directly**, I want `EchoWire.Cmd.run/2` to flush a built
`%Command{}` against a conn-or-pool, so that I can run a command value without threading a `Pipe`, and against
either deployment target without my code branching.

Acceptance criteria:
- Given a built command, when I `EchoWire.Cmd.run(cmd, conn)`, then it flushes the command's `.parts` once
  through `via.pipeline/3` and returns `{:ok, [reply]}` — the same shape `Pipe.exec/1` returns.
- Given a list of built commands, when I `EchoWire.Cmd.run([c1, c2], conn)`, then the replies map 1:1 in order;
  an empty list answers `{:error, :empty_pipeline}` (parity with `Pipe`).
- Given `run/2` with the target = a `Connector` and then a target = an `EchoMQ.Pool` (via the `:via` option),
  then both round-trip identically — `run/2` carries the dispatch and **never inspects** the reference (no
  `is_struct`/`is_atom`/module guard).
- Given the facade, when I check it, then `EchoWire.run/2` does **not** exist — `run/2` lives on `EchoWire.Cmd`,
  the facade stays at 11 verbs (INV1).

INVEST — independent; testable by a `:valkey` suite with both targets; encodes EWR.1.2-INV3 (opacity),
EWR.1.2-INV5, EWR.1.2-INV1. Priority: must · Size: 5 · Implements deliverables: EWR.1.2-D6.

## EWR.1.2-US6 — reach an un-modeled command as a value via the escape hatch

As a **caller needing a command the curated builder does not model**, I want a generic `EchoWire.Command.raw/1`,
so that the curated builder is convenience and never a ceiling.

Acceptance criteria:
- Given a raw command-list, when I call `EchoWire.Command.raw(["CLIENT","INFO"])`, then I get a `%Command{}` whose
  `parts/1` is `["CLIENT","INFO"]`, whose flags default to **write/unknown** (the conservative assume-mutating
  default), and whose `slot/1` is `nil` (no identifiable key).
- Given a curated verb and its raw equivalent — `EchoWire.Cmd.get(k) |> build()` and `EchoWire.Command.raw(["GET",
  k])` — when each flushes (via `run/2` or `Pipe.command/2`), then the replies are identical (the escape hatch is a
  complete substitute at the wire).

INVEST — independent; testable offline + `:valkey`; encodes EWR.1.2-INV6. Priority: must · Size: 2 · Implements
deliverables: EWR.1.2-D4.

## EWR.1.2-US7 — the command value flushes through the shipped Pipe, byte-identically (the seam)

As a **caller threading a batch**, I want `Pipe.command/2` to accept a built `%Command{}` wherever it accepts a
raw list, so that I can mix command values into a `ewr.1.1` pipe with no change to how the batch flushes.

Acceptance criteria:
- Given a pipe, when I call `Pipe.command(pipe, EchoWire.Cmd.set(k) |> value("alice") |> ex(60) |> build())`,
  then it appends the command's `.parts` exactly as the raw list would — the `%Command{}` and the equivalent raw
  list produce a **byte-identical** `cmds` entry.
- Given a pipe built through `%Command{}` values and the equivalent pipe built through `ewr.1.1`'s bare `Pipe`
  verbs, when each `exec`s on `6390`, then the reply lists are **identical** — appending a flagged command
  changes nothing observable, because the flags are advisory and dropped at the seam (only `.parts` reaches the
  wire).
- Given the seam, when I diff `pipe.ex` against HEAD, then the only change is **one added function head** on
  `command/2` — the struct, the curated verbs, `add/2`, and `exec/1` are byte-identical.

INVEST — independent; testable offline (the `cmds`-equality assertion) + `:valkey` (the equivalence round-trip);
encodes EWR.1.2-INV4, EWR.1.2-INV5. Priority: must · Size: 5 · Implements deliverables: EWR.1.2-D6.

## EWR.1.2-US8 — `exec`'s shipped contract is untouched

As the **caller relying on `ewr.1.1`'s flush**, I want this rung to leave `exec`/`exec_txn`/`exec_noreply`
exactly as shipped, so that the command core adds construction + a thin `run/2` only, never a second
pipelining/retry/routing behaviour.

Acceptance criteria:
- Given a pipe carrying `%Command{}`-built commands, when I `exec/1`, then the return is `{:ok, [reply]}` /
  `{:error, term}` in the `ewr.1.1` shapes, the empty pipe still answers `{:error, :empty_pipeline}`, and
  `exec`'s body is byte-identical to HEAD.
- Given the same pipe against a `Connector`, when I `exec_txn/1`, then it flushes via `transaction_pipeline/3`
  unchanged (Connector-only; out of contract for a pool, as in `ewr.1.1`).
- Given `EchoWire.Cmd.run/2`, when I inspect its body, then it reduces to one `via.pipeline/3` call — it adds no
  pipelining/retry/routing (the flags are advisory).

INVEST — independent; testable by the `:valkey` suite + a `pipe.ex`/`run/2` body inspection; encodes EWR.1.2-INV5.
Priority: must · Size: 2 · Implements deliverables: EWR.1.2-D6.

## EWR.1.2-US9 — the full `cf` flags are advisory this rung (no wire consumer)

As the **wire's steward**, I want the whole vocabulary carried but **not acted on** until a consumer exists, so
that the complete flag set ships ahead of its readers without changing wire behaviour or freezing a contract a
consumer would contradict.

Acceptance criteria:
- Given the build, when I `grep` the frozen runtime (`echo/apps/echo_wire/lib/echo_mq/`) for any flag read
  (`readonly?` / `block?` / `static_ttl?` / `pipe?` / `noreply?` / `retryable?` / `Command.slot` / `.flags`), then
  the count is `0` — no dispatch path consults the flags.
- Given a `readonly?`/`retryable?`-true command run across a simulated reconnect, when the connector loses the
  socket, then it still fails `:disconnected` without replay (the flag is *not* yet a retry signal —
  connector.ex:21); the advisory status is a documented fact (seam 4), not a half-built consumer.

INVEST — independent; testable by the grep + the standing connector behaviour; encodes EWR.1.2-INV7. Priority:
must · Size: 1 · Implements deliverables: EWR.1.2-D5.

## EWR.1.2-US10 — the additive guarantee holds (the frozen floor; conformance byte-stable, the count emq-owned)

As the **wire's steward**, I want this rung to leave the frozen wire and its truth row untouched, so that the
complete command core costs nothing in conformance or facade surface.

Acceptance criteria:
- Given the build, when the facade-freeze test runs, then `EchoWire` still exports exactly its 11 verbs
  (`echo_wire_facade_test.exs` unchanged; `EchoWire.run/2` does not exist).
- Given the build, when conformance runs, then it stays **byte-stable** — the wire registers no scenario and
  writes no `registry.json`; the count is **emq-owned** (it has drifted 52 → 53 → 54 within this program's life,
  from emq's out-of-band control-plane work — not the wire's to pin).
- Given the lib diff, when `grep redis.call` runs, then the count is `0`; no file under `lib/echo_mq/` is edited;
  `echo/mix.lock` is unchanged; the only `pipe.ex` change is the one additive `command/2` head.

INVEST — independent; testable by the standing suites + the diff; encodes EWR.1.2-INV1, EWR.1.2-INV2. Priority:
must · Size: 1 · Implements deliverables: EWR.1.2-D7.

## EWR.1.2-US11 · EWR.1.2-US-GATE — the Valkey gate, specification by example

As the **Operator/verifier**, I want the command-core equivalence proven against Valkey on `6390`, so that
acceptance is a runnable artifact, not a description.

Acceptance criteria:
- Given Valkey up on `6390` (`valkey-cli -p 6390 ping → PONG`), when the `@tag :valkey` story suite runs, then:
  a `%Command{}`-built command run via `EchoWire.Cmd.run/2` and the same command composed via `Pipe.command/2`
  both return **identical** replies to the equivalent bare-verb `Pipe` across the patterns (cache-aside, counter,
  leaderboard, hash, set-membership); a `raw/1`-built command matches its curated form; and the value's
  `readonly?`/`write?`/`retryable?`/`slot` is the expected one for each verb.
- Given the full ladder, when it completes, then compile is warnings-clean, the facade is 11 verbs, conformance
  is byte-stable (the count emq-owned — currently 54), the `--match wire_pipe` regen is idempotent and leaves the
  bus dir byte-unchanged, and the multi-seed sweep passes.

INVEST — the standing gate; encodes every INV. Priority: must · Size: 3 · Implements deliverables: EWR.1.2-D7.

## EWR.1.2-US12 — each curated family's flag/slot proven, and the equivalence written back from the tests

As a **caller learning the command core**, I want each data family's principal verbs proven to flush identically
to their bare-`Pipe` form (with the right flag/slot), through both `run/2` and `Pipe.command/2`, and the proof
generated from the passing tests, so that the command core is demonstrably equivalent and the example is the
documentation.

Acceptance criteria — each a `EchoMQ.Story` `:valkey` scenario building a command via `EchoWire.Cmd`, running it
(via `run/2` and via `Pipe.command/2`), and asserting equivalence + the flag/slot:
- **cache-aside (strings):** Given a cold key, when `Cmd.set(k) |> value(v) |> ex(60) |> build()` then `Cmd.get(k)
  |> build()` run, then the replies equal the bare-`Pipe` form `["OK", v]`, `set` is `write?` and `get` is
  `readonly?` (and `retryable?`).
- **counter (atomic-updates):** Given a counter key, when `Cmd.incr(c) |> build()` runs three times, then the
  replies are `[1, 2, 3]` (identical to the bare form) and `incr` is `write?`.
- **leaderboard (sorted sets):** Given a board key, when `Cmd.zadd(b) |> score(10, "a") |> build()` / `... score(20,
  "b") ...` then `Cmd.zrevrange(b) |> range(0, -1) |> build()` run, then the order is `["b","a"]` (identical to the
  bare form), `zadd` is `write?` and `zrevrange` is `readonly?`. *(As-built RESP3: `zscore` returns a double; the
  story asserts that reality, as in `ewr.1.1`.)*
- **set-membership (sets):** Given a set key, when `Cmd.sadd(s) |> member(x) |> build()` then `Cmd.sismember(s) |>
  member(x) |> build()` run, then the replies are `1` then `1` (identical to the bare form), `sadd` is `write?`
  and `sismember` is `readonly?`.
- **hash object (hashes):** Given an entity key, when `Cmd.hset_all(h, %{...}) |> build()` then `Cmd.hgetall(h) |>
  build()` run, then the map round-trips identically to the bare form, `hset_all` is `write?` and `hgetall` is
  `readonly?`.
- **escape-hatch + slot:** Given `EchoWire.Command.raw(["GET", k])` and `Cmd.get(k) |> build()`, when each runs,
  then the replies are identical; and `Command.slot(Cmd.get("{user}:1") |> build()) == Command.slot(Cmd.get("{user}:2")
  |> build())` (the hashtag rule).

INVEST — independent (each family is its own scenario); testable only by a `:valkey` suite (the proof is the live
equivalence round-trip); encodes EWR.1.2-INV4, EWR.1.2-INV6, EWR.1.2-INV8, and exercises D3 across the families.
Priority: must · Size: 5 · Implements deliverables: EWR.1.2-D3, EWR.1.2-D6.

## EWR.1.2-US13 — the stories are written back from the as-built tests (the proof, not prose)

As the **Operator/verifier reading the spec docs**, I want the command-core story documents generated from the
passing tests rather than hand-written, so that a story is true by construction — it exists only because a
`:valkey` test compiled and passed, and the regen harms no sibling program's stories.

Acceptance criteria:
- Given the `echo_mq/test/stories/wire_pipe_command_*_story_test.exs` BDD suite green on `6390`, when I run
  `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories`, then
  `wire-pipe-command-*.stories.md` + the README catalogue are written, and the generated scenario set equals the
  test scenario set one-for-one (every story has a live test behind it).
- Given the committed `docs/echo_mq/wire/stories/`, when a fresh `--match wire_pipe` generation runs, then the
  output equals it **byte-for-byte** (idempotent — the `--match` filter touches only the wire features), AND the
  sibling `docs/echo_mq/stories/` (the bus program's stories) is **byte-unchanged** by the regen (the shared-tool
  no-harm assertion — L-1 sharpening).
- Given a story document, when it is inspected, then no scenario lacks a backing test — a no-op or a
  hand-authored story does not satisfy INV8.
- Given this (generated) layer and the hand-authored user-story layer (this file), when both are read, then they
  name the same command-core behaviour set and neither contradicts the body (INV9).

INVEST — independent; testable by the generator + a diff of story-vs-test scenario sets + the bus-dir
byte-unchanged check; encodes EWR.1.2-INV8, EWR.1.2-INV9. Priority: must · Size: 2 · Implements deliverables:
EWR.1.2-D7.

---

Coverage: D1→US-GATE/US1 (the design-make precedes all; the flag representation + builder shape ruled) ·
D2→US1/US3/US4 · D3→US1/US2/US4/US12 · D4→US4/US6 · D5→US1/US3/US9 · D6→US5/US7/US8/US12 · D7→US10/US-GATE/US13 ·
INV1→US5/US10 · INV2→US10 · INV3→US2/US3/US4/US5 · INV4→US7/US12 · INV5→US5/US7/US8 · INV6→US6/US12 · INV7→US9 ·
INV8→US12/US13 · INV9→US13.

Body: [`ewr.1.2.md`](ewr.1.2.md) · Design (the ruling):
[`ewr.1.2.design.md`](ewr.1.2.design.md) · Testing: [`../../ewr.testing.md`](../../ewr.testing.md)
