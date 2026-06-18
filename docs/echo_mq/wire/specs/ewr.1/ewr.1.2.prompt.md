# EWR.1.2 · the x-mode orchestration runbook — the fluent builder + the immutable command value + the full `cf` vocabulary

> **Status: BUILT — the runbook the `ewr.1.2` build run executed (shipped green, Director-verified).** The fork
> was RULED (Arm 3 + full-cf). Its inputs were this rung's triad ([`ewr.1.2.md`](ewr.1.2.md) authoritative, plus
> [`ewr.1.2.stories.md`](ewr.1.2.stories.md) and [`ewr.1.2.llms.md`](ewr.1.2.llms.md)) and the ruled design
> [`ewr.1.2.design.md`](ewr.1.2.design.md) §4. The app is `echo_wire` (+ the `echo_mq` story tests, test-only);
> the canon is [`../../ewr.roadmap.md`](../../ewr.roadmap.md). **The Operator ruled Arm 3 + full-cf-now
> (`2026-06-18`)** — not Venus's Arm 1 + minimal recommendation; the triad was authored to the ruling and Mars
> adopted it. **Outcome:** `echo_wire` **109/0** (facade still 11, `EchoWire.run` absent), the wire `:valkey`
> command stories **8/0**, conformance byte-stable (the count emq-owned), byte-equivalence proven, the INV3 + INV4
> mutations KILLED.

## The rung in one paragraph

Build the **complete rueidis-faithful command core** as two new pure modules in `echo/apps/echo_wire/lib/echo_wire/`:
**`EchoWire.Command`** (`command.ex`) — the immutable value `%Command{parts, flags, slot}`, the faithful port of
rueidis `Completed` (`cmds.go:117`), carrying the **full `cf` flag vocabulary** (`cmds.go:5-23`, all ten tags
with the bit-inclusion preserved) + the **key-slot** (CRC16 over the key/`{hashtag}`, `slot.go:5`), the full
predicate set (`readonly?` · `write?` · `block?` · `pipe?` · `noreply?` · `static_ttl?` · `retryable?` ·
`opt_in?` · `mt_get?` · `unsub?` · `scr_ro?`) + `slot/1` + `parts/1`, and a `raw/1` escape hatch; and
**`EchoWire.Cmd`** (`cmd.ex`) — the **fluent builder** `EchoWire.Cmd.set("k") |> value("v") |> ex(60) |> build()`
(the rueidis type-state chain reimagined as `|>`) across the six Valkey data families, **plus `EchoWire.Cmd.run/2`**
running a built command (or list) against a conn-or-pool through the opaque `via` dispatch (`run/2` on
`EchoWire.Cmd`, **NOT** a 12th facade verb). It integrates with the as-built `EchoWire.Pipe` (`ewr.1.1`) by **one
additive seam**: `EchoWire.Pipe.command/2` (`pipe.ex:490`) accepts a `%Command{}` (extracting `.parts`); `exec/1`
is untouched. **The flags are advisory** (seam 4 — no retry/cluster/caching consumer exists yet); they are
carried, and the proof the value is sound is **byte-equivalence** (a built+flagged command, run via `run/2` or
`Pipe.command/2`, runs identically to the bare verb). This is **design-Arm B realized** — the additive
command-value sibling to `Pipe`, with `Pipe` staying the primary batch surface. The rung **also** ships a **BDD
story layer**: `EchoMQ.Story` `:valkey` tests under `echo_mq/test/stories/wire_pipe_command_*` build a
`%Command{}`, run it both ways, assert byte-equivalence + the flag/slot, and generate self-documenting
`.stories.md` to `docs/echo_mq/wire/stories/`. Purely additive: the frozen connector/RESP/Script/Pool are reused,
the 11-verb facade is untouched (`EchoWire.run/2` does not exist), no Lua enters the wire, the **only**
shipped-file edit is one additive `Pipe.command/2` head, no `echo_mq` lib runtime is edited (story tests are
test-only), and the conformance **stays byte-stable — the wire registers no scenario and writes no
`registry.json`; the count is emq-owned (it has drifted 52 → 53 → 54 within this program's life — not the wire's
to pin)**.

## Mode

