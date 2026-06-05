# F2 — Functional Programming (chapter landing)

- Route (served): `/elixir/functional`
- File: `elixir/functional/index.html`
- Place in the chapter: the chapter hub for F2 · Functional Programming. It frames nine modules in four movements — Foundations (`pure`, `persistence`), The operators (`higher-order`, `recursion`, `folds`), Abstraction (`closures`, `adt`, `composition`), and The lab (`pipeline-lab`) — and sits as the second of six course chapters, after F1 · Algebra and before F3 · The Elixir Language.
- Accent: chapter accent `elixir` (purple — `--elixir:#b39ddb`, `--elixir-bright:#cdb8f0`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `Chapter F2 · nine modules`

H1 (verbatim): `Functional Programming` (the word `Programming` carries the `.ex` italic accent span).

Hero lede (verbatim):

> F1 showed that functions are an algebra. This chapter takes that algebra off the page and makes it the working style of Elixir: pure transformations of immutable data, composed into programs.

Kicker line (verbatim):

> Every idea here has a root in F1 — substitution becomes purity, immutable binding becomes persistent data, composition becomes the pipe, and the higher-order operators become the everyday verbs of the language. The path runs from what a functional value is, through the operators that act on collections, to composing whole programs, and ends in a lab where a dataset flows through a pipeline you build.

## What the page frames

The hub is built from a `deflist` directory under `#modules` (not the `.mods` card grid), grouped by movement. Each module link with its one-line summary and status word:

Foundations
- F2.01 · Pure functions & side effects — "What purity buys; isolating effects." — `/elixir/functional/pure` — built (status word `start here`).
- F2.02 · Immutability & persistent data — "Structural sharing; why copying is cheap." — `/elixir/functional/persistence` — built (`available`).

The operators
- F2.03 · Higher-order functions — "Functions as arguments and return values." — `/elixir/functional/higher-order` — built (`available`).
- F2.04 · Recursion patterns & tail calls — "Accumulators and tail-call optimisation." — `/elixir/functional/recursion` — built (`available`).
- F2.05 · map / filter / reduce (folds) — "reduce as the universal fold." — `/elixir/functional/folds` — built (`available`).

Abstraction
- F2.06 · Closures & partial application — "Capturing environment; the capture operator and currying by hand." — `/elixir/functional/closures` — built (`available`).
- F2.07 · Algebraic data types — "Sum and product types; tagged tuples." — `/elixir/functional/adt` — built (`available`).
- F2.08 · Composition & pipelines — "Building programs by composing functions." — `/elixir/functional/composition` — built (`available`).

The lab
- F2.09 · The data-pipeline lab — "Compose map / filter / reduce over a dataset; watch each stage." — `/elixir/functional/pipeline-lab` — built (`available`).

The `MODS` map in the page script carries the same nine modules with `route`/`slug`/`phase`/`status` (all `available now`); `F2.09` is flagged `lab: true`. The `#sits` section names the neighbours: F2 follows F1 · Algebra and precedes F3 · The Elixir Language and F4 · Algorithms & Data Structures.

## The interactives

### Figure 1 — The journey · select a module
- `<figure>` title (verbatim `<h4 id="jTitle">`): `The journey · select a module`.
- Nine selectable `.arc-node` buttons in `#arc` (SVG `role="button"`), each with a `data-mod` key and an `aria-label`: `F2.01` (pure), `F2.02` (persist), `F2.03` (higher-order), `F2.04` (recursion), `F2.05` (folds), `F2.06` (closures), `F2.07` (ADTs), `F2.08` (compose), `F2.09` (lab). `F2.01` carries `class="arc-node active"` as the static default.
- Readout element ids: `#jNm`, `#jOne`, `#jId`, `#jPhase`, `#jStatus`, `#jOpen`.
- Pure function: `selectMod(id)` reads `MODS[id]` and writes title/one-liner/id/phase/status plus an `Open <id> · <slug> →` link into `#jOpen`. `selectMod('F2.01')` is called on load.
- Static default readout strings (verbatim in markup): `#jNm` = `Pure functions & side effects`; `#jOne` = `What purity buys, and how to keep it: deterministic results and isolated effects.`; `#jId` = `F2.01`; `#jPhase` = `Foundations`; `#jStatus` = `available now`; `#jOpen` link text = `Open F2.01 · pure →`.

### Figure 2 — A pipeline · data through pure stages
- `<figure>` title (verbatim `<h4 id="pTitle">`): `A pipeline · data through pure stages`.
- Control group `#pipeSel` (`role="group"`), three toggle buttons, all `class="active"` by default: `data-stage="map"` `data-c="elixir"` label `map · ×2`; `data-stage="filter"` `data-c="blue"` label `filter · > 6`; `data-stage="reduce"` `data-c="gold"` label `reduce · +`.
- SVG element ids: `#pipeRows` (the rendered chip rows), `#pipeCode` (the live code block, `aria-live="polite"`), `#pipeOut` (the readout, `aria-live="polite"`).
- Pure function: `renderPipe()` computes the chain over `BASE = [1, 2, 3, 4, 5, 6]` — `map` = `x * 2`, `filter` = `x > 6`, `reduce` = `a + b` from `0` — and rebuilds the chip rows, the code lines, and the readout from which stages are active.
- Readout (verbatim default `#pipeOut`): `[1, 2, 3, 4, 5, 6] → map → filter → reduce → 30` (the `30` in `--gold-bright`).
- Code labels rendered per stage (verbatim): `|> Enum.map(&(&1 * 2))`, `|> Enum.filter(&(&1 > 6))`, `|> Enum.reduce(0, &+/2)`.

### Bridge cell (`#shape` section)
- F1 · Algebra → F2 · Functional. F2 cell text (verbatim): "A program is a pipeline of pure transformations — `data |> map |> filter |> reduce`."

### Degrade behaviour
Both figures render a static default in the markup (the `active` arc-node and the default `#pipeOut`/`#jNm` strings), so the content reads without JS. `html.js .reveal` is JS-gated and `prefers-reduced-motion: reduce` disables the reveal transition and the `.arc-flow` dash animation (`@keyframes flow`); `scroll-behavior` falls back to `auto` under reduced motion.

### Footer build-stamp decoder
- Stamp id (verbatim `#stampId`): `TSK0NZi40KKl6m`.
- Decoded UTC timestamp shown in the panel (verbatim `#st-ts`): `2026-05-30 16:28:26 UTC`.
- `decodeBranded` splits the `TSK` namespace from the base-62 Snowflake (`EPOCH_MS = 1704067200000`) and fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`; the stamp toggles open on click/Enter/Space.

## References (#refs, verbatim)

This page has no `#refs` References block — no Sources list and no "Related in this course" list are present in the markup. (The in-page cross-links live in the `#sits` prose and the `#modules` directory, not a refs section.)

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `functional` (`<a href="/elixir">elixir</a>` then `<span class="rcur">functional</span>`).
- crumbs (verbatim): `Course` / `F2 · Functional Programming` (`here`).
- toc-mini: none on the hub; the in-page section anchors are `#arc`, `#shape`, `#modules`, `#sits` (no `.toc-mini` nav).
- pager: prev → `/elixir` label `← Course contents`; next → `/elixir/functional/pure` label `Start · F2.01 · pure →`.
- footer columns (verbatim):
  - foot-brand: `jonnify` logo → `/elixir`; tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `F1 · Algebra` → `/elixir/algebra`; `F2 · Functional Programming` → `/elixir/functional`; `F3 · The Elixir Language` → `/elixir/language`; `F4 · Algorithms & Data Structures` → `/elixir/algorithms`; `F5 · Pragmatic Programming` → `/elixir/pragmatic`; `F6 · Phoenix Framework` → `/elixir/phoenix`.
  - The course: `Course home` → `/elixir`; `Contents & history` → `/elixir/course`; `Start · F1.01` → `/elixir/algebra/functions`.
- Page meta:
  - `<title>` (verbatim): `F2 · Functional Programming — jonnify`
  - `<meta name="description">` (verbatim): `The Functional Programming chapter: pure functions, persistent data, higher-order functions, folds, closures, and composition — a guided path through nine modules ending in a data-pipeline lab.`

## Build instruction

To (re)build this chapter landing, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing two `<script>` blocks verbatim from a recent BUILT sibling on this chapter accent — the model sibling is `elixir/functional/index.html` itself (this hub), or for the head/footer scaffolding any built F2 leaf such as `elixir/functional/pure.html`. Change only the `<title>`/`<meta name="description">`, the `route-tag`, and the `<main>` body (hero, the `#arc` journey figure, the `#shape` pipeline figure, the `#modules` directory, and `#sits`). Keep the `elixir` purple accent tokens (`--elixir`/`--elixir-bright`) on the active arc-node, the `data-c` keys, and the pill/status words. No-invent guards: name only the real course routes and module slugs as written (the nine `/elixir/functional/<slug>` routes); when this page eventually cites the F5/F6 platform, use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent a route, id, readout string, or code token. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
