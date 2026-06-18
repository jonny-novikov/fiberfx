# EchoMQ benchmarking framework { id="echo_mq-bench-framework" }

> _A repeatable way to measure the EchoMQ bus at each stage against another MQ on the same box. First candidate: Oban. This document defines what we measure, how, and how to read it honestly; the `mq_bench` project is the harness; `REPORT.md` holds the first local run._

## Goal and shape

Measure EchoMQ's bus operations against an analogue in another MQ, **stage by stage**,
on one machine, with each system exercised through its *real* mechanism. The first
candidate is Oban because it is the Elixir default and the opposite storage
philosophy — Valkey/Redis (volatile by EchoMQ's decision D-2) versus PostgreSQL
(durable rows). The comparison is therefore as much about the **durability trade-off**
as about raw speed, and the framework is built to make that trade-off visible rather
than to hide it behind a single headline number.

## What we measure

Per stage, three families of metric:

- **Throughput** — operations/second at a fixed concurrency.
- **Latency** — per-operation p50/p99/avg.
- **Cost shape** — how the number moves with concurrency, pipelining/batching, and
  durability setting (the last is the decisive axis for EchoMQ-vs-Oban).

## The fairness rules (read these before the numbers)

A benchmark that compares a memory store to a durable store can mislead in either
direction. These rules keep it honest:

1. **Each system runs its real mechanism.** EchoMQ admission is its actual v3 enqueue
   script (`EchoMQ.Jobs.enqueue/4`: kind-law → idempotent `EXISTS` refuse → `HSET`
   row → `ZADD` score-0 pending) issued over RESP3. Oban admission is the real
   PostgreSQL write `Oban.insert` performs (a row into the `oban_jobs` schema with its
   fetch index). Neither is a strawman re-implementation.
2. **Durability is reported, never assumed.** EchoMQ's bus is volatile by design
   (D-2): admission is memory-resident, no per-op fsync. Postgres is durable by
   default (`synchronous_commit=on`: an fsync per commit). We therefore report Oban at
   **both** its durable default *and* relaxed `synchronous_commit=off`, so the reader
   sees the durability-matched number and the default-durability number side by side.
   The gap between EchoMQ and durable-Oban is mostly this axis, and saying so is the
   point.
3. **Same box, same payload, same run length.** One machine, a fixed 64-byte payload,
   identical warmup and duration, tables/keyspace reset between scenarios.
4. **Absolute numbers are hardware-bound; the comparison travels.** The first run is a
   single-core sandbox — its absolute figures are not production numbers. The relative
   shape (and the durability decomposition) is what carries to other hardware.

## The stages (scenario catalogue)

The harness runs admission today; the rest are the staged roadmap, each mapped to the
EchoMQ surface and an Oban analogue. "Harness" = drivable by `mq_bench` now; "full
app" = needs the `echo_mq` umbrella running (and is scripted in the suite for a real
deployment).

| Stage | EchoMQ operation | Oban analogue | Status |
|---|---|---|---|
| **Admission (single)** | `Jobs.enqueue/4` (atomic script) | `Oban.insert/1` | **harness** |
| **Admission (batch)** | `Jobs.enqueue_many/3` (pipelined) | `Oban.insert_all/1` | **harness** |
| Claim → complete | `Jobs.claim/3` + `complete/5` | engine fetch + ack | full app |
| Fairness under contention | `Lanes` rotating ring across N groups | Smart-engine partition/limit (Pro) | full app |
| Scheduled release | `enqueue_in/5` + `Pump` promote | scheduled jobs + Stager | full app |
| Fan-out / fan-in | `Flows.add/3` | Workflows (Pro) | full app |
| Throughput ceiling | `Pool` (pipelined connectors) | queue concurrency | full app |

## Feature side-by-side — current EchoMQ vs Oban analogue

The user's ask: existing EchoMQ features, as they are *today*, against their Oban
analogue. This is the map the staged benchmark fills in.

| EchoMQ (today) | What it does | Oban analogue | Notes for benchmarking |
|---|---|---|---|
| `Jobs.enqueue/4` | atomic admit, kind-law + dedup | `Oban.insert` | apples-to-apples admission; the headline stage |
| `Jobs.enqueue_many/3` | pipelined batch admit | `Oban.insert_all` | batch admission; both amortise the round-trip |
| `Lanes` (rotating ring) | per-identity fairness, free | global concurrency / partitioning (Pro) | measure starvation under a hot tenant |
| `Jobs.claim/3` + `complete/5` | lease + settle | engine fetch + ack | round-trip latency; Oban's is in-engine |
| `enqueue_at/in` + `Pump` | schedule + promote | scheduled jobs + Stager plugin | promotion latency at depth |
| `Flows` | single-queue fan-in | Workflows (Pro) | DAG completion time |
| `Backoff` | pure retry curve | per-worker backoff | host-side; not a bus op |
| `Stalled` + reap | recover/dead-letter | Lifeline / Rescuer | recovery time after a killed worker |
| `Events` | lifecycle pub/sub | Telemetry events | notification latency |
| `Metrics` | pure-read plane | retained-row queries | read cost without mutation |
| `Meter` | `[:emq,…]` telemetry | Telemetry | parity, not a perf axis |
| `Admin` | queue pause/drain/obliterate | pause/resume + Web | operational, not throughput |
| `Pool` | pipelined connector pool | queue concurrency | throughput ceiling |
| `Conformance` (55) | the wire contract | — | correctness gate, run alongside |

## The harness

`mq_bench` is a standalone mix project (no `echo_mq` umbrella dependency, so it builds
anywhere hex is reachable):

- **EchoMQ side** — `MqBench.Echo` drives the real v3 enqueue script over `redix`
  against Redis/Valkey on port 6390 (the same RESP3 path the connector uses).
- **Oban side** — the real `oban` + `ecto_sql` + `postgrex` against Postgres, Oban
  configured for admission only (`queues: []`, `plugins: false`) so we measure
  `insert`, not execution.
- **Driver** — `Benchee`, with markdown output, reset between scenarios.

Run while developing:

```bash
# services
redis-server --port 6390 --save '' --appendonly no &
# (Postgres running; bench/bench DB created)
mix deps.get
mix bench.setup     # ecto.create + ecto.migrate (Oban tables)
mix bench.admit     # the admission stage -> bench/results/*.md + console
```

When hex or Valkey/Postgres are unavailable, the same operations are measurable with
the engines' native tools — `redis-benchmark` running the enqueue script and `pgbench`
running the `oban_jobs` insert — which is exactly how `REPORT.md`'s first run was
produced.

## Reading the result

The headline is not "EchoMQ is N× Oban." It is the **decomposition**: how much of the
gap is the durability trade-off (memory bus vs fsync — EchoMQ's D-2 choice) and how
much is the substrate (a Redis script vs a Postgres row + index). `REPORT.md` reports
both, because that decomposition is the actual engineering content of an
EchoMQ-vs-Oban comparison.