**Flat-L2**, the five-stage shape: **Mars-1** (design-make + build) → **Director** solo review (independent gate
re-run on Valkey 6390 + an adversarial probe + a net-zero mutation spot-check) → **Mars-2** (remediate + harden +
test) → **Venus** (post-build specs reconcile, body → as-built) → **Director** (closure + one ratifying LAW-4
pathspec commit). **Risk tier LOW** — two new pure modules above the wire + one additive head on a shipped
function: no process, no lease, no state transition, no auth/deploy/network surface, no frozen-runtime edit. The
command value + builder are pure data + a thin `run/2`; the flags are advisory (read by nothing); the `echo_mq`
touch is **test-only** (`test/stories/`, no lib). **The two care-points** are (a) the single `pipe.ex`
`command/2` edit — it touches a shipped file, so the Director's adversarial probe must confirm `git diff pipe.ex`
is **added-lines-only** on `command/2` and `exec`/the struct/the verbs/`add` are byte-identical, and (b)
`EchoWire.Cmd.run/2` must be on `EchoWire.Cmd`, not the facade (`EchoWire.run/2` must not exist — INV1). **No
Apollo charter** in the per-rung pipeline (the solo Director review + Venus's independent reconcile are the rigor
floor); Apollo mentors out of band. Scope slug: **`ewr-1-2`** (dashed, no dots — the aaw scope slug constraint).
Operator: `jonny`. Workspace: **`echo/apps/echo_wire` (the two modules + the one `pipe.ex` head) + `echo/apps/echo_mq`
(the story tests, test-only)** — the two-app boundary is Operator-sanctioned for this rung and intrinsic to the
dep direction. Ledger: [`../progress/ewr-1-2.progress.md`](../progress/ewr-1-2.progress.md).

## Stage 0 — the fork is RULED (no open Operator gate)

There is **no open Operator fork** — the Stage-1 gate is reachable. The Operator ruled (`2026-06-18`,
[`ewr.1.2.design.md`](ewr.1.2.design.md) §4):
- **The integration arm: Arm 3** — a standalone `EchoWire.Cmd` fluent builder minting an immutable
  `EchoWire.Command` value, + `EchoWire.Cmd.run/2`, + the one additive `Pipe.command/2` seam. (Not Arm 1 — the
  value-only minimal seam Venus recommended; not Arm 2 — the verb-rewrite.)
- **The vocabulary depth: full-cf-now** — the whole rueidis `cf` flag set (`cmds.go:5-23`) ported onto the value,
  with the bit-inclusion preserved. (Not minimal-now.)

Mars **adopts** both and does not re-litigate them. (Venus's recommendation was Arm 1 + minimal-now; the Operator
ruled otherwise, and the ruling governs — the design doc records both the recommendation and the ruling.)

## The design-make — the relocated gate (what Mars-1 rules, not re-litigates)

These are the implementor's to settle and log as `tool_x_decision`s at the top of the build, **before** any
artifact:
1. **The flag representation** — the **binding contract** is that a command's flags are derived from a **static
   per-verb property** at build time (the rueidis `Builder.<Verb>()` stamp, `gen_string.go:231` — `Get()` stamps
   `readonly`, `Set()` leaves cf zero), **never** by parsing the assembled `parts`; the **rueidis bit-inclusion
   is preserved** (`readonly` ⊇ `retryable`; `noRetTag` ⊇ `readonly | pipe`; `unsub` ⊇ `noreply` — so a
   `readonly?` command answers `retryable?` true); the `slot` is `crc16(key | {hashtag}) & 16_383` (`slot.go:5`),
   pure in the key. The exact SHAPE — `flags` as a `MapSet` of atoms, a keyword, or a bitfield integer mirroring
   `cf`; the per-verb table's form; the un-built-builder representation — is the implementor's design-make.
2. **The full-cf membership** — ALL ten tags (`opt_in` / `block` / `readonly` / `noreply` / `mt_get` / `scr_ro` /
   `unsub` / `pipe` / `retryable` / `static_ttl`, `cmds.go:5-23`) with their predicates. (`InitSlot`/`NoSlot` are
   slot sentinels on `ks`, not `cf` flags.) `EchoWire.Command`/`EchoWire.Cmd` are NOT arity-frozen (not the
   facade), so per-verb arities + the opener/setter split are the implementor's; `Command.raw/1` makes the
   boundary non-binding.
3. **The builder chain shape** — the `set |> value |> ex |> build` surface (the verb-opener returning an un-built
   builder, the chainable token-setters appending tokens, `build/1` freezing a `%Command{}`), reimagining the
   rueidis type-state chain (`Set → SetKey → SetValue → Build`, `gen_string.go:1487,1956,1998,2043`) as `|>`;
   `build/1` is a runtime closing token (dynamic Elixir has no compile-time type-state).
