# F4.02 — Trees & traversals (module hub)

- Route (served): `/elixir/algorithms/trees`
- File: `elixir/algorithms/trees/index.html`
- Place in the chapter: the second module of F4 · Algorithms & Data Structures, sitting between `F4.01` (lists, recursion & complexity) and `F4.03` (sorting & searching). It frames three dives — the recursive shape, depth-first orders, and breadth-first level order with balance — over one running seven-node binary search tree, and points forward to the trie family (`F4.05` onward) that this chapter's persistent-map spine builds on.
- Accent: sage (the F4 chapter accent; nodes and "shape" controls render in `--sage` / `--sage-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · Foundations · module 2`

H1 (verbatim): Trees & *traversals* (the word "traversals" carries the `.ex` elixir-italic span)

Hero lede (verbatim):

> Give a list two tails instead of one and it becomes a tree. The cons cell's single pointer splits into a left and a right, and the linear walk of F4.01 becomes a traversal — depth-first or breadth-first. When the tree stays balanced, the O(n) walk of a list collapses to an O(log n) descent, which is the whole reason trees exist and the road into the trie family later in this chapter.

Kicker (verbatim):

> The running example is a seven-node binary search tree. Three angles open the module: its recursive shape, the three depth-first orders, and the breadth-first level order — then an advanced look at balance and the descent to tries.

## What the page frames

This module hub uses inline-styled dive cards (not the `.mods` grid). The three deep dives, in pedagogical order:

- `F4.02.1` — **Binary trees & recursive shape** — A node is `{value, left, right}` or `nil`. Size, height, and sum by recursion — plus structural sharing on insert. Route: `/elixir/algorithms/trees/shape`. Built (sage left-border card).
- `F4.02.2` — **Depth-first: pre, in, post-order** — When you visit the node relative to its subtrees gives three orders — and in-order on a BST comes out sorted. Route: `/elixir/algorithms/trees/dfs`. Built (blue left-border card).
- `F4.02.3` — **Breadth-first & balance** — Level order with a queue, why balance keeps height at log n, and how a degenerate tree decays into a list. Route: `/elixir/algorithms/trees/bfs`. Built (gold left-border card).

The hub also carries two teaching sections of its own:

- `#tree` — "A tree is a branching list": a binary tree is a node (value + left + right subtree) or `nil`; that is the cons cell with a second pointer.
- `#advanced` — "Advanced: balance & the road to tries": a balanced BST of `n` nodes has height about `log₂ n` so search/insert/delete are O(log n); inserting `1, 2, 3, 4` in order degenerates into a right-leaning chain (back to O(n)); self-balancing trees (AVL, red-black) restore height by rotation; a `HAMT` (`F4.05`) branches up to thirty-two ways on hash bits, height about `log₃₂ n`, which is how Elixir's `Map` gets fast persistent lookup.

## The interactives

There are two interactive figures.

Figure 1 — hero concept figure, `aria-labelledby="hpTitle"`, caption `In-order traversal`. Steps a traversal over the seven-node tree.
- Static default in markup: full tree drawn with the root (`12`) highlighted as the traversal start, visible without JS (no render on load).
- Controls (no `data-key` group; three buttons by id): `#hpStep` label `▸ step`; `#hpOrder` label `order: in`; `#hpReset` label `reset`.
- Node group id `#hpNodes`; each node `<g class="hp-node">` carries `data-i` (in-order index 0–6) and `data-v` (value). Values keyed by in-order index: `VAL = [5, 8, 10, 12, 20, 30, 42]`. Edges in `#hpEdges`; caption text node `#hpTreeCap`; live readout `#hpCap`.
- Three orders cycle on `#hpOrder` (`KEYS = ['in', 'pre', 'post']`), each an array of in-order indices: `in` seq `[0,1,2,3,4,5,6]`; `pre` seq `[3,1,0,2,5,4,6]`; `post` seq `[0,2,1,4,6,5,3]`.
- Per-order tree caption strings (verbatim): in — `left subtree · node · right subtree`; pre — `node · left subtree · right subtree`; post — `left subtree · right subtree · node`.
- Per-order hint strings (verbatim): in — `Visit the left subtree, the node, then the right — on a BST this comes out sorted.`; pre — `Visit the node first, then its left subtree, then its right — the order to copy a tree.`; post — `Visit both subtrees before the node — the order to free or fold a tree from the leaves up.`
- Completion readout template (verbatim): `Traversal complete — <n> nodes in <label>.`
- Static readout default (verbatim): `in-order: ·` then `Visit the left subtree, the node, then the right — on a BST this comes out sorted.`
- Degrade: `prefers-reduced-motion: no-preference` animates the `.hp-node.current circle` pulse (`@keyframes hpPulse`); under `prefers-reduced-motion: reduce` the animation is `none`. No render runs on load — the static SVG already shows the full tree with the root highlighted.

Figure 2 — angle selector, `aria-labelledby="trTitle"`, heading `The angle · select one`. Re-colours the same tree under three angles.
- Control group `#trSel` (role group), three buttons: `data-k="shape"` `data-c="sage"` label `shape` (active default); `data-k="depth"` `data-c="blue"` label `depth-first`; `data-k="breadth"` `data-c="gold"` label `breadth-first`.
- SVG node circle ids `#trN0`..`#trN6` (values 12, 8, 30, 5, 10, 20, 42); caption text `#trCaption`; code block `#trCode`; readout `#trOut`; role text `#trRole`; sequence text `#trSeq`.
- Pure function: `pick(k)` reads the `CASES[k]` record, toggles the active button + `aria-pressed`, re-strokes the seven node circles from `c.n`, and writes caption / role / seq / code / out.
- Captions (verbatim): shape — `left subtree < root < right subtree`; depth — `go all the way down one branch before backing up`; breadth — `visit every node on a level before the next level`.
- Role strings (verbatim): shape — `{value, left, right}`; depth — `go deep, then across`; breadth — `level by level`.
- Sequence strings (verbatim): shape — `7 nodes · height 3 · a root over two subtrees`; depth — `in-order: 5 · 8 · 10 · 12 · 20 · 30 · 42`; breadth — `level-order: 12 · 8 · 30 · 5 · 10 · 20 · 42`.
- Static markup default (visible without JS): role text `{value, left, right}`, seq text `7 nodes · height 3 · a root over two subtrees`, caption `left subtree < root < right subtree`.

Footer build-stamp decoder: `#stamp` is a clickable/keyboard-activatable build chip decoding a branded Snowflake via base-62 over the alphabet `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz` with `EPOCH_MS = 1704067200000`. The stamp id is `TSK0NbXXZEcRAO` — namespace `TSK`, snowflake `319549694441160704`, node `0`, seq `0`, decoded `2026-05-31 18:56:24 UTC` (the panel's static `st-ts` reads `2026-05-31 18:56:24 UTC`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Tree traversal — Wikipedia` → `https://en.wikipedia.org/wiki/Tree_traversal` — depth-first and breadth-first orders.
- Okasaki, C. (1996). *Purely Functional Data Structures* (thesis) — trees, functionally. (no URL)

Related in this course:
- `/elixir/algorithms` — F4 · Algorithms & Data Structures
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `trees` (the `trees` segment is the current `.rcur`, not a link).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) `/` `F4.02 · trees` (here).
- toc-mini: `#tree` "A tree is a branching list"; `#dives` "Three deep dives"; `#advanced` "Advanced: balance & tries".
- pager: prev → `/elixir/algorithms/lists` label `← F4.01 · lists`; next → `/elixir/algorithms/trees/shape` label `Start · recursive shape →`.
- footer columns (verbatim): brand column — logo `jonnify`, tagline `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.` · Chapters column — `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`) · The course column — `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta: `<title>` = `Trees & traversals — F4.02 · jonnify`; `<meta description>` = `A binary tree is a cons cell with two pointers: a node is {value, left, right} or nil. The linear list walk becomes a traversal, and a balanced tree turns an O(n) walk into an O(log n) descent — the idea the trie family builds on. Three dives plus an advanced look at balance and tries.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure controllers + the Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the sage F4 accent — the model sibling is the F4.01 lists module hub at `elixir/algorithms/lists/index.html`. Change only `<title>` / `<meta description>`, the `route-tag`, and the `<main>` body (hero, the `#tree` angle figure, the `#dives` dive cards, the `#advanced` section, References, pager). Use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of *just* / *simply* / *obviously*. Wrap every route, file path, id, and code token in backticks.
