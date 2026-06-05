# Course home — Functional Programming in Elixir (course landing)

- Route (served): `/elixir`
- File: `elixir/index.html`
- Place in the chapter: the course home and contents hub — the top of the whole `/elixir` tree. It frames the six numbered chapters (`F1` algebra, `F2` functional, `F3` language, `F4` algorithms, `F5` pragmatic, `F6` phoenix) plus the optional history chapter (`F0`), and serves as the contents/route manifest for all 54+ modules. Every chapter card links to its chapter landing; this page is where a reader starts.
- Accent: `elixir` (purple `--elixir` / `--elixir-bright`); the word `Elixir` carries the `.ex` accent in the `<h1>`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Hero eyebrow (verbatim): `A jonnify course`

Hero `<h1>` (verbatim): `Functional Programming in Elixir` (with `Elixir` in the `.ex` purple accent; the markup breaks the line as `Functional Programming<br>in <span class="ex">Elixir</span>`).

Hero lede (verbatim): `A bridge from the algebra you already know to real-time systems on the BEAM.`

Hero kicker (`.kicker`, verbatim): `Six chapters, 54 modules, plus an optional history chapter. Every idea is defined precisely, paired with its Elixir form, and shown — not only described. The code is idiomatic and runnable; the diagrams compute the real thing.`

CTA row (verbatim): `Begin · F1 Algebra →` → `/elixir/algebra`; `Course contents` → `/elixir/course`.

## What the page frames

The page is the contents/route manifest. After the hero it carries three framing sections — `How to read this`, `One idea, early: composition`, and `The map` (with a legend) — followed by one `.chap` section per chapter, each a `.chap-head` plus a `.mods` grid of `<a class="mod">` cards. Every chapter and every module card below is `built` and links live.

Legend (`The map`, verbatim pills + labels): `live` chapter front door · `built` lesson ready · `planned` drafted, on the way · `soon` specified. On this page every card carries the `built` pill.

The six chapters plus the optional history chapter, each a `.chap` section (chapter id · title · `Open chapter →` link · one-line):

- F0 · History — `/elixir/course` — "Where this came from — the languages, the runtimes, and the BEAM." — built
  - F0.1 · The evolution of functional languages & runtimes → `/elixir/course/fp-evolution` — built
    - dives: F0.1.1 From λ-calculus to LISP · F0.1.2 Types & laziness — the ML and Haskell branch · F0.1.3 The immutable turn — persistent data on the JVM & CLR
  - F0.2 · The evolution of Erlang, the BEAM & OTP → `/elixir/course/beam-evolution` — built
    - dives: F0.2.1 Telecom roots & "let it crash" · F0.2.2 Inside the BEAM — scheduling, heaps & soft-real-time GC · F0.2.3 OTP & the supervision tree — and the polyglot BEAM
- F1 · Algebra — `/elixir/algebra` — "The functional mindset, straight from the math you already know." — built (9 modules)
  - F1.01 What a function really is → `/elixir/algebra/functions` — built
  - F1.02 The substitution model → `/elixir/algebra/substitution` — built
  - F1.03 Composition, f∘g → `/elixir/algebra/composition` — built
  - F1.04 Immutability & binding → `/elixir/algebra/immutability` — built
  - F1.05 Sets, sequences & mappings → `/elixir/algebra/collections` — built
  - F1.06 Recursion & induction → `/elixir/algebra/recursion` — built
  - F1.07 Higher-order operators (Σ, Π) → `/elixir/algebra/higher-order` — built
  - F1.08 Equations & pattern matching → `/elixir/algebra/pattern-matching` — built
  - F1.09 Functions on the plane — a plotting lab → `/elixir/algebra/plotting-lab` — built (lab)
- F2 · Functional Programming — `/elixir/functional` — "Pure functions, immutability, and higher-order functions on their own terms." — built (9 modules)
  - F2.01 Pure functions & side effects → `/elixir/functional/pure` — built
  - F2.02 Immutability & persistent data → `/elixir/functional/persistence` — built
  - F2.03 Higher-order functions → `/elixir/functional/higher-order` — built
  - F2.04 Recursion patterns & tail calls → `/elixir/functional/recursion` — built
  - F2.05 map / filter / reduce (folds) → `/elixir/functional/folds` — built
  - F2.06 Closures & partial application → `/elixir/functional/closures` — built
  - F2.07 Algebraic data types → `/elixir/functional/adt` — built
  - F2.08 Composition & pipelines → `/elixir/functional/composition` — built
  - F2.09 The data-pipeline lab → `/elixir/functional/pipeline-lab` — built (lab)
