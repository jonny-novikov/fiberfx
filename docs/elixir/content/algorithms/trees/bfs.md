# F4.02.3 — Breadth-first & balance (dive)

- Route (served): `/elixir/algorithms/trees/bfs`
- File: `elixir/algorithms/trees/bfs.html`
- Place in the chapter: the last of the three `F4.02` dives. It follows `dfs` (depth-first orders), closing the trees module by walking the tree level by level with a FIFO queue and tying the level count to search cost — the bridge to the trie family (`F4.05` onward) and forward to `F4.03` sorting & searching.
- Accent: sage (F4 chapter accent; all three level buttons and node strokes use `--sage` / `--sage-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.02 · part 3 of 3`

H1 (verbatim): Breadth-first & balance

Hero lede (verbatim):

> Breadth-first traversal takes the tree a level at a time: the root, then both its children, then all four grandchildren. Where depth-first leans on the call stack, breadth-first leans on a FIFO queue — take a node from the front, record it, add its children to the back. The same level structure is what makes a balanced tree fast: `n` nodes fit in about `log₂ n` levels, so a search descends only that far.

Kicker (verbatim):

> Step through the levels and watch the queue fill and drain. Then see what happens to the cost when the tree is balanced — and when it is not.

## Sections

In order:

1. `#levels` — "Level by level, with a queue" (teaching). The queue holds nodes waiting to be visited; start with the root, and each time you take one from the front, record its value and push its children to the back. Carries the interactive level selector showing the visited sequence and the queue after each level. Takeaway: a queue turns recursion inside out — you keep a running line of what to visit next, oldest first.
2. `#balance` — "Advanced: balance & O(log n)" (advanced). The number of levels is the cost of a search: a balanced tree of `n` nodes has about `log₂ n` levels (seven in three, a thousand in ten), but inserting `1, 2, 3, 4` in order produces a chain as tall as the list. Self-balancing trees (AVL, red-black) rotate subtrees to hold height near `log n`; the trie family takes the idea further with a wide branching factor — the subject of `F4.05` onward. Carries a static "balanced vs degenerate" figure and the `level_order/walk` code.

Running example: the seven-node binary search tree (root 12; 8 and 30; leaves 5, 10, 20, 42).

Real Elixir code shown (`#levels`, selectable per level):
- `l1` — `walk([12], [])` (`# start: queue holds the root` / `# take 12, emit it, enqueue 8 and 30`)
- `l2` — `# take 8 -> enqueue 5, 10 ; take 30 -> enqueue 20, 42` / `# emitted so far: 12, 8, 30`
- `l3` — `# take 5, 10, 20, 42 — each has nil children, nothing enqueued` / `# queue empties; level order complete`

Real Elixir code shown (`#balance`, static `level_order`):
```
def level_order(root), do: walk([root], [])
defp walk([], acc), do: Enum.reverse(acc)
defp walk([nil | rest], acc), do: walk(rest, acc)
defp walk([{v, l, r} | rest], acc), do: walk(rest ++ [l, r], [v | acc])
# 12, 8, 30, 5, 10, 20, 42  (use :queue for O(1) enqueue in real code)
```

## The interactives

Figure 1 — level selector, `aria-labelledby="bfTitle"`, heading `The level · select one`.
- Control group `#bfSel` (role group), three buttons, all `data-c="sage"`: `data-k="l1"` label `level 1` (active default); `data-k="l2"` label `level 2`; `data-k="l3"` label `level 3`.
- SVG node circle ids `#bfN0`..`#bfN6` (values 12, 8, 30, 5, 10, 20, 42); caption text `#bfCaption`; code `#bfCode`; readout `#bfOut`; visited-sequence text `#bfSeq`; queue text `#bfQueue`.
- Pure function: `pick(k)` reads `CASES[k]`, toggles the active button + `aria-pressed`, re-strokes each node circle lit (`SAGE`, width `2.5`) or dim (`DIM #4a5474`, width `2`) from `c.lit`, and writes caption / seq / queue / code / out.
- Lit masks (verbatim): l1 — `[1,0,0,0,0,0,0]`; l2 — `[1,1,1,0,0,0,0]`; l3 — `[1,1,1,1,1,1,1]`.
- Captions (verbatim): l1 — `level 1: the root`; l2 — `level 2: the root's children`; l3 — `level 3: the four leaves`.
- Visited strings (verbatim): l1 — `12`; l2 — `12 · 8 · 30`; l3 — `12 · 8 · 30 · 5 · 10 · 20 · 42`.
- Queue strings (verbatim): l1 — `[8, 30]`; l2 — `[5, 10, 20, 42]`; l3 — `(empty)`.
- Readout strings (verbatim): l1 — `Level 1 is the root. It is taken from the queue, recorded, and its two children are pushed to the back — the queue now holds 8 and 30.`; l2 — `Level 2 drains 8 then 30 from the front, each pushing its own two children. The queue holds all four grandchildren, oldest first.`; l3 — `Level 3 empties the queue: each leaf is recorded and adds nothing. The full level order is 12, 8, 30, 5, 10, 20, 42.`
- Static markup default (visible without JS): caption `level 1: the root`; visited `12`; queue `[8, 30]`.
- Degrade: no animation in this figure; the static SVG already shows the tree with only the root lit, and `pick('l1')` runs on load to populate code/readout.

Figure 2 — static advanced figure, `aria-labelledby="bfAdvTitle"`, heading `Same keys, two shapes · balanced vs degenerate`. Not interactive: a fixed SVG with a balanced seven-node tree (label `balanced` / `7 nodes · 3 levels · O(log n)`, sage) beside a degenerate right-leaning chain of nodes 1→2→3→4 (label `degenerate` / `4 nodes · 4 levels · O(n)`, burgundy `#e08f8b`). Static readout (verbatim): `Insert 1, 2, 3, 4 in sorted order and the right-hand shape is what you get — a linked list wearing a tree's clothes. Keeping the left shape is the entire job of a self-balancing tree.`

Footer build-stamp decoder: `#stamp` decodes a branded Snowflake via base-62 (`0123456789…xyz`) with `EPOCH_MS = 1704067200000`. The stamp id is `TSK0NbXXaZVJ9E` — namespace `TSK`, snowflake `319549695665897472`, node `0`, seq `0`, decoded `2026-05-31 18:56:24 UTC` (panel static `st-ts` reads `2026-05-31 18:56:24 UTC`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Tree traversal — Wikipedia` → `https://en.wikipedia.org/wiki/Tree_traversal` — depth-first and breadth-first orders.
- Okasaki, C. (1996). *Purely Functional Data Structures* (thesis) — trees, functionally. (no URL)

Related in this course:
- `/elixir/algorithms/trees` — F4.02 · Trees & traversals
- `/elixir/algorithms/trees/dfs` — Depth-first traversal
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `trees` `/` `bfs` (the `bfs` segment is `.rcur`; `trees` links to `/elixir/algorithms/trees`).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.02` (→ `/elixir/algorithms/trees`) `/` `bfs` (here).
- toc-mini: `#levels` "Level by level, with a queue"; `#balance` "Advanced: balance & O(log n)".
- pager: prev → `/elixir/algorithms/trees/dfs` label `← F4.02.2 · dfs`; next → `/elixir/algorithms` label `Back to F4 · overview →`.
- footer columns (verbatim): brand column — `jonnify` + tagline `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.` · Chapters — `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`) · The course — `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta: `<title>` = `Breadth-first & balance — F4.02.3 · jonnify`; `<meta description>` = `Breadth-first traversal walks the tree level by level with a FIFO queue. The level count is the search cost: a balanced tree of n nodes has about log2 n levels, while sorted insertion degenerates into an O(n) chain — which is why self-balancing trees and, later, tries exist.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the sage F4 accent — the model sibling is the previous dive in this module, `elixir/algorithms/trees/dfs.html` (identical dive shell: crumbs, eyebrow `part N of 3`, one teaching section + one advanced section, References, pager). Change only `<title>` / `<meta description>`, the `route-tag`, the crumbs `.here`, and the `<main>` body (hero, `#levels` figure, `#balance` advanced figure + `level_order/walk`, References, pager). Use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of *just* / *simply* / *obviously*. Wrap every route, file path, id, and code token in backticks.
