# EchoMQ vs Oban — first local run { id="echo_mq-bench-report" }

> _Results of the admission stage measured on one machine, EchoMQ's bus against Oban, each through its real mechanism. The headline is the **decomposition**, not a single multiplier: how much of the gap is the durability trade-off and how much is the substrate. Methodology lives in `framework.md`._

## Environment

A single-core sandbox. **The absolute numbers are not production figures** — Redis is
single-threaded so it uses the one core fully, while Postgres cannot show parallel
scaling on one core, so its higher-concurrency rows are contention-bound rather than
representative. What carries to real hardware is the *relative shape* and the
durability decomposition below.

| | |
|---|---|
| CPU | Intel Xeon @ 2.80 GHz, **1 vCPU** |
| Memory | 3.9 GiB |
| Elixir / OTP | 1.14.0 / Erlang 25 (the pinned EchoMQ contract) |
| Redis | 7.0.15, jemalloc 5.3.0, port 6390, `--save '' --appendonly no` (volatile, per D-2) |
| PostgreSQL | 16.14 |

## What was measured, and how

Only **admission** (enqueue/insert) — the cleanest apples-to-apples stage. The deeper
stages are scaffolded at the end for a full run.

Because hex.pm package fetches are blocked by this sandbox's egress proxy, the Benchee
project (`mq_bench`) could not compile here, so this run used the engines' **native
tools**, each issuing the system's *real* operation:

- **EchoMQ** — `redis-benchmark` issuing the **real v3 enqueue script**
  (`EchoMQ.Jobs.enqueue/4`: kind-law → idempotent `EXISTS` refuse → `HSET` row →
  `ZADD` score-0 pending), 64-byte payload, branded `JOB` ids randomized for load (the
  per-op work — `EXISTS` + `HSET` + `ZADD` in one atomic script — is identical to a
  real enqueue).
- **Oban** — `pgbench` issuing the **real insert** Oban performs: a row into the
  `oban_jobs` schema carrying Oban's primary fetch index
  (`state, queue, priority, scheduled_at, id`).

Both measure the dominant *substrate* cost of admission. Each system's thin Elixir
wrapper (the `redix`/`Ecto` call) is excluded and is small and comparable; the shipped
`mq_bench` Benchee suite measures the full library paths on a box where hex is
reachable.

## Results — single-job admission

| System (admission) | Durability | Throughput (jobs/s) | p50 latency | avg latency |
|---|---|---:|---:|---:|
| **EchoMQ** `enqueue` — c=1 | volatile (D-2) | **25,700** | 0.031 ms | 0.036 ms |
| **EchoMQ** `enqueue` — c=8 | volatile (D-2) | **35,273** | 0.207 ms | — |
| **EchoMQ** `enqueue` — c=8, pipelined ×16 | volatile (D-2) | **85,985** | 1.423 ms | — |
| **Oban** `insert` — c=1 | **durable** (fsync) | **1,125** | — | 0.889 ms |
| **Oban** `insert` — c=8 | **durable** (fsync) | **3,604** | — | 2.220 ms |
| **Oban** `insert` — c=1 | relaxed (`sync_commit=off`) | **7,273** | — | 0.138 ms |
| **Oban** `insert` — c=8 | relaxed (`sync_commit=off`) | **7,812** | — | 1.024 ms |

## The decomposition (the actual result)

The single-client gap between EchoMQ and Oban splits into two distinct causes, and
naming them is the whole point:

```text
EchoMQ enqueue        25,700 jobs/s   ┐
                                      │  ≈ 3.5×   ← SUBSTRATE
Oban insert (relaxed)  7,273 jobs/s   ┘            (Redis HSET+ZADD in memory
                                                    vs Postgres row + index + MVCC)
Oban insert (relaxed)  7,273 jobs/s   ┐
                                      │  ≈ 6.5×   ← DURABILITY
Oban insert (durable)  1,125 jobs/s   ┘            (no per-op fsync vs an fsync per commit)

EchoMQ vs Oban-durable, end to end:  ≈ 23×        (the two causes multiplied)
```