4. **`run/2`'s dispatch** — `EchoWire.Cmd.run(cmd_or_list, conn_or_opts)` mirroring `Pipe`'s opaque `via` (default
   `EchoMQ.Connector`, `EchoMQ.Pool` via `:via`; never inspect the reference; empty list → `{:error,
   :empty_pipeline}`). On `EchoWire.Cmd`, NOT the facade.
5. **The seam shape** — the one additive `Pipe.command/2` head: `def command(pipe, %EchoWire.Command{parts:
   parts}), do: add(pipe, parts)` placed beside the existing `command(pipe, parts) when is_list(parts)` head at
   `pipe.ex:490` — added lines only, the rest of `pipe.ex` byte-identical.
6. **Placement** — `command.ex` + `cmd.ex` + the offline construction tests `test/echo_wire/command_test.exs` +
   `cmd_test.exs`; the **BDD story tests at `echo_mq/test/stories/wire_pipe_command_*`** (test-only, forced by the
   dep direction), generated to `docs/echo_mq/wire/stories/` by `mix echo_mq.stories --match wire_pipe`.

## The as-built floor (RE-PROBE at build time — the lag-1 law)

- `echo/apps/echo_wire/lib/echo_wire/pipe.ex`: `command/2` at **`:490`** (the raw-list escape hatch — the seam);
  `add/2` at **`:538`** (prepend-newest-first); `exec/1` at **`:503`** (`via.pipeline(conn, Enum.reverse(cmds),
  timeout)`); the `@type command` at `:50`; the `via` opacity (no reference guard — `run/2` mirrors it). **Do not
  edit any line but the one new `command/2` head.**
- `connector.ex:56` `pipeline/3` · `:21` "cannot know what is idempotent" (the why-no-retry-consumer fact) ·
  `:130` `transaction_pipeline/3` · `:125` `noreply_pipeline/3`. **Frozen.** `pool.ex:48` `pipeline/3` (the
  `:via` target).
- `resp.ex:30` the `reply()` type (`{:error_reply, _}` in-band at `:47`).
- `lib/echo_wire.ex:19-31` the 11 frozen verbs; `test/echo_wire_facade_test.exs` the freeze (`EchoWire.run/2`
  must stay absent).
- **`echo_mq/test/conformance_run_test.exs` `Conformance.run/2`** — the wire registers NO scenario and writes NO
  `registry.json`; the count is **emq-owned and NOT the wire's to pin** (it has drifted 52 → 53 → 54 within this
  program's life — emq's out-of-band control-plane work). Read it fresh; the check is "byte-stable from the wire's
  side". The as-built count is currently **54**.
- `echo_mq/mix.exs:31` `{:echo_wire, in_umbrella: true}` (the dep direction that forces the story-test home).
- `echo_mq/test/support/echo_mq/story.ex` the `EchoMQ.Story` DSL (no auto-`setup` — the test writes its own, per
  `echo_mq/test/stories/wire_pipe_cache_aside_story_test.exs:19-24`); `echo_mq/lib/mix/tasks/echo_mq.stories.ex`
  the generator (the `--match wire_pipe` filter + glob `test/stories/*_story_test.exs`, `--out DIR`, default
  `docs/echo_mq/stories`).
- `go/valkey-go/internal/cmds/cmds.go:117` (`Completed`), `:5-23` (the **full** `cf` consts + bit-inclusion),
  `:147-210` (accessors → predicates + `Slot`); `internal/cmds/slot.go:5` (`slot(key)`);
  `internal/cmds/gen_string.go:231` (the per-verb flag stamp), `:1487,1956,1998,2043,37` (the type-state chain +
  `Build()`); the six `gen_*.go` family builders.

## The pipeline — five stages, Director-in-loop

1. **Stage 1 — Mars-1 (design-make + build).** Re-probe the floor (incl. the full `cf` block + the type-state
   chain + `slot.go` + the story DSL/task); log the design-make decisions (the flag representation — static
   per-verb, bit-inclusion; the builder chain shape; `run/2` dispatch; the full-cf membership; the seam shape);
   build `EchoWire.Command` (D2/D4/D5 — the value, the full `cf` set + predicates, `raw/1`) + `EchoWire.Cmd`
   (D3/D6-run — the fluent builder across the six families + `run/2`); add the **one** `Pipe.command/2` head
   (D6-seam) — verify `git diff pipe.ex` is added-lines-only; write the offline construction suites (`echo_wire`
   — parts/flags/slot pins + the full predicate truth table incl. bit-inclusion + builder-chain assertions +
   `command/2`-equivalence + `run/2`-vs-bare-verb `parts` equality); write the **BDD byte-equivalence story
   tests** (`echo_mq/test/stories/wire_pipe_command_*`, each with its own `setup`) per D7 and run `mix
   echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories` (the `--match` filter scopes the regen to
   the wire features — idempotent, bus dir untouched); run the Stage-1 gate (compile + smoke, both apps). Report
   to the ledger `{ewr-1-2-report}` (a `Y-n`).
