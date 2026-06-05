# F4.01.1 — Cons cells & the shape of a list (dive)

- Route (served): `/elixir/algorithms/lists/cons`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/cons.html`
- Place in the chapter: the first of the three dives under the `F4.01 · lists` hub (part 1 of 3). It establishes the cons-cell shape and the cost asymmetry — O(1) prepend/read vs O(n) append — that the recursion and big-O dives build on.
- Accent: sage (the dive uses sage for prepend, blue for head/tail, gold for append; the chapter accent is sage).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.01 · part 1 of 3`

Hero `h1`: Cons cells & the shape of a list

Lede (verbatim):

> A cons cell is a pair: a head and a pointer to the tail. Building a list with `[head | tail]` makes one new cell that points at an existing list — so prepending is O(1) and the old list is shared, never copied. Reading the head or tail is O(1) too. Appending is the expensive one: it must copy the whole left-hand list.

Kicker (verbatim):

> Three operations on `[1, 2, 3]`, and what each does to the cells. Watch which cells are reused and which are copied.

## Sections

In order:

1. `#ops` — **Three operations**. Teaching section: prepend adds one cell at the front and shares the rest; head/tail only read an existing cell; append walks to the end, copying every cell. Carries the interactive operation-select figure.
2. `#code` — **In code**. Shows the cons operator `|`, `hd/1` and `tl/1`, the `++` append, and a `case` destructure. A `.bridge` (idea → Elixir) and a closing `.note` to the recursion dive.

Running example: the list `[1, 2, 3]` (with `[0 | list]` prepended and `++ [99]` appended).

Real Elixir code shown (`#code` section `pre.code`, verbatim intent):

```
list = [1, 2, 3]

[0 | list]      # prepend  => [0, 1, 2, 3]   · O(1), shares list
hd(list)        # head     => 1              · O(1)
tl(list)        # tail     => [2, 3]         · O(1)
list ++ [99]    # append   => [1, 2, 3, 99]  · O(n), copies list

case list do
  [head | tail] -> {head, tail}   # {1, [2, 3]}
  [] -> :empty
end
```

## The interactives

**Figure — `The operation · select one`** (`figure.fig`, `aria-labelledby="cnTitle"`, in `#ops`)

- Title (`#cnTitle`): `The operation · select one`.
- Control group id: `#cnSel` (`role="group"`, `aria-label="The operation"`). Buttons (`data-k` / `data-c` / label):
  - `prepend` / `sage` / "prepend [0 | list]" (active by default)
  - `headtail` / `blue` / "head / tail"
  - `append` / `gold` / "append ++ [99]"
- SVG element ids: new front cell `#cnNewFront`/`#cnNewFrontV` with arrow `#cnFrontArr`/`#cnFrontArrH`; base cells `#cnCell0`/`#cnCell1`/`#cnCell2`; tail arrow `#cnTailArr`/`#cnTailArrH`; nil box `#cnNil`; new end cell `#cnNewEnd`/`#cnNewEndV`; floating note `#cnSvgNote`.
- Live regions / readouts: code `#cnCode`, readout `#cnOut`, plus a result/cost line `#cnResult` and `#cnCost`.
- Pure function: `pick(k)` looks up `CASES[k]`, toggles the active button + `aria-pressed`, sets the opacity overlays via `setOp`, recolours the three base cells via `cell`, and writes the note/result/cost/code/out. Defaults to `pick('prepend')`. The static note default in markup: "one new cell points at the existing list — nothing is copied". Per-case readout (`#cnOut`) strings, verbatim:
  - `prepend`: "**Prepend** makes one cell whose tail points at the existing list. The old cells are shared unchanged, so the cost is O(1) no matter how long the list is." — note "one new cell points at the existing list — nothing is copied"; result `[0, 1, 2, 3]`; cost `O(1)`.
  - `headtail`: "**Head** reads the first cell's value; **tail** returns the rest of the list, which is the same shared cells. Both are O(1) reads." — note "head is the first cell; tail is the rest, shared as-is"; result `hd 1 · tl [2, 3]`; cost `O(1)`.
  - `append`: "**Append** must copy every cell of the left list, because each one already points at its own tail. The cost grows with the list length — O(n)." — note "every left-hand cell is copied so its tail can point to the new end"; result `[1, 2, 3, 99]`; cost `O(n)`.
- Static result/cost line defaults in markup: result `[0, 1, 2, 3]`, cost `O(1)`. The static SVG note default: "one new cell points at the existing list — nothing is copied".
- Take (verbatim): "Prepend and read are cheap because they touch one cell. Append is linear because the cells of the left list already point at their own tails, so the runtime must build fresh copies to redirect them."
- Degrade: the figure renders statically (the SVG ships the base `[1, 2, 3]` chain); `pick('prepend')` runs only with JS. No motion animation on this figure beyond the opacity toggles. The reveal-on-scroll enhancer falls back to showing all `.reveal` sections under `prefers-reduced-motion: reduce` or without `IntersectionObserver`.

**Footer build-stamp decoder** (`.stamp` `#stamp`): id `#stampId` = `TSK0NbUltQM8no`. Decoded by the inline `decodeBranded` (`EPOCH_MS = 1704067200000`): namespace `TSK`, snowflake `319539943296729088`, node `0`, seq `0`, timestamp `2026-05-31 18:17:39 UTC` (matching the static `#st-ts` panel value `2026-05-31 18:17:39 UTC`). Click/Enter/Space toggles the `.panel`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `List` — Elixir documentation — `https://hexdocs.pm/elixir/List.html` — cons-cell lists.
- Efficiency Guide — Erlang/OTP documentation — `https://www.erlang.org/doc/system/efficiency_guide.html` — complexity on the BEAM.
- Okasaki, C. (1996). *Purely Functional Data Structures.* — the foundational text. (no link)

Related in this course:
- `/elixir/algorithms/lists/big-o` — Big-O on the BEAM — the cost of each list operation.
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / lists / cons` — `cons` is the current segment (`.rcur`); `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `lists` → `/elixir/algorithms/lists`.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) · `/` · `F4.01` (→ `/elixir/algorithms/lists`) · `/` · here `cons`.
- toc-mini: `#ops` "Three operations"; `#code` "In code".
- pager: prev → `/elixir/algorithms/lists` label "F4.01 · lists" (ghost); next → `/elixir/algorithms/lists/recursion` label "Next · recursion".
- footer: `Chapters` column → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. `The course` column → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Foot-tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = "Cons cells & the shape of a list — F4.01.1 · jonnify". `<meta description>` = "A cons cell is a head and a tail pointer. [head | tail] builds one new cell over an existing list, so prepend is O(1) and the old list is shared; hd/1 and tl/1 are O(1) reads; ++ appends by copying the left list, so it is O(n)."

## Build instruction

To (re)build this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the figure-select + stamp module, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the sage `F4` accent. Change only the `<title>`/`<meta description>`, the `route-tag` (`cons` current), and the `<main>` body — the hero copy, the `#ops` operation-select figure (its `CASES` table and the SVG cell ids), the `#code` block, the `.bridge`, and the `#refs` block. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…`/`PGE…` Snowflake ids), the event-sourced engine behind ONE Portal facade, and the Phoenix web app; cite the companion course for OTP internals, do not re-teach them; keep the running example concrete (`[1, 2, 3]`, `[0 | list]`, `++ [99]`). Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Specific model sibling to copy from: `/Users/jonny/dev/jonnify/elixir/algorithms/lists/big-o.html` (same `F4` sage accent, same dive anatomy and figure-select pattern).
