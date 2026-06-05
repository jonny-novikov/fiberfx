# F2.04 — Recursion patterns & tail calls (module hub)

- Route (served): `/elixir/functional/recursion`
- File: `elixir/functional/recursion/index.html`
- Place in the chapter: the recursion module of F2 · Functional Programming. It is a hub: it teaches the call stack once on the landing, then splits into three deep-dive subpages taken in order — `shape`, `tail-calls`, `patterns`. It sits between F2.03 (`higher-order`) and F2.05 (`folds`).
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2 · Functional Programming · hub`

H1 (verbatim): `Recursion patterns & tail calls`

Hero lede (verbatim):

> A loop changes a counter; a recursive function calls itself on a smaller problem until it reaches a case small enough to answer outright. With immutable data and no mutable counter, recursion is how functional code repeats.

Kicker line (verbatim):

> F1.06 proved recursion sound through induction: a base case plus a step that shrinks the input. This hub takes the working view and splits into three deep dives. First the **shape** of a recursive function and the call stack it builds; then **tail calls** and the accumulator pattern that flatten that stack to constant space; then the **patterns** that recur — sum, length, reverse, map, filter — each of them a fold. Trace the stack on the right, then take the three pages in order.

## What the page frames

The hub frames its own teaching content (a call-stack tracer, a worked example) plus three deep-dive subpages, presented as a vertical card list under the heading `Three deep dives`. The hub's own in-page sections: `The call stack` (`#trace`), `Three deep dives` (`#paths`), `Worked example` (`#worked`).

The three dive cards (verbatim numbers, titles, summaries, routes):

- `F2.04.1` — The shape of recursion — "Base case, recursive case, and the call stack growing then unwinding as a function runs." — `/elixir/functional/recursion/shape` — built.
- `F2.04.2` — Tail calls & accumulators — "Rewrite with an accumulator so the work happens on the way down and the stack stays flat." — `/elixir/functional/recursion/tail-calls` — built.
- `F2.04.3` — Recursion patterns — "sum, length, reverse, map, and filter written recursively — and why each one is a fold." — `/elixir/functional/recursion/patterns` — built.

(The three dives are styled as inline `<a>` cards in a flex column, not the `.mods`/`.dives` card grid; the F2.04.1/F2.04.2 numbers render in `--elixir-bright`, F2.04.3 in `--gold-bright`.)

Hub-owned definition list (`.deflist`, in `#trace`): `recursion` — "a function defined in terms of itself on a smaller input."; `base case` — "the input small enough to answer without recursing."; `recursive case` — "reduce the problem and call the function on the smaller part."; `call stack` — "the frames of calls still waiting on the calls they made."

Worked-example code (`#worked`), verbatim:

```
# sum a list by recursion — two clauses
def sum([]),        do: 0                 # base case
def sum([h | t]),   do: h + sum(t)         # recursive case

sum([1, 2, 3, 4])
# 1 + sum([2, 3, 4])
# 1 + (2 + sum([3, 4]))
# 1 + (2 + (3 + (4 + sum([]))))
# 1 + (2 + (3 + (4 + 0)))  =>  10
```

## The interactives

### Hero figure — `aria-labelledby="rcTitle"`

- Figure caption (`#rcTitle`, verbatim): `Body recursion grows the stack; a tail call keeps it flat`.
- SVG element ids: `rcMode` (mode banner text), `rcFrames` (frame group), `rcAccLbl` (accumulator label), `rcAccVal` (accumulator value).
- Control group `rc-ctrls`: `rcStep` (`▸ step`), `rcReset` (`reset`), and a mode toggle group `rcModeSel` (`role="group"`, `aria-label="Recursion mode"`) with buttons `data-m="body"` (label `body`, default `active`) and `data-m="tail"` (label `tail`).
- Pure functions: `renderBody()` redraws the growing/unwinding stack for `sum([1,2,3,4])` (5 frames, push 1..4 then pop, depth readouts); `renderTail()` redraws the single reused frame plus the four ghost `(no frame)` rows and the accumulator chip carrying the running sum. Data arrays `CALLS` (list/acc per step) and `COMBINE` (the body-unwind arithmetic, base first: `sum([]) → 0`, `4 + 0 = 4`, `3 + 4 = 7`, `2 + 7 = 9`, `1 + 9 = 10`).
- Readout id `rcCap` (`aria-live="polite"`). Initial markup (verbatim): `stack depth 1 · body recursion holds every pending frame until sum([]) turns it around.` Other body-mode caps (verbatim): `stack depth N · each call pushes a frame and waits on the call it makes.`; `stack depth 5 · base case sum([]) returns 0; now the stack unwinds.`; `stack depth N · popping a frame and combining: <COMBINE>.`; `stack depth 0 · every frame combined — sum([1,2,3,4]) = 10.` Tail-mode caps (verbatim): `stack depth 1 · the accumulator starts at 0; the call to itself is in tail position, so no frame is kept.`; `stack depth 1 · the frame is replaced, not stacked; acc = N carries the work forward.`; `stack depth 1 · sum([], N) matches the base case — the answer is already in acc = N.`; `stack depth 1 · the base case returns N with no frames to unwind — constant space.` Banner `rcMode` text: `BODY RECURSION · STACK GROWS TO DEPTH n` / `TAIL CALL · STACK STAYS FLAT AT DEPTH 1`.
- Degrade: the SVG ships a static initial state (top call frame `sum([1, 2, 3, 4])` at depth 1, sketched dashed frames down to the labelled `base case` row `sum([]) → 0`). No render runs on load; the script comment states "the static SVG already shows the top call frame, the sketched stack, and the base case." The `.rc-new` frame entrance animation is gated by `@media (prefers-reduced-motion: no-preference)` and disabled under `prefers-reduced-motion: reduce`.

