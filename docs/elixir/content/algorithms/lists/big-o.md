# F4.01.3 — Complexity & big-O on the BEAM (dive)

- Route (served): `/elixir/algorithms/lists/big-o`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/big-o.html`
- Place in the chapter: the third and last dive under the `F4.01 · lists` hub (part 3 of 3). It converts the cons-cell shape and the recursive walk into a concrete cost model — count the cells an operation touches — and ships the list-operation cost cheat-sheet that motivates the rest of `F4`. It points forward to `F4.02 — Trees & traversals`.
- Accent: sage (the chapter accent; the figure uses sage for prepend, gold for length and append).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.01 · part 3 of 3`

Hero `h1`: Complexity & big-O on the BEAM

Lede (verbatim):

> Big-O for a list is concrete: count how many cons cells an operation has to touch. Working at the head touches one cell, so it is O(1). Anything that needs the far end — length, append, `last` — touches every cell, so it is O(n). That single rule predicts the cost of every list function you will write.

Kicker (verbatim):

> Select an operation over a four-cell list and watch which cells light up. The number of touched cells is the complexity.

## Sections

In order:

1. `#touch` — **Cost is cells touched**. Teaching section: prepend builds one cell and shares the rest (one cell touched); length and append reach the end (all four). Carries the interactive operation-select figure over a four-cell list.
2. `#table` — **The cost cheat-sheet**. The whole list-operation cost table follows from the cons shape: prefer the head, treat the end as linear, reach for a different structure when the end must be fast. A `.bridge` (idea → Elixir) and a closing `.note` to `F4.02 — Trees & traversals`.

Running example: the list `[1, 2, 3, 4]` (with `[0 | list]` prepended and `++ [99]` appended).

Real Elixir code shown (`#table` section `pre.code`, verbatim intent):

```
list = [1, 2, 3, 4]

[0 | list]        # prepend  · O(1)  — one new head cell
hd(list)          # head     · O(1)  — read the first cell
tl(list)          # tail     · O(1)  — the rest, shared
length(list)      # count    · O(n)  — walk every cell
list ++ [99]      # append   · O(n)  — copy the left list
List.last(list)   # last     · O(n)  — walk to the end
```

## The interactives

**Figure — `The operation · select one`** (`figure.fig`, `aria-labelledby="boTitle"`, in `#touch`)

- Title (`#boTitle`): `The operation · select one`.
- Control group id: `#boSel` (`role="group"`, `aria-label="The operation"`). Buttons (`data-k` / `data-c` / label):
  - `prepend` / `sage` / "prepend" (active by default)
  - `length` / `gold` / "length"
  - `append` / `gold` / "append (++)"
- SVG element ids: new front cell `#boFront`/`#boFrontV` with arrow `#boFrontArr`/`#boFrontArrH`; base cells `#boCell0`/`#boCell1`/`#boCell2`/`#boCell3`; nil box `#boNil`; new end cell `#boEnd`/`#boEndV`; floating note `#boNote`.
- Live regions / readouts: code `#boCode`, readout `#boOut`, plus a complexity/touches line `#boBadge` and `#boTouches`.
- Pure function: `pick(k)` looks up `CASES[k]`, toggles the active button + `aria-pressed`, sets the opacity overlays, recolours the four base cells, and writes note/badge/touches/code/out. Defaults to `pick('prepend')`. Per-case data:
  - `prepend`: note "the four existing cells are shared, not touched"; badge `O(1)`; touches "1 cell at the head". Readout (`#boOut`): "**Prepend** builds one cell and shares the rest. One cell touched, regardless of length — **O(1)**."
  - `length`: note "every cell is visited once to count it"; badge `O(n)`; touches "all 4 cells". Readout: "**Length** has to walk to the end, visiting every cell once. Four cells, four steps — the cost grows with the list, so **O(n)**."
  - `append`: note "every left cell is copied, then the new cell is added"; badge `O(n)`; touches "all 4 + 1 new". Readout: "**Append** copies all four left-hand cells so the last can point at the new one. Linear in the left list — **O(n)**."
- Static defaults in markup: note "the four existing cells are shared, not touched"; badge `O(1)`; touches "1 cell at the head" — the SVG ships the `prepend` state so it reads correctly without JS.
- Take (verbatim): "If an operation can finish at the head, it is O(1); if it has to reach the end, it is O(n). Reading the cost is reading the cells — no benchmark required."
- Degrade: the figure renders statically in the `prepend` state; `pick('prepend')` runs only with JS, toggling opacity and recolouring. The reveal-on-scroll enhancer falls back to showing all `.reveal` sections under `prefers-reduced-motion: reduce` or without `IntersectionObserver`.

**Footer build-stamp decoder** (`.stamp` `#stamp`): id `#stampId` = `TSK0NbUluKYiYa`. Decoded by the inline `decodeBranded` (`EPOCH_MS = 1704067200000`): namespace `TSK`, snowflake `319539944127201280`, node `0`, seq `0`, timestamp `2026-05-31 18:17:39 UTC` (matching the static `#st-ts` panel value `2026-05-31 18:17:39 UTC`). Click/Enter/Space toggles the `.panel`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `List` — Elixir documentation — `https://hexdocs.pm/elixir/List.html` — cons-cell lists.
- Efficiency Guide — Erlang/OTP documentation — `https://www.erlang.org/doc/system/efficiency_guide.html` — complexity on the BEAM.
- Okasaki, C. (1996). *Purely Functional Data Structures.* — the foundational text. (no link)

Related in this course:
- `/elixir/algorithms/lists/recursion` — F4.01.2 · Recursion over cons cells
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls
- `/elixir/algorithms` — F4 · Algorithms & data structures

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / lists / big-o` — `big-o` is the current segment (`.rcur`); `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `lists` → `/elixir/algorithms/lists`.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) · `/` · `F4.01` (→ `/elixir/algorithms/lists`) · `/` · here `big-o`.
- toc-mini: `#touch` "Cost is cells touched"; `#table` "The cost cheat-sheet".
- pager: prev → `/elixir/algorithms/lists/recursion` label "F4.01.2 · recursion" (ghost); next → `/elixir/algorithms` label "Back to F4 · overview".
- footer: `Chapters` column → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. `The course` column → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Foot-tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = "Complexity & big-O on the BEAM — F4.01.3 · jonnify". `<meta description>` = "Big-O for a list is concrete: count the cons cells an operation touches. Working at the head is O(1); reaching the end — length, ++, last — is O(n). The cost cheat-sheet that motivates the rest of F4."

## Build instruction

To (re)build this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the operation-select + stamp module, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the sage `F4` accent. Change only the `<title>`/`<meta description>`, the `route-tag` (`big-o` current), and the `<main>` body — the hero copy, the `#touch` operation-select figure (its `CASES` table and the `#boCell0..3`/`#boBadge`/`#boTouches` ids), the `#table` cost cheat-sheet, the `.bridge`, and the `#refs` block. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…`/`PGE…` Snowflake ids), the event-sourced engine behind ONE Portal facade, and the Phoenix web app; cite the companion course for OTP / BEAM internals, do not re-teach them; keep the running example concrete (`[1, 2, 3, 4]`). Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Specific model sibling to copy from: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/cons.html` (same `F4` sage accent, same dive anatomy and the matching operation-select figure with overlay opacity toggles).
