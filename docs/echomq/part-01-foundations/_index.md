# Part II. Foundations

> Getting started with EchoMQ across all three runtimes. This part covers why EchoMQ exists, how to set up your first queue and worker, the architecture that ties everything together, and production-ready connection management.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [08](ch08-why-echomq.md) | Why EchoMQ | The problem EchoMQ solves and when to use it |
| [09](ch09-getting-started.md) | Getting Started | First queue, first worker, first job — in all three languages |
| [10](ch10-architecture-overview.md) | Architecture Overview | L3-L4 layer comparison: Elixir, Go, and Node.js side by side |
| [11](ch11-connections.md) | Connections | Redis connection setup, pooling, and reconnection strategies |

## Prerequisites

- Redis 6.0+ installed and running
- One of: Elixir 1.14+ / Go 1.21+ / Node.js 18+
- Basic familiarity with the chosen runtime's package manager

## What You'll Learn

- How to add jobs to a queue and process them with a worker
- The concurrency model differences between BEAM processes, goroutines, and the event loop
- Production-ready Redis connection configuration for standalone and cluster deployments
