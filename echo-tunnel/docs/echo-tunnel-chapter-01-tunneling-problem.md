# `echo-tunnel` Chapter 1 · The Tunneling Problem

---

*In which we name the seven requirements that any serious tunnel must meet, ground each in a concrete failure scenario, and explain why no single requirement is sufficient on its own.*

---

## The Naive Picture

Picture the simplest version of "expose my local server to the internet."

You're developing a web service on your laptop. The service runs on `http://localhost:3000`. You want a third party — a webhook provider, a teammate, a mobile app, a customer demo — to reach it. The naive solution: open a port on your router, configure dynamic DNS, send the resulting `http://your-laptop.dyndns.org:3000` to the third party, and call it done.

This works for exactly the smallest case: a single developer, behind a router they control, exposing a single non-secure HTTP endpoint, to a single trusted recipient, for a single short-lived demo.

It fails for everything else.

It fails when the third party requires HTTPS (most do). It fails when the third party requires a non-self-signed certificate (most do). It fails when your laptop is behind a corporate NAT you can't punch through. It fails when your home ISP blocks inbound port 80 and 443. It fails when your IP address changes and the third party's webhook configuration becomes invalid. It fails when you need a teammate to also expose a service on the same hostname. It fails when the third party signs requests and your reverse proxy reorders headers in a way that breaks signature verification. It fails when your local server crashes and you have no record of what the third party tried to send.

The naive picture, viewed up close, has at least seven failures. Each failure is a requirement. Together, the seven requirements define what a serious tunnel is for.

---

## The Seven Requirements

### 1. HTTPS with a Trusted Certificate

**The requirement.** The tunnel must terminate TLS using a certificate that the third party's TLS validation accepts without intervention. The certificate must be valid for the hostname being accessed, signed by a CA in the third party's trust store, and not expired. Self-signed certificates are not acceptable. Wildcard certificates that don't cover the hostname are not acceptable.

**Why it matters universally.** This is not a Telegram requirement; it's a 2026 internet requirement. Every major webhook provider rejects HTTP. Every modern browser warns aggressively on unprotected connections. Mobile apps using Apple's App Transport Security or Android's Network Security Configuration refuse plain-HTTP connections by default. OAuth 2.0 providers (Google, GitHub, Microsoft) reject HTTP redirect URIs.

The list of services that require HTTPS:

- **Telegram Bot API** — webhook URLs must use HTTPS, no exceptions
- **Stripe** — webhook endpoints require HTTPS in production
- **GitHub Webhooks** — accepts HTTP only with `insecure_ssl=1`, which is documented as a development-only escape hatch
- **Slack** — Slash commands, Events API, and Interactive Components all require HTTPS endpoints
- **Twilio** — webhook URLs for SMS, Voice, and other products must be HTTPS

**Why naive solutions fail.** A dynamic-DNS hostname resolved to a residential IP and serving plain HTTP fails immediately. A self-signed certificate also fails — the certificate authority chain validation rejects it, and there's no way to install your laptop's self-signed root in a third-party SaaS provider's certificate trust store. Even Let's Encrypt's HTTP-01 challenge requires inbound port 80 reachability that residential ISPs and corporate networks frequently block.

**What a tunnel solves.** The tunnel terminates TLS at a publicly-accessible edge with a properly issued certificate. The third party connects to a valid HTTPS endpoint, the connection is terminated at the edge, and the request is forwarded to your laptop over a connection that your laptop initiated outbound (which firewalls allow by default). Let's Encrypt issues the certificate. The DNS-01 challenge type sidesteps the inbound-port-80 problem by validating domain ownership through DNS records.

### 2. Stable URLs Across Sessions

**The requirement.** The hostname your local service is reachable at must persist across tunnel client restarts, laptop sleep cycles, network changes, and software upgrades. If you registered `dev-alice.example.com` last month, it must still resolve to your tunnel today — not to a new randomly-assigned `random-words-12345.example.com`.

**Why it matters universally.** Webhook providers don't tolerate URL churn. Every time the URL changes, you must:

