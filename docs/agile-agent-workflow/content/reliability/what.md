# A6 — What the chapter covers · orientation dive 2

- **Route:** `/course/agile-agent-workflow/reliability/what` (`reliability/what.html`)
- **Model:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`
- **Accent:** sage on interactive accents.
- **Eyebrow:** `A6 · orientation dive 2`
- **Crumbs:** `jonnify / Agile Agent Workflow / A6 · Reliability / What it covers`

## Open by echoing the reverse-verification link

A5 leaves a built increment correct on the happy path but not proven under failure; A6 names the four pillars that
close that gap and orders them at roadmap altitude.

## Lead

A6 covers four pillars, each at roadmap altitude: OTP supervision, boundaries, parse-don't-validate, and property
tests. Each turns one happy-path weakness into a production guarantee. The module-by-module breakdown is deferred —
A6's triad is not yet seeded — so this dive names the scope, not invented detail.

## The four scope pillars (from the roadmap)

1. **OTP supervision** — a crash is isolated and recovered, not propagated. What it adds: a failing process is
   restarted clean instead of taking neighbours down.
2. **Boundaries** — untrusted input meets a single edge before it reaches the core. What it adds: the core trusts
   only values that crossed the boundary.
3. **Parse-don't-validate** — the boundary turns an untrusted string into a typed value or rejects it there. What it
   adds: the typed value carries its own guarantee inward; no downstream re-check.
4. **Property tests** — an invariant is proven across generated inputs, not asserted on a chosen few. What it adds:
   a property holds over thousands of generated inputs, not three examples.

## Interactives (two; teach different moves)

### 1 — Hero: scope-pillar selector

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#pillarSel` (four pillar buttons,
  `data-c="sage"`), a live `.geo-readout#pillarOut`.
- **Fixed dataset:** the four pillars, each with the failure it addresses and the companion `/elixir` course that
  teaches its OTP mechanics (the readout names the companion `/elixir/course`; it is cited as text, not linked from
  the SVG — the only `/elixir` links on the page are the verified `/elixir/course` and `/elixir/phoenix` in refs).
- **Pure functions:**
  - `pillarOf(key) -> {name, failure, companion}`.
  - `readoutFor(key) -> string`.
- **Sample readout (supervision):** `OTP supervision — addresses a crashed process that propagates; a supervisor
  isolates the crash and restarts the process clean. The OTP mechanics are taught by the companion /elixir course —
  cited here, not re-taught.`

### 2 — Content: the coverage matrix

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#coverSel` (a count slider or four toggle
  buttons, `data-c="sage"`), a live `.geo-readout#coverOut`.
- **Fixed dataset:** four failure cases × the pillar that covers each. Enabling a pillar covers its case.
- **Pure functions:**
  - `covered(onSet) -> int`.
  - `readoutFor(onSet) -> string`.
- **Sample readout (all four):** `4 of 4 failure cases covered — each pillar closes exactly one: boundary +
  parse-don't-validate close malformed input, supervision closes a propagating crash, property tests close an
  unproven invariant. With no pillar, 0 of 4.`

The hero names *each pillar and where its OTP mechanics live*; the content figure proves *the coverage is complete
only when all four pillars are present*.

## Bridge

- **Idea:** production-readiness is four named techniques — supervision, boundaries, parse-don't-validate, property
  tests — each closing a specific happy-path weakness.
- **Portal:** the Portal's boundary parses input into a typed value (`Portal.ID.decode/1`), a supervisor isolates a
  crash, and a property test proves an id round-trips; the supervision tree and OTP mechanics are the companion
  `/elixir` course's, cited not re-taught.
- **Take:** A6's scope is four pillars; the module set that teaches them is detailed once the triad is seeded.

## The deferral note

> The module-by-module breakdown of A6 is deferred until its triad (`a6.{md,stories.md,llms.md}`) is seeded. This
> dive names the chapter's scope at roadmap altitude — the four pillars — not an invented module list.

## References

### Sources

- Parse, don't validate (King) — `https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/`
- Railway-oriented programming (Wlaschin) — `https://fsharpforfunandprofit.com/rop/`
- StreamData (property testing) — `https://hexdocs.pm/stream_data/StreamData.html`
- Continuous Delivery (Humble & Farley) — `https://continuousdelivery.com/`

### Related in this course

- `/course/agile-agent-workflow/reliability` — the chapter landing.
- `/course/agile-agent-workflow/reliability/why` — the previous dive (the failure A6 prevents).
- `/course/agile-agent-workflow/reliability/how` — the next dive (how you build it).
- `/course/agile-agent-workflow/spec` — A4, the spec that defines done.
- `/elixir/phoenix` — the real Portal web build.
- `/elixir/course` — the Portal's OTP foundations (cite, do not re-teach).

## Wiring

- Pager: prev `= /course/agile-agent-workflow/reliability/why`, next `= /course/agile-agent-workflow/reliability/how`.
