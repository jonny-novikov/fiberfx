# Part IV. Advanced Features

> Complex job orchestration patterns: parent-child flows, scheduled and repeatable jobs, and real-time event systems. These features let you build multi-step pipelines, cron-like schedules, and reactive monitoring — all backed by the same atomic Lua scripts.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [18](ch18-flows.md) | Flows | Job flow trees with parent-child dependencies |
| [19](ch19-parent-child-jobs.md) | Parent-Child Jobs | Dependency resolution, waiting-children state, and result aggregation |
| [20](ch20-job-schedulers.md) | Job Schedulers | Cron expressions, every-based intervals, and scheduler management |
| [21](ch21-repeatable-jobs.md) | Repeatable Jobs | Recurring job patterns, deduplication, and timezone handling |
| [22](ch22-queue-events.md) | Queue Events | Redis Streams subscription, event types, and reactive patterns |
| [23](ch23-custom-events.md) | Custom Events | Application-defined events and cross-worker communication |

## Prerequisites

- Parts 1-2 completed (jobs, queues, and workers)
- Understanding of tree data structures (for flows)

## What You'll Learn

- How to build multi-step job pipelines where parents wait for all children
- Scheduling patterns for recurring work with cron and interval-based triggers
- Real-time event monitoring using Redis Streams across all three runtimes
