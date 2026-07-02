# DASH.1 · The application and the contract — Movement D-I opens

> **Status: AUTHORED (pre-build, July 2026).** The forward spec for the rung that opens the
> dashboard program: the `echo_dash` Phoenix LiveView application, the read-plane contract
> suite, and the Overview live wall. The canon it binds to is the
> [dashboard roadmap](../../../dash.roadmap.md) (the boundary law, seams DASH-A/B) and the
> bus's [emq4 boundary note](../../../emq4.roadmap.md) (the read plane the bus keeps stable).

## Goal

dash.1 puts a Phoenix application behind the shipped read plane without adding to it: an
`echo_dash` umbrella app (seam DASH-A, arm A1) that boots read-only beside the bus; a
**read-plane contract suite** that pins every field the UI consumes against a live bus, so
the dashboard owns a conformance gate the way the bus owns `EchoMQ.Conformance`; and the
**Overview** live view — queue discovery, the six-state depths wall in the house palette,
the throughput strip — live by push with a poll reconcile (seam DASH-B, arm B3), on the
Mercury mock's dark-first tokens.

## Rationale (5W)

- **Why** — the bus roadmap rules the dashboard out of the bus's scope and freezes its
  responsibility at the read plane; the terminal alpha (`EchoMQ.Dashboard` + the mix task)
  proves the reads and the rendering laws but serves one operator at one terminal. The
  Mercury mock fixes the design with no data behind it. dash.1 is the join: the mock's
  design, the alpha's laws, the plane's data, one LiveView surface.
- **What** — D1 the `echo_dash` app scaffold (Phoenix LiveView, deps `echo_mq` and
  `echo_wire` only, no Ecto, no write verb reachable); D2 the contract suite
  (`EchoDash.Contract` tests: the closed state set of `Metrics.get_counts/3`, the
  `get_job/3` row fields, `lane_depth(s)/3` shapes, the `Events` payload event names —
  each asserted against a live Valkey); D3 the Overview live view fed by
  `EchoMQ.Dashboard.discover_queues/1` + `fetch_depths/2`, refreshed by an `Events`
  subscription per queue and reconciled by a slow `Metrics` tick; D4 the Mercury tokens
  ported (dark-first) with the Overview mapping one-to-one onto the mock's view; D5 the
  named empty and error states (no `emq:*` keys, a per-queue read error) rendered, never
  faked to zero.
- **Who** — the on-call operator (the depths wall at a glance), the bus developer (the
  contract suite as the compatibility gate for read-plane rungs), and codemojex as the
  worked producer whose queues populate the wall.
- **Where** — `echo/apps/echo_dash` (new); reads via `EchoMQ.{Metrics, Events, Dashboard,
  Keyspace}`; design tokens from `mercury/apps/echomq` (path cited as the design source,
  consumed as assets).
- **When** — July 2026, first rung of Movement D-I; dash.2 stacks on its scaffold and
  contract suite.

## Invariants

- **INV1 — read-only.** No write verb is reachable from any dash.1 surface; the app links
  no `Admin` call.
- **INV2 — no reimplemented read.** Every fetch delegates to `Metrics` / `Events` / the
  `Dashboard` fetchers; no key is composed outside `Keyspace`.
- **INV3 — wire names as-built.** The closed set `pending · active · schedule · dead ·
  completed · failed` renders under its wire names; "schedule" (the set) and `:scheduled`
  (the job-state atom) both honored, neither "fixed".
- **INV4 — named absence.** The empty bus, an unknown queue, and a read error are named
  states in the UI, never a confident zero.
- **INV5 — bounded staleness.** A dropped push costs at most one reconcile tick; the tick
  interval is declared in config, not hard-coded.

## Gate

`mix test` green in `echo_dash` with the contract suite against a live Valkey `:6390`
(the bench's engine); LiveView render tests over fixture maps for the empty, error, and
live cases (the pure-renderer discipline of `EchoMQ.Dashboard` carried into components);
a Playwright smoke at zero console errors (the mercury ports' precedent). The rung label
climbs only when all three hold.
