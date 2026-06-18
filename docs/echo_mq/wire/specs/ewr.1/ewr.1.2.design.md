# EWR.1.2 — the immutable command value + the `cf`-flag vocabulary · the integration fork

> The design fork for **`ewr.1.2`** — porting the valkey-go (rueidis) **immutable command value** (`Completed`:
> parts + bit-packed flags + key-slot) as Elixir data, and integrating it with the as-built **`EchoWire.Pipe`**
> (`ewr.1.1`). This document framed the integration fork in four-part Arms; the method is
> [aaw.architect-approach.md](../../../../aaw/aaw.architect-approach.md) — Rationale · 5W · Steelman · Steward per
> arm. It mirrors the surfaced-fork shape of the chapter design
> [`../../design/ewr.design.md`](../../design/ewr.design.md), narrowed to this rung's one integration question.
> **Venus surfaced, the Operator ruled.**
>
> **RULED (the Operator, `2026-06-18`): Arm 3 — the standalone `EchoWire.Cmd` fluent builder — with the FULL `cf`
> vocabulary now.** Not Arm 1, not minimal-now. The Operator is buying the complete rueidis-faithful command core:
> a standalone fluent builder (`EchoWire.Cmd`) that mints an immutable value (`EchoWire.Command`) carrying the
> whole `cf` flag set (`cmds.go:5-23`) + the key-slot, with a `EchoWire.Cmd.run/2` runner — landed as the
> additive command-value **sibling** to `Pipe` (design-Arm B realized), `Pipe` staying the primary batch surface.
> **The losing arms keep their cases below** (§2 Arms 1 & 2, the Steelman/Steward record of why they were weighed
> and set aside); §4 records the ruling. The triad ([`ewr.1.2.md`](ewr.1.2.md) + stories + brief) is authored for
> the ruled arm. **Venus's recommendation was Arm 1 + minimal-now; the Operator ruled otherwise, and the ruling
> governs.**

## 0 · Genesis — why a command value, and why now

`ewr.1.1` shipped `EchoWire.Pipe` (`echo/apps/echo_wire/lib/echo_wire/pipe.ex`): a `%Pipe{conn, via, timeout,
cmds}` accumulator where each curated verb appends one **bare command-list** — a flat `[binary | integer |
atom]` — via a private `add/2` (pipe.ex:538), and `exec/1` flushes `Enum.reverse(cmds)` once through the opaque
`via.pipeline/3` (pipe.ex:503). A command, the instant it is appended, is a bare list and nothing more: it
carries no record of whether it is a read or a write, whether it may be retried across a reconnect, or which
cluster slot its key hashes to.

The reference for the missing structure is the valkey-go client's **`Completed`** value
(`go/valkey-go/internal/cmds/cmds.go:117`):

```go
type Completed struct {
    cs *CommandSlice // the parts (the command tokens)
    cf uint16        // cmd flag  (bit-packed advisory flags)
    ks uint16        // key slot
}
```

Two facts about `Completed` frame this whole fork, and both were re-probed against the as-built Go tree:

1. **The flags are set per-builder-verb at construction, not parsed from the parts.** `Builder.Get()`
   (`gen_string.go:231`) constructs `Get{cs: get(), ks: b.ks, cf: int16(readonly)}` — the `readonly` flag is
   stamped because the *verb is* `GET`; `Builder.Set()` leaves `cf` zero (a write). `Build()` (`gen_string.go:37`)
   then freezes `Completed{cs, cf, ks}`. So a faithful Elixir port derives a command's flags from a **static
   per-verb table** (`GET → readonly`, `SET → write`), never from re-inspecting the assembled `["GET", "k"]`.
   This is the load-bearing port fact: the flag is a property of the *verb*, decided at build time.