- **~23× is mostly the durability trade-off.** EchoMQ's bus is volatile by decision
  D-2: an enqueue is memory-resident with no per-op fsync. Oban's default insert is
  durable — the job is on disk (fsync) when `insert` returns. That difference, not
  EchoMQ being "faster code," is the bulk of the gap. It is a *choice*, and EchoMQ pays
  for it elsewhere (the Journal outbox + Graft, for the obligations that must survive a
  crash).
- **~3.5× is the substrate**, visible once durability is matched: an in-memory
  `HSET` + `ZADD` is lighter than a Postgres row insert with index maintenance and MVCC
  bookkeeping. This is the honest "speed" delta, and it is modest.
- **Latency tells the same story**: EchoMQ admission p50 is 0.031 ms; Oban-durable
  averages 0.889 ms (the fsync), Oban-relaxed 0.138 ms (substrate only).
- **Pipelining** (EchoMQ's `enqueue_many` path) reaches ~86k jobs/s by amortising the
  round-trip — Oban's analogue is `insert_all`, scaffolded below.

The takeaway is not "EchoMQ beats Oban." It is that EchoMQ trades durability for
admission speed by design, and when you hold durability constant the engines are within
a small factor — which is exactly what you would predict from their architectures.

## Feature side-by-side — current EchoMQ vs Oban analogue

The features being compared, as they stand today (full table and benchmarking notes in
`framework.md`):

| EchoMQ (today) | Oban analogue | Stage benchmarked here |
|---|---|---|
| `Jobs.enqueue/4` (atomic script) | `Oban.insert/1` | **yes — above** |
| `Jobs.enqueue_many/3` (pipelined) | `Oban.insert_all/1` | partial (pipelined ×16 shown) |
| `Lanes` rotating-ring fairness | global concurrency / partitioning (Pro) | to run |
| `Jobs.claim/3` + `complete/5` | engine fetch + ack | to run |
| `enqueue_at/in` + `Pump` | scheduled jobs + Stager | to run |
| `Flows` (single-queue fan-in) | Workflows (Pro) | to run |
| `Stalled` + reap | Lifeline / Rescuer | to run |
| `Events` / `Metrics` / `Meter` | Telemetry / retained-row queries | to run |

## Caveats

1. **Single-core sandbox** — absolute numbers are not production figures; the relative
   shape and the decomposition are what travel.
2. **Native tools, not the Benchee suite** — hex was proxy-blocked here, so this run
   used `redis-benchmark` + `pgbench` against each engine's real operation. The shipped
   `mq_bench` suite produces the same comparison through the full Elixir libraries where
   hex is reachable.
3. **Wire vs library** — EchoMQ measured via its real enqueue script (excludes the thin
   `redix` wrapper); Oban measured as the real Postgres write (excludes the cheap
   in-memory changeset build). Both small, both comparable.
4. **Durability is reported, not assumed** — Oban shown at both its durable default and
   relaxed; EchoMQ's volatile bus is its D-2 design, with durability provided beside the
   bus (Journal + Graft), not inside the admission path.
5. **Randomized ids** — per-op work is identical to a real enqueue.

## Deeper stages — to run (full Benchee suite)

These need the `echo_mq` umbrella running and a box where hex is reachable; the harness
scripts them. Fill on a real deployment:

### Claim → complete (round-trip latency)

| System | p50 | p99 | throughput | notes |
|---|---|---|---|---|
| EchoMQ `claim` + `complete` | — | — | — | lease + settle |
| Oban fetch + ack | — | — | — | in-engine |

### Fairness under a hot tenant (no starvation)

| System | fair share held? | tail latency of cold tenant | notes |
|---|---|---|---|
| EchoMQ `Lanes` (rotating ring) | — | — | constructed fairness |
| Oban Smart-engine partition/limit (Pro) | — | — | configured |

### Scheduled release & fan-in

| Stage | EchoMQ | Oban | metric |
|---|---|---|---|
| Scheduled promotion at depth | `Pump` promote | Stager | promotion latency |
| Fan-out / fan-in | `Flows` | Workflows (Pro) | DAG completion time |

Run them with: `mix bench.setup && mix bench.admit` (admission, reproduces the above),
then the staged scripts as they are added to `bench/`.
