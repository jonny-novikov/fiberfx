# F5.0.3 — The command & event flow (dive — design front-matter)

- Route (served): `/elixir/pragmatic/flow`
- File: `elixir/pragmatic/flow.html`
- Place in the chapter: the third and last of three design front-matter pages on the F5 landing (3 of 3). With structure (the blueprint) and data (the domain model) set, this page fixes how the engine moves — the command → contract → event → state → query path the UI will see. It follows `F5.0.2 · The domain model` and returns the reader to the chapter to start F5.01.
- Accent: burgundy (`--burgundy:#c4504c`; active stage chip stroke `#c4504c`, highlight text `#e08f8b`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Hero lede (verbatim):

> The structure and the data are set; the last piece of the design is how the engine moves. Every change follows the same path: a **command** states an intent, a **contract** checks it, a domain **event** records what happened, the event transitions **state**, and a separate **query** reads a projection. Writes and reads never share a door — commands change the world and return events, queries read the world and change nothing — so the surface the UI calls stays small and predictable. This is the flow F5.04, F5.05, and F5.06 build.

Eyebrow (verbatim): `F5 · system design · 3 of 3`

Kicker (verbatim):

> Follow one use case — enrolling a learner. Select a stage to see what it does and which module builds it.

h1 (verbatim): `The command & event ` + `flow` (`.ex` accent span).

## Sections

In order:

1. `#pipeline` — "One use case, five stages". Teaching section. Carries the interactive flow figure. Prose: the write path is the first four stages left to right, the read path is the fifth on its own; because only events change state the engine has one auditable list of what happened, and because queries are pure the UI can read freely; enrolling a learner walks the whole path once. `.take` (verbatim): "One path for every change, and a separate one for every read. Decide the flow once, here, and each command the engine grows later slots into the same five stages."
2. `#dispatch` — "The flow in code". Advanced/code section. Shows the write path as a `with` chain and the read path as a pure function, plus a `.bridge` and a closing `.note`.

Running example: enrolling a learner — `EnrollLearner` command → contract check → `LearnerEnrolled` event → state transition → `courses_of` query.

Real Elixir code shown (the `#dispatch` `pre.code`, verbatim):

```
# write: command -> contract (F5.04) -> event (F5.05) -> state (F5.06)
def dispatch(%EnrollLearner{} = cmd, state) do
  with :ok           <- check(cmd, state),                  # contract — or {:error, reason}
       event       = build_event(cmd),                     # %LearnerEnrolled{...}
       next_state  = apply_event(state, event) do        # pure reducer
    {:ok, event, next_state}
  end
end

# read: a pure projection — no command, no side effects (F5.05)
def query(:courses_of, user_id, state), do: Map.get(state.enrollments, user_id, [])
```

`.bridge` cells (verbatim): idea "a command" — "An intent the UI submits — `EnrollLearner`." → elix "an event, then new state" — "Checked, recorded as `LearnerEnrolled`, applied by a pure reducer." `.note` (verbatim): "That completes the design brief — structure, data, and flow. Back to [the chapter overview](/elixir/pragmatic) to start F5.01, or revisit [the blueprint](/elixir/pragmatic/architecture) and [the domain model](/elixir/pragmatic/domain-model)."

## The interactives

### `#pipeline` figure — "The flow · select a stage" (`#flSel` selector + `#flCode`/`#flOut` readouts)

- Markup: `<figure class="fig" aria-labelledby="flTitle">` titled "The flow · select a stage". Inside: a `.controls` > `.solid-select#flSel` group, an `<svg viewBox="0 0 720 180">` with five stage chips (`<rect>` + label `<text>`s) and write-path arrows (the fourth dashed into the read path), a `pre.code#flCode` (`aria-live="polite"`), a `.geo-readout#flOut` (`aria-live="polite"`), plus two mono lines `stage:` (`#flRole`) and `built by:` (`#flResult`).
- Control ids / buttons: `#flSel` group, `role="group"`, `aria-label="Flow stage"`. Five `<button data-k>`s: `command` ("command", starts `active`), `contract` ("contract"), `event` ("event"), `state` ("state"), `query` ("query").
- SVG element ids: chips `#flChip_command`, `#flChip_contract`, `#flChip_event`, `#flChip_state`, `#flChip_query`. Static sub-labels in markup: `EnrollLearner`, `preconditions`, `LearnerEnrolled`, `apply event`, `read projection`; captions "write path · only events change state" and "read path".
- Pure function: `pick(k)` — toggles each `#flSel` button's `active`/`aria-pressed` by `data-k === k`; for each id in `ORDER ['command','contract','event','state','query']` sets the matching chip `stroke`/`stroke-width`/`fill` (on: `#c4504c` / `2` / `#1d1320`; off: `#3a4263` / `1.3` / `#10162b`); writes `k` into `#flRole`, `S.by` into `#flResult`, a generated comment + `S.code` line into `#flCode.innerHTML`, and an HTML readout into `#flOut`. Wired by `addEventListener('click', …)` per button; initial call `pick('command')`.
- Readout payloads (`STAGES`, verbatim `by` / `code` / `desc`; `#flOut` renders ``The <b>{k}</b> stage — built by <b>{by}</b>. {desc}``; `#flCode` renders ``# {k} — {by}`` then `code`):
  - command: by "F5.05", code ``%EnrollLearner{user_id: "USR0Nb...", course_id: "CRS0Nb..."}   # the intent``, desc "The write request: a struct naming an intent and its arguments. The UI builds it and hands it to `dispatch/1` — nothing has changed yet."
  - contract: by "F5.04", code ``:ok <- check(cmd, state)   # or {:error, :already_enrolled}``, desc "The command is checked against the engine's rules — here, that the learner is not already enrolled. A failed precondition stops the flow with a tagged error before any state changes."
  - event: by "F5.05", code ``event = %LearnerEnrolled{user_id: ..., course_id: ..., at: ts}``, desc "If the contract holds, the command produces a domain event — a past-tense fact, **LearnerEnrolled**. Events are the only thing that changes state."
  - state: by "F5.06", code ``next_state = apply_event(state, event)   # a pure reducer``, desc "A pure reducer applies the event to the current state, producing the next state. Where that state lives — GenServer, ETS — is F5.06's question."
  - query: by "F5.05", code ``query(:courses_of, user_id, state)   # no side effects``, desc "Reads never go through commands: a query returns a projection of the current state — a learner's courses — with no side effects. The read half of the split."
- Degrades: the `command` button ships `active` and the mono lines default to `command` / `F5.05`; `#flCode`/`#flOut` are empty in static markup until `pick('command')` fills them on load. Respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id (`#stampId`): `TSK0NclTctDKRU`; panel `#st-ts` hard-codes `2026-06-01 12:39:01 UTC`.
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoded namespace `TSK`; decoded timestamp matches `2026-06-01 12:39:01 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "Separating writes from reads, and modeling change as events."

Sources:
- [Martin Fowler — CQRS](https://martinfowler.com/bliki/CQRS.html) — the command/query split.
- [Martin Fowler — Domain Event](https://martinfowler.com/eaaDev/DomainEvent.html) — change as a past-tense fact.
- [Elixir — `with`](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#with/1) — the happy-path chain that fails fast.

Related in this course:
- `F5.0.1 · The Portal engine blueprint` → `/elixir/pragmatic/architecture` — where dispatch and query live.
- `F5.0.2 · The domain model` → `/elixir/pragmatic/domain-model` — the entities the events change.
- `F4.09 · Branded CHAMP maps & GenServer` → `/elixir/algorithms/branded-champ` — where engine state is kept.
- `F5 · Pragmatic Programming` → `/elixir/pragmatic`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><span class="rcur">flow</span>` — i.e. `/ elixir / pragmatic / flow`.
- crumbs (verbatim): `Contents` → `/elixir/course` · sep `/` · `F5 · Pragmatic Programming` → `/elixir/pragmatic` · sep `/` · here `The command & event flow` (no link).
- toc-mini: `#pipeline` ("One use case, five stages") · `#dispatch` ("The flow in code").
- pager: prev → `/elixir/pragmatic/domain-model` ("← F5.0.2 · the domain model"); next → `/elixir/pragmatic` ("Back to the chapter →").
- footer (3-column `foot-nav`): identical to the chapter siblings — brand `.foot-logo` → `/elixir`; Chapters column `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework"); The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "The command & event flow — F5.0.3 · jonnify"; `<meta description>` "How one use case moves through the engine: a command is checked against a contract, emits a domain event, the event transitions state, and a query reads a projection. The write path and the read path are kept separate, so the engine the UI calls has a predictable surface — the flow F5.04, F5.05, and F5.06 build."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built design sibling on this burgundy chapter — the model is `elixir/pragmatic/domain-model.html` (the preceding design front-matter sibling, same hero/figure-with-generated-code/refs anatomy) — then change only `<title>`/`<meta description>`, the `.route-tag` (last segment `<span class="rcur">flow</span>`), the crumbs/eyebrow ("3 of 3"), and the `<main>` body. Keep the `#flSel` selector + `pick(k)` shape (it generates `#flCode` and `#flOut` on select); ship the `command` button `active` for the default state. No-invent guards: use only the real Portal surfaces as written — the command → contract → event → state → query flow behind the one `Portal.Engine` facade (`dispatch/1` as a `with` chain that fails fast, `query/2` as a pure projection), domain events as past-tense facts, a pure reducer over state — and attribute the stages to their building modules (F5.04 contracts, F5.05 events/queries, F5.06 state) without re-teaching OTP internals; cite `F4` for the store. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
