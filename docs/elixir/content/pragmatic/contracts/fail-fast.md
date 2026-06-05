# F5.04.3 — Failing fast (dive)

- **Route (served):** `/elixir/pragmatic/contracts/fail-fast`
- **File:** `/Users/jonny/dev/jonnify/elixir/pragmatic/contracts/fail-fast.html`
- **Place in the chapter:** part 3 of 3 of module F5.04 · Design by contract (chapter F5 · Pragmatic Programming). It closes the contract arc — after F5.04.1 (the three terms) and F5.04.2 (the Elixir idioms) — by placing the checks at the boundary, and hands off to F5.05 (commands, queries & events).
- **Accent:** burgundy (chapter) — this dive's selected timing rides gold (`--gold:#d4a85a`; the `fail fast` row and `#ffRole` use `#f0cd7f`), the chapter accent staying burgundy.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.04 · part 3 of 3`

Hero `h1` (verbatim): `Failing fast`

Hero lede (`<p class="lede">`, verbatim): "A contract is only useful if it is checked at the right moment: **at the boundary, before the command does anything**. Check the precondition first, and a violation stops the command before a struct is built or the store is touched — the error lands right next to its cause and nothing downstream is corrupted. Skip the check, or bury it deep, and bad input flows inward to surface much later as a broken enrollment or a crash far from where it started. Failing fast also means splitting the two kinds of failure: an **expected** one returns a tagged error the caller handles; an **impossible** one — a broken invariant — crashes, because there is no sensible way to continue."

Kicker (`<p class="kicker">`, verbatim): "Two places a contract can break. Select one to see where the failure surfaces and what it costs."

## Sections

In order (teaching arc: *the cost of timing → the gate goes first in code*):

1. **`#when` — "Early or late"** (teaching). Prose: the same violation costs almost nothing caught early and a great deal caught late; the rule is "check, then act — never act, then discover." Carries the interactive `#ffSel` timing-selector figure and the `take` "Check, then act. A contract enforced after the work is done is not a contract; it is a post-mortem."
2. **`#code` — "In code"**. The fail-fast `enroll/2` with the `with`-gate up front, contrasted against a commented-out fail-late version that acts first and checks after. Closes with a `.bridge` ("check, then act" → "close to the cause") and a `.note` that closes F5.04 and points to F5.05.

Running example: the `enroll(user_id, course_id)` command — `check_precondition/2`, `build/2`, `Portal.Store.put/1`.

Real Elixir code shown (`#code` block):
- fail-fast version — `def enroll(user_id, course_id)` with `with :ok <- check_precondition(user_id, course_id) do` (the gate, up front), then `enrollment = build(...)`, `:ok = Portal.Store.put(enrollment)`, returning `{:ok, enrollment}` — nothing built or stored until the contract holds.
- fail-late version (commented out, "avoid") — `build`, then `Portal.Store.put` ("a bad enrollment is now persisted"), then `check_precondition` ("too late to matter").

## The interactives

This dive carries one interactive figure (the timing selector) plus the footer stamp.

### Content figure — "Where it breaks · select one" (`#ffSel` + `#ffOut`)

- **`<figure class="fig" aria-labelledby="ffTitle">`** titled "Where it breaks · select one" (`#ffTitle`).
- **Control group `#ffSel`** (role="group"), two `<button>`s by `data-k` (no `data-c`):
  - `data-k="fast"` — label "fail fast" — starts `active`
  - `data-k="late"` — label "fail late"
