# Roadmap — the EchoMQ Dashboard { id="echo_mq-dash-roadmap" }

> _The operator dashboard as its own program: a Phoenix LiveView application consuming the bus's stable read plane — never adding to it. The bus roadmap ([emq4](emq4.roadmap.md)) rules the dashboard out of the bus's scope and names the read plane it must keep stable; this roadmap is the other side of that boundary. Rung prefix `dash`; specs under [`specs/dash1/`](specs/dash1/dash.1/dash.1.md)._

## Where the alpha stands (as-built at `0c0fd19`)

The "alpha stage" the bus roadmap records resolves, at this revision, to two shipped
surfaces and one design source — none of them yet a Phoenix application:

- **The terminal alpha — `EchoMQ.Dashboard` + `mix echo_mq.dashboard`.** A cat-able,
  read-only ANSI operator dashboard split into a pure renderer (`render_depths/2`,
  `render_lanes/2`, `render_job/4`, `render_no_queues/1`, `frame/2` — testable without
  Valkey) and live-fetch orchestration (`discover_queues/1`, `fetch_depths/2`,
  `groups_for/2`, `fetch_lanes/2`, `fetch_job/3`) that delegates every read to the
  as-built `EchoMQ.Metrics` plane. Its laws are the program's laws: reimplement no read,
  open no new wire, write nothing, and name the empty and error cases rather than fake a
  confident zero.
- **The read plane the bus keeps stable.** `EchoMQ.Metrics` (the pure reads: counts on
  the closed six-state set, job rows, lane depths, rate-gate reads), `EchoMQ.Events`
  (the per-queue lifecycle pub/sub on `emq:{q}:events`, reconnect-safe), `EchoMQ.Meter`
  (the `[:emq, …]` telemetry surface, zero-cost when `:telemetry` is absent), and the
  Stream Tier read verbs. The bus's contract with this program is exactly these.
- **The design source — the Mercury mock.** `mercury/apps/echomq` is the dark-first
  React port of the dashboard design: five views (Overview · Jobs · Groups · Batches ·
  Processors), the chrome (Sidebar, Topbar, MetricStrip, FlowRowCard), the throughput
  and donut charts — on static `data.ts`. Design flows from it; data does not.

The distance to close is therefore precise: put a Phoenix LiveView application behind
the mock's design, fed by the read plane, under the ANSI dashboard's laws.

## The boundary law (master invariant)

**The dashboard is a consumer of the bus, never an author of it.** Every read rides
`Metrics` / `Events` / `Meter` / the `Dashboard` fetch helpers / the Stream read verbs;
no key is composed outside `EchoMQ.Keyspace`; no write verb is reachable from the UI
until Movement D-III gates one. A read the dashboard needs and the plane lacks is a
**bus runway item** ruled on the bus's roadmap — the dashboard never pokes the keyspace
to route around a missing verb. This is the emq4 boundary read from the other side.

## The movements

### Movement D-0 · Foundation — in place

The terminal alpha, the read plane, and the Mercury design source above. Nothing to
build; everything below stands on it.

### Movement D-I · The live wall — July 2026 (this month)

- **dash.1 — the application and the contract** ([triad](specs/dash1/dash.1/dash.1.md)).
  The `echo_dash` Phoenix LiveView app scaffolded read-only inside the umbrella; the
  **read-plane contract suite** — the dashboard's conformance, pinning every consumed
  field against a live bus so a bus rung cannot silently break the UI; the **Overview**
  live view (queue discovery, the six-state depths wall in the house palette, the
  throughput strip) on push-with-poll-reconcile; the Mercury dark-first tokens ported.
- **dash.2 — drill-down: jobs and groups** ([triad](specs/dash1/dash.2/dash.2.md)).
  The **Jobs** view (browse, the job inspection panel with logs and progress — the ANSI
  `render_job` twin, deep-linkable) and the **Groups** view (lanes, the ring order,
  paused set, limit/weight/active reads), live per visible queue via `Events` with the
  poll reconcile, subscription lifecycle tied to the LiveView mount.

