# F4.02.2 — Depth-first: pre, in, post-order (dive)

- Route (served): `/elixir/algorithms/trees/dfs`
- File: `elixir/algorithms/trees/dfs.html`
- Place in the chapter: the second of the three `F4.02` dives. It follows `shape` (the recursive data definition and folds) and precedes `bfs` (level order & balance), teaching the three depth-first orders as one recursion that differs only in when it visits the node.
- Accent: sage (F4 chapter accent; the `pre-order` control and node strokes default to `--sage` / `--sage-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.02 · part 2 of 3`

H1 (verbatim): Depth-first: pre, in, post-order

Hero lede (verbatim):

> Depth-first traversal commits to one branch and follows it to the bottom before backing up. All three depth-first orders make the same two recursive calls — left subtree, right subtree — and differ only in *when* they visit the node: before the calls (pre-order), between them (in-order), or after them (post-order). On a binary search tree, in-order comes out sorted, for free.

Kicker (verbatim):

> The badge on each node is its visit number for the selected order. Watch the root move from first, to fourth, to last as you switch pre → in → post.

## Sections

In order:

1. `#orders` — "When you visit the node" (teaching). Pre-order records the node then recurses left then right; in-order recurses left, records, then recurses right; post-order recurses both subtrees first and records the node last. Carries the interactive order selector (each node badged with its visit number). Takeaway: same shape, same two recursive calls, three results — pre-order copies or serialises a tree, in-order reads a BST sorted, post-order frees or evaluates children before their parent.
2. `#fold` — "Advanced: traversal as a fold" (advanced). All three orders are special cases of one higher-order tree fold that threads an accumulator; placing the `fun` call before / between / after the recursive calls gives pre / in / post. Folding a BST in-order with `[v | acc]` and reversing yields a sorted list with no separate sort. For unbounded depth, swap the implicit call stack for an explicit one.

Running example: the seven-node binary search tree (root 12; 8 and 30; leaves 5, 10, 20, 42).

Real Elixir code shown (`#orders`, selectable per order):
- `pre` — `def preorder({v, l, r}), do: [v] ++ preorder(l) ++ preorder(r)` / `def preorder(nil), do: []` (`# 12, 8, 5, 10, 30, 20, 42`)
- `in` — `def inorder({v, l, r}), do: inorder(l) ++ [v] ++ inorder(r)` / `def inorder(nil), do: []` (`# 5, 8, 10, 12, 20, 30, 42 — sorted, because BST`)
- `post` — `def postorder({v, l, r}), do: postorder(l) ++ postorder(r) ++ [v]` / `def postorder(nil), do: []` (`# 5, 10, 8, 20, 42, 30, 12 — children before parents`)

Real Elixir code shown (`#fold`, static fold):
```
# one fold, parameterised by where the node is visited
def reduce(nil, acc, _f), do: acc
def reduce({v, l, r}, acc, f) do
  acc = reduce(l, acc, f)     # left subtree first…
  acc = f.(v, acc)            # …visit here ⇒ in-order
  reduce(r, acc, f)            # …then the right subtree
end

# in-order of a BST is sorted, so this needs no Enum.sort:
tree |> reduce([], fn v, acc -> [v | acc] end) |> Enum.reverse()
# => [5, 8, 10, 12, 20, 30, 42]
```

## The interactives

Figure 1 — order selector, `aria-labelledby="dfTitle"`, heading `The order · select one`.
- Control group `#dfSel` (role group), three buttons: `data-k="pre"` `data-c="sage"` label `pre-order` (active default); `data-k="in"` `data-c="blue"` label `in-order`; `data-k="post"` `data-c="gold"` label `post-order`.
- SVG: seven node circles (values 12, 8, 30, 5, 10, 20, 42), each with a small badge text id `#dfOrd0`..`#dfOrd6` holding the visit number; order-name text `#dfName`; code `#dfCode`; readout `#dfOut`; clause text `#dfClause`; sequence text `#dfSeq`.
- Pure function: `pick(k)` reads `CASES[k]`, toggles the active button + `aria-pressed`, writes the seven badge numbers from `c.ord`, and writes name / clause / seq / code / out.
- Badge orders (verbatim, indices match the static node order 12,8,30,5,10,20,42): pre — `['1','2','5','3','4','6','7']`; in — `['4','2','6','1','3','5','7']`; post — `['7','3','6','1','2','4','5']`.
- Name strings (verbatim): pre — `pre-order · node, then left, then right`; in — `in-order · left, then node, then right`; post — `post-order · left, then right, then node`.
- Clause strings (verbatim): pre — `visit(v); pre(l); pre(r)`; in — `in(l); visit(v); in(r)`; post — `post(l); post(r); visit(v)`.
- Sequence strings (verbatim): pre — `12 · 8 · 5 · 10 · 30 · 20 · 42`; in — `5 · 8 · 10 · 12 · 20 · 30 · 42  (sorted)`; post — `5 · 10 · 8 · 20 · 42 · 30 · 12`.
- Readout strings (verbatim): pre — `Pre-order records the node before either subtree, so the root comes first. It mirrors the structure top-down — the order to copy or serialise a tree.`; in — `In-order visits the node between its subtrees. On a binary search tree the left subtree is all smaller and the right all larger, so the sequence comes out sorted.`; post — `Post-order records the node only after both subtrees, so every child is handled before its parent. It is the order to free, evaluate, or aggregate bottom-up.`
- Static markup default (visible without JS): badges `1,2,5,3,4,6,7`; name `pre-order · node, then left, then right`; clause `visit(v); pre(l); pre(r)`; sequence `12 · 8 · 5 · 10 · 30 · 20 · 42`.
- Degrade: no animation in this figure; the static SVG already shows the full sage-stroked tree with pre-order badges, and `pick('pre')` runs on load to populate code/readout.

Footer build-stamp decoder: `#stamp` decodes a branded Snowflake via base-62 (`0123456789…xyz`) with `EPOCH_MS = 1704067200000`. The stamp id is `TSK0NbXXa8XPn6` — namespace `TSK`, snowflake `319549695267438592`, node `0`, seq `0`, decoded `2026-05-31 18:56:24 UTC` (panel static `st-ts` reads `2026-05-31 18:56:24 UTC`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Tree traversal — Wikipedia` → `https://en.wikipedia.org/wiki/Tree_traversal` — depth-first and breadth-first orders.
- Okasaki, C. (1996). *Purely Functional Data Structures.* — trees, functionally. (no URL)

Related in this course:
- `/elixir/algorithms/trees` — F4.02 · Trees & traversals
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `trees` `/` `dfs` (the `dfs` segment is `.rcur`; `trees` links to `/elixir/algorithms/trees`).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.02` (→ `/elixir/algorithms/trees`) `/` `dfs` (here).
- toc-mini: `#orders` "When you visit the node"; `#fold` "Advanced: traversal as a fold".
- pager: prev → `/elixir/algorithms/trees/shape` label `← F4.02.1 · shape`; next → `/elixir/algorithms/trees/bfs` label `Next · breadth-first →`.
- footer columns (verbatim): brand column — `jonnify` + tagline `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.` · Chapters — `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`) · The course — `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta: `<title>` = `Depth-first: pre, in, post-order — F4.02.2 · jonnify`; `<meta description>` = `Depth-first traversal makes the same two recursive calls and differs only in when it visits the node: before the calls (pre), between them (in), or after them (post). In-order on a binary search tree comes out sorted, and all three are one parameterised fold.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the sage F4 accent — the model sibling is the previous dive in this module, `elixir/algorithms/trees/shape.html` (identical dive shell: crumbs, eyebrow `part N of 3`, one teaching section + one advanced section, References, pager). Change only `<title>` / `<meta description>`, the `route-tag`, the crumbs `.here`, and the `<main>` body (hero, `#orders` figure, `#fold` advanced section + `reduce/3`, References, pager). Use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of *just* / *simply* / *obviously*. Wrap every route, file path, id, and code token in backticks.
