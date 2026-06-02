# F5 · near-term delivery roadmap (F5.1 – F5.5)

> The plan for shipping the first five rungs of the Portal engine to production. These five go out as planned — thin in
> scope, robust in code, fully harnessed by tests. Delivery runs as Agile iterations: each rung is sharpened to a
> crisp spec, built to its Definition of Done, shipped, and reviewed. The Operator reviews each delivered increment and
> its spec, then returns with feedback we adopt to learn, evolve the development process, and move Phoenix Portal
> forward.

This roadmap is the delivery instrument for the value ladder in [`pragmatic.md`](pragmatic.md). It covers the
near-term arc only (F5.1 → F5.5); the next arc is planned after F5.5 is reviewed.

## Who does what

- **Author** — produces the deliverables: the spec triad per rung (`f5.N.md` / `.stories.md` / `.llms.md`) and the
  build plan, sharpened so an agent can implement without guessing.
- **Operator** — the person steering this work (this conversation). Reviews each delivered spec and shipped increment,
  then returns with feedback and the request for the next feature specs and roadmap. "Adopt, learn, evolve, move
  forward" is about the **feature-development process** — not end-user telemetry.

The deliverable the Operator reviews is twofold: the **specs** (is this the right thing, scoped correctly) and the
**shipped increment** (does the production code do it robustly). Feedback on either feeds the next iteration.

## How we deliver — the Agile loop

Delivery is iterative and incremental: one rung per iteration, each ending in a potentially-shippable, production-bound
increment. The rhythm repeats per rung:

1. **Sharpen** — refine the rung's spec triad: Goal, Rationale (5W), Scope (in/out), Deliverables, Invariants,
   Definition of Done, stories, and the agent brief. Open questions are resolved into the spec before any code.
2. **Build** — implement to the Definition of Done with robust, harnessed code (see below).
3. **Ship** — release the increment to production. Thin scope, but real and supervised.
4. **Review** — demo the increment against its acceptance criteria; the Operator inspects the spec and the running
   result.
5. **Feedback → adapt** — the Operator returns feedback; we adopt it by editing the spec (the single source of truth),
   then move to the next rung. A short retrospective adapts the process itself.

This is inspect-and-adapt: we respond to change by updating the spec, so the codebase never drifts from a decision the
Operator has not reviewed. The build order is value-first — each rung is independently demoable — following tracer
bullets and walking-skeleton delivery (Pragmatic Programmer), small releases (XP), and Lean MVP, as sourced in
[the specs approach](../specs.approach.md).

## Thin scope, robust code

The pragmatic ladder keeps each increment **narrow in scope** — one vertical slice — yet **production-grade in
quality**. Thin never means a throwaway spike. Every rung ships:

- **supervised** under OTP, with the failure path designed, not hoped for;
- **contract-guarded** at its boundary (the F5.4 contract), so bad input is rejected before it reaches the core;
- **harnessed** by a test suite weighted to the pure core.

The **harness** that ships with each rung: ExUnit example tests on the pure functions, `StreamData` properties for the
invariants (identity round-trips, `replay == fold`, `0 ≤ progress ≤ 100`), contract tests for the closed error set,
and the rung's Definition-of-Done verification gates (including a static check that the web names only the boundary).
From F5.6 the harness adds a crash-recovery test and a single command→query process smoke test. This is what makes a
thin increment safe to put in production.

## Near-term plan — F5.1 to F5.5

| It. | Rung | Ships to production | Demo (observable) | Harness & robustness | Feedback we ask the Operator for |
| --- | --- | --- | --- | --- | --- |
| 1 | [F5.1](f5.1.md) · Start thin | a supervised app serving HTTP on `:4000`; branded Snowflake ids | boot; `curl` enroll → `422`, unknown → `404`; kill the engine → it restarts | `:one_for_one` supervision; `Portal.ID` round-trip tests; F5.1 DoD gates | the web/engine seam; id format and namespaces; the supervision posture |
| 2 | [F5.2](f5.2.md) · Domain | the Accounts/Catalog/Learning contexts and entities; enroll builds an enrollment | `iex` → `Learning.enroll("USR1","CRS1")` → `{:ok, %Enrollment{progress: 0}}`, retrievable | enforced-keys tests; `@type t`/`@spec` (Dialyzer-checkable); context-ownership check | the domain model (entities, fields); context boundaries; the public API surface |
| 3 | [F5.3](f5.3.md) · Tracer bullets | enroll round-trips end to end over HTTP and persists; a deliver-lesson read slice | `curl` enroll → `201` + id, retrievable; `GET /lessons/:id` → `200`/`404` | an end-to-end test with no mocks; deterministic result→status mapping | the first real feature's behaviour; the JSON envelope; which slice next |
| 4 | [F5.4](f5.4.md) · The enroll contract | bad/duplicate enroll rejected at the door with nothing written | `curl` bad/duplicate → `422 :course_not_found`/`:already_enrolled`, store unchanged; valid → `201` | `StreamData` properties (postcondition, `0..100`); examples per error; fail-fast (no partial writes) | the closed error vocabulary (right reasons and statuses); the contract's strictness |
| 5 | [F5.5](f5.5.md) · Commands, queries & events | enroll/deliver recorded as events; the engine is `decide`/`evolve` over a log; state rebuildable by `replay` | `decide` → events + `:ok`; a query → data; `replay(log)` reconstructs state | pure-core example tests; a `replay == fold` property; CQS enforced | the event model (types, fields); the command/query tuples; whether CQS is right before the state home (F5.6) |

Each row is one iteration: sharpen the spec, build it robustly and harnessed, ship, demo on the observable shown,
review, and fold the Operator's feedback into the spec before the next.

## The feedback loop — inspect and adapt

After each delivery the Operator reviews the increment and its spec triad and returns feedback. We adopt it by editing
the spec — scope, acceptance criteria, invariants, or the next rung's sharpening — so the spec stays the single source
of truth and the code never runs ahead of a reviewed decision. Feedback may re-order, re-scope, split, or add rungs;
the value ladder is negotiable. A short retrospective adapts the process itself: the cadence, the harness, or the spec
template. The completion rule stays "correct by definition" — a rung is done only when its Definition of Done is met.

## After F5.5 — move forward

Once F5.5 ships and is reviewed, we plan the next arc with the Operator's feedback in hand: F5.6 (where state lives),
then F5.7 (the test pyramid), F5.8 (the durable `EventStore` port and the `Portal` facade with its closed
`%Portal.Error{}` set), and F5.9 (the engine assembled, LiveView-ready) — the handoff into the Phoenix web chapter,
[`../phoenix/phoenix.md`](../phoenix/phoenix.md). That arc is deliberately not over-planned now; responding to the
feedback comes first. [F5.6](f5.6.md) is already specced and queued so the next iteration can start without delay.

---

Index: [`pragmatic.md`](pragmatic.md) · Approach: [`../specs.approach.md`](../specs.approach.md) · Web chapter:
[`../phoenix/phoenix.md`](../phoenix/phoenix.md).
