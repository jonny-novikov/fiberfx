# F5.05.3 — The engine as a reducer (dive)

- Route (served): `/elixir/pragmatic/cqrs/reducer`
- File: `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/reducer.html`
- Place in the chapter: The third and final F5.05 dive. With commands separated from queries (`cqs`) and changes modeled as events (`events`), it closes the module by folding the event log into state — making the engine two pure functions (`decide`, `evolve`) run by a `reduce`. It carries an advanced section on temporal queries and bridges into F5.06.
- Accent: burgundy (F5 · Pragmatic Programming).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.05 · part 3 of 3`

H1 (verbatim): The engine as a reducer

Hero lede (verbatim):

> Once every change is an event, state stops being something you mutate and becomes something you **fold**. The engine is two pure functions: **decide** takes the current state and a command and returns the events it produces, and **evolve** takes the state and one event and returns the next state. Run `evolve` across the whole event log with a single `Enum.reduce/3` and you have replayed the engine to its current state. Because the functions are pure and the events are ordered, the result is deterministic: the same log always folds to the same state — on restart, in a test, or on another node.

Kicker (verbatim):

> Three events, folded left into state. Select one to see the step it performs.

## Sections

Three sections — two teaching, one advanced.

1. **Folding the log** (`#fold`) — start from empty state `s0`, apply the first event to get `s1`, the second to get `s2`, and so on; each step uses only the running accumulator and the next event, which is the shape of a left fold. Anchored by the reduce-over-events stepper. Takeaway (verbatim): "State is a fold of its history. Keep the events and you can always recompute the present — which is why the log, not the snapshot, is the thing that matters."
2. **In code** (`#code`) — two pure functions and a `reduce`: `evolve/2` has one clause per event and returns the next state; `replay/1` folds the whole log from the empty state; a command path runs `decide` to produce events, appends them, and applies them. Bridge cells: "decide, then evolve" (A command produces events; each event folds into the next state.) → "one reduce" (Folding the log replays the engine to now — deterministic, every time.). The `.note` closes F5.05 and points forward to F5.06 — Where engine state lives.
3. **Replaying to a point: state as of an earlier event** (`#replay-progress`, advanced, `.reveal`) — `replay/1` folds the whole log into the present, but nothing about the fold demands the full history: hand it a prefix (the first *n* events) and the same `evolve` clauses reconstruct the state as of that earlier point, with no snapshot kept. This is the temporal query Martin Fowler attaches to Event Sourcing — any earlier state is the fold of an earlier prefix; the history is auditable and recomputable. Takeaway (verbatim): "A prefix of the log folds to the state as of its last event. Keep the events in order and any past moment is recomputable from them — the log is auditable, and an earlier state is the fold of an earlier prefix, never a stored snapshot."

Running example: the Portal engine's `replay/1` over `%LearnerEnrolled{}` / `%ProgressRecorded{}` events, then `replay_until/2` folding a prefix. Real Elixir code shown (verbatim, section 2):

```elixir
# the engine is two pure functions:
#   decide: (state, command) -> [event]   — validate, then emit (F5.04 contract runs here)
#   evolve: (state, event)   -> state      — fold one event in

def replay(events), do: Enum.reduce(events, initial_state(), &evolve/2)

defp evolve(%LearnerEnrolled{} = e, state),
  do: put_in(state.enrollments[e.user_id], e)

defp evolve(%ProgressRecorded{} = e, state),
  do: put_in(state.enrollments[e.enrollment_id].progress, e.percent)
```

Real Elixir code shown (verbatim, section 3 — the temporal-query block):

```elixir
# reuse the engine's replay/1 unchanged — the whole-log fold from above:
#   def replay(events), do: Enum.reduce(events, initial_state(), &evolve/2)
# a prefix selector + the same fold reconstructs the state as of an earlier event.
def replay_until(events, n), do: events |> Enum.take(n) |> replay()

log = [
  %LearnerEnrolled{id: "EVT-1", user_id: "USR-9", course_id: "CRS-7", at: t1},
  %LearnerEnrolled{id: "EVT-2", user_id: "USR-4", course_id: "CRS-7", at: t2}
]

# now: the whole log folded — both enrolments are present
replay(log).enrollments |> Map.keys() |> Enum.sort()
# => ["USR-4", "USR-9"]

# then: replay to the point after the first event only — a prefix fold,
# with no snapshot kept for that moment (audit / temporal query)
as_of_first = replay_until(log, 1)
Map.keys(as_of_first.enrollments)
# => ["USR-9"]
Map.has_key?(as_of_first.enrollments, "USR-4")
# => false   — USR-4 enrolled after the cut, so the earlier state never held it

# the cut can be a predicate instead of a count — fold up to a timestamp/id:
before_evt2 = log |> Enum.take_while(fn e -> e.id != "EVT-2" end) |> replay()
map_size(before_evt2.enrollments)
# => 1   — same prefix, same reconstructed state
```

