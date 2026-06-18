# EWR.1.2 · the agent brief (LLM build brief)

> The build-grade brief `ewr.1.2` was built from and the verifier accepted against. Derived from
> [`ewr.1.2.md`](ewr.1.2.md) (the spec body — **authoritative**; this brief and the stories may lag it, and when
> they disagree the body wins). **Status: BUILT** — shipped green and Director-verified (the ruled arm, Arm 3 +
> full-cf, the Operator's ruling `2026-06-18`: [`ewr.1.2.design.md`](ewr.1.2.design.md) §4): `echo_wire`
> **109/0** facade-still-11 / `EchoWire.run` absent; the wire `:valkey` command stories **8/0**; conformance
> byte-stable (the count emq-owned); byte-equivalence proven; the INV3 + INV4 mutations KILLED. Mars **adopted**
> the ruling and did not re-open it.

## References (read first, in order)

1. **The ruling (the design doc)** — [`ewr.1.2.design.md`](ewr.1.2.design.md) §4: **Arm 3 + full-cf RULED** — a
   standalone fluent `EchoWire.Cmd` builder minting an immutable `EchoWire.Command` value carrying the **whole**
   `cf` flag vocabulary + the key-slot, with `EchoWire.Cmd.run/2`, + the one additive `Pipe.command/2` seam. The
   `cf` table (with bit-inclusion) and the load-bearing port fact (flags static per-verb, never parsed from
   parts) are in §4. Adopt; do not re-litigate. (The losing arms' cases stay in §2 as the record of why.)
2. **The body** — [`ewr.1.2.md`](ewr.1.2.md): the authoritative D1–D7, INV1–INV9, the closed error set, the
   Definition of Done.
3. **The shipped floor — RE-PROBE every anchor against the as-landed tree (the lag-1 law) before any decision or
   artifact:**
   - `EchoWire.Pipe` — `echo/apps/echo_wire/lib/echo_wire/pipe.ex` (shipped `ewr.1.1`): `%Pipe{conn, via,
     timeout, cmds}`; the curated six-family verbs; `command/2` at **`:490`** (`command(pipe, parts) when
     is_list(parts), do: add(pipe, parts)` — the escape hatch that appends a raw list, the seam this rung
     extends); the private `add/2` at **`:538`** (prepend-newest-first); `exec/1` at **`:503`**
     (`via.pipeline(conn, Enum.reverse(cmds), timeout)`); the `@type command :: [binary() | integer() | atom()]`
     at `:50` (the token shape `Command.parts` must match); the `via` opacity (no reference guard) — `run/2`
     mirrors it.
   - `EchoMQ.Connector.pipeline/3` — `echo/apps/echo_wire/lib/echo_mq/connector.ex:56` (the flush target,
     reached via `Pipe` + `Cmd.run/2`; **frozen**, do not edit); the "cannot know what is idempotent" note at
     `:21` (why the flags have no retry consumer yet); `:130`/`:125` the txn/noreply seams.
   - `EchoMQ.Pool.pipeline/3` — `echo/apps/echo_mq/lib/echo_mq/pool.ex:48` (round-robin; the `:via` target for
     `run/2` / `Pipe`).
   - `EchoMQ.RESP.reply()` — `resp.ex:30` (the reply union; `{:error_reply, _}` in-band at `:47`).
   - `EchoWire` facade — `lib/echo_wire.ex:19-31` (11 verbs), pinned by `test/echo_wire_facade_test.exs`. Do not
     grow it; `EchoWire.Command` / `EchoWire.Cmd` are **new modules**, and **`run/2` is on `EchoWire.Cmd`**, not
     a 12th facade verb (`EchoWire.run/2` must not exist).
   - **Conformance — `echo/apps/echo_mq/test/conformance_run_test.exs`** — the wire registers **no** scenario and
     writes **no** `registry.json`; the count is **emq-owned and NOT the wire's to pin** — it has drifted
     52 → 53 → 54 within this program's life (emq's out-of-band control-plane work). **Do not pin a number**; the
     check is "conformance is byte-stable from the wire's side". If the gate must cite the floor, read it fresh —
     the as-built count is currently **54** (`conformance.ex` "fifty-four scenarios").
   - The new module homes: `echo/apps/echo_wire/lib/echo_wire/command.ex` + `echo/apps/echo_wire/lib/echo_wire/cmd.ex`
     — **new**, beside the shipped `pipe.ex`.
4. **The valkey-go reference** — `go/valkey-go` (read-only, cited never copied) — the command core this rung
   ports:
   - `internal/cmds/cmds.go:117` — `type Completed struct { cs *CommandSlice; cf uint16 /*flags*/; ks uint16
     /*key slot*/ }` — **parts + flags + slot**, the exact model.
   - `internal/cmds/cmds.go:5-23` — the **full** `cf` flag constants, ALL ported (the depth ruling) **with the
     bit-inclusion preserved**: `optInTag = 1<<15` · `blockTag = 1<<14` · `readonly = 1<<13 | retryableTag` (a
     read is retryable) · `noRetTag = 1<<12 | readonly | pipeTag` · `mtGetTag = 1<<11 | readonly` · `scrRoTag =
     1<<10 | readonly` · `unsubTag = 1<<9 | noRetTag` · `pipeTag = 1<<8` · `retryableTag = 1<<7` · `staticTTLTag =
     1<<6`. (`InitSlot = 1<<14` / `NoSlot = 1<<15` are slot sentinels on `ks` — the `slot` field, **not** a `cf`
     flag.)
   - `internal/cmds/cmds.go:147-210` — the accessors → the predicates: `IsOptIn()` (:147) → `opt_in?/1`,
     `IsStaticTTL()` (:155) → `static_ttl?/1`, `IsBlock()` (:168) → `block?/1`, `NoReply()` (:173) → `noreply?/1`,
     `IsUnsub()` (:178) → `unsub?/1`, `IsReadOnly()` (:183) → `readonly?/1`, `IsWrite()` (:188) → `write?/1`,
     `IsPipe()` (:193) → `pipe?/1`, `IsRetryable()` (:198) → `retryable?/1`, `Commands()` (:205) → `parts/1`,
     `Slot()` (:210) → `slot/1`. (`mtGetTag`/`scrRoTag` reads → `mt_get?/1` / `scr_ro?/1`.) **Mirror the
     bit-inclusion in the predicate truth table.**
   - `internal/cmds/slot.go:5` — `slot(key) = crc16(key) & 16383`, or `crc16(key[{...}])` when a `{hashtag}` is
     present — the **pure key-slot function** `slot/1` ports. (CRC16-CCITT, the Redis-cluster standard; ground it
     against a known vector, e.g. `slot("123456789")` per the redis-cluster spec, and `slot("{a}b") ==
     slot("{a}c")`.)
   - **The builder is a TYPE-STATE chain** (`gen_string.go`): `func (b Builder) Set() (c Set)` builds the verb,
     `func (c Set) Key(key string) SetKey` (:1487), `func (c SetKey) Value(value string) SetValue` (:1956), `func
     (c SetValue) ExSeconds(seconds int64) SetExpirationExSeconds` (:1998), `func (c SetValue) Build() Completed`
     (:2043). The **load-bearing fact:** `func (b Builder) Get() (c Get) { c = Get{cs: get(), ks: b.ks, cf:
     int16(readonly)} ... }` (:231) — the flag is stamped because the *verb is* `GET`, at construction; `Set()`
     leaves `cf` zero (write). `Build()` returns `Completed{cs, cf, ks}` (gen_string.go:37). **Reimagine the
     type-state chain as `|>`** (`set("k") |> value("v") |> ex(60) |> build()`); dynamic Elixir cannot enforce
     the compile-time type-state, so `build/1` is a runtime closing token (a forgotten `build/1` fails at the
     `run/2`/`Pipe.command/2` boundary). The Elixir builder reads a **static per-verb table**, never parses
     `parts` (INV3).
   - The six family builders (the same `ewr.1.1` curated from): `gen_{string,generic,hash,list,set,sorted_set}.go`
     — for the per-verb membership + which verbs are `readonly` (the `cf: int16(readonly)` ones) vs `write` (cf
     zero) vs `block` (the `BLPOP`/`BRPOP`/`BLMOVE` family, `ToBlock`, cmds.go:105).
5. **The BDD story pipeline (ground it — do not re-invent; same as `ewr.1.1`):**
   - The DSL **`EchoMQ.Story`** — `echo/apps/echo_mq/test/support/echo_mq/story.ex`: `use EchoMQ.Story, feature:
     "...", async: false` emits `use ExUnit.Case` + `scenario/2,3` + `given_/when_/then_/and_/2` + `__stories__/0`;
     it does **NOT** inject `setup` — the test module writes its own (see the working `ewr.1.1` precedent
     `echo/apps/echo_mq/test/stories/wire_pipe_cache_aside_story_test.exs:19-24`: `Connector.start_link(port:
     6390)` + a unique key via `System.unique_integer([:positive])` + `on_exit` purge). `@moduletag :valkey`.
   - The generator **`mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories`** —
     `echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex`: reads `__stories__/0` over the glob
     `echo_mq/test/stories/*_story_test.exs` (offline), the **`--match wire_pipe` filter** (already shipped in
     `ewr.1.1`, F-1) scoping the FILE SET by `Path.basename` containing `wire_pipe` — so naming the new tests
     `wire_pipe_command_*_story_test.exs` puts them in scope **and** leaves the bus stories untouched. **The
     regen must be idempotent AND leave the sibling `docs/echo_mq/stories/` byte-unchanged** (the L-1 sharpening:
     a shared-tool edit/use must prove no harm to the tool's other consumers).
   - The placement is forced by the dep direction: `echo_mq` depends on `echo_wire`
     (`echo/apps/echo_mq/mix.exs:31`), so a wire story test in `echo_mq/test/stories/` can drive
     `EchoWire.Command`/`EchoWire.Cmd`/`EchoWire.Pipe`; the reverse would invert the dependency. The MODULES +
     pure construction tests stay in `echo_wire`.
6. **The roadmap seam (the advisory frame)** — [`../../ewr.roadmap.md`](../../ewr.roadmap.md) seam 4: the flags
   stay **advisory** — the connector does not act on them — until a retry / cluster-routing consumer gives them
   meaning. This rung ships the value + the full vocabulary + the builder + `run/2`, never a consumer (INV7).

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | Rule the design-make FIRST: the **flag representation** (static per-verb, never parsed from parts, **bit-inclusion preserved**; the `flags` SHAPE — `MapSet`/keyword/bitfield — is the implementor's), the **slot** as a pure key function, the **builder chain shape** (verb-opener / token-setter / `build/1`) + `run/2` dispatch, the **full-cf** membership, the curated membership across the six families, the placement (`command.ex` + `cmd.ex` + the one `pipe.ex:490` seam clause + `echo_mq/test/stories/wire_pipe_command_*`) — ledgered before any artifact | US-GATE, US1 | D1 (no artifact predates the ruling) |
| R2 | `%EchoWire.Command{parts, flags, slot}` struct — `parts` a flat `[binary\|integer\|atom]` (the `Pipe` token shape), `flags` the **full `cf` set** with bit-inclusion (10 tags, D1 shape), `slot` an integer `0..16_383` or `nil`; immutable pure data (no process, no I/O to build) | US1, US3, US4 | D2 |
| R3 | `EchoWire.Cmd` — the fluent builder across the six families: a verb-opener per principal verb + chainable token-setters + `build/1`; each `build/1` stamps `parts` (same rendering as `Pipe`), the **static per-verb flags** (read/write/block/cacheable, **never** parsed from parts), and `slot` (CRC16 over the key/`{hashtag}`, slot.go:5); an un-built builder is a distinct intermediate | US1, US2, US4, US12 | D3, INV3 |
| R4 | `EchoWire.Command.raw/1` (and optional `raw/2` for the slot key) appends a raw command-list verbatim, flags default **write/unknown**, slot from the identified key or `nil` — the curated builder is never a ceiling | US4, US6 | D4, INV6 |
| R5 | The **full** predicate set: `readonly?/1`·`write?/1`·`block?/1`·`pipe?/1`·`noreply?/1`·`static_ttl?/1`·`retryable?/1`·`opt_in?/1`·`mt_get?/1`·`unsub?/1`·`scr_ro?/1` (mirroring `cmds.go:147-210` + the bit-inclusion: `readonly?`⇒`retryable?`) + `slot/1` (`Slot`) + `parts/1` (`Commands`). **These are advisory — nothing in the wire calls them** | US3, US9 | D5, INV3, INV7 |
| R6 | `EchoWire.Cmd.run/2` runs a built command/list against a conn-or-pool via the opaque `via` (default Connector, Pool via `:via`; **never inspects** the reference; empty list → `{:error, :empty_pipeline}`); **on `EchoWire.Cmd`, NOT the facade** (`EchoWire.run/2` must not exist) | US5, US8 | D6, INV1, INV3, INV5 |
| R7 | The **ONE shipped-file edit**: one additive `EchoWire.Pipe.command/2` head accepting a `%Command{}` (extract `.parts`, `add/2` them) — the existing raw-list head + the struct/verbs/`add`/`exec` byte-identical to HEAD; `exec/1`'s return + wire shape frozen; the flags dropped at the seam (only `.parts` reaches the wire) | US7, US8 | D6, INV4, INV5 |
| R8 | The gate: compile warnings-clean; construction (offline) suites — parts/flags/slot pins + the **full** predicate truth table (incl. bit-inclusion) + the builder-chain assertions + the `command/2`-accepts-`%Command{}` equivalence + the `run/2`-vs-bare-verb `parts` equivalence; the `:valkey` byte-equivalence story suite; facade still 11 (`EchoWire.run/2` absent); **conformance byte-stable (the count emq-owned — not the wire's to pin)**; the `--match wire_pipe` regen idempotent **and the bus dir byte-unchanged**; multi-seed sweep + posture | US10, US-GATE, US13 | D7, INV1, INV2, INV8 |
| R9 | The advisory check: `grep -rE "readonly\?\|block\?\|static_ttl\?\|pipe\?\|noreply\?\|retryable\?\|Command\.slot\|\.flags" echo/apps/echo_wire/lib/echo_mq/` is `0` — no frozen-runtime file consults the flags (the value carries them for a future consumer) | US9 | INV7 |
| R10 | The **BDD story layer**: `EchoMQ.Story` `:valkey` tests under `echo_mq/test/stories/wire_pipe_command_*` build a `%Command{}` (via `Cmd`), run it (via `run/2` and `Pipe.command/2`), assert byte-equivalence to the bare verb + the flag/slot; `mix echo_mq.stories --match wire_pipe` regenerates the `.stories.md` idempotently + bus dir byte-unchanged; a generated story exists only because a passing test backs it; the generated + user-story layers name the same behaviour set and neither forks the body | US12, US13 | D7, INV8, INV9 |

## Execution topology

**Runtime shape.** `EchoWire.Command` is a **pure data module** (the value + predicates + `slot/1`/`parts/1`/
`raw/1`); `EchoWire.Cmd` is a **pure builder + a thin runner** (`run/2` is one `via.pipeline/3` over the
extracted parts). No process, no `GenServer`, no supervised child, no I/O beyond `run/2`'s single flush. A
`%Command{}` is an immutable value built by a synchronous chain (verb-opener → token-setters → `build/1` stamps
parts + the static flag + the slot). The integration is **construction-only**: `Pipe.command/2` gains one head
that extracts `.parts`; `exec` is untouched, so `Pipe`'s only effect remains `ewr.1.1`'s single `via.pipeline/3`
call. The flags are **advisory** — carried on the value, dropped at the seam and in `run/2`, read by nothing in
the wire (seam 4). So the `echo_wire` construction suites are offline and deterministic (the parts/flags/slot
pins, the full predicate truth table with bit-inclusion, the builder-chain assertions, the `cmds`-equality of a
`%Command{}` vs its raw list, the `run/2`-vs-bare-verb `parts` equality); the **`:valkey` band is the BDD story
layer in `echo_mq`** — it proves the round-trip is **byte-identical** to the bare verb (the advisory-flag
theorem) through both `run/2` and `Pipe.command/2`, and doubles as the generated `.stories.md`.

**Build-order task DAG.**
1. **D1 (the design-make)** — re-probe the floor; rule the flag representation (static per-verb, bit-inclusion) +
   the slot function + the builder chain shape + `run/2` dispatch + the full-cf membership + the curated
   membership + the placement; ledger the decisions. *Gate: no `.ex`/test artifact predates this.*
2. **D2/D4/D5 (the value)** — `command.ex`: the struct, the full `cf` flag set + the predicates + `slot/1`/
   `parts/1`, `raw/1`. *Gate: the offline value suite (flags/slot pins + the full predicate truth table incl.
   bit-inclusion) green.*
3. **D3/D6-run (the builder + runner)** — `cmd.ex`: the verb-openers + token-setters + `build/1` (stamping parts
   + static flags + slot) across the six families; `run/2` over the opaque `via`. *Gate: the offline builder
   suite (chain → expected `%Command{}`; un-built intermediate distinct; `run/2`-vs-bare-verb `parts` equality)
   green.*
4. **D6-seam (the Pipe seam)** — the one additive `Pipe.command/2` head. *Gate: `git diff pipe.ex` is
   added-lines-only; the offline `cmds`-equality assertion green.*
5. **D7 / the story layer** — the `wire_pipe_command_*` `:valkey` tests (byte-equivalence via `run/2` +
   `Pipe.command/2` + flag/slot); the `--match wire_pipe` regen (idempotent + bus dir byte-unchanged). *Gate: the
   two-app ladder green.*

**Files (the planned touch-set — NEW files + the ONE additive shipped-file head).**
- NEW `echo/apps/echo_wire/lib/echo_wire/command.ex` (the value module).
- NEW `echo/apps/echo_wire/lib/echo_wire/cmd.ex` (the fluent builder + `run/2`).
- NEW `echo/apps/echo_wire/test/echo_wire/command_test.exs` + `echo/apps/echo_wire/test/echo_wire/cmd_test.exs`
  (the offline construction suites).
- EDIT `echo/apps/echo_wire/lib/echo_wire/pipe.ex` — **the only shipped-file change**: one **additive function
  head** on `command/2` (`:490`) accepting `%EchoWire.Command{}`. Added lines only; the struct, the curated
  verbs, `add/2`, `exec/1` are byte-identical to HEAD.
- NEW `echo/apps/echo_mq/test/stories/wire_pipe_command_*_story_test.exs` (the BDD `:valkey` story tests;
  test-only, no `echo_mq` runtime touched).
- GENERATED `docs/echo_mq/wire/stories/wire-pipe-command-*.stories.md` + the updated README (by `mix
  echo_mq.stories --match wire_pipe`).

Nothing else — no frozen-runtime `lib/` edit (`Connector`/`RESP`/`Script`/`Pool`), no `lib/echo_wire.ex` facade
edit, no other `pipe.ex` line, no `echo_mq` lib runtime edit, `echo/mix.lock` unchanged.

> **Note on the `pipe.ex` touch.** The one shipped-file edit is a single **additive head** on the already-shipped
> `pipe.ex` `command/2` — the minimal possible integration of the command value with the batch surface. It is
> in-bounds because it is additive and preserves the frozen `exec` contract; INV2's check is "`git diff pipe.ex`
> is added-lines-only on `command/2`". This is the sharpest as-built fact for the Director to verify.

**The gate ladder (two-app, intrinsic to the dep direction).** From `echo/apps/echo_wire/`: re-probe
`.tool-versions`; `valkey-cli -p 6390 ping → PONG`; `TMPDIR=/tmp mix compile --warnings-as-errors`;
`TMPDIR=/tmp mix test` (the offline construction suites — parts/flags/slot pins + the full predicate truth table
incl. bit-inclusion + the builder-chain assertions + `command/2`-equivalence + `run/2`-vs-bare-verb `parts`
equality; the facade-freeze still 11, `EchoWire.run/2` absent). Then from `echo/apps/echo_mq/`: `TMPDIR=/tmp mix
test --include valkey` (the BDD byte-equivalence story suite drives a `%Command{}` via `run/2` + `Pipe.command/2`
vs the bare-verb pipe against `6390`); `TMPDIR=/tmp mix echo_mq.stories --match wire_pipe --out
docs/echo_mq/wire/stories` (regenerate the wire `.stories.md` **idempotently** — offline; run it twice + `diff
-r` clean; **assert `docs/echo_mq/stories/` is git-clean** after — the bus dir no-harm check); the facade-freeze
test green (`echo_wire`); **the `echo_mq` conformance byte-stable** (the count is emq-owned — read it fresh, not
pinned; currently 54); a multi-seed sweep
(`for s in 0 1 42 312540 999999; do TMPDIR=/tmp mix test --seed $s || break; done`, both suites). **Determinism
posture:** no id-mint/process/lease is introduced → the ≥100-iteration loop is NOT run; the multi-seed sweep +
this statement is the honest floor (see [`../../ewr.testing.md`](../../ewr.testing.md)). (A story scenario that
mints a branded id via `setup_all` remains a single deterministic mint per scenario, not the same-ms contention
the loop guards — but this rung mints none.)

**Framing constraints (held through the build).** No gendered pronouns for agents; no perceptual or
interior-state verbs ("sees"/"wants"/"feels"); no first-person narration ("we"/"I think"). NO-INVENT: every
public surface cited against `pipe.ex` + the valkey-go anchors; `EchoWire.Command` / `EchoWire.Cmd` are now
shipped (present-tense), their surface verified at `echo/apps/echo_wire/lib/echo_wire/{command,cmd}.ex`.

---

Body: [`ewr.1.2.md`](ewr.1.2.md) · Stories: [`ewr.1.2.stories.md`](ewr.1.2.stories.md) · Runbook:
[`ewr.1.2.prompt.md`](ewr.1.2.prompt.md) · Design (the ruling): [`ewr.1.2.design.md`](ewr.1.2.design.md) · Ledger:
[`../progress/ewr-1-2.progress.md`](../progress/ewr-1-2.progress.md)
