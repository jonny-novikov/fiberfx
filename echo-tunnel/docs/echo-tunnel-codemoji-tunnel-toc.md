# `echo-tunnel` / `codemoji-tunnel` · Table of Contents

---

*A complete map of the two-project series. Each entry is contractual: what the chapter delivers, the components it ships, the design choices it makes, and the trade-offs it surfaces.*

---

## How to Use This Document

Each entry below is a contract. When a chapter is written, the abstract here is the deliverable list it must satisfy: the components named must exist, the configurations described must be present, the design decisions surfaced must be made explicitly. The abstracts are not teasers; they are the constraints that make the chapter writeable independently and the series internally consistent.

The TOC is split into three sections:

- **`echo-tunnel`** — the generic framework, Parts 0 through 3, Chapters 1 through 18
- **`codemoji-tunnel`** — the Codemoji-specific application built on the framework, Parts 4 through 7, Chapters 19 through 35
- **Shared Appendices** — A through D, designed for non-linear reference access

Readers approaching the series for the first time should consult the Preface for reading paths. Readers looking for a specific topic should jump directly to the chapter or appendix below.

---

## `echo-tunnel` — The Framework

The framework is a self-hosted tunneling platform written in Go. It exposes stable Go interfaces under `pkg/`, deploys as a single static binary, and makes no assumptions about the application that consumes it. Every chapter in this section either establishes the framework's reasoning (Part 0), implements a primitive (Part 1), hardens it for production (Part 2), or operates it in the field (Part 3).

### Part 0 — Foundations

**Chapter 1 · The Tunneling Problem**
The seven requirements that any serious tunnel must meet, each grounded in a concrete failure scenario from the public webhook ecosystem: trusted HTTPS without intervention, stable URLs across sessions, WebSocket passthrough, request inspection with replay, raw body preservation for HMAC verification, sub-deadline round-trip latency, and multi-developer coexistence. The chapter shows that no single requirement is the killer — the conjunction is. Each requirement is illustrated with the providers that impose it (Telegram, Stripe, GitHub, Shopify, Slack, AppFather) and the failure mode that follows when a tunnel doesn't meet it. The chapter closes with a forward map: which subsequent chapters address which requirement, so a reader can navigate by the problem they care most about.

**Chapter 2 · The Market in 2026**
A factual, deduplicated survey of available tunneling tools applied against the seven-requirement matrix from Chapter 1. Managed tools covered: ngrok (free, Hobbyist, Pro pricing tiers), Cloudflare Tunnel, Hookdeck, Pinggy, LocalXpose, Localtunnel. Self-hosted alternatives covered: frp, Chisel, Bore. Each tool gets a row in the matrix and a one-paragraph summary of what it optimizes for and where it gives way. The chapter is written without the marketing softening that vendor websites apply, and ends with the honest summary: the closest match fails on at least one capability that production-adjacent development depends on.

**Chapter 3 · The Build Decision**
The architectural rationale for self-hosting, treated as a real engineering trade-off rather than a foregone conclusion. The chapter enumerates the costs of building (engineering time, operational responsibility, security risk in HMAC and TLS code) and the benefits (control, customization, no per-developer fees, no usage limits, complete observability), then provides a decision framework readers can apply to projects beyond Codemoji. The choice of Go as the implementation language is justified explicitly: standard-library quality for HTTP and TLS, certmagic for ACME, single-binary deployment, low operational footprint. The chapter does not assume the build decision is universally right — it explains why it was right for the project that motivated this work.

### Part 1 — Building the Tunnel

**Chapter 4 · The Smallest Useful Proxy**
A working reverse proxy in roughly fifty lines of Go using `httputil.ReverseProxy`. The chapter develops the three primitives that everything else extends: the `Director` function for request rewriting, the `Transport` configuration for connection pooling and timeouts, and the `responseWriter` wrapper for capturing response metadata. Each primitive has its design choices justified — why this Transport timeout, why the responseWriter wrapper, what the alternatives are. The chapter ships a complete `cmd/proxyd/main.go` that compiles and runs, and ends with a tagged commit (`chapter-04-smallest-useful-proxy`) that produces the working state.

