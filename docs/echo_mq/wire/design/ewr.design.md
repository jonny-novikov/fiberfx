# EchoWire — the client core + functional-pipelining API · the design fork

> The design fork for a brand-new **`EchoWire` functional-pipelining surface** — the idiomatic-Elixir
> reimplementation of the valkey-go (rueidis) client core's command-construction + pipelining ergonomics, as
> an **additive layer** over the owned wire. This document SURFACES the fork in three arms; it does not rule
> it. The method is [aaw.architect-approach.md](../../../aaw/aaw.architect-approach.md) — Rationale · 5W ·
> Steelman · Steward per arm, then the staged multi-architect debate. The arms were argued by two echo_mq
> architects from divergent lenses, **Venus-1** (developer-experience) and **Venus-2** (spec-steward /
> invariants); §3 stages their debate. **Venus surfaces, the Operator rules.**

## 0 · Genesis — why a new EchoWire surface

The owned wire already carries the hard part of a Valkey client. `EchoMQ.Connector`
(`echo/apps/echo_wire/lib/echo_mq/connector.ex`) is a single-owner `:gen_tcp` GenServer whose moduledoc names
pipelining the primitive — `command/3` is "a pipeline of one" (connector.ex:7) — and whose `pipeline/3` takes
a list of command-lists and returns `{:ok, [reply]}` off an in-flight FIFO (`send_pipe/4`, connector.ex:296).
`EchoMQ.RESP` parses every reply into the `RESP.reply()` union (resp.ex:30-43), carrying server errors as
`{:error_reply, msg}` *values* rather than failures (resp.ex:47). `EchoMQ.Script` precomputes a SHA for
EVALSHA-first scripting. What the wire lacks is any way to CONSTRUCT a command or a batch other than a
hand-written nested-list literal — `[["SET","user:1","alice","EX","60"], ["GET","user:1"], ["INCR","hits"]]` —
with positional flag adjacency (`EX` next to `60`) the caller keeps correct by eye.

The reference for the missing layer is the valkey-go client, the official Valkey fork of rueidis
(`go/valkey-go`, module `github.com/valkey-io/valkey-go`). Its two signature features are a **type-state fluent
command builder** — `client.B().Set().Key("k").Value("v").ExSeconds(10).Build()`, each step a distinct Go type
terminating in an immutable `Completed` (`go/valkey-go/internal/cmds/gen_string.go`, `Build() Completed`) — and
**connection-level auto-pipelining** (`DoMulti`, `go/valkey-go/pipe.go:1097`; the `_backgroundWrite` coalescer
at pipe.go:485). The developer rationale for this rung: a brand-new `EchoWire` surface whose pipeline calls are
reimplemented in idiomatic Elixir functional style and syntax — seamless and `|>`-native — as a purely
additive layer over the connector.

**The fact that frames the whole fork** (both architects established it independently): the connector
*already* pipelines. None of the three arms adds pipelining; each is an ergonomic façade over `pipeline/3`
(+ `transaction_pipeline/3`, `noreply_pipeline/3`). The fork is not "add a capability" — it is "choose how a
caller assembles `[[binary]]` before handing it to a verb that exists." A façade is weighed against the public
surface it permanently widens.

## 1 · The seam and the frozen-surface constraints

- **The seam.** Every arm terminates in `Connector.pipeline/3` (connector.ex:56) — or `transaction_pipeline/3`
  (connector.ex:130) / `noreply_pipeline/3` (connector.ex:125). The change is **additive-minor by
  construction**: no wire touch, no new Lua, no `Script.new/2` body change. The 52-scenario conformance suite
  (`echo/apps/echo_mq`, conformance.ex:38) stays byte-stable and its additive-minor law is **not engaged** —
  the new layer lives strictly *above* the conformance boundary.
- **The frozen facade.** `EchoWire` is pinned at exactly **11 verbs** (`echo_wire.ex:19-31`, pinned by
  `echo_wire_facade_test.exs` via `function_exported?`). The new surface lives in a **NEW module**
  (`EchoWire.Pipe` / `.Cmd` / `.Query`) and may not grow the facade. This disqualifies the draft
  `EchoWire.run/2` of Proposal B (see §2.B-Steward) — it would be a 12th verb.
- **Frozen names.** `EchoMQ.Connector` / `RESP` / `Script` are frozen by committed records — reuse, never
  edit.