- Update the URL configuration in the third party's dashboard or API call
- Wait for any caching or rate limit on URL updates to clear
- Re-test that the new URL works
- Update any documentation, OAuth callback URLs, or app build configurations that hardcoded the URL

For a single-provider integration, this is annoying. For a project integrating with five webhook providers (payment processor, email service, push notifications, analytics, partner API), it compounds: every tunnel restart requires five URL updates, with five different procedures, in five different dashboards.

**Where naive solutions fail.** Free-tier tunnels with random URLs fail this requirement immediately. ngrok's free tier, Localtunnel's default behavior, Pinggy's free SSH tunnels — all assign a fresh random subdomain on each connection. The cost shows up not in the tunnel itself but in the operational tax of reconfiguring upstream services.

**What a tunnel solves.** Stable URLs are a configuration choice, not a technical limitation. A tunnel with a token-based authentication system can let a developer claim a specific subdomain (e.g., `dev-alice`) and reclaim the same subdomain on every reconnection. The server-side registry tracks the claim by token, not by connection identity.

### 3. WebSocket Passthrough

**The requirement.** When a client opens a WebSocket connection to the tunnel's hostname, the connection must be established end-to-end between the client and the local service. WebSocket frames must flow in both directions through the tunnel without being framed, re-serialized, or decomposed into HTTP request/response cycles.

**Why it matters universally.** WebSocket is the dominant transport for real-time browser-to-server communication in 2026. The use cases:

- **Real-time gameplay** — multiplayer games, collaborative editing, live whiteboarding
- **Live dashboards** — admin panels, monitoring tools, financial trading interfaces
- **Chat applications** — every messaging product, Slack, Discord, customer support tools
- **Frontend HMR** — Vite, Next.js, Webpack DevServer, SvelteKit all use WebSocket for hot module replacement during development
- **GraphQL subscriptions** — `graphql-ws` and Apollo's transport-ws both depend on WebSocket
- **Server-sent events alternatives** — when SSE is insufficient, WebSocket fills the gap
- **Phoenix Channels** — Elixir/Phoenix's real-time framework, used by every BEAM-based real-time application

**Where naive solutions fail.** Tunneling tools that model the world as HTTP request/response break WebSocket. The HTTP-level abstraction means there's no way to express "this connection should be upgraded and then bytes should flow." Hookdeck CLI, for example, is purpose-built for HTTP webhook delivery and explicitly does not support WebSocket. Any tool that buffers full request bodies before forwarding will not work for WebSocket because there is no full body — the connection is open-ended.

**What a tunnel solves.** WebSocket passthrough requires the tunnel to recognize the HTTP `Upgrade: websocket` header, hijack the underlying TCP connection from the standard HTTP handler, establish a corresponding TCP connection to the local service, send the original upgrade request, and bridge bytes bidirectionally. This is implementable in Go using `http.Hijacker`, but it must be a designed feature of the tunnel, not an emergent property.

### 4. Request Inspection with Replay

**The requirement.** Every request flowing through the tunnel must be captured: full request line, all headers, complete body, response status, response headers, response body, and timing. The captures must be browsable through some interface (web UI or API). Any captured request must be replayable against the active tunnel — sending the exact same bytes to the local service as if the original request had just been received.

**Why it matters universally.** Webhook debugging without replay is excruciating. The sequence without replay:

1. Webhook arrives, your handler errors
2. You read the error in your local logs
3. You write the fix
4. You restart your local service
5. You ask the third party to send the webhook again

Step 5 is the killer. For payment webhooks, "send it again" means initiating another payment. For OAuth callbacks, it means logging out and back in. For partner API events, it means coordinating with a partner sandbox or test environment that may have rate limits and cooldown periods. A bad day fixing a webhook handler can include 20 of these cycles, each one taking 5–10 minutes of manual setup just to trigger the event.

The sequence with replay:

1. Webhook arrives, your handler errors
2. You read the captured request in the inspector
3. You write the fix
4. You restart your local service
5. You click "replay" in the inspector

Steps 4 and 5 take seconds.

