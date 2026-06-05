# F2.04.2 — Tail calls & accumulators (dive)

- Route (served): `/elixir/functional/recursion/tail-calls`
- File: `elixir/functional/recursion/tail-calls.html`
- Place in the chapter: the second of the three F2.04 dives (`part 2 of 3`), under the `/elixir/functional/recursion` hub. It removes the stack-depth cost the `shape` dive exposed — body vs tail recursion, then the accumulator pattern — and hands off to `patterns`, where the same recursions become folds.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2.04 · part 2 of 3`

H1 (verbatim): `Tail calls & accumulators`

Hero lede (verbatim):

> Body recursion does its work on the way back up, so it holds a frame for every pending call. A tail-recursive function does the work on the way down and carries the result in an accumulator — so there is nothing to come back to, and the stack stays flat.

Kicker line (verbatim):

> A call is in tail position when it is the last thing a function does — its result is returned directly, with no pending addition or multiplication around it. The runtime can then reuse the current frame instead of stacking a new one: tail-call optimisation. The trick that puts a recursive call in tail position is an accumulator: an extra argument that carries the answer-so-far.

## Sections

In order:

1. `Body vs tail` (`#stack`) — teaching section. A `.deflist` (`body recursion`, `tail call`, `accumulator`, `tail-call optimisation`) then an interactive body-vs-tail stack comparison.
2. `The accumulator builds` (`#acc`) — a step-through of the tail-recursive `sum([1, 2, 3, 4], 0)`, watching one frame reused while the accumulator grows.
3. `Worked examples` (`#gallery`) — the accumulator pattern three times (`sum`, `reverse`, `factorial`), each with a public wrapper that sets the starting accumulator.

Running example: `sum([1, 2, 3, 4])` (body) versus `sum([1, 2, 3, 4], 0)` (tail).

Real Elixir code shown (gallery `TA` data, verbatim):

```
def sum(list), do: sum(list, 0)        # wrapper sets acc
defp sum([], acc),      do: acc
defp sum([h | t], acc), do: sum(t, acc + h)
```

```
def reverse(list), do: reverse(list, [])
defp reverse([], acc),      do: acc
defp reverse([h | t], acc), do: reverse(t, [h | acc])
```

```
def fact(n), do: fact(n, 1)
defp fact(0, acc), do: acc
defp fact(n, acc), do: fact(n - 1, acc * n)
```

Body-vs-tail code (from `renderBvt`, verbatim): body → `def sum([]), do: 0` / `def sum([h | t]), do: h + sum(t)   # + waits on the call`; tail → `def sum([], acc), do: acc` / `def sum([h | t], acc), do: sum(t, acc + h)   # call is the result`.

## The interactives

### Section 1 — body vs tail stack, `aria-labelledby="bvtTitle"` (`#stack`)

- Figure title (`#bvtTitle`, verbatim): `sum([1, 2, 3, 4]) · the stack at its deepest`.
- Control group `bvtSel` (`role="group"`, `aria-label="Choose a style"`): buttons `data-m="body"` (label `body recursion`, `data-c="blue"`, default `active`), `data-m="tail"` (label `tail recursion`, `data-c="sage"`).
- SVG element ids: `bvtLabel` (the space banner), `bvtStack` (the frame group). Plus `pre.code#bvtCode` and readout `#bvtOut`.
- Pure functions: `bvtKey()` reads the active `data-m`; `renderBvt()` draws either the five-frame `BODY_FRAMES` stack (`sum([1, 2, 3, 4])`, `sum([2, 3, 4])`, `sum([3, 4])`, `sum([4])`, `sum([])`) or the single reused tail frame `sum(list, acc)   — reused`, and sets the banner + code + readout.
- Banner `bvtLabel` strings (verbatim): `5 FRAMES · O(n) SPACE` (body, the static markup default) / `1 FRAME · O(1) SPACE` (tail).
- Readout `#bvtOut` (`aria-live="polite"`). Initial markup (verbatim): `body recursion · the stack grows to one frame per element · O(n) space`. Tail form (verbatim): `tail recursion · one frame, reused at every step · O(1) space`.

### Section 2 — accumulator builds, `aria-labelledby="accTitle"` (`#acc`)

- Figure title (`#accTitle`, verbatim): `sum([1, 2, 3, 4], 0) · one frame, growing accumulator`.
- Control: range slider `accStep` (`min=0 max=5 step=1 value=0`), readout `accStepval` (initial `1 / 6`).
- SVG element ids: `accCall` (the current call), `accList` (the remaining-list chip group), `accVal` (the accumulator chip value). Plus `pre.code#accCode` and readout `#accOut`. The static SVG banner reads `ONE FRAME · REUSED EACH STEP`.
- Pure functions: `chip(x, y, val)` draws a list chip; `renderAcc()` walks the 6-entry `ACC` array (`call`/`list`/`acc`/`act`, last entry `base:true`). Calls in order: `sum([1, 2, 3, 4], 0)`, `sum([2, 3, 4], 1)`, `sum([3, 4], 3)`, `sum([4], 6)`, `sum([], 10)`, `sum([], 10)` (base). `act` strings (verbatim): "start: acc = 0", "acc + 1 = 1", "acc + 2 = 3", "acc + 3 = 6", "acc + 4 = 10", "base: list empty, return acc". Empty-list chip text: `[]  (empty)`.
- Readout `#accOut` (`aria-live="polite"`). Initial markup (verbatim): `step 1 · sum([1, 2, 3, 4], 0) · acc = 0`. Generated forms: `step N · <call> · acc = N`; the base step ends `· returns 10`.