**Chapter 5 · Automatic HTTPS**
Single-domain Let's Encrypt certificates via `golang.org/x/crypto/acme/autocert`. The chapter walks through the HTTP-01 challenge mechanism, persistent certificate caching to avoid rate limits during development, and the staging-versus-production endpoint switch. Fly.io specifics are surfaced explicitly: raw TCP passthrough so TLS terminates in the application, `kill_signal` and `kill_timeout` configuration so certificate work isn't interrupted mid-flight. By the end, a single domain serves valid HTTPS without manual certificate management.

**Chapter 6 · Wildcard Routing**
Wildcard certificates via DNS-01 ACME using `caddyserver/certmagic` and `libdns/cloudflare`, plus the routing layer that takes advantage of them. The chapter introduces the `Router` struct with subdomain-keyed lookup, validates subdomains per RFC 1035 with practical extensions, and adds fallback handlers for unmatched hostnames. Wildcard routing is what makes per-developer subdomains (`dev-alice.example.com`, `dev-bob.example.com`) practical without provisioning a certificate per developer. The chapter ends with a demo that registers three subdomains dynamically and serves them all under one wildcard certificate.

**Chapter 7 · WebSocket Tunnels — The Control Plane**
The wire protocol that makes the tunnel a tunnel. Six message types are defined: `Register`, `RegisterAck`, `Request`, `Response`, `Disconnect`, `Ping`. Bodies are JSON-encoded with base64 fields for raw byte preservation (the requirement that protects HMAC signatures end-to-end). The chapter implements `Tunnel.RoundTrip`, the pending response map keyed by request ID, the `TunnelRegistry` that maps subdomains to active tunnels, and the `TunnelHandler` that manages the WebSocket lifecycle. Client-side reconnection with exponential backoff and jitter closes the chapter and produces the first end-to-end working tunnel.

**Chapter 8 · Multiplexing**
Concurrent request handling on a single tunnel WebSocket without head-of-line blocking. The writer-goroutine pattern with a buffered channel serializes outbound writes; goroutine-per-request with a semaphore-bounded concurrency cap parallelizes inbound handling. Streamed response chunks let large bodies flow without full buffering. The chapter discusses the flow-control trade-offs visible in the writer channel buffer size — too small and slow consumers cause backpressure, too large and memory growth becomes the failure mode. The deliverable is a tunnel that handles dozens of concurrent requests over one WebSocket connection.

**Chapter 9 · Raw TCP and WebSocket Passthrough**
Transparent WebSocket passthrough via `http.Hijacker`. The chapter implements bidirectional byte bridging with `io.Copy` and proper close coordination on both directions. Stream-mode messages are added to the wire protocol: `StreamOpen`, `StreamReady`, `StreamData`, `StreamClose`. The chapter is honest about what it does not implement — UDP passthrough is named, the reasons it's hard (no connection lifecycle, no in-band signaling) are stated, and the requirements for a future implementation are sketched. The deliverable is a tunnel that supports Phoenix Channels, GraphQL subscriptions, and Vite HMR without modification.

**Chapter 10 · Authentication and Access Control**
Four security layers composed via standard `http.Handler` wrapping. Pre-shared bearer tokens with `subtle.ConstantTimeCompare` guard the tunnel registration endpoint. Per-token subdomain policies with namespace-prefix matching limit which subdomains a token may claim. Header trust boundary middleware (`TrustNone`, `TrustFly`, `TrustCloudflare`) controls which inbound headers the tunnel accepts as authoritative. Per-tunnel auth (HTTP Basic Auth, IP allowlists) protects the tunneled service itself. The chapter ends with a composition example showing how to stack the four layers cleanly.

**Chapter 11 · Observability**
Three observability surfaces shipped together. Structured logging with `log/slog` and JSON output. Prometheus metrics covering tunnel registrations, active tunnel count, HTTP throughput, latency histograms, stream activity, and authentication failures. The request inspector implemented as a bounded ring buffer, a JSON API for browsing captures, and an embedded HTML/JS UI mounted at `/_inspect`. A replay endpoint that re-sends a captured request through the active tunnel as if it had just arrived — the capability that turns webhook debugging from minutes per cycle into seconds.