- **The reply contract.** Replies stay `RESP.reply()` (resp.ex:30-43); the layer adds no second result
  representation. The rueidis two-tier error split — transport (`NonValkeyError()`) vs protocol (`Error()`),
  `go/valkey-go/message.go:143-154` — is **already present** in the as-built return: `{:error, :disconnected}`
  transport on the whole call vs `{:error_reply, _}` protocol value in a reply slot.
- **The conn-or-pool contract.** `EchoMQ.Pool.pipeline/3` (`echo/apps/echo_mq/lib/echo_mq/pool.ex:48`) shares
  the connector's signature; every arm's entry point must accept conn-or-pool and never inspect it.

## 2 · The fork — three arms

### Arm A — the threaded pipeline (`EchoWire.Pipe`)

```elixir
conn
|> EchoWire.Pipe.new()
|> EchoWire.Pipe.set("user:1", "alice", ex: 60)
|> EchoWire.Pipe.get("user:1")
|> EchoWire.Pipe.incr("hits")
|> EchoWire.Pipe.exec()
# => {:ok, ["OK", "alice", 1]}
```

**Rationale.** A makes the *batch* the first-class noun: `new/1` seeds a `%Pipe{conn, cmds}` accumulator, each
verb appends one command-list, `exec/1` flushes once. It is a credible answer to the developer rationale
because `|>` is the most reflexive gesture in idiomatic Elixir, and here it threads exactly the value the wire
consumes — a list of commands — from connection to result. The caller's mental model becomes identical to the
connector's own ("pipelining as the primitive", connector.ex:7); there is no intermediate concept between the
engineer and the wire.

**5W.**
- **Why** — the batch is the wire's native unit, yet there is no idiomatic way to *grow* one; A makes growing a
  batch a pipe-chain.
- **What** — `%EchoWire.Pipe{conn, cmds}` + `new/1`, one append verb per command, and three terminals
  `exec/1` / `exec_txn/1` / `exec_noreply/1` mapping to `pipeline/3` / `transaction_pipeline/3` /
  `noreply_pipeline/3`.
- **Who** — `echo_mq` and `echo_cache` internals (the two systems built over the wire) and any future direct
  consumer; the Pool is the deployment target.
- **When** — the founding `wire.*` rung, before a higher app standardizes a calling convention.
- **Where** — a new module `echo/apps/echo_wire/lib/echo_wire/pipe.ex`, beside the frozen facade; zero
  connector edits.

**Steelman.** The terminal owns the round-trip, and that is the whole safety story: `exec/1` is literally
`Connector.pipeline(pipe.conn, pipe.cmds, timeout)`, so batch semantics are inherited verbatim from a verb with
52 conformance scenarios behind it. Switching execution mode is one word — `exec → exec_txn` turns the same
built batch into MULTI/EXEC (connector.ex:130) at the verb that already means "run it", where B fragments that
choice onto a separate runner and C onto a different macro. The reply comes back as the positional
`RESP.reply()` list unchanged, so **no new error model is invented** — the two-tier split is already expressed.
Composition with conn-or-pool is free and total: `new/1` carries an opaque `conn` field and never inspects it,
and `Pool.pipeline/3` is signature-identical (pool.ex:48). A single command is `new |> verb |> exec` — a
pipeline-of-one, mirroring the connector's own `command/3` reduction (connector.ex:47).

**Steward.** A's one real liability is **per-verb arity inflation**: a typed verb per command family is an
unbounded set of pinned `{fun, arity}` pairs, the surface that ages worst because each verb is a
hand-maintained promise (the maintenance question rueidis answers with code-gen from `hack/cmds/*.json`). The
**mitigation is a design invariant the triad must carry**: `Pipe` exposes a small *curated* verb set (the
commands `echo_mq`/`echo_cache` actually issue) **plus a generic escape hatch** `Pipe.command(pipe, parts)`
that appends a raw command-list — so the surface is "the curated few + one universal verb", closed and small,
and a never-before-seen command never forces a new public arity. With that invariant A ages well; without it,
worst of the three. Otherwise A is the cleanest long game: it touches **neither** the frozen facade **nor** the
conformance law; it is pure data (offline unit pins of `cmds` + one `:valkey` round-trip test, the same shape
as `echo_wire_facade_test.exs`); it has zero metaprogramming; and One-authority holds — the reply stays
`RESP.reply()`, the batch stays `pipeline/3`, no second source of truth.

