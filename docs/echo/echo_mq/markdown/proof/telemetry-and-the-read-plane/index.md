# Telemetry & the read plane

> Route: `/echomq/proof/telemetry-and-the-read-plane` · Pillar VI — the Proof · Module 02 (hub).
> Grounds in `EchoMQ.Meter` (`meter.ex`) + `EchoMQ.Metrics` (`metrics.ex`), both `echo/apps/echo_mq`.
> As-shipped, dark-editorial, no version labels, no `file:line`, no Lua block (the read/telemetry verbs issue
> direct through `EchoMQ.Connector`; the read scripts are shipped + declared-keys, but the page teaches the
> Elixir verb, never a Lua body).

The conformance suite proves the system is **correct**. This module is the other half of the question a
running system has to answer: **how is it doing right now** — and it has to answer that *without being asked
to change*. The bus answers it two ways, and they are mirror images of each other.

**Push.** As work happens, the lifecycle **emits events** — a job admitted, started, completed, failed — the
standard Elixir `:telemetry` way, re-rooted under `[:emq, …]`. A host that wants throughput, latency, and
failure counts attaches a handler and the numbers flow to it. This is `EchoMQ.Meter`.

**Pull.** At any moment, a caller can **read the state** — counts per state, which set holds an id, the
completed/failed throughput, the rate-gate — off the bus's as-built structures. Every verb **observes; none
mutates**. This is `EchoMQ.Metrics`.

One side *observes by emitting*; the other side *answers by reading*. Neither changes the work. Together they
are the whole self-report: the system tells you what is happening as it happens, and answers a question about
its state whenever you ask.

## The framing interactive — push and pull, one lifecycle

A single job moves left to right through its lifecycle. On the **push** side, each transition fires an
`[:emq, :job, …]` event to an attached meter handler — `add`, `start`, `complete` (or `fail`). On the
**pull** side, a `Metrics` read answers the same lifecycle as **counts** — how many ids sit `pending`,
`active`, `scheduled`, `dead` right now. The interactive lets the reader watch the job advance and see both
reports update: the meter receives an event, the read plane reports the new shape.

- **push** — `EchoMQ.Meter` emits `[:emq, :job, :start]` / `[:emq, :job, :complete]` to whoever attached;
  zero cost if no `:telemetry` is loaded.
- **pull** — `EchoMQ.Metrics.get_counts/3` reads `ZCARD` of each state set (and the terminal-outcome
  counters), answering a map of state → count without moving a single member.

## The three dives

1. **The telemetry surface** (`the-telemetry-surface`) — `EchoMQ.Meter`: `attach` / `attach_many` / `emit` /
   `span` + the lifecycle emitters (`job_added/4`, `job_started/4`, `job_completed/5`, `job_failed/6`),
   re-rooted under `[:emq, …]` — one event tree with the connector's `[:emq, :connector, …]`.
2. **Zero cost when absent** (`zero-cost-when-absent`) — the opt-in property: every emission guards
   `:erlang.function_exported(:telemetry, :execute, 3)`, so with no `:telemetry` dependency loaded an emit is
   a no-op and an `attach` answers `:ok` with no effect. The bus carries **no `:telemetry` dependency edge**.
3. **The read plane** (`the-read-plane`) — `EchoMQ.Metrics`: pure-read verbs — `get_counts/3`,
   `get_job_state/3`, `get_metrics/3`, `get_rate_limit_ttl` + `is_maxed/2`, `lane_depth/3`. Every verb
   observes; none mutates. Every read script declares its keys; an unregistered state name is an error, never
   an open read.

## Redis Patterns Applied

This module is the depth behind **Redis Patterns Applied** — **R8 · Production Operations**
(`/redis-patterns/production-operations`): the metering and read-side introspection an operator runs a tier
with, made concrete as the `EchoMQ.Meter` event tree and the `EchoMQ.Metrics` read plane. There the pattern is
the door; here is the surface.

## The rest of the pillar

Module 01 (the conformance suite) proves the contract holds; this module is how the proven system reports on
itself; the benchmark gate is the named frontier. The whole pillar shows the same thing three ways: the system
holds, meters itself, and reads honestly.

## References

### Sources
- [Elixir — the `:telemetry` library](https://hexdocs.pm/telemetry/readme.html) — the standard metering surface the Meter re-roots under `[:emq, …]`.
- [Erlang/OTP — `:telemetry.execute/3`](https://hexdocs.pm/telemetry/telemetry.html) — the execute the guarded emit calls when the dependency is loaded.
- [Valkey — ZCARD](https://valkey.io/commands/zcard/) — the cardinality the read plane counts each state set by.
- [Valkey — ZSCORE](https://valkey.io/commands/zscore/) — the membership test `get_job_state/3` resolves an id by.

### Related in this course
- `/echomq/proof/telemetry-and-the-read-plane/the-telemetry-surface` — the push side, `EchoMQ.Meter`.
- `/echomq/proof/telemetry-and-the-read-plane/zero-cost-when-absent` — the opt-in property.
- `/echomq/proof/telemetry-and-the-read-plane/the-read-plane` — the pull side, `EchoMQ.Metrics`.
- `/echomq/proof` — the pillar this module belongs to.
- `/echomq/queue` — the lifecycle the meter and the read plane observe.
- `/bcs/together` — the manuscript chapter (B6) where the four libraries are one umbrella.
