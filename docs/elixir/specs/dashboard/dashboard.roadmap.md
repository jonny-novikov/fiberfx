# F11 · Roadmap — the student dashboard

> The delivery plan for the learner-facing dashboard: *my progress* and *my paid, unlocked courses*. Five-to-seven
> thin, robust increments take a signed-in student from an empty page to a live view of their progress across courses
> and the courses they have unlocked — with the ability to unlock a paid one. The chapter introduces one new domain
> dimension, **entitlements**, event-sourced in the engine and surfaced through the unchanged `Portal` facade. This
> file plans the work; the rungs themselves are mapped in [`dashboard.md`](dashboard.md) and defined under
> [`../specs.approach.md`](../specs.approach.md).

## What we are delivering

A student-facing dashboard, distinct from F6.9's operations dashboard. By the end of the chapter a signed-in student
can open *my learning* and see their progress in each course and which courses they have unlocked versus which are
locked behind a price, unlock a paid course, and watch the page update live as they progress or unlock. Underneath, the
engine gains course **entitlements** — a `CourseUnlocked` fact recorded through the F5.9 `EventStore` port, an
`Entitlements` context, a course **price** held as catalog data, and a **payment port** with a stub adapter for dev and
tests and a real provider later. The facade gains `unlock_course/2`, `entitlements_of/1`, and the progress reads the
dashboard composes; nothing else below the facade changes.

## Where this starts and ends

**Start.** The F5 engine behind the `Portal` facade (`enroll/2`, `deliver_lesson/2`, `progress_of/1`, `courses_of/1`)
and its `EventStore` port ([`../pragmatic/f5.9.md`](../pragmatic/f5.9.md)), plus the F6 web it runs in —
authentication and `current_user` (F6.8), LiveView and PubSub (F6.6–F6.7), the bounded contexts and the `Catalog`
(F6.4). See [`../phoenix/phoenix.md`](../phoenix/phoenix.md).

**End.** A live, authenticated student dashboard showing per-course and overall progress and the locked/unlocked state
of each course, with a working unlock action — calling only the facade, with entitlements event-sourced and payments
behind a port whose real provider is wired in the final milestone.

## Architecture decision

Four choices fix the shape of the chapter so the rungs implement rather than decide.

- **Entitlements are event-sourced, like enrollment.** An unlock is a fact with a time and a provenance — who unlocked
  which course, when, and via which payment — so it is a past-tense `CourseUnlocked` event recorded through the F5.9
  `EventStore` port and replayed by an `Entitlements` context, exactly as enrollment is. This reuses the port already
  built, gives unlocks an audit trail, and keeps the unlock decision in the engine
  ([`../pragmatic/decider-pattern.md`](../pragmatic/decider-pattern.md)).
- **The course price stays catalog data (CRUD).** A price is editable state, not an event; it lives on the course in
  the `Catalog` context (F6.4), keeping the F5 split — facts in the event store, editable reference data in the
  catalog — intact.
- **The dashboard is a LiveView under F6.8 auth, scoped to `current_user`.** It is per-student and read-mostly, unlike
  F6.9's platform-wide, read-only operations dashboard. It seeds from the facade at mount and renders only assigns and
  streams.
- **Payments cross a port, not the UI.** A `Portal.Payments` behaviour has a stub adapter (dev and tests — explicit
  success and failure, no network) and a real provider adapter (Stripe) wired in F11.7. The unlock command calls the
  port and records the entitlement on success; the LiveView never sees payment internals — the same ports-and-adapters
  discipline as the `EventStore` ([`../pragmatic/f5.8.md`](../pragmatic/f5.8.md)).

Live updates reuse the F6.7 PubSub facade on a **per-student topic**, carrying that student's progress and unlock
events for the dashboard to fold — scoped to the learner, not the global catalog or events topics.

## The master invariant

> The dashboard is a web surface: it calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set.
> No LiveView, controller, or template names `Portal.Engine`, a repo, or `GenServer.call`. Entitlement decisions live
> in the engine; payments cross a port.

The closed error set extends — by an explicit, no-catch-all `from/1` mapping (the F5.8 / F6.3 discipline) — with the
codes this chapter needs: `:course_locked` (a course not yet unlocked), `:already_unlocked` (unlocking one already
owned), and `:payment_failed` (the payment port reported failure). Each is added deliberately, never by a catch-all.

## How this roadmap runs

The chapter runs the Author/Operator loop from [`../specs.approach.md`](../specs.approach.md):

- **Author (Claude)** turns each rung into a spec triad and a build plan at the quality bar in the approach doc.
- **Operator (the human)** reviews the delivered specs and the shipped increment, then asks for the next rung's specs
  or a change to a shipped one.

The loop per rung is **sharpen → build → ship → demo → review → feedback → adapt**, and feedback edits the spec, which
is the single source of truth. Rungs ship in dependency order; the payment-provider rung is deferred until the unlock
flow has shipped against the stub.

## "Thin but robust" for the dashboard

Each rung is a narrow vertical slice built to production quality, not a prototype:

- the unlock command goes through the engine and the `EventStore` port, with the `CourseUnlocked` event and the
  `Entitlements` read pinned by example and property tests;
- every read and command crosses the `Portal` facade and returns `:ok | {:ok, data} | {:error, %Portal.Error{}}`;
- payments run against the **stub** adapter in dev and tests, so no rung before F11.7 depends on an external service;
- the LiveView is supervised by the F6 endpoint, renders only assigns and streams, and ships behind its
  Definition-of-Done gates.