### Arm B — the command builder (`EchoWire.Cmd`)

```elixir
import EchoWire.Cmd
[ set("user:1") |> value("alice") |> ex(60) |> build(),
  get("user:1") |> build(),
  incr("hits")  |> build() ]
|> EchoWire.Cmd.run(conn)        # NB: NOT EchoWire.run/2 — see Steward
# => {:ok, ["OK", "alice", 1]}
```

**Rationale.** B targets a narrower, deeper problem than A: build *one command correctly, with its flags, as
an immutable value*. The rueidis load-bearing invariant is "a completed command = an immutable list of binaries
+ bit-packed flags" (`go/valkey-go/internal/cmds/cmds.go:7-9` — `blockTag = 1<<14`,
`readonly = 1<<13 | retryableTag`; `IsBlock()` at cmds.go:168). Those flags drive routing and retry. The
connector today fails all in-flight callers `:disconnected` without replay, precisely because "the connector
cannot know what is idempotent" (connector.ex:21) — a `:readonly` flag is exactly the missing knowledge.

**5W.**
- **Why** — make a *command* an immutable, flagged value, so routing/retry/cacheability can be decided from
  the value rather than re-parsed from `parts`.
- **What** — `EchoWire.Cmd` builder verbs + `build/1` (stamps `parts` + `flags`), the `%Cmd{parts, flags}`
  struct, and `EchoWire.Cmd.run/2` extracting `parts` into `Connector.pipeline/3`.
- **Who** — primarily a *future* retry/routing layer and `echo_cache` (cacheability is its concern); the
  everyday batch caller consumes it only indirectly.
- **When** — a wire rung, but the flag *consumers* (retry-on-`:readonly`, cluster slot routing) are later
  rungs — B ships the vocabulary ahead of its readers.
- **Where** — `echo/apps/echo_wire/lib/echo_wire/cmd.ex` + a `Cmd.run/2`.

**Steelman.** The flag is a contract the connector is already missing, and B is the only arm that creates a
home for it: `%Cmd{parts: ["GET","k"], flags: [:readonly]}` is a value a future retry layer can branch on to
replay an idempotent read across a reconnect, where A and C hold a command as a bare `[binary]` the instant it
is appended. The built command is an inspectable value, testable offline like A. A batch is honest list
composition (`Enum.map`, `++`, comprehensions), and a caller can build commands in one place and run them in
another — which A's connection-bound `%Pipe{}` cannot. B is the faithful port of rueidis's *actual* signature
feature (the `Completed` value), where A and C port only the pipelining half.

**Steward.** Three long-game costs, and here the developer-experience lens turns *against* B too. (1) **The
flags have no consumer yet** — shipping a `:readonly`/`:block` vocabulary whose semantics nothing enforces is
speculative generality; if the flag is wrong (is an `EVAL` of a read-only script `:readonly`?) a wrong contract
is frozen. (2) **Worst arity inflation by construction** — rueidis *code-generates* the builder from
`hack/cmds/*.json` precisely because a hand-maintained per-command × per-option surface is unsustainable;
ported by hand, B is either a massive hand-written surface that ages terribly or it forces **adopting a code-gen
toolchain** into the Elixir build — a permanent maintenance dependency the program has never had. (3) **`build/1`
is ceremony without the benefit** — rueidis's `.Build()` collapses a *compile-time* type-state (the prompt and
the source agree this does not translate to dynamic Elixir); ported, it is a mandatory closing token that buys
nothing the type system enforces, and a forgotten `build/1` is a *runtime* error. Finally, a **reconcile
correction**: the draft `EchoWire.run/2` would be a 12th verb on the facade frozen at 11 (echo_wire.ex:19-31,
the facade test) — it must rehome to `EchoWire.Cmd.run/2`.

### Arm C — the query block (`EchoWire.Query`)

```elixir
import EchoWire.Query
query conn do
  set "user:1", "alice", ex: 60
  get "user:1"
  incr "hits"
end
# => {:ok, ["OK", "alice", 1]}
```

