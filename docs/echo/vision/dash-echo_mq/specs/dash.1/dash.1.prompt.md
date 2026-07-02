# DASH.1 · the orchestration runbook — LAUNCH-ready (authored July 2026)

> **Status: LAUNCH-ready.** Pipeline: **Venus (this triad, reconciled pre-build) →
> Mars-1 (scaffold + contract suite + Overview) → Director (independent verify: gates +
> invariants + boundary law) → Mars-2 (harden: fixtures, empty/error states, smoke) →
> Director (closure + one pathspec commit)**. Apollo joins only if the Director flags a
> law breach. Inputs: the spec ([`./dash.1.md`](dash.1.md)), the stories
> ([`./dash.1.stories.md`](dash.1.stories.md)), the
> [dashboard roadmap](../../../dash.roadmap.md), and the bus boundary note in
> [emq4](../../../emq4.roadmap.md).

## The rung in one paragraph

dash.1 opens the dashboard program: the `echo_dash` Phoenix LiveView application scaffolded
read-only inside the umbrella (seam DASH-A arm A1 — deps `echo_mq` + `echo_wire`, no Ecto,
no write verb reachable), the read-plane **contract suite** pinning the closed state set,
the job-row fields, the lane-depth shapes, and the `Events` names against a live Valkey,
and the **Overview** wall — discovery, six-state depths in the house palette, throughput
strip — live by `Events` push with a declared-interval `Metrics` reconcile tick (seam
DASH-B arm B3), on the Mercury mock's dark-first tokens. The empty and error cases render
named, never faked. The substrate is entirely as-built: every read the rung consumes
exists today in `Metrics`, `Events`, and the `Dashboard` fetch helpers.

## Build notes for Mars

- Scaffold with the umbrella's Phoenix generation conventions; mirror `codemojex`'s
  endpoint shape where it is boring to do so, diverge where operator tooling differs.
- The contract suite is the rung's centre of gravity — write it FIRST against the live
  bench bus, then build the Overview on the fields it pins.
- Port tokens from `mercury/apps/echomq` (`src/echomq.css` and the token layer) as
  static assets; the Overview maps one-to-one onto the mock's `views/Overview.tsx`.
- The `Events` subscription per queue rides `EchoMQ.Events` on a dedicated connector
  lane (the blocking-verbs-own-lane precedent); bridge pushes into Phoenix.PubSub, and
  tie subscription lifecycle to LiveView mount/terminate — no leaked subscriptions.

## The Director's verify list

INV1 (reference scan: no write verb), INV2 (every fetch through the plane), INV3 (wire
names rendered as-built), INV4 (named absence in fixtures and live), INV5 (tick declared
in config), the three-part gate from the spec, and the boundary law: any read the build
wanted and the plane lacked is recorded as a bus runway item, not worked around.