**Where naive solutions fail.** Most managed tunnels don't capture request bodies. ngrok's inspector at `localhost:4040` is the gold standard for this and one of the reasons developers tolerate ngrok's pricing. Cloudflare Tunnel has no built-in inspector at all. Self-hosted tools like frp, Chisel, and Bore focus on byte forwarding and ship nothing for inspection. The requirement is rare enough that it's a differentiator; common enough that without it, certain workflows (especially payment debugging) become operationally untenable.

**What a tunnel solves.** A tunnel that owns the connection on both sides can capture everything that flows through it. A bounded ring buffer of recent requests, a JSON API for browsing captures, and a replay endpoint that re-sends a captured request through the active tunnel — these are an afternoon's work for someone who has already built the rest of the tunnel. The capability is undervalued because it's invisible until you need it, at which point it's invaluable.

### 5. Raw Body Preservation for HMAC Verification

**The requirement.** When a request body arrives at the tunnel, the bytes that reach the local service must be byte-for-byte identical to the bytes the original sender produced. No JSON re-serialization. No header normalization that affects the body. No transcoding. No whitespace changes.

**Why it matters universally.** Webhook signature verification depends on the raw bytes. Every major webhook provider signs the body with HMAC-SHA256 (or similar) and includes the signature in a header. The receiving server hashes the received body with the shared secret and compares against the signature. If the bytes differ — even by one whitespace character — the hashes don't match and verification fails.

The list of services that use HMAC body-signing for webhooks:

- **Stripe** — `Stripe-Signature` header, HMAC-SHA256 over `timestamp.payload`
- **GitHub** — `X-Hub-Signature-256` header, HMAC-SHA256 over the body
- **Shopify** — `X-Shopify-Hmac-Sha256` header, HMAC-SHA256 over the body
- **Slack** — `X-Slack-Signature` header, HMAC-SHA256 over `v0:timestamp:body`
- **Twilio** — `X-Twilio-Signature` header, HMAC-SHA1 over the URL plus form parameters
- **AppFather** — `X-AppFather-Signature` header, HMAC-SHA256 over `timestamp.body`

In every case, the signature is computed over the raw request body. If your tunnel parses the JSON body, validates it, and then re-serializes it before forwarding to the local service, the re-serialized JSON may have keys in a different order, different whitespace, or different number formatting. The signature verification at the local service will fail. You won't see this failure when testing with curl or Postman — only with real signed webhooks.

**Where naive solutions fail.** Any tunnel that uses an HTTP middleware framework with content-type-aware parsers risks this. Many JavaScript-based tunneling tools fall into this trap because the Express/Fastify/Koa default behavior is to parse JSON bodies. Generic reverse proxies (nginx, Apache) don't have this problem because they treat bodies as opaque byte streams. Tunnels written in Go using `httputil.ReverseProxy` also avoid the problem because the standard library treats bodies as `io.ReadCloser` streams.

