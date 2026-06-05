# F4.12 — Lab: build a branded CHAMP store (module hub / lab landing)

- **Route (served):** `/elixir/algorithms/lab`
- **File:** `elixir/algorithms/lab/index.html`
- **Place in the chapter:** the capstone module of F4 · Algorithms & Data Structures, and the final module of the
  chapter (12 of 12). It frames the lab that assembles the chapter's parts — branded ids (`F4.07`–`F4.08`), the
  CHAMP node (`F4.06`), the partitioned store behind a GenServer (`F4.09`), and the recipes that read it (`F4.10`)
  — into one `Portal.Store`. The hub traces a single write through four layers, then routes the reader to three
  dives that build the store: insert and grow (`grow`), resolve ids as a registry (`registry`), and query by time
  range (`range`).
- **Accent:** sage (the F4 chapter accent; the page's accent word is `store`, rendered `<span class="ex">store</span>`,
  which the shared `.ex` rule paints in `--elixir-bright`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · Lab · module 12`

Hero `<h1>`: `Lab: build a branded CHAMP store`

Hero lede (`.lede`, verbatim): "This chapter built the parts in isolation — branded ids that validate and decode
(F4.07–F4.08), the CHAMP node that holds them cheaply (F4.06), the partitioned store behind a GenServer (F4.09),
the recipes that read it (F4.10). The lab assembles them into one `Portal.Store` you can keep as a reference. A
`put` is validated, routed to a partition by its namespace, stored in that partition's CHAMP, and its Snowflake
gives the creation time at no extra cost. Three dives build it, register entities, and query by time."

Kicker line (`.kicker`, verbatim): "Start with the whole stack at once: trace a single entity from `put` to
stored, through the four layers the dives assemble. Pick an entity."

## What the page frames

This is a lab landing built like a lesson hub: a hero with an interactive concept figure, a `#stack` trace
section, a `#build` section listing the three dives as link-cards, and a `#advanced` section showing the assembled
module. The three dives are presented as full-width `<a>` link-cards (not a `.mods` grid), each with its number,
title, one-line, and a left accent border.

- **F4.12.1 · put & partition — Watch a branded CHAMP grow** — route `/elixir/algorithms/lab/grow` — built (sage
  accent border). One-line (verbatim): "Insert branded keys one by one and watch the store take shape — each key
  routed to its partition by namespace, each partition's CHAMP filling, new partitions appearing on first use."
- **F4.12.2 · get & resolve — A Snowflake registry** — route `/elixir/algorithms/lab/registry` — built (blue
  accent border). One-line (verbatim): "Resolve any branded id in one call: route it to its partition, look it up
  in O(log₃₂ n) hops, and read its creation time straight out of the Snowflake — or reject it if the namespace is
  wrong."
- **F4.12.3 · range by time — Query by time range** — route `/elixir/algorithms/lab/range` — built (gold accent
  border). One-line (verbatim): "Because Snowflake ids are time-ordered, a time window becomes an id range:
  compute the bounds, scan one partition, and return the entries created inside it — no separate timestamp column."

The `#stack` section frames the four-layer write path (one teaching section): validate → route by namespace →
store in the partition CHAMP → decode the Snowflake for `created_at`. The `#advanced` section names the assembled
module: a GenServer over one map `%{namespace => CHAMP}` whose public surface is `put/2` (validate and route),
`get/1` (resolve an id to its entry and embedded timestamp), and `range/2` (turn a time window into id bounds and
scan a partition).

## The interactives

### Hero figure — "The store · namespace → CHAMP" (`#hsLanes` lanes + `hp-ctrls` buttons)

- **Figure:** `<figure class="hero-fig" aria-labelledby="hsTitle">`, title `The store · namespace → CHAMP`
  (`#hsTitle`). Inline `<svg viewBox="0 0 320 300">` labelled `Portal.Store` with `%{ns => champ}`. Three lanes in
  group `#hsLanes`, keyed by three-letter namespace: `USR` (users, sage accent `#a7c9b1`, entry stroke `#7ba387`),
  `LSN` (lessons, blue `#9fc0ea`, stroke `#5a87c4`), `PGE` (pages, gold `#f0cd7f`, stroke `#d4a85a`). Static markup
  starts with one stored `USR` entry chip (`USR0NbAb1xcFCy`); the `LSN` and `PGE` lanes read `empty CHAMP`.
- **Routing note SVG text (`#hsRoute`):** `prefix routes each id to its lane`.
- **Controls (`.hp-ctrls`):** four `<button class="hp-btn">` — `#hsPut` ("▸ put"), `#hsGet` ("get"),
  `#hsRange` ("range", `.ghost`), `#hsReset` ("reset", `.ghost`).
- **SVG element ids:** `#hsLanes` (lane group), `#hsRoute` (routing note), `#hsCap` (the live caption `.hp-cap`).
- **Pure functions:** `tally` is not used here; the hero state machine uses `clone(s)`, `renderLane(lane)`,
  `render()`, `putNext()`, `getOne()`, `rangeOne()`, `syncDisabled()`, `poolExhausted()`. `putNext` draws the next
  unused id from `POOL = ['LSN0NbCMKoAopE', 'PGE0NbWMtkolM0', 'USR0NbZ7q2bvKm', 'LSN0Nc1pX4rDtA', 'PGE0Nc7vQ9mEhB',
  'USR0NcFw3pLnTd']` whose lane (cap `CAP = 3`) still has room, routes it by its three-letter prefix, and
  `unshift`es it to the front of `store[ns]`. `INITIAL = { USR: ['USR0NbAb1xcFCy'], LSN: [], PGE: [] }`.
- **Caption strings (`#hsCap`, verbatim):**
  - Default first line: `store: USR→1, LSN→0, PGE→0` (the static markup); the live first line is rebuilt as
    `store: USR→n, LSN→n, PGE→n`.
  - Default / reset second line: "put routes by the 3-letter prefix; get and range read one lane."
  - On put: "put <b>{shortId}</b> — prefix <b>{ns}</b> routed it to the <b>{label}</b> lane."
  - On get: "get <b>{shortId}</b> — routed to <b>{label}</b>, found in O(log₃₂ n) hops."
  - On range: "range over <b>{label}</b> — {n} time-ordered id(s) inside the window."
- **Degrades:** the static SVG already shows the store with one `USR` entry and the default caption; there is no
  render on load (comment: "No render on load: the static SVG already shows the store with one USR entry."). The
  slide-in `.hp-new` animation is gated behind `@media (prefers-reduced-motion: no-preference)` and disabled under
  `prefers-reduced-motion: reduce`. No browser storage. `put` self-disables when the pool is exhausted or every
  lane is at cap.

### `#stack` figure — "Entity · select one" (`#lbSel` selector + four-layer SVG)

- **Figure:** `<figure class="fig" aria-labelledby="lbTitle">`, heading `Entity · select one` (`#lbTitle`).
- **Control ids / buttons (`#lbSel`, role="group"):** three `<button>`s — `data-k="usr" data-c="sage"` (label
  "a user", starts `active`), `data-k="lsn" data-c="blue"` (label "a lesson"), `data-k="pge" data-c="gold"`
  (label "a page").
- **SVG element ids:** `#lbId` (the `put` line), `#lbValidate` (layer 1), `#lbRoute` (layer 2), `#lbChamp`
  (layer 3), `#lbStamp` (layer 4); below the SVG `#lbCode` (`pre.code`), `#lbOut` (`.geo-readout`), `#lbRole`
  (partition), `#lbResult` (created).
- **Pure functions:** `hops(n) = max(1, ceil(log(n)/log(32)))`; `pick(k)` selects the entity from
  `ENT = { usr:{id:'USR0NbAb1xcFCy', ns:'USR', part:'users', size:3, ts:'2026-05-31 13:35:19'},
  lsn:{id:'LSN0NbCMKoAopE', ns:'LSN', part:'lessons', size:5, ts:'2026-05-31 14:00:00'},
  pge:{id:'PGE0NbWMtkolM0', ns:'PGE', part:'pages', size:1, ts:'2026-05-31 18:40:00'} }` and rewrites all five SVG
  texts plus the code block and readout. Initial call `pick('usr')`.
- **SVG static defaults (verbatim):** `#lbId` "put  USR0NbAb1xcFCy"; `#lbValidate` "well-formed USR id";
  `#lbRoute` "USR → users partition"; `#lbChamp` "users CHAMP · 3 entries · 1 level"; `#lbStamp`
  "created 2026-05-31 13:35:19 UTC". `#lbRole` "users"; `#lbResult` "2026-05-31 13:35:19".
- **Readout string (`#lbOut`, the template, verbatim):** "The id `{e.id}` validates as a **{e.ns}**, routes to the
  **{e.part}** partition, lands in a CHAMP of **{e.size}** entries (**{h}** level), and carries its own creation
  time **{e.ts} UTC** — four layers, four earlier lessons, one write."
- **Takeaway (`.take`, verbatim):** "One id carries everything the store needs: it validates itself, names its own
  partition, and dates itself. The four layers are the four earlier lessons, stacked into one write path."

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NchNwlMM1g`. The static `#st-ts` reads `2026-06-01 11:41:46 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319802704245293056`, node `0`, seq `0`, timestamp
  `2026-06-01 11:41:46 UTC` — matching the static value.
- **Pure functions:** `b62decode(s)` over `"0123…XYZabc…xyz"` → BigInt; `pad2(x)`; `decodeBranded(id)` splits
  `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`,
  `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Toggle on click / Enter / Space sets `.open` and
  `aria-expanded`. Fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`.

## References (`#refs`, verbatim)

Intro prose: "Primary sources for this lab, and the lessons it assembles."

**Sources**
- Elixir — GenServer → `https://hexdocs.pm/elixir/GenServer.html` — the process that owns the store.
- Elixir — `update_in/3` → `https://hexdocs.pm/elixir/Kernel.html#update_in/3` — updating one partition in the map.
- Elixir — Map → `https://hexdocs.pm/elixir/Map.html` — the namespace-to-CHAMP map at the top.

**Related in this course**
- F4.09 · Branded CHAMP maps & GenServer → `/elixir/algorithms/branded-champ` — the store this lab builds.
- F4.06 · CHAMP → `/elixir/algorithms/champ` — the node inside each partition.
- F4.08 · Branded ids & persistence → `/elixir/algorithms/persistence` — validation and time-range queries.
- F4 · Algorithms & Data Structures → `/elixir/algorithms`

## Wiring

- **route-tag (verbatim, segmented):** `/` `elixir` `/` `algorithms` `/` `lab` — `elixir` links `/elixir`,
  `algorithms` links `/elixir/algorithms`, current `lab` is `<span class="rcur">`.
- **crumbs:** `F4 · Algorithms & Data Structures` → `/elixir/algorithms` · sep `/` · here `F4.12 · lab` (no link).
- **toc-mini:** `#stack` ("Trace the stack") · `#build` ("Build it · three dives") · `#advanced`
  ("Advanced: the assembled module").
- **pager:** prev → `/elixir/algorithms/dynamic-programming` ("← F4.11 · dynamic-programming"); next →
  `/elixir/algorithms/lab/grow` ("Start · watch it grow →").
- **footer (3-column "foot-nav"):**
  - Brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice:
    first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"),
    `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"),
    `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"),
    `/elixir/algebra/functions` ("Start · F1.01").
  - Build stamp `TSK0NchNwlMM1g`.
  - Header brand `.brand` → `/elixir`; header nav `Contents` → `/elixir/course`.
- **Page meta:** `<title>` "Lab: build a branded CHAMP store — F4.12 · jonnify"; `<meta description>` "The
  capstone lab assembles the chapter into one Portal.Store: a GenServer over a map from namespace to that
  namespace's CHAMP. A put is validated, routed to a partition by its three-letter prefix, stored in that
  partition's CHAMP, and dated for free from the Snowflake embedded in its id. The hub traces one write through
  those four layers — each an earlier lesson — and three dives build the store: insert and watch it grow, resolve
  ids as a registry, and query by time range."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the
two trailing `<script>` blocks (the figure logic + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim
from a recent built sibling on the F4 sage accent — the model is the sibling dive `elixir/algorithms/lab/grow.html`
(same chapter, same accent, same shared shell), changing only `<title>`/`<meta description>`, the `.route-tag`
segments, the crumbs, and the `<main>` body. This hub additionally carries the hero concept figure (`#hsLanes`
put/get/range state machine) and the dive link-card list, so for those copy the hero-art figure markup and its
`<script>` block from this page itself. Use only the real Portal surfaces as written — the branded store
(`Portal.Store` as a GenServer over `%{namespace => CHAMP}`, public `put/2`/`get/1`/`range/2`), the immutable
CHAMP partition, the Snowflake-branded ids that route and date themselves; do not invent module names or arities,
and cite the companion F4 lessons (`F4.06`–`F4.10`) for the OTP and data-structure internals rather than
re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
Model sibling to copy from: `elixir/algorithms/lab/grow.html`.
