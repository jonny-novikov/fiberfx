# Chapter 07. Vision & Roadmap

## 7.1. Strategic Positioning

EchoMQ is not competing with single-language job queues. It fills a unique niche: **high-throughput, cross-runtime job processing** for systems that use Redis and need interoperability between Node.js, Go, and Elixir services.

### EchoMQ vs Alternatives

| Aspect | Oban (Elixir) | Sidekiq (Ruby) | Celery (Python) | BullMQ (Node) | **EchoMQ** |
|--------|:---:|:---:|:---:|:---:|:---:|
| Backend | PostgreSQL | Redis | Redis/RabbitMQ | Redis | Redis |
| Cross-runtime | No | No | No | No | **Yes** |
| Throughput | ~1K j/s | ~10K j/s | ~5K j/s | ~10K j/s | **~16K j/s** (Elixir) |
| Flows (DAG) | Pro (paid) | No | Yes (chains) | Built-in | Built-in |
| Rate limiting | Pro (paid) | Enterprise | Built-in | Built-in | Built-in |
| Real-time events | PG NOTIFY | Redis | Redis | Redis Streams | Redis Streams |
| Wire compatibility | None | None | None | Self | **BullMQ ecosystem** |

### The Polyglot Value Proposition

1. **Incremental adoption**: Run Elixir workers alongside existing Node.js workers on the same queue
2. **Language-specialized workers**: Route CPU-heavy jobs to Go, fan-out to Elixir, I/O to Node.js
3. **Zero-downtime language migration**: Switch from Node.js to Go one worker at a time
4. **Unified observability**: One event stream, one metrics pipeline, one dashboard for all languages

## 7.2. Critical Path

Based on the cross-validated research from Venus, Mars, Saturn, and Apollo, the critical path for EchoMQ is:

### Phase 1: Go Atomicity (Weeks 1-3)

Wire existing Lua scripts into echomq-go critical-path operations. This is the highest-impact work — it eliminates job loss on crash, fixes cross-language race conditions, and reduces network overhead by 7-10 RTTs per job.

**Deliverables**:
- `pickupJob()` → MoveToActive Lua script
- `Complete()`/`Fail()` → MoveToFinished Lua script
- `checkAndRecover()` → MoveStalledJobsToWait Lua script
- Compressed field names (`atm`, `ats`, `stc`, `pb`)
- msgpack ARGV encoding for Lua script arguments

### Phase 2: Go Field Name Fix (Week 4)

Fix compressed field name mismatch. Change Go struct JSON tags from full names to compressed v5.x names.

### Phase 3: Cross-Language Validation (Weeks 5-6)

Build and run cross-language integration tests:
- Node.js produces → Go consumes
- Go produces → Elixir consumes
- Elixir produces → Node.js consumes
- Concurrent mixed workers on same queue

### Phase 4: EchoMQ Rename (COMPLETED)

~~Create the EchoMQ alias layer over BullMQ modules. Reserve `echomq` on hex.pm. Begin gradual migration.~~

**Completed**: Full rename from BullMQex to EchoMQ across 53 Elixir files + 51 Go files + 3 directory renames. Package directory moved to `phoenix/apps/echomq/`, Go package to `pkg/echomq/`. Redis key prefix `"bull"` preserved for wire compatibility.

### Phase 5: Shared Test Suite (Weeks 8-9)

Language-agnostic protocol compliance tests. Verify Redis state after each operation against the protocol specification.

## 7.3. Elixir-Native Vision

Beyond BullMQ protocol compatibility, EchoMQ Elixir will offer BEAM-native features unavailable in other runtimes.

### Broadway Integration (High Priority)

A Broadway producer that enables batch processing, back-pressure, and partitioning:

```elixir
defmodule MyApp.Pipeline do
  use Broadway

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {EchoMQ.Broadway.Producer, [
          queue: "data-pipeline",
          connection: :my_redis,
          prefetch_count: 100
        ]}
      ],
      processors: [default: [concurrency: 50]],
      batchers: [default: [batch_size: 100, batch_timeout: 1000]]
    )
  end
end
```

### Phoenix LiveDashboard (High Priority)

Real-time queue monitoring integrated into Phoenix LiveDashboard:

```elixir
live_dashboard "/dashboard",
  additional_pages: [echomq: EchoMQ.Phoenix.LiveDashboard]
```

Showing:
- Real-time queue depths via QueueEvents → PubSub → LiveView
- Worker health (concurrency utilization, stall rate, error rate)
- Job flow DAG visualization
- Rate limit status
- Historical throughput graphs via Telemetry.Metrics

### BrandedChamp Job Registry (Medium Priority)

Using the CHAMP trie data structure for O(1) namespace-partitioned job tracking:

```elixir
active_jobs = BrandedChamp.namespace_size(state, "JOB")
active_flows = BrandedChamp.namespace_size(state, "FLW")
```

### Native Distributed Queues (Long-Term)

BEAM-native queues for Elixir-only workloads without Redis:

```elixir
{:ok, queue} = EchoMQ.Distributed.Queue.start_link(
  name: :local_tasks,
  nodes: [:"app@node1", :"app@node2"],
  replication: :quorum
)
```

Implementation: `:pg` for worker discovery, Horde for coordination, CRDTs for consistency.

