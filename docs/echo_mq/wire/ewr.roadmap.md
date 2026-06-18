# EchoWire — the client-core program roadmap

Read [Echo References](../emq.references.md) before EXPANDING this roadmap. The design fork this program
builds from is [`design/ewr.design.md`](design/ewr.design.md) (RULED: Arm A); the method that fork follows is
[`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md).

## The epic

**One program, two movements: a brand-new `EchoWire.*` construction surface, ported from the valkey-go
(rueidis) client core, layered additively over the owned wire — never into it.**

- **Why.** `echo_wire` already owns the hard half of a Valkey client: a single-owner socket connector that
  *auto-pipelines* concurrent callers (`EchoMQ.Connector`, the in-flight FIFO `send_pipe/5`..`drain/1`), a full
  RESP3 decoder (`EchoMQ.RESP`), EVALSHA-first scripting (`EchoMQ.Script`), a round-robin pool (`EchoMQ.Pool`),
  all behind a frozen 11-verb facade (`EchoWire`). What it has never owned is the **construction** half: above
  `Connector.pipeline/3` a caller hand-writes nested `[[binary]]` literals and keeps positional flags correct by
  eye. The rueidis client answers exactly this — a fluent builder plus connection-level auto-pipelining —
  and EchoWire ports the construction ergonomics in idiomatic Elixir, additively, leaving the frozen wire
  untouched.
- **What.** A new `EchoWire.*` surface in three additive rungs — a threaded `|>` pipeline (`EchoWire.Pipe`),
  then a command vocabulary plus an immutable command value, then a two-tier error split — each an ergonomic
  façade over the existing `Connector.pipeline/3` family — then a Movement-I **closer (`ewr.1.4`) that adopts the
  core into its first real consumer** (`echo_mq`'s own internals). Server-assisted client-side caching (CLIENT
  TRACKING) is named as a later movement, not folded into the core.
- **Who.** Every Elixir caller assembling Valkey command batches: `echo_mq`'s own internals, `echo_store`'s
  direct-Valkey paths, and application code. The connector and the pool are the deployment targets; the new
  surface is the ergonomics they reach for.
- **When.** Opens now — the design fork is ruled (Arm A), and the SQLite / store-design questions are closed.
  Movement I is the additive core; Movement II is gated on a real caching consumer.
- **Where.** `echo/apps/echo_wire` — a new `lib/echo_wire/` module tree beside the frozen `lib/echo_mq/`
  connector and the `lib/echo_wire.ex` facade. The program canon is `docs/echo_mq/wire/`.

## The floor (the owned wire, as-built)

The program builds strictly **above** this floor; every name here is frozen and is cited, never edited.

- **`EchoMQ.Connector`** (`echo/apps/echo_wire/lib/echo_mq/connector.ex`) — the single-owner `:gen_tcp`
  GenServer. `pipeline/3` (:56) takes a list of command-lists and answers `{:ok, [RESP.reply()]}`;
  `transaction_pipeline/3` (:130) wraps `MULTI`/`EXEC` and answers `{:ok, exec_replies}`; `noreply_pipeline/3`
  (:125) suppresses replies via `CLIENT REPLY OFF/ON` and answers `:ok`; `command/3` (:47) is a pipeline of
  one; `eval/5` (:63) is EVALSHA-first. It **already auto-pipelines** concurrent callers — the new surface adds
  *construction*, never pipelining. The version fence (`fence/2` :465 reads `EchoMQ.Keyspace.version_key/0`
  :466 against `@wire_version` :33 — the climbing fence, `echomq:2.4.2` live).
- **`EchoMQ.RESP`** (`resp.ex`) — the 13-term RESP3 decoder; the `reply()` type at :30 covers simple/error/
  int/bulk/verbatim/array/push/set/map/bool/null/double/bignum. Server errors decode to the in-band value
  `{:error_reply, binary()}`, not a transport failure.
- **`EchoMQ.Script`** (`script.ex`) — `new/2`, the SHA-precomputed script struct; EVALSHA-first execution is
  `Connector.eval/5`.
- **`EchoMQ.Pool`** (`echo/apps/echo_mq/lib/echo_mq/pool.ex`) — a fixed pool of connectors with lock-free
  round-robin dispatch. `pipeline/3` (:48), `command/3` (:45), `eval/5` (:51), `stats/1` (:55) are
  signature-identical to the connector's. It carries **no** `transaction_pipeline/3` or `noreply_pipeline/3`
  — by design: a transaction and a reply-suppression window are connection-stateful and cannot round-robin
  across members.
- **`EchoWire`** (`lib/echo_wire.ex`) — the facade, **frozen at 11 verbs** (:19–31; ten `defdelegate` to
  `Connector` + `script/2` to `Script.new`), pinned by `test/echo_wire_facade_test.exs`. `EchoMQ.Connector` /
  `RESP` / `Script` are "frozen by the committed records that cite them" (the facade moduledoc).
- **The conformance truth row** — the 52-scenario suite in `echo_mq`: `EchoMQ.Conformance.run/2 → {:ok, 52}`
  (`echo/apps/echo_mq/test/conformance_run_test.exs:45`), pinned by `conformance_scenarios_test.exs`. The wire
  client-core lives *above* this boundary and leaves the count byte-stable.

## The movements

### Movement I · The ergonomic core — COMPLETE (ewr.1.1–1.4 BUILT)

Three additive rungs that port the valkey-go *construction* ergonomics as new `EchoWire.*` modules, then a
closer (`ewr.1.4`) that adopts them into the first real consumer. The three core rungs each land on the
`Connector.pipeline/3` family; none touches the frozen connector, RESP, or Script; none grows the 11-verb
facade; the conformance stays byte-stable.

- **`ewr.1.1` — `EchoWire.Pipe`, the threaded pipeline.** The `%Pipe{conn, cmds}` accumulator threads through
  `|>`; a curated verb set appends one command-list each; `exec/1` flushes once into `Connector.pipeline/3`
  (with `exec_txn/1` / `exec_noreply/1` variants), and a generic `Pipe.command/2` escape hatch keeps the
  curated set from ever being a ceiling. **The founding rung** (specced this run).
- **`ewr.1.2` — the command vocabulary + the immutable command value.** The rueidis `Completed` model
  (`internal/cmds/cmds.go:117`) ported as Elixir data: an immutable command carrying its parts plus
  bit-packed advisory flags (`cf`, cmds.go:5–23). The flags stay advisory in the upper layer (seam 4).
- **`ewr.1.3` — the two-tier error split.** The rueidis `NonValkeyError()` vs `Error()` distinction
  (`message.go:149`/`:154`): a result classifier separating a transport failure (`{:error, term}`) from a
  server error carried in-band as `{:error_reply, _}` (resp.ex:47), so a caller can branch on which tier broke
  without re-parsing.
- **`ewr.1.4` — adopt `EchoWire.Pipe` into `echo_mq`'s internals.** Movement I's
  **closer**: convert `echo_mq`'s hand-written multi-command `Connector.pipeline/3` call-sites (the nested
  `[[binary]]` literals, positional flags kept correct by eye) to the `EchoWire.Pipe` builder — proving the core
  on a real consumer before Movement II's caching trade. **Gated on `ewr.1.2` + `ewr.1.3`** (the adoption uses
  the *complete* construction surface — command value + error split — not the bare pipeline). **The boundary
  widens here:** unlike `ewr.1.1`–`1.3` (which edit only `echo_wire` + the one story-tooling seam), `ewr.1.4` is
  the FIRST ewr rung to touch `echo_mq`'s **runtime** call-sites — an explicit, surfaced widening. The frozen
  wire stays frozen (`Connector`/`RESP`/`Script`/`Pool` untouched, the 11-verb facade unchanged, `grep
  redis.call` on the diff = 0 — a construction refactor, not a Lua/protocol change); the **proof is
  behaviour-preservation** — `echo_mq`'s conformance + every suite green and byte-stable across the swap. A
  single one-shot `Script.new/2` eval is NOT a wiring target. NOT an emq.4–8 capability rung — this is the wire
  client's adoption, not a bus feature.

### Movement II · Server-assisted caching — RESOLVED (shipped in `echo_store`)

The rueidis client-side-caching half: `DoCache` / `Cacheable` (`pipe.go:1480`), the
`CLIENT TRACKING ON [OPTIN|BCAST]` handshake (`pipe.go:185`), and the `invalidate` push → eviction coherence
(`pipe.go:748`) — the "message about a name" the BCS law names, and the natural fit for an L1 cache in front of
Valkey (the `echo_store` L1).

**Resolution (2026-06-18).** Built as the `echo_store` `:tracking` coherence mode, **not a wire rung**: the
connector already delivers invalidation pushes to a `push_to` consumer, de-interleaves them from in-band
replies, and emits reconnect telemetry — so no frozen-connector boot-step was needed. The send side and the
eviction coherence both compose from the existing public surface; reconnect survival is **flush-then-re-arm**,
which demotes the once-feared wire **MAJOR** to a deferred warmth optimization. The L1 consumer is
`echo_store`'s `EchoStore.Table` (`coherence: :tracking`). See
[`../store/store.tracking.md`](../store/store.tracking.md).

## The rung ladder

| Rung | Movement | Ships (the slice) | Status |
| --- | --- | --- | --- |
| **`ewr.1.1`** | I | `EchoWire.Pipe` — the threaded `\|>` pipeline + a curated verb set + the `command/2` escape hatch + `exec` / `exec_txn` / `exec_noreply` | ✅ **BUILT** |
| `ewr.1.2` | I | the command vocabulary + the immutable command value (the `cf`-flag model, advisory) | ✅ **BUILT** |
| `ewr.1.3` | I | the two-tier error split (transport vs server: `NonValkeyError` vs `Error`) | ✅ **BUILT** |
| `ewr.1.4` | I | adopt `EchoWire.Pipe` into `echo_mq`'s internals — the first real consumer (convert the multi-command `Connector.pipeline/3` call-sites) | ✅ **BUILT** (the Movement I closer) |
| `ewr.2.x` | II | CLIENT TRACKING / client-side caching | ✅ **RESOLVED** — shipped as `echo_store` `:tracking` (no wire edit); [`../store/store.tracking.md`](../store/store.tracking.md) |

## How the program runs

The AAW **Flat-L2 lead-team** ships each rung (Venus authors/reconciles the triad → Mars builds to the brief
and is the code-quality gate → the Director verifies independently → Apollo mentors out of the pipeline), per
the repo-root workflow and the `echo-mq-*` skills. The app is **`echo_wire`**; the gate ladder is **per-app**,
run from inside `echo/apps/echo_wire/`: re-probe `.tool-versions`; `valkey-cli -p 6390 ping` → `PONG`;
`TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test` (add `--include valkey` for the
round-trip gate). An additive-layer rung **re-pins** the facade-freeze (11 verbs) and the conformance count
(`{:ok, 52}`) as byte-stable rather than registering new scenarios — the layer is above the conformance
boundary.

## The master invariant

The wire client-core lives **above** the conformance boundary, and every Movement-I rung is **additive-minor by
construction**: `EchoMQ.Connector` / `RESP` / `Script` stay frozen (no edit); the `EchoWire` facade stays fixed
at 11 verbs (the new surface is *new modules*, never a facade delegate); no new Lua enters the wire
(`grep redis.call` on the lib diff is `0`); the 52-scenario conformance stays byte-stable. The **single
exception** is Movement II's caching: the `CLIENT TRACKING` handshake may require a connector boot-step — the
one place the program may cut into the frozen wire, and it is gated as an explicit **MAJOR** with its own
surfaced fork, never folded into an additive rung.

## Seams & open decisions

1. **The arm choice (A / B / C)** — **RULED: Arm A (`EchoWire.Pipe`).** The developer-experience and
   spec-steward lenses converged on the threaded `|>` pipeline; B's flags and C's block-macro stay *layerable
   onto* A, not the reverse. CLOSED. (→ [`design/ewr.design.md`](design/ewr.design.md))
2. **The sub-fork inside A** — **RULED: a curated verb set + a generic `Pipe.command/2` escape hatch** (not a
   full per-command surface). The curated set is convenience; the escape hatch guarantees any command
   expressible as `[[binary]]` is still reachable, so the curated set is never a ceiling. CLOSED.
3. **Client-side caching / CLIENT TRACKING** — **RESOLVED (2026-06-18): shipped as an `echo_store` consumer,
   no wire MAJOR.** Ground truth showed the frozen connector already suffices — `push_to` delivery of
   invalidation pushes, push-frame de-interleaving (`fill/5`), and `[:emq, :connector, :reconnect]` telemetry
   — so the feature landed as the `echo_store` `:tracking` coherence mode (a RESP3 `CLIENT TRACKING ON BCAST`
   consumer over a table's `ecc:{table}:` prefix), **zero `echo_wire` edits**. Reconnect survival is
   **flush-then-re-arm** (the L1 drops on reconnect), which makes the connector boot-step a pure warmth
   optimization — deferred, maybe never. See [`../store/store.tracking.md`](../store/store.tracking.md).
4. **The `cf`-flag command model** — **OPEN.** `ewr.1.2` ports rueidis's immutable command value (parts +
   bit-packed flags) as Elixir data, but the flags stay **advisory** in the upper layer — the connector does
   not act on them — until a retry or cluster-routing consumer gives them meaning. Promoting a flag to
   connector behaviour is a separate, later decision.
5. **The `echo_wire` ↔ `echo_mq` Keyspace edge** — **NOTED** (not a fork). The connector's version fence
   already reads `EchoMQ.Keyspace.version_key/0` (`connector.ex:466`), so `echo_wire` is not hermetic from
   `echo_mq` today. The client-core does not deepen this edge; it is recorded so a later rung does not
   rediscover it as a surprise.

## Dependencies, recorded

- **`echo_wire`** (base) — the owned wire; the only app a Movement-I rung edits.
- **`echo_data`** — the identity library; not yet consumed by the core (a forward edge).
- **`go/valkey-go`** — the rueidis-derived reference; the pattern source, read-only, cited never copied.
- **[`design/ewr.design.md`](design/ewr.design.md)** — the ruled fork the rungs build from.
- **[`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md)** — the method the fork follows.

---

Design: [`design/ewr.design.md`](design/ewr.design.md) · Dashboard: [`ewr.progress.md`](ewr.progress.md) ·
Features: [`ewr.features.md`](ewr.features.md) · Testing: [`ewr.testing.md`](ewr.testing.md) ·
References: [`ewr.references.md`](ewr.references.md) · Founding rung:
[`specs/ewr.1/ewr.1.1.md`](specs/ewr.1/ewr.1.1.md) · The bus program:
[`../emq.roadmap.md`](../emq.roadmap.md)
