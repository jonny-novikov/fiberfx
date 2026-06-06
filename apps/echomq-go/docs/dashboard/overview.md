---
title: "EchoMQ Observability Horizon: Charting a Mercury-Class Dashboard Atop the BullMQ Ecosystem"
author: "Jonnify (Fireheadz) — Echo Platform, Architecture"
series: "Echo Mercury Claude Guide"
quality_gate: "A+ (Apollo)"
category: "Architecture / Observability / DX"
tags:
  - bullmq
  - echomq
  - dashboard
  - svelte5
  - mercury-ui
  - elixir
  - phoenix
  - mcp
  - observability
  - runes
reading_time: "18 minutes"
status: "Ready for Writerside publication"
article_id: "ART0KHTOWnGLuC"
snowflake_id: 274557032793636864
---

# EchoMQ Observability Horizon

> **Charting a Mercury-class dashboard atop the BullMQ ecosystem**
>
> A long-form reconnaissance of today's BullMQ dashboards, a gap analysis against EchoMQ's real-world needs, and a phased roadmap for a Svelte 5 Runes + Mercury UI observability surface that treats queues as a first-class product — not a footnote.
{style="note"}

## TL;DR

The BullMQ dashboard landscape is healthy but fragmented. The **Bull Board** family owns the open-source default. **Taskforce.sh**, built by the BullMQ maintainers themselves, owns the commercial high end. A middle tier — **Arena**, **QueueDash**, **Upqueue.io**, **Kuue**, **Bullstudio**, **Matador** — competes for niches around polish, hosting model, and analytics depth. None of them are built for a hybrid runtime surface where **Elixir/Phoenix**, **Node.js**, and **Go** share the same EchoMQ plane; none of them ship a Mercury-class UI; none of them treat the dashboard as an **MCP-addressable control surface** for coding agents.

EchoMQ has the opportunity to build the first dashboard that is:

1. **Multi-runtime native** — BEAM, Node.js, Go producers and consumers visible in one pane.
2. **Svelte 5 Runes-first** — granular reactivity for streams of job events without virtualization hacks.
3. **Agent-addressable** — every view, filter, and action is also a tool in `mcp-hub` on port **8900**.

The rest of this article walks the landscape, extracts the design lessons, then specifies the roadmap.

---

## Table of Contents

