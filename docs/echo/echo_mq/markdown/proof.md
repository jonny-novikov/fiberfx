# The Proof — EchoMQ, In Depth (route mirror: `/echomq/proof`)

> Route-mirror md for the Proof chapter **landing**. The HTML at `html/echomq/proof/index.html` reflects this.
> The conformance, telemetry, and read-plane surfaces are **real code** in `echo/apps/echo_mq`
> (`conformance.ex` / `meter.ex` / `metrics.ex`) — no `[RECONCILE]` marker. The **benchmark** is the one frontier:
> there is **no benchmark module on disk** (`EchoMQ.Bench` does not exist), so it is a **`soon` card on the landing**,
> never a built module and never a fabricated surface — the cleaner expression than a `[RECONCILE]` marker, and **zero
> `[RECONCILE]` leaks into the HTML**. Manuscript figure home: `docs/echo/bcs/bcs.6.md` (B6, the four libraries as one
> umbrella).

## Thesis

The Proof is the closing pillar: **the whole system holds, and it can show you.** A bus is only as good as the evidence
it can produce about itself, and EchoMQ produces three kinds — but two are shipped code and one is a named frontier:

- **Conformance — it is proven.** The contract is not asserted, it is **run**. The conformance suite
  (`EchoMQ.Conformance`) is the bus contract written as a set of runnable scenarios: each drives the public surface — or
  raw commands where the contract *is* the wire — against a **live server** and asserts the externally visible verdict.
  The protocol is *proven*, not promised, and any runtime that speaks the wire must pass the same set: the polyglot
  promise made testable.
- **Telemetry — it reports.** The running system answers *how it is doing* without being asked to change.
  `EchoMQ.Meter` meters the lifecycle the standard Elixir `:telemetry` way (re-rooted under `[:emq, …]`), at **zero cost
  when `:telemetry` is absent**; `EchoMQ.Metrics` is a **pure-read plane** — every verb observes, none mutates — that
  reports counts, state, throughput, and the rate-gate over the as-built structures.
- **Benchmark — the named frontier.** The third concern is performance under load, and it is **the frontier**: there is
  **no benchmark surface on disk yet**, so it is named here and built later. No-invent: a surface that is neither code
  nor canon is fabrication, so the benchmark is a `soon` card — a promise the page keeps honest by not pretending it is
  shipped.

The thread is the same one that runs through every pillar — the branded id. A scenario asserts a verdict about a named
`JOB`; a meter event carries the lifecycle of a named job; a read answers which set holds a named id. Proof is the
system telling the truth about itself, in the same vocabulary it works in.

## The three concerns (the framing interactive)

Pick a concern to read what it is, the surface beneath it, and whether it is shipped or the frontier.

- **Conformance** — `EchoMQ.Conformance.scenarios/0` + `run/2`. Status: **proven** (real code). The bus contract as a
  set of named scenarios, each asserting an externally visible verdict against a live server; `run/2` answers
  `{:ok, n}` when all pass or `{:error, failed_names}` otherwise.
- **Telemetry & the read plane** — `EchoMQ.Meter` + `EchoMQ.Metrics`. Status: **reporting** (real code). Push (the
  lifecycle metered via `:telemetry`) and pull (a pure-read plane over the as-built sets); one observes by emitting, the
  other answers without changing anything.
- **Benchmark** — the named frontier. Status: **on the build front** (no surface yet). Throughput and latency under
  load; named so the picture is whole, never invented so the page stays honest.

## The modules

1. **The conformance suite** (`/echomq/proof/the-conformance-suite`) — `EchoMQ.Conformance`: `scenarios/0` (the names +
   one-line contracts in run order), `run/2` (run on per-scenario sub-queues, purge what it mints, one `CONF` line each,
   the `{:ok, n}` / `{:error, names}` verdict), and the additive-minor growth law — prior scenarios byte-frozen and
   git-verified, each new one probe-registered, the count re-pinned. The contract is run, not asserted, and any runtime
   that speaks the wire must pass the same set.
2. **Telemetry & the read plane** (`/echomq/proof/telemetry-and-the-read-plane`) — `EchoMQ.Meter` (the `:telemetry`
   surface over the job lifecycle, re-rooted under `[:emq, …]`, zero cost when absent) + `EchoMQ.Metrics` (the pure-read
   plane: per-state counts, job state, throughput, the rate-gate, lane depth — every read declares its keys). Two ways
   the running system reports on itself: push and pull.
3. **Benchmark** — the named frontier. Throughput and latency under load; the placement story the `{q}` hashtag and the
   declared-keys discipline exist *for*. **No surface on disk** — named here, built later. (Not yet built.)
4. **Workshop** (`/echomq/proof/workshop`) — prove it on a live queue: run the conformance suite (`Conformance.run/2`),
   attach a meter and watch the `[:emq, :job, …]` events flow, then read the plane (`Metrics.get_counts/3` +
   `lane_depth/3` + `is_maxed/2`) over a codemojex queue. The system holds, meters itself, and reports honestly.

## Redis Patterns Applied (the reverse door)

This is the depth behind two `/redis-patterns` chapters that door here:

- **R2 · Coordination** (`/redis-patterns/coordination`) — the atomicity the conformance suite proves. The claim
  script's single-owner token, the fence read before any work, the kind law, the stale-token refusal — every one is a
  named scenario asserting an externally visible verdict. There the coordination pattern is the door; here the suite is
  the proof it holds.
- **R8 · Production operations** (`/redis-patterns/production-operations`) — running the tier in production. Telemetry
  is how you see the bus working without changing it; the read plane is how you answer counts, state, and the rate-gate
  without mutating a thing. There the operations pattern is the door; here is the plane it reads.

There the pattern is the door; here is the evidence.

## The rest of the system

The Proof is the closing reading of the shared substrate. The **Queue** distributes work over the wire; the **Bus**
broadcasts signals and keeps a replayable log; the **Cache** serves reads in front of it; the **Protocol** below them
all is the keyspace every key is born to. Proof shows the whole of it holds.

## References

### Sources
- Beck — Test-Driven Development (`https://www.oreilly.com/library/view/test-driven-development/0321146530/`) — the
  verdict-asserting scenario as the contract: the test states the externally visible truth the suite proves.
- Elixir — the `:telemetry` library (`https://hexdocs.pm/telemetry/readme.html`) — the standard metering surface the
  Meter re-roots under `[:emq, …]`, opt-in at zero cost when the dep is absent.
- Erlang/OTP — `:telemetry.execute/3` (`https://hexdocs.pm/telemetry/telemetry.html`) — the emit the guarded
  `function_exported` check fences, so the bus carries no telemetry dependency edge.
- Valkey — `ZCARD` (`https://valkey.io/commands/zcard/`) — the per-state cardinality the read plane's `get_counts`
  answers over the four sorted sets.

### Related in this course
- The Queue (`/echomq/queue`) — distribute work; the first pillar the conformance suite proves whole.
- The Bus (`/echomq/bus`) — broadcast signals; the second pillar over the same wire.
- The Cache (`/echomq/cache`) — serve reads; cache-aside in front of the bus.
- The Protocol (`/echomq/protocol`) — the keyspace and branded-id gate every scenario asserts against.
- Overview (`/echomq/overview`) — the chapter that frames the three pillars.
- The Branded Component System — together (`/bcs/together`) — the manuscript chapter (B6) where the four libraries
  become one umbrella the Proof shows holds.
