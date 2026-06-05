# F5.05.1 — Command/query separation (dive)

- Route (served): `/elixir/pragmatic/cqrs/cqs`
- File: `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/cqs.html`
- Place in the chapter: The first of the three F5.05 dives. It opens the module by stating Meyer's command/query separation rule, then connects it to the Portal's `enroll`/`courses_of` split; it precedes `events` and `reducer`.
- Accent: burgundy (F5 · Pragmatic Programming).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.05 · part 1 of 3`

H1 (verbatim): Command/query separation

Hero lede (verbatim):

> Command/query separation is one rule, due to Bertrand Meyer: a function either **changes state and returns whether it worked**, or **returns data and changes nothing** — never both. A command does work and reports success or failure; a query answers a question and leaves the world untouched. `enroll` is a command; `courses_of` is a query. The payoff is reasoning: a query can be called twice, cached, or run in parallel because it has no effect, and a command is honest about the fact that it changes things. It also nudges `enroll` away from returning a read model — on success it reports `:ok`, and the caller queries for the result.

Kicker (verbatim):

> Two kinds of function, one job each. Select one to see what it returns and what it touches.

## Sections

Two teaching sections.

1. **Change or read, not both** (`#two`) — the rule and its payoff, anchored by the command-or-query interactive. Prose: a function that both reads and writes can never be called safely only to look; separating the two makes a query a free repeatable observation and a command the only thing that moves the engine. Takeaway (verbatim): "If a function returns data, it must be safe to call again. The only way to promise that is to keep it from changing anything — which is the whole rule."
2. **In code** (`#code`) — two functions, two shapes: `enroll` changes state and returns only a tag; `courses_of` returns data and runs no effect; after a successful command the route renders by issuing a query. Bridge cells: "ask or act" (A query observes for free; a command is the only thing that moves the engine.) → "enroll, then query" (The command reports `:ok`; the caller reads back the result.). The `.note` points forward to `/elixir/pragmatic/cqrs/events` (domain events).

Running example: the Portal's `enroll` (command) and `courses_of` (query). Real Elixir code shown (verbatim):

```elixir
# command — changes state; returns success or failure, not a read model
@spec enroll(String.t(), String.t()) :: :ok | {:error, atom}
def enroll(user_id, course_id) do
  with :ok <- check_precondition(user_id, course_id) do
    emit(%LearnerEnrolled{user_id: user_id, course_id: course_id})   # record the change
  end
end

# query — returns data; changes nothing, safe to repeat or run in parallel
@spec courses_of(String.t()) :: [Enrollment.t()]
def courses_of(user_id), do: State.enrollments_for(user_id)
```

## The interactives

One figure — `<figure class="fig">`, `aria-labelledby="csTitle"`. Title `#csTitle`: `Command or query · select one`. Control group `#csSel` (`role="group"`, `aria-label="Function kind"`) with buttons `data-k="command"` (label `command`, default active) and `data-k="query"` (`query`). SVG row ids: `csRow_command` (`changes state · returns :ok | {:error, _}`, labelled `writes`) and `csRow_query` (`returns data · changes nothing`, labelled `reads`). Readout `#csOut` (`aria-live="polite"`), plus `#csRole` (kind name) and `#csResult` (the return shape). The pure picker is `pick(k)` over the `KINDS` map; it restyles the selected row and writes the readout. The `KINDS` entries VERBATIM:
- command — name `Command`, ret `:ok | {:error, _}`, desc `It changes state and reports only whether it worked. No read model comes back — the caller re-queries if it wants the result. enroll is a command.`
- query — name `Query`, ret `data, no change`, desc `It answers a question and leaves the engine untouched. Idempotent and side-effect-free, so it is safe to repeat or run in parallel. courses_of is a query.`
- The readout string assembled by `pick` is `A <b>{name}</b> returns <b>{ret}</b>. {desc}`.

Degrade behaviour: the figure ships with `command` pre-active in the markup (a meaningful static default). Reveal-on-scroll degrades to immediately-shown without JS or under `prefers-reduced-motion: reduce`. The page carries no looping animation.

Footer build-stamp: id `TSK0NcxSZZzmSG`, decoded timestamp `2026-06-01 15:26:42 UTC` (namespace `TSK`, branded Snowflake under epoch `1704067200000`, base62, decoded client-side by `decodeBranded`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://martinfowler.com/bliki/CQRS.html` — Martin Fowler — CQRS — separate the write model from the read model.
- `https://martinfowler.com/eaaDev/EventSourcing.html` — Martin Fowler — Event Sourcing — state as a log of events to fold over.
- `https://hexdocs.pm/commanded/Commanded.html` — Commanded — CQRS/ES building blocks in Elixir.

Related in this course:
- `/elixir/pragmatic/cqrs` — F5.05 · Commands, queries & events
- `/elixir/pragmatic/cqrs/events` — Domain events
- `/elixir/pragmatic/cqrs/reducer` — The reducer

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `pragmatic` `/` `cqrs` `/` `cqs` (`elixir`, `pragmatic`, `cqrs` linked; current segment `cqs`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.05` (→ `/elixir/pragmatic/cqrs`) `/` `cqs` (here).
- toc-mini: `#two` → "Change or read, not both"; `#code` → "In code".
- pager: prev → `/elixir/pragmatic/cqrs` label `← F5.05 · cqrs`; next → `/elixir/pragmatic/cqrs/events` label `Next · domain events →`.
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`; foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: `Command/query separation — F5.05.1 · jonnify`. `<meta name="description">`: `Command/query separation is one rule: a function either changes state and returns only whether it worked, or returns data and changes nothing — never both. enroll is a command, courses_of is a query. Keeping them apart makes queries safe to repeat and commands honest about what they do.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT dive on this burgundy chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/pragmatic/cqrs/events.html` (the next dive in this same module). Change only the `<title>`/`<meta description>`, the route-tag (`…/cqrs/cqs`), and the `<main>` body (hero, the command-or-query figure, the code block, the bridge, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and do not change the signatures shown here (`@spec enroll(String.t(), String.t()) :: :ok | {:error, atom}`, `@spec courses_of(String.t()) :: [Enrollment.t()]`) or introduce a read model from `enroll`; cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