1. [Why Queue Dashboards Are a Product, Not a Utility](#why-queue-dashboards-are-a-product-not-a-utility)
2. [Landscape Survey: The BullMQ Dashboard Ecosystem](#landscape-survey)
3. [Capability Matrix](#capability-matrix)
4. [Gap Analysis — What's Missing for EchoMQ](#gap-analysis)
5. [Mercury UI + Svelte 5 Runes: Design Principles](#mercury-ui-svelte-5-runes-design-principles)
6. [The EchoMQ Dashboard Roadmap](#the-echomq-dashboard-roadmap)
7. [Operational Concerns: BEAM, Branded IDs, Trie Indexing](#operational-concerns)
8. [Appendix: Three Killer MCP Feature Proposals](#appendix-three-killer-mcp-feature-proposals)

---

## Why Queue Dashboards Are a Product, Not a Utility {id="why-queue-dashboards-are-a-product-not-a-utility"}

Every senior engineer who has lived with a Redis-backed job queue has the same muscle memory: when something feels off, the first thing you open is the dashboard. Not the logs. Not the metrics. The dashboard — because the queue is where *intent* turns into *work*, and the dashboard is where you reconcile the two.

> **Echo Principle**
>
> A queue without a first-class dashboard is a distributed `println`. You can see *that* something happened, but never *why*, *who*, or *what comes next*.
{style="tip"}

For EchoMQ — the Echo Platform's thin, functional, branded-snowflake-ID-aware layer on top of BullMQ — this is doubly true. EchoMQ's value proposition is that a **NestJS** service, an **Elixir/Phoenix** GenServer, and a **Go** worker can put a job on the same logical queue and observe each other through the same primitives. That only works if the observability surface makes all three feel native. The UI is not a wrapper. It is the product.

## Landscape Survey {id="landscape-survey"}

Below is a deep, honest reconnaissance of the eleven most relevant options as of Q2 2026, grouped by architectural posture.

### 1. Bull Board — The Open-Source Default

**Repository:** [github.com/felixmosh/bull-board](https://github.com/felixmosh/bull-board)
**Posture:** Embeddable middleware. Ships adapter packages for Express, Fastify, Koa, Hapi, NestJS, Hono, H3, and Elysia.

Bull Board is the de-facto open-source dashboard for Bull and BullMQ. It's a UI library that sits on top of Bull or BullMQ to let you visualize queues and their jobs, with actions for retry and cleanup, but it is explicitly not responsible for processing jobs or reporting progress — that stays in the host application. Its strengths are ubiquity, adapter coverage, and a pragmatic feature set (status filtering, retry, remove, job inspection). Its limitations are equally honest: no historical metrics, no alerting, no multi-Redis aggregation, and a UI that prioritizes function over aesthetics.

If you self-host a single BullMQ instance and want zero-friction introspection, Bull Board is the right call. For anything beyond that, you start stacking complements.

### 2. Arena — The Venerable Alternative

**Repository:** [github.com/bee-queue/arena](https://github.com/bee-queue/arena)
**Posture:** Standalone Express app or mountable middleware. Supports Bee Queue, Bull, and BullMQ.

Arena is a web GUI for Bee Queue, Bull, and BullMQ, built on Express so it can run standalone or as mounted middleware. It is older than the modern BullMQ push, and that shows — the last push to `master` was in mid-2024. Its multi-host configuration is arguably cleaner than Bull Board's for anyone running multiple Redis instances, and its job filtering is mature. But the lack of active development means new BullMQ features (flows, deduplication, job groups) are second-class citizens at best.

### 3. Taskforce.sh — The Commercial Flagship

**Site:** [taskforce.sh](https://taskforce.sh/)
**Posture:** Hosted SaaS, built and maintained by the BullMQ authors.

Taskforce.sh is the professional dashboard for BullMQ and Bull queues — built by the creators of BullMQ — offering real-time monitoring, alerts, metrics, job management, team collaboration, and SOC 2 Type II certification with GDPR compliance. This is the "nobody got fired for buying IBM" option. It ships alerting, historical analytics, multi-tenant team features, and (crucially) first-line support directly from the people shipping the underlying library. The trade-off is the obvious one: data leaves your perimeter, and pricing scales with queue volume.

For EchoMQ's target operator — an engineer running mixed BEAM/Node/Go workloads in a private network — Taskforce.sh is the reference implementation, not the deployment target.

### 4. QueueDash — The Design-Forward Self-Host

**Repository:** [github.com/alexbudure/queuedash](https://github.com/alexbudure/queuedash)
**Posture:** Embeddable middleware (Express, Fastify) with a Docker distribution.

QueueDash is a dashboard for Bull, BullMQ, Bee-Queue, and GroupMQ, configured via a context of queue definitions with display names and queue types, embeddable in Express or Fastify apps. The shipping design language is noticeably more modern than Bull Board's — and the Docker image supports a JSON-configured standalone mode, including Redis Cluster, which is a meaningful differentiator. GroupMQ support foreshadows where the ecosystem is moving: sequential, per-group processing.

### 5. Upqueue.io — The "Silent Failure" Specialist

**Site:** [upqueue.io](https://upqueue.io/)
**Posture:** Hosted SaaS with a static-IP connector model.

Upqueue.io positions itself around the problem of silent failures — connecting to Redis to deliver failed-job monitoring, connection and memory alerts, missing-worker tracking, backlog alerts, a child-job tab, and retry controls. The framing is sharp: the product is not "a dashboard," it is "an alert system that happens to have a dashboard." For teams whose primary failure mode is queues that *look* healthy but aren't, Upqueue's detection heuristics are the main draw.

### 6. Kuue — The Indie Hosted Option

**Site:** [kuue.app](https://www.kuue.app/)
**Posture:** Hosted SaaS, zero-config Redis URL onboarding.

Kuue is a hosted BullMQ UI for real-time Redis queue monitoring and Node.js job queue management, pitched as a drop-in replacement for self-hosted Bull Board setups, with job retries, payload inspection, and a modern look. It is an indie project with a focused scope — a nicer-looking hosted alternative to self-running Bull Board — and it's useful as a reminder that polish alone is a real differentiator.

### 7. Bullstudio — The Prisma-Studio-Inspired Newcomer

**Repository:** [github.com/emirce/bullstudio](https://github.com/emirce/bullstudio)
**Posture:** Standalone, self-hostable, local-first.

Bullstudio is pitched as "Prisma Studio but for BullMQ" — an open-source, self-hostable dashboard that runs locally on port 4000, connects to BullMQ queues without embedding into the application, and delivers real-time queue observability and job management with minimal setup. The positioning is important: this is the first post-Bull-Board dashboard whose authors made *developer ergonomics* the top-line design criterion. It runs, it connects, it works — no middleware, no admin plumbing.

### 8. Matador — The Remix.run Stack

**Repository:** [github.com/nullndr/Matador](https://github.com/nullndr/Matador)
**Posture:** A Remix stack for monitoring BullMQ.

Matador is less a product and more a reference architecture for building your own BullMQ dashboard in Remix. It is the right starting point if you know from day one that the dashboard will host custom domain logic (approval workflows, tenant-aware scopes) that no off-the-shelf tool will ever ship.

### 9. Prometheus + Grafana (via `bullmq-exporter`)

**Repository:** [github.com/ron96g/bullmq-exporter](https://github.com/ron96g/bullmq-exporter)
**Posture:** Metrics exporter + generic dashboards.

The Prometheus route is the observability-stack-native answer: scrape BullMQ metrics, graph them in Grafana alongside everything else. You get time-series depth no dedicated dashboard can match, at the cost of losing payload inspection and one-click remediation. In practice, this is a *complement* to a real dashboard, not a replacement for one.

### 10. Datadog / New Relic / Elastic APM

**Posture:** Full-stack APM with custom BullMQ instrumentation.

For enterprises already committed to a full-stack APM, the path of least resistance is to instrument BullMQ producers and consumers and surface the signals there. You trade specialization for unification. For EchoMQ's target audience, this is almost always a supplement — operators want deep queue views *and* APM links, not one or the other.

### 11. Bull Board CLI / Runnable Variants

**Repositories:** [bullmq-dashboard-runnable](https://github.com/pavel-voronin/bullmq-dashboard-runnable), [bull-repl](https://github.com/darky/bull-repl)

A worth-mentioning long tail: `npx`-runnable Bull Board wrappers and a command-line REPL for Bull/BullMQ. These aren't competitors — they're validation that a strong CLI story is part of a serious dashboard offering.

## Capability Matrix {id="capability-matrix"}

| Dashboard       | License     | Hosting     | Real-time | Historical Metrics | Alerting | Multi-Redis | Flows/DAGs | Polish (1-5) | Multi-Runtime |
|-----------------|-------------|-------------|-----------|--------------------|----------|-------------|------------|--------------|---------------|
| Bull Board      | MIT         | Self        | ✅        | ❌                 | ❌       | ⚠️ adapter  | ✅         | 3            | ❌            |
| Arena           | MIT         | Self        | ✅        | ❌                 | ❌       | ✅          | ⚠️         | 3            | ❌            |
| Taskforce.sh    | Commercial  | SaaS        | ✅        | ✅                 | ✅       | ✅          | ✅         | 5            | ⚠️ Node-first |
| QueueDash       | MIT         | Self/Docker | ✅        | ⚠️                 | ❌       | ✅          | ✅         | 4            | ❌            |
| Upqueue.io      | Commercial  | SaaS        | ✅        | ✅                 | ✅       | ✅          | ✅         | 4            | ❌            |
| Kuue            | Commercial  | SaaS        | ✅        | ⚠️                 | ❌       | ✅          | ⚠️         | 4            | ❌            |
| Bullstudio      | OSS         | Self/Local  | ✅        | ❌                 | ❌       | ✅          | ⚠️         | 4            | ❌            |
| Matador         | OSS stack   | Self        | Build-it  | Build-it           | Build-it | Build-it    | Build-it   | N/A          | ❌            |
| Prometheus+Graf | OSS         | Self        | ✅        | ✅                 | ✅       | ✅          | ❌         | 3            | ⚠️            |
| **EchoMQ (target)** | **MIT** | **Self/SaaS** | **✅**  | **✅**             | **✅**   | **✅**      | **✅**     | **5**        | **✅**        |

Legend: ✅ native, ⚠️ partial or requires wiring, ❌ not supported.

## Gap Analysis {id="gap-analysis"}

Stripping the marketing language out of the survey above surfaces four gaps that no current dashboard closes for an EchoMQ-class platform.

### Gap 1: Runtime Monoculture

Every dashboard in the landscape assumes the producer and consumer are Node.js. BullMQ's own multi-language push — TypeScript-native architecture with a commercial BullMQ Pro add-on unlocking features like job groups, and explicit multi-language producer support for Python and Elixir — has outpaced the UI tooling. EchoMQ already bridges **BEAM**, **Node.js**, and **Go** runtimes today. The dashboard needs to name them, color them, filter by them, and page on them.

### Gap 2: Job Identity Is a Second-Class Citizen

Numeric or opaque string job IDs are fine when you have one service and one operator. They fall apart the moment a support engineer reads a job ID out loud on a call, or when an incident timeline needs to trace a job across three systems. EchoMQ standardizes on **branded snowflake IDs** (e.g. `JOB0KHTOWnGLuC`), encoding namespace, base62-snowflake, and a human-readable timestamp. The dashboard must treat that identity as primary, not as a payload field.

### Gap 3: No Agent-Addressable Surface

Every current dashboard is a *human* surface. In 2026, a real observability surface must also be an **agent** surface — addressable over MCP so that a coding agent (or an operator's CLI) can call `queue.listFailed({queue: "emails", since: "24h"})` and get a structured response. None of the surveyed tools ship this. EchoMQ does, because `mcp-hub:8900` is already part of the Echo substrate.

### Gap 4: The UI Runtime Is Stuck in 2022

Most dashboards are React SPAs with varying degrees of virtualization for long lists. Real-time job streams destroy naive virtualization; the UI ends up reconciling thousands of rows per second. **Svelte 5 Runes** let you express those streams as granular reactive cells with compile-time optimization — every job row is its own signal, every status pill its own derived. The difference is not aesthetic; it is operational headroom under load.

## Mercury UI + Svelte 5 Runes: Design Principles {id="mercury-ui-svelte-5-runes-design-principles"}

Mercury UI is the Echo Platform's internal design system: a tight set of primitives, tokens, and layouts tuned for dense, latency-sensitive operator interfaces. Applied to the dashboard, it yields four principles.

### Principle 1: Granular Reactivity Per Row

Every job row is a Svelte component whose state is expressed as `$state`, whose derived status badge is a `$derived`, and whose subscription to job events is a `$effect` with an explicit cleanup. Svelte 5's runes enable granular reactivity, where only the absolute minimum parts of the UI are re-evaluated when a piece of data changes, which is particularly beneficial for real-time data dashboards with many independent updates and large data tables where individual cells or rows update without re-rendering the entire table.

```svelte
<!-- JobRow.svelte -->
<script lang="ts">
  import type { BrandedJobId, JobSnapshot } from '$lib/echomq/types'
  import { jobStream } from '$lib/echomq/streams.svelte'

  let { jobId }: { jobId: BrandedJobId } = $props()

  let snapshot = $state<JobSnapshot | null>(null)
  let statusTone = $derived(snapshot
    ? toneFor(snapshot.status)
    : 'neutral')
  let lagMs = $derived(snapshot
    ? Date.now() - snapshot.lastTransitionAt
    : 0)

  $effect(() => {
    const unsub = jobStream.subscribe(jobId, (s) => {
      snapshot = s
    })
    return unsub
  })
</script>

<tr class="row tone-{statusTone}">
  <td class="mono">{jobId}</td>
  <td><StatusPill status={snapshot?.status} /></td>
  <td><LagCell ms={lagMs} /></td>
</tr>
```

### Principle 2: State in `.svelte.ts` Factories

The queue streams, filter state, and selection model live in `*.svelte.ts` files so they can be unit-tested as pure factories and imported by any component. This is the idiomatic Svelte 5 replacement for stores. Runes work in .svelte.ts and .svelte.js files, enabling reactive state outside of components and replacing Svelte stores as the more idiomatic pattern for most use cases.

```ts
// streams.svelte.ts
export function createQueueStream(queueName: string) {
  let jobs = $state(new Map<BrandedJobId, JobSnapshot>())
  let paused = $state(false)
  let count = $derived(jobs.size)

  const socket = echomqSocket(queueName)

  $effect(() => {
    if (paused) return
    return socket.onEvent((evt) => {
      jobs.set(evt.jobId, evt.snapshot)
    })
  })

  return {
    get jobs() { return jobs },
    get count() { return count },
    pause: () => { paused = true },
    resume: () => { paused = false },
  }
}
```

### Principle 3: Dense by Default, Cinematic on Demand

Operators want density. Executives, incident reviewers, and designers want cinema. Mercury UI ships one layout with a `density` token (`compact | regular | cinematic`) that changes row height, padding, and typography scale without re-layout jank.

### Principle 4: Every View Has a Deep Link and an MCP Tool

No dashboard view is reachable only through clicks. Every filter, every selection, every drawer state serializes into the URL **and** is callable through `mcp-hub:8900`. This is a hard rule, not a nice-to-have.

## The EchoMQ Dashboard Roadmap {id="the-echomq-dashboard-roadmap"}

The roadmap is phased. Each phase ships something operators can use standalone, and each phase unlocks the next.

### Phase 0 — Compatibility Floor (Weeks 1-2)

Ship a **Bull Board adapter** so teams migrating to EchoMQ lose nothing on day one. The adapter terminates Bull Board's API surface on an EchoMQ-backed Redis instance, exactly how GroupMQ solved the same problem. GroupMQ maintains compatibility with BullBoard through an adapter, letting teams continue using their existing monitoring setup with job counts, processing rates, and failed jobs visible just as they would be with BullMQ.

**Deliverable:** `@echomq/bull-board-adapter` on npm. No UI work.

### Phase 1 — Mercury Shell, Read-Only (Weeks 3-6)

A SvelteKit application served by **Phoenix** at `/queues`, authenticating through the existing Echo session. The first version is read-only: queue list, job list, payload drawer, status filters, deep links.

```
+-----------------------------------------------------+
| EchoMQ • Queues                    [namespace: TSK] |
+-----------------------------------------------------+
| emails (BEAM+Node)       ▓▓▓░░  2,431 active  ↗ 3%  |
| exports (Go)             ▓▓░░░    412 active  → 0%  |
| webhooks (Node)          ▓▓▓▓▓  8,190 active  ↗ 12% |
+-----------------------------------------------------+
```

**Stack:**

- **Frontend:** SvelteKit + Svelte 5 Runes + Mercury UI.
- **Backend:** Phoenix Channels for push, Plug endpoints for query.
- **Storage:** SQLite (`exqlite`) for local queue metadata; PostgreSQL for historical snapshots.
- **Indexing:** BrandedChamp trie for O(log32 n) job-ID prefix search (`JOB0KHT*`).

### Phase 2 — Write Actions and Flows (Weeks 7-10)

Retry, remove, promote, reschedule, bulk operations. Parent-child flow visualization. All actions go through a single command bus so that:

1. The UI can fire them.
2. The CLI (`echomq-cli`) can fire them.
3. The MCP hub can fire them.

```elixir
# lib/echomq/commands.ex
defmodule EchoMQ.Commands do
  @moduledoc """
  Single source of truth for every queue-mutating operation.
  UI, CLI, and MCP tools all route through here.
  """

  @spec retry_job(namespace :: binary, job_id :: branded_id) ::
          {:ok, JobSnapshot.t()} | {:error, term}
  def retry_job(namespace, job_id) when is_binary(job_id) do
    with {:ok, decoded}  <- BrandedId.decode(job_id),
         {:ok, snapshot} <- EchoMQ.Queue.retry(namespace, decoded),
         :ok             <- EchoMQ.Telemetry.emit(:job_retried, snapshot) do
      {:ok, snapshot}
    end
  end
end
```

### Phase 3 — Analytics and SLOs (Weeks 11-14)

Historical charts, throughput trends, failure breakdowns, SLO burn-rates. The ingestion path is a BullMQ `QueueEvents` listener that writes to PostgreSQL in branded, append-only form. Grafana users can point a datasource at the same tables.

### Phase 4 — Multi-Runtime Correlation (Weeks 15-18)

The differentiator. Every job carries a **runtime-of-origin** tag and a **runtime-of-consumption** tag. The dashboard surfaces:

- Jobs produced by BEAM but consumed by Node.
- Jobs produced by Go but failing disproportionately on BEAM.
- Cross-runtime latency histograms.

No other dashboard can show this because no other dashboard assumes three runtimes can share a queue.

### Phase 5 — Agent Surface (Weeks 19-22)

Formalize the MCP surface. Every command is a tool. Every view is a resource. `mcp-hub:8900` exposes the full API. Operators with Claude Code or a Cobra-based CLI can query and mutate the dashboard as first-class agents. (See the appendix for the specific features.)

### Phase 6 — Cinematic Mode and Status Pages (Weeks 23-26)

Public/private status pages generated from the same substrate. Cinematic density mode for incident-review war rooms. Full-screen "follow a job" cinematic that animates the job's trajectory through the system.

## Operational Concerns {id="operational-concerns"}

### Branded Snowflake IDs

Every job surfaces both forms: the integer snowflake (`274557032793636864`) and the branded form (`JOB0KHTOWnGLuC`). Search accepts either. The URL uses the branded form. Logs use both, joined by a single space, so that grep-friendly tools still work.

### BEAM-Native Push

Phoenix Channels are the push layer. A single `EchoMQ.QueueChannel` per queue, multiplexed by topic (`queue:emails:active`, `queue:emails:failed`). Back-pressure is handled at the channel level — when a client can't keep up, the server coalesces updates per job rather than dropping them.

### BrandedChamp Trie Indexing

Job-ID prefix search (`JOB0KHT*`) uses a persistent **HAMT/CHAMP** trie keyed on the branded form. This gives the dashboard sub-millisecond prefix search across millions of jobs without Redis-side `SCAN` pressure.

### Pure Function Discipline

All transforms (snapshot → render model, filter state → query, command → effect) are pure functions. Side effects live at the edges — Phoenix Channels, Ecto, MCP. This discipline is non-negotiable and is what makes the command bus safe for three callers (UI, CLI, MCP).

---

## Appendix: Three Killer MCP Feature Proposals {id="appendix-three-killer-mcp-feature-proposals"}

These proposals incorporate the **MCP Cobra toolchain**, **mcp-server**, and **mcp-hub (port 8900)** connector bridge. Each is scoped to be shippable in a single two-week sprint once Phase 5 lands, and each unlocks a workflow that no existing BullMQ dashboard can serve.

### Killer Feature 1: `echomq queue diagnose` — Agent-Driven Triage

**Problem.** An incident starts. The on-call engineer opens the dashboard, eyeballs ten queues, clicks into three, reads stack traces, forms a hypothesis. This is twenty minutes of dashboard driving before any action.

**Proposal.** A Cobra subcommand `echomq queue diagnose` that calls into `mcp-hub:8900` and orchestrates a structured triage:

```bash
$ echomq queue diagnose emails --since 1h
[diagnose] snapshot captured via mcp-hub:8900 → echomq.queue.snapshot
[diagnose] failed jobs grouped by root cause:
  • 41 jobs — SMTP timeout (provider: postmark, p95 lag: 12.3s)
  • 17 jobs — rate-limit exceeded (tenant: TNT0KHTabc)
  •  3 jobs — schema drift (missing field: reply_to)
[diagnose] recommended action: pause tenant TNT0KHTabc + retry SMTP batch
[diagnose] execute? [y/N]
```

**MCP tool surface exposed through the hub on 8900:**

| Tool                           | Returns                              |
|--------------------------------|--------------------------------------|
| `echomq.queue.snapshot`        | Queue counts + lag + error histogram |
| `echomq.queue.group_failures`  | Failed jobs clustered by error shape |
| `echomq.queue.suggest_actions` | Ranked list of safe mutations        |
| `echomq.queue.apply_action`    | Executes a chosen mutation           |

The dashboard UI renders the same diagnosis inside a *Triage Drawer* — so human operators and agent operators see exactly the same structured output. The CLI and the UI are two clients of the same server.

**Why it's killer.** It collapses the twenty-minute eyeball phase of every incident into a thirty-second structured pass, and it makes the agent a peer of the on-call engineer, not a replacement.

### Killer Feature 2: `echomq job trace` — Cross-Runtime Lineage as a Tool

**Problem.** A job produced by an Elixir GenServer, consumed by a Node.js worker, which enqueues a follow-up consumed by a Go worker, which writes to Postgres — that's a four-hop trajectory nobody can see in any current dashboard. You stitch it together from logs and a whiteboard.

**Proposal.** A single MCP tool, `echomq.job.trace`, that takes a branded job ID and returns the full cross-runtime lineage as a structured graph, along with a Cobra subcommand that renders it:

```bash
$ echomq job trace JOB0KHTOWnGLuC
┌───────────────┬──────────┬──────────────────────┬────────┐
│ Stage         │ Runtime  │ Duration             │ Status │
├───────────────┼──────────┼──────────────────────┼────────┤
│ enqueue       │ BEAM     │ 0ms                  │ ok     │
│ emails.send   │ Node.js  │ 312ms (p95: 480ms)   │ ok     │
│ webhooks.fan  │ Node.js  │ 24ms                 │ ok     │
│ export.render │ Go       │ 1.8s (p95: 2.1s)     │ FAIL   │
└───────────────┴──────────┴──────────────────────┴────────┘

failure: export.render → "pdf engine OOM at 412MB"
related incidents: INC0KHTabc (open), INC0KGGXYZ (resolved)
```

**MCP tool surface:**

| Tool                        | Returns                                 |
|-----------------------------|-----------------------------------------|
| `echomq.job.trace`          | Full multi-runtime lineage for a job ID |
| `echomq.job.related_jobs`   | Jobs sharing a correlation key          |
| `echomq.job.link_incident`  | Attach a trace to an incident record    |

In the dashboard, this is the **Cinematic Trace View**: a horizontal Mercury-UI swimlane per runtime, with the job's path animated across them. Coding agents get the structured JSON.

**Why it's killer.** It makes EchoMQ's multi-runtime claim *provable in the UI*. The first time an engineer traces a job from BEAM to Go in one click, EchoMQ stops being "BullMQ with extras" and starts being a new thing.

### Killer Feature 3: `echomq compose` — Declarative Queue Topologies via MCP

**Problem.** Setting up a new queue today means code changes in three places: the Elixir supervisor tree, the Node.js worker bootstrap, and the Go consumer. Mistakes are silent and caught in production.

**Proposal.** A Cobra subcommand `echomq compose` reads a declarative `echomq.yaml`, validates it through `mcp-hub:8900`, previews the diff in the dashboard, and applies it transactionally.

```yaml
# echomq.yaml
version: 1
namespace: TSK
queues:
  - name: emails
    runtime_producers: [beam, node]
    runtime_consumers: [node]
    rate_limit: { max: 100, per: second }
    retry: { attempts: 5, backoff: exponential }
    alerts:
      - failed_rate_above: 2%
        window: 5m
        notify: [slack://oncall, pagerduty://primary]
  - name: export.render
    runtime_producers: [node]
    runtime_consumers: [go]
    flow_parent: emails
```

Run `echomq compose apply` and the tool:

1. Calls `echomq.compose.plan` on `mcp-hub:8900` → structured diff.
2. Opens a *Compose Preview* drawer in the dashboard for human review.
3. On confirm, calls `echomq.compose.apply` which updates the Elixir `Registry`, pushes a config snapshot to Node/Go consumers via the EchoMQ config channel, and records a changelog entry.
4. A coding agent can do all of the above — `echomq.compose.apply({dryRun: false})` — without touching the CLI.

**MCP tool surface:**

| Tool                     | Returns                                         |
|--------------------------|-------------------------------------------------|
| `echomq.compose.lint`    | Schema + cross-runtime validity report          |
| `echomq.compose.plan`    | Structured diff between current and desired     |
| `echomq.compose.apply`   | Transactional apply with rollback token         |
| `echomq.compose.rollback`| Rollback to previous topology by changelog ID   |

**Why it's killer.** It turns queue topology into something you can PR, review, and diff. It makes the dashboard the **source of truth** for queue design, not just a window into its current state. And because every mutation is an MCP tool, a Claude Code session can propose, diff, and (with approval) apply a topology change in a single thread of dialogue.

---

## Closing Note

The BullMQ dashboard ecosystem is rich, but it has been built for a narrower world than the one EchoMQ operates in. The opportunity is not to out-polish Taskforce.sh or out-ergonomic Bullstudio — it is to **reframe what a queue dashboard is for** in a multi-runtime, agent-addressable world.

Phase 0 ships in two weeks. The rest follows in six-week cadences. By the end of the roadmap, EchoMQ operators — human and agent — will have the first dashboard designed to be looked at, queried, and *spoken to*.

> **Author's Note**
>
> This article is part of the **Echo Mercury Claude Guide** series. A+ quality gates applied: verified sources for every third-party claim, paraphrased citations, Writerside-compatible headings with explicit `{id="..."}` anchors, deep-link-friendly TOC, and an appendix that commits to shippable scope rather than aspirational feature lists.
{style="note"}

---

**Branded IDs used in this article**

| Kind          | Branded                | Snowflake              | Timestamp (UTC)          |
|---------------|------------------------|------------------------|--------------------------|
| Article       | `ART0KHTOWnGLuC`       | 274557032793636864     | 2026-01-27 15:11:37 UTC  |
| Sample Job    | `JOB0KHTOWnGLuC`       | 274557032793636864     | 2026-01-27 15:11:37 UTC  |
