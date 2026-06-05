# F4.10.3 — Profiling & complexity (dive)

- Route (served): `/elixir/algorithms/recipes/profiling`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/recipes/profiling.html`
- Place in the chapter: part 3 of 3 of module `F4.10` (Practical recipes), the closing dive of F4 · Algorithms & Data Structures' recipes module. It reads complexity from the code — an `O(n)` list scan against an `O(log₃₂ n)` branded-CHAMP lookup — to justify why the Portal's session store is the F4.09 CHAMP. Last dive off the `F4.10` hub; closes the module before `F4.11 — Dynamic programming in Elixir`.
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.10 · part 3 of 3 · choosing a lookup`

Hero h1 (verbatim): Profiling & `complexity`

Hero lede (verbatim):

> Every active session has to be found on every request. Keep sessions in a list and a lookup scans it — `O(n)`, growing with the user base. Keep them in the branded-CHAMP store of F4.09 and a lookup descends a few trie levels — `O(log₃₂ n)`, effectively flat. The right structure is not a matter of taste here; you can read the difference straight from the code and watch it widen as the Portal grows.

Kicker line (verbatim):

> The same lookup, the two structures, at three user-base sizes. Pick a size and compare the work each one does.

## Sections

In order:

1. `#cost` — **Read the cost from the shape** (teaching). The "Active sessions · select one" figure (list scan vs CHAMP lookup at three sizes) plus its take.
2. `#advanced` — **Advanced: measure, but reason first** (advanced). Reasoning about complexity tells you how a cost scales; `:timer.tc/1` tells you what it is at one size; reason first, then measure. Two caveats: `O(log₃₂ n)` is flat in practice (at most ~six hops to a billion) but still grows, and a small list beats a trie on constant factors.

Running example: finding an active session by id. Real Elixir shown (advanced block, verbatim): `{t_list, _} = :timer.tc(fn -> List.keyfind(sessions, sid, 0) end) # O(n)` and `{t_map, _} = :timer.tc(fn -> Champ.get(store, sid) end) # O(log₃₂ n)`, with comments `# at 10_000_000 sessions: ~10_000_000 comparisons vs ~5 node hops` and `# the list keeps growing; the map barely moves — so the store is a CHAMP`.

## The interactives

### Figure — "Active sessions · select one"

- `<figure class="fig">`, labelled by `id="pfTitle"` (`Active sessions · select one`).
- Control group `id="pfSel"` (role `group`, aria-label `Dataset size`) with buttons: `data-k="k"` `data-c="sage"` (active, label `1,000`); `data-k="h"` `data-c="blue"` (`100,000`); `data-k="m"` `data-c="gold"` (`10,000,000`).
- SVG ids: list-scan label/bar `pfBarList` + count `pfListN` (under `List.keyfind/3 · O(n)`); map-lookup bar `pfBarMap` + count `pfMapN` (under `Champ.get/2 · O(log₃₂ n)`); caption `pfCaption`. Code/readout ids: `pfCode`, `pfOut`, `pfRole`, `pfResult`.
- Pure functions: `hops(n) = max(1, ceil(log(n)/log(32)))` (CHAMP depth, base 32); list scan = `n` comparisons; `speed = round(n / h)`; bars scaled on a log10 scale to the 10M case. `SIZES`: `k` `1000`, `h` `100000`, `m` `10000000`.
- Readout strings (VERBATIM):
  - Static default markup: `pfListN` `1,000 comparisons`; `pfMapN` `2 node hops`; axis note `bars are on a logarithmic scale; labels are the actual operation counts`; `pfCaption` `about 500× fewer operations`; `pfRole` `1,000 ops`; `pfResult` `2 hops`.
  - Computed (JS): `pfListN` `<n with commas> comparisons`; `pfMapN` `<h> node hops`; `pfCaption` `about <speed with commas>× fewer operations`; `pfRole` `<n with commas> ops`; `pfResult` `<h> hops`.
  - Printed code template: `# <n> active sessions` / `List.keyfind(sessions, sid, 0)   # O(n)  ->  up to <n> comparisons` / `Champ.get(store, sid)            # O(log₃₂ n)  ->  <h> node hops` / `# the map does about <speed>× fewer operations to find the session`.
  - Readout `pfOut`: `At <n> sessions, the list scan does up to <n> comparisons while the CHAMP lookup does <h> node hops — about <speed>× fewer. The list cost rises with every size; the map cost barely moves.`
- Take (verbatim): `The list and the map agree at small sizes and diverge without bound. At ten million sessions the scan is millions of comparisons and the map is five hops — the reason the Portal's store is a CHAMP.`

### Bridge

`a structure choice` (List or map for the session store.) → `a complexity` (`O(n)` that grows with users, or `O(log₃₂ n)` that stays flat.).

### Footer build-stamp decoder

- `id="stamp"` keyboard-activatable; `id="stampId"` text `TSK0NcdRcARPcW`.
- Decodes namespace `TSK`, snowflake, node, seq, timestamp via the B62 / epoch `1704067200000` decoder; markup pre-decoded timestamp dd `2026-06-01 10:46:37 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- Erlang — Efficiency Guide: list handling — the cost of scanning a list. — `https://www.erlang.org/doc/efficiency_guide/listhandling.html`
- Erlang — `:timer.tc/1` — measuring a call's wall-clock time. — `https://www.erlang.org/doc/man/timer.html#tc-1`
- Big O notation — Wikipedia — reasoning about how cost scales. — `https://en.wikipedia.org/wiki/Big_O_notation`

Related in this course:
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — the map whose lookup is logarithmic.
- `/elixir/algorithms/branded-champ` — F4.09 · Branded CHAMP maps & GenServer — the store this lookup runs against.
- `/elixir/algorithms/recipes` — F4.10 · Practical recipes in Elixir — the module hub.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `recipes` `/` `profiling` (`profiling` is `.rcur`; `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `recipes` → `/elixir/algorithms/recipes`).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) / `F4.10` (→ `/elixir/algorithms/recipes`) / `profiling` (here).
- toc-mini: `#cost` → `Read the cost from the shape`; `#advanced` → `Advanced: measure, but reason first`.
- pager: prev → `/elixir/algorithms/recipes/pipelines` label `F4.10.2 · pipelines`; next → `/elixir/algorithms` label `F4 · Algorithms & Data Structures`.
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot-tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta:
  - `<title>`: `Profiling & complexity — F4.10.3 · jonnify`
  - `<meta description>`: `Every request finds an active session. A list scan is O(n) and grows with the user base; a branded-CHAMP lookup is O(log32 n) and stays a few node hops — 2 at a thousand sessions, 4 at a hundred thousand, 5 at ten million. Reason about which scales before measuring with :timer.tc; log32 n is flat in practice but not literally O(1), and a small list still beats a trie. The Portal's store is a CHAMP for this reason.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `header`, `footer`, and trailing `<script>` blocks verbatim from a recent built sibling on the sage F4 accent — copy from the chapter-mate dive `/elixir/algorithms/recipes/pipelines` (`/Users/jonny/dev/jonnify/elixir/algorithms/recipes/pipelines.html`), which shares this dive's exact anatomy (hero lede, one teaching `.fig` + one advanced section, bridge, refs, pager). Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `List.keyfind/3`, `Champ.get/2`, `:timer.tc/1`, the branded-CHAMP store of F4.09, the event-sourced engine behind one Portal facade, the Phoenix web app; cite the companion course for OTP internals, do not re-teach them; do not invent ids, routes, readout strings, operation counts, or reference URLs beyond those above. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
