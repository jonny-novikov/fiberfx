# F3.02.1 — The match operator (dive)

- Route (served): `/elixir/language/match/operator`
- File: `elixir/language/match/operator.html`
- Place in the chapter: part 1 of 3 in module F3.02 (Pattern matching). It opens the deep-dive arc by isolating what the single `=` does — assert and bind — and introduces the pin `^` as the way to match against a value already held. Followed by `destructuring`, then `branching`.
- Accent: elixir (purple), `--elixir` / `--elixir-bright`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.02 · part 1 of 3`

H1: The match operator

Hero lede (verbatim):

> The single `=` does two jobs at once: it asserts that the value on the right matches the pattern on the left, and it binds any unbound names in that pattern. To compare against a value you _already_ hold rather than rebind it, you pin the name with `^`.

Kicker line (verbatim):

> The portal keeps the signed-in learner's id in `user_id`. When a new request arrives carrying a user id, the question is whether it belongs to the same learner. A plain match would quietly overwrite the original; a pinned match asserts they are equal — and fails loudly if not.

## Sections

In order:

1. `Bind or pin` (`#pin`) — the teaching section. Sets up `user_id` already bound to the signed-in learner, then lets the reader pick plain vs. pinned and same vs. different incoming id, and watch the outcome. Carries the interactive figure.
2. `Why it matters` (`#why`) — the advanced section. Explains that a bare name always matches and binds (and so can hide bugs), and that the pin makes intent explicit by surfacing a mismatch as a `MatchError` at the exact line. Ends with a `.bridge` (Plain match → Pinned match).

Running example: the Portal's `user_id` (the signed-in learner) re-matched against an incoming request id, with the real Portal id `"USR0NbAb1xcFCy"`.

Real Elixir shown (verbatim from the figure code): `user_id = "USR0NbAb1xcFCy"` (the signed-in learner), then `user_id = <incoming>` or `^user_id = <incoming>`, with the trailing comment varying by outcome (`# user_id => … (rebound, unchanged)`, `# user_id => "USR0NbXraQ7f2D" (the original is gone)`, `# match succeeds; user_id is unchanged`, `# ** (MatchError) no match of right hand side value`).

## The interactives

### `Match · plain or pinned` (`aria-labelledby="pTitle"`)
- Title id `pTitle`: `Match · plain or pinned`.
- Control group `pinSel` (`.solid-select`, `aria-label="Plain or pinned match"`): `plain  =` (`data-pin="off"`, `data-c="blue"`, active default); `pinned  ^=` (`data-pin="on"`, `data-c="elixir"`).
- Control group `valSel` (`.solid-select`, `aria-label="Incoming id"`): `same id` (`data-val="same"`, `data-c="sage"`, active default); `different id` (`data-val="diff"`, `data-c="burg"`).
- SVG ids: a static "already bound" box (`user_id = "USR0NbAb1xcFCy"`), then `pinBox` (this-match box), `pinExpr` (the match expression text), `pinResult` (the verdict). Code `pre` id `pinCode`, readout `pinOut` (`.geo-readout`, `aria-live="polite"`).
- Pure function: `render()` reads the active `data-pin`/`data-val`, builds the LHS (`^user_id` or `user_id`) and incoming literal (`SAME = '"USR0NbAb1xcFCy"'`, `DIFF = '"USR0NbXraQ7f2D"'`), recolours the box, and writes the code + note. `activeOf(group, attr)` is the helper that reads the active button's attribute.
- The four outcomes — `pinResult` text then `pinOut` note (verbatim):
  - plain + same — `rebinds — to the same value` — `A plain match always binds. The value happens to be identical, so nothing visibly changes — but no check was performed.`
  - plain + different — `rebinds — original replaced` — `A plain match silently rebinds user_id to the incoming value. The learner you were tracking has been overwritten with no warning.`
  - pinned + same — `matches — pinned, equal` — `The pin uses the current value as a literal. The incoming id equals it, so the match succeeds and nothing is rebound.`
  - pinned + different — `no match — MatchError` — `The pin asserts equality with the current value. The incoming id differs, so Elixir raises a MatchError right here — the safe outcome.`
- Takeaway (verbatim): Plain `=` always succeeds by rebinding; `^` turns the name into an assertion. Reach for the pin whenever a value must equal one you already trust — a session's learner, an expected token.

### Degrade behaviour
The figure renders its default (plain + same) on load via `render()`. The `.arc-flow` and `.hp-row` animations are gated to `prefers-reduced-motion: no-preference`; reveal-on-scroll is JS-gated and disabled under reduced motion. The SVG carries a meaningful static state in markup.

### Footer build-stamp decoder
Stamp id `TSK0NbBlxpKHYG`. `decodeBranded` base-62-decodes after the 3-char namespace and splits the Snowflake against `EPOCH_MS = 1704067200000`; the page hard-codes the decoded `st-ts` panel value `2026-05-31 13:51:47 UTC`.

## References (#refs, verbatim)

Intro line: Primary sources for this lesson, and where it connects in the course.

Sources:
- `https://hexdocs.pm/elixir/pattern-matching.html` — Pattern matching — Elixir documentation — `=` as the match operator, and the pin.
- `https://hexdocs.pm/elixir/case-cond-and-if.html` — case, cond, and if — Elixir documentation — matching in control flow.

Related in this course:
- `/elixir/language/match` — F3.02 · Pattern matching & the match operator
- `/elixir/language/match/destructuring` — Destructuring portal data
- `/elixir/algebra/pattern-matching` — F1.08 · Equations & pattern matching

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `match` `/` `operator` (with `operator` as the current `.rcur` segment).
- crumbs (verbatim): `F3` (links `/elixir/language`) `/` `F3.02` (links `/elixir/language/match`) `/` `operator` (`.here`).
- toc-mini: `#pin` → `Bind or pin`; `#why` → `Why it matters`.
- pager: prev → `/elixir/language/match` label `F3.02 · match`; next → `/elixir/language/match/destructuring` label `Next · destructuring`.
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand links `/elixir`.
- Page meta — `<title>`: `The match operator — F3.02 · jonnify`. `<meta description>`: `= asserts that a value matches a pattern and binds the rest; the pin operator ^ matches against a value you already have. Seen through verifying a magic-link sign-in.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure IIFE + the Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on this chapter accent, then change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body (hero, the two sections, the figure, references, pager). The canonical model sibling is `elixir/language/match/destructuring.html` — the same dive shell (single teaching figure + advanced section + `.bridge`) on the same elixir accent. No-invent guards: use only the real Portal surfaces as written — the branded `USR…` ids, the pin semantics, and `Portal.Auth`; do not invent new ids, the `DIFF` literal, or `MatchError` wording, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
