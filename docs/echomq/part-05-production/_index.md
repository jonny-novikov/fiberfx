# Part VI. Production

> Operating EchoMQ in production: metrics collection, distributed tracing, and deployment best practices. This part covers Prometheus integration, OpenTelemetry spans, health checks, and operational runbooks for all three runtimes.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [29](ch29-metrics-prometheus.md) | Metrics & Prometheus | Counter/gauge/histogram metrics, Prometheus export, and Grafana dashboards |
| [30](ch30-telemetry-tracing.md) | Telemetry & Tracing | OpenTelemetry integration, span propagation, and distributed trace correlation |
| [31](ch31-production-guide.md) | Production Guide | Deployment patterns, health checks, graceful shutdown, and operational runbooks |

## Prerequisites

- Parts 1-3 completed (full feature understanding)
- Familiarity with Prometheus, Grafana, or equivalent monitoring stack

## What You'll Learn

- How to instrument EchoMQ workers with Prometheus metrics across all three runtimes
- Distributed tracing patterns that correlate job processing across language boundaries
- Production deployment checklists covering Redis configuration, worker scaling, and failure recovery
