# F2.03 — Higher-order functions (dive)

- Route (served): `/elixir/functional/higher-order`
- File: `elixir/functional/higher-order.html`
- Place in the chapter: the third module of F2 · Functional Programming and the first of its The operators movement. It follows F2.02 · Immutability & persistent data and introduces the verbs that act on collections — functions as values — leading into F2.04 · Recursion and F2.05 · folds. Its closing section seeds the closure idea developed in F2.06.
- Accent: chapter accent `elixir` (purple — `--elixir`/`--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2 · Functional Programming`

H1 (verbatim): `Higher-order functions`

Hero lede (verbatim):

> In a functional language, functions are values like any other. A higher-order function is one that takes a function as an argument or returns one — so you can pass behaviour around the way you pass a number or a list.

Kicker line (verbatim):

> F1.07 met this idea in the abstract: the sum and product operators each took a function and applied it across a range. Here it is the everyday tool. `Enum.map` takes a function and runs it over a list; `Enum.filter` takes a test; `Enum.reduce` takes a combiner. And a function can build and return another function. Writing the iteration once and passing in the part that varies is how functional code stays small.

## Sections

In order, three teaching sections (each closes with a `.bridge` and a `.take`), then a synthesis:

1. `#pass` — "Passing a function". `Enum.map` is the canonical higher-order function: the list operation is fixed, the behaviour is a parameter. Carries a `deflist` defining `higher-order function`, `first-class`, `capture operator`, `function factory`. Running example: `Enum.map` over `[1, 2, 3, 4]` with a chosen function.
2. `#roles` — "One shape, many roles". Different operators expect different function shapes — `map` a transformer, `filter` a test, `reduce` a combiner, `sort_by` a key. The signature tells the role. Running example: each operator's signature, example, and result.
3. `#return` — "Returning a function". A factory returns a function carrying a captured value — `adder` takes `n` and returns a function that adds `n`. Running example: build with `n`, apply to `x`.
4. Synthesis "What this lands", then the pager.

Real Elixir shown across the sections (verbatim): `Enum.map`, `Enum.filter`, `Enum.reduce`, `sort_by`; the capture forms `&(&1 * 2)`, `&(&1 + 1)`, `&(&1 * &1)`, `&(-&1)`, `&String.upcase/1`; the role example `&(&1 * 10)`; and the factory `fn n -> fn x -> x + n end end` building `fn x -> x + 5 end` (`add5`).

## The interactives

### Figure 1 — Enum.map · the behaviour is an argument
- `<figure>` title (verbatim `<h4 id="passTitle">`): `Enum.map · the behaviour is an argument`.
- Control group `#passSel` (`role="group"`), four buttons (`data-fn`): `dbl` `data-c="elixir"` (active by default) label `&(&1 * 2)`; `inc` `data-c="blue"` label `&(&1 + 1)`; `sq` `data-c="sage"` label `&(&1 * &1)`; `neg` `data-c="gold"` label `&(-&1)`.
- SVG element ids: `#passIn` (the input chips), `#passFn` (the function shown on the `Enum.map` box), `#passOut` (the output chips); plus `#passCode` and `#passOutTxt` readouts (`aria-live="polite"`).
- Pure function: the section script maps the chosen function over `[1, 2, 3, 4]`, rendering the input and output chips, the code, and the readout.
- Readout (verbatim default `#passOutTxt`): `f = &(&1 * 2) · [1, 2, 3, 4] → [2, 4, 6, 8]` (the result list in `--elixir-bright`).

### Figure 2 — The function each one expects
- `<figure>` title (verbatim `<h4 id="rolesTitle">`): `The function each one expects`.
- Control group `#roleSel` (`role="group"`), four buttons (`data-h`): `map` `data-c="elixir"` (active) label `map`; `filter` `data-c="blue"` label `filter`; `reduce` `data-c="gold"` label `reduce`; `sortby` `data-c="sage"` label `sort_by`.
- SVG element ids: `#roleCall` (the call), `#roleSig` (the function signature), `#roleRole` (the role label), `#roleEx` (the example function), `#roleRes` (the example result); plus `#roleCode` and `#roleOut` readouts.
- Pure function: the section script reads the chosen operator and writes its call, the signature of the function it takes, the role, the worked example, the code, and the readout.
- Readout (verbatim default `#roleOut`): `Enum.map takes a → b · a transformer · [3, 1, 2] → [30, 10, 20]` (the `a → b` in `--gold-bright`). Static defaults in markup: `#roleCall` = `Enum.map(list, fun)`; `#roleSig` = `fun : a → b`; `#roleEx` = `&(&1 * 10)`; `#roleRes` = `[3, 1, 2] → [30, 10, 20]`.

### Figure 3 — A function factory · build, then apply
- `<figure>` title (verbatim `<h4 id="retTitle">`): `A function factory · build, then apply`.
- Controls: two `.fold-ctrl` sliders — `#retN` (`min=0 max=9 step=1 value=5`, label `#retNval` default `5`) and `#retX` (`min=0 max=9 step=1 value=3`, label `#retXval` default `3`).
- SVG element ids: `#retN1` (captured `n`), `#retClosure` (the returned closure), `#retX1` (the applied `x`), `#retApply` (the named function), `#retResult` (the result); plus `#retCode` and `#retOut` readouts.
- Pure function: the section script builds the closure from `n` (e.g. `fn x -> x + 5 end`), applies it to `x`, and writes the closure text, the result, the code, and the readout.
- Readout (verbatim default `#retOut`): `adder.(5) returns add5 = fn x → x + 5 · add5.(3) = 8` (the `8` in `--sage-bright`). Static defaults in markup: `#retClosure` = `fn x -> x + 5 end`; `#retApply` = `add5`; `#retResult` = `8`.

### Degrade behaviour
Each figure renders its static default in the markup (the active button + the verbatim default readouts above), so the lesson reads without JS. `html.js .reveal` is JS-gated; `prefers-reduced-motion: reduce` disables the reveal transition; `scroll-behavior` falls back to `auto` under reduced motion.

### Footer build-stamp decoder
- Stamp id (verbatim `#stampId`): `TSK0NZdG3wr1zU`.
- Decoded UTC timestamp (verbatim `#st-ts`): `2026-05-30 15:21:12 UTC`.
- `decodeBranded` splits the `TSK` namespace from the base-62 Snowflake (`EPOCH_MS = 1704067200000`) and fills the panel rows; toggles open on click/Enter/Space.

## References (#refs, verbatim)

This page has no `#refs` References block — no intro line, no Sources list, and no "Related in this course" list are present in the markup. The cross-links it carries are inline: the `.bridge` cells cite `F1.07 · operators`, `Elixir`, and `Idea`; the synthesis and `.note` point back to F1.07, forward to F2.04 and F2.06 (the closure), and to `/elixir/functional` (the F2 overview).

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `functional` `/ ` `higher-order` (`<a href="/elixir">elixir</a>`, `<a href="/elixir/functional">functional</a>`, `<span class="rcur">higher-order</span>`).
- crumbs (verbatim): `F2 · Functional` → `/elixir/functional` / `F2.02` → `/elixir/functional/persistence` / `F2.03` (`here`).
- toc-mini (`.toc-mini`, in-page anchors): `Passing a function` → `#pass`; `One shape, many roles` → `#roles`; `Returning a function` → `#return`.
- pager: prev → `/elixir/functional/persistence` label `← F2.02 · persistent data`; next → `/elixir/functional` label `More in F2 · Functional →`.
- footer columns (verbatim): identical to the chapter hub — foot-brand `jonnify` → `/elixir` with the "functional thinking taught twice" tagline; Chapters `F1 · Algebra`/`F2 · Functional Programming`/`F3 · The Elixir Language`/`F4 · Algorithms & Data Structures`/`F5 · Pragmatic Programming`/`F6 · Phoenix Framework` → `/elixir/algebra`/`/elixir/functional`/`/elixir/language`/`/elixir/algorithms`/`/elixir/pragmatic`/`/elixir/phoenix`; The course `Course home`/`Contents & history`/`Start · F1.01` → `/elixir`/`/elixir/course`/`/elixir/algebra/functions`.
- Page meta:
  - `<title>` (verbatim): `Higher-order functions — F2.03 · jonnify`
  - `<meta name="description">` (verbatim): `Functions as values: passing a function into Enum.map, the differing signatures map / filter / reduce / sort_by expect, and a factory that returns a function carrying a captured value.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent BUILT sibling on this chapter accent — the model sibling is `elixir/functional/persistence.html` (the previous F2 leaf: same three-section hero/`toc-mini`/`bridge`/`take`/`deflist` anatomy and the same footer). Change only the `<title>`/`<meta name="description">`, the `route-tag`, the crumbs, and the `<main>` body (hero, the `#pass`/`#roles`/`#return` figures and their data, and the synthesis). Keep the `elixir` purple accent as the primary on `data-c="elixir"` controls (with blue/sage/gold for the alternative functions), and keep the stamp decoder verbatim. No-invent guards: cite only the real Elixir surfaces as written (`Enum.map`, `Enum.filter`, `Enum.reduce`, `sort_by`, the capture operator `&`, `&String.upcase/1`, `fn n -> fn x -> x + n end end`) and the real course routes; if later editions reach the F5/F6 platform, name only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent a signature, readout string, code token, or route. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