- F3 · The Elixir Language — `/elixir/language` — "Syntax, pipelines, pattern matching, and structs on the BEAM." — built (9 modules)
  - F3.01 Values, types & IEx → `/elixir/language/values` — built
  - F3.02 Pattern matching & the match operator → `/elixir/language/match` — built
  - F3.03 Functions, modules & the pipe → `/elixir/language/modules` — built
  - F3.04 Enumerables & streams → `/elixir/language/enum-streams` — built
  - F3.05 Structs, maps & keyword lists → `/elixir/language/structs` — built
  - F3.06 Protocols & behaviours → `/elixir/language/protocols` — built
  - F3.07 Processes & the actor model → `/elixir/language/processes` — built
  - F3.08 OTP: GenServer & supervisors → `/elixir/language/otp` — built
  - F3.09 The process playground → `/elixir/language/playground` — built (lab)
- F4 · Algorithms & Data Structures — `/elixir/algorithms` — "Classical and advanced problems, from lists to branded CHAMP tries." — built (9 modules listed in the arc; 12 cards F4.01–F4.12)
  - F4.01 Lists, recursion & complexity → `/elixir/algorithms/lists` — built
  - F4.02 Trees & traversals → `/elixir/algorithms/trees` — built
  - F4.03 Sorting & searching → `/elixir/algorithms/sorting` — built
  - F4.04 Maps, sets & hashing → `/elixir/algorithms/maps` — built
  - F4.05 Hash Array Mapped Tries (HAMT) → `/elixir/algorithms/hamt` — built
  - F4.06 CHAMP maps → `/elixir/algorithms/champ` — built
  - F4.07 Identifiers, Snowflake & branded ids → `/elixir/algorithms/identifiers` — built
  - F4.08 Branded ids & persistence → `/elixir/algorithms/persistence` — built
  - F4.09 Branded CHAMP maps & GenServer → `/elixir/algorithms/branded-champ` — built
  - F4.10 Practical recipes in Elixir → `/elixir/algorithms/recipes` — built
  - F4.11 Dynamic programming & advanced problems → `/elixir/algorithms/dynamic-programming` — built
  - F4.12 Lab: build a branded CHAMP store → `/elixir/algorithms/lab` — built (lab)
- F5 · Pragmatic Programming — `/elixir/pragmatic` — "Real-world engineering: structure, testing, telemetry, releases." — built (9 modules)
  - F5.01 Foundations → `/elixir/pragmatic/foundations` — built
  - F5.02 Modeling the Portal domain → `/elixir/pragmatic/domain` — built
  - F5.03 Tracer bullets: a walking skeleton → `/elixir/pragmatic/tracer-bullets` — built
  - F5.04 Design by contract → `/elixir/pragmatic/contracts` — built
  - F5.05 Commands, queries & events → `/elixir/pragmatic/cqrs` — built
  - F5.06 Where engine state lives → `/elixir/pragmatic/state` — built
  - F5.07 Pragmatic testing → `/elixir/pragmatic/testing` — built
  - F5.08 Boundaries & integration seams → `/elixir/pragmatic/boundaries` — built
  - F5.09 Lab: the Portal engine, LiveView-ready → `/elixir/pragmatic/engine-lab` — built (lab)
- F6 · Phoenix Framework — `/elixir/phoenix` — "Web applications on Elixir, and the road into real-time LiveView." — built (9 modules)
  - F6.01 Architecture & the request lifecycle → `/elixir/phoenix/lifecycle` — built
  - F6.02 Routing, controllers & plugs → `/elixir/phoenix/routing` — built
  - F6.03 Ecto: schemas, changesets & queries → `/elixir/phoenix/ecto` — built
  - F6.04 Contexts & domain design → `/elixir/phoenix/contexts` — built
  - F6.05 Templates, components & HEEx → `/elixir/phoenix/heex` — built
  - F6.06 Phoenix LiveView fundamentals → `/elixir/phoenix/liveview` — built
  - F6.07 PubSub, channels & real-time → `/elixir/phoenix/pubsub` — built
  - F6.08 Auth, deployment & going live → `/elixir/phoenix/deployment` — built
  - F6.09 The live dashboard → `/elixir/phoenix/live-dashboard` — built (lab)

`How to read this` prose (verbatim takeaway, `.take`): "The course is one curve, not eight disconnected topics. Read it in order and each chapter is a consequence of the last."