**Rationale.** C targets readability of multi-step scripts: a `query conn do … end` block where each statement
is a command and the block compiles to one pipeline, with optional result binding. For a long, linear sequence
it reads as the cleanest of the three — no `|>`, no `Pipe.` prefix, no `build/1` noise. Elixir's macro system is
designed for exactly this block-to-AST rewrite (Ecto's `from`, Plug pipelines), and the rewrite target is
honest: each verb call becomes a command-list appended to a pipeline, emitted as one `Connector.pipeline/3`.

**5W.**
- **Why** — maximize *reading* ergonomics for the multi-step sequences this stack writes most.
- **What** — a `query/2` macro + a `transaction/2` macro rewriting verb statements into a pipeline, with
  result-binding compiled to positional extraction.
- **Who** — authors of multi-step sequences and test scenarios (the conformance/story suites *are* these).
- **When** — a wire rung, but every later rung that touches it pays the macro-maintenance tax.
- **Where** — `echo/apps/echo_wire/lib/echo_wire/query.ex`, a compile-time module imported at call sites.

**Steelman.** C reads best at the call site for the most-written shape, and a macro can do one thing A and B
cannot: **compile-time validation** — reject an unknown verb at compile time, recovering a sliver of rueidis's
compile-time-safety story that *does* translate (because the macro runs at compile time). The `transaction
conn do … end` form is the most readable transaction surface of the three. The macro can emit the exact same
`Connector.pipeline/3` call A's `exec` makes, so at the wire it is byte-identical — the difference is purely
surface sugar over the same proven terminal.

**Steward.** C ages worst against the program's two load-bearing forces. (1) **Freezability** — the freeze
instrument is `function_exported?/3` over a `{fun, arity}` table (the facade test); a macro does not appear in
that table, so its contract is its *expansion*, pinned only by brittle golden-AST tests that break on incidental
codegen changes across Elixir versions. (2) **Hygiene hazards** — result-binding (`bal = get "acct:1"`) injects
a binding into the caller's scope, a hygiene-sensitive rewrite whose bugs are gate-invisible (compiles, the
happy path passes, the hazard surfaces only under a binding collision or nested block) — the class of latent,
path-dependent defect the connector's own history records (`map_script_reply`, connector.ex:84-88, "found by the
conformance harness on a cold script cache"). (3) **A semantic trap in the transaction form** — inside
MULTI/EXEC the `GET` reply does not exist until `EXEC` runs, so `bal = get "acct:1"; set "acct:1", bal + 100`
*reads* correct but is structurally unavailable; C's most attractive feature is a correctness trap precisely in
its transaction form. Testability is the worst of the three (golden-AST or wire-only), and there is no clean
escape-hatch equivalent (a raw command statement fights the rewriter).

## 3 · The argument — Venus-1 (DX) vs Venus-2 (steward)

**Both lenses converge on Arm A.** Venus-1 ranks **A > C > B**; Venus-2 ranks **A ≻ B ≻ C**. Two architects
arguing from opposite north stars — call-site elegance against multi-year freeze cost — independently
recommend the same arm. The disagreement is only about the *runner-up*, and even that resolves to a sequencing
agreement rather than a conflict.

**Venus-1 (developer-experience).** A is the call site an Elixir engineer writes unprompted: it threads the
wire's native unit with the language's native gesture, and `exec/exec_txn/exec_noreply` express execution
intent as a word at the end of the pipe rather than a structural choice up front. C ranks second on the narrow
axis of "most readable linear sequence"; B ranks last because it ports a `build/1` terminal whose entire
justification is compile-time type-state safety the language does not provide — importing the ceremony without
the benefit is the least idiomatic of the three. *Pre-buttal to the steward's arity-inflation charge:* the
verb count is intrinsic to any typed command-builder and is therefore not a differentiator — B is strictly
*larger* (it fragments each verb across tokens, then adds `build/1` and `run/2`); the routing-by-flag seam is
**not lost** under A (the accumulator keeps command-data up to `exec`, so flags are an additive enrichment
later); and A's freeze is the cheapest to discharge — the existing `function_exported?` table shape — while
touching neither the frozen facade nor the conformance law.

