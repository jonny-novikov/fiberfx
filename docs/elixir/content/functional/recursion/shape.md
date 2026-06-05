# F2.04.1 — The shape of recursion (dive)

- Route (served): `/elixir/functional/recursion/shape`
- File: `elixir/functional/recursion/shape.html`
- Place in the chapter: the first of the three F2.04 dives (`part 1 of 3`), under the `/elixir/functional/recursion` hub. It opens the recursion arc — base case vs recursive case, then unfold-and-collapse — before `tail-calls` flattens the stack and `patterns` reveals the fold.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2.04 · part 1 of 3`

H1 (verbatim): `The shape of recursion`

Hero lede (verbatim):

> Every recursive function has the same skeleton: at least one base case that returns a value outright, and at least one recursive case that does a little work and calls itself on a smaller input. Get those two parts right and the function terminates with the answer.

Kicker line (verbatim):

> The base case is where the recursion stops; the recursive case is where it shrinks the problem. Miss the base case and the calls never stop; fail to shrink the input and they never reach it. Below: tell the two cases apart, then watch a call unfold into a full expression and collapse back to a number.

## Sections

In order:

1. `Base case or recursive case` (`#cases`) — one teaching section. A `.deflist` (`base case`, `recursive case`, `decomposition`, `termination`) then an interactive clause classifier.
2. `Unfold and collapse` (`#unfold`) — a step-through of `factorial(4)` expanding into nested multiplications then collapsing to a number; ties to F1.02's substitution model.
3. `Worked examples` (`#gallery`) — three two-clause recursions (`sum`, `length`, `factorial`) plus the failure to avoid (a non-terminating recursion).

Running example: `factorial(4)` (the unfold), with `sum`/`length`/`factorial` clauses as the gallery set.

Real Elixir code shown — the non-terminating counter-example (`#gallery`, verbatim):

```
# no base case — never stops
def forever(n), do: forever(n + 1)   # grows away from any base
```

Gallery clause sets (from the `EX` data, verbatim): `sum` → `def sum([]), do: 0` / `def sum([h | t]), do: h + sum(t)` (`sum([1, 2, 3])   # => 6`); `length` → `def len([]), do: 0` / `def len([_ | t]), do: 1 + len(t)` (`len([:a, :b, :c])   # => 3`); `factorial` → `def fact(0), do: 1` / `def fact(n), do: n * fact(n - 1)` (`fact(4)   # => 24`).

## The interactives

### Section 1 — clause classifier, `aria-labelledby="casesTitle"` (`#cases`)

- Figure title (`#casesTitle`, verbatim): `Does this clause recurse?`.
- Control group `clSel` (`role="group"`, `aria-label="Choose a clause"`): buttons `data-c="fact0"` (label `factorial(0)`, default `active`, `data-c-color="sage"`), `data-c="factn"` (`factorial(n)`), `data-c="sum0"` (`sum([])`), `data-c="sumht"` (`sum([h | t])`).
- SVG element ids: `clCode` (the clause text), `clBadge` group with `clBadgeBox` (badge rect) and `clBadgeT` (badge label).
- Pure functions: `clKey()` reads the active button's `data-c`; `renderCl()` looks the clause up in `CL` and paints the code, the badge label (`base case` in `#a7c9b1`/stroke `#7ba387`, or `recursive case` in `#cdb8f0`/stroke `#b39ddb`), and the readout. `CL` data (verbatim `why` strings): `fact0` base "an input small enough to answer outright — 0! is 1, no recursion"; `factn` recursive "it calls itself on a smaller input, n - 1"; `sum0` base "the empty list sums to 0 with no further work"; `sumht` recursive "it recurses on the tail, a shorter list".
- Readout id `clOut` (`aria-live="polite"`). Initial markup (verbatim): `base case · an input small enough to answer outright — 0! is 1, no recursion`.

### Section 2 — unfold / collapse, `aria-labelledby="unfoldTitle"` (`#unfold`)

- Figure title (`#unfoldTitle`, verbatim): `factorial(4) · substitution, both ways`.
- Control: range slider `ufStep` (`min=0 max=9 step=1 value=0`), readout `ufStepval` (initial `1 / 10`).
- SVG element ids: `ufPhase` (phase banner), `ufExpr` (the expression). Plus `pre.code#ufCode` and readout `#ufOut`.
- Pure function: `renderUf()` walks the 10-entry `UF` array (`e` = the expression at that step, `act` = the action label). Expressions in order: `factorial(4)`, `4 * factorial(3)`, `4 * (3 * factorial(2))`, `4 * (3 * (2 * factorial(1)))`, `4 * (3 * (2 * (1 * factorial(0))))`, `4 * (3 * (2 * (1 * 1)))` (base), `4 * (3 * (2 * 1))`, `4 * (3 * 2)`, `4 * 6`, `24`.
- Phase banner strings (verbatim): `EXPANDING · SUBSTITUTING EACH CALL`; `BASE CASE · factorial(0) = 1`; `COLLAPSING · MULTIPLYING BACK UP`. (The static SVG markup ships `ufPhase` = `EXPANDING`.)
- Readout `#ufOut` (`aria-live="polite"`). Initial markup (verbatim): `step 1 · start with factorial(4)`. Generated form: `step N · <act>` (with ` · 24` appended at step 10). `act` strings (verbatim): "start with factorial(4)", "expand: factorial(4) = 4 * factorial(3)", "expand factorial(3)", "expand factorial(2)", "expand factorial(1)", "base case: factorial(0) = 1", "collapse: 1 * 1 = 1", "collapse: 2 * 1 = 2", "collapse: 3 * 2 = 6", "collapse: 4 * 6 = 24".

