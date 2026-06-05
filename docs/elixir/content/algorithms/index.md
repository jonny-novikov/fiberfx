# F4 — Algorithms & Data Structures (chapter landing)

- Route (served): `/elixir/algorithms`
- File: `elixir/algorithms/index.html`
- Place in the chapter: The chapter-overview landing for F4. It frames twelve modules — `F4.01` lists through the `F4.12` branded-CHAMP lab — and surfaces the persistent-map spine (`F4.05` HAMT → `F4.06` CHAMP → `F4.07` identifiers → `F4.08` persistence → `F4.09` branded CHAMP). It sits after F3 (The Elixir Language) in the course arc and feeds forward into F5 (Pragmatic Programming).
- Accent: sage (the F4 chapter accent; `--sage` / `--sage-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · chapter overview`

Hero h1 (verbatim): Algorithms & *data structures* (`data structures` is the `.ex` italic accent span).

Hero lede (verbatim):

> The data behind the systems you built in F3. This chapter starts at the list — the BEAM's fundamental sequence — and works up through trees, sorting, and hash-based maps to the persistent tries that make immutable maps fast: HAMT and CHAMP. From there it turns to the ids that key them — the Snowflake bigint and its branded, base62 form — their persistence across SQLite, PostgreSQL, and Redis, and the branded CHAMP map behind a GenServer. Each structure comes with the cost model that tells you when to reach for it.

Kicker line (verbatim):

> Twelve modules, each grounded in working Elixir and the running portal's data. The arc is deliberate: foundations first (lists, trees, sorting, maps), then the persistent-map spine (HAMT → CHAMP → identifiers → persistence → branded CHAMP), then practical recipes, dynamic programming, and a lab where you watch a branded CHAMP map grow node by node.

## What the page frames

The landing carries two content sections after the hero. `#arc` (The chapter arc) holds the spine figure; `#modules` (Module navigation) holds the `.mods` card grid. The twelve module cards (all `built`):

- `F4.01` — Lists, recursion & complexity — Cons cells; big-O on the BEAM. — `/elixir/algorithms/lists` — built
- `F4.02` — Trees & traversals — Recursive tree shape and the three depth-first orders. — `/elixir/algorithms/trees` — built
- `F4.03` — Sorting & searching — Comparison sorts and the cost of finding things. — `/elixir/algorithms/sorting` — built
- `F4.04` — Maps, sets & hashing — Key lookup, membership, and what a hash buys you. — `/elixir/algorithms/maps` — built
- `F4.05` — Hash Array Mapped Tries (HAMT) — A tree of small nodes indexed by slices of the hash. — `/elixir/algorithms/hamt` — built
- `F4.06` — CHAMP maps — A compressed HAMT: tighter nodes, faster iteration. — `/elixir/algorithms/champ` — built
- `F4.07` — Identifiers, Snowflake & branded ids — From naive ids to a Snowflake bigint and a branded, base62 id. — `/elixir/algorithms/identifiers` — built
- `F4.08` — Branded ids & persistence — Branded ids as keys in SQLite, PostgreSQL, and Redis. — `/elixir/algorithms/persistence` — built
- `F4.09` — Branded CHAMP maps & GenServer — A CHAMP keyed by branded ids, partitioned by namespace, behind a GenServer. — `/elixir/algorithms/branded-champ` — built
- `F4.10` — Practical recipes in Elixir — Turning algorithmic problems into idiomatic Elixir. — `/elixir/algorithms/recipes` — built
- `F4.11` — Dynamic programming & advanced problems — Overlapping subproblems, memoized and tabulated. — `/elixir/algorithms/dynamic-programming` — built
- `F4.12` — Lab: build a branded CHAMP store — An interactive lab: insert branded keys and watch the partitioned CHAMP restructure. — `/elixir/algorithms/lab` — built (carries the `.mod.lab` accent border + ` · lab` suffix)

Each card also lists its three planned deep dives via the `.dives` list (the `.dn` dive number + label). For example `F4.01` lists `F4.01.1` Cons cells & the shape of a list, `F4.01.2` Recursion over lists, `F4.01.3` Complexity & big-O on the BEAM; the same `.N.1/.N.2/.N.3` shape repeats down to `F4.12.1` Watch a branded CHAMP grow, `F4.12.2` A Snowflake registry, `F4.12.3` Query by time range.

The `#arc` prose (verbatim):

> Read it in order. The foundations earn the tries: once you can reason about a list's O(n) walk and a map's average-O(1) lookup, the HAMT and CHAMP show how a tree of small nodes gives you both persistence and speed. Modules F4.01 through F4.12 — lists through the branded-CHAMP lab — are all built.

The `#modules` prose (verbatim):

> F4.01 is built; open it below. The rest list their planned deep dives so the path through the chapter is visible from here.

The closing `.note` (verbatim):

> Begin with F4.01 — Lists, recursion & complexity. The chapter builds toward the branded CHAMP map, so the early modules on cost and hashing pay off directly in the persistent-map spine. (links `F4.01 — Lists, recursion & complexity` to `/elixir/algorithms/lists`.)

## The interactives

There is one static figure (no JS-driven control group; no `solid-select` buttons, no pure function, no readout-toggle on this hub).

`<figure class="fig" aria-labelledby="arcTitle">` — The chapter-arc spine.

- Figure title (`h4#arcTitle`, verbatim): `Twelve modules · F4.01 through F4.06 are built`
- The SVG (`viewBox="0 0 720 158"`) is a static inline diagram: a horizontal spine line with twelve numbered circle nodes `01`–`12`. Nodes are labelled `lists` (with sub-label `start`), `trees`, `sort`, `maps`, `HAMT`, `CHAMP`, `ids`, `store`, `branded`, `recipe`, `DP`, `lab`. The five spine nodes `05`–`09` (HAMT, CHAMP, ids, store, branded) are drawn in the sage stroke `#7ba387`; `01` is highlighted as the start in `#a7c9b1`; `12` (lab) is drawn in the elixir accent `#b39ddb`/`#cdb8f0`. SVG aria-label (verbatim): `A spine of twelve F4 modules from lists through the persistent-map spine to a branded CHAMP lab, with F4.01 highlighted as the starting point.`
- Caption text inside the SVG (verbatim): `foundations · the persistent-map spine (05–09) · recipes · DP · lab`

The `.geo-readout` under the figure is static prose, not a JS-updated string (verbatim):

> The persistent-map spine runs through five modules: a Hash Array Mapped Trie (F4.05), its compressed successor CHAMP (F4.06), the identifiers that key them (F4.07), their persistence in SQL and Redis (F4.08), and the branded CHAMP map behind a GenServer (F4.09). The F4.12 lab then animates one growing.

The `.take` pull-quote closing `#arc` (verbatim):

> A data structure is a bet about which operations you will do most. This chapter is about reading that bet from the cost model — and choosing the structure that wins it.

Degrade behaviour: the figure is fully static in markup (no JS needed to render it). The `.arc-flow` dashed-line flow animation and the `.reveal` scroll-reveal are wrapped in `@media (prefers-reduced-motion: no-preference)` / disabled under `prefers-reduced-motion: reduce`; `html.js .reveal` content is visible without JS. `scroll-behavior:smooth` is set to `auto` under reduced motion.

Footer build-stamp decoder: the `.stamp` (`id="stamp"`) shows `build TSK0NcV2vhoCS8`. The inline script base62-decodes the branded id (`B62` alphabet, `EPOCH_MS = 1704067200000`), splitting the leading 3-char namespace from the Snowflake and unpacking `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. The markup ships the decoded timestamp verbatim in `#st-ts`: `2026-06-01 08:49:06 UTC`. Namespace prefix `TSK` (task id) with the snowflake/node/seq fields filled in on activation.

## References (#refs, verbatim)

This hub page has no `#refs` References section. There is no References block in the markup (no intro line, no Sources list, no Related-in-this-course list). Per-module References blocks live on the F4 module hubs and dives, not on this chapter landing.

## Wiring

- route-tag (verbatim, in the sticky header): `/ ` `elixir` `/ ` `algorithms` — rendered as `<span class="route-tag"><span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><span class="rcur">algorithms</span></span>`.
- crumbs (verbatim): `Contents` (→ `/elixir/course`) `/` `F4 · Algorithms & Data Structures` (`.here`).
- toc-mini (verbatim): `The chapter arc` (→ `#arc`), `Module navigation` (→ `#modules`). Labelled `On this page`.
- pager (verbatim): prev → `/elixir/language` label `← F3 · The Elixir Language`; next → `/elixir/algorithms/lists` label `Start · F4.01 lists →`.
- footer: three columns under `Functional Programming in Elixir — course navigation`.
  - Brand column: `jonnify` logo (→ `/elixir`) + tagline `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
  - `Chapters`: `F1 · Algebra` (→ `/elixir/algebra`), `F2 · Functional Programming` (→ `/elixir/functional`), `F3 · The Elixir Language` (→ `/elixir/language`), `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`), `F5 · Pragmatic Programming` (→ `/elixir/pragmatic`), `F6 · Phoenix Framework` (→ `/elixir/phoenix`).
  - `The course`: `Course home` (→ `/elixir`), `Contents & history` (→ `/elixir/course`), `Start · F1.01` (→ `/elixir/algebra/functions`).
- Page meta: `<title>` (verbatim): `Algorithms & Data Structures — F4 · jonnify`. `<meta name="description">` (verbatim): `The F4 chapter overview: nine modules from lists through trees, sorting, and hash-based maps to the persistent trie family — HAMT, CHAMP, and the branded CHAMP map keyed by a Snowflake pivot — plus dynamic programming and a lab. F4.01 is built; the rest show their planned dives.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the sticky `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks (the build-stamp decoder and the reveal-on-scroll enhancer) verbatim from a recent built F4 sibling on the sage accent; change only the `<title>`/`<meta name="description">`, the header `route-tag`, the crumbs `.here` label, and the `<main>` body (hero, `#arc` figure, `#modules` card grid, pager). The model sibling to copy from is `elixir/algorithms/lists/index.html` (`/elixir/algorithms/lists`), the built F4.01 module hub on this chapter accent; for the chapter-landing card-grid shape, the F3 landing `elixir/language/index.html` is the closest structural template. No-invent guards: use only the real Portal surfaces as written — the branded store keyed by `TSK…`/`PGE…` Snowflake ids, the event-sourced engine behind one Portal facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them here. Do not fabricate a route, module number, dive label, readout string, or build-stamp id; this hub carries no `#refs` block, so do not add one. Voice rules: no first person, no exclamation marks, no emoji, and none of the words *just*, *simply*, or *obviously*.