**Chapter 12 · Resilience**
The tunnel's behavior under stress and shutdown. Graceful shutdown with phased drain on SIGTERM: stop accepting new tunnels, finish in-flight requests, close active tunnels, exit. Liveness (`/livez`) and readiness (`/healthz`) endpoints backed by `atomic.Bool` for lock-free reads from a hot path. Per-IP rate limiting at both the WebSocket handshake and HTTP request layers. The chapter ships seven failure-mode tests covering shutdown timing, mid-stream disconnects, unreachable backends, auth failures, subdomain conflicts, rate-limit exhaustion, and health-state transitions.

### Part 2 — Production Infrastructure

**Chapter 13 · Multi-Tenant Isolation**
User accounts, namespaces, and quotas as first-class framework concerns. The `Store` interface is defined with two implementations — SQLite for single-machine deployments, PostgreSQL for multi-machine scale-out — and tokens are stored hashed (the chapter chooses bcrypt and explains the choice). Namespaced subdomain enforcement uses prefix matching against per-token policies. Resource quotas cover max tunnels, max subdomains, max in-flight requests, max TCP ports, and max streams per tenant. Persistent subdomain claims survive restarts. Custom domains are supported via certmagic's `OnDemandConfig` with a database-backed `DecisionFunc` so any tenant-claimed domain provisions a certificate on first request.

**Chapter 14 · Edge Caching and Static File Serving**
HTTP caching semantics from RFC 9111, implemented as middleware. The cache is a byte-bounded LRU using `container/list` for O(1) operations; cache key construction includes `Vary` header values for correct content negotiation. The middleware handles fresh-hit, stale-but-validatable conditional revalidation, and miss-and-store cases distinctly. Static file serving is layered on top: tar.gz archives uploaded per subdomain, extracted to local storage, served from the edge without crossing the tunnel — the right behavior for sites with static frontends and a separate API.

**Chapter 15 · Fly.io Deployment**
The single supported production deployment path. The chapter ships a complete `fly.toml` with raw TCP passthrough, `kill_signal = "SIGTERM"`, `kill_timeout = "15s"`, persistent volume mount, and metrics integration. The Dockerfile is multi-stage with `CGO_ENABLED=0` for a minimal final image. Secrets management uses `fly secrets set` for ACME credentials and database passwords. Volume creation via `fly volumes create` provides certificate persistence across machine restarts. DNS configuration with Cloudflare is shown end-to-end. Verification commands and update/rollback procedures close the chapter.

### Part 3 — Operations

**Chapter 16 · Monitoring and Alerting**
Operating the framework after it's deployed. Prometheus scraping configuration is shown for both Fly.io's built-in scraper and external Prometheus servers. Eight core metrics are documented with PromQL queries that turn each into a useful signal. A Grafana dashboard JSON ships with four key panels: throughput by subdomain, p95 latency by subdomain, active tunnel gauge, and backend health. Alertmanager rules cover actionable conditions: certificate expiry within 14 days, sustained backend health failures, tunnel registration error rate above threshold, and edge unhealthy. Each alert includes the runbook link for the operator who answers it.

**Chapter 17 · Security Model**
Threat model for a self-hosted tunnel, written without the ambiguity that "we take security seriously" sentences allow. The chapter enumerates what a stolen developer token enables (and does not enable), documents the trust boundary between development tunnels and production routing, and walks through the token rotation procedure step by step. IP allowlisting for high-value tokens is shown with concrete configuration. Audit log review patterns identify the suspicious behaviors operators should look for. The chapter closes with a blast-radius table — for each authentication failure mode, exactly what an attacker can reach.

**Chapter 18 · The Operator's Runbook**
Routine operations with copy-paste commands. View active tunnels. Rotate a token. Purge the cache for a subdomain. Open the inspector. Check certificate expiry. Force certificate renewal. Backup the SQLite database. Migrate from SQLite to PostgreSQL for multi-machine scale-out. Filter logs by subdomain. Recover from a Fly.io regional outage. Each procedure is timed, has a copy-paste command sequence, and lists the verification steps that confirm success.

---

## `codemoji-tunnel` — The Application

The application layer consumes `echo-tunnel` as a Go module dependency and configures it for Codemoji's specific needs: routing `*.codemoji.games` to the sera-merge service mesh, integrating Telegram and AppFather webhook flows, embedding the Echo Evaluator GenServer protocol, and running the EchoMQ Redis replication sidecar. Every chapter in this section assumes the framework's primitives are available and focuses on the specific assumptions Codemoji's stack imposes.

### Part 4 — Codemoji Integration

