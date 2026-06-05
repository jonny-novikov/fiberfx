# F4.12.3 — Query by time range (dive)

- **Route (served):** `/elixir/algorithms/lab/range`
- **File:** `elixir/algorithms/lab/range.html`
- **Place in the chapter:** the third and final dive under the `F4.12` lab (`/elixir/algorithms/lab`), and the last
  page of the F4 chapter. It builds the store's time-range query: because a Snowflake puts the timestamp in its
  high bits, ids sort by creation time, so a time window becomes an id range `[min, max)` computed from the clock.
  It closes the lab arc (grow → registry → range) and the chapter, returning the reader to the chapter overview.
- **Accent:** sage (the F4 chapter accent; accent word `range`, rendered `<span class="ex">range</span>`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.12 · part 3 of 3 · range by time`

Hero `<h1>`: `Query by time range`

Hero lede (`.lede`, verbatim): "The last capability the store needs is "what was created between these two times."
Because a Snowflake puts the timestamp in its high bits, ids sort by creation time, and a time window becomes an
**id range**: compute the id that any entry at the start would have, and the one at the end, and every entry in
the window is an id between them. The query needs no separate timestamp column — the bound is computed straight
from the clock."

Kicker line (`.kicker`, verbatim): "Five lessons in the partition, at known times. Pick a window and watch the
bounds pick out the entries created inside it."

## Sections

One teaching section then one advanced section, in the single-column lesson layout (no hero-art figure).

1. **`#window` · "A window becomes a range"** (teaching) — the window's start and end map to id bounds
   `[min, max)`; an entry is in the window when its id (equivalently its decoded time) falls in that range; the
   13:35 lesson sits before every window and is never matched. Carries the `#rnSel` timeline figure.
2. **`#advanced` · "Advanced: bounds, sorting, and the catch"** — the bound is arithmetic: the smallest id at
   time `t` is `(t - epoch) << 22`, the same trick as the F4.08 database range query; the honest catch is that a
   CHAMP is hash-ordered, so a true range scan needs a sorted index (`:gb_sets`/tree) alongside the partition or a
   filter over a small partition. Carries the `pre.code` for `handle_call({:range, …})` and the idea→elixir bridge.

**Running example:** five lessons in the `LSN` partition at known UTC times on `2026-05-31` —
`LSN0NbAb2Lk9GS` (13:35), `LSN0NbCMKoAopE` (14:00), `LSN0NbCiUI0Sg4` (14:05), `LSN0NbD94T0Qtu` (14:11),
`LSN0NbDmwjVOEa` (14:20) — against three windows: `14:00–14:10`, `14:00–14:15`, `14:00–14:25`.

**Real Elixir shown (`#advanced`, verbatim):**
```
# range/2 — a time window becomes id bounds over one partition
def handle_call({:range, ns, from, to}, _from, store) do
  min = Snowflake.at(from)                    # (from - epoch) << 22
  max = Snowflake.at(to)
  hits =
    store
    |> Map.get(ns, Champ.new())              # only this namespace's partition
    |> Champ.keys()
    |> Enum.filter(fn id -> id >= min and id < max end)  # in the window
  {:reply, {:ok, hits}, store}
end
```

## The interactives

### `#window` figure — "Time window · select one · 2026-05-31 UTC" (`#rnSel` selector + timeline)

- **Figure:** `<figure class="fig" aria-labelledby="rnTitle">`, heading `Time window · select one · 2026-05-31 UTC`
  (`#rnTitle`).
- **Control ids / buttons (`#rnSel`, role="group"):** three `<button>`s — `data-k="a" data-c="sage"`
  (label "14:00–14:10", starts `active`), `data-k="b" data-c="blue"` (label "14:00–14:15"), `data-k="c" data-c="gold"`
  (label "14:00–14:25").
- **SVG element ids:** `#rnBand` (the shaded window band), `#rnTicks` (axis ticks group), `#rnDots` (lesson dots
  group, per-lesson `#rnDot_<i>` and `#rnLbl_<i>`), `#rnBounds` (the `min ≤ id < max` line), `#rnCount`
  (in-window tally). Below the SVG: `#rnCode` (`pre.code`), `#rnOut` (`.geo-readout`), `#rnRole` (window),
  `#rnResult` (matched).
- **SVG static defaults (verbatim):** `#rnBounds` "min ≤ id < max"; `#rnCount` "2 of 5 in window";
  `#rnRole` "14:00–14:10"; `#rnResult` "2 entries".
- **Pure functions:** `xOf(ms)` plots a time on the 13:30→14:30 timeline (10px per minute from x=60);
  `snowAt(ms) = ((ms - EPOCH_MS) << 22n).toString()` computes the id bound; `pick(k)` moves the band, recolours
  the matched dots, and rewrites the bounds line, count, code, and readout. The match is real: `start <= ms < end`.
  `EPOCH_MS = 1704067200000`. Initial call (the `active` button) is window `a`.
- **Readout string (`#rnOut`, the template, verbatim):** "The window **{label}** becomes id bounds `[min, max)`,
  and **{n}** of the partition's 5 lessons fall inside — {matched labels}. The 13:35 lesson is before the window,
  so it is excluded; no timestamp column was read."
- **Code string (`#rnCode`, the template, verbatim):** `# window {label} -> id bounds over the lessons partition` /
  `Portal.Store.range("LSN", {~U[2026-05-31 {start}:00Z], ~U[2026-05-31 {end}:00Z]})` /
  `# => {n} entries: {matched labels}`.
- **Takeaway (`.take`, verbatim):** "No timestamp was stored, yet the store answered a time-range query. The id is
  the sort key and the clock, so a window of time and a range of ids are the same question."
- **Degrades:** the ticks, dots, and band are positioned by JS, but content is visible without JS (`html.js` gates
  only the reveal). `prefers-reduced-motion: reduce` collapses the reveal. No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NchNxghKIi`. The static `#st-ts` reads `2026-06-01 11:41:46 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319802705092542464`, node `0`, seq `0`, timestamp
  `2026-06-01 11:41:46 UTC` — matching the static value.
- **Pure functions:** `b62decode(s)` over `"0123…XYZabc…xyz"` → BigInt; `pad2(x)`; `decodeBranded(id)` splits
  `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`,
  `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Toggle on click / Enter / Space sets `.open`.

## References (`#refs`, verbatim)

Intro prose: "Primary sources for this lab, and the lessons it assembles."

**Sources**
- Snowflake ID — Wikipedia → `https://en.wikipedia.org/wiki/Snowflake_ID` — the time-ordered id and its bit layout.
- Elixir — `Enum.filter/2` → `https://hexdocs.pm/elixir/Enum.html#filter/2` — selecting the entries in the window.
- Erlang — `:gb_sets` → `https://www.erlang.org/doc/man/gb_sets.html` — a sorted set for a true id-range scan.

**Related in this course**
- F4.12 · Lab: build a branded CHAMP store → `/elixir/algorithms/lab` — the lab hub.
- F4.08 · Branded ids & persistence → `/elixir/algorithms/persistence` — the same bounds as a database range query.
- F4.07 · Identifiers, Snowflake & branded ids → `/elixir/algorithms/identifiers` — why ids sort by time.
- F4 · Algorithms & Data Structures → `/elixir/algorithms`

## Wiring

- **route-tag (verbatim, segmented):** `/` `elixir` `/` `algorithms` `/` `lab` `/` `range` — `elixir`, `algorithms`,
  `lab` are links; current `range` is `<span class="rcur">`.
- **crumbs:** `F4` → `/elixir/algorithms` · sep `/` · `F4.12` → `/elixir/algorithms/lab` · sep `/` · here `range`.
- **toc-mini:** `#window` ("A window becomes a range") · `#advanced` ("Advanced: bounds, sorting, and the catch").
- **pager:** prev → `/elixir/algorithms/lab/registry` ("← F4.12.2 · registry"); next → `/elixir/algorithms`
  ("F4 · Algorithms & Data Structures →"). This dive's next is the chapter overview, not a sibling — it is the last
  page of the lab and of the chapter.
- **footer (3-column "foot-nav"):** identical to the lab hub — brand `.foot-logo` → `/elixir`; Chapters column
  `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`,
  `/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; build stamp
  `TSK0NchNxghKIi`. Header brand → `/elixir`; nav `Contents` → `/elixir/course`.
- **Page meta:** `<title>` "Query by time range — F4.12.3 · jonnify"; `<meta description>` "Because a Snowflake
  puts the timestamp in its high bits, ids sort by creation time and a time window becomes an id range: the
  smallest id at time t is (t - epoch) << 22, so computing the bounds for a window's start and end selects the
  entries created inside it with no timestamp column. The honest catch in memory is that a CHAMP is hash-ordered,
  so a true range scan needs a sorted index alongside it (gb_sets) or a filter over a small partition."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the
two trailing `<script>` blocks verbatim from a recent built sibling on the F4 sage accent — the model is the
sibling dive `elixir/algorithms/lab/registry.html` (same lab, same accent, same single-column lesson hero, same
`solid-select` figure pattern), changing only `<title>`/`<meta description>`, the `.route-tag` segments, the
crumbs, and the `<main>` body (eyebrow/h1/lede/kicker, the `#window` figure, the `#advanced` prose + `pre.code`,
the bridge, the references, and the pager — note the pager's next points at the chapter overview `/elixir/algorithms`
because this is the chapter's last page). Use only the real Portal surfaces as written — `Portal.Store.range/2`
over a `%{namespace => CHAMP}` map, `Snowflake.at/1` to compute the `(t - epoch) << 22` bound, `Map.get(ns, Champ.new())`
to read one partition, `Champ.keys/1` and `Enum.filter/2` to select the window; do not invent module names or
arities, and cite the companion F4 lessons (`F4.07` identifiers, `F4.08` persistence) for the Snowflake bit-layout
and the database-range trick rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji,
and none of "just"/"simply"/"obviously". Model sibling to copy from: `elixir/algorithms/lab/registry.html`.
