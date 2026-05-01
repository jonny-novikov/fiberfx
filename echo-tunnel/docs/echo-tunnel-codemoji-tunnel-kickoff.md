# Echo Tunnel & Codemoji Tunnel

### Two Go Projects. One Tunneling Platform. Self-Hosted, Pragmatic, Fly-Native.

---

## Prelude

### The Setup

Codemoji is a Telegram Mini App. Its development loop depends on Telegram's Bot API delivering webhooks to your laptop, AppFather forwarding partner payment events with HMAC signatures intact, and a real-time WebSocket connection between the Mini App and the local Fastify server — all within a 10-second pre-checkout deadline that does not negotiate. None of these requirements are optional, and none of them are met by `localhost:3000`.

You need a tunnel.

The kick-off research surveyed the market: ngrok, Cloudflare Tunnel, Pinggy, LocalXpose, Hookdeck, Localtunnel, frp. Each tool met some of the seven requirements (HTTPS, stable URLs, WebSocket passthrough, request inspection with replay, raw body preservation, sub-10-second round-trip, multi-developer coexistence). None met all seven. The honest summary: the closest match was the wrong fit for at least one critical capability, and the hybrid solution (Cloudflare for the frontend, ngrok for backend webhooks, frp for WebSocket passthrough) split operational concerns across three vendors with three billing models, three configuration formats, and three failure modes.

Tunneling is not a peripheral concern for Codemoji. It carries every webhook that drives the payment system, every gameplay WebSocket that drives the multiplayer experience, and every development cycle that drives feature delivery. A tunnel is infrastructure. The decision to build one — bounded in scope, owned in code, deployed on infrastructure we already operate — is the foundation of this project.

### Why Two Projects

A tunnel for Codemoji has two layers of concern.

**The tunneling concern is generic.** Routing HTTP between a public edge and a private origin, terminating TLS, multiplexing concurrent requests over a single WebSocket transport, authenticating clients, observing traffic, draining gracefully on shutdown — these are tunnel problems, not Codemoji problems. They appear identically in every project that needs a self-hosted tunnel. They have nothing to do with Telegram Mini Apps, BEAM virtual machines, or emoji-guessing games.

**The application concern is specific.** Routing `*.codemoji.games` to the three sera-merge services over Fly's 6PN private network, validating Telegram Bot API webhook signatures, preserving AppFather HMAC-SHA256 signatures across the tunnel-to-Fastify chain, replicating production Redis events to local Redis for development, evaluating Elixir code on a remote BEAM node — these are Codemoji problems built on top of tunneling primitives.

Mixing the two in a single repository creates two pathologies. The generic tunneling code accumulates Codemoji-specific assumptions (the namespace prefix `dev-`, the trust boundary tuned for Fly.io, the metric labels assuming the sera-merge service mesh). The application code accumulates implementation details about the tunnel internals that should be private. Neither layer can be reasoned about in isolation. Reusing the tunnel for a non-Codemoji project becomes impossible.

The pragmatic answer: two projects.

**`echo-tunnel/`** is the generic Go-based tunneling platform. Domain-agnostic. Reusable. Tested as a library. Deployed as a binary. It exposes well-defined extension points for application code without making any assumptions about what that application looks like. It can be used standalone for any project that needs the tunnel concern solved. It is built first because everything else depends on it.

**`codemoji-tunnel/`** is the Codemoji-specific application that consumes `echo-tunnel` as a Go module dependency. It configures the tunnel for the `*.codemoji.games` deployment, adds the Telegram and AppFather webhook flows, implements the Echo Evaluator GenServer integration, and runs the EchoMQ Redis replication sidecar. It contains everything that would be wrong to put in a generic library because it makes assumptions specific to Codemoji's stack.

The relationship is a one-way dependency: `codemoji-tunnel` imports `echo-tunnel`, never the reverse. The tunneling layer never knows about Codemoji. Codemoji knows what tunnel it's running on.

### Why This Article Exists

Two projects need a coordinated kick-off. This article is that kick-off. It defines:

- **The architectural rationale** for the two-project split, made explicit so it survives team changes
- **The repository structures** for both projects, with directory layouts and module boundaries
- **The roadmap** organized by project, mapping the planned chapters and milestones
- **The development standards** that apply to both projects (no fabricated numbers, references-per-chapter, ship-working-code)
- **The deployment story** — Fly.io native, single primary deployment path

After this article, the work begins. Each project gets its own chapters, its own commits, its own tests, its own release cadence. The chapters are written elsewhere; this article ensures they're written against a coherent foundation.

---

## The Architecture

```
                                    Internet
                                       │
                                       ▼
         ┌──────────────────────────────────────────────────┐
         │          codemoji-edge (Fly.io app)              │
         │                                                  │
         │   ┌────────────────────────────────────────┐    │
         │   │           codemoji-tunnel              │    │
         │   │                                         │    │
         │   │   • Telegram webhook routing           │    │
         │   │   • AppFather HMAC preservation        │    │
         │   │   • Eval protocol (Echo evaluator)     │    │
         │   │   • EchoMQ Redis replication sidecar   │    │
         │   │   • codemoji.games-specific config     │    │
         │   └────────────────────────────────────────┘    │
         │                       │                          │
         │                       │ imports                  │
         │                       ▼                          │
         │   ┌────────────────────────────────────────┐    │
         │   │             echo-tunnel                 │    │
         │   │                                         │    │
         │   │   • Reverse proxy + TLS                │    │
         │   │   • WebSocket tunnel transport         │    │
         │   │   • Multiplexing + streaming           │    │
         │   │   • Authentication + access control    │    │
         │   │   • Observability + inspection         │    │
         │   │   • Multi-tenant + caching             │    │
         │   │   • Resilience + graceful shutdown     │    │
         │   └────────────────────────────────────────┘    │
         │                       │                          │
         │                       │ imports                  │
         │                       ▼                          │
         │   Go stdlib + certmagic + coder/websocket       │
         │   + prometheus + modernc.org/sqlite              │
         └──────────────────────────────────────────────────┘
                                       │
                       Fly.io 6PN (WireGuard mesh)
                      ┌────────────────┼─────────────────┐
                      ▼                ▼                 ▼
                 [backend]         [admin]          [frontend]
```

`echo-tunnel` is the framework layer. It exposes Go interfaces and types: `tunnel.Registry`, `tunnel.Handler`, `auth.TokenStore`, `proxy.Router`, `cache.Middleware`, `inspect.RingBuffer`. Every chapter in the `echo-tunnel` roadmap (Parts 0–3 below) extends one of these surfaces with code that has nothing to do with Codemoji.

`codemoji-tunnel` is the application layer. It composes `echo-tunnel`'s primitives into a configured edge proxy: it provides a `tunnel.Registry` configured for the `dev-*` namespace, an `auth.TokenStore` populated from Fly secrets, a `proxy.Router` with static routes to `sera-merge-{backend,admin,frontend}.internal`, and a custom message handler that knows how to route `EvalRequest` to the Echo Evaluator and `RedisEvent` to the local Redis publisher. It is its own binary, but every primitive comes from `echo-tunnel`.

The deployment is a single Fly.io app: `codemoji-edge`. The binary is `codemoji-tunnel` (which imports `echo-tunnel`). The volume mount, the certificate cache, the SQLite database, and the Prometheus metrics endpoint are configured in the Codemoji-specific `fly.toml`. There is no separate `echo-tunnel` deployment for Codemoji — the framework runs inside the application binary.

For other projects (a hypothetical `partner-app-tunnel/` or `internal-dashboard-tunnel/`), the pattern repeats: import `echo-tunnel`, configure for your application, deploy as a single binary. The framework stays generic.

---

## Repository Structures

### `echo-tunnel/`