### Section 3 — worked examples gallery (`#gallery`)

- Control group `taSel` (`role="group"`, `aria-label="Choose an example"`): buttons `data-ta="sum"` (`data-c="sage"`, default `active`), `data-ta="reverse"` (`data-c="blue"`), `data-ta="factorial"` (`data-c="gold"`).
- Elements: `pre.code#taCode`, readout `#taOut`.
- Pure functions: `taKey()` reads the active `data-ta`; `renderTa()` paints `TA[key].code` and the note. Notes (verbatim): `sum` "the accumulator starts at 0 and adds each head"; `reverse` "prepending each head reverses the list — and prepend is O(1)"; `factorial` "the accumulator starts at 1 and multiplies down to 0".
- Readout `#taOut` initial markup (verbatim): `sum · the accumulator starts at 0 and adds each head`.

### Takeaways (`.take`, verbatim)

- `#stack`: "Body recursion: a frame per element. Tail recursion: one frame, reused. The difference is whether the recursive call is the last thing the clause does."
- `#acc`: "The accumulator turns "remember to add this later" into "add it now and pass it on." The result arrives at the base case fully formed."

### Bridge cells

- `#stack`: `Idea` → "If nothing waits on the recursive call, nothing needs to be remembered." → `Elixir`: "The BEAM reuses the frame for a tail call, so deep recursion runs in constant space."
- `#acc`: `Idea` → "Carry the answer-so-far instead of leaving it for the return trip." → `Elixir`: "`sum([], acc), do: acc` — at the base, the accumulator is the result."

### Footer build-stamp decoder

- Stamp id (`#stampId`, verbatim): `TSK0NZi3zVo9xI`.
- Hard-coded fallback timestamp in markup (`#st-ts`): `2026-05-30 16:28:26 UTC`.
- Same `decodeBranded` logic (namespace `TSK`, b62 Snowflake, `EPOCH_MS = 1704067200000`) populating `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts` on click/Enter/Space; decoded UTC matches the markup fallback `2026-05-30 16:28:26 UTC`.

## References (#refs, verbatim)

This page has no `#refs` / References section. There is no References block, no Sources list, and no "Related in this course" list in the markup. The only cross-references are the inline `Idea`/`Elixir` bridge labels (text only) and the pager (see Wiring). The companion BEAM/OTP note ("The BEAM reuses the frame for a tail call") is cited in prose, not as a linked reference.

## Wiring

- route-tag (verbatim): `/ elixir / functional / recursion / tail-calls` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/recursion">recursion</a>` · `<span class="rcur">tail-calls</span>`.
- crumbs (verbatim): `F2` (→ `/elixir/functional`) / `F2.04` (→ `/elixir/functional/recursion`) / `tail-calls` (here).
- toc-mini (verbatim): `Body vs tail` → `#stack`; `The accumulator builds` → `#acc`; `Worked examples` → `#gallery`.
- pager: prev → `/elixir/functional/recursion/shape` label `← Part 1 · the shape`; next → `/elixir/functional/recursion/patterns` label `Part 3 · patterns →`.
- footer: identical to the hub/`shape` — three columns. Brand logo → `/elixir` + tagline. `Chapters`: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`). `The course`: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`). Foot bar: `© jonnify` + build stamp.
- Page meta: `<title>` (verbatim) `Tail calls & accumulators — F2.04.2 · jonnify`; `<meta description>` (verbatim) `Body versus tail recursion, the accumulator pattern, and how a tail call reuses the stack frame to run in constant space.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the per-section IIFE — body-vs-tail, accumulator builds, worked-examples gallery, branded Snowflake decoder — and the progressive-enhancement reveal script) verbatim from a recent BUILT sibling on the elixir (purple) accent — the model sibling is `elixir/functional/recursion/shape.html` (the adjacent dive: same single-column hero, three numbered sections, `.deflist` + `.fig` + `.bridge` + `.take`, identical head/footer/decoder). Change only the `<title>` / `<meta description>`, the header `route-tag` (current `tail-calls` segment as `<span class="rcur">`), and the `<main>` body. No-invent guards: use only the real Portal surfaces exactly as written elsewhere in the course — the branded store, the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app — and cite the companion F5/F6 material for OTP/BEAM internals (this dive correctly attributes tail-call frame reuse to "the BEAM" without re-teaching the VM); do not invent routes, ids, readout strings, code tokens, or function arities. Voice rules: no first person, no exclamation marks, no emoji, and none of "just" / "simply" / "obviously". Keep the footer build stamp as a real `TSK…` id whose decode matches its `#st-ts` markup. Model sibling to copy from: `elixir/functional/recursion/shape.html`.
