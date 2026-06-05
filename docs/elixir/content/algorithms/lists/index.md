# F4.01 — Lists, recursion & complexity (module hub)

- Route (served): `/elixir/algorithms/lists`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/index.html`
- Place in the chapter: the opening module of `F4 · Algorithms & Data Structures`. It frames the chapter's first idea — the BEAM list is a linked list of cons cells, not an array — and fans out into three dives (`cons`, `recursion`, `big-o`). The chapter bridge points back to `F3` (processes held state, which is made of data) and forward to `F4.02 — Trees & traversals`.
- Accent: sage (the `F4` chapter accent; the hero/figure controls use `--sage-bright`, with `blue` and `gold` for the secondary angles).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4 · Foundations · module 1`

Hero `h1`: Lists, recursion & complexity

Lede (verbatim):

> The list is the BEAM's fundamental sequence, and it is a linked list of **cons cells**, not an array. That one fact explains everything that follows: why prepending is instant, why finding the length is not, why every list function is written by recursion, and how to read the cost of an operation straight from the shape of the data.

Kicker (verbatim):

> This module builds the list from three angles — the cons-cell shape, the recursion that walks it, and the big-O cost that shape implies. The portal's lesson minutes are the running example.

## What the page frames

The hub has no `.mods` grid; the three children are rendered as full-width dive cards in the `#dives` section (`.dives` flow). Each card:

- `F4.01.1` — **Cons cells & the shape of a list** — "A list is `[head | tail]`. Prepending is O(1); `hd/1` and `tl/1` read the cell; appending must copy." — route `/elixir/algorithms/lists/cons` — sage left-border — built.
- `F4.01.2` — **Recursion over lists** — "Match `[h | t]`, act on the head, recurse on the tail, stop at `[]` — with a tail-recursive accumulator." — route `/elixir/algorithms/lists/recursion` — blue left-border — built.
- `F4.01.3` — **Complexity & big-O on the BEAM** — "O(1) prepend versus O(n) length, `++`, and last — reading cost from how many cells an operation must touch." — route `/elixir/algorithms/lists/big-o` — gold left-border — built.

Chapter bridge (`.bridge`): left cell `F3 · processes held state` — "In F3 a process kept state between messages. That state is made of data — and the list is where data structures start."; right cell `F4 · the data and its cost` — "A list is a chain of cons cells. Its shape fixes the cost of every operation, which is what this chapter learns to read."

Closing `.note` (verbatim): "Start with `cons cells`, then `recursion over lists`, then `complexity on the BEAM`. Next module: **F4.02 — Trees & traversals**, where the tail becomes two branches and a walk becomes a traversal." (links: `/elixir/algorithms/lists/cons`, `/elixir/algorithms/lists/recursion`, `/elixir/algorithms/lists/big-o`).

## The interactives

**1. Hero figure — `Prepend is O(1)`** (`figure.hero-fig`, `aria-labelledby="hpTitle"`)

- Title (`#hpTitle`): `Prepend is O(1)`.
- SVG group id: `#hpChain`. Static markup draws `[12, 8, 30]` as a vertical chain of cons cells ending in `[]` (visible without JS).
- Controls (`.hp-ctrls`): button `#hpAdd` label `▸ prepend`; button `#hpReset` label `reset` (`.ghost`).
- Caption (`#hpCap`, `aria-live="polite"`). Initial readout strings, verbatim:
  - `[12, 8, 30]`
  - `Prepend adds one cell pointing at the old head — O(1).`
- JS state: `INITIAL = [12, 8, 30]`; `POOL = [7, 5, 21, 3]` (values prepended in order); `CAP = 5` (most cells the chain ever shows). `render()` re-emits the caption as `[<list>]` + the same `O(1)` ohint line. Prepend is disabled (button dimmed) once `list.length >= CAP`. The `cell`, `nilCell`, `el` helpers build SVG nodes; `reset` returns to `[12, 8, 30]`.
- Degrade: static SVG already shows `[12, 8, 30]` ending in `[]` (no render on load). The new front cell carries `.hp-new`; under `prefers-reduced-motion: no-preference` it animates via `@keyframes hpIn` (slide-in), and the animation is set to `none` under `prefers-reduced-motion: reduce`.

**2. Section figure — `The angle · select one`** (`figure.fig`, `aria-labelledby="lsTitle"`, in `#shape`)