2. **Stage 2 — Director solo review.** Independent two-app gate re-run on 6390; an **adversarial probe** (the
   headline risks: is `git diff pipe.ex` truly added-lines-only on `command/2`, with `exec`/the struct/the
   verbs/`add` byte-identical to HEAD? is `run/2` on `EchoWire.Cmd` and is `EchoWire.run/2` absent — facade still
   11, INV1? does a `%Command{}` run byte-identically to its bare verb through BOTH `run/2` and `Pipe.command/2`
   — is the advisory-flag equivalence real, INV4? does the builder derive a flag by **parsing the parts** instead
   of the static table, and is the **bit-inclusion** right [`readonly?` ⇒ `retryable?`] — INV3? does any
   frozen-runtime file read a flag — `grep -E "readonly\?|block\?|static_ttl\?|...|\.flags"` in `lib/echo_mq/`,
   INV7? does every generated story have a passing `:valkey` test behind it, INV8? does the `--match wire_pipe`
   regen leave `docs/echo_mq/stories/` byte-unchanged, INV8? is conformance byte-stable (the count emq-owned —
   read fresh, not pinned)? is any `echo_mq`
   lib runtime touched?); a **net-zero mutation spot-check** (the equivalence theorem: mutate the seam to drop a
   token / mis-stamp a flag and confirm a test **kills** it — the order-theorem analogue, L-4). Findings as `F-n`.
3. **Stage 3 — Mars-2 (remediate + harden).** Fold any `F-n`; run the full two-app gate ladder to completion
   (compile + construction suites in `echo_wire`; the `:valkey` byte-equivalence story suite + `mix
   echo_mq.stories --match wire_pipe` regen [twice + `diff -r` clean] + the `docs/echo_mq/stories/` byte-unchanged
   assertion + conformance byte-stable [the count emq-owned, read fresh] in `echo_mq`; facade-freeze; multi-seed
   sweep). The determinism posture is
   the multi-seed sweep + the statement (no id-mint/process/lease).
4. **Stage 4 — Venus (post-build reconcile).** Differ the as-built `EchoWire.Command` + `EchoWire.Cmd` + the
   `pipe.ex` seam + the story tests against the triad; flip the frame SPECCED → BUILT; sync the design-make
   rulings (the realized `flags` shape, the builder chain surface, the final curated arities, the realized
   full-cf membership) + any realization-over-literal deviations into the body; re-pin the realized verb/flag
   set; confirm the two story layers (hand-authored user stories vs the generated `.stories.md`) are
   non-contradicting (INV9). Record the SPECCED→BUILT reconcile block in the body (as `ewr.1.1` did).
5. **Stage 5 — Director (closure).** Ratify; one LAW-4 pathspec commit spanning **only** the rung's create-
   locations + the one additive `pipe.ex` head — `echo/apps/echo_wire/lib/echo_wire/command.ex` +
   `echo/apps/echo_wire/lib/echo_wire/cmd.ex` + `echo/apps/echo_wire/test/echo_wire/{command,cmd}_test.exs` + the
   single added `command/2` head in `echo/apps/echo_wire/lib/echo_wire/pipe.ex` +
   `echo/apps/echo_mq/test/stories/wire_pipe_command_*_story_test.exs` + the regenerated
   `docs/echo_mq/wire/stories/` (and the triad doc edits) — re-verify `git diff --cached --name-only` is purely
   the rung (no frozen-runtime `lib/` of either app, no facade edit, no `echo_mq` lib runtime edit, `echo/mix.lock`
   unchanged) before committing.

---

Body: [`ewr.1.2.md`](ewr.1.2.md) · Stories: [`ewr.1.2.stories.md`](ewr.1.2.stories.md) · Brief:
[`ewr.1.2.llms.md`](ewr.1.2.llms.md) · Design (the ruling): [`ewr.1.2.design.md`](ewr.1.2.design.md) · Roadmap:
[`../../ewr.roadmap.md`](../../ewr.roadmap.md)
