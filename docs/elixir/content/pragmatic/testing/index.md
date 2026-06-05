# F5.07 — Pragmatic testing (module hub)

- Route (served): `/elixir/pragmatic/testing`
- File: `elixir/pragmatic/testing/index.html`
- Place in the chapter: The seventh module of F5 · Pragmatic Programming. It frames how the framework-free Portal engine from F5.06 is tested, organising the work as a pyramid of three tiers and three deep dives — the pure core, property-based testing, and contract tests.
- Accent: burgundy (the F5 chapter accent; the page's `--burgundy` is `#c4504c`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5 · the engine · module 7`

Hero `h1`: Pragmatic *testing*

Hero lede (verbatim):

> The engine from F5.06 was built to be tested. Because `decide` and `evolve` are pure and state is a fold, most of the engine is checked with plain example tests — arrange a state, call a function, assert the result — with no processes and no mocks. Above those sit **property-based** tests that state an invariant and let `StreamData` generate hundreds of cases, and **contract** tests that turn the F5.04 contract into assertions, with doctests keeping the documentation honest. Pragmatic testing here is largely a dividend of the architecture: purity is what makes the tests cheap.

Kicker (verbatim):

> Three kinds of test, narrowing as they go. Select a tier to see what it checks and which dive builds it.

## What the page frames

The landing carries two in-page sections (`#pyramid`, `#dives`) and then the three dive cards.

The `.dives` (the three deep dives, each a card linking out):

- **F5.07.1 · Testing the pure core** — `decide` and `evolve` are pure, so a test is arrange a state, call, assert the output — no process, no mocks. Route: `/elixir/pragmatic/testing/pure-core`. Built.
- **F5.07.2 · Property-based testing** — state a rule true for all valid inputs — replay is deterministic, progress stays in `0..100` — and let `StreamData` generate the cases. Route: `/elixir/pragmatic/testing/property`. Built.
- **F5.07.3 · Contract tests** — the F5.04 precondition, postcondition, and invariant become assertions, and `doctest` runs the examples in the docs. Route: `/elixir/pragmatic/testing/contract-tests`. Built.

The `.bridge` framing pair: `F5.06 · the engine` (a supervised GenServer whose logic lives in pure `decide` and `evolve`, with state as a fold) → `F5.07 · test it` (examples on the pure core, properties over generated inputs, and the contract run as tests).

## The interactives

### Hero figure — "One example pins a point; one property covers a region"

- `<figure class="hero-fig">`, labelled by `id="hpTitle"`: `One example pins a point; one property covers a region`.
- Field group id: `hpField` (static default in markup: a single sage check-dot at `cx=120 cy=150` plus the caption text `one chosen case`).
- Controls: `id="hpGen"` button labelled `▸ generate cases` (toggles to `▸ back to one example`), and `id="hpReset"` ghost button labelled `reset`.
- Caption id: `hpCap` (`aria-live="polite"`). Initial readout strings (VERBATIM): `1 example · 1 input checked` / `An example test pins a single point in the input space.`. Generated readout strings (VERBATIM): `1 property · 100 inputs checked` / `A property states an invariant; the generator covers the region.`.
- Pure function: an inline `render()` over a fixed `GENERATED` array of deterministic SVG coordinates (22 listed points, no random, no time) representing the StreamData default of 100 cases; `checkDot(cx, cy, isNew)` builds each green-check dot.
- Degrade: the static SVG already shows the one example point (no render on load); `prefers-reduced-motion: reduce` disables the `hpIn` entry animation (`.hp-dot.hp-new`).

### Section figure — "The testing pyramid · select a tier"

- `<figure class="fig">` labelled by `id="tpTitle"`: `The testing pyramid · select a tier`.
- Control group `id="tpSel"` (`role="group"`, `aria-label="Test tier"`) with three buttons:
  - `data-k="core"` — label `pure core` (default active)
  - `data-k="property"` — label `properties`
  - `data-k="contract"` — label `contracts`
- SVG part ids highlighted on select: `tpPart_core`, `tpPart_property`, `tpPart_contract`.
- Readout ids: `tpOut` (`aria-live="polite"`), `tpRole` (tier name), `tpResult` (checks).
- The pure function `pick(k)` looks up the tier in the `TIERS` map and updates the readouts. The tier detail strings (VERBATIM): `core` → `example tests on decide/evolve`; `property` → `invariants over generated inputs`; `contract` → `the F5.04 contract, asserted`. Default selection on load is `core` (`tpRole` initial `Pure core`, `tpResult` initial `example tests on decide/evolve`).
- Degrade: the SVG renders its three labelled bands without JS; the `arc-flow` dash animation (shared CSS) is disabled under `prefers-reduced-motion: reduce`.

### Footer build-stamp

- `id="stamp"` carries `build` id `TSK0Nd4rswuNU0`; the inline branded-Snowflake decoder (`b62decode`, base62, epoch `1704067200000`) fills the `dl.panel`. Static printed timestamp: `2026-06-01 17:10:22 UTC`.

## References (#refs, verbatim)

Intro line: `Testing pure functions, generating cases, and running contracts as tests.`

Sources:

- [Elixir — ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) — the test framework.
- [StreamData](https://hexdocs.pm/stream_data/StreamData.html) — property-based testing.
- [Elixir — ExUnit.DocTest](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html) — contracts as runnable examples.

Related in this course:

- `/elixir/pragmatic/testing/pure-core` — F5.07.1 · Testing the pure core
- `/elixir/pragmatic/testing/property` — F5.07.2 · Property-based testing
- `/elixir/pragmatic/testing/contract-tests` — F5.07.3 · Contract tests
- `/elixir/pragmatic/state` — F5.06 · Where engine state lives — the engine under test.
- `/elixir/pragmatic/contracts` — F5.04 · Design by contract — the contract these tests run.

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `testing` — links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, current segment `testing` (`rcur`).
- crumbs (verbatim): `F5 · Pragmatic Programming` (→ `/elixir/pragmatic`) `/` `F5.07 · testing` (here).
- toc-mini: `#pyramid` → `A pyramid of tests`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/pragmatic` label `← F5 · overview`; next → `/elixir/pragmatic/testing/pure-core` label `Start · testing the pure core →`.
- footer: three columns. Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tagline: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta — `<title>`: `Pragmatic testing — F5.07 · jonnify`. `<meta description>`: `The engine was built to be tested: decide and evolve are pure and state is a fold, so most of it is checked with plain example tests — no processes, no mocks. Above those sit property-based tests that state an invariant and let StreamData generate the cases, and contract tests that run the F5.04 contract with doctests keeping the docs honest. Three dives on the pure core, property-based testing, and contract tests.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, `header`, `footer`, and the trailing two `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the natural model is this module's own dives such as `elixir/pragmatic/testing/pure-core.html`, or another F5 module hub (e.g. `elixir/pragmatic/state/index.html`). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body (hero, the `#pyramid` pyramid figure, the `#dives` three cards, the bridge, refs, and pager). Keep the no-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine (`decide`, `evolve`, `replay`) behind one Portal facade, and the Phoenix web app; cite the companion course for OTP internals and do not re-teach GenServer mechanics here. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/testing/pure-core.html`.