2. **The flags are advisory until a consumer acts on them.** In rueidis the consumers are real — `IsReadOnly()`
   (`cmds.go:183`) gates retry-across-reconnect, `Slot()` (`cmds.go:210`) routes to a cluster node, `IsBlock()`
   (`cmds.go:168`) reserves a dedicated connection. **In `echo_wire` today none of those consumers exists**: the
   connector fails all in-flight callers `:disconnected` without replay (it "cannot know what is idempotent",
   connector.ex:21), there is no cluster router, and there is no blocking-command dispatcher. The roadmap names
   this exactly — seam 4: *"the flags stay **advisory** in the upper layer — the connector does not act on them
   — until a retry or cluster-routing consumer gives them meaning"* ([`../../ewr.roadmap.md`](../../ewr.roadmap.md),
   Seams & open decisions). So `ewr.1.2` ships the **vocabulary ahead of its readers**, by design.

**The fact that frames the whole fork:** `ewr.1.1` already covers construction. This rung does not add a way to
*build a batch* — it adds **structure to a single command** (a value that remembers its own flags + slot) and
chooses **how that value meets the shipped `Pipe`**. The integration question is the fork; the `Completed` port
itself is settled (parts + advisory flags + slot, as pure Elixir data).

## 1 · The seam and the frozen-surface constraints (carried from the chapter design)

Every arm here inherits the chapter design's constraints ([`../../design/ewr.design.md`](../../design/ewr.design.md),
§1) and `ewr.1.1`'s as-built reality:

- **Additive above the conformance boundary.** No edit to `EchoMQ.Connector` / `RESP` / `Script` / `Pool`; no new
  Lua (`grep redis.call` on the lib diff `= 0`); the `echo_mq` conformance stays byte-stable
  (`Conformance.run/2 → {:ok, 53}`, conformance_run_test.exs:46 — the as-built figure; 53, after emq's
  out-of-band drift from 52) and registers **no** scenario / writes **no** `registry.json` — the layer is *above*
  the boundary, the count is emq-owned ([`../../ewr.roadmap.md`](../../ewr.roadmap.md), The master invariant).
- **The facade stays at 11 verbs.** `EchoWire` is pinned at exactly 11 (`lib/echo_wire.ex:19-31`, the facade
  test). The command value is a **new module** (`EchoWire.Command`), never a 12th facade verb.
- **`exec/1`'s shipped contract is frozen.** `ewr.1.1`'s `exec/1` returns `{:ok, [RESP.reply()]}` /
  `{:error, term}` by flushing `Enum.reverse(cmds)` (the same `[[binary]]`) to `via.pipeline/3`. This rung must
  not change that return or that wire shape — appending a command value must flush the **identical** `[[binary]]`
  the bare verb would.
- **The flags are pure data and advisory.** `EchoWire.Command` is an immutable struct; nothing in the wire reads
  its flags this rung. The proof that the value is sound is therefore *equivalence* — a flagged command
  round-trips byte-identically to its bare form (the flags are carried, not acted on).
- **The pure-data, no-process shape holds.** Like `ewr.1.1`, this rung adds no process, no lease, no id-mint; the
  determinism floor stays the multi-seed sweep + the posture statement, not the ≥100 loop.

## 2 · The fork — four Arms

### Arm 1 — a `%EchoWire.Command{}` value + a `Pipe` accept-seam (RECOMMENDED)

```elixir
# the value, built from a verb + opts, as pure data
cmd = EchoWire.Command.get("user:1")
#  => %EchoWire.Command{parts: ["GET", "user:1"], flags: %{readonly: true}, slot: 5_474}
EchoWire.Command.readonly?(cmd)   # => true   (advisory — nothing in the wire reads it yet)

# the seam: Pipe accepts a %Command{} wherever it accepts a raw list
conn
|> EchoWire.Pipe.new()
|> EchoWire.Pipe.command(EchoWire.Command.set("user:1", "alice", ex: 60))
|> EchoWire.Pipe.command(EchoWire.Command.get("user:1"))
|> EchoWire.Pipe.exec()
# => {:ok, ["OK", "alice"]}   — byte-identical to the bare-verb pipe (the flags are advisory)
```