## The interactives

Two figures.

1. Reduce-over-events stepper — `<figure class="fig">`, `aria-labelledby="rdTitle"`. Title `#rdTitle`: `Reduce over events · select a step`. Control group `#rdSel` (`role="group"`, `aria-label="Fold step"`) with buttons `data-k="e1"` (label `apply 1`, default active), `data-k="e2"` (`apply 2`), `data-k="e3"` (`apply 3`). SVG ids: state circles `rdState_s1` / `rdState_s2` / `rdState_s3` (plus static `s0`), arrows `rdArrow_e1` / `rdArrow_e2` / `rdArrow_e3` (labelled `LearnerEnrolled`, `LessonDelivered`, `ProgressRecorded`); static caption text `state = Enum.reduce(events, s0, &evolve/2)`. Readout `#rdOut` (`aria-live="polite"`), plus `#rdRole` (step, default `apply LearnerEnrolled`) and `#rdResult` (transition, default `s0 → s1`). The pure picker over the step map restyles the active arrow/circle (gold accent) and writes the readout. (The per-step readout strings are produced by the inline script's step map.)

2. Replay-to-a-point figure (advanced, static SVG) — `<figure class="fig">`, `aria-labelledby="rpTitle"`. Title `#rpTitle`: `Folding a prefix of the log to reconstruct an earlier state`. The SVG shows an append-only event log of two `%LearnerEnrolled{}` events with a cut after the first (`take(log, 1) · the cut`), folded by `Enum.reduce(prefix, initial_state(), &evolve/2)` into a reconstructed accumulator (`state as of the cut`) holding only `"USR-9"` (`map_size: 1 · "USR-4" absent`). Static caption (verbatim): `prefix of 1 event → enrollments holds only "USR-9" · the second enrolment is after the cut`. This figure has no controls; it is a labelled diagram. Its flow path uses class `.rp-flow` (sage), animated only under `prefers-reduced-motion: no-preference`.

Degrade behaviour: the stepper ships with `apply 1` pre-active and `s0 → s1` shown (a meaningful static default); the replay-to-a-point figure is fully static in markup. The `.rp-flow` dash and the reveal-on-scroll both disable under `prefers-reduced-motion: reduce` (and reveal degrades to immediately-shown without JS).

Footer build-stamp: id `TSK0NcxSaH8oE4`, decoded timestamp `2026-06-01 15:26:43 UTC` (namespace `TSK`, branded Snowflake under epoch `1704067200000`, base62, decoded client-side by `decodeBranded`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://martinfowler.com/bliki/CQRS.html` — Martin Fowler — CQRS — separate the write model from the read model.
- `https://martinfowler.com/eaaDev/EventSourcing.html` — Martin Fowler — Event Sourcing — state as a log of events to fold over.
- `https://hexdocs.pm/commanded/Commanded.html` — Commanded — CQRS/ES building blocks in Elixir.

Related in this course:
- `/elixir/functional/folds/reduce` — F2.05 · reduce, the left fold
- `/elixir/pragmatic/cqrs/events` — F5.05.2 · Events as the record of change
- `/elixir/pragmatic/state` — F5.06 · Where engine state lives

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `pragmatic` `/` `cqrs` `/` `reducer` (`elixir`, `pragmatic`, `cqrs` linked; current segment `reducer`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.05` (→ `/elixir/pragmatic/cqrs`) `/` `reducer` (here).
- toc-mini: `#fold` → "Folding the log"; `#code` → "In code"; `#replay-progress` → "Replaying to a point".
- pager: prev → `/elixir/pragmatic/cqrs/events` label `← F5.05.2 · events`; next → `/elixir/pragmatic/cqrs` label `Back to F5.05 →`.
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`; foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `The engine as a reducer — F5.05.3 · jonnify`. `<meta name="description">`: `State is not stored so much as derived: a command emits events, each event evolves the state, and one reduce over the event log replays the engine to its current state. Two pure functions — decide and evolve — are the whole engine, and a fold is how they run.`

## Build instruction

To rebuild this page, copy the `<head>…</style>` (this dive adds one extra block — the `.rp-flow` sage replay-flow keyframes after the references CSS), `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT dive on this burgundy chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/events.html` (the previous dive in this same module), keeping the added `.rp-flow` rule. Change only the `<title>`/`<meta description>`, the route-tag (`…/cqrs/reducer`), and the `<main>` body (hero, the reduce stepper, the code block, the bridge, the advanced replay-to-a-point section, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and do not change the `decide`/`evolve/2`/`replay/1`/`replay_until/2` shapes, the `Enum.reduce(events, initial_state(), &evolve/2)` fold, the event struct names, or the `put_in`/`Enum.take`/`Enum.take_while` calls as shown; cite the companion course (F2.05 reduce, OTP internals) rather than re-teaching the fold. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
