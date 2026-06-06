# Part I. Protocol & Architecture

> EchoMQ is built on a shared protocol layer: the same Lua scripts, the same Redis data structures, the same wire format — across Elixir, Go, and Node.js. This part covers the immutable foundation (L0-L2) and the language-specific architectures (L3-L4) that every EchoMQ developer should understand before writing their first job.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [00](ch00-echomq-overview.md) | EchoMQ Overview | The 4-layer architecture model and design philosophy |
| [01](ch01-unified-protocol.md) | Unified Protocol | The immutable protocol contract shared by all implementations |
| [02](ch02-redis-data-layer.md) | Redis Data Layer | Key taxonomy, hash schemas, and compressed field names |
| [03](ch03-job-lifecycle.md) | Job Lifecycle | State machine: wait, active, completed, failed, delayed, stalled |
| [04](ch04-elixir-architecture.md) | Elixir Architecture | OTP supervision trees, BEAM processes, and stateless queues |
| [05](ch05-go-architecture.md) | Go Architecture | Goroutine-per-job concurrency, ScriptLoader, and Redis Cluster |
| [06](ch06-cross-language-interop.md) | Cross-Language Interop | Feature parity matrix, divergence analysis, and interop patterns |
| [07](ch07-vision-and-roadmap.md) | Vision & Roadmap | Future direction, milestones, and polyglot evolution |

## Prerequisites

- Basic understanding of Redis (keys, hashes, sorted sets, streams)
- Familiarity with job queue concepts (producers, consumers, retries)
- At least one of: Elixir/OTP, Go, or Node.js/TypeScript

## What You'll Learn

- How EchoMQ achieves cross-language compatibility through a shared Lua script layer
- The Redis data structures and key naming conventions that form the wire protocol
- How each runtime (BEAM, goroutines, event loop) adapts the shared protocol to its concurrency model