**Rationale.** Arm 1 makes the **command** the new first-class value while leaving `ewr.1.1`'s **batch**
surface exactly as shipped. `%EchoWire.Command{parts, flags, slot}` is the rueidis `Completed` ported as pure
Elixir data: a small builder (the same six families' principal verbs) stamps the parts + the per-verb advisory
flags + the key-slot; `readonly?/1` / `write?/1` / `block?/1` / `retryable?/1` / `slot/1` read them back. The
only `Pipe` change is **non-invasive**: the existing `command/2` (pipe.ex:490) — already the escape hatch that
appends a raw list — learns to also accept a `%Command{}`, extracting its `.parts`. `exec/1` is **untouched**:
it still flushes `[[binary]]`. So the command value is *born*, the batch surface *absorbs* it through the one
door already built for "a command from outside the curated set", and nothing `ewr.1.1` shipped is reopened.

**5W.**
- **Why** — give a single command a home for its own flags + slot (the rueidis `Completed`), so a *future*
  retry/routing/caching layer can branch on the value rather than re-parse `parts`; do it without disturbing the
  shipped batch surface.
- **What** — a new module `EchoWire.Command`: the `%Command{parts, flags, slot}` struct; a curated builder
  (one function per principal verb, mirroring `Pipe`'s families, grounded in `gen_*.go`) that stamps parts +
  the static per-verb flag set + `slot` (CRC16 over the key / `{hashtag}`, slot.go:5); the flag predicates
  (`readonly?`/`write?`/`block?`/`retryable?`) + `slot/1` + `parts/1`; and a `raw/1`-style constructor for an
  un-modeled command (flags default to write/unknown). **Plus one seam:** `EchoWire.Pipe.command/2` accepts a
  `%EchoWire.Command{}` in addition to a raw list (extracting `.parts`); `exec/1` is unchanged.
- **Who** — primarily a *future* `ewr` retry/cluster/caching rung (the flag/slot consumers); today, any caller
  who wants an inspectable, flag-bearing command value. The everyday batch caller keeps `ewr.1.1`'s verbs
  unchanged.
- **When** — now, as Movement I rung 2: the value is the prerequisite the later consumers need; the seam is the
  cheapest possible integration with the shipped `Pipe`.
- **Where** — a new module `echo/apps/echo_wire/lib/echo_wire/command.ex` (+ its offline test), beside
  `pipe.ex`; one additive clause on `Pipe.command/2` (`pipe.ex:490`); the BDD `:valkey` proof in
  `echo_mq/test/stories/wire_pipe_command_*_story_test.exs`.

**Steelman.** Arm 1 is the only arm that adds the rueidis **value** (`Completed`'s actual signature feature)
**without re-opening `ewr.1.1`'s shipped verb bodies.** The seam is a single additive clause on a function
(`command/2`) whose contract is *already* "append a command from outside the curated set" — so the blast radius
is one pattern-matched head, not 80 verbs. The equivalence proof is clean and total: a `%Command{}` flushed
through `command/2` produces byte-identical replies to the bare verb, because `exec` still sees the same
`[[binary]]` — which is exactly the right proof for an advisory-flag rung (the flags are carried, not acted on,
so *carrying them changes nothing observable* is the theorem). It honours the additive-minor stance the program
is built on: facade untouched, conformance byte-stable, the frozen runtime never read. And it is forward-
compatible in both directions the design fork already promised — it **is** the `Cmd` value the design's Arm B
wanted ("`%Cmd{parts, flags}` is a value a future retry layer can branch on", ewr.design §2.B-Steelman), now
landed as the layer over `Pipe` that §4 said sequences B onto A: *"a future `Cmd` value can feed
`Pipe.command/2`."* Arm 1 is the literal realization of that sentence.

**Steward.** Arm 1's one real liability is **two construction surfaces with overlapping verb names** — `Pipe`
has `get/2`, `Command` has `get/1` — which could read as duplication (a DRY worry). The mitigation is a crisp
division of authority the triad must carry: **`Pipe` builds a batch to flush now; `Command` builds one
inspectable value to carry** (its flags/slot for a later consumer). They are not two ways to do one thing — they
are a batch builder and a command-value builder, and the seam (`command/2` accepts a `%Command{}`) is the single
point they meet. The second cost is **the advisory flags have no consumer yet** — the same speculative-generality
charge the design fork's Arm B carried. Arm 1 answers it the way the roadmap's seam 4 does: ship the value
*minimal* (the sub-question below), keep the flags advisory and *documented as advisory*, and prove only
equivalence — so a wrong flag is cheap to correct (nothing depends on it) and the value is in place when a
consumer arrives. Otherwise Arm 1 ages best of the four: it touches neither facade nor conformance nor a shipped
verb; it is pure data (offline pins of `parts`/`flags`/`slot` + one `:valkey` equivalence round-trip); zero
metaprogramming; One-authority holds (the reply stays `RESP.reply()`, the batch stays `pipeline/3`, the parts
stay the single source of the wire bytes — the flags are a *non-authoritative annotation*).

### Arm 2 — enrich the `Pipe` verbs to emit `%Command{}` internally

```elixir
# every curated Pipe verb now produces a flagged command internally:
conn
|> EchoWire.Pipe.new()
|> EchoWire.Pipe.get("user:1")   # internally: add(pipe, Command.get("user:1"))
|> EchoWire.Pipe.exec()
# the %Pipe.cmds list now holds %Command{} structs; exec extracts .parts before flushing
```

**Rationale.** Arm 2 makes *every* command in a batch a flagged value, by changing `Pipe`'s curated verbs to
build `%Command{}` instead of a bare list. The appeal is uniformity: a caller never thinks about which
construction surface to use — `Pipe.get` simply *is* readonly, because internally it builds `Command.get`. The
batch becomes a list of rich commands, and a future consumer (a retry layer reading `pipe.cmds`) sees flags on
every command without the caller doing anything.

**5W.**
- **Why** — make the flag intrinsic to the batch, not opt-in: every `Pipe` verb carries its flag automatically,
  so there is one construction surface and the enrichment is invisible to the caller.
- **What** — re-point `Pipe`'s private `add/2` and the ~80 curated verbs to build `%Command{}` values;
  `%Pipe{cmds}` becomes `[%Command{}]`; `exec/1` maps `.parts` out of each before flushing.
- **Who** — the everyday batch caller (transparently) and a future flag consumer reading `pipe.cmds`.
- **When** — now, but it is a **rewrite of `ewr.1.1`'s shipped surface**, not a layer over it.
- **Where** — `echo/apps/echo_wire/lib/echo_wire/pipe.ex` — **the shipped verbs**, `add/2`, `exec/1` —
  plus the new `command.ex`.

**Steelman.** Arm 2 is the most *complete* port: it is closest to rueidis, where the builder always yields a
`Completed` and the pipeline always carries flagged commands. There is exactly one construction surface, so the
Arm 1 "two builders, overlapping names" DRY worry vanishes. A future retry layer needs no caller cooperation —
every command in every batch is already flagged. If the end-state is "all flags, everywhere, consumed," Arm 2 is
the shortest path to it.

**Steward.** Arm 2 **fights the program's two load-bearing forces head-on.** (1) **It re-opens `ewr.1.1`'s
shipped, Director-verified verb bodies** — the additive-minor stance says the new surface is a *new module*,
never a rewrite of a frozen one ([`../ewr.venus.md`](../../program/ewr.venus.md), the additive-above-the-
conformance-boundary stance); Arm 2 rewrites `add/2` and every verb, turning a one-clause seam into an
~80-function diff that the as-built reconcile must re-verify line-by-line. (2) **It changes `%Pipe{cmds}`'s
internal type** from `[command()]` to `[%Command{}]` — a structural change to a shipped struct's field
semantics, the kind of latent, path-dependent change `ewr.1.1`'s order-theorem mutation exists to guard
(reverse/drop the accumulator and a test must die; that proof now has to be re-established over a richer
element type). (3) **It pays the full cost for a benefit that has no consumer** — every verb is enriched *now*
for flags nothing reads *yet*, the worst form of the speculative-generality charge: maximum surface disturbance,
zero present payoff. (4) The equivalence proof is no longer a clean "one seam, byte-identical" — it is "all 80
verbs still flush byte-identically after the rewrite," a far larger thing to prove byte-stable. Arm 2 is the
right *end-state* and the wrong *rung*: it is what Arm 1 grows into **after** a consumer exists, done in one
disruptive step before the consumer exists.

### Arm 3 — a standalone `EchoWire.Cmd` builder surface, parallel to `Pipe`

```elixir
import EchoWire.Cmd
[ set("user:1") |> value("alice") |> ex(60) |> build(),
  get("user:1") |> build() ]
|> EchoWire.Cmd.run(conn)
# => {:ok, ["OK", "alice"]}
```

**Rationale.** Arm 3 is the chapter design's **Arm B**, brought back as a rung: a full fluent command builder
(`set |> value |> ex |> build`) producing `%Cmd{parts, flags, slot}`, with its own `run/2` runner — a second
construction surface beside `Pipe`, faithful to rueidis's type-state chain.

**5W.**
- **Why** — port rueidis's *builder* (the method chain terminating in `build()`) as faithfully as the value, for
  callers who want the complete rueidis-faithful command core: per-token assembly **plus** the full `cf` flag
  vocabulary on the built value.
- **What** — two new modules: **`EchoWire.Command`** (the immutable value — `%Command{parts, flags, slot}` + the
  predicates) and **`EchoWire.Cmd`** (the fluent builder verbs + `build/1` that stamps `parts` + the static
  per-verb `flags` + the key-`slot`, + `EchoWire.Cmd.run/2` extracting `parts` into the opaque conn-or-pool
  dispatch, mirroring `Pipe`'s `via`). The builder reimagines rueidis's *type-state chain* (`Builder.Set()` →
  `Set.Key(k)` → `SetKey.Value(v)` → `SetValue.ExSeconds(s)` → `SetValue.Build()`, `gen_string.go:1487,1956,1998,2043`)
  as a `|>` chain (`set("k") |> value("v") |> ex(60) |> build()`) — dynamic Elixir cannot enforce the
  compile-time type-state, so `build/1` is a runtime closing token (a known cost, below). The **full `cf`
  vocabulary** is ported on the value (the depth ruling): `readonly` / `block` / `pipe` / `noreply` (`noRetTag`) /
  `static_ttl` / `retryable` / `opt_in` / `mt_get` / `unsub` / `scr_ro` (`cmds.go:5-23`), with predicates
  `readonly?/1` · `block?/1` · `pipe?/1` · `noreply?/1` · `static_ttl?/1` · `retryable?/1` · … — and the rueidis
  **bit-inclusion** preserved (`readonly` *includes* `retryableTag`, so a read is `retryable?`; `noRetTag`
  includes `readonly | pipeTag`).
- **Who** — a caller who wants the rueidis builder ergonomics + the inspectable flagged value; a *future* retry /
  cluster / caching consumer of the flags + slot (seam 4). It is the per-command sibling to `Pipe`'s batch
  surface, not a replacement for it.
- **When** — now, as the additive command-value sibling (design-Arm B realized).
- **Where** — new modules `echo/apps/echo_wire/lib/echo_wire/command.ex` + `echo/apps/echo_wire/lib/echo_wire/cmd.ex`
  (with `Cmd.run/2`); the one additive `Pipe.command/2` head so a built `%Command{}` composes into a `Pipe` batch.

**Steelman.** Arm 3 is the most faithful port of rueidis's *builder + value* together, and it keeps `Pipe`
entirely untouched (true new modules; the only `pipe.ex` change is one additive `command/2` head to *accept* a
built value, not a rewrite). For a caller who thinks in the rueidis idiom, the per-token chain reads exactly like
the Go source, and the built value carries the whole `cf` vocabulary a future retry/routing/caching layer will
read. It cleanly separates "build one command" (`Cmd`) from "thread a batch" (`Pipe`), and the `%Command{}` value
is as inspectable as Arm 1's — Arm 3 *is* Arm 1's value plus the faithful builder around it.

**Steward.** Arm 3 carries real, named costs — the Operator ruled with them on the table, and the triad must
mitigate, not hide, each. (1) **Arity inflation by construction** — rueidis *code-generates* the builder from
`hack/cmds/*.json` precisely because a hand-maintained per-command × per-option chain is large; ported by hand,
`EchoWire.Cmd` is a substantial surface. *Mitigation the triad carries:* a **curated** builder across the six
families (not the full Redis command set) **+ a `raw/1` escape hatch** on `EchoWire.Command`, so the builder is
"the families the stack issues + one universal constructor", and `EchoWire.Cmd` is **not** arity-frozen (it is
not the facade). (2) **`build/1` is a runtime closing token** — it collapses a compile-time type-state dynamic
Elixir does not provide; a forgotten `build/1` is a runtime error. *Mitigation:* the construction suite asserts
the un-built builder value is a distinct, inspectable intermediate, and `run/2` / `Pipe.command/2` accept only a
*built* `%Command{}` (a clear contract boundary). (3) **Two construction surfaces** (`Pipe` *and* `Cmd`) is the
DRY tension Arm 1 avoided. *Mitigation — the division of authority the triad pins:* `Pipe` is the **batch**
surface (thread many commands, flush once); `EchoWire.Cmd` is the **single-command value+builder** (mint one
flagged value, carry it, or `run/2` it). They meet at exactly one point — `Pipe.command/2` accepts a built
`%Command{}` — so a built command composes *into* a batch rather than duplicating the batch surface. (4) **The
full `cf` flags have no consumer yet** — they are advisory this rung. *Mitigation:* the flags are *carried,
documented advisory* (seam 4) and proven only by **byte-equivalence** (a flagged command runs identically to its
bare verb), so a wrong flag is cheap to correct (nothing reads it) while the complete vocabulary is in place for
the consumer the Operator is provisioning for. Arm 3 **is design-Arm B realized**: the chapter design said B's
value *"can be layered onto A later … a future `Cmd` value can feed `Pipe.command/2`"* (ewr.design §4) — Arm 3
lands exactly that `Cmd` value/builder as the sibling to `Pipe`, with `Pipe` remaining the primary batch surface,
so it **extends** the chapter ruling rather than reopening it.

## 3 · The argument as surfaced — and the Operator's ruling

**Venus surfaced a recommendation; the Operator ruled past it.** The two lenses Venus ran (developer-experience,
spec-steward) both ranked **Arm 1** first on *minimum-footprint* grounds — Arm 1 presses on nothing frozen (the
facade stays 11, conformance stays byte-stable, no shipped verb body reopened, the seam is one additive clause)
and keeps Arms 2/3 layerable. That argument is recorded; it lost to a different priority.

**The Operator's priority — completeness over minimum footprint.** The ruling buys the **complete
rueidis-faithful command core now**: not the thinnest value that defers everything ambiguous (Arm 1 +
minimal-now), but the faithful builder (Arm 3) *and* the whole `cf` vocabulary (full-cf). The trade the Operator
accepted, explicitly:

- **The footprint cost** — two new modules (`Command` + `Cmd`) and a second construction surface, where Arm 1 was
  one module + one seam. Accepted: the wire is still untouched (true new modules; one additive `Pipe.command/2`
  head), so the *frozen-surface* guarantee holds — only the *new public surface* is larger.
- **The full-cf cost** — porting flags (`opt_in` / `mt_get` / `static_ttl` / …) ahead of any consumer, including
  the ambiguous ones Venus flagged. Accepted: a complete, settled vocabulary now is worth more to the Operator
  than the wrong-frozen-contract risk, *and* the risk is bounded because the flags are advisory (byte-equivalence
  is the proof; a wrong flag is correctable while nothing reads it).
- **The `build/1` runtime-token cost** — accepted as the price of the faithful builder idiom.

**Why this is not reopening the chapter ruling.** Arm 3 is **design-Arm B realized**: the chapter design ruled
Arm A (`Pipe`) the *primary* surface and said B's value *"can be layered onto A later … a future `Cmd` value can
feed `Pipe.command/2`"* (ewr.design §4). `ewr.1.2` lands exactly that `Cmd` value+builder as the **additive
sibling** to `Pipe` — `Pipe` stays the primary batch surface, the built `%Command{}` composes *into* a `Pipe`
batch through the one seam — so the ruling **extends** the chapter decision (B layered onto A, as promised), it
does not overturn it. The triad below is authored to this ruling.

## 4 · The ruling (Venus surfaced, the Operator ruled)

| Arm | Shape | The one-line trade | Disposition |
| --- | --- | --- | --- |
| **1** `EchoWire.Command` + a `Pipe` seam | a `%Command{parts, flags, slot}` value; `Pipe.command/2` accepts it | adds the rueidis value with **one additive clause**; never reopens a shipped verb; minimum footprint — but the thinnest, defers the builder + the ambiguous flags | *Venus's recommendation; not ruled* |
| **2** enrich the `Pipe` verbs | every curated verb emits `%Command{}` internally | one construction surface — but rewrites `ewr.1.1`'s ~80 shipped verbs + changes `%Pipe{cmds}`'s type, all for a flag nothing reads yet | *Not ruled (worst footprint)* |
| **3** standalone `EchoWire.Cmd` builder + the value | a fluent `set \|> value \|> build` chain → `%Command{}` (full `cf`) + `run/2`, + the `Pipe.command/2` seam | the **complete rueidis-faithful command core**; `build/1` runtime token + a second construction surface, accepted | **✅ RULED + full-cf** |

**The ruling (the Operator, `2026-06-18`): Arm 3 + the FULL `cf` vocabulary now.** The build delivers two new
modules — **`EchoWire.Command`** (the immutable value: `%Command{parts, flags, slot}` carrying the whole
`cf` flag set + the predicates) and **`EchoWire.Cmd`** (the fluent builder `set |> value |> ex |> build` across
the six families, + `EchoWire.Cmd.run/2` running a built command or a list against a conn-or-pool via the opaque
`via` dispatch) — plus the one additive `Pipe.command/2` head so a built `%Command{}` composes into a `Pipe`
batch. `Pipe` remains the primary batch surface; `EchoWire.Cmd`/`Command` is the additive command-value sibling
(design-Arm B realized).

**The full `cf` vocabulary (the depth ruling — ported now, advisory).** Port the whole rueidis flag set
(`go/valkey-go/internal/cmds/cmds.go:5-23`) onto `%Command{}`, with the **bit-inclusion preserved**:

| `cf` tag (rueidis) | bit | includes | `%Command{}` flag / predicate |
| --- | --- | --- | --- |
| `optInTag` | `1<<15` | — | `opt_in` / `opt_in?/1` |
| `blockTag` | `1<<14` | — | `block` / `block?/1` |
| `readonly` | `1<<13` | `retryableTag` | `readonly` / `readonly?/1` (⇒ `retryable?`) |
| `noRetTag` | `1<<12` | `readonly` \| `pipeTag` | `noreply` / `noreply?/1` (⇒ `readonly?`, `pipe?`) |
| `mtGetTag` | `1<<11` | `readonly` | `mt_get` / `mt_get?/1` (⇒ `readonly?`) |
| `scrRoTag` | `1<<10` | `readonly` | `scr_ro` / `scr_ro?/1` (⇒ `readonly?`) |
| `unsubTag` | `1<<9` | `noRetTag` | `unsub` / `unsub?/1` (⇒ `noreply?`) |
| `pipeTag` | `1<<8` | — | `pipe` / `pipe?/1` |
| `retryableTag` | `1<<7` | — | `retryable` / `retryable?/1` |
| `staticTTLTag` | `1<<6` | — | `static_ttl` / `static_ttl?/1` |

(`InitSlot = 1<<14` / `NoSlot = 1<<15` are slot sentinels on `ks`, not `cf` — the `slot` field, not a flag.) The
predicates mirror the rueidis accessors (`IsReadOnly`/`IsBlock`/`IsPipe`/`NoReply`/`IsRetryable`/`IsStaticTTL`,
`cmds.go:147-210`). **The flags stay ADVISORY this rung** (roadmap seam 4 — no retry/cluster/caching consumer in
the wire): they are carried on the value, the wire does not act on them, and the acceptance is **byte-equivalence**
(a built+flagged command runs identically to its bare verb — *that the flags change nothing observable* is the
theorem).

**The load-bearing port fact (INV3, kept).** A command's flags are stamped from the **static per-verb property**
at build time — the rueidis builder stamps `readonly` because the *verb is* `GET` (`Get()` →
`cf: int16(readonly)`, `gen_string.go:231`; `Set()` leaves `cf` zero, a write) — **never** parsed from the
assembled `parts`. The Elixir builder reads a per-verb table, not a string-match. The `slot` is
`crc16(key | {hashtag}) & 16_383` (`slot.go:5`), a pure function of the command's key.

**The deferred seam, unchanged (roadmap seam 4):** the per-command **flag *consumer*** (retry-on-`readonly`,
cluster slot-routing, caching by `static_ttl`) opens *when* a Movement-I retry/cluster rung or Movement II's
caching gives the flags a reader. The value already carries the whole vocabulary the consumer will read.

**Two constraints, kept (the chapter design's §4 corrections):**
1. `EchoWire.Command` / `EchoWire.Cmd` are **new modules**, and `run/2` lives on `EchoWire.Cmd` — **never** a
   12th facade verb; `EchoWire` stays at 11 (`echo_wire.ex:19-31`, the facade test).
2. `exec/1`'s shipped return + wire shape are **frozen** — appending a `%Command{}` must flush the identical
   `[[binary]]` the bare verb would, proven by byte-equivalence (the flags are advisory).

---

**Provenance.** Framed by Venus (spec-steward, the EchoWire client-core program) per the four-part-Arm method of
[aaw.architect-approach.md](../../../../aaw/aaw.architect-approach.md). The rueidis facts are source-grounded at
`go/valkey-go` (`internal/cmds/cmds.go:117` the `Completed` value · `cmds.go:5-23` the `cf` constants ·
`cmds.go:147-210` the accessors + `Slot()` · `internal/cmds/slot.go:5` the CRC16 slot · `internal/cmds/gen_string.go:37,231`
`Build()` + the per-verb flag stamp). The as-built `EchoWire.Pipe` is verified at
`echo/apps/echo_wire/lib/echo_wire/pipe.ex` (the `command/2` seam at :490, `add/2` at :538, `exec/1` at :503).

**References.** Method: [aaw.architect-approach.md](../../../../aaw/aaw.architect-approach.md). Chapter design &
surfaced-fork precedent: [`../../design/ewr.design.md`](../../design/ewr.design.md). The shipped floor:
[`ewr.1.1.md`](ewr.1.1.md). Roadmap (seam 4, the master invariant): [`../../ewr.roadmap.md`](../../ewr.roadmap.md).
The wire: `echo/apps/echo_wire/lib/echo_wire/pipe.ex`, the facade `echo/apps/echo_wire/lib/echo_wire.ex` (frozen
at 11). The rueidis reference: `go/valkey-go/internal/cmds/` (`cmds.go` · `slot.go` · `gen_string.go`).
