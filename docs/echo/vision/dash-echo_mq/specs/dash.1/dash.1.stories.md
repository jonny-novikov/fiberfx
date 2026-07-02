# DASH.1 · user stories

> Who wants the live wall and the contract, what they need, and how acceptance is known.
> Derived from [`./dash.1.md`](dash.1.md) (AUTHORED, pre-build — forward tense). The
> consumer ground is the on-call operator and the bus developer; the worked producer is
> codemojex (`echo/apps/codemojex`), whose queues populate the wall.

## DASH.1-US1 — the depths wall at a glance

As an on-call operator, I want a live Overview of every discovered queue with its six
state depths in the house palette, so that a growing dead set or a stalled pending set is
visible in seconds without a terminal or a Valkey client.

Acceptance criteria
- Given a running bus with queues, when the Overview mounts, then every discovered queue
  renders a depths row on the closed six-state set with the house state colours.
- Given a scored job lands (codemojex play), when the `Events` push arrives, then the
  affected queue's row updates without a page action; given the push is lost, then the
  reconcile tick corrects the row within one declared interval.
- Given an empty bus, when the Overview mounts, then the named empty state renders (the
  ANSI dashboard's no-queues case), never a zeroed table.

INVEST — independent of dash.2; testable by LiveView render tests + the live contract
suite; encodes INV3, INV4, INV5. Priority: must · Size: 5 · Implements: D3, D4, D5.

## DASH.1-US2 — the contract that protects both sides

As a bus developer shipping read-plane rungs, I want a dashboard-owned contract suite
that pins every consumed field against a live bus, so that a change to `Metrics`,
`Events`, or the `Dashboard` fetchers fails a named test here before it breaks an
operator's wall silently.

Acceptance criteria
- Given the suite runs against a live Valkey, when the closed state set, the job-row
  fields, the lane-depth shapes, and the `Events` event names are read, then each is
  asserted by name, and a missing or renamed field fails with the field named.
- Given the bus is absent, when the suite runs, then it fails LOUD as unreachable rather
  than passing vacuously.

INVEST — independent; testable in CI beside the bus's conformance; encodes INV2.
Priority: must · Size: 3 · Implements: D2.

## DASH.1-US3 — a read-only app an operator can trust

As a platform owner, I want the dashboard application to be structurally read-only in
its first movement, so that handing its URL to a wider group carries no operational
write risk before the gated ops mode of Movement D-III exists.

Acceptance criteria
- Given the compiled `echo_dash` app, when its modules are inspected, then no `Admin` or
  write verb is referenced (a compile-time check in the suite), and no route mutates bus
  state.
- Given any UI action in dash.1, when it executes, then only `Metrics` / `Events` /
  `Dashboard` fetch calls cross to the bus.

INVEST — independent; testable by a reference scan in the suite; encodes INV1, INV2.
Priority: must · Size: 2 · Implements: D1, D2.
