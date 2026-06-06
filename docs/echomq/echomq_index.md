---
title: EchoMQ Documentation
description: Polyglot job queue documentation covering Elixir, Go, and Node.js implementations of the BullMQ protocol
tags: [echomq, bullmq, job-queue, elixir, go, nodejs, redis]
---

# EchoMQ Documentation

EchoMQ is a polyglot job queue system implementing the BullMQ wire protocol across three runtimes: **Elixir** (OTP/BEAM), **Go** (goroutines), and **Node.js** (BullMQ reference). All implementations share the same Lua scripts, Redis data structures, and wire format — jobs created by one language are fully processable by another.

## Table of Contents

### [Part I: Protocol & Architecture](part-00-protocol/_index.md)

The immutable foundation: wire protocol, Redis data layer, and language-specific architectures.

| # | Chapter | Description |
|---|---------|-------------|
| 00 | [EchoMQ Overview](part-00-protocol/ch00-echomq-overview.md) | 4-layer architecture model and design philosophy |
| 01 | [Unified Protocol](part-00-protocol/ch01-unified-protocol.md) | Immutable protocol contract shared by all implementations |
| 02 | [Redis Data Layer](part-00-protocol/ch02-redis-data-layer.md) | Key taxonomy, hash schemas, compressed field names |
| 03 | [Job Lifecycle](part-00-protocol/ch03-job-lifecycle.md) | State machine: wait, active, completed, failed, delayed |
| 04 | [Elixir Architecture](part-00-protocol/ch04-elixir-architecture.md) | OTP supervision, BEAM processes, stateless queues |
| 05 | [Go Architecture](part-00-protocol/ch05-go-architecture.md) | Goroutine concurrency, ScriptLoader, Redis Cluster |
| 06 | [Cross-Language Interop](part-00-protocol/ch06-cross-language-interop.md) | Feature parity matrix and divergence analysis |
| 07 | [Vision & Roadmap](part-00-protocol/ch07-vision-and-roadmap.md) | Future direction and polyglot evolution |

### [Part II: Foundations](part-01-foundations/_index.md)

Getting started with EchoMQ across all three runtimes.

| # | Chapter | Description |
|---|---------|-------------|
| 08 | [Why EchoMQ](part-01-foundations/ch08-why-echomq.md) | The problem EchoMQ solves and when to use it |
| 09 | [Getting Started](part-01-foundations/ch09-getting-started.md) | First queue, first worker, first job |
| 10 | [Architecture Overview](part-01-foundations/ch10-architecture-overview.md) | L3-L4 layer comparison across runtimes |
| 11 | [Connections](part-01-foundations/ch11-connections.md) | Redis connection setup, pooling, reconnection |

### [Part III: Core Components](part-02-core-components/_index.md)

Jobs, queues, and workers — the fundamental building blocks.

| # | Chapter | Description |
|---|---------|-------------|
| 12 | [Jobs Overview](part-02-core-components/ch12-jobs-overview.md) | Job structure, fields, Redis hash representation |
| 13 | [Job Lifecycle](part-02-core-components/ch13-job-lifecycle.md) | State transitions and lifecycle events |
| 14 | [Job Options](part-02-core-components/ch14-job-options.md) | Priority, delay, retries, backoff, deduplication |
| 15 | [Queues](part-02-core-components/ch15-queues.md) | Queue creation, pause/resume, drain, bulk ops |
| 16 | [Workers](part-02-core-components/ch16-workers.md) | Worker configuration, processors, concurrency |
| 17 | [Worker Patterns](part-02-core-components/ch17-worker-patterns.md) | Named processors, graceful shutdown, scaling |

### [Part IV: Advanced Features](part-03-advanced-features/_index.md)

Flows, schedulers, and events for complex job orchestration.

