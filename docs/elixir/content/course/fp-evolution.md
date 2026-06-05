# F0.1 — The evolution of functional languages & runtimes (dive)

- Route (served): `/elixir/course/fp-evolution`
- File: `elixir/course/fp-evolution.html`
- Place in the chapter: the first of the two history modules in F0, tracing the language lineage Elixir inherited. It precedes F0.2 (the runtime story at `/elixir/course/beam-evolution`) and feeds directly into F1 · Algebra. Three dives follow the overview, each pairing a historical idea with the exact place it reappears in Elixir.
- Accent: chapter F0 · History · blue (timeline rail and bridge cells; the page sits on the shared editorial palette with the elixir-bright accent on the "In Elixir" echoes).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F0 · History · optional`

H1 (verbatim): `The evolution of functional languages & runtimes`

Lede (verbatim): "Everything Elixir leans on was argued out decades earlier. This module traces the line — from the λ-calculus to the immutable runtimes that made the idea ordinary."

Kicker (verbatim): "This chapter is context, not a prerequisite: F1 stands on its own. Read it to see where each idea came from and why it survived. Three dives follow the overview, and each one pairs a historical idea with the exact place it reappears in Elixir."

## Sections

In order:

1. Overview — `One line, six steps` (the interactive lineage timeline; running example: the six-step `λ-calculus → LISP → ML → Haskell → Clojure → Elixir` rail).
2. `#lisp-origins` — dive `F0.1.1` · `From the λ-calculus to LISP` (teaching). Bridge: `λ-calculus, 1936` (`λx. x * x`) → `Elixir, today` (`fn x -> x * x end`, applied with `.(3)`). Running example: β-reduction of `(λx. x * x) ((λy. y + 1) n)`. Real Elixir token shown: `fn x -> x * x end`.
3. `#ml-haskell` — dive `F0.1.2` · `Types & laziness — the ML and Haskell branch` (teaching). Bridge: `Haskell, lazy by default` (`take 3 (map f [1..])`) → `Elixir, lazy on request` (`1.. |> Stream.map(f) |> Enum.take(3)`). Running example: strict-vs-lazy square pipeline over a 100,000-element source. Real Elixir tokens: `Stream.map`, `Enum.take`, `Enum.map`, `&(&1 * &1)`.
4. `#immutable-turn` — dive `F0.1.3` · `The immutable turn — persistent data on the JVM & CLR` (teaching). Bridge: `Persistent structure` → `Elixir collections` (maps and lists immutable, runtime shares structure; "F4.05–F4.07 build the HAMT, CHAMP, and branded keys"). Running example: a persistent eight-leaf tree, updating one leaf. Real Elixir token shown: the branded key `TSK0KHTOWnGLuC`.
5. Synthesis — `What this lands` (no interactive; threads forward into F1.02, F3, F4) followed by the pager.

## The interactives

- `<figure aria-labelledby="linTitle">` — title `The lineage · select a step`. Six SVG nodes `g.arc-node` carry `data-era="0"`..`"5"` (`role="button"`, `tabindex="0"`), node 0 default `.active`. Readout targets: `#linNm`, `#linIdea`, `#linYear`, `#linWho`, `#linEcho`. Pure function `selectEra(i)` reads `ERAS[i]` and writes those five ids. The `ERAS` table (verbatim `nm` / `y` / `who` / `idea` / `echo`):
  - `1936` · `Alonzo Church` · `The λ-calculus` — idea "Computation as functions and substitution: no state, no steps, only rewriting a term until it can reduce no further." — echo "expressions reduce to values; the substitution model of F1.02 is this idea, named."
  - `1958` · `John McCarthy` · `LISP` — idea "The first executable functional language: code as data, the literal lambda, automatic memory, and the interactive prompt." — echo "IEx is that prompt; fn x -> ... end is the lambda; the BEAM manages memory for you."
  - `1973` · `Robin Milner` · `ML` — idea "Type inference and pattern matching: code organised by the shape of its data, checked by the compiler." — echo "Elixir keeps the pattern matching outright — function heads and case mirror ML's clauses."
  - `1990` · `a committee` · `Haskell` — idea "Purity by default and lazy evaluation: effects are explicit, and nothing is computed before it is needed." — echo "effects stay pragmatic, but laziness returns as the Stream module in F3.04."
  - `2007` · `Rich Hickey` · `Clojure` — idea "Persistent data structures on the JVM made immutable collections cheap through structural sharing." — echo "Elixir's maps and lists share structure too; F4.05 and F4.06 build the HAMT and CHAMP."
  - `2012` · `José Valim` · `Elixir` — idea "A functional language on the BEAM that gathers the line above and aims it at concurrency and real-time." — echo "this course; the runtime half of the story is F0.2."
  - Default readout in markup: `#linNm` = `The λ-calculus`, `#linIdea` = the 1936 idea string, `#linYear` = `1936`, `#linWho` = `Alonzo Church`, `#linEcho` = "expressions reduce to values; the substitution model of F1.02 is this idea, named."
