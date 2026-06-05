# F5.07.2 — Property-based testing (dive)

- Route (served): `/elixir/pragmatic/testing/property`
- File: `elixir/pragmatic/testing/property.html`
- Place in the chapter: The second of the three F5.07 dives. It follows pure-core (example tests) and precedes contract-tests; where the first dive checked the cases you thought of, this dive states a rule over the cases the machine thinks of, with `StreamData` generating and shrinking inputs.
- Accent: burgundy (the F5 chapter accent). The interactive figure highlights its selected row in blue (`--blue` `#5a87c4` / fill `#11203a`), matching the dive card's blue left-border on the hub.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.07 · part 2 of 3`

Hero `h1`: Property-based testing

Hero lede (verbatim):

> An example test checks the cases you thought of; a property test checks a rule over the cases the machine thinks of. You state a **property** — something that must hold for every valid input — and `StreamData` generates hundreds of inputs trying to find one that breaks it, shrinking any failure to the smallest counterexample. The engine offers natural properties: replaying a log is **deterministic**, the F5.04 **invariant** (progress in `0..100`) survives any sequence of valid commands, and `decide` is **total** on valid input — it returns a tagged result rather than raising. These hold for the whole input space, not three hand-picked points.

Kicker (verbatim):

> Three properties of the engine. Select one to see the rule and what the generator throws at it.

## Sections

In order:

1. **Rules, not examples** (`#props`) — a property names something always true and quantifies it over generated inputs; on failure the framework shrinks to the smallest counterexample. Carries the interactive "engine property" figure.
2. **In code** (`#code`) — two properties with `ExUnitProperties`, `check all` drawing from generators.
3. **References** (`#refsTitle`, a reveal section).

Running example: the Portal engine's three laws — determinism of `replay`, the progress invariant, and totality of `decide`.

Real Elixir code shown (the `#code` block, verbatim tokens):

```elixir
use ExUnitProperties

property "folding a log is deterministic" do
  check all log <- list_of(event_generator()) do
    assert Engine.replay(log) == Engine.replay(log)
  end
end

property "progress stays within 0..100" do
  check all cmds <- list_of(command_generator()) do
    state = Enum.reduce(cmds, State.new(), &apply_command/2)
    assert Enum.all?(State.progresses(state), &(&1 in 0..100))
  end
end
```

## The interactives

### Section figure — "Engine property · select one"

- `<figure class="fig">` labelled by `id="prTitle"`: `Engine property · select one`.
- Control group `id="prSel"` (`role="group"`, `aria-label="Engine property"`) with three buttons:
  - `data-k="determinism"` — label `determinism` (default active)
  - `data-k="invariant"` — label `invariant`
  - `data-k="total"` — label `totality`
- SVG row ids highlighted on select: `prRow_determinism`, `prRow_invariant`, `prRow_total`. Each row prints a rule and a generator hint: `replay(log) == replay(log) · for any generated log` (gen: event logs); `progress in 0..100 · after any command sequence` (gen: commands); `decide → {:ok, _} | {:error, _} · never raises` (gen: valid commands).
- Readout ids: `prOut` (`aria-live="polite"`), `prRole` (property), `prResult` (the rule).
- Pure function `pick(k)` reads the `PROPS` map and updates readouts. The per-property `name`/`rule` strings (VERBATIM): `determinism` → `determinism` / `same log folds to the same state`; `invariant` → `invariant` / `progress stays in 0..100`; `total` → `totality` / `decide returns ok or error, never raises`. Default on load is `determinism` (`prRole` initial `determinism`, `prResult` initial `same log folds to the same state`).
- Degrade: the SVG renders its three labelled rows without JS; the shared `arc-flow` animation is disabled under `prefers-reduced-motion: reduce`.

### Footer build-stamp

- `id="stamp"` carries `build` id `TSK0Nd4rtQiG8m`; the inline branded-Snowflake decoder fills the `dl.panel` (base62, epoch `1704067200000`). Static printed timestamp: `2026-06-01 17:10:23 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- [Elixir — ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) — the test framework.
- [StreamData](https://hexdocs.pm/stream_data/StreamData.html) — property-based testing of the pure core.
- [Elixir — ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html) — examples in @doc become tests.

Related in this course:

- `/elixir/pragmatic/testing` — F5.07 · Pragmatic testing
- `/elixir/pragmatic/testing/pure-core` — Testing the pure core
- `/elixir/pragmatic/testing/contract-tests` — Contract tests

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `testing` ` / ` `property` — links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, `testing` → `/elixir/pragmatic/testing`, current segment `property` (`rcur`).
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.07` (→ `/elixir/pragmatic/testing`) `/` `property` (here).
- toc-mini: `#props` → `Rules, not examples`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/testing/pure-core` label `← F5.07.1 · pure-core`; next → `/elixir/pragmatic/testing/contract-tests` label `Next · contract tests →`.
- footer: identical three-column course nav as the hub (Chapters F1–F6; The course: `/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta — `<title>`: `Property-based testing — F5.07.2 · jonnify`. `<meta description>` (verbatim): `State a property true for every valid input and let StreamData generate hundreds of cases, shrinking any failure to the smallest counterexample. The engine's properties: replay is deterministic, the progress invariant survives any command sequence, and decide is total — it returns a tagged result, never raises.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the trailing two `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the closest model is a sibling dive in this same module, `elixir/pragmatic/testing/pure-core.html` (same dive shape: select figure → in-code → refs). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body (hero lede, the `#props` select figure with the blue-highlighted property rows, the `#code` `ExUnitProperties` block, the bridge, refs, and pager). Keep the no-invent guards: use only the real Portal surfaces as written — `Engine.replay/1`, `State.new/0`, `State.progresses/1`, the `decide → {:ok, _} | {:error, _}` totality shape, and generator helpers (`event_generator`, `command_generator`, `apply_command`) behind one Portal facade; cite the companion course for OTP internals and do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/testing/pure-core.html`.