## The interactives

This landing carries two interactive figures plus the footer build-stamp decoder. There are no `#refs`, `.crumbs`, or `.toc-mini` on this page (it is the course landing, not a lesson) — those sections are absent.

### Figure 1 — "The arc · select a chapter" (`#arcTitle`)

- Markup: `<figure class="fig" aria-labelledby="arcTitle">` titled `The arc · select a chapter`. An inline `<svg viewBox="0 0 1000 152">` draws six `.arc-node` `<g>` group "buttons" along one flow line, plus a readout block `.arc-readout`.
- Control ids / nodes: six `.arc-node` groups, each `role="button" tabindex="0"`, keyed by `data-ch`: `F1` (label `Algebra`, starts `active`), `F2` (`Functional`), `F3` (`Language`), `F4` (`Algorithms`), `F5` (`Pragmatic`), `F6` (`Phoenix`). The flow runs from a `start` label (sage) to a `real-time` label (blue).
- Readout element ids: `#arcNm` (chapter name), `#arcOne` (one-line), `#arcId` (chapter id, in `.meta`), `#arcMods` (module count), `#arcReuse` (what it reuses), `#arcOpen` (the open-chapter link). Default static values are `F1`'s.
- Pure function: `selectChapter(id)` — looks up `byId[id]` from the inline `CH` dataset, toggles each `.arc-node`'s `active` class + `aria-pressed`, writes `c.name`/`c.one`/`c.id`/`String(c.modules)`/`c.reuses` into the readout ids, and rebuilds `#arcOpen` as an `<a href=c.route>` reading `Open <id> · <name> →` when `c.live`, else a `.muted` span `<id> · <name> — in progress`. Wired by `click` and `keydown` (Enter/Space) on each node.
- The `CH` dataset (verbatim per-chapter `one`/`reuses`, all `live:true`, `modules:9`):
  - `F1` Algebra → `/elixir/algebra` — one: "The functional mindset, straight from the math you already know." reuses: "Starts from the algebra you already know."
  - `F2` Functional Programming → `/elixir/functional` — one: "Pure functions, immutability, and higher-order functions on their own terms." reuses: "Builds on F1 · Algebra."
  - `F3` The Elixir Language → `/elixir/language` — one: "Syntax, pipelines, pattern matching, and structs on the BEAM." reuses: "Builds on F2 · Functional Programming."
  - `F4` Algorithms & Data Structures → `/elixir/algorithms` — one: "Classical and advanced problems, from lists to branded CHAMP tries." reuses: "Builds on F3 · The Elixir Language."
  - `F5` Pragmatic Programming → `/elixir/pragmatic` — one: "Real-world engineering: structure, testing, telemetry, releases." reuses: "Builds on F4 · Algorithms & Data Structures."
  - `F6` Phoenix Framework → `/elixir/phoenix` — one: "Web applications on Elixir, and the road into real-time LiveView." reuses: "Builds on F5 · Pragmatic Programming."
- Default readout strings (static markup, the `F1` row, verbatim): `#arcNm` = "Algebra"; `#arcOne` = "The functional mindset, straight from the math you already know."; `.meta` = "F1 · chapter", "9 modules", "Starts from the algebra you already know."; `#arcOpen` link = "Open F1 · Algebra →" → `/elixir/algebra`.

### Figure 2 — "The pipe · build a pipeline" (`#pipeTitle`)

