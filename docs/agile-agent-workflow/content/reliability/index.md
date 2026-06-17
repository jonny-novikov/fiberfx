# A6 — Reliability and correctness · chapter landing

- **Route:** `/course/agile-agent-workflow/reliability` (`reliability/index.html`)
- **Model:** `html/agile-agent-workflow/roadmap/index.html` (chapter landing)
- **Accent:** sage (`--sage` / `--sage-bright`). The shared `h1 .ex` rule renders elixir-purple, which is kept
  course-wide; sage is applied only to the *interactive accents* (`data-c="sage"` on `.solid-select` buttons, sage
  SVG fills).
- **Eyebrow:** `A6 · chapter overview`
- **Crumbs:** `Agile Agent Workflow / A6 · Reliability and correctness` (two-element landing form).

## Grounding — NO TRIAD

A6 has **no seeded triad** (`a6.{md,stories.md,llms.md}` does not exist). The chapter is grounded **only** on
`aaw.roadmap.md` (Part VI: *the increment built to production quality*) and the `aaw.progress.md` line ("scope not
yet enumerated"). A6's scope, named only at the roadmap's altitude, is the four pillars: **OTP supervision ·
boundaries · parse-don't-validate · property tests**. No A6 module is invented or enumerated. The landing replaces
the module-cards grid with an honest deferral `.note`.

## Lead

A5 leaves a built increment that passes its own demo. A6 makes it production-grade: it survives a malformed input,
a crashed process, and an invariant proven across generated inputs rather than asserted on a chosen few. "It builds
and the demo passes" is not yet "it survives production"; A6 closes that gap.

## The whole-course seam (reverse verification)

A6's reason-to-exist is the gap A5 leaves. A5 produces a built increment correct on the happy path but not proven
under failure. A6 names exactly what production-readiness A5 leaves unproven — supervision, boundaries, properties —
and closes it. This is the load-bearing seam: the chapter exists for the precise deficit the previous chapter
leaves, not for an abstract virtue.

## Interactives (two; the framing one is mandatory on a landing)

### 1 — Hero framing interactive: the course-arc selector, re-centred on A6

- **Container:** `<figure class="fig">` with `<svg>` spine of eight nodes A0–A7, a `.solid-select#arcSel`, a live
  `.geo-readout#arcOut`.
- **Fixed dataset:** the eight parts. Status: A0–A4 `built`, A5 `built` (ships before A6), A6 `here`, A7 `planned`.
- **Pure functions:**
  - `partsBefore(i) -> int` — count of `built` parts before index i.
  - `readoutFor(i) -> string` — the readout. For A6 (`here`) the tail names *what A5 leaves unproven*: the
    production-readiness gap A6 closes.
- **Buttons carry `data-c="sage"`**; the active SVG node is highlighted sage-bright.
- **Sample readout (A6 selected):** `A6 · Reliability and correctness — /reliability. Delivers: an increment built
  to production quality — supervision, boundaries that parse-don't-validate, and properties proven across generated
  inputs. Status: you are here. · 6 of 8 parts built before this one; A5 leaves a built increment correct on the
  happy path but not proven under failure — that gap is what this chapter closes.`

### 2 — Main-content interactive: the four-pillar survival meter

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#guardSel` (four pillar buttons +
  one "none" button, `data-c="sage"`), a live `.geo-readout#guardOut`.
- **Fixed dataset:** four failure cases (malformed input, crashed process, unproven invariant, concurrent access)
  and the four pillars that each address one. A "happy-path only" build addresses none; each pillar toggled on
  closes one case.
- **Pure functions:**
  - `survivors(onSet) -> int` — count of cases covered by the set of enabled pillars.
  - `readoutFor(key) -> string`.
- **Sample readout (all four on):** `Production-grade — 4 of 4 failure cases survive: a malformed input is parsed
  or rejected at the boundary, a crashed process is isolated by a supervisor, an invariant is proven across
  generated inputs, concurrent access holds. A demo passing the happy path covers 0 of 4.`

These teach different moves: the hero frames *where A6 sits and the gap it closes*; the content figure proves *the
consequence* — a happy-path build covers none of the four failure cases, the four pillars together cover all.

## Bridge (principle → Portal practice)

- **Idea:** A built increment that passes its demo is not yet production-grade; production-readiness is supervision,
  boundaries, and proven invariants — separate work from the build.
- **Portal:** the Portal's boundary parses untrusted input into a typed value (`Portal.ID.decode/1` turns a string
  into a struct or rejects it; `Portal.ID.generate/1` mints one), a supervisor isolates a crash, and a property
  test proves an id round-trips across generated inputs. The OTP mechanics are taught by the companion `/elixir`
  course — cited, not re-taught.
- **Take:** A6 turns a built increment into one that survives a malformed input, a crashed process, and an
  unproven invariant.

## The deferral note (load-bearing)

> A6's modules will be enumerated when its triad (`a6.{md,stories.md,llms.md}`) is seeded. The chapter's scope, per
> the course roadmap, is OTP supervision, boundaries that parse-don't-validate, and property tests — the techniques
> that turn a built increment into a production-grade one.

No module cards. The scope is named at roadmap altitude; the module set is deferred.

## References

### Sources (real, vetted; from the home registry)

- Parse, don't validate (King) — `https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/`
- Railway-oriented programming (Wlaschin) — `https://fsharpforfunandprofit.com/rop/`
- StreamData (property testing) — `https://hexdocs.pm/stream_data/StreamData.html`
- Continuous Delivery (Humble & Farley) — `https://continuousdelivery.com/`

### Related in this course

- `/course/agile-agent-workflow/brief` — A5, the built increment A6 hardens.
- `/course/agile-agent-workflow/spec` — A4, the spec that defines done.
- `/course/agile-agent-workflow/why/correct` — A1.05, correct by definition.
- `/course/agile-agent-workflow/why/loop` — A1.03, the Author/Operator loop.
- `/elixir/phoenix` — the real Portal web build.
- `/elixir/course` — the Portal's Elixir and OTP foundations (OTP internals — cite, do not re-teach).

## Wiring

- Pager: prev `= /course/agile-agent-workflow/brief` (A5 landing — built by the A5 sibling this batch; a `links`
  FAIL on this one route is the expected transient until A5 lands), next `= /course/agile-agent-workflow/reliability/why`.
- The three dive cards (`why`/`what`/`how`) are real `<a class="mod">` with `built` pills.
