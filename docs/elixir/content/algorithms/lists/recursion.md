# F4.01.2 — Recursion over lists (dive)

- Route (served): `/elixir/algorithms/lists/recursion`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/recursion.html`
- Place in the chapter: the second dive under the `F4.01 · lists` hub (part 2 of 3). It takes the head-and-tail split established in `cons` and turns it into the recursion that walks a list, then contrasts direct recursion with the tail-recursive accumulator. It leads into the big-O dive.
- Accent: sage (the chapter accent; the figure uses sage for `sum`, blue for `map`, gold for `length`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.01 · part 2 of 3`

Hero `h1`: Recursion over lists

Lede (verbatim):

> There is no loop keyword for lists — you walk one by recursion. The pattern is always the same: match `[head | tail]`, do something with the head, call yourself on the tail, and stop at the empty list. Sum, map, and length are all this one shape with a different body.

Kicker (verbatim):

> When the recursive call is the very last thing a clause does, it is tail-recursive and runs in constant stack space — a loop in disguise. Select a function to see its clauses and how the list reduces.

## Sections

In order:

1. `#fold` — **Three functions, one shape**. Teaching section: each function has a recursive clause for `[h | t]` and a base clause for `[]`; the recursive clause reduces by one element, the base clause stops it. Carries the interactive function-select figure over `[12, 8, 30]`.
2. `#tail` — **Direct vs tail-recursive**. Direct recursion leaves work pending so the call stack grows; a tail-recursive version carries an accumulator and the BEAM runs it as a loop in constant space. A `.bridge` (idea → Elixir) and a closing `.note` to the big-O dive.

Running example: the list `[12, 8, 30]` (sum → `50`; map ×2 → `[24, 16, 60]`; length → `3`).

Real Elixir code shown (`#tail` section `pre.code`, verbatim intent):

```
# direct recursion — clear, but the stack grows with the list
def sum([h | t]), do: h + sum(t)
def sum([]), do: 0

# tail-recursive — the recursive call is the last step, so it is a loop
def tsum(list), do: tsum(list, 0)
defp tsum([h | t], acc), do: tsum(t, acc + h)
defp tsum([], acc), do: acc
```

## The interactives

**Figure — `The function · select one`** (`figure.fig`, `aria-labelledby="rcTitle"`, in `#fold`)

- Title (`#rcTitle`): `The function · select one`.
- Control group id: `#rcSel` (`role="group"`, `aria-label="The function"`). Buttons (`data-k` / `data-c` / label):
  - `sum` / `sage` / "sum" (active by default)
  - `map` / `blue` / "map (×2)"
  - `length` / `gold` / "length"
- SVG element ids: clause line `#rcClause`, arrow label `#rcArrLbl`, result box `#rcResultBox`, result text `#rcResult`, base-case line `#rcBase`. (The three cell rects `12`/`8`/`30` are static.)
- Live regions: code `#rcCode`, readout `#rcOut`.
- Pure function: `pick(k)` looks up `CASES[k]`, toggles the active button + `aria-pressed`, rewrites the clause line / arrow label / base-case line, recolours and re-fills `#rcResultBox` + `#rcResult`, and writes `code`/`out`. Defaults to `pick('sum')`. Per-case data:
  - `sum`: clause `sum([h | t]) = h + sum(t)`, base `base case:  sum([]) = 0`, arrow "fold with +", result `50`. Readout (`#rcOut`): "`sum/1` adds the head to the sum of the tail, bottoming out at `0` for `[]`. Over `[12, 8, 30]` that is `12 + 8 + 30 + 0 = 50`."
  - `map`: clause `map([h | t], f) = [f(h) | map(t, f)]`, base `base case:  map([], f) = []`, arrow "apply ×2", result `[24, 16, 60]`. Readout: "`map/2` builds a new list: the function applied to the head, consed onto the mapped tail. Doubling `[12, 8, 30]` gives `[24, 16, 60]`."
  - `length`: clause `length([_ | t]) = 1 + length(t)`, base `base case:  length([]) = 0`, arrow "count cells", result `3`. Readout: "`length/1` ignores the head and adds one per cell, bottoming out at `0`. It must walk the whole list, so it is O(n) — the cost model of the next dive."
- Static defaults in markup: clause `sum([h | t]) = h + sum(t)`, base `base case:  sum([]) = 0`, arrow label "fold with +", result `50` — the SVG ships the `sum` state so it reads correctly without JS.
- Take (verbatim): "The recursive clause shrinks the list by its head; the base clause says what an empty list is worth. Get those two right and the function is correct — there is no third case to forget."
- Degrade: the figure renders statically in the `sum` state; `pick('sum')` runs only with JS, swapping colours/text/code. The reveal-on-scroll enhancer falls back to showing all `.reveal` sections under `prefers-reduced-motion: reduce` or without `IntersectionObserver`.

**Footer build-stamp decoder** (`.stamp` `#stamp`): id `#stampId` = `TSK0NbUltrbdI0`. Decoded by the inline `decodeBranded` (`EPOCH_MS = 1704067200000`): namespace `TSK`, snowflake `319539943699382272`, node `0`, seq `0`, timestamp `2026-05-31 18:17:39 UTC` (matching the static `#st-ts` panel value `2026-05-31 18:17:39 UTC`). Click/Enter/Space toggles the `.panel`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `List` — Elixir documentation — `https://hexdocs.pm/elixir/List.html` — cons-cell lists.
- Erlang — Efficiency Guide — `https://www.erlang.org/doc/system/efficiency_guide.html` — complexity on the BEAM.
- Okasaki, C. (1996). *Purely Functional Data Structures* — the foundational text on recursive list and tree structures. (no link)

Related in this course:
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls
- `/elixir/algorithms/lists/big-o` — Complexity & big-O on the BEAM

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / lists / recursion` — `recursion` is the current segment (`.rcur`); `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `lists` → `/elixir/algorithms/lists`.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) · `/` · `F4.01` (→ `/elixir/algorithms/lists`) · `/` · here `recursion`.
- toc-mini: `#fold` "Three functions, one shape"; `#tail` "Direct vs tail-recursive".
- pager: prev → `/elixir/algorithms/lists/cons` label "F4.01.1 · cons" (ghost); next → `/elixir/algorithms/lists/big-o` label "Next · big-O".
- footer: `Chapters` column → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. `The course` column → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Foot-tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = "Recursion over lists — F4.01.2 · jonnify". `<meta description>` = "You walk a list by recursion, not a loop: match [h | t], act on the head, recurse on the tail, and stop at []. sum, map, and length are the same shape with a different body; a tail-recursive accumulator turns the walk into a constant-space loop."

## Build instruction

To (re)build this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the function-select + stamp module, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the sage `F4` accent. Change only the `<title>`/`<meta description>`, the `route-tag` (`recursion` current), and the `<main>` body — the hero copy, the `#fold` function-select figure (its `CASES` table and the `#rcClause`/`#rcResult` ids), the `#tail` direct-vs-tail-recursive code, the `.bridge`, and the `#refs` block. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…`/`PGE…` Snowflake ids), the event-sourced engine behind ONE Portal facade, and the Phoenix web app; cite the companion course for OTP internals (including how the BEAM runs a tail call as a loop), do not re-teach them; keep the running example concrete (`[12, 8, 30]`). Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Specific model sibling to copy from: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/cons.html` (same `F4` sage accent, same dive anatomy and figure-select pattern).