```
echo-tunnel/
├── README.md
├── LICENSE                       # permissive (MIT or Apache 2.0)
├── go.mod
├── go.sum
├── cmd/
│   ├── proxyd/                   # the framework's reference proxy binary
│   │   └── main.go               # minimal — most users embed via the library
│   └── proxy/                    # the tunnel client
│       └── main.go
├── pkg/                          # public API surface
│   ├── proxy/
│   │   ├── proxy.go              # ReverseProxy with Director + Transport tuning
│   │   ├── router.go             # Subdomain-keyed Router type
│   │   ├── routes.go             # StaticRoute + LoadStaticRoutes
│   │   └── health.go             # HealthChecker with circuit breaking
│   ├── tls/
│   │   ├── certmagic.go          # certmagic configuration helpers
│   │   ├── ondemand.go           # On-Demand TLS DecisionFunc plumbing
│   │   └── dns.go                # DNS-01 challenge solvers (libdns)
│   ├── tunnel/
│   │   ├── protocol.go           # Wire protocol message types
│   │   ├── registry.go           # TunnelRegistry (in-memory + persistent)
│   │   ├── handler.go            # TunnelHandler (WebSocket lifecycle)
│   │   ├── tunnel.go             # Tunnel.RoundTrip + writer goroutine
│   │   ├── stream.go             # Stream-mode messages (TCP/WS passthrough)
│   │   └── client.go             # Tunnel client with reconnect logic
│   ├── auth/
│   │   ├── tokens.go             # TokenStore interface + env/db backends
│   │   ├── policy.go             # TokenPolicy with subdomain restrictions
│   │   └── trust.go              # Header trust boundary middleware
│   ├── cache/
│   │   ├── lru.go                # Byte-bounded LRU
│   │   ├── middleware.go         # HTTP caching middleware
│   │   └── key.go                # Cache key construction with Vary
│   ├── inspect/
│   │   ├── buffer.go             # Ring buffer for captured requests
│   │   ├── api.go                # JSON API for list/detail/replay
│   │   └── ui.go                 # Embedded HTML/JS inspector UI
│   ├── tenant/
│   │   ├── store.go              # Multi-tenant Store interface
│   │   ├── sqlite.go             # SQLite implementation
│   │   ├── postgres.go           # PostgreSQL implementation
│   │   └── quota.go              # Resource quota checking
│   ├── observe/
│   │   ├── metrics.go            # Prometheus metrics
│   │   ├── logging.go            # slog setup helpers
│   │   └── health.go             # /livez + /healthz endpoints
│   └── extension/
│       └── handler.go            # Pluggable message handler interface
│                                 # for application-specific protocol extensions
├── internal/                     # implementation details, not public API
│   └── ...
├── deploy/
│   └── fly/
│       ├── fly.toml.example      # reference Fly configuration
│       └── Dockerfile.example
├── docs/
│   └── # echo-tunnel playbook chapters <-- YOU ARE HERE
└── tests/
    ├── integration/
    └── perf/
```

The `pkg/` directory is the public Go API. Everything in `pkg/` follows Go's stable-API rules: no breaking changes without a major version bump. The `internal/` directory contains implementation details that consumers cannot import.

The `pkg/extension/` package is the seam where applications hook in. `codemoji-tunnel` registers handlers for `EvalRequest` and `RedisEvent` message types through this interface — the framework doesn't know about those messages, but it dispatches them when they arrive on a tunnel connection.

### `codemoji-tunnel/`

