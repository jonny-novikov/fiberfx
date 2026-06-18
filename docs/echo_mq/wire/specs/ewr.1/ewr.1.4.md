# EWR.1.4 · adopt the wire-core into `echo_mq` + the version-reflection rule (Movement I, the closer)

> **Status: BUILT — shipped green, solo (no team — a small rung).** Movement I's closer
> ([`../../ewr.roadmap.md`](../../ewr.roadmap.md)): `echo_mq` becomes the **first real consumer** of the
> EchoWire client-core, AND the program's **mandatory protocol-version rule** is instituted. Gate:
> `Conformance.run/2 → {:ok, 55}` byte-stable, the `enqueue_many` round-trip + the version guard green
> (`echo_mq` 10/0 on the targeted suite), `grep redis.call` on the diff = `0`, the frozen wire + the 11-verb
> facade untouched.

## What shipped (two coupled halves, one small rung)

1. **The adoption.** `EchoMQ.Jobs.enqueue_many/3` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`) — `echo_mq`'s one
   hand-written multi-command pipeline (a nested-list `for`-comprehension of `EVALSHA`s flushed through
   `Connector.pipeline/2`) — is rebuilt on **`EchoWire.Pipe`** (`ewr.1.1`): the per-pair `EVALSHA` accumulates
   via the `command/2` escape hatch and flushes once through `exec/1`. **Behaviour-preserving** on the defined
   domain — the same `@enqueue.sha`, the same `KEYS`/`ARGV`, the same `:enqueued` / `:duplicate` /
   `{:error, :kind}` mapping in pair order (proven by `test/jobs_test.exs` + conformance byte-stable). The
   `EVALSHA` is reached through `command/2` because it is not a curated verb (`ewr.1.1-INV6`); `EchoWire.Cmd` /
   `EchoWire.Result` were **not** forced in (the per-reply `:kind` map does not fit `Result`'s whole-return
   classifier — using them here would gold-plate). The lone runtime edit is `jobs.ex` — the FIRST ewr rung to
   touch `echo_mq` runtime, an explicit, bounded boundary-widening.
   - *One benign edge change (noted, untested in the suite):* an **empty** `pairs` now answers
     `{:error, :empty_pipeline}` (the Pipe's empty guard, `pipe.ex:508`) instead of the old
     `Connector.pipeline` `cmds != []` `FunctionClauseError` — a strict improvement.

2. **The version-reflection rule (the mandate) + its guard.** From `ewr.1.4` onward, **`echo_wire`'s library
   version reflects the echomq protocol version** — `echo_wire`'s `mix.exs` version, `echo_mq`'s `mix.exs`
   version, and the protocol version carried by the connector `@wire_version` (`echomq:X.Y.Z`,
   `connector.ex:35`) + the `{emq}:version` fence are **ONE number, climbing in lockstep every rung** (the emq
   climbing fence, `emq.4.2-D3`; `2.4.2` today). The wire and the bus are versioned and shipped as **one unit**,
   so `echo_wire vN ⟺ echo_mq protocol vN` by construction — **no wire↔bus skew, full compatibility**. The
   single-owner wire (no external clients; connector + server + the now-bus-internal `EchoWire.*` consumer
   deploy as a unit) makes this safe and exact. This is an addition to the **wire master invariant**
   ([`../../program/ewr.program.md`](../../program/ewr.program.md)); the lockstep is a coordinated **minor** on
   the climb to `echomq:3.0.0` (the `emq.8` MAJOR).
   - **The guard** (`echo/apps/echo_mq/test/version_reflection_test.exs`, the dep closure — `echo_wire` is the
     dep-free base) asserts the three numbers agree. A future rung that climbs one and forgets the others turns
     the guard **red** — the rule is self-enforcing, not a promise.

## The frozen floor (held)

`EchoMQ.Connector` / `RESP` / `Script` / `Pool` untouched; the `EchoWire` facade still 11 verbs; no new Lua
(`grep redis.call` on the diff = `0`); `echo/mix.lock` unchanged; conformance byte-stable at the **current**
count (`{:ok, 55}` — the wire *reflects* the bus's count, freezes no number). Determinism posture: a refactor
+ a pure guard — no id-mint / process / lease, so a multi-seed sweep, not the ≥100 loop.

---

Touch-set: `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`enqueue_many/3`) ·
`echo/apps/echo_mq/test/version_reflection_test.exs` (new) · this doc. Roadmap:
[`../../ewr.roadmap.md`](../../ewr.roadmap.md) · Bus climbing fence:
[`../../../emq.roadmap.md`](../../../emq.roadmap.md) (`emq.4.2-D3`).