- Title (`#lsTitle`): `The angle · select one`.
- Control group id: `#lsSel` (`role="group"`, `aria-label="The angle"`). Buttons (`data-k` / `data-c` / label):
  - `cons` / `sage` / "cons cells" (active by default)
  - `recursion` / `blue` / "recursion"
  - `complexity` / `gold` / "complexity"
- SVG element ids: cells `#lsCell0`/`#lsCell1`/`#lsCell2`, head text `#lsHead0`, arrows `#lsArr0`/`#lsArr0h`/`#lsArr1`/`#lsArr1h`/`#lsArr2`/`#lsArr2h`, nil box `#lsNil`, recursion overlay `#lsRecArr`/`#lsRecTxt` ("recurse on the tail"), complexity markers `#lsFront` ("prepend here · O(1)") and `#lsWalk` ("reach the end · O(n)").
- Live regions: code `#lsCode`, readout `#lsOut`, role line `#lsRole`.
- Pure function: `pick(k)` looks up `CASES[k]`, toggles the active button + `aria-pressed`, recolours the three cells (head0 highlight for the `recursion` case), sets the opacity overlays, and writes `code`/`out`/`role`. Defaults to `pick('cons')`. Readout (`#lsOut`) strings, verbatim:
  - `cons`: "A list is a chain of **cons cells**. Each cell holds a head and a pointer to the tail, so `[12, 8, 30]` is `12 | (8 | (30 | []))`, ending in the empty list." (role `[head | tail]`).
  - `recursion`: "Recursion splits a list into its **head and tail**: act on the head, call yourself on the tail, and stop at `[]`. Every list function in F4 is a variation on this clause." (role `[h | t] → recurse t`).
  - `complexity`: "The shape fixes the cost. **Prepending** a head is O(1) — one new cell points at the old list. **Reaching the end** — length, append, last — is O(n), because you must walk every cell." (role `prepend O(1) · walk O(n)`).
- Take (verbatim): "The list points one way, from head to tail. Operations that work at the head are cheap; operations that need the far end are not. Everything in this module follows from that asymmetry."

**Footer build-stamp decoder** (`.stamp` `#stamp`): id `#stampId` = `TSK0NbUlt1f2UC`. The inline `decodeBranded` splits the 3-char namespace + base62 snowflake, with `EPOCH_MS = 1704067200000`. Decoded: namespace `TSK`, snowflake `319539942931824640`, node `0`, seq `0`, timestamp `2026-05-31 18:17:39 UTC` (matching the static `#st-ts` panel value `2026-05-31 18:17:39 UTC`). Click/Enter/Space toggles the `.panel`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `List` — Elixir documentation — `https://hexdocs.pm/elixir/List.html` — cons-cell lists and the functions over them.
- Efficiency Guide — Erlang/OTP documentation — `https://www.erlang.org/doc/system/efficiency_guide.html` — operation complexity on the BEAM.
- Okasaki, C. (1996). *Purely Functional Data Structures.* — the foundational text on persistent structures. (no link)

Related in this course:
- `/elixir/algorithms` — F4 · Algorithms & data structures
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls
- `/elixir/algebra/recursion` — F1.06 · Recursion & induction

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / lists` — `lists` is the current segment (`.rcur`); `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`.
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) · `/` · here `F4.01 · lists`.
- toc-mini: `#shape` "A list is cons cells"; `#dives` "Three deep dives".
- pager: no prev (left is `F4 · overview` ghost button → `/elixir/algorithms`); next → `/elixir/algorithms/lists/cons` label "Start · cons cells".
- footer: `Chapters` column → `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). `The course` column → `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot-tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = "Lists, recursion & complexity — F4.01 · jonnify". `<meta description>` = "The BEAM list is a linked list of cons cells, not an array: prepend is O(1) and the tail is shared, every list function is written by recursion, and the cost of an operation is the number of cells it touches. Three dives on the shape, the recursion, and the big-O."

## Build instruction

To (re)build this hub, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the figure/hero/stamp module + the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on this sage `F4` accent — the model sibling is the chapter landing `/Users/jonny/dev/jonnify/elixir/algorithms/index.html` for the hub framing, or one of the in-module dives below for the figure/stamp scaffolding. Change only the `<title>`/`<meta description>`, the `route-tag` (`lists` current), and the `<main>` body (hero copy, the `#shape` angle figure, the three `#dives` cards, the chapter bridge, and the `#refs` block). No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…`/`PGE…` Snowflake ids), the event-sourced engine behind ONE Portal facade, and the Phoenix web app; the running example is the portal's lesson minutes — cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Specific model sibling to copy from: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/cons.html` (same accent, same stamp scaffold, in-module).