- **SVG rect ids:** `#ffRow_fast` (gold stroke `#d4a85a`, "check at the boundary, before any change", with a marker "cheap · close to cause") and `#ffRow_late` ("surfaces deep, after the damage", with an ✕ marker "costly · far from cause").
- **Pure function:** `pick(k)` over `WHEN {fast, late}` — toggles `#ffSel` button `active`/`aria-pressed`, sets the matching `#ffRow_*` rect's `stroke`/`stroke-width`/`fill` (on = `#d4a85a`/`2`/`#241d10`, off = `#3a4263`/`1.3`/`#10162b`), writes `W.name` into `#ffRole`, `W.where` into `#ffResult`, and the composed sentence into `#ffOut.innerHTML`. Initial call `pick('fast')`.
- **Readout strings (`WHEN`, verbatim — `#ffOut` is composed as ``<b>{name}</b> — the failure surfaces <b>{where}</b>. {desc}``):**
  - fast: name "Fail fast", where "at the boundary, before any change", desc "A violated precondition stops the command immediately — before the struct is built or the store is touched. The error lands close to its cause, nothing is corrupted, and the trace points at the real problem."
  - late: name "Fail late", where "deep in the stack, after damage", desc "Skip the check and the bad input flows inward, surfacing later as a corrupt enrollment or a crash far from the cause. Cheap to write, expensive to debug — the failure and its source are now far apart."
- **Static readout fallbacks (in markup):** `#ffRole` = "Fail fast"; `#ffResult` = "at the boundary, before any change"; `#ffOut` empty until JS runs.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0Ncv18OBCzY` (in `#stampId`); `#st-ts` hard-codes "2026-06-01 14:52:32 UTC".
- **Decoder:** `decodeBranded(id)` with `EPOCH_MS = 1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Decoding `TSK0Ncv18OBCzY` yields **2026-06-01 14:52:32 UTC** (node 0, seq 0), matching the markup. Toggle on click / Enter / Space sets `.open` + `aria-expanded`.

Degrade behaviour: the `#ffSel` controls + the two SVG rows (the gold `fail fast` row pre-highlighted) are in static markup; JS only enhances. The `.reveal` references section shows without JS and restores immediately under `prefers-reduced-motion: reduce`. No browser storage.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Bertrand Meyer — Applying Design by Contract](https://se.inf.ethz.ch/~meyer/publications/computer/contract.pdf) — preconditions, postconditions, invariants.
- [Eiffel — Design by Contract and assertions](https://www.eiffel.org/doc/solutions/Design_by_Contract_and_Assertions) — the contract metaphor, in depth.
- [Elixir — Patterns and guards](https://hexdocs.pm/elixir/patterns-and-guards.html) — guards as executable preconditions.

**Related in this course**
- F5.04 · Design by contract → `/elixir/pragmatic/contracts`
- Pre- & postconditions → `/elixir/pragmatic/contracts/conditions`
- F5.06 · Supervision & restart → `/elixir/pragmatic/state/supervision`

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><a href="/elixir/pragmatic/contracts">contracts</a><span class="rsep">/</span><span class="rcur">fail-fast</span>` (current segment `fail-fast` is `.rcur`).
- **crumbs:** `F5` → `/elixir/pragmatic` · sep `/` · `F5.04` → `/elixir/pragmatic/contracts` · sep `/` · here `fail-fast` (no link).
- **toc-mini:** `#when` ("Early or late") · `#code` ("In code").
- **pager:** prev → `/elixir/pragmatic/contracts/assertions` ("← F5.04.2 · assertions"); next → `/elixir/pragmatic/contracts` ("Back to F5.04 →"). The last dive's forward link returns to the module hub, not a sibling.
- **footer (3-column `foot-nav`):** Chapters column — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. The course column — `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"). Header brand + footer logo both → `/elixir`.
- **Page meta:** `<title>` "Failing fast — F5.04.3 · jonnify"; `<meta description>` "Check at the boundary and stop on the first violation, before the struct is built or the store is touched. An expected failure returns a tagged error the caller handles; an impossible state raises and crashes. Either way the error lands close to its cause and nothing downstream is corrupted — the opposite of failing late and silently."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent; change only `<title>`/`<meta description>`, the `.route-tag` current segment, and the `<main>` body (hero, the `#when` timing-selector figure, the `#code` block with its fail-fast / commented fail-late contrast, and the `#refs` block). Keep the no-invent guards: use only the real Portal surfaces as written — `enroll/2`, `check_precondition/2`, `build/2`, `Portal.Store.put/1`, `%Enrollment{}` — and do not re-teach OTP internals (cite the companion course for supervision/let-it-crash; this dive links F5.06 · Supervision & restart for the runtime side). Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `assertions.html` (part 2 of 3 of this module, same burgundy accent and footer/stamp pattern).
