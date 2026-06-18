# ewr-1-1 — AAW scope ledger

The scope ledger for the founding wire rung. Seeded at program-open with the ruled design fork (the `D-n`
decisions and the `V-n` chosen-against arms); the `T-n` / `L-n` / `Y-n` / `Z-n` channels are filled by the
build run. There is **no** `ewr-1-1.registry.json` — the rung is additive above the conformance boundary, so
no conformance scenario is probe-registered.

## {ewr-1-1-thinking} Thinking

### T-1 — SPECCED at program-open; awaiting the build run

The triad ([`../ewr.1/ewr.1.1.md`](../ewr.1/ewr.1.1.md) + stories + brief) is authored forward-tense and
build-grade. The design fork is ruled (Arm A + curated/escape; D-1, D-2 below), so the Stage-1 gate is reachable
with no open Operator fork. The remaining decisions are the implementor's **design-make** (the conn-or-pool
dispatch mechanism, the curated membership, the internal `cmds` representation, placement) — logged here as
`D-n` at the top of the build, before any `.ex`/test artifact. This channel carries the build run's
UNDERSTAND/EXPAND / re-probe / build / gate / reconcile narrative.

## {ewr-1-1-decisions} Decisions

### D-1 — RULED: Arm A (`EchoWire.Pipe`), the threaded pipeline

The API surface fork (Arm A `Pipe` / B `Cmd` / C `Query`) is settled by the Operator as **Arm A** (this
session, recorded against [`../../design/ewr.design.md`](../../design/ewr.design.md) §4). The threaded `%Pipe{}`
accumulator threads through `|>` and `exec/1` is literally `Connector.pipeline/3` over the gathered commands —
the mental model is identical to the connector's own. Decisive reason: A is the **base that keeps both other
arms available** while committing to neither B's speculative flag vocabulary nor C's metaprogramming today (B's
command value layers on as `ewr.1.2`; C's block can later expand to A's functions — not the reverse). Both
review lenses converged (developer-experience A>C>B; spec-steward A≻B≻C). The alternatives keep their best case
in `{ewr-1-1-alternatives}` (V-1, V-2).

### D-2 — RULED: a curated verb set + a generic `Pipe.command/2` escape hatch

The sub-fork inside Arm A (a curated verb set + an escape hatch **vs** a full per-command surface mirroring the
rueidis `gen_*` tree) is settled as **curated + escape**. RULED: a curated set gives discoverability and
idiomatic option handling for the common string/key family, while `command/2` appends any raw `[[binary]]`
command verbatim — so the curated set is convenience and **never a ceiling** (INV6). The full per-command
surface is a large freeze liability with no incremental benefit over curated + escape; it is not built. This is
the binding invariant the triad carries (body D3/D4, INV6).

## {ewr-1-1-alternatives} Alternatives

### V-1 — Arm B: `EchoWire.Cmd`, the command builder (steelmanned, chosen-against)

The alternative the design fork names as B: an immutable `%Cmd{parts, flags}` value built fluently
(`set("k") |> value("v") |> ex(60) |> build()`) and run via `EchoWire.Cmd.run/2` — the faithful Elixir port of
rueidis's `Completed` (`go/valkey-go/internal/cmds/cmds.go:117`) with its bit-packed `cf` flags (cmds.go:5-23).

STEELMAN (real): B makes the **`cf`-flag command model first-class now** — the immutable command value carries
the readonly/block/pipe metadata the connector is missing (it fails in-flight callers `:disconnected` without
replay because it cannot know what is idempotent). For a future retry or cluster-routing layer, that flag
vocabulary is exactly the knowledge needed, and building it into the command value from the start avoids a later
migration.

CHOSEN-AGAINST: the flags have **no consumer yet** — there is no retry/cluster-routing rung — so the flag
vocabulary is speculative surface frozen ahead of need; and B's draft `run/2` would be a 12th verb on the
11-frozen `EchoWire` facade unless rehomed to `EchoWire.Cmd.run/2`. B's *value* is preserved, not discarded: the
immutable command + `cf` model is scheduled as **`ewr.1.2`**, layered onto A's accumulator when a consumer makes
the flags load-bearing (roadmap seam 4).

### V-2 — Arm C: `EchoWire.Query`, the query block (steelmanned, chosen-against)

The alternative the design fork names as C: a `query conn do set "k","v"; get "k" end` macro compiling to one
`Connector.pipeline/3`, with a `transaction conn do … end` companion.

STEELMAN (real): C reads **cleanest for a long linear sequence** — no `|>`, no `new/1`, no `build/1`, no prefix;
the block is the batch. For a reader scanning a ten-command sequence, the macro is the most legible of the three.

CHOSEN-AGAINST: the cost is **metaprogramming** — a macro is harder to ground (NO-INVENT), harder to freeze and
debug, and the readability gain over A's `|>` is marginal for the BCS audience already fluent in pipes. C's block
can later **expand to A's functions** (a macro over `EchoWire.Pipe`), so it stays available as sugar on top of A
without being the foundation. Layerable onto A, not the reverse — the same asymmetry that carried D-1.

## {ewr-1-1-learnings} Learnings

*Awaiting the build run — program-convention findings, realization-over-literal deviations, and Director
Stage-2 findings land here as `L-n`.*

## {ewr-1-1-report} Report

*Awaiting the build run — the stage-by-stage audit record lands here as `Y-n` (Mars build/harden, Director
review gates).*

## {ewr-1-1-complete} Complete

*Awaiting the build run — the ship record lands here as `Z-n` (WHAT SHIPPED / VERIFICATION / LAW-4).*
