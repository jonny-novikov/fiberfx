# A6 — Why reliability is its own layer · orientation dive 1

- **Route:** `/course/agile-agent-workflow/reliability/why` (`reliability/why.html`)
- **Model:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html` (orientation dive)
- **Accent:** sage on interactive accents (`data-c="sage"`, sage SVG fills); `h1 .ex` stays elixir-purple.
- **Eyebrow:** `A6 · orientation dive 1`
- **Crumbs:** `jonnify / Agile Agent Workflow / A6 · Reliability / Why reliability`

## Open by echoing the reverse-verification link

A5 produces a built increment that is correct on the happy path but not proven under failure. A6 exists to close
exactly that gap. The dive opens on this seam: a passing demo is not a production guarantee.

## Lead

A demo passes the inputs you chose. Production sends the inputs you did not. Three failures separate "it builds" from
"it survives": an unhandled malformed input, a crashed process that propagates, and an invariant held by luck rather
than proof. Reliability is its own layer because each of these is invisible to a happy-path demo and fatal in
production.

## The three failures A6 prevents

1. **An unhandled malformed input.** The demo sent a well-formed value; a real caller sends a garbled one. Without a
   boundary that parses or rejects, the malformed value travels inward and corrupts state far from where it entered.
2. **A crashed process that propagates.** One operation raises; without supervision the failure takes neighbours
   down with it. With supervision the crash is isolated and the process is restarted clean.
3. **An invariant held by luck.** The test asserted the property on three chosen examples; a fourth input the author
   never imagined breaks it. An asserted example is not a proven invariant.

## Interactives (two; teach different moves)

### 1 — Hero: happy-path-vs-production meter

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#modeSel` (two buttons: "happy path only",
  "production-grade", `data-c="sage"`), a live `.geo-readout#modeOut`.
- **Fixed dataset:** four input cases — valid, malformed, boundary, concurrent.
- **Pure functions:**
  - `survives(mode) -> int` — happy-path mode survives only the valid case (1 of 4); production-grade survives all
    four (4 of 4).
  - `readoutFor(mode) -> string`.
- **Sample readout (production-grade):** `Production-grade — 4 of 4 cases survive: valid, malformed (rejected at the
  boundary), boundary, concurrent. Happy path alone survives 1 of 4 — the valid case only. A demo passing is not a
  production guarantee.`

### 2 — Content: the three-failure ledger

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#failSel` (three buttons: malformed,
  crash, unproven, `data-c="sage"`), a live `.geo-readout#failOut`.
- **Fixed dataset:** the three failures, each with the pillar that prevents it (boundary, supervision, property
  test) and a one-line consequence-if-unhandled.
- **Pure functions:**
  - `prevention(key) -> {pillar, consequence}`.
  - `readoutFor(key) -> string`.
- **Sample readout (crash):** `A crashed process — without supervision the failure propagates and takes neighbours
  down; with an OTP supervisor the crash is isolated and the process restarts clean. Prevented by: supervision.`

The hero frames *the gap* (happy path covers 1 of 4); the content figure names *each specific failure and its
prevention*.

## Bridge

- **Idea:** a passing demo proves only the inputs you chose; production sends the inputs you did not, so reliability
  is separate work from the build.
- **Portal:** the Portal's boundary parses untrusted input — `Portal.ID.decode/1` returns a typed struct or rejects
  the string — and a supervisor isolates a crashed process; the OTP mechanics are the companion `/elixir` course's.
- **Take:** a demo passing the happy path is not a production guarantee; A6 is the layer that proves the rest.

## References

### Sources

- Parse, don't validate (King) — `https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/`
- Railway-oriented programming (Wlaschin) — `https://fsharpforfunandprofit.com/rop/`
- StreamData (property testing) — `https://hexdocs.pm/stream_data/StreamData.html`

### Related in this course

- `/course/agile-agent-workflow/brief` — A5, the built increment whose gap A6 closes.
- `/course/agile-agent-workflow/reliability` — the chapter landing.
- `/course/agile-agent-workflow/reliability/what` — the next dive (what A6 covers).
- `/course/agile-agent-workflow/why/correct` — A1.05, correct by definition.
- `/elixir/course` — the Portal's OTP foundations (cite, do not re-teach).

## Wiring

- Pager: prev `= /course/agile-agent-workflow/reliability` (landing), next `= /course/agile-agent-workflow/reliability/what`.
