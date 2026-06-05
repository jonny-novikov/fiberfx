# A6 — How you learn and build it here · orientation dive 3

- **Route:** `/course/agile-agent-workflow/reliability/how` (`reliability/how.html`)
- **Model:** `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`
- **Accent:** sage on interactive accents.
- **Eyebrow:** `A6 · orientation dive 3`
- **Crumbs:** `jonnify / Agile Agent Workflow / A6 · Reliability / How you build it`

## Open by echoing the reverse-verification link

A5 leaves a built increment correct on the happy path but not proven under failure; A6 is the method that hardens
that built increment against the four pillars and accepts it only when an invariant is proven, not asserted.

## Lead

The method is to harden the *built* increment from A5, not to rebuild it. Take what passes its demo and make it
production-grade: parse every boundary value, supervise every process, and accept the increment only when an
invariant is proven across generated inputs. A parsed boundary value is the only thing the core trusts.

## The method (how A6 runs)

1. **Parse at the boundary.** Untrusted input becomes a typed value at the edge or is rejected there. The core never
   re-checks; it trusts the type.
2. **Supervise every process.** A crash is isolated by a supervisor and the process restarts clean — the failure
   does not propagate.
3. **Prove, don't assert.** Acceptance closes only when a property test proves the invariant across generated
   inputs. An example asserts on a chosen few; a property proves over many.
4. **Accept against the proof, not the demo.** The Operator accepts the rung when the property holds, the boundary
   rejects malformed input, and the supervisor isolates a crash — the same review discipline A1.05 named.

## The Portal practice

The Portal's boundary parses untrusted input into a typed value: `Portal.ID.decode/1` turns a string into a struct
(carrying `.type` and `.timestamp`) or rejects it; `Portal.ID.generate/1` mints a fresh id. The core trusts only
the decoded struct. A supervisor isolates a crashed process. A property test proves that a generated id round-trips
through `generate` then `decode`. The supervision tree and the OTP mechanics are the companion `/elixir` course's —
cited, not re-taught. No Portal surface or API beyond `Portal.ID.generate/1` / `Portal.ID.decode/1` is invented.

## Interactives (two; teach different moves)

### 1 — Hero: assert-vs-prove

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#proveSel` (two buttons: "asserted on
  examples", "proven across generated inputs", `data-c="sage"`), a live `.geo-readout#proveOut`.
- **Fixed dataset:** an invariant (an id round-trips: `decode(generate()) == id`), a small example set (3 chosen
  examples), and a generated-input count (1000).
- **Pure functions:**
  - `coverage(mode) -> int` — `asserted` covers 3; `proven` covers 1000.
  - `readoutFor(mode) -> string`.
- **Sample readout (proven):** `Proven across generated inputs — the round-trip invariant decode(generate()) == id
  holds over 1000 generated inputs. Asserted on examples covers 3 chosen cases. A property test proves; an example
  asserts.`

### 2 — Content: the boundary parse gate

- **Container:** `<figure class="fig">` with `<svg>`, a `.solid-select#parseSel` (a set of input strings:
  well-formed id, malformed string, empty, `data-c="sage"`), a live `.geo-readout#parseOut`.
- **Fixed dataset:** three input strings and the boundary's verdict (typed value vs rejected) — modelling
  `Portal.ID.decode/1` as a total function returning a typed value or a rejection.
- **Pure functions:**
  - `decodeVerdict(input) -> {accepted, result}` (a pure model over the fixed strings — not a live decode).
  - `readoutFor(key) -> string`.
- **Sample readout (malformed):** `Boundary verdict for "not-an-id": rejected. The core never sees it; only a typed
  value crosses the boundary. Parse, don't validate — the typed value carries its guarantee inward.`

The hero proves *coverage* (a property covers 1000, an example covers 3); the content figure proves *the boundary's
totality* (every input is parsed to a typed value or rejected, none leaks through).

## Bridge

- **Idea:** harden the built increment against the four pillars; accept it only when an invariant is proven and a
  boundary value is the only thing the core trusts.
- **Portal:** `Portal.ID.decode/1` parses a string into a typed struct or rejects it; a property test proves a
  generated id round-trips; a supervisor isolates a crash. The OTP supervision mechanics are the companion
  `/elixir` course's, cited not re-taught.
- **Take:** a property test proves; an example asserts — A6 accepts the increment only against the proof.

## References

### Sources

- Parse, don't validate (King) — `https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/`
- Railway-oriented programming (Wlaschin) — `https://fsharpforfunandprofit.com/rop/`
- StreamData (property testing) — `https://hexdocs.pm/stream_data/StreamData.html`

### Related in this course

- `/course/agile-agent-workflow/reliability` — the chapter landing.
- `/course/agile-agent-workflow/reliability/what` — the previous dive (what A6 covers).
- `/course/agile-agent-workflow/why/correct` — A1.05, correct by definition: proven, not asserted.
- `/course/agile-agent-workflow/brief` — A5, the built increment A6 hardens.
- `/elixir/phoenix` — the real Portal web build.
- `/elixir/course` — the Portal's OTP foundations (cite, do not re-teach).

## Wiring

- Pager: prev `= /course/agile-agent-workflow/reliability/what`, next `= /course/agile-agent-workflow/portal`
  (the next chapter landing, A7 — built by the A7 sibling this batch; a `links` FAIL on this one route is the
  expected transient until A7 lands).
