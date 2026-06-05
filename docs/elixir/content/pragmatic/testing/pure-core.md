# F5.07.1 — Testing the pure core (dive)

- Route (served): `/elixir/pragmatic/testing/pure-core`
- File: `elixir/pragmatic/testing/pure-core.html`
- Place in the chapter: The first of the three F5.07 dives. It belongs to the testing arc that runs pure-core (example tests) → property (generators) → contract-tests (the F5.04 contract as assertions). This dive shows that because `decide`, `evolve`, and `replay` are pure, a test is arrange-call-assert with no machinery.
- Accent: burgundy (the F5 chapter accent; selected SVG rows use `--burgundy` `#c4504c` / fill `#1d1320`, readout colour `#e08f8b`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.07 · part 1 of 3`

Hero `h1`: Testing the pure core

Hero lede (verbatim):

> The engine's logic lives in pure functions: `decide` takes a state and a command and returns events, `evolve` takes a state and an event and returns the next state, and `replay` folds a log into a state. Pure means the same input always gives the same output and nothing else happens, so a test is three lines — **arrange** a value, **call** the function, **assert** the result. No process to start, no database to seed, no mocks to wire. This is the payoff of having pushed the work out of the GenServer and into functions in F5.05 and F5.06: the bulk of the engine is tested without any of the machinery around it.

Kicker (verbatim):

> Three pure functions, three plain tests. Select one to see what it takes and what the test asserts.

## Sections

In order:

1. **Arrange, call, assert** (`#funcs`) — each function is a value-to-value transformation, so a test gives an input and checks the output directly; carries the interactive "pure function under test" figure.
2. **In code** (`#code`) — three example tests as direct value checks, no `setup` block.
3. **Doctests on the pure core** (`#doctestsTitle`, a reveal section) — moving the example into the function's own `@doc`, parsed by `ExUnit.DocTest`, so documentation cannot drift.
4. **References** (`#refsTitle`, a reveal section).

Running example: the Portal engine's three pure functions tested against an enrollment/progress history.

Real Elixir code shown (the `#code` example-test block, verbatim tokens):

```elixir
# the pure core needs no process and no mocks — arrange, call, assert
test "decide on a fresh state emits LearnerEnrolled" do
  {:ok, [event]} = Engine.decide(State.new(), {:enroll, "u1", "c1"})
  assert %LearnerEnrolled{user_id: "u1"} = event
end

test "evolve folds an enrollment into the state" do
  state = Engine.evolve(%LearnerEnrolled{user_id: "u1"}, State.new())
  assert State.enrolled?(state, "u1")
end

test "replay folds a log to the current state" do
  assert Engine.replay([enrolled("u1"), progressed("u1", 40)]).progress["u1"] == 40
end
```

Doctest code (the `#doctestsTitle` block, verbatim): `defmodule Portal.Engine do` carries an `@doc` on `evolve/2` whose `iex>` example aliases `Portal.{Engine, State, LearnerEnrolled}`, evolves `%LearnerEnrolled{user_id: "u1"}` onto `State.new()`, and asserts `State.enrolled?(state, "u1")` returns `true`; the test module `Portal.EngineTest` does `use ExUnit.Case, async: true` and `doctest Portal.Engine`. The verbatim `mix test` comment closes: `2 doctests, 3 tests, 0 failures`.

## The interactives

### Section figure — "Pure function under test · select one"

- `<figure class="fig">` labelled by `id="pcTitle"`: `Pure function under test · select one`.
- Control group `id="pcSel"` (`role="group"`, `aria-label="Pure function"`) with three buttons:
  - `data-k="decide"` — label `decide` (default active)
  - `data-k="evolve"` — label `evolve`
  - `data-k="replay"` — label `replay`
- SVG row ids highlighted on select: `pcRow_decide`, `pcRow_evolve`, `pcRow_replay`. Each row prints a signature: `(state, command) → {:ok, events} | {:error, reason}`, `(event, state) → next_state`, `events → state  (Enum.reduce over evolve)`.
- Readout ids: `pcOut` (`aria-live="polite"`), `pcRole` (function), `pcResult` (the test).
- Pure function `pick(k)` reads the `FUNCS` map and updates readouts. The per-function `name`/`test` strings (VERBATIM): `decide` → `decide/2` / `asserts the events emitted`; `evolve` → `evolve/2` / `asserts the next state`; `replay` → `replay/1` / `asserts the folded state`. Default on load is `decide` (`pcRole` initial `decide/2`, `pcResult` initial `asserts the events emitted`).
- Degrade: the SVG renders its three labelled rows without JS; no animation depends on motion settings here beyond shared CSS.

### Footer build-stamp

- `id="stamp"` carries `build` id `TSK0Nd4rtCEiVU`; the inline branded-Snowflake decoder fills the `dl.panel` (base62, epoch `1704067200000`). Static printed timestamp: `2026-06-01 17:10:23 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- [Elixir — ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) — the test framework.
- [StreamData](https://hexdocs.pm/stream_data/StreamData.html) — property-based testing of the pure core.
- [Elixir — ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html) — examples in @doc become tests.

Related in this course:

- `/elixir/pragmatic/testing` — F5.07 · Pragmatic testing
- `/elixir/pragmatic/testing/property` — Property-based testing

(A second inline source link appears in the doctest prose: `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html`.)

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `testing` ` / ` `pure-core` — links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, `testing` → `/elixir/pragmatic/testing`, current segment `pure-core` (`rcur`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.07` (→ `/elixir/pragmatic/testing`) `/` `pure-core` (here).
- toc-mini: `#funcs` → `Arrange, call, assert`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/testing` label `← F5.07 · testing`; next → `/elixir/pragmatic/testing/property` label `Next · property-based testing →`.
- footer: identical three-column course nav as the hub (Chapters F1–F6; The course: `/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta — `<title>`: `Testing the pure core — F5.07.1 · jonnify`. `<meta description>`: `decide, evolve, and replay are pure functions, so a test is three lines: arrange a state, call the function, assert the output — no process to start, no database to seed, no mocks. This is the payoff of pushing the logic out of the GenServer and into functions: the bulk of the engine is tested without the machinery.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the trailing two `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the closest model is a sibling dive in this same module, `elixir/pragmatic/testing/contract-tests.html` (same four-section dive shape: select figure → in-code → reveal section → refs). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body (hero lede, the `#funcs` select figure, the `#code` example tests, the doctest reveal, refs, and pager). Keep the no-invent guards: use only the real Portal surfaces as written — `Engine.decide/2`, `Engine.evolve/2`, `Engine.replay/1`, `State.new/0`, `State.enrolled?/2`, the `%LearnerEnrolled{}` event, behind one Portal facade; cite the companion course for OTP internals and do not re-teach GenServer mechanics. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/testing/contract-tests.html`.
