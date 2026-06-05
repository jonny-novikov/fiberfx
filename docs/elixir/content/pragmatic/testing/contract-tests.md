# F5.07.3 — Contract tests (dive)

- Route (served): `/elixir/pragmatic/testing/contract-tests`
- File: `elixir/pragmatic/testing/contract-tests.html`
- Place in the chapter: The third and last of the F5.07 dives, closing the testing arc (pure-core → property → contract-tests). It turns the F5.04 contract's three promises — precondition, postcondition, invariant — into assertions the suite runs, and adds `doctest` so the docs cannot drift; it points forward to F5.08 (Boundaries & integration seams).
- Accent: burgundy (the F5 chapter accent). The interactive figure highlights its selected row in gold (`--gold` `#d4a85a` / fill `#241d10`), matching the dive card's gold left-border on the hub.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.07 · part 3 of 3`

Hero `h1`: Contract tests

Hero lede (verbatim):

> The contract from F5.04 was three promises about a command: a **precondition** the caller must meet, a **postcondition** the command guarantees, and an **invariant** always true of the state. Written as documentation they describe behaviour; written as tests they enforce it. A precondition test feeds a bad command and asserts `{:error, reason}` with no state change; a postcondition test runs a valid command and asserts the guarantee; an invariant test asserts the rule on the resulting state. And `doctest` runs the `@doc` examples as tests, so the documentation cannot drift from the code. The contract stops being a comment and becomes something the suite checks.

Kicker (verbatim):

> Three promises, three assertions. Select a term to see what its test feeds in and checks.

## Sections

In order:

1. **A contract you can run** (`#terms`) — each clause of the contract maps to an assertion: a refused bad input, a checked guarantee, a property of the result, with doctests covering the examples in between. Carries the interactive "contract term as a test" figure.
2. **In code** (`#code`) — the contract terms as assertions and a one-line `doctest`.
3. **References** (`#refsTitle`, a reveal section).

Running example: the Portal engine's enroll/record-progress commands tested against the three F5.04 contract terms.

Real Elixir code shown (the `#code` block, verbatim tokens):

```elixir
# the F5.04 contract, now run as tests
test "enrolling twice is refused (precondition)" do
  state = Engine.evolve(%LearnerEnrolled{user_id: "u1"}, State.new())
  assert {:error, :already_enrolled} = Engine.decide(state, {:enroll, "u1", "c1"})
end

test "recording progress keeps it in 0..100 (invariant)" do
  {:ok, [event]} = Engine.decide(state, {:record_progress, "e1", 40})
  assert State.progress(Engine.evolve(event, state), "e1") in 0..100
end

doctest Portal.Engine   # the @doc examples run as tests, so the docs cannot drift
```

## The interactives

### Section figure — "Contract term as a test · select one"

- `<figure class="fig">` labelled by `id="ctTitle"`: `Contract term as a test · select one`.
- Control group `id="ctSel"` (`role="group"`, `aria-label="Contract term"`) with three buttons:
  - `data-k="precondition"` — label `precondition` (default active)
  - `data-k="postcondition"` — label `postcondition`
  - `data-k="invariant"` — label `invariant`
- SVG row ids highlighted on select: `ctRow_precondition`, `ctRow_postcondition`, `ctRow_invariant`. Each row prints the mapping and the contract role: `bad command → {:error, reason} · no state change` (caller must meet); `valid command → the event is emitted` (command guarantees); `resulting state → progress in 0..100` (always true of state).
- Readout ids: `ctOut` (`aria-live="polite"`), `ctRole` (term), `ctResult` (the test asserts).
- Pure function `pick(k)` reads the `TERMS` map and updates readouts. The per-term `name`/`asserts` strings (VERBATIM): `precondition` → `precondition` / `bad input returns {:error, _}`; `postcondition` → `postcondition` / `success emits the event`; `invariant` → `invariant` / `progress stays in 0..100`. Default on load is `precondition` (`ctRole` initial `precondition`, `ctResult` initial `bad input returns {:error, _}`).
- Degrade: the SVG renders its three labelled rows without JS; the shared `arc-flow` animation is disabled under `prefers-reduced-motion: reduce`.

### Footer build-stamp

- `id="stamp"` carries `build` id `TSK0Nd4rtfTOu8`; the inline branded-Snowflake decoder fills the `dl.panel` (base62, epoch `1704067200000`). Static printed timestamp: `2026-06-01 17:10:23 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- [Elixir — ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) — the test framework.
- [StreamData](https://hexdocs.pm/stream_data/StreamData.html) — property-based testing of the pure core.
- [Elixir — ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html) — examples in @doc become tests.

Related in this course:

- `/elixir/pragmatic/contracts` — F5.04 · Design by contract
- `/elixir/pragmatic/testing` — F5.07 · Pragmatic testing

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `testing` ` / ` `contract-tests` — links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, `testing` → `/elixir/pragmatic/testing`, current segment `contract-tests` (`rcur`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.07` (→ `/elixir/pragmatic/testing`) `/` `contract-tests` (here).
- toc-mini: `#terms` → `A contract you can run`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/testing/property` label `← F5.07.2 · property`; next → `/elixir/pragmatic/testing` label `Back to F5.07 →`.
- footer: identical three-column course nav as the hub (Chapters F1–F6; The course: `/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta — `<title>`: `Contract tests — F5.07.3 · jonnify`. `<meta description>` (verbatim): `The F5.04 contract written as tests: a precondition test feeds a bad command and asserts {:error, reason} with no state change, a postcondition test asserts the guarantee, an invariant test checks the rule on the result, and doctest runs the @doc examples so the documentation cannot drift from the code.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the trailing two `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the closest model is a sibling dive in this same module, `elixir/pragmatic/testing/pure-core.html` (same dive shape: select figure → in-code → refs). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body (hero lede, the `#terms` select figure with the gold-highlighted contract rows, the `#code` assertions plus `doctest`, the bridge, refs, and pager). Keep the no-invent guards: use only the real Portal surfaces as written — `Engine.decide/2`, `Engine.evolve/2`, `State.new/0`, `State.progress/2`, the `%LearnerEnrolled{}` event, the `{:enroll, ...}`/`{:record_progress, ...}` commands, and the `{:error, :already_enrolled}` shape behind one Portal facade; the contract terms must match F5.04 (`/elixir/pragmatic/contracts`) as written. Cite the companion course for OTP internals and do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/testing/pure-core.html`.
