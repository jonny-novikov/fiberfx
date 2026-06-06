# Chapter 00. EchoMQ Overview

## 0.1. What is EchoMQ?

EchoMQ is a **unified protocol for message queuing and background job processing** that spans three language runtimes: **Elixir** (BEAM), **Go**, and **Node.js** (TypeScript). It builds on the proven BullMQ protocol — the most widely-adopted Redis-based job queue system — and extends it with polyglot interoperability, language-native optimizations, and a shared governance model.

The core insight driving EchoMQ is simple: **the BullMQ Lua scripts ARE the protocol**. Any implementation that executes the same Lua scripts against the same Redis data structures is wire-compatible, regardless of the host language. EchoMQ formalizes this insight into a versioned, testable protocol specification with three reference implementations.

## 0.2. The Polyglot Advantage

Most job queue systems are single-language. Sidekiq serves Ruby, Celery serves Python, Oban serves Elixir, and BullMQ serves Node.js. When your system spans multiple runtimes — a common reality in modern architectures — you're forced to pick one queue system and build adapters, or run multiple queue systems with synchronization overhead.

EchoMQ eliminates this problem. A Go microservice can enqueue a job that an Elixir worker processes, with a Node.js dashboard observing progress in real-time. All three share the same Redis, the same data structures, the same atomic Lua scripts, and the same event stream.

```
┌─────────────────────────────────────────────────┐
│              Shared Redis Instance               │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐ │
│  │ Lua      │  │ Redis    │  │ Event         │ │
│  │ Scripts  │  │ Data     │  │ Streams       │ │
│  │ (atomic) │  │ Layer    │  │ (observability│ │
│  └──────────┘  └──────────┘  └───────────────┘ │
└────────┬───────────┬───────────────┬────────────┘
         │           │               │
    ┌────┴────┐ ┌────┴────┐   ┌─────┴─────┐
    │ EchoMQ  │ │ EchoMQ  │   │ EchoMQ    │
    │ Elixir  │ │ Go      │   │ Node.js   │
    │ (OTP)   │ │ (gorout)│   │ (= BullMQ)│
    └─────────┘ └─────────┘   └───────────┘
```

## 0.3. Three Implementations, One Protocol

### EchoMQ Elixir

The Elixir implementation leverages OTP supervision trees, BEAM lightweight processes, and preemptive scheduling. Workers are GenServers, queues are stateless function modules, and fault tolerance is structural — not bolted on. The LockManager optimization (1 timer per worker vs N timers per job) and preemptive scheduling eliminate entire categories of stalled-job bugs that plague single-threaded runtimes.

**Maturity**: Most complete. Full BullMQ feature parity including flows, schedulers, and events.

### EchoMQ Go (echomq-go)

The Go implementation targets high-throughput, low-latency workloads. Goroutine-per-job concurrency, Redis Cluster support with CRC16 hash tag auto-detection, and embedded Lua scripts from BullMQ v5.62.0. The core architecture is sound — the primary remaining work is wiring the embedded Lua scripts into critical-path operations.

**Maturity**: Functional. 7/10 requirements fully implemented, 3 need Lua script integration for atomicity.

### EchoMQ Node.js (= BullMQ)

The reference implementation. Node.js BullMQ v5.x IS the EchoMQ protocol. EchoMQ does not fork or modify BullMQ — it pins to a specific version and extracts the Lua scripts and Redis conventions as the shared protocol definition.

**Maturity**: Production. Widely deployed, battle-tested.

## 0.4. Protocol Version Strategy

EchoMQ pins to a specific BullMQ commit SHA. All implementations embed Lua scripts extracted verbatim from that commit. CI validates script checksums against upstream.

| Component | Current Version | BullMQ Pin |
|-----------|----------------|------------|
| EchoMQ Protocol | 5.62.0 | `6a31e0aeab1311d7d089811ede7e11a98b6dd408` |
| EchoMQ Elixir | 0.8.x | v5.62.0 |
| EchoMQ Go | 0.1.1 | v5.62.0 |
| EchoMQ Node.js | (= BullMQ 5.62.0) | — |

## 0.5. Architecture Layers

The EchoMQ architecture follows a 4-layer model where the bottom two layers are immutable (shared across all implementations) and the top two layers are language-specific:

| Layer | Name | Scope | Mutability |
|-------|------|-------|------------|
| **L0** | Redis Engine | Redis 6.0+ / Redis Cluster | External |
| **L1** | Redis Data Layer | Key naming, data structures, field names | **IMMUTABLE** |
| **L2** | Lua Script Layer | 53 main scripts + 60 includes | **IMMUTABLE** |
| **L3** | Script Executor | EVALSHA dispatch, msgpack encoding, SHA caching | Language-specific |
| **L4** | Language API | Queue.add(), Worker.process(), Job.getState() | Language-specific |

> **The Golden Rule**: If two implementations execute the same Lua scripts against the same Redis data structures with the same field names, they are protocol-compatible. Everything above L2 can vary freely.

## 0.6. Document Structure

This architecture section covers:

1. **[Unified Protocol Specification](ch01-unified-protocol.md)** — The immutable protocol layers (L1 + L2)
2. **[Redis Data Layer](ch02-redis-data-layer.md)** — Complete key taxonomy, data structures, and field schemas
3. **[Job Lifecycle & State Machine](ch03-job-lifecycle.md)** — State transitions, event system, error codes
4. **[Elixir OTP Architecture](ch04-elixir-architecture.md)** — BEAM advantages, OTP patterns, supervision trees
5. **[Go Implementation](ch05-go-architecture.md)** — Current status, gap analysis, v1.0 roadmap
6. **[Cross-Language Interoperability](ch06-cross-language-interop.md)** — Feature matrix, divergences, testing strategy
7. **[Vision & Roadmap](ch07-vision-and-roadmap.md)** — Next-generation features, positioning, evolution path

## 0.7. Epic & Task Reference

| Entity | ID | Description |
|--------|-----|------------|
| Epic | `EPC0KZptaxp2H2` | EchoMQ Unified Polyglot Message Queue Protocol |
| Research Task | `TSK0KZptlgbau8` | Architecture research (CCLIN Rose Tree, 4-agent) |

### Research Agents

| Agent | ID | Domain | Grade |
|-------|-----|--------|-------|
| Venus-Protocol-Architect | MCA0KZq3JFDrcG | Cross-language protocol | A- (26/30) |
| Mars-Elixir-Analyst | MCA0KZqi9zPvDE | EchoMQ / BEAM | A- (25/30) |
| Saturn-Go-Analyst | MCA0KZq6PqLDWK | echomq-go implementation | A (27/30) |
| Apollo-Architecture-Evaluator | MCA0KZrOJX2sKm | Independent review | Combined: A- (78/90) |

---

*Next: [Unified Protocol](ch01-unified-protocol.md)*
