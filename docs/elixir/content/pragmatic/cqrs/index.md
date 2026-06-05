# F5.05 — Commands, queries & events (module hub)

- Route (served): `/elixir/pragmatic/cqrs`
- File: `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/index.html`
- Place in the chapter: The fifth module of F5 · Pragmatic Programming. With the `enroll` command contract-checked in F5.04, this module formalizes how the engine handles change — separating writes from reads, recording every change as a domain event, and deriving state by folding the log. It frames three dives (`cqs`, `events`, `reducer`) and bridges into F5.06 · Where engine state lives.
- Accent: burgundy (F5 · Pragmatic Programming).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5 · the engine · module 5`

H1 (verbatim): Commands, queries & *events*

Hero lede (verbatim):

> The enroll command is contract-checked, but the engine still mixes two jobs — changing things and answering questions — and keeps no record of what changed. F5.05 separates them. A **command** changes state and returns only whether it worked; a **query** returns data and changes nothing; and every change is recorded as a past-tense **event** — `%LearnerEnrolled{}`, `%LessonDelivered{}`. Once changes are events, state stops being something you store and becomes something you **derive**: fold the events and you have the current state. That makes the engine a reducer — two pure functions, run by a fold.

Kicker (verbatim):

> Two paths through the engine and one record of change. Select a piece to see what it does and what it returns.

## What the page frames

The landing presents the split (writes/reads/events) interactive, then the three deep dives as cards:

- **F5.05.1 — Command/query separation** — "A function either changes state and returns success or failure, or returns data and changes nothing — never both." Route `/elixir/pragmatic/cqrs/cqs`. Built.
- **F5.05.2 — Domain events** — "Every change is a past-tense fact — `%LearnerEnrolled{}` — immutable and carrying the data of what happened." Route `/elixir/pragmatic/cqrs/events`. Built.
- **F5.05.3 — The engine as a reducer** — "A command emits events, each event evolves the state, and one `reduce` replays the engine to now." Route `/elixir/pragmatic/cqrs/reducer`. Built.

The bridge cells frame the arc: F5.04 · honest commands ("Enroll checks its contract, but it both changes state and is the only record that anything happened.") → F5.05 · split and record ("Writes and reads part ways, every change becomes an event, and state is the fold of the log."). The `.note` directs the reader to start with command/query separation, then domain events, then the engine as a reducer, and points forward to F5.06 — Where engine state lives, and to the design brief `/elixir/pragmatic/flow`.

## The interactives

Two figures.

1. Hero concept figure — `<figure class="hero-fig">`, `aria-labelledby="rpTitle"`. Caption title (`#rpTitle`): `State is a left fold over the log`. SVG element ids: event chips `rpEvt0` / `rpEvt1` / `rpEvt2` (Enrolled / Delivered / Progressed), accumulator `rpAcc`, state text `rpState`, fold-tick group `rpTicks` (three `circle`s), count text `rpCount`. Controls: button `#rpBtn` (`▸ fold next event`, becomes `▸ replay from start` at the last step) and ghost button `#rpReset` (`reset`). Caption readout `#rpCap` (`aria-live="polite"`) shows the constant code line `reduce(events, %{}, &evolve/2)` plus a per-step hint. The four STEPS states/captions VERBATIM:
   - state `%{} — nothing folded yet`, cap `State starts empty. Each event folds in to derive the state at that point.`
   - state `%{enrolled: true}`, cap `LearnerEnrolled folded: the learner now appears in the derived state.`
   - state `%{enrolled: true, lessons: 1}`, cap `LessonDelivered folded: the same state, evolved by the next event.`
   - state `%{enrolled: true, lessons: 1, progress: 0.4}`, cap `ProgressNoted folded: replay is complete and the state is current.`
   - The count text reads `<n> of 3 events`. The fold is driven inline by the `STEPS` array (no exported pure-function name); the conceptual fold it depicts is `reduce(events, %{}, &evolve/2)`.

