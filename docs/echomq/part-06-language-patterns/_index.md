# Part VII. Language Patterns

> Deep dives into language-specific patterns for supervision, telemetry, framework integration, concurrent data structures, and error handling — shown across all three EchoMQ runtimes. Each chapter takes a concept rooted in one language's strengths and shows how it translates (or doesn't) to the other two.

## Chapters

| Chapter | Title | Description |
|---------|-------|-------------|
| [32](ch32-otp-supervision.md) | Supervision Patterns | OTP supervision trees, goroutine lifecycle, and PM2/cluster patterns |
| [33](ch33-telemetry-integration.md) | Telemetry Integration | Elixir `:telemetry`, Go middleware, and Node.js EventEmitter instrumentation |
| [34](ch34-framework-integration.md) | Framework Integration | Phoenix LiveView, Go HTTP handlers, and Express/Fastify middleware |
| [35](ch35-concurrent-data-structures.md) | Concurrent Data Structures | ETS tables, sync.Map, and SharedArrayBuffer for worker-visible state |
| [36](ch36-error-handling.md) | Error Handling | `{:ok, _}/{:error, _}`, `(result, error)`, and try/catch across runtimes |
| [37](ch37-testing-mocking.md) | Testing & Mocking | Unit tests, Redis mocking, integration testing, CI/CD strategies |
| [38](ch38-migration-guide.md) | Migration from BullMQ | Zero-downtime migration from Node.js BullMQ to polyglot EchoMQ |

## Prerequisites

- Familiarity with at least one EchoMQ runtime (Elixir, Go, or Node.js)
- Parts 1-2 completed for foundational context

## What You'll Learn

- How OTP supervision translates to goroutine lifecycle management and process managers
- Telemetry and instrumentation patterns native to each runtime
- Framework integration recipes for the most popular web frameworks in each ecosystem
