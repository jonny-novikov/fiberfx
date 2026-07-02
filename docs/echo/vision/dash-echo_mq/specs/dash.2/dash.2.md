# DASH.2 · Drill-down — jobs and groups

> **Status: AUTHORED (pre-build, July 2026).** The forward spec for the second July rung:
> the Jobs view with the inspection panel, and the Groups view over lanes. Stacks on
> dash.1's scaffold, contract suite, and liveness bridge; the canon is the
> [dashboard roadmap](../../../dash.roadmap.md).

## Goal

dash.2 lands the two views an operator reaches for after the wall: **Jobs** — browse the
pending set, open one job's inspection panel (row fields, logs, progress; the LiveView
twin of the ANSI `render_job`, deep-linkable by queue and `JOB` id) — and **Groups** —
the per-group lanes with their depths, the ring's serving order, the paused set, and the
limit / weight / active reads. Both live per visible queue via the dash.1 `Events`
bridge with the poll reconcile, subscriptions tied to the LiveView lifecycle.

## Rationale (5W)

- **Why** — depths say that something is wrong; jobs and groups say what. The ANSI
  dashboard already answers both one terminal at a time (`--job`, `--lanes`); the mock
  already draws both (`views/Jobs.tsx`, `views/Groups.tsx`); the plane already reads
  both. dash.2 is again a join, not an invention.
- **What** — D1 the Jobs view: `Jobs.browse/3` over pending, the state filter on the
  closed set, the inspection panel on `Metrics.get_job/3` + `Jobs.get_job_logs/3` +
  progress, deep-linked at `/queues/:queue/jobs/:id` with the id gated by
  `EchoData.BrandedId.valid?/1` at the route; D2 the Groups view:
  `Dashboard.groups_for/2` + `fetch_lanes/2` + `Metrics.lane_depths/3`, the ring order
  as served, the paused set, and the `glimit` / `gweight` / `gactive` reads; D3 the
  liveness: per-visible-queue `Events` subscription through the dash.1 bridge, reconcile
  tick shared; D4 the contract suite extended to every field these views consume.
- **Who** — the on-call operator triaging a dead job or a starved tenant; the tenant
  owner confirming a pause landed; the bus developer reading the ring's fairness live.
- **Where** — `echo/apps/echo_dash` (dash.1's app); reads via `Metrics`, `Jobs`' read
  verbs, `Events`, the `Dashboard` fetchers; design from the mock's Jobs and Groups
  views.
- **When** — July 2026, closing Movement D-I's month with dash.1.

## Invariants

- **INV1 — dash.1's laws hold whole.** Read-only; no reimplemented read; wire names
  as-built; named absence; bounded staleness.
- **INV2 — the id is gated at the door.** A malformed or wrong-namespace job id in the
  deep link is refused before any read (the series' oldest rule, in a route).
- **INV3 — subscriptions are lifecycle-bound.** Every `Events` subscription opened for a
  view is closed with it; the suite asserts no growth across mount/unmount cycles.
- **INV4 — reads stay proportionate.** The Jobs view pages `browse/3`; no view scans a
  queue unbounded.

## Gate

The extended contract suite green against the live bench bus; LiveView render tests for
the inspection panel over fixture rows (present, missing, errored); the
mount/unmount subscription assertion; the Playwright smoke extended to both views at
zero console errors.