Exit gate for the movement: both rungs' contract suites green against a live Valkey,
LiveView render tests over fixture maps (the pure-renderer discipline carried over),
and a Playwright smoke at zero console errors — the mercury ports' precedent.

### Movement D-II · Depth — August 2026

- **dash.3 — batches and flows.** The Batches view on the `BAT` progress counters and
  `BatchFinish`; the flow (parent/children) read via the declared `:dependencies` /
  `:processed` subkeys.
- **dash.4 — the stream wall.** Stream depth, consumer groups, PEL and delivery counts,
  the retention and archive watermark — the Stream Tier made visible, including what
  `StreamArchive` has folded to the floor.
- **dash.5 — processors.** The consumers made visible. First arm: read the
  `Metronome`'s idle registrations plus `Meter` lifecycle aggregation; if a true
  presence read is ruled necessary, it is a bus runway item (seam DASH-C), not a
  dashboard invention.

### Movement D-III · Operate — September 2026

- **dash.6 — the gated write half.** `Admin.pause/resume/drain`, `reprocess_job`,
  `remove_job` behind an explicit, opt-in ops mode with confirmation — the dashboard
  stays read-only by default (the library law's UI form). Auth and deployment beside
  the bus on Fly close the movement.

## Cross-cutting laws

- **No invented data.** The empty bus, a missing job, and a per-queue read error render
  as named states — the ANSI dashboard's law, verbatim, in LiveView.
- **Wire names honored as-built.** The state set is the closed
  `pending · active · schedule · dead · completed · failed` — "schedule" is the wire's
  set name, distinct from the `:scheduled` job-state atom; the UI displays both
  faithfully and "fixes" neither.
- **Push first, poll to reconcile.** `Events` drives liveness; a slow tick re-reads
  `Metrics` so a dropped pub/sub message costs staleness bounded by the tick, never a
  wrong number held forever.
- **Design flows down.** The Mercury mock is the visual canon; the LiveView port
  consumes its tokens and layout, and visual changes land in the mock first.

## Seams & open decisions

| Seam | The fork | Arms (brief) | Venus recommends |
|---|---|---|---|
| **DASH-A · the app's home** | where the Phoenix app lives | A1 umbrella sibling `echo/apps/echo_dash` · A2 a standalone repo app · A3 inside `codemojex_web` | **A1** — one boot, the read plane in-cluster, and the product app stays uncoupled from operator tooling |
| **DASH-B · liveness transport** | how the wall stays live | B1 `Events` pub/sub only · B2 poll only · B3 push with a poll reconcile tick | **B3** — pub/sub is at-most-once by substrate; the tick bounds staleness without hammering the wire |
| **DASH-C · processors presence** | where "who is consuming" comes from | C1 `Metronome` registrations + `Meter` aggregation · C2 a new bus presence verb | **C1** first — spend shipped surfaces; C2 goes to the bus runway only if C1 proves blind |
| **DASH-D · the write gate** | how Movement D-III arms operator verbs | D1 opt-in ops mode + per-action confirm · D2 always-on with auth only | **D1** — read-only is the default posture; the write half is a deliberate, visible switch |

## This month — July 2026

Two rungs, in order, each with its authored triad (spec · stories · runbook):

| Rung | Ships | Triad |
|---|---|---|
| dash.1 | `echo_dash` scaffold · read-plane contract suite · Overview live · tokens | [spec](specs/dash1/dash.1/dash.1.md) · [stories](specs/dash1/dash.1/dash.1.stories.md) · [runbook](specs/dash1/dash.1/dash.1.prompt.md) |
| dash.2 | Jobs view + inspection panel · Groups view · per-queue live push | [spec](specs/dash1/dash.2/dash.2.md) · [stories](specs/dash1/dash.2/dash.2.stories.md) · [runbook](specs/dash1/dash.2/dash.2.prompt.md) |

dash.1 opens the month because the contract suite it ships is the gate every later rung
(and every bus rung touching the read plane) runs against; dash.2 lands the two views
operators reach for first. The movement's exit gate above closes the month.