Near-term rungs (the entitlement model and the dashboard view) ship first; the real payment provider is specified last,
once the slice it backs is proven.

## The delivery arc

Four milestones, each a coherent product step.

| Milestone | Rungs | What the student can do at the end |
| --- | --- | --- |
| M1 · Model & shell | F11.1–F11.2 | the engine records unlocks; a signed-in student opens their dashboard |
| M2 · Progress & access | F11.3–F11.4 | see per-course and overall progress, and which courses are unlocked versus locked |
| M3 · Unlock & live | F11.5–F11.6 | unlock a paid course (stubbed payment) and watch progress and unlocks update live |
| M4 · Real payments | F11.7 | unlock a course through a real provider, granted on a verified webhook |

| Rung | Ships (the slice) | Demo | Harness | Feedback asked |
| --- | --- | --- | --- | --- |
| F11.1 | `CourseUnlocked` event, `Entitlements` context, `unlock_course/2` + `entitlements_of/1`, course price | unlock a course in IEx; replay shows the entitlement | example + property tests over the context; `EventStore` port | is the entitlement model right (paid → unlocked)? |
| F11.2 | `DashboardLive` shell under F6.8 auth, the student's courses seeded from the facade, the route | sign in and open `/dashboard` | a connected mount test; an auth-redirect test | is the shell the right starting frame? |
| F11.3 | per-course progress (`0..100`) and an overall view, read-only | the dashboard shows progress bars per course | rendered-output tests for progress | is progress shown the way students expect? |
| F11.4 | locked vs unlocked state per course, with price and a lock badge | locked courses show a price; unlocked ones open | tests for entitled / not-entitled rendering | is the locked/unlocked distinction clear? |
| F11.5 | the unlock action through the stub payment port; `CourseUnlocked` recorded; the course opens | unlock a paid course and see it open | the stub adapter (success + failure); the closed error set | does the unlock flow feel right end to end? |
| F11.6 | per-student PubSub; progress and unlock events update the dashboard without reload | complete a lesson in one tab, see the other update | two-session test; broadcast-on-success only | is live the right behavior here? |
| F11.7 | a real provider (Stripe) behind the payment port; a verified webhook grants the entitlement idempotently | pay through Checkout and see the course unlock | webhook signature + idempotency tests | is the provider integration sound? |

## Seams & open decisions

- **The payment provider.** F11.7 names Stripe behind the `Portal.Payments` port, but the port keeps the choice
  reversible; the provider, its checkout style (hosted vs embedded), and the webhook surface are decided when F11.7 is
  sharpened.
- **Refunds and revocation.** Whether an entitlement can be revoked (a `CourseLocked`/refund event) is deferred; the
  event-sourced model leaves room for it without rework.
- **The pricing model.** One-off unlock per course is assumed; bundles, subscriptions, and trials are out of scope and
  noted as later seams.
- **Entitlement vs enrollment.** Enrollment (F5/F6) and entitlement (F11) are distinct facts; how they relate —
  whether unlocking implies enrolling, or enrollment is gated on entitlement for paid courses — is a decision F11.4/F11.5
  fix explicitly rather than assume here.
- **Free courses.** A course with no price is unlocked for everyone; the locked/unlocked logic treats free as a
  trivially-granted entitlement.

## Conventions

- **The master invariant** holds throughout: the dashboard calls only the `Portal` facade and renders only the closed
  `%Portal.Error{}` set; entitlement decisions live in the engine; payments cross a port.
- **Branded Snowflake ids** for entitlements — a branded `ENT` id (integer column; branded transport form with the
  `ENT` namespace and base62 encoding) per unlock.
- **The spec system** is the contract: each rung conforms to [`../specs.approach.md`](../specs.approach.md) and passes
  the quality gates (voice, structure, traceability, fences, links) before it is presented.
- **A+ quality, Writerside-friendly markdown** throughout.

## Map

- This chapter's index and ladder: [`dashboard.md`](dashboard.md).
- The contract for the spec system: [`../specs.approach.md`](../specs.approach.md).
- The program roadmap: [`../portal.roadmap.md`](../portal.roadmap.md).
- Upstream — engine: [`../pragmatic/pragmatic.md`](../pragmatic/pragmatic.md), the `EventStore` port
  [`../pragmatic/f5.9.md`](../pragmatic/f5.9.md), boundaries [`../pragmatic/f5.8.md`](../pragmatic/f5.8.md), the engine
  pattern [`../pragmatic/decider-pattern.md`](../pragmatic/decider-pattern.md).
- Upstream — web: [`../phoenix/phoenix.md`](../phoenix/phoenix.md), contexts [`../phoenix/f6.4.md`](../phoenix/f6.4.md),
  LiveView [`../phoenix/f6.6.md`](../phoenix/f6.6.md), real-time [`../phoenix/f6.7.md`](../phoenix/f6.7.md), auth &
  deploy [`../phoenix/f6.8.md`](../phoenix/f6.8.md), web roadmap [`../phoenix/phoenix.roadmap.md`](../phoenix/phoenix.roadmap.md).

---

> Part of the jonnify toolkit. One core, many surfaces — the dashboard is the student's. The roadmap plans; the specs
> define and prove; both are reviewed here before any implementation runs.
