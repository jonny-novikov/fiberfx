# F4.11.3 — Classic DP problems (dive)

- Route (served): `/elixir/algorithms/dynamic-programming/problems`
- File: `elixir/algorithms/dynamic-programming/problems.html`
- Place in the chapter: the third and last of the three dives under the `F4.11` hub (`/elixir/algorithms/dynamic-programming`), part 3 of 3. It teaches the textbook two-dimensional dynamic program — edit distance — on the Portal use case of typo-tolerant "did you mean" search, and closes `F4.11` before the chapter's lab `F4.12`.
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.11 · part 3 of 3 · typo-tolerant search`

Hero `h1` (verbatim): Classic DP `problems`

Hero lede (verbatim):

> When a learner mistypes a course name in the search box, the Portal still wants to find it. The measure is **edit distance**: the fewest single-character inserts, deletes, or substitutions that turn one string into another. It is the textbook two-dimensional dynamic program — a cell for every pair of prefixes, each built from the three cells above and to its left — and it powers the "did you mean" suggestion under the search bar.

Kicker (verbatim):

> A misspelled query against the catalog entry `elixir`. Pick a query and watch the table fill; the bottom-right cell is the distance.

## Sections

In order:

1. **`#grid` · Fill the grid** (teaching) — running example: a misspelled query down the rows against the target `elixir` across the columns; `dp[i][j]` is the distance between their first `i` and `j` characters, each cell the cheapest of a delete, an insert, or a substitute (free when the two characters match). Carries the interactive figure.
2. **`#advanced` · Advanced: cost, space, and scale** — edit distance has the two DP hallmarks (optimal substructure, overlapping subproblems); the work is `O(m × n)` for strings of length `m` and `n`, the full grid collapses to `O(min(m, n))` space when only the number is wanted, and at scale the Portal would index titles (a BK-tree or trigram index) and compute edit distance only against the near matches.

Real Elixir code shown (in `#advanced`) — edit distance computed row by row:

```elixir
def distance(a, b) do
  a = String.graphemes(a)
  b = String.graphemes(b)
  row0 = Enum.to_list(0..length(b))

  Enum.reduce(Enum.with_index(a, 1), row0, fn {ca, i}, prev ->
    Enum.scan(Enum.with_index(b, 1), i, fn {cb, j}, left ->
      cost = if ca == cb, do: 0, else: 1
      min(min(left + 1, Enum.at(prev, j) + 1), Enum.at(prev, j - 1) + cost)
    end)
  end)
  |> List.last()
end
```

The `.bridge` reads `two strings (a misspelled query and a catalog title) → an alignment cost (one grid, filled once; the corner cell is the fewest edits between them)`.

## The interactives

### `#grid` figure — `aria-labelledby="pbTitle"`
- Figcaption `h4` (`#pbTitle`): `Typed query · select one · target "elixir"`.
- Control group `#pbSel` (`role="group"`, `aria-label="Typed query"`). Buttons: `data-q="elixr" data-c="sage"` (label `elixr`, default `.active`), `data-q="exilir" data-c="blue"` (label `exilir`), `data-q="exlir" data-c="gold"` (label `exlir`).
- SVG element ids: `#pbGrid` (the edit-distance table built in JS), `#pbQ` (the query echo), `#pbDistLabel` (the distance), `#pbSuggestLabel` (the suggestion line). Below the figure: `#pbCode` (`pre.code`, `aria-live="polite"`), `#pbOut` (`.geo-readout`), `#pbRole` (query), `#pbResult` (edit distance).
- Pure function: `grid(s, t)` builds the full Levenshtein grid between the query `s` (rows) and the target `t` = `elixir` (cols). The target is fixed `TARGET = 'elixir'`; `THRESHOLD = 2` gates the suggestion; the per-query bar colours are `FILL = { elixr: SAGE, exilir: BLUE, exlir: GOLD }`.
- Readout strings (verbatim). Static SVG default (query `elixr`): `query:  elixr`, `target: elixir`, `edit distance: 1`, suggestion `did you mean "elixir"?`. Below the figure the static labels read `query: elixr` and `edit distance: 1`.
- `#grid` takeaway (verbatim): `The whole table is solved cell by cell from the empty-prefix edges inward, and the single bottom-right number is the answer. Below a threshold of two edits, the Portal offers the match as a suggestion.`

### Degrade behaviour
The grid, code, and prose are written by JS; the SVG ships with the static `elixr` query echo, `edit distance: 1`, and the suggestion line in markup so the default state reads without JS. `prefers-reduced-motion: reduce` disables smooth scrolling, the `.arc-flow` animation, and `.reveal` transitions; `.reveal` sections show immediately without JS / `IntersectionObserver`.

### Footer build-stamp decoder
Stamp id `TSK0Ncfoer3W1A`. Decoded by the inline base-62 / Snowflake decoder: namespace `TSK`, snowflake `319797178216218624`, node `0`, seq `0`, timestamp `2026-06-01 11:19:48 UTC` (the value shown in the `#st-ts` panel).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Levenshtein distance — Wikipedia](https://en.wikipedia.org/wiki/Levenshtein_distance) — the edit-distance recurrence and its grid.
- [Edit distance — Wikipedia](https://en.wikipedia.org/wiki/Edit_distance) — variants and the row-by-row space saving.
- [BK-tree — Wikipedia](https://en.wikipedia.org/wiki/BK-tree) — indexing for fuzzy search at scale.

Related in this course:
- `/elixir/algorithms/dynamic-programming` — F4.11 · Dynamic programming & advanced problems — the module hub.
- `/elixir/algorithms/recipes` — F4.10 · Practical recipes in Elixir — the reduce/scan idioms the solution uses.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `algorithms` `/` `dynamic-programming` `/` `problems` (current segment `problems` in `.rcur`; `elixir`, `algorithms`, `dynamic-programming` are links).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.11` (→ `/elixir/algorithms/dynamic-programming`) `/` `problems` (`.here`).
- toc-mini: `#grid` → `Fill the grid`; `#advanced` → `Advanced: cost, space, and scale`.
- pager: prev → `/elixir/algorithms/dynamic-programming/tabulation` label `F4.11.2 · tabulation`; next → `/elixir/algorithms` label `F4 · Algorithms & Data Structures`.
- footer columns. **Chapters:** `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. **The course:** `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta. `<title>`: `Classic DP problems — F4.11.3 · jonnify`. `<meta name="description">`: `Edit distance — the fewest single-character inserts, deletes, or substitutions between two strings — is the textbook two-dimensional DP: a cell per pair of prefixes, each built from the three above and to its left. Against the catalog title elixir, elixr is one edit, exilir two, exlir three; below a two-edit threshold the Portal offers a 'did you mean' suggestion. The grid is O(m x n) and collapses to one row when only the number is wanted.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks (the figure-and-stamp IIFE plus the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling dive on the sage F4 accent — the closest model is the sibling dive `tabulation.html` in this same module directory (same hero-without-art lesson layout, the same one-teaching-plus-one-advanced section shape, the same `.solid-select` figure shell). Change only the `<title>`/`<meta name="description">`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (the `#grid` figure, the `#advanced` section with its `pre.code` and `.bridge`, and the References block). No-invent guards: cite only the real Portal surfaces as written — the branded `Store`, the event-sourced engine behind the single `Portal` facade, and the Phoenix web app (the search/suggestion is framed as a Portal feature, not a new API); cite the companion course for any OTP internals rather than re-teaching them, and do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of `just`/`simply`/`obviously`. Model sibling to copy from: `elixir/algorithms/dynamic-programming/tabulation.html`.