```
codemoji-tunnel/
├── README.md
├── LICENSE                       # private (Codemoji proprietary)
├── go.mod                        # depends on echo-tunnel
├── go.sum
├── cmd/
│   ├── codemoji-edge/            # the Codemoji edge proxy binary
│   │   └── main.go               # imports echo-tunnel, wires Codemoji extensions
│   ├── codemoji-tunnel/          # the developer-facing tunnel client
│   │   └── main.go               # wraps echo-tunnel/cmd/proxy with config
│   ├── echo-eval/                # remote Elixir CLI
│   │   └── main.go
│   └── echomq-publisher/         # local Redis publisher (developer side)
│       └── main.go
├── internal/
│   ├── telegram/
│   │   ├── webhook.go            # Telegram Bot API webhook validation
│   │   └── secret.go             # X-Telegram-Bot-Api-Secret-Token verification
│   ├── appfather/
│   │   ├── webhook.go            # AppFather webhook signature verification
│   │   └── hmac.go               # HMAC-SHA256 over timestamp.body
│   ├── eval/
│   │   ├── protocol.go           # EvalRequest, EvalResult, EvalStream messages
│   │   ├── handler.go            # echo-tunnel extension handler for eval messages
│   │   └── client.go             # echo-eval CLI logic
│   ├── echomq/
│   │   ├── subscriber.go         # production-side Redis subscriber
│   │   ├── publisher.go          # developer-side Redis publisher
│   │   ├── filter.go             # channel filtering rules
│   │   ├── snapshot.go           # BullMQ queue snapshots
│   │   └── dashboard.go          # local web UI
│   ├── routes/
│   │   └── codemoji.go           # static routes for sera-merge services
│   └── codemoji/
│       └── config.go             # Codemoji-specific configuration loader
├── echo-integration/
│   └── lib/echo/evaluator/       # Elixir GenServer for code evaluation
│       ├── evaluator.ex
│       ├── safety.ex             # AST-level restrictions
│       └── sandbox.ex
├── scripts/
│   ├── set-webhook.ts            # Telegram webhook URL switching
│   ├── test-webhook.ts           # local AppFather test harness
│   ├── codemoji-tunnel           # one-command tunnel wrapper (bash)
│   └── new-developer.sh          # token generation for new team members
├── deploy/
│   └── fly/
│       ├── fly.toml              # the production Fly configuration
│       ├── Dockerfile            # multi-stage build for codemoji-edge
│       └── secrets.example.env   # template for fly secrets set
├── docs/
│   └── chapters/                 # codemoji-tunnel playbook chapters
└── tests/
    ├── e2e/
    └── webhook-fixtures/         # captured AppFather/Telegram payloads
```

The `internal/` packages are not importable from outside `codemoji-tunnel`. The Codemoji-specific logic stays Codemoji-private. The `echo-integration/` directory contains the Elixir module that runs inside the Echo orchestrator process — it's checked into this repository because its protocol must stay synchronized with the Go-side eval handler.

The `cmd/codemoji-edge/main.go` is the production binary. It imports `echo-tunnel/pkg/*`, configures the framework for Codemoji's specific deployment, registers the eval and EchoMQ extension handlers, and runs the resulting bundle as `codemoji-edge` on Fly.io.

---

## Roadmap

The chapters below are organized by project. Each project has a coherent reading order independent of the other. Cross-references are explicit when they appear.

---

### `echo-tunnel`: The Tunneling Platform

#### Part 0 — Foundations

**Chapter 1 · The Tunneling Problem**
The seven requirements that drive a serious tunnel implementation: trusted HTTPS, stable URLs, WebSocket passthrough, request inspection with replay, raw body preservation for HMAC verification, sub-10-second round-trip, multi-developer coexistence. Why each requirement matters in production scenarios beyond Codemoji: SaaS webhook integrations, partner API debugging, multi-region staging environments.

**Chapter 2 · The Market in 2026**
A factual survey of available tunneling tools. ngrok, Cloudflare Tunnel, Hookdeck, Pinggy, LocalXpose, Localtunnel, frp. Pricing tiers, feature matrices, what each tool optimizes for. The seven-requirement matrix applied to each. Where managed services fit and where self-hosting wins.

**Chapter 3 · The Build Decision**
The architectural rationale for self-hosting. Costs (engineering time, operational responsibility) and benefits (control, customization, no per-developer fees, no usage limits, complete observability). Why Go: standard library quality for HTTP and TLS, certmagic for ACME, single-binary deployment, low operational footprint. The tunnel as a piece of infrastructure that should be owned, not rented.

#### Part 1 — Building the Tunnel

**Chapter 4 · The Smallest Useful Proxy**
A reverse proxy in 50 lines using `httputil.ReverseProxy`. The `Director` function for request rewriting, the `Transport` configuration for connection pooling and timeouts, the `responseWriter` wrapper for capturing response metadata. The foundation everything else extends.

**Chapter 5 · Automatic HTTPS**
Let's Encrypt certificates via `golang.org/x/crypto/acme/autocert` for single-domain certificates. The HTTP-01 challenge mechanism. Persistent certificate caching. Switching between staging and production endpoints. The Fly.io specifics: raw TCP passthrough, kill_signal and kill_timeout configuration.