**What a tunnel solves.** Treat the body as bytes from edge to local service. Read it once, transport it intact (the wire protocol's serialization can use base64 encoding without affecting the original bytes), and write it to the local service unchanged. This is what `echo-tunnel`'s wire protocol does, and the result is HMAC signatures that verify on the local service exactly as they would in production.

### 6. Sub-Deadline Round-Trip Latency

**The requirement.** The tunnel must add only a small fraction of latency to the request-response cycle. The total round-trip — from external client through tunnel to local service and back — must complete within the deadline imposed by the upstream service.

**Why it matters universally.** Webhook providers impose response deadlines. Miss the deadline and the webhook is treated as failed:

- **Telegram pre-checkout queries** — 10 seconds. Miss it and Telegram cancels the payment with no recovery.
- **Stripe webhooks** — 30 seconds. Miss it and Stripe retries with exponential backoff. After enough failures, the endpoint can be disabled.
- **GitHub webhooks** — 10 seconds. Miss it and the delivery is logged as failed; manual replay is required.
- **Shopify webhooks** — 5 seconds. Miss it and Shopify retries up to 19 times over 48 hours, then disables the webhook.
- **AWS SNS** — 15 seconds. Miss it and the message is retried per the subscription's policy.

The total deadline is shared between the upstream network hop, the tunnel's contribution, the local service's processing, and the response return path. The tunnel's contribution is the variable you can optimize. A poorly-designed tunnel can consume seconds of the deadline; a well-designed tunnel adds latency on the order of the network round-trip between the edge and the laptop, which is typically a small fraction of the deadline.

**Where naive solutions fail.** Tunnels that round-trip through congested public servers (Localtunnel's free tier is the canonical example) can add unpredictable latency that occasionally pushes requests past the deadline. Tunnels with serialization overhead (rare but possible if the wire protocol is poorly designed) add measurable latency. Tunnels that buffer the entire request body before forwarding (also rare in good implementations) double the latency for large bodies.

**What a tunnel solves.** A well-designed tunnel streams bytes through with minimal buffering, runs on infrastructure with predictable latency to the developer's location, and exposes metrics that let you measure the tunnel's contribution to the round-trip. The "measurement methodology" standard in this project (see Chapter 3) means the tunnel ships with a way to measure its own latency rather than fabricating performance claims.

### 7. Multi-Developer Coexistence

**The requirement.** Multiple developers on the same team must be able to use the tunneling system simultaneously. Each developer's tunnel must be isolated from the others — separate subdomains, separate inspectors, separate request streams — without interfering with other developers' work or with production traffic.

**Why it matters universally.** Engineering teams have more than one engineer. The moment your team grows past one person, single-tenant tunneling tools become a coordination problem. Two developers can't both claim `dev.example.com` at the same time. Two developers fighting over a shared webhook URL means one of them can't develop until the other finishes.

**Where naive solutions fail.** ngrok's free tier (1 endpoint) makes multi-developer development impossible without per-developer paid subscriptions. Self-hosted tools like frp can support multiple tunnels, but isolation between developers requires careful configuration of namespaces and access control that the tools don't enforce by default. Most managed tunneling tools price per developer, turning a team of five into five separate subscriptions with five separate billing relationships.

**What a tunnel solves.** A token-based authentication system with namespace policies. Alice's token allows her to claim `dev-alice-*` subdomains; Bob's token allows `dev-bob-*`. The tokens are issued from a shared pool managed by the team's tunnel administrator. Production routes (`api.example.com`, `app.example.com`) are inaccessible to development tokens. Each developer has their own webhook URL, their own inspector view, their own request replay. The infrastructure is shared; the experience is isolated.

---

## Why the Seven Compound

No single requirement is the killer.

If only HTTPS were required, `mkcert` plus a dynamic DNS service would suffice. If only stable URLs were required, ngrok's $8/month Hobbyist tier with a custom domain works. If only WebSocket passthrough were required, frp solves it. If only inspection were required, Hookdeck does it well.

The killer is the conjunction.

A real production-adjacent development workflow involves all seven requirements simultaneously. A team building a Telegram Mini App with payment processing needs HTTPS (Telegram requirement), stable URLs (every webhook URL is configured once), WebSocket passthrough (gameplay), inspection with replay (payment debugging), raw body preservation (HMAC signatures), sub-deadline round-trip (10-second pre-checkout), and multi-developer coexistence (engineering team of any size). A team building a Stripe-integrated SaaS platform needs the same seven, with different specific deadlines and different specific HMAC schemes.

Find a managed tunneling tool that meets all seven. Look honestly. The closest matches each fail on at least one critical capability:

- **ngrok Pro ($20/month)** — meets six. Fails on cost-per-developer when scaled to a team.
- **Cloudflare Tunnel** — meets six. Fails on inspection with replay; the lack of webhook debugging tooling is a daily friction.
- **Hookdeck** — meets five. Fails on WebSocket passthrough (HTTP-only) and is webhook-specific.
- **frp + custom infrastructure** — meets six. Fails on built-in inspection; you'd build it yourself, at which point you've started building this project.

The conjunction is what makes self-hosting attractive. Each requirement is achievable individually with off-the-shelf tools; the combination is rare enough that no off-the-shelf tool delivers it without compromise.

---

## What This Implies for `echo-tunnel`

The seven requirements set the project's scope. Every chapter of `echo-tunnel`'s Part 1 implements one or more of them:

- **Chapter 4** (the smallest useful proxy) addresses requirement 1 indirectly — without a proper reverse proxy, HTTPS termination has nothing to forward to.
- **Chapter 5** (automatic HTTPS) addresses requirement 1 directly via `autocert` for single-domain certificates.
- **Chapter 6** (wildcard routing) addresses requirements 1 and 2 — a wildcard certificate covers all developer subdomains, and the routing layer maintains stable subdomain assignments.
- **Chapter 7** (WebSocket tunnel control plane) addresses requirements 5 and 6 — the wire protocol that preserves bytes and the foundation for low-latency request forwarding.
- **Chapter 8** (multiplexing) addresses requirement 6 — concurrent requests over a single WebSocket connection without head-of-line blocking.
- **Chapter 9** (raw TCP and WebSocket passthrough) addresses requirement 3 — the full WebSocket lifecycle implementation.
- **Chapter 10** (authentication and access control) addresses requirements 2 and 7 — token-based subdomain claims and per-developer namespace isolation.
- **Chapter 11** (observability) addresses requirement 4 — the request inspector with capture and replay.
- **Chapter 12** (resilience) addresses requirement 6 — graceful shutdown and rate limiting that prevent latency spikes during normal operations.

Part 2 (production infrastructure) and Part 3 (operations) extend the seven requirements with capabilities they enable rather than capabilities they directly satisfy: multi-tenant isolation in a database, edge caching for static assets, and operational runbooks for the deployed system.

By the end of `echo-tunnel`'s Part 1, the seven requirements are met. By the end of Part 2, they're met at production scale. By the end of Part 3, they're met with operational confidence.

---

## What's Next

Chapter 2 surveys the market in 2026. It applies the seven-requirement matrix to the major managed tunneling tools (ngrok, Cloudflare Tunnel, Hookdeck, Pinggy, LocalXpose, Localtunnel) and the major self-hosted alternatives (frp, Chisel, Bore). The output is a fact-based analysis of where each tool fits, written without the marketing softening that vendor websites apply.

Chapter 3 makes the build decision explicit. It treats "build vs. buy" as a real engineering trade-off, lists the costs of building (engineering time, operational responsibility, risk of bugs in security-critical code) and the benefits (control, customization, no per-developer fees, no usage limits, complete observability), and gives a framework for applying the decision to projects beyond Codemoji. It does not assume the build decision is right; it explains why it was right for the project that motivated this work.

The reader who finishes Part 0 has the conceptual scaffolding for the rest of the project. The reader who skips Part 0 and jumps straight to Part 1 will have to come back here when a design decision they don't understand makes them ask why.

Either reader is welcome.

→ **Chapter 2 · The Market in 2026**

---

## References

### Repositories

- **anderspitman/awesome-tunneling** — A curated list of tunneling solutions, maintained continuously. The starting point for any market survey.
  https://github.com/anderspitman/awesome-tunneling

- **caddyserver/certmagic** — Automatic HTTPS for Go programs. The library this project uses for ACME certificate provisioning. Reading certmagic's design philosophy informs the approach to TLS taken throughout `echo-tunnel`.
  https://github.com/caddyserver/certmagic

- **coder/websocket** — The WebSocket library used for both the tunnel control plane and gameplay passthrough. Formerly `nhooyr/websocket`; the maintainership transition is documented in the README.
  https://github.com/coder/websocket

### Webhook Provider Documentation

- **Telegram Bot API: Payments** — Defines the 10-second pre-checkout deadline. The most demanding deadline in mainstream webhook ecosystems.
  https://core.telegram.org/bots/payments

- **Stripe Webhooks: Best Practices** — Documents the 30-second response timeout, retry policy, and signature verification scheme. The canonical reference for webhook reliability patterns.
  https://docs.stripe.com/webhooks

- **GitHub Webhooks: About Webhooks** — Documents the 10-second timeout, signature verification with `X-Hub-Signature-256`, and replay capabilities through the GitHub UI.
  https://docs.github.com/en/webhooks/about-webhooks

- **Shopify Webhooks** — Documents the 5-second timeout and the 19-retry-over-48-hours policy. The shortest mainstream deadline.
  https://shopify.dev/docs/apps/build/webhooks

- **Slack: Verifying Requests from Slack** — The HMAC-SHA256 scheme over `v0:timestamp:body`. A clean reference implementation of webhook signature verification.
  https://api.slack.com/authentication/verifying-requests-from-slack

### Standards and RFCs

- **RFC 6455 — The WebSocket Protocol** — The protocol specification. Required reading for understanding what passthrough has to preserve.
  https://www.rfc-editor.org/rfc/rfc6455

- **RFC 8446 — The Transport Layer Security (TLS) Protocol Version 1.3** — The TLS version that all modern certificate-based connections use. Particularly relevant for understanding SNI (Server Name Indication), which is how a single edge proxy can serve certificates for many hostnames.
  https://www.rfc-editor.org/rfc/rfc8446

- **RFC 8555 — Automatic Certificate Management Environment (ACME)** — The protocol that Let's Encrypt and other modern CAs use for certificate issuance. Underpins requirement 1.
  https://www.rfc-editor.org/rfc/rfc8555

- **RFC 9110 — HTTP Semantics** — The current HTTP semantics specification. Section 7.8 on the Upgrade mechanism is the foundation for WebSocket detection.
  https://www.rfc-editor.org/rfc/rfc9110

- **RFC 2104 — HMAC: Keyed-Hashing for Message Authentication** — The original HMAC specification. Every webhook signature scheme in the references above is HMAC with a different hash function.
  https://www.rfc-editor.org/rfc/rfc2104

### Expert Voice

- **Filippo Valsorda, "Subtleties of constant-time comparison"** — Why HMAC verification must use timing-safe comparison, and what happens when it doesn't. Cited frequently throughout this project; required reading for anyone implementing webhook signature verification.
  https://words.filippo.io/constant-time-compare/

- **Thomas Ptacek, "Cryptographic Right Answers" (Latacora)** — The opinionated guide to choosing cryptographic primitives. Validates the HMAC-SHA256 choice that pervades webhook signatures and explains why it's the right answer rather than RSA signatures or JWT.
  https://latacora.micro.blog/2018/04/03/cryptographic-right-answers.html

- **Adrian Cockcroft, "Microservices: Decomposing Applications for Deployability and Scalability"** — The "smart pipes vs. dumb pipes" argument that informs the tunneling philosophy. A tunnel is a smart pipe — it does inspection, it does replay, it does authentication. The dumb-pipe alternative is plain TCP forwarding, which solves none of the seven requirements.
  https://www.infoq.com/articles/microservices-intro/

### Books

- **Sam Newman, "Building Microservices" (2nd ed., O'Reilly, 2021)** — Chapter 5 on inter-service communication covers the gateway and edge proxy patterns. The tunnel sits between the gateway and edge proxy categories — it's an edge proxy that happens to forward to a single backend over a non-standard transport.

- **Martin Kleppmann, "Designing Data-Intensive Applications" (O'Reilly, 2017)** — Chapter 8 on distributed systems failure modes informs how this project thinks about resilience. The tunnel is a distributed system: edge proxy on one side, client on the other, with an unreliable WebSocket between them. Kleppmann's frameworks for partial failures and timeout handling apply directly.

- **Brendan Burns, "Designing Distributed Systems" (O'Reilly, 2018)** — Chapter 6 on the adapter pattern. The tunnel is an adapter: it adapts a publicly-routable HTTP endpoint into a privately-running local service without changing either side. The book's framing clarifies why the tunnel is its own architectural component rather than a feature of the local server or the edge proxy.

- **Michael Nygard, "Release It!" (2nd ed., Pragmatic Bookshelf, 2018)** — Chapter 5 on stability patterns and Chapter 17 on transparency. The circuit breaker, bulkhead, and timeout patterns appear throughout the tunnel implementation. The transparency principle ("the system makes its state visible") is the philosophical foundation for the request inspector and Prometheus metrics.

### Related Reading

- **Anders Pitman, "What I Want from a Tunneling Service"** — The README of `awesome-tunneling`, written as a personal manifesto. The seven requirements in this chapter overlap substantially with Pitman's list; both arrive at similar conclusions through similar reasoning.
  https://github.com/anderspitman/awesome-tunneling#readme
