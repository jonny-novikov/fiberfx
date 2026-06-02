# F11 · Student dashboard — the Portal as a value ladder

> The student's own view of the Portal: *my learning* and *my courses*. This chapter climbs a ladder of increments
> that show a signed-in student their progress across courses and their **paid, unlocked** courses, and lets them
> unlock a paid course — all over the unchanged `Portal` facade. It is the learner-facing counterpart to F6.9's
> operations dashboard, and it introduces one new domain dimension: course **entitlements** (paid → unlocked).

This index is the map. Each rung links to its three artifacts once specced — the spec (`f11.N.md`), the user stories
(`f11.N.stories.md`), and the agent brief (`f11.N.llms.md`). The chapter is authored spec-first; the delivery plan is
in [`dashboard.roadmap.md`](dashboard.roadmap.md), and the contract every rung follows is
[`../specs.approach.md`](../specs.approach.md).

## Where this chapter starts and ends

**Start (the F5 + F6 handoff).** The F5 engine behind the `Portal` facade (`enroll/2`, `deliver_lesson/2`,
`progress_of/1`, `courses_of/1`, returning `:ok | {:ok, data} | {:error, %Portal.Error{}}`), and the F6 web it runs in:
authentication and `current_user` (F6.8), LiveView, streams, and PubSub (F6.6–F6.7), the bounded contexts and the
`Catalog` (F6.4). See [`../pragmatic/f5.9.md`](../pragmatic/f5.9.md) and [`../phoenix/phoenix.md`](../phoenix/phoenix.md).

**End (after F11.7).** A signed-in student opens a dashboard that shows their progress in each course and which
courses they have unlocked versus which are locked behind a price; they can unlock a paid course; and the dashboard
updates live as they progress or unlock — all calling only the facade, with entitlements event-sourced in the engine
and payments behind a port.

## The master invariant

> The dashboard is a web surface: it calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set.
> No LiveView, controller, or template names `Portal.Engine`, a repo, or `GenServer.call`. Entitlement decisions live
> in the engine; payments cross a port, never the UI.

Entitlements join enrollment as event-sourced domain facts; the course price stays catalog data (CRUD), keeping the
F5 split intact. The closed error set extends — by an explicit, no-catch-all mapping (the F5.8/F6.3 `from/1`
discipline) — with the entitlement and payment codes this chapter needs (for example `:course_locked`,
`:already_unlocked`, `:payment_failed`).

## What this chapter adds to the domain

The Portal already knows courses, enrollments, lessons, and progress. F11 adds **entitlements**: a record that a
student has unlocked (paid for) a course.

- A new past-tense event, `CourseUnlocked` (`user_id`, `course_id`, `at`), recorded through the F5.9 `EventStore` port
  exactly as enrollment is.
- A small `Entitlements` context over that port, exposing the reads the dashboard needs and the unlock command, with a
  branded `ENT` id per entitlement.
- A **price** (and a paid/free flag) on the course, held as catalog data.
- A **payment port** — a behaviour with a stub adapter for dev and tests and a real provider adapter later — so the
  unlock command can record an entitlement without the UI knowing how payment happened.

The facade gains `unlock_course/2`, `entitlements_of/1`, and the progress reads the dashboard composes; nothing below
the facade changes for the rest of the platform.

## The value ladder

| Spec | Feature | Value it adds | Primary roles | Status |
| --- | --- | --- | --- | --- |
| F11.1 | Entitlements: model paid unlocking | the engine records who has unlocked which course (`CourseUnlocked`, an `Entitlements` context, `unlock_course/2` + `entitlements_of/1`, a course price) | Developer, Learner | planned |
| F11.2 | The student dashboard shell | a signed-in student opens *my learning* — their courses, seeded from the facade, under F6.8 auth | Learner | planned |
| F11.3 | Progress on the dashboard | per-course progress (`0..100`) and an overall view, read-only | Learner | planned |
| F11.4 | Paid & unlocked courses | each course shown as unlocked (entitled) or locked behind a price; the catalog through an entitlement lens | Learner | planned |
| F11.5 | Unlock a course | the unlock action through the payment port (stubbed); a `CourseUnlocked` recorded; the course opens | Learner | planned |
| F11.6 | A live dashboard | progress and unlock events update the student's dashboard without a reload (PubSub, per-student) | Learner | planned |
| F11.7 | Payments with a provider | a real provider (Stripe) behind the payment port; a verified webhook grants the entitlement idempotently | Learner, Operator | planned |

The rungs depend only downward: F11.1 is the domain foundation; F11.2 needs it; F11.3–F11.4 render what F11.1 makes
queryable; F11.5 acts on it; F11.6 makes F11.2–F11.5 live; F11.7 puts a real provider behind F11.5's port. The
delivery plan — milestones and per-rung iterations — is in [`dashboard.roadmap.md`](dashboard.roadmap.md).

## How to read a rung

Read the spec (`f11.N.md`) first — Goal, Rationale (5W), Scope, Deliverables, Invariants, Definition of Done. Then the
user stories (`f11.N.stories.md`) for the acceptance criteria. Then the agent brief (`f11.N.llms.md`) when you are
ready to implement: its references, requirements, execution topology, and the comprehensive prompt an agent runs to
build and self-check the increment. Every artifact follows [`../specs.approach.md`](../specs.approach.md) and the
master invariant above.

---

Roadmap: [`dashboard.roadmap.md`](dashboard.roadmap.md) · Engine: [`../pragmatic/pragmatic.md`](../pragmatic/pragmatic.md)
· Web: [`../phoenix/phoenix.md`](../phoenix/phoenix.md) · Program: [`../portal.roadmap.md`](../portal.roadmap.md) ·
Approach: [`../specs.approach.md`](../specs.approach.md).