**Chapter 6 · Wildcard Routing**
Wildcard certificates via DNS-01 using `caddyserver/certmagic` and `libdns/cloudflare`. The `Router` struct with subdomain-keyed lookup. RFC 1035 subdomain validation with practical extensions. Fallback handlers for unmatched hostnames.

**Chapter 7 · WebSocket Tunnels — The Control Plane**
The wire protocol: six message types (`Register`, `RegisterAck`, `Request`, `Response`, `Disconnect`, `Ping`). JSON-encoded with base64 body fields for raw byte preservation. `Tunnel.RoundTrip`, the pending response map, the `TunnelRegistry` and `TunnelHandler`. Client-side reconnection with exponential backoff and jitter.

**Chapter 8 · Multiplexing**
Concurrent request handling on a single tunnel WebSocket. The writer goroutine pattern with a buffered channel. Goroutine-per-request with semaphore-bounded concurrency. Streamed response chunks for large bodies. Flow control via the writer channel buffer.

**Chapter 9 · Raw TCP and WebSocket Passthrough**
WebSocket connections that pass through transparently using `http.Hijacker`. Bidirectional byte bridging via `io.Copy` with proper close coordination. Stream-mode messages (`StreamOpen`, `StreamReady`, `StreamData`, `StreamClose`). Why UDP is not implemented and what would be required.

**Chapter 10 · Authentication and Access Control**
Four security layers. Pre-shared bearer tokens with `subtle.ConstantTimeCompare`. Per-token subdomain policies with namespace prefix matching. Header trust boundary middleware (`TrustNone`, `TrustFly`, `TrustCloudflare`). Per-tunnel auth (HTTP Basic Auth, IP allowlists). Composition through standard `http.Handler` wrapping.

**Chapter 11 · Observability**
Three observability surfaces. Structured logging with `log/slog` and JSON output. Prometheus metrics: tunnel registrations, active tunnel count, HTTP throughput, latency histograms, stream activity, auth failures. Request inspector with ring buffer, JSON API, and embedded HTML UI at `/_inspect`. Replay endpoint for captured requests.

**Chapter 12 · Resilience**
Graceful shutdown with phased drain on SIGTERM. Liveness (`/livez`) and readiness (`/healthz`) endpoints with `atomic.Bool` for lock-free reads. Per-IP rate limiting at WebSocket handshake and HTTP request layers. Seven failure mode tests covering shutdown, disconnects, unreachable backends, auth failures, conflicts, rate limits, and health transitions.

#### Part 2 — Production Infrastructure

**Chapter 13 · Multi-Tenant Isolation**
User accounts with namespaces and quotas. SQLite-backed `Store` interface with a PostgreSQL alternative. Hashed token storage. Namespaced subdomain enforcement with prefix matching. Resource quotas: max tunnels, max subdomains, max in-flight requests, max TCP ports, max streams. Persistent subdomain claims that survive restarts. Custom domains via certmagic's `OnDemandConfig` with a database-backed `DecisionFunc`.

**Chapter 14 · Edge Caching and Static File Serving**
HTTP caching semantics from RFC 9111. Byte-bounded LRU cache with `container/list` for O(1) operations. Cache key construction including `Vary` header values. Caching middleware: fresh-hit, stale-but-validatable conditional revalidation, miss-and-store. Static file serving: upload tar.gz archives, extract per subdomain, serve from edge without touching the tunnel.

**Chapter 15 · Fly.io Deployment**
The single supported production deployment path. The `fly.toml` configuration: raw TCP passthrough, kill_signal `SIGTERM`, kill_timeout 15s, persistent volume mount, metrics integration. Multi-stage Dockerfile with `CGO_ENABLED=0`. `fly secrets set` for credentials. `fly volumes create` for certificate persistence. DNS configuration with Cloudflare. Verification commands. Update and rollback procedures.

#### Part 3 — Operations