### Section 3 — worked examples gallery (`#gallery`)

- Control group `exSel` (`role="group"`, `aria-label="Choose an example"`): buttons `data-ex="sum"` (`data-c="sage"`, default `active`), `data-ex="length"` (`data-c="blue"`), `data-ex="factorial"` (`data-c="gold"`).
- Elements: `pre.code#exCode`, readout `#exOut`.
- Pure functions: `exKey()` reads the active `data-ex`; `renderEx()` paints `EX[key].code` and the note. Notes (verbatim): `sum` "base: the empty list is 0 · step: head plus the sum of the tail"; `length` "base: the empty list has length 0 · step: one plus the length of the tail"; `factorial` "base: 0! is 1 · step: n times the factorial of n minus one".
- Readout `#exOut` initial markup (verbatim): `sum · base: the empty list is 0 · step: head plus the sum of the tail`.

### Takeaways (`.take`, verbatim)

- `#cases`: "If a clause calls the function again on a smaller input, it is the recursive case; if it answers without calling, it is the base case."
- `#unfold`: "The work happens on the way back: nothing multiplies until the base case supplies the innermost value. The deeper the input, the taller the expression — and the stack."

### Bridge cells

- `#cases`: `F1.06 · induction` → "Base case and inductive step — the proof structure and the code structure are the same." → `Elixir`: "Clauses pattern-match the argument's shape: `0` or `[]` for the base, a larger shape for the step."
- `#unfold`: `F1.02 · substitution` → "Replace each call by its definition; the expression grows until the base case." → `the stack`: "Each nested multiplication waiting to finish is one frame on the call stack."

### Footer build-stamp decoder

- Stamp id (`#stampId`, verbatim): `TSK0NZi3zF3pHU`.
- Hard-coded fallback timestamp in markup (`#st-ts`): `2026-05-30 16:28:26 UTC`.
- Same `decodeBranded` logic (namespace `TSK`, b62 Snowflake, `EPOCH_MS = 1704067200000`) populating `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts` on click/Enter/Space; decoded UTC matches the markup fallback `2026-05-30 16:28:26 UTC`.

## References (#refs, verbatim)

This page has no `#refs` / References section. There is no References block, no Sources list, and no "Related in this course" list in the markup. The only cross-course links are the inline F1.02 / F1.06 bridge labels (text only, not hyperlinks) and the pager (see Wiring).

## Wiring

- route-tag (verbatim): `/ elixir / functional / recursion / shape` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/recursion">recursion</a>` · `<span class="rcur">shape</span>`.
- crumbs (verbatim): `F2` (→ `/elixir/functional`) / `F2.04` (→ `/elixir/functional/recursion`) / `shape` (here).
- toc-mini (verbatim): `Two cases` → `#cases`; `Unfold and collapse` → `#unfold`; `Worked examples` → `#gallery`.
- pager: prev → `/elixir/functional/recursion` label `← F2.04 · hub`; next → `/elixir/functional/recursion/tail-calls` label `Part 2 · tail calls →`.
- footer: identical to the hub — three columns. Brand logo → `/elixir` + tagline. `Chapters`: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`). `The course`: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`). Foot bar: `© jonnify` + build stamp.
- Page meta: `<title>` (verbatim) `The shape of recursion — F2.04.1 · jonnify`; `<meta description>` (verbatim) `Base case and recursive case, and the call stack growing then unwinding as a body-recursive function runs to a result.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the per-section IIFE — clause classifier, unfold/collapse, worked-examples gallery, branded Snowflake decoder — and the progressive-enhancement reveal script) verbatim from a recent BUILT sibling on the elixir (purple) accent — the model sibling is `elixir/functional/recursion/tail-calls.html` (same dive shape: single-column hero, three numbered sections, `.deflist` + `.fig` + `.bridge` + `.take`, identical head/footer/decoder). Change only the `<title>` / `<meta description>`, the header `route-tag` (append the current `shape` segment as `<span class="rcur">`), and the `<main>` body. No-invent guards: use only the real Portal surfaces exactly as written elsewhere in the course — the branded store, the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app — and cite the companion F5/F6 material for OTP/BEAM internals rather than re-teaching them; do not invent routes, ids, readout strings, code tokens, or function arities. Voice rules: no first person, no exclamation marks, no emoji, and none of "just" / "simply" / "obviously". Keep the footer build stamp as a real `TSK…` id whose decode matches its `#st-ts` markup. Model sibling to copy from: `elixir/functional/recursion/tail-calls.html`.