**Venus-2 (spec-steward / invariants).** A is the only arm that does not press on the frozen wire (no
conformance scenario, no script body, the additive-minor law not engaged) — minimum pressure on a wire that
"broke once" is the dominant stewardship virtue. B's flag vocabulary is a real future need but premature, and
its faithful form drags in the rueidis code-gen toolchain; C does not fit the arity-based freeze machinery the
program already owns. *Pre-buttal to the DX "C reads best" charge:* freeze legibility is itself consumer-facing
DX (a consumer reads a `{fun, arity}` table, not a macro expansion); and C's elegance can be **built on top of
A later** — a `query`-style macro whose expansion is `Pipe.new |> ... |> Pipe.exec` — because functions can be
wrapped in a macro but clean functions cannot be extracted from a macro-first surface. "Faithful port" is a
means, not the end: A honors the portable rueidis *invariant* ("a command = an immutable list of binaries"); B
ports the *machinery* (compile-time type-state, code-gen) the source itself shows does not translate.

**The synthesis.** The runner-up split is not a true conflict — both architects agree that B's flags and C's
block-sugar can be *layered onto A later* (flags as an additive enrichment of the accumulator; the block as a
macro expanding to A's functions). So A is not merely the compromise: it is the **base that keeps both other
arms available** while committing to neither the speculative flag vocabulary nor the metaprogramming today.

## 4 · The surfaced fork (Venus surfaces, the Operator rules)

| Arm | Shape | The one-line trade | Lens ranking |
| --- | --- | --- | --- |
| **A** `EchoWire.Pipe` | a `%Pipe{}` threaded by `\|>` to `exec/1` | thinnest skin over `pipeline/3`; no new error model; per-verb surface, closed by an escape-hatch invariant | DX #1 · Steward #1 |
| **B** `EchoWire.Cmd` | build one `%Cmd{parts, flags}`, run a list | the only home for routing/retry flags — but flags have no consumer yet and the faithful form pulls in code-gen | DX #3 · Steward #2 |
| **C** `EchoWire.Query` | a `query conn do … end` macro | most readable linear sequence — but unfreezable by the arity machinery, hygiene + transaction-binding hazards | DX #2 · Steward #3 |

**Recommendation (advice, not a ruling).** Both lenses converge on **Arm A**, carried with one binding
invariant: a **curated verb set + a generic `Pipe.command/2` escape hatch**, so the public surface is "the few
commands the stack issues + one universal verb", never one public arity per Redis command.

**The sub-fork inside A, surfaced for the Operator:** *curated-verbs + escape-hatch* vs *full per-command
surface*. The recommendation takes the former; the latter is the unbounded, worst-aging form.

**The deferred seam, surfaced for the roadmap's "Seams & open decisions":** the per-command **flag /
cacheability surface** (rueidis `Completed`) — opened *when* a retry or cluster-routing rung gives the flags a
consumer. A's escape hatch is forward-compatible: a future `Cmd` value can feed `Pipe.command/2`, so choosing A
**sequences** B rather than foreclosing it. C's block syntax is likewise a later macro layer over A's functions.

**Two triad corrections, required regardless of the ruling:**
1. If B is chosen, `run/2` must be rehomed off the frozen facade (e.g. `EchoWire.Cmd.run/2`) — `EchoWire` may
   not grow past 11 verbs.
2. Every arm must state the **conn-or-pool** contract explicitly: the entry point accepts `Connector` *or*
   `Pool` (signature-identical, pool.ex:48) and never inspects it.

---

**Provenance.** Argued by Venus-1 (developer-experience lens) and Venus-2 (spec-steward / invariants lens) per
the multi-architect-debate pattern of [aaw.architect-approach.md](../../../aaw/aaw.architect-approach.md). The
rueidis facts are source-grounded at `go/valkey-go` (the tree moved from `apps/valkey-go` during the session);
every `echo_wire` surface is verified at its source.

**References.** Method: [aaw.architect-approach.md](../../../aaw/aaw.architect-approach.md). Canon &
surfaced-fork precedent: [emq.design.md](../../emq.design.md). The wire: `echo/apps/echo_wire/lib/echo_mq/`
(`connector.ex` · `resp.ex` · `script.ex`), the facade `echo/apps/echo_wire/lib/echo_wire.ex` (frozen at 11,
`echo_wire_facade_test.exs`), the pool `echo/apps/echo_mq/lib/echo_mq/pool.ex`, the conformance count
`echo/apps/echo_mq/lib/echo_mq/conformance.ex`. The rueidis reference: `go/valkey-go`
(`internal/cmds/gen_string.go` · `internal/cmds/cmds.go:7-9` · `pipe.go:1097` · `message.go:143-154`).