**Chapter 16 · Monitoring and Alerting**
Prometheus scraping configuration. The eight core metrics with PromQL queries. Grafana dashboard JSON for the four key panels: throughput by subdomain, p95 latency, active tunnel gauge, backend health. Alertmanager rules for actionable conditions: certificate expiry within 14 days, sustained backend health failures, tunnel registration error rate above threshold, edge unhealthy.

**Chapter 17 · Security Model**
Threat model for a self-hosted tunnel. What a stolen developer token enables. The trust boundary between development tunnels and production routing. Token rotation procedure. IP allowlisting for high-value tokens. Audit log review patterns. The blast radius of each authentication failure mode.

**Chapter 18 · The Operator's Runbook**
Routine operations with copy-paste commands. View active tunnels. Rotate a token. Purge the cache for a subdomain. View the inspector. Check certificate expiry. Force renewal. Backup the SQLite database. Migrate to PostgreSQL for multi-machine scale-out. Filter logs by subdomain. Recover from a Fly outage.

---

### `codemoji-tunnel`: The Application

#### Part 4 — Codemoji Integration

**Chapter 19 · Edge Proxy for `*.codemoji.games`**
Deploying `codemoji-edge` to Fly.io. Wildcard TLS for `*.codemoji.games` and the apex `codemoji.games` via certmagic + Cloudflare DNS-01 (DNS provider only). Static route configuration for the production service mesh: routing to the three sera-merge Fly apps over 6PN. Health checking with circuit breaking. The complete deployment from zero to running.

**Chapter 20 · Tunnel Mode for Local Development**
Adding the tunnel WebSocket endpoint alongside production routes on the same binary. Token authentication with `dev-*` namespace prefix restriction. WebSocket passthrough for Codemoji's real-time gameplay. The `codemoji-tunnel` wrapper script with `~/.codemoji-tunnel` dotfile. The routing decision: production static routes take priority over development tunnels.

**Chapter 21 · Telegram Webhook Pipeline**
Configuring `setWebhook` to point at `dev-yourname.codemoji.games` for development. The complete payment flow traced through the tunnel. Measuring tunnel round-trip latency on actual infrastructure to verify the 10-second deadline. The request inspector for webhook replay after handler fixes.

**Chapter 22 · AppFather Partner Webhook Integration**
HMAC-SHA256 signature preservation through the edge → tunnel → client chain. The bytes-as-base64 transport that never re-parses JSON. The `rawBody` Fastify plugin for preserving bytes during local handler invocation. Three webhook handlers: pre-checkout (validation, deadline), checkout-success (double-entry ledger fulfillment), refund (reversal). Local test harness for generating signed payloads.

**Chapter 23 · Multi-Developer Setup**
Per-developer tunnel tokens with namespace restrictions. Multiple tunnels coexisting on the same edge proxy. Each developer with their own webhook URL, inspector view, and request replay. The `new-developer.sh` script for token generation. Coordination patterns for shared bot tokens. Token rotation procedure.

#### Part 5 — Remote BEAM Access

**Chapter 24 · The Eval Protocol**
Three new wire protocol messages: `EvalRequest`, `EvalResult`, `EvalStream`. Registration via the `echo-tunnel` extension interface — the framework dispatches the messages, `codemoji-tunnel` handles them. Wire format examples. Protocol versioning.

**Chapter 25 · The Echo Evaluator GenServer**
An Elixir GenServer that receives `EvalRequest` messages and evaluates them in a restricted environment. `Code.eval_string/3` with a binding exposing safe references to application modules. Execution timeout via `Task.async` + `Task.yield` + `Task.shutdown`. Memory monitoring. Audit logging with the tunnel user's identity attached.

**Chapter 26 · Safety Rails**
AST-level restrictions using `Code.string_to_quoted/2` before evaluation. Denylist of modules, functions, and constructs. The restrictions as defense-in-depth, not a sandbox. A `--unsafe` flag for the rare cases that need `File.read`. Honest threat modeling.

**Chapter 27 · The `echo-eval` CLI**
A local Go binary that connects to the tunnel and sends Elixir expressions. Reads from stdin for multi-line. `--format json` for scripting. `--timeout` for long-running queries. Editor integration: select an Elixir expression, pipe through `echo-eval`, see the result inline.

