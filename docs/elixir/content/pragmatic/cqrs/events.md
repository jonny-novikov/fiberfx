# F5.05.2 — Domain events (dive)

- Route (served): `/elixir/pragmatic/cqrs/events`
- File: `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/events.html`
- Place in the chapter: The second of the three F5.05 dives. Having separated commands from queries in `cqs`, it models each change as a past-tense domain event — the record the next dive (`reducer`) folds back into state.
- Accent: burgundy (F5 · Pragmatic Programming).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.05 · part 2 of 3`

H1 (verbatim): Domain events

Hero lede (verbatim):

> An event is a record that something happened, written in the **past tense**: `%LearnerEnrolled{}`, `%LessonDelivered{}`, `%ProgressRecorded{}`. It is a plain, immutable struct that carries the data of the change and the time it occurred — not a command to do something, but the fact that it was done. Where a command can fail, an event already happened and cannot be argued with. Naming changes this way gives the engine a vocabulary for its own history, and that history is exactly what the next dive folds back into state. Events carry their own branded id under an `EVT` namespace, so each is timestamped for free.

Kicker (verbatim):

> Three changes the Portal records. Select an event to see what happened and what it carries.

## Sections

Two teaching sections.

1. **Facts, in the past tense** (`#facts`) — the tense is deliberate: a command is an imperative and might be refused; an event is a settled report. Because an event is immutable and self-describing it can be stored, replayed, or handed to another part of the system without fear. Anchored by the Portal-events interactive. Takeaway (verbatim): "A command might not happen; an event already did. That difference is why events, not commands, are the thing worth keeping."
2. **In code** (`#code`) — an event is a struct like any domain type (enforced keys, a typespec) named in the past tense; the command builds one on success, stamping it with an `EVT` id whose snowflake gives the time for free. Bridge cells: "name the change" (Past tense, immutable, self-describing — a fact you can store and replay.) → "stamped in time" (Each event carries an `EVT` id whose snowflake decodes to `at`.). The `.note` points forward to `/elixir/pragmatic/cqrs/reducer` (the engine as a reducer).

Running example: the three Portal events (`%LearnerEnrolled{}`, `%LessonDelivered{}`, `%ProgressRecorded{}`) and `enroll`'s `EVT`-stamped emission. Real Elixir code shown (verbatim):

```elixir
defmodule Portal.Events.LearnerEnrolled do
  @enforce_keys [:id, :user_id, :course_id, :at]
  defstruct [:id, :user_id, :course_id, :at]

  @type t :: %__MODULE__{
          id: String.t(), user_id: String.t(),
          course_id: String.t(), at: DateTime.t()
        }
end

# enroll emits it on success — a past-tense fact, stamped with an EVT id and its time
defp enrolled_event(user_id, course_id) do
  id = Portal.ID.new("EVT")
  %LearnerEnrolled{id: id, user_id: user_id, course_id: course_id, at: Portal.ID.at(id)}
end
```

## The interactives

One figure — `<figure class="fig">`, `aria-labelledby="evTitle"`. Title `#evTitle`: `Portal events · select one`. Control group `#evSel` (`role="group"`, `aria-label="Domain event"`) with buttons `data-k="enrolled"` (label `enrolled`, default active), `data-k="delivered"` (`delivered`), `data-k="progressed"` (`progressed`). SVG chip ids: `evChip_enrolled` (`LearnerEnrolled` / "a learner joined a course"), `evChip_delivered` (`LessonDelivered` / "a lesson was served"), `evChip_progressed` (`ProgressRecorded` / "a learner advanced"). Readout `#evOut` (`aria-live="polite"`), plus `#evRole` (event name) and `#evResult` (what it records). The pure picker is `pick(k)` over the `EVENTS` map; it restyles the selected chip (blue accent on this dive) and writes the readout. The `EVENTS` entries VERBATIM:
- enrolled — name `LearnerEnrolled`, records `a learner joined a course`, desc `Emitted by enroll on success. Carries the user_id, the course_id, and the time — the fact that the enrollment now exists.`
- delivered — name `LessonDelivered`, records `a lesson was served`, desc `Emitted when a lesson is delivered. Carries the user_id and the lesson_id. Worth recording as a fact even though the read itself changes nothing.`
- progressed — name `ProgressRecorded`, records `a learner advanced`, desc `Emitted when progress changes. Carries the enrollment_id and the new percent. Folding these is what moves an enrollment through 0..100.`
- The readout string assembled by `pick` is `<b>%{name}{}</b> records that <b>{records}</b>. {desc}`.

Degrade behaviour: the figure ships with `enrolled` pre-active in the markup (a meaningful static default). Reveal-on-scroll degrades to immediately-shown without JS or under `prefers-reduced-motion: reduce`. The page carries no looping animation.

Footer build-stamp: id `TSK0NcxSZyPHdo`, decoded timestamp `2026-06-01 15:26:42 UTC` (namespace `TSK`, branded Snowflake under epoch `1704067200000`, base62, decoded client-side by `decodeBranded`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://martinfowler.com/bliki/CQRS.html` — Martin Fowler — CQRS — separate the write model from the read model.
- `https://martinfowler.com/eaaDev/EventSourcing.html` — Martin Fowler — Event Sourcing — state as a log of events to fold over.
- `https://hexdocs.pm/commanded/Commanded.html` — Commanded — CQRS/ES building blocks in Elixir.

Related in this course:
- `/elixir/pragmatic/cqrs` — F5.05 · Commands, queries & events
- `/elixir/pragmatic/cqrs/cqs` — CQS: separating commands from queries
- `/elixir/pragmatic/cqrs/reducer` — The engine as a reducer

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `pragmatic` `/` `cqrs` `/` `events` (`elixir`, `pragmatic`, `cqrs` linked; current segment `events`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.05` (→ `/elixir/pragmatic/cqrs`) `/` `events` (here).
- toc-mini: `#facts` → "Facts, in the past tense"; `#code` → "In code".
- pager: prev → `/elixir/pragmatic/cqrs/cqs` label `← F5.05.1 · cqs`; next → `/elixir/pragmatic/cqrs/reducer` label `Next · the engine as a reducer →`.
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`; foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `Domain events — F5.05.2 · jonnify`. `<meta name="description">`: `Model every change as a past-tense fact: %LearnerEnrolled{}, %LessonDelivered{}, %ProgressRecorded{}. An event is immutable, named for what happened, and carries the data of the change plus the time it occurred. Events are the record the engine is built from.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT dive on this burgundy chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/cqs.html` (the previous dive in this same module). Change only the `<title>`/`<meta description>`, the route-tag (`…/cqrs/events`), and the `<main>` body (hero, the Portal-events figure, the struct/code block, the bridge, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.ID.new("EVT")` / `Portal.ID.at(id)`), the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and do not rename the event structs (`%LearnerEnrolled{}`, `%LessonDelivered{}`, `%ProgressRecorded{}`), change their enforced keys, or invent fields beyond `id`/`user_id`/`course_id`/`at` as shown; cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
