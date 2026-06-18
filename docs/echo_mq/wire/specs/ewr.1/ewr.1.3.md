# EWR.1.3 · EchoWire.Result — the two-tier error split (Movement I, the ergonomic core closes)

> **Status: BUILT** — shipped green, Director-verified (design Arm 1, the Operator's ruling `2026-06-18`; the
> partition mutation independently re-killed). The third and final Movement-I rung
> ([`../../ewr.roadmap.md`](../../ewr.roadmap.md)). It builds a new **pure** module **`EchoWire.Result`**
> (`lib/echo_wire/result.ex`) that NAMES the two-tier error distinction rueidis draws — `NonValkeyError()` vs
> `Error()` (`message.go:149`/`:154`) — as a **classifier over `EchoWire.Pipe.exec/1`'s already-decoded return**.
> The split already exists in the data (`ewr.1.1`'s closed error set); this rung does not invent it, it gives it a
> vocabulary. Pure — it reads a value `exec` produced, touches no socket, calls nothing on the connector. `exec/1`
> is frozen and byte-unchanged; the frozen wire and the 11-verb facade are untouched; conformance byte-stable.

## The surface — four accessors over `exec`'s return

- **`classify/1`** — the transport-vs-server partition, one of three outcomes: **clean** (no reply is a server
  error) · **transport-error** (`exec`'s `{:error, term}` whole-call branch) · **server-error** (`{:ok, replies}`
  with ≥1 in-band `{:error_reply, _}`, carrying the replies + the indexed error slots).
- **`non_valkey_error/1`** — the transport-tier question (rueidis `NonValkeyError()`): `{:error, term}` or `nil`;
  a success carrying server errors answers `nil` (a server error is not a transport error).
- **`error/1`** — transport-or-server (rueidis `Error()`): the transport error if present, else the first
  `{:error_reply, _}`, else `nil`.
- **`server_errors/1`** — the per-reply lens: a reply list → `[{index, {:error_reply, msg}}]`, 0-based ascending.

The **four accessors + the partition behaviour are the frozen contract**; the internal representation of
`classify/1`'s return (a tagged tuple, `oks` = the full reply list) was Mars's design-make, checked *through* the
accessors, never pinned as a literal.

## The two tiers (the as-built shapes — classified, not invented)

- **Transport** (`exec`'s `{:error, term}`): `:disconnected` · `:overloaded` · `{:version_fence, _}` ·
  `:empty_pipeline` · any `{:error, term}`.
- **Server** (the in-band `{:error_reply, binary()}` value, `resp.ex:47`): `WRONGTYPE`, `ERR`, a Lua-surfaced
  error. The `eval/5`-exclusive `{:error, {:server, _}}` is unreachable through `Pipe` — recorded, not classified.

## Invariants

- **`exec/1` frozen; classifier purely additive.** `pipe.ex` not edited; `EchoWire.Result` is a standalone module
  reading `exec`'s return. Facade still **11 verbs**; no new Lua; conformance byte-stable (emq-owned count); no
  Mix-task edit (the `--match` filter already shipped).
- **Pure + total.** No `Connector`/`Pool`/socket/process (`grep` = `0`); `classify/1` is total and exhaustive over
  `exec`'s return — every input lands in exactly one outcome.
- **The honest net-zero proof is the PARTITION mutation, not an order theorem.** `error/1`'s two clauses match
  disjoint inputs (`{:error, _}` vs `{:ok, _}`), so there is no order-mutation to kill (the delta from `ewr.1.1`).
  The real mutation: blind `server_errors/1` (drop the `{:error_reply, _}` match) → the real `WRONGTYPE` `:valkey`
  story dies. **KILLED**, and the Director re-killed it independently.
- **Stories proven, not prose.** The server-error story provokes a REAL `WRONGTYPE` (not a hand-built error);
  idempotent regen; the bus stories dir stays git-clean (the shared-tool no-harm assertion).

**Gate (green):** `echo_wire` compile-clean + the offline partition suite + facade-still-11; from `echo_mq` the
wire `:valkey` story suite (the real `WRONGTYPE` split + the transport path) + the idempotent `--match wire_pipe`
regen + conformance byte-stable (emq-owned, 54 at ship); the partition misclassify mutation **KILLED**. Touch-set:
`result.ex` + `result_test.exs` + the `wire_pipe_error_*` stories + the generated stories — **no `pipe.ex` edit**.

---

Stories: [`ewr.1.3.stories.md`](ewr.1.3.stories.md) · Brief: [`ewr.1.3.llms.md`](ewr.1.3.llms.md) · Runbook:
[`ewr.1.3.prompt.md`](ewr.1.3.prompt.md) · Design (the ruling): [`ewr.1.3.design.md`](ewr.1.3.design.md) ·
Ledger: [`../progress/ewr-1-3.progress.md`](../progress/ewr-1-3.progress.md) · Predecessor:
[`ewr.1.1.md`](ewr.1.1.md) · Roadmap: [`../../ewr.roadmap.md`](../../ewr.roadmap.md)
