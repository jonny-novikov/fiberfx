# EWR.1.2 · EchoWire.Cmd / EchoWire.Command — the fluent builder + the immutable command value (Movement I)
> ✅ **Shipped** — the as-built deliverable (verbs · conformance delta · commit) is in the [changelog](../../../emq.changelog.md). This body is the historical spec.

> **Status: BUILT** — shipped green, Director-verified (design Arm B + full-`cf`, the Operator's ruling
> `2026-06-18`). The second rung of the EchoWire client-core ([`../../ewr.roadmap.md`](../../ewr.roadmap.md),
> Movement I). Where `ewr.1.1`'s `Pipe` is *batch* construction, this rung adds the *per-command* surface: a
> single command becomes an inspectable, flag-bearing value — a faithful Elixir port of the rueidis `Completed`
> value (`cmds.go:117`). Additive by construction: the only shipped-file edit is one additive `Pipe.command/2`
> head; the frozen wire and the 11-verb facade are untouched, no Lua enters the wire, conformance byte-stable.

## The surface

- **`EchoWire.Command`** (`lib/echo_wire/command.ex`) — the immutable `%Command{parts, flags, slot}` value: the
  raw token list, the **full `cf` flag vocabulary** (an integer bitfield mirroring rueidis, the bit-inclusion
  baked into the constants — so `readonly?` ⇒ `retryable?` holds for free), and the cluster key-slot (a
  CRC16-XMODEM port with the `{hashtag}` rule). The full predicate set (`readonly?` · `write?` · `block?` · …) +
  `slot/1` + `parts/1` + a `raw/1` escape hatch.
- **`EchoWire.Cmd`** (`lib/echo_wire/cmd.ex`) — the fluent builder that mints a `%Command{}`
  (`set("k") |> value("v") |> ex(60) |> build()`, the rueidis type-state chain as `|>`) across the same six
  families `Pipe` curates, **plus `run/2`** — running a built command (or list) against a conn-or-pool through the
  opaque `via` dispatch. `run/2` lives on `EchoWire.Cmd`, **never** as a 12th facade verb.
- **The one seam** — `EchoWire.Pipe.command/2` gains a single additive head accepting a `%Command{}` (extracting
  `.parts`); `Pipe`'s struct / verbs / `add/2` / `exec/1` are byte-identical to HEAD, so a built command composes
  *into* a batch.

## The flags are ADVISORY (this rung)

The full `cf` vocabulary is carried for a *future* retry / cluster-routing / caching consumer (roadmap seam 4) —
nothing in the wire reads it. Flags are stamped **static per-verb** (the verb decides the flag, never parsed from
`parts`). The proof the value is sound is **byte-equivalence**: a built+flagged command flushed via `run/2` or
`Pipe.command/2` runs byte-identically to the bare verb — the flags drop at the seam, only `.parts` reach the wire.

## Invariants

- **Frozen floor.** No frozen-runtime edit; facade still **11 verbs** (`EchoWire.run/2` does not exist); the only
  shipped-file change is the one `pipe.ex` `command/2` head (added lines only); no new Lua; conformance byte-stable
  (the count is emq-owned, not the wire's to pin).
- **Static flags + pure slot.** Flags from the per-verb table, never the parts; the bit-inclusion lives in the
  constants; the slot is a pure CRC16 of the key.
- **Wire sees only `.parts`.** Both the seam and `run/2` drop flags/slot; the static-per-verb and
  wire-sees-only-parts mutations were **KILLED**.
- **Advisory, proven.** No frozen-runtime file consults the flags (`grep` = `0`); the predicates exist only for a
  future consumer.

**Gate (green):** `echo_wire` **109/0** (facade still 11, `EchoWire.run` absent), the wire `:valkey` command
stories **8/0**, conformance byte-stable (emq-owned, 54 at ship), byte-equivalence proven. Touch-set: `command.ex`
+ `cmd.ex` + their offline tests + the one additive `pipe.ex` `command/2` head + the `wire_pipe_command_*` stories
+ the generated stories.

---

Stories: [`ewr.1.2.stories.md`](ewr.1.2.stories.md) · Runbook:
[`ewr.1.2.prompt.md`](ewr.1.2.prompt.md) · Design (the ruling): [`ewr.1.2.design.md`](ewr.1.2.design.md) ·
Ledger: [`../progress/ewr-1-2.progress.md`](../progress/ewr-1-2.progress.md) · Roadmap:
[`../../ewr.roadmap.md`](../../ewr.roadmap.md)