**Chapter 28 · Mix Tasks Over Tunnel**
A Mix task runner over the eval protocol. `echo-eval mix "Echo.ReleaseTasks.migrate()"`. A `.echo-tasks.exs` file defining commonly used tasks with descriptions and confirmation prompts for destructive operations.

#### Part 6 — EchoMQ: Data Plane Replication

**Chapter 29 · The Replication Architecture**
The problem: local Redis has no production events. The solution: a tunnel extension that replicates production PUBSUB messages to local Redis. Strictly one-way (production → local) for safety. BullMQ queue state via periodic snapshots. Local subscriber code unchanged.

**Chapter 30 · The Redis Subscriber Sidecar**
A Go process running alongside `codemoji-edge` on the Fly machine. Connects to production Redis, subscribes to configured PUBSUB channels, forwards messages through the tunnel as `RedisEvent` messages. Channel-selective configuration. BullMQ snapshot intervals.

**Chapter 31 · The Local Redis Publisher**
On the developer's laptop, a Go process receives `RedisEvent` messages from the tunnel and publishes them to local Redis. Local Fastify subscriber sees events as if originated locally. Publisher never writes to production Redis. BullMQ queue snapshots written to dashboard-readable keys.

**Chapter 32 · Channel Filtering and Transformation**
Filter rules narrowing replication. Filters run on the production-side sidecar so filtered events never cross the tunnel. Field-level transformations for masking sensitive data (player IDs, payment details) before replication.

**Chapter 33 · The EchoMQ Dashboard**
A local web UI showing replication status: active channels, throughput per channel, queue depths, live event stream. Reads from local Redis and tunnel metrics. The window into the production data plane without touching production.

#### Part 7 — Codemoji Operations

**Chapter 34 · The Codemoji Runbook**
Codemoji-specific operational procedures beyond `echo-tunnel`'s generic runbook. Webhook URL switching workflows. Token generation for new developers. Inspector replay for payment flow debugging. EchoMQ replication health checks. The double-entry ledger reconciliation procedure when a payment flow is interrupted mid-transaction.

**Chapter 35 · Codemoji Disaster Recovery**
Recovery procedures specific to Codemoji's data model. Replaying captured webhooks from the inspector. Reconstructing the ledger from BullMQ job history. Coordinating Telegram bot webhook reconfiguration during a Fly region outage. The decision tree for "is this a tunnel problem or a backend problem."

---

### Appendices (shared)

**Appendix A · Wire Protocol Reference**
Complete message type definitions across both projects. Base messages from `echo-tunnel` (Register, Request, Response, Stream*). Extension messages from `codemoji-tunnel` (EvalRequest, EvalResult, EvalStream, RedisEvent, QueueSnapshot). JSON schema for each. Wire format examples. Versioning and backwards-compatibility rules.

**Appendix B · DNS and TLS Fundamentals**
A field manual for debugging certificate and DNS issues at 2 AM. DNS record types, propagation, the TLS handshake, wildcard rules, the ACME protocol, certificate chains. An eight-step debugging checklist with `dig` and `openssl` commands.

**Appendix C · ngrok Feature Parity**
Feature-by-feature comparison between this platform and ngrok's current pricing tiers. Five comparison tables. Decision framework for when ngrok wins and when self-hosting wins. Parity by chapter.

**Appendix D · Codemoji Configuration Reference**
Copy-paste configuration files for the Codemoji deployment. The complete `fly.toml` for `codemoji-edge`. The `~/.codemoji-tunnel` dotfile template. The `echomq.yaml` for replication channels. The `.echo-tasks.exs` for remote Mix tasks. The `vite.config.ts` HMR configuration. Environment variable reference with defaults and explanations.

---

## Reading Paths

The two-project structure supports several reading paths.

**The "I'm extending `echo-tunnel`" path.** Read `echo-tunnel` Part 0 (foundations), then Part 1 in order (the chapters build on each other), then Parts 2 and 3 for production concerns. Skip the `codemoji-tunnel` section unless you want to see how a real application is built on the framework.