- `<figure aria-labelledby="betaTitle">` — title `β-reduction · step through an evaluation`. Controls: range `#betaN` (`input n`, 0–9, default 2, value label `#betaNval`); range `#betaStep` (`reduction`, 0–4, default 4, value label `#betaStepval` formatted `step / 4`). Code target `#betaCode` (`aria-live="polite"`); readout `#betaOut`. Pure function `betaTrace(n)` computes `m = n + 1`, `r = m * m` and returns the five-line reduction trace `(λx. x * x) ((λy. y + 1) n) →β (λx. x * x) (n + 1) →δ (λx. x * x) m →β m * m →δ r`; `renderBeta()` renders up to the chosen step. Readout VERBATIM: "n = 2 · (n + 1)² = 9" (recomputed as `n = {n} · (n + 1)² = {(n+1)*(n+1)}`). Deflist rows: `α rename`, `β apply`, `δ arithmetic`, `normal form` (definitions as in markup).
- `<figure aria-labelledby="lazyTitle">` — title `Strict vs lazy · count the work`. Control group `#lazyMode` (`role="group"`) with buttons `data-mode="lazy"` `data-c="elixir"` (default active, label `lazy · Stream`) and `data-mode="eager"` `data-c="blue"` (label `eager · Enum`); range `#lazyK` (`take k`, 1–8, default 3, value label `#lazyKval`). Code target `#lazyCode`; readout `#lazyOut`. Pure logic `renderLazy()` with `SOURCE_N = 100000`: `evaluated = (mode === 'lazy') ? k : SOURCE_N`, building `squares = [1², …, k²]`. Readout strings VERBATIM: lazy — "lazy: squares computed = **{k}** · result = [{squares}]"; eager — "eager: squares computed = **100,000** · result = [{squares}]". The code block shows the real lazy pipeline `1.. |> Stream.map(&(&1 * &1)) |> Enum.take(k)` vs the eager `1..100,000 |> Enum.map(&(&1 * &1)) |> Enum.take(k)`.
- `<figure aria-labelledby="shareTitle">` — title `Structural sharing · update one leaf`. Control: range `#shareLeaf` (`update leaf`, 0–7, default 5, value label `#shareLeafval` formatted `#i`); SVG of an eight-leaf persistent tree; readout `#shareOut`. Pure logic `renderShare()`: `a = floor(i/4)`, `b = floor(i/2)`, lighting the path nodes `nr`, `na{a}`, `nb{b}`, `nc{i}` and edges `e_a{a}`, `e_b{b}`, `e_c{i}`. Readout VERBATIM: "copied: **4** · shared: **11** · total: 15 · O(log n) = 4, not O(n) = 15".
- Degrade behaviour: there are no `.reveal` elements on this page; the trailing script still adds `html.js` and is a no-op here. The animated `.arc-flow` dashes run only under `prefers-reduced-motion: no-preference`; figures carry static default readouts in the markup so the page reads with JS off.
- Footer build-stamp decoder (`#stamp` / `#stampId`): real id `TSK0NZ8mp4xvP6`; markup-decoded timestamp `2026-05-30 08:14:47 UTC`. The JS comment notes the decoder "mirrors build_page.py" (3-char namespace + base62 snowflake, `EPOCH_MS = 1704067200000`, `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF`).

## References (#refs, verbatim)

This page has no `#refs` References section — there is no intro line, no Sources list, and no "Related in this course" block. Forward cross-links live inline in the dive prose and takeaways instead (F1.01, F1.02, F3.04, F4, F4.05, F4.06, F4.07, F0.2). The only `https://` links are the Google Fonts preconnect/stylesheet in `<head>`.

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `course` ` / ` `fp-evolution` — markup `<span class="route-tag"><span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/course">course</a><span class="rsep">/</span><span class="rcur">fp-evolution</span></span>`.
- crumbs (verbatim): `F0 · History` (links `/elixir/course`) `/` `F0.1`.
- toc-mini: `F0.1.1 · λ-calculus → LISP` → `#lisp-origins`; `F0.1.2 · ML & Haskell` → `#ml-haskell`; `F0.1.3 · the immutable turn` → `#immutable-turn`.
- pager: prev → `/elixir/course` label `Course contents`; next → `/elixir/algebra` label `Next · F1 Algebra`.
- footer: three columns identical to the F0 landing. Brand logo → `/elixir` + the "taught twice" tagline. Column `Chapters`: `F1 · Algebra` → `/elixir/algebra`, `F2 · Functional Programming` → `/elixir/functional`, `F3 · The Elixir Language` → `/elixir/language`, `F4 · Algorithms & Data Structures` → `/elixir/algorithms`, `F5 · Pragmatic Programming` → `/elixir/pragmatic`, `F6 · Phoenix Framework` → `/elixir/phoenix`. Column `The course`: `Course home` → `/elixir`, `Contents & history` → `/elixir/course`, `Start · F1.01` → `/elixir/algebra/functions`. Foot bar: `© jonnify` + build stamp.
- Page meta — `<title>`: `The evolution of functional languages & runtimes — F0.1 · jonnify`. `<meta name="description">`: "From the lambda calculus to LISP, the ML and Haskell branch, and the immutable turn — the lineage Elixir inherited, each idea paired with its Elixir form."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks (the four interactives + the snowflake decoder, then the reveal/`html.js` enhancer) verbatim from a recent built F0 sibling on this chapter; change only `<title>` / `<meta>`, the `route-tag` current segment, the crumbs, and the `<main>` body (the lineage timeline, the three dives with their bridge cells, and the synthesis). No-invent guards: present only the real lineage and the real Elixir forms each idea maps to — use the actual `ERAS` facts (years, people, the one-line ideas) and the real Elixir surfaces (`fn`, `Stream.map`, `Enum.take`, immutable maps/lists, the branded `TSK…` key); do not invent dates, attributions, routes, or code. Defer runtime internals to F0.2 and the companion course; cross-link forward (F1.02, F3.04, F4.05–F4.07) rather than re-teaching. Voice rules: no first person, no exclamation marks, no emoji, none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/course/beam-evolution.html` (the other F0 dive — same head, footer, timeline-and-three-dives anatomy, and decoder script).
