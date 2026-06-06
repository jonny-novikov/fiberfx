# Part V. Performance & Scaling

> Tuning EchoMQ for production workloads: concurrency control, rate limiting, priority queues, batch processing, and job groups. These patterns help you manage throughput, protect downstream services, and organize work at scale.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [24](ch24-worker-concurrency.md) | Worker Concurrency | Concurrency limits, semaphores, and per-runtime tuning |
| [25](ch25-rate-limiting.md) | Rate Limiting | Token bucket limiting via Lua scripts and group-based throttling |
| [26](ch26-priorities.md) | Priorities | Priority encoding, composite scoring, and priority starvation prevention |
| [27](ch27-batches.md) | Batches | Batch job submission, bulk operations, and pipeline optimization |
| [28](ch28-groups.md) | Groups | Job groups for parallel queue partitioning and group-level concurrency |

## Prerequisites

- Parts 1-2 completed (working queue/worker setup)
- Production workload experience or benchmarking goals

## What You'll Learn

- How to tune concurrency per runtime (BEAM processes, goroutines, async functions)
- Rate limiting strategies that protect external APIs without losing jobs
- Priority and batch patterns for high-throughput game queue scenarios
