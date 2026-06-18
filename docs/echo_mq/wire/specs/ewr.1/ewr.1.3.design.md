# EWR.1.3 — the two-tier error split (transport vs server) · the design fork

> The design fork for the **placement** of EchoWire's two-tier error split — the rueidis
> `NonValkeyError()` vs `Error()` distinction (`go/valkey-go/message.go:149`/`:154`) brought into idiomatic
> Elixir as a discriminator over `EchoWire.Pipe.exec/1`'s return. This document surfaced the fork in four arms;
> the method is [`aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md) — Rationale · 5W ·
> Steelman · Steward per arm, then the surfaced fork with a recommendation. It mirrors the chapter design fork
> [`../../design/ewr.design.md`](../../design/ewr.design.md). **Venus surfaced; the Operator RULED Arm 1.**
>
> **RULED: Arm 1 — the pure `EchoWire.Result` classifier** (the Operator's ruling, 2026-06-18; Venus's
> recommendation). The chosen-against arms (2 / 3 / 4) keep their Steelman + `CHOSEN-AGAINST:` case below so the
> decision stays inspectable a year later. The **result-shape sub-question** (the internal representation of
> `classify/1`'s return — a tagged tuple vs a `%EchoWire.Result{}` struct) is **delegated to Mars's design-make**
> (the Director's call, per the "contract-to-specify, shape-to-leave-to-Mars" rule,
> [`../../program/ewr.venus.md`](../../program/ewr.venus.md)): the frozen CONTRACT is the four rueidis-mirrored
> accessors + the total transport-vs-server partition (§3); the internal SHAPE is the implementor's, runnable-
> checked through the accessors, never pinned as a tuple literal.

## 0 · Genesis — the split already exists in the data; the fork is how to NAME it

The two-tier distinction rueidis draws between a transport failure and a server (protocol) error is **already
present in the as-built return** — `ewr.1.1`'s closed error set established it
([`ewr.1.1.md`](ewr.1.1.md), The closed error set):

- **The transport tier** is `EchoWire.Pipe.exec/1`'s `{:error, term}` — the whole-call failure the connector
  raises before or instead of a reply list: `{:error, :disconnected}` (socket loss; in-flight callers failed,
  never replayed — `connector.ex:197-198`/`:592`), `{:error, :overloaded}` (the `max_pending` backpressure —
  `connector.ex:234-237`), `{:error, {:version_fence, got}}` (the boot fence — `connector.ex:478`/`:483`), and
  the Pipe's own `{:error, :empty_pipeline}` (`pipe.ex:501`).
- **The server tier** is the in-band value `{:error_reply, binary()}` (`resp.ex:47`) — a successful flush
  `{:ok, [reply]}` whose reply *list* carries one or more `{:error_reply, _}` slots (e.g.
  `{:ok, ["OK", {:error_reply, "WRONGTYPE Operation against a key holding the wrong kind of value"}, 1]}`). A
  server error on the `pipeline/3` path is **never** a transport failure and **never** the `{:error, {:server,
  _}}` term — see §1, The verified server-error shape.

The rueidis reference is two methods on the result value (`go/valkey-go/message.go`): `ValkeyResult.NonValkeyError()`
(`:149-151`) returns only the transport error `r.err`; `ValkeyResult.Error()` (`:154-161`) returns the transport
error **or** folds in the server error `r.val.Error()`; and `(*ValkeyMessage).Error()` (`:740-751`) maps a RESP
simple/blob error frame (the `-`/`!` first byte → our `{:error_reply, _}`) to a `*ValkeyError`, a RESP null to
`Nil`, and anything else to `nil`. The model is a **clean discriminator for which tier broke** — the caller asks
one of two questions rather than re-parsing `exec`'s return by hand at every call site.

**The fact that frames the whole fork:** no arm changes `exec/1`. `exec`'s shipped `{:ok, [reply]} | {:error,
term}` contract is **FROZEN** by `ewr.1.1` (`pipe.ex:500`); the split is a **NEW surface OVER `exec`'s return**,
never an edit to it. The fork is not "add error handling" — the wire already returns everything needed — it is
"choose how a caller DISCRIMINATES the two tiers that the return already expresses." Each arm is weighed as a
new public surface the program freezes and tests for years.

## 1 · The seam, the verified server-error shape, and the frozen-surface constraints

**The seam.** Every arm reads `exec/1`'s already-decoded return (`pipe.ex:500` — `{:ok, [reply]} | {:error,
term}`). The classifier is **pure**: it touches no socket, performs no round-trip, and calls nothing on the
connector — it is a function over a value `exec` already produced. The change is **additive-minor by
construction** and lives strictly *above* the conformance boundary
([`../../program/ewr.program.md`](../../program/ewr.program.md), The wire master invariant).

**The verified server-error shape (load-bearing — re-probed at the as-built tree).** For the
`Connector.pipeline/3` family that `exec/1` flushes through, a server error is **always** the in-band value
`{:error_reply, binary()}` inside `{:ok, [reply]}`, and **never** `{:error, {:server, _}}`:

- `pipeline/3` (`connector.ex:56`) → `GenServer.call(conn, {:pipeline, cmds})` → `send_pipe(..., :plain)`
  (`connector.ex:239`) → on drain, `pipe_reply(:plain, replies)` = **`{:ok, replies}`** (`connector.ex:560`).
  The `replies` list is raw decoded `RESP.reply()` values: `fill/5` pushes whatever `RESP.parse` returns,
  including `{:error_reply, msg}` verbatim (`connector.ex:573` → `resp.ex:47`). **No server-error → `{:error,
  {:server, _}}` mapping exists on this path.**
- The `{:error, {:server, msg}}` term is **`eval/5`-EXCLUSIVE** (`connector.ex:76-77` and `map_script_reply/1`
  at `:87`), reached only from the EVALSHA scripting path — which `EchoWire.Pipe` does not use (`exec`/`exec_txn`/
  `exec_noreply` call `pipeline`/`transaction_pipeline`/`noreply_pipeline`, never `eval`). It reaches a caller
  only through `EchoWire.script/2` → `Connector.eval/5`, outside the Pipe surface.
- `EchoMQ.Pool.pipeline/3` (`pool.ex:48`) is a pure pass-through to `Connector.pipeline` — it adds no re-map, so
  the shape is identical against a connector or a pool.
- `exec_txn/1` answers `{:ok, exec_replies}` (the `EXEC` array — `connector.ex:562` `List.last`); a server error
  inside a transaction is an `{:error_reply, _}` slot in that array, the same server-tier shape.

So the classifier's server tier is **exactly** "find the `{:error_reply, _}` values in the reply list", and its
transport tier is **exactly** `exec`'s `{:error, term}` branch. The discrimination is total and rests on no
invented term.

**The frozen-surface constraints (every arm honors all):**

- **`exec/1` is frozen** — `{:ok, [reply]} | {:error, term}` is the `ewr.1.1` contract; the split adds a new
  surface that READS this return, never a variant that changes it. (Arm 2 adds *new* exec verbs beside it; even
  there the existing `exec/1` is byte-unchanged — see §2.Arm-2.)
- **The facade stays at 11 verbs** (`echo_wire.ex:19-31`, pinned by `echo_wire_facade_test.exs`). The new
  surface is a **new module** (`EchoWire.Result`), never a `defdelegate` on `EchoWire`.
- **Frozen names** — `EchoMQ.Connector` / `RESP` / `Script` / `Pool` are reused, never edited; no new Lua
  (`grep redis.call` on the lib diff is `0`).
- **The conformance count stays byte-stable** — `Conformance.run/2 → {:ok, 53}` (`conformance_run_test.exs:46`);
  the layer is above the conformance boundary, so the additive-minor *registration* law is **not engaged** (no
  scenario registered, no `registry.json` written).
- **`RESP.reply()` is the reply representation** — the classifier introduces no second decode of a reply; it
  *partitions* the existing `RESP.reply()` values, it does not re-type them.

## 2 · The fork — four arms

### Arm 1 — a pure `EchoWire.Result` classifier over `exec`'s return (RECOMMENDED)

```elixir
conn
|> EchoWire.Pipe.new()
|> EchoWire.Pipe.set("k", "v")
|> EchoWire.Pipe.lpush("k", "x")      # WRONGTYPE against the string at "k"
|> EchoWire.Pipe.exec()
|> EchoWire.Result.classify()
# => {:server_error, ["OK"], [{1, {:error_reply, "WRONGTYPE Operation against a key ..."}}]}
#    tag · the :ok replies · the [{index, error_reply}] server-error slots

EchoWire.Result.non_valkey_error(exec_return)   # transport tier only  → {:error, term} | nil
EchoWire.Result.error(exec_return)              # transport OR first server error → {:error, term} | {:error_reply, msg} | nil
EchoWire.Result.server_errors(reply_list)       # the per-reply lens   → [{index, {:error_reply, msg}}]
```

**Rationale.** The split already lives in `exec`'s return; Arm 1 names it with a **pure classifier module** that
the caller pipes `exec`'s result into. It is the faithful Elixir port of the rueidis model — `non_valkey_error/1`
mirrors `NonValkeyError()` (transport only), `error/1` mirrors `Error()` (transport OR the folded-in server
error), and a `classify/1` that returns a tagged result (`{:ok, replies}` clean · `{:transport_error, term}` ·
`{:server_error, oks, [{index, error_reply}]}`) gives the caller one branch point. It is a credible answer
because it adds **zero new wire surface** — `exec/1` is untouched, the classifier reads a value — and it
mirrors rueidis's *actual* discriminator (two methods on a result value), not a re-shaped return.

**5W.**
- **Why** — a caller who wants to branch on "did the transport break, or did the server reject one command?"
  must today re-parse `exec`'s return by hand (`case` on `{:error, _}` vs walk the list for `{:error_reply, _}`)
  at every call site; Arm 1 makes that one named function.
- **What** — a new pure module `EchoWire.Result` carrying four accessors over `exec`'s return: `classify/1` (the
  transport-vs-server partition), `non_valkey_error/1` (the transport-tier question, `NonValkeyError()`),
  `error/1` (the transport-or-server question, `Error()`), and `server_errors/1` (the per-reply lens — `[{index,
  {:error_reply, _}}]` over a reply list). The four accessors + the partition are the contract; the **internal
  representation** of `classify/1`'s return is the implementor's design-make (§3, delegated to Mars).
- **Who** — every caller of `EchoWire.Pipe.exec/1`/`exec_txn/1` that needs to distinguish the tiers: a future
  retry layer (transport errors are retryable on an idempotent batch; a server `WRONGTYPE` is not), a caller
  surfacing a typed error upward, `echo_store`/`echo_mq` command sites reading a batch result.
- **When** — Movement I, rung 3 (the last ergonomic-core rung), after `ewr.1.1` (the accumulator + `exec`) and
  `ewr.1.2` (the command value). It depends only on `exec`'s frozen return, so it layers cleanly on the floor.
- **Where** — a new module `echo/apps/echo_wire/lib/echo_wire/result.ex` beside `pipe.ex`, with the offline
  unit suite in `echo_wire` and the BDD `:valkey` stories in `echo_mq/test/stories/` (the dep direction, as
  `ewr.1.1`).

**Steelman.** Arm 1 is the thinnest possible skin over a distinction the wire already draws, and that is the
whole safety story: it changes **no** existing surface — `exec/1`'s `{:ok, [reply]} | {:error, term}` contract
is byte-identical, so no `ewr.1.1` test moves and the founding rung's frozen floor is untouched. It is **pure
data over a value** — testable entirely offline by feeding hand-built `exec`-shaped returns (`{:ok, ["OK",
{:error_reply, "WRONGTYPE ..."}, 1]}`, `{:error, :disconnected}`) and asserting the partition, plus one
`:valkey` story that provokes a *real* server error (`set` a string then `lpush` it → a genuine `{:error_reply,
"WRONGTYPE ..."}` from Valkey on `6390`) and proves the classifier splits it from the `:ok` replies. It is the
**faithful** port: rueidis discriminates with two methods *on the result*, and Arm 1 is two functions *on
`exec`'s return* — the same shape, where Arm 2 re-shapes the return and Arm 3 drops the transport tier. One-
authority holds: `exec` stays the single source of the return, `RESP.reply()` stays the reply type, the
classifier *partitions* — it introduces no second result representation. And it composes forward: a `ewr.1.2`
`%Cmd{}` carrying a `:readonly` flag plus Arm 1's transport/server discrimination is exactly the pair a retry
layer needs — transport-tier + idempotent ⇒ replayable — so Arm 1 is the natural completion of the error half
the way `ewr.1.2` is the completion of the command half.

**Steward.** Arm 1's one real liability is **a public vocabulary the program must freeze**: the tag set
(`:transport_error` / `:server_error` / `:ok`, or whatever `classify/1` returns) and the `error/1`-vs-
`non_valkey_error/1` split become a frozen contract — a consumer branches on those tags, so renaming one later
is a breaking change. The mitigation is that the vocabulary is **small, total, and derived** — three tags
covering the two tiers `exec` already expresses plus the clean case, mirrored 1:1 from a shipped reference
(rueidis's two methods), so it ages as well as the distinction it names (which is intrinsic to any Valkey
client). It adds a handful of pure-function pins and one `:valkey` story; it has zero metaprogramming, touches
neither the facade nor the conformance law, and carries no process or state. The honest cost: a *tri-state*
`classify/1` is slightly richer than rueidis's binary `Error()`/`NonValkeyError()` because a pipeline can carry
a *partial* server failure (some replies ok, one `{:error_reply, _}`) that a single-command rueidis `Do` cannot
— so the per-reply `server_errors/1` lens (the `[{index, error_reply}]` shape) is a genuine addition beyond the
port, justified because the batch is EchoWire's native unit. That richness is the smallest surface that tells
the truth about a batch; a binary tag would lose the index of the failed command. Of the four arms, Arm 1 ages
best: it freezes the least and re-uses the most.

### Arm 2 — new exec variants on Pipe (`exec_split/1` / `exec!/1`)

```elixir
conn |> EchoWire.Pipe.new() |> EchoWire.Pipe.set("k","v") |> EchoWire.Pipe.lpush("k","x")
|> EchoWire.Pipe.exec_split()
# => {:server_error, ["OK"], [{1, {:error_reply, "WRONGTYPE ..."}}]}
#    a richer tri-state shape: {:ok, replies} | {:transport_error, term} | {:server_error, oks, errs}

conn |> EchoWire.Pipe.new() |> EchoWire.Pipe.get("k") |> EchoWire.Pipe.exec!()
# => ["alice"]   (raises EchoWire.TransportError / EchoWire.ServerError on either tier)
```

**Rationale.** Arm 2 targets the same split, but places the discrimination **at the flush** rather than in a
separate read step: a new `exec_split/1` returns the richer tri-state directly, and a bang `exec!/1` raises on
either tier for the "I expect success, crash otherwise" caller. The rationale is ergonomic immediacy — the
caller asks for the classified result in one verb at the end of the pipe, with no second `|> Result.classify`
hop, mirroring how `ewr.1.1` made `exec → exec_txn` a one-word switch of execution mode.

**5W.**
- **Why** — collapse "flush then classify" into one terminal, so the split is reached without a second module
  in the call chain.
- **What** — two **new** flush verbs on `EchoWire.Pipe`: `exec_split/1` (the tri-state shape) and `exec!/1`
  (raises typed exceptions `EchoWire.TransportError` / `EchoWire.ServerError`), each leaving the existing
  `exec/1`/`exec_txn/1`/`exec_noreply/1` byte-unchanged.
- **Who** — the same consumers as Arm 1; the bang form additionally serves scripts/tests that want a fail-fast
  flush.
- **When** — Movement I, rung 3, same position as Arm 1.
- **Where** — additions to `echo/apps/echo_wire/lib/echo_wire/pipe.ex` (the existing module grows), plus two
  small exception modules.

**Steelman.** Arm 2 reads best at the call site for the caller who wants the classified result *and nothing
else*: one verb, no second hop, and the bang variant is the most ergonomic fail-fast surface of the four —
`exec!` is the idiomatic Elixir "give me the value or raise". It keeps the split physically adjacent to the
flush that produces it, so a reader sees the execution intent and the error posture in one word. Because the new
verbs sit beside `exec/1` without changing it, `ewr.1.1`'s contract is still honored at the letter — `exec/1`
is frozen; `exec_split/1` is a *sibling*, not a mutation.

**Steward.** Arm 2's costs are where the steward lens turns against it. (1) **It grows the `Pipe` surface
permanently** — two more flush verbs (plus their pool-vs-connector contract: does `exec_split` work against a
pool? `exec!`?) and two exception types, each a frozen public promise, where Arm 1 adds one cohesive module
that the existing `exec/1` feeds. The error-classification concern is **mixed into the construction module**
rather than given its own home — `Pipe` becomes "build *and* flush *and* classify *and* raise", a wider single
responsibility. (2) **The bang form encodes a policy** — raising on a server `{:error_reply, _}` is one opinion
(a `WRONGTYPE` is often a branch, not a crash); freezing `exec!`'s raise-on-server-error semantics commits the
program to that opinion, and a caller who wants raise-on-transport-but-branch-on-server is unserved. (3) **It is
harder to test in isolation** — `exec_split`/`exec!` only exist against a live (or mocked) flush, so the pure
offline partition tests Arm 1 gets for free become `:valkey`-bound or require a fake `via`. (4) Arm 2 and Arm 1
are **not** mutually exclusive in the long run — `exec_split` could later be sugar over `Result.classify` — but
choosing Arm 2 *first* puts the vocabulary in the wrong module and makes the pure classifier harder to extract,
the inverse of the `ewr.1.1` lesson that "functions can be wrapped in a verb but clean functions cannot be
pulled out of a verb-first surface".

### Arm 3 — a per-reply lens only (`server_errors/1`), no result wrapper

```elixir
{:ok, replies} = conn |> EchoWire.Pipe.new() |> ... |> EchoWire.Pipe.exec()
EchoWire.Result.server_errors(replies)
# => [{1, {:error_reply, "WRONGTYPE ..."}}]   (or [] when every reply is clean)
```

**Rationale.** Arm 3 is the minimalist arm: ship **only** the per-reply lens — a function mapping a reply list
to its `{:error_reply, _}` slots (or a `{oks, server_errors}` split) — and ship **no** transport-tier surface at
all, on the argument that the transport tier is *already* idiomatic (`exec` returns `{:error, term}`; a caller
`case`s on it with no help needed), so the only un-served need is finding the server errors buried in a
successful reply list. It is a credible answer because it adds the smallest possible surface for the one genuinely
awkward task (walking a reply list), and leaves the transport tier exactly as `ewr.1.1` shipped it.

**5W.**
- **Why** — the transport tier is already a clean `{:error, term}` branch; only the *server* tier (an
  `{:error_reply, _}` hidden among `:ok` replies) is hard to read, so ship only that.
- **What** — one pure function (`server_errors/1`, or `partition/1` → `{oks, errs}`) over a reply list. No
  `classify/1`, no `non_valkey_error/1`, no `error/1`.
- **Who** — a caller post-`{:ok, replies}` who needs to know which commands the server rejected.
- **When** — Movement I, rung 3.
- **Where** — a small `echo/apps/echo_wire/lib/echo_wire/result.ex` (one function) or even a single addition.

**Steelman.** Arm 3 freezes the *least* of any arm — one pure function over a list — and is the cheapest to
maintain and test (a handful of offline list-partition assertions plus one `:valkey` story). It honors "thin but
robust" most literally: it adds exactly the missing capability (server-error extraction from a reply list) and
nothing speculative, refusing to wrap the transport tier that is already idiomatic. It is forward-compatible —
a later `classify/1` (Arm 1) could call `server_errors/1` internally — so it forecloses nothing.

**Steward.** Arm 3's liability is **an incomplete port that re-fragments the very split it set out to name.**
The whole point of the rueidis model is the *paired* discriminator — `NonValkeyError()` AND `Error()` — so a
caller asks one consistent question ("which tier?") at one place. Arm 3 ships half of it and leaves the caller to
hand-write the transport half at every site, so the split is *named in one tier and folklore in the other* — the
asymmetry the program's own history warns against (a partial contract is the surface that drifts). It also
under-serves the headline consumer: a retry layer needs the *transport-vs-server* decision (transport ⇒ maybe
retry; server ⇒ never), which Arm 3 does not provide — it provides only the server-side half. The "transport is
already idiomatic" premise is true today but thin: `non_valkey_error/1` and `error/1` are not about *reading*
`{:error, term}` (easy) but about giving the two tiers a **single named vocabulary** so a consumer branches on
`Result.*` uniformly rather than mixing a bare `case` with a list walk. Arm 3 saves a few functions now and
costs the uniform discriminator the whole rung exists to provide.

### Arm 4 — defer the rung; fold the split into the `ewr.1.2` command value

**Rationale.** The do-nothing/baseline arm, argued seriously: do **not** ship `ewr.1.3` as a standalone error
surface; instead, when `ewr.1.2`'s `%Cmd{}` value lands (parts + advisory `cf` flags), let the eventual
retry/routing *consumer* of those flags carry whatever error discrimination it needs, internally, when it is
built. The argument is that the split has **no consumer today** — no retry layer, no routing layer exists — and
shipping a frozen `Result` vocabulary ahead of its reader is speculative generality (the same charge the design
fork levelled at Arm B's flags, [`../../design/ewr.design.md`](../../design/ewr.design.md), §2.B-Steward).

**5W.**
- **Why** — avoid freezing an error-classification vocabulary before a consumer gives it meaning.
- **What** — nothing now; the capability arrives folded into a future retry/routing rung.
- **Who** — deferred to that rung's author.
- **When** — not on the Movement-I ladder; re-opened when a flag consumer exists.
- **Where** — no new surface; the roadmap's "Seams & open decisions" records the deferral.

**Steelman.** Arm 4 is the honest counterweight: it spends nothing and freezes nothing, and if the split's only
real consumer is a retry layer that does not yet exist, building the vocabulary now risks freezing the wrong
shape (does a `MOVED`/`ASK` cluster-redirect count as transport or server? rueidis treats it as a
`*ValkeyError` sub-case — `message.go:76-92` — a nuance a premature Elixir split might get wrong). Deferral keeps
the option open to design the discriminator *with* its consumer, when the trade is real.

**Steward.** Arm 4's cost is that it leaves a **named, ruled rung unbuilt and the split permanently folklore.**
Unlike the design fork's deferred *flag* seam (which had genuinely no shape until a routing consumer existed),
the error split's shape is **already fully determined by the as-built return** — transport `{:error, term}` vs
in-band `{:error_reply, _}` — so there is no shape risk to defer away: the discriminator is not speculative, it
is a faithful naming of a distinction the wire already draws and a shipped reference (rueidis) already validates.
The `MOVED`/`ASK` nuance is moot on a single-node deployment and is reachable via the escape hatch regardless.
Deferring it means every caller re-derives the tier discrimination by hand indefinitely — the precise
re-derivation tax the whole EchoWire program exists to remove (the `ewr.1.1` rationale: callers "re-derive the
same discipline by hand"). And `ewr.1.3` is a *ruled* Movement-I rung on the ladder
([`../../ewr.roadmap.md`](../../ewr.roadmap.md)); Arm 4 un-rules it without a new fact. The do-nothing arm is on
the table for honesty; its Steward is weak precisely because the split, unlike the flags, is not premature.

## 3 · The fork — RULED: Arm 1 (Venus surfaced, the Operator ruled)

| Arm | Shape | The one-line trade | Lens read |
| --- | --- | --- | --- |
| **1 — RULED** `EchoWire.Result` classifier | pure `classify/1` + `non_valkey_error/1` + `error/1` + `server_errors/1` over `exec`'s return | thinnest skin; `exec/1` untouched; faithful rueidis port; offline-testable; one small frozen vocabulary | **recommended → RULED** — least frozen, most reused |
| **2** new exec variants | `exec_split/1` / `exec!/1` on `Pipe` (+ exception types) | split at the flush, no second hop — but grows the `Pipe` surface, mixes classify into construct, bakes a raise policy | richer ergonomics, wider + harder-to-extract surface |
| **3** per-reply lens only | `server_errors/1` only; no transport-tier surface | freezes least — but ships half the paired discriminator; transport tier stays folklore | minimal, but an incomplete port |
| **4** defer (fold into `ewr.1.2`) | nothing now | freezes nothing — but the split's shape is already determined, so there is nothing to defer away; un-rules a ruled rung | baseline; weak Steward (not premature) |

**RULED: Arm 1** (the Operator's ruling, 2026-06-18 — Venus's recommendation). A pure `EchoWire.Result`
classifier over `exec`'s return. The one reason that carries it: it names the two tiers `exec` **already**
returns with the **faithful** rueidis discriminator (two functions on the result, mirroring
`NonValkeyError()`/`Error()`), at **zero** cost to the frozen `exec/1` contract and zero new wire surface — the
cheapest correct completion of the error half, the way `ewr.1.2` is the command half. The chosen-against arms
(2 / 3 / 4) keep their Steelman + `CHOSEN-AGAINST:` case (§2) so the path not taken stays on the record.

**The CONTRACT (frozen, specified by the triad) vs the SHAPE (delegated to Mars's design-make).** Per the
"contract-to-specify, shape-to-leave-to-Mars" rule ([`../../program/ewr.venus.md`](../../program/ewr.venus.md),
the conn-or-pool precedent), the rung specifies the **observable contract + its runnable checks**, never the
internal representation:
- **The frozen contract** is the **four rueidis-mirrored accessors** over `exec`'s return — `classify/1` (the
  total transport-vs-server partition: clean / transport-error / server-error), `non_valkey_error/1` (transport
  only, `NonValkeyError()`), `error/1` (transport-or-server, `Error()`), `server_errors/1` (the indexed per-reply
  lens) — plus the partition's behaviour (total + exhaustive over `exec`'s return; the server tier is exactly the
  in-band `{:error_reply, _}`; transport precedes server; the three agree). A consumer branches through the
  accessors, so the accessors are the surface that ages.
- **The implementor's design-make** is the **internal representation of `classify/1`'s return** — a tagged tuple
  (e.g. `{:ok, replies}` | `{:transport_error, term}` | `{:server_error, oks, [{index, error_reply}]}`) **or** a
  `%EchoWire.Result{}` struct (`:status`, `:replies`, `:transport_error`, `:server_errors`). Either realizes the
  same accessor contract; naming the tuple in the spec would over-constrain a free choice, exactly as pinning the
  `%Pipe{via}` dispatch field would have on `ewr.1.1`. The tuple above is **illustrative**, not the contract; the
  triad's checks run **through the accessors** (assert what `classify/1`/`error/1`/`non_valkey_error/1`/`server_errors/1`
  answer), not against a literal return shape. The Director may rule the representation or leave it to Mars.

**The deferred seam, surfaced for the roadmap's "Seams & open decisions":** **cluster-redirect classification**
(`MOVED`/`ASK` as a server-error sub-case, rueidis `message.go:76-92`). On the single-node deployment a
`MOVED`/`ASK` is just another `{:error_reply, _}` (correctly server-tier); a *finer* sub-classification (a
`:redirect` sub-tag a routing layer branches on) is opened **when** a cluster-routing consumer exists — the same
sequencing as the `cf`-flag seam (decision 4). Arm 1's `server_errors/1` is forward-compatible: a future router
can sub-match the `{:error_reply, msg}` binaries it returns without a surface change.

**Two notes that hold regardless of the ruling:**
1. **`exec/1` does not change.** Whichever arm wins, `ewr.1.1`'s `{:ok, [reply]} | {:error, term}` contract is
   byte-identical; the facade stays at 11 verbs; conformance stays `{:ok, 53}`.
2. **The server tier is in-band only on the Pipe surface.** The `{:error, {:server, _}}` term is `eval/5`-only
   (`connector.ex:76-77`) and unreachable through `EchoWire.Pipe`; the classifier's server tier is exactly the
   in-band `{:error_reply, _}` value (`resp.ex:47`). A future `eval`-aware classifier is out of this rung's
   scope (the Pipe does not flush through `eval`).

---

**Provenance.** Framed by Venus (spec-steward) per the four-part-arm method of
[`aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md). Every `echo_wire` surface is verified
at its source (`pipe.ex` / `resp.ex` / `connector.ex` / `pool.ex`, re-probed at the as-built tree); the rueidis
facts are source-grounded at `go/valkey-go/message.go` (`:149-151` `NonValkeyError`, `:154-161` `Error`,
`:740-751` `(*ValkeyMessage).Error`, `:53`/`:76-92` `ValkeyError`/`IsMoved`/`IsAsk`); the unbuilt `EchoWire.Result`
is written forward-tense.

**References.** Method: [`aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md). Chapter design
fork (the mirror): [`../../design/ewr.design.md`](../../design/ewr.design.md). The closed error set this rung
classifies: [`ewr.1.1.md`](ewr.1.1.md) (The closed error set). The features/blast-radius map:
[`../../ewr.features.md`](../../ewr.features.md) (the two-tier error split row). The wire:
`echo/apps/echo_wire/lib/echo_mq/` (`connector.ex` · `resp.ex`) + `echo/apps/echo_wire/lib/echo_wire/pipe.ex`
(the frozen `exec/1`). The rueidis reference: `go/valkey-go/message.go`.