**Chapter 19 · Edge Proxy for `*.codemoji.games`**
Deploying `codemoji-edge` to Fly.io as the production entry point for the Codemoji platform. Wildcard TLS for `*.codemoji.games` and the apex `codemoji.games` is provisioned via certmagic with Cloudflare as the DNS-01 provider only (Cloudflare does not proxy traffic — the TLS certificate is issued by Let's Encrypt and the connection terminates in `codemoji-edge`). Static routes are configured for the production service mesh: `app.codemoji.games` to `sera-merge-frontend.internal`, `api.codemoji.games` to `sera-merge-backend.internal`, `admin.codemoji.games` to `sera-merge-admin.internal`, all over Fly's 6PN private network. Health checking with circuit breaking removes unhealthy backends from rotation. The chapter delivers the complete deployment from zero to running production traffic.

**Chapter 20 · Tunnel Mode for Local Development**
Adding the tunnel WebSocket endpoint alongside production routes on the same `codemoji-edge` binary. Token authentication is configured with `dev-*` namespace prefix restriction so developer tokens cannot claim production hostnames. WebSocket passthrough is exercised against Codemoji's real-time gameplay traffic — Phoenix Channels frames flow through unmodified. The `codemoji-tunnel` wrapper script reads from a `~/.codemoji-tunnel` dotfile for token and subdomain configuration so developers don't pass credentials on the command line. The routing decision is made explicit: production static routes always take priority over development tunnel claims, so a misconfigured developer token cannot accidentally hijack production traffic.

**Chapter 21 · Telegram Webhook Pipeline**
Configuring `setWebhook` to point at `dev-yourname.codemoji.games` for development, and tracing the complete Telegram payment flow through the tunnel. The pre-checkout, checkout-success, and refund webhooks are each followed step by step from Telegram's edge to the local Fastify handler. Tunnel round-trip latency is measured on actual infrastructure using a timing-server pattern — no fabricated numbers — so the reader knows their margin against Telegram's 10-second pre-checkout deadline. The request inspector becomes the central debugging tool: capture a real webhook, fix the handler, replay the captured request locally without re-initiating a real payment.

**Chapter 22 · AppFather Partner Webhook Integration**
HMAC-SHA256 signature preservation through the edge → tunnel → client → Fastify chain, end to end. The chapter shows how the bytes-as-base64 transport never re-parses the JSON body, so the signature computed by AppFather verifies exactly on the local handler. The `rawBody` Fastify plugin preserves bytes during local handler invocation. Three webhook handlers are implemented: pre-checkout (validation against the database, deadline enforcement), checkout-success (double-entry ledger fulfillment), and refund (reversal entries with audit trail). A local test harness generates signed payloads so the developer can exercise the handlers without coordinating with AppFather's sandbox.

**Chapter 23 · Multi-Developer Setup**
Running multiple developers concurrently on the same `codemoji-edge` deployment. Each developer gets a tunnel token with a namespace restriction (`dev-alice-*`, `dev-bob-*`) and claims subdomains under their namespace independently. Each developer has their own webhook URL, their own inspector view, and their own request replay history. The `new-developer.sh` script generates and registers a new token with a single command. Coordination patterns for shared bot tokens (when two developers must point the same Telegram bot at different webhooks) are documented. The token rotation procedure handles the case of a leaked token without disrupting other developers' work.

### Part 5 — Remote BEAM Access

**Chapter 24 · The Eval Protocol**
Three new wire-protocol messages added via the `echo-tunnel` extension interface: `EvalRequest`, `EvalResult`, and `EvalStream`. The framework dispatches these messages to the registered handler; `codemoji-tunnel` handles them. Wire format examples are shown for each message type. Protocol versioning is addressed explicitly so the eval protocol can evolve without breaking deployed clients. The deliverable is a clean extension surface that future protocols (the Redis replication protocol in Part 6) reuse.

**Chapter 25 · The Echo Evaluator GenServer**
An Elixir GenServer in `codemoji-tunnel/echo-integration/` that receives `EvalRequest` messages and evaluates them in a restricted environment. `Code.eval_string/3` is invoked with a binding that exposes safe references to application modules. Execution timeout is enforced via `Task.async` plus `Task.yield` plus `Task.shutdown` — the only pattern that actually kills runaway BEAM processes. Memory monitoring caps per-evaluation heap growth. Audit logging attaches the tunnel user's identity to every evaluation so post-incident review is possible. The chapter ends with a worked example: evaluate an arbitrary Elixir expression remotely and receive the result over the tunnel.

**Chapter 26 · Safety Rails**
AST-level restrictions applied via `Code.string_to_quoted/2` before evaluation. The denylist covers modules (`File`, `System`, `Code`, `:os`), functions that escape the BEAM (`System.cmd/3`, `Port.open/2`), and constructs that disable the safety rails themselves. The chapter is honest that the restrictions are defense-in-depth, not a sandbox — a determined attacker with eval access can find escapes, so the protection is in token-level access control rather than the AST checker. A `--unsafe` flag is provided for the rare cases that legitimately need `File.read` for debugging. The threat model is stated explicitly: who can use eval, what they can do, what the audit log captures.

**Chapter 27 · The `echo-eval` CLI**
A local Go binary that connects to the tunnel and sends Elixir expressions over the eval protocol. Multi-line expressions are read from stdin. The `--format json` flag produces machine-readable output for scripting. The `--timeout` flag bounds long-running queries. Editor integration is shown for VS Code and Neovim: select an Elixir expression, pipe through `echo-eval`, see the result inline in the editor. The chapter ends with the case for replacing `iex --remsh` (which requires SSH access to a Fly machine) with `echo-eval` (which works over the tunnel that's already running).

**Chapter 28 · Mix Tasks Over Tunnel**
A Mix task runner built on the eval protocol. `echo-eval mix "Echo.ReleaseTasks.migrate()"` runs a database migration on the remote BEAM node. A `.echo-tasks.exs` file in the project root defines commonly used tasks with descriptions and confirmation prompts for destructive operations (production database migrations, ledger truncation, subscription rebuilds). The chapter argues that this is the right replacement for the SSH-and-IEx workflow that most BEAM projects fall back to: same expressiveness, much less ceremony, with audit logging built in.

### Part 6 — EchoMQ: Data Plane Replication

**Chapter 29 · The Replication Architecture**
The problem: a developer's local environment has no production events, so code paths that respond to PUBSUB messages or BullMQ job state changes go untested until production. The solution: a tunnel extension that replicates production Redis PUBSUB messages to local Redis, strictly one-way, with BullMQ queue state captured via periodic snapshots rather than live replication. Local subscriber code runs unchanged because it sees production-shaped events. The chapter develops the architecture diagram, names the components added in Chapters 30 through 32, and explicitly excludes write-back to production as a non-goal.

**Chapter 30 · The Redis Subscriber Sidecar**
A Go process running alongside `codemoji-edge` on the production Fly machine. It connects to production Redis, subscribes to configured PUBSUB channels, and forwards messages through the tunnel as `RedisEvent` wire-protocol messages. Channel selection is configuration-driven — only declared channels are replicated. BullMQ snapshot intervals are configurable per queue. The sidecar is its own binary in `cmd/echomq-sidecar/` so it can be deployed and scaled independently. The chapter ships the deployment story for adding the sidecar to the existing `codemoji-edge` Fly.io app.

**Chapter 31 · The Local Redis Publisher**
On the developer's laptop, a Go process receives `RedisEvent` messages from the tunnel and publishes them to local Redis. The local Fastify subscriber sees events as if originated locally, no code changes required. The publisher never writes to production Redis — the architecture is strictly one-way. BullMQ queue snapshots are written to local-Redis keys that the existing dashboard code reads. The chapter shows the developer-side wire-up and the configuration for selecting which channels to subscribe to.

**Chapter 32 · Channel Filtering and Transformation**
Filter rules narrowing replication so unnecessary traffic doesn't cross the tunnel. Filters run on the production-side sidecar: events that don't match the filter are dropped before transmission, not after. Field-level transformations mask sensitive data (player IDs hashed, payment details redacted) before replication so developers never see raw production PII even though they see production-shaped events. The chapter ships a filter-rule grammar with examples and the transformation library that applies the rules. Audit logging captures every filtered or transformed event for compliance review.

**Chapter 33 · The EchoMQ Dashboard**
A local web UI showing replication health and live activity. Active channels are listed with their throughput. BullMQ queue depths are displayed. A live event stream shows `RedisEvent` messages as they arrive. The dashboard reads from local Redis and tunnel metrics — it's a window into the production data plane without any direct production access. The chapter closes the EchoMQ part by tying replication, filtering, and visibility into a single developer-facing experience.

### Part 7 — Codemoji Operations

**Chapter 34 · The Codemoji Runbook**
Operational procedures specific to Codemoji that go beyond `echo-tunnel`'s generic runbook. Webhook URL switching workflows for moving traffic between developer tunnels and the production handler. Token generation procedures for new developers, including the `new-developer.sh` script and the audit trail it produces. Inspector replay walkthroughs for payment flow debugging — capture, fix, replay, verify. EchoMQ replication health checks. The double-entry ledger reconciliation procedure when a payment flow is interrupted mid-transaction (the most consequential procedure in the runbook, with explicit pre-flight checks).

**Chapter 35 · Codemoji Disaster Recovery**
Recovery procedures specific to Codemoji's data model. Replaying captured webhooks from the inspector after a production handler outage. Reconstructing the ledger from BullMQ job history when Redis state is partially lost. Coordinating Telegram bot webhook reconfiguration during a Fly.io regional outage so payments don't queue against an unreachable endpoint. The decision tree for the most-asked operational question — "is this a tunnel problem or a backend problem?" — with the diagnostic commands for each branch. The chapter closes the series by giving the operator a complete map of what can go wrong and what to do about it.

---

## Shared Appendices

The appendices serve both projects and are designed for non-linear access. Each section is self-contained, ends with a diagnostic command or a copy-paste configuration, and links to the chapter that covers the same material in narrative form.

**Appendix A · Wire Protocol Reference**
Complete message-type definitions across both projects in one place. Base messages from `echo-tunnel`: `Register`, `RegisterAck`, `Request`, `Response`, `Disconnect`, `Ping`, `StreamOpen`, `StreamReady`, `StreamData`, `StreamClose`. Extension messages from `codemoji-tunnel`: `EvalRequest`, `EvalResult`, `EvalStream`, `RedisEvent`, `QueueSnapshot`. Each message has a JSON schema, a wire-format example, and the chapter that introduces it. Versioning rules and backwards-compatibility expectations are stated so future extensions don't break deployed clients.

**Appendix B · DNS and TLS Fundamentals**
A field manual for debugging certificate and DNS issues at 2 AM, written for the on-call engineer who isn't a TLS specialist. DNS record types (A, AAAA, CNAME, TXT, NS, SOA), propagation behavior, and the actual lookup path. The TLS handshake step by step, with the SNI extension that matters most for wildcard certificate serving. Wildcard certificate rules (one level deep, subject alternative names). The ACME protocol (HTTP-01 vs DNS-01, when each works). Certificate chain construction and how missing intermediates manifest as failures. An eight-step debugging checklist with `dig`, `openssl`, and `curl` commands at each step.

**Appendix C · ngrok Feature Parity**
A feature-by-feature comparison between this platform and ngrok's current pricing tiers. Five comparison tables cover the seven requirements from Chapter 1, ngrok-specific features (custom domains, IP restrictions, OAuth integration), pricing per developer at scale, deployment and operational overhead, and migration cost from ngrok to this platform. A decision framework states explicitly when ngrok wins (small teams, no operational appetite, willing to pay the per-developer fee) and when self-hosting wins (multi-developer teams, custom protocol needs, production-adjacent debugging, control over the inspector and replay). Parity is mapped chapter-by-chapter so a reader migrating from ngrok knows which chapters address the features they currently rely on.

**Appendix D · Codemoji Configuration Reference**
Copy-paste configuration files for the Codemoji deployment, kept in one place so an operator never has to grep for a config snippet during an incident. The complete `fly.toml` for `codemoji-edge` with every relevant setting annotated. The `~/.codemoji-tunnel` dotfile template with the variables developers customize. The `echomq.yaml` for replication channel configuration with examples. The `.echo-tasks.exs` for remote Mix tasks. The `vite.config.ts` HMR configuration that makes WebSocket-passthrough development tooling work across the tunnel. An environment-variable reference with defaults and explanations for every setting both projects respect.

---

## Status

This TOC is the source of truth for the chapters' contracts. When a chapter is written, it must satisfy the abstract above; when an abstract changes, prior chapters that reference the changed material may need revision. Updates to this document are made deliberately and announced in the project changelog.
