# F5.04.1 — Preconditions, postconditions & invariants (dive)

- **Route (served):** `/elixir/pragmatic/contracts/conditions`
- **File:** `/Users/jonny/dev/jonnify/elixir/pragmatic/contracts/conditions.html`
- **Place in the chapter:** part 1 of 3 of module F5.04 · Design by contract (chapter F5 · Pragmatic Programming). It opens the contract arc — naming the three terms and their owners — before F5.04.2 (the Elixir idioms that express them) and F5.04.3 (failing fast at the boundary).
- **Accent:** burgundy (`--burgundy:#c4504c`; the precondition row and `#cdRole` use burgundy `#e08f8b`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.04 · part 1 of 3`

Hero `h1` (verbatim): `Preconditions, postconditions & invariants`

Hero lede (`<p class="lede">`, verbatim): "A contract is an agreement between a caller and a function, and like any contract it assigns obligations. The **precondition** is the caller's obligation — what must hold before the call. The **postcondition** is the function's obligation — what it guarantees on return, given the precondition held. The **invariant** is a shared obligation on the data itself — what every operation must leave true. The value of naming them is precise blame: when something breaks, the term that broke says exactly whose fault it is, and that tells you whether you have a bad request or a bug."

Kicker (`<p class="kicker">`, verbatim): "Three terms, three owners. Select one to see who must guarantee it and what that buys the other side."

## Sections

In order (the teaching arc is *name → express → prove*, here with one teaching section and two reveal sections):

1. **`#owners` — "Who owns each term"** (teaching). Prose: the asymmetry of obligation. Carries the interactive `#cdSel` term-selector figure and the `take` "Name the owner and you name the fault. A broken precondition is the caller's; a broken postcondition is the function's; a broken invariant is a defect in the type itself."
2. **`#code` — "In code"**. The contract written down as `@precondition`/`@postcondition`/`@invariant` comments above the `enroll/2` body, with a `.bridge` ("an agreement" → "precise blame") and a `.note` forward to assertions.
3. **`#invTitle` — "Invariants that always hold"** (`.reveal`, advanced). Introduces the **class invariant** (citing Meyer's *Applying Design by Contract*) via `Portal.Learning.Roster` — the rule `completed ⊆ enrolled` — with a second diagram and a second code block, plus the `take` "An invariant proven at the single point a value is constructed, on immutable fields, is an invariant that cannot later be false."

Running example: the `enroll(user_id, course_id)` command on the Portal engine, plus `Portal.Learning.Roster.new/1` for the class-invariant section.

Real Elixir code shown:
- `#code` block — `enroll/2` with a `with :ok <- check_precondition(...)` chain, building `%Enrollment{id: Portal.ID.new("ENR"), ...}`, `Portal.Store.put(enrollment)`, returning `{:ok, enrollment}` (postcondition holds, progress defaults to 0).
- `#invTitle` block — `defmodule Portal.Learning.Roster` with `@enforce_keys [:learner_id, :enrolled, :completed]`, a checked constructor `new/1` that raises `ArgumentError, "completed must be a subset of enrolled"` `unless MapSet.subset?(completed, enrolled)`, then two example calls (one admitted, one rejected at the door).

## The interactives

This dive carries one interactive figure (the term selector) plus a static second diagram and the footer stamp.

### Content figure — "The three terms · select one" (`#cdSel` + `#cdOut`)

- **`<figure class="fig" aria-labelledby="cdTitle">`** titled "The three terms · select one" (`#cdTitle`).
- **Control group `#cdSel`** (role="group"), three `<button>`s by `data-k` (no `data-c`):
  - `data-k="pre"` — label "precondition" — starts `active`
  - `data-k="post"` — label "postcondition"
  - `data-k="invariant"` — label "invariant"
- **SVG rect ids:** `#cdRow_pre` (burgundy stroke `#c4504c`, owner "the caller"), `#cdRow_post` (owner "the function"), `#cdRow_invariant` (owner "every operation"). Each row shows term label + a mono caption ("checked before the call" / "guaranteed on return" / "true before and after") + the owner at right.
- **Pure function:** `pick(k)` over `TERMS {pre, post, invariant}` — toggles `#cdSel` button `active`/`aria-pressed`, sets the matching `#cdRow_*` rect's `stroke`/`stroke-width`/`fill` (on = `#c4504c`/`2`/`#1d1320`, off = `#3a4263`/`1.3`/`#10162b`), writes `T.name` into `#cdRole`, `T.who` into `#cdResult`, and the composed sentence into `#cdOut.innerHTML`. Initial call `pick('pre')`.
- **Readout strings (`TERMS`, verbatim — `#cdOut` is composed as ``The <b>{name}</b> is owned by <b>{who}</b>. {desc}``):**
  - pre: name "Precondition", who "the caller", desc "The caller must establish it before calling. If it is broken, the fault is the caller's — the function is entitled to refuse, and need not guard against what the precondition rules out."
  - post: name "Postcondition", who "the function", desc "The function must establish it before returning, assuming the precondition held. The caller may rely on it without re-checking — the benefit it buys by meeting the precondition."
  - invariant: name "Invariant", who "every operation", desc "Every operation that touches the entity must leave it true — it holds before and after each call. It constrains the type itself, not a single function."
- **Static readout fallbacks (in markup):** `#cdRole` = "Precondition"; `#cdResult` = "the caller"; `#cdOut` empty until JS runs.

### Second diagram — "The one rule a Roster keeps: completed ⊆ enrolled" (`#invFigTitle`, static)

- **`<figure class="fig" aria-labelledby="invFigTitle">`** — a static Venn-style SVG (`viewBox="0 0 720 188"`): an ENROLLED box containing a DONE circle (the completed subset), with the rule "completed ⊆ enrolled" labelled "holds — admitted", and a rejected point `#invBad` labelled "done ⊄ enrolled" / "impossible — new/1 raises". No controls; static only.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0Ncv17k9leS` (in `#stampId`); `#st-ts` hard-codes "2026-06-01 14:52:31 UTC".
- **Decoder:** `decodeBranded(id)` with `EPOCH_MS = 1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Decoding `TSK0Ncv17k9leS` yields **2026-06-01 14:52:31 UTC** (node 0, seq 0), matching the markup. Toggle on click / Enter / Space sets `.open` + `aria-expanded`.

Degrade behaviour: the `#cdSel` controls + the SVG default (the burgundy precondition row, owner labels) are in static markup; JS only enhances. The `.reveal` sections show their content without JS (`html.js .reveal` is the only hidden state, restored on scroll or immediately under `prefers-reduced-motion: reduce`). No browser storage.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Bertrand Meyer — Applying Design by Contract](https://se.inf.ethz.ch/~meyer/publications/computer/contract.pdf) — preconditions, postconditions, invariants.
- [Eiffel — Design by Contract and assertions](https://www.eiffel.org/doc/solutions/Design_by_Contract_and_Assertions) — the contract metaphor, in depth.
- [Elixir — Patterns and guards](https://hexdocs.pm/elixir/patterns-and-guards.html) — guards as executable preconditions.

**Related in this course**
- F5.04 · Design by contract → `/elixir/pragmatic/contracts`
- Assertions in Elixir → `/elixir/pragmatic/contracts/assertions`
- Fail fast → `/elixir/pragmatic/contracts/fail-fast`

(Note: the `#invTitle` prose also links Meyer's paper inline: `https://se.inf.ethz.ch/~meyer/publications/computer/contract.pdf`.)

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><a href="/elixir/pragmatic/contracts">contracts</a><span class="rsep">/</span><span class="rcur">conditions</span>` (current segment `conditions` is `.rcur`).
- **crumbs:** `F5` → `/elixir/pragmatic` · sep `/` · `F5.04` → `/elixir/pragmatic/contracts` · sep `/` · here `conditions` (no link).
- **toc-mini:** `#owners` ("Who owns each term") · `#code` ("In code") · `#invTitle` ("Invariants that always hold").
- **pager:** prev → `/elixir/pragmatic/contracts` ("← F5.04 · contracts"); next → `/elixir/pragmatic/contracts/assertions` ("Next · assertions in Elixir →").
- **footer (3-column `foot-nav`):** Chapters column — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. The course column — `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"). Header brand + footer logo both → `/elixir`.
- **Page meta:** `<title>` "Preconditions, postconditions & invariants — F5.04.1 · jonnify"; `<meta description>` "A contract has three parts and three owners. The precondition is the caller's obligation — valid ids, not already enrolled. The postcondition is the function's guarantee — a fresh enrollment with progress 0. The invariant is what every operation must preserve — progress stays within 0..100. Each says who is at fault when it breaks."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent; change only `<title>`/`<meta description>`, the `.route-tag` current segment, and the `<main>` body (hero, the `#owners` term-selector figure, the `#code` block, the `#invTitle` reveal section with its second diagram and Roster code, and the `#refs` block). Keep the no-invent guards: use only the real Portal surfaces as written — `enroll/2`, `Portal.ID.new("ENR")`, `Portal.Store.put/1`, `%Enrollment{progress: 0}`, `Portal.Learning.Roster` with `@enforce_keys` + a raising `new/1`, the `completed ⊆ enrolled` invariant and the `0..100` progress range — and do not re-teach OTP internals (cite the companion course). Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `assertions.html` (part 2 of 3 of this module, same burgundy accent, same footer and stamp pattern).