| # | Chapter | Description |
|---|---------|-------------|
| 18 | [Flows](part-03-advanced-features/ch18-flows-overview.md) | Job flow trees with parent-child dependencies |
| 19 | [Parent-Child Jobs](part-03-advanced-features/ch19-parent-child-jobs.md) | Dependency resolution and result aggregation |
| 20 | [Job Schedulers](part-03-advanced-features/ch20-job-schedulers.md) | Cron expressions and interval-based triggers |
| 21 | [Repeatable Jobs](part-03-advanced-features/ch21-repeatable-jobs.md) | Recurring patterns, deduplication, timezones |
| 22 | [Queue Events](part-03-advanced-features/ch22-queue-events.md) | Redis Streams subscription and reactive patterns |
| 23 | [Custom Events](part-03-advanced-features/ch23-custom-events.md) | Application-defined events and cross-worker comms |

### [Part V: Performance & Scaling](part-04-performance-scaling/_index.md)

Concurrency, rate limiting, priorities, batches, and groups.

| # | Chapter | Description |
|---|---------|-------------|
| 24 | [Worker Concurrency](part-04-performance-scaling/ch24-worker-concurrency.md) | Concurrency limits and per-runtime tuning |
| 25 | [Rate Limiting](part-04-performance-scaling/ch25-rate-limiting.md) | Token bucket limiting and group throttling |
| 26 | [Priorities](part-04-performance-scaling/ch26-priorities.md) | Priority encoding and composite scoring |
| 27 | [Batches](part-04-performance-scaling/ch27-batches.md) | Batch submission and pipeline optimization |
| 28 | [Groups](part-04-performance-scaling/ch28-groups.md) | Job groups and group-level concurrency |

### [Part VI: Production](part-05-production/_index.md)

Metrics, telemetry, tracing, and deployment patterns.

| # | Chapter | Description |
|---|---------|-------------|
| 29 | [Metrics & Prometheus](part-05-production/ch29-metrics-prometheus.md) | Prometheus metrics export and Grafana dashboards |
| 30 | [Telemetry & Tracing](part-05-production/ch30-telemetry-tracing.md) | OpenTelemetry spans and distributed trace correlation |
| 31 | [Production Guide](part-05-production/ch31-production-guide.md) | Deployment, health checks, and operational runbooks |

### [Part VII: Language Patterns](part-06-language-patterns/_index.md)

Deep dives into language-specific patterns across all three runtimes.

| # | Chapter | Description |
|---|---------|-------------|
| 32 | [Supervision Patterns](part-06-language-patterns/ch32-otp-supervision.md) | OTP trees, goroutine lifecycle, PM2/cluster |
| 33 | [Telemetry Integration](part-06-language-patterns/ch33-telemetry-integration.md) | `:telemetry`, Go middleware, EventEmitter |
| 34 | [Framework Integration](part-06-language-patterns/ch34-framework-integration.md) | Phoenix, Go HTTP, Express/Fastify |
| 35 | [Concurrent Data Structures](part-06-language-patterns/ch35-concurrent-data-structures.md) | ETS, sync.Map, SharedArrayBuffer |
| 36 | [Error Handling](part-06-language-patterns/ch36-error-handling.md) | Idiomatic error patterns across runtimes |
| 37 | [Testing & Mocking](part-06-language-patterns/ch37-testing-mocking.md) | Unit tests, Redis mocking, integration testing, CI/CD strategies |
| 38 | [Migration Guide](part-06-language-patterns/ch38-migration-guide.md) | Zero-downtime migration from Node.js BullMQ to polyglot EchoMQ |

## Quick Navigation

| Part | Focus | Start Here |
|------|-------|------------|
| [Part I](part-00-protocol/_index.md) | Protocol & Architecture | Understanding the shared foundation |
| [Part II](part-01-foundations/_index.md) | Foundations | First-time setup and getting started |
| [Part III](part-02-core-components/_index.md) | Core Components | Jobs, queues, and workers in depth |
| [Part IV](part-03-advanced-features/_index.md) | Advanced Features | Flows, schedulers, and events |
| [Part V](part-04-performance-scaling/_index.md) | Performance & Scaling | Production tuning and optimization |
| [Part VI](part-05-production/_index.md) | Production | Metrics, tracing, and deployment |
| [Part VII](part-06-language-patterns/_index.md) | Language Patterns | Runtime-specific deep dives |