**The "I'm working on Codemoji" path.** Skim `echo-tunnel` Part 0 Chapter 3 (the build decision) for context. Skip Parts 1 and 2 — the framework is the dependency, not your concern. Read `codemoji-tunnel` Parts 4–7 in order. Refer back to `echo-tunnel` Part 3 (operations) when an incident requires understanding the framework layer.

**The "I'm understanding the system" path.** Read both Part 0 sections (one per project), then both Part 7 / Part 3 sections (the runbooks). The middle chapters become reference material — read them when you need depth on a specific topic.

**The "I'm onboarding a new team member" path.** This article (the kick-off), plus Chapter 19 (the edge proxy deployment) and Chapter 23 (multi-developer setup) from `codemoji-tunnel`. Total reading time is short. After this, the new engineer can run `codemoji-tunnel` locally and receive their first webhook within a few hours.

---

## Standards

These apply to both `echo-tunnel` and `codemoji-tunnel`.

**Every chapter ships working code.** The repository is tagged per chapter. Clone the repo, check out the tag, and you have the working state for that chapter. No pseudocode, no "exercise for the reader," no scaffolding that doesn't compile. CI verifies that every tagged commit builds, every test passes, and the chapter's example commands execute successfully.

**No fabricated numbers.** Performance claims include measurement methodology or are derived from formulas with stated inputs. When the playbook says "the tunnel adds latency," it tells you how to measure that latency on your specific infrastructure rather than fabricating a number. This standard was established after an early draft contained synthetic benchmarks that were caught and removed.

**References per chapter.** Every chapter ends with a references section: repositories with links, expert voices in the field, books that informed the design, relevant RFCs or standards. The reader can follow these references for depth beyond the chapter's scope.

**Single deployment path: Fly.io native.** Both projects deploy to Fly.io. The `fly.toml`, `fly secrets`, `fly volumes`, and `fly deploy` commands are the supported workflow. No Docker Compose for production, no Kubernetes manifests, no Terraform. The constraint is intentional: one deployment story means one set of operational concerns, one runbook, one set of failure modes. If a project outgrows Fly.io, a migration chapter gets written; until then, the focus is on doing one thing well.

**Three languages where they fit.** Go for the tunnel itself (both projects). Elixir for the Echo evaluator integration in `codemoji-tunnel/echo-integration/`. TypeScript for the Fastify-side scripts (`set-webhook.ts`, `test-webhook.ts`). The tunnel binaries have no runtime dependencies on Elixir or Node — those languages appear only in adjacent code that integrates with the existing Codemoji stack.

**Public vs. private API.** `echo-tunnel/pkg/` is the stable public Go API; consumers (including `codemoji-tunnel`) can rely on it without breaking changes between minor versions. `echo-tunnel/internal/` contains implementation details. `codemoji-tunnel/internal/` is entirely private — no public API surface, no external consumers. This boundary is mechanical (Go enforces `internal/`) and intentional.

---

## Closing the Kick-Off

Two repositories. One tunneling platform. The framework (`echo-tunnel`) is generic and reusable. The application (`codemoji-tunnel`) is Codemoji-specific and consumes the framework. The architectural split keeps each layer focused on its own concern, makes the framework reusable for future projects, and prevents Codemoji-specific assumptions from polluting generic tunneling code.

The deployment is Fly.io. The language is Go. The dependencies are minimal: certmagic for ACME, coder/websocket for the WebSocket layer, prometheus/client_golang for metrics, modernc.org/sqlite for persistence. Every other piece is the Go standard library.

The first chapter is `echo-tunnel` Chapter 1 — the tunneling problem statement that establishes why the framework exists and what it must solve. The first chapter someone working on Codemoji actually reads is `codemoji-tunnel` Chapter 19 — the Codemoji edge proxy deployment that turns the framework into running infrastructure.

Both paths converge on the same outcome: a tunnel platform Codemoji owns, runs, and extends. No subscription, no per-developer fees, no usage limits, no external dependency on a tunneling vendor's roadmap or pricing changes.

The investment is bounded. The result is owned.

Let's start.

→ **`echo-tunnel` · Chapter 1 · The Tunneling Problem**
