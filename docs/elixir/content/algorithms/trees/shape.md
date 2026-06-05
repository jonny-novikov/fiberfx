# F4.02.1 — Binary trees & recursive shape (dive)

- Route (served): `/elixir/algorithms/trees/shape`
- File: `elixir/algorithms/trees/shape.html`
- Place in the chapter: the first of the three `F4.02` dives. It opens the trees module by establishing the recursive data definition (`{value, left, right}` or `nil`) and the fold-shaped functions over it, before `dfs` (traversal orders) and `bfs` (level order & balance).
- Accent: sage (F4 chapter accent; the `size` function and node strokes default to `--sage` / `--sage-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.02 · part 1 of 3`

H1 (verbatim): Binary trees & recursive shape

Hero lede (verbatim):

> A binary tree is defined by recursion: a node is `{value, left, right}`, and a subtree is either another node or `nil`. Every function over a tree follows that definition — handle `nil` as the base case, and handle a node by combining the results from its two subtrees. Size, height, and sum are the same recursion with a different combine step.

Kicker (verbatim):

> Because the data branches, the recursion branches too: two recursive calls per node instead of the one a list needed. Select a function to see its clauses and result over the seven-node tree.

## Sections

In order:

1. `#fold` — "Functions that fold a tree" (teaching). Each function has a clause for `nil` and a clause for a node; the node clause makes two recursive calls (one per subtree) and combines them. Carries the interactive function selector. Takeaway: there are always exactly two clauses to get right — what an empty tree is worth, and how to fold a node from its two subtrees.
2. `#sharing` — "Advanced: structural sharing on insert" (advanced). Insert returns a new tree without copying the old one: it rebuilds only the nodes on the root-to-leaf path and shares untouched subtrees by reference. Inserting `15` walks `12 → 30 → 20` and hangs it on 20's empty left — three nodes rebuilt, the whole left half shared. Carries a static figure and the `insert/2` code.

Running example: the seven-node binary search tree (root 12; 8 and 30; leaves 5, 10, 20, 42).

Real Elixir code shown (`#fold`, selectable per function):
- `size` — `def size({_v, l, r}), do: 1 + size(l) + size(r)` / `def size(nil), do: 0` (`# 7 nodes`)
- `height` — `def height({_v, l, r}), do: 1 + max(height(l), height(r))` / `def height(nil), do: 0` (`# 3 levels — this is what makes search O(log n)`)
- `sum` — `def sum({v, l, r}), do: v + sum(l) + sum(r)` / `def sum(nil), do: 0` (`# 12+8+30+5+10+20+42 = 127`)

Real Elixir code shown (`#sharing`, static `insert/2`):
```
def insert(nil, x), do: {x, nil, nil}
def insert({v, l, r}, x) when x < v, do: {v, insert(l, x), r}
def insert({v, l, r}, x) when x > v, do: {v, l, insert(r, x)}
def insert({v, l, r}, _x), do: {v, l, r}   # already present
```

## The interactives

Figure 1 — function selector, `aria-labelledby="shTitle"`, heading `The function · select one`.
- Control group `#shSel` (role group), three buttons: `data-k="size"` `data-c="sage"` label `size` (active default); `data-k="height"` `data-c="blue"` label `height`; `data-k="sum"` `data-c="gold"` label `sum`.
- SVG node circle ids `#shN0`..`#shN6` (values 12, 8, 30, 5, 10, 20, 42); caption text `#shCaption`; code `#shCode`; readout `#shOut`; clause text `#shClause`; result text `#shResult`; base text `#shBase`.
- Pure function: `pick(k)` reads `CASES[k]`, toggles the active button + `aria-pressed`, re-strokes the seven node circles from `c.n`, and writes caption / clause / base / result / code / out.
- Captions (verbatim): size — `every node counts once`; height — `height is the longest root-to-leaf path: 3 levels`; sum — `add every node value`.
- Clauses (verbatim): size — `size({v, l, r}) = 1 + size(l) + size(r)`; height — `height({v, l, r}) = 1 + max(height(l), height(r))`; sum — `sum({v, l, r}) = v + sum(l) + sum(r)`.
- Base strings (verbatim): size — `base: size(nil) = 0`; height — `base: height(nil) = 0`; sum — `base: sum(nil) = 0`.
- Results (verbatim): size — `7`; height — `3`; sum — `127`.
- Readout strings (verbatim): size — `size/1 adds one for the node plus the sizes of both subtrees, bottoming out at 0 for nil. Seven nodes total.`; height — `height/1 takes the taller of the two subtrees and adds one for the node. This tree is 3 levels deep — the number that decides whether search is fast.`; sum — `sum/1 swaps the combine step from counting to adding values: the node value plus both subtree sums. Over this tree, 127.`
- Static markup default (visible without JS): clause `size({v, l, r}) = 1 + size(l) + size(r)`, result `7`, base `base: size(nil) = 0`, caption `every node counts once`.
- Degrade: no animation in this figure; the static SVG already shows the full sage-stroked tree, and `pick('size')` runs on load to populate the code/readout.

Figure 2 — static advanced figure, `aria-labelledby="shAdvTitle"`, heading `insert(tree, 15) · rebuilt path vs shared subtrees`. Not interactive: a fixed SVG colouring the rebuilt path (`12`, `30`, `20` in gold), shared nodes (8, 5, 10, 42 in muted blue), and the new leaf `15` (sage), with a legend `rebuilt` / `shared` / `new`. Static readout (verbatim): `Three nodes rebuilt on the path, one new leaf, four subtrees shared by reference. For a balanced tree that is O(log n) new nodes per insert — the foundation of persistent data structures, and exactly how the tries later in this chapter stay cheap to update.`

Footer build-stamp decoder: `#stamp` decodes a branded Snowflake via base-62 (`0123456789…xyz`) with `EPOCH_MS = 1704067200000`. The stamp id is `TSK0NbXXZg9Wme` — namespace `TSK`, snowflake `319549694848008192`, node `0`, seq `0`, decoded `2026-05-31 18:56:24 UTC` (panel static `st-ts` reads `2026-05-31 18:56:24 UTC`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Tree traversal — Wikipedia` → `https://en.wikipedia.org/wiki/Tree_traversal` — depth-first and breadth-first orders.
- Okasaki, C. (1996). *Purely Functional Data Structures.* — trees, functionally. (no URL)

Related in this course:
- `/elixir/algorithms/trees` — F4.02 · Trees & traversals
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/algebra/recursion` — F1.06 · Recursion & induction

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `trees` `/` `shape` (the `shape` segment is `.rcur`; `trees` is a link to `/elixir/algorithms/trees`).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.02` (→ `/elixir/algorithms/trees`) `/` `shape` (here).
- toc-mini: `#fold` "Functions that fold a tree"; `#sharing` "Advanced: structural sharing".
- pager: prev → `/elixir/algorithms/trees` label `← F4.02 · trees`; next → `/elixir/algorithms/trees/dfs` label `Next · depth-first →`.
- footer columns (verbatim): brand column — `jonnify` + tagline `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.` · Chapters — `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`) · The course — `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta: `<title>` = `Binary trees & recursive shape — F4.02.1 · jonnify`; `<meta description>` = `A node is {value, left, right} or nil, so every tree function handles nil as the base case and a node by combining its two subtrees. size, height, and sum are one recursion with a different combine — and insert rebuilds only the path it changes, sharing the rest.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the sage F4 accent — the model sibling is the next dive in this module, `elixir/algorithms/trees/dfs.html` (identical dive shell: crumbs, eyebrow `part N of 3`, one teaching section + one advanced section, References, pager). Change only `<title>` / `<meta description>`, the `route-tag`, the crumbs `.here`, and the `<main>` body (hero, `#fold` figure, `#sharing` advanced figure + `insert/2`, References, pager). Use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of *just* / *simply* / *obviously*. Wrap every route, file path, id, and code token in backticks.
