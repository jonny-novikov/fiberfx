# F4.04 — Maps, sets & hashing (module hub)

- Route (served): `/elixir/algorithms/maps`
- File: `elixir/algorithms/maps/index.html`
- Place in the chapter: The fourth module of F4 · Algorithms & Data Structures. It follows `F4.03 · sorting` (ordering buys `O(log n)` search) and opens the persistent-map spine — its advanced section points forward to `F4.05 · HAMT`, the start of the spine that runs HAMT → CHAMP → Snowflake/branded ids → persistence → branded-CHAMP. The hub frames three dives: lookup, membership, and the hash underneath.
- Accent: sage (the F4 chapter accent; `--sage` `#7ba387` / `--sage-bright` `#a7c9b1`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4 · Foundations · module 4`

Hero h1: Maps, sets & `hashing` (the word "hashing" carries the `.ex` elixir-bright italic accent).

Lede (verbatim):

> Sorting (F4.03) bought fast search by paying for order. A **hash map** makes a different trade: it gives up order entirely and, in exchange, looks a value up by key in effectively constant time. A **set** is the same machinery answering one question — is this element present? — and **hashing** is what makes both O(1) on average.

Kicker (verbatim):

> The worked example is this course's own data layer. The site runs on Phoenix LiveView; its content is a map from route to a page record, keyed by a branded `Snowflake` id, and the set of built routes is what the link checker tests against. Three angles open the module — lookup, membership, and the hash underneath.

## What the page frames

The hub is structured as three top-level sections (`#registry`, `#dives`, `#advanced`) plus References. The three dives are presented as the `.dives` card list under `#dives`:

- **F4.04.1 — Maps & key lookup** — `Map.get`, `Map.fetch`, and `Map.put` over the page registry — and why a LiveView's `socket.assigns` is itself a map. Route `/elixir/algorithms/maps/lookup`. Built. (left-border accent sage)
- **F4.04.2 — MapSet & membership** — `MapSet.member?` is the link checker; union, intersection, and difference compose the built and planned route sets. Route `/elixir/algorithms/maps/sets`. Built. (left-border accent blue)
- **F4.04.3 — Hashing & collisions** — `:erlang.phash2` turns a key into a slot, collisions resolve, and Elixir stores entries in a 32-way HAMT. Route `/elixir/algorithms/maps/hashing`. Built. (left-border accent gold)

The `#registry` section ("The page registry") establishes the running example: every page is one entry in a map — route key → `%Page{}` struct carrying a branded Snowflake id. The `#advanced` section ("Advanced: sort vs hash, and the HAMT") contrasts ordering (`O(log n)`) with hashing (`O(1)`) and introduces the HAMT, naming `F4.05` as the next module.

## The interactives

### Figure 1 — hero: `key → hash → bucket`

- `<figure class="hero-fig">`, labelled by `#hpTitle` with text `key → hash → bucket`.
- Controls (`.hp-ctrls`): `#hpAdd` button label `▸ insert key`; `#hpReset` button label `reset`.
- SVG element ids: incoming key pill `#hpKey` / `#hpKeyTxt` (default `"/maps"`); hash box `#hpFn` (`phash2(key)` / `mod 5`); computed index `#hpIdx` / `#hpIdxVal` (default `3`); routing arrow `#hpRoute` / `#hpRouteHead`; bucket group `#hpBuckets` with `#hpB0`–`#hpB4`; collision label `#hpCollLbl`; caption `#hpCap`.
- The figure has no named pure function; it carries state `INITIAL = [[], ['"/lists"'], [], ['"/maps"', '"/sets"'], []]` and an insert `POOL` of three keys — `{ "/trees", idx 4 }`, `{ "/heaps", idx 1 }`, `{ "/dag", idx 2 }` — each landing at a precomputed `idx` (`h mod 5`). `render(flash)` rebuilds the bucket array; `routeTo(idx)` repoints the arrow.
- Default caption (`#hpCap`, verbatim): `"/maps"` and `"/sets"` both hash to index 3 — a collision, resolved by chaining.
- Insert into an open bucket caption (verbatim): `<key>` hashes to index `<n>` (h mod 5), an open bucket — one step, no scan.
- Insert into an occupied bucket caption (verbatim): `<key>` hashes to index `<n>`, already taken — a collision, appended to the chain.
- Reset caption restores the default verbatim string above.
- Degrade: the static SVG already shows buckets 1 (`"/lists"`) and 3 (`"/maps"` chained to `"/sets"`); there is no render on load. The insert/chain "new" entry uses the `.hp-new` animation, disabled under `prefers-reduced-motion: reduce`.

### Figure 2 — `#registry`: The angle · select one

- `<figure class="fig">`, labelled by `#mpTitle` (`The angle · select one`).
- Control group `#mpSel` (`.solid-select`) with three buttons:
  - `data-k="lookup"` `data-c="sage"` (active by default) — label `lookup`
  - `data-k="membership"` `data-c="blue"` — label `membership`
  - `data-k="hashing"` `data-c="gold"` — label `hashing`
- SVG rows `#mpRow0` (`"/elixir/algorithms/maps"` → `Maps, sets & hashing`), `#mpRow1` (`"/elixir/algorithms/sorting"` → `Sorting & searching`), `#mpRow2` (`"/elixir/language/modules"` → `Functions, modules & the pipe`); caption `#mpCaption`; code `#mpCode`; readout `#mpOut`; role `#mpRole`; expression `#mpExpr`.
- Pure function: `pick(k)` selects a case from `CASES` and writes the rows, caption, role, expression, code, and out. No numeric compute.
- Readout strings VERBATIM by case:
  - **lookup** — caption: `Map.fetch by route returns the page in O(1) average time`; role: `look up a page by route`; expression: `Map.fetch(pages, route) #=> {:ok, page}`; out: "A **map lookup** resolves a route to its page in effectively constant time. The registry could hold every page in the course and `Map.fetch` would stay exactly as fast."
  - **membership** — caption: `MapSet.member? tests whether a route is built — the links gate`; role: `is this route built?`; expression: `MapSet.member?(built, route) #=> true`; out: "A **set membership** test asks only whether the key is present. The link checker runs `MapSet.member?` for every internal href — the same O(1) lookup, returning a boolean."
  - **hashing** — caption: `the key is hashed to a slot — that is what makes lookup O(1)`; role: `the hash makes it O(1)`; expression: `:erlang.phash2(route) #=> 48721903 -> slot`; out: "Both lookup and membership rest on **hashing**: the key becomes an integer, the integer picks a slot, and the value sits there. No scanning, no ordering — the subject of the third dive."
- The lookup case `code` shows `Map.fetch(pages, "/elixir/algorithms/maps")` resolving to `{:ok, %Page{title: "Maps, sets & hashing", id: "PGE0NbWMtkolM0"}}` — the branded page id appears here.

### Footer build-stamp decoder

- `.stamp` `#stamp`, id `#stampId` = `TSK0NbdtN260FE` (namespace `TSK`, base62 Snowflake decoded client-side: epoch `1704067200000`, layout `ts<<22 | node<<12 | seq`).
- Decoded timestamp shown in markup (`#st-ts`): `2026-05-31 20:25:17 UTC`.
- Panel fields `#st-ns`, `#st-snow`, `#st-node`, `#st-seq`, `#st-ts` populate on load via `decodeBranded`; the stamp toggles open on click / Enter / Space.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `Hash table — Wikipedia` — `https://en.wikipedia.org/wiki/Hash_table` — hashing and collisions.
- `Map` / `MapSet` — Elixir documentation — `https://hexdocs.pm/elixir/Map.html` — maps and sets in Elixir.

Related in this course:
- `/elixir/algorithms/maps/lookup` — F4.04.1 · Maps & key lookup
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching
- `/elixir/language/structs` — F3.05 · Structs, maps & keyword lists

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `maps` (segments `elixir` and `algorithms` link to `/elixir` and `/elixir/algorithms`; `maps` is the current `.rcur` segment, unlinked).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) `/` `F4.04 · maps` (here).
- toc-mini: `#registry` "The page registry"; `#dives` "Three deep dives"; `#advanced` "Advanced: sort vs hash, and the HAMT".
- pager: prev → `/elixir/algorithms/sorting` "F4.03 · sorting"; next → `/elixir/algorithms/maps/lookup` "Start · maps & key lookup".
- footer columns:
  - brand: `jonnify` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` = `Maps, sets & hashing — F4.04 · jonnify`. `<meta description>` = "The course you are reading runs on Phoenix LiveView, and its data layer is built from these structures: a map from route to page, a set of built routes, and branded Snowflake ids hashed as keys. Map lookup and set membership are O(1) on average; this module shows why, ending at the 32-way HAMT behind Elixir maps."

## Build instruction

To (re)build this page, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the F4 sage accent; change only `<title>`/`<meta description>`, the `.route-tag`, and the `<main>` body. This is a module hub: keep the hero (eyebrow + h1 + toc-mini + hero-fig), the `#registry` running-example figure, the three `.dives` cards, the `#advanced` sort-vs-hash bridge, and the References block. No-invent guards: use only the real Portal surfaces as written — the branded store (`%Page{}` keyed by a branded Snowflake id, namespace `PGE`/`TSK`), the event-sourced engine behind ONE Portal facade, and the Phoenix web app; do not re-teach OTP internals — cite the companion course for those. Do not fabricate routes, ids, readout strings, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/maps/lookup.html` (same chapter, same accent, same stamp epoch) for the head/header/footer/scripts, mirroring the `#mpSel` solid-select controller pattern already present in this hub.