- Markup: `<figure class="fig" aria-labelledby="pipeTitle">` titled `The pipe · build a pipeline`. A `.controls` block holds an input slider and a `.solid-select#pipeStages` button group; below sit a `<pre class="code" id="pipeCode">` and a `.geo-readout#pipeChain`.
- Controls: `#pipeX` range slider (`min="0" max="12" step="1" value="3"`) with its value mirrored in `#pipeXval`; `#pipeStages` group of three toggle buttons, each `data-stage` + `data-c`, all start `active aria-pressed="true"`: `double` (`data-c="blue"`), `increment` (`data-stage="inc"`, `data-c="sage"`), `square` (`data-c="gold"`).
- SVG / element ids: `#pipeCode` (the rebuilt pipeline source), `#pipeChain` (the value chain readout).
- Pure functions: `STAGES` array of three steps — `double` `function(v){return v*2}`, `inc` `function(v){return v+1}`, `square` `function(v){return v*v}`. `activeStages()` reads which `#pipeStages` buttons hold `active`. `renderPipe()` parses `#pipeX`, folds `x` through the active stages, rebuilds `#pipeCode` line-by-line (`x |> label() # => v`, comments aligned to the widest label `increment`), and writes the chain into `#pipeChain`.
- Readout strings (verbatim): the static default `#pipeChain` markup reads `3 ▷ 6 ▷ 7 ▷ 49  = 49`. With every stage off, `renderPipe()` writes `x  = x (identity)`. With stages on, it writes `chain joined by " ▷ "` then `  = v`. The static `#pipeCode` default is the three-line block `3` / `|> double()    # => 6` / `|> increment() # => 7` / `|> square()    # => 49`.
- `.take` (verbatim): "A pipeline reads left to right: `x |> f |> g` is g(f(x)). Turn every function off and the pipeline is the identity — it returns its input untouched. F1.03 makes f∘g and its associativity precise."
- Degrades: both figures ship full static markup (controls, SVG, the default `F1` arc readout, the default pipe code + chain) — JS only enhances. `renderPipe()` and `selectChapter('F1')`-equivalent default state are already present without JS. `prefers-reduced-motion` is respected globally (the `.arc-flow` dash animation is gated behind `@media (prefers-reduced-motion: no-preference)`, and the reveal-on-scroll script falls back to showing all `.reveal` sections). No browser storage is used.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0Nb1VTbfnu4` (in `#stampId`); panel `#st-ts` hard-codes `2026-05-31 11:28:08 UTC`.
- Pure functions: `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`; `decodeBranded(id)` — splits `ns = id.slice(0,3)` (`TSK`) and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, with epoch `EPOCH_MS = 1704067200000`, formatting a UTC timestamp. Fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`. Decoded build timestamp: `2026-05-31 11:28:08 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References block. As the course landing it carries no Sources or Related-in-this-course list — the section is absent (not fabricated here).

## Wiring

- route-tag: `<span class="route-tag"><span class="rsep">/</span><span class="rcur">elixir</span></span>` — the segmented route-tag, with the current segment `elixir` as `.rcur` (no intermediate `<a>` links, since `/elixir` is the root).
- crumbs: none — the course landing has no `.crumbs` row (the header `nav` instead carries a `Contents` link → `/elixir/course` and the route-tag).
- toc-mini: none — the landing has no in-page `.toc-mini` anchor strip. Its in-page sections are `How to read this`, `One idea, early: composition`, `The map`, and the per-chapter `.chap` sections, but they are not surfaced as a `.toc-mini`.
- pager: a single `.pager` (`p-left` text `jonnify · Functional Programming in Elixir`) with one forward CTA — next → `/elixir/algebra` ("Begin · F1 Algebra →"). No prev link (this is the course root).
- footer: `<footer class="site-foot">` with a three-column `.foot-nav`:
  - Brand column — `.foot-logo` → `/elixir`; tag (verbatim): "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - `Chapters` column links (verbatim): `F1 · Algebra` → `/elixir/algebra`; `F2 · Functional Programming` → `/elixir/functional`; `F3 · The Elixir Language` → `/elixir/language`; `F4 · Algorithms & Data Structures` → `/elixir/algorithms`; `F5 · Pragmatic Programming` → `/elixir/pragmatic`; `F6 · Phoenix Framework` → `/elixir/phoenix`.
  - `The course` column links (verbatim): `Course home` → `/elixir`; `Contents & history` → `/elixir/course`; `Start · F1.01` → `/elixir/algebra/functions`.
  - `.foot-bar`: `© jonnify` plus the `#stamp` build-stamp decoder.
- Page meta: `<title>` "Functional Programming in Elixir — a jonnify course"; `<meta name="description">` "A bridge from the algebra you already know to real-time apps on the BEAM. Six chapters, fifty-four modules, interactive and runnable throughout."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the `elixir` (purple) accent — this course-home page (`elixir/index.html`) is itself the canonical model for the shared shell, the arc/pipe interactives, and the build-stamp decoder; the chapter-landing pattern is mirrored at `elixir/algebra/index.html` (`/elixir/algebra`). Change only the `<title>`/`<meta description>`, the route-tag, and the `<main>` body (hero, the framing sections, and the per-chapter `.mods` grid). Use only the real Portal surfaces exactly as written — a branded store, an event-sourced engine behind ONE `Portal` facade, and a Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; invent no routes, ids, readout strings, code tokens, or chapter cards. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Specific model sibling to copy from on this accent: `elixir/algebra/index.html` (the F1 chapter landing) for the header/footer/stamp shell, and this file itself for the contents-manifest body.