2. Write/read/event figure — `<figure class="fig">`, `aria-labelledby="cqTitle"`. Title `#cqTitle`: `Through the engine · select a piece`. Control group `#cqSel` (`role="group"`, `aria-label="Engine piece"`) with buttons `data-k="command"` (label `command`, default active), `data-k="event"` (`event`), `data-k="query"` (`query`). SVG part ids: `cqPart_command` (`enroll(...)`), `cqPart_event` (`%LearnerEnrolled{}`), `cqPart_query` (`courses_of(user_id)`); plus a static STATE box (`folded from events`). Readout `#cqOut` (`aria-live="polite"`), plus `#cqRole` (piece name) and `#cqResult` (Portal detail). The pure picker is `pick(k)` over the `PIECES` map; it sets stroke/fill on the selected part and writes the readout. The `PIECES` descriptions VERBATIM:
   - command — name `Command`, detail `enroll(user_id, course_id)`, desc `A write. It runs the contract from F5.04, and on success emits a domain event and changes state. It returns :ok or {:error, reason} — never data. Asking a command for data is the smell CQS removes.`
   - event — name `Event`, detail `%LearnerEnrolled{}`, desc `A past-tense fact: the record that a thing happened. Immutable, named in the past tense, carrying the data of the change. Every state change has one, which is what makes the engine a reducer.`
   - query — name `Query`, detail `courses_of(user_id)`, desc `A read. It returns data and changes nothing — call it twice and the engine is identical. Because queries never write, they are safe to cache, repeat, and run in parallel.`
   - The readout string assembled by `pick` is `A <b>{name}</b> — in the Portal, <code>{detail}</code>. {desc}`.

Degrade behaviour: both figures render a meaningful static default in the markup (hero shows `%{} · nothing folded yet`, `0 of 3 events`, and the first event chip stroked sage; the engine figure ships with `command` pre-active). All animation is gated behind `@media (prefers-reduced-motion: no-preference)` (the `.hp-row.hp-new` slide and the `.arc-flow` dash) and disabled under reduce; reveal-on-scroll degrades to immediately-shown without JS or under reduced motion.

Footer build-stamp: id `TSK0NcxSYzNWfw`, decoded timestamp `2026-06-01 15:26:42 UTC` (namespace `TSK`, branded Snowflake under epoch `1704067200000`, base62 alphabet, decoded client-side by `decodeBranded`).

## References (#refs, verbatim)

Intro line: `Separating commands from queries, and modeling change as events.`

Sources:
- `https://martinfowler.com/bliki/CQRS.html` — Martin Fowler — CQRS — command/query responsibility separation.
- `https://martinfowler.com/eaaDev/DomainEvent.html` — Martin Fowler — Domain Event — modeling change as events.
- `https://hexdocs.pm/commanded/Commanded.html` — Commanded — CQRS/ES building blocks in Elixir.

Related in this course:
- `/elixir/pragmatic/cqrs/cqs` — F5.05.1 · Command/query separation
- `/elixir/pragmatic/cqrs/events` — F5.05.2 · Domain events
- `/elixir/pragmatic/cqrs/reducer` — F5.05.3 · The engine as a reducer
- `/elixir/pragmatic/contracts` — F5.04 · Design by contract — the command this builds on.
- `/elixir/pragmatic/flow` — F5.0.3 · The command & event flow — the design brief for this path.

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `pragmatic` `/` `cqrs` (`pragmatic` → `/elixir/pragmatic`, `elixir` → `/elixir`; current segment `cqrs`).
- crumbs (verbatim): `F5 · Pragmatic Programming` (→ `/elixir/pragmatic`) `/` `F5.05 · cqrs` (here).
- toc-mini: `#split` → "Writes, reads, and events"; `#dives` → "Three deep dives".
- pager: prev → `/elixir/pragmatic` label `← F5 · overview`; next → `/elixir/pragmatic/cqrs/cqs` label `Start · command/query separation →`.
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`; foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `Commands, queries & events — F5.05 · jonnify`. `<meta name="description">`: `With the enroll command now contract-checked, F5.05 formalizes how the engine handles change: writes are commands that return only success or failure, reads are queries that return data and change nothing, and every change is recorded as a past-tense domain event. State is then derived by folding those events, which makes the engine a reducer. Three dives on command/query separation, domain events, and the engine as a reducer.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling hub on this burgundy chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/pragmatic/contracts/index.html` (F5.04 hub, same chapter). Change only the `<title>`/`<meta description>`, the route-tag (`cqrs`), and the `<main>` body (hero, the split figure, the three dive cards, the bridge, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.ID` minting `TSK…`/`EVT…` ids), the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and do not redefine `enroll/2`, `courses_of/1`, the event struct names (`%LearnerEnrolled{}`, `%LessonDelivered{}`, `%ProgressRecorded{}`), or the `decide`/`evolve`/`reduce` shapes shown in the dives; cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