Hybrid architecture: Redis-backed for cross-runtime, BEAM-native for Elixir-only.

## 7.4. Go Evolution Path

### v0.2.0: Atomic Operations

Lua script integration for all state transitions. This is the "rewire, not rewrite" milestone — the architecture, types, and control flow exist. The remaining work is connecting existing pieces.

### v0.3.0: Validation & Benchmarks

Cross-language compatibility tests under concurrent load. Benchmark suite measuring throughput, latency, memory, and goroutine count. Connection pool configuration exposure.

### v1.0.0: Production Hardening

Chaos testing, OpenTelemetry integration, documentation, CI/CD with cross-language matrix.

### Beyond v1.0: Feature Expansion

| Feature | Priority | Effort |
|---------|----------|--------|
| FlowProducer | High | 2-3 weeks |
| QueueEvents (XREAD) | High | 1 week |
| Job Schedulers | Medium | 2 weeks |
| Pause/Resume | Medium | 1 week |
| Rate Limiting | Medium | 1 week (Lua already supports) |
| Deduplication | Low | 1 week |
| OpenTelemetry | Low | 2 weeks |

## 7.5. Next-Generation Protocol Features

### Flow Enhancements

Current BullMQ flows are tree-structured (strict parent-child). Future enhancements:

| Enhancement | Description |
|-------------|-------------|
| **DAG support** | Diamond dependencies (A→B, A→C, B→D, C→D) |
| **Conditional flows** | Child completion triggers different parent paths |
| **Dynamic children** | Add children while parent in waiting-children |
| **Cross-queue visibility** | Unified flow view across multiple queues |
| **Flow-level rate limiting** | Rate limit at flow level, not just queue |

### Application-Layer Extensions

These are NOT protocol changes but application patterns:

| Extension | Description | Owner |
|-----------|-------------|-------|
| Results Queue | Automatic result forwarding | echomq-go (exists) |
| Dead Letter Queue | Configurable DLQ routing with metadata | All |
| Job Chaining | Sequential execution without flow overhead | All |
| Batch Processing | Group jobs, process as batch, single result | All |
| Circuit Breaker | Worker-level breaker for downstream protection | All |

## 7.6. Protocol Governance Model

### Version Bump Process

1. BullMQ releases new version with Lua script changes
2. EchoMQ extracts scripts verbatim from new commit SHA
3. All three implementations update embedded scripts simultaneously
4. CI validates script checksums across all implementations
5. Cross-language integration tests run against new scripts
6. Coordinated release of all three implementations

### Protocol Compliance Certification

A shared test suite that any implementation can run to verify protocol compliance:

```
echomq/
  protocol/
    lua/                  # Verbatim Lua scripts (pinned version)
    schemas/              # JSON schemas for job, event, options
    tests/                # Language-agnostic compliance tests
      test_add_job.json   # Expected Redis state after add
      test_pickup.json    # Expected state after moveToActive
      test_complete.json  # Expected state after moveToFinished
```

### Repository Structure (Proposed)

```
echomq/
  protocol/               # Shared protocol definition (L1 + L2)
  echomq-node/             # Node.js (= BullMQ, pinned version)
  echomq-go/               # Go implementation
  echomq-ex/               # Elixir implementation
  echomq-dashboard/        # Universal dashboard (reads events stream)
  echomq-cli/              # CLI for queue management
```

## 7.7. Research Gaps to Address

The CCLIN research identified gaps that none of the three analyst agents covered:

| Gap | Priority | Next Step |
|-----|----------|-----------|
| No EchoMQ source-level audit | HIGH | Read actual `.ex` files, confirm feature status |
| No msgpack round-trip validation | CRITICAL | Go encode → Redis cmsgpack decode test suite |
| No Go benchmark data | MEDIUM | Create `*_bench_test.go` files |
| No Redis version requirements analysis | LOW | Document minimum Redis version |
| No security analysis (auth, TLS, ACL) | MEDIUM | Production readiness checklist |
| No analysis of existing compatibility harness | LOW | Audit `tests/compatibility/nodejs/` |

## 7.8. Architecture Coherence Assessment

From Apollo's independent evaluation:

| Dimension | Score | Notes |
|-----------|-------|-------|
| Protocol definition clarity | 9/10 | Venus's spec is near-complete |
| Cross-language interop vision | 8/10 | Clear: shared Lua scripts, shared Redis |
| Go implementation path | 9/10 | "Rewire, don't rewrite" — excellent |
| Elixir implementation depth | 7/10 | Documentation-based; needs source verification |
| Unified governance model | 7/10 | Version pinning + CI proposed; needs operational detail |
| **Overall** | **8/10** | **Strong foundation, actionable for implementation** |

Combined Research Grade: **A- (78/90, 86.7%)**

---

*Architecture documents synthesized from CCLIN Rose Tree research.*
*Epic: EPC0KZptaxp2H2 | Task: TSK0KZptlgbau8*
*Agents: Venus (A-), Mars (A-), Saturn (A), Apollo (A- combined)*
*Date: 2026-02-07*

---

*Previous: [Cross-Language Interop](ch06-cross-language-interop.md) | Next: [Why EchoMQ?](ch08-why-echomq.md)*