### Flagship — call-stack tracer, `aria-labelledby="trTitle"` (`#trace`)

- Figure title (`#trTitle`, verbatim): `sum([1, 2, 3, 4]) · grow, then unwind`.
- Control: range slider `trStep` (`min=0 max=8 step=1 value=0`), readout `trStepval` (initial `1 / 9`).
- SVG element ids: `trPhase` (phase banner), `trFrames` (frame group). Plus `pre.code#trCode` and readout `#trOut`.
- Pure functions: `trState(s)` maps step 0..8 to `{phase:'descend', active:s}` for s≤4 and `{phase:'return', active:8-s}` after; `renderTrace()` draws each of the five `FRAMES` (`call`/`ret` pairs: `sum([1, 2, 3, 4])`→`1 + 9 = 10`, `sum([2, 3, 4])`→`2 + 7 = 9`, `sum([3, 4])`→`3 + 4 = 7`, `sum([4])`→`4 + 0 = 4`, `sum([])`→`0  (base case)`).
- Phase banner strings (verbatim): `DESCENDING · PUSHING FRAMES`; `BASE CASE REACHED · sum([]) = 0`; `RETURNING · POPPING FRAMES, COMBINING`.
- Readout `#trOut` (`aria-live="polite"`). Initial markup (verbatim): `step 1 · call sum([1, 2, 3, 4]) · stack depth 1`. Generated forms (verbatim): `step N · call <FRAME.call> · stack depth N`; `step 5 · base case · sum([]) returns 0`; `step N · <FRAME.call> returns <FRAME.ret>`.

### Takeaways (`.take`, verbatim)

- `#trace`: "Body recursion does its work on the way back up: the stack holds every pending frame until the base case turns it around. That depth is the cost the next page removes."
- `#worked`: "Each line of the unwinding is one frame returning. The page ahead shows how to do the same work without holding all those frames at once."

### Bridge cell (`#trace`)

`F1.06 · induction` → "A base case and a step that shrinks the input — the same structure that proves a recursion ends." → `Elixir`: "Clauses match the shapes: `sum([])` is the base, `sum([h | t])` recurses."

### Footer build-stamp decoder

- Stamp id (`#stampId`, verbatim): `TSK0NZi3yy1tTc`.
- Hard-coded fallback timestamp in markup (`#st-ts`): `2026-05-30 16:28:26 UTC`.
- The decoder (`decodeBranded`, mirrors `build_page.py`): strips the 3-char namespace `TSK`, b62-decodes the rest to a Snowflake, shifts out `ts`/`node`/`seq`, adds `EPOCH_MS = 1704067200000`, and renders a UTC string into `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts` on click/Enter/Space. The decoded timestamp matches the markup fallback `2026-05-30 16:28:26 UTC`.

## References (#refs, verbatim)

This page has no `#refs` / References section. There is no References block, no Sources list, and no "Related in this course" list in the markup. (The `<meta description>` mentions the lesson covers material "across three deep-dive subpages" — it does not denote a References section.) The only cross-course links present are the inline dive cards and the pager (see Wiring).

## Wiring

- route-tag (verbatim): `/ elixir / functional / recursion` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<span class="rcur">recursion</span>` (last segment current, not a link).
- crumbs (verbatim): `F2 · Functional` (→ `/elixir/functional`) / `F2.03` (→ `/elixir/functional/higher-order`) / `F2.04` (here).
- toc-mini (verbatim): `The call stack` → `#trace`; `Three deep dives` → `#paths`; `Worked example` → `#worked`.
- pager: prev → `/elixir/functional/higher-order` label `← F2.03 · higher-order`; next → `/elixir/functional/recursion/shape` label `Start · the shape of recursion →`.
- footer: three columns. Brand: logo → `/elixir`, tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." Column `Chapters`: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`). Column `The course`: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`). Foot bar: `© jonnify` + the build stamp.
- Page meta: `<title>` (verbatim) `Recursion patterns & tail calls — F2.04 · jonnify`; `<meta description>` (verbatim) `Recursion as the functional way to repeat: the call stack, tail calls and accumulators for constant stack space, and the patterns that recur — across three deep-dive subpages.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the IIFE with the call-stack tracer + hero figure + branded Snowflake decoder, then the progressive-enhancement reveal script) verbatim from a recent BUILT sibling on the elixir (purple) accent — the model sibling is `elixir/functional/recursion/shape.html` (same chapter, same head/footer/decoder; lift its hub-vs-dive differences from this `index.html` itself). Change only the `<title>` / `<meta description>`, the header `route-tag` (current segment `recursion`, no trailing link), and the `<main>` body (the hub hero with its `hero-art` figure, the `#trace` tracer, the `#paths` dive cards, and the `#worked` example). No-invent guards: use only the real Portal surfaces exactly as written elsewhere in the course — the branded store, the event-sourced engine behind the ONE `Portal` facade, and the Phoenix web app — and cite the companion F5/F6 material for OTP/BEAM internals (this page already does so by mentioning "The BEAM reuses the frame for a tail call" only in the dives, not re-teaching it); do not invent routes, ids, readout strings, or function arities. Voice rules: no first person, no exclamation marks, no emoji, and none of "just" / "simply" / "obviously". Keep the footer build stamp as a real `TSK…` id whose decode matches its `#st-ts` markup. Model sibling to copy from: `elixir/functional/recursion/shape.html`.
