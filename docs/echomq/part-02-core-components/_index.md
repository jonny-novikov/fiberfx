# Part III. Core Components

> Jobs, queues, and workers are the fundamental building blocks of every EchoMQ application. This part covers the job data model, lifecycle state machine, configuration options, queue management, and worker processing patterns — all shown in Elixir, Go, and Node.js.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [12](ch12-jobs-overview.md) | Jobs Overview | Job structure, fields, and the Redis hash representation |
| [13](ch13-job-lifecycle.md) | Job Lifecycle | State transitions: waiting, active, completed, failed, delayed |
| [14](ch14-job-options.md) | Job Options | Priority, delay, retries, backoff, removeOn, and deduplication |
| [15](ch15-queues.md) | Queues | Queue creation, pause/resume, drain, and bulk operations |
| [16](ch16-workers.md) | Workers | Worker configuration, processor functions, and concurrency |
| [17](ch17-worker-patterns.md) | Worker Patterns | Named processors, sandboxing, graceful shutdown, and scaling |

## Prerequisites

- Part 1 completed (working queue and worker setup)
- Understanding of JSON serialization and Redis hashes

## What You'll Learn

- How jobs are stored in Redis and what each compressed field name means
- The complete job state machine and what triggers each transition
- How to configure retry strategies, priority levels, and cleanup policies
