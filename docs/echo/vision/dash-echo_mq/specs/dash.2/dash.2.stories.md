# DASH.2 · user stories

> Derived from [`./dash.2.md`](dash.2.md) (AUTHORED, pre-build — forward tense). The
> consumer ground is the on-call operator and the tenant owner; the worked producer is
> codemojex, whose per-player lanes are the Groups view's live subject.

## DASH.2-US1 — one job, fully explained

As an on-call operator, I want to open one job by queue and id and see its row, state,
attempts, logs, and progress in one panel, so that a stuck or dead job is explained
where it is found, without a terminal.

Acceptance criteria
- Given a live job id, when the deep link opens, then the panel renders the row fields,
  the log lines, and progress, matching the ANSI `render_job` content.
- Given a missing job, when the link opens, then the named missing state renders (never
  an empty panel pretending success).
- Given a malformed id, when the route is hit, then it is refused at the door with the
  gate's error, before any bus read.

INVEST — independent of US2; testable by render fixtures + the live suite; encodes
INV1, INV2. Priority: must · Size: 5 · Implements: D1, D4.

## DASH.2-US2 — fairness made visible

As a tenant owner on a shared queue, I want the Groups view to show my lane's depth, the
ring's serving order, whether I am paused, and my limit / weight / active counts, so
that a starvation claim or a pause is settled by looking, not by asking.

Acceptance criteria
- Given grouped work, when the view mounts, then every lane renders depth and its
  limit / weight / active reads, and the ring order matches the wire's rotation.
- Given a pause lands on my group, when the next push or tick arrives, then the paused
  marker renders without a reload.

INVEST — independent; testable against the bench's seeded lanes; encodes INV1.
Priority: must · Size: 5 · Implements: D2, D3.

## DASH.2-US3 — liveness that cleans up after itself

As the platform owner, I want every live subscription the views open to close with
them, so that a day of operator browsing leaves the bus's pub/sub exactly as it found
it.

Acceptance criteria
- Given repeated mount/unmount cycles across both views, when the suite counts
  subscriptions, then the count returns to baseline every cycle.

INVEST — independent; testable in the suite; encodes INV3.
Priority: must · Size: 2 · Implements: D3, D4.
