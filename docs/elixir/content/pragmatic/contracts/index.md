# F5.04 — Design by contract (module hub)

- **Route (served):** `/elixir/pragmatic/contracts`
- **File:** `/Users/jonny/dev/jonnify/elixir/pragmatic/contracts/index.html`
- **Place in the chapter:** the fourth module hub of F5 · Pragmatic Programming. It follows F5.03 (tracer-bullets — the walking skeleton runs end to end) and precedes F5.05 (commands, queries & events). It frames three deep dives that make the `enroll` command honest — the contract triad, the Elixir idioms that express it, and failing fast at the boundary.
- **Accent:** burgundy (`--burgundy:#c4504c`; the precondition rect and the `F5.04.1` dive rail are burgundy, `#e08f8b`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5 · the engine · module 4`

Hero `h1` (verbatim): `Design by contract` (the word `contract` is the `.ex` accent span).

Hero lede (`<p class="lede">`, verbatim): "The walking skeleton runs, but its commands trust whatever they are handed. **Design by contract** makes that trust explicit. Every command carries three terms: a **precondition** the caller must satisfy to call it, a **postcondition** the command guarantees on success, and an **invariant** that is always true of the state, before and after. For `enroll`: the ids must be valid and the learner not already on the course; on success a fresh `%Enrollment{}` with `progress: 0` is returned and stored; and progress never leaves `0..100`. Elixir has no contract keywords, so these are written as guards, `with` chains, and tagged tuples — and they fail fast, at the boundary, before anything can be corrupted."

Kicker (`<p class="kicker">`, verbatim): "A contract wraps a command on three sides. Select a term to see what it says for `enroll` and who is responsible for it."

## What the page frames

The hub presents the `#contract` section (the contract-triad figure) and the `#dives` section, a `.dives`-style list of three deep-dive cards (each a full-card `<a>`, not the `.mods` grid). All three are built. The cards carry burgundy/blue/gold left-rails respectively.

- **F5.04.1 · Preconditions, postconditions & invariants** — burgundy rail. One-line: "Three terms, three owners: the caller meets the precondition, the function guarantees the postcondition, every operation preserves the invariant." Route: `/elixir/pragmatic/contracts/conditions`. Built.
- **F5.04.2 · Assertions in Elixir** — blue rail. One-line: "Guards for shape, a `with` chain to compose checks, tagged tuples for expected failures, and `raise` for broken invariants." Route: `/elixir/pragmatic/contracts/assertions`. Built.
- **F5.04.3 · Failing fast** — gold rail. One-line: "Stop on the first violation, at the boundary, before any state changes — an error close to its cause beats corruption far from it." Route: `/elixir/pragmatic/contracts/fail-fast`. Built.

The `.bridge` after the cards frames the arc from F5.03 to F5.04: "F5.03 · the slice runs" / "Enroll travels every layer, but it trusts its inputs and promises nothing in particular." → "F5.04 · make the command honest" / "State its precondition, guarantee its postcondition, preserve the invariant — and fail fast when broken."

The closing `.note` (verbatim): "Start with [the three conditions](/elixir/pragmatic/contracts/conditions), then [assertions in Elixir](/elixir/pragmatic/contracts/assertions), then [failing fast](/elixir/pragmatic/contracts/fail-fast). The next module, F5.05 — Commands, queries & events, separates writes from reads and models each change as an event. For the runtime path the contract guards, see the design brief: [the command & event flow](/elixir/pragmatic/flow)."

## The interactives

This hub carries two figures plus the footer build-stamp decoder.

### Hero figure — "Where a violation is caught" (`#ffChain` + `#ffCap`)

- **`<figure class="hero-fig" aria-labelledby="ffTitle">`** titled "Where a violation is caught" (`#ffTitle`).
- **Markup:** an SVG (`viewBox="0 0 320 300"`) with a static initial state in `<g id="ffChain">` — three `.hp-row` rows: `boundary gate` ("precondition stops it here"), `command` ("never runs"), `store` ("untouched"). A dashed descent line carries the label "A CALL WITH progress: 250".
- **Controls:** `<button id="ffBtn">` ("▸ drop the precondition" / toggles to "▸ restore the precondition") and `<button id="ffReset">` ("reset"). No `data-key` attributes; the toggle is boolean `guarded`.
- **Pure function:** `render()` rebuilds `#ffChain` from the `GUARDED` or `UNGUARDED` row dataset and rewrites `#ffCap`/`#ffBtn`. `row(...)` builds each `<g class="hp-row">` with `el(name, attrs)`.
  - `GUARDED` rows: `boundary gate` / "precondition stops it here"; `command` / "never runs"; `store` / "untouched".
  - `UNGUARDED` rows: `boundary gate` / "no precondition — passes"; `command` / "runs on bad input"; `store` / "corrupted far from the cause".
- **Readout strings (`#ffCap`, verbatim):**
  - guarded (default in markup): "caught at the gate · store intact" / "A precondition fails fast: the error lands at its cause."
  - unguarded: "passes the gate · store corrupted" / "Without the check, the violation is found far from its cause."
- **Degrades:** the guarded three-row chain + the default caption are present in static markup; JS only enhances. The new bottom row animates via `.hp-new` (`@keyframes hpIn`), disabled under `prefers-reduced-motion: reduce`. No browser storage.

### Content figure — "The enroll contract · select a term" (`#ctSel` + `#ctOut`)

- **`<figure class="fig" aria-labelledby="ctTitle">`** titled "The enroll contract · select a term" (`#ctTitle`).
- **Control group `#ctSel`** (role="group"), three `<button>`s by `data-k` (no `data-c`):
  - `data-k="pre"` — label "precondition" — starts `active`
  - `data-k="post"` — label "postcondition"
  - `data-k="invariant"` — label "invariant"
- **SVG rect ids:** `#ctPart_pre` (burgundy stroke `#c4504c`), `#ctPart_post`, `#ctPart_invariant`. The diagram lays out PRECONDITION ("valid ids, not enrolled") → COMMAND ("enroll(user_id, course_id)") → POSTCONDITION ("{:ok, %Enrollment{}}"), with the INVARIANT band ("0 <= progress <= 100 · user_id is always a USR") under all three.
- **Pure function:** `pick(k)` over `TERMS {pre, post, invariant}` — toggles each `#ctSel` button's `active` class + `aria-pressed`, sets the matching `#ctPart_*` rect's `stroke`/`stroke-width`/`fill` (on = `#c4504c`/`2`/`#1d1320`, off = `#3a4263`/`1.3`/`#10162b`), writes `T.name` into `#ctRole`, `T.detail` into `#ctResult`, and the composed sentence into `#ctOut.innerHTML`. Initial call `pick('pre')`.
- **Readout strings (`TERMS`, verbatim — `#ctOut` is composed as ``The <b>{name}</b> — for enroll, <code class="inl">{detail}</code>. {desc}``):**
  - pre: name "Precondition", detail "valid ids, not already enrolled", desc "What must be true to call enroll — the caller's obligation. The user_id is a USR, the course_id a CRS, and the learner is not already on the course. If it fails, the command never runs."
  - post: name "Postcondition", detail "{:ok, %Enrollment{progress: 0}}", desc "What enroll guarantees on success — the function's promise. A fresh Enrollment with a branded id and progress 0, written to the store. The caller can rely on this without re-checking."
  - invariant: name "Invariant", detail "0 <= progress <= 100", desc "What is always true of an enrollment, before and after every operation. Progress never leaves 0..100; the user_id is always a USR. Breaking one is a bug, not a bad request."
- **Static readout fallbacks (in markup):** `#ctRole` = "Precondition"; `#ctResult` = "valid ids, not already enrolled"; `#ctOut` is empty until JS runs.
- **Take (verbatim):** "A contract turns assumptions into checks. Once the three terms are written down, "is this safe to call" has an answer in the code, not in your head."

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0Ncv17QZRg0` (in `#stampId`); `#st-ts` hard-codes "2026-06-01 14:52:31 UTC".
- **Decoder:** `decodeBranded(id)` splits `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoding `TSK0Ncv17QZRg0` yields **2026-06-01 14:52:31 UTC** (node 0, seq 0), matching the markup. Toggle on click / Enter / Space sets `.open` + `aria-expanded`.

## References (#refs, verbatim)

Intro line: "Contracts on functions, and the Elixir idioms that express them."

**Sources**
- [Bertrand Meyer — Design by Contract](https://en.wikipedia.org/wiki/Design_by_contract) — preconditions, postconditions, invariants.
- [Elixir — Patterns and guards](https://hexdocs.pm/elixir/patterns-and-guards.html) — checks at the boundary.
- [Elixir — `with`](https://hexdocs.pm/elixir/Kernel.SpecialForms.html#with/1) — happy-path composition that fails fast.

**Related in this course**
- F5.04.1 · Preconditions, postconditions & invariants → `/elixir/pragmatic/contracts/conditions`
- F5.04.2 · Assertions in Elixir → `/elixir/pragmatic/contracts/assertions`
- F5.04.3 · Failing fast → `/elixir/pragmatic/contracts/fail-fast`
- F5.02.3 · A context's public API → `/elixir/pragmatic/domain/api` — where the contract lives.
- F5.03.2 · The walking skeleton → `/elixir/pragmatic/tracer-bullets/skeleton` — the enroll command being hardened.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><span class="rcur">contracts</span>` (current segment `contracts` is `.rcur`, not a link).
- **crumbs:** `F5 · Pragmatic Programming` → `/elixir/pragmatic` · sep `/` · here `F5.04 · contracts` (no link).
- **toc-mini:** `#contract` ("The contract triad") · `#dives` ("Three deep dives").
- **pager:** prev → `/elixir/pragmatic` ("← F5 · overview"); next → `/elixir/pragmatic/contracts/conditions` ("Start · the three conditions →").
- **footer (3-column `foot-nav`):**
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Brand (header `.brand`) and footer logo (`.foot-logo`) both point at `/elixir`.
- **Page meta:** `<title>` "Design by contract — F5.04 · jonnify"; `<meta description>` "Every command on the engine carries a contract: a precondition the caller must meet, a postcondition the function guarantees, and an invariant always true of the state. F5.04 makes the enroll command honest — expressing those conditions in idiomatic Elixir with guards, with chains, tagged tuples, and raises, and failing fast at the boundary so a violation stops the command before it can corrupt anything. Three dives on the conditions, the Elixir assertions, and failing fast."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent — the closest model is the dive page `/elixir/pragmatic/contracts/conditions` (`conditions.html`); change only `<title>`/`<meta description>`, the `.route-tag` current segment, and the `<main>` body (hero, the two figures, the dive-card list, the `.bridge`, the `.note`, and the `#refs` block). Keep the no-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.Store`, `Portal.ID.new("ENR")`), the event-sourced engine behind the one `Portal` facade, the `%Enrollment{}` struct, the `0..100` progress invariant — and do not re-teach OTP internals (cite the companion course instead). Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `conditions.html` (this module's part 1 of 3, same burgundy accent and footer).
