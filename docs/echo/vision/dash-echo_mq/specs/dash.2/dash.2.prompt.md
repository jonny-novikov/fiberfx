# DASH.2 · the orchestration runbook — LAUNCH-ready (authored July 2026)

> **Status: LAUNCH-ready, gated on dash.1's closure.** Pipeline: **Venus (this triad) →
> Mars-1 (Jobs + Groups + liveness) → Director (verify: invariants + gates) → Mars-2
> (harden: fixtures, gate assertions, smoke) → Director (closure + one pathspec
> commit)**. Inputs: [`./dash.2.md`](dash.2.md), [`./dash.2.stories.md`](dash.2.stories.md),
> the [dashboard roadmap](../../../dash.roadmap.md), and dash.1's shipped scaffold.

## The rung in one paragraph

dash.2 closes July's Movement D-I slice: the **Jobs** view (paged `browse`, the
state filter on the closed set, and the deep-linkable inspection panel over
`get_job` + logs + progress, with the `JOB` id gated at the route) and the **Groups**
view (lanes with depths, the ring's serving order, the paused set, and the
limit / weight / active reads), both live per visible queue through dash.1's `Events`
bridge with the shared reconcile tick, subscriptions bound to the LiveView lifecycle.
Every read exists today on the plane; the rung adds views and their contract pins, no
verbs.

## Build notes for Mars

- Reuse dash.1's bridge and tick wholesale; the only new liveness code is the
  per-view subscription set and its lifecycle assertion.
- The inspection panel's content contract is the ANSI `render_job/4` — parity of
  fields, not of formatting.
- Gate the deep link with `EchoData.BrandedId.valid?/1` in the route pipeline, and let
  the refusal render the gate's own error text.
- Extend the contract suite in the same file family as dash.1's, so the bus developer
  runs one suite for the whole consumed plane.

## The Director's verify list

dash.1's five laws re-asserted on the new surfaces; INV2 (route gate before any read);
INV3 (the subscription-count assertion across cycles); INV4 (paged browse, no unbounded
scan); the extended gate from the spec; and the boundary law's ledger — any missing read
recorded as a bus runway item.
